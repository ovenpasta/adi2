# Callback Dispatch and Cross-Task Operation Model — Design Notes

Status: **proposal** — discussion document, not yet implemented.

This document captures the design discussion around Adi's callback
model: what's in the tree today, the two communication directions
between user code and the GUI task, the gaps in each, a critique of
an earlier 26-section proposal that tried to overhaul the entire
model, and the recommended phased implementation that stays close to
Adi's existing primitives.

---

## 1. What Adi has today

Three core modules already cover most of the surface area. A new
callback/dispatch design should compose with them, not replace them.

### 1.1 `Adi.Signal` — generic multi-subscriber signal
`src/adi-signal.ads/adb`. Each widget instantiates one package per
event shape, e.g.:

```ada
type Click_Callback is access procedure (W : Widget_Handle);
package Click_Signals is new Adi.Signal (Click_Callback, null);
```

Properties:
* `Connect (S, CB) return Connection_Id` — monotonic id, never reused.
* `Disconnect (S, Id)` — tombstone-based.
* `For_Each` snapshots length at entry, so connect-during-emit and
  disconnect-during-emit are safe (the re-entrancy contract).
* Subscribers fire **inline** on the emitting task, in registration
  order.

### 1.2 `Adi.Dispatch` — task-safe deferred queue
`src/adi-dispatch.ads/adb`. One global FIFO of parameterless
procedures:

```ada
type Deferred_Proc is access procedure;
procedure Post  (Proc : Deferred_Proc);   -- any task
procedure Drain;                           -- main task only, FIFO
```

`App.Run` calls `Adi.Dispatch.Drain` once per frame, after the SDL
pump and before `Tick`/`Render` (`src/adi-app.adb:268`). It exists for
application tasks; no in-tree package posts to it.

### 1.3 `Adi.Handle_Store` — generation-checked id primitive
`src/adi-handle_store.ads`. Record `(Index, Gen)`, `Null` sentinel,
`Request_Destroy` / `Pump` / pin / unpin. Any new id-typed surface in
the framework should be an instance of this, not a parallel invention.

### 1.4 Single-task model + per-frame pumps
Adi is single-task by design. `App.Run` is the only main loop. The
per-frame order is fixed and forms the contract every "deferred"
mechanism plugs into:

```
SDL_PollEvent loop (dispatches widget events INLINE)
Adi.Dispatch.Drain
Pump_Widget_Store
Pump_Menu_Store
Pump_Window_Store
Tick (Window.Tick — Tick_Signals + widget On_Tick)
Render
sleep until next frame
```

No in-tree package creates a task today.

---

## 2. The two communication directions

Every callback / dispatch discussion is really one of two questions:

### 2.1 GUI → user code (callbacks)
Today: synchronous, inline on the GUI task. The full path for a
button click is

```
App.Run (GUI task)
  SDL_PollEvent
    Window.On_Mouse_Up
      Button_Widget.On_Click
        Click_Signals.For_Each (Call)
          user On_Click (Btn_Handle)   -- still GUI task
```

Guarantees for callback authors today:
1. You're on the GUI task; you can freely touch widgets, fonts, items.
2. You're inside the SDL event handler; the frame hasn't rendered yet.
3. You block the GUI while you run. Long work freezes input + render.
4. Multiple subscribers run in registration (FIFO) order.
5. **An exception in subscriber #2 prevents subscriber #3 from running
   and propagates out into the SDL pump.**

### 2.2 User task → GUI code (operations)
Today: `Adi.Dispatch.Post (My_Proc'Access)`. The worker task
parameterless-posts a procedure that runs during the next
`Adi.Dispatch.Drain`. Idioms in tree:

```ada
task body Loader is begin
   Result := Do_Heavy_Work;
   Latest := Result;                              -- shared protected
   Adi.Dispatch.Post (Apply_On_Main'Access);
end Loader;

procedure Apply_On_Main is begin
   Adi.Widget.Label.Set_Text (Status, To_String (Latest));
end Apply_On_Main;
```

Gaps today: no typed payload, no completion status, no `Wait`, no
cancellation. Every worker that wants any of those rolls its own
protected-object handshake.

---

## 3. Critique of the earlier 26-section proposal

