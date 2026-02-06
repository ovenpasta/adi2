pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.Widget; use Adi.Widget;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;

procedure Layout_Test is

   procedure Test_Horizontal_Icon_Text is
      Items : Layout_Item_List.Vector;
      Icon_Item : Layout_Item;
      Text_Item : Layout_Item;
      Container : constant Rectangle := (X => 0.0, Y => 0.0, Width => 200.0, Height => 40.0);
      Style : Resolved_Style;
   begin
      Put_Line ("==================================================");
      Put_Line ("TEST: Horizontal Icon + Text Layout");
      Put_Line ("==================================================");

      --  Setup container style (Row direction, centered)
      Style := (
         Display => Flex,
         Flex_Direction => Row,
         Align_Items => Center,
         Justify_Content => Flex_Start,
         Gap => (Kind => Gap_Uniform, All_Gap => Px (8.0)),
         others => <>
      );

      --  Icon: 24x24, fixed size
      Icon_Item := (
         Part => Icon_Part,
         Min_Width => 24.0,
         Min_Height => 24.0,
         Max_Width => 24.0,
         Max_Height => 24.0,
         Content_Width => 24.0,
         Content_Height => 24.0,
         Flex => (
            Grow => 0.0,
            Shrink => 0.0,
            Basis => 24.0,
            Align_Self => Auto
         ),
         Geometry => <>,
         Index => 1
      );

      --  Text: flexible width, 20px height
      Text_Item := (
         Part => Label_Part,
         Min_Width => 0.0,
         Min_Height => 20.0,
         Max_Width => Float'Last,
         Max_Height => 20.0,
         Content_Width => 100.0,
         Content_Height => 20.0,
         Flex => (
            Grow => 1.0,
            Shrink => 1.0,
            Basis => 0.0,
            Align_Self => Auto
         ),
         Geometry => <>,
         Index => 2
      );

      Items.Append (Icon_Item);
      Items.Append (Text_Item);

      --  Run layout
      Perform_Item_Flex_Layout (Container, Style, Items);

      --  Verify results
      declare
         Icon_Result : constant Layout_Item := Items.Element (1);
         Text_Result : constant Layout_Item := Items.Element (2);
      begin
         Put_Line ("EXPECTED:");
         Put_Line ("  Icon: X=0, Y=8 (centered), W=24, H=24");
         Put_Line ("  Text: X=32 (24+8gap), Y=10 (centered), W=168, H=20");
         Put_Line ("");

         --  Check icon
         if Icon_Result.Geometry.X /= 0.0 then
            Put_Line ("FAIL: Icon X=" & Icon_Result.Geometry.X'Image & " (expected 0.0)");
         end if;
         if Icon_Result.Geometry.Width /= 24.0 then
            Put_Line ("FAIL: Icon Width=" & Icon_Result.Geometry.Width'Image & " (expected 24.0)");
         end if;
         if Icon_Result.Geometry.Height /= 24.0 then
            Put_Line ("FAIL: Icon Height=" & Icon_Result.Geometry.Height'Image & " (expected 24.0)");
         end if;

         --  Check text
         if Text_Result.Geometry.Height /= 20.0 then
            Put_Line ("FAIL: Text Height=" & Text_Result.Geometry.Height'Image & " (expected 20.0)");
         end if;

         Put_Line ("Test completed.");
      end;
      Put_Line ("");
   end Test_Horizontal_Icon_Text;

   procedure Test_Vertical_Icon_Text is
      Items : Layout_Item_List.Vector;
      Icon_Item : Layout_Item;
      Text_Item : Layout_Item;
      Container : constant Rectangle := (X => 0.0, Y => 0.0, Width => 100.0, Height => 80.0);
      Style : Resolved_Style;
   begin
      Put_Line ("==================================================");
      Put_Line ("TEST: Vertical Icon + Text Layout");
      Put_Line ("==================================================");

      --  Setup container style (Column direction, centered)
      Style := (
         Display => Flex,
         Flex_Direction => Column,
         Align_Items => Center,
         Justify_Content => Flex_Start,
         Gap => (Kind => Gap_Uniform, All_Gap => Px (8.0)),
         others => <>
      );

      --  Icon: 48x48, fixed size
      Icon_Item := (
         Part => Icon_Part,
         Min_Width => 48.0,
         Min_Height => 48.0,
         Max_Width => 48.0,
         Max_Height => 48.0,
         Content_Width => 48.0,
         Content_Height => 48.0,
         Flex => (
            Grow => 0.0,
            Shrink => 0.0,
            Basis => 48.0,
            Align_Self => Auto
         ),
         Geometry => <>,
         Index => 1
      );

      --  Text: flexible, 20px height
      Text_Item := (
         Part => Label_Part,
         Min_Width => 0.0,
         Min_Height => 20.0,
         Max_Width => Float'Last,
         Max_Height => 20.0,
         Content_Width => 80.0,
         Content_Height => 20.0,
         Flex => (
            Grow => 0.0,
            Shrink => 1.0,
            Basis => 20.0,
            Align_Self => Auto
         ),
         Geometry => <>,
         Index => 2
      );

      Items.Append (Icon_Item);
      Items.Append (Text_Item);

      --  Run layout
      Perform_Item_Flex_Layout (Container, Style, Items);

      --  Verify results
      declare
         Icon_Result : constant Layout_Item := Items.Element (1);
         Text_Result : constant Layout_Item := Items.Element (2);
      begin
         Put_Line ("EXPECTED:");
         Put_Line ("  Icon: X=26 (centered), Y=0, W=48, H=48");
         Put_Line ("  Text: Y=56 (48+8gap), W=80, H=20");
         Put_Line ("");

         --  Check icon
         if Icon_Result.Geometry.Y /= 0.0 then
            Put_Line ("FAIL: Icon Y=" & Icon_Result.Geometry.Y'Image & " (expected 0.0)");
         end if;
         if Icon_Result.Geometry.Width /= 48.0 then
            Put_Line ("FAIL: Icon Width=" & Icon_Result.Geometry.Width'Image & " (expected 48.0)");
         end if;
         if Icon_Result.Geometry.Height /= 48.0 then
            Put_Line ("FAIL: Icon Height=" & Icon_Result.Geometry.Height'Image & " (expected 48.0)");
         end if;

         --  Check text
         if Text_Result.Geometry.Height /= 20.0 then
            Put_Line ("FAIL: Text Height=" & Text_Result.Geometry.Height'Image & " (expected 20.0)");
         end if;

         Put_Line ("Test completed.");
      end;
      Put_Line ("");
   end Test_Vertical_Icon_Text;

   procedure Test_Text_Only is
      Items : Layout_Item_List.Vector;
      Text_Item : Layout_Item;
      Container : constant Rectangle := (X => 10.0, Y => 10.0, Width => 300.0, Height => 40.0);
      Style : Resolved_Style;
   begin
      Put_Line ("==================================================");
      Put_Line ("TEST: Text Only Layout");
      Put_Line ("==================================================");

      --  Setup container style
      Style := (
         Display => Flex,
         Flex_Direction => Row,
         Align_Items => Center,
         Justify_Content => Flex_Start,
         Gap => (Kind => Gap_Uniform, All_Gap => Px (0.0)),
         others => <>
      );

      --  Text: fills container
      Text_Item := (
         Part => Label_Part,
         Min_Width => 0.0,
         Min_Height => 18.0,
         Max_Width => Float'Last,
         Max_Height => 18.0,
         Content_Width => 200.0,
         Content_Height => 18.0,
         Flex => (
            Grow => 1.0,
            Shrink => 1.0,
            Basis => 0.0,
            Align_Self => Auto
         ),
         Geometry => <>,
         Index => 1
      );

      Items.Append (Text_Item);

      --  Run layout
      Perform_Item_Flex_Layout (Container, Style, Items);

      --  Verify results
      declare
         Text_Result : constant Layout_Item := Items.Element (1);
      begin
         Put_Line ("EXPECTED:");
         Put_Line ("  Text: X=10, Y=21 (centered), W=300, H=18");
         Put_Line ("");

         --  Check text
         if Text_Result.Geometry.X /= 10.0 then
            Put_Line ("FAIL: Text X=" & Text_Result.Geometry.X'Image & " (expected 10.0)");
         end if;
         if Text_Result.Geometry.Width /= 300.0 then
            Put_Line ("FAIL: Text Width=" & Text_Result.Geometry.Width'Image & " (expected 300.0)");
         end if;
         if Text_Result.Geometry.Height /= 18.0 then
            Put_Line ("FAIL: Text Height=" & Text_Result.Geometry.Height'Image & " (expected 18.0)");
         end if;

         Put_Line ("Test completed.");
      end;
      Put_Line ("");
   end Test_Text_Only;

begin
   Put_Line ("========================================");
   Put_Line ("  LAYOUT ALGORITHM UNIT TESTS");
   Put_Line ("========================================");
   Put_Line ("");

   Test_Text_Only;
   Test_Horizontal_Icon_Text;
   Test_Vertical_Icon_Text;

   Put_Line ("========================================");
   Put_Line ("  ALL TESTS COMPLETED");
   Put_Line ("========================================");
end Layout_Test;
