--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Button_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 30, 36)),
      others => <>
   );

   --  Base style for container
   Container_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (24.0))),
      Padding => Set (CSS_Box (Px (30.0))),
      others => <>
   );

   --  Base style for section-row
   Section_Row_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (12.0))),
      Align_Items => Set (Center),
      others => <>
   );

   --  Base style for section-row-2
   Section_Row_2_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      others => <>
   );

   --  Base style for primary
   Primary_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Width => Set (Border_Width (Px (0.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for primary when State_Hovered
   Primary_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>
   );

   --  Style for primary when State_Pressed
   Primary_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (29, 58, 145)),
      others => <>
   );

   --  Base style for primary::label
   Primary_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Align => Set (Text_Center),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for danger
   Danger_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (220, 38, 38)),
      Border_Width => Set (Border_Width (Px (0.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for danger when State_Hovered
   Danger_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (185, 28, 28)),
      others => <>
   );

   --  Style for danger when State_Pressed
   Danger_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (153, 27, 27)),
      others => <>
   );

   --  Base style for danger::label
   Danger_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for outline
   Outline_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for outline when State_Hovered
   Outline_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.15)),
      others => <>
   );

   --  Style for outline when State_Pressed
   Outline_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.25)),
      others => <>
   );

   --  Base style for outline::label
   Outline_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (226, 232, 240)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for toggle
   Toggle_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Color => Set (Border_Color (RGB (107, 114, 128))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for toggle when State_Hovered
   Toggle_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (90, 100, 114)),
      others => <>
   );

   --  Style for toggle when State_Pressed
   Toggle_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      others => <>
   );

   --  Style for toggle when State_Selected
   Toggle_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (22, 163, 74)),
      Border_Color => Set (Border_Color (RGB (21, 128, 61))),
      others => <>
   );

   --  Style for toggle when State_Selected, State_Pressed
   Toggle_Selected_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (21, 128, 61)),
      Border_Color => Set (Border_Color (RGB (20, 110, 55))),
      others => <>
   );

   --  Base style for toggle::label
   Toggle_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for option-left
   Option_Left_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (6.0), Px (0.0), Px (0.0), Px (6.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (16.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for option-left when State_Hovered
   Option_Left_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for option-left when State_Selected
   Option_Left_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for option-left::label
   Option_Left_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for option-center
   Option_Center_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Padding => Set (CSS_Box (Px (8.0), Px (16.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for option-center when State_Hovered
   Option_Center_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for option-center when State_Selected
   Option_Center_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for option-center::label
   Option_Center_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for option-right
   Option_Right_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (0.0), Px (6.0), Px (6.0), Px (0.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (16.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for option-right when State_Hovered
   Option_Right_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for option-right when State_Selected
   Option_Right_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for option-right::label
   Option_Right_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Complete widget style for root
   Root_Widget : constant Widget_Style :=
     From (Root_Base_Style)
     .Build;

   --  Part styles bundle for root
   Root_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Root_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for container
   Container_Widget : constant Widget_Style :=
     From (Container_Base_Style)
     .Build;

   --  Part styles bundle for container
   Container_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Container_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for section-row
   Section_Row_Widget : constant Widget_Style :=
     From (Section_Row_Base_Style)
     .Build;

   --  Part styles bundle for section-row
   Section_Row_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Section_Row_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for section-row-2
   Section_Row_2_Widget : constant Widget_Style :=
     From (Section_Row_2_Base_Style)
     .Build;

   --  Part styles bundle for section-row-2
   Section_Row_2_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Section_Row_2_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for primary
   Primary_Widget : constant Widget_Style :=
     From (Primary_Base_Style)
     .On (When_State (State_Hovered), Primary_Hovered_Style)
     .On (When_State (State_Pressed), Primary_Pressed_Style)
     .Build;

   --  Complete widget style for primary::label
   Primary_Label_Widget : constant Widget_Style :=
     From (Primary_Label_Base_Style)
     .Build;

   --  Part styles bundle for primary
   Primary_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Primary_Widget, Enabled => True),
      Label_Part => (Style => Primary_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for danger
   Danger_Widget : constant Widget_Style :=
     From (Danger_Base_Style)
     .On (When_State (State_Hovered), Danger_Hovered_Style)
     .On (When_State (State_Pressed), Danger_Pressed_Style)
     .Build;

   --  Complete widget style for danger::label
   Danger_Label_Widget : constant Widget_Style :=
     From (Danger_Label_Base_Style)
     .Build;

   --  Part styles bundle for danger
   Danger_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Danger_Widget, Enabled => True),
      Label_Part => (Style => Danger_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for outline
   Outline_Widget : constant Widget_Style :=
     From (Outline_Base_Style)
     .On (When_State (State_Hovered), Outline_Hovered_Style)
     .On (When_State (State_Pressed), Outline_Pressed_Style)
     .Build;

   --  Complete widget style for outline::label
   Outline_Label_Widget : constant Widget_Style :=
     From (Outline_Label_Base_Style)
     .Build;

   --  Part styles bundle for outline
   Outline_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Outline_Widget, Enabled => True),
      Label_Part => (Style => Outline_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for toggle
   Toggle_Widget : constant Widget_Style :=
     From (Toggle_Base_Style)
     .On (When_State (State_Hovered), Toggle_Hovered_Style)
     .On (When_State (State_Pressed), Toggle_Pressed_Style)
     .On (When_State (State_Selected), Toggle_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Pressed), Toggle_Selected_Pressed_Style)
     .Build;

   --  Complete widget style for toggle::label
   Toggle_Label_Widget : constant Widget_Style :=
     From (Toggle_Label_Base_Style)
     .Build;

   --  Part styles bundle for toggle
   Toggle_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Toggle_Widget, Enabled => True),
      Label_Part => (Style => Toggle_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for option-left
   Option_Left_Widget : constant Widget_Style :=
     From (Option_Left_Base_Style)
     .On (When_State (State_Hovered), Option_Left_Hovered_Style)
     .On (When_State (State_Selected), Option_Left_Selected_Style)
     .Build;

   --  Complete widget style for option-left::label
   Option_Left_Label_Widget : constant Widget_Style :=
     From (Option_Left_Label_Base_Style)
     .Build;

   --  Part styles bundle for option-left
   Option_Left_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Option_Left_Widget, Enabled => True),
      Label_Part => (Style => Option_Left_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for option-center
   Option_Center_Widget : constant Widget_Style :=
     From (Option_Center_Base_Style)
     .On (When_State (State_Hovered), Option_Center_Hovered_Style)
     .On (When_State (State_Selected), Option_Center_Selected_Style)
     .Build;

   --  Complete widget style for option-center::label
   Option_Center_Label_Widget : constant Widget_Style :=
     From (Option_Center_Label_Base_Style)
     .Build;

   --  Part styles bundle for option-center
   Option_Center_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Option_Center_Widget, Enabled => True),
      Label_Part => (Style => Option_Center_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for option-right
   Option_Right_Widget : constant Widget_Style :=
     From (Option_Right_Base_Style)
     .On (When_State (State_Hovered), Option_Right_Hovered_Style)
     .On (When_State (State_Selected), Option_Right_Selected_Style)
     .Build;

   --  Complete widget style for option-right::label
   Option_Right_Label_Widget : constant Widget_Style :=
     From (Option_Right_Label_Base_Style)
     .Build;

   --  Part styles bundle for option-right
   Option_Right_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Option_Right_Widget, Enabled => True),
      Label_Part => (Style => Option_Right_Label_Widget, Enabled => True),
      others => <>
   );

end Button_Example_Styles;