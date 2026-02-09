#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/tools/css_to_ada.py"
CSS_DIR="$ROOT_DIR/examples/css"
OUT_DIR="$ROOT_DIR/examples/generated"

mkdir -p "$OUT_DIR"

generate_if_needed() {
  local css_file="$1"
  local out_file="$2"
  local package_name="$3"

  if [[ ! -f "$out_file" || "$css_file" -nt "$out_file" || "$GENERATOR" -nt "$out_file" ]]; then
    echo "[styles] generate: $(basename "$out_file")"
    python3 "$GENERATOR" "$css_file" "$out_file" --package-name "$package_name"
  else
    echo "[styles] skip:     $(basename "$out_file")"
  fi
}

generate_if_needed "$CSS_DIR/text_input_example.css" "$OUT_DIR/text_input_example_styles.ads" "Text_Input_Example_Styles"
generate_if_needed "$CSS_DIR/label_example.css" "$OUT_DIR/label_example_styles.ads" "Label_Example_Styles"
generate_if_needed "$CSS_DIR/widget_demo.css" "$OUT_DIR/widget_demo_styles.ads" "Widget_Demo_Styles"
generate_if_needed "$CSS_DIR/button_example.css" "$OUT_DIR/button_example_styles.ads" "Button_Example_Styles"
generate_if_needed "$CSS_DIR/demo_flex.css" "$OUT_DIR/demo_flex_styles.ads" "Demo_Flex_Styles"
generate_if_needed "$CSS_DIR/transition_example.css" "$OUT_DIR/transition_example_styles.ads" "Transition_Example_Styles"
generate_if_needed "$CSS_DIR/stack_example.css" "$OUT_DIR/stack_example_styles.ads" "Stack_Example_Styles"
generate_if_needed "$CSS_DIR/list_box_example.css" "$OUT_DIR/list_box_example_styles.ads" "List_Box_Example_Styles"
generate_if_needed "$CSS_DIR/combo_box_example.css" "$OUT_DIR/combo_box_example_styles.ads" "Combo_Box_Example_Styles"
generate_if_needed "$CSS_DIR/overflow_example.css" "$OUT_DIR/overflow_example_styles.ads" "Overflow_Example_Styles"
