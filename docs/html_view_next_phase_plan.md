# HTML View Next Phase Plan

This phase focuses on moving from a token-stream renderer to an element-driven HTML/CSS model while keeping the widget lightweight and documentation-oriented.

## Goals

- Improve style correctness for mixed inline/block content.
- Make CSS application deterministic and closer to CSS cascade expectations.
- Preserve current callback-only resource loading model for images and linked stylesheets.
- Keep rendering and input stable under scrolling/overflow clipping.

## Scope

### 1) Element Tree + Attributes

- Introduce a small internal node model (`Element`, `Text`, `Break`) instead of direct token-only flow.
- Track per-element attributes needed in v1.5:
  - `id`, `class`, `style`
  - `href` for links
  - `src`/`alt` for images
- Keep parser recovery behavior permissive for malformed HTML.

### 2) CSS Cascade per Element

- Use `Adi.CSS_Parser` output to compute effective style in this order:
  - internal defaults
  - tag selector
  - class selector(s)
  - id selector
  - inline `style`
- Apply resolved styles to element parts (`main`, `label`, `indicator`, heading/code/inline emphasis parts) before layout.
- Keep support for embedded `<style>` and callback-loaded `<link rel="stylesheet">`.

### 3) Line-Box Layout Pass

- Build line boxes from inline runs so baseline, ascent/descent, and vertical metrics are line-local.
- Separate block spacing from inline metrics to prevent heading metrics from affecting following paragraph lines.
- Keep wrapping behavior deterministic for spaces, `br`, and inline images.

### 4) Interaction + Hit Testing

- Derive link hit regions from final laid out run boxes.
- Ensure click behavior remains press/release-on-same-link.
- Maintain clipping-aware interaction when content is partially visible.

### 5) Rendering + Clipping Validation

- Keep clipping centralized in base rendering (`Adi.Widget`) for overflow/scroll contexts.
- Validate that text and images clip consistently when partially out of viewport.
- Ensure no glyph truncation regressions from clip behavior.

## Tests

- Add targeted tests in `tests/src/html_view_test.adb` for:
  - cascade precedence (`tag < class < id < inline`)
  - baseline alignment in mixed inline styles
  - heading metrics isolation from subsequent normal paragraphs
  - clipping behavior for partially visible text and images
  - callback-only resource loading paths (`img` and linked CSS)

## Example Update

- Keep `examples/html_view_example.adb` as the manual QA harness.
- Continue using generated CSS package (`examples/css/html_view_example.css`) for non-content UI (root/tabs/editor/status + html-view main/scroll/knob).
- Keep content styling inside HTML via `<style>` and callback-linked stylesheet.

## Exit Criteria

- No baseline drift in mixed inline styling (`strong`, `em`, `code`, links).
- CSS precedence tests pass for tag/class/id/inline styles.
- Partial overflow clipping is correct for both text and images.
- `html_view_test` suite remains green and example behavior matches expected interactions.
