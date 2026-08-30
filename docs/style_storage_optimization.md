# Internal Style Storage Optimization

## Scope

This document describes the internal style-system refactor in `Adi.Widget` that reduces memory usage and style-resolution overhead without changing user-facing APIs.

Public APIs are unchanged:
- `Part_Style`
- `Part_Style_Array`
- `Set_Part_Style`
- `Set_Part_Styles`
- CSS parser/source interfaces and generated CSS Ada usage

Only private/internal representation and resolution plumbing changed.

## Design Summary

The optimization has four internal layers:

1. Handle-based per-widget style storage
2. Prepared rule-order evaluation
3. Global resolved-style memo cache
4. A store of distinct resolved styles, which the memo and every widget
   name by handle

### 1) Handle-Based Storage

Each widget part now stores:
- `Part_Style_Handles : array (Part_Kind) of Style_Handle`
- `Part_Style_Enabled : array (Part_Kind) of Boolean`

Instead of embedding full `Widget_Style` payloads per part inside each widget record.

`Style_Handle = 0` is reserved for `Empty_Widget_Style`.

An internal interning store maps unique `Widget_Style` values to stable handles:
- `Intern_Style`
- `Style_From_Handle`

This keeps public APIs the same while deduplicating identical style payloads across widgets.

### 2) Prepared Rule Order

Interned style entries carry precomputed metadata:
- stable pre-sorted rule order
- effective priority = explicit `Priority` or selector `Specificity`
- source-order tie behavior preserved

Runtime style computation uses `Compute_Style_Prepared` and no longer sorts rules per call.

### 3) Global Resolved-Style Memo

The existing per-widget resolved-style cache remains, and a global cache is added as a second memoization layer.

Global cache key includes:
- part style handle
- effective main-part handle
- packed widget states
- packed part states
- packed main-part states

The element is a `Resolved_Handle` into the resolved-style store, so an
entry costs its key and eight bytes.

Policy:
- bounded capacity (`32_768` entries)
- on overflow: clear cache
- cleared as well when the store's generation moves, since the handles
  it holds name entries the store has let go

This keeps behavior deterministic and bounded while capturing cross-widget repetition.

## Behavioral Invariants

The refactor preserves existing semantics:
- `Any_Part` fallback behavior is unchanged.
- Part `Enabled` semantics are unchanged.
- Sub-part inheritance from `Main_Part` remains unchanged.
- CSS merge/apply/source behavior remains unchanged.

Assumptions:
- Widget/style mutation paths are effectively single-threaded.
- Interned styles are immutable after insertion.

## Validation

Existing suite (unchanged) remains green:
- `styles`
- `layout_test`
- `layout_perf_test`
- `css_parser_test`
- `min_size_test`
- `disabled_test`
- `html_view_test`
- `image_widget_test`

Added targeted regression test:
- `tests/src/style_storage_equivalence_test.adb`

Coverage in the new test:
- `Any_Part` fallback and part override parity
- enabled/disabled part storage parity
- rule priority and equal-priority tie-order behavior
- dynamic style churn via repeated selector rebinding

## Observed Results

Measured with GNAT representation output (`-gnatR3`) for style-related fields:
- previous embedded `Part_Style_Array`: `1,543,168 bits` (`192,896 bytes`)
- new embedded handle+enabled arrays: `440 bits` (`55 bytes`)
- per-widget style payload reduction: `192,841 bytes` (~`99.97%`)

`layout_perf_test` behavior checks (style cache hit/miss + invalidation) remain green.  
Single-run wall-clock timing is very small (about `0.01s`) and should be treated as noise-level for CPU conclusions; use repeated runs when comparing microbenchmark deltas.

---

## Interned Registered Selectors

Widgets hold style handles, but a `Style_Source` held its registered
selectors by value. `Adi.CSS_Source.Static_Style_Entry` embedded a
`Part_Style_Array`, and so did `Adi.CSS_Parser.Stylesheet_Metadata`
through `Root_Styles`.

