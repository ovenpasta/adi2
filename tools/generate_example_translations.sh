#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$ROOT_DIR/tools/po_to_ada.py"
I18N_DIR="$ROOT_DIR/examples/i18n"
OUT_DIR="$ROOT_DIR/examples/generated"

mkdir -p "$OUT_DIR"

OUT_FILE="$OUT_DIR/i18n_example_translations.adb"

shopt -s nullglob
PO_FILES=("$I18N_DIR"/*.po)
shopt -u nullglob

if [[ ${#PO_FILES[@]} -eq 0 ]]; then
  echo "[translations] skip: no .po files found"
  exit 0
fi

# Check if regeneration is needed
needs_regen=0
if [[ ! -f "$OUT_FILE" ]]; then
  needs_regen=1
elif [[ "$GENERATOR" -nt "$OUT_FILE" ]]; then
  needs_regen=1
else
  for f in "${PO_FILES[@]}"; do
    if [[ "$f" -nt "$OUT_FILE" ]]; then
      needs_regen=1
      break
    fi
  done
fi

if [[ "$needs_regen" -eq 1 ]]; then
  echo "[translations] generate: i18n_example_translations"
  python3 "$GENERATOR" \
    --output-dir "$OUT_DIR" \
    --package-name I18N_Example_Translations \
    "${PO_FILES[@]}"
else
  echo "[translations] skip:     i18n_example_translations"
fi
