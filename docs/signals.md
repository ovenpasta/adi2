# Signals and Deferred Dispatch

Adi provides two complementary mechanisms for decoupled communication between components:

- **Adi.Signal** — multi-subscriber signal/slot pattern for event callbacks
- **Adi.Dispatch** — thread-safe deferred execution queue for the main thread

## Adi.Signal

### Overview

`Adi.Signal` is a generic package that implements a multi-subscriber signal. Widgets use it to expose events (clicked, toggled, value changed, etc.) that application code can subscribe to.

```
src/adi-signal.ads   -- Spec
src/adi-signal.adb   -- Body
```

### Instantiation

The generic takes a callback access type and a null sentinel:

```ada
type Click_Callback is access procedure (W : Widget_Handle);

package Click_Signals is new Adi.Signal
  (Callback_Type => Click_Callback,
   Null_Callback => null);
```

Each widget stores a `Signal` instance in its private record:

```ada
type Button_Widget is new Label_Widget with record
   Clicked : Click_Signals.Signal;
end record;
```

### Connecting

Subscribe a handler with `Connect`. The function form returns a `Connection_Id` for later disconnection; the procedure form discards it:

```ada
--  Function form (when you need to disconnect later)
Id := W.Clicked.Connect (My_Handler'Unrestricted_Access);

--  Procedure form (fire-and-forget)
W.Clicked.Connect (My_Handler'Unrestricted_Access);
```

Widgets typically wrap this with convenience procedures:

```ada
procedure Connect_Clicked
  (W : in out Button_Widget; CB : Click_Callback) is
begin
   W.Clicked.Connect (CB);
end Connect_Clicked;
```

#### Connect_Unique

`Connect_Unique` subscribes only if the same callback is not already active. If the callback is already connected, it returns the existing `Connection_Id` without adding a duplicate:

```ada
--  First call: connects, returns new ID
Id1 := S.Connect_Unique (Handler'Unrestricted_Access);

--  Second call: no-op, returns same ID
Id2 := S.Connect_Unique (Handler'Unrestricted_Access);
--  Id1 = Id2, Subscriber_Count = 1
```

Use `Connect_Unique` when the same connect site may execute multiple times (e.g. in `Build_Items` or a setup loop) and duplicate subscriptions would cause unwanted repeated callbacks.

### Disconnecting

Remove a subscription by ID. Safe to call with `No_Connection` or an already-disconnected ID:

```ada
W.Clicked.Disconnect (Id);

--  Remove all subscribers
W.Clicked.Disconnect_All;
```

### Emitting

Emit sites use the `For_Each` generic procedure with a local visitor that captures the emit arguments:

```ada
procedure On_Click (W : in out Button_Widget) is
   H : constant Widget_Handle := Get_Handle (W);
   procedure Call (CB : Click_Callback) is
   begin
      CB (H);
   end Call;
   procedure Emit_Clicked is new Click_Signals.For_Each (Call);
begin
   Emit_Clicked (W.Clicked);
end On_Click;
```

For signals with value arguments, capture them in the visitor closure:

```ada
procedure Fire_Changed (W : in out Slider_Widget) is
   H   : constant Widget_Handle := Get_Handle (W);
   Val : constant Value_Type := W.Value;
   procedure Call (CB : Value_Changed_Callback) is
   begin
      CB (H, Val);
   end Call;
   procedure Emit is new Value_Changed_Signals.For_Each (Call);
begin
   Emit (W.Changed);
end Fire_Changed;
```

### Emit-During-Modify Safety

`For_Each` snapshots the subscriber count at entry:

- **Connect during emit**: new subscriber appends beyond the snapshot range and will not fire until the next emit.
- **Disconnect during emit**: the slot is tombstoned immediately and skipped by the current iteration.

This means signal handlers can safely connect or disconnect other handlers without corrupting iteration.

### Subscriber Count

```ada
N : Natural := S.Subscriber_Count;
```

Returns the number of active (non-tombstone) subscribers.

### Internals

- Monotonic `Connection_Id` — IDs are never reused
- Tombstone-based disconnection — `Disconnect` marks a slot inactive rather than shifting elements
- Trailing tombstone compaction — `Disconnect` reclaims trailing inactive slots so `Connect` can reuse them
- Dynamic array storage — starts at capacity 4, doubles on growth

### Widget Signal Conventions

Every widget signal follows the same pattern:

1. **Callback type** declared in the widget spec (access-to-procedure)
2. **Signal package** instantiated with `Adi.Signal`
3. **Signal field** stored in the widget's private record
4. **Connect/Disconnect procedures** exposed in the public API
5. **Emit** done internally via a local `For_Each` instantiation

