# CSS Styling System

Adi uses a CSS-like styling system with two paths:

- **Compile-time** — `tools/css_to_ada.py` converts `.css` files into Ada constant packages
- **Runtime** — `Adi.CSS_Source` and `Adi.CSS_Parser` load and apply stylesheets dynamically, with optional live reload

Both paths use the same selector syntax, property set, and value types.

---

## Selectors

### Selector Types

| Syntax | Kind | Example |
|--------|------|---------|
| `.name` | Class | `.button { ... }` |
| `#name` | ID | `#root { ... }` |
| `name` | Tag | `label { ... }` |

Comma-separated selector groups are supported and expanded per selector:

```css
.primary, .secondary {
  border-radius: 8px;
}
```

### Part Selectors

Part selectors target sub-elements of a widget using `::part` pseudo-element syntax:

| Part | Constant | Typical Usage |
|------|----------|---------------|
| *(none)* / `::main` | `Main_Part` | Widget body (default when no part specified) |
| `::label` | `Label_Part` | Text label area |
| `::icon` | `Icon_Part` | Icon region |
| `::cursor` | `Cursor_Part` | Text cursor |
| `::selected` | `Selected_Part` | Selected item highlight |
| `::indicator` | `Indicator_Part` | Dropdown arrow, slider fill |
| `::scroll` | `Scroll_Part` | Scrollbar track |
| `::knob` | `Knob_Part` | Scrollbar/slider thumb |
| `::items` | `Items_Part` | Items container |

Example:

```css
.combo::label {
  color: rgb(15, 23, 42);
  font-size: 14px;
}

.combo::indicator {
  color: rgb(71, 85, 105);
}
```

### Property Inheritance Between Parts

Text and typography properties set on `Main_Part` (i.e., without a `::part` selector) automatically **inherit** to sub-parts (`::label`, `::icon`, etc.) when those sub-parts don't explicitly set the property. This matches CSS cascade semantics where text properties flow from parent to child.

**Inheritable properties:** `color`, `font-family`, `font-size`, `font-weight`, `font-style`, `text-align`, `vertical-align`, `text-decoration`, `text-overflow`, `text-wrap-mode`, `line-height`, `white-space`, `cursor`, `list-style-type`, `list-style-image`, `list-style-position`.

**Non-inheritable properties** (box-model, layout, visual): `background-color`, `background-image`, `border-*`, `outline-*`, `padding`, `margin`, sizing, `display`, `position`, `overflow`, `opacity`, `box-shadow`, `flex-*`, `grid-*`, `transition`, etc.

Example:

```css
/* font-size and color inherit to ::label and ::icon automatically */
.title { font-size: 24px; color: white; }

/* explicit ::label overrides the inherited color */
.title::label { color: yellow; }
```

The authoritative set of inheritable properties is defined by `Inheritable_Properties` in `adi-css_styles.ads`.

---

## Pseudo-Classes

### State Mapping

| CSS Pseudo-Class | Ada State | Notes |
|-----------------|-----------|-------|
| `:hover`, `:hovered` | `State_Hovered` | |
| `:active`, `:pressed` | `State_Pressed` | |
| `:focus`, `:focused` | `State_Focused` | |
| `:disabled` | `State_Disabled` | Inherited — applies when widget or any ancestor is disabled |
| `:enabled` | `When_Not(State_Disabled)` | Inherited — false when widget or any ancestor is disabled |
| `:checked`, `:selected` | `State_Selected` | |
| `:not(...)` | Negation | Single pseudo-class inside |

### Inherited Disabled State

The `:disabled` pseudo-class is **inherited through the widget hierarchy**. When a parent widget is disabled, all of its descendants are effectively disabled — both for interaction (no clicks, keyboard, or focus) and for visual styling (`:disabled` CSS rules apply).

