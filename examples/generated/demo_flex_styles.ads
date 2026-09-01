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

package Demo_Flex_Styles is

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
        .Flex_Wrap (Wrap)
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
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
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

   --  Style for class 'item'
   Item_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Width (Size (Px (26.0)))
        .Height (Size (Px (26.0)))
        .Background (RGB (94, 129, 172))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'item'::label
   Item_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (240, 243, 248))
        .Font_Size (Px (12.0))
        .Font_Weight (Weight_Bold)
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'item'
   Item_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tall'
   Tall_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (70.0)))
     .Build;

   --  Part styles bundle for class 'tall'
   Tall_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tall_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'short'
   Short_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (46.0)))
     .Build;

   --  Part styles bundle for class 'short'
   Short_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Short_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bar'
   Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Auto_Size)
     .Build;

   --  Part styles bundle for class 'bar'
   Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dir-row'
   Dir_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Direction (Row)
     .Build;

   --  Part styles bundle for class 'dir-row'
   Dir_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dir_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dir-row-rev'
   Dir_Row_Rev_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Direction (Row_Reverse)
     .Build;

   --  Part styles bundle for class 'dir-row-rev'
   Dir_Row_Rev_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dir_Row_Rev_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dir-col'
   Dir_Col_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Direction (Column)
     .Build;

   --  Part styles bundle for class 'dir-col'
   Dir_Col_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dir_Col_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'dir-col-rev'
   Dir_Col_Rev_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Direction (Column_Reverse)
     .Build;

   --  Part styles bundle for class 'dir-col-rev'
   Dir_Col_Rev_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Dir_Col_Rev_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grow-1'
   Grow_1_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'grow-1'
   Grow_1_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grow_1_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grow-2'
   Grow_2_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (2.0)
        .Background (RGB (235, 203, 139))
     .Build;

   --  Part styles bundle for class 'grow-2'
   Grow_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grow_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'grow-0'
   Grow_0_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (0.0)
        .Width (Size (Px (70.0)))
     .Build;

   --  Part styles bundle for class 'grow-0'
   Grow_0_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Grow_0_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w320'
   W320_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (320.0)))
     .Build;

   --  Part styles bundle for class 'w320'
   W320_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W320_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'shrink-yes'
   Shrink_Yes_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (160.0)))
        .Flex_Shrink (1.0)
        .Min_Width (Size (Px (0.0)))
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'shrink-yes'
   Shrink_Yes_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Shrink_Yes_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'shrink-no'
   Shrink_No_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (160.0)))
        .Flex_Shrink (0.0)
        .Background (RGB (191, 97, 106))
     .Build;

   --  Part styles bundle for class 'shrink-no'
   Shrink_No_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Shrink_No_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'basis-40'
   Basis_40_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (40.0)))
        .Flex_Grow (1.0)
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'basis-40'
   Basis_40_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Basis_40_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'basis-120'
   Basis_120_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (120.0)))
        .Flex_Grow (1.0)
        .Background (RGB (235, 203, 139))
     .Build;

   --  Part styles bundle for class 'basis-120'
   Basis_120_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Basis_120_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'basis-200'
   Basis_200_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (200.0)))
        .Flex_Grow (1.0)
        .Background (RGB (180, 142, 173))
     .Build;

   --  Part styles bundle for class 'basis-200'
   Basis_200_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Basis_200_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w300'
   W300_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (300.0)))
     .Build;

   --  Part styles bundle for class 'w300'
   W300_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W300_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'pct-width'
   Pct_Width_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Pct (50.0)))
        .Flex_Grow (0.0)
        .Flex_Shrink (0.0)
        .Background (RGB (235, 203, 139))
     .Build;

   --  Part styles bundle for class 'pct-width'
   Pct_Width_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pct_Width_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'pct-basis'
   Pct_Basis_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Pct (50.0)))
        .Flex_Grow (0.0)
        .Flex_Shrink (0.0)
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'pct-basis'
   Pct_Basis_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pct_Basis_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'just-start'
   Just_Start_Class_Widget : constant Widget_Style :=
     Style_Of
        .Justify_Content (Flex_Start)
     .Build;

   --  Part styles bundle for class 'just-start'
   Just_Start_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Just_Start_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'just-center'
   Just_Center_Class_Widget : constant Widget_Style :=
     Style_Of
        .Justify_Content (Center)
     .Build;

   --  Part styles bundle for class 'just-center'
   Just_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Just_Center_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'just-end'
   Just_End_Class_Widget : constant Widget_Style :=
     Style_Of
        .Justify_Content (Flex_End)
     .Build;

   --  Part styles bundle for class 'just-end'
   Just_End_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Just_End_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'just-around'
   Just_Around_Class_Widget : constant Widget_Style :=
     Style_Of
        .Justify_Content (Space_Around)
     .Build;

   --  Part styles bundle for class 'just-around'
   Just_Around_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Just_Around_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'just-between'
   Just_Between_Class_Widget : constant Widget_Style :=
     Style_Of
        .Justify_Content (Space_Between)
     .Build;

   --  Part styles bundle for class 'just-between'
   Just_Between_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Just_Between_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'just-evenly'
   Just_Evenly_Class_Widget : constant Widget_Style :=
     Style_Of
        .Justify_Content (Space_Evenly)
     .Build;

   --  Part styles bundle for class 'just-evenly'
   Just_Evenly_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Just_Evenly_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align-start'
   Align_Start_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Items (Flex_Start)
     .Build;

   --  Part styles bundle for class 'align-start'
   Align_Start_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Align_Start_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align-center'
   Align_Center_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Items (Center)
     .Build;

   --  Part styles bundle for class 'align-center'
   Align_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Align_Center_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align-end'
   Align_End_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Items (Flex_End)
     .Build;

   --  Part styles bundle for class 'align-end'
   Align_End_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Align_End_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align-stretch'
   Align_Stretch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Items (Stretch)
     .Build;

   --  Part styles bundle for class 'align-stretch'
   Align_Stretch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Align_Stretch_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'h20'
   H20_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (20.0)))
     .Build;

   --  Part styles bundle for class 'h20'
   H20_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H20_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'h40'
   H40_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (40.0)))
        .Background (RGB (94, 129, 172))
     .Build;

   --  Part styles bundle for class 'h40'
   H40_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H40_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'h-auto'
   H_Auto_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Auto_Size)
        .Background (RGB (180, 142, 173))
     .Build;

   --  Part styles bundle for class 'h-auto'
   H_Auto_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H_Auto_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w480'
   W480_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (480.0)))
     .Build;

   --  Part styles bundle for class 'w480'
   W480_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W480_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w170'
   W170_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (170.0)))
     .Build;

   --  Part styles bundle for class 'w170'
   W170_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W170_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'h120'
   H120_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (120.0)))
     .Build;

   --  Part styles bundle for class 'h120'
   H120_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H120_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'h150'
   H150_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (150.0)))
     .Build;

   --  Part styles bundle for class 'h150'
   H150_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H150_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'nowrap'
   Nowrap_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Wrap (No_Wrap)
     .Build;

   --  Part styles bundle for class 'nowrap'
   Nowrap_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Nowrap_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wrap'
   Wrap_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Wrap (Wrap)
     .Build;

   --  Part styles bundle for class 'wrap'
   Wrap_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wrap_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wrap-reverse'
   Wrap_Reverse_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Wrap (Wrap_Reverse)
     .Build;

   --  Part styles bundle for class 'wrap-reverse'
   Wrap_Reverse_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wrap_Reverse_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'self-center'
   Self_Center_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Self (Center)
     .Build;

   --  Part styles bundle for class 'self-center'
   Self_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Self_Center_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'self-end'
   Self_End_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Self (Flex_End)
     .Build;

   --  Part styles bundle for class 'self-end'
   Self_End_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Self_End_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'self-stretch'
   Self_Stretch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Self (Stretch)
        .Height (Auto_Size)
     .Build;

   --  Part styles bundle for class 'self-stretch'
   Self_Stretch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Self_Stretch_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'gap-row'
   Gap_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Gap (Gap (Px (24.0), Px (0.0)))
     .Build;

   --  Part styles bundle for class 'gap-row'
   Gap_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'gap-column'
   Gap_Column_Class_Widget : constant Widget_Style :=
     Style_Of
        .Gap (Gap (Px (0.0), Px (24.0)))
     .Build;

   --  Part styles bundle for class 'gap-column'
   Gap_Column_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Column_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'gap-both'
   Gap_Both_Class_Widget : constant Widget_Style :=
     Style_Of
        .Gap (Gap (Px (24.0), Px (6.0)))
     .Build;

   --  Part styles bundle for class 'gap-both'
   Gap_Both_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Gap_Both_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tile-deep'
   Tile_Deep_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (46.0)))
     .Build;

   --  Part styles bundle for class 'tile-deep'
   Tile_Deep_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tile_Deep_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w110'
   W110_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (110.0)))
     .Build;

   --  Part styles bundle for class 'w110'
   W110_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W110_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ac-start'
   Ac_Start_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Content (Flex_Start)
     .Build;

   --  Part styles bundle for class 'ac-start'
   Ac_Start_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ac_Start_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ac-center'
   Ac_Center_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Content (Center)
     .Build;

   --  Part styles bundle for class 'ac-center'
   Ac_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ac_Center_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ac-end'
   Ac_End_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Content (Flex_End)
     .Build;

   --  Part styles bundle for class 'ac-end'
   Ac_End_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ac_End_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ac-between'
   Ac_Between_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Content (Space_Between)
     .Build;

   --  Part styles bundle for class 'ac-between'
   Ac_Between_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ac_Between_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ac-around'
   Ac_Around_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Content (Space_Around)
     .Build;

   --  Part styles bundle for class 'ac-around'
   Ac_Around_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ac_Around_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ac-stretch'
   Ac_Stretch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Content (Stretch)
     .Build;

   --  Part styles bundle for class 'ac-stretch'
   Ac_Stretch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ac_Stretch_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tile'
   Tile_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (40.0)))
        .Height (Size (Px (34.0)))
        .Flex_Grow (0.0)
        .Flex_Shrink (0.0)
     .Build;

   --  Part styles bundle for class 'tile'
   Tile_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tile_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tile-short'
   Tile_Short_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (22.0)))
     .Build;

   --  Part styles bundle for class 'tile-short'
   Tile_Short_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tile_Short_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align-start-items'
   Align_Start_Items_Class_Widget : constant Widget_Style :=
     Style_Of
        .Align_Items (Flex_Start)
     .Build;

   --  Part styles bundle for class 'align-start-items'
   Align_Start_Items_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Align_Start_Items_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'pinned'
   Pinned_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (90.0)))
        .Min_Width (Size (Px (90.0)))
        .Flex_Shrink (1.0)
        .Background (RGB (191, 97, 106))
     .Build;

   --  Part styles bundle for class 'pinned'
   Pinned_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pinned_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'elastic'
   Elastic_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (220.0)))
        .Min_Width (Size (Px (0.0)))
        .Flex_Shrink (1.0)
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'elastic'
   Elastic_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Elastic_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'rigid'
   Rigid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (0.0)
        .Flex_Shrink (0.0)
        .Min_Width (Size (Px (90.0)))
        .Background (RGB (191, 97, 106))
     .Build;

   --  Part styles bundle for class 'rigid'
   Rigid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Rigid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'capped'
   Capped_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (220.0)))
        .Flex_Grow (0.0)
        .Flex_Shrink (0.0)
        .Max_Width (Size (Px (90.0)))
        .Background (RGB (191, 97, 106))
     .Build;

   --  Part styles bundle for class 'capped'
   Capped_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Capped_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'greedy'
   Greedy_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Width (Size (Px (0.0)))
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'greedy'
   Greedy_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Greedy_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'frac-half'
   Frac_Half_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (0.0)))
        .Flex_Grow (0.5)
        .Min_Width (Size (Px (0.0)))
        .Background (RGB (180, 142, 173))
     .Build;

   --  Part styles bundle for class 'frac-half'
   Frac_Half_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Frac_Half_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'frac-quarter'
   Frac_Quarter_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (0.0)))
        .Flex_Grow (0.25)
        .Min_Width (Size (Px (0.0)))
        .Background (RGB (180, 142, 173))
     .Build;

   --  Part styles bundle for class 'frac-quarter'
   Frac_Quarter_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Frac_Quarter_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'floored-wide'
   Floored_Wide_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (0.0)))
        .Flex_Grow (1.0)
        .Min_Width (Size (Px (260.0)))
        .Background (RGB (191, 97, 106))
     .Build;

   --  Part styles bundle for class 'floored-wide'
   Floored_Wide_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Floored_Wide_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'based'
   Based_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (160.0)))
        .Flex_Grow (1.0)
        .Min_Width (Size (Px (0.0)))
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'based'
   Based_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Based_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'triple'
   Triple_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (0.0)))
        .Flex_Grow (3.0)
        .Min_Width (Size (Px (0.0)))
        .Background (RGB (94, 129, 172))
     .Build;

   --  Part styles bundle for class 'triple'
   Triple_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Triple_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ceiling'
   Ceiling_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (0.0)))
        .Flex_Grow (1.0)
        .Min_Width (Size (Px (0.0)))
        .Max_Width (Size (Px (112.0)))
        .Background (RGB (180, 142, 173))
     .Build;

   --  Part styles bundle for class 'ceiling'
   Ceiling_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ceiling_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'plain-grow'
   Plain_Grow_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Basis (Basis (Px (0.0)))
        .Flex_Grow (1.0)
        .Min_Width (Size (Px (0.0)))
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'plain-grow'
   Plain_Grow_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Plain_Grow_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Demo_Flex_Styles;