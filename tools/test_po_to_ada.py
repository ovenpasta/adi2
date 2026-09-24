#!/usr/bin/env python3
"""Tests for po_to_ada.py PO parser and Ada code generator."""

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
from po_to_ada import parse_po, generate, language_from_filename, PoFile


class TestLanguageFromFilename(unittest.TestCase):
    def test_simple(self):
        self.assertEqual(language_from_filename("fr.po"), "fr")

    def test_regional(self):
        self.assertEqual(language_from_filename("pt_BR.po"), "pt_BR")

    def test_with_path(self):
        self.assertEqual(
            language_from_filename("/some/path/de.po"), "de")

    def test_hyphenated(self):
        self.assertEqual(language_from_filename("zh-CN.po"), "zh-CN")


class TestPoParser(unittest.TestCase):
    def _parse(self, content: str, filename: str = "test.po") -> PoFile:
        with tempfile.NamedTemporaryFile(
            mode='w', suffix='.po', prefix=filename.replace('.po', '_'),
            delete=False, encoding='utf-8'
        ) as f:
            f.write(content)
            path = f.name
        try:
            result = parse_po(path)
            result.language = language_from_filename(filename)
            return result
        finally:
            os.unlink(path)

    def test_simple_entry(self):
        po = self._parse('''
msgid "Hello"
msgstr "Bonjour"
''', 'fr.po')
        self.assertEqual(len(po.entries), 1)
        self.assertEqual(po.entries[0].msgid, "Hello")
        self.assertEqual(po.entries[0].msgstr, "Bonjour")

    def test_multiple_entries(self):
        po = self._parse('''
msgid "Hello"
msgstr "Hallo"

msgid "Cancel"
msgstr "Abbrechen"
''', 'de.po')
        self.assertEqual(len(po.entries), 2)
        self.assertEqual(po.entries[0].msgid, "Hello")
        self.assertEqual(po.entries[1].msgid, "Cancel")

    def test_multiline_strings(self):
        po = self._parse('''
msgid ""
"Hello "
"World"
msgstr ""
"Bonjour "
"le monde"
''', 'fr.po')
        self.assertEqual(len(po.entries), 1)
        self.assertEqual(po.entries[0].msgid, "Hello World")
        self.assertEqual(po.entries[0].msgstr, "Bonjour le monde")

    def test_fuzzy_skip(self):
        po = self._parse('''
#, fuzzy
msgid "Hello"
msgstr "Bonjour"

msgid "World"
msgstr "Monde"
''', 'fr.po')
        self.assertEqual(len(po.entries), 1)
        self.assertEqual(po.entries[0].msgid, "World")

    def test_empty_msgstr_skip(self):
        po = self._parse('''
msgid "Untranslated"
msgstr ""

msgid "Translated"
msgstr "Traduit"
''', 'fr.po')
        self.assertEqual(len(po.entries), 1)
        self.assertEqual(po.entries[0].msgid, "Translated")

    def test_comments_ignored(self):
        po = self._parse('''
# Translator comment
#. Extracted comment
#: src/file.c:42
msgid "Hello"
msgstr "Bonjour"
''', 'fr.po')
        self.assertEqual(len(po.entries), 1)

    def test_msgctxt(self):
        po = self._parse('''
msgctxt "menu"
msgid "Open"
msgstr "Ouvrir"

msgctxt "adjective"
msgid "Open"
msgstr "Ouvert"
''', 'fr.po')
        self.assertEqual(len(po.entries), 2)
        self.assertEqual(po.entries[0].msgctxt, "menu")
        self.assertEqual(po.entries[0].msgid, "Open")
        self.assertEqual(po.entries[0].msgstr, "Ouvrir")
        self.assertEqual(po.entries[1].msgctxt, "adjective")

    def test_plural_forms(self):
        po = self._parse('''
msgid "%d file"
msgid_plural "%d files"
msgstr[0] "%d fichier"
msgstr[1] "%d fichiers"
''', 'fr.po')
        self.assertEqual(len(po.entries), 1)
        entry = po.entries[0]
        self.assertEqual(entry.msgid, "%d file")
        self.assertEqual(entry.msgid_plural, "%d files")
        self.assertEqual(entry.msgstr_plural[0], "%d fichier")
        self.assertEqual(entry.msgstr_plural[1], "%d fichiers")

    def test_header_plural_forms(self):
        po = self._parse('''
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\\n"
"Plural-Forms: nplurals=2; plural=n > 1;\\n"

msgid "Hello"
msgstr "Bonjour"
''', 'fr.po')
        self.assertEqual(po.n_plurals, 2)
        self.assertEqual(po.plural_formula, "n > 1")
        self.assertEqual(len(po.entries), 1)

    def test_header_complex_formula(self):
        po = self._parse('''
msgid ""
msgstr ""
"Plural-Forms: nplurals=3; plural=(n==1 ? 0 : n>=2 && n<=4 ? 1 : 2);\\n"
''', 'cs.po')
        self.assertEqual(po.n_plurals, 3)
        self.assertEqual(
            po.plural_formula,
            "(n==1 ? 0 : n>=2 && n<=4 ? 1 : 2)")

    def test_escaped_quotes(self):
        po = self._parse(r'''
msgid "Say \"hello\""
msgstr "Dire \"bonjour\""
''', 'fr.po')
        self.assertEqual(len(po.entries), 1)
        self.assertEqual(po.entries[0].msgid, 'Say "hello"')
        self.assertEqual(po.entries[0].msgstr, 'Dire "bonjour"')

    def test_escapes_decode_in_one_pass(self):
        #  Each backslash takes exactly the character after it.
        po = self._parse(r'''
msgid "a\\nb"
msgstr "c\\td\\\"e\\\\f"

msgid "g\nh\ti\rj"
msgstr "k\ql"
''', 'fr.po')
        self.assertEqual(len(po.entries), 2)
        self.assertEqual(po.entries[0].msgid, 'a\\nb')
        self.assertEqual(po.entries[0].msgstr, 'c\\td\\"e\\\\f')
        self.assertEqual(po.entries[1].msgid, 'g\nh\ti\rj')
        self.assertEqual(po.entries[1].msgstr, 'k\\ql')

    def test_three_plural_forms(self):
        po = self._parse('''
msgid ""
msgstr ""
"Plural-Forms: nplurals=3; plural=(n==1 ? 0 : n>=2 && n<=4 ? 1 : 2);\\n"

msgid "%d item"
msgid_plural "%d items"
msgstr[0] "%d polozka"
msgstr[1] "%d polozky"
msgstr[2] "%d polozek"
''', 'cs.po')
        self.assertEqual(po.n_plurals, 3)
        self.assertEqual(len(po.entries), 1)
        entry = po.entries[0]
        self.assertEqual(len(entry.msgstr_plural), 3)


