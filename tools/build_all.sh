#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/build_all.sh --build-dir <dir> [--source-dir <dir>] [--pkg-config <bin>] [--gpr-config <file>]

Runs full build:
  1) tools/configure.sh
  2) tools/generate_example_styles.sh
  3) Library build
  4) All tests
  5) All examples
EOF
}

BUILD_DIR=""
SOURCE_DIR=""
PKG_CONFIG_BIN=""
GPR_CONFIG=""

while (($#)); do
  case "$1" in
    --build-dir)
      shift
      BUILD_DIR="${1:-}"
      ;;
    --source-dir)
      shift
      SOURCE_DIR="${1:-}"
      ;;
    --pkg-config)
      shift
      PKG_CONFIG_BIN="${1:-}"
      ;;
    --gpr-config)
      shift
      GPR_CONFIG="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ -z "${BUILD_DIR}" ]]; then
  echo "--build-dir is required" >&2
  usage
  exit 1
fi

if [[ -z "${SOURCE_DIR}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SOURCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
  SOURCE_DIR="$(cd "${SOURCE_DIR}" && pwd)"
fi

CONFIGURE_ARGS=(--build-dir "${BUILD_DIR}" --source-dir "${SOURCE_DIR}")
if [[ -n "${PKG_CONFIG_BIN}" ]]; then
  CONFIGURE_ARGS+=(--pkg-config "${PKG_CONFIG_BIN}")
fi

echo "[build_all] configure"
"${SOURCE_DIR}/tools/configure.sh" "${CONFIGURE_ARGS[@]}"

BUILD_DIR_ABS="$(cd "${BUILD_DIR}" && pwd)"

GPR_ARGS=()
if [[ -n "${GPR_CONFIG}" ]]; then
  GPR_ARGS+=(--config="${GPR_CONFIG}")
fi

echo "[build_all] generate CSS Ada packages"
bash "${SOURCE_DIR}/tools/generate_example_styles.sh"

echo "[build_all] build library"
gprbuild "${GPR_ARGS[@]}" -P "${BUILD_DIR_ABS}/projects/adi_build.gpr"

TEST_KINDS=(
  styles
  layout_test
  layout_flex_grid_test
  css_parser_test
  css_source_test
  text_buffer_test
  text_layout_test
)

for kind in "${TEST_KINDS[@]}"; do
  echo "[build_all] build test: ${kind}"
  gprbuild "${GPR_ARGS[@]}" -P "${BUILD_DIR_ABS}/projects/tests_build.gpr" -XTEST_KIND="${kind}"
done

EXAMPLE_KINDS=(
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
)

for kind in "${EXAMPLE_KINDS[@]}"; do
  echo "[build_all] build example: ${kind}"
  gprbuild "${GPR_ARGS[@]}" -P "${BUILD_DIR_ABS}/projects/examples_build.gpr" -XEXAMPLE_KIND="${kind}"
done

echo "[build_all] complete"
