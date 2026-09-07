# Signals and Deferred Dispatch

Two mechanisms for decoupled communication between components:

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

A handler may therefore connect or disconnect other handlers during an emit.

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
| List_Box | `Item_Clicked` | `(W : Widget_Handle; Index : Positive; Clicks : Natural)` |
| List_Box | `Item_Activated` | `(W : Widget_Handle; Index : Positive)` |
| List_Box | `Selection_Changed` | `(W : Widget_Handle)` |
| Combo_Box | `Selection_Changed` | `(W : Widget_Handle; Index : Natural; Text : String)` |
| Dialog | `Result` | `(W : Widget_Handle; Index : Natural; Text : String)` |
| Html_View | `Link_Click` | `(Self : Html_View_Handle; Href : String)` |
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
  (Win   : Adi.Window.Window_Handle;
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

### Quitting from a dialog

`Should_Quit`, the flag that ends `App.Run`, is local to `Run`, and
`Handle_Close_Request` is the emit of `Close_Request`, so a callback
running inside a dispatch — a dialog's result callback, say — reaches
neither. `Adi.App.Request_Quit` pushes `SDL_EVENT_QUIT` instead, and the
loop takes the quit path on its next poll, through `Close_Request` like
any other quit.

A confirmation dialog is therefore two close-request cycles:

```
User clicks the window X
  SDL queues SDL_EVENT_WINDOW_CLOSE_REQUESTED
  App.Run → Handle_Close_Request → On_Close_Request
    Quit_Confirmed is False: Allow := False, Show (Quit_Dialog)
  loop continues, dialog visible

User clicks "Yes"
  App.Run → Window → Dialog → On_Quit_Result
    Quit_Confirmed := True; Request_Quit
  SDL_PollEvent returns the pushed SDL_EVENT_QUIT
  App.Run → Handle_Close_Request → On_Close_Request
    Quit_Confirmed is True: Allow stays True
  Should_Quit := True, loop exits
```

The dialog callback sets the application's own flag and calls
`Request_Quit`; the `Close_Request` handler reads the flag.

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

`Deferred_Proc` is a library-level access type, so `'Access` is legal on a library-level procedure only, and such a procedure is still there when `Drain` runs.

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
