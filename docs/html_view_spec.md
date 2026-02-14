# `Adi.Widget.Html_View` v1 Technical Spec

## Goals
- Render lightweight documentation-style HTML inside Adi widgets.
- Reuse existing Adi layout/style systems where practical, without browser-level complexity.
- Support clickable hyperlinks via `<a>` that invoke an application callback.

## Non-Goals
- No DOM API, JavaScript, navigation stack, forms, iframes, or script execution.
- No complex CSS selectors/combinators (v1 remains tag/class/id + inline style).
- No full HTML5 parsing compliance; deterministic, documented recovery rules are enough.

## Implementation Status
- Next-phase milestone completed on 2026-02-13.
- Renderer now uses an internal element tree (`Element`, `Text`, `Break`) with per-element attribute-driven cascade and line-box layout.
- Phase 2 milestone completed on 2026-02-14.
- Added line finalization alignment (`center` / `text-align`), html content scaling API, `vw`/`vh` support, block margin/padding flow participation, and expanded runtime parser support (`line-height`, `white-space`, `text-decoration`, `text-overflow`, `object-fit`, `visibility`).
- Temporary decoration workaround is active in `Adi.Widget` for `underline`, `line-through`, and `overline`.
  - Reason: current SDL_ttf renderer text engine can render decoration fill ops with white RGB for non-white text colors.
  - Upstream issue draft and patch are tracked in `deps/issues/sdl_ttf_text_decoration_color_issue.md` and `deps/issues/sdl_ttf_text_decoration_color.patch`.

## Supported Tags (v1)
- Block: `div`, `p`, `h1`, `h2`, `ul`, `ol`, `li`, `hr`, `center`
- Inline: `span`, `b`, `strong`, `em`, `code`, `a`, `img` (inline atomic box), `br`
- Unknown tags: transparent containers (children preserved and rendered).

## Attributes (v1)
- Common: `id`, `class`, `style`
- `img`: `src`, `alt`, `width`, `height`
- `a`: `href`, optional `title`

Attributes other than the above may be parsed and ignored.

## Public Widget API (Proposed)
Package: `Adi.Widget.Html_View`

- **Creation**
  - `function Create return Html_View_Access;`

- **Content**
  - `procedure Set_HTML (Self : in out Html_View; Source : String);`
  - `function Get_HTML (Self : Html_View) return String;`

- **Hyperlink callback**
  - ```ada
    type Link_Click_Callback is access procedure
      (Self : access Html_View;
       Href : String);
    procedure Set_On_Link_Click
      (Self     : in out Html_View;
       Callback : Link_Click_Callback);
    ```
  - Triggered on left-button release when pointer is still over the same link run.
  - If no callback is set, link clicks are ignored.

- **Asset loading callback (`img` resources)**
  - ```ada
    with Adi.Image;

    type Asset_Load_Callback is access function
      (Self : access Html_View;
       URI  : String)
       return Adi.Image.Image_Access;

    procedure Set_On_Load_Asset
      (Self     : in out Html_View;
       Callback : Asset_Load_Callback);
    ```
  - Resolution path for `img src`:
    1. If `On_Load_Asset` is set, call it first with the raw `src` value.
    2. If callback returns non-null, use returned image.
    3. If callback is null or returns null, image is treated as unavailable (render `alt` fallback if present).
  - Callback may implement custom URI schemes (e.g. `app://`, in-memory bundles, virtual FS).
  - Widget does not take ownership of callback internals; image lifetime follows normal `Adi.Image` ownership conventions.

- **Resource loading callback (`<link rel="stylesheet">`)**
  - ```ada
    type Resource_Load_Callback is access function
      (Self : access Html_View;
       URI  : String) return String;

    procedure Set_On_Load_Resource
      (Self     : in out Html_View;
       Callback : Resource_Load_Callback);
    ```
  - Used to resolve linked stylesheet resources by URI.
  - Invoked for `<link rel="stylesheet" href="...">` entries in HTML content.
  - Return empty string to indicate resource-not-found.
  - No file-system fallback is performed by the widget; resources are callback-owned.

