#!/usr/bin/env python3
"""Compile .po translation files to Ada packages for Adi.I18N.

Usage:
    python3 tools/po_to_ada.py \\
        --output-dir examples/generated/ \\
        --package-name I18N_Example_Translations \\
        fr.po de.po
"""

import argparse
import os
import re
import sys
from dataclasses import dataclass, field


@dataclass
class PoEntry:
    msgctxt: str = ""
    msgid: str = ""
    msgid_plural: str = ""
    msgstr: str = ""           # singular translation
    msgstr_plural: dict = field(default_factory=dict)  # {index: string}
    fuzzy: bool = False


@dataclass
class PoFile:
    language: str
    entries: list[PoEntry] = field(default_factory=list)
    n_plurals: int = 2
    plural_formula: str = "n != 1"


def language_from_filename(path: str) -> str:
    """Extract language code from filename: fr.po -> 'fr', pt_BR.po -> 'pt_BR'."""
    base = os.path.basename(path)
    name, _ = os.path.splitext(base)
    return name


def _extract_string(line: str) -> str | None:
    """Extract the string content from a PO line like 'msgid "text"'."""
    m = re.search(r'"((?:[^"\\]|\\.)*)"', line)
    if m:
        return m.group(1)
    return None


_PO_ESCAPES = {'a': '\a', 'b': '\b', 'f': '\f', 'n': '\n', 'r': '\r',
               't': '\t', 'v': '\v', '"': '"', '\\': '\\'}


def _unescape_po(s: str) -> str:
    """Decode the single-character escapes; any other, octal and hex
    included, stays as written."""
    return re.sub(r'\\(.)',
                  lambda m: _PO_ESCAPES.get(m.group(1), m.group(0)), s)


def parse_po(path: str) -> PoFile:
    """Parse a .po file and return a PoFile with all entries."""
    language = language_from_filename(path)
    result = PoFile(language=language)

    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    current = None
    last_field = None  # tracks which field continuation lines append to
    is_fuzzy = False

    def finish_entry():
        nonlocal current, is_fuzzy
        if current is None:
            return
        current.fuzzy = is_fuzzy
        is_fuzzy = False

        if current.msgid == "" and current.msgstr:
            for header_line in current.msgstr.split('\n'):
                header_line = header_line.strip()
                if header_line.lower().startswith('plural-forms:'):
                    rest = header_line[len('plural-forms:'):].strip()
                    m = re.search(r'nplurals\s*=\s*(\d+)', rest)
                    if m:
                        result.n_plurals = int(m.group(1))
                    m = re.search(r'plural\s*=\s*(.+?)(?:\s*;|$)', rest)
                    if m:
                        result.plural_formula = m.group(1).strip()
                        result.plural_formula = result.plural_formula.rstrip(';').strip()
            current = None
            return

        if current.fuzzy:
            current = None
            return

        if current.msgid_plural:
            if current.msgstr_plural and all(
                v for v in current.msgstr_plural.values()
            ):
                result.entries.append(current)
        else:
            if current.msgstr:
                result.entries.append(current)

        current = None

    for raw_line in lines:
        line = raw_line.rstrip('\n')

        if line.startswith('#,'):
            if 'fuzzy' in line:
                is_fuzzy = True
            continue

        if line.startswith('#'):
            continue

        if not line.strip():
            finish_entry()
            continue

        if line.startswith('msgctxt '):
            finish_entry()
            current = PoEntry()
            s = _extract_string(line)
            if s is not None:
                current.msgctxt = _unescape_po(s)
            last_field = 'msgctxt'
            continue

        if line.startswith('msgid_plural '):
            s = _extract_string(line)
            if s is not None and current is not None:
                current.msgid_plural = _unescape_po(s)
            last_field = 'msgid_plural'
            continue

        if line.startswith('msgid '):
            # If current already has a msgid, finish it and start fresh.
            # But if current has only a msgctxt (no msgid yet), keep it.
            if current is not None and current.msgid != "":
                finish_entry()
                current = PoEntry()
            elif current is None:
                current = PoEntry()
            s = _extract_string(line)
            if s is not None:
                current.msgid = _unescape_po(s)
            last_field = 'msgid'
            continue

        m_plural = re.match(r'msgstr\[(\d+)\]\s', line)
        if m_plural:
            idx = int(m_plural.group(1))
            s = _extract_string(line)
            if s is not None and current is not None:
                current.msgstr_plural[idx] = _unescape_po(s)
            last_field = f'msgstr_plural_{idx}'
            continue

        if line.startswith('msgstr '):
            s = _extract_string(line)
            if s is not None and current is not None:
                current.msgstr = _unescape_po(s)
            last_field = 'msgstr'
            continue

        stripped = line.strip()
        if stripped.startswith('"') and current is not None:
            s = _extract_string(stripped)
            if s is not None:
                val = _unescape_po(s)
                if last_field == 'msgctxt':
                    current.msgctxt += val
                elif last_field == 'msgid':
                    current.msgid += val
                elif last_field == 'msgid_plural':
                    current.msgid_plural += val
                elif last_field == 'msgstr':
                    current.msgstr += val
                elif last_field and last_field.startswith('msgstr_plural_'):
                    idx = int(last_field.split('_')[-1])
                    current.msgstr_plural[idx] = \
                        current.msgstr_plural.get(idx, '') + val

    finish_entry()

    return result


