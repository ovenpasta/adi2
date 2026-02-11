--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Text_Input_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (20, 24, 31)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'container'
   Container_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (31, 41, 55)),
      Border_Radius => Set (Radius (Px (10.0))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>
   );

   --  Base style for class 'title'::label
   Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for class 'hint'::label
   Hint_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (191, 219, 254)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for class 'echo-label'::label
   Echo_Label_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (165, 243, 252)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'length-label'::label
   Length_Label_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>
   );

   --  Base style for class 'input'
   Input_Class_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (42.0))),
      Cursor => Set (Cursor_Text),
      Background_Color => Set_Bg (C (White)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (191, 219, 254))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0))),
      Box_Shadow => Set (No_Shadow),
      Padding => Set (CSS_Box (Px (10.0), Px (12.0), Px (10.0), Px (12.0))),
      others => <>
   );

   --  Style for class 'input' when widget State_Focused
   Input_Class_Widget_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0), RGBA (59, 130, 246, 0.35))),
      others => <>
   );

   --  Base style for class 'input'::cursor
   Input_Class_Cursor_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>
   );

   --  Base style for class 'input'::label
   Input_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'input'::selected
   Input_Class_Selected_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (191, 219, 254, 0.85)),
      others => <>
   );

   --  Base style for class 'context-menu'
   Context_Menu_Class_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (180.0))),
      Background_Color => Set_Bg (RGB (15, 23, 42)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (8.0), Px (24.0), Px (0.0), RGBA (2, 6, 23, 0.45))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      others => <>
   );

   --  Base style for class 'context-menu-item'
   Context_Menu_Item_Class_Base_Style : constant Style_Rules := (
      Min_Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.0)),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0))),
      others => <>
   );

   --  Style for class 'context-menu-item' when widget State_Hovered
   Context_Menu_Item_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (37, 99, 235, 0.35)),
      others => <>
   );

   --  Base style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (219, 234, 254)),
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

   --  Complete widget style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     From (Container_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'hint'::label
   Hint_Class_Label_Widget : constant Widget_Style :=
     From (Hint_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'hint'
   Hint_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'echo-label'::label
   Echo_Label_Class_Label_Widget : constant Widget_Style :=
     From (Echo_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'echo-label'
   Echo_Label_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Echo_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'length-label'::label
   Length_Label_Class_Label_Widget : constant Widget_Style :=
     From (Length_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'length-label'
   Length_Label_Class_Part_Styles : constant Part_Style_Array := [
      Label_Part => (Style => Length_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'input'
   Input_Class_Widget : constant Widget_Style :=
     From (Input_Class_Base_Style)
     .On (When_State (State_Focused), Input_Class_Widget_Focused_Style)
     .Build;

   --  Complete widget style for class 'input'::cursor
   Input_Class_Cursor_Widget : constant Widget_Style :=
     From (Input_Class_Cursor_Base_Style)
     .Build;

   --  Complete widget style for class 'input'::label
   Input_Class_Label_Widget : constant Widget_Style :=
     From (Input_Class_Label_Base_Style)
     .Build;

   --  Complete widget style for class 'input'::selected
   Input_Class_Selected_Widget : constant Widget_Style :=
     From (Input_Class_Selected_Base_Style)
     .Build;

   --  Part styles bundle for class 'input'
   Input_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Input_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Input_Class_Cursor_Widget, Enabled => True),
      Label_Part => (Style => Input_Class_Label_Widget, Enabled => True),
      Selected_Part => (Style => Input_Class_Selected_Widget, Enabled => True),
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

end Text_Input_Example_Styles;