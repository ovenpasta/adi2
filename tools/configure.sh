#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/configure.sh --build-dir <dir> [--source-dir <dir>] [--pkg-config <bin>] [--cgpr <file>] [--target <linux|windows>] [--build-profile <development|validation|release>] [--svg-backend <ada|plutosvg>]

Generates build files in <build-dir> (no writes to source dir):
  <build-dir>/config/adi_linker_config.gpr
  <build-dir>/projects/adi_build.gpr
  <build-dir>/projects/tests_build.gpr
  <build-dir>/projects/examples_build.gpr
  <build-dir>/build_all.sh
EOF
}

BUILD_DIR=""
SOURCE_DIR=""
PKG_CONFIG_BIN="${PKG_CONFIG:-pkg-config}"
CGPR_FILE=""
TARGET_PLATFORM="linux"
BUILD_PROFILE_DEFAULT="development"
SVG_BACKEND_DEFAULT="plutosvg"

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
    --cgpr)
      shift
      CGPR_FILE="${1:-}"
      ;;
    --target)
      shift
      TARGET_PLATFORM="${1:-}"
      ;;
    --build-profile)
      shift
      BUILD_PROFILE_DEFAULT="${1:-}"
      ;;
    --svg-backend)
      shift
      SVG_BACKEND_DEFAULT="${1:-}"
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

BUILD_DIR="$(mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}" && pwd)"
mkdir -p "${BUILD_DIR}/config" "${BUILD_DIR}/projects"
mkdir -p "${BUILD_DIR}/adi/obj" "${BUILD_DIR}/adi/lib"
mkdir -p "${BUILD_DIR}/vendor/plutosvg/obj" "${BUILD_DIR}/vendor/plutosvg/lib"
mkdir -p "${BUILD_DIR}/vendor/rlottie/obj" "${BUILD_DIR}/vendor/rlottie/lib"
mkdir -p "${BUILD_DIR}/tests/obj" "${BUILD_DIR}/tests/bin"
mkdir -p "${BUILD_DIR}/examples/obj" "${BUILD_DIR}/examples/bin"

if [[ -n "${CGPR_FILE}" ]]; then
  if [[ ! -f "${CGPR_FILE}" ]]; then
    echo "--cgpr file not found: ${CGPR_FILE}" >&2
    exit 1
  fi
  CGPR_FILE="$(cd "$(dirname "${CGPR_FILE}")" && pwd)/$(basename "${CGPR_FILE}")"
fi

if [[ "${TARGET_PLATFORM}" != "linux" && "${TARGET_PLATFORM}" != "windows" ]]; then
  echo "--target must be either linux or windows" >&2
  exit 1
fi

if [[ "${BUILD_PROFILE_DEFAULT}" != "development" \
   && "${BUILD_PROFILE_DEFAULT}" != "validation" \
   && "${BUILD_PROFILE_DEFAULT}" != "release" ]]; then
  echo "--build-profile must be one of development, validation, release" >&2
  exit 1
fi

if [[ "${SVG_BACKEND_DEFAULT}" != "ada" \
   && "${SVG_BACKEND_DEFAULT}" != "plutosvg" ]]; then
  echo "--svg-backend must be either ada or plutosvg" >&2
  exit 1
fi

