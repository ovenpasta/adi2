#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/tools/css_to_ada.py"
CSS_DIR="$ROOT_DIR/examples/css"
OUT_DIR="$ROOT_DIR/examples/generated"

mkdir -p "$OUT_DIR"

python3 "$GENERATOR" "$CSS_DIR/text_input_example.css" "$OUT_DIR/text_input_example_styles.ads" --package-name Text_Input_Example_Styles
python3 "$GENERATOR" "$CSS_DIR/label_example.css" "$OUT_DIR/label_example_styles.ads" --package-name Label_Example_Styles
python3 "$GENERATOR" "$CSS_DIR/widget_demo.css" "$OUT_DIR/widget_demo_styles.ads" --package-name Widget_Demo_Styles
python3 "$GENERATOR" "$CSS_DIR/button_example.css" "$OUT_DIR/button_example_styles.ads" --package-name Button_Example_Styles
python3 "$GENERATOR" "$CSS_DIR/demo_flex.css" "$OUT_DIR/demo_flex_styles.ads" --package-name Demo_Flex_Styles
python3 "$GENERATOR" "$CSS_DIR/transition_example.css" "$OUT_DIR/transition_example_styles.ads" --package-name Transition_Example_Styles
python3 "$GENERATOR" "$CSS_DIR/stack_example.css" "$OUT_DIR/stack_example_styles.ads" --package-name Stack_Example_Styles
