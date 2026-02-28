#!/usr/bin/env python3
"""Tests for binary_to_ada.py"""

import os
import sys
import tempfile
import unittest

# Add tools directory to path
sys.path.insert(0, os.path.dirname(__file__))
from binary_to_ada import file_to_identifier, bytes_to_decimal_lines, relative_key, generate


class TestFileToIdentifier(unittest.TestCase):
    def test_simple(self):
        self.assertEqual(file_to_identifier('icons.svg'), 'Icons_Svg')

    def test_dashes(self):
        self.assertEqual(file_to_identifier('my-font.ttf'), 'My_Font_Ttf')

    def test_dots(self):
        self.assertEqual(file_to_identifier('data.min.js'), 'Data_Min_Js')

    def test_leading_digit(self):
        self.assertEqual(file_to_identifier('123file.png'), 'F_123file_Png')

    def test_path_uses_basename(self):
        self.assertEqual(file_to_identifier('a/b/c/test.png'), 'Test_Png')

    def test_special_chars(self):
        self.assertEqual(file_to_identifier('a@b#c.txt'), 'A_B_C_Txt')

    def test_empty_after_strip(self):
        self.assertEqual(file_to_identifier('...'), 'Unknown')


class TestBytesToDecimalLines(unittest.TestCase):
    def test_basic(self):
        data = bytes([137, 80])
        lines = bytes_to_decimal_lines(data, bytes_per_line=16)
        self.assertEqual(len(lines), 1)
        self.assertIn('137', lines[0])
        self.assertIn('80', lines[0])

    def test_multiple_lines(self):
        data = bytes(range(32))
        lines = bytes_to_decimal_lines(data, bytes_per_line=16)
        self.assertEqual(len(lines), 2)


class TestRelativeKey(unittest.TestCase):
    def test_with_base_dir(self):
        key = relative_key('/foo/bar/icons.svg', '/foo/bar')
        self.assertEqual(key, 'icons.svg')

    def test_with_subdirectory(self):
        key = relative_key('/foo/bar/sub/icon.svg', '/foo/bar')
        self.assertEqual(key, 'sub/icon.svg')

    def test_without_base_dir(self):
        key = relative_key('/foo/bar/icons.svg', None)
        self.assertEqual(key, 'icons.svg')


class TestGenerate(unittest.TestCase):
    def test_constants_in_body(self):
        """Constants must be in the body, not the spec."""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = os.path.join(tmpdir, 'test.bin')
            with open(test_file, 'wb') as f:
                f.write(b'\x00\x01\x02')

            spec, body = generate([test_file], tmpdir, 'Test_Bundle', None)

            # Spec should only have Register_All
            self.assertIn('Register_All', spec)
            self.assertNotIn('Storage_Array', spec)

            # Body should have the constants as decimal literals
            self.assertIn('Storage_Array', body)
            self.assertIn('0,1,2', body)
            self.assertIn('Register_All', body)
            self.assertIn('Adi.Assets.Register', body)

    def test_roundtrip(self):
        """Hex encoding should match original bytes."""
        with tempfile.TemporaryDirectory() as tmpdir:
            data = bytes(range(256))
            test_file = os.path.join(tmpdir, 'all_bytes.bin')
            with open(test_file, 'wb') as f:
                f.write(data)

            spec, body = generate([test_file], tmpdir, 'Test_Pkg', None)

            # Extract all decimal values from the body
            import re
            dec_vals = re.findall(r'\b(\d+)\b', body)
            # Filter: only values 0-255 that appear in the array literal
            # Find the array content between := and ;
            array_match = re.search(
                r'Storage_Array \(0 \.\. 255\) :=\s*\(([\s\S]*?)\);', body)
            self.assertIsNotNone(array_match)
            array_content = array_match.group(1)
            vals = [int(v.strip()) for v in array_content.split(',')]
            reconstructed = bytes(vals)
            self.assertEqual(reconstructed, data)

    def test_base_dir_stripping(self):
        """--base-dir should produce clean relative paths."""
        with tempfile.TemporaryDirectory() as tmpdir:
            sub = os.path.join(tmpdir, 'assets')
            os.makedirs(sub)
            test_file = os.path.join(sub, 'icon.svg')
            with open(test_file, 'wb') as f:
                f.write(b'<svg/>')

            spec, body = generate([test_file], tmpdir, 'B', sub)
            self.assertIn('"icon.svg"', body)
            self.assertNotIn('./', body)

    def test_multiple_files(self):
        """Multiple files should each get their own constant."""
        with tempfile.TemporaryDirectory() as tmpdir:
            f1 = os.path.join(tmpdir, 'a.bin')
            f2 = os.path.join(tmpdir, 'b.bin')
            with open(f1, 'wb') as f:
                f.write(b'\xAA')
            with open(f2, 'wb') as f:
                f.write(b'\xBB')

            spec, body = generate([f1, f2], tmpdir, 'Multi', None)
            self.assertIn('A_Bin_Data', body)
            self.assertIn('B_Bin_Data', body)
            self.assertIn('"a.bin"', body)
            self.assertIn('"b.bin"', body)


if __name__ == '__main__':
    unittest.main()
