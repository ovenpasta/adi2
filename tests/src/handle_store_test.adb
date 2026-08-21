pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Test_Support; use Test_Support;
with Adi.Handle_Store;

procedure Handle_Store_Test is

   ---------------------------------------------------------------------------
   --  A simple tagged type to test with
   ---------------------------------------------------------------------------

   type Test_Object is abstract tagged limited record
      Value : Natural := 0;
   end record;
   type Test_Access is access all Test_Object'Class;

   type Concrete_Object is new Test_Object with null record;

   package Stores is new Adi.Handle_Store (Test_Object, Test_Access);
   use Stores;

   --  Get answers null for a stale Id rather than raising.  True when the
   --  call returned at all and returned null.
   function Get_Degrades (Id : Object_Id) return Boolean is
   begin
      return Get (Id) = null;
   exception
      when others =>
         return False;
   end Get_Degrades;

   --  Registering right after a free reuses the slot that was freed:
   --  Really_Free pushes the index onto the head of the free list.
   --  True when the slot at Idx was recycled with a bumped generation.
   function Slot_Was_Recycled (Idx : Slot_Index; Gen : Generation)
     return Boolean
   is
      Id : constant Object_Id := Register (new Concrete_Object'(Value => 0));
   begin
      return R : constant Boolean := Id.Index = Idx and then Id.Gen = Gen + 1
      do
         Request_Destroy (Id);
      end return;
   end Slot_Was_Recycled;

   ---------------------------------------------------------------------------
   --  Test: Null_Id is invalid
   ---------------------------------------------------------------------------

   procedure Test_Null_Id is
   begin
      Put_Line ("-- Null_Id tests --");
      Assert (not Is_Valid (Null_Id), "Null_Id should be invalid");
      Assert (Get (Null_Id) = null, "Get(Null_Id) should return null");
   end Test_Null_Id;

   ---------------------------------------------------------------------------
   --  Test: Register and retrieve
   ---------------------------------------------------------------------------

   procedure Test_Register_Get is
      Obj : constant Test_Access := new Concrete_Object'(Value => 42);
      Id  : constant Object_Id := Register (Obj);
   begin
      Put_Line ("-- Register/Get tests --");
      Assert (Is_Valid (Id), "registered Id should be valid");
      Assert (Get (Id) /= null, "Get should return non-null");
      Assert (Get (Id).Value = 42, "Get should return the same object");
   end Test_Register_Get;

   ---------------------------------------------------------------------------
   --  Test: Destroy makes Id stale
   ---------------------------------------------------------------------------

   procedure Test_Destroy_Stale is
      Obj : constant Test_Access := new Concrete_Object'(Value => 10);
      Id  : constant Object_Id := Register (Obj);
   begin
      Put_Line ("-- Destroy/stale tests --");
      Assert (Is_Valid (Id), "before destroy: valid");
      Request_Destroy (Id);
      Assert (not Is_Valid (Id), "after destroy: stale");
      Assert (Get_Degrades (Id), "Get after destroy: null, no exception");
   end Test_Destroy_Stale;

   ---------------------------------------------------------------------------
   --  Test: Deferred destroy when pinned
   ---------------------------------------------------------------------------

   procedure Test_Deferred_Destroy is
      Obj : constant Test_Access := new Concrete_Object'(Value => 20);
      Id  : constant Object_Id := Register (Obj);
      Idx : constant Slot_Index := Id.Index;
      Gen : constant Generation := Id.Gen;
   begin
      Put_Line ("-- Deferred destroy tests --");
      Pin (Id);
      Request_Destroy (Id);
      Assert (not Is_Valid (Id),
              "pinned: invalid from the moment destroy is requested");
      Assert (Get (Id) = null, "pinned + pending: Get answers null");

      Unpin (Id);
      Assert (not Is_Valid (Id), "after unpin: still invalid");
      Assert (Slot_Was_Recycled (Idx, Gen),
              "unpin of a pending slot frees it");
   end Test_Deferred_Destroy;

   ---------------------------------------------------------------------------
   --  Test: Unpin frees a slot whose destroy is already pending
   ---------------------------------------------------------------------------

   procedure Test_Unpin_Frees_Pending is
      Obj : constant Test_Access := new Concrete_Object'(Value => 21);
      Id  : constant Object_Id := Register (Obj);
      Idx : constant Slot_Index := Id.Index;
      Gen : constant Generation := Id.Gen;
   begin
      Put_Line ("-- Unpin of a pending slot --");
      Pin (Id);
      Request_Destroy (Id);
      Assert (not Is_Valid (Id), "pending: invalid");

      --  Unpin drops the pin and frees, on an Id that Is_Valid rejects.
      Unpin (Id);
      Assert (Slot_Was_Recycled (Idx, Gen),
              "the pin is released and the slot recycled");
   end Test_Unpin_Frees_Pending;

   ---------------------------------------------------------------------------
   --  Test: Multiple pins
   ---------------------------------------------------------------------------

   procedure Test_Multiple_Pins is
      Obj : constant Test_Access := new Concrete_Object'(Value => 30);
      Id  : constant Object_Id := Register (Obj);
      Idx : constant Slot_Index := Id.Index;
      Gen : constant Generation := Id.Gen;
   begin
      Put_Line ("-- Multiple pin tests --");
      Pin (Id);
      Pin (Id);
      Request_Destroy (Id);
      Assert (not Is_Valid (Id), "2 pins: invalid once destroy is requested");

      Unpin (Id);
      Assert (not Slot_Was_Recycled (Idx, Gen),
              "1 pin remaining: not freed");

      Unpin (Id);
      Assert (Slot_Was_Recycled (Idx, Gen), "0 pins: freed");
   end Test_Multiple_Pins;

   ---------------------------------------------------------------------------
   --  Test: Pump drains deferred destroys
   ---------------------------------------------------------------------------

   procedure Test_Pump is
      Obj : constant Test_Access := new Concrete_Object'(Value => 40);
      Id  : constant Object_Id := Register (Obj);
      Idx : constant Slot_Index := Id.Index;
      Gen : constant Generation := Id.Gen;
   begin
      Put_Line ("-- Pump tests --");
      Pin (Id);
      Request_Destroy (Id);

      Pump;
      Assert (not Slot_Was_Recycled (Idx, Gen),
              "Pump with a pin outstanding: not freed");

      Unpin (Id);
      Assert (Slot_Was_Recycled (Idx, Gen), "after unpin: freed");
   end Test_Pump;

   ---------------------------------------------------------------------------
   --  Test: Pump with pending + no pins
   ---------------------------------------------------------------------------

   procedure Test_Pump_No_Pins is
      Obj : constant Test_Access := new Concrete_Object'(Value => 50);
      Id  : constant Object_Id := Register (Obj);
   begin
      Put_Line ("-- Pump (no pins) tests --");
      --  Directly destroy without pin — should free immediately
      Request_Destroy (Id);
      Assert (not Is_Valid (Id), "destroyed without pin: freed immediately");
   end Test_Pump_No_Pins;

   ---------------------------------------------------------------------------
   --  Test: Borrow / Object_Ref
   ---------------------------------------------------------------------------

   procedure Test_Borrow is
      Obj : constant Test_Access := new Concrete_Object'(Value => 99);
      Id  : constant Object_Id := Register (Obj);
      Idx : constant Slot_Index := Id.Index;
      Gen : constant Generation := Id.Gen;
   begin
      Put_Line ("-- Borrow tests --");
      declare
         R : constant Object_Ref := Borrow (Id);
      begin
         Assert (R.Ptr /= null, "Borrow: Ptr non-null");
         Assert (R.Ptr.Value = 99, "Borrow: correct value via Ptr");

         --  Destroying under a borrow defers the free but not the answer.
         Request_Destroy (Id);
         Assert (not Is_Valid (Id), "destroy while borrowed: invalid");
         Assert (R.Ptr.Value = 99, "the borrowed pointer stays readable");
      end;
      --  R finalized here => unpin => deferred free triggers
      Assert (Slot_Was_Recycled (Idx, Gen), "after borrow scope: freed");
   end Test_Borrow;

   ---------------------------------------------------------------------------
   --  Test: Borrow stale Id raises Constraint_Error
   ---------------------------------------------------------------------------

   procedure Test_Borrow_Stale is
      Obj : constant Test_Access := new Concrete_Object'(Value => 1);
      Id  : constant Object_Id := Register (Obj);
   begin
      Put_Line ("-- Borrow stale tests --");
      Request_Destroy (Id);

      --  Borrow is the one operation that raises: its purpose is to
      --  produce a usable pointer, and there is none.
      begin
         declare
            R : Object_Ref := Borrow (Id);
            pragma Unreferenced (R);
         begin
            Assert (False, "should have raised Constraint_Error");
         end;
      exception
         when Constraint_Error =>
            Assert (True, "stale Borrow raises Constraint_Error");
      end;

      --  Also test Null_Id
      begin
         declare
            R : Object_Ref := Borrow (Null_Id);
            pragma Unreferenced (R);
         begin
            Assert (False, "Null_Id Borrow should raise");
         end;
      exception
         when Constraint_Error =>
            Assert (True, "Null_Id Borrow raises Constraint_Error");
      end;
   end Test_Borrow_Stale;

   ---------------------------------------------------------------------------
   --  Test: every read degrades on an Id the store does not recognise
   ---------------------------------------------------------------------------

   procedure Test_Unrecognised_Ids is
      Obj    : constant Test_Access := new Concrete_Object'(Value => 7);
      Id     : constant Object_Id := Register (Obj);
      Beyond : constant Object_Id := (Index => 1_000_000, Gen => 1);
      Wrong  : constant Object_Id := (Index => Id.Index, Gen => Id.Gen + 9);
   begin
      Put_Line ("-- Unrecognised Id tests --");
      Assert (not Is_Valid (Beyond), "out-of-range index: invalid");
      Assert (Get_Degrades (Beyond), "out-of-range index: Get null");
      Assert (not Is_Valid (Wrong), "wrong generation: invalid");
      Assert (Get_Degrades (Wrong), "wrong generation: Get null");
      Assert (Get (Null_Id) = null, "Null_Id: Get null");

      Request_Destroy (Id);
      Assert (Get_Degrades (Id), "retired Id: Get null");

      --  Request_Destroy on an Id the store no longer recognises is a
      --  no-op, not a second free.
      Request_Destroy (Id);
      Request_Destroy (Beyond);
      Assert (True, "repeat Request_Destroy is inert");
   end Test_Unrecognised_Ids;

   ---------------------------------------------------------------------------
   --  Test: Slot reuse with generation bump
   ---------------------------------------------------------------------------

   procedure Test_Generation_Reuse is
      Obj1 : constant Test_Access := new Concrete_Object'(Value => 100);
      Id1  : constant Object_Id := Register (Obj1);
      Idx  : constant Slot_Index := Id1.Index;
      Gen1 : constant Generation := Id1.Gen;
   begin
      Put_Line ("-- Generation reuse tests --");
      Request_Destroy (Id1);
      Assert (not Is_Valid (Id1), "first object destroyed");

      --  Allocate again — should reuse the slot with bumped generation
      declare
         Obj2 : constant Test_Access := new Concrete_Object'(Value => 200);
         Id2  : constant Object_Id := Register (Obj2);
      begin
         Assert (Id2.Index = Idx, "reused same slot index");
         Assert (Id2.Gen = Gen1 + 1, "generation bumped");
         Assert (Is_Valid (Id2), "new Id valid");
         Assert (not Is_Valid (Id1), "old Id still stale");
         Assert (Get (Id2).Value = 200, "new object via new Id");
         Request_Destroy (Id2);
      end;
   end Test_Generation_Reuse;

   ---------------------------------------------------------------------------
   --  Test: For_Each_Alive
   ---------------------------------------------------------------------------

   procedure Test_For_Each_Alive is
      Obj1 : constant Test_Access := new Concrete_Object'(Value => 1000);
      Obj2 : constant Test_Access := new Concrete_Object'(Value => 2000);
      Obj3 : constant Test_Access := new Concrete_Object'(Value => 3000);
      Id1 : constant Object_Id := Register (Obj1);
      Id2 : constant Object_Id := Register (Obj2);
      Id3 : constant Object_Id := Register (Obj3);

      Item_Count : Natural := 0;

      procedure Count_Items
        (Id : Object_Id; Obj : not null Test_Access) is
         pragma Unreferenced (Id, Obj);
      begin
         Item_Count := Item_Count + 1;
      end Count_Items;

      procedure Do_Count is new For_Each_Alive (Count_Items);

      Before_Count : Natural;
   begin
      Put_Line ("-- For_Each_Alive tests --");

      Do_Count;
      Before_Count := Item_Count;
      Assert (Before_Count >= 3,
              "at least 3 alive, got" & Before_Count'Image);

      --  Destroy one, re-count
      Request_Destroy (Id2);
      Item_Count := 0;
      Do_Count;
      Assert (Item_Count = Before_Count - 1,
              "after destroying #2: count decreased by 1, got" &
              Item_Count'Image);

      Request_Destroy (Id1);
      Request_Destroy (Id3);
   end Test_For_Each_Alive;

   ---------------------------------------------------------------------------
   --  Test: Capacity growth (register more than initial 64)
   ---------------------------------------------------------------------------

   procedure Test_Growth is
      type Id_Array is array (1 .. 70) of Object_Id;
      Ids : Id_Array;
   begin
      Put_Line ("-- Growth tests --");
      for I in Ids'Range loop
         Ids (I) := Register (new Concrete_Object'(Value => I));
      end loop;

      Assert (Is_Valid (Ids (1)), "first slot valid after growth");
      Assert (Is_Valid (Ids (70)), "70th slot valid after growth");
      Assert (Get (Ids (70)).Value = 70, "70th value correct");

      for I in Ids'Range loop
         Request_Destroy (Ids (I));
      end loop;
   end Test_Growth;

begin
   Start_Suite ("Handle Store Tests");

   Test_Null_Id;
   Test_Register_Get;
   Test_Destroy_Stale;
   Test_Deferred_Destroy;
   Test_Unpin_Frees_Pending;
   Test_Multiple_Pins;
   Test_Pump;
   Test_Pump_No_Pins;
   Test_Borrow;
   Test_Borrow_Stale;
   Test_Unrecognised_Ids;
   Test_Generation_Reuse;
   Test_For_Each_Alive;
   Test_Growth;

   New_Line;
   Test_Support.Finish;
end Handle_Store_Test;
