pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Handle_Store;

procedure Handle_Store_Test is

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Passed := Passed + 1;
      else
         Failed := Failed + 1;
         Put_Line ("  [FAIL] " & Msg);
      end if;
   end Assert;

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
      Assert (Get (Id) = null, "Get after destroy: null");
   end Test_Destroy_Stale;

   ---------------------------------------------------------------------------
   --  Test: Deferred destroy when pinned
   ---------------------------------------------------------------------------

   procedure Test_Deferred_Destroy is
      Obj : constant Test_Access := new Concrete_Object'(Value => 20);
      Id  : constant Object_Id := Register (Obj);
   begin
      Put_Line ("-- Deferred destroy tests --");
      Pin (Id);
      Request_Destroy (Id);
      Assert (Is_Valid (Id), "pinned: still valid after Request_Destroy");
      Assert (Get (Id) /= null, "pinned: Get still works");

      Unpin (Id);
      Assert (not Is_Valid (Id), "after unpin: stale (deferred free)");
      Assert (Get (Id) = null, "after unpin: Get returns null");
   end Test_Deferred_Destroy;

   ---------------------------------------------------------------------------
   --  Test: Multiple pins
   ---------------------------------------------------------------------------

   procedure Test_Multiple_Pins is
      Obj : constant Test_Access := new Concrete_Object'(Value => 30);
      Id  : constant Object_Id := Register (Obj);
   begin
      Put_Line ("-- Multiple pin tests --");
      Pin (Id);
      Pin (Id);
      Request_Destroy (Id);
      Assert (Is_Valid (Id), "2 pins: still valid");

      Unpin (Id);
      Assert (Is_Valid (Id), "1 pin remaining: still valid");

      Unpin (Id);
      Assert (not Is_Valid (Id), "0 pins: freed");
   end Test_Multiple_Pins;

   ---------------------------------------------------------------------------
   --  Test: Pump drains deferred destroys
   ---------------------------------------------------------------------------

   procedure Test_Pump is
      Obj : constant Test_Access := new Concrete_Object'(Value => 40);
      Id  : constant Object_Id := Register (Obj);
   begin
      Put_Line ("-- Pump tests --");
      Pin (Id);
      Request_Destroy (Id);
      Assert (Is_Valid (Id), "pinned: alive");

      --  Pump should not free while pinned
      Pump;
      Assert (Is_Valid (Id), "Pump with pin: still alive");

      Unpin (Id);
      --  Unpin triggers immediate free when pending, but test Pump path too
      --  (the unpin already freed it since pins hit 0 with pending)
      Assert (not Is_Valid (Id), "after unpin: freed");
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
   begin
      Put_Line ("-- Borrow tests --");
      declare
         R : constant Object_Ref := Borrow (Id);
      begin
         Assert (R.Ptr /= null, "Borrow: Ptr non-null");
         Assert (R.Ptr.Value = 99, "Borrow: correct value via Ptr");

         --  Try destroy while borrowed — should defer
         Request_Destroy (Id);
         Assert (Is_Valid (Id), "destroy while borrowed: still valid");
      end;
      --  R finalized here => unpin => deferred free triggers
      Assert (not Is_Valid (Id), "after borrow scope: freed");
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
   Put_Line ("=== Handle Store Tests ===");

   Test_Null_Id;
   Test_Register_Get;
   Test_Destroy_Stale;
   Test_Deferred_Destroy;
   Test_Multiple_Pins;
   Test_Pump;
   Test_Pump_No_Pins;
   Test_Borrow;
   Test_Borrow_Stale;
   Test_Generation_Reuse;
   Test_For_Each_Alive;
   Test_Growth;

   New_Line;
   Put_Line ("Results:" & Passed'Image & " passed," &
             Failed'Image & " failed");
   if Failed > 0 then
      Put_Line ("SOME TESTS FAILED");
   else
      Put_Line ("ALL TESTS PASSED");
   end if;
end Handle_Store_Test;
