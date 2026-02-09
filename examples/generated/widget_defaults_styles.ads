--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Widget_Defaults_Styles is

   --  Base style for button
   Button_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Min_Height => Set (Size (Px (34.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (14.0))),
      Background_Color => Set_Bg (RGB (240, 244, 249)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (181, 191, 205))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Style for button when widget State_Hovered
   Button_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (228, 235, 244)),
      Border_Color => Set (Border_Color (RGB (150, 164, 183))),
      others => <>
   );

   --  Style for button when widget State_Pressed
   Button_Widget_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (214, 223, 235)),
      others => <>
   );

   --  Style for button when widget State_Focused
   Button_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      others => <>
   );

   --  Style for button when widget State_Disabled
   Button_Widget_Disabled_Style : constant Style_Rules := (
      Opacity => Set (0.6),
      others => <>
   );

   --  Base style for button::label
   Button_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (30, 41, 59)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for text-input
   Text_Input_Base_Style : constant Style_Rules := (
      Min_Height => Set (Size (Px (38.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (186, 198, 212))),
      Border_Radius => Set (Radius (Px (7.0))),
      others => <>
   );

   --  Style for text-input when widget State_Focused
   Text_Input_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      others => <>
   );

   --  Base style for text-input::cursor
   Text_Input_Cursor_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Width => Set (Size (Px (1.0))),
      others => <>
   );

   --  Base style for text-input::label
   Text_Input_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for text-input::selected
   Text_Input_Selected_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (59, 130, 246, 0.22)),
      others => <>
   );

   --  Base style for list-box
   List_Box_Base_Style : constant Style_Rules := (
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (198, 208, 220))),
      Border_Radius => Set (Radius (Px (8.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      others => <>
   );

   --  Base style for list-box::knob
   List_Box_Knob_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (71, 85, 105, 0.85)),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Base style for list-box::scroll
   List_Box_Scroll_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (10.0))),
      Margin => Set (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0))),
      Padding => Set (CSS_Box (Px (2.0))),
      Background_Color => Set_Bg (RGBA (148, 163, 184, 0.22)),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Base style for list-row
   List_Row_Base_Style : constant Style_Rules := (
      Padding => Set (CSS_Box (Px (8.0), Px (10.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Border_Width => Set (Border_Width (Px (1.0), Px (0.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (222, 229, 238))),
      others => <>
   );

   --  Style for list-row when widget State_Hovered
   List_Row_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (239, 246, 255)),
      others => <>
   );

   --  Style for list-row when widget State_Selected
   List_Row_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      others => <>
   );

   --  Base style for list-row::label
   List_Row_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (30, 41, 59)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Style for list-row::label when widget State_Selected
   List_Row_Label_Widget_Selected_Style : constant Style_Rules := (
      Color => Set (RGB (255, 255, 255)),
      others => <>
   );

   --  Complete widget style for button
   Button_Widget : constant Widget_Style :=
     From (Button_Base_Style)
     .On (When_State (State_Hovered), Button_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Button_Widget_Pressed_Style)
     .On (When_State (State_Focused), Button_Widget_Focused_Style)
     .On (When_State (State_Disabled), Button_Widget_Disabled_Style)
     .Build;

   --  Complete widget style for button::label
   Button_Label_Widget : constant Widget_Style :=
     From (Button_Label_Base_Style)
     .Build;

   --  Part styles bundle for button
   Button_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Button_Widget, Enabled => True),
      Label_Part => (Style => Button_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for text-input
   Text_Input_Widget : constant Widget_Style :=
     From (Text_Input_Base_Style)
     .On (When_State (State_Focused), Text_Input_Widget_Focused_Style)
     .Build;

   --  Complete widget style for text-input::cursor
   Text_Input_Cursor_Widget : constant Widget_Style :=
     From (Text_Input_Cursor_Base_Style)
     .Build;

   --  Complete widget style for text-input::label
   Text_Input_Label_Widget : constant Widget_Style :=
     From (Text_Input_Label_Base_Style)
     .Build;

   --  Complete widget style for text-input::selected
   Text_Input_Selected_Widget : constant Widget_Style :=
     From (Text_Input_Selected_Base_Style)
     .Build;

   --  Part styles bundle for text-input
   Text_Input_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Text_Input_Widget, Enabled => True),
      Cursor_Part => (Style => Text_Input_Cursor_Widget, Enabled => True),
      Label_Part => (Style => Text_Input_Label_Widget, Enabled => True),
      Selected_Part => (Style => Text_Input_Selected_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for list-box
   List_Box_Widget : constant Widget_Style :=
     From (List_Box_Base_Style)
     .Build;

   --  Complete widget style for list-box::knob
   List_Box_Knob_Widget : constant Widget_Style :=
     From (List_Box_Knob_Base_Style)
     .Build;

   --  Complete widget style for list-box::scroll
   List_Box_Scroll_Widget : constant Widget_Style :=
     From (List_Box_Scroll_Base_Style)
     .Build;

   --  Part styles bundle for list-box
   List_Box_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => List_Box_Widget, Enabled => True),
      Knob_Part => (Style => List_Box_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => List_Box_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for list-row
   List_Row_Widget : constant Widget_Style :=
     From (List_Row_Base_Style)
     .On (When_State (State_Hovered), List_Row_Widget_Hovered_Style)
     .On (When_State (State_Selected), List_Row_Widget_Selected_Style)
     .Build;

   --  Complete widget style for list-row::label
   List_Row_Label_Widget : constant Widget_Style :=
     From (List_Row_Label_Base_Style)
     .On (When_State (State_Selected), List_Row_Label_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for list-row
   List_Row_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => List_Row_Widget, Enabled => True),
      Label_Part => (Style => List_Row_Label_Widget, Enabled => True),
      others => <>
   ];

end Widget_Defaults_Styles;