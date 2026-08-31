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

package Font_Example_Styles is

   function Has_Root_Font_Size return Boolean is (True);
   function Root_Font_Size return Length_Value is (Dip (18.0));

   function Root_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Dip (18.0)),
      others => <>);

   function Has_Root_Styles return Boolean is (True);
   Root_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => From (Root_Base_Style).Build, Enabled => True),
      others => <>
   ];

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Root_Part_Styles,
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);

   function Var_Font_Caption return Length_Value is (Root_Em (0.72));
   function Var_Font_Small return Length_Value is (Root_Em (0.78));
   function Var_Font_Body return Length_Value is (Root_Em (1.0));
   function Var_Font_Title return Length_Value is (Root_Em (1.33));
   function Var_Font_Large return Length_Value is (Root_Em (1.56));

   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (17, 24, 39)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Overflow_X => Set_Overflow_X (Overflow_Auto),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'root'::knob
   function Root_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (226, 232, 240, 0.8)),
      Transition => Set ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'root'::knob when part State_Hovered
   function Root_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (241, 245, 249, 0.94)),
      others => <>);

   --  Style for class 'root'::knob when part State_Pressed
   function Root_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (248, 250, 252, 1.0)),
      others => <>);

   --  Base style for class 'root'::scroll
   function Root_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.24)),
      Transition => Set ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Margin => Set_Margin (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (8.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'root'::scroll when part State_Hovered
   function Root_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.42)),
      others => <>);

   --  Style for class 'root'::scroll when part State_Pressed
   function Root_Class_Scroll_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.62)),
      others => <>);

   --  Base style for class 'container'
   function Container_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (10.0))),
      Background_Color => Set_Bg (RGB (31, 41, 55)),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Root_Em (1.33)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'hint'
   function Hint_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'hint'::label
   function Hint_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (191, 219, 254)),
      Font_Size => Set_Font (Root_Em (0.72)),
      others => <>);

   --  Base style for class 'section_title'
   function Section_Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'section_title'::label
   function Section_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Root_Em (0.78)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>);

   --  Base style for class 'sample'
   function Sample_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (15, 23, 42)),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'sample'::label
   function Sample_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (226, 232, 240)),
      Font_Size => Set_Font (Root_Em (1.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'weight_normal'::label
   function Weight_Normal_Class_Label_Base_Style return Style_Rules is
     (
      Font_Weight => Set (Weight_Normal),
      others => <>);

   --  Base style for class 'weight_light'::label
   function Weight_Light_Class_Label_Base_Style return Style_Rules is
     (
      Font_Weight => Set (Weight_Light),
      others => <>);

   --  Base style for class 'weight_medium'::label
   function Weight_Medium_Class_Label_Base_Style return Style_Rules is
     (
      Font_Weight => Set (Weight_Medium),
      others => <>);

   --  Base style for class 'weight_semibold'::label
   function Weight_Semibold_Class_Label_Base_Style return Style_Rules is
     (
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>);

   --  Base style for class 'weight_bold'::label
   function Weight_Bold_Class_Label_Base_Style return Style_Rules is
     (
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'weight_black'::label
   function Weight_Black_Class_Label_Base_Style return Style_Rules is
     (
      Font_Weight => Set (Weight_Black),
      others => <>);

   --  Base style for class 'style_italic'::label
   function Style_Italic_Class_Label_Base_Style return Style_Rules is
     (
      Font_Style => Set (Style_Italic),
      others => <>);

   --  Base style for class 'style_oblique'::label
   function Style_Oblique_Class_Label_Base_Style return Style_Rules is
     (
      Font_Style => Set (Style_Oblique),
      others => <>);

   --  Base style for class 'size_small'::label
   function Size_Small_Class_Label_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Root_Em (0.72)),
      others => <>);

   --  Base style for class 'size_base'::label
   function Size_Base_Class_Label_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Root_Em (1.0)),
      others => <>);

   --  Base style for class 'size_large'::label
   function Size_Large_Class_Label_Base_Style return Style_Rules is
     (
      Font_Size => Set_Font (Root_Em (1.56)),
      others => <>);

   --  Base style for class 'decor_underline'::label
   function Decor_Underline_Class_Label_Base_Style return Style_Rules is
     (
      Text_Decoration => Set (Decoration_Underline),
      others => <>);

   --  Base style for class 'decor_strike'::label
   function Decor_Strike_Class_Label_Base_Style return Style_Rules is
     (
      Text_Decoration => Set (Decoration_Line_Through),
      others => <>);

   --  Base style for class 'decor_overline'::label
   function Decor_Overline_Class_Label_Base_Style return Style_Rules is
     (
      Text_Decoration => Set (Decoration_Overline),
      others => <>);

   --  Base style for class 'wrap_sample'
   function Wrap_Sample_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (100, 116, 139))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'wrap_sample'::label
   function Wrap_Sample_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (219, 234, 254)),
      Font_Size => Set_Font (Root_Em (0.78)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>);

   --  Base style for class 'lh_normal'::label
   function Lh_Normal_Class_Label_Base_Style return Style_Rules is
     (
      Line_Height => Set (Normal_Line_Height),
      others => <>);

   --  Base style for class 'lh_number'::label
   function Lh_Number_Class_Label_Base_Style return Style_Rules is
     (
      Line_Height => Set (Line_Height (1.8)),
      others => <>);

   --  Base style for class 'lh_percent'::label
   function Lh_Percent_Class_Label_Base_Style return Style_Rules is
     (
      Line_Height => Set (Line_Height (Pct (150.0))),
      others => <>);

   --  Base style for class 'lh_length'::label
   function Lh_Length_Class_Label_Base_Style return Style_Rules is
     (
      Line_Height => Set (Line_Height (Px (30.0))),
      others => <>);

   --  Base style for class 'align_left'::label
   function Align_Left_Class_Label_Base_Style return Style_Rules is
     (
      Text_Align => Set (Text_Left),
      others => <>);

   --  Base style for class 'align_center'::label
   function Align_Center_Class_Label_Base_Style return Style_Rules is
     (
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'align_right'::label
   function Align_Right_Class_Label_Base_Style return Style_Rules is
     (
      Text_Align => Set (Text_Right),
      others => <>);

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     From (Root_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Root_Class_Knob_Part_Pressed_Style)
     .Build;

   --  Complete widget style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     From (Root_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Scroll_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Root_Class_Scroll_Part_Pressed_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     From (Container_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'hint'
   Hint_Class_Widget : constant Widget_Style :=
     From (Hint_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'hint'::label
   Hint_Class_Label_Widget : constant Widget_Style :=
     From (Hint_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'hint'
   Hint_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'section_title'
   Section_Title_Class_Widget : constant Widget_Style :=
     From (Section_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'section_title'::label
   Section_Title_Class_Label_Widget : constant Widget_Style :=
     From (Section_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'section_title'
   Section_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Section_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'sample'
   Sample_Class_Widget : constant Widget_Style :=
     From (Sample_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'sample'::label
   Sample_Class_Label_Widget : constant Widget_Style :=
     From (Sample_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'sample'
   Sample_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sample_Class_Widget, Enabled => True),
      Label_Part => (Style => Sample_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'weight_normal'::label
   Weight_Normal_Class_Label_Widget : constant Widget_Style :=
     From (Weight_Normal_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'weight_normal'
   Weight_Normal_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Normal_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'weight_light'::label
   Weight_Light_Class_Label_Widget : constant Widget_Style :=
     From (Weight_Light_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'weight_light'
   Weight_Light_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Light_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'weight_medium'::label
   Weight_Medium_Class_Label_Widget : constant Widget_Style :=
     From (Weight_Medium_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'weight_medium'
   Weight_Medium_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Medium_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'weight_semibold'::label
   Weight_Semibold_Class_Label_Widget : constant Widget_Style :=
     From (Weight_Semibold_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'weight_semibold'
   Weight_Semibold_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Semibold_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'weight_bold'::label
   Weight_Bold_Class_Label_Widget : constant Widget_Style :=
     From (Weight_Bold_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'weight_bold'
   Weight_Bold_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Bold_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'weight_black'::label
   Weight_Black_Class_Label_Widget : constant Widget_Style :=
     From (Weight_Black_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'weight_black'
   Weight_Black_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Black_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'style_italic'::label
   Style_Italic_Class_Label_Widget : constant Widget_Style :=
     From (Style_Italic_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'style_italic'
   Style_Italic_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Style_Italic_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'style_oblique'::label
   Style_Oblique_Class_Label_Widget : constant Widget_Style :=
     From (Style_Oblique_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'style_oblique'
   Style_Oblique_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Style_Oblique_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'size_small'::label
   Size_Small_Class_Label_Widget : constant Widget_Style :=
     From (Size_Small_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'size_small'
   Size_Small_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Size_Small_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'size_base'::label
   Size_Base_Class_Label_Widget : constant Widget_Style :=
     From (Size_Base_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'size_base'
   Size_Base_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Size_Base_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'size_large'::label
   Size_Large_Class_Label_Widget : constant Widget_Style :=
     From (Size_Large_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'size_large'
   Size_Large_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Size_Large_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'decor_underline'::label
   Decor_Underline_Class_Label_Widget : constant Widget_Style :=
     From (Decor_Underline_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'decor_underline'
   Decor_Underline_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Decor_Underline_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'decor_strike'::label
   Decor_Strike_Class_Label_Widget : constant Widget_Style :=
     From (Decor_Strike_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'decor_strike'
   Decor_Strike_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Decor_Strike_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'decor_overline'::label
   Decor_Overline_Class_Label_Widget : constant Widget_Style :=
     From (Decor_Overline_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'decor_overline'
   Decor_Overline_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Decor_Overline_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'wrap_sample'
   Wrap_Sample_Class_Widget : constant Widget_Style :=
     From (Wrap_Sample_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'wrap_sample'::label
   Wrap_Sample_Class_Label_Widget : constant Widget_Style :=
     From (Wrap_Sample_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'wrap_sample'
   Wrap_Sample_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wrap_Sample_Class_Widget, Enabled => True),
      Label_Part => (Style => Wrap_Sample_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'lh_normal'::label
   Lh_Normal_Class_Label_Widget : constant Widget_Style :=
     From (Lh_Normal_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'lh_normal'
   Lh_Normal_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Normal_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'lh_number'::label
   Lh_Number_Class_Label_Widget : constant Widget_Style :=
     From (Lh_Number_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'lh_number'
   Lh_Number_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Number_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'lh_percent'::label
   Lh_Percent_Class_Label_Widget : constant Widget_Style :=
     From (Lh_Percent_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'lh_percent'
   Lh_Percent_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Percent_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'lh_length'::label
   Lh_Length_Class_Label_Widget : constant Widget_Style :=
     From (Lh_Length_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'lh_length'
   Lh_Length_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Length_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'align_left'::label
   Align_Left_Class_Label_Widget : constant Widget_Style :=
     From (Align_Left_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'align_left'
   Align_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Align_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'align_center'::label
   Align_Center_Class_Label_Widget : constant Widget_Style :=
     From (Align_Center_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'align_center'
   Align_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Align_Center_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'align_right'::label
   Align_Right_Class_Label_Widget : constant Widget_Style :=
     From (Align_Right_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'align_right'
   Align_Right_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Align_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Font_Example_Styles;