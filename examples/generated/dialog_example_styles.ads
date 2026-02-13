--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Dialog_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (19, 26, 38)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'container'
   Container_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (16.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Radius => Set (Radius (Px (10.0))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'title'
   Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'title'::label
   Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'hint'
   Hint_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'hint'::label
   Hint_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (186, 204, 230)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for class 'status'::label
   Status_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'btn-primary'
   Btn_Primary_Class_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (40.0))),
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (29, 78, 216))),
      Border_Radius => Set (Radius (Px (8.0))),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (9.0), Px (16.0), Px (9.0), Px (16.0))),
      others => <>
   );

   --  Style for class 'btn-primary' when widget State_Hovered
   Btn_Primary_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Style for class 'btn-primary' when widget State_Pressed
   Btn_Primary_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      Border_Color => Set (Border_Color (RGB (30, 64, 175))),
      others => <>
   );

   --  Base style for class 'btn-primary'::label
   Btn_Primary_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Align => Set (Text_Center),
      White_Space => Set (WS_Nowrap),
      others => <>
   );

   --  Base style for class 'backdrop'
   Backdrop_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.45)),
      others => <>
   );

   --  Base style for class 'panel'
   Panel_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (16.0))),
      Min_Width => Set (Size (Px (340.0))),
      Max_Width => Set (Size (Px (480.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Radius => Set (Radius (Px (12.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (16.0), Px (48.0), Px (0.0), RGBA (0, 0, 0, 0.3))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'dialog-title'
   Dialog_Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'dialog-title'::label
   Dialog_Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'dialog-message'::label
   Dialog_Message_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (71, 85, 105)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for class 'button-row'
   Button_Row_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Flex_End),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      others => <>
   );

   --  Base style for class 'dialog-btn'
   Dialog_Btn_Class_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (36.0))),
      Background_Color => Set_Bg (RGB (241, 245, 249)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (203, 213, 225))),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.12, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (7.0), Px (16.0), Px (7.0), Px (16.0))),
      others => <>
   );

   --  Style for class 'dialog-btn' when widget State_Hovered
   Dialog_Btn_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (226, 232, 240)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      others => <>
   );

   --  Style for class 'dialog-btn' when widget State_Pressed
   Dialog_Btn_Class_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (203, 213, 225)),
      Border_Color => Set (Border_Color (RGB (100, 116, 139))),
      others => <>
   );

   --  Style for class 'dialog-btn' when widget State_Focused
   Dialog_Btn_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (59, 130, 246, 0.3))),
      others => <>
   );

   --  Base style for class 'dialog-btn'::label
   Dialog_Btn_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (30, 41, 59)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Align => Set (Text_Center),
      White_Space => Set (WS_Nowrap),
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

   --  Complete widget style for class 'hint'
   Hint_Class_Widget : constant Widget_Style :=
     From (Hint_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'hint'::label
   Hint_Class_Label_Widget : constant Widget_Style :=
     From (Hint_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'hint'
   Hint_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     From (Status_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'btn-primary'
   Btn_Primary_Class_Widget : constant Widget_Style :=
     From (Btn_Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Btn_Primary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Btn_Primary_Class_Widget_Pressed_Style)
     .Build;

   --  Complete widget style for class 'btn-primary'::label
   Btn_Primary_Class_Label_Widget : constant Widget_Style :=
     From (Btn_Primary_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'btn-primary'
   Btn_Primary_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'backdrop'
   Backdrop_Class_Widget : constant Widget_Style :=
     From (Backdrop_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'backdrop'
   Backdrop_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Backdrop_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'panel'
   Panel_Class_Widget : constant Widget_Style :=
     From (Panel_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'panel'
   Panel_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-title'
   Dialog_Title_Class_Widget : constant Widget_Style :=
     From (Dialog_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'dialog-title'::label
   Dialog_Title_Class_Label_Widget : constant Widget_Style :=
     From (Dialog_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-title'
   Dialog_Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-message'::label
   Dialog_Message_Class_Label_Widget : constant Widget_Style :=
     From (Dialog_Message_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-message'
   Dialog_Message_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Dialog_Message_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'button-row'
   Button_Row_Class_Widget : constant Widget_Style :=
     From (Button_Row_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'button-row'
   Button_Row_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Button_Row_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'dialog-btn'
   Dialog_Btn_Class_Widget : constant Widget_Style :=
     From (Dialog_Btn_Class_Base_Style)
     .On (When_State (State_Hovered), Dialog_Btn_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Dialog_Btn_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Dialog_Btn_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'dialog-btn'::label
   Dialog_Btn_Class_Label_Widget : constant Widget_Style :=
     From (Dialog_Btn_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'dialog-btn'
   Dialog_Btn_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dialog_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Dialog_Example_Styles;