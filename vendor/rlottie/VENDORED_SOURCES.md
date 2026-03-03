Vendored upstream sources

- `rlottie/src/*`, `rlottie/inc/*` copied from:
  - https://github.com/Samsung/rlottie/tree/671c561130ead1c7e44805a7ec1263573a3440fd/src
  - https://github.com/Samsung/rlottie/tree/671c561130ead1c7e44805a7ec1263573a3440fd/inc
- `rlottie/licenses/*` copied from:
  - https://github.com/Samsung/rlottie/tree/671c561130ead1c7e44805a7ec1263573a3440fd/licenses
- `rlottie/src/config.h` is locally generated (not from upstream)

Local patches:
- `src/lottie/lottieparser.cpp`: Replace `strcpy_s` with `strncpy` for
  Windows XP compatibility (`strcpy_s` requires the MSVC secure CRT which
  is not available on Windows XP)

License files:
- `rlottie/COPYING` (MIT)
- `rlottie/licenses/` (third-party licenses for bundled dependencies)
