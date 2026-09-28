#!/usr/bin/env bash
# Build all examples, or the named mains, through the examples Alire crate.
# Usage: tools/build_examples.sh [label_example ...]
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# A caller such as `alr exec -- tools/run_tests.sh` exports dependency
# prefixes for the root crate. Let Alire select the examples crate's own
# dependency locations; inherited prefixes otherwise conflict with them.
while IFS= read -r variable; do
  case "$variable" in
    *_ALIRE_PREFIX) unset "$variable" ;;
  esac
done < <(compgen -e)
cd "$ROOT_DIR/examples"
MAINS=()
for name in "$@"; do
  MAINS+=("${name%.adb}.adb")
done
alr build --profiles=adi2=development -- -j0 "${MAINS[@]}"
