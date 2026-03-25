--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Demo_Flex_Styles is

   --  Base style for class 'box-base'
   function Box_Base_Class_Base_Style return Style_Rules is
     (
      Min_Width => Set (Size (Px (20.0))),
      Min_Height => Set (Size (Px (20.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (C (Gray))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'flex-container'
   function Flex_Container_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (C (Gray))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'row-base'
   function Row_Base_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Grow => Set (1.0),
      Justify_Content => Set (Flex_Start),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (15.0))),
      Background_Color => Set_Bg (C (Transparent)),
      others => <>);

   --  Complete widget style for class 'box-base'
   function Box_Base_Class_Widget return Widget_Style is
     (From (Box_Base_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'box-base'
   function Box_Base_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Box_Base_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'flex-container'
   function Flex_Container_Class_Widget return Widget_Style is
     (From (Flex_Container_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'flex-container'
   function Flex_Container_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Flex_Container_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'row-base'
   function Row_Base_Class_Widget return Widget_Style is
     (From (Row_Base_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'row-base'
   function Row_Base_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Row_Base_Class_Widget, Enabled => True),
      others => <>
   ]);

end Demo_Flex_Styles;