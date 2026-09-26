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

   function Has_Root_Styles return Boolean is (True);
   Root_Style : constant Widget_Style :=
     Style_Of
        .Font_Size (Dip (18.0))
     .Build;

   Root_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Style, Enabled => True),
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

   --  Style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Stretch)
        .Gap (Gap (Px (12.0)))
        .Background (RGB (17, 24, 39))
        .Padding (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0)))
        .Overflow_X (Overflow_Auto)
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Min_Height (Size (Px (24.0)))
        .Background (RGBA (226, 232, 240, 0.8))
        .Transition ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Px (6.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (241, 245, 249, 0.94))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGBA (248, 250, 252, 1.0))
     .Build;

   --  Style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (148, 163, 184, 0.24))
        .Transition ((Duration => 0.22, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Margin (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (8.0)))
        .Radius (Radius (Px (6.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (148, 163, 184, 0.42))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGBA (148, 163, 184, 0.62))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Stretch)
        .Gap (Gap (Px (10.0)))
        .Background (RGB (31, 41, 55))
        .Padding (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Root_Em (1.33))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'hint'
   Hint_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'hint'::label
   Hint_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (191, 219, 254))
        .Font_Size (Root_Em (0.72))
     .Build;

   --  Part styles bundle for class 'hint'
   Hint_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section_title'
   Section_Title_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'section_title'::label
   Section_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (147, 197, 253))
        .Font_Size (Root_Em (0.78))
        .Font_Weight (Weight_Semi_Bold)
     .Build;

   --  Part styles bundle for class 'section_title'
   Section_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Section_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'sample'
   Sample_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (15, 23, 42))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (71, 85, 105)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'sample'::label
   Sample_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (226, 232, 240))
        .Font_Size (Root_Em (1.0))
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'sample'
   Sample_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sample_Class_Widget, Enabled => True),
      Label_Part => (Style => Sample_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'weight_normal'::label
   Weight_Normal_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Weight (Weight_Normal)
     .Build;

   --  Part styles bundle for class 'weight_normal'
   Weight_Normal_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Normal_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'weight_light'::label
   Weight_Light_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Weight (Weight_Light)
     .Build;

   --  Part styles bundle for class 'weight_light'
   Weight_Light_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Light_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'weight_medium'::label
   Weight_Medium_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Weight (Weight_Medium)
     .Build;

   --  Part styles bundle for class 'weight_medium'
   Weight_Medium_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Medium_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'weight_semibold'::label
   Weight_Semibold_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Weight (Weight_Semi_Bold)
     .Build;

   --  Part styles bundle for class 'weight_semibold'
   Weight_Semibold_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Semibold_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'weight_bold'::label
   Weight_Bold_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'weight_bold'
   Weight_Bold_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Bold_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'weight_black'::label
   Weight_Black_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Weight (Weight_Black)
     .Build;

   --  Part styles bundle for class 'weight_black'
   Weight_Black_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Weight_Black_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'style_italic'::label
   Style_Italic_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Style (Style_Italic)
     .Build;

   --  Part styles bundle for class 'style_italic'
   Style_Italic_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Style_Italic_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'style_oblique'::label
   Style_Oblique_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Style (Style_Oblique)
     .Build;

   --  Part styles bundle for class 'style_oblique'
   Style_Oblique_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Style_Oblique_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'size_small'::label
   Size_Small_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Size (Root_Em (0.72))
     .Build;

   --  Part styles bundle for class 'size_small'
   Size_Small_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Size_Small_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'size_base'::label
   Size_Base_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Size (Root_Em (1.0))
     .Build;

   --  Part styles bundle for class 'size_base'
   Size_Base_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Size_Base_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'size_large'::label
   Size_Large_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Font_Size (Root_Em (1.56))
     .Build;

   --  Part styles bundle for class 'size_large'
   Size_Large_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Size_Large_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'decor_underline'::label
   Decor_Underline_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Decoration (Decoration_Underline)
     .Build;

   --  Part styles bundle for class 'decor_underline'
   Decor_Underline_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Decor_Underline_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'decor_strike'::label
   Decor_Strike_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Decoration (Decoration_Line_Through)
     .Build;

   --  Part styles bundle for class 'decor_strike'
   Decor_Strike_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Decor_Strike_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'decor_overline'::label
   Decor_Overline_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Decoration (Decoration_Overline)
     .Build;

   --  Part styles bundle for class 'decor_overline'
   Decor_Overline_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Decor_Overline_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wrap_sample'
   Wrap_Sample_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (30, 41, 59))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (100, 116, 139)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'wrap_sample'::label
   Wrap_Sample_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (219, 234, 254))
        .Font_Size (Root_Em (0.78))
        .Text_Wrap_Mode (TWM_Wrap)
     .Build;

   --  Part styles bundle for class 'wrap_sample'
   Wrap_Sample_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wrap_Sample_Class_Widget, Enabled => True),
      Label_Part => (Style => Wrap_Sample_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'lh_normal'::label
   Lh_Normal_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Line_Height (Normal_Line_Height)
     .Build;

   --  Part styles bundle for class 'lh_normal'
   Lh_Normal_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Normal_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'lh_number'::label
   Lh_Number_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Line_Height (Line_Height (1.8))
     .Build;

   --  Part styles bundle for class 'lh_number'
   Lh_Number_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Number_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'lh_percent'::label
   Lh_Percent_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Line_Height (Line_Height (Pct (150.0)))
     .Build;

   --  Part styles bundle for class 'lh_percent'
   Lh_Percent_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Percent_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'lh_length'::label
   Lh_Length_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Line_Height (Line_Height (Px (30.0)))
     .Build;

   --  Part styles bundle for class 'lh_length'
   Lh_Length_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Lh_Length_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align_left'::label
   Align_Left_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Align (Text_Left)
     .Build;

   --  Part styles bundle for class 'align_left'
   Align_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Align_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align_center'::label
   Align_Center_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Align (Text_Center)
     .Build;

   --  Part styles bundle for class 'align_center'
   Align_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Align_Center_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'align_right'::label
   Align_Right_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Align (Text_Right)
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