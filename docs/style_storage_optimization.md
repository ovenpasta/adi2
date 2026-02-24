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
