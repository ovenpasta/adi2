pragma Ada_2022;

with Adi.Signal;
with Adi.Log;

procedure Signal_Test is

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
   --  Callback type for testing: increments a counter
   ---------------------------------------------------------------------------

   type Test_Callback is access procedure (Value : Positive);

   package Test_Signals is new Adi.Signal
     (Callback_Type => Test_Callback,
      Null_Callback => null);

   use Test_Signals;

   ---------------------------------------------------------------------------
   --  Global state for tracking callback invocations
   ---------------------------------------------------------------------------

   Call_Count : Natural := 0;
   Last_Value : Natural := 0;

   --  Accumulates call order for ordering tests
   type Call_Record is record
      Handler_Id : Positive;
      Value      : Positive;
   end record;
   Call_Log     : array (1 .. 20) of Call_Record;
   Call_Log_Len : Natural := 0;

   procedure Reset_Log is
   begin
      Call_Count := 0;
      Last_Value := 0;
      Call_Log_Len := 0;
   end Reset_Log;

   procedure Log_Call (Handler_Id : Positive; Value : Positive) is
   begin
      Call_Count := Call_Count + 1;
      Last_Value := Value;
      if Call_Log_Len < Call_Log'Last then
         Call_Log_Len := Call_Log_Len + 1;
         Call_Log (Call_Log_Len) := (Handler_Id, Value);
      end if;
   end Log_Call;

   procedure Handler_A (Value : Positive) is
   begin
      Log_Call (1, Value);
   end Handler_A;

   procedure Handler_B (Value : Positive) is
   begin
      Log_Call (2, Value);
   end Handler_B;

   procedure Handler_C (Value : Positive) is
   begin
      Log_Call (3, Value);
   end Handler_C;

   ---------------------------------------------------------------------------
   --  Emit helper
   ---------------------------------------------------------------------------

   Emit_Value : Positive := 1;

   procedure Call_With_Value (CB : Test_Callback) is
   begin
      CB (Emit_Value);
   end Call_With_Value;

   procedure Emit is new Test_Signals.For_Each (Call_With_Value);

   ---------------------------------------------------------------------------
   --  Signal used for connect-during-emit and disconnect-during-emit tests
   ---------------------------------------------------------------------------

   Modify_Sig : Test_Signals.Signal;
   Disconnect_Target : Test_Signals.Connection_Id := Test_Signals.No_Connection;

   procedure Handler_That_Connects (Value : Positive) is
      pragma Unreferenced (Value);
   begin
      Call_Count := Call_Count + 1;
      --  Connect a new handler during emit
      Modify_Sig.Connect (Handler_C'Unrestricted_Access);
   end Handler_That_Connects;

   procedure Handler_That_Disconnects (Value : Positive) is
      pragma Unreferenced (Value);
   begin
      Call_Count := Call_Count + 1;
      --  Disconnect another handler during emit
      Modify_Sig.Disconnect (Disconnect_Target);
   end Handler_That_Disconnects;

   procedure Handler_After_Disconnect (Value : Positive) is
      pragma Unreferenced (Value);
   begin
      --  This should NOT be called if disconnected during emit
      Call_Count := Call_Count + 1;
   end Handler_After_Disconnect;

   procedure Emit_Modify is new Test_Signals.For_Each (Call_With_Value);

begin
   Adi.Log.Info ("=== Signal Test ===");

   ---------------------------------------------------------------------------
   --  Test 1: Emit with zero subscribers
   ---------------------------------------------------------------------------
   declare
      S : Test_Signals.Signal;
   begin
      Reset_Log;
      Emit_Value := 42;
      Emit (S);
      Assert (Call_Count = 0, "emit with zero subscribers fires nothing");
   end;

   ---------------------------------------------------------------------------
   --  Test 2: Connect one, emit fires it
   ---------------------------------------------------------------------------
   declare
      S : Test_Signals.Signal;
   begin
      Reset_Log;
      S.Connect (Handler_A'Unrestricted_Access);
      Emit_Value := 10;
      Emit (S);
      Assert (Call_Count = 1, "single subscriber fires once");
      Assert (Last_Value = 10, "subscriber receives correct value");
   end;

   ---------------------------------------------------------------------------
   --  Test 3: Multiple subscribers fire in connect order
   ---------------------------------------------------------------------------
   declare
      S : Test_Signals.Signal;
   begin
      Reset_Log;
      S.Connect (Handler_A'Unrestricted_Access);
      S.Connect (Handler_B'Unrestricted_Access);
      S.Connect (Handler_C'Unrestricted_Access);
      Emit_Value := 7;
      Emit (S);
      Assert (Call_Count = 3, "three subscribers all fire");
      Assert (Call_Log (1).Handler_Id = 1, "first connected fires first");
      Assert (Call_Log (2).Handler_Id = 2, "second connected fires second");
      Assert (Call_Log (3).Handler_Id = 3, "third connected fires third");
   end;

   ---------------------------------------------------------------------------
   --  Test 4: Disconnect by ID removes only that subscriber
   ---------------------------------------------------------------------------
   declare
      S    : Test_Signals.Signal;
      Id_B : Connection_Id;
   begin
      Reset_Log;
      S.Connect (Handler_A'Unrestricted_Access);
      Id_B := S.Connect (Handler_B'Unrestricted_Access);
      S.Connect (Handler_C'Unrestricted_Access);
      S.Disconnect (Id_B);
      Emit_Value := 5;
      Emit (S);
      Assert (Call_Count = 2, "disconnect removes exactly one subscriber");
      Assert (Call_Log (1).Handler_Id = 1, "handler A still fires");
      Assert (Call_Log (2).Handler_Id = 3, "handler C still fires");
   end;

   ---------------------------------------------------------------------------
   --  Test 5: Disconnect_All clears everything
   ---------------------------------------------------------------------------
   declare
      S : Test_Signals.Signal;
   begin
      Reset_Log;
      S.Connect (Handler_A'Unrestricted_Access);
      S.Connect (Handler_B'Unrestricted_Access);
      S.Disconnect_All;
      Emit_Value := 1;
      Emit (S);
      Assert (Call_Count = 0, "disconnect_all clears all subscribers");
      Assert (S.Subscriber_Count = 0, "subscriber_count is 0 after disconnect_all");
   end;

   ---------------------------------------------------------------------------
   --  Test 6: Subscriber_Count accurate after connect/disconnect
   ---------------------------------------------------------------------------
   declare
      S    : Test_Signals.Signal;
      Id_A : Connection_Id;
      Id_B : Connection_Id;
   begin
      Assert (S.Subscriber_Count = 0, "empty signal has 0 subscribers");
      Id_A := S.Connect (Handler_A'Unrestricted_Access);
      Assert (S.Subscriber_Count = 1, "1 subscriber after connect");
      Id_B := S.Connect (Handler_B'Unrestricted_Access);
      Assert (S.Subscriber_Count = 2, "2 subscribers after second connect");
      S.Disconnect (Id_A);
      Assert (S.Subscriber_Count = 1, "1 subscriber after disconnect");
      S.Disconnect (Id_B);
      Assert (S.Subscriber_Count = 0, "0 subscribers after second disconnect");
   end;

   ---------------------------------------------------------------------------
   --  Test 7: Double-disconnect same ID is a no-op
   ---------------------------------------------------------------------------
   declare
      S  : Test_Signals.Signal;
      Id : Connection_Id;
   begin
      Id := S.Connect (Handler_A'Unrestricted_Access);
      S.Disconnect (Id);
      S.Disconnect (Id);  --  Should not crash
      Assert (S.Subscriber_Count = 0, "double disconnect is safe no-op");
   end;

   ---------------------------------------------------------------------------
   --  Test 8: Disconnect with No_Connection is a no-op
   ---------------------------------------------------------------------------
   declare
      S : Test_Signals.Signal;
   begin
      S.Connect (Handler_A'Unrestricted_Access);
      S.Disconnect (No_Connection);
      Assert (S.Subscriber_Count = 1, "disconnect No_Connection is no-op");
   end;

   ---------------------------------------------------------------------------
   --  Test 9: Connect during emit — new subscriber does NOT fire
   ---------------------------------------------------------------------------
   begin
      Reset_Log;
      Modify_Sig.Disconnect_All;
      Modify_Sig.Connect (Handler_That_Connects'Unrestricted_Access);
      Emit_Value := 1;
      Emit_Modify (Modify_Sig);
      Assert (Call_Count = 1,
              "connect during emit: new subscriber does not fire in current emit");
      --  But the new subscriber is now registered
      Assert (Modify_Sig.Subscriber_Count = 2,
              "connect during emit: new subscriber is registered for next emit");
   end;

   ---------------------------------------------------------------------------
   --  Test 10: Disconnect during emit — disconnected subscriber is skipped
   ---------------------------------------------------------------------------
   begin
      Reset_Log;
      Modify_Sig.Disconnect_All;
      --  Add: Handler_That_Disconnects, then Handler_After_Disconnect
      Modify_Sig.Connect (Handler_That_Disconnects'Unrestricted_Access);
      Disconnect_Target :=
        Modify_Sig.Connect (Handler_After_Disconnect'Unrestricted_Access);
      Emit_Value := 1;
      Emit_Modify (Modify_Sig);
      --  Handler_That_Disconnects fires (Call_Count=1), then
      --  Handler_After_Disconnect should be skipped because it was
      --  disconnected during the emit.
      Assert (Call_Count = 1,
              "disconnect during emit: disconnected subscriber is skipped");
   end;

   ---------------------------------------------------------------------------
   --  Test 11: Null callback connect is a no-op
   ---------------------------------------------------------------------------
   declare
      S  : Test_Signals.Signal;
      Id : Connection_Id;
   begin
      Id := S.Connect (null);
      Assert (Id = No_Connection, "null connect returns No_Connection");
      Assert (S.Subscriber_Count = 0, "null connect does not add subscriber");
   end;

   ---------------------------------------------------------------------------
   --  Test 12: Trailing tombstone compaction — churn does not grow unbounded
   ---------------------------------------------------------------------------
   declare
      S  : Test_Signals.Signal;
      Id : Connection_Id;
   begin
      --  Connect and disconnect 100 times; Count should stay compact.
      for J in 1 .. 100 loop
         Id := S.Connect (Handler_A'Unrestricted_Access);
         S.Disconnect (Id);
      end loop;
      Assert (S.Subscriber_Count = 0,
              "churn: no active subscribers after 100 connect/disconnect cycles");
      --  After compaction, a fresh connect should work at slot 1.
      Id := S.Connect (Handler_B'Unrestricted_Access);
      Assert (S.Subscriber_Count = 1,
              "churn: connect after compaction works");
      Reset_Log;
      Emit_Value := 7;
      Emit (S);
      Assert (Call_Count = 1, "churn: emit fires the surviving subscriber");
   end;

   ---------------------------------------------------------------------------
   --  Test 13: Disconnect compacts trailing but not interior tombstones
   ---------------------------------------------------------------------------
   declare
      S      : Test_Signals.Signal;
      Id_A   : Connection_Id;
      Id_B   : Connection_Id;
      Id_C   : Connection_Id;
   begin
      Id_A := S.Connect (Handler_A'Unrestricted_Access);
      Id_B := S.Connect (Handler_B'Unrestricted_Access);
      Id_C := S.Connect (Handler_C'Unrestricted_Access);
      --  Disconnect middle, then tail — tail compaction should shrink past B
      S.Disconnect (Id_B);  --  B is interior tombstone, Count stays 3
      S.Disconnect (Id_C);  --  C is trailing, compacts past B too → Count=1
      Assert (S.Subscriber_Count = 1,
              "trailing compact: only A remains");
      Reset_Log;
      Emit_Value := 8;
      Emit (S);
      Assert (Call_Count = 1, "trailing compact: emit fires only A");
      pragma Unreferenced (Id_A);
   end;

   ---------------------------------------------------------------------------
   --  Test 14: Connect_Unique adds a new callback
   ---------------------------------------------------------------------------
   declare
      S  : Test_Signals.Signal;
      Id : Connection_Id;
   begin
      Id := S.Connect_Unique (Handler_A'Unrestricted_Access);
      Assert (Id /= No_Connection, "connect_unique returns valid ID");
      Assert (S.Subscriber_Count = 1, "connect_unique adds subscriber");
   end;

   ---------------------------------------------------------------------------
   --  Test 15: Connect_Unique with duplicate is a no-op
   ---------------------------------------------------------------------------
   declare
      S   : Test_Signals.Signal;
      Id1 : Connection_Id;
      Id2 : Connection_Id;
   begin
      Id1 := S.Connect_Unique (Handler_A'Unrestricted_Access);
      Id2 := S.Connect_Unique (Handler_A'Unrestricted_Access);
      Assert (Id1 = Id2, "connect_unique duplicate returns same ID");
      Assert (S.Subscriber_Count = 1,
              "connect_unique duplicate does not add subscriber");
   end;

   ---------------------------------------------------------------------------
   --  Test 16: Connect_Unique with null callback returns No_Connection
   ---------------------------------------------------------------------------
   declare
      S  : Test_Signals.Signal;
      Id : Connection_Id;
   begin
      Id := S.Connect_Unique (null);
      Assert (Id = No_Connection,
              "connect_unique null returns No_Connection");
      Assert (S.Subscriber_Count = 0,
              "connect_unique null does not add subscriber");
   end;

   ---------------------------------------------------------------------------
   --  Test 17: Connect_Unique after disconnect allows re-connection
   ---------------------------------------------------------------------------
   declare
      S   : Test_Signals.Signal;
      Id1 : Connection_Id;
      Id2 : Connection_Id;
   begin
      Id1 := S.Connect_Unique (Handler_A'Unrestricted_Access);
      S.Disconnect (Id1);
      Assert (S.Subscriber_Count = 0,
              "connect_unique re-add: 0 after disconnect");
      Id2 := S.Connect_Unique (Handler_A'Unrestricted_Access);
      Assert (Id2 /= No_Connection,
              "connect_unique re-add: returns valid ID");
      Assert (Id2 /= Id1,
              "connect_unique re-add: returns new ID (not old)");
      Assert (S.Subscriber_Count = 1,
              "connect_unique re-add: 1 subscriber");
   end;

   ---------------------------------------------------------------------------
   --  Test 18: Regular Connect allows duplicates, Connect_Unique does not
   ---------------------------------------------------------------------------
   declare
      S : Test_Signals.Signal;
   begin
      S.Connect (Handler_A'Unrestricted_Access);
      S.Connect (Handler_A'Unrestricted_Access);
      Assert (S.Subscriber_Count = 2,
              "regular connect allows duplicates");
      S.Disconnect_All;
      S.Connect_Unique (Handler_A'Unrestricted_Access);
      S.Connect_Unique (Handler_A'Unrestricted_Access);
      Assert (S.Subscriber_Count = 1,
              "connect_unique prevents duplicates");
   end;

   ---------------------------------------------------------------------------
   --  Test 19: Connect_Unique with different callbacks adds both
   ---------------------------------------------------------------------------
   declare
      S : Test_Signals.Signal;
   begin
      Reset_Log;
      S.Connect_Unique (Handler_A'Unrestricted_Access);
      S.Connect_Unique (Handler_B'Unrestricted_Access);
      Assert (S.Subscriber_Count = 2,
              "connect_unique adds distinct callbacks");
      Emit_Value := 3;
      Emit (S);
      Assert (Call_Count = 2, "connect_unique distinct: both fire");
   end;

   ---------------------------------------------------------------------------
   --  Summary
   ---------------------------------------------------------------------------

   Adi.Log.Info ("Signal_Test: " & Passed'Image & " passed," &
                 Failed'Image & " failed");
   if Failed > 0 then
      Adi.Log.Error ("SIGNAL TEST FAILED");
   end if;

end Signal_Test;
