# Handle and Ownership Model

This document describes Adi's handle-first ownership system for widgets, context menus, and windows.

## Goals

- Prevent stale pointer reuse after destruction.
- Keep public APIs ergonomic (`Create_Handle`, typed handles, `+` bridge).
- Preserve backward compatibility with existing `*_Access` APIs during migration.
- Support safe short-lived borrowing via pin/unpin.

## Core Primitive: `Adi.Handle_Store`

`Adi.Handle_Store` is a generic generational store with:

- `Object_Id = (Index, Gen)` where slot `0` is reserved as null.
- `Register`, `Get`, `Is_Valid`, `Request_Destroy`, `Pump`.
- `Pin`/`Unpin` and `Borrow` (`Implicit_Dereference`) for scoped safe access.
- `Set_Strict`/`Is_Strict` — strict-mode validation policy.

Destruction model:

- `Request_Destroy` frees immediately when unpinned.
- If pinned, destruction is deferred until last `Unpin`.
- `Pump` drains deferred entries each frame.

### Strict Mode

Each store instantiation has an independent `Strict` flag (default **True**).

When strict mode is enabled, `Get` raises `Program_Error` for non-null IDs that fail validation (stale generation, out-of-range index). `Null_Id` always returns null silently regardless of this setting, since null handles represent intentional "nothing" values.

This catches common bugs at the point of misuse:

- Using a handle after its object has been destroyed (stale generation).
- Calling `Get_Handle` on a widget that was never registered in the store (`Store_Index = 0`).
- Passing a handle returned by an unregistered widget to `Add_Child` or other operations.

Since all handle resolution paths flow through `Get` — including `Resolve_Handle`, wrapper generics (`Wrap_CW_Proc/Func`), manual `Widget_Stores.Get(H.Id)` patterns, and `Borrow` — strict mode provides centralized coverage. Exception-catching patterns (e.g. `Add_Child` catching `Constraint_Error` from `Borrow`) do not suppress the `Program_Error` raised by strict mode.

For release builds where stale handles should degrade gracefully, call `Set_Strict(False)` on the relevant store.

## Widget Ownership

`Adi.Widget` owns all widgets through a package-level store (`Widget_Stores`).

- Public handle: `Widget_Handle` (opaque).
- Typed handles (e.g. `Button_Handle`, `Label_Handle`) wrap the same store ID.
- Bridge helpers per typed handle:
  - `To_Widget_Handle`
  - `Try_As_*`
  - `Is_Valid`
  - unary `+`

Core APIs:

- `Get_Handle (W : Widget'Class) return Widget_Handle`
- `Destroy (H : in out Widget_Handle)`
- `Resolve_Handle (H)` (compatibility bridge)
- `Borrow (H) return Widget_Ref` (scoped pin/unpin)
- `Pump_Widget_Store`

`Destroy_Subtree` is bottom-up and calls dispatching `On_Destroy` before final request-destroy, allowing widgets to clean external bindings.

## Animation Ownership

`Adi.RLottie` and `Adi.Animated_Image` each instantiate
`Adi.Handle_Store` and hand out an `Animation_Handle` of their own. `Load_From_File` registers; `Destroy` tears the
animation down, retires the slot and nulls the handle, so every copy
goes stale together and a reused slot does not revive them. Operations
resolve a handle for one call and answer a stale or null one with a
default rather than reaching through it.

`Adi.Assets` caches images and animated images as handles, so clearing
or invalidating an entry retires the slot and every handle it gave out
goes stale.

## Owned Handles

`Adi.Owned_Handle_Store` layers two types over `Adi.Handle_Store`. An
`Owner` keeps an object and is the only thing that can end it; a
`Handle` names it without keeping it. Owners are counted between
themselves, so they can live in ordinary containers; a handle never
counts, so the last owner going stales every view at once rather than
keeping the object alive for whoever still points at it.

Releasing is explicit. When a container finalises a value it drops is
unspecified, and GNAT's map and vector do not agree, so an owner held in
one is released before it is removed.

## Image Ownership

`Adi.Image` instantiates it. The raw image and the pointer to it are
private, so every holder — render items, widget icons, CSS background
images, cached HTML images, animation frames — names an image by
`Image_Handle`, and nothing outside the package holds a pointer to one.

Constructors return an `Image_Owner`; `To_Handle` gives the view that
everything else stores. `Release` on the last owner frees the image and
retires its slot, and every handle to it goes stale in that moment — so
an owner may end an image while widgets still hold handles: each answers
with the default an image holding nothing would give, and a render item
naming one draws nothing.

Who owns what: the asset cache owns what it hands out, an animation owns
its frames, an HTML view owns the images it builds from inline `<svg>`
and borrows the ones a callback hands it, a combo box owns the chevrons
it draws for want of any supplied. An application owns what it loads,
and must outlive the widgets drawing it.

One limit is worth stating: nothing pins a slot, so every operation must
run on the render thread — including the release an owner performs on
its way out of scope.

## Context Menu Ownership

`Adi.Widget.Context_Menu` has its own `Menu_Stores`:

- `Menu_Handle`, `Get_Handle`, `Destroy`, `Is_Valid`, `Pump_Menu_Store`.
- Menus and their popup/dismiss widgets are cleaned via handle-based teardown.