class TestGenerate(unittest.TestCase):
    def test_simple_generation(self):
        po = PoFile(language="fr")
        from po_to_ada import PoEntry
        po.entries = [
            PoEntry(msgid="Hello", msgstr="Bonjour"),
            PoEntry(msgid="Cancel", msgstr="Annuler"),
        ]
        spec, body = generate([po], "My_Translations")

        self.assertIn("procedure Register_All;", spec)
        self.assertIn("My_Translations", spec)
        self.assertIn('Register ("fr", "Hello", "Bonjour")', body)
        self.assertIn('Register ("fr", "Cancel", "Annuler")', body)

    def test_context_generation(self):
        po = PoFile(language="fr")
        from po_to_ada import PoEntry
        po.entries = [
            PoEntry(msgctxt="menu", msgid="Open", msgstr="Ouvrir"),
        ]
        _, body = generate([po], "Ctx_Test")
        self.assertIn('Context => "menu"', body)

    def test_plural_generation(self):
        po = PoFile(language="fr", n_plurals=2, plural_formula="n > 1")
        from po_to_ada import PoEntry
        po.entries = [
            PoEntry(
                msgid="%d file",
                msgid_plural="%d files",
                msgstr_plural={0: "%d fichier", 1: "%d fichiers"}),
        ]
        _, body = generate([po], "Plural_Test")
        self.assertIn('Register_Plural_Formula ("fr", 2, "n > 1")', body)
        self.assertIn('Register_Plural ("fr", "%d file"', body)
        self.assertIn(
            '[To_Unbounded_String ("%d fichier"),\n'
            '         To_Unbounded_String ("%d fichiers")]', body)

    def test_single_plural_form_is_a_named_aggregate(self):
        po = PoFile(language="ja", n_plurals=1, plural_formula="0")
        from po_to_ada import PoEntry
        po.entries = [
            PoEntry(msgid="%d file", msgid_plural="%d files",
                    msgstr_plural={0: "%d ファイル"}),
        ]
        _, body = generate([po], "Single_Test")
        self.assertIn('[0 => To_Unbounded_String ("%d ファイル")]', body)

    def test_ada_escaping(self):
        po = PoFile(language="fr")
        from po_to_ada import PoEntry
        po.entries = [
            PoEntry(msgid='Say "hello"', msgstr='Dire "bonjour"'),
        ]
        _, body = generate([po], "Escape_Test")
        self.assertIn('Say ""hello""', body)
        self.assertIn('Dire ""bonjour""', body)

    def test_control_characters_are_concatenated(self):
        from po_to_ada import PoEntry
        po = PoFile(language="fr")
        po.entries = [
            PoEntry(msgid='Two\nlines', msgstr='Deux\nlignes\t\x7f'),
            PoEntry(msgid='%d line', msgid_plural='%d lines',
                    msgstr_plural={0: '%d\nligne', 1: '%d\nlignes'}),
        ]
        _, body = generate([po], "Control_Test")
        self.assertIn(
            'Register ("fr", "Two" & Character\'Val (10) & "lines", '
            '"Deux" & Character\'Val (10) & "lignes" & Character\'Val (9)'
            ' & "" & Character\'Val (127) & "");', body)
        self.assertIn(
            'To_Unbounded_String ("%d" & Character\'Val (10) & "ligne")',
            body)
        self.assertFalse(any(ord(c) < 32 and c != '\n' or ord(c) == 127
                             for c in body))

    def test_multiple_languages(self):
        from po_to_ada import PoEntry
        fr = PoFile(language="fr")
        fr.entries = [PoEntry(msgid="Hello", msgstr="Bonjour")]
        de = PoFile(language="de")
        de.entries = [PoEntry(msgid="Hello", msgstr="Hallo")]

        _, body = generate([fr, de], "Multi_Lang")
        self.assertIn('Register ("fr", "Hello", "Bonjour")', body)
        self.assertIn('Register ("de", "Hello", "Hallo")', body)

    def test_with_clause(self):
        po = PoFile(language="fr")
        _, body = generate([po], "With_Test")
        self.assertIn("with Adi.I18N; use Adi.I18N;", body)

    def test_default_formula_not_emitted(self):
        """Default English formula (nplurals=2, n != 1) should not emit
        Register_Plural_Formula."""
        po = PoFile(language="en", n_plurals=2, plural_formula="n != 1")
        _, body = generate([po], "Default_Test")
        self.assertNotIn("Register_Plural_Formula", body)


class TestLanguageExtraction(unittest.TestCase):
    def test_simple_codes(self):
        self.assertEqual(language_from_filename("fr.po"), "fr")
        self.assertEqual(language_from_filename("de.po"), "de")
        self.assertEqual(language_from_filename("en.po"), "en")

    def test_regional_codes(self):
        self.assertEqual(language_from_filename("pt_BR.po"), "pt_BR")
        self.assertEqual(language_from_filename("zh_CN.po"), "zh_CN")
        self.assertEqual(language_from_filename("en_US.po"), "en_US")


if __name__ == '__main__':
    unittest.main()
