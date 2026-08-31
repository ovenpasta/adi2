--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Runtime_Css_Properties;

--  The constants below intern as this package elaborates, so the
--  stores behind Intern_Rules and Build are wanted first.
pragma Elaborate_All (Adi.Widget_Styles);

package Runtime_Css_Example_Styles is

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
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (8, 12, 24)),
      Padding => Set (CSS_Box (Px (15.0), Px (15.0), Px (15.0), Px (15.0))),
      others => <>);

   --  Base style for class 'header'
   function Header_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (18.0))),
      Background_Color => Set_Bg (RGBA (30, 41, 59, 0.55)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (30.0), Px (0.0), RGBA (15, 23, 42, 0.45))),
      Padding => Set (CSS_Box (Px (18.0), Px (20.0), Px (18.0), Px (20.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (148, 163, 184, 0.35))),
      Border_Radius => Set (Radius (Px (18.0))),
      others => <>);

   --  Base style for class 'content'
   function Content_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (40.0))),
      others => <>);

   --  Base style for class 'card-left'
   function Card_Left_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (10.0))),
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.9)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (12.0), Px (28.0), Px (0.0), RGBA (2, 6, 23, 0.5))),
      Transition => Set ((Duration => 0.5, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (59, 130, 246, 0.35))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Style for class 'card-left' when widget State_Hovered
   function Card_Left_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (30, 58, 110, 0.92)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (16.0), Px (36.0), Px (0.0), RGBA (15, 23, 42, 0.75))),
      Border_Color => Set (Border_Color (RGBA (96, 165, 250, 0.9))),
      others => <>);

   --  Style for class 'card-left' when [severity="ok"]
   function Card_Left_Class_Prop_Severity_Ok_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (6, 78, 59, 0.92)),
      Border_Color => Set (Border_Color (RGBA (34, 197, 94, 0.9))),
      others => <>);

   --  Style for class 'card-left' when [severity="warning"]
   function Card_Left_Class_Prop_Severity_Warning_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (87, 66, 6, 0.92)),
      Border_Color => Set (Border_Color (RGBA (234, 179, 8, 0.9))),
      others => <>);

   --  Style for class 'card-left' when [severity="critical"]
   function Card_Left_Class_Prop_Severity_Critical_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (94, 12, 12, 0.92)),
      Border_Color => Set (Border_Color (RGBA (239, 68, 68, 0.9))),
      others => <>);

   --  Style for class 'card-left' when :not([severity])
   function Card_Left_Class_Not_Prop_Severity_Style return Style_Rules is
     (
      Border_Style => Set (Border_Style (Dashed)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'card-right'
   function Card_Right_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (10.0))),
      Background_Color => Set_Bg (RGBA (30, 41, 59, 0.9)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (12.0), Px (28.0), Px (0.0), RGBA (2, 6, 23, 0.5))),
      Transition => Set ((Duration => 0.5, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (45, 212, 191, 0.35))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Style for class 'card-right' when widget State_Hovered
   function Card_Right_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (22, 78, 99, 0.92)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (16.0), Px (36.0), Px (0.0), RGBA (15, 23, 42, 0.75))),
      Border_Color => Set (Border_Color (RGBA (45, 212, 191, 0.9))),
      others => <>);

   --  Style for class 'card-right' when [severity="ok"]
   function Card_Right_Class_Prop_Severity_Ok_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (6, 78, 59, 0.92)),
      Border_Color => Set (Border_Color (RGBA (34, 197, 94, 0.9))),
      others => <>);

   --  Style for class 'card-right' when [severity="warning"]
   function Card_Right_Class_Prop_Severity_Warning_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (87, 66, 6, 0.92)),
      Border_Color => Set (Border_Color (RGBA (234, 179, 8, 0.9))),
      others => <>);

   --  Style for class 'card-right' when [severity="critical"]
   function Card_Right_Class_Prop_Severity_Critical_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (94, 12, 12, 0.92)),
      Border_Color => Set (Border_Color (RGBA (239, 68, 68, 0.9))),
      others => <>);

   --  Style for class 'card-right' when :not([severity])
   function Card_Right_Class_Not_Prop_Severity_Style return Style_Rules is
     (
      Border_Style => Set (Border_Style (Dashed)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (34.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      others => <>);

   --  Base style for class 'subtitle'
   function Subtitle_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'subtitle'::label
   function Subtitle_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (16.0)),
      others => <>);

   --  Base style for class 'badge'
   function Badge_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Width => Set (Size (Px (84.0))),
      Background_Color => Set_Bg (RGBA (34, 197, 94, 0.18)),
      Padding => Set (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0))),
      Margin => Set_Margin (CSS_Box (Px (8.0), Px (0.0), Px (0.0), Px (0.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (74, 222, 128, 0.6))),
      Border_Radius => Set (Radius (Px (999.0))),
      others => <>);

   --  Base style for class 'badge'::label
   function Badge_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (134, 239, 172)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Align => Set (Text_Center),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'mode-button'
   function Mode_Button_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Width => Set (Size (Px (220.0))),
      Background_Color => Set_Bg (RGBA (30, 64, 175, 0.35)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.2, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (28.0))),
      Margin => Set_Margin (CSS_Box (Px (20.0), Px (0.0), Px (0.0), Px (0.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (96, 165, 250, 0.7))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Style for class 'mode-button' when widget State_Hovered
   function Mode_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (30, 64, 175, 0.55)),
      others => <>);

   --  Style for class 'mode-button' when widget State_Pressed
   function Mode_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (30, 64, 175, 0.7)),
      others => <>);

   --  Base style for class 'mode-button'::label
   function Mode_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (219, 234, 254)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for tag 'button'
   function Button_Tag_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.22, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Base style for id 'mode-switch'
   function Mode_Switch_Id_Base_Style return Style_Rules is
     (
      Border_Color => Set (Border_Color (RGBA (147, 197, 253, 0.95))),
      others => <>);

   --  Base style for class 'card-title'
   function Card_Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'card-title'::label
   function Card_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (226, 232, 240)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Style for class 'card-title'::label when [severity="critical"]
   function Card_Title_Class_Label_Prop_Severity_Critical_Style return Style_Rules is
     (
      Color => Set (RGB (254, 202, 202)),
      others => <>);

   --  Base style for class 'card-body'::label
   function Card_Body_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (10.0)),
      Line_Height => Set (Line_Height (1.4)),
      others => <>);

   --  Base style for class 'status'
   function Status_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.75)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (28.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (71, 85, 105, 0.8))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (125, 211, 252)),
      Font_Size => Set_Font (Px (13.0)),
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

   --  Complete widget style for class 'header'
   Header_Class_Widget : constant Widget_Style :=
     From (Header_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'header'
   Header_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'content'
   Content_Class_Widget : constant Widget_Style :=
     From (Content_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'content'
   Content_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Content_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-left'
   Card_Left_Class_Widget : constant Widget_Style :=
     From (Card_Left_Class_Base_Style)
     .On (When_State (State_Hovered), Card_Left_Class_Widget_Hovered_Style)
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Ok)), Card_Left_Class_Prop_Severity_Ok_Style)
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Warning)), Card_Left_Class_Prop_Severity_Warning_Style)
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Critical)), Card_Left_Class_Prop_Severity_Critical_Style)
     .On (When_Not_Property_Set (Runtime_Css_Properties.Severity.Id), Card_Left_Class_Not_Prop_Severity_Style)
     .Build;

   --  Part styles bundle for class 'card-left'
   Card_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Left_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-right'
   Card_Right_Class_Widget : constant Widget_Style :=
     From (Card_Right_Class_Base_Style)
     .On (When_State (State_Hovered), Card_Right_Class_Widget_Hovered_Style)
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Ok)), Card_Right_Class_Prop_Severity_Ok_Style)
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Warning)), Card_Right_Class_Prop_Severity_Warning_Style)
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Critical)), Card_Right_Class_Prop_Severity_Critical_Style)
     .On (When_Not_Property_Set (Runtime_Css_Properties.Severity.Id), Card_Right_Class_Not_Prop_Severity_Style)
     .Build;

   --  Part styles bundle for class 'card-right'
   Card_Right_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Right_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     From (Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     From (Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'subtitle'
   Subtitle_Class_Widget : constant Widget_Style :=
     From (Subtitle_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     From (Subtitle_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'badge'
   Badge_Class_Widget : constant Widget_Style :=
     From (Badge_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'badge'::label
   Badge_Class_Label_Widget : constant Widget_Style :=
     From (Badge_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'badge'
   Badge_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Badge_Class_Widget, Enabled => True),
      Label_Part => (Style => Badge_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'mode-button'
   Mode_Button_Class_Widget : constant Widget_Style :=
     From (Mode_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Mode_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Mode_Button_Class_Widget_Pressed_Style)
     .Build;

   --  Complete widget style for class 'mode-button'::label
   Mode_Button_Class_Label_Widget : constant Widget_Style :=
     From (Mode_Button_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'mode-button'
   Mode_Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Mode_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Mode_Button_Class_Label_Widget, Enabled => True),
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

   --  Complete widget style for id 'mode-switch'
   Mode_Switch_Id_Widget : constant Widget_Style :=
     From (Mode_Switch_Id_Base_Style)
     .Build;

   --  Part styles bundle for id 'mode-switch'
   Mode_Switch_Id_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Mode_Switch_Id_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-title'
   Card_Title_Class_Widget : constant Widget_Style :=
     From (Card_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'card-title'::label
   Card_Title_Class_Label_Widget : constant Widget_Style :=
     From (Card_Title_Class_Label_Base_Style)
     .On (When_Property (Runtime_Css_Properties.Severity.Value (Runtime_Css_Properties.Critical)), Card_Title_Class_Label_Prop_Severity_Critical_Style)
     .Build;

   --  Part styles bundle for class 'card-title'
   Card_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-body'::label
   Card_Body_Class_Label_Widget : constant Widget_Style :=
     From (Card_Body_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'card-body'
   Card_Body_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Card_Body_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     From (Status_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     From (Status_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Runtime_Css_Example_Styles;