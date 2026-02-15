# SVG Backend Report (2026-02)

## Current decision

- `plutosvg` is the default backend (`-XADI_SVG_BACKEND=plutosvg` in `adi.gpr`).
- The native Ada backend remains available (`-XADI_SVG_BACKEND=ada`) for continued development.

Reason for defaulting to `plutosvg` now:

- Better output smoothness on fine details.
- Better cold-render performance on large assets (notably `camera.svg` at 1024px).

## Repository state

- Vendored upstream:
  - `plutosvg/source/*`
  - `plutosvg/plutovg/source/*`
  - `plutosvg/plutovg/include/*`
- Project wiring:
  - `plutosvg/plutosvg.gpr`
  - `adi.gpr` depends on it and switches backend through `ADI_SVG_BACKEND`.
- Tests:
  - Correctness: `tests/src/svg_test.adb`
  - Performance: `tests/src/svg_perf_test.adb`
  - Comparison helper: `tools/compare_svg_perf.sh`

## Performance instrumentation model

`svg_perf_test` reports, per asset/size/backend:

- `cold_ms`: first render for the target size (no warm cache)
- `avg_ms`: repeated render average for same size
- `min_ms`, `max_ms`

Assets and sizes:

- Assets: `tests/assets/tiger.svg`, `tests/assets/camera.svg`
- Sizes: `64`, `128`, `256`, `512`, `1024`

Interpretation:

- `cold_ms` is the main metric for first-time display latency.
- `avg_ms` reflects repeated render behavior (same document/size).

## Ada backend status

Recent Ada-side work included:

- Default supersampling changed to `AA=1` (faster baseline, less smoothing than previous default).
- Path contour caching by `(path position, d text, transform key)`.
- Per-size rendered buffer cache in the backend cache layer.
- Raster hot-path improvements in blend/fill internals.

Known limitation:

- Visual smoothness is still below `plutosvg` in some small/fine-detail cases.
- Cold performance remains behind `plutosvg` for complex documents.

## Why Ada still differs from plutosvg

Main technical differences:

1. Rasterization strategy
   - `plutosvg/plutovg` uses an optimized analytic rasterizer path.
   - Ada backend currently relies on a different scanline implementation and does not fully match plutovg's coverage behavior.

2. Retained document/render model depth
   - `plutosvg` is designed around a retained parsed document + optimized renderer.
   - Ada backend still has heavier per-render traversal/cost for several operations.

3. Paint/compositing internals
   - Gradient/stroke composition and clipping in Ada are functionally correct for current tests but not yet as optimized as plutovg internals.

## Future work plan (Ada backend)

### Phase 1: quality parity baseline

- Implement analytic AA coverage strategy closer to plutovg.
- Revisit stroke edge/cap/join raster coverage to reduce jagged edges at small sizes.

### Phase 2: cold-render optimization

- Expand retained compiled representation (display-list style) to minimize per-render parsing/traversal work.
- Replace transient vector-heavy hot paths with preallocated arrays/pools where beneficial.

### Phase 3: paint/composition optimization

- Optimize gradient/stroke mask workflows to reduce extra full-buffer passes.
- Improve clipping and compositing path costs on large buffers.

### Phase 4: benchmarking/guardrails

- Keep `svg_perf_test` and `compare_svg_perf.sh` as regression guard.
- Add profile/backend result snapshots in CI artifacts (informational, non-gating).

## Operational guidance

- Use `plutosvg` backend for product/release builds now.
- Use Ada backend for ongoing implementation and quality/perf iteration.
- Re-evaluate default backend only after:
  - quality parity on small/fine-detail assets, and
  - competitive cold-render performance on `camera.svg`/`tiger.svg` at `1024`.