- `Is_Disabled(W)` walks from `W` up through `W.Parent`, `W.Parent.Parent`, etc., returning `True` if any ancestor has `State_Disabled` set.
- `Get_States(W)` returns the widget's own states with `State_Disabled` injected when any ancestor is disabled. This is the state set used for CSS style resolution, so `:disabled` rules apply automatically to children of disabled containers.
- `Set_Disabled(W, True/False)` sets the widget's own `State_Disabled` flag and marks all descendants dirty so their styles are recomputed.
- A child that has its own `State_Disabled` flag set remains disabled even when its parent is re-enabled.

```ada
--  Disable an entire form container and all its children
Set_Disabled (Form_Box.all);

--  Re-enable the container; children without their own disabled flag
--  become enabled again
Set_Disabled (Form_Box.all, False);
```

### Placement Rules

Pseudo-classes can appear **before** or **after** a part selector, with different scoping:

**Before `::part`** — Widget-scoped state (the whole widget must be in that state):

```css
.combo:hover::indicator { color: blue; }     /* widget hovered → style indicator */
.list:hover::scroll { opacity: 1; }          /* widget hovered → show scrollbar */
```

**After `::part`** — Part-scoped state (the specific part must be in that state):

```css
.list::scroll:hover { background-color: gray; }   /* scroll track hovered */
.list::knob:pressed { background-color: black; }   /* knob being dragged */
```

For `::main`, interactive pseudos remain widget-scoped regardless of position:

```css
.button::main:hover { ... }   /* equivalent to .button:hover */
```

---

## Supported Properties

### Box Model

| Property | Values | Example |
|----------|--------|---------|
| `width` | length, `auto`, `fit-content` | `width: 200px;` |
| `height` | length, `auto`, `fit-content` | `height: 40px;` |
| `min-width` | length | `min-width: 100px;` |
| `max-width` | length | `max-width: 50%;` |
| `min-height` | length | `min-height: 24px;` |
| `max-height` | length | `max-height: 240px;` |
| `padding` | 1–4 lengths | `padding: 12px 24px;` |
| `padding-top/right/bottom/left` | length | `padding-left: 16px;` |
| `margin` | 1–4 lengths | `margin: 8px 0px;` |
| `margin-top/right/bottom/left` | length | `margin-top: 4px;` |

### Borders

| Property | Values | Example |
|----------|--------|---------|
| `border` | shorthand (width style color) | `border: 1px solid #ccc;` |
| `border-top/right/bottom/left` | side shorthand (width/style/color in any order) | `border-top: 2px dashed red;` |
| `border-width` | 1–4 lengths | `border-width: 1px;` |
| `border-top/right/bottom/left-width` | length | `border-left-width: 4px;` |
| `border-color` | color value | `border-color: rgb(200,200,200);` |
| `border-top/right/bottom/left-color` | color value | `border-left-color: red;` |
| `border-style` | `none`, `solid`, `dashed`, `dotted`, `double`, `groove`, `ridge`, `inset`, `outset`, `hidden` | `border-style: solid;` |
| `border-top/right/bottom/left-style` | same as `border-style` | `border-bottom-style: dotted;` |
| `border-radius` | 1–4 lengths | `border-radius: 8px;` |
| `border-top-left/top-right/bottom-right/bottom-left-radius` | single length/percent | `border-top-left-radius: 10px;` |

Runtime (`Adi.CSS_Parser`) and compile-time (`css_to_ada.py`) both support `border` shorthand and side/corner longhands with standard declaration order semantics (later declarations win).
For asymmetric corners, prefer `border-radius` shorthand when possible (for example, top-only rounding: `border-radius: 8px 8px 0px 0px;`) and use corner longhands only for targeted overrides.
Corner radius longhands currently accept a single value only (elliptical two-value corner syntax is not supported yet).

### Colors

| Property | Values | Example |
|----------|--------|---------|
| `color` | color value | `color: white;` |
| `background-color` | color value | `background-color: rgb(30, 41, 59);` |
| `opacity` | 0.0–1.0 | `opacity: 0.7;` |

### Typography