to_gpr_list() {
  local flags="$1"
  local -a tokens=()
  read -r -a tokens <<< "${flags}"
  if ((${#tokens[@]} == 0)); then
    printf "()"
    return
  fi
  printf "("
  local first=1
  local token
  for token in "${tokens[@]}"; do
    token="${token//\\/\\\\}"
    token="${token//\"/\\\"}"
    if ((first)); then
      first=0
    else
      printf ", "
    fi
    printf "\"%s\"" "${token}"
  done
  printf ")"
}

SDL_LIBS="-lSDL3 -lSDL3_ttf -lSDL3_image -lm"

if command -v "${PKG_CONFIG_BIN}" >/dev/null 2>&1; then
  SDL_LIBS=""

  if "${PKG_CONFIG_BIN}" --exists sdl3; then
    SDL_LIBS="${SDL_LIBS} $("${PKG_CONFIG_BIN}" --libs sdl3)"
  else
    SDL_LIBS="${SDL_LIBS} -lSDL3 -lm"
    echo "[configure] missing pkg-config module: sdl3 (fallback -lSDL3 -lm)"
  fi

  if "${PKG_CONFIG_BIN}" --exists sdl3-ttf; then
    SDL_LIBS="${SDL_LIBS} $("${PKG_CONFIG_BIN}" --libs sdl3-ttf)"
  else
    SDL_LIBS="${SDL_LIBS} -lSDL3_ttf"
    echo "[configure] missing pkg-config module: sdl3-ttf (fallback -lSDL3_ttf)"
  fi

  if "${PKG_CONFIG_BIN}" --exists sdl3-image; then
    SDL_LIBS="${SDL_LIBS} $("${PKG_CONFIG_BIN}" --libs sdl3-image)"
  else
    SDL_LIBS="${SDL_LIBS} -lSDL3_image"
    echo "[configure] missing pkg-config module: sdl3-image (fallback -lSDL3_image)"
  fi

else
  echo "[configure] pkg-config binary not found (${PKG_CONFIG_BIN}); using defaults"
fi

cat > "${BUILD_DIR}/config/adi_linker_config.gpr" <<EOF
abstract project Adi_Linker_Config is
   SDL_Linker_Switches := $(to_gpr_list "${SDL_LIBS}");
   Platform_Linker_Switches := ("-lm");
end Adi_Linker_Config;
EOF

cat > "${BUILD_DIR}/projects/plutosvg_build.gpr" <<EOF
project PlutoSVG_Build extends "${SOURCE_DIR}/vendor/plutosvg/plutosvg.gpr" is
   for Object_Dir use "${BUILD_DIR}/vendor/plutosvg/obj";
   for Library_Dir use "${BUILD_DIR}/vendor/plutosvg/lib";
   for Create_Missing_Dirs use "True";
end PlutoSVG_Build;
EOF

cat > "${BUILD_DIR}/projects/rlottie_build.gpr" <<EOF
project RLottie_Build extends "${SOURCE_DIR}/vendor/rlottie/rlottie.gpr" is
   for Object_Dir use "${BUILD_DIR}/vendor/rlottie/obj";
   for Library_Dir use "${BUILD_DIR}/vendor/rlottie/lib";
   for Create_Missing_Dirs use "True";
end RLottie_Build;
EOF

cat > "${BUILD_DIR}/projects/adi_build.gpr" <<EOF
with "plutosvg_build.gpr";
with "rlottie_build.gpr";

project Adi_Build extends "${SOURCE_DIR}/adi.gpr" is
   type Platform_Kind is ("linux", "windows");
   Platform_Name : Platform_Kind := external ("ADI_PLATFORM", "linux");
   type SVG_Backend_Kind is ("ada", "plutosvg");
   SVG_Backend : SVG_Backend_Kind := external ("ADI_SVG_BACKEND", "plutosvg");
   type Build_Profile_Kind is ("release", "validation", "development");
   Build_Profile : Build_Profile_Kind := external ("ADI_BUILD_PROFILE", "development");

   for Object_Dir use "${BUILD_DIR}/adi/obj";
   for Library_Dir use "${BUILD_DIR}/adi/lib";
   for Create_Missing_Dirs use "True";
end Adi_Build;
EOF

cat > "${BUILD_DIR}/projects/tests_build.gpr" <<EOF
with "adi_build.gpr";
with "../config/adi_linker_config.gpr";

project Tests_Build is
   type Test_Kind is
     ("styles",
      "layout_test",
      "layout_flex_grid_test",
      "css_parser_test",
      "css_source_test",
      "text_buffer_test",
      "text_layout_test",
      "html_view_test",
      "svg_test",
      "svg_perf_test",
      "disabled_test",
      "image_widget_test",
      "slider_test",
      "value_input_test",
      "svg_sprites_test",
      "min_size_test",
      "layout_perf_test",
      "style_storage_equivalence_test",
      "window_resize_safety_test",
      "mcp_test",
      "bundle_test",
      "signal_test",
      "dispatch_test",
      "i18n_test",
      "settings_test",
      "close_request_test",
      "window_handle_test",
      "text_editor_test",
      "handle_store_test",
      "widget_handle_test",
      "combo_box_item_test");
   Kind : Test_Kind := external ("TEST_KIND", "styles");

   for Source_Dirs use ("${SOURCE_DIR}/tests/src");
   for Object_Dir use "${BUILD_DIR}/tests/obj/" & Kind;
   for Exec_Dir use "${BUILD_DIR}/tests/bin";
   for Main use (Kind & ".adb");
   for Create_Missing_Dirs use "True";

   type Build_Profile_Kind is ("release", "validation", "development");
   Build_Profile : Build_Profile_Kind := external ("ADI_BUILD_PROFILE", "development");
   User_Ada_Compiler_Switches := External_As_List ("ADAFLAGS", " ");
   Profile_Ada_Compiler_Switches := ();
   case Build_Profile is
      when "release" =>
         Profile_Ada_Compiler_Switches := ("-O2", "-gnatn");
      when "validation" =>
         Profile_Ada_Compiler_Switches := ("-O2", "-g", "-gnata");
      when "development" =>
         Profile_Ada_Compiler_Switches := ("-Og", "-g", "-gnatwa", "-gnatw.X", "-gnatVa", "-gnatW8");
   end case;
   Ada_Switches := ("-gnat2022", "-gnatX0", "-gnatef");
   package Compiler is
      for Default_Switches ("Ada") use
        Profile_Ada_Compiler_Switches & User_Ada_Compiler_Switches & Ada_Switches;
   end Compiler;

   package Binder is
      for Switches ("Ada") use ("-E");
   end Binder;

   package Linker is
      for Default_Switches ("Ada") use
        Adi_Linker_Config.SDL_Linker_Switches &
        Adi_Linker_Config.Platform_Linker_Switches;
   end Linker;
end Tests_Build;
EOF

cat > "${BUILD_DIR}/projects/examples_build.gpr" <<EOF
with "adi_build.gpr";
with "../config/adi_linker_config.gpr";

project Examples_Build is
   type Example_Kind is
     ("label_example",
      "widget_demo",
      "button_example",
      "transition_example",
      "text_input_example",
      "text_editor_example",
      "demo_flex",
      "stack_example",
      "list_box_example",
      "combo_box_example",
      "overflow_example",
      "grid_example",
      "dialog_example",
      "font_example",
      "runtime_css_example",
      "animated_image_example",
      "rlottie_example",
      "html_view_example",
      "material_demo",
      "image_example",
      "assets_example",
      "gradient_example");
   Kind : Example_Kind := external ("EXAMPLE_KIND", "label_example");

   for Source_Dirs use ("${SOURCE_DIR}/examples", "${SOURCE_DIR}/examples/generated");
   for Object_Dir use "${BUILD_DIR}/examples/obj/" & Kind;
   for Exec_Dir use "${BUILD_DIR}/examples/bin";
   for Main use (Kind & ".adb");
   for Create_Missing_Dirs use "True";

   type Build_Profile_Kind is ("release", "validation", "development");
   Build_Profile : Build_Profile_Kind := external ("ADI_BUILD_PROFILE", "development");
   User_Ada_Compiler_Switches := External_As_List ("ADAFLAGS", " ");
   Profile_Ada_Compiler_Switches := ();
   case Build_Profile is
      when "release" =>
         Profile_Ada_Compiler_Switches := ("-O2", "-gnatn");
      when "validation" =>
         Profile_Ada_Compiler_Switches := ("-O2", "-g", "-gnata");
      when "development" =>
         Profile_Ada_Compiler_Switches := ("-Og", "-g", "-gnatwa", "-gnatw.X", "-gnatVa", "-gnatW8");
   end case;
   Ada_Switches := ("-gnat2022", "-gnatX0", "-gnatef");
   package Compiler is
      for Default_Switches ("Ada") use
        Profile_Ada_Compiler_Switches & User_Ada_Compiler_Switches & Ada_Switches;
   end Compiler;

   package Binder is
      for Switches ("Ada") use ("-E");
   end Binder;

   package Linker is
      for Default_Switches ("Ada") use
        Adi_Linker_Config.SDL_Linker_Switches &
        Adi_Linker_Config.Platform_Linker_Switches;
   end Linker;
end Examples_Build;
EOF

cat > "${BUILD_DIR}/build_all.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${SOURCE_DIR}"
BUILD_DIR="${BUILD_DIR}"
CGPR_FILE="${CGPR_FILE}"
TARGET_PLATFORM="${TARGET_PLATFORM}"
BUILD_PROFILE="${ADI_BUILD_PROFILE:-${BUILD_PROFILE_DEFAULT}}"
SVG_BACKEND="${ADI_SVG_BACKEND:-${SVG_BACKEND_DEFAULT}}"

GPR_ARGS=(-v -j0)
if [[ -n "\${CGPR_FILE}" ]]; then
  GPR_ARGS+=(--config="\${CGPR_FILE}")
fi

echo "[build_all] generate CSS Ada packages"
bash "\${SOURCE_DIR}/tools/generate_example_styles.sh"

echo "[build_all] generate XML Ada packages"
bash "\${SOURCE_DIR}/tools/generate_example_ui.sh"

echo "[build_all] build library"
gprbuild "\${GPR_ARGS[@]}" -P "\${BUILD_DIR}/projects/adi_build.gpr" -XADI_PLATFORM="\${TARGET_PLATFORM}" -XADI_BUILD_PROFILE="\${BUILD_PROFILE}" -XADI_SVG_BACKEND="\${SVG_BACKEND}"

TEST_KINDS=(
  styles
  layout_test
  layout_flex_grid_test
  css_parser_test
  css_source_test
  text_buffer_test
  text_layout_test
  html_view_test
  svg_test
  svg_perf_test
  disabled_test
  image_widget_test
  slider_test
  value_input_test
  svg_sprites_test
  min_size_test
  layout_perf_test
  style_storage_equivalence_test
  window_resize_safety_test
  mcp_test
  bundle_test
  signal_test
  dispatch_test
  i18n_test
  settings_test
  close_request_test
  window_handle_test
  text_editor_test
  handle_store_test
  widget_handle_test
  combo_box_item_test
)

for kind in "\${TEST_KINDS[@]}"; do
  echo "[build_all] build test: \${kind}"
  gprbuild "\${GPR_ARGS[@]}" -P "\${BUILD_DIR}/projects/tests_build.gpr" -XADI_PLATFORM="\${TARGET_PLATFORM}" -XADI_BUILD_PROFILE="\${BUILD_PROFILE}" -XADI_SVG_BACKEND="\${SVG_BACKEND}" -XTEST_KIND="\${kind}"
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
  html_view_example
  material_demo
  image_example
  slider_example
  value_input_example
  assets_example
  gradient_example
)

for kind in "\${EXAMPLE_KINDS[@]}"; do
  echo "[build_all] build example: \${kind}"
  gprbuild "\${GPR_ARGS[@]}" -P "\${BUILD_DIR}/projects/examples_build.gpr" -XADI_PLATFORM="\${TARGET_PLATFORM}" -XADI_BUILD_PROFILE="\${BUILD_PROFILE}" -XADI_SVG_BACKEND="\${SVG_BACKEND}" -XEXAMPLE_KIND="\${kind}"
done

echo "[build_all] complete"
EOF

chmod +x "${BUILD_DIR}/build_all.sh"

cat > "${BUILD_DIR}/BUILDING.md" <<EOF
# Build commands

gprbuild ${CGPR_FILE:+--config="${CGPR_FILE}"} -P "${BUILD_DIR}/projects/adi_build.gpr" -XADI_PLATFORM="${TARGET_PLATFORM}" -XADI_BUILD_PROFILE=${BUILD_PROFILE_DEFAULT} -XADI_SVG_BACKEND=${SVG_BACKEND_DEFAULT}
gprbuild ${CGPR_FILE:+--config="${CGPR_FILE}"} -P "${BUILD_DIR}/projects/tests_build.gpr" -XADI_PLATFORM="${TARGET_PLATFORM}" -XADI_BUILD_PROFILE=${BUILD_PROFILE_DEFAULT} -XADI_SVG_BACKEND=${SVG_BACKEND_DEFAULT} -XTEST_KIND=styles
gprbuild ${CGPR_FILE:+--config="${CGPR_FILE}"} -P "${BUILD_DIR}/projects/examples_build.gpr" -XADI_PLATFORM="${TARGET_PLATFORM}" -XADI_BUILD_PROFILE=${BUILD_PROFILE_DEFAULT} -XADI_SVG_BACKEND=${SVG_BACKEND_DEFAULT} -XEXAMPLE_KIND=font_example

One-command full build:
"${BUILD_DIR}/build_all.sh"
EOF

echo "[configure] source dir: ${SOURCE_DIR}"
echo "[configure] build dir: ${BUILD_DIR}"
echo "[configure] pkg-config: ${PKG_CONFIG_BIN}"
if [[ -n "${CGPR_FILE}" ]]; then
  echo "[configure] cgpr: ${CGPR_FILE}"
else
  echo "[configure] cgpr: (none)"
fi
echo "[configure] target: ${TARGET_PLATFORM}"
echo "[configure] build profile: ${BUILD_PROFILE_DEFAULT}"
echo "[configure] svg backend default: ${SVG_BACKEND_DEFAULT}"
echo "[configure] generated projects in ${BUILD_DIR}/projects"
echo "[configure] generated build script: ${BUILD_DIR}/build_all.sh"