(Preserved here because the analysis informs the chosen design.)

### 3.1 What the earlier proposal got right
* `Invocation` tagged objects — a refinement of `Deferred_Proc`
  that carries typed payload.
* `Single_Shot` connection mode with consume-on-post semantics.
* Per-operation status + `Wait` + cancellation.
* "User code never runs inside a protected action" as an explicit
  framework-wide rule.
* `In_GUI_Task` predicate (necessary the moment any synchronous
  `Wait` is added).
* Exception containment in the dispatcher.

### 3.2 What it over-designed (rejected)
* **`Event_Type_Id` registry.** Adi already gets unique event
  identity from per-callback-type `Adi.Signal` package
  instantiations. Adding a runtime registry of named ids with
  elaboration-order hazards solves no problem the framework has.
* **Multiple user-visible `Dispatcher` types** with priority queues
  and per-dispatcher dispatch order. Adi is single-task; the
  per-frame pump chain in `App.Run` already orders work between
  classes. Until a multi-worker workload concretely exists,
  exposing `Dispatcher` as a first-class user type is speculative.
* **Per-operation `Priority`.** One drain per frame, sub-millisecond
  to traverse. No measured win.
* **Merging `Operation_Id` and `Connection_Id`.** They're different
  concepts (job vs subscription) with different lifecycle rules;
  the unification was a false economy.
* **`Cancel` of running operations.** Ada has no safe arbitrary
  task termination. Public API should not pretend otherwise.

### 3.3 What it missed
* **Interaction with `Adi.Widget.Borrow`** and the single-task
  widget invariant. The proposal's "callback runs on a user task"
  feature is unusable for code that wants to touch widgets without
  rules.
* **Memory ownership of `Invocation_Access`** when `Status`/`Wait`
  outlive `Execute`. The invocation object and the per-id status
  metadata must live in separate stores.
* **Where the new module sits.** No explicit placement against
  `Adi.Signal` and `Adi.Dispatch`.

---

## 4. Proposed design

Three orthogonal additions, each independently shippable, each
building on existing primitives. No new framework core.

### Phase A — Exception isolation in `Adi.Signal`

**Problem.** `Signal.For_Each` calls user `Visitor` inline; an
exception aborts the rest of the emit and propagates into the SDL
pump.

**Change.** Wrap each per-subscriber `Visitor` invocation:

```ada
begin
   Visitor (CB);
exception
   when E : others =>
      Adi.Log.Error
        ("Signal subscriber raised in " & Source_Tag &
         " (conn=" & Image (Id) & "): " &
         Ada.Exceptions.Exception_Message (E));
      Slot.Fault_Count := Slot.Fault_Count + 1;
      if Slot.Fault_Count > Auto_Disconnect_Threshold then
         Disconnect (S, Id);
      end if;
end;
```

Behaviour additions:
1. `Signal.Set_Auto_Disconnect_After (N)` — default 0 (never),
   opt-in.
2. New optional `Source : String` parameter on `Connect`, surfaces
   in log lines; widget packages pass `"button.clicked"` etc.

**Surface change.** None for existing callers (new params default to
opt-out).

### Phase B — Single-shot connections in `Adi.Signal`

**Problem.** "Fire-once-and-disconnect" requires the user to
disconnect inside the callback, which is awkward and races with
re-entrant emits.

**Change.** Extend `Connect`:

```ada
type Connection_Mode is (Persistent, Single_Shot);

function Connect
  (S      : in out Signal;
   CB     : Callback_Type;
   Mode   : Connection_Mode := Persistent;
   Source : String := "") return Connection_Id;
```

Semantics:
* A single-shot connection is **atomically tombstoned the first time
  `For_Each` visits it, before the user `Visitor` is called.**
  (Consume on post-to-call, not on call-success.)
* If `Visitor` raises, the connection stays tombstoned — otherwise
  two events in one frame could both invoke the same single-shot.
* `Disconnect (already-fired-id)` is a no-op (matches current
  stale-id behavior).

Done in tandem with Phase A — both touch `For_Each` and they share
the per-slot record extension.

### Phase C — `Adi.Operation`: typed cross-task work

**Problem.** `Adi.Dispatch.Post` is parameterless and fire-and-forget.

**Module spec sketch:**