## Window Ownership

`Adi.Window` has an independent `Window_Stores` (window is not a widget):

- `Window_Handle`, `Null_Window_Handle`
- `Create_Window_Handle`
- `Get_Handle`, `Is_Valid`, `Resolve_Window_Handle`
- `Destroy (H : in out Window_Handle)`
- `Destroy (W : in out Window_Access)` (compat)
- `Pump_Window_Store`

Window destruction path:

1. Clear focus/hover/pressed refs.
2. Destroy overlays and root via widget handles.
3. Finalize SDL resources (`Renderer`, `Window`) after widget teardown.

When `Destroy(Window_Handle)` is called from inside window-dispatch callbacks
(mouse/keyboard/tick/render/close-request), destruction is queued and applied
by `Pump_Window_Store` after callback dispatch unwinds. This avoids
deallocating the active window object mid-dispatch.

## App Lifecycle

`Adi.App` now stores `Main_Window : Window_Handle`.

- `Add_Window` accepts both `Window_Access` and `Window_Handle`.
- Run loop resolves handle on use.
- Per-frame drain order:
  1. `Adi.Dispatch.Drain`
  2. `Pump_Widget_Store`
  3. `Pump_Menu_Store`
  4. `Pump_Window_Store`
- If main window becomes invalid mid-run, app exits cleanly.
- End-of-run destroys main window via handle.

## Bridge Overloads

Handle overloads exist for integration points that historically required access pointers:

- `Adi.Widget.Dialog.Attach_Window (..., Host : Window_Handle)`
- `Adi.Widget.Context_Menu.Attach_Window (..., Host : Window_Handle)`
- `Adi.OS.Show_*_Dialog (..., Window : Window_Handle)`
- `Adi.MCP.Initialize (Win : Window_Handle, ...)`

These resolve to access internally and no-op safely when stale/null.

## XML Generator API Shape

Window-mode `Build` now returns `Adi.Window.Window_Handle` and emits:

- `Adi.Window.Create_Window_Handle`
- `Adi.Window.Connect_Tick (W, ...)`
- `Adi.Window.Set_Root (W, +Root)`

Widget exports in generated specs are typed handles (not raw access types).

## Recommended Usage

- Prefer `Create_Handle` + typed-handle methods in application code.
- Use `+Typed_Handle` when a `Widget_Handle` is needed.
- Use `Borrow` for scoped internal access when dispatching on class-wide widget API is needed.
- Keep `Resolve_Handle` usage minimal and internal.

## Backward Compatibility and Future Direction

### Completed removals

The following access-based APIs have been removed (previously marked `Obsolescent`):

- `Adi.Window.Create_Window (...) return Window_Access` — use `Create_Window_Handle`
- `Adi.Window.Destroy (W : in out Window_Access)` — use `Destroy (H : in out Window_Handle)`
- `Adi.Window.Set_Root (..., Root : access Widget'Class)` — use `Set_Root (..., Root : Widget_Handle)`
- `Adi.Window.Add_Overlay (..., Overlay : access Widget'Class)` — use `Add_Overlay (..., Overlay : Widget_Handle)`
- `Adi.Window.Remove_Overlay (..., Overlay : access Widget'Class)` — use `Remove_Overlay (..., Overlay : Widget_Handle)`
- `Adi.App.Add_Window (A, W : Window_Access)` — use `Add_Window (A, W : Window_Handle)`
- `Adi.OS.Show_*_Dialog (..., Window : Window_Access, ...)` — use `Window_Handle` parameter
- `Adi.Widget.Dialog.Create return Dialog_Widget_Access` — use `Create_Handle`
- `Adi.Widget.Dialog.Attach_Window (..., Host : Window_Access)` — use `Attach_Window (..., Host : Window_Handle)`
- `Adi.Widget.Dialog.Get_Button (...) return Button_Widget_Access` — use `Get_Button_Handle`

### Current state

- `Widget_Access` and `Window_Access` remain public for internal use and `Resolve_Handle`/`Find_Host_Window`.
- All public construction, destruction, and configuration APIs are handle-only.

### Dialog handle-first internals

`Dialog_Widget` stores all sub-widgets as handles internally:

- `Host_Window : Window_Handle`
- `Content_Panel : Box_Handle`, `Title_Label : Label_Handle`, `Message_Label : Label_Handle`, `Button_Row : Box_Handle`
- `Custom_Content : Widget_Handle`
- `Button_Info.Widget : Widget_Handle`
- `Dialog_Binding` records: `Btn : Widget_Handle`, `Owner : Widget_Handle`

Full handle API: `Create_Handle`, `Dialog_Handle`, `+`, `Is_Valid`, `To_Widget_Handle`, `Try_As_Dialog`, plus handle methods for all widget operations (`Set_Title`, `Set_Message`, `Add_Button`, `Show`, `Hide`, `Connect_Result`, style setters, etc.).

### Remaining tightening

1. Migrate internal framework code from `Resolve_Handle` to `Borrow` where practical.
2. Move `Widget_Access` toward private visibility once downstream usage is migrated.

Target outcome: user-facing ownership through handles plus scoped borrow, with raw access types mostly internal escape hatches.
