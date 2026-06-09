# Finalization ordering — known issue and structural options

## Symptom

A test (or any program) that opens an `Adi.Window` without calling
`Window.Destroy` before exit can crash *after* main returns:

```
All tests PASSED!
========================================

Execution of … terminated by unhandled exception
raised CONSTRAINT_ERROR : erroneous memory access
```

Stack (via lldb / addr2line) consistently lands inside library finalization:

```
adi__widget__destroy_subtree (adi-widget.adb)
adi__window__destroy_widget_tree (adi-window.adb)
adi__window__finalize         (controlled-type Finalize on Window)
system__finalization_primitives__finalize_master
ada_main__finalize_library
```

The faulting instruction is a **dispatching call** — either `On_Destroy
(Widget'Class (W.all))`, `Clear_Items (Widget'Class (W.all))`, or
`Free_Object (S.Obj)` (an `Unchecked_Deallocation` of a controlled
object, which itself dispatches into `Finalize`). The vtable slot
resolves to `0x0` and the process faults.

GNAT's signal-to-exception mapping (`__gnat_map_signal`) is already
torn down at this point, so wrapping the call in
`exception when others => null` does **not** catch the fault — it is
delivered as a hardware fault past Ada's reach.

## Why it happens

`Adi.Window` thinks it owns the widget tree: it holds `W.Root` and
walks the tree from its overriding `Finalize`. That ownership model is
correct **semantically** but Ada's library-level finalization order
isn't driven by ownership — it's driven by **reverse elaboration
order**, which is in turn driven by `with` clauses.

A typical consumer unit has:

```ada
with Adi.Window;
with Adi.Widget.Box;     -- child of Adi.Widget
with Adi.Widget.Label;   -- child of Adi.Widget
```

Adi.Window withs Adi.Widget (the root) but **not** the child packages
that contain the concrete widget tagged types. So:

| Stage | Order |
|---|---|
| Elaboration | `Adi.Widget` → `Adi.Widget.Box` → `Adi.Widget.Label` → `Adi.Window` → main |
| Finalization | main → `Adi.Window` → `Adi.Widget.Label` → `Adi.Widget.Box` → `Adi.Widget` |

The relative order between Adi.Window and the widget child packages is
**not enforced**. GNAT happens to finalize widget children *before*
Adi.Window in practice — by which point those types' vtables are gone.
`Adi.Window.Finalize` then walks the still-allocated widget objects
(the store keeps them pinned) and dispatches into freed vtables.

## What's in tree today

`src/adi-widget.adb`, `Destroy_Subtree`: a `Library_Finalizing : Boolean`
flag, set by `Adi.Window.Finalize` before it walks the tree and
cleared after. When the flag is set, `Destroy_Subtree` clears child
references and returns without calling `On_Destroy`, `Clear_Items`, or
`Widget_Stores.Request_Destroy` — the OS reclaims the heap at process
exit so the store cleanup is harmless to skip.

This is a **tactical guard**, not a structural fix. Widgets destroyed
explicitly (`Adi.Widget.Destroy (H)` while the program is still
running) go through the full normal path.

## Structural options, ordered by leverage

### Option 1 — `pragma Elaborate_All` on every widget child package in `Adi.Window`

Add to `src/adi-window.ads`:

```ada
with Adi.Widget.Box;     pragma Elaborate_All (Adi.Widget.Box);
with Adi.Widget.Label;   pragma Elaborate_All (Adi.Widget.Label);
with Adi.Widget.Button;  pragma Elaborate_All (Adi.Widget.Button);
... -- and every other widget tagged-type child
```

Forces `Adi.Window` to depend on each widget child package, which
forces those packages to elaborate *before* Window and therefore
finalize *after* it. The guard becomes unnecessary in the normal case.

**Cost:** enumeration (breaks every time a new widget type lands),
backwards dependency (Window now knows about every concrete widget
type, which it doesn't otherwise need to). Doesn't cover user-defined
widget types at all.

**Effort:** ~5 lines per widget type, ~50 lines total today.

### Option 2 — Type-erased cleanup captured at registration time (recommended)

The clean fix. When a widget is created, capture a non-dispatching
cleanup procedure derived from the concrete type **at that moment**,
and store it in the handle-store slot alongside the access value:

```ada
type Cleanup_Proc is access procedure (Self : Widget_Access);

procedure Register_Widget
  (Obj : not null Widget_Access) is
   procedure Concrete_Cleanup (Self : Widget_Access);
   --  Generated per concrete type by a generic helper at Create time.
begin
   Widget_Stores.Register (Obj, Cleanup => Concrete_Cleanup'Access);
end Register_Widget;
```

The captured `Concrete_Cleanup` is a regular access-to-procedure that
closes over the concrete type. Calling it through the access value
does not dispatch and does not consult the vtable. The procedure
itself runs `Foo_Widget (Self.all).On_Destroy` (or whatever) as a
direct call — also non-dispatching, because the cast is to a concrete
type, not the class-wide.

The closure is alive as long as the access value is alive, which is
guaranteed by the captured copy in the store slot — independent of the
widget's tagged-type package finalization state.

**Cost:** every `Create` / `Create_Handle` has to register a
type-specific cleanup. A small generic can factor the pattern:

```ada
generic
   type Concrete is new Widget with private;
   with procedure Concrete_On_Destroy (W : in out Concrete) is null;
package Widget_Registration is
   procedure Register (Obj : not null access Concrete);
end Widget_Registration;
```

Instantiated once per widget type in its body.

**Effort:** moderate refactor (~1–2 days for the framework
side). Touches every Create entry point and the handle-store API.

**Pays off:** Window can be safely walked at any time, including from
library finalization, including with consumer-defined widget types
that we don't `with`.

### Option 3 — Make `Adi.Window.Destroy` mandatory; leave Finalize a leak

Document that consumers **must** call `Adi.Window.Destroy` before exit,
and have `Adi.Window.Finalize` only tear down SDL resources (renderer,
window, render context). The widget tree leaks — but the OS reclaims
it at process exit.

**Cost:** API contract change. Every example, every test, every
embedder has to remember to call Destroy. Easy to forget.

**Effort:** documentation + a small change to `Finalize` to skip the
tree walk entirely.

## Recommendation

**Option 2.** It's the only one that gives a real ownership guarantee
without enumerating widget types or putting the burden on consumers.
The tactical guard buys time; it shouldn't be the permanent answer.

If Option 2 is too much surface area in the short term, **Option 1**
covers the in-tree widget set with minimal code and the user can layer
their own `Elaborate_All` for custom widgets. It is, however, a real
backwards dependency from Window onto every widget child package —
which is arguably an architectural smell, since Window shouldn't need
to know about Button or Combo_Box.

## See also

- `src/adi-widget.adb` — `Destroy_Subtree`, `Begin_Library_Finalization`,
  `End_Library_Finalization`.
- `src/adi-window.adb` — `Finalize` (calls Begin/End around its tree walk).
- Commit `ce15a63` — the tactical guard. Comment at the guard site
  cross-references this document.
