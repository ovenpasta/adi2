--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Dialog_Example_Styles is

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
      Gap => Set (Gap (Px (16.0))),
      Padding => Set (CSS_Box (Px (24.0))),
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

   --  Base style for btn-primary
   Btn_Primary_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (40.0))),
      Padding => Set (CSS_Box (Px (9.0), Px (16.0))),
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (29, 78, 216))),
      Border_Radius => Set (Radius (Px (8.0))),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for btn-primary when widget State_Hovered
   Btn_Primary_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Style for btn-primary when widget State_Pressed
   Btn_Primary_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      Border_Color => Set (Border_Color (RGB (30, 64, 175))),
      others => <>
   );

   --  Base style for btn-primary::label
   Btn_Primary_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Align => Set (Text_Center),
      White_Space => Set (WS_Nowrap),
      others => <>
   );

   --  Base style for backdrop
   Backdrop_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.45)),
      others => <>
   );

   --  Base style for panel
   Panel_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (16.0))),
      Padding => Set (CSS_Box (Px (24.0))),
      Min_Width => Set (Size (Px (340.0))),
      Max_Width => Set (Size (Px (480.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Radius => Set (Radius (Px (12.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (16.0), Px (48.0), Px (0.0), RGBA (0, 0, 0, 0.3))),
      others => <>
   );

   --  Base style for dialog-title::label
   Dialog_Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for dialog-message::label
   Dialog_Message_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (71, 85, 105)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for button-row
   Button_Row_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Flex_End),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      others => <>
   );

   --  Base style for dialog-btn
   Dialog_Btn_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (36.0))),
      Padding => Set (CSS_Box (Px (7.0), Px (16.0))),
      Background_Color => Set_Bg (RGB (241, 245, 249)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (203, 213, 225))),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.12, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for dialog-btn when widget State_Hovered
   Dialog_Btn_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (226, 232, 240)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      others => <>
   );

   --  Style for dialog-btn when widget State_Pressed
   Dialog_Btn_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (203, 213, 225)),
      Border_Color => Set (Border_Color (RGB (100, 116, 139))),
      others => <>
   );

   --  Style for dialog-btn when widget State_Focused
   Dialog_Btn_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (59, 130, 246, 0.3))),
      others => <>
   );

   --  Base style for dialog-btn::label
   Dialog_Btn_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (30, 41, 59)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Align => Set (Text_Center),
      White_Space => Set (WS_Nowrap),
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

   --  Complete widget style for btn-primary
   Btn_Primary_Widget : constant Widget_Style :=
     From (Btn_Primary_Base_Style)
     .On (When_State (State_Hovered), Btn_Primary_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Btn_Primary_Widget_Pressed_Style)
     .Build;

   --  Complete widget style for btn-primary::label
   Btn_Primary_Label_Widget : constant Widget_Style :=
     From (Btn_Primary_Label_Base_Style)
     .Build;

   --  Part styles bundle for btn-primary
   Btn_Primary_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Btn_Primary_Widget, Enabled => True),
      Label_Part => (Style => Btn_Primary_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for backdrop
   Backdrop_Widget : constant Widget_Style :=
     From (Backdrop_Base_Style)
     .Build;

   --  Part styles bundle for backdrop
   Backdrop_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Backdrop_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for panel
   Panel_Widget : constant Widget_Style :=
     From (Panel_Base_Style)
     .Build;

   --  Part styles bundle for panel
   Panel_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Panel_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for dialog-title::label
   Dialog_Title_Label_Widget : constant Widget_Style :=
     From (Dialog_Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for dialog-title
   Dialog_Title_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Dialog_Title_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for dialog-message::label
   Dialog_Message_Label_Widget : constant Widget_Style :=
     From (Dialog_Message_Label_Base_Style)
     .Build;

   --  Part styles bundle for dialog-message
   Dialog_Message_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Dialog_Message_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for button-row
   Button_Row_Widget : constant Widget_Style :=
     From (Button_Row_Base_Style)
     .Build;

   --  Part styles bundle for button-row
   Button_Row_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Button_Row_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for dialog-btn
   Dialog_Btn_Widget : constant Widget_Style :=
     From (Dialog_Btn_Base_Style)
     .On (When_State (State_Hovered), Dialog_Btn_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Dialog_Btn_Widget_Pressed_Style)
     .On (When_State (State_Focused), Dialog_Btn_Widget_Focused_Style)
     .Build;

   --  Complete widget style for dialog-btn::label
   Dialog_Btn_Label_Widget : constant Widget_Style :=
     From (Dialog_Btn_Label_Base_Style)
     .Build;

   --  Part styles bundle for dialog-btn
   Dialog_Btn_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Btn_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Label_Widget, Enabled => True),
      others => <>
   ];

end Dialog_Example_Styles;