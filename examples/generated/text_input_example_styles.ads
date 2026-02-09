--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Text_Input_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Padding => Set (CSS_Box (Px (24.0))),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (20, 24, 31)),
      others => <>
   );

   --  Base style for container
   Container_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (24.0))),
      Background_Color => Set_Bg (RGB (31, 41, 55)),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for title::label
   Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for hint::label
   Hint_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (191, 219, 254)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for echo-label::label
   Echo_Label_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (165, 243, 252)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for length-label::label
   Length_Label_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>
   );

   --  Base style for input
   Input_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (42.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (12.0))),
      Cursor => Set (Cursor_Text),
      Background_Color => Set_Bg (C (White)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (191, 219, 254))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0))),
      Box_Shadow => Set (No_Shadow),
      others => <>
   );

   --  Style for input when State_Focused
   Input_Focused_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (10.0), Px (2.0), RGBA (59, 130, 246, 0.35))),
      others => <>
   );

   --  Base style for input::cursor
   Input_Cursor_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      others => <>
   );

   --  Base style for input::label
   Input_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for input::selected
   Input_Selected_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (191, 219, 254, 0.85)),
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

   --  Complete widget style for title::label
   Title_Label_Widget : constant Widget_Style :=
     From (Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for title
   Title_Part_Styles : constant Part_Style_Array := (
      Label_Part => (Style => Title_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for hint::label
   Hint_Label_Widget : constant Widget_Style :=
     From (Hint_Label_Base_Style)
     .Build;

   --  Part styles bundle for hint
   Hint_Part_Styles : constant Part_Style_Array := (
      Label_Part => (Style => Hint_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for echo-label::label
   Echo_Label_Label_Widget : constant Widget_Style :=
     From (Echo_Label_Label_Base_Style)
     .Build;

   --  Part styles bundle for echo-label
   Echo_Label_Part_Styles : constant Part_Style_Array := (
      Label_Part => (Style => Echo_Label_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for length-label::label
   Length_Label_Label_Widget : constant Widget_Style :=
     From (Length_Label_Label_Base_Style)
     .Build;

   --  Part styles bundle for length-label
   Length_Label_Part_Styles : constant Part_Style_Array := (
      Label_Part => (Style => Length_Label_Label_Widget, Enabled => True),
      others => <>
   );

   --  Complete widget style for input
   Input_Widget : constant Widget_Style :=
     From (Input_Base_Style)
     .On (When_State (State_Focused), Input_Focused_Style)
     .Build;

   --  Complete widget style for input::cursor
   Input_Cursor_Widget : constant Widget_Style :=
     From (Input_Cursor_Base_Style)
     .Build;

   --  Complete widget style for input::label
   Input_Label_Widget : constant Widget_Style :=
     From (Input_Label_Base_Style)
     .Build;

   --  Complete widget style for input::selected
   Input_Selected_Widget : constant Widget_Style :=
     From (Input_Selected_Base_Style)
     .Build;

   --  Part styles bundle for input
   Input_Part_Styles : constant Part_Style_Array := (
      Main_Part => (Style => Input_Widget, Enabled => True),
      Cursor_Part => (Style => Input_Cursor_Widget, Enabled => True),
      Label_Part => (Style => Input_Label_Widget, Enabled => True),
      Selected_Part => (Style => Input_Selected_Widget, Enabled => True),
      others => <>
   );

end Text_Input_Example_Styles;