A `Part_Style_Array` is twelve `Part_Kind` slots, each a `Widget_Style`
carrying a fixed `State_Rule_Array (1 .. 16)`.

`'Max_Size_In_Storage_Elements` on x86-64 Linux, which is what a vector
element or a heap allocation of one costs. A 32-bit build differs, and
the sizes below are not what `'Size` reports for the same types:

| | bytes |
|---|---|
| `Widget_Style` | 20,008 |
| `Part_Style_Array` | 239,840 |
| a registered or parsed selector, by value | 239,864 |
| the same, interned | 120 |

The cost is paid per selector, per source, and again per source in
`Applied_Statics`. An application that creates one `Style_Source` per
generated UI package registers the same generated table from each of
them, so a 221-selector sheet across 22 sources cost about 1.2 GB once
and 2.4 GB with `Applied_Statics` — over the address space of a 32-bit
build, and about five seconds of `Same_As_Applied` on top.

### What changed

- `Adi.Widget.Interned_Part_Styles` — a `Part_Style_Array` stored once
  and referred to by handle, with `Intern` and `Expand`. Interning is
  canonical, so equality on it is value equality.
- `Static_Style_Entry.Styles` holds one of these. `Selector_Styles`
  expands before merging, which is where a real `Part_Style_Array` was
  already being built.
- `Style_Source_Impl` keeps a `Root_Fingerprint` rather than a second
  `Stylesheet_Metadata`, so `Same_As_Applied` compares handles.
  `Stylesheet_Metadata` itself is unchanged, so generated stylesheets
  are unaffected.

Measured on the workload above, RSS growth for registration fell from
1,159 MB to 17.6 MB, and the registration itself from 1.24 s to 0.59 s.

### Interning has to be hashed

`Intern_Style` scanned the whole store comparing whole `Widget_Style`s.
That was tolerable at one call per widget styling; interning at
registration raises it by orders of magnitude. Handles are now grouped
by `Adi.Widget_Styles.Hash`, and the map is keyed by hash rather than by
style so it does not hold a second copy of each.

`Style_Rules` cannot be hashed as bytes. Its properties are
discriminated `Optional` records whose inactive variants hold
indeterminate bytes. Two equal styles built by separate calls share
none of those bytes, so a byte digest splits them and the
deduplication silently disappears for exactly the properties most
likely to vary.

`Hash` therefore keys on `Set_Properties` — which properties each rule
set names — together with the selectors and counts. Nothing it reads
depends on how a value was constructed. A property missing from
`Set_Properties` costs a collision, which equality then settles; it
cannot cost a wrong answer.

### Composite values are canonical

`Background_Image` holds a gradient by `Linear_Gradient_Ref`, and a
pointer is what equality on the enclosing style compares. `Linear_Gradient`
therefore returns a shared pointer: it scans a store of gradient values
and allocates only for one it has not seen. Without that, a style
carrying a gradient is unequal to its own copy, so it interns twice and
`Same_As_Applied` reports a source handed its own configuration again as
changed — restyling every bound widget on every `Build`.

The store is scanned rather than hashed. A sheet has a handful of
gradients, and the angle and stop positions are floats, where equal
values need not share their bits. Nothing writes through the pointer:
the three `Render_Gradient_*` helpers take the value as `in`.

Text a style value names — the `background-image` and
`list-style-image` paths, the `list-style-type` marker and the
`font-family` list — reaches the same shape through
`Adi.CSS_Styles.Intern_Text`, which answers one `CSS_Text_Id` per
distinct string from a store the body holds. A style value therefore
carries a 4-byte id rather than a string, which keeps it flat, and
equal text compares equal for the same reason a shared gradient
pointer does.

### Parsed selectors

A stylesheet held the same shape: `Adi.CSS_Parser.Selector_Style`
embedded a `Part_Style_Array`, field for field the same record as
`Static_Style_Entry` and so the same size. Dynamic mode gives every
source its own sheet, so 22 sources loading a 221-selector file cost
about 1.2 GB.

