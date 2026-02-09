--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Overflow_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (18.0))),
      Background_Color => Set_Bg (RGB (20, 24, 31)),
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
      Color => Set (RGB (189, 205, 230)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>
   );

   --  Base style for panels
   Panels_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (18.0))),
      Align_Items => Set (Stretch),
      Flex_Grow => Set (1.0),
      others => <>
   );

   --  Base style for panel
   Panel_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (10.0))),
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (12.0))),
      Background_Color => Set_Bg (RGB (31, 41, 55)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for panel-title::label
   Panel_Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (224, 231, 255)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for clip-visible
   Clip_Visible_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Overflow => Set (Overflow_Visible),
      Height => Set (Size (Px (170.0))),
      Padding => Set (CSS_Box (Px (10.0))),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGBA (96, 165, 250, 0.16)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (96, 165, 250))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>
   );

   --  Base style for clip-hidden
   Clip_Hidden_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Overflow => Set (Overflow_Hidden),
      Height => Set (Size (Px (170.0))),
      Padding => Set (CSS_Box (Px (10.0))),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGBA (74, 222, 128, 0.16)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (74, 222, 128))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>
   );

   --  Base style for content-stack
   Content_Stack_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      others => <>
   );

   --  Base style for item-a
   Item_A_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (56.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      others => <>
   );

   --  Base style for item-b
   Item_B_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (56.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      Background_Color => Set_Bg (RGB (245, 158, 11)),
      others => <>
   );

   --  Base style for item-c
   Item_C_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (56.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      others => <>
   );

   --  Base style for item-d
   Item_D_Base_Style : constant Style_Rules := (
      Height => Set (Size (Px (56.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      Background_Color => Set_Bg (RGB (16, 185, 129)),
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

   --  Complete widget style for clip-visible
   Clip_Visible_Widget : constant Widget_Style :=
     From (Clip_Visible_Base_Style)
     .Build;

   --  Part styles bundle for clip-visible
   Clip_Visible_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Clip_Visible_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for clip-hidden
   Clip_Hidden_Widget : constant Widget_Style :=
     From (Clip_Hidden_Base_Style)
     .Build;

   --  Part styles bundle for clip-hidden
   Clip_Hidden_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Clip_Hidden_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for content-stack
   Content_Stack_Widget : constant Widget_Style :=
     From (Content_Stack_Base_Style)
     .Build;

   --  Part styles bundle for content-stack
   Content_Stack_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Content_Stack_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for item-a
   Item_A_Widget : constant Widget_Style :=
     From (Item_A_Base_Style)
     .Build;

   --  Part styles bundle for item-a
   Item_A_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Item_A_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for item-b
   Item_B_Widget : constant Widget_Style :=
     From (Item_B_Base_Style)
     .Build;

   --  Part styles bundle for item-b
   Item_B_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Item_B_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for item-c
   Item_C_Widget : constant Widget_Style :=
     From (Item_C_Base_Style)
     .Build;

   --  Part styles bundle for item-c
   Item_C_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Item_C_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for item-d
   Item_D_Widget : constant Widget_Style :=
     From (Item_D_Base_Style)
     .Build;

   --  Part styles bundle for item-d
   Item_D_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Item_D_Widget, Enabled => True),
      others => <>
   ];

end Overflow_Example_Styles;