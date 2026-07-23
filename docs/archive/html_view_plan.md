# Minimal HTML Documentation View (`Adi.Widget.Html_View`) — Updated Scope

## Summary
Keep the same plan, with these scope updates:
1. Add `div` as a first-class supported tag (essential block container).
2. Add extra low-complexity documentation tags: `span`, `br`, `hr`, `em`, `code`.
3. Keep parser/layout model minimal and non-browser-like.

## Supported Tags (v1)
1. Existing: `img`, `h1`, `h2`, `p`, `b`, `strong`, `center`, `ul`, `ol`, `li`
2. Added: `div`, `span`, `br`, `hr`, `em`, `code`

## Tag Behavior Additions
1. `div`:
   1. Generic block container (default `display:block`)
   2. Accepts `id`, `class`, `style`
   3. Children rendered in normal block flow

2. `span`:
   1. Inline container for run-level styles
   2. Merges into paragraph/run layout model (no standalone block widget)

3. `br`:
   1. Forced line break within current paragraph/run layout
   2. No box geometry beyond line advance

4. `hr`:
   1. Simple block separator line
   2. Implement as a `Box` with fixed small height and styleable border/background

5. `em`:
   1. Inline emphasis mapped to italic (`font-style: italic`)
   2. Same precedence/cascade behavior as `b/strong`

6. `code`:
   1. Inline code run (default monospace font handle if configured, fallback to current font)
   2. Optional default subtle background/padding via tag style

## CSS and Cascade (unchanged)
1. Full integration with existing `Adi.CSS_Parser`
2. Selector support in v1 remains single selectors: tag/class/id
3. Cascade order: tag < class < id < inline `style`

## Parser/Renderer Complexity Guardrails
1. Still no complex selectors/combinators
2. No hyperlinks/navigation/forms/scripts
3. Unknown tags remain transparent containers (children preserved)

## Test Additions
Add cases to `html_view_test` for:
1. `div` block nesting + class/id/style application
2. `span` inline style override inside paragraph
3. `br` line break behavior
4. `hr` rendered separator block
5. `em` italic rendering
6. `code` inline styling and wrapping behavior within paragraph

## Assumptions/Defaults
1. `code` uses a configurable/fallback font family (no hard dependency on external monospace asset).
2. `hr` default style is lightweight and overrideable through CSS.
3. `div` is essential and always supported in v1.
