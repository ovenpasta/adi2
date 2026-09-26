#!/usr/bin/env bash
# Build all demos, or the named mains, through the demos Alire crate.
# Usage: tools/build_demos.sh [label_example ...]
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/demos"
MAINS=()
for name in "$@"; do
  MAINS+=("${name%.adb}.adb")
done
alr build --profiles=adi2=development -- -j0 "${MAINS[@]}"