```ada
package Adi.Operation is

   type Operation is abstract tagged limited private;
   type Operation_Access is access all Operation'Class;

   procedure Execute (Op : in out Operation) is abstract;
   procedure Finalize_Op (Op : in out Operation) is null;

   type Operation_Id is private;
   No_Operation : constant Operation_Id;

   type Op_Status is
     (Pending, Running, Completed, Failed, Cancelled);
   function Is_Terminal (S : Op_Status) return Boolean;

   --  Posting (ownership of Op transfers to the runtime).
   function Post (Op : not null Operation_Access) return Operation_Id;
   procedure Post (Op : not null Operation_Access);   -- discard id

   --  Convenience: post a parameterless Action_Proc closure.
   type Action_Proc is access procedure;
   function Post_Proc (P : Action_Proc) return Operation_Id;
   procedure Post_Proc (P : Action_Proc);

   --  Status & waiting.
   function Status (Id : Operation_Id) return Op_Status;
   procedure Wait (Id : Operation_Id);
   function Wait (Id : Operation_Id; Timeout : Duration) return Boolean;
   function Failure_Message (Id : Operation_Id) return String;

   --  Cancellation: Pending → Cancelled. Running/terminal: no-op.
   function Cancel_Pending (Id : Operation_Id) return Boolean;

   --  Predicate: true iff caller is the task running App.Run.
   function In_GUI_Task return Boolean;

end Adi.Operation;
```

#### C.1 Drain integration
`App.Run`'s `Adi.Dispatch.Drain` call becomes `Adi.Operation.Drain`.
The new drain pops each op under a protected lock, then **outside**
the lock transitions `Pending → Running`, runs `Execute`, transitions
to `Completed`/`Failed`, calls `Finalize_Op`, and marks the slot
ready to evict.

`Adi.Dispatch.Post (Deferred_Proc)` becomes a thin alias of
`Post_Proc`, so existing callers (including `Adi.RLottie`) compile
unchanged.

#### C.2 Registry & memory ownership
Registry is `Adi.Handle_Store`-backed, keyed by `Operation_Id`:

```ada
type Slot is record
   Op           : Operation_Access := null;
   Status       : Op_Status        := Pending;
   Failure      : Unbounded_String := Null_Unbounded_String;
   Waiter_Count : Natural          := 0;   --  pin/unpin
end record;
```

The `Op` object is freed right after `Finalize_Op`. The slot's
status/message survive on the slot until the last `Wait`/`Status`/
`Failure_Message` caller drops `Waiter_Count` to 0, at which point
the per-frame `Adi.Operation.Pump` evicts it. This separates the
two stores the earlier proposal conflated.

#### C.3 Deadlock guard
`Wait` from the GUI task with non-terminal status raises
`Program_Error`. Pattern for "if I'm already on the GUI task, run
inline":

```ada
if Adi.Operation.In_GUI_Task then
   Execute (Op.all);
else
   Id := Adi.Operation.Post (Op);
   Adi.Operation.Wait (Id);
end if;
```

No auto-inline behind the user's back.

### Phase D — User-owned Operation queues (the missing reverse path)

**Problem.** Phase C handles user task → GUI. But "GUI emits signal,
callback runs in a *specific user task*" is the symmetric direction,
and `Adi.Dispatch` gives no support for it. Without it, a worker task
that wants to react to UI events still has to build its own queue +
ack handshake.

**Change.** Reuse Phase C's runtime. A queue is just an
`Operation_Access` FIFO with a blocking `Take`. The GUI's per-frame
drain becomes a special case of this same primitive against the
implicit `GUI_Queue`.

```ada
package Adi.Operation is
   ...

   type Queue is tagged limited private;
   type Queue_Access is access all Queue;

   --  The GUI queue (drained by App.Run once per frame).
   function GUI_Queue return Queue_Access;

   --  User-owned queue (typically a package-level aliased object
   --  in a worker task).
   procedure Initialize (Q : in out Queue);
   procedure Finalize (Q : in out Queue);

   --  Targeted post; default targets GUI_Queue.
   function Post
     (Op     : not null Operation_Access;
      Target : Queue_Access) return Operation_Id;

   --  Block, execute one op on calling task. Exceptions caught and
   --  surfaced via Status/Failure_Message (worker loop doesn't die).
   procedure Dispatch_Next      (Q : in out Queue);
   function  Try_Dispatch_Next  (Q : in out Queue) return Boolean;
   procedure Dispatch_Pending   (Q : in out Queue);
   function  Pending            (Q : Queue) return Natural;
end Adi.Operation;
```