| Property | Values | Example |
|----------|--------|---------|
| `font-size` | length | `font-size: 16px;` |
| `font-weight` | `100`–`900`, `thin`, `extra-light`, `light`, `normal`, `medium`, `semi-bold`, `bold`, `extra-bold`, `black` | `font-weight: 700;` |
| `font-style` | `normal`, `italic`, `oblique` | `font-style: italic;` |
| `text-align` | `left`, `right`, `center`, `justify`, `start`, `end` | `text-align: center;` |
| `vertical-align` | `baseline`, `top`, `middle`, `bottom`, `text-top`, `text-bottom` | `vertical-align: middle;` |
| `text-decoration` | `none`, `underline`, `overline`, `line-through` | `text-decoration: underline;` |
| `line-height` | `normal`, number, length | `line-height: 1.5;` |
| `white-space` | `normal`, `nowrap`, `pre`, `pre-wrap`, `pre-line` | `white-space: nowrap;` |
| `text-overflow` | `clip`, `ellipsis` | `text-overflow: ellipsis;` |
| `text-wrap-mode` | `wrap`, `nowrap` | `text-wrap-mode: wrap;` |

### Layout & Display

| Property | Values | Example |
|----------|--------|---------|
| `display` | `none`, `block`, `inline`, `inline-block`, `flex`, `inline-flex`, `grid`, `inline-grid` | `display: flex;` |
| `position` | `static`, `relative`, `absolute`, `fixed`, `sticky` | `position: relative;` |
| `overflow` | `visible`, `hidden`, `scroll`, `auto` | `overflow: auto;` |
| `overflow-x` | `visible`, `hidden`, `scroll`, `auto` | `overflow-x: hidden;` |
| `overflow-y` | `visible`, `hidden`, `scroll`, `auto` | `overflow-y: auto;` |
| `visibility` | `visible`, `hidden`, `collapse` | `visibility: hidden;` |

`overflow` is treated as shorthand only: it sets both `overflow-x` and `overflow-y`.
Resolved styles store only axis values (`Overflow_X`, `Overflow_Y`), and normal CSS order/override rules apply.

### Flexbox Container

| Property | Values | Example |
|----------|--------|---------|
| `flex-direction` | `row`, `row-reverse`, `column`, `column-reverse` | `flex-direction: column;` |
| `flex-wrap` | `nowrap`, `wrap`, `wrap-reverse` | `flex-wrap: wrap;` |
| `justify-content` | `flex-start`, `flex-end`, `center`, `space-between`, `space-around`, `space-evenly` | `justify-content: center;` |
| `align-items` | `flex-start`, `flex-end`, `center`, `baseline`, `stretch` | `align-items: stretch;` |
| `align-content` | `flex-start`, `flex-end`, `center`, `space-between`, `space-around`, `stretch` | `align-content: center;` |
| `gap` | length | `gap: 12px;` |

### Flexbox Item

| Property | Values | Example |
|----------|--------|---------|
| `flex-grow` | number | `flex-grow: 1;` |
| `flex-shrink` | number | `flex-shrink: 0;` |
| `flex-basis` | `auto`, `content`, length | `flex-basis: 200px;` |
| `align-self` | `auto`, `flex-start`, `flex-end`, `center`, `baseline`, `stretch` | `align-self: center;` |
| `order` | integer | `order: -1;` |

### Grid

| Property | Values | Example |
|----------|--------|---------|
| `grid-template-columns` | track list or `repeat(N, size)` | `grid-template-columns: auto auto 1fr;` |
| `grid-template-rows` | column count or `repeat(N, ...)` | `grid-template-rows: repeat(2, 1fr);` |
| `grid-column` | start / span | `grid-column: 2;` |
| `grid-row` | start / span | `grid-row: 1 / span 2;` |

#### `grid-template-columns` track sizing

Column tracks can be specified as a space-separated list of sizing tokens, or via `repeat()`:

| Token | Meaning |
|-------|---------|
| `auto` | Column sizes to fit its content |
| `Xfr` | Column takes a fractional share of remaining space (e.g. `1fr`, `2fr`) |
| `Xpx` | Column has a fixed pixel width |
| `repeat(N, size)` | Expand `size` token N times |

