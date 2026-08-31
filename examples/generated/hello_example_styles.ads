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

package Hello_Example_Styles is

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
      Background_Color => Set_Bg (RGB (24, 26, 32)),
      Gap => Set (Gap (Px (16.0))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>);

   --  Base style for tag 'button'
   function Button_Tag_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'primary'
   function Primary_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>);

   --  Style for class 'primary' when widget State_Hovered
   function Primary_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      others => <>);

   --  Base style for class 'primary'::label
   function Primary_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      others => <>);

   --  Base style for id 'Greeting'::label
   function Greeting_Id_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (220, 225, 240)),
      Font_Size => Set_Font (Px (18.0)),
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

   --  Complete widget style for tag 'button'
   Button_Tag_Widget : constant Widget_Style :=
     From (Button_Tag_Base_Style)
     .Build;

   --  Part styles bundle for tag 'button'
   Button_Tag_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Button_Tag_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'primary'
   Primary_Class_Widget : constant Widget_Style :=
     From (Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Primary_Class_Widget_Hovered_Style)
     .Build;

   --  Complete widget style for class 'primary'::label
   Primary_Class_Label_Widget : constant Widget_Style :=
     From (Primary_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'primary'
   Primary_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for id 'Greeting'::label
   Greeting_Id_Label_Widget : constant Widget_Style :=
     From (Greeting_Id_Label_Base_Style)
     .Build;

   --  Part styles bundle for id 'Greeting'
   Greeting_Id_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Greeting_Id_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Hello_Example_Styles;