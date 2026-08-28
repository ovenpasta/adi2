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

The optimization has three internal layers:

1. Handle-based per-widget style storage
2. Prepared rule-order evaluation
3. Global resolved-style memo cache

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

Policy:
- bounded capacity (`32_768` entries)
- on overflow: clear cache

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
carrying a fixed `State_Rule_Array (1 .. 16)`:

| | bytes |
|---|---|
| `Widget_Style` (`-gnatR3`) | 19,976 |
| `Part_Style_Array` | 239,808 |
| `Static_Style_Entry`, by value | 239,832 |
| `Static_Style_Entry`, interned | 88 |

The cost is paid per selector, per source, and again per source in
`Applied_Statics`. An application that creates one `Style_Source` per
generated UI package registers the same generated table from each of
them, so a 221-selector sheet across 22 sources cost about 1.2 GB once
and 2.3 GB with `Applied_Statics` — over the address space of a 32-bit
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

`Intern_Style` scanned the whole store comparing 19,976-byte records.
That was tolerable at one call per widget styling; interning at
registration raises it by orders of magnitude. Handles are now grouped
by `Adi.Widget_Styles.Hash`, and the map is keyed by hash rather than by
style so it does not hold a second copy of each.

`Style_Rules` cannot be hashed as bytes. Its properties are
discriminated `Optional` records whose inactive variants hold
indeterminate bytes, and four of them carry an `Unbounded_String` while
`Background_Image` carries a `Linear_Gradient_Ref`. Two equal styles
built by separate calls share none of those bytes, so a byte digest
splits them and the deduplication silently disappears for exactly the
properties most likely to vary.

`Hash` therefore keys on `Set_Properties` — which properties each rule
set names — together with the selectors and counts. Nothing it reads
depends on how a value was constructed. A property missing from
`Set_Properties` costs a collision, which equality then settles; it
cannot cost a wrong answer.

### Known gaps

The store never evicts, and `Class_Entry` now interns when it is called
rather than when a widget is styled. A caller that bakes per-instance
content into a registered selector — a distinct value per row of a list
— therefore retains a style per row for the life of the process. The
store already grew this way through `Set_Part_Styles`; registration is a
new way to reach it.


`Linear_Gradient_Ref` is an access type with no user-defined `"="`, and
`Linear_Gradient` allocates on every call, so two equal gradients built
separately are unequal styles and are stored twice. Correctness does not
depend on it — `style_interning_test` pins that a gradient round-trips
through interning either way — but a sheet heavy in gradients
deduplicates less.

### Tests

`tests/src/style_interning_test.adb` covers the entry size, the same
table registered from many sources, equal styles carrying a string
(which is what catches a byte-wise digest), the enabled/disabled
round-trip, and the gradient case. `Adi.Widget.Testing.Interned_Styles`
reports the store size.
