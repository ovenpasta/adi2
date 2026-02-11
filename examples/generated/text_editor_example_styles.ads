--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Text_Editor_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (20, 24, 31)),
      Overflow => Set (Overflow_Hidden),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'title'::label
   Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (20.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for class 'editor'
   Editor_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Cursor => Set (Cursor_Text),
      Background_Color => Set_Bg (RGB (30, 30, 46)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (69, 71, 90))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0))),
      Overflow => Set (Overflow_Auto),
      Box_Shadow => Set (No_Shadow),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      others => <>
   );

   --  Style for class 'editor' when widget State_Focused
   Editor_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (137, 180, 250))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (137, 180, 250, 0.25))),
      others => <>
   );

   --  Base style for class 'editor'::cursor
   Editor_Class_Cursor_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (245, 224, 220)),
      others => <>
   );

   --  Base style for class 'editor'::knob
   Editor_Class_Knob_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (6.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.4)),
      Border_Radius => Set (Radius (Px (3.0))),
      others => <>
   );

   --  Style for class 'editor'::knob when part State_Hovered
   Editor_Class_Knob_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.6)),
      others => <>
   );

   --  Style for class 'editor'::knob when part State_Pressed
   Editor_Class_Knob_Part_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.8)),
      others => <>
   );

   --  Base style for class 'editor'::label
   Editor_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (205, 214, 244)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      White_Space => Set (WS_Normal),
      others => <>
   );

   --  Base style for class 'editor'::scroll
   Editor_Class_Scroll_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (8.0))),
      Background_Color => Set_Bg (RGBA (69, 71, 90, 0.3)),
      Border_Radius => Set (Radius (Px (4.0))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      others => <>
   );

   --  Style for class 'editor'::scroll when part State_Hovered
   Editor_Class_Scroll_Part_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (69, 71, 90, 0.6)),
      others => <>
   );

   --  Base style for class 'editor'::selected
   Editor_Class_Selected_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.3)),
      others => <>
   );

   --  Base style for class 'context-menu'
   Context_Menu_Class_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (200.0))),
      Background_Color => Set_Bg (RGB (24, 24, 37)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (137, 180, 250))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (26.0), Px (0.0), RGBA (0, 0, 0, 0.45))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      others => <>
   );

   --  Base style for class 'context-menu-item'
   Context_Menu_Item_Class_Base_Style : constant Style_Rules := (
      Min_Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGBA (24, 24, 37, 0.0)),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0))),
      others => <>
   );

   --  Style for class 'context-menu-item' when widget State_Hovered
   Context_Menu_Item_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.28)),
      others => <>
   );

   --  Base style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (205, 214, 244)),
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

   --  Complete widget style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     From (Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'editor'
   Editor_Class_Widget : constant Widget_Style :=
     From (Editor_Class_Base_Style)
     .On (When_State (State_Focused), Editor_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'editor'::cursor
   Editor_Class_Cursor_Widget : constant Widget_Style :=
     From (Editor_Class_Cursor_Base_Style)
     .Build;

   --  Complete widget style for class 'editor'::knob
   Editor_Class_Knob_Widget : constant Widget_Style :=
     From (Editor_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Editor_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Editor_Class_Knob_Part_Pressed_Style)
     .Build;

   --  Complete widget style for class 'editor'::label
   Editor_Class_Label_Widget : constant Widget_Style :=
     From (Editor_Class_Label_Base_Style)
     .Build;

   --  Complete widget style for class 'editor'::scroll
   Editor_Class_Scroll_Widget : constant Widget_Style :=
     From (Editor_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Editor_Class_Scroll_Part_Hovered_Style)
     .Build;

   --  Complete widget style for class 'editor'::selected
   Editor_Class_Selected_Widget : constant Widget_Style :=
     From (Editor_Class_Selected_Base_Style)
     .Build;

   --  Part styles bundle for class 'editor'
   Editor_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Editor_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Editor_Class_Cursor_Widget, Enabled => True),
      Knob_Part => (Style => Editor_Class_Knob_Widget, Enabled => True),
      Label_Part => (Style => Editor_Class_Label_Widget, Enabled => True),
      Scroll_Part => (Style => Editor_Class_Scroll_Widget, Enabled => True),
      Selected_Part => (Style => Editor_Class_Selected_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'context-menu'
   Context_Menu_Class_Widget : constant Widget_Style :=
     From (Context_Menu_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'context-menu'
   Context_Menu_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Context_Menu_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'context-menu-item'
   Context_Menu_Item_Class_Widget : constant Widget_Style :=
     From (Context_Menu_Item_Class_Base_Style)
     .On (When_State (State_Hovered), Context_Menu_Item_Class_Widget_Hovered_Style)
     .Build;

   --  Complete widget style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Widget : constant Widget_Style :=
     From (Context_Menu_Item_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'context-menu-item'
   Context_Menu_Item_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Context_Menu_Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Context_Menu_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Text_Editor_Example_Styles;