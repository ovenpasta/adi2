--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Test_Support; use Test_Support;
with Adi.Slot_Pool;
with Adi.Slot_Pool.Refs;

procedure Slot_Pool_Test is

   --  No component default, so the pool's instantiation carries the
   --  restrictions below: GNAT charges a payload's default-initialization
   --  procedure against both, and that charge belongs to the payload
   --  rather than to any pool code.
   type Marker is record
      Tag : Integer;
   end record;

   Capacity : constant := 4;

   --  The pool spends no secondary stack and no heap, and the compiler
   --  holds that here rather than a comment asserting it.
   package Pool is new Adi.Slot_Pool (Payload => Marker, Capacity => Capacity)
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);
   package Pool_Refs is new Pool.Refs
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   use Pool;
   use type Pool_Refs.Const_Access;
   use type Pool_Refs.Var_Access;

   --  Refused says Get raised; otherwise Answered carries what it gave,
   --  so a check can say what a stale name reads as rather than only
   --  that it failed.
   procedure Try_Get
     (S : Slot; Refused : out Boolean; Answered : out Integer) is
   begin
      Answered := Get (S).Tag;
      Refused := False;
   exception
      when Constraint_Error =>
         Answered := 0;
         Refused := True;
   end Try_Get;

   function Set_Refused (S : Slot; Tag : Integer) return Boolean is
   begin
      Set (S, (Tag => Tag));
      return False;
   exception
      when Constraint_Error =>
         return True;
   end Set_Refused;

   ---------------------------------------------------------------------------

   procedure Test_Empty_Pool is
      Refused  : Boolean;
      Answered : Integer;
   begin
      Section ("a pool with nothing taken");

      Assert (Held = 0, "the pool starts empty");
      Assert (not Live (No_Slot), "No_Slot names no slot");
      Assert (Ordinal (No_Slot) = 0, "and carries no ordinal");
      Assert (Pool_Refs.Ref (No_Slot) = null,
              "an accessor into No_Slot is null");

      Try_Get (No_Slot, Refused, Answered);
      Assert (Refused, "and reading it is refused rather than answered");
   end Test_Empty_Pool;

   procedure Test_Acquire_To_Capacity is
      Taken : array (1 .. Capacity) of Slot;
      Over  : Slot;
   begin
      Section ("acquiring the whole pool");

      for I in Taken'Range loop
         Taken (I) := Acquire;
         Assert (Taken (I) /= No_Slot, "slot" & I'Image & " is there to take");
         Assert (Live (Taken (I)), "and the pool holds it");
         Assert (Held = I, "Held counts" & I'Image);
         Set (Taken (I), (Tag => 100 + I));
      end loop;

      Over := Acquire;
      Assert (Over = No_Slot, "a full pool answers No_Slot");
      Assert (Held = Capacity, "and hands out nothing more");

      for I in Taken'Range loop
         Assert (Ordinal (Taken (I)) = I,
                 "the pool hands out its slots in order");
         Assert (Get (Taken (I)).Tag = 100 + I,
                 "and each slot keeps its own payload");
      end loop;

      for I in Taken'Range loop
         Release (Taken (I));
         Assert (Taken (I) = No_Slot, "Release takes the name to No_Slot");
         Assert (Held = Capacity - I, "and the count falls");
      end loop;

      Assert (Held = 0, "released slots go back to the pool");
   end Test_Acquire_To_Capacity;

   --  The serial is the whole reason a Slot is not an array index: the
   --  pool reuses the ordinal, and the name taken at the earlier
   --  hand-out has to read as absent rather than as the new holder.
   procedure Test_A_Reused_Slot_Reads_Absent is
      Stale    : Slot;
      Mine     : Slot;
      Fresh    : Slot;
      Refused  : Boolean;
      Answered : Integer;
   begin
      Section ("a slot released and handed out again");

      Mine := Acquire;
      Set (Mine, (Tag => 11));
      Stale := Mine;

      Release (Mine);
      Assert (Held = 0, "the slot is back");
      Assert (not Live (Stale), "and the name taken at that hand-out is dead");

      Fresh := Acquire;
      Set (Fresh, (Tag => 22));

      Assert (Ordinal (Fresh) = Ordinal (Stale),
              "the pool reuses the same ordinal, so the serial is the "
              & "only thing telling the two names apart");
      Assert (Serial (Fresh) = Serial (Stale) + 1,
              "which the fresh hand-out raised");
      Assert (Live (Fresh) and then not Live (Stale),
              "the fresh name is live and the stale one is not");

      Try_Get (Stale, Refused, Answered);
      Assert (Refused,
              "reading the stale name is refused rather than answered");
      Assert (Answered /= 22,
              "and never gives the new holder's payload");

      Assert (Pool_Refs.Ref (Stale) = null,
              "an accessor into the stale name is null");
      Assert (Pool_Refs.Mutable (Stale) = null,
              "and so is a writable one");

      Assert (Set_Refused (Stale, 99), "writing through it is refused");
      Assert (Get (Fresh).Tag = 22,
              "so the new holder's payload stands");

      --  Releasing through the stale name leaves the live slot alone.
      Release (Stale);
      Assert (Held = 1 and then Live (Fresh),
              "and releasing through it frees nothing");

      Release (Fresh);
      Assert (Held = 0, "the pool is empty again");
   end Test_A_Reused_Slot_Reads_Absent;

   procedure Test_In_Place is
      Mine  : Slot := Acquire;
      Stale : Slot;
   begin
      Section ("the payload in place");

      Set (Mine, (Tag => 7));

      declare
         Reading : constant Pool_Refs.Const_Access := Pool_Refs.Ref (Mine);
         Writing : constant Pool_Refs.Var_Access := Pool_Refs.Mutable (Mine);
      begin
         Assert (Reading /= null, "a live slot answers an accessor");
         Assert (Reading.Tag = 7, "reading it gives what Set wrote");
         Writing.Tag := 8;
         Assert (Get (Mine).Tag = 8, "and a write through it lands");
      end;

      Stale := Mine;
      Release (Mine);
      Assert (Pool_Refs.Ref (Stale) = null,
              "a released slot answers no accessor");
   end Test_In_Place;

   --  A one-slot pool hands out the same ordinal every time, so every
   --  earlier name is a candidate for reading as the current holder.
   --  None of them does.
   Cycles : constant := 1_000;

   package One is new Adi.Slot_Pool (Payload => Marker, Capacity => 1)
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);
   package One_Refs is new One.Refs
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   use type One_Refs.Const_Access;

   procedure Test_Serial_Across_Cycles is
      Past    : array (1 .. Cycles) of One.Slot;
      Current : One.Slot;
      Absent  : Natural := 0;
      Counted : Boolean := True;
   begin
      Section ("a thousand hand-outs of one slot");

      for I in Past'Range loop
         Current := One.Acquire;
         Counted := Counted and then One.Serial (Current) = I;
         Past (I) := Current;
         One.Set (Current, (Tag => I));
         One.Release (Current);
      end loop;

      Assert (Counted, "each hand-out raised the serial by one");
      Assert (One.Held = 0, "every hand-out came back");

      Current := One.Acquire;
      One.Set (Current, (Tag => -1));

      for I in Past'Range loop
         if not One.Live (Past (I)) and then One_Refs.Ref (Past (I)) = null
         then
            Absent := Absent + 1;
         end if;
      end loop;

      Assert (Absent = Cycles,
              "every earlier name reads as absent while the slot is held "
              & "by the latest");
      Assert (One.Serial (Current) = Cycles + 1,
              "and the serial has counted every hand-out");

      --  Serial is a Natural, so it never wraps a stale name onto a
      --  live one: past Natural'Last Acquire raises Constraint_Error,
      --  which asks 2**31 hand-outs of a single slot.
      Assert (One.Serial (Current) < Natural'Last,
              "the serial rises toward Natural'Last rather than around it");

      One.Release (Current);
   end Test_Serial_Across_Cycles;

begin
   Start_Suite ("Slot Pool Test");

   Test_Empty_Pool;
   Test_Acquire_To_Capacity;
   Test_A_Reused_Slot_Reads_Absent;
   Test_In_Place;
   Test_Serial_Across_Cycles;

   Finish;
end Slot_Pool_Test;
