--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Properties;

package Widget_Property_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   function Root_Part_Styles return Part_Style_Array is (Empty_Part_Styles);

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Adi.Widget.Intern (Root_Part_Styles),
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);
   --  Base style for class 'alarm'
   function Alarm_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (20, 20, 20)),
      Padding => Set (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      others => <>);

   --  Style for class 'alarm' when [severity="ok"]
   function Alarm_Class_Prop_Severity_Ok_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (0, 128, 0)),
      others => <>);

   --  Style for class 'alarm' when [severity="warning"]
   function Alarm_Class_Prop_Severity_Warning_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (200, 160, 0)),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      others => <>);

   --  Style for class 'alarm' when [severity="critical"]
   function Alarm_Class_Prop_Severity_Critical_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (200, 0, 0)),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      others => <>);

   --  Style for class 'alarm' when widget State_Hovered, [severity="critical"]
   function Alarm_Class_Widget_Hovered_Prop_Severity_Critical_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (255, 0, 0)),
      others => <>);

   --  Style for class 'alarm' when [link]
   function Alarm_Class_Prop_Link_Style return Style_Rules is
     (
      Border_Width => Set (Border_Width (Px (3.0))),
      others => <>);

   --  Style for class 'alarm' when [link="degraded"], [severity="critical"]
   function Alarm_Class_Prop_Link_Degraded_Prop_Severity_Critical_Style return Style_Rules is
     (
      Border_Width => Set (Border_Width (Px (5.0))),
      others => <>);

   --  Style for class 'alarm' when :not([severity="critical"])
   function Alarm_Class_Not_Prop_Severity_Critical_Style return Style_Rules is
     (
      Outline_Width => Set_Outline_Width (Px (2.0)),
      others => <>);

   --  Style for class 'alarm' when :not([link])
   function Alarm_Class_Not_Prop_Link_Style return Style_Rules is
     (
      Margin => Set_Margin (CSS_Box (Px (7.0), Px (7.0), Px (7.0), Px (7.0))),
      others => <>);

   --  Style for class 'alarm' when [power="on"]
   function Alarm_Class_Prop_Power_On_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      others => <>);

   --  Style for class 'alarm' when [radio="on"]
   function Alarm_Class_Prop_Radio_On_Style return Style_Rules is
     (
      Flex_Grow => Set (3.0),
      others => <>);

   --  Style for class 'alarm'::label when [severity="critical"]
   function Alarm_Class_Label_Prop_Severity_Critical_Style return Style_Rules is
     (
      Color => Set (RGB (255, 255, 255)),
      others => <>);

   --  Complete widget style for class 'alarm'
   function Alarm_Class_Widget return Widget_Style is
     (From (Alarm_Class_Base_Style)
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Ok)), Alarm_Class_Prop_Severity_Ok_Style)
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Warning)), Alarm_Class_Prop_Severity_Warning_Style)
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)), Alarm_Class_Prop_Severity_Critical_Style)
     .On (When_State (State_Hovered) and When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)), Alarm_Class_Widget_Hovered_Prop_Severity_Critical_Style)
     .On (When_Property_Set (Test_Properties.Link.Id), Alarm_Class_Prop_Link_Style)
     .On (When_Property (Test_Properties.Link.Value (Test_Properties.Degraded)) and When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)), Alarm_Class_Prop_Link_Degraded_Prop_Severity_Critical_Style)
     .On (When_Not_Property (Test_Properties.Severity.Value (Test_Properties.Critical)), Alarm_Class_Not_Prop_Severity_Critical_Style)
     .On (When_Not_Property_Set (Test_Properties.Link.Id), Alarm_Class_Not_Prop_Link_Style)
     .On (When_Property (Test_Properties.Power.Value (Test_Properties.On)), Alarm_Class_Prop_Power_On_Style)
     .On (When_Property (Test_Properties.Radio.Value (Test_Properties.On)), Alarm_Class_Prop_Radio_On_Style)
     .Build);

   --  Complete widget style for class 'alarm'::label
   function Alarm_Class_Label_Widget return Widget_Style is
     (Create
     .On (When_Property (Test_Properties.Severity.Value (Test_Properties.Critical)), Alarm_Class_Label_Prop_Severity_Critical_Style)
     .Build);

   --  Part styles bundle for class 'alarm'
   function Alarm_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Alarm_Class_Widget, Enabled => True),
      Label_Part => (Style => Alarm_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Widget_Property_Styles;