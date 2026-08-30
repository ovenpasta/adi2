--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Image_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   function Root_Part_Styles return Part_Style_Array is (Empty_Part_Styles);

   function Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
     (
      Has_Root_Style => Has_Root_Styles,
      Root_Styles => Adi.Widget.Intern (Root_Part_Styles),
      Has_Root_Font_Size => Has_Root_Font_Size,
      Root_Font_Size => Root_Font_Size);
   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (16.0))),
      Background_Color => Set_Bg (RGB (17, 24, 39)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'subtitle'
   function Subtitle_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'subtitle'::label
   function Subtitle_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'section-title'
   function Section_Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'section-title'::label
   function Section_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (191, 204, 224)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'format-grid'
   function Format_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (16.0))),
      Flex_Grow => Set (1.0),
      others => <>);

   --  Base style for class 'fit-grid'
   function Fit_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (5)),
      Grid_Column_Tracks => (Count => 5, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), 5 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (16.0))),
      Flex_Grow => Set (0.0),
      Height => Set (Size (Px (96.0))),
      others => <>);

   --  Base style for class 'card'
   function Card_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'card-label'
   function Card_Label_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'card-label'::label
   function Card_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>);

   --  Base style for class 'image'
   function Image_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      others => <>);

   --  Base style for class 'image'::icon
   function Image_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      Object_Position => Set (Object_Position (Pos_Center, Pos_Center)),
      others => <>);

   --  Base style for class 'fit-fill'::icon
   function Fit_Fill_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Fill),
      others => <>);

   --  Base style for class 'fit-contain'::icon
   function Fit_Contain_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      others => <>);

   --  Base style for class 'fit-cover'::icon
   function Fit_Cover_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Cover),
      others => <>);

   --  Base style for class 'fit-none'::icon
   function Fit_None_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_None),
      others => <>);

   --  Base style for class 'fit-scale-down'::icon
   function Fit_Scale_Down_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Scale_Down),
      others => <>);

   --  Base style for class 'tint-grid'
   function Tint_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (16.0))),
      Flex_Grow => Set (1.0),
      others => <>);

   --  Base style for class 'tint-card'
   function Tint_Card_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'tint-icon'
   function Tint_Icon_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      others => <>);

   --  Base style for class 'tint-icon'::icon
   function Tint_Icon_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      others => <>);

   --  Base style for class 'tint-default'::icon
   function Tint_Default_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      others => <>);

   --  Style for class 'tint-default'::icon when widget State_Hovered
   function Tint_Default_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (96, 165, 250)),
      others => <>);

   --  Base style for class 'tint-warm'::icon
   function Tint_Warm_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (251, 191, 36)),
      others => <>);

   --  Style for class 'tint-warm'::icon when widget State_Hovered
   function Tint_Warm_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (253, 224, 71)),
      others => <>);

   --  Base style for class 'tint-success'::icon
   function Tint_Success_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (74, 222, 128)),
      others => <>);

   --  Style for class 'tint-success'::icon when widget State_Hovered
   function Tint_Success_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (134, 239, 172)),
      others => <>);

   --  Base style for class 'tint-danger'::icon
   function Tint_Danger_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 113, 113)),
      others => <>);

   --  Style for class 'tint-danger'::icon when widget State_Hovered
   function Tint_Danger_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (252, 165, 165)),
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

   --  Complete widget style for class 'subtitle'
   function Subtitle_Class_Widget return Widget_Style is
     (From (Subtitle_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'subtitle'::label
   function Subtitle_Class_Label_Widget return Widget_Style is
     (From (Subtitle_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'subtitle'
   function Subtitle_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'section-title'
   function Section_Title_Class_Widget return Widget_Style is
     (From (Section_Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'section-title'::label
   function Section_Title_Class_Label_Widget return Widget_Style is
     (From (Section_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'section-title'
   function Section_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Section_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Section_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'format-grid'
   function Format_Grid_Class_Widget return Widget_Style is
     (From (Format_Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'format-grid'
   function Format_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Format_Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'fit-grid'
   function Fit_Grid_Class_Widget return Widget_Style is
     (From (Fit_Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'fit-grid'
   function Fit_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Fit_Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card'
   function Card_Class_Widget return Widget_Style is
     (From (Card_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'card'
   function Card_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'card-label'
   function Card_Label_Class_Widget return Widget_Style is
     (From (Card_Label_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'card-label'::label
   function Card_Label_Class_Label_Widget return Widget_Style is
     (From (Card_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'card-label'
   function Card_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Card_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'image'
   function Image_Class_Widget return Widget_Style is
     (From (Image_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'image'::icon
   function Image_Class_Icon_Widget return Widget_Style is
     (From (Image_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'image'
   function Image_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Image_Class_Widget, Enabled => True),
      Icon_Part => (Style => Image_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'fit-fill'::icon
   function Fit_Fill_Class_Icon_Widget return Widget_Style is
     (From (Fit_Fill_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'fit-fill'
   function Fit_Fill_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Fit_Fill_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'fit-contain'::icon
   function Fit_Contain_Class_Icon_Widget return Widget_Style is
     (From (Fit_Contain_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'fit-contain'
   function Fit_Contain_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Fit_Contain_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'fit-cover'::icon
   function Fit_Cover_Class_Icon_Widget return Widget_Style is
     (From (Fit_Cover_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'fit-cover'
   function Fit_Cover_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Fit_Cover_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'fit-none'::icon
   function Fit_None_Class_Icon_Widget return Widget_Style is
     (From (Fit_None_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'fit-none'
   function Fit_None_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Fit_None_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'fit-scale-down'::icon
   function Fit_Scale_Down_Class_Icon_Widget return Widget_Style is
     (From (Fit_Scale_Down_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'fit-scale-down'
   function Fit_Scale_Down_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Fit_Scale_Down_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tint-grid'
   function Tint_Grid_Class_Widget return Widget_Style is
     (From (Tint_Grid_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tint-grid'
   function Tint_Grid_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tint_Grid_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tint-card'
   function Tint_Card_Class_Widget return Widget_Style is
     (From (Tint_Card_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tint-card'
   function Tint_Card_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tint_Card_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tint-icon'
   function Tint_Icon_Class_Widget return Widget_Style is
     (From (Tint_Icon_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'tint-icon'::icon
   function Tint_Icon_Class_Icon_Widget return Widget_Style is
     (From (Tint_Icon_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'tint-icon'
   function Tint_Icon_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tint_Icon_Class_Widget, Enabled => True),
      Icon_Part => (Style => Tint_Icon_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tint-default'::icon
   function Tint_Default_Class_Icon_Widget return Widget_Style is
     (From (Tint_Default_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Default_Class_Icon_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'tint-default'
   function Tint_Default_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Tint_Default_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tint-warm'::icon
   function Tint_Warm_Class_Icon_Widget return Widget_Style is
     (From (Tint_Warm_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Warm_Class_Icon_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'tint-warm'
   function Tint_Warm_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Tint_Warm_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tint-success'::icon
   function Tint_Success_Class_Icon_Widget return Widget_Style is
     (From (Tint_Success_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Success_Class_Icon_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'tint-success'
   function Tint_Success_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Tint_Success_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tint-danger'::icon
   function Tint_Danger_Class_Icon_Widget return Widget_Style is
     (From (Tint_Danger_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Danger_Class_Icon_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'tint-danger'
   function Tint_Danger_Class_Part_Styles return Part_Style_Array is
     ([
      Icon_Part => (Style => Tint_Danger_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Image_Example_Styles;