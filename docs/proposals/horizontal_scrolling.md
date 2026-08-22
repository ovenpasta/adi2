# Horizontal Scrolling

Surveyed at `5a4c1b1`. Not implemented. This describes what exists, what
blocks it, and what implementing it would touch.

## Current state

A container carries one scroll axis. `Scroll_Offset_Y` and its supporting
fields are in `src/adi-widget.ads:940-948`; `Adi.Render` carries a single
`Scroll_Y` (`src/adi-render.ads:114-124`). There is no horizontal offset
anywhere.

Two things are further along than that suggests, and one is further behind.

**The X input path is complete.** SDL's wheel `x` reaches
`Adi.App` (`src/adi-app.adb:237`), `Adi.Window.On_Mouse_Wheel`
(`src/adi-window.adb:2500`), and `Adi.Widget.On_Mouse_Wheel`
(`src/adi-widget.adb:3188`), where `Handle_Scroll_Mouse_Wheel` discards it
at `src/adi-widget.adb:3074`, `pragma Unreferenced (Delta_X)`. The MCP
`scroll` tool's `dx` is plumbed the same distance
(`tools/adi_mcp_server.py:365`, `src/mcp/adi-mcp.adb:1153`) and stops at
the same line.

**`overflow-x` is live in shipped stylesheets.** `overflow: auto` is a
shorthand setting both axes (`src/adi-css_parser.adb:2022-2023`, mirrored
in `tools/css_to_ada.py:2926-2930`), and appears in
`combo_box_example.css:83`, `font_example.css:14`,
`html_view_example.css:95,126`, `material_demo.css:464`,
`material_demo_light.css:494` and `text_editor_example.css:107`. The
`Scrollable_X` branch of `Get_Preferred_Size`
(`src/adi-widget.adb:6771-6773`) therefore already suppresses
content-width reporting in those layouts, in favour of the min-width plus
chrome floor. `tests/src/min_size_test.adb:868-908` pins that behaviour.

**Block layout cannot produce horizontal overflow.** See below. This, not
the missing offset, is what the work consists of.

## The blocker

`Block_Child_Width` (`src/adi-widget-box.adb:255-257`) returns
`Inner_Width - margins` and never reads the child's declared `width`. It
is the single width source for measurement (`:312`), minimum aggregation
(`:1066`) and placement (`:1403`, `:1430`). A `width: 800px` child in a
400px container is laid out at 400.

So a `Scroll_Content_W` derived the way `Scroll_Content_H` is derived —
from child geometry, `src/adi-widget.adb:2537-2552` — equals the viewport
width by construction, `Max_Offset_X` is always zero, and
`Update_Scrollbar_Geometry`'s `Want_Bar` test (`:2480`) never fires under
`auto`. Under `scroll` the result is a full-length knob that cannot move.

The one thing that overflows a block container horizontally today is a
`nowrap` label drawing past its box (`docs/css_styling.md:234`). That
happens at item level and is invisible to any geometry-derived extent.

### What a horizontally scrollable block box needs

Two different measurements at once. They answer different questions and
neither substitutes for the other:

| Question | Primitive | Feeds |
|---|---|---|
| How wide is the scrollable canvas? | `Measure_Content (W)`, unconstrained | `Scroll_Content_W` |
| How wide is the viewport? | the content box | `Scroll_Viewport_W` |
| How tall is each child? | `Measure_At_Width (Child, canvas - margins)` | stacking and placement |

That is:

```
Canvas_W := max (Content_W, Measure_Content (W).Width)   -- when Scrollable_X
Block_Child_Width (Canvas_W, Margin)                     -- not Content_W
Scroll_Content_W := Canvas_W
Scroll_Viewport_W := Content_W
```

Children lay out against the canvas rather than the viewport. Heights are
still measured at the width a child is given, so `d7a6367` stands: a
`nowrap` label measured at canvas width reports one line, which is correct
for content that scrolls rather than wraps.

This is where the two axes stop being symmetric. `Scrollable_Y` suppresses
the preferred height a parent reads and block flow supplies the overflow
by itself. `Scrollable_X` suppresses the preferred width and nothing
supplies the overflow, so suppression is the whole of it.

## Machinery inventory

### Widget state, `src/adi-widget.ads`

