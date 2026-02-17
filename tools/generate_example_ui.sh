#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/tools/xml_to_ada.py"
XML_DIR="$ROOT_DIR/examples/xml"
OUT_DIR="$ROOT_DIR/examples/generated"

mkdir -p "$OUT_DIR"

generate_if_needed() {
  local xml_file="$1"
  local package_name="$2"
  local file_base
  file_base="$(echo "$package_name" | tr '[:upper:]' '[:lower:]')"
  local out_spec="$OUT_DIR/${file_base}.ads"
  local out_body="$OUT_DIR/${file_base}.adb"

  if [[ ! -f "$out_spec" || ! -f "$out_body" \
     || "$xml_file" -nt "$out_spec" \
     || "$GENERATOR" -nt "$out_spec" ]]; then
    echo "[ui] generate: ${file_base}.ads + .adb"
    python3 "$GENERATOR" "$xml_file" --output-dir "$OUT_DIR" --package-name "$package_name"
  else
    echo "[ui] skip:     ${file_base}.ads + .adb"
  fi
}

generate_if_needed "$XML_DIR/red_page.xml" "Red_Page_UI"
generate_if_needed "$XML_DIR/stack_example.xml" "Stack_Example_UI"
generate_if_needed "$XML_DIR/material_demo.xml" "Material_Demo_UI"
generate_if_needed "$XML_DIR/image_example.xml" "Image_Example_UI"
