#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/configure.sh --build-dir <dir> [--source-dir <dir>] [--pkg-config <bin>]

Generates build files in <build-dir> (no writes to source dir):
  <build-dir>/config/adi_linker_config.gpr
  <build-dir>/projects/adi_build.gpr
  <build-dir>/projects/tests_build.gpr
  <build-dir>/projects/examples_build.gpr
EOF
}

BUILD_DIR=""
SOURCE_DIR=""
PKG_CONFIG_BIN="${PKG_CONFIG:-pkg-config}"

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
mkdir -p "${BUILD_DIR}/tests/obj" "${BUILD_DIR}/tests/bin"
mkdir -p "${BUILD_DIR}/examples/obj" "${BUILD_DIR}/examples/bin"

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
RLOTTIE_LIBS="-lrlottie"

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

  if "${PKG_CONFIG_BIN}" --exists rlottie; then
    RLOTTIE_LIBS="$("${PKG_CONFIG_BIN}" --libs rlottie)"
  else
    echo "[configure] rlottie pkg-config entry not found; using defaults"
  fi
else
  echo "[configure] pkg-config binary not found (${PKG_CONFIG_BIN}); using defaults"
fi

cat > "${BUILD_DIR}/config/adi_linker_config.gpr" <<EOF
abstract project Adi_Linker_Config is
   SDL_Linker_Switches := $(to_gpr_list "${SDL_LIBS}");
   RLottie_Linker_Switches := $(to_gpr_list "${RLOTTIE_LIBS}");
   Platform_Linker_Switches := ();
end Adi_Linker_Config;
EOF

cat > "${BUILD_DIR}/projects/adi_build.gpr" <<EOF
project Adi_Build extends "${SOURCE_DIR}/adi.gpr" is
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
      "text_layout_test");
   Kind : Test_Kind := external ("TEST_KIND", "styles");

   for Source_Dirs use ("${SOURCE_DIR}/tests/src");
   for Object_Dir use "${BUILD_DIR}/tests/obj/" & Kind;
   for Exec_Dir use "${BUILD_DIR}/tests/bin";
   for Main use (Kind & ".adb");
   for Create_Missing_Dirs use "True";

   Ada_Switches := ("-gnat2022", "-gnatX0","-gnatef","-g", "-gnatwa", "-gnata");
   package Compiler is
      for Default_Switches ("Ada") use Ada_Switches;
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
   type Example_Kind is ("label_example", "widget_demo", "button_example", "transition_example", "text_input_example", "text_editor_example", "demo_flex", "stack_example", "list_box_example", "combo_box_example", "overflow_example", "grid_example", "dialog_example", "font_example", "runtime_css_example", "animated_image_example", "rlottie_example");
   Kind : Example_Kind := external ("EXAMPLE_KIND", "label_example");

   for Source_Dirs use ("${SOURCE_DIR}/examples", "${SOURCE_DIR}/examples/generated");
   for Object_Dir use "${BUILD_DIR}/examples/obj/" & Kind;
   for Exec_Dir use "${BUILD_DIR}/examples/bin";
   for Main use (Kind & ".adb");
   for Create_Missing_Dirs use "True";

   Ada_Switches := ("-gnat2022", "-gnatX0", "-gnatef", "-g", "-gnatwa", "-gnata");
   package Compiler is
      for Default_Switches ("Ada") use Ada_Switches;
   end Compiler;

   package Binder is
      for Switches ("Ada") use ("-E");
   end Binder;

   package Linker is
      case Kind is
         when "rlottie_example" =>
            for Default_Switches ("Ada") use
              Adi_Linker_Config.SDL_Linker_Switches &
              Adi_Linker_Config.RLottie_Linker_Switches &
              Adi_Linker_Config.Platform_Linker_Switches;
         when others =>
            for Default_Switches ("Ada") use
              Adi_Linker_Config.SDL_Linker_Switches &
              Adi_Linker_Config.Platform_Linker_Switches;
      end case;
   end Linker;
end Examples_Build;
EOF

cat > "${BUILD_DIR}/BUILDING.md" <<EOF
# Build commands

gprbuild -P "${BUILD_DIR}/projects/adi_build.gpr"
gprbuild -P "${BUILD_DIR}/projects/tests_build.gpr" -XTEST_KIND=styles
gprbuild -P "${BUILD_DIR}/projects/examples_build.gpr" -XEXAMPLE_KIND=font_example

Cross-target example:
gprbuild --config=path/to/target.cgpr -P "${BUILD_DIR}/projects/adi_build.gpr"
EOF

echo "[configure] source dir: ${SOURCE_DIR}"
echo "[configure] build dir: ${BUILD_DIR}"
echo "[configure] pkg-config: ${PKG_CONFIG_BIN}"
echo "[configure] generated projects in ${BUILD_DIR}/projects"
