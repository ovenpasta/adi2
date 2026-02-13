# HTML View Next Phase Plan (Completed Milestone)

This phase is now complete. The HTML view moved from a token-stream renderer to an element-driven model while staying lightweight and documentation-focused.

Milestone completed: 2026-02-13

## Delivered Goals

- Improved style correctness for mixed inline/block content with line-local metrics.
- Deterministic CSS cascade per element.
- Callback-only resource loading preserved for images and linked stylesheets.
- Stable rendering/input behavior under scrolling and overflow clipping.

## Delivered Scope

### 1) Element Tree + Attributes

- Added internal node model (`Element`, `Text`, `Break`) instead of direct token-only layout.
- Added per-element attributes used by the renderer:
  - `id`, `class`, `style`
  - `href` for links
  - `src`/`alt` for images
- Kept permissive recovery for malformed HTML.

### 2) CSS Cascade per Element

- Implemented per-element style resolution in this order:
  - internal defaults
  - tag selector
  - class selector(s)
  - id selector
  - inline `style`
- Kept support for embedded `<style>` and callback-loaded `<link rel="stylesheet">`.
- Added inline-style parse caching to avoid reparsing identical inline declarations.

### 3) Line-Box Layout Pass

- Added line-box layout with local ascent/descent/line-height handling.
- Isolated block boundaries so heading metrics do not leak into following paragraph lines.
- Kept deterministic wrapping around spaces, `br`, and inline images.

### 4) Interaction + Hit Testing

- Link hit regions are derived from final laid out run/image boxes.
- Click behavior remains press/release-on-same-link.
- Link hit regions are clipped to the visible content viewport.

### 5) Core Rendering Support

- Extended `Adi.Widget.Item` with optional explicit per-item style override.
- Html view now uses per-item resolved styles without part-style flattening.

## Tests and Validation

- Added targeted html tests in `tests/src/html_view_test.adb` for:
  - cascade precedence (`tag < class < id < inline`)
  - mixed-inline baseline alignment
  - heading metric isolation
  - clipping-aware link hit testing
  - callback-only resource loading (`img` and linked CSS)
- Stress corpus parsing/build remains green for `tests/html/*.html` malformed and nested cases.

## Example Coverage

- `examples/html_view_example.adb` remains the manual QA harness.
- Expanded `examples/assets/html_view_example.html` to exercise a wider feature set:
  - cascade layers, nested lists, unknown tags, inline formatting, links, images, and long scroll content.
