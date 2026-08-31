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

package Stack_Example_Green_Styles is

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
   --  Base style for class 'page-green'
   function Page_Green_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (20, 83, 45)),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'page-title'
   function Page_Title_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'page-title'::label
   function Page_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'page-desc'
   function Page_Desc_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      others => <>);

   --  Base style for class 'page-desc'::label
   function Page_Desc_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGBA (255, 255, 255, 0.7)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Normal),
      others => <>);

   --  Complete widget style for class 'page-green'
   Page_Green_Class_Widget : constant Widget_Style :=
     From (Page_Green_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-green'
   Page_Green_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Green_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-title'
   Page_Title_Class_Widget : constant Widget_Style :=
     From (Page_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'page-title'::label
   Page_Title_Class_Label_Widget : constant Widget_Style :=
     From (Page_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-title'
   Page_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Page_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-desc'
   Page_Desc_Class_Widget : constant Widget_Style :=
     From (Page_Desc_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'page-desc'::label
   Page_Desc_Class_Label_Widget : constant Widget_Style :=
     From (Page_Desc_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-desc'
   Page_Desc_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Desc_Class_Widget, Enabled => True),
      Label_Part => (Style => Page_Desc_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Stack_Example_Green_Styles;