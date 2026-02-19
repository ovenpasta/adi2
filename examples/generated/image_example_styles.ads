--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Image_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (16.0))),
      Background_Color => Set_Bg (RGB (17, 24, 39)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      others => <>
   );

   --  Base style for class 'title'
   Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'title'::label
   Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'subtitle'
   Subtitle_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'subtitle'::label
   Subtitle_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'section-title'
   Section_Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'section-title'::label
   Section_Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (191, 204, 224)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'format-grid'
   Format_Grid_Class_Base_Style : constant Style_Rules := (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Gap => Set (Gap (Px (16.0))),
      Flex_Grow => Set (1.0),
      others => <>
   );

   --  Base style for class 'fit-grid'
   Fit_Grid_Class_Base_Style : constant Style_Rules := (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (5)),
      Gap => Set (Gap (Px (16.0))),
      Flex_Grow => Set (1.0),
      others => <>
   );

   --  Base style for class 'card'
   Card_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      others => <>
   );

   --  Base style for class 'card-label'
   Card_Label_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'card-label'::label
   Card_Label_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>
   );

   --  Base style for class 'image'
   Image_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      others => <>
   );

   --  Base style for class 'image'::icon
   Image_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_Contain),
      others => <>
   );

   --  Base style for class 'fit-fill'::icon
   Fit_Fill_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_Fill),
      others => <>
   );

   --  Base style for class 'fit-contain'::icon
   Fit_Contain_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_Contain),
      others => <>
   );

   --  Base style for class 'fit-cover'::icon
   Fit_Cover_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_Cover),
      others => <>
   );

   --  Base style for class 'fit-none'::icon
   Fit_None_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_None),
      others => <>
   );

   --  Base style for class 'fit-scale-down'::icon
   Fit_Scale_Down_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_Scale_Down),
      others => <>
   );

   --  Base style for class 'tint-grid'
   Tint_Grid_Class_Base_Style : constant Style_Rules := (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Gap => Set (Gap (Px (16.0))),
      Flex_Grow => Set (1.0),
      others => <>
   );

   --  Base style for class 'tint-card'
   Tint_Card_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      others => <>
   );

   --  Base style for class 'tint-icon'
   Tint_Icon_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      others => <>
   );

   --  Base style for class 'tint-icon'::icon
   Tint_Icon_Class_Icon_Base_Style : constant Style_Rules := (
      Object_Fit => Set (Fit_Contain),
      others => <>
   );

   --  Base style for class 'tint-default'::icon
   Tint_Default_Class_Icon_Base_Style : constant Style_Rules := (
      Color => Set (RGB (148, 163, 184)),
      others => <>
   );

   --  Style for class 'tint-default'::icon when widget State_Hovered
   Tint_Default_Class_Icon_Widget_Hovered_Style : constant Style_Rules := (
      Color => Set (RGB (96, 165, 250)),
      others => <>
   );

   --  Base style for class 'tint-warm'::icon
   Tint_Warm_Class_Icon_Base_Style : constant Style_Rules := (
      Color => Set (RGB (251, 191, 36)),
      others => <>
   );

   --  Style for class 'tint-warm'::icon when widget State_Hovered
   Tint_Warm_Class_Icon_Widget_Hovered_Style : constant Style_Rules := (
      Color => Set (RGB (253, 224, 71)),
      others => <>
   );

   --  Base style for class 'tint-success'::icon
   Tint_Success_Class_Icon_Base_Style : constant Style_Rules := (
      Color => Set (RGB (74, 222, 128)),
      others => <>
   );

   --  Style for class 'tint-success'::icon when widget State_Hovered
   Tint_Success_Class_Icon_Widget_Hovered_Style : constant Style_Rules := (
      Color => Set (RGB (134, 239, 172)),
      others => <>
   );

   --  Base style for class 'tint-danger'::icon
   Tint_Danger_Class_Icon_Base_Style : constant Style_Rules := (
      Color => Set (RGB (248, 113, 113)),
      others => <>
   );

   --  Style for class 'tint-danger'::icon when widget State_Hovered
   Tint_Danger_Class_Icon_Widget_Hovered_Style : constant Style_Rules := (
      Color => Set (RGB (252, 165, 165)),
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

   --  Complete widget style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     From (Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     From (Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'subtitle'
   Subtitle_Class_Widget : constant Widget_Style :=
     From (Subtitle_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     From (Subtitle_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'section-title'
   Section_Title_Class_Widget : constant Widget_Style :=
     From (Section_Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'section-title'::label
   Section_Title_Class_Label_Widget : constant Widget_Style :=
     From (Section_Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'section-title'
   Section_Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Section_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Section_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'format-grid'
   Format_Grid_Class_Widget : constant Widget_Style :=
     From (Format_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'format-grid'
   Format_Grid_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Format_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'fit-grid'
   Fit_Grid_Class_Widget : constant Widget_Style :=
     From (Fit_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'fit-grid'
   Fit_Grid_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Fit_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card'
   Card_Class_Widget : constant Widget_Style :=
     From (Card_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'card'
   Card_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Card_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card-label'
   Card_Label_Class_Widget : constant Widget_Style :=
     From (Card_Label_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'card-label'::label
   Card_Label_Class_Label_Widget : constant Widget_Style :=
     From (Card_Label_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'card-label'
   Card_Label_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Card_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'image'
   Image_Class_Widget : constant Widget_Style :=
     From (Image_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'image'::icon
   Image_Class_Icon_Widget : constant Widget_Style :=
     From (Image_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'image'
   Image_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Image_Class_Widget, Enabled => True),
      Icon_Part => (Style => Image_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'fit-fill'::icon
   Fit_Fill_Class_Icon_Widget : constant Widget_Style :=
     From (Fit_Fill_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'fit-fill'
   Fit_Fill_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Fit_Fill_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'fit-contain'::icon
   Fit_Contain_Class_Icon_Widget : constant Widget_Style :=
     From (Fit_Contain_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'fit-contain'
   Fit_Contain_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Fit_Contain_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'fit-cover'::icon
   Fit_Cover_Class_Icon_Widget : constant Widget_Style :=
     From (Fit_Cover_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'fit-cover'
   Fit_Cover_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Fit_Cover_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'fit-none'::icon
   Fit_None_Class_Icon_Widget : constant Widget_Style :=
     From (Fit_None_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'fit-none'
   Fit_None_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Fit_None_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'fit-scale-down'::icon
   Fit_Scale_Down_Class_Icon_Widget : constant Widget_Style :=
     From (Fit_Scale_Down_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'fit-scale-down'
   Fit_Scale_Down_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Fit_Scale_Down_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-grid'
   Tint_Grid_Class_Widget : constant Widget_Style :=
     From (Tint_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tint-grid'
   Tint_Grid_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tint_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-card'
   Tint_Card_Class_Widget : constant Widget_Style :=
     From (Tint_Card_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tint-card'
   Tint_Card_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tint_Card_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-icon'
   Tint_Icon_Class_Widget : constant Widget_Style :=
     From (Tint_Icon_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'tint-icon'::icon
   Tint_Icon_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Icon_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'tint-icon'
   Tint_Icon_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tint_Icon_Class_Widget, Enabled => True),
      Icon_Part => (Style => Tint_Icon_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-default'::icon
   Tint_Default_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Default_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Default_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-default'
   Tint_Default_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Tint_Default_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-warm'::icon
   Tint_Warm_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Warm_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Warm_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-warm'
   Tint_Warm_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Tint_Warm_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-success'::icon
   Tint_Success_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Success_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Success_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-success'
   Tint_Success_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Tint_Success_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-danger'::icon
   Tint_Danger_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Danger_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Danger_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-danger'
   Tint_Danger_Class_Part_Styles : constant Part_Style_Array := [
      Icon_Part => (Style => Tint_Danger_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

end Image_Example_Styles;