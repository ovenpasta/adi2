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

### A stale handle degrades

Staleness is a state the library manufactures in normal operation: a window holds `Hovered`/`Pressed`/`Focused` widget handles across frames, an option group holds `Button_Handle`s, `Adi.Dispatch.Post` runs a frame after the state it captured. So a handle that names something already destroyed is a question with an answer, not a programming error.

`Get` returns null for `Null_Id` and for any id that fails validation — stale generation, out-of-range index, destruction requested. Every operation reached through a handle is written around that null: a procedure does nothing, a function answers the value that means "no object" (`False`, `0`, `""`, `Null_Handle`, `No_Connection`). `Handle_Close_Request` answers `True`, since a window that is gone cannot veto a close.

`Borrow` is the single exception and raises `Constraint_Error`, because its whole purpose is to produce a usable pointer and there is none.

### `Is_Valid` and the pin

`Is_Valid` answers False from `Request_Destroy` onwards, including while the slot is still pinned. A pin defers the free, not the answer: by the time destruction is requested a widget has had `On_Destroy` dispatched and its children cleared, so the object is readable through a `Ref` taken earlier but is no longer something to drive.

Internally the store separates the two questions. A raw slot-identity predicate — alive, generation matches, `Pending` ignored — backs `Unpin` and the free path, so the pin holding a requested destroy back can still be released. `Is_Valid` is that predicate plus `not Pending`, and is what every public path uses.

### What still raises

`Get_Handle` raises `Program_Error` for a widget or window whose `Store_Index` is 0. That names something never registered — a construction bug with no handle to hand back — which is categorically different from a handle naming something legitimately destroyed.

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
- `Borrow (H) return Widget_Ref` (scoped pin/unpin)
- `Pump_Widget_Store`

`Destroy_Subtree` is bottom-up and calls dispatching `On_Destroy` before final request-destroy, allowing widgets to clean external bindings.

An operation reached through a handle borrows for the length of its call
when that call can reach an application callback. That is: the four
wrapper generics the `Widget_Handle` overloads are built from
(`Wrap_CW_Proc`, `Wrap_Prim_Proc`, `Wrap_CW_Func`, `Wrap_Prim_Func`); the
ten hand-written event overloads (`Handle_Scroll_Mouse_Down/Move/Up`,
`On_Mouse_Down/Move/Up/Wheel`, `On_Key_Down/Up`, `On_Text_Input`); the
typed-handle setters that end in an emit — `Set_Scroll_Offset_Y`,
`Stack.Set_Active`, `Combo_Box.Set_Selected_Index`,
`List_Box.Select_Row`, `Toggle_Row_Selected`, `Clear_Selection`,
`Clear_Rows`, `Set_Scroll_Offset`, `Scroll_By`, `Ensure_Row_Visible`; and
the places where one widget reaches into another to emit on it — a
dialog button forwarding Escape to its dialog, and a text input or text
editor firing `Changed` for a context-menu command, where the dispatch
that got there is holding the button or the menu popup and not the
target.

So a callback may destroy the widget whose call it is running under: the
slot is retired when the call unwinds, not underneath it. The pin keeps
the widget readable, not usable — its teardown has already run, and its
handle answers `Is_Valid` False from that moment.

Every other typed-handle setter — `Set_Label`, `Text_Input.Set_Text`,
`Slider.Set_Value`, `Value_Input.Set_Value`, `Switch.Set_Checked`,
`Button.Set_Toggled` and the rest — resolves raw and does not pin. What
makes that safe is a property of what they do, not of the handle: each
writes the widget's own state and marks it dirty, and none of them
emits, so none can reach code that destroys the widget while the call is
still running. A setter that grows an emit has to grow a borrow with it.

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
- `Get_Handle`, `Is_Valid`
- `Borrow (H) return Window_Ref` (scoped pin)
- `Destroy (H : in out Window_Handle)`
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

- `Add_Window` takes a `Window_Handle`.
- The run loop drives the window through handle operations. A callback
  running under a dispatch guard queues its destroy; `Pump_Window_Store`
  at the top of the next frame carries it out, and the loop ends on the
  check after it.
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
- Use `Borrow` for scoped access when dispatching on the class-wide widget API is needed.
- Define a widget type of your own at library level and register it with `Adi.Widget.Extension`.

## Backward Compatibility and Future Direction

### Completed removals

The following access-based APIs have been removed (previously marked `Obsolescent`):

