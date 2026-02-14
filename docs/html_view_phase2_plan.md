# HTML View Phase 2 Plan

## Summary

Phase 2 completes CSS/layout parity for `Adi.Widget.Html_View` and adds predictable scaling/viewport behavior:
- fix `center` / `text-align` behavior,
- add html content scaling,
- add `vw` / `vh`,
- improve runtime CSS parser coverage for text properties,
- improve inheritance and box-model behavior.

## Required Behavior Decisions

- Content scaling does not multiply `%`, `vw`, or `vh` results.
  - Rationale: `width: 100%` must keep fitting its container.
- `vw` / `vh` in `Html_View` use the html widget content viewport.
- `vw` / `vh` in normal widget styling use SDL window size.

## Work Items

### 1) Center and Text Alignment

- Implement horizontal line alignment during line finalization in html layout.
- Apply alignment offsets consistently to both rendered runs and link hit fragments.
- Ensure `<center>` and `text-align: center` produce centered output.

### 2) Runtime Parser Property Coverage

Add runtime CSS parser support used by html/text rendering for:
- `line-height`
- `white-space`
- `text-decoration`
- `text-overflow`
- `object-fit`
- `visibility`

### 3) Viewport Units (`vw`, `vh`)

- Extend CSS unit model with `vw` and `vh`.
- Extend runtime parser and `tools/css_to_ada.py` to parse/generate those units.
- Extend length conversion to accept viewport dimensions and context-specific defaults.

### 4) Html Content Scale API

Add API:
- `Set_Content_Scale (Self : in out Html_View; Scale : Pixel_Type)`
- `Get_Content_Scale (Self : Html_View) return Pixel_Type`

Behavior:
- default scale = `1.0`
- scales absolute/content units (`px`, `dip`, `em`, `rem`)
- does not scale `%`, `vw`, `vh`
- applies to text metrics, spacing lengths, and link hit geometry via final layout output

### 5) Inheritance and Defaults Cleanup

- Remove hardcoded defaults that block expected `body` typography inheritance.
- Keep semantic heading defaults while allowing normal CSS override semantics.
- Ensure glyph size and line-height are derived from the same resolved style path.

### 6) Box Model in Html Layout

- Apply block-level `margin`/`padding` in html flow.
- Keep inline box-model handling intentionally minimal in this phase.
- Preserve clipping/hit-testing correctness after spacing changes.

## Tests

Extend `tests/src/html_view_test.adb` with assertions for:
- center/text-align geometry,
- line-height parser + layout behavior,
- body-font inheritance behavior,
- html-local `vw`/`vh` behavior,
- content scaling behavior,
- clipping/hit-region behavior after alignment/scaling.

## Exit Criteria

- `<center>` and `text-align` are visually/test-wise correct.
- body font-size changes affect text and line metrics coherently.
- line-height and whitespace declarations are parsed and applied.
- `vw`/`vh` resolve correctly in html and normal widget contexts.
- content scaling works without breaking `%` fit semantics.
- html test suite remains green.