- **Optional helper**
  - `procedure Clear (Self : in out Html_View);`

- **Content scale**
  - `procedure Set_Content_Scale (Self : in out Html_View; Scale : Pixel_Type);`
  - `function Get_Content_Scale (Self : Html_View) return Pixel_Type;`
  - Scale affects absolute/content units (`px`, `dip`, `em`, `rem`) and typography metrics.
  - Scale does not multiply `%`, `vw`, or `vh` resolution.

## Internal Model

### Parse Tree
- Parse source into a small normalized tree:
  - Node kinds: `Element_Node`, `Text_Node`, `Line_Break_Node`.
  - Element stores: tag kind, filtered attributes, inline style text, children.
- Tag names are ASCII case-insensitive (`DIV`, `Div`, `div` are equivalent).

### Layout Boxes
- Convert parse tree into layout boxes/runs:
  - Block box list for block tags.
  - Inline run sequence for text-level content.
  - Atomic inline items for `img` and inline `code` segments.
- `br` inserts a forced line break in the active inline context.
- `hr` creates a dedicated block separator box.

## Flow and Layout Rules

### Block Flow
- Parent block content is laid out top-to-bottom.
- Block width is container content width unless constrained by explicit width rules.
- Vertical margins/padding/border participate via existing style resolution.

### Inline Flow
- Inline content is line-wrapped by available width (similar to text widgets).
- Wrapping opportunities:
  - At collapsible whitespace boundaries.
  - Between runs with different styles.
  - Around atomic inline objects (`img`, `code` chunks when split is allowed by text wrapping).
- `br` always terminates current line and starts next line.

### Whitespace Normalization
- Outside `code`, consecutive ASCII whitespace collapses to a single space.
- Leading/trailing collapsible whitespace around block boundaries is trimmed.
- Newline characters in source are treated as collapsible whitespace.
- Inside `code`, whitespace is preserved (subject to clipping/wrapping policy below).

### `code` Behavior
- Render with monospace family if configured; otherwise fallback to current resolved family.
- Default tag style may include subtle background + small horizontal padding.
- Wrapping:
  - Default v1: permit wrapping at normal whitespace boundaries.
  - No horizontal scrolling in v1.

### Lists (`ul`/`ol`/`li`)
- Each `li` is a block row with marker area + content area.
- Marker rules:
  - `ul`: bullet marker (`•`).
  - `ol`: decimal markers (`1.`, `2.`, ...).
- Wrapped lines in an `li` align to the content area (not marker origin).
- Nesting increases indentation by a fixed style-driven step.

### `center`
- Treated as block container with default `text-align: center` for descendant inline formatting context.

## Hyperlink (`a`) Semantics
- `<a>` is an inline style/run container.
- Default visual style (overrideable): link color + underline.
- Hit-testing:
  - Each laid-out link fragment stores rect + `href`.
  - Hover state tracked per fragment for style resolution.
  - Click dispatch calls `On_Link_Click (Href)` once per completed click.
- Keyboard activation for links is out of scope for v1 unless the widget is later made focus-fragment aware.

## CSS and Cascade
- Style sources:
  1. Tag defaults (widget internal defaults)
  2. CSS extracted from embedded `<style> ... </style>` blocks
  3. CSS extracted from `<link rel="stylesheet" href="...">` resources (via callback)
  4. Tag/class/id selectors from parsed stylesheets
  5. Inline `style` attributes
- Implemented precedence: `defaults < tag < class < id < inline`.
- Inline style declarations are parsed once and cached by normalized declaration text.

