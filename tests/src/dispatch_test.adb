pragma Ada_2022;

with Adi.Dispatch;
with Adi.Log;

procedure Dispatch_Test is

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Passed := Passed + 1;
      else
         Failed := Failed + 1;
         Adi.Log.Error ("FAIL: " & Msg);
      end if;
   end Assert;

   ---------------------------------------------------------------------------
   --  Global state for tracking execution order
   ---------------------------------------------------------------------------

   Exec_Log     : array (1 .. 20) of Natural;
   Exec_Log_Len : Natural := 0;

   procedure Reset_Exec_Log is
   begin
      Exec_Log_Len := 0;
   end Reset_Exec_Log;

   procedure Log_Exec (Id : Natural) is
   begin
      if Exec_Log_Len < Exec_Log'Last then
         Exec_Log_Len := Exec_Log_Len + 1;
         Exec_Log (Exec_Log_Len) := Id;
      end if;
   end Log_Exec;

   ---------------------------------------------------------------------------
   --  Test procedures (library-level, safe for Post)
   ---------------------------------------------------------------------------

   procedure Proc_A is
   begin
      Log_Exec (1);
   end Proc_A;

   procedure Proc_B is
   begin
      Log_Exec (2);
   end Proc_B;

   procedure Proc_C is
   begin
      Log_Exec (3);
   end Proc_C;

   --  Re-entrant: posts another proc during Drain
   procedure Proc_That_Posts is
   begin
      Log_Exec (10);
      Adi.Dispatch.Post (Proc_C'Unrestricted_Access);
   end Proc_That_Posts;

begin
   Adi.Log.Info ("=== Dispatch Test ===");

   ---------------------------------------------------------------------------
   --  Test 1: Drain with empty queue is a no-op
   ---------------------------------------------------------------------------
   begin
      Adi.Dispatch.Drain;
      Assert (Adi.Dispatch.Pending_Count = 0,
              "drain on empty queue is no-op");
   end;

   ---------------------------------------------------------------------------
   --  Test 2: Post + Drain executes proc
   ---------------------------------------------------------------------------
   begin
      Reset_Exec_Log;
      Adi.Dispatch.Post (Proc_A'Unrestricted_Access);
      Assert (Adi.Dispatch.Pending_Count = 1, "pending count is 1 after post");
      Adi.Dispatch.Drain;
      Assert (Exec_Log_Len = 1, "drain executes posted proc");
      Assert (Exec_Log (1) = 1, "correct proc executed");
      Assert (Adi.Dispatch.Pending_Count = 0,
              "pending count is 0 after drain");
   end;

   ---------------------------------------------------------------------------
   --  Test 3: Multiple posts drain in FIFO order
   ---------------------------------------------------------------------------
   begin
      Reset_Exec_Log;
      Adi.Dispatch.Post (Proc_A'Unrestricted_Access);
      Adi.Dispatch.Post (Proc_B'Unrestricted_Access);
      Adi.Dispatch.Post (Proc_C'Unrestricted_Access);
      Assert (Adi.Dispatch.Pending_Count = 3, "pending count is 3");
      Adi.Dispatch.Drain;
      Assert (Exec_Log_Len = 3, "all three procs executed");
      Assert (Exec_Log (1) = 1, "FIFO order: A first");
      Assert (Exec_Log (2) = 2, "FIFO order: B second");
      Assert (Exec_Log (3) = 3, "FIFO order: C third");
   end;

   ---------------------------------------------------------------------------
   --  Test 4: Post during Drain — new item NOT in current batch
   ---------------------------------------------------------------------------
   begin
      Reset_Exec_Log;
      Adi.Dispatch.Post (Proc_That_Posts'Unrestricted_Access);
      Adi.Dispatch.Drain;
      --  Proc_That_Posts fires (logs 10) and posts Proc_C.
      --  Proc_C should NOT have fired in this Drain.
      Assert (Exec_Log_Len = 1,
              "re-entrant post: new item not in current drain");
      Assert (Exec_Log (1) = 10,
              "re-entrant post: original proc fired");
      Assert (Adi.Dispatch.Pending_Count = 1,
              "re-entrant post: new item pending for next drain");
      --  Now drain again to pick up the re-entrant post
      Adi.Dispatch.Drain;
      Assert (Exec_Log_Len = 2,
              "re-entrant post: second drain picks up new item");
      Assert (Exec_Log (2) = 3,
              "re-entrant post: correct proc fired on second drain");
   end;

   ---------------------------------------------------------------------------
   --  Test 5: Post null is ignored
   ---------------------------------------------------------------------------
   begin
      Adi.Dispatch.Post (null);
      Assert (Adi.Dispatch.Pending_Count = 0,
              "posting null is ignored");
   end;

   ---------------------------------------------------------------------------
   --  Summary
   ---------------------------------------------------------------------------

   Adi.Log.Info ("Dispatch_Test: " & Passed'Image & " passed," &
                 Failed'Image & " failed");
   if Failed > 0 then
      Adi.Log.Error ("DISPATCH TEST FAILED");
   end if;

end Dispatch_Test;
