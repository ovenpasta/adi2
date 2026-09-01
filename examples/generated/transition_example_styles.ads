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

package Transition_Example_Styles is

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
        .Background (RGB (24, 24, 30))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'content'
   Content_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Gap (Gap (Px (28.0)))
        .Padding (CSS_Box (Px (28.0), Px (32.0), Px (28.0), Px (32.0)))
     .Build;

   --  Part styles bundle for class 'content'
   Content_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Content_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section'
   Section_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'section'
   Section_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section-row'
   Section_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (16.0)))
        .Align_Items (Flex_Start)
     .Build;

   --  Part styles bundle for class 'section-row'
   Section_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'col-style'
   Col_Style_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Center)
     .Build;

   --  Part styles bundle for class 'col-style'
   Col_Style_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Col_Style_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
        .Padding (CSS_Box (Px (0.0), Px (4.0), Px (0.0), Px (4.0)))
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (160, 170, 190))
        .Font_Size (Px (12.0))
        .Font_Weight (Weight_Semi_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'desc'
   Desc_Class_Widget : constant Widget_Style :=
     Style_Of
        .Padding (CSS_Box (Px (2.0), Px (4.0), Px (2.0), Px (4.0)))
     .Build;

   --  Style for class 'desc'::label
   Desc_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (120, 130, 150))
        .Font_Size (Px (10.0))
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'desc'
   Desc_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Desc_Class_Widget, Enabled => True),
      Label_Part => (Style => Desc_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'demo-base'
   Demo_Base_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (55, 65, 81))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0)))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Style for class 'demo-base'::label
   Demo_Base_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'demo-base'
   Demo_Base_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Demo_Base_Class_Widget, Enabled => True),
      Label_Part => (Style => Demo_Base_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-linear'
   T_Linear_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Linear, Properties => Props (Prop_Background_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (59, 130, 246))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (37, 99, 235))
     .Build;

   --  Part styles bundle for class 't-linear'
   T_Linear_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Linear_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-ease-in'
   T_Ease_In_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Ease_In, Properties => Props (Prop_Background_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (168, 85, 247))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (126, 34, 206))
     .Build;

   --  Part styles bundle for class 't-ease-in'
   T_Ease_In_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Ease_In_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-ease-out'
   T_Ease_Out_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (34, 197, 94))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (22, 163, 74))
     .Build;

   --  Part styles bundle for class 't-ease-out'
   T_Ease_Out_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Ease_Out_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-ease-io'
   T_Ease_Io_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (245, 158, 11))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (217, 119, 6))
     .Build;

   --  Part styles bundle for class 't-ease-io'
   T_Ease_Io_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Ease_Io_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-bg'
   T_Bg_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.25, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (59, 130, 246))
     .Build;

   --  Part styles bundle for class 't-bg'
   T_Bg_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Bg_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-border'
   T_Border_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Border_Color)))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Border_Color (Border_Color (RGB (251, 191, 36)))
     .Build;

   --  Part styles bundle for class 't-border'
   T_Border_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Border_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-radius'
   T_Radius_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Border_Radius)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Radius (Radius (Px (20.0)))
     .Build;

   --  Part styles bundle for class 't-radius'
   T_Radius_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Radius_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-shadow'
   T_Shadow_Class_Widget : constant Widget_Style :=
     Style_Of
        .Box_Shadow (No_Shadow)
        .Transition ((Duration => 0.3, Easing => Ease_Out, Properties => Props (Prop_Box_Shadow)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (4.0), RGBA (100, 255, 100, 1.0)))
     .Build;

   --  Part styles bundle for class 't-shadow'
   T_Shadow_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Shadow_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-opacity'
   T_Opacity_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (239, 68, 68))
        .Opacity (1.0)
        .Transition ((Duration => 0.25, Easing => Ease_In_Out, Properties => Props (Prop_Opacity)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Opacity (0.5)
     .Build;

   --  Part styles bundle for class 't-opacity'
   T_Opacity_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Opacity_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-multi'
   T_Multi_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color) + Props (Prop_Box_Shadow)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (79, 70, 229))
        .Box_Shadow (Shadow (Px (0.0), Px (4.0), Px (12.0), Px (4.0), RGBA (165, 180, 252, 0.9)))
        .Border_Color (Border_Color (RGB (199, 210, 254)))
     .Build;

   --  Part styles bundle for class 't-multi'
   T_Multi_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Multi_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-everything'
   T_Everything_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.3, Easing => Ease_In_Out, Properties => All_Properties))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (6, 182, 212))
        .Box_Shadow (Shadow (Px (0.0), Px (4.0), Px (14.0), Px (4.0), RGBA (103, 232, 249, 0.9)))
        .Padding (CSS_Box (Px (10.0), Px (28.0), Px (10.0), Px (28.0)))
        .Border_Color (Border_Color (RGB (207, 250, 254)))
        .Radius (Radius (Px (16.0)))
     .Build;

   --  Part styles bundle for class 't-everything'
   T_Everything_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Everything_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-fast'
   T_Fast_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.05, Easing => Linear, Properties => Props (Prop_Background_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (16, 185, 129))
     .Build;

   --  Part styles bundle for class 't-fast'
   T_Fast_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Fast_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 't-slow'
   T_Slow_Class_Widget : constant Widget_Style :=
     Style_Of
        .Transition ((Duration => 0.8, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (236, 72, 153))
     .Build;

   --  Part styles bundle for class 't-slow'
   T_Slow_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => T_Slow_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Transition_Example_Styles;