Vendored upstream sources

From https://github.com/Samsung/rlottie at
`8de0d9e6ca80ffef654965505981727b9fa06a51`: `src/`, `inc/`, `licenses/`,
`COPYING`, `AUTHORS`.

- `src/config.h` is locally generated.
- `CMakeLists.txt`, `meson.build` and `src/wasm/` are not vendored; this
  tree builds through `rlottie.gpr`.
- `AUTHORS` is needed because `licenses/COPYING.MIT` reads "Copyright 2020
  (see AUTHORS)".

Local patches:

- `src/lottie/lottieparser.cpp`: `Canonicalize` copies with `std::memcpy`
  instead of `strcpy_s`, which needs the MSVC secure CRT that the Windows
  XP toolchain lacks. Keep upstream's preceding `out.size() >= PATH_MAX`
  guard — it is what bounds the copy, and without it the truncated path
  reaches `isResourcePathSafe`.

- `src/lottie/lottieitem.cpp`: `kMaxShapeContentBudget` 15000 → 100000.
  The eight Noto emoji in `examples/assets/` need 6164..70843; at 15000
  `noto_rocket.json` lost 91% of its pixels. Exhaustion drops content
  silently, since `vWarning` compiles out without `LOTTIE_LOGGING_SUPPORT`.
  Re-measure before lowering — there are no pixel goldens.

`src/vector/vinterpolator.cpp` is the only MPL-2.0 file here; upstream's
`COPYING` omits the mapping. Distributing a build containing it obliges
telling recipients how to obtain its source form, so any patch to it must
stay reachable for as long as the build is distributed.

Per-file licences are declared in `REUSE.toml` and generated into
`adi2.spdx`.