Existing widget signals:

| Widget | Signal | Callback Signature |
|--------|--------|--------------------|
| Button | `Clicked` | `(W : Widget_Handle)` |
| Button | `Toggled` | `(W : Widget_Handle; Active : Boolean)` |
| Button.Options | `Changed` | `(Value : Option_Type)` |
| Slider | `Changed` | `(W : Widget_Handle; Value : Value_Type)` |
| Value_Input | `Changed` | `(W : Widget_Handle; Value : Value_Type)` |
| Text_Input | `Changed` | `(W : Widget_Handle; Text : String)` |
| Text_Editor | `Changed` | `(W : Widget_Handle; Text : String)` |
| List_Box | `Item_Clicked` | `(W : Widget_Handle; Index : Positive)` |
| List_Box | `Item_Activated` | `(W : Widget_Handle; Index : Positive)` |
| List_Box | `Selection_Changed` | `(W : Widget_Handle)` |
| Combo_Box | `Selection_Changed` | `(W : Widget_Handle; Index : Natural; Text : String)` |
| Dialog | `Result` | `(W : Widget_Handle; Index : Natural; Text : String)` |
| Html_View | `Link_Click` | `(Self : access Html_View; Href : String)` |
| Context_Menu | `Item_Selected` | `(Menu : Menu_Handle; Index : Positive; Text : String)` |
| Stack | `Page_Changed` | `(Id : Page_Id)` |
| Window | `Tick` | `(DT : Duration)` |
| Window | `Post_Render` | `(Win : Window_Handle; Renderer : SDL_Renderer_Ptr)` |
| Window | `Frame` | `(Win : Window_Handle)` |
| Window | `Close_Request` | `(Win : Window_Handle; Allow : in out Boolean)` |

### Usage Example

A complete example connecting to a button click:

```ada
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Button; use Adi.Widget.Button;

procedure Setup (Btn : in out Button_Widget) is

   procedure On_Click (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      Adi.Log.Info ("Button clicked!");
   end On_Click;

begin
   Btn.Connect_Clicked (On_Click'Unrestricted_Access);
end Setup;
```

Connecting to a slider value change:

```ada
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Slider; use Adi.Widget.Slider;

procedure Setup (S : in out Slider_Widget) is

   procedure On_Value (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Adi.Log.Info ("Slider: " & Value'Image);
   end On_Value;

begin
   S.Connect_Changed (On_Value'Unrestricted_Access);
end Setup;
```

### Vetoable Signals

The `Close_Request` signal on `Window` demonstrates a vetoable pattern. The callback receives `Allow : in out Boolean`, initialized to `True`. Any subscriber can set it to `False` to prevent the close:

```ada
procedure On_Close
  (Win   : not null access Adi.Window.Window'Class;
   Allow : in out Boolean)
is
begin
   if Has_Unsaved_Changes then
      Allow := False;
      Show_Save_Dialog;
   end if;
end On_Close;

--  Connect:
Win.Connect_Close_Request (On_Close'Unrestricted_Access);
```

The signal fires for both `SDL_EVENT_WINDOW_CLOSE_REQUESTED` (title-bar X) and `SDL_EVENT_QUIT` (Cmd+Q / Alt+F4). With no subscribers connected, close is allowed by default.

### Confirmation dialog pattern and why Request_Quit is needed

The common pattern — show a "Are you sure?" dialog, then quit when the user confirms — requires two separate close-request cycles and cannot be collapsed into one. Here is why, and how the pieces fit together.

#### Why you cannot exit the loop directly from a dialog callback

`Should_Quit`, the flag that terminates `App.Run`'s event loop, is a local variable inside `Run`. Dialog result callbacks (e.g. `On_Quit_Result`) are called deep inside the same event loop, on the call stack:

```
App.Run
  └─ SDL_PollEvent  ← mouse-button-up for "Yes" button
       └─ Window.On_Mouse_Up
            └─ Dialog_Widget.On_Mouse_Up
                 └─ On_Quit_Result   ← you are here
```

`On_Quit_Result` has no way to reach `Should_Quit` — it is a nested local in a different subprogram. There is no shared variable, no handle, no channel to write to. The callback can only act on its own state.

#### Why the callback cannot call Handle_Close_Request directly

`Handle_Close_Request` is the function that emits the `Close_Request` signal and checks whether any subscriber vetoed it. Calling it from inside a `Close_Request` subscriber would be a recursive signal emit — the `On_Close_Request` handler would fire again while it is already on the stack. The `Adi.Signal` implementation supports disconnect-during-emit safely, but re-entrant emission of the same signal from inside one of its own handlers is not a supported or intended pattern.