`Selector_Style.Styles` is now `Interned_Part_Styles`.
Rules for one selector arrive scattered through the file and are merged
as they come, so `Build_Styles` accumulates into a working vector of
`Part_Style_Array` and interns each selector once its rules are all in.
Interning every intermediate instead would leave the store holding every
partial rule set the build passed through, and the store does not evict.

The working vector is indefinite. Its elements are a quarter of a
megabyte each, and a definite vector copies them all on every growth.

Measured on that workload, peak RSS fell from 1,136 MB to 66 MB and the
loading from 0.97 s to 0.60 s.

### Comparing styles

`Widget_Style.Rules` is a fixed `State_Rule_Array (1 .. 16)` of which
`Rule_Count` slots are live. Predefined equality compares all sixteen,
so most of the work of a comparison is on unused rule sets. Nothing
writes a slot past `Rule_Count` — `Add_Rule` increments and then writes
the slot it claimed, and nothing decrements — so
`Adi.Widget_Styles.Same_Style` compares the live prefix and answers as
predefined equality does. Interning uses it for both the empty-style
test and the bucket probe, which is a quarter of the loading above.

### Known gaps

The store never evicts, and `Class_Entry` now interns when it is called
rather than when a widget is styled. A caller that bakes per-instance
content into a registered selector — a distinct value per row of a list
— therefore retains a style per row for the life of the process. The
store already grew this way through `Set_Part_Styles`; registration is a
new way to reach it.

`Stylesheet_Metadata.Root_Styles` is still a `Part_Style_Array`, so a
`Stylesheet_Metadata` is 239,864 bytes and every `Stylesheet_Impl`
embeds one. It is public and generated stylesheets construct it, so
shrinking it would mean regenerating every downstream application to
save about 5 MB across 22 sources.

`Set_Properties` is not injective over `Style_Rules`: two rule sets that
name different properties can share a key when one of them names a
property the enumeration folds elsewhere, such as `overflow`. That costs
a bucket probe, never a wrong answer, because equality settles it.


### Tests

`tests/src/style_interning_test.adb` covers the entry size, the same
table registered from many sources, equal styles carrying a string
(which is what catches a byte-wise digest), the enabled/disabled
round-trip, and that equal gradients built separately make equal styles.
On the parser side it covers the size of a parsed selector, the same CSS
parsed into many sheets, that rules scattered through a sheet still
merge onto one entry, and that `Same_Style` agrees with predefined
equality. `Adi.Widget.Testing.Interned_Styles` reports the store size,
and `Adi.CSS_Parser.Testing.Selector_Entry_Bytes` the entry size.

---

## Resolved Styles

A `Resolved_Style` is 840 bytes of concrete values, and the widget record
embedded 48 of them: twelve in `Cached_Resolved`, twelve in `Last_Target`,
and a start/target pair per part across `Transitions`. Each `Item` held
two more. A widget carries 2.72 items across the 27 widget-tree goldens,
so a 500-widget tree held 23 MB in these records, most of it copies of
the same handful of values.

`Adi.Resolved_Styles` holds each distinct value once and answers with a
`Resolved_Handle`. Interning is canonical, so equal handles carry equal
values and a handle comparison is a value comparison.

| | before | after |
|---|---|---|
| `Resolved_Style` | 840 | 840 |
| `Resolved_Handle` | — | 8 |
| `Cached_Resolved`, twelve parts | 10,080 | 96 |
| `Last_Target`, twelve parts | 10,080 | 96 |
| `Transitions`, twelve parts | 20,352 | 480 |
| `Item` | 1,848 | 176 |
| `Widget` | 40,968 | 1,136 |
| a widget and its 2.72 items | 45,994 | 1,614 |

`Get_Resolved_Part_Style` keeps its profile and returns the stored value,
so the sites that read a component out of it by name are unaffected.
`Get_Resolved_Part_Handle` answers the same question as a handle, for a
caller that stores or compares the answer rather than reading a field out
of it, and `Adi.Resolved_Styles.Ref` gives the value in place for a
reader that would otherwise copy 840 bytes to reach one field.