| Location | Counterpart needed |
|---|---|
| `:940-948` offset, content, viewport, track, knob, show-bar, dragging, drag-offset, velocity | One of each. Dragging must stay per-axis: both bars can be grabbed in turn |
| `:333-340` `Set/Get_Scroll_Offset_Y`, `Scroll_By_Y`, `Get_Scroll_Content_Height`, `Get_Scroll_Max_Offset_Y`, each with a handle overload | Eight subprograms |
| `:467` dispatching `Get_Scroll_Content_Height` | A width primitive. Adding one is a breaking spec change for widgets registered through `Adi.Widget.Extension` |
| `:565` dispatching `On_Scroll_Changed (W; Old, New)` | A second hook, or an axis parameter that breaks every existing override |
| `:74-82, 848` `Scroll_Observer` / `Scroll_Changed` | Reusable unchanged: the signature carries no axis and observers re-read geometry |
| `:119-120` `Scroll_Part`, `Knob_Part` | See "Parts" below |

### Core logic, `src/adi-widget.adb`

| Location | Counterpart |
|---|---|
| `:2303-2312` `Supports_Scrollbar`, `Is_Scroll_Enabled` | Per axis. The `Scrollable` flag is axis-less — see S4 |
| `:2314-2326` clamp, max offset | Direct mirror |
| `:2358-2408` `Set_Scroll_Offset_Y` and its borrowing handle overload | Direct mirror; keep the borrow, observers may destroy the widget |
| `:2410-2454` `Resolve_Scrollbar_Metrics` | Reads `Scroll_Style.Width` (`:2421`) and `Knob_Style.Min_Height` (`:2445`); horizontally these are `Height` and `Min_Width` |
| `:2456-2524` `Update_Scrollbar_Geometry` | Track pins to the right edge (`:2499`); horizontally to the bottom. Neither contemplates two bars sharing a corner |
| `:2526-2562` `Update_Shared_Scroll_Layout` | Mirror does not work — see "The blocker" |
| `:1865-1903` `Get_Part_At` | Must test four rectangles |
| `:2971-3014` `Handle_Scroll_Mouse_Down` | Mirror; pages by `Content.Width * 0.9` |
| `:3016-3057` `Handle_Scroll_Mouse_Move` | Mirror; discards `Y` where the vertical form discards `X` |
| `:3059-3068` `Handle_Scroll_Mouse_Up` | Must clear the right axis's flag |
| `:3070-3089` `Handle_Scroll_Mouse_Wheel` | One line: consume `Delta_X` |
| `:3091-3133` `Tick_Scroll_Animations` | Mirror; the `Fast` decision (`:3129`) becomes an OR of both axes |
| `:6232-6241` `In_Render_Space` | Add the X shift and four call sites follow |
| `:6249-6422`, `:6500-6553` clipping, `:2255-2295` `Build_Content_Clip_Rect` | Already axis-symmetric. No change |
| `:6555-6567` scroll push/pop | Add the X pair |
| `:6424-6442` `Render_Shared_Scrollbar` | Paint the second pair |
| `:6900-6949`, `:7322-7327` `Axis_Minimum`, `Effective_Min_Size` | `Overflow_X` already zeroes the width minimum. No change |

### Window routing, `src/adi-window.adb`

| Location | Counterpart |
|---|---|
| `:1896-1918` `Ancestor_Scroll_Offset_Y`, `Map_Window_Point_To_Widget` | An X walk; delete the `pragma Unreferenced (X)` |
| `:1920-1935` `Geometry_In_Window`, `To_Window_Space` | Subtract the X offset — see S1 |
| `:1937-1945` `Mapped_Y` | Add `Mapped_X`, and pair it at all eight call sites (`:2058, 2178, 2293, 2303, 2317, 2378, 2394, 2460`) |
| `:1976-1982` `Find_Deepest` | Add the X shift |
| `:2048-2067` `Find_Scroll_Widget_At` | Needs `Mapped_X` and axis-distinguished parts |
| `:2497-2564` `On_Mouse_Wheel` | Target selection is axis-blind — see "Wheel routing" |

### Keyboard

There is no shared keyboard scrolling on either axis. What exists is
caret-driven and lives in the widgets: `Ensure_Row_Visible`
(`src/adi-widget-list_box.adb:370-406`), `Ensure_Caret_Visible`
(`src/adi-widget-text_editor.adb:172-198`). Keyboard scrolling is new work
for both axes, not a counterpart to anything.