#### D.1 Signal opt-in
`Adi.Signal.Connect` grows an optional `Target_Queue` parameter.
Default `null` keeps existing inline-on-GUI-task semantics. Non-null
makes emit time enqueue an invocation onto that queue instead of
calling the user callback inline.

`Adi.Signal` itself is generic over an abstract `Callback_Type`, so
the signal package cannot box up the invocation. Each widget that
wants to support queueable callbacks instantiates one tiny nested
generic next to its `*_Signals` instance:

```ada
package Click_Invocations is new Adi.Signal.Build_Invocation
  (Callback_Type => Click_Callback);

procedure Call (CB : Click_Callback; Q : Queue_Access) is
begin
   if Q = null then
      CB (H);                                       -- inline (today)
   else
      Discard := Adi.Operation.Post
        (Click_Invocations.Make (CB, (W => H)), Q);
   end if;
end Call;
procedure Emit is new Click_Signals.For_Each_With_Queue (Call);
```

~15 lines per widget that opts in. Widgets that don't opt in keep
the inline-only emit and silently ignore (with a one-time
`Adi.Log.Warning`) any caller that passes a `Target_Queue`.

#### D.2 End-to-end worker pattern

```ada
--  Worker task package
package Worker is
   procedure Setup;
private
   Q : aliased Adi.Operation.Queue;
end Worker;

package body Worker is

   procedure Handle_Click (W : Adi.Widget.Widget_Handle) is
   begin
      --  Runs in THIS task. Must NOT touch widget state directly.
      --  Process locally + Post back to GUI_Queue for mutations.
      Process_Click (W);
   end Handle_Click;

   task body Loop_T is
   begin
      loop
         Adi.Operation.Dispatch_Next (Q);
      end loop;
   end Loop_T;

   procedure Setup is
   begin
      Adi.Operation.Initialize (Q);
      Discard := Connect_Clicked
        (Some_Button, Handle_Click'Access,
         Target_Queue => Q'Access);
   end Setup;

end Worker;
```

The round trip GUI → worker → GUI:

```ada
--  Worker task: schedule a widget mutation back on GUI
type Update is new Adi.Operation.Operation with record
   Label : Adi.Widget.Label.Label_Handle;
   Text  : Unbounded_String;
end record;
overriding procedure Execute (Op : in out Update) is
begin
   Adi.Widget.Label.Set_Text (Op.Label, To_String (Op.Text));
end Execute;

Discard := Adi.Operation.Post  --  defaults to GUI_Queue
  (new Update'(Label => Status_Lbl,
               Text  => To_Unbounded_String ("done")));
```

#### D.3 Lifetime rules
* Each `Queue` registers itself in a small global table on
  `Initialize` and unregisters on `Finalize`. Emit checks the
  queue's validity bit; stale queue reference → connection is
  silently disconnected (same policy as a destroyed widget for an
  Operation_Id).
* Worker callbacks that raise → `Failed` status, worker loop keeps
  running (`Dispatch_Next` catches), GUI emits unaffected.
* App shutdown: `App.Run` exits, no further GUI emits happen,
  worker queues drain naturally on next `Dispatch_Next`. Workers
  must have their own loop-exit condition (typically a
  `Sentinel_Op` the GUI posts during shutdown).
* **Widget access from worker task is forbidden.** Widgets aren't
  thread-safe. The worker's callback may read captured args and
  must `Post` back to `GUI_Queue` for any widget mutation.
  Consider an assertion inside `Adi.Widget.Borrow`
  (`pragma Assert (Adi.Operation.In_GUI_Task)`) to catch
  violations early.

### Phase E — Coalescing for flood-style events (deferred)

Out of v1 scope. Mouse-move / window-resize / scroll-wheel are the
only event classes where per-frame coalescing would matter; SDL
already drops redundant motion events when configured, and current
widgets handle the spam. Revisit only if profiling shows callback
overhead is significant.

