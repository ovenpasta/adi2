--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Stack_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 30, 36)),
      others => <>
   );

   --  Base style for class 'tab-bar'
   Tab_Bar_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (0.0), Px (16.0))),
      others => <>
   );

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

   --  Base style for class 'stack'
   Stack_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      others => <>
   );

   --  Base style for class 'page-red'
   Page_Red_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (127, 29, 29)),
      Border_Radius => Set (Radius (Px (12.0))),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      others => <>
   );

   --  Base style for class 'page-green'
   Page_Green_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (20, 83, 45)),
      Border_Radius => Set (Radius (Px (12.0))),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      others => <>
   );

   --  Base style for class 'page-blue'
   Page_Blue_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      Border_Radius => Set (Radius (Px (12.0))),
      Gap => Set (Gap (Px (8.0))),
      Padding => Set (CSS_Box (Px (30.0), Px (30.0), Px (30.0), Px (30.0))),
      others => <>
   );

   --  Base style for class 'page-title'
   Page_Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'page-title'::label
   Page_Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'page-desc'
   Page_Desc_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      others => <>
   );

   --  Base style for class 'page-desc'::label
   Page_Desc_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGBA (255, 255, 255, 0.7)),
      Font_Size => Set_Font (Px (16.0)),
      Font_Weight => Set (Weight_Normal),
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

   --  Complete widget style for class 'tab-bar'
   Tab_Bar_Class_Widget : constant Widget_Style :=
     From (Tab_Bar_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tab-bar'
   Tab_Bar_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

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

   --  Complete widget style for class 'stack'
   Stack_Class_Widget : constant Widget_Style :=
     From (Stack_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'stack'
   Stack_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Stack_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-red'
   Page_Red_Class_Widget : constant Widget_Style :=
     From (Page_Red_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-red'
   Page_Red_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Red_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-green'
   Page_Green_Class_Widget : constant Widget_Style :=
     From (Page_Green_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-green'
   Page_Green_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Green_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-blue'
   Page_Blue_Class_Widget : constant Widget_Style :=
     From (Page_Blue_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-blue'
   Page_Blue_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Blue_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-title'
   Page_Title_Class_Widget : constant Widget_Style :=
     From (Page_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'page-title'::label
   Page_Title_Class_Label_Widget : constant Widget_Style :=
     From (Page_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-title'
   Page_Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Page_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-desc'
   Page_Desc_Class_Widget : constant Widget_Style :=
     From (Page_Desc_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'page-desc'::label
   Page_Desc_Class_Label_Widget : constant Widget_Style :=
     From (Page_Desc_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-desc'
   Page_Desc_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Desc_Class_Widget, Enabled => True),
      Label_Part => (Style => Page_Desc_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Stack_Example_Styles;