#!/usr/bin/env bash
# Build Adi examples.
#
# Usage:
#   tools/build_examples.sh              # build all examples
#   tools/build_examples.sh stack_example # build one example
#   tools/build_examples.sh stack_example slider_example  # build several

set -euo pipefail

ALL_EXAMPLES=(
  label_example
  widget_demo
  button_example
  transition_example
  text_input_example
  text_editor_example
  demo_flex
  stack_example
  list_box_example
  combo_box_example
  overflow_example
  grid_example
  dialog_example
  font_example
  runtime_css_example
  animated_image_example
  rlottie_example
  html_view_example
  material_demo
  image_example
  slider_example
  value_input_example
  assets_example
  hello_example
  hello_raw_example
)

if [ $# -eq 0 ]; then
  EXAMPLES=("${ALL_EXAMPLES[@]}")
else
  EXAMPLES=("$@")
fi

FAILED=()

for ex in "${EXAMPLES[@]}"; do
  echo "=== Building $ex ==="
  if gprbuild -j0 -P examples/examples.gpr -XEXAMPLE_KIND="$ex"; then
    echo "    OK"
  else
    echo "    FAILED"
    FAILED+=("$ex")
  fi
done

echo ""
echo "=== ${#EXAMPLES[@]} example(s) processed ==="
if [ ${#FAILED[@]} -ne 0 ]; then
  echo "FAILED (${#FAILED[@]}): ${FAILED[*]}"
  exit 1
else
  echo "All succeeded."
fi