### MCP

Nothing to add. `dx` is accepted, validated and forwarded
(`tools/adi_mcp_server.py:365,383-389`, `src/mcp/adi-mcp.adb:1153-1214`)
and documented (`docs/mcp.md`). It works the moment `:3074` consumes it.

## What generalises

Clean candidates for parameterising on an axis: the clamp and max-offset
arithmetic, `Set_Scroll_Offset`, `Scroll_By`, the momentum integrator,
`Handle_Scroll_Mouse_Move` and `Down`, `In_Render_Space` and the render
push/pop, the ancestor-offset walks, and the knob ratio and placement
maths. Clipping and the axis minimums are already generic.

The natural shape is a per-axis record held as an array, with the existing
vertical accessors kept as renamings so the public API and
`Adi.Widget.Extension` clients are untouched.

### Inherently one-axis

**Which property gives the bar its thickness.** Vertical reads `Width` and
`Min_Height`; horizontal reads `Height` and `Min_Width`. The `Edge_Pixels`
insets mean different edges per axis.

**The corner.** With both bars showing, each track must shorten by the
other's thickness or they overlap. There is no vertical original to
generalise from.

**Wheel routing.** `On_Mouse_Wheel` picks one target
(`src/adi-window.adb:2528`). The correct target for `Delta_X` and
`Delta_Y` can be different widgets — a horizontally scrolling row inside a
vertically scrolling page is the ordinary case. Two independent searches
with per-axis eligibility. Whether SDL delivers shift+wheel as `Delta_X`
or as `Delta_Y` with a modifier needs a runtime check.

**Parts.** Either add `Scroll_X_Part` and `Knob_X_Part`, which grows every
`Part_Kind`-indexed array (`Part_Resolved_Array`, `Part_State_Array`,
`Part_Transition_Array`, `Last_Target`, the global resolved-style memo
key) and touches `src/adi-css_parser.adb:1774-1775`,
`tools/css_to_ada.py`, `docs/css_styling.md` and `docs/mcp.md`; or reuse
the existing two, in which case hovering one knob sets `State_Hovered` on
a per-widget part and **both bars highlight together**, with no stylesheet
able to separate them. The first is the larger change and the only correct
one.

## Silent breakage

Each of these compiles and runs, and gives a wrong answer.

**S1. `Geometry_In_Window` corrects Y only** (`src/adi-window.adb:1920-1935`).
Callers that place things by it: the combo dropdown anchor
(`src/adi-widget-combo_box.adb:622-625`), which would detach from its
combo inside a horizontally scrolled container; `click_widget` and
`scroll` in `src/mcp/adi-mcp.adb:1130,1191,1205`, so MCP-driven clicks
land elsewhere and look like widget bugs.

**S2. Unpaired `Mapped_Y` call sites.** Eight of them map Y and pass raw
X. Adding an offset without pairing each gives hover on the wrong part and
mouse events at the wrong X.

**S3. The `> 0.0` guards** (`src/adi-window.adb:1980`,
`src/adi-widget.adb:6559`) encode an assumption that offsets are
non-negative, which holds only because the clamp floors at zero. RTL or
`row-reverse` content wants a negative horizontal offset. Decide before
implementing, not after.

**S4. The `Scrollable` flag is axis-less** (`src/adi-widget.ads:135`).
`Update_Shared_Scroll_Layout:2534-2536` sets it whenever scrolling is
enabled; `Is_Scroll_Enabled:2311` reads it back as "scrolls vertically".
Reusing it for X makes every `List_Box` and `Text_Editor` horizontally
scrollable, with a `Scrollable_X` preferred-width floor and X clipping.
This is the most likely silent regression in the change. Split the flag
first, as its own landing.

**S5. Six shipped stylesheets already take the `Scrollable_X` floor.**
Changing what `Scrollable_X` means moves them on the first frame.

**S6. `Html_View`'s `Origin_X` is inert but present**
(`src/adi-widget-html_view.adb:3037`). `Clipped` (`:3046-3058`) already
clips link regions on both axes, so a link scrolled out horizontally would
be clipped to zero width and stop answering clicks before any X offset
applied. `Document_Layout` (`src/adi-widget-html_view.ads:203-210`) has no
`Scroll_W` or `Viewport_W` and lays out at a fixed width.

