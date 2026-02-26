--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Button_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 30, 36)),
      others => <>
   );

   --  Base style for class 'container'
   Container_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (24.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      others => <>
   );

   --  Base style for class 'section-row'
   Section_Row_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (12.0))),
      Align_Items => Set (Center),
      others => <>
   );

   --  Base style for class 'section-row-2'
   Section_Row_2_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      others => <>
   );

   --  Base style for class 'primary'
   Primary_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (0.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Style for class 'primary' when widget State_Hovered
   Primary_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>
   );

   --  Style for class 'primary' when widget State_Pressed
   Primary_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (29, 58, 145)),
      others => <>
   );

   --  Style for class 'primary' when widget State_Focused
   Primary_Class_Widget_Focused_Style : constant Style_Rules := (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (191, 219, 254, 0.9))),
      others => <>
   );

   --  Base style for class 'primary'::label
   Primary_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Align => Set (Text_Center),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'danger'
   Danger_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (220, 38, 38)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (0.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Style for class 'danger' when widget State_Hovered
   Danger_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (185, 28, 28)),
      others => <>
   );

   --  Style for class 'danger' when widget State_Pressed
   Danger_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (153, 27, 27)),
      others => <>
   );

   --  Style for class 'danger' when widget State_Focused
   Danger_Class_Widget_Focused_Style : constant Style_Rules := (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (254, 202, 202, 0.9))),
      others => <>
   );

   --  Base style for class 'danger'::label
   Danger_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'outline'
   Outline_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.0)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (12.0), Px (24.0), Px (12.0), Px (24.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Style for class 'outline' when widget State_Hovered
   Outline_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.15)),
      others => <>
   );

   --  Style for class 'outline' when widget State_Pressed
   Outline_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.25)),
      others => <>
   );

   --  Style for class 'outline' when widget State_Focused
   Outline_Class_Widget_Focused_Style : constant Style_Rules := (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (147, 197, 253, 0.4))),
      Border_Color => Set (Border_Color (RGB (96, 165, 250))),
      others => <>
   );

   --  Base style for class 'outline'::label
   Outline_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (226, 232, 240)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'toggle'
   Toggle_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (107, 114, 128))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Style for class 'toggle' when widget State_Hovered
   Toggle_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (90, 100, 114)),
      others => <>
   );

   --  Style for class 'toggle' when widget State_Pressed
   Toggle_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      others => <>
   );

   --  Style for class 'toggle' when widget State_Selected
   Toggle_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (22, 163, 74)),
      Border_Color => Set (Border_Color (RGB (21, 128, 61))),
      others => <>
   );

   --  Style for class 'toggle' when widget State_Selected, widget State_Pressed
   Toggle_Class_Widget_Selected_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (21, 128, 61)),
      Border_Color => Set (Border_Color (RGB (20, 110, 55))),
      others => <>
   );

   --  Style for class 'toggle' when widget State_Focused
   Toggle_Class_Widget_Focused_Style : constant Style_Rules := (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (96, 165, 250, 0.35))),
      Border_Color => Set (Border_Color (RGB (147, 197, 253))),
      others => <>
   );

   --  Base style for class 'toggle'::label
   Toggle_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'switch'
   Switch_Class_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (56.0))),
      Height => Set (Size (Px (32.0))),
      Background_Color => Set_Bg (RGB (71, 85, 105)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (30, 41, 59, 0.22))),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.28, Easing => Ease_In_Out, Properties => Props (Prop_Background_Color))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (148, 163, 184, 0.55))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>
   );

   --  Style for class 'switch' when widget State_Hovered
   Switch_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (100, 116, 139)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (3.0), RGBA (71, 85, 105, 0.3))),
      others => <>
   );

   --  Style for class 'switch' when widget State_Pressed
   Switch_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (51, 65, 85)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (1.0), Px (3.0), Px (0.0), RGBA (15, 23, 42, 0.14))),
      others => <>
   );

   --  Style for class 'switch' when widget State_Selected
   Switch_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (16, 185, 129)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (12.0), Px (4.0), RGBA (16, 185, 129, 0.34))),
      Border_Color => Set (Border_Color (RGB (5, 150, 105))),
      others => <>
   );

   --  Style for class 'switch' when widget State_Selected, widget State_Hovered
   Switch_Class_Widget_Selected_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (5, 150, 105)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (14.0), Px (5.0), RGBA (5, 150, 105, 0.4))),
      Border_Color => Set (Border_Color (RGB (4, 120, 87))),
      others => <>
   );

   --  Style for class 'switch' when widget State_Selected, widget State_Pressed
   Switch_Class_Widget_Selected_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (4, 120, 87)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (6, 78, 59, 0.26))),
      others => <>
   );

   --  Style for class 'switch' when widget State_Focused
   Switch_Class_Widget_Focused_Style : constant Style_Rules := (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (134, 239, 172, 0.36))),
      others => <>
   );

   --  Base style for class 'switch'::knob
   Switch_Class_Knob_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (26.0))),
      Height => Set (Size (Px (26.0))),
      Background_Color => Set_Bg (RGB (248, 250, 252)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (6.0), Px (1.0), RGBA (15, 23, 42, 0.22))),
      Transition => Set ((Duration => 0.26, Easing => Ease_In_Out, Properties => Props (Prop_Margin))),
      Margin => Set (CSS_Box (Px (2.0), Px (0.0), Px (0.0), Px (2.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (15, 23, 42, 0.12))),
      Border_Radius => Set (Radius (Px (13.0))),
      others => <>
   );

   --  Style for class 'switch'::knob when part State_Hovered
   Switch_Class_Knob_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (15, 23, 42, 0.28))),
      others => <>
   );

   --  Style for class 'switch'::knob when part State_Pressed
   Switch_Class_Knob_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (241, 245, 249)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (4.0), Px (1.0), RGBA (15, 23, 42, 0.18))),
      others => <>
   );

   --  Style for class 'switch'::knob when widget State_Selected
   Switch_Class_Knob_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (240, 253, 244)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (5, 150, 105, 0.3))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (28.0))),
      others => <>
   );

   --  Base style for class 'option-left'
   Option_Left_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (8.0), Px (16.0), Px (8.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Radius => Set (Radius (Px (6.0), Px (0.0), Px (0.0), Px (6.0))),
      others => <>
   );

   --  Style for class 'option-left' when widget State_Hovered
   Option_Left_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for class 'option-left' when widget State_Selected
   Option_Left_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Style for class 'option-left' when widget State_Focused
   Option_Left_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (147, 197, 253))),
      others => <>
   );

   --  Base style for class 'option-left'::label
   Option_Left_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'option-center'
   Option_Center_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (8.0), Px (16.0), Px (8.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      others => <>
   );

   --  Style for class 'option-center' when widget State_Hovered
   Option_Center_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for class 'option-center' when widget State_Selected
   Option_Center_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Style for class 'option-center' when widget State_Focused
   Option_Center_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (147, 197, 253))),
      others => <>
   );

   --  Base style for class 'option-center'::label
   Option_Center_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'option-right'
   Option_Right_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (8.0), Px (16.0), Px (8.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Radius => Set (Radius (Px (0.0), Px (6.0), Px (6.0), Px (0.0))),
      others => <>
   );

   --  Style for class 'option-right' when widget State_Hovered
   Option_Right_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for class 'option-right' when widget State_Selected
   Option_Right_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Style for class 'option-right' when widget State_Focused
   Option_Right_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (147, 197, 253))),
      others => <>
   );

   --  Base style for class 'option-right'::label
   Option_Right_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
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

   --  Complete widget style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     From (Container_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'section-row'
   Section_Row_Class_Widget : constant Widget_Style :=
     From (Section_Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'section-row'
   Section_Row_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Section_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'section-row-2'
   Section_Row_2_Class_Widget : constant Widget_Style :=
     From (Section_Row_2_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'section-row-2'
   Section_Row_2_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Section_Row_2_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'primary'
   Primary_Class_Widget : constant Widget_Style :=
     From (Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Primary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Primary_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Primary_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'primary'::label
   Primary_Class_Label_Widget : constant Widget_Style :=
     From (Primary_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'primary'
   Primary_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'danger'
   Danger_Class_Widget : constant Widget_Style :=
     From (Danger_Class_Base_Style)
     .On (When_State (State_Hovered), Danger_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Danger_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Danger_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'danger'::label
   Danger_Class_Label_Widget : constant Widget_Style :=
     From (Danger_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'danger'
   Danger_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Danger_Class_Widget, Enabled => True),
      Label_Part => (Style => Danger_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'outline'
   Outline_Class_Widget : constant Widget_Style :=
     From (Outline_Class_Base_Style)
     .On (When_State (State_Hovered), Outline_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Outline_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Outline_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'outline'::label
   Outline_Class_Label_Widget : constant Widget_Style :=
     From (Outline_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'outline'
   Outline_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Outline_Class_Widget, Enabled => True),
      Label_Part => (Style => Outline_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'toggle'
   Toggle_Class_Widget : constant Widget_Style :=
     From (Toggle_Class_Base_Style)
     .On (When_State (State_Hovered), Toggle_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Toggle_Class_Widget_Pressed_Style)
     .On (When_State (State_Selected), Toggle_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Pressed), Toggle_Class_Widget_Selected_Widget_Pressed_Style)
     .On (When_State (State_Focused), Toggle_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'toggle'::label
   Toggle_Class_Label_Widget : constant Widget_Style :=
     From (Toggle_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'toggle'
   Toggle_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Toggle_Class_Widget, Enabled => True),
      Label_Part => (Style => Toggle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'switch'
   Switch_Class_Widget : constant Widget_Style :=
     From (Switch_Class_Base_Style)
     .On (When_State (State_Hovered), Switch_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Switch_Class_Widget_Pressed_Style)
     .On (When_State (State_Selected), Switch_Class_Widget_Selected_Style)
     .On (When_State (State_Selected) and When_State (State_Hovered), Switch_Class_Widget_Selected_Widget_Hovered_Style)
     .On (When_State (State_Selected) and When_State (State_Pressed), Switch_Class_Widget_Selected_Widget_Pressed_Style)
     .On (When_State (State_Focused), Switch_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'switch'::knob
   Switch_Class_Knob_Widget : constant Widget_Style :=
     From (Switch_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Switch_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Switch_Class_Knob_Part_Pressed_Style)
     .On (When_State (State_Selected), Switch_Class_Knob_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for class 'switch'
   Switch_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'option-left'
   Option_Left_Class_Widget : constant Widget_Style :=
     From (Option_Left_Class_Base_Style)
     .On (When_State (State_Hovered), Option_Left_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Option_Left_Class_Widget_Selected_Style)
     .On (When_State (State_Focused), Option_Left_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'option-left'::label
   Option_Left_Class_Label_Widget : constant Widget_Style :=
     From (Option_Left_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'option-left'
   Option_Left_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Option_Left_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'option-center'
   Option_Center_Class_Widget : constant Widget_Style :=
     From (Option_Center_Class_Base_Style)
     .On (When_State (State_Hovered), Option_Center_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Option_Center_Class_Widget_Selected_Style)
     .On (When_State (State_Focused), Option_Center_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'option-center'::label
   Option_Center_Class_Label_Widget : constant Widget_Style :=
     From (Option_Center_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'option-center'
   Option_Center_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Option_Center_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Center_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'option-right'
   Option_Right_Class_Widget : constant Widget_Style :=
     From (Option_Right_Class_Base_Style)
     .On (When_State (State_Hovered), Option_Right_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Option_Right_Class_Widget_Selected_Style)
     .On (When_State (State_Focused), Option_Right_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'option-right'::label
   Option_Right_Class_Label_Widget : constant Widget_Style :=
     From (Option_Right_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'option-right'
   Option_Right_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Option_Right_Class_Widget, Enabled => True),
      Label_Part => (Style => Option_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Button_Example_Styles;