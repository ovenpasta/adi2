--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Task_Identification; use Ada.Task_Identification;
with Adi.Dispatch;
with Adi.OS;                  use Adi.OS;
with Adi.OS.Testing;
with Test_Support;            use Test_Support;

procedure Os_Dialog_Delivery_Test is

   package Call_Vectors is new Ada.Containers.Vectors
     (Positive, Unbounded_String);

   Main_Task : constant Task_Id := Current_Task;

   --  One entry per callback run: "Name(count):path|path".
   Calls    : Call_Vectors.Vector;
   Off_Main : Natural := 0;
   Claimed  : Boolean := False;

   procedure Record_Call (Name : String; Files : String_Array) is
      Count : constant String := Natural'Image (Files'Length);
      Text  : Unbounded_String := To_Unbounded_String
        (Name & "(" & Count (Count'First + 1 .. Count'Last) & "):");
   begin
      for I in Files'Range loop
         if I > Files'First then
            Append (Text, "|");
         end if;
         Append (Text, Files (I));
      end loop;
      Calls.Append (Text);
      if Current_Task /= Main_Task then
         Off_Main := Off_Main + 1;
      end if;
   end Record_Call;

   procedure On_A (Files : String_Array) is
   begin
      Record_Call ("A", Files);
   end On_A;

   --  Opens the next dialog from inside the answer to the last.
   procedure On_Claim (Files : String_Array) is
   begin
      Record_Call ("Claim", Files);
      Claimed := Adi.OS.Testing.Claim_Dialog;
   end On_Claim;

   --  Opens another dialog, which SDL answers at once.
   procedure On_Reopen (Files : String_Array) is
   begin
      Record_Call ("Reopen", Files);
      Adi.OS.Testing.Post_Dialog_Result
        (On_A'Unrestricted_Access, [To_Unbounded_String ("again.txt")]);
   end On_Reopen;

   --  SDL on Windows answers from a thread of its own.
   procedure Post_From_Task (Callback : Dialog_Callback; Files : String_Array)
   is
      task Answer;
      task body Answer is
      begin
         Adi.OS.Testing.Post_Dialog_Result (Callback, Files);
      end Answer;
   begin
      null;
   end Post_From_Task;

   --  Also closes any dialog a section left open, with an answer that
   --  has no callback.
   procedure Reset is
   begin
      while Adi.Dispatch.Pending_Count > 0 loop
         Adi.Dispatch.Drain;
      end loop;
      Adi.OS.Testing.Post_Dialog_Result (null, Empty_Strings);
      Adi.Dispatch.Drain;
      Calls.Clear;
      Off_Main := 0;
      Claimed := False;
   end Reset;

   function Call (I : Positive) return String is
     (if I <= Natural (Calls.Length) then To_String (Calls (I)) else "");

   procedure Test_Answer_From_Another_Task is
   begin
      Section ("an answer from another task waits for Drain");
      Reset;
      Post_From_Task
        (On_A'Unrestricted_Access,
         [To_Unbounded_String ("/tmp/a.txt"),
          To_Unbounded_String ("/tmp/b.txt")]);
      Assert (Calls.Is_Empty, "callback has not run before Drain");
      Assert (Adi.Dispatch.Pending_Count = 1, "one delivery is queued");

      Adi.Dispatch.Drain;
      Assert (Natural (Calls.Length) = 1, "Drain runs the callback");
      Assert (Call (1) = "A(2):/tmp/a.txt|/tmp/b.txt",
              "callback gets both paths in order, got " & Call (1));
      Assert (Off_Main = 0, "callback runs on the main task");

      Adi.Dispatch.Drain;
      Assert (Natural (Calls.Length) = 1, "a later Drain runs it no more");
   end Test_Answer_From_Another_Task;

   procedure Test_Cancel is
   begin
      Section ("a cancel delivers an empty array");
      Reset;
      Post_From_Task (On_A'Unrestricted_Access, Empty_Strings);
      Assert (Calls.Is_Empty, "cancel has not run before Drain");

      Adi.Dispatch.Drain;
      Assert (Natural (Calls.Length) = 1 and then Call (1) = "A(0):",
              "callback gets no paths, got " & Call (1));
      Assert (Off_Main = 0, "cancel runs on the main task");
   end Test_Cancel;

   procedure Test_One_Dialog_At_A_Time is
   begin
      Section ("one dialog at a time");
      Reset;
      Assert (Adi.OS.Testing.Claim_Dialog, "the first dialog opens");
      Assert (not Adi.OS.Testing.Claim_Dialog,
              "a second is refused while the first is open");

      Post_From_Task
        (On_Claim'Unrestricted_Access, [To_Unbounded_String ("x.txt")]);
      Assert (not Adi.OS.Testing.Claim_Dialog,
              "an answer not yet delivered still holds the dialog open");

      Adi.Dispatch.Drain;
      Assert (Call (1) = "Claim(1):x.txt",
              "the answer is delivered, got " & Call (1));
      Assert (Claimed, "its callback may open the next dialog");
      Assert (not Adi.OS.Testing.Claim_Dialog,
              "which is then the one holding the gate");

      Adi.OS.Testing.Post_Dialog_Result (null, Empty_Strings);
      Adi.Dispatch.Drain;
      Assert (Adi.OS.Testing.Claim_Dialog,
              "an answer with no callback still closes its dialog");
   end Test_One_Dialog_At_A_Time;

   procedure Test_Answer_Posted_By_Callback is
   begin
      Section ("an answer posted by a callback waits for the next Drain");
      Reset;
      Adi.OS.Testing.Post_Dialog_Result
        (On_Reopen'Unrestricted_Access, [To_Unbounded_String ("open.txt")]);

      Adi.Dispatch.Drain;
      Assert (Natural (Calls.Length) = 1
                and then Call (1) = "Reopen(1):open.txt",
              "the Drain that runs the callback leaves its answer queued");

      Adi.Dispatch.Drain;
      Assert (Natural (Calls.Length) = 2 and then Call (2) = "A(1):again.txt",
              "the next Drain delivers it, got " & Call (2));
   end Test_Answer_Posted_By_Callback;

begin
   Start_Suite ("OS Dialog Delivery Test");

   Test_Answer_From_Another_Task;
   Test_Cancel;
   Test_One_Dialog_At_A_Time;
   Test_Answer_Posted_By_Callback;

   Finish;
end Os_Dialog_Delivery_Test;
