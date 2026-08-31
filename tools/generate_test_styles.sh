#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/tools/css_to_ada.py"
CSS_DIR="$ROOT_DIR/tests/css"
OUT_DIR="$ROOT_DIR/tests/generated"

mkdir -p "$OUT_DIR"

generate_if_needed() {
  local css_file="$1"
  local out_file="$2"
  local package_name="$3"
  shift 3

  local out_body="${out_file%.ads}.adb"

  if [[ ! -f "$out_file" || ! -f "$out_body" \
     || "$css_file" -nt "$out_file" || "$GENERATOR" -nt "$out_file" ]]; then
    echo "[styles] generate: $(basename "$out_file")"
    python3 "$GENERATOR" "$css_file" "$out_file" --package-name "$package_name" "$@"
  else
    echo "[styles] skip:     $(basename "$out_file")"
  fi
}

generate_if_needed "$CSS_DIR/side_cascade.css" "$OUT_DIR/side_cascade_styles.ads" "Side_Cascade_Styles"
generate_if_needed "$CSS_DIR/auto_margin.css" "$OUT_DIR/auto_margin_styles.ads" "Auto_Margin_Styles"
generate_if_needed "$CSS_DIR/flat_values.css" "$OUT_DIR/flat_values_styles.ads" "Flat_Values_Styles"
generate_if_needed "$CSS_DIR/widget_property.css" "$OUT_DIR/widget_property_styles.ads" "Widget_Property_Styles" \
  --properties-package Test_Properties
generate_if_needed "$CSS_DIR/widget_property_static.css" "$OUT_DIR/widget_property_static_styles.ads" "Widget_Property_Static_Styles" \
  --properties-package Test_Properties
