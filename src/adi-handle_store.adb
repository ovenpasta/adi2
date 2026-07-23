--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body Adi.Handle_Store is

   ---------------------------------------------------------------------------
   --  Slot record
   ---------------------------------------------------------------------------

   type Slot is record
      Gen       : Generation    := 1;
      Alive     : Boolean       := False;
      Pending   : Boolean       := False;
      Pins      : Natural       := 0;
      Obj       : Object_Access := null;
      Next_Free : Slot_Index    := 0;   --  intrusive free-list link
   end record;

   type Slot_Array is array (Slot_Index range <>) of Slot;
   type Slot_Array_Access is access Slot_Array;

   ---------------------------------------------------------------------------
   --  Global state
   ---------------------------------------------------------------------------

   Initial_Capacity : constant := 64;

   Slots       : Slot_Array_Access := null;
   Count       : Slot_Index := 0;   --  number of live + pending slots
   Free_Head   : Slot_Index := 0;   --  head of free list (0 = empty)
   Strict_Mode : Boolean := True;

   ---------------------------------------------------------------------------
   --  Deallocation
   ---------------------------------------------------------------------------

   procedure Free_Object is new Ada.Unchecked_Deallocation
     (Object_Type'Class, Object_Access);

   procedure Really_Free (Id : Object_Id);
   --  Non-recursive.  Frees a single slot.

   ---------------------------------------------------------------------------
   --  Internal helpers
   ---------------------------------------------------------------------------

   procedure Ensure_Capacity is
      New_Cap  : Slot_Index;
      New_Arr  : Slot_Array_Access;

      procedure Free_Old is new Ada.Unchecked_Deallocation
        (Slot_Array, Slot_Array_Access);
      Old : Slot_Array_Access;
   begin
      if Slots = null then
         New_Cap := Initial_Capacity;
         Slots := new Slot_Array (0 .. New_Cap);
         --  Slot 0 stays default (reserved sentinel).
         --  Build free list from 1 .. New_Cap.
         for I in 1 .. New_Cap loop
            Slots (I).Next_Free := (if I < New_Cap then I + 1 else 0);
         end loop;
         Free_Head := 1;
         return;
      end if;

      if Free_Head /= 0 then
         return;  --  still have free slots
      end if;

      --  Double capacity
      New_Cap := Slots'Last * 2;
      New_Arr := new Slot_Array (0 .. New_Cap);
      New_Arr (Slots'Range) := Slots.all;

      --  Build free list from old-last+1 .. New_Cap
      for I in Slots'Last + 1 .. New_Cap loop
         New_Arr (I).Next_Free := (if I < New_Cap then I + 1 else 0);
      end loop;
      Free_Head := Slots'Last + 1;

      Old := Slots;
      Slots := New_Arr;
      Free_Old (Old);
   end Ensure_Capacity;

   ---------------------------------------------------------------------------
   --  Is_Valid
   ---------------------------------------------------------------------------

   function Is_Valid (Id : Object_Id) return Boolean is
   begin
      if Id.Index = 0 or else Slots = null then
         return False;
      end if;
      if Id.Index > Slots'Last then
         return False;
      end if;
      declare
         S : Slot renames Slots (Id.Index);
      begin
         return S.Alive and then S.Gen = Id.Gen;
      end;
   end Is_Valid;

   ---------------------------------------------------------------------------
   --  Register
   ---------------------------------------------------------------------------

   function Register (Obj : not null Object_Access) return Object_Id is
   begin
      Ensure_Capacity;

      declare
         I : constant Slot_Index := Free_Head;
         S : Slot renames Slots (I);
      begin
         Free_Head := S.Next_Free;
         S.Obj       := Obj;
         S.Alive     := True;
         S.Pending   := False;
         S.Pins      := 0;
         S.Next_Free := 0;
         Count       := Count + 1;
         return (Index => I, Gen => S.Gen);
      end;
   end Register;

   ---------------------------------------------------------------------------
   --  Get
   ---------------------------------------------------------------------------

   function Get (Id : Object_Id) return Object_Access is
   begin
      if Id = Null_Id then
         return null;
      end if;
      if not Is_Valid (Id) then
         if Strict_Mode then
            raise Program_Error with
              "Handle_Store: stale handle (idx="
              & Slot_Index'Image (Id.Index) & ")";
         end if;
         return null;
      end if;
      return Slots (Id.Index).Obj;
   end Get;

   ---------------------------------------------------------------------------
   --  Request_Destroy
   ---------------------------------------------------------------------------

   procedure Request_Destroy (Id : Object_Id) is
   begin
      if not Is_Valid (Id) then
         return;
      end if;

      declare
         S : Slot renames Slots (Id.Index);
      begin
         if S.Pins > 0 then
            S.Pending := True;  --  deferred
         else
            Really_Free (Id);
         end if;
      end;
   end Request_Destroy;

   ---------------------------------------------------------------------------
   --  Pump
   ---------------------------------------------------------------------------

   procedure Pump is
   begin
      if Slots = null then
         return;
      end if;
      for I in 1 .. Slots'Last loop
         declare
            S : Slot renames Slots (I);
         begin
            if S.Alive and then S.Pending and then S.Pins = 0 then
               Really_Free ((Index => I, Gen => S.Gen));
            end if;
         end;
      end loop;
   end Pump;

   ---------------------------------------------------------------------------
   --  Pin / Unpin
   ---------------------------------------------------------------------------

   procedure Pin (Id : Object_Id) is
   begin
      if Is_Valid (Id) then
         Slots (Id.Index).Pins := Slots (Id.Index).Pins + 1;
      end if;
   end Pin;

   procedure Unpin (Id : Object_Id) is
   begin
      if not Is_Valid (Id) then
         return;
      end if;

      declare
         S : Slot renames Slots (Id.Index);
      begin
         if S.Pins > 0 then
            S.Pins := S.Pins - 1;
         end if;

         if S.Pins = 0 and then S.Pending then
            Really_Free (Id);
         end if;
      end;
   end Unpin;

   ---------------------------------------------------------------------------
   --  Really_Free  (non-recursive, single slot)
   ---------------------------------------------------------------------------

   procedure Really_Free (Id : Object_Id) is
      S : Slot renames Slots (Id.Index);
   begin
      if S.Obj /= null then
         Free_Object (S.Obj);
      end if;

      S.Alive     := False;
      S.Pending   := False;
      S.Pins      := 0;
      S.Gen       := S.Gen + 1;   --  stale handles now fail Is_Valid
      S.Next_Free := Free_Head;
      Free_Head   := Id.Index;
      Count       := Count - 1;
   end Really_Free;

   ---------------------------------------------------------------------------
   --  Borrow
   ---------------------------------------------------------------------------

   function Borrow (Id : Object_Id) return Object_Ref is
      Obj : constant Object_Access := Get (Id);
   begin
      if Obj = null then
         raise Constraint_Error with "Handle_Store: stale or null Id";
      end if;
      Pin (Id);
      return (Ada.Finalization.Limited_Controlled with
              Ptr => Obj,
              Id  => Id);
   end Borrow;

   ---------------------------------------------------------------------------
   --  Object_Ref finalization
   ---------------------------------------------------------------------------

   overriding procedure Finalize (R : in out Object_Ref) is
   begin
      if R.Id /= Null_Id then
         Unpin (R.Id);
      end if;
   end Finalize;

   ---------------------------------------------------------------------------
   --  For_Each_Alive
   ---------------------------------------------------------------------------

   procedure For_Each_Alive is
   begin
      if Slots = null then
         return;
      end if;
      for I in 1 .. Slots'Last loop
         declare
            S : Slot renames Slots (I);
         begin
            if S.Alive and then S.Obj /= null then
               Process ((Index => I, Gen => S.Gen), S.Obj);
            end if;
         end;
      end loop;
   end For_Each_Alive;

   ---------------------------------------------------------------------------
   --  Strict mode
   ---------------------------------------------------------------------------

   procedure Set_Strict (Value : Boolean) is
   begin
      Strict_Mode := Value;
   end Set_Strict;

   function Is_Strict return Boolean is
   begin
      return Strict_Mode;
   end Is_Strict;

end Adi.Handle_Store;
