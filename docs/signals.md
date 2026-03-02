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
type Click_Callback is access procedure (Btn : Button_Widget_Access);

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
   Self : constant Button_Widget_Access := W'Unchecked_Access;
   procedure Call (CB : Click_Callback) is
   begin
      CB (Self);
   end Call;
   procedure Emit_Clicked is new Click_Signals.For_Each (Call);
begin
   Emit_Clicked (W.Clicked);
end On_Click;
```

For signals with value arguments, capture them in the visitor closure:

```ada
procedure Fire_Changed (W : in out Slider_Widget) is
   Self : constant Slider_Widget_Access := W'Unchecked_Access;
   Val  : constant Value_Type := W.Value;
   procedure Call (CB : Value_Changed_Callback) is
   begin
      CB (Self, Val);
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
| Button | `Clicked` | `(Btn : Button_Widget_Access)` |
| Button | `Toggled` | `(Btn : Button_Widget_Access; Active : Boolean)` |
| Button.Options | `Changed` | `(Group : Options_Widget_Access; Page : Page_Id)` |
| Slider | `Changed` | `(W : Slider_Widget_Access; Value : Value_Type)` |
| Value_Input | `Changed` | `(W : Value_Input_Widget_Access; Value : Value_Type)` |
| Text_Input | `Changed` | `(W : Text_Input_Widget_Access)` |
| Text_Editor | `Changed` | `(W : Text_Editor_Widget_Access)` |
| List_Box | `Item_Clicked` | `(W : List_Box_Widget_Access; Index : Positive)` |
| List_Box | `Item_Activated` | `(W : List_Box_Widget_Access; Index : Positive)` |
| List_Box | `Selection_Changed` | `(W : List_Box_Widget_Access)` |
| Combo_Box | `Selection_Changed` | `(W : Combo_Box_Widget_Access; Index : Natural)` |
| Dialog | `Result` | `(Result : Dialog_Result)` |
| Html_View | `Link_Click` | `(URL : String)` |
| Context_Menu | `Item_Selected` | `(Index : Positive)` |
| Stack | `Page_Changed` | `(W : Stack_Widget_Access; Page : Page_Id)` |
| Window | `Tick` | `(DT : Duration)` |
| Window | `Post_Render` | `(W : Window_Access; Renderer : SDL_Renderer_Ptr)` |
| Window | `Frame` | `(W : Window_Access)` |

### Usage Example

A complete example connecting to a button click:

```ada
with Adi.Widget.Button; use Adi.Widget.Button;

procedure Setup (Btn : in out Button_Widget) is

   procedure On_Click (B : Button_Widget_Access) is
   begin
      Adi.Log.Info ("Button clicked!");
   end On_Click;

begin
   Btn.Connect_Clicked (On_Click'Unrestricted_Access);
end Setup;
```

Connecting to a slider value change:

```ada
with Adi.Widget.Slider; use Adi.Widget.Slider;

procedure Setup (S : in out Slider_Widget) is

   procedure On_Value (W : Slider_Widget_Access; Value : Float) is
   begin
      Adi.Log.Info ("Slider: " & Value'Image);
   end On_Value;

begin
   S.Connect_Changed (On_Value'Unrestricted_Access);
end Setup;
```

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
