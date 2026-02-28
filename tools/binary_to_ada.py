#!/usr/bin/env python3
"""Convert binary files to Ada Storage_Array constants for asset bundling.

Usage:
    python3 tools/binary_to_ada.py \\
        --output-dir examples/generated/ \\
        --package-name Assets_Example_Bundle \\
        --base-dir examples/assets/ \\
        examples/assets/icons.svg examples/assets/happycat.png
"""

import argparse
import os
import re
import sys


def file_to_identifier(path: str) -> str:
    """Convert a file path to a valid Ada identifier.

    Replaces non-alphanumeric characters with '_', ensures it starts with
    a letter, and capitalizes word segments.
    """
    name = os.path.basename(path)
    # Replace non-alphanumeric with underscore
    ident = re.sub(r'[^a-zA-Z0-9]', '_', name)
    # Collapse multiple underscores
    ident = re.sub(r'_+', '_', ident)
    # Strip leading/trailing underscores
    ident = ident.strip('_')
    # Ensure starts with letter
    if ident and ident[0].isdigit():
        ident = 'F_' + ident
    if not ident:
        ident = 'Unknown'
    # Capitalize each segment
    parts = ident.split('_')
    ident = '_'.join(p.capitalize() for p in parts if p)
    return ident


def bytes_to_decimal_lines(data: bytes, bytes_per_line: int = 16) -> list[str]:
    """Convert bytes to Ada decimal literal lines."""
    lines = []
    for i in range(0, len(data), bytes_per_line):
        chunk = data[i:i + bytes_per_line]
        vals = ','.join(str(b) for b in chunk)
        lines.append('      ' + vals)
    return lines


def relative_key(filepath: str, base_dir: str | None) -> str:
    """Compute the bundle registration key for a file."""
    if base_dir:
        rel = os.path.relpath(filepath, base_dir)
        # Normalize to forward slashes
        rel = rel.replace('\\', '/')
        return rel
    return os.path.basename(filepath)


def generate(files: list[str], output_dir: str, package_name: str,
             base_dir: str | None) -> tuple[str, str]:
    """Generate Ada spec and body source strings."""
    entries = []
    for filepath in files:
        with open(filepath, 'rb') as f:
            data = f.read()
        key = relative_key(filepath, base_dir)
        ident = file_to_identifier(key) + '_Data'
        entries.append((key, ident, data))

    # Spec
    spec_lines = [
        f'pragma Ada_2022;',
        f'package {package_name} is',
        f'   procedure Register_All;',
        f'end {package_name};',
    ]

    # Body
    body_lines = [
        f'pragma Ada_2022;',
        f'with System.Storage_Elements; use System.Storage_Elements;',
        f'with Adi.Assets;',
        f'package body {package_name} is',
        f'',
    ]

    for key, ident, data in entries:
        size = len(data)
        body_lines.append(
            f'   {ident} : aliased constant Storage_Array (0 .. {size - 1}) :=')
        hex_lines = bytes_to_decimal_lines(data)
        for i, line in enumerate(hex_lines):
            if i == 0 and len(hex_lines) == 1:
                body_lines.append(f'     ({line.strip()});')
            elif i == 0:
                body_lines.append(f'     ({line.strip()},')
            elif i == len(hex_lines) - 1:
                body_lines.append(f'{line});')
            else:
                body_lines.append(f'{line},')
        body_lines.append('')

    body_lines.append('   procedure Register_All is')
    body_lines.append('   begin')
    for key, ident, data in entries:
        escaped_key = key.replace('"', '""')
        body_lines.append(
            f'      Adi.Assets.Register ("{escaped_key}", '
            f"{ident}'Address, {ident}'Length);")
    body_lines.append('   end Register_All;')
    body_lines.append(f'end {package_name};')

    spec = '\n'.join(spec_lines) + '\n'
    body = '\n'.join(body_lines) + '\n'
    return spec, body


def main():
    parser = argparse.ArgumentParser(
        description='Convert binary files to Ada Storage_Array constants')
    parser.add_argument('files', nargs='+', help='Input files')
    parser.add_argument('--output-dir', required=True,
                        help='Output directory for generated Ada files')
    parser.add_argument('--package-name', required=True,
                        help='Ada package name')
    parser.add_argument('--base-dir', default=None,
                        help='Base directory to strip from paths for keys')
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    spec, body = generate(args.files, args.output_dir, args.package_name,
                          args.base_dir)

    # Ada file naming: package name lowercased, dots to dashes
    base_name = args.package_name.lower().replace('.', '-')
    spec_path = os.path.join(args.output_dir, base_name + '.ads')
    body_path = os.path.join(args.output_dir, base_name + '.adb')

    with open(spec_path, 'w') as f:
        f.write(spec)
    with open(body_path, 'w') as f:
        f.write(body)

    print(f'[binary_to_ada] generated: {spec_path}')
    print(f'[binary_to_ada] generated: {body_path}')


if __name__ == '__main__':
    main()
