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

package Grid_Example_Styles is

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
      Gap => Set (Gap (Px (12.0))),
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'case'
   function Case_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (4.0))),
      Flex_Grow => Set (1.0),
      Flex_Basis => Set (Basis (Px (0.0))),
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
      Display => Set (Grid),
      Gap => Set (Gap (Px (6.0))),
      Background_Color => Set_Bg (RGB (35, 38, 48)),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (94, 129, 172))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'cell'
   function Cell_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Min_Height => Set (Size (Px (30.0))),
      Background_Color => Set_Bg (RGB (69, 104, 150)),
      Padding => Set (CSS_Box (Px (6.0), Px (8.0), Px (6.0), Px (8.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'cell'::label
   function Cell_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (240, 243, 248)),
      Font_Size => Set_Font (Px (11.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'alt'
   function Alt_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (94, 128, 78)),
      others => <>);

   --  Base style for class 'warm'
   function Warm_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (158, 121, 48)),
      others => <>);

   --  Base style for class 'rose'
   function Rose_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (133, 94, 128)),
      others => <>);

   --  Base style for class 'red'
   function Red_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (158, 66, 76)),
      others => <>);

   --  Base style for class 'cols-3fr'
   function Cols_3fr_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      others => <>);

   --  Base style for class 'cols-px-fr'
   function Cols_Px_Fr_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (2)),
      Grid_Column_Tracks => (Count => 2, Tracks => [1 => (Track_Px, 120.0), 2 => (Track_Fr, 1.0), others => <>]),
      others => <>);

   --  Base style for class 'cols-auto'
   function Cols_Auto_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (2)),
      Grid_Column_Tracks => (Count => 2, Tracks => [1 => (Track_Auto, 0.0), 2 => (Track_Fr, 1.0), others => <>]),
      others => <>);

   --  Base style for class 'cols-weight'
   function Cols_Weight_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 2.0), 3 => (Track_Fr, 1.0), others => <>]),
      others => <>);

   --  Base style for class 'cols-mixed'
   function Cols_Mixed_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Px, 120.0), 2 => (Track_Fr, 2.0), 3 => (Track_Fr, 0.5), 4 => (Track_Auto, 0.0), others => <>]),
      others => <>);

   --  Base style for class 'board'
   function Board_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]),
      Grid_Rows => Set (Grid_Rows_Value (3)),
      others => <>);

   --  Base style for class 'span-2col'
   function Span_2col_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (2)),
      Grid_Row => Set (Grid_Row_Value (1)),
      others => <>);

   --  Base style for class 'span-2row'
   function Span_2row_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (3)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Grid_Row_Span => Set (Grid_Row_Span_Value (2)),
      others => <>);

   --  Base style for class 'at-4-1'
   function At_4_1_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (1)),
      others => <>);

   --  Base style for class 'at-1-2'
   function At_1_2_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Row => Set (Grid_Row_Value (2)),
      others => <>);

   --  Base style for class 'at-2-2'
   function At_2_2_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Row => Set (Grid_Row_Value (2)),
      others => <>);

   --  Base style for class 'at-4-2'
   function At_4_2_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (2)),
      others => <>);

   --  Base style for class 'at-1-3'
   function At_1_3_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Row => Set (Grid_Row_Value (3)),
      others => <>);

   --  Base style for class 'span-3col'
   function Span_3col_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (3)),
      Grid_Row => Set (Grid_Row_Value (3)),
      others => <>);

   --  Base style for class 'gap-both'
   function Gap_Both_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (14.0))),
      others => <>);

   --  Base style for class 'gap-row'
   function Gap_Row_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (20.0), Px (2.0))),
      others => <>);

   --  Base style for class 'gap-col'
   function Gap_Col_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (2.0), Px (20.0))),
      others => <>);

   --  Base style for class 'floor-grid'
   function Floor_Grid_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Width => Set (Size (Px (300.0))),
      others => <>);

   --  Base style for class 'floor-wide'
   function Floor_Wide_Class_Base_Style return Style_Rules is
     (
      Min_Width => Set (Size (Px (150.0))),
      others => <>);

   --  Base style for class 'floor-medium'
   function Floor_Medium_Class_Base_Style return Style_Rules is
     (
      Min_Width => Set (Size (Px (90.0))),
      others => <>);

   --  Base style for class 'floor-rest'
   function Floor_Rest_Class_Base_Style return Style_Rules is
     (
      Padding => Set (CSS_Box (Px (6.0), Px (2.0), Px (6.0), Px (2.0))),
      others => <>);

   --  Base style for class 'clip-grid'
   function Clip_Grid_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (2)),
      Grid_Column_Tracks => (Count => 2, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), others => <>]),
      Width => Set (Size (Px (265.0))),
      others => <>);

   --  Base style for class 'wide'::label
   function Wide_Class_Label_Base_Style return Style_Rules is
     (
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'clipped'
   function Clipped_Class_Base_Style return Style_Rules is
     (
      Overflow_X => Set_Overflow_X (Overflow_Hidden),
      Overflow_Y => Set_Overflow_Y (Overflow_Hidden),
      others => <>);

   --  Base style for class 'scroll-grid'
   function Scroll_Grid_Class_Base_Style return Style_Rules is
     (
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Height => Set (Size (Px (150.0))),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'scroll-grid'::knob
   function Scroll_Grid_Class_Knob_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (129, 161, 193, 0.55)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'scroll-grid'::scroll
   function Scroll_Grid_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (8.0))),
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.1)),
      Border_Radius => Set (Radius (Px (4.0))),
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

   --  Complete widget style for class 'cell'
   Cell_Class_Widget : constant Widget_Style :=
     From (Cell_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'cell'::label
   Cell_Class_Label_Widget : constant Widget_Style :=
     From (Cell_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'cell'
   Cell_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cell_Class_Widget, Enabled => True),
      Label_Part => (Style => Cell_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'alt'
   Alt_Class_Widget : constant Widget_Style :=
     From (Alt_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'alt'
   Alt_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Alt_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'warm'
   Warm_Class_Widget : constant Widget_Style :=
     From (Warm_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'warm'
   Warm_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Warm_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'rose'
   Rose_Class_Widget : constant Widget_Style :=
     From (Rose_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'rose'
   Rose_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Rose_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'red'
   Red_Class_Widget : constant Widget_Style :=
     From (Red_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'red'
   Red_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Red_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'cols-3fr'
   Cols_3fr_Class_Widget : constant Widget_Style :=
     From (Cols_3fr_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'cols-3fr'
   Cols_3fr_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_3fr_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'cols-px-fr'
   Cols_Px_Fr_Class_Widget : constant Widget_Style :=
     From (Cols_Px_Fr_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'cols-px-fr'
   Cols_Px_Fr_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Px_Fr_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'cols-auto'
   Cols_Auto_Class_Widget : constant Widget_Style :=
     From (Cols_Auto_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'cols-auto'
   Cols_Auto_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Auto_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'cols-weight'
   Cols_Weight_Class_Widget : constant Widget_Style :=
     From (Cols_Weight_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'cols-weight'
   Cols_Weight_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Weight_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'cols-mixed'
   Cols_Mixed_Class_Widget : constant Widget_Style :=
     From (Cols_Mixed_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'cols-mixed'
   Cols_Mixed_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Mixed_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'board'
   Board_Class_Widget : constant Widget_Style :=
     From (Board_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'board'
   Board_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Board_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'span-2col'
   Span_2col_Class_Widget : constant Widget_Style :=
     From (Span_2col_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'span-2col'
   Span_2col_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Span_2col_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'span-2row'
   Span_2row_Class_Widget : constant Widget_Style :=
     From (Span_2row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'span-2row'
   Span_2row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Span_2row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'at-4-1'
   At_4_1_Class_Widget : constant Widget_Style :=
     From (At_4_1_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'at-4-1'
   At_4_1_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_4_1_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'at-1-2'
   At_1_2_Class_Widget : constant Widget_Style :=
     From (At_1_2_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'at-1-2'
   At_1_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_1_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'at-2-2'
   At_2_2_Class_Widget : constant Widget_Style :=
     From (At_2_2_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'at-2-2'
   At_2_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_2_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'at-4-2'
   At_4_2_Class_Widget : constant Widget_Style :=
     From (At_4_2_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'at-4-2'
   At_4_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_4_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'at-1-3'
   At_1_3_Class_Widget : constant Widget_Style :=
     From (At_1_3_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'at-1-3'
   At_1_3_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_1_3_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'span-3col'
   Span_3col_Class_Widget : constant Widget_Style :=
     From (Span_3col_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'span-3col'
   Span_3col_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Span_3col_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'gap-both'
   Gap_Both_Class_Widget : constant Widget_Style :=
     From (Gap_Both_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'gap-both'
   Gap_Both_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Both_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'gap-row'
   Gap_Row_Class_Widget : constant Widget_Style :=
     From (Gap_Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'gap-row'
   Gap_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'gap-col'
   Gap_Col_Class_Widget : constant Widget_Style :=
     From (Gap_Col_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'gap-col'
   Gap_Col_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Col_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'floor-grid'
   Floor_Grid_Class_Widget : constant Widget_Style :=
     From (Floor_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'floor-grid'
   Floor_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'floor-wide'
   Floor_Wide_Class_Widget : constant Widget_Style :=
     From (Floor_Wide_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'floor-wide'
   Floor_Wide_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Wide_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'floor-medium'
   Floor_Medium_Class_Widget : constant Widget_Style :=
     From (Floor_Medium_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'floor-medium'
   Floor_Medium_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Medium_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'floor-rest'
   Floor_Rest_Class_Widget : constant Widget_Style :=
     From (Floor_Rest_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'floor-rest'
   Floor_Rest_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Rest_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'clip-grid'
   Clip_Grid_Class_Widget : constant Widget_Style :=
     From (Clip_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'clip-grid'
   Clip_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Clip_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'wide'::label
   Wide_Class_Label_Widget : constant Widget_Style :=
     From (Wide_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'wide'
   Wide_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Wide_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'clipped'
   Clipped_Class_Widget : constant Widget_Style :=
     From (Clipped_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'clipped'
   Clipped_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Clipped_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'scroll-grid'
   Scroll_Grid_Class_Widget : constant Widget_Style :=
     From (Scroll_Grid_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'scroll-grid'::knob
   Scroll_Grid_Class_Knob_Widget : constant Widget_Style :=
     From (Scroll_Grid_Class_Knob_Base_Style)
     .Build;

   --  Complete widget style for class 'scroll-grid'::scroll
   Scroll_Grid_Class_Scroll_Widget : constant Widget_Style :=
     From (Scroll_Grid_Class_Scroll_Base_Style)
     .Build;

   --  Part styles bundle for class 'scroll-grid'
   Scroll_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Scroll_Grid_Class_Widget, Enabled => True),
      Knob_Part => (Style => Scroll_Grid_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Scroll_Grid_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Grid_Example_Styles;