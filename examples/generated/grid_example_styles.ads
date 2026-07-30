--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Grid_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   function Root_Part_Styles return Part_Style_Array is (Empty_Part_Styles);

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Root_Part_Styles,
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);
   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (17, 24, 39)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'hint'
   function Hint_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'hint'::label
   function Hint_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (191, 204, 224)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Base style for class 'grid'
   function Grid_Class_Base_Style return Style_Rules is
     (
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
      others => <>);

   --  Base style for class 'tile'
   function Tile_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Min_Height => Set (Size (Px (68.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'tile'::label
   function Tile_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (15.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>);

   --  Base style for class 'tile-a'
   function Tile_A_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (2)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      others => <>);

   --  Base style for class 'tile-b'
   function Tile_B_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (3)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Grid_Row_Span => Set (Grid_Row_Span_Value (2)),
      Background_Color => Set_Bg (RGB (16, 185, 129)),
      others => <>);

   --  Base style for class 'tile-c'
   function Tile_C_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (1)),
      Background_Color => Set_Bg (RGB (245, 158, 11)),
      others => <>);

   --  Base style for class 'tile-d'
   function Tile_D_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Grid_Row_Span => Set (Grid_Row_Span_Value (2)),
      Background_Color => Set_Bg (RGB (239, 68, 68)),
      others => <>);

   --  Base style for class 'tile-e'
   function Tile_E_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Background_Color => Set_Bg (RGB (168, 85, 247)),
      others => <>);

   --  Base style for class 'tile-f'
   function Tile_F_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (4)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Background_Color => Set_Bg (RGB (6, 182, 212)),
      others => <>);

   --  Base style for class 'tile-g'
   function Tile_G_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (2)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (3)),
      Grid_Row => Set (Grid_Row_Value (3)),
      Background_Color => Set_Bg (RGB (99, 102, 241)),
      others => <>);

   --  Base style for class 'track-grid'
   function Track_Grid_Class_Base_Style return Style_Rules is
     (
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
      others => <>);

   --  Base style for class 'tr-cell'
   function Tr_Cell_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Min_Height => Set (Size (Px (36.0))),
      Padding => Set (CSS_Box (Px (6.0), Px (14.0), Px (6.0), Px (14.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'tr-cell'::label
   function Tr_Cell_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (226, 232, 240)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Base style for class 'tr-name'
   function Tr_Name_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      others => <>);

   --  Base style for class 'tr-val'
   function Tr_Val_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (6, 78, 59)),
      others => <>);

   --  Base style for class 'tr-unit'
   function Tr_Unit_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (92, 46, 5)),
      others => <>);

   --  Base style for class 'tr-desc'
   function Tr_Desc_Class_Base_Style return Style_Rules is
     (
      Justify_Content => Set (Flex_Start),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (51, 65, 85))),
      others => <>);

   --  Base style for class 'columns'
   function Columns_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (16.0))),
      others => <>);

   --  Base style for class 'column'
   function Column_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Flex_Basis => Set (Basis (Px (0.0))),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'mix-grid'
   function Mix_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Px, 120.0), 2 => (Track_Fr, 2.0), 3 => (Track_Fr, 0.5), 4 => (Track_Auto, 0.0), others => <>]),
      Grid_Rows => Set (Grid_Rows_Value (2)),
      Gap => Set (Gap (Px (4.0), Px (14.0))),
      Background_Color => Set_Bg (RGB (15, 23, 42)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'mx-fixed'
   function Mx_Fixed_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      others => <>);

   --  Base style for class 'mx-wide'
   function Mx_Wide_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (6, 78, 59)),
      others => <>);

   --  Base style for class 'mx-narrow'
   function Mx_Narrow_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (92, 46, 5)),
      others => <>);

   --  Base style for class 'mx-auto'
   function Mx_Auto_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (76, 29, 78)),
      others => <>);

   --  Base style for class 'mx-implicit'
   function Mx_Implicit_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (4)),
      Grid_Row => Set (Grid_Row_Value (3)),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (51, 65, 85))),
      others => <>);

   --  Base style for class 'nested-host'
   function Nested_Host_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (1)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (2)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (4.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (4.0), Px (4.0), Px (4.0), Px (4.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (51, 65, 85))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'nested-cell'
   function Nested_Cell_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (51, 65, 85)),
      others => <>);

   --  Base style for class 'mx-note'
   function Mx_Note_Class_Base_Style return Style_Rules is
     (
      Grid_Column => Set (Grid_Column_Value (3)),
      Grid_Column_Span => Set (Grid_Column_Span_Value (2)),
      Grid_Row => Set (Grid_Row_Value (2)),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (51, 65, 85))),
      others => <>);

   --  Base style for class 'scroll-grid'
   function Scroll_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (2)),
      Grid_Column_Tracks => (Count => 2, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (6.0))),
      Height => Set (Size (Px (150.0))),
      Background_Color => Set_Bg (RGB (15, 23, 42)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (10.0))),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'scroll-grid'::knob
   function Scroll_Grid_Class_Knob_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (100, 116, 139)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'scroll-grid'::scroll
   function Scroll_Grid_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (8.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'sc-cell'
   function Sc_Cell_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (30, 58, 138)),
      others => <>);

   --  Complete widget style for class 'root'
   function Root_Class_Widget return Widget_Style is
     (From (Root_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'root'
   function Root_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'
   function Title_Class_Widget return Widget_Style is
     (From (Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'hint'
   function Hint_Class_Widget return Widget_Style is
     (From (Hint_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'hint'::label
   function Hint_Class_Label_Widget return Widget_Style is
     (From (Hint_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'hint'
   function Hint_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grid'
   function Grid_Class_Widget return Widget_Style is
     (From (Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grid'
   function Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile'
   function Tile_Class_Widget return Widget_Style is
     (From (Tile_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'tile'::label
   function Tile_Class_Label_Widget return Widget_Style is
     (From (Tile_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile'
   function Tile_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_Class_Widget, Enabled => True),
      Label_Part => (Style => Tile_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile-a'
   function Tile_A_Class_Widget return Widget_Style is
     (From (Tile_A_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile-a'
   function Tile_A_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_A_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile-b'
   function Tile_B_Class_Widget return Widget_Style is
     (From (Tile_B_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile-b'
   function Tile_B_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_B_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile-c'
   function Tile_C_Class_Widget return Widget_Style is
     (From (Tile_C_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile-c'
   function Tile_C_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_C_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile-d'
   function Tile_D_Class_Widget return Widget_Style is
     (From (Tile_D_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile-d'
   function Tile_D_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_D_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile-e'
   function Tile_E_Class_Widget return Widget_Style is
     (From (Tile_E_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile-e'
   function Tile_E_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_E_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile-f'
   function Tile_F_Class_Widget return Widget_Style is
     (From (Tile_F_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile-f'
   function Tile_F_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_F_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile-g'
   function Tile_G_Class_Widget return Widget_Style is
     (From (Tile_G_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile-g'
   function Tile_G_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_G_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'track-grid'
   function Track_Grid_Class_Widget return Widget_Style is
     (From (Track_Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'track-grid'
   function Track_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Track_Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tr-cell'
   function Tr_Cell_Class_Widget return Widget_Style is
     (From (Tr_Cell_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'tr-cell'::label
   function Tr_Cell_Class_Label_Widget return Widget_Style is
     (From (Tr_Cell_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'tr-cell'
   function Tr_Cell_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tr_Cell_Class_Widget, Enabled => True),
      Label_Part => (Style => Tr_Cell_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tr-name'
   function Tr_Name_Class_Widget return Widget_Style is
     (From (Tr_Name_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tr-name'
   function Tr_Name_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tr_Name_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tr-val'
   function Tr_Val_Class_Widget return Widget_Style is
     (From (Tr_Val_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tr-val'
   function Tr_Val_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tr_Val_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tr-unit'
   function Tr_Unit_Class_Widget return Widget_Style is
     (From (Tr_Unit_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tr-unit'
   function Tr_Unit_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tr_Unit_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tr-desc'
   function Tr_Desc_Class_Widget return Widget_Style is
     (From (Tr_Desc_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tr-desc'
   function Tr_Desc_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tr_Desc_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'columns'
   function Columns_Class_Widget return Widget_Style is
     (From (Columns_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'columns'
   function Columns_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Columns_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'column'
   function Column_Class_Widget return Widget_Style is
     (From (Column_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'column'
   function Column_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Column_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'mix-grid'
   function Mix_Grid_Class_Widget return Widget_Style is
     (From (Mix_Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'mix-grid'
   function Mix_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Mix_Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'mx-fixed'
   function Mx_Fixed_Class_Widget return Widget_Style is
     (From (Mx_Fixed_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'mx-fixed'
   function Mx_Fixed_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Mx_Fixed_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'mx-wide'
   function Mx_Wide_Class_Widget return Widget_Style is
     (From (Mx_Wide_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'mx-wide'
   function Mx_Wide_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Mx_Wide_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'mx-narrow'
   function Mx_Narrow_Class_Widget return Widget_Style is
     (From (Mx_Narrow_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'mx-narrow'
   function Mx_Narrow_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Mx_Narrow_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'mx-auto'
   function Mx_Auto_Class_Widget return Widget_Style is
     (From (Mx_Auto_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'mx-auto'
   function Mx_Auto_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Mx_Auto_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'mx-implicit'
   function Mx_Implicit_Class_Widget return Widget_Style is
     (From (Mx_Implicit_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'mx-implicit'
   function Mx_Implicit_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Mx_Implicit_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'nested-host'
   function Nested_Host_Class_Widget return Widget_Style is
     (From (Nested_Host_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'nested-host'
   function Nested_Host_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Nested_Host_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'nested-cell'
   function Nested_Cell_Class_Widget return Widget_Style is
     (From (Nested_Cell_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'nested-cell'
   function Nested_Cell_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Nested_Cell_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'mx-note'
   function Mx_Note_Class_Widget return Widget_Style is
     (From (Mx_Note_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'mx-note'
   function Mx_Note_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Mx_Note_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'scroll-grid'
   function Scroll_Grid_Class_Widget return Widget_Style is
     (From (Scroll_Grid_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'scroll-grid'::knob
   function Scroll_Grid_Class_Knob_Widget return Widget_Style is
     (From (Scroll_Grid_Class_Knob_Base_Style)
     .Build);

   --  Complete widget style for class 'scroll-grid'::scroll
   function Scroll_Grid_Class_Scroll_Widget return Widget_Style is
     (From (Scroll_Grid_Class_Scroll_Base_Style)
     .Build);

   --  Part styles bundle for class 'scroll-grid'
   function Scroll_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Scroll_Grid_Class_Widget, Enabled => True),
      Knob_Part => (Style => Scroll_Grid_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Scroll_Grid_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'sc-cell'
   function Sc_Cell_Class_Widget return Widget_Style is
     (From (Sc_Cell_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'sc-cell'
   function Sc_Cell_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Sc_Cell_Class_Widget, Enabled => True),
      others => <>
   ]);

end Grid_Example_Styles;