def ada_escape(s: str) -> str:
    """Escape a string for use as an Ada string literal body (inside quotes).

    A literal cannot hold a control character, so one is concatenated.
    """
    return re.sub(r'[\x00-\x1f\x7f]',
                  lambda m: f'" & Character\'Val ({ord(m.group())}) & "',
                  s.replace('"', '""'))


def generate(po_files: list[PoFile], package_name: str) -> tuple[str, str]:
    """Generate Ada spec and body source strings from parsed PO files."""

    spec_lines = [
        'pragma Ada_2022;',
        f'package {package_name} is',
        '   procedure Register_All;',
        f'end {package_name};',
    ]

    #  The translated msgstr are plain String literals holding raw UTF-8
    #  bytes (what Adi.I18N / the text renderer consume). They are only
    #  correct when NOT UTF-8-decoded at compile time: a project-wide
    #  -gnatW8 would collapse each accent to a single Latin-1 byte, which
    #  the renderer then sees as invalid UTF-8 and draws as a box. The
    #  pragma forces this one file to keep the bytes verbatim; it is a
    #  no-op for consumers that don't use -gnatW8 (Brackets is the default).
    #  Ada.Strings.Unbounded is only referenced by the plural-form
    #  registrations (To_Unbounded_String); emitting it unconditionally
    #  gives consumers an unreferenced-unit warning.
    has_plurals = any(
        entry.msgid_plural for po in po_files for entry in po.entries)

    body_lines = [
        'pragma Wide_Character_Encoding (Brackets);',
        'pragma Ada_2022;',
        '',
    ]
    if has_plurals:
        body_lines.append(
            'with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;')
    body_lines += [
        'with Adi.I18N; use Adi.I18N;',
        '',
        f'package body {package_name} is',
        '',
        '   procedure Register_All is',
        '   begin',
    ]

    for po in po_files:
        lang = ada_escape(po.language)

        if po.plural_formula != "n != 1" or po.n_plurals != 2:
            formula = ada_escape(po.plural_formula)
            body_lines.append(
                f'      Register_Plural_Formula'
                f' ("{lang}", {po.n_plurals}, "{formula}");')
            body_lines.append('')

        for entry in po.entries:
            msgid = ada_escape(entry.msgid)
            ctx_param = ""
            if entry.msgctxt:
                ctx = ada_escape(entry.msgctxt)
                ctx_param = f', Context => "{ctx}"'

            if entry.msgid_plural:
                forms = []
                for idx in sorted(entry.msgstr_plural.keys()):
                    val = ada_escape(entry.msgstr_plural[idx])
                    forms.append(f'To_Unbounded_String ("{val}")')

                if len(forms) == 1:
                    forms_str = f'[0 => {forms[0]}]'
                else:
                    forms_str = '[' + ',\n         '.join(forms) + ']'

                body_lines.append(
                    f'      Register_Plural ("{lang}", "{msgid}",')
                body_lines.append(
                    f'        {forms_str}{ctx_param});')
            else:
                msgstr = ada_escape(entry.msgstr)
                body_lines.append(
                    f'      Register ("{lang}", "{msgid}",'
                    f' "{msgstr}"{ctx_param});')

        body_lines.append('')

    if body_lines and body_lines[-1] == '':
        body_lines.pop()

    body_lines.append('   end Register_All;')
    body_lines.append('')
    body_lines.append(f'end {package_name};')

    spec = '\n'.join(spec_lines) + '\n'
    body = '\n'.join(body_lines) + '\n'
    return spec, body


def main():
    parser = argparse.ArgumentParser(
        description='Compile .po files to Ada packages for Adi.I18N')
    parser.add_argument('files', nargs='+', help='Input .po files')
    parser.add_argument('--output-dir', required=True,
                        help='Output directory for generated Ada files')
    parser.add_argument('--package-name', required=True,
                        help='Ada package name')
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    po_files = []
    for filepath in args.files:
        po_files.append(parse_po(filepath))

    spec, body = generate(po_files, args.package_name)

    base_name = args.package_name.lower().replace('.', '-')
    spec_path = os.path.join(args.output_dir, base_name + '.ads')
    body_path = os.path.join(args.output_dir, base_name + '.adb')

    with open(spec_path, 'w') as f:
        f.write(spec)
    with open(body_path, 'w') as f:
        f.write(body)

    print(f'[po_to_ada] generated: {spec_path}')
    print(f'[po_to_ada] generated: {body_path}')


if __name__ == '__main__':
    main()
