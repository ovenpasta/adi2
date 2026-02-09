--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Demo_Flex_Styles is

   --  Base style for box-base
   Box_Base_Base_Style : constant Style_Rules := (
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (C (Gray))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (4.0))),
      Min_Width => Set (Size (Px (20.0))),
      Min_Height => Set (Size (Px (20.0))),
      others => <>
   );

   --  Base style for flex-container
   Flex_Container_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Color => Set (Border_Color (C (Gray))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>
   );

   --  Base style for row-base
   Row_Base_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Flex_Start),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (15.0))),
      Background_Color => Set_Bg (C (Transparent)),
      others => <>
   );

   --  Complete widget style for box-base
   Box_Base_Widget : constant Widget_Style :=
     From (Box_Base_Base_Style)
     .Build;

   --  Part styles bundle for box-base
   Box_Base_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Box_Base_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for flex-container
   Flex_Container_Widget : constant Widget_Style :=
     From (Flex_Container_Base_Style)
     .Build;

   --  Part styles bundle for flex-container
   Flex_Container_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Flex_Container_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for row-base
   Row_Base_Widget : constant Widget_Style :=
     From (Row_Base_Base_Style)
     .Build;

   --  Part styles bundle for row-base
   Row_Base_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Row_Base_Widget, Enabled => True),
      others => <>
   );

end Demo_Flex_Styles;