**S7. `List_Box` grid-mode hit testing** (`src/adi-widget-list_box.adb:78-79`)
computes `Local_X` with no offset term beside a `Local_Y` that has one.

**S8. `Text_Editor` inherits X scrolling for free and cannot use it.** It
forwards both deltas to the shared handler (`:1308-1313`) but computes no
horizontal extent, and `Adi.Text_Layout.Position_At_Point`
(`src/adi-text_layout.ads:41-48`) takes a vertical offset only, so caret
placement would ignore any X offset.

**S9. `Text_Input`'s `Horizontal_Scroll` is not a model.**
`src/adi-widget-text_input.ads:161` applies it through
`Item.Text_Offset_X`, a per-item text-draw offset consumed at
`src/adi-widget.adb:5548`. It is not a subtree translation, is recomputed
from the caret each `Build_Items`, and undoes itself in hit testing by
hand (`:287`). It solves keeping a caret visible, not scrolling a
container.

**S10. `Adi.Widget.Stack` warns that scrolling is unsupported**
(`src/adi-widget-stack.adb:352-355`). The advice stays valid; the wording
would not.

**S11. `tests/src/window_resize_safety_test.adb:1889-1892` asserts X passes
through unchanged.** It would fail correctly, and must be replaced with
the two-axis contract rather than deleted.

## Scope

**A — offset, wheel, clipping, no scrollbar.** Around 410 lines across
`adi-render`, `adi-widget`, `adi-widget-box` and `adi-window`, plus
documentation. Land it in three parts, in this order:

1. Split the `Scrollable` flag. No behaviour change; removes S4 from the
   blast radius of everything after.
2. The canvas-width block layout, with no offset field at all. This is the
   hard part, is independently testable (`Scroll_Content_W >
   Scroll_Viewport_W`), and is where the six stylesheets move — landing it
   alone makes any regression attributable.
3. Offset, wheel, clip and coordinate mapping. Mechanical once (2) exists.

**B — scrollbar, drag, inertia, keyboard.** Around 500 lines on top,
including the part-kind expansion and its ripple through the CSS pipeline
and the style memo. Keyboard scrolling is new behaviour on both axes and
can steal PageUp/PageDown from `Text_Editor` and `List_Box` if routing is
not widget-first.

The offset is worthless without (2), and (2) is worth having alone: it is
the missing half of a `Scrollable_X` that already ships. Doing the offset
first produces a feature that demonstrably does nothing.

## If this is not implemented

`overflow-x: scroll|auto` is accepted, changes sizing, clips, and never
scrolls. Rejecting it at parse time is incoherent while the `overflow`
shorthand sets both axes and is the idiomatic way to ask for vertical
scrolling. Treating it as `hidden` would flip the six stylesheets from the
min-width floor to full content width and contradicts
`tests/src/min_size_test.adb:868-908`.

What remains is to say so. `docs/css_styling.md` should record that the
values parse, clip and take the floor but produce no offset, scrollbar or
wheel response, and that the `overflow` shorthand puts a container in that
state. A one-shot `Adi.Log.Warning` from `Update_Shared_Scroll_Layout`
naming `overflow-x: hidden` as the honest alternative follows the existing
`Warn_Unsupported_Stack_Scrolling` precedent
(`src/adi-widget-stack.adb:223-236`) and costs nothing in release, where
logging is compiled out.

## Open questions

These need a runtime check:

- Does SDL3 deliver shift+wheel as `Delta_X`, or as `Delta_Y` with a
  modifier? `src/adi-app.adb:237` reads `Integer_X` directly.
- Does `Measure_Content` terminate at a stable canvas width for a
  `Scrollable_X` container, or does the preferred-size cache key's
  geometry term (`src/adi-widget.adb:6735-6736`) let it ratchet pass over
  pass? This is the failure mode `d7a6367` fixed for percentages.
- How far do the six `overflow: auto` layouts actually move once the
  canvas basis lands.
- What two extra `Part_Kind` values cost across `Cached_Resolved`,
  `Last_Target`, `Part_Transition_Array` and the global memo on a large
  tree.
- Whether `Update_Shared_Scroll_Layout`'s use of `Pref.Height` as a floor
  (`src/adi-widget.adb:2542`) has a sensible width analogue, or would
  inflate the canvas past what is drawn.
