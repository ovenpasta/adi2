--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Generated_Styles is

   --  Base style for button
   Button_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (0, 102, 204)),
      Color => Set (C (White)),
      Padding => Set (Box (Px (12.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (0, 102, 204))),
      others => <>
   );

   --  Style for button when State_Hovered
   Button_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (0, 136, 255)),
      others => <>
   );

   --  Style for button when State_Hovered, State_Focused
   Button_Hovered_Focused_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (0, 170, 255)),
      Border_Color => Set (Border_Color (C (Yellow))),
      others => <>
   );

   --  Style for button when State_Pressed
   Button_Pressed_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (0, 68, 153)),
      others => <>
   );

   --  Style for button when State_Disabled
   Button_Disabled_Style : constant Style_Rules := (
      Background_Color => Set_Bg (C (Gray)),
      Color => Set (C (Dark_Gray)),
      others => <>
   );

   --  Style for button when State_Hovered, not State_Disabled
   Button_Hovered_Not_Disabled_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (0, 119, 238)),
      others => <>
   );

   --  Base style for card
   Card_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (C (White)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (C (Light_Gray))),
      Border_Radius => Set (Radius (Px (8.0))),
      Padding => Set (Box (Px (16.0))),
      others => <>
   );

   --  Style for card when State_Hovered
   Card_Hovered_Style : constant Style_Rules := (
      Border_Color => Set (Border_Color (C (Blue))),
      others => <>
   );

   --  Style for card when State_Selected
   Card_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (240, 248, 255)),
      Border_Width => Set (Border_Width (Px (2.0))),
      others => <>
   );

   --  Complete widget style for button
   Button_Widget : constant Widget_Style :=
     From (Button_Base_Style)
     .On (When_State (State_Hovered), Button_Hovered_Style)
     .On (When_State (State_Hovered) and When_State (State_Focused), Button_Hovered_Focused_Style)
     .On (When_State (State_Pressed), Button_Pressed_Style)
     .On (When_State (State_Disabled), Button_Disabled_Style)
     .On (When_State (State_Hovered) and When_Not (State_Disabled), Button_Hovered_Not_Disabled_Style)
     .Build;

   --  Complete widget style for card
   Card_Widget : constant Widget_Style :=
     From (Card_Base_Style)
     .On (When_State (State_Hovered), Card_Hovered_Style)
     .On (When_State (State_Selected), Card_Selected_Style)
     .Build;

end Generated_Styles;