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
  button_example
  transition_example
  text_input_example
  text_editor_example
  demo_flex
  demo_block
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
  gradient_example
  hello_example
  hello_raw_example
  svg_example
)

if [ $# -eq 0 ]; then
  EXAMPLES=("${ALL_EXAMPLES[@]}")
else
  EXAMPLES=("$@")
fi

#  Regenerate example sources from their CSS/XML/asset/PO inputs. Each
#  script is incremental: it rewrites only what is out of date.
echo "=== Generating example sources ==="
bash tools/generate_example_styles.sh
bash tools/generate_example_ui.sh
bash tools/generate_example_bundles.sh
bash tools/generate_example_translations.sh

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
