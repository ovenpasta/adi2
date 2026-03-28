pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Image;   use Adi.Image;
with Adi.Widget.Combo_Box; use Adi.Widget.Combo_Box;

procedure Combo_Box_Item_Test is
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Assert;

   --  A concrete subclass of Item_Data for testing
   type My_Data is new Item_Data with record
      Id : Integer := 0;
   end record;

   procedure Test_Text_Only_Item is
      H : constant Combo_Box_Handle := Create_Handle;
   begin
      Put_Line ("Test: text-only Add_Item");
      Add_Item (H, "Hello");
      Assert (Option_Count (H) = 1, "option count = 1");
      Assert (Get_Item_Data (H, 1) = null, "Get_Item_Data = null for text-only");
      Assert (Get_Item_Icon (H, 1) = null, "Get_Item_Icon = null for text-only");
      Assert (Get_Selected_Text (H) = "Hello", "Get_Selected_Text = Hello");
      Assert (Get_Selected_Data (H) = null, "Get_Selected_Data = null");
   end Test_Text_Only_Item;

   procedure Test_Icon_Item is
      H    : constant Combo_Box_Handle := Create_Handle;
      Icon : constant Image_Access :=
        Load_SVG_Path ("M4 6 L12 14 L20 6", (24.0, 24.0),
                       (R => 255, G => 255, B => 255, A => 255));
   begin
      Put_Line ("Test: Add_Item with icon");
      Add_Item (H, "With Icon", Icon);
      Assert (Option_Count (H) = 1, "option count = 1");
      Assert (Get_Item_Icon (H, 1) = Icon, "Get_Item_Icon returns supplied icon");
      Assert (Get_Item_Data (H, 1) = null, "Get_Item_Data = null when no data");
   end Test_Icon_Item;

   procedure Test_Data_Item is
      H    : constant Combo_Box_Handle := Create_Handle;
      D    : aliased My_Data := (Id => 42);
   begin
      Put_Line ("Test: Add_Item with data");
      Add_Item (H, "With Data", Data => D'Unchecked_Access);
      Assert (Option_Count (H) = 1, "option count = 1");
      Assert (Get_Item_Icon (H, 1) = null, "Get_Item_Icon = null when no icon");
      declare
         Got : constant Item_Data_Access := Get_Item_Data (H, 1);
      begin
         Assert (Got /= null, "Get_Item_Data not null");
         Assert (My_Data (Got.all).Id = 42, "data Id = 42");
      end;
   end Test_Data_Item;

   procedure Test_Get_Selected_Data is
      H  : constant Combo_Box_Handle := Create_Handle;
      D1 : aliased My_Data := (Id => 1);
      D2 : aliased My_Data := (Id => 2);
   begin
      Put_Line ("Test: Get_Selected_Data after Set_Selected_Index");
      Add_Item (H, "One",   Data => D1'Unchecked_Access);
      Add_Item (H, "Two",   Data => D2'Unchecked_Access);
      --  First item auto-selected on first Add_Item
      Assert (Get_Selected_Data (H) /= null, "selected data not null");
      Assert (My_Data (Get_Selected_Data (H).all).Id = 1,
              "selected data Id = 1 initially");
      Set_Selected_Index (H, 2);
      Assert (My_Data (Get_Selected_Data (H).all).Id = 2,
              "selected data Id = 2 after Set_Selected_Index");
   end Test_Get_Selected_Data;

   procedure Test_Out_Of_Range is
      H : constant Combo_Box_Handle := Create_Handle;
   begin
      Put_Line ("Test: out-of-range accessors return null");
      Add_Item (H, "Only");
      Assert (Get_Item_Data (H, 2) = null, "Get_Item_Data out of range = null");
      Assert (Get_Item_Icon (H, 2) = null, "Get_Item_Icon out of range = null");
   end Test_Out_Of_Range;

   procedure Test_Clear_Items is
      H : constant Combo_Box_Handle := Create_Handle;
      D : aliased My_Data := (Id => 7);
   begin
      Put_Line ("Test: Clear_Items resets selections");
      Add_Item (H, "Item", Data => D'Unchecked_Access);
      Clear_Items (H);
      Assert (Option_Count (H) = 0, "option count = 0 after clear");
      Assert (Get_Selected_Data (H) = null, "Get_Selected_Data = null after clear");
      Assert (Get_Selected_Text (H) = "", "Get_Selected_Text = empty after clear");
   end Test_Clear_Items;

   procedure Test_Handle_Widget_Agreement is
      H  : constant Combo_Box_Handle := Create_Handle;
      D  : aliased My_Data := (Id => 99);
      Icon : constant Image_Access :=
        Load_SVG_Path ("M4 14 L12 6 L20 14", (24.0, 24.0),
                       (R => 255, G => 255, B => 255, A => 255));
   begin
      Put_Line ("Test: handle overloads agree with widget overloads");
      Add_Item (H, "Test", Icon, D'Unchecked_Access);
      --  Handle accessors already delegate to widget overloads; verify values
      Assert (Get_Selected_Text (H) = "Test", "text matches via handle");
      Assert (Get_Item_Icon (H, 1) = Icon,    "icon matches via handle");
      Assert (Get_Item_Data (H, 1) /= null,   "data non-null via handle");
      Assert (My_Data (Get_Item_Data (H, 1).all).Id = 99,
              "data Id matches via handle");
   end Test_Handle_Widget_Agreement;

begin
   Put_Line ("========================================");
   Put_Line ("   Combo Box Item Test");
   Put_Line ("========================================");

   Test_Text_Only_Item;
   Test_Icon_Item;
   Test_Data_Item;
   Test_Get_Selected_Data;
   Test_Out_Of_Range;
   Test_Clear_Items;
   Test_Handle_Widget_Agreement;

   Put_Line ("Total:" & Test_Count'Image
             & "  Passed:" & Pass_Count'Image
             & "  Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Put_Line ("FAILED");
   else
      Put_Line ("All tests PASSED!");
   end if;
end Combo_Box_Item_Test;
