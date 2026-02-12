#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  source tools/setup_pkg_config_env.sh
  source tools/setup_pkg_config_env.sh --with-rlottie

Exports:
  ADI_SDL_LINKER_FLAGS
  ADI_RLOTTIE_LINKER_FLAGS (optional, only when --with-rlottie is used)

If pkg-config is unavailable, this script leaves existing ADI_* env vars as-is and
falls back to default linker switches in the GPR files.
EOF
}

WITH_RLOTTIE=0
while (($#)); do
  case "$1" in
    --with-rlottie) WITH_RLOTTIE=1 ;;
    -h|--help) usage; return 0 2>/dev/null || exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      return 1 2>/dev/null || exit 1
      ;;
  esac
  shift
done

if ! command -v pkg-config >/dev/null 2>&1; then
  echo "[adi] pkg-config not found; using existing ADI_* env vars and GPR defaults."
  return 0 2>/dev/null || exit 0
fi

if pkg-config --exists sdl3 sdl3_ttf sdl3_image; then
  ADI_SDL_LINKER_FLAGS="$(pkg-config --libs sdl3 sdl3_ttf sdl3_image)"
  export ADI_SDL_LINKER_FLAGS
  echo "[adi] ADI_SDL_LINKER_FLAGS=$ADI_SDL_LINKER_FLAGS"
else
  echo "[adi] SDL pkg-config entries not found; using existing ADI_SDL_LINKER_FLAGS/GPR defaults."
fi

if ((WITH_RLOTTIE)); then
  if pkg-config --exists rlottie; then
    ADI_RLOTTIE_LINKER_FLAGS="$(pkg-config --libs rlottie)"
    export ADI_RLOTTIE_LINKER_FLAGS
    echo "[adi] ADI_RLOTTIE_LINKER_FLAGS=$ADI_RLOTTIE_LINKER_FLAGS"
  else
    echo "[adi] rlottie pkg-config entry not found; using existing ADI_RLOTTIE_LINKER_FLAGS/GPR defaults."
  fi
fi
