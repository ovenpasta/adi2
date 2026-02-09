--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Combo_Box_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Padding => Set (CSS_Box (Px (24.0))),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (19, 26, 38)),
      others => <>
   );

   --  Base style for container
   Container_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (22.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for title::label
   Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for hint::label
   Hint_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (186, 204, 230)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for status::label
   Status_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for combo
   Combo_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (40.0))),
      Padding => Set (CSS_Box (Px (9.0), Px (10.0))),
      Background_Color => Set_Bg (RGB (248, 250, 252)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (8.0))),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Border_Color))),
      others => <>
   );

   --  Style for combo when widget State_Hovered
   Combo_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Color => Set (Border_Color (RGB (96, 165, 250))),
      others => <>
   );

   --  Style for combo when widget State_Focused
   Combo_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (37, 99, 235, 0.3))),
      others => <>
   );

   --  Base style for combo::indicator
   Combo_Indicator_Base_Style : constant Style_Rules := (
      Color => Set (RGB (71, 85, 105)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Align => Set (Text_Center),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Color))),
      others => <>
   );

   --  Style for combo::indicator when widget State_Hovered
   Combo_Indicator_Widget_Hovered_Style : constant Style_Rules := (
      Color => Set (RGB (30, 64, 175)),
      others => <>
   );

   --  Style for combo::indicator when widget State_Focused
   Combo_Indicator_Widget_Focused_Style : constant Style_Rules := (
      Color => Set (RGB (30, 58, 138)),
      others => <>
   );

   --  Base style for combo::label
   Combo_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for dropdown
   Dropdown_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (246, 248, 252)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (191, 201, 216))),
      Border_Radius => Set (Radius (Px (8.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (24.0), Px (0.0), RGBA (2, 8, 23, 0.22))),
      others => <>
   );

   --  Base style for dropdown::knob
   Dropdown_Knob_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (71, 85, 105, 0.85)),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for dropdown::knob when part State_Hovered
   Dropdown_Knob_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (51, 65, 85, 0.95)),
      others => <>
   );

   --  Style for dropdown::knob when part State_Pressed
   Dropdown_Knob_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (30, 41, 59, 1.0)),
      others => <>
   );

   --  Base style for dropdown::scroll
   Dropdown_Scroll_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0))),
      Padding => Set (CSS_Box (Px (2.0))),
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.22)),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.18, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for dropdown::scroll when part State_Hovered
   Dropdown_Scroll_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.42)),
      others => <>
   );

   --  Style for dropdown::scroll when part State_Pressed
   Dropdown_Scroll_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.58)),
      others => <>
   );

   --  Base style for option-row
   Option_Row_Base_Style : constant Style_Rules := (
      Padding => Set (CSS_Box (Px (8.0), Px (10.0))),
      Background_Color => Set_Bg (C (White)),
      Border_Width => Set (Border_Width (Px (1.0), Px (0.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (222, 229, 238))),
      Border_Radius => Set (Radius (Px (0.0))),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for option-row when widget State_Hovered
   Option_Row_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (239, 246, 255)),
      Border_Color => Set (Border_Color (RGB (147, 197, 253))),
      others => <>
   );

   --  Style for option-row when widget State_Selected
   Option_Row_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (29, 78, 216))),
      others => <>
   );

   --  Base style for option-row::label
   Option_Row_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (30, 41, 59)),
      Font_Size => Set_Font (Px (14.0)),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Color))),
      others => <>
   );

   --  Style for option-row::label when part State_Hovered
   Option_Row_Label_Part_Hovered_Style : constant Style_Rules := (
      Color => Set (RGB (15, 23, 42)),
      others => <>
   );

   --  Style for option-row::label when widget State_Selected
   Option_Row_Label_Widget_Selected_Style : constant Style_Rules := (
      Color => Set (C (White)),
      others => <>
   );

   --  Complete widget style for root
   Root_Widget : constant Widget_Style :=
     From (Root_Base_Style)
     .Build;

   --  Part styles bundle for root
   Root_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for container
   Container_Widget : constant Widget_Style :=
     From (Container_Base_Style)
     .Build;

   --  Part styles bundle for container
   Container_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Container_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for title::label
   Title_Label_Widget : constant Widget_Style :=
     From (Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for title
   Title_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Title_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for hint::label
   Hint_Label_Widget : constant Widget_Style :=
     From (Hint_Label_Base_Style)
     .Build;

   --  Part styles bundle for hint
   Hint_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Hint_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for status::label
   Status_Label_Widget : constant Widget_Style :=
     From (Status_Label_Base_Style)
     .Build;

   --  Part styles bundle for status
   Status_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Status_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for combo
   Combo_Widget : constant Widget_Style :=
     From (Combo_Base_Style)
     .On (When_State (State_Hovered), Combo_Widget_Hovered_Style)
     .On (When_State (State_Focused), Combo_Widget_Focused_Style)
     .Build;

   --  Complete widget style for combo::indicator
   Combo_Indicator_Widget : constant Widget_Style :=
     From (Combo_Indicator_Base_Style)
     .On (When_State (State_Hovered), Combo_Indicator_Widget_Hovered_Style)
     .On (When_State (State_Focused), Combo_Indicator_Widget_Focused_Style)
     .Build;

   --  Complete widget style for combo::label
   Combo_Label_Widget : constant Widget_Style :=
     From (Combo_Label_Base_Style)
     .Build;

   --  Part styles bundle for combo
   Combo_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Combo_Widget, Enabled => True),
      Indicator_Part => (Style => Combo_Indicator_Widget, Enabled => True),
      Label_Part => (Style => Combo_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for dropdown
   Dropdown_Widget : constant Widget_Style :=
     From (Dropdown_Base_Style)
     .Build;

   --  Complete widget style for dropdown::knob
   Dropdown_Knob_Widget : constant Widget_Style :=
     From (Dropdown_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Dropdown_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Dropdown_Knob_Part_Pressed_Style)
     .Build;

   --  Complete widget style for dropdown::scroll
   Dropdown_Scroll_Widget : constant Widget_Style :=
     From (Dropdown_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Dropdown_Scroll_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Dropdown_Scroll_Part_Pressed_Style)
     .Build;

   --  Part styles bundle for dropdown
   Dropdown_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dropdown_Widget, Enabled => True),
      Knob_Part => (Style => Dropdown_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Dropdown_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for option-row
   Option_Row_Widget : constant Widget_Style :=
     From (Option_Row_Base_Style)
     .On (When_State (State_Hovered), Option_Row_Widget_Hovered_Style)
     .On (When_State (State_Selected), Option_Row_Widget_Selected_Style)
     .Build;

   --  Complete widget style for option-row::label
   Option_Row_Label_Widget : constant Widget_Style :=
     From (Option_Row_Label_Base_Style)
     .On (When_Part_State (State_Hovered), Option_Row_Label_Part_Hovered_Style)
     .On (When_State (State_Selected), Option_Row_Label_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for option-row
   Option_Row_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Option_Row_Widget, Enabled => True),
      Label_Part => (Style => Option_Row_Label_Widget, Enabled => True),
      others => <>
   ];

end Combo_Box_Example_Styles;