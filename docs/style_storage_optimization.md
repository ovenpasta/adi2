# Internal Style Storage Optimization

## Scope

How the library stores styles, resolves them and bounds what it keeps.
The stores live in `Adi.CSS_Styles` (rule sets), `Adi.Widget_Styles`
(styles) and `Adi.Resolved_Styles` (resolved values); `Adi.Widget` holds
handles into them.

These spellings are what an application writes, and each carries a
handle or an array of them:
- `Part_Style`, `Part_Style_Array`
- `Set_Part_Style`, `Set_Part_Styles`
- `From (…) .On (…) .Build`, which answers a `Widget_Style`
- the CSS parser and source interfaces, and generated CSS Ada

`Widget_Style` is private, so a caller that reads a style's own rules
goes through `Adi.Widget_Styles.Definition`.

## Design Summary

Four layers:

1. Handle-based per-widget style storage
2. Prepared rule-order evaluation
3. Global resolved-style memo cache
4. A store of distinct resolved styles, which the memo and every widget
   name by handle

### 1) Handle-Based Storage

`Adi.Widget_Styles.Widget_Style` is a private four-byte handle into a
store the same package keeps. `Style_Definition` is the record an author
fills in — a base rule set and sixteen state-rule slots — and the two
convert through `Intern` and `Definition`. `Empty_Widget_Style` is
handle zero.

A widget holds `Part_Styles : Part_Style_Array`, twelve slots of a
handle and an enabled flag, 96 bytes in all.

Interning is canonical, so equal definitions share one entry and
comparing two handles compares two styles. The store holds an entry for
the life of the process.

### 2) Prepared Rule Order

Interned style entries carry precomputed metadata:
- stable pre-sorted rule order
- effective priority = explicit `Priority` or selector `Specificity`
- source-order tie behavior preserved

Runtime style computation goes through
`Adi.Widget_Styles.Compute_Style_Prepared`, which takes a handle and
folds the rules in the prepared order rather than sorting per call.
`Uses_Widget_State`, `Uses_Part_State` and `Uses_Properties` answer from
the same entry, so `Adi.Widget` reads the masks without holding the
record.

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

## What the layers hold to

- The `Any_Part` fallback: a part with no style of its own resolves
  through `Any_Part` when that carries one.
- A part's `Enabled` flag rides beside its handle, so a part that carries
  a style and is switched off stays distinct from a part with none.
- A sub-part inherits the typography of `Main_Part`.
- Two assumptions the stores rest on: style mutation is single-threaded,
  and an interned entry is immutable once stored.

`tests/src/style_storage_equivalence_test.adb` holds the first three,
plus rule priority, equal-priority tie order, and dynamic style churn
through repeated selector rebinding.

## Observed Results

`'Object_Size`/8 on x86-64 Linux, which `tests/src/style_flat_values_test.adb`
reports and `tests/src/style_handle_test.adb` pins:

| | bytes |
|---|---|
| `Style_Rules` | 1,072 |
| `State_Rule` | 16 |
| `Widget_Style` | 4 |
| `Style_Definition` | 268 |
| `Part_Style` | 8 |
| `Part_Style_Array` | 96 |
| `Stylesheet_Metadata` | 112 |
| `Resolved_Style` | 840 |

A widget's twelve part slots are 96 bytes, and every layer that stores or
passes a style — a registered selector, a parsed selector, a stylesheet's
`:root` block, a merge result, a builder step — carries that width or
less.

`layout_perf_test` behaviour checks (style cache hit/miss + invalidation)
remain green.

---

## Registered and parsed selectors

`Adi.CSS_Source.Static_Style_Entry` and `Adi.CSS_Parser.Selector_Style`
each hold a `Part_Style_Array` directly, and so does
`Adi.CSS_Parser.Stylesheet_Metadata` through `Root_Styles`. At 96 bytes
that is a selector's whole styling; a source's `Applied_Statics` holds a
second copy per selector and costs the same again.

