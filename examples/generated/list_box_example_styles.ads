--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package List_Box_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (12.0))),
      Background_Color => Set_Bg (RGB (242, 245, 248)),
      others => <>
   );

   --  Base style for panels
   Panels_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (12.0))),
      Flex_Grow => Set (1.0),
      Height => Set (Size (Px (580.0))),
      others => <>
   );

   --  Base style for panel
   Panel_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (10.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (220, 226, 234))),
      Border_Radius => Set (Radius (Px (10.0))),
      Width => Set (Size (Px (476.0))),
      Height => Set (Size (Px (580.0))),
      others => <>
   );

   --  Base style for panel-title::label
   Panel_Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (41, 49, 64)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      White_Space => Set (WS_Nowrap),
      Text_Overflow => Set (Overflow_Clip),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for status::label
   Status_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (83, 97, 120)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Overflow => Set (Overflow_Clip),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for listbox
   Listbox_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (247, 249, 252)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (213, 221, 231))),
      Border_Radius => Set (Radius (Px (8.0))),
      Height => Set (Size (Px (500.0))),
      Flex_Grow => Set (1.0),
      others => <>
   );

   --  Base style for listbox::knob
   Listbox_Knob_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (71, 85, 105, 0.78)),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.26, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for listbox::knob when part State_Hovered
   Listbox_Knob_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (71, 85, 105, 0.94)),
      others => <>
   );

   --  Style for listbox::knob when part State_Pressed
   Listbox_Knob_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (71, 85, 105, 1.0)),
      others => <>
   );

   --  Base style for listbox::scroll
   Listbox_Scroll_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0))),
      Padding => Set (CSS_Box (Px (2.0))),
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.22)),
      Border_Radius => Set (Radius (Px (6.0))),
      Transition => Set ((Duration => 0.26, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      others => <>
   );

   --  Style for listbox::scroll when part State_Hovered
   Listbox_Scroll_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.38)),
      others => <>
   );

   --  Style for listbox::scroll when part State_Pressed
   Listbox_Scroll_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.52)),
      others => <>
   );

   --  Base style for label-row
   Label_Row_Base_Style : constant Style_Rules := (
      Padding => Set (CSS_Box (Px (8.0), Px (10.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (220, 228, 236))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Style for label-row when widget State_Selected
   Label_Row_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (62, 118, 210)),
      Border_Color => Set (Border_Color (RGB (48, 95, 171))),
      others => <>
   );

   --  Base style for label-row::label
   Label_Row_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (43, 52, 67)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Style for label-row::label when widget State_Selected
   Label_Row_Label_Widget_Selected_Style : constant Style_Rules := (
      Color => Set (C (White)),
      others => <>
   );

   --  Base style for card-row
   Card_Row_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0))),
      Background_Color => Set_Bg (RGB (63, 115, 176)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (28, 33, 45))),
      Border_Radius => Set (Radius (Px (8.0))),
      Height => Set (Size (Px (44.0))),
      others => <>
   );

   --  Style for card-row when widget State_Selected
   Card_Row_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (244, 166, 77)),
      Border_Color => Set (Border_Color (RGB (190, 120, 35))),
      others => <>
   );

   --  Base style for card-row-title::label
   Card_Row_Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
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

   --  Complete widget style for panels
   Panels_Widget : constant Widget_Style :=
     From (Panels_Base_Style)
     .Build;

   --  Part styles bundle for panels
   Panels_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Panels_Widget, Enabled => True),
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

   --  Complete widget style for panel-title::label
   Panel_Title_Label_Widget : constant Widget_Style :=
     From (Panel_Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for panel-title
   Panel_Title_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Panel_Title_Label_Widget, Enabled => True),
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

   --  Complete widget style for listbox
   Listbox_Widget : constant Widget_Style :=
     From (Listbox_Base_Style)
     .Build;

   --  Complete widget style for listbox::knob
   Listbox_Knob_Widget : constant Widget_Style :=
     From (Listbox_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Listbox_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Listbox_Knob_Part_Pressed_Style)
     .Build;

   --  Complete widget style for listbox::scroll
   Listbox_Scroll_Widget : constant Widget_Style :=
     From (Listbox_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Listbox_Scroll_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Listbox_Scroll_Part_Pressed_Style)
     .Build;

   --  Part styles bundle for listbox
   Listbox_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Listbox_Widget, Enabled => True),
      Knob_Part => (Style => Listbox_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Listbox_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for label-row
   Label_Row_Widget : constant Widget_Style :=
     From (Label_Row_Base_Style)
     .On (When_State (State_Selected), Label_Row_Widget_Selected_Style)
     .Build;

   --  Complete widget style for label-row::label
   Label_Row_Label_Widget : constant Widget_Style :=
     From (Label_Row_Label_Base_Style)
     .On (When_State (State_Selected), Label_Row_Label_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for label-row
   Label_Row_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Label_Row_Widget, Enabled => True),
      Label_Part => (Style => Label_Row_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for card-row
   Card_Row_Widget : constant Widget_Style :=
     From (Card_Row_Base_Style)
     .On (When_State (State_Selected), Card_Row_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for card-row
   Card_Row_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Card_Row_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for card-row-title::label
   Card_Row_Title_Label_Widget : constant Widget_Style :=
     From (Card_Row_Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for card-row-title
   Card_Row_Title_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Card_Row_Title_Label_Widget, Enabled => True),
      others => <>
   ];

end List_Box_Example_Styles;