---

## 5. What this proposal explicitly does NOT do

These are dropped from the earlier 26-section design:

| Dropped item | Why |
|---|---|
| `Event_Type_Id` registry | `Adi.Signal` instantiations already provide unique event identity at compile time. |
| Multiple user-visible `Dispatcher` types | The implicit `GUI_Queue` + user-owned `Queue` (Phase D) covers every workload we can name today. |
| Per-Operation `Priority` | One drain per frame is fast; intra-queue priority adds API surface for no measured win. |
| Merging `Operation_Id` and `Connection_Id` | Different concepts, different lifecycles. Two types. |
| `Cancel` of running ops | Cooperative cancellation only, via user-defined polling. Not surfaced. |

---

## 6. Migration story

| Today | After |
|---|---|
| `Adi.Dispatch.Post (My_Proc'Access)` | Unchanged. Internally aliased to `Adi.Operation.Post_Proc`. |
| `Connect_Clicked (W, CB)` | Unchanged. |
| `Connect_Clicked (W, CB, Mode => Single_Shot)` | New, opt-in. |
| Subscriber raises an exception | Frame survives; user sees a logged error; subscriber stays connected unless `Set_Auto_Disconnect_After` is configured. |
| Worker task wants result acked | Move to `Adi.Operation.Post (new My_Op'(…))` + `Wait`. |
| Worker task wants GUI clicks delivered to itself | `Connect_Clicked (..., Target_Queue => My_Q'Access)` + `Dispatch_Next (My_Q)` loop. |

No existing caller is forced to change. All public symbols stay
where they are.

---

## 7. Files affected

* `src/adi-signal.ads/adb` — Phases A + B + D.
* `src/adi-operation.ads/adb` — **new**, Phases C + D.
* `src/adi-dispatch.ads/adb` — thin wrapper after C ships; can be
  deprecated later.
* `src/adi-app.adb` — swap `Adi.Dispatch.Drain` for
  `Adi.Operation.Drain` (== `Dispatch_Pending (GUI_Queue.all)`);
  add `Adi.Operation.Pump` to the pump chain.
* Per-widget bodies (Button, Slider, Combo_Box, Html_View,
  Text_Editor, Window.Tick) — Phase D opt-in. Pure addition;
  default `Target_Queue => null` keeps inline behaviour.
* `docs/signals.md` — **new or updated**, covers Phases A + B + D.
* `docs/operations.md` — **new**, covers Phase C + Queue (D).

---

## 8. Reused utilities (no re-implementation)

* `Adi.Handle_Store` for `Operation_Id` — don't roll a fresh
  generation-checked id type.
* `Adi.Log` for the per-subscriber exception logging.
* `Adi.Signal.For_Each` snapshot pattern — extend in place, don't
  parallel-implement.

---

## 9. Verification

### Phase A
* `tests/src/signal_test.adb` — connect three subscribers, middle
  raises, first + third still fire; `Subscriber_Count` unchanged.
* Configure `Set_Auto_Disconnect_After (1)`, emit twice with raising
  subscriber, assert auto-disconnect.

### Phase B
* Connect single-shot, emit twice, assert subscriber called once.
* Re-entrancy: single-shot subscriber that itself disconnects
  another single-shot mid-`For_Each`. Verify no double-call.

### Phase C
* `tests/src/operation_test.adb` — **new**.
  * `Post_Proc` from main task, drain, observe `Completed`.
  * Background task `Post` of a custom `Operation`, main thread
    drains, background `Wait` returns `Completed`.
  * Background task `Post`, `Cancel_Pending` immediately, drain,
    assert `Cancelled` and `Execute` never called.
  * Background task `Post` of an op that raises, drain, background
    observes `Failed` + non-empty `Failure_Message`.
  * GUI-task `Wait` with non-terminal status raises `Program_Error`.

### Phase D
* Worker task creates a `Queue`, connects to a `Click_Signals`
  instance, GUI emits twice, worker's `Dispatch_Next` runs twice
  in order.
* Worker callback raises → `Failed` status, worker loop keeps
  running, GUI emits unaffected.
* `Finalize (Q)` while emit is racing → no segfault, pending ops
  become `Cancelled`.