`Style_Source_Impl` keeps a `Root_Fingerprint` rather than a second
`Stylesheet_Metadata`, so `Same_As_Applied` compares handles.

Rules for one selector arrive scattered through a file and are merged as
they come, so `Build_Styles` accumulates into a working vector of
`Part_Style_Array` and publishes it to `Impl.Selectors` once the whole
build has succeeded. A failed build leaves the selectors the sheet
started with.

### Interning is hashed

Interning runs at registration and at every `Set_Part_Styles`, so the
store groups handles by hash and probes a bucket rather than scanning.
Both stores are keyed by hash rather than by value, so neither holds a
second copy of what it stores.

`Adi.Widget_Styles.Hash` reads a `Style_Definition`: the store index of
its base rule set, the index of each live rule's rule set, the selectors
and the counts. A rule-set handle stands for its value, interning being
canonical, so the digest reaches the values without reading them.

`Adi.CSS_Styles.Hash` reads a `Style_Rules`, which cannot be hashed as
bytes: its properties are discriminated `Optional` records whose inactive
arms hold indeterminate bytes, so two equal rule sets built by separate
calls share none of them and a byte digest would split them. It reads
`Set_Properties` — which properties the set names — and then each
property's value through `Resolve`, which answers the default for a
property the set leaves alone and so never reaches an inactive arm.
`Adi.CSS_Styles.Value_Hash` holds the per-value steps, shared with
`Adi.Resolved_Styles`.

Two rule sets can still share a digest — a single zero `padding-top` and
a single zero `padding-left` both report `Prop_Padding` and resolve to a
uniform zero box. That costs a bucket probe, never a wrong answer,
because equality settles it.
`tests/src/style_handle_test.adb` drives that pair.

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

### Comparing definitions

`Style_Definition.Rules` is a fixed `State_Rule_Array (1 .. 16)` of which
`Rule_Count` slots are live. Predefined equality compares all sixteen, so
most of the work of a comparison is on unused slots. Nothing writes a
slot past `Rule_Count` — `Add_Rule` increments and then writes the slot
it claimed, and nothing decrements — so
`Adi.Widget_Styles.Same_Style` compares the live prefix and answers as
predefined equality does. Interning uses it for both the empty-style test
and the bucket probe.

### Elaboration

`tools/css_to_ada.py` emits its `Widget_Style` and `Part_Style_Array`
constants at library level, so a generated sheet interns as it
elaborates. The spec carries `pragma Elaborate_All (Adi.Widget_Styles)`,
which puts that store and the rule-set store behind it in place first.

### Known gaps

Neither store evicts, and `Class_Entry` interns when it is called rather
than when a widget is styled. A caller that bakes per-instance content
into a registered selector — a distinct value per row of a list —
therefore retains a style per row for the life of the process. The store
is reached the same way through `Set_Part_Styles`.

`Adi.CSS_Parser.Build_Styles` and `Adi.Style_Merge.Merge` fold a rule set
and intern the result, so a selector named by several rule blocks leaves
the intermediate folds in the rule-set store as well as the final one.
`Merge` answers with a contributor's own handle where only one of them
carries the part, which is the common case.

### Tests

`tests/src/style_handle_test.adb` covers the widths each type carries,
that equal definitions share a handle and different ones do not, a
deliberate digest collision, the `Intern`/`Definition` round trip, the
merge path re-interning and passing a single contributor through, and a
generated sheet answering a live handle from constants that interned as
it elaborated.

`tests/src/style_interning_test.adb` covers the entry size, the same
table registered from many sources, equal styles carrying a string
(which is what catches a byte-wise digest), and that equal gradients
built separately make equal styles. On the parser side it covers the size
of a parsed selector, the same CSS parsed into many sheets, that rules
scattered through a sheet still merge onto one entry, and that
`Same_Style` agrees with predefined equality.
`Adi.Widget.Testing.Interned_Styles` reports the store size, and
`Adi.CSS_Parser.Testing.Selector_Entry_Bytes` the entry size.

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
