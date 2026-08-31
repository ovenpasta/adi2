--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Properties;

--  The constants below intern as this package elaborates, so the
--  stores behind Intern_Rules and Build are wanted first.
pragma Elaborate_All (Adi.Widget_Styles);

package Widget_Property_Static_Styles is

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
   --  Base style for class 'hush'
   function Hush_Class_Base_Style return Style_Rules is
     (
      Opacity => Set (1.0),
      others => <>);

   --  Style for class 'hush' when [quiet="yes"]
   function Hush_Class_Prop_Quiet_Yes_Style return Style_Rules is
     (
      Opacity => Set (0.25),
      others => <>);

   --  Complete widget style for class 'hush'
   Hush_Class_Widget : constant Widget_Style :=
     From (Hush_Class_Base_Style)
     .On (When_Property (Test_Properties.Quiet.Value (Test_Properties.Yes)), Hush_Class_Prop_Quiet_Yes_Style)
     .Build;

   --  Part styles bundle for class 'hush'
   Hush_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Hush_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Widget_Property_Static_Styles;