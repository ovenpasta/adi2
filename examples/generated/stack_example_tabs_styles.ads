--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Stack_Example_Tabs_Styles is

   --  Base style for class 'tab-left'
   Tab_Left_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0), Px (0.0), Px (0.0), Px (8.0))),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0))),
      others => <>
   );

   --  Style for class 'tab-left' when widget State_Hovered
   Tab_Left_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for class 'tab-left' when widget State_Selected
   Tab_Left_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for class 'tab-left'::label
   Tab_Left_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'tab-center'
   Tab_Center_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0))),
      others => <>
   );

   --  Style for class 'tab-center' when widget State_Hovered
   Tab_Center_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for class 'tab-center' when widget State_Selected
   Tab_Center_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for class 'tab-center'::label
   Tab_Center_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for class 'tab-right'
   Tab_Right_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (0.0), Px (8.0), Px (8.0), Px (0.0))),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0))),
      others => <>
   );

   --  Style for class 'tab-right' when widget State_Hovered
   Tab_Right_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for class 'tab-right' when widget State_Selected
   Tab_Right_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for class 'tab-right'::label
   Tab_Right_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Complete widget style for class 'tab-left'
   Tab_Left_Class_Widget : constant Widget_Style :=
     From (Tab_Left_Class_Base_Style)
     .On (When_State (State_Hovered), Tab_Left_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Left_Class_Widget_Selected_Style)
     .Build;

   --  Complete widget style for class 'tab-left'::label
   Tab_Left_Class_Label_Widget : constant Widget_Style :=
     From (Tab_Left_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'tab-left'
   Tab_Left_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Left_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tab-center'
   Tab_Center_Class_Widget : constant Widget_Style :=
     From (Tab_Center_Class_Base_Style)
     .On (When_State (State_Hovered), Tab_Center_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Center_Class_Widget_Selected_Style)
     .Build;

   --  Complete widget style for class 'tab-center'::label
   Tab_Center_Class_Label_Widget : constant Widget_Style :=
     From (Tab_Center_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'tab-center'
   Tab_Center_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Center_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Center_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tab-right'
   Tab_Right_Class_Widget : constant Widget_Style :=
     From (Tab_Right_Class_Base_Style)
     .On (When_State (State_Hovered), Tab_Right_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Right_Class_Widget_Selected_Style)
     .Build;

   --  Complete widget style for class 'tab-right'::label
   Tab_Right_Class_Label_Widget : constant Widget_Style :=
     From (Tab_Right_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'tab-right'
   Tab_Right_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Right_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Stack_Example_Tabs_Styles;