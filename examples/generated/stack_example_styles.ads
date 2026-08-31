--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

--  The constants below intern as this package elaborates, so the
--  stores behind Intern_Rules and Build are wanted first.
pragma Elaborate_All (Adi.Widget_Styles);

package Stack_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   Root_Part_Styles : constant Part_Style_Array := Empty_Part_Styles;

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Root_Part_Styles,
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);
   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 30, 36)),
      others => <>);

   --  Base style for class 'tab-bar'
   function Tab_Bar_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Shrink => Set (0.0),
      Align_Items => Set (Center),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (0.0), Px (16.0))),
      others => <>);

   --  Base style for class 'stack'
   function Stack_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      others => <>);

   --  Base style for class 'page-red'
   function Page_Red_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (127, 29, 29)),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'page-blue'
   function Page_Blue_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tab-bar'
   Tab_Bar_Class_Widget : constant Widget_Style :=
     From (Tab_Bar_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tab-bar'
   Tab_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'stack'
   Stack_Class_Widget : constant Widget_Style :=
     From (Stack_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'stack'
   Stack_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Stack_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-red'
   Page_Red_Class_Widget : constant Widget_Style :=
     From (Page_Red_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-red'
   Page_Red_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Red_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-blue'
   Page_Blue_Class_Widget : constant Widget_Style :=
     From (Page_Blue_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-blue'
   Page_Blue_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Blue_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Stack_Example_Styles;