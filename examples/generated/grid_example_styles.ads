--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Grid_Example_Styles is

   --  Base style for root
   Root_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (12.0))),
      Padding => Set (CSS_Box (Px (20.0))),
      Background_Color => Set_Bg (RGB (17, 24, 39)),
      others => <>
   );

   --  Base style for title::label
   Title_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for hint::label
   Hint_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (191, 204, 224)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>
   );

   --  Base style for grid
   Grid_Base_Style : constant Style_Rules := (
      Display => Set (Grid),
      Flex_Grow => Set (1.0),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Rows => Set (Grid_Rows_Value (3)),
      Gap => Set (Gap (Px (10.0))),
      Padding => Set (CSS_Box (Px (10.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>
   );

   --  Base style for tile
   Tile_Base_Style : constant Style_Rules := (
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

   --  Base style for tile::label
   Tile_Label_Base_Style : constant Style_Rules := (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (15.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>
   );

   --  Base style for tile-a
   Tile_A_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (2)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      others => <>
   );

   --  Base style for tile-b
   Tile_B_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (3)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Grid_Row_Span => Set (Grid_Row_Span_Value (2)),
      Background_Color => Set_Bg (RGB (16, 185, 129)),
      others => <>
   );

   --  Base style for tile-c
   Tile_C_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Background_Color => Set_Bg (RGB (245, 158, 11)),
      others => <>
   );

   --  Base style for tile-d
   Tile_D_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Grid_Row_Span => Set (Grid_Row_Span_Value (2)),
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      others => <>
   );

   --  Base style for tile-e
   Tile_E_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Background_Color => Set_Bg (RGB (168, 85, 247)),
      others => <>
   );

   --  Base style for tile-f
   Tile_F_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Background_Color => Set_Bg (RGB (6, 182, 212)),
      others => <>
   );

   --  Base style for tile-g
   Tile_G_Base_Style : constant Style_Rules := (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (3)),
      Grid_Row => Set (Grid_Row_Value (3)),
      Background_Color => Set_Bg (RGB (99, 102, 241)),
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

   --  Complete widget style for grid
   Grid_Widget : constant Widget_Style :=
     From (Grid_Base_Style)
     .Build;

   --  Part styles bundle for grid
   Grid_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Grid_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile
   Tile_Widget : constant Widget_Style :=
     From (Tile_Base_Style)
     .Build;

   --  Complete widget style for tile::label
   Tile_Label_Widget : constant Widget_Style :=
     From (Tile_Label_Base_Style)
     .Build;

   --  Part styles bundle for tile
   Tile_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_Widget, Enabled => True),
      Label_Part => (Style => Tile_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile-a
   Tile_A_Widget : constant Widget_Style :=
     From (Tile_A_Base_Style)
     .Build;

   --  Part styles bundle for tile-a
   Tile_A_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_A_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile-b
   Tile_B_Widget : constant Widget_Style :=
     From (Tile_B_Base_Style)
     .Build;

   --  Part styles bundle for tile-b
   Tile_B_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_B_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile-c
   Tile_C_Widget : constant Widget_Style :=
     From (Tile_C_Base_Style)
     .Build;

   --  Part styles bundle for tile-c
   Tile_C_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_C_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile-d
   Tile_D_Widget : constant Widget_Style :=
     From (Tile_D_Base_Style)
     .Build;

   --  Part styles bundle for tile-d
   Tile_D_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_D_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile-e
   Tile_E_Widget : constant Widget_Style :=
     From (Tile_E_Base_Style)
     .Build;

   --  Part styles bundle for tile-e
   Tile_E_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_E_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile-f
   Tile_F_Widget : constant Widget_Style :=
     From (Tile_F_Base_Style)
     .Build;

   --  Part styles bundle for tile-f
   Tile_F_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_F_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for tile-g
   Tile_G_Widget : constant Widget_Style :=
     From (Tile_G_Base_Style)
     .Build;

   --  Part styles bundle for tile-g
   Tile_G_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tile_G_Widget, Enabled => True),
      others => <>
   ];

end Grid_Example_Styles;