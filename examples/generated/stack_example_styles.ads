--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Stack_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 30, 36)),
      others => <>
   );

   --  Base style for tab-bar
   Tab_Bar_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (0.0), Px (16.0))),
      others => <>
   );

   --  Base style for tab-left
   Tab_Left_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (8.0), Px (0.0), Px (0.0), Px (8.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for tab-left when widget State_Hovered
   Tab_Left_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for tab-left when widget State_Selected
   Tab_Left_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for tab-left::label
   Tab_Left_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for tab-center
   Tab_Center_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for tab-center when widget State_Hovered
   Tab_Center_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for tab-center when widget State_Selected
   Tab_Center_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for tab-center::label
   Tab_Center_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for tab-right
   Tab_Right_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Radius => Set (Radius (Px (0.0), Px (8.0), Px (8.0), Px (0.0))),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0))),
      Cursor => Set (Cursor_Pointer),
      others => <>
   );

   --  Style for tab-right when widget State_Hovered
   Tab_Right_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (75, 85, 99)),
      others => <>
   );

   --  Style for tab-right when widget State_Selected
   Tab_Right_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>
   );

   --  Base style for tab-right::label
   Tab_Right_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Base style for stack
   Stack_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (16.0))),
      others => <>
   );

   --  Base style for page-red
   Page_Red_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (127, 29, 29)),
      Border_Radius => Set (Radius (Px (12.0))),
      Padding => Set (CSS_Box (Px (30.0))),
      Gap => Set (Gap (Px (8.0))),
      others => <>
   );

   --  Base style for page-green
   Page_Green_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (20, 83, 45)),
      Border_Radius => Set (Radius (Px (12.0))),
      Padding => Set (CSS_Box (Px (30.0))),
      Gap => Set (Gap (Px (8.0))),
      others => <>
   );

   --  Base style for page-blue
   Page_Blue_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      Border_Radius => Set (Radius (Px (12.0))),
      Padding => Set (CSS_Box (Px (30.0))),
      Gap => Set (Gap (Px (8.0))),
      others => <>
   );

   --  Base style for page-title
   Page_Title_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for page-title::label
   Page_Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for page-desc
   Page_Desc_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for page-desc::label
   Page_Desc_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGBA (255, 255, 255, 0.7)),
      Font_Size => Set_Font (Px (16.0)),
      Font_Weight => Set (Weight_Normal),
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

   --  Complete widget style for tab-bar
   Tab_Bar_Widget : constant Widget_Style :=
     From (Tab_Bar_Base_Style)
     .Build;

   --  Part styles bundle for tab-bar
   Tab_Bar_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Bar_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tab-left
   Tab_Left_Widget : constant Widget_Style :=
     From (Tab_Left_Base_Style)
     .On (When_State (State_Hovered), Tab_Left_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Left_Widget_Selected_Style)
     .Build;

   --  Complete widget style for tab-left::label
   Tab_Left_Label_Widget : constant Widget_Style :=
     From (Tab_Left_Label_Base_Style)
     .Build;

   --  Part styles bundle for tab-left
   Tab_Left_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Left_Widget, Enabled => True),
      Label_Part => (Style => Tab_Left_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tab-center
   Tab_Center_Widget : constant Widget_Style :=
     From (Tab_Center_Base_Style)
     .On (When_State (State_Hovered), Tab_Center_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Center_Widget_Selected_Style)
     .Build;

   --  Complete widget style for tab-center::label
   Tab_Center_Label_Widget : constant Widget_Style :=
     From (Tab_Center_Label_Base_Style)
     .Build;

   --  Part styles bundle for tab-center
   Tab_Center_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Center_Widget, Enabled => True),
      Label_Part => (Style => Tab_Center_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tab-right
   Tab_Right_Widget : constant Widget_Style :=
     From (Tab_Right_Base_Style)
     .On (When_State (State_Hovered), Tab_Right_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Right_Widget_Selected_Style)
     .Build;

   --  Complete widget style for tab-right::label
   Tab_Right_Label_Widget : constant Widget_Style :=
     From (Tab_Right_Label_Base_Style)
     .Build;

   --  Part styles bundle for tab-right
   Tab_Right_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Right_Widget, Enabled => True),
      Label_Part => (Style => Tab_Right_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for stack
   Stack_Widget : constant Widget_Style :=
     From (Stack_Base_Style)
     .Build;

   --  Part styles bundle for stack
   Stack_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Stack_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for page-red
   Page_Red_Widget : constant Widget_Style :=
     From (Page_Red_Base_Style)
     .Build;

   --  Part styles bundle for page-red
   Page_Red_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Red_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for page-green
   Page_Green_Widget : constant Widget_Style :=
     From (Page_Green_Base_Style)
     .Build;

   --  Part styles bundle for page-green
   Page_Green_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Green_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for page-blue
   Page_Blue_Widget : constant Widget_Style :=
     From (Page_Blue_Base_Style)
     .Build;

   --  Part styles bundle for page-blue
   Page_Blue_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Blue_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for page-title
   Page_Title_Widget : constant Widget_Style :=
     From (Page_Title_Base_Style)
     .Build;

   --  Complete widget style for page-title::label
   Page_Title_Label_Widget : constant Widget_Style :=
     From (Page_Title_Label_Base_Style)
     .Build;

   --  Part styles bundle for page-title
   Page_Title_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Title_Widget, Enabled => True),
      Label_Part => (Style => Page_Title_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for page-desc
   Page_Desc_Widget : constant Widget_Style :=
     From (Page_Desc_Base_Style)
     .Build;

   --  Complete widget style for page-desc::label
   Page_Desc_Label_Widget : constant Widget_Style :=
     From (Page_Desc_Label_Base_Style)
     .Build;

   --  Part styles bundle for page-desc
   Page_Desc_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Desc_Widget, Enabled => True),
      Label_Part => (Style => Page_Desc_Label_Widget, Enabled => True),
      others => <>
   ];

end Stack_Example_Styles;