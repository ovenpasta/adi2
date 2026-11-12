#!/usr/bin/env bash
# Generate all example sources; also used by the examples crate's Alire pre-build hook.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for kind in styles ui bundles translations; do
  bash "$ROOT_DIR/tools/generate_example_${kind}.sh"
done
