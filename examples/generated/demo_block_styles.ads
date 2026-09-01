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
        .Flex_Basis (Basis (Px (0.0)))
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
        .Background (RGB (35, 38, 48))
        .Padding (CSS_Box (Px (6.0), Px (6.0), Px (0.0), Px (6.0)))
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

   --  Style for class 'bar'
   Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (22.0)))
        .Background (RGB (94, 129, 172))
        .Padding (Left, Px (8.0))
        .Margin (Bottom, Margin (Px (6.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'bar'::label
   Bar_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (240, 243, 248))
        .Font_Size (Px (12.0))
        .Font_Weight (Weight_Bold)
        .Vertical_Align (VA_Middle)
     .Build;

   --  Part styles bundle for class 'bar'
   Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bar_Class_Widget, Enabled => True),
      Label_Part => (Style => Bar_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w120'
   W120_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (120.0)))
     .Build;

   --  Part styles bundle for class 'w120'
   W120_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W120_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w45'
   W45_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Pct (45.0)))
     .Build;

   --  Part styles bundle for class 'w45'
   W45_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W45_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wcap'
   Wcap_Class_Widget : constant Widget_Style :=
     Style_Of
        .Max_Width (Size (Px (160.0)))
     .Build;

   --  Part styles bundle for class 'wcap'
   Wcap_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wcap_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'w280'
   W280_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (280.0)))
     .Build;

   --  Part styles bundle for class 'w280'
   W280_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => W280_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'indent'
   Indent_Class_Widget : constant Widget_Style :=
     Style_Of
        .Margin (Left, Margin (Px (48.0)))
     .Build;

   --  Part styles bundle for class 'indent'
   Indent_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Indent_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'inset'
   Inset_Class_Widget : constant Widget_Style :=
     Style_Of
        .Padding (Left, Px (48.0))
     .Build;

   --  Part styles bundle for class 'inset'
   Inset_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Inset_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'centred'
   Centred_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (220.0)))
        .Margin (Right, Auto_Margin)
        .Margin (Left, Auto_Margin)
     .Build;

   --  Part styles bundle for class 'centred'
   Centred_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Centred_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'pushed'
   Pushed_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (220.0)))
        .Margin (Left, Auto_Margin)
     .Build;

   --  Part styles bundle for class 'pushed'
   Pushed_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pushed_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'auto-width'
   Auto_Width_Class_Widget : constant Widget_Style :=
     Style_Of
        .Margin (Right, Auto_Margin)
        .Margin (Left, Auto_Margin)
     .Build;

   --  Part styles bundle for class 'auto-width'
   Auto_Width_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Auto_Width_Class_Widget, Enabled => True),
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

   --  Style for class 'h34'
   H34_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (34.0)))
     .Build;

   --  Part styles bundle for class 'h34'
   H34_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H34_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'h48'
   H48_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (48.0)))
     .Build;

   --  Part styles bundle for class 'h48'
   H48_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => H48_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ghost'
   Ghost_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Auto_Size)
        .Background (RGB (191, 97, 106))
        .Margin (Bottom, Margin (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'ghost'
   Ghost_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ghost_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'frame'
   Frame_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Px (120.0)))
        .Padding (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0)))
     .Build;

   --  Part styles bundle for class 'frame'
   Frame_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Frame_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'fill'
   Fill_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Pct (100.0)))
        .Background (RGB (163, 190, 140))
        .Margin (Bottom, Margin (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'fill'
   Fill_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Fill_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'half'
   Half_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Pct (50.0)))
        .Background (RGB (235, 203, 139))
        .Margin (Bottom, Margin (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'half'
   Half_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Half_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'quarter'
   Quarter_Class_Widget : constant Widget_Style :=
     Style_Of
        .Height (Size (Pct (25.0)))
        .Background (RGB (180, 142, 173))
        .Margin (Bottom, Margin (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'quarter'
   Quarter_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Quarter_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'flex-row'
   Flex_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'flex-row'
   Flex_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Flex_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'chip'
   Chip_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (60.0)))
        .Height (Size (Px (22.0)))
        .Margin (Bottom, Margin (Px (6.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Part styles bundle for class 'chip'
   Chip_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Chip_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'chip-1'
   Chip_1_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (163, 190, 140))
     .Build;

   --  Part styles bundle for class 'chip-1'
   Chip_1_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Chip_1_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'chip-2'
   Chip_2_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (235, 203, 139))
     .Build;

   --  Part styles bundle for class 'chip-2'
   Chip_2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Chip_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'chip-3'
   Chip_3_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (180, 142, 173))
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