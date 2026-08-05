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

CSS Grid's bare `Nfr` is `minmax(auto, Nfr)`, so a flexible track may not
shrink below its items' minimum contribution. Adi honours that floor:
each `fr` track records one, and track sizing allocates by flex factor,
freezes any track landing below its floor, and shares what is left among
those still flexible — repeating, because freezing one track shrinks the
pool for the others. Flex factors summing below 1 divide by 1, so a lone
`0.5fr` track takes half the space rather than all of it.

The floor comes from the item's *minimum* width, never from `Req_W`:
under visible overflow that carries the preferred width, and freezing on
it would pin wrapping content at its full unwrapped width.

When the floors together exceed the space available, every track freezes
and **the grid overflows**. That is the point of a minimum — one that
yields under pressure is not a minimum. `tests/src/min_size_test.adb`
covers the cascade (three `1fr` tracks in 300px with floors 150/90/0
settling at 150/90/60) and the overflow case.

Not yet implemented, and tracked as follow-up work:

- **Mixed-axis `overflow` normalisation depends on horizontal
  scrolling.** CSS computes a `visible` axis to `auto` when the other
  axis is not visible. Adi currently keeps both axes independent:
  `Overflow_X` and `Overflow_Y` are honoured exactly as written, and
  only the internal input clip (`Clips_Own_Content`, used by text
  inputs) covers both axes. Normalising them now would make
  `overflow-y: auto` discard the horizontal content minimum and clip
  horizontally, while Adi has no horizontal offset, scrollbar, or input
  path to reach that content. A probe reduced the minimum width from
  523px to 48px. Do not implement normalisation until horizontal
  scrolling exists end to end, or until a deliberately specified partial
  policy preserves horizontal reachability.
- **`flex-wrap` is inert.** The value is parsed, resolved and passed to
  `Flex_Layout_Context.Wrap`, but `Compute_Flex_Layout` lays out a single
  line and never reads it, so `wrap` and `nowrap` render identically.
- Indefinite preferred sizing still measures `fr` tracks from their
  minimum contribution, so a one-column `1fr` grid reports the same
  preferred and min-content width. CSS derives a common flex fraction
  from max-content contributions instead.
- Weighted tracks (`1fr 2fr`) need that common fraction rather than
  summing each track independently.
- Items spanning several tracks still divide their contribution equally,
  which breaks once tracks have different frozen bases.
- `minmax(0, Nfr)` has no representation in `Grid_Track_Spec`.