Mixed forms are supported — `repeat(3, auto) 1fr` is equivalent to `auto auto auto 1fr`.

Examples:

```css
/* Three content-sized columns then one stretching column */
grid-template-columns: auto auto auto 1fr;

/* Two equal stretching columns */
grid-template-columns: repeat(2, 1fr);

/* Fixed sidebar + content area */
grid-template-columns: 200px 1fr;

/* Uniform 3-column grid (legacy form, same as repeat(3,1fr)) */
grid-template-columns: 3;
```

**Sizing semantics:**
- `auto` columns are sized to the maximum preferred width of their single-span children; they expand for `min-width` constraints.
- `fr` columns receive a proportional share of the space left after all `auto` and `px` columns are sized. During content measurement (e.g. when the grid is inside a flex parent and sized by its content), `fr` columns contribute their children's intrinsic minimum width — not the full preferred width. This follows CSS `minmax(auto, Xfr)` semantics: the grid is wide enough to display `fr` content at its minimum, but `fr` columns remain shrinkable so text can wrap when the container is constrained.
- The column count used by item placement (`Grid_Columns`) is always kept in sync with the track list length.

**Ada static form** (generated by `css_to_ada.py` and usable directly in Ada):

```ada
Grid_Column_Tracks => (Count => 4,
                       Tracks => [1 => (Track_Auto, 0.0),
                                  2 => (Track_Auto, 0.0),
                                  3 => (Track_Auto, 0.0),
                                  4 => (Track_Fr,   1.0),
                                  others => <>])
```

### Outline

Outline is drawn outside the border box without affecting layout — ideal for focus indicators.

| Property | Values | Example |
|----------|--------|---------|
| `outline` | shorthand (width style color) | `outline: 2px solid rgb(208, 188, 255);` |
| `outline-width` | length | `outline-width: 3px;` |
| `outline-style` | `none`, `solid`, `dashed`, `dotted` | `outline-style: solid;` |
| `outline-color` | color value | `outline-color: rgb(100, 200, 50);` |
| `outline-offset` | length | `outline-offset: 2px;` |

Unlike `border`, outline does not shift surrounding content and respects `border-radius` for rounded widgets.

### Visual Effects

| Property | Values | Example |
|----------|--------|---------|
| `box-shadow` | offset-x offset-y blur spread color | `box-shadow: 0 4px 12px rgba(0,0,0,0.2);` |
| `cursor` | `auto`, `default`, `pointer`, `text`, `move`, `not-allowed`, `wait`, `crosshair`, `grab`, `grabbing`, `ns-resize`, `ew-resize`, `nesw-resize`, `nwse-resize` | `cursor: pointer;` |

### Background Images

| Property | Values | Example |
|----------|--------|---------|
| `background-image` | `none`, `url(...)` | `background-image: url(bg.jpg);` |

Background images are resolved via `Adi.Assets.Get_Image` — the URI is looked up in the registered asset search paths. Register paths before widget creation:

```ada
Adi.Assets.Add_Path ("assets");
Adi.Assets.Add_Path ("assets/images", Scheme => "app");
```

Then use in CSS:

```css
.hero { background-image: url(hero.jpg); object-fit: cover; }
.icon-panel { background-image: url(app://panel-bg.png); }
```

Plain paths (e.g. `bg.jpg`) search directories registered with an empty scheme. Scheme URIs (e.g. `app://panel-bg.png`) search directories registered with that scheme.

Images are loaded as CPU surfaces and GPU textures are created lazily at render time — no renderer dependency at style/load time.

### Image Sizing

| Property | Values | Example |
|----------|--------|---------|
| `object-fit` | `fill`, `contain`, `cover`, `none`, `scale-down` | `object-fit: cover;` |
| `object-position` | `center`, keyword pairs (`left top`, `top center`, ...), or 1-2 length/percent offsets | `object-position: center center;` |

`object-position` intentionally supports the common forms above; advanced mixed edge-offset forms are currently rejected.

#### Tintable images

