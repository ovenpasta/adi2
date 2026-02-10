--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Demo_Flex_Styles is

   --  Base style for class 'box-base'
   Box_Base_Class_Base_Style : constant Style_Rules := (
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (C (Gray))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (4.0))),
      Min_Width => Set (Size (Px (20.0))),
      Min_Height => Set (Size (Px (20.0))),
      others => <>
   );

   --  Base style for class 'flex-container'
   Flex_Container_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Color => Set (Border_Color (C (Gray))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>
   );

   --  Base style for class 'row-base'
   Row_Base_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Grow => Set (1.0),
      Justify_Content => Set (Flex_Start),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (15.0))),
      Background_Color => Set_Bg (C (Transparent)),
      others => <>
   );

   --  Complete widget style for class 'box-base'
   Box_Base_Class_Widget : constant Widget_Style :=
     From (Box_Base_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'box-base'
   Box_Base_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Box_Base_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'flex-container'
   Flex_Container_Class_Widget : constant Widget_Style :=
     From (Flex_Container_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'flex-container'
   Flex_Container_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Flex_Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'row-base'
   Row_Base_Class_Widget : constant Widget_Style :=
     From (Row_Base_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'row-base'
   Row_Base_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Row_Base_Class_Widget, Enabled => True),
      others => <>
   ];

end Demo_Flex_Styles;