* `Target_Queue = null` (existing) — assert no regression in
  timing relative to today's inline path.

### Integration
* Migrate `Adi.RLottie`'s `Adi.Dispatch.Post` calls to
  `Adi.Operation.Post_Proc`. Existing example runs unchanged.
* `examples/wasabee_browser_example`'s libcurl fetch (currently
  synchronous, blocking in `Build_Items`) becomes a candidate for
  moving onto a worker task using Phase C — separate follow-up
  commit after the runtime lands.

---

## 10. Open questions

1. **Naming.** `Adi.Operation` vs `Adi.Task_Op` vs
   `Adi.Dispatch.Typed`. Preference: `Adi.Operation` (short,
   doesn't collide with Ada `task`). `Queue` is generic — bare
   type name is fine inside the namespace.
2. **Deprecate `Adi.Dispatch.Post` or keep forever?** Recommendation
   is to keep — the symbol is entrenched and covers 90% of callers.
3. **Per-subscriber exception logging granularity.** Message only
   by default; full `GNAT.Traceback.Symbolic` traceback only when
   `Adi.Log` debug level is on.
4. **`Set_Auto_Disconnect_After` default.** 0 (never) for
   bit-exact backwards compatibility.
5. **Single-shot for `Adi.Window.Connect_Tick`.** "Do this at the
   start of the next frame" is a useful primitive; free with
   Phase B.
6. **`Build_Invocation` placement.** Explicit nested generic per
   widget (clear, no reflection). Alternatives like
   `Ada.Tags.Generic_Dispatching_Constructor` were considered and
   rejected as harder to reason about.
7. **`Adi.Widget.Borrow` thread-safety assertion.** Add
   `pragma Assert (Adi.Operation.In_GUI_Task)` inside `Borrow`
   as part of Phase D so worker-task widget access faults loudly
   at construction rather than silently corrupting state later.

---

## Appendix A — Today's "how do I do X" answers

For reference until Phases C and D ship.

### A.1 User task → GUI task communication
Use `Adi.Dispatch.Post (My_Proc'Access)`. The procedure runs on
the GUI task during the next `Adi.Dispatch.Drain` (called once per
frame). To carry typed data, stash it in a protected object first;
the posted procedure reads it on the GUI side. Pattern:

```ada
task body Loader is
   Result : Some_Heavy_Result;
begin
   Result := Do_Heavy_Work;
   Latest.Set (Result);                       -- protected obj
   Adi.Dispatch.Post (Apply_On_Main'Access);
end Loader;

procedure Apply_On_Main is
begin
   Adi.Widget.Label.Set_Text (Status, Latest.Get_Text);
   Adi.Widget.Mark_Dirty (+View);
end Apply_On_Main;
```

This is what `Adi.RLottie` does for background SVG decoding.

### A.2 GUI → user task communication
**Not supported as a primitive.** Callbacks run inline on the GUI
task. Workaround: inside the callback, hand work to a worker task
(via a protected object queue) and return immediately. Pattern:

```ada
procedure On_Click (Btn : Widget_Handle) is
begin
   Worker_Inbox.Submit (Get_Url);          -- returns immediately
end On_Click;

task body Worker is
   Url : Unbounded_String;
begin
   loop
      Worker_Inbox.Take (Url);             -- blocks
      declare
         Result : constant String := Fetch (To_String (Url));
      begin
         Latest.Set (Result);
         Adi.Dispatch.Post (Apply_On_Main'Access);
      end;
   end loop;
end Worker;
```

The callback is microseconds; the worker does the slow part;
`Adi.Dispatch.Post` brings the result back. This is the manual
version of the round-trip Phase C + D supports as one-liners.

### A.3 What if a callback raises?
Today: bad. The exception propagates through `Signal.For_Each`,
through the widget's `On_*` virtual, through the SDL event handler,
and into `App.Run`'s outer loop where it'll terminate the frame.
Phase A fixes this with a per-subscriber catch.

### A.4 Long work in a callback
Don't. The callback runs on the GUI task; a 200ms decode = visibly
dropped frames. Use the worker pattern above. After Phase C +
Phase D, the worker-task variant of `Connect_*` keeps the
ergonomic signature but routes the call to your task instead of
blocking the GUI.