Images loaded with `Tintable => True` (via `Load_SVG_Path`, `Load_SVG_From_String`, or `SVG_Sprites.Get_Image`) are rendered white-on-transparent. The renderer automatically applies the resolved CSS `color` as a tint using SDL hardware color modulation (multiply). This lets standard CSS `color` — including `:hover` and class-based overrides — control icon color:

```css
.my-label::icon { color: #333; }
.my-label:hover::icon { color: #0088ff; }
```

Since `color` is an inheritable property, setting it on the widget makes `::icon` parts inherit it automatically:

```css
.toolbar-btn { color: #666; }
.toolbar-btn:hover { color: white; }
/* ::icon inherits the color */
```

### List Styling

| Property | Values | Example |
|----------|--------|---------|
| `list-style` | shorthand | `list-style: disc inside;` |
| `list-style-type` | `none`, `disc`, `circle`, `square`, `decimal`, custom string | `list-style-type: circle;` |
| `list-style-image` | `url(...)` | `list-style-image: url(icon.png);` |
| `list-style-position` | `outside`, `inside` | `list-style-position: inside;` |

### Transitions

| Property | Values | Example |
|----------|--------|---------|
| `transition` | property duration [easing] | `transition: background-color 200ms ease-out;` |

Transition syntax:

```css
transition: <property> <duration> [easing];
transition: background-color 200ms ease-out;
transition: all 300ms ease-in-out;
transition: color 150ms ease-out, background-color 150ms ease-out;
```

Animatable properties: `all`, `color`, `background-color`, `border-color`, `border-width`, `border-radius`, `padding`, `margin`, `opacity`, `box-shadow`, `font-size`.

Layout-affecting properties (`padding`, `margin`, `border-width`, `font-size`) trigger relayout during animation. Visual-only properties (`color`, `background-color`, `border-color`, `border-radius`, `opacity`, `box-shadow`) trigger repaint only, avoiding the cost of full relayout.

Easing functions: `linear`, `ease`, `ease-in`, `ease-out`, `ease-in-out`.

Duration formats: `100ms`, `0.3s`.

---

## Value Types

### Lengths

| Unit | Description |
|------|-------------|
| `px` | Pixels (default if no unit given) |
| `dip` / `dp` | Device-independent pixels |
| `em` | Relative to element font size |
| `rem` | Relative to root font size |
| `%` | Percentage of parent |
| `vw` | Viewport width percentage |
| `vh` | Viewport height percentage |

### Colors

| Format | Example |
|--------|---------|
| Named | `red`, `aliceblue`, `transparent` (140+ SVG color names) |
| Hex | `#RGB`, `#RRGGBB`, `#RRGGBBAA` |
| RGB | `rgb(255, 128, 0)` |
| RGBA | `rgba(255, 128, 0, 0.5)` |

Special keywords: `transparent`, `inherit`, `currentcolor`.

---

## Compile-Time Generation

### Invocation

```bash
python3 tools/css_to_ada.py input.css output.ads --package-name=My_Styles
python3 tools/css_to_ada.py input.css output.ads --package-name=My_Styles --strict
```

Incremental generation for all examples via `tools/generate_example_styles.sh`.

### Validation Modes

- **Default mode** (no `--strict`): unsupported properties, unsupported `::part` names, and invalid values produce warnings on `stderr`; generation continues.
- **Strict mode** (`--strict`): any warning-level diagnostic fails generation (exit code `1`) and no output file is written.

### Generated Code Structure

For each CSS selector, the generator produces three layers of constants:

**1. Style_Rules** — Individual style declarations per selector+state+part:

```ada
Button_Class_Base_Style : constant Style_Rules := (
   Display => Set (Inline_Flex),
   Background_Color => Set_Bg (RGB (59, 130, 246)),
   Border_Radius => Set (Radius (Px (6.0))),
   Padding => Set (CSS_Box (Px (12.0), Px (24.0))),
   Cursor => Set (Pointer),
   others => <>
);

Button_Class_Widget_Hovered_Style : constant Style_Rules := (
   Background_Color => Set_Bg (RGB (37, 99, 235)),
   others => <>
);
```

