pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Image;   use Adi.Image;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Combo_Box; use Adi.Widget.Combo_Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;

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

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Message : String) is
      Eps : constant Pixel_Type := 0.5;
   begin
      Assert
        (abs (Actual - Expected) <= Eps,
         Message & " actual=" & Actual'Image & " expected=" & Expected'Image);
   end Assert_Close;

   function Make_Test_Image
     (W, H : Pixel_Type) return Image_Access
   is
   begin
      return Load_SVG_Path
        (Path_Data => "M0 0 L" & Integer (W)'Image & " 0 L"
                      & Integer (W)'Image & " " & Integer (H)'Image
                      & " L0 " & Integer (H)'Image & " Z",
         Size      => (Width => W, Height => H),
         Fill      => (R => 128, G => 128, B => 128, A => 255));
   end Make_Test_Image;

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

   procedure Test_Selected_Icon_Measure_Uses_CSS_Size is
      H : constant Combo_Box_Handle := Create_Handle;
      Icon : constant Image_Access := Make_Test_Image (512.0, 512.0);
      Icon_Rules : constant Style_Rules := (
         Width  => Set (Size (Px (18.0))),
         Height => Set (Size (Px (18.0))),
         others => <>
      );
      Hidden_Rules : constant Style_Rules := (
         Display => Set (Display_None),
         others  => <>
      );
      Measured : Size_2D;
   begin
      Put_Line ("Test: selected icon Measure_Content respects CSS width/height");
      Add_Item (H, "", Icon);
      Set_Part_Style (+H, Icon_Part, From (Icon_Rules).Build);
      Set_Part_Style (+H, Text_Part, From (Hidden_Rules).Build);
      Set_Part_Style (+H, Indicator_Part, From (Hidden_Rules).Build);

      Build_Items (+H);
      Layout (+H);
      Update (+H);
      Measured := Measure_Content (+H);

      Assert_Close (Measured.Width, 18.0, "Measured width should use CSS size");
      Assert_Close (Measured.Height, 18.0, "Measured height should use CSS size");
   end Test_Selected_Icon_Measure_Uses_CSS_Size;

   procedure Test_Indicator_Uses_CSS_Size is
      H : constant Combo_Box_Handle := Create_Handle;
      Arrow : constant Image_Access := Make_Test_Image (24.0, 12.0);
      Main_Rules : constant Style_Rules := (
         Align_Items => Set (Center),
         others      => <>
      );
      Indicator_Rules : constant Style_Rules := (
         Height => Set (Size (Px (18.0))),
         others => <>
      );
      Indicator_Item : Item := (others => <>);
      Found : Boolean := False;
   begin
      Put_Line ("Test: indicator layout respects CSS size");
      Add_Item (H, "One");
      Set_Arrow_Image (H, Arrow);
      Set_Geometry (+H, (X => 0.0, Y => 0.0, Width => 120.0, Height => 40.0));
      Set_Part_Style (+H, Main_Part, From (Main_Rules).Build);
      Set_Part_Style (+H, Indicator_Part, From (Indicator_Rules).Build);

      Build_Items (+H);
      Layout (+H);
      Update (+H);

      for I in 1 .. Item_Count (+H) loop
         declare
            Current : constant Item := Get_Item (+H, I);
         begin
            if Current.Part = Indicator_Part then
               Indicator_Item := Current;
               Found := True;
               exit;
            end if;
         end;
      end loop;

      Assert (Found, "Indicator item should exist");
      if Found then
         Assert_Close
           (Indicator_Item.Geometry.Width, 36.0,
            "Indicator width should preserve aspect ratio");
         Assert_Close
           (Indicator_Item.Geometry.Height, 18.0,
            "Indicator height should match CSS height");
         Assert_Close
           (Indicator_Item.Geometry.Y, 11.0,
            "Indicator should remain centered by flex layout");
      end if;
   end Test_Indicator_Uses_CSS_Size;

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
   Test_Selected_Icon_Measure_Uses_CSS_Size;
   Test_Indicator_Uses_CSS_Size;

   Put_Line ("Total:" & Test_Count'Image
             & "  Passed:" & Pass_Count'Image
             & "  Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Put_Line ("FAILED");
   else
      Put_Line ("All tests PASSED!");
   end if;
end Combo_Box_Item_Test;
