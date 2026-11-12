#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/tools/binary_to_ada.py"
ASSETS_DIR="$ROOT_DIR/examples/assets"
FONT="$ROOT_DIR/vendor/open-sans/static/OpenSans-Regular.ttf"
OUT_DIR="$ROOT_DIR/examples/generated"

mkdir -p "$OUT_DIR"

OUT_FILE="$OUT_DIR/assets_example_bundle.adb"

needs_regen=0
if [[ ! -f "$OUT_FILE" ]]; then
  needs_regen=1
elif [[ "$GENERATOR" -nt "$OUT_FILE" ]]; then
  needs_regen=1
else
  for f in "$ASSETS_DIR"/icons.svg "$ASSETS_DIR"/happycat.png "$FONT"; do
    if [[ -f "$f" && "$f" -nt "$OUT_FILE" ]]; then
      needs_regen=1
      break
    fi
  done
fi

if [[ "$needs_regen" -eq 1 ]]; then
  echo "[bundles] generate: assets_example_bundle"
  python3 "$GENERATOR" \
    --output-dir "$OUT_DIR" \
    --package-name Assets_Example_Bundle \
    --base-dir "$ASSETS_DIR" \
    "$ASSETS_DIR/icons.svg" "$ASSETS_DIR/happycat.png" \
    --named OpenSans-Regular.ttf "$FONT"
else
  echo "[bundles] skip:     assets_example_bundle"
fi
