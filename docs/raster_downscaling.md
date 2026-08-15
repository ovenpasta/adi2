# Raster Image Downscaling

## Problem

When a large raster image (e.g. 1280x720 JPG) is displayed at a small size
(e.g. 160x90), SDL3's single-pass bilinear filtering (`SDL_SCALEMODE_LINEAR`)
produces visible aliasing artifacts. Bilinear only samples 4 texels per output
pixel, so at an 8x downscale, 60 of every 64 source pixels are skipped entirely.

SDL3's 2D renderer has no mipmap support — only `SDL_SCALEMODE_NEAREST` and
`SDL_SCALEMODE_LINEAR`. There is no `SDL_SCALEMODE_BEST` or anisotropic option.

SVG images are unaffected: they re-rasterize at the exact target pixel size via
the SVG renderer, so they never alias on downscale.

## Proposed Solution: Cascaded Half-Size GPU Rendering

Use the SDL renderer's render-to-texture capability to progressively halve the
texture, with each pass using bilinear filtering over a 2x reduction (equivalent
to box-filter / mipmap level generation). Cache the final result per size.

### Algorithm

1. If downscale ratio <= 2x in both axes, skip cascading (single bilinear pass
   is adequate at this ratio).
2. Save the current render target (`SDL_GetRenderTarget`).
3. Set `SDL_SCALEMODE_LINEAR` on the source texture.
4. Loop: create a `SDL_TEXTUREACCESS_TARGET` texture at half dimensions, set it
   as render target, draw the previous texture with `SDL_BLENDMODE_NONE`. Destroy
   the previous intermediate.
5. Stop when within 2x of the target size.
6. Final pass: render to exact target dimensions.
7. Restore the original render target.
8. Set `SDL_BLENDMODE_BLEND` on the final texture for compositing and restore it
   on the source texture.
9. Store the final texture in the render context's `Adi.Texture_Cache` under
   the image's raster key, and hand the caller a lease on it.

### Key Design Points

- **`SDL_BLENDMODE_NONE` during intermediate passes**: Prevents alpha darkening
  against a black render-target background. Copies RGBA values directly.
- **`SDL_BLENDMODE_BLEND` restored after**: The rendering code in
  `Render_Image_Item` expects normal alpha compositing.
- **Half-size via `(W + 1) / 2`**: Rounds up, preventing zero-size textures.
- **Graceful fallback**: If any `SDL_CreateTexture` fails, fall back to the
  unscaled upload rather than caching a partial result.
- **Cache cleanup**: Nothing to add — the render context's cache owns every
  texture it is handed and destroys them on eviction and at teardown.

### Size Quantization

To avoid cache thrashing during continuous window resizing (where the target
size changes every frame), quantize `Target_W` and `Target_H` to an 8px grid:

```ada
Target_W := ((Target_W + 7) / 8) * 8;
Target_H := ((Target_H + 7) / 8) * 8;
```

The remaining <= 7px difference is handled by SDL's bilinear stretch at render
time, which is negligible at these small remainders.

### Files Involved

| File | Role |
|------|------|
| `src/adi-image.adb` | `Acquire_Texture` / `Build_Raster` — raster branch implementation |
| `src/adi-image.ads` | Public API (no signature changes needed) |
| `src/adi-sdl-render.ads` | All required SDL bindings already present |
| `src/adi-widget.adb` | Call site (`Render_Image_Item` line ~3186) — no changes needed |

### Required SDL Bindings (all already bound)

- `SDL_CreateTexture` with `SDL_TEXTUREACCESS_TARGET`
- `SDL_SetRenderTarget` / `SDL_GetRenderTarget`
- `SDL_SetTextureScaleMode` (`SDL_SCALEMODE_LINEAR`)
- `SDL_SetTextureBlendMode` (`SDL_BLENDMODE_NONE`, `SDL_BLENDMODE_BLEND`)
- `SDL_RenderTexture`
- `SDL_DestroyTexture`

## Known Issues and Future Improvements

### Cache growth with shared images

When a single `Image` is shared across multiple widgets (e.g. one photo shown at
4 different sizes), each size creates a separate cached texture. The cache is
unbounded (matching SVG behavior). For typical use this is fine, but a very large
number of distinct sizes from the same image could consume significant GPU memory.

Possible improvements:
- LRU eviction with a configurable max cache size
- Reference counting per cached entry
- Tolerance-based cache matching (accept a cached texture within N% of the
  target size rather than requiring an exact match)

### Render target switching mid-frame

The cascaded rendering switches the active render target during the widget tree's
render pass. While the previous target is saved and restored, this causes GPU
pipeline flushes. For images whose display size is stable (not animating or
resizing), this only happens once (on first render), then the cache serves
subsequent frames. During active resize, the quantization limits re-rendering
to at most once per 8px of movement.

A future improvement could defer the cascading to a separate pre-render pass
(before the widget tree render), avoiding mid-frame target switches.

### Pixel format

Intermediate textures use `SDL_PIXELFORMAT_ARGB8888`. If the source texture uses
a different format (e.g. RGB without alpha), there is a format conversion cost.
This is generally negligible since it only happens on cache miss.

## Prototype Branch

A working prototype is available on the `cascaded-downscaling` branch, including
a demo section in the image example showing bg.jpg (1280x720) at 4x, 8x, and
16x downscale ratios.
