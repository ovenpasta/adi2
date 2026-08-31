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

package Auto_Margin_Styles is

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
   --  Base style for tag 'box'
   function Box_Tag_Base_Style return Style_Rules is
     (
      Margin => Set_Margin (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0))),
      others => <>);

   --  Base style for class 'centred'
   function Centred_Class_Base_Style return Style_Rules is
     (
      Margin => [Top => Set_Margin_Side (Px (0.0)), Right => Set_Margin (Auto_Margin), Bottom => Set_Margin_Side (Px (0.0)), Left => Set_Margin (Auto_Margin)],
      others => <>);

   --  Base style for class 'push-right'
   function Push_Right_Class_Base_Style return Style_Rules is
     (
      Margin => [Left => Set_Margin (Auto_Margin), others => <>],
      others => <>);

   --  Base style for class 'push-left'
   function Push_Left_Class_Base_Style return Style_Rules is
     (
      Margin => [Right => Set_Margin (Auto_Margin), others => <>],
      others => <>);

   --  Base style for class 'three'
   function Three_Class_Base_Style return Style_Rules is
     (
      Margin => [Top => Set_Margin_Side (Px (5.0)), Right => Set_Margin (Auto_Margin), Bottom => Set_Margin_Side (Px (12.0)), Left => Set_Margin (Auto_Margin)],
      others => <>);

   --  Base style for class 'vertical-auto'
   function Vertical_Auto_Class_Base_Style return Style_Rules is
     (
      Margin => [Top => Set_Margin (Auto_Margin), Bottom => Set_Margin (Auto_Margin), others => <>],
      others => <>);

   --  Base style for class 'tweak'
   function Tweak_Class_Base_Style return Style_Rules is
     (
      Margin => [Right => Set_Margin_Side (Px (7.0)), others => <>],
      others => <>);

   --  Style for class 'tweak' when widget State_Hovered
   function Tweak_Class_Widget_Hovered_Style return Style_Rules is
     (
      Margin => [Left => Set_Margin (Auto_Margin), others => <>],
      others => <>);

   --  Base style for id 'bad'
   function Bad_Id_Base_Style return Style_Rules is
     (
      Padding => [Top => Set (Px (3.0)), others => <>],
      Border_Width => [Left => Set (Px (6.0)), others => <>],
      others => <>);

   --  Complete widget style for tag 'box'
   Box_Tag_Widget : constant Widget_Style :=
     From (Box_Tag_Base_Style)
     .Build;

   --  Part styles bundle for tag 'box'
   Box_Tag_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Box_Tag_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'centred'
   Centred_Class_Widget : constant Widget_Style :=
     From (Centred_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'centred'
   Centred_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Centred_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'push-right'
   Push_Right_Class_Widget : constant Widget_Style :=
     From (Push_Right_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'push-right'
   Push_Right_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Push_Right_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'push-left'
   Push_Left_Class_Widget : constant Widget_Style :=
     From (Push_Left_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'push-left'
   Push_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Push_Left_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'three'
   Three_Class_Widget : constant Widget_Style :=
     From (Three_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'three'
   Three_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Three_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'vertical-auto'
   Vertical_Auto_Class_Widget : constant Widget_Style :=
     From (Vertical_Auto_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'vertical-auto'
   Vertical_Auto_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Vertical_Auto_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tweak'
   Tweak_Class_Widget : constant Widget_Style :=
     From (Tweak_Class_Base_Style)
     .On (When_State (State_Hovered), Tweak_Class_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tweak'
   Tweak_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tweak_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for id 'bad'
   Bad_Id_Widget : constant Widget_Style :=
     From (Bad_Id_Base_Style)
     .Build;

   --  Part styles bundle for id 'bad'
   Bad_Id_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bad_Id_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Auto_Margin_Styles;