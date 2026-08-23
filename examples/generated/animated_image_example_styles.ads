--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Animated_Image_Example_Styles is

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
      Gap => Set (Gap (Px (14.0))),
      Background_Color => Set_Bg (RGB (14, 18, 28)),
      Padding => Set (CSS_Box (Px (20.0), Px (24.0), Px (20.0), Px (24.0))),
      others => <>);

   --  Base style for class 'header'
   function Header_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (6.0))),
      Background_Color => Set_Bg (RGBA (30, 41, 59, 0.55)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (24.0), Px (0.0), RGBA (2, 6, 23, 0.5))),
      Padding => Set (CSS_Box (Px (14.0), Px (18.0), Px (14.0), Px (18.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (148, 163, 184, 0.35))),
      Border_Radius => Set (Radius (Px (14.0))),
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
      Font_Size => Set_Font (Px (30.0)),
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
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'viewer-frame'
   function Viewer_Frame_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.85)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (16.0), Px (36.0), Px (0.0), RGBA (2, 6, 23, 0.58))),
      Padding => Set (CSS_Box (Px (18.0), Px (18.0), Px (18.0), Px (18.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (59, 130, 246, 0.35))),
      Border_Radius => Set (Radius (Px (18.0))),
      others => <>);

   --  Base style for class 'viewer'
   function Viewer_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (340.0))),
      Background_Color => Set_Bg (RGBA (2, 6, 23, 0.7)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (148, 163, 184, 0.25))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'viewer'::icon
   function Viewer_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      Object_Position => Set (Object_Position (Pos_Center, Pos_Center)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'controls'
   function Controls_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'action-button'
   function Action_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (136.0))),
      Background_Color => Set_Bg (RGB (30, 64, 175)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.18, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow))),
      Padding => Set (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Style for class 'action-button' when widget State_Hovered
   function Action_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>);

   --  Style for class 'action-button' when widget State_Pressed
   function Action_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      others => <>);

   --  Style for class 'action-button' when widget State_Focused
   function Action_Button_Class_Widget_Focused_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (147, 197, 253, 0.42))),
      others => <>);

   --  Base style for class 'action-button'::label
   function Action_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (239, 246, 255)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'loop-button'
   function Loop_Button_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (136.0))),
      Background_Color => Set_Bg (RGB (220, 38, 38)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.18, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Box_Shadow))),
      Padding => Set (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (239, 68, 68))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Style for class 'loop-button' when widget State_Hovered
   function Loop_Button_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      others => <>);

   --  Style for class 'loop-button' when widget State_Pressed
   function Loop_Button_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (185, 28, 28)),
      others => <>);

   --  Style for class 'loop-button' when widget State_Selected
   function Loop_Button_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (22, 163, 74)),
      Border_Color => Set (Border_Color (RGB (34, 197, 94))),
      others => <>);

   --  Style for class 'loop-button' when widget State_Selected, widget State_Hovered
   function Loop_Button_Class_Widget_Selected_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (21, 128, 61)),
      others => <>);

   --  Style for class 'loop-button' when widget State_Selected, widget State_Pressed
   function Loop_Button_Class_Widget_Selected_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (20, 110, 55)),
      others => <>);

   --  Style for class 'loop-button' when widget State_Focused
   function Loop_Button_Class_Widget_Focused_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (134, 239, 172, 0.4))),
      others => <>);

   --  Base style for class 'loop-button'::label
   function Loop_Button_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (240, 253, 244)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'status'
   function Status_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.76)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Margin => [Top => Set_Margin_Side (Px (4.0)), others => <>],
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (71, 85, 105, 0.85))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (125, 211, 252)),
      Font_Size => Set_Font (Px (13.0)),
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

   --  Complete widget style for class 'header'
   function Header_Class_Widget return Widget_Style is
     (From (Header_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'header'
   function Header_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'subtitle'
   function Subtitle_Class_Widget return Widget_Style is
     (From (Subtitle_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'subtitle'::label
   function Subtitle_Class_Label_Widget return Widget_Style is
     (From (Subtitle_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'subtitle'
   function Subtitle_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'viewer-frame'
   function Viewer_Frame_Class_Widget return Widget_Style is
     (From (Viewer_Frame_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'viewer-frame'
   function Viewer_Frame_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Viewer_Frame_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'viewer'
   function Viewer_Class_Widget return Widget_Style is
     (From (Viewer_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'viewer'::icon
   function Viewer_Class_Icon_Widget return Widget_Style is
     (From (Viewer_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'viewer'
   function Viewer_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Viewer_Class_Widget, Enabled => True),
      Icon_Part => (Style => Viewer_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'controls'
   function Controls_Class_Widget return Widget_Style is
     (From (Controls_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'controls'
   function Controls_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Controls_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'action-button'
   function Action_Button_Class_Widget return Widget_Style is
     (From (Action_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Action_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Action_Button_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Action_Button_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'action-button'::label
   function Action_Button_Class_Label_Widget return Widget_Style is
     (From (Action_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'action-button'
   function Action_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Action_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Action_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'loop-button'
   function Loop_Button_Class_Widget return Widget_Style is
     (From (Loop_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Loop_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Loop_Button_Class_Widget_Pressed_Style)
     .On (When_State (State_Selected), Loop_Button_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Loop_Button_Class_Widget_Selected_Widget_Hovered_Style)
     .On (When_State (State_Selected) and When_State (State_Pressed), Loop_Button_Class_Widget_Selected_Widget_Pressed_Style)
     .On (When_State (State_Focused), Loop_Button_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'loop-button'::label
   function Loop_Button_Class_Label_Widget return Widget_Style is
     (From (Loop_Button_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'loop-button'
   function Loop_Button_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Loop_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Loop_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'status'
   function Status_Class_Widget return Widget_Style is
     (From (Status_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'status'::label
   function Status_Class_Label_Widget return Widget_Style is
     (From (Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'status'
   function Status_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Animated_Image_Example_Styles;