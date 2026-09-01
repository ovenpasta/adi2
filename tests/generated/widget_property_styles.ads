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

package Widget_Property_Styles is

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
   --  Style for class 'alarm'
   Alarm_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (20, 20, 20))
        .Padding (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0)))
        .Border_Width (Border_Width (Px (1.0)))
     --  [severity="ok"]
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Ok)))
        .Background (RGB (0, 128, 0))
     --  [severity="warning"]
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Warning)))
        .Background (RGB (200, 160, 0))
        .Padding (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0)))
     --  [severity="critical"]
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)))
        .Background (RGB (200, 0, 0))
        .Padding (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0)))
     --  widget State_Hovered, [severity="critical"]
     .On (When_State (State_Hovered) and When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)))
        .Background (RGB (255, 0, 0))
     --  [link]
     .On (When_Property_Set (Test_Properties.Link.Id))
        .Border_Width (Border_Width (Px (3.0)))
     --  [link="degraded"], [severity="critical"]
     .On (When_Property (Test_Properties.Link.Value (Test_Properties.Degraded)) and When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)))
        .Border_Width (Border_Width (Px (5.0)))
     --  :not([severity="critical"])
     .On (When_Not_Property (Test_Properties.Severity.Value (Test_Properties.Critical)))
        .Outline_Width (Px (2.0))
     --  :not([link])
     .On (When_Not_Property_Set (Test_Properties.Link.Id))
        .Margin (CSS_Box (Px (7.0), Px (7.0), Px (7.0), Px (7.0)))
     --  [power="on"]
     .On (When_Property (Test_Properties.Power.Value (Test_Properties.On)))
        .Opacity (0.5)
     --  [radio="on"]
     .On (When_Property (Test_Properties.Radio.Value (Test_Properties.On)))
        .Flex_Grow (3.0)
     .Build;

   --  Style for class 'alarm'::label
   Alarm_Class_Label_Widget : constant Widget_Style :=
     Style_Of
     --  [severity="critical"]
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)))
        .Text_Color (RGB (255, 255, 255))
     .Build;

   --  Part styles bundle for class 'alarm'
   Alarm_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Alarm_Class_Widget, Enabled => True),
      Label_Part => (Style => Alarm_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Widget_Property_Styles;