# Layout Minimums

Two different questions, two different primitives. Confusing them is
what let flex containers crush labels until their text spilled out.

| Primitive | Question it answers |
|-----------|--------------------|
| `Get_Min_Size` | What minimum does this widget *demand*? Explicit CSS `min-width`/`min-height`, plus whatever a widget adds on its own behalf. |
| `Get_Content_Min_Size` | How small can this widget's *content* get before it misrenders? The min-content size. |
| `Get_Preferred_Size` | How big does it want to be? |

`Get_Content_Min_Size` is **advisory**. A widget reports its content
size and the parent decides what to do with it, because the rules
depend on the parent's axis and the child's own styling — knowledge the
child does not have.

## Automatic minimum size (flex)

CSS Flexbox [§4.5](https://www.w3.org/TR/css-flexbox-1/#min-size-auto)
says a flex item whose main-axis `min-width`/`min-height` is `auto` gets
a *content-based minimum size*:

```
automatic minimum = min (specified size suggestion, content size suggestion)
```

- **content size suggestion** — the item's min-content size in the main
  axis, i.e. `Get_Content_Min_Size`.
- **specified size suggestion** — the item's own `width`/`height` in the
  main axis, when definite. A declared size caps the floor: `height:
  10px` on a 19px-tall label means the label may shrink to 10px.
- The floor is **zero** when the item is its own scroll container in
  that axis (`overflow: auto`/`scroll`/`hidden`). It can scroll its own
  content, so it does not need room for all of it.
- It applies on the **main axis only**. There is no automatic floor
  across the cross axis.

The container's own `overflow` is irrelevant: the automatic minimum
belongs to the item.

Adi computes this in the parent's flex layout pass
(`Adi.Widget`, when populating `Flex_Child_Info`), never inside the
child.

## Which widgets override it

A widget overrides `Get_Content_Min_Size` when squeezing it below some
size makes its content render outside its own box:

- **Label** — longest word (or full text when `nowrap`) for width; the
  wrapped text height *at the width the label actually has* for height.
  Measuring height at the min-content width instead would report a
  one-word-per-line height and ratchet every ancestor's minimum up with
  it.
- **Containers** (`Box`) — children's content minimums, summed along the
  main axis and maxed across the cross axis, like `Get_Min_Size`.
- **Controls** with intrinsic chrome — their measured content.

Everything else inherits the default of zero, meaning "squeeze me
freely".

## Grid

CSS Grid's bare `1fr` is `minmax(auto, 1fr)`, so a track is not supposed
to shrink below its items' minimum contribution. Adi currently floors
`fr` tracks at zero (`Adi.Layout_Util`, pass 4) to stop content-sized
grids from overflowing their container, and
`tests/src/min_size_test.adb` locks that in. This is a known deviation:
an item with an explicit `min-width` inside a `1fr` track can be
allocated less than it asked for.
