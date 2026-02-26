--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Animated_Image_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (14.0))),
      Background_Color => Set_Bg (RGB (14, 18, 28)),
      Padding => Set (CSS_Box (Px (20.0), Px (24.0), Px (20.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'header'
   Header_Class_Base_Style : constant Style_Rules := (
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
      others => <>
   );

   --  Base style for class 'title'
   Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'title'::label
   Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (30.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      others => <>
   );

   --  Base style for class 'subtitle'
   Subtitle_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'subtitle'::label
   Subtitle_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'viewer-frame'
   Viewer_Frame_Class_Base_Style : constant Style_Rules := (
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
      others => <>
   );

   --  Base style for class 'viewer'
   Viewer_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (340.0))),
      Background_Color => Set_Bg (RGBA (2, 6, 23, 0.7)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (148, 163, 184, 0.25))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>
   );

   --  Base style for class 'viewer'::icon
   Viewer_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_Contain),
      Object_Position => Set (Object_Position (Pos_Center, Pos_Center)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for class 'controls'
   Controls_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Gap => Set (Gap (Px (12.0))),
      others => <>
   );

   --  Base style for class 'action-button'
   Action_Button_Class_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (136.0))),
      Background_Color => Set_Bg (RGB (30, 64, 175)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.18, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Style for class 'action-button' when widget State_Hovered
   Action_Button_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>
   );

   --  Style for class 'action-button' when widget State_Pressed
   Action_Button_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      others => <>
   );

   --  Style for class 'action-button' when widget State_Focused
   Action_Button_Class_Widget_Focused_Style : constant Style_Rules := (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (147, 197, 253, 0.42))),
      others => <>
   );

   --  Base style for class 'action-button'::label
   Action_Button_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (239, 246, 255)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>
   );

   --  Base style for class 'loop-button'
   Loop_Button_Class_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (136.0))),
      Background_Color => Set_Bg (RGB (220, 38, 38)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.18, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (239, 68, 68))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Style for class 'loop-button' when widget State_Hovered
   Loop_Button_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      others => <>
   );

   --  Style for class 'loop-button' when widget State_Pressed
   Loop_Button_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (185, 28, 28)),
      others => <>
   );

   --  Style for class 'loop-button' when widget State_Selected
   Loop_Button_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (22, 163, 74)),
      Border_Color => Set (Border_Color (RGB (34, 197, 94))),
      others => <>
   );

   --  Style for class 'loop-button' when widget State_Selected, widget State_Hovered
   Loop_Button_Class_Widget_Selected_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (21, 128, 61)),
      others => <>
   );

   --  Style for class 'loop-button' when widget State_Selected, widget State_Pressed
   Loop_Button_Class_Widget_Selected_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (20, 110, 55)),
      others => <>
   );

   --  Style for class 'loop-button' when widget State_Focused
   Loop_Button_Class_Widget_Focused_Style : constant Style_Rules := (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (134, 239, 172, 0.4))),
      others => <>
   );

   --  Base style for class 'loop-button'::label
   Loop_Button_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (240, 253, 244)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Text_Align => Set (Text_Center),
      others => <>
   );

   --  Base style for class 'status'
   Status_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.76)),
      Padding => Set (CSS_Box (Px (8.0), Px (12.0), Px (8.0), Px (12.0))),
      Margin => Set (CSS_Box (Px (4.0), Px (0.0), Px (0.0), Px (0.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (71, 85, 105, 0.85))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for class 'status'::label
   Status_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (125, 211, 252)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>
   );

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'header'
   Header_Class_Widget : constant Widget_Style :=
     From (Header_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'header'
   Header_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
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
   Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'subtitle'
   Subtitle_Class_Widget : constant Widget_Style :=
     From (Subtitle_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     From (Subtitle_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'viewer-frame'
   Viewer_Frame_Class_Widget : constant Widget_Style :=
     From (Viewer_Frame_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'viewer-frame'
   Viewer_Frame_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Viewer_Frame_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'viewer'
   Viewer_Class_Widget : constant Widget_Style :=
     From (Viewer_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'viewer'::icon
   Viewer_Class_Icon_Widget : constant Widget_Style :=
     From (Viewer_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'viewer'
   Viewer_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Viewer_Class_Widget, Enabled => True),
      Icon_Part => (Style => Viewer_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'controls'
   Controls_Class_Widget : constant Widget_Style :=
     From (Controls_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'controls'
   Controls_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Controls_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'action-button'
   Action_Button_Class_Widget : constant Widget_Style :=
     From (Action_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Action_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Action_Button_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Action_Button_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'action-button'::label
   Action_Button_Class_Label_Widget : constant Widget_Style :=
     From (Action_Button_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'action-button'
   Action_Button_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Action_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Action_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'loop-button'
   Loop_Button_Class_Widget : constant Widget_Style :=
     From (Loop_Button_Class_Base_Style)
     .On (When_State (State_Hovered), Loop_Button_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Loop_Button_Class_Widget_Pressed_Style)
     .On (When_State (State_Selected), Loop_Button_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Loop_Button_Class_Widget_Selected_Widget_Hovered_Style)
     .On (When_State (State_Selected) and When_State (State_Pressed), Loop_Button_Class_Widget_Selected_Widget_Pressed_Style)
     .On (When_State (State_Focused), Loop_Button_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'loop-button'::label
   Loop_Button_Class_Label_Widget : constant Widget_Style :=
     From (Loop_Button_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'loop-button'
   Loop_Button_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Loop_Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Loop_Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     From (Status_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     From (Status_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Animated_Image_Example_Styles;