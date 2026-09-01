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
   --  Style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Background (RGB (30, 30, 36))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tab-bar'
   Tab_Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Flex_Shrink (0.0)
        .Align_Items (Center)
        .Padding (CSS_Box (Px (16.0), Px (16.0), Px (0.0), Px (16.0)))
     .Build;

   --  Part styles bundle for class 'tab-bar'
   Tab_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'stack'
   Stack_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Padding (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0)))
     .Build;

   --  Part styles bundle for class 'stack'
   Stack_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Stack_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'page-red'
   Page_Red_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Background (RGB (127, 29, 29))
        .Gap (Gap (Px (8.0)))
        .Padding (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0)))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'page-red'
   Page_Red_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Red_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'page-blue'
   Page_Blue_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Background (RGB (30, 58, 138))
        .Gap (Gap (Px (8.0)))
        .Padding (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0)))
        .Radius (Radius (Px (12.0)))
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