**2. Widget_Style** — Fluent builder combining base + state rules:

```ada
Button_Class_Widget : constant Widget_Style :=
  From (Button_Class_Base_Style)
  .On (When_State (State_Hovered), Button_Class_Widget_Hovered_Style)
  .On (When_State (State_Pressed), Button_Class_Widget_Pressed_Style)
  .Build;
```

**3. Part_Style_Array** — Bundle of all parts for a selector:

```ada
Button_Class_Part_Styles : constant Part_Style_Array := [
   Main_Part => (Style => Button_Class_Widget, Enabled => True),
   Label_Part => (Style => Button_Class_Label_Widget, Enabled => True),
   Icon_Part => (Style => Button_Class_Icon_Widget, Enabled => True),
   others => <>
];
```

### Naming Conventions

Generated constant names follow the pattern:

- `{Selector}_Class_{Part}_{State}_Style` — Style_Rules
- `{Selector}_Class_{Part}_Widget` — Widget_Style
- `{Selector}_Class_Part_Styles` — Part_Style_Array

For ID selectors, `_Class_` becomes `_Id_`; for tag selectors, `_Tag_`.

Repeated blocks for the same selector/state are merged with CSS ordering semantics (later declarations override earlier ones).

---

## Runtime CSS

### `Adi.CSS_Source` — High-Level API

`Adi.CSS_Source` unifies compile-time and runtime styling behind a single `Style_Source` object.

#### Modes

```ada
type Source_Mode is (Dynamic_Mode, Static_Mode);
```

- **Dynamic_Mode** — Load from files or strings, parse at runtime, optional live reload
- **Static_Mode** — Use precompiled `Part_Style_Array` constants from `css_to_ada.py`

#### Static Setup

```ada
Adi.CSS_Source.Set_Static_Entries (Source, [
   Adi.CSS_Source.Class_Entry ("button", Button_Class_Part_Styles),
   Adi.CSS_Source.Id_Entry ("root", Root_Id_Part_Styles),
   Adi.CSS_Source.Tag_Entry ("label", Label_Tag_Part_Styles)]);
```

Repeated entries for the same selector are merged in insertion order (later entries win).

#### Dynamic Loading

```ada
Adi.CSS_Source.Add_Dynamic_File (Source, "path/to/style.css", Success);
Adi.CSS_Source.Add_Dynamic_String (Source, CSS_String, Success);
Adi.CSS_Source.Reload_Dynamic (Source, Success);
Adi.CSS_Source.Clear_Dynamic_Entries (Source);
```

#### Mode Selection

```ada
Adi.CSS_Source.Set_Mode (Source, Dynamic_Mode, Success);
--  Falls back: if not Success, use Static_Mode
```

#### Binding Widgets

Binding attaches a widget to a selector. Styles are applied immediately and reapplied on reload.

```ada
--  Single class
Adi.CSS_Source.Bind_Class (Source, "button", Widget);

--  Multiple classes (space-separated, merged in order)
Adi.CSS_Source.Bind_Class (Source, "btn btn-primary", Widget);

--  Other selector kinds
Adi.CSS_Source.Bind_Id (Source, "root", Widget);
Adi.CSS_Source.Bind_Tag (Source, "label", Widget);

--  Composite selector (CSS specificity: tag < class < id)
Adi.CSS_Source.Bind_Selector_Set (Source, Widget,
   Tag_Name   => "button",
   Class_Name => "primary",
   Id_Name    => "submit");
```

When multiple class names are passed to `Bind_Class`, styles are looked up for each class individually and merged left-to-right (later classes override earlier ones for shared properties). This mirrors HTML's `class="base accent"` behavior.

#### Merging Part Styles

`Merge_Part_Styles` is available as a public function for combining style arrays outside the binding system:

```ada
Merged := Adi.CSS_Source.Merge_Part_Styles (Base_Styles, Override_Styles);
```

#### One-Off Application

