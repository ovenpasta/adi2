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


def _unescape_po(s: str) -> str:
    """Unescape PO string escapes."""
    return (s.replace('\\n', '\n')
             .replace('\\t', '\t')
             .replace('\\"', '"')
             .replace('\\\\', '\\'))


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

        # Header entry (empty msgid)
        if current.msgid == "" and current.msgstr:
            # Extract Plural-Forms from header
            for header_line in current.msgstr.split('\n'):
                header_line = header_line.strip()
                if header_line.lower().startswith('plural-forms:'):
                    rest = header_line[len('plural-forms:'):].strip()
                    # Parse nplurals=N
                    m = re.search(r'nplurals\s*=\s*(\d+)', rest)
                    if m:
                        result.n_plurals = int(m.group(1))
                    # Parse plural=EXPR
                    m = re.search(r'plural\s*=\s*(.+?)(?:\s*;|$)', rest)
                    if m:
                        result.plural_formula = m.group(1).strip()
                        # Remove trailing semicolons
                        result.plural_formula = result.plural_formula.rstrip(';').strip()
            current = None
            return

        # Skip fuzzy or empty translations
        if current.fuzzy:
            current = None
            return

        if current.msgid_plural:
            # Plural entry — check all forms are non-empty
            if current.msgstr_plural and all(
                v for v in current.msgstr_plural.values()
            ):
                result.entries.append(current)
        else:
            # Singular entry
            if current.msgstr:
                result.entries.append(current)

        current = None

    for raw_line in lines:
        line = raw_line.rstrip('\n')

        # Flags line
        if line.startswith('#,'):
            if 'fuzzy' in line:
                is_fuzzy = True
            continue

        # Other comments
        if line.startswith('#'):
            continue

        # Empty line = entry separator
        if not line.strip():
            finish_entry()
            continue

        # msgctxt
        if line.startswith('msgctxt '):
            finish_entry()
            current = PoEntry()
            s = _extract_string(line)
            if s is not None:
                current.msgctxt = _unescape_po(s)
            last_field = 'msgctxt'
            continue

        # msgid_plural
        if line.startswith('msgid_plural '):
            s = _extract_string(line)
            if s is not None and current is not None:
                current.msgid_plural = _unescape_po(s)
            last_field = 'msgid_plural'
            continue

        # msgid
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

        # msgstr[N]
        m_plural = re.match(r'msgstr\[(\d+)\]\s', line)
        if m_plural:
            idx = int(m_plural.group(1))
            s = _extract_string(line)
            if s is not None and current is not None:
                current.msgstr_plural[idx] = _unescape_po(s)
            last_field = f'msgstr_plural_{idx}'
            continue

        # msgstr (singular)
        if line.startswith('msgstr '):
            s = _extract_string(line)
            if s is not None and current is not None:
                current.msgstr = _unescape_po(s)
            last_field = 'msgstr'
            continue

        # Continuation line (starts with ")
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

    # Finish last entry
    finish_entry()

    return result


def ada_escape(s: str) -> str:
    """Escape a string for use as an Ada string literal body (inside quotes)."""
    return s.replace('"', '""')


def generate(po_files: list[PoFile], package_name: str) -> tuple[str, str]:
    """Generate Ada spec and body source strings from parsed PO files."""

    # Spec
    spec_lines = [
        'pragma Ada_2022;',
        f'package {package_name} is',
        '   procedure Register_All;',
        f'end {package_name};',
    ]

    # Body
    body_lines = [
        'pragma Ada_2022;',
        '',
        'with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;',
        'with Adi.I18N; use Adi.I18N;',
        '',
        f'package body {package_name} is',
        '',
        '   procedure Register_All is',
        '   begin',
    ]

    for po in po_files:
        lang = ada_escape(po.language)

        # Register plural formula if non-default
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
                # Plural entry
                forms = []
                for idx in sorted(entry.msgstr_plural.keys()):
                    val = ada_escape(entry.msgstr_plural[idx])
                    forms.append(f'To_Unbounded_String ("{val}")')

                if len(forms) == 1:
                    forms_str = f'(0 => {forms[0]})'
                else:
                    forms_str = '(' + ',\n         '.join(forms) + ')'

                body_lines.append(
                    f'      Register_Plural ("{lang}", "{msgid}",')
                body_lines.append(
                    f'        {forms_str}{ctx_param});')
            else:
                # Singular entry
                msgstr = ada_escape(entry.msgstr)
                body_lines.append(
                    f'      Register ("{lang}", "{msgid}",'
                    f' "{msgstr}"{ctx_param});')

        body_lines.append('')

    # Remove trailing blank line if present
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
