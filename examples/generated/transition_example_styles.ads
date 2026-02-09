--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Transition_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (24, 24, 30)),
      others => <>
   );

   --  Base style for content
   Content_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (28.0))),
      Padding => Set (CSS_Box (Px (28.0), Px (32.0))),
      others => <>
   );

   --  Base style for section
   Section_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (10.0))),
      others => <>
   );

   --  Base style for section-row
   Section_Row_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (16.0))),
      Align_Items => Set (Flex_Start),
      others => <>
   );

   --  Base style for col-style
   Col_Style_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Center),
      others => <>
   );

   --  Base style for white-label
   White_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for dark-label
   Dark_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (200, 200, 210)),
      Font_Size => Set_Font (Px (11.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for title
   Title_Base_Style : constant Style_Rules := (
      Padding => Set (CSS_Box (Px (0.0), Px (4.0))),
      others => <>
   );

   --  Base style for title::label
   Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (160, 170, 190)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for desc
   Desc_Base_Style : constant Style_Rules := (
      Padding => Set (CSS_Box (Px (2.0), Px (4.0))),
      others => <>
   );

   --  Base style for desc::label
   Desc_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (120, 130, 150)),
      Font_Size => Set_Font (Px (10.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for demo-base
   Demo_Base_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (6.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0))),
      Cursor => Set (Cursor_Pointer),
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

   --  Complete widget style for content
   Content_Widget : constant Widget_Style :=
     From (Content_Base_Style)
     .Build;

   --  Part styles bundle for content
   Content_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Content_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for section
   Section_Widget : constant Widget_Style :=
     From (Section_Base_Style)
     .Build;

   --  Part styles bundle for section
   Section_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Section_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for section-row
   Section_Row_Widget : constant Widget_Style :=
     From (Section_Row_Base_Style)
     .Build;

   --  Part styles bundle for section-row
   Section_Row_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Section_Row_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for col-style
   Col_Style_Widget : constant Widget_Style :=
     From (Col_Style_Base_Style)
     .Build;

   --  Part styles bundle for col-style
   Col_Style_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Col_Style_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for white-label
   White_Label_Widget : constant Widget_Style :=
     From (White_Label_Base_Style)
     .Build;

   --  Part styles bundle for white-label
   White_Label_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => White_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for dark-label
   Dark_Label_Widget : constant Widget_Style :=
     From (Dark_Label_Base_Style)
     .Build;

   --  Part styles bundle for dark-label
   Dark_Label_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Dark_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for title
   Title_Widget : constant Widget_Style :=
     From (Title_Base_Style)
     .Build;

   --  Complete widget style for title::label
   Title_Label_Widget : constant Widget_Style :=
     From (Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for title
   Title_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Title_Widget, Enabled => True),
      Label_Part => (Style => Title_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for desc
   Desc_Widget : constant Widget_Style :=
     From (Desc_Base_Style)
     .Build;

   --  Complete widget style for desc::label
   Desc_Label_Widget : constant Widget_Style :=
     From (Desc_Label_Base_Style)
     .Build;

   --  Part styles bundle for desc
   Desc_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Desc_Widget, Enabled => True),
      Label_Part => (Style => Desc_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for demo-base
   Demo_Base_Widget : constant Widget_Style :=
     From (Demo_Base_Base_Style)
     .Build;

   --  Part styles bundle for demo-base
   Demo_Base_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Demo_Base_Widget, Enabled => True),
      others => <>
   ];

end Transition_Example_Styles;