- `Adi.Window.Create_Window (...) return Window_Access` — use `Create_Window_Handle`
- `Adi.Window.Destroy (W : in out Window_Access)` — use `Destroy (H : in out Window_Handle)`
- `Adi.Window.Resolve_Window_Handle (...) return Window_Access` — use `Borrow`
- `Adi.MCP.Initialize (Win : access Window'Class, ...)` — use `Initialize (Win : Window_Handle, ...)`
- `Adi.Window.Set_Root (..., Root : access Widget'Class)` — use `Set_Root (..., Root : Widget_Handle)`
- `Adi.Window.Add_Overlay (..., Overlay : access Widget'Class)` — use `Add_Overlay (..., Overlay : Widget_Handle)`
- `Adi.Window.Remove_Overlay (..., Overlay : access Widget'Class)` — use `Remove_Overlay (..., Overlay : Widget_Handle)`
- `Adi.App.Add_Window (A, W : Window_Access)` — use `Add_Window (A, W : Window_Handle)`
- `Adi.OS.Show_*_Dialog (..., Window : Window_Access, ...)` — use `Window_Handle` parameter
- `Adi.Widget.Dialog.Create return Dialog_Widget_Access` — use `Create_Handle`
- `Adi.Widget.Dialog.Attach_Window (..., Host : Window_Access)` — use `Attach_Window (..., Host : Window_Handle)`
- `Adi.Widget.Dialog.Get_Button (...) return Button_Widget_Access` — use `Get_Button_Handle`

### Current state

- `Widget_Access`, `Resolve_Handle` and `Register_Widget` are private to `Adi.Widget`; the library's own child packages use them, and a widget type defined outside the library goes through `Adi.Widget.Extension`.
- `Window_Access` is private to `Adi.Window`, and `Resolve_Window_Handle` is gone. `Borrow` is the only way to a window pointer, and it pins.
- Construction, destruction and configuration are handle-only across the widget and window packages.
- `Scroll_Observer` (`adi-widget.ads`) is the one callback still handed a raw widget pointer; see below.

### Dialog handle-first internals

`Dialog_Widget` stores all sub-widgets as handles internally:

- `Host_Window : Window_Handle`
- `Content_Panel : Box_Handle`, `Title_Label : Label_Handle`, `Message_Label : Label_Handle`, `Button_Row : Box_Handle`
- `Custom_Content : Widget_Handle`
- `Button_Info.Widget : Widget_Handle`
- `Dialog_Binding` records: `Btn : Widget_Handle`, `Owner : Widget_Handle`

Full handle API: `Create_Handle`, `Dialog_Handle`, `+`, `Is_Valid`, `To_Widget_Handle`, `Try_As_Dialog`, plus handle methods for all widget operations (`Set_Title`, `Set_Message`, `Add_Button`, `Show`, `Hide`, `Connect_Result`, style setters, etc.).

### Scroll_Observer

`Scroll_Observer` (`adi-widget.ads`) is handed an anonymous pointer to the
widget that scrolled, borrowed for the duration of the call. It is the one
callback that does not carry a handle, because it also fires for stack
widgets that are not registered in the store and therefore have no handle
to carry. An observer must not retain the pointer.

### Option groups

`Adi.Widget.Button.Options` gives every button it owns a
`Group_Handler_Access` back to the group, which `Button.On_Click`
dispatches through. `Option_Group` is limited controlled so that
finalization unlinks the buttons it still owns, and it holds membership
as `Button_Handle`, so a button destroyed first drops out rather than
being followed.

Unlinking is conditional: a group clears a button's link only while that
link still points at itself. `Set_Button` publishes the new membership
and link before calling `Forget_Button` on the group the button is
leaving, so for that window — and permanently if `Forget_Button`
propagates an exception — the old group still records a button that has
moved on. An unconditional unlink would then sever the newer binding
when that group finalizes.

`Group_Handler.Forget_Button` is a null-default primitive called on the
group a button is leaving. A group that keeps its own record of
membership should override it; one that does not simply keeps a stale
entry, which every operation skips because the link no longer names it.

`Group_Handler`, `Set_Group` and `Group_Of` are private to
`Adi.Widget.Button`, so an application cannot hand a button a pointer to
a group whose lifetime nothing controls. `Option_Group` is `limited
private` and wraps the tagged half rather than being it: a partial view
has to name the interfaces its full view implements, so deriving
directly would have put the protocol back in the public API.