### Runtime property coverage used by Html_View
- Typography/text flow: `font-size`, `font-weight`, `font-style`, `text-align`, `text-decoration`, `white-space`, `text-wrap-mode`, `text-overflow`, `line-height`.
- Box/layout basics: `display`, `margin*`, `padding*`, `width/height/min/max`, `overflow`.
- Visuals: `color`, `background-color`, `border*`, `box-shadow`, `opacity`, `visibility`.
- Images: `object-fit`.

## Unit Resolution Semantics
- Supported length units include: `px`, `dip`/`dp`, `em`, `rem`, `%`, `vw`, `vh`.
- For `Html_View`, `vw`/`vh` are resolved against the html content viewport.
- For normal widget styling, `vw`/`vh` are resolved against SDL window pixel size.

## Parser Recovery Rules
- Best-effort tree construction for malformed input.
- Unclosed tags auto-close at end of parent/document.
- Unexpected closing tag closes up-stack until match; if no match, ignore close token.
- Text outside known structure is preserved as text nodes.
- Entities supported in v1: `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`.
- Unknown entities remain literal text.

## Images (`img`) and `hr`
- `img`:
  - Source resolution is callback-driven through `Set_On_Load_Asset` (no widget-side filesystem fallback).
  - Missing/failed `src` load renders `alt` text when present, otherwise empty inline placeholder.
  - `width`/`height` attributes override intrinsic size when provided.
  - If only one dimension is provided, preserve intrinsic aspect ratio.
  - Final painted size is clamped by available line width (inline) or container width policy.
- `hr`:
  - Block element with default thin line style and vertical margins.
  - Implemented using standard box rendering primitives for themeability.

## Event Integration
- Pointer move updates hover fragment for links.
- Pointer down stores candidate link fragment.
- Pointer up on same fragment triggers callback.
- Non-link clicks are ignored by default and may bubble per normal widget behavior.

## Performance and Caching
- `Set_HTML` reparses and rebuilds internal run/tree caches, then marks widget dirty.
- Re-layout only when width or style-affecting state changes.
- Image cache is keyed by `src` within the widget instance to avoid repeated callback loads.
- Inline style declarations are cached to reduce repeated parse cost.

## Testing Coverage (`tests/src/html_view_test.adb`)
- Parsing and recovery:
  - Case-insensitive tag names, unknown tag transparency, malformed close handling.
  - Entity decoding for supported entities.
- Layout:
  - `div` nesting and block flow.
  - `span` inline overrides.
  - `br` forced line breaks.
  - `hr` block separator geometry.
  - `code` whitespace preservation and wrapping.
  - List marker placement and wrapped-line indentation.
- Styling/cascade:
  - `tag < class < id < inline style` precedence assertions.
- Line metrics:
  - mixed-inline baseline alignment and heading isolation checks.
- Alignment:
  - `center` and `text-align: center` geometry assertions.
- Inheritance:
  - body font-size inheritance checks for descendant text runs.
- Scaling and units:
  - html content scale behavior (`1.0` vs higher scales).
  - `vw`/`vh` context checks (active viewport and html-local viewport).
- Link behavior:
  - `<a href>` fragment hit-test mapping.
  - Click callback called with exact `href`.
  - No callback call when pointer down/up are on different fragments.
- Clipping:
  - visible clipped link fragments clickable, scrolled-out fragments not clickable.
- Image behavior:
  - Callback-first asset loading path and fallback path.
  - Missing source fallback (`alt` path).

## Implementation Milestones
1. Parser + normalized node model + recovery/entity handling.
2. Block/inline layout engine with list markers and line-break semantics.
3. Rendering integration (text, boxes, images, `hr`) with style cascade.
4. Link fragment hit-testing + callback dispatch.
5. Test suite and example program (`examples/html_view_example.adb`, optional in v1).

## Open Decisions (Default Choices)
- Link keyboard activation: defer to v2.
- Rich URL policy (`mailto:`, custom schemes): pass `href` string unchanged to app callback.
- Sanitization: widget is render-only; application decides trust and navigation policy in callback.
