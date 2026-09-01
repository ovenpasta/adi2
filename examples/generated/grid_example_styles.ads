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
   --  Style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (18.0)))
        .Background (RGB (24, 26, 33))
        .Padding (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0)))
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.1)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.28)))
     .Build;

   --  Style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (94, 129, 172, 0.06))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (94, 129, 172, 0.16))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (236, 239, 244))
        .Font_Size (Px (22.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section'
   Section_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (6.0)))
        .Flex_Shrink (0.0)
        .Padding (Right, Px (14.0))
     .Build;

   --  Part styles bundle for class 'section'
   Section_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'caption'::label
   Caption_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (163, 190, 140))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'caption'
   Caption_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'note'::label
   Note_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (150, 158, 172))
        .Font_Size (Px (12.0))
     .Build;

   --  Part styles bundle for class 'note'
   Note_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Note_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cases'
   Cases_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (12.0)))
        .Flex_Shrink (0.0)
     .Build;

   --  Part styles bundle for class 'cases'
   Cases_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cases_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'case'
   Case_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (4.0)))
        .Flex_Grow (1.0)
        .Flex_Basis (Basis (Px (0.0)))
        .Min_Width (Size (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'case'
   Case_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Case_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'case-label'::label
   Case_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (150, 158, 172))
        .Font_Size (Px (11.0))
     .Build;

   --  Part styles bundle for class 'case-label'
   Case_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Case_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'demo'
   Demo_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Gap (Gap (Px (6.0)))
        .Background (RGB (35, 38, 48))
        .Padding (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0)))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (94, 129, 172)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'demo'
   Demo_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Demo_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cell'
   Cell_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Min_Height (Size (Px (30.0)))
        .Background (RGB (69, 104, 150))
        .Padding (CSS_Box (Px (6.0), Px (8.0), Px (6.0), Px (8.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'cell'::label
   Cell_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (240, 243, 248))
        .Font_Size (Px (11.0))
        .Font_Weight (Weight_Bold)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'cell'
   Cell_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cell_Class_Widget, Enabled => True),
      Label_Part => (Style => Cell_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'alt'
   Alt_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (94, 128, 78))
     .Build;

   --  Part styles bundle for class 'alt'
   Alt_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Alt_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'warm'
   Warm_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (158, 121, 48))
     .Build;

   --  Part styles bundle for class 'warm'
   Warm_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Warm_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'rose'
   Rose_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (133, 94, 128))
     .Build;

   --  Part styles bundle for class 'rose'
   Rose_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Rose_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'red'
   Red_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (158, 66, 76))
     .Build;

   --  Part styles bundle for class 'red'
   Red_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Red_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cols-3fr'
   Cols_3fr_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'cols-3fr'
   Cols_3fr_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_3fr_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cols-px-fr'
   Cols_Px_Fr_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (2))
        .Grid_Columns ((Count => 2, Tracks => [1 => (Track_Px, 120.0), 2 => (Track_Fr, 1.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'cols-px-fr'
   Cols_Px_Fr_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Px_Fr_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cols-auto'
   Cols_Auto_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (2))
        .Grid_Columns ((Count => 2, Tracks => [1 => (Track_Auto, 0.0), 2 => (Track_Fr, 1.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'cols-auto'
   Cols_Auto_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Auto_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cols-weight'
   Cols_Weight_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 2.0), 3 => (Track_Fr, 1.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'cols-weight'
   Cols_Weight_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Weight_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'cols-mixed'
   Cols_Mixed_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (4))
        .Grid_Columns ((Count => 4, Tracks => [1 => (Track_Px, 120.0), 2 => (Track_Fr, 2.0), 3 => (Track_Fr, 0.5), 4 => (Track_Auto, 0.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'cols-mixed'
   Cols_Mixed_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Cols_Mixed_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'board'
   Board_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (4))
        .Grid_Columns ((Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]))
        .Grid_Rows (Grid_Rows_Value (3))
     .Build;

   --  Part styles bundle for class 'board'
   Board_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Board_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'span-2col'
   Span_2col_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (1))
        .Grid_Column_Span (Grid_Column_Span_Value (2))
        .Grid_Row (Grid_Row_Value (1))
     .Build;

   --  Part styles bundle for class 'span-2col'
   Span_2col_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Span_2col_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'span-2row'
   Span_2row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (3))
        .Grid_Row (Grid_Row_Value (1))
        .Grid_Row_Span (Grid_Row_Span_Value (2))
     .Build;

   --  Part styles bundle for class 'span-2row'
   Span_2row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Span_2row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'at-4-1'
   At_4_1_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (4))
        .Grid_Row (Grid_Row_Value (1))
     .Build;

   --  Part styles bundle for class 'at-4-1'
   At_4_1_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_4_1_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'at-1-2'
   At_1_2_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (1))
        .Grid_Row (Grid_Row_Value (2))
     .Build;

   --  Part styles bundle for class 'at-1-2'
   At_1_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_1_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'at-2-2'
   At_2_2_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (2))
        .Grid_Row (Grid_Row_Value (2))
     .Build;

   --  Part styles bundle for class 'at-2-2'
   At_2_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_2_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'at-4-2'
   At_4_2_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (4))
        .Grid_Row (Grid_Row_Value (2))
     .Build;

   --  Part styles bundle for class 'at-4-2'
   At_4_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_4_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'at-1-3'
   At_1_3_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (1))
        .Grid_Row (Grid_Row_Value (3))
     .Build;

   --  Part styles bundle for class 'at-1-3'
   At_1_3_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => At_1_3_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'span-3col'
   Span_3col_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Column (Grid_Column_Value (2))
        .Grid_Column_Span (Grid_Column_Span_Value (3))
        .Grid_Row (Grid_Row_Value (3))
     .Build;

   --  Part styles bundle for class 'span-3col'
   Span_3col_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Span_3col_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'gap-both'
   Gap_Both_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (14.0)))
     .Build;

   --  Part styles bundle for class 'gap-both'
   Gap_Both_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Both_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'gap-row'
   Gap_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (20.0), Px (2.0)))
     .Build;

   --  Part styles bundle for class 'gap-row'
   Gap_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'gap-col'
   Gap_Col_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (2.0), Px (20.0)))
     .Build;

   --  Part styles bundle for class 'gap-col'
   Gap_Col_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Col_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'floor-grid'
   Floor_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Width (Size (Px (300.0)))
     .Build;

   --  Part styles bundle for class 'floor-grid'
   Floor_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'floor-wide'
   Floor_Wide_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Width (Size (Px (150.0)))
     .Build;

   --  Part styles bundle for class 'floor-wide'
   Floor_Wide_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Wide_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'floor-medium'
   Floor_Medium_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Width (Size (Px (90.0)))
     .Build;

   --  Part styles bundle for class 'floor-medium'
   Floor_Medium_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Medium_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'floor-rest'
   Floor_Rest_Class_Widget : constant Widget_Style :=
     Style_Of
        .Padding (CSS_Box (Px (6.0), Px (2.0), Px (6.0), Px (2.0)))
     .Build;

   --  Part styles bundle for class 'floor-rest'
   Floor_Rest_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floor_Rest_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'clip-grid'
   Clip_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (2))
        .Grid_Columns ((Count => 2, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), others => <>]))
        .Width (Size (Px (265.0)))
     .Build;

   --  Part styles bundle for class 'clip-grid'
   Clip_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Clip_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wide'::label
   Wide_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'wide'
   Wide_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Wide_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'clipped'
   Clipped_Class_Widget : constant Widget_Style :=
     Style_Of
        .Overflow_X (Overflow_Hidden)
        .Overflow_Y (Overflow_Hidden)
     .Build;

   --  Part styles bundle for class 'clipped'
   Clipped_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Clipped_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'scroll-grid'
   Scroll_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Height (Size (Px (150.0)))
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'scroll-grid'::knob
   Scroll_Grid_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (129, 161, 193, 0.55))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'scroll-grid'::scroll
   Scroll_Grid_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (8.0)))
        .Background (RGBA (94, 129, 172, 0.1))
        .Radius (Radius (Px (4.0)))
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