```ada
Adi.CSS_Source.Apply_Class (Source, "button", Widget);
Adi.CSS_Source.Apply_Selector_Set (Source, Widget,
   Class_Name => "primary");
```

#### Live Reload

```ada
Adi.CSS_Source.Set_Auto_Reload (Source, True);

--  Call in your frame loop:
Adi.CSS_Source.Tick (Source, Reloaded, Success);
--  Reloaded = True if stylesheet changed and was reapplied
```

`Tick` checks file modification times and reloads + reapplies to all bound widgets when files change.

#### Error Handling

```ada
Error_Msg : constant String := Adi.CSS_Source.Get_Last_Error (Source);
```

Returns an empty string if no error.

### `Adi.CSS_Parser` — Low-Level API

Direct stylesheet loading and querying without the `Source` abstraction:

```ada
Sheet : Adi.CSS_Parser.Stylesheet;
Adi.CSS_Parser.Load_File (Sheet, "style.css", Success);
Adi.CSS_Parser.Load_String (Sheet, CSS_Content, Success);

if Adi.CSS_Parser.Has_Class (Sheet, "button") then
   Styles := Adi.CSS_Parser.Styles_For_Class (Sheet, "button");
end if;

Adi.CSS_Parser.Apply_Class (Sheet, "button", Widget);
Adi.CSS_Parser.Bind_Class (Sheet, "button", Widget);
Adi.CSS_Parser.Reload_If_Changed (Sheet, Reloaded, Success);
```

---

## Practical Guidance

### Flex Shrink for Structural Labels

Structural labels (titles, hints, panel headers) should set `flex-shrink: 0` to prevent text compression in constrained containers:

```css
.title { flex-shrink: 0; }
.hint { flex-shrink: 0; }
```

Interactive input rows should also use `flex-shrink: 0` when they need stable control height.

### Box Shadow Syntax

```css
box-shadow: 2px 4px 10px rgba(0, 0, 0, 0.25);           /* offset blur color */
box-shadow: 0 8px 16px 0 rgba(0, 0, 0, 0.15);           /* with spread */
box-shadow: none;                                          /* disable */
```

### Transition Syntax

When multiple transitions are comma-separated, the generator uses the first transition's duration and easing as the overall `Transition_Spec`, with the union of all listed properties:

```css
/* All three properties animate with 180ms ease-out */
transition: border-color 180ms ease-out,
            box-shadow 180ms ease-out,
            background-color 180ms ease-out;
```

### Interactive Part Styling Pattern

For widgets with interactive sub-parts (scrollbars, dropdown indicators), use part-scoped pseudos:

```css
.dropdown::scroll { background-color: rgba(148, 163, 184, 0.22); }
.dropdown::scroll:hover { background-color: rgba(148, 163, 184, 0.42); }
.dropdown::scroll:pressed { background-color: rgba(148, 163, 184, 0.58); }
.dropdown::knob { background-color: rgba(71, 85, 105, 0.85); }
.dropdown::knob:hover { background-color: rgba(51, 65, 85, 0.95); }
.dropdown::knob:pressed { background-color: rgba(30, 41, 59, 1.0); }
```

---

## Limitations

- **No descendant/child combinators** — `.parent .child` and `.parent > .child` are not supported
- **No attribute selectors** — `[type="text"]` is not supported
- **No `@media` queries** — No responsive breakpoints
- **No CSS variables** — `var(--custom)` is not supported
- **No multiple box-shadows** — Only one shadow per rule
- **Single font-family** — Font loading uses `Font_Handle`; CSS `font-family` is not parsed
- **Grid rows not track-sized** — `grid-template-rows` sets an explicit row count; per-row sizing tokens (`auto`, `fr`, `px`) are not yet supported for rows
- **No named grid lines** — `[line-name]` syntax is not supported
- **Max 16 tracks** — `grid-template-columns` track lists are capped at 16 entries; wider grids fall back to equal-column distribution
- **First transition wins** — Comma-separated transitions use the first entry's timing for all properties
- **No `!important`** — Specificity follows tag < class < id ordering only
