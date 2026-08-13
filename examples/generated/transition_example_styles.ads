--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Transition_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   function Root_Part_Styles return Part_Style_Array is (Empty_Part_Styles);

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
      Background_Color => Set_Bg (RGB (24, 24, 30)),
      others => <>);

   --  Base style for class 'content'
   function Content_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (28.0))),
      Padding => Set (CSS_Box (Px (28.0), Px (32.0), Px (28.0), Px (32.0))),
      others => <>);

   --  Base style for class 'section'
   function Section_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (10.0))),
      others => <>);

   --  Base style for class 'section-row'
   function Section_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (16.0))),
      Align_Items => Set (Flex_Start),
      others => <>);

   --  Base style for class 'col-style'
   function Col_Style_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Center),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Padding => Set (CSS_Box (Px (0.0), Px (4.0), Px (0.0), Px (4.0))),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (160, 170, 190)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'desc'
   function Desc_Class_Base_Style return Style_Rules is
     (
      Padding => Set (CSS_Box (Px (2.0), Px (4.0), Px (2.0), Px (4.0))),
      others => <>);

   --  Base style for class 'desc'::label
   function Desc_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (120, 130, 150)),
      Font_Size => Set_Font (Px (10.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'demo-base'
   function Demo_Base_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'demo-base'::label
   function Demo_Base_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 't-linear'
   function T_Linear_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Linear, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Style for class 't-linear' when widget State_Hovered
   function T_Linear_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      others => <>);

   --  Style for class 't-linear' when widget State_Pressed
   function T_Linear_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>);

   --  Base style for class 't-ease-in'
   function T_Ease_In_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Ease_In, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Style for class 't-ease-in' when widget State_Hovered
   function T_Ease_In_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (168, 85, 247)),
      others => <>);

   --  Style for class 't-ease-in' when widget State_Pressed
   function T_Ease_In_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (126, 34, 206)),
      others => <>);

   --  Base style for class 't-ease-out'
   function T_Ease_Out_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Style for class 't-ease-out' when widget State_Hovered
   function T_Ease_Out_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (34, 197, 94)),
      others => <>);

   --  Style for class 't-ease-out' when widget State_Pressed
   function T_Ease_Out_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (22, 163, 74)),
      others => <>);

   --  Base style for class 't-ease-io'
   function T_Ease_Io_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Style for class 't-ease-io' when widget State_Hovered
   function T_Ease_Io_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (245, 158, 11)),
      others => <>);

   --  Style for class 't-ease-io' when widget State_Pressed
   function T_Ease_Io_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (217, 119, 6)),
      others => <>);

   --  Base style for class 't-bg'
   function T_Bg_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.25, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Style for class 't-bg' when widget State_Hovered
   function T_Bg_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      others => <>);

   --  Base style for class 't-border'
   function T_Border_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Border_Color))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      others => <>);

   --  Style for class 't-border' when widget State_Hovered
   function T_Border_Class_Widget_Hovered_Style return Style_Rules is
     (
      Border_Color => Set (Border_Color (RGB (251, 191, 36))),
      others => <>);

   --  Base style for class 't-radius'
   function T_Radius_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Border_Radius))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 't-radius' when widget State_Hovered
   function T_Radius_Class_Widget_Hovered_Style return Style_Rules is
     (
      Border_Radius => Set (Radius (Px (20.0))),
      others => <>);

   --  Base style for class 't-shadow'
   function T_Shadow_Class_Base_Style return Style_Rules is
     (
      Box_Shadow => Set (No_Shadow),
      Transition => Set ((Duration => 0.3, Easing => Ease_Out, Properties => Props (Prop_Box_Shadow))),
      others => <>);

   --  Style for class 't-shadow' when widget State_Hovered
   function T_Shadow_Class_Widget_Hovered_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (4.0), RGBA (100, 255, 100, 1.0))),
      others => <>);

   --  Base style for class 't-opacity'
   function T_Opacity_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      Opacity => Set (1.0),
      Transition => Set ((Duration => 0.25, Easing => Ease_In_Out, Properties => Props (Prop_Opacity))),
      others => <>);

   --  Style for class 't-opacity' when widget State_Hovered
   function T_Opacity_Class_Widget_Hovered_Style return Style_Rules is
     (
      Opacity => Set (0.5),
      others => <>);

   --  Base style for class 't-multi'
   function T_Multi_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color) + Props (Prop_Box_Shadow))),
      others => <>);

   --  Style for class 't-multi' when widget State_Hovered
   function T_Multi_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (79, 70, 229)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (4.0), Px (12.0), Px (4.0), RGBA (165, 180, 252, 0.9))),
      Border_Color => Set (Border_Color (RGB (199, 210, 254))),
      others => <>);

   --  Base style for class 't-everything'
   function T_Everything_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.3, Easing => Ease_In_Out, Properties => All_Properties)),
      others => <>);

   --  Style for class 't-everything' when widget State_Hovered
   function T_Everything_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (6, 182, 212)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (4.0), Px (14.0), Px (4.0), RGBA (103, 232, 249, 0.9))),
      Padding => Set (CSS_Box (Px (10.0), Px (28.0), Px (10.0), Px (28.0))),
      Border_Color => Set (Border_Color (RGB (207, 250, 254))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Base style for class 't-fast'
   function T_Fast_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.05, Easing => Linear, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Style for class 't-fast' when widget State_Hovered
   function T_Fast_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (16, 185, 129)),
      others => <>);

   --  Base style for class 't-slow'
   function T_Slow_Class_Base_Style return Style_Rules is
     (
      Transition => Set ((Duration => 0.8, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      others => <>);

   --  Style for class 't-slow' when widget State_Hovered
   function T_Slow_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (236, 72, 153)),
      others => <>);

   --  Complete widget style for class 'root'
   function Root_Class_Widget return Widget_Style is
     (From (Root_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'root'
   function Root_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'content'
   function Content_Class_Widget return Widget_Style is
     (From (Content_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'content'
   function Content_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Content_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'section'
   function Section_Class_Widget return Widget_Style is
     (From (Section_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'section'
   function Section_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'section-row'
   function Section_Row_Class_Widget return Widget_Style is
     (From (Section_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'section-row'
   function Section_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Section_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'col-style'
   function Col_Style_Class_Widget return Widget_Style is
     (From (Col_Style_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'col-style'
   function Col_Style_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Col_Style_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'
   function Title_Class_Widget return Widget_Style is
     (From (Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'desc'
   function Desc_Class_Widget return Widget_Style is
     (From (Desc_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'desc'::label
   function Desc_Class_Label_Widget return Widget_Style is
     (From (Desc_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'desc'
   function Desc_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Desc_Class_Widget, Enabled => True),
      Label_Part => (Style => Desc_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'demo-base'
   function Demo_Base_Class_Widget return Widget_Style is
     (From (Demo_Base_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'demo-base'::label
   function Demo_Base_Class_Label_Widget return Widget_Style is
     (From (Demo_Base_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'demo-base'
   function Demo_Base_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Demo_Base_Class_Widget, Enabled => True),
      Label_Part => (Style => Demo_Base_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-linear'
   function T_Linear_Class_Widget return Widget_Style is
     (From (T_Linear_Class_Base_Style)
     .On (When_State (State_Hovered), T_Linear_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), T_Linear_Class_Widget_Pressed_Style)
     .Build);

   --  Part styles bundle for class 't-linear'
   function T_Linear_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Linear_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-ease-in'
   function T_Ease_In_Class_Widget return Widget_Style is
     (From (T_Ease_In_Class_Base_Style)
     .On (When_State (State_Hovered), T_Ease_In_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), T_Ease_In_Class_Widget_Pressed_Style)
     .Build);

   --  Part styles bundle for class 't-ease-in'
   function T_Ease_In_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Ease_In_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-ease-out'
   function T_Ease_Out_Class_Widget return Widget_Style is
     (From (T_Ease_Out_Class_Base_Style)
     .On (When_State (State_Hovered), T_Ease_Out_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), T_Ease_Out_Class_Widget_Pressed_Style)
     .Build);

   --  Part styles bundle for class 't-ease-out'
   function T_Ease_Out_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Ease_Out_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-ease-io'
   function T_Ease_Io_Class_Widget return Widget_Style is
     (From (T_Ease_Io_Class_Base_Style)
     .On (When_State (State_Hovered), T_Ease_Io_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), T_Ease_Io_Class_Widget_Pressed_Style)
     .Build);

   --  Part styles bundle for class 't-ease-io'
   function T_Ease_Io_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Ease_Io_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-bg'
   function T_Bg_Class_Widget return Widget_Style is
     (From (T_Bg_Class_Base_Style)
     .On (When_State (State_Hovered), T_Bg_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-bg'
   function T_Bg_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Bg_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-border'
   function T_Border_Class_Widget return Widget_Style is
     (From (T_Border_Class_Base_Style)
     .On (When_State (State_Hovered), T_Border_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-border'
   function T_Border_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Border_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-radius'
   function T_Radius_Class_Widget return Widget_Style is
     (From (T_Radius_Class_Base_Style)
     .On (When_State (State_Hovered), T_Radius_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-radius'
   function T_Radius_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Radius_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-shadow'
   function T_Shadow_Class_Widget return Widget_Style is
     (From (T_Shadow_Class_Base_Style)
     .On (When_State (State_Hovered), T_Shadow_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-shadow'
   function T_Shadow_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Shadow_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-opacity'
   function T_Opacity_Class_Widget return Widget_Style is
     (From (T_Opacity_Class_Base_Style)
     .On (When_State (State_Hovered), T_Opacity_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-opacity'
   function T_Opacity_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Opacity_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-multi'
   function T_Multi_Class_Widget return Widget_Style is
     (From (T_Multi_Class_Base_Style)
     .On (When_State (State_Hovered), T_Multi_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-multi'
   function T_Multi_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Multi_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-everything'
   function T_Everything_Class_Widget return Widget_Style is
     (From (T_Everything_Class_Base_Style)
     .On (When_State (State_Hovered), T_Everything_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-everything'
   function T_Everything_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Everything_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-fast'
   function T_Fast_Class_Widget return Widget_Style is
     (From (T_Fast_Class_Base_Style)
     .On (When_State (State_Hovered), T_Fast_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-fast'
   function T_Fast_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Fast_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 't-slow'
   function T_Slow_Class_Widget return Widget_Style is
     (From (T_Slow_Class_Base_Style)
     .On (When_State (State_Hovered), T_Slow_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 't-slow'
   function T_Slow_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => T_Slow_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Transition_Example_Styles;