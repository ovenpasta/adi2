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

Destruction model:

- `Request_Destroy` frees immediately when unpinned.
- If pinned, destruction is deferred until last `Unpin`.
- `Pump` drains deferred entries each frame.

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

Current state:

- `Widget_Access` and `Window_Access` remain public for compatibility.
- Access-based APIs still exist where migration is incomplete or callback types require them.

Phase 3 soft deprecations (obsolescent warnings enabled):

- `Adi.Window.Create_Window (...) return Window_Access`
- `Adi.Window.Destroy (W : in out Window_Access)`
- `Adi.App.Add_Window (A, W : Window_Access)`
- `Adi.OS.Show_Open_File_Dialog (..., Window : Window_Access, ...)`
- `Adi.OS.Show_Save_File_Dialog (..., Window : Window_Access, ...)`
- `Adi.OS.Show_Open_Folder_Dialog (..., Window : Window_Access, ...)`

These remain functional compatibility paths, but new code should use handle
overloads/constructors.

Planned tightening:

1. Keep adding handle-returning/handle-accepting overloads.
2. Migrate internal framework code from `Resolve_Handle` to `Borrow` where practical.
3. Add handle-based alternatives for remaining access-returning getters.
4. Move `Widget_Access` toward private visibility once downstream usage is migrated.

Potential end-state:

- Public widget ownership/identity is handle-only.
- Public mutable/widget traversal access uses scoped `Borrow`.
- Raw `Widget_Access` remains internal (or explicit expert escape hatch only), reducing stale-pointer misuse in application code.

Target outcome: user-facing ownership through handles plus scoped borrow, with raw access types mostly internal escape hatches.
