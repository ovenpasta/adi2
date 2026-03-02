pragma Ada_2022;

package Adi.Dispatch is

   ---------------------------------------------------------------------------
   --  Deferred execution queue
   --
   --  Post queues a procedure to run on the main thread at the start of
   --  the next frame. Thread-safe: can be called from any Ada task.
   --
   --  Drain executes all pending procedures in FIFO order, then clears
   --  the queue. Must only be called from the main thread (App.Run loop).
   --
   --  Re-entrant safety: Drain takes a snapshot (swap) of the queue.
   --  If a deferred proc calls Post, the new item goes into the live
   --  queue and will be picked up on the next frame's Drain — preventing
   --  unbounded recursion.
   --
   --  Lifetime: callers MUST pass library-level 'Access, not
   --  'Unrestricted_Access on local procedures. Ada accessibility rules
   --  enforce this at compile time.
   ---------------------------------------------------------------------------

   type Deferred_Proc is access procedure;

   --  Queue a procedure to run on the main thread next frame.
   --  Thread-safe.
   procedure Post (Proc : Deferred_Proc);

   --  Execute all pending deferred procedures. Main thread only.
   procedure Drain;

   --  Number of pending items (for diagnostics).
   function Pending_Count return Natural;

end Adi.Dispatch;
