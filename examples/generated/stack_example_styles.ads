--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Stack_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 30, 36)),
      others => <>
   );

   --  Base style for class 'tab-bar'
   Tab_Bar_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (0.0), Px (16.0))),
      others => <>
   );

   --  Base style for class 'stack'
   Stack_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      others => <>
   );

   --  Base style for class 'page-red'
   Page_Red_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (127, 29, 29)),
      Border_Radius => Set (Radius (Px (12.0))),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      others => <>
   );

   --  Base style for class 'page-green'
   Page_Green_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (20, 83, 45)),
      Border_Radius => Set (Radius (Px (12.0))),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      others => <>
   );

   --  Base style for class 'page-blue'
   Page_Blue_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      Border_Radius => Set (Radius (Px (12.0))),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      others => <>
   );

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tab-bar'
   Tab_Bar_Class_Widget : constant Widget_Style :=
     From (Tab_Bar_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tab-bar'
   Tab_Bar_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'stack'
   Stack_Class_Widget : constant Widget_Style :=
     From (Stack_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'stack'
   Stack_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Stack_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-red'
   Page_Red_Class_Widget : constant Widget_Style :=
     From (Page_Red_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-red'
   Page_Red_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Red_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-green'
   Page_Green_Class_Widget : constant Widget_Style :=
     From (Page_Green_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-green'
   Page_Green_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Green_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-blue'
   Page_Blue_Class_Widget : constant Widget_Style :=
     From (Page_Blue_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-blue'
   Page_Blue_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Blue_Class_Widget, Enabled => True),
      others => <>
   ];

end Stack_Example_Styles;