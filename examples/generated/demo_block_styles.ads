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

package Demo_Block_Styles is

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
      Gap => Set (Gap (Px (18.0))),
      Background_Color => Set_Bg (RGB (24, 26, 33)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'root'::knob
   function Root_Class_Knob_Base_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.1))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::knob when part State_Hovered
   function Root_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.28))),
      others => <>);

   --  Base style for class 'root'::scroll
   function Root_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.06)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::scroll when part State_Hovered
   function Root_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.16)),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (236, 239, 244)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'section'
   function Section_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (6.0))),
      Flex_Shrink => Set (0.0),
      Padding => [Right => Set (Px (14.0)), others => <>],
      others => <>);

   --  Base style for class 'caption'::label
   function Caption_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (163, 190, 140)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'note'::label
   function Note_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (150, 158, 172)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>);

   --  Base style for class 'cases'
   function Cases_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Wrap => Set (Wrap),
      Gap => Set (Gap (Px (12.0))),
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'case'
   function Case_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (4.0))),
      Flex_Basis => Set (Basis (Px (0.0))),
      Flex_Grow => Set (1.0),
      Min_Width => Set (Size (Px (0.0))),
      others => <>);

   --  Base style for class 'case-label'::label
   function Case_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (150, 158, 172)),
      Font_Size => Set_Font (Px (11.0)),
      others => <>);

   --  Base style for class 'demo'
   function Demo_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (35, 38, 48)),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (0.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (94, 129, 172))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'bar'
   function Bar_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (22.0))),
      Background_Color => Set_Bg (RGB (94, 129, 172)),
      Padding => [Left => Set (Px (8.0)), others => <>],
      Margin => [Bottom => Set_Margin_Side (Px (6.0)), others => <>],
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'bar'::label
   function Bar_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (240, 243, 248)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Bold),
      Vertical_Align => Set (VA_Middle),
      others => <>);

   --  Base style for class 'w120'
   function W120_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (120.0))),
      others => <>);

   --  Base style for class 'w45'
   function W45_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Pct (45.0))),
      others => <>);

   --  Base style for class 'wcap'
   function Wcap_Class_Base_Style return Style_Rules is
     (
      Max_Width => Set (Size (Px (160.0))),
      others => <>);

   --  Base style for class 'w280'
   function W280_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (280.0))),
      others => <>);

   --  Base style for class 'indent'
   function Indent_Class_Base_Style return Style_Rules is
     (
      Margin => [Left => Set_Margin_Side (Px (48.0)), others => <>],
      others => <>);

   --  Base style for class 'inset'
   function Inset_Class_Base_Style return Style_Rules is
     (
      Padding => [Left => Set (Px (48.0)), others => <>],
      others => <>);

   --  Base style for class 'centred'
   function Centred_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (220.0))),
      Margin => [Right => Set_Margin (Auto_Margin), Left => Set_Margin (Auto_Margin), others => <>],
      others => <>);

   --  Base style for class 'pushed'
   function Pushed_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (220.0))),
      Margin => [Left => Set_Margin (Auto_Margin), others => <>],
      others => <>);

   --  Base style for class 'auto-width'
   function Auto_Width_Class_Base_Style return Style_Rules is
     (
      Margin => [Right => Set_Margin (Auto_Margin), Left => Set_Margin (Auto_Margin), others => <>],
      others => <>);

   --  Base style for class 'h20'
   function H20_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (20.0))),
      others => <>);

   --  Base style for class 'h34'
   function H34_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (34.0))),
      others => <>);

   --  Base style for class 'h48'
   function H48_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (48.0))),
      others => <>);

   --  Base style for class 'ghost'
   function Ghost_Class_Base_Style return Style_Rules is
     (
      Height => Set (Auto_Size),
      Background_Color => Set_Bg (RGB (191, 97, 106)),
      Margin => [Bottom => Set_Margin_Side (Px (0.0)), others => <>],
      others => <>);

   --  Base style for class 'frame'
   function Frame_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (120.0))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      others => <>);

   --  Base style for class 'fill'
   function Fill_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Pct (100.0))),
      Background_Color => Set_Bg (RGB (163, 190, 140)),
      Margin => [Bottom => Set_Margin_Side (Px (0.0)), others => <>],
      others => <>);

   --  Base style for class 'half'
   function Half_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Pct (50.0))),
      Background_Color => Set_Bg (RGB (235, 203, 139)),
      Margin => [Bottom => Set_Margin_Side (Px (0.0)), others => <>],
      others => <>);

   --  Base style for class 'quarter'
   function Quarter_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Pct (25.0))),
      Background_Color => Set_Bg (RGB (180, 142, 173)),
      Margin => [Bottom => Set_Margin_Side (Px (0.0)), others => <>],
      others => <>);

   --  Base style for class 'flex-row'
   function Flex_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (6.0))),
      others => <>);

   --  Base style for class 'chip'
   function Chip_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (60.0))),
      Height => Set (Size (Px (22.0))),
      Margin => [Bottom => Set_Margin_Side (Px (6.0)), others => <>],
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'chip-1'
   function Chip_1_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (163, 190, 140)),
      others => <>);

   --  Base style for class 'chip-2'
   function Chip_2_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (235, 203, 139)),
      others => <>);

   --  Base style for class 'chip-3'
   function Chip_3_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (180, 142, 173)),
      others => <>);

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     From (Root_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Knob_Part_Hovered_Style)
     .Build;

   --  Complete widget style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     From (Root_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Scroll_Part_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     From (Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'section'
   Section_Class_Widget : constant Widget_Style :=
     From (Section_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'section'
   Section_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'caption'::label
   Caption_Class_Label_Widget : constant Widget_Style :=
     From (Caption_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'caption'
   Caption_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'note'::label
   Note_Class_Label_Widget : constant Widget_Style :=
     From (Note_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'note'
   Note_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Note_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'cases'
   Cases_Class_Widget : constant Widget_Style :=
     From (Cases_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'cases'
   Cases_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cases_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'case'
   Case_Class_Widget : constant Widget_Style :=
     From (Case_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'case'
   Case_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Case_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'case-label'::label
   Case_Label_Class_Label_Widget : constant Widget_Style :=
     From (Case_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'case-label'
   Case_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Case_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'demo'
   Demo_Class_Widget : constant Widget_Style :=
     From (Demo_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'demo'
   Demo_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Demo_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'bar'
   Bar_Class_Widget : constant Widget_Style :=
     From (Bar_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'bar'::label
   Bar_Class_Label_Widget : constant Widget_Style :=
     From (Bar_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'bar'
   Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bar_Class_Widget, Enabled => True),
      Label_Part => (Style => Bar_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'w120'
   W120_Class_Widget : constant Widget_Style :=
     From (W120_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'w120'
   W120_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W120_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'w45'
   W45_Class_Widget : constant Widget_Style :=
     From (W45_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'w45'
   W45_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W45_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'wcap'
   Wcap_Class_Widget : constant Widget_Style :=
     From (Wcap_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'wcap'
   Wcap_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wcap_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'w280'
   W280_Class_Widget : constant Widget_Style :=
     From (W280_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'w280'
   W280_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W280_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'indent'
   Indent_Class_Widget : constant Widget_Style :=
     From (Indent_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'indent'
   Indent_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Indent_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'inset'
   Inset_Class_Widget : constant Widget_Style :=
     From (Inset_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'inset'
   Inset_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Inset_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'pushed'
   Pushed_Class_Widget : constant Widget_Style :=
     From (Pushed_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'pushed'
   Pushed_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pushed_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'auto-width'
   Auto_Width_Class_Widget : constant Widget_Style :=
     From (Auto_Width_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'auto-width'
   Auto_Width_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Auto_Width_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'h20'
   H20_Class_Widget : constant Widget_Style :=
     From (H20_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'h20'
   H20_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H20_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'h34'
   H34_Class_Widget : constant Widget_Style :=
     From (H34_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'h34'
   H34_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H34_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'h48'
   H48_Class_Widget : constant Widget_Style :=
     From (H48_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'h48'
   H48_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H48_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'ghost'
   Ghost_Class_Widget : constant Widget_Style :=
     From (Ghost_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'ghost'
   Ghost_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ghost_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'frame'
   Frame_Class_Widget : constant Widget_Style :=
     From (Frame_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'frame'
   Frame_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Frame_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'fill'
   Fill_Class_Widget : constant Widget_Style :=
     From (Fill_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'fill'
   Fill_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Fill_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'half'
   Half_Class_Widget : constant Widget_Style :=
     From (Half_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'half'
   Half_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Half_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'quarter'
   Quarter_Class_Widget : constant Widget_Style :=
     From (Quarter_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'quarter'
   Quarter_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Quarter_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'flex-row'
   Flex_Row_Class_Widget : constant Widget_Style :=
     From (Flex_Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'flex-row'
   Flex_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Flex_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'chip'
   Chip_Class_Widget : constant Widget_Style :=
     From (Chip_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'chip'
   Chip_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Chip_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'chip-1'
   Chip_1_Class_Widget : constant Widget_Style :=
     From (Chip_1_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'chip-1'
   Chip_1_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Chip_1_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'chip-2'
   Chip_2_Class_Widget : constant Widget_Style :=
     From (Chip_2_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'chip-2'
   Chip_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Chip_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'chip-3'
   Chip_3_Class_Widget : constant Widget_Style :=
     From (Chip_3_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'chip-3'
   Chip_3_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Chip_3_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Demo_Block_Styles;