#### The correct two-cycle sequence

The solution is to post a new SDL event so that the event loop itself invokes the quit path on its own terms, in the next poll iteration. `Adi.App.Request_Quit` does exactly this:

```ada
procedure Request_Quit is
   Event : aliased SDL_Event := (Event_Type => SDL_EVENT_QUIT);
begin
   if not Boolean (SDL_PushEvent (Event'Access)) then
      Adi.Log.Error ("Request_Quit: SDL_PushEvent failed");
   end if;
end Request_Quit;
```

The full sequence for a confirmation dialog is:

```
Cycle 1 — user clicks window X
  SDL queues: SDL_EVENT_WINDOW_CLOSE_REQUESTED
  App.Run picks it up → calls Handle_Close_Request
    → On_Close_Request fires
    → Quit_Confirmed = False, so: Allow := False, Show(Quit_Dialog)
  Handle_Close_Request returns False → loop continues

  [dialog is visible, app keeps running normally]

Cycle N — user clicks "Yes" in dialog
  SDL queues: SDL_BUTTON_UP for "Yes"
  App.Run picks it up → dispatches mouse event to Window → Dialog
    → On_Quit_Result fires
    → sets Quit_Confirmed := True
    → calls Request_Quit → SDL_PushEvent(SDL_EVENT_QUIT)
  Mouse event processing continues, loop continues to next event

  SDL_PollEvent returns the just-pushed SDL_EVENT_QUIT
  App.Run picks it up → calls Handle_Close_Request
    → On_Close_Request fires
    → Quit_Confirmed = True, so: Allow := True (no change needed)
  Handle_Close_Request returns True → Should_Quit := True → loop exits
```

Each close attempt is a complete, independent event-loop cycle. The dialog callback's only job is to set the application-level `Quit_Confirmed` flag and re-enter the quit path via `Request_Quit`. The event loop then handles the quit the same way it would handle any other quit — through the `Close_Request` signal — and the handler allows it because the flag is set.

#### Why not make Should_Quit a field on App

An alternative would be to move `Should_Quit` out of `Run`'s locals and into the `App` record, then expose a `Quit` procedure that sets it. This would let callbacks quit directly. It is not done because:

- It would require `Request_Quit` to take an `App` parameter (or use a global), adding coupling between the dialog callback and the App instance.
- The SDL-event approach is already the idiomatic SDL pattern: SDL itself uses event queues for cross-component communication. Pushing a quit event means the quit goes through the same path as a real OS-initiated quit, exercising the same code.
- The `Close_Request` signal fires on every quit attempt, so application-level guards (`Quit_Confirmed`, unsaved-changes checks, etc.) are always respected regardless of where the quit originates.

## Adi.Dispatch

### Overview

`Adi.Dispatch` provides a thread-safe deferred execution queue. Procedures posted via `Post` are executed on the main thread at the start of the next frame.

```
src/adi-dispatch.ads   -- Spec
src/adi-dispatch.adb   -- Body
```

### API

```ada
type Deferred_Proc is access procedure;

--  Queue a procedure to run on the main thread next frame.
--  Thread-safe: can be called from any Ada task.
procedure Post (Proc : Deferred_Proc);

--  Execute all pending procedures in FIFO order, then clear.
--  Must only be called from the main thread (called by App.Run).
procedure Drain;

--  Number of pending items (for diagnostics).
function Pending_Count return Natural;
```

### Usage

Post a library-level procedure for deferred execution:

```ada
procedure Update_UI is
begin
   --  This runs on the main thread next frame
   My_Label.Set_Text ("Updated");
end Update_UI;

--  From any task or callback:
Adi.Dispatch.Post (Update_UI'Access);
```

### Re-Entrant Safety

`Drain` takes a snapshot (swap) of the queue before executing. If a deferred procedure calls `Post`, the new item goes into the live queue and will be picked up on the **next** frame's `Drain` — preventing unbounded recursion.

### Lifetime Requirement

Callers must pass library-level `'Access`, not `'Unrestricted_Access` on local procedures. Ada accessibility rules enforce this at compile time.

### Integration

`Adi.App.Run` calls `Adi.Dispatch.Drain` once per frame before processing events and rendering. This is automatic — application code only needs to call `Post`.

## Testing

```bash
# Signal tests
alr exec -- gprbuild -j0 -P tests/tests.gpr -XTEST_KIND=signal_test
./tests/bin/signal_test

# Dispatch tests
alr exec -- gprbuild -j0 -P tests/tests.gpr -XTEST_KIND=dispatch_test
./tests/bin/dispatch_test
```
