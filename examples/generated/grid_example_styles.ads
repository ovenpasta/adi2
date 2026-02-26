--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Grid_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (12.0))),
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
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'hint'
   Hint_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'hint'::label
   Hint_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (191, 204, 224)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>
   );

   --  Base style for class 'grid'
   Grid_Class_Base_Style : constant Style_Rules := (
      Display => Set (Grid),
      Flex_Grow => Set (1.0),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]),
      Grid_Rows => Set (Grid_Rows_Value (3)),
      Gap => Set (Gap (Px (10.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for class 'tile'
   Tile_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Min_Height => Set (Size (Px (68.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>
   );

   --  Base style for class 'tile'::label
   Tile_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (15.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for class 'tile-a'
   Tile_A_Class_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (2)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      others => <>
   );

   --  Base style for class 'tile-b'
   Tile_B_Class_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (3)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Grid_Row_Span => Set (Grid_Row_Span_Value (2)),
      Background_Color => Set_Bg (RGB (16, 185, 129)),
      others => <>
   );

   --  Base style for class 'tile-c'
   Tile_C_Class_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Background_Color => Set_Bg (RGB (245, 158, 11)),
      others => <>
   );

   --  Base style for class 'tile-d'
   Tile_D_Class_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Grid_Row_Span => Set (Grid_Row_Span_Value (2)),
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      others => <>
   );

   --  Base style for class 'tile-e'
   Tile_E_Class_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Background_Color => Set_Bg (RGB (168, 85, 247)),
      others => <>
   );

   --  Base style for class 'tile-f'
   Tile_F_Class_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Background_Color => Set_Bg (RGB (6, 182, 212)),
      others => <>
   );

   --  Base style for class 'tile-g'
   Tile_G_Class_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (3)),
      Grid_Row => Set (Grid_Row_Value (3)),
      Background_Color => Set_Bg (RGB (99, 102, 241)),
      others => <>
   );

   --  Base style for class 'track-grid'
   Track_Grid_Class_Base_Style : constant Style_Rules := (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Auto, 0.0), 2 => (Track_Auto, 0.0), 3 => (Track_Auto, 0.0), 4 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (6.0))),
      Background_Color => Set_Bg (RGB (15, 23, 42)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for class 'tr-cell'
   Tr_Cell_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Min_Height => Set (Size (Px (36.0))),
      Padding => Set (CSS_Box (Px (6.0), Px (14.0), Px (6.0), Px (14.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>
   );

   --  Base style for class 'tr-cell'::label
   Tr_Cell_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (226, 232, 240)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>
   );

   --  Base style for class 'tr-name'
   Tr_Name_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      others => <>
   );

   --  Base style for class 'tr-val'
   Tr_Val_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (6, 78, 59)),
      others => <>
   );

   --  Base style for class 'tr-unit'
   Tr_Unit_Class_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (92, 46, 5)),
      others => <>
   );

   --  Base style for class 'tr-desc'
   Tr_Desc_Class_Base_Style : constant Style_Rules := (
      Justify_Content => Set (Flex_Start),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (51, 65, 85))),
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

   --  Complete widget style for class 'hint'
   Hint_Class_Widget : constant Widget_Style :=
     From (Hint_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'hint'::label
   Hint_Class_Label_Widget : constant Widget_Style :=
     From (Hint_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'hint'
   Hint_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'grid'
   Grid_Class_Widget : constant Widget_Style :=
     From (Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'grid'
   Grid_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile'
   Tile_Class_Widget : constant Widget_Style :=
     From (Tile_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'tile'::label
   Tile_Class_Label_Widget : constant Widget_Style :=
     From (Tile_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile'
   Tile_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_Class_Widget, Enabled => True),
      Label_Part => (Style => Tile_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile-a'
   Tile_A_Class_Widget : constant Widget_Style :=
     From (Tile_A_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile-a'
   Tile_A_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_A_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile-b'
   Tile_B_Class_Widget : constant Widget_Style :=
     From (Tile_B_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile-b'
   Tile_B_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_B_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile-c'
   Tile_C_Class_Widget : constant Widget_Style :=
     From (Tile_C_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile-c'
   Tile_C_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_C_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile-d'
   Tile_D_Class_Widget : constant Widget_Style :=
     From (Tile_D_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile-d'
   Tile_D_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_D_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile-e'
   Tile_E_Class_Widget : constant Widget_Style :=
     From (Tile_E_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile-e'
   Tile_E_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_E_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile-f'
   Tile_F_Class_Widget : constant Widget_Style :=
     From (Tile_F_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile-f'
   Tile_F_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_F_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tile-g'
   Tile_G_Class_Widget : constant Widget_Style :=
     From (Tile_G_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tile-g'
   Tile_G_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_G_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'track-grid'
   Track_Grid_Class_Widget : constant Widget_Style :=
     From (Track_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'track-grid'
   Track_Grid_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Track_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tr-cell'
   Tr_Cell_Class_Widget : constant Widget_Style :=
     From (Tr_Cell_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'tr-cell'::label
   Tr_Cell_Class_Label_Widget : constant Widget_Style :=
     From (Tr_Cell_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'tr-cell'
   Tr_Cell_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tr_Cell_Class_Widget, Enabled => True),
      Label_Part => (Style => Tr_Cell_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tr-name'
   Tr_Name_Class_Widget : constant Widget_Style :=
     From (Tr_Name_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tr-name'
   Tr_Name_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tr_Name_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tr-val'
   Tr_Val_Class_Widget : constant Widget_Style :=
     From (Tr_Val_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tr-val'
   Tr_Val_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tr_Val_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tr-unit'
   Tr_Unit_Class_Widget : constant Widget_Style :=
     From (Tr_Unit_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tr-unit'
   Tr_Unit_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tr_Unit_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tr-desc'
   Tr_Desc_Class_Widget : constant Widget_Style :=
     From (Tr_Desc_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tr-desc'
   Tr_Desc_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tr_Desc_Class_Widget, Enabled => True),
      others => <>
   ];

end Grid_Example_Styles;