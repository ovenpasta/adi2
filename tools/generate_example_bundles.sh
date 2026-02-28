#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/tools/binary_to_ada.py"
ASSETS_DIR="$ROOT_DIR/examples/assets"
OUT_DIR="$ROOT_DIR/examples/generated"

mkdir -p "$OUT_DIR"

OUT_FILE="$OUT_DIR/assets_example_bundle.adb"

# Check if regeneration is needed
needs_regen=0
if [[ ! -f "$OUT_FILE" ]]; then
  needs_regen=1
elif [[ "$GENERATOR" -nt "$OUT_FILE" ]]; then
  needs_regen=1
else
  # Check if any asset file is newer than the output
  for f in "$ASSETS_DIR"/icons.svg "$ASSETS_DIR"/happycat.png "$ASSETS_DIR"/OpenSans-Regular.ttf; do
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
    "$ASSETS_DIR/OpenSans-Regular.ttf"
else
  echo "[bundles] skip:     assets_example_bundle"
fi