### Storage and eviction

Entries sit in fixed blocks of 128, so an address stays put as the store
grows and a clear returns the blocks to the pool rather than to the
allocator.

`Collect` is the one place the store clears: it drops every entry when
the count has passed `Entry_Cap`, 16,384, and raises `Generation`.
Interning never clears, so an entry and the layout projection behind it
land together and a handle keeps naming its value from the call that
minted it until the next `Collect`. The count therefore stands above the
cap by what one frame interned past it, which is what `Entry_Bytes`
reports. `Adi.Texture_Cache` reclaims at a frame boundary for the same
reason.

`Adi.Widget.Update` calls `Collect` and is the only caller, so a driver
that never updates a tree never clears — and never interns either, since
resolving is what fills the store.

Two things follow a clear.

**Values computed on demand** carry the generation beside the handle and
resolve again on a difference: the per-widget cache through
`Cached_Store_Gen`, the animation targets through `Target_Store_Gen`, and
the memo through `Memo_Store_Gen`.

**Values cached by copy** cannot, and this is the case a per-holder gate
does not reach. An `Item` holds its style by handle and
`Apply_Styles_To_Items` is the only thing that puts a live one back,
which `Update` reaches through `Is_Dirty` alone. Rendering walks every
child unconditionally and reads those handles with no resolution behind
them, so a widget that had gone clean would draw the default style —
transparent, black, borderless — until something dirtied it again.
`Update` therefore compares the generation once per tree and marks the
whole subtree dirty on a difference, descending whether a widget is dirty
or not. A clear is a process-wide event and this answers it in one place
rather than at each holder.

Because `Collect` runs at the top of `Update`, before the layout pass and
the draw that follow it, no handle goes stale part-way through a frame.

### Layout inputs

Each entry carries a second handle, interned from the layout-affecting
properties projected onto the defaults, and
`Adi.Resolved_Styles.Layout_Affecting_Diff` is one equality on it.
Canonical interning makes it exact: equal layout handles are equal layout
inputs, where a digest over the same properties would trade that for a
collision reporting a layout change as none, which surfaces as stale
geometry. `tests/src/style_property_table_test.adb` pins the handle
comparison against `Adi.CSS_Styles.Layout_Affecting_Diff` property by
property.

Twenty of the 66 properties stay outside the projection, so the layout
entries are a fraction of the style entries.

### Hashing a resolved style

`Resolved_Style` cannot be hashed as bytes, for the reason `Style_Rules`
cannot: its variant components hold indeterminate bytes in the arms that
are not active. The hash reads a subset of the record and reaches every
variant component through its discriminant. A component it skips costs a
bucket probe, which equality then settles.

### Animation scratch

A transition mints an interpolated style every frame. Interning those
would grow the store for the length of every animation, so they live in a
fixed pool of 64 slots outside it. A slot carries two cells — where the
transition starts from, and where it stands this frame — and `Advance`
writes the second and answers with a handle to it. A slot serial rides in
the handle, so a handle into a released slot reads as the default style
rather than as the next animation's.

`Adi.Animation.Start` acquires a slot and answers `Started => False` when
the pool is full; the part then takes its target outright, which is the
path a zero `transition-duration` already takes. `Cancel` and a completed
`Advance` return the slot, and so does `Destroy_Subtree`, so a widget
destroyed mid-transition leaves none held.

### Tests

`tests/src/resolved_store_test.adb` covers canonical interning, the
default handle, the layout handle, the scratch pool and its ceiling, a
transition holding and returning a slot, an intern whose layout
projection crosses the cap, and three eviction cases: one under a widget
that is asked for its style again, one under a widget that has gone clean
and is reached only through `Update`, and one under a clean child of a
dirty parent, which is what pins the descent. The last two drive `Update`
rather than `Rebuild_All_Items`, which re-applies unconditionally and
would step over the `Is_Dirty` gate they exist to test. It also reports
the size chain and asserts that nothing on it needs finalization.
