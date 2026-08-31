--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

--  The constants below intern as this package elaborates, so the
--  stores behind Intern_Rules and Build are wanted first.
pragma Elaborate_All (Adi.Widget_Styles);

package Assets_Example_Styles is

   function Has_Root_Font_Size return Boolean is (False);
   function Root_Font_Size return Length_Value is (Default_Font_Size);

   function Has_Root_Styles return Boolean is (False);
   Root_Part_Styles : constant Part_Style_Array := Empty_Part_Styles;

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
      Gap => Set (Gap (Px (20.0))),
      Background_Color => Set_Bg (RGB (17, 24, 39)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'root'::knob
   function Root_Class_Knob_Base_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.1))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::knob when part State_Hovered
   function Root_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.28))),
      others => <>);

   --  Base style for class 'root'::scroll
   function Root_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.06)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::scroll when part State_Hovered
   function Root_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.16)),
      others => <>);

   --  Base style for class 'section-title'
   function Section_Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'section-title'::label
   function Section_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (191, 204, 224)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'sprite-grid'
   function Sprite_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (6)),
      Grid_Column_Tracks => (Count => 6, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), 5 => (Track_Fr, 1.0), 6 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'sprite-icon'
   function Sprite_Icon_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (48.0))),
      others => <>);

   --  Base style for class 'sprite-icon'::icon
   function Sprite_Icon_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      others => <>);

   --  Base style for class 'crop-grid'
   function Crop_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (4)),
      Grid_Column_Tracks => (Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'crop-img'
   function Crop_Img_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (80.0))),
      others => <>);

   --  Base style for class 'crop-img'::icon
   function Crop_Img_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      others => <>);

   --  Base style for class 'scale-grid'
   function Scale_Grid_Class_Base_Style return Style_Rules is
     (
      Display => Set (Grid),
      Grid_Columns => Set (Grid_Columns_Value (3)),
      Grid_Column_Tracks => (Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'scale-img'
   function Scale_Img_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (100.0))),
      others => <>);

   --  Base style for class 'scale-img'::icon
   function Scale_Img_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      others => <>);

   --  Base style for class 'card'
   function Card_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'card-label'
   function Card_Label_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'card-label'::label
   function Card_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>);

   --  Base style for class 'nav-bar'
   function Nav_Bar_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (8.0))),
      others => <>);

   --  Base style for class 'nav-item'
   function Nav_Item_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (71, 85, 105))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'nav-item'::icon
   function Nav_Item_Class_Icon_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (20.0))),
      Height => Set (Size (Px (20.0))),
      Color => Set (RGB (148, 163, 184)),
      others => <>);

   --  Style for class 'nav-item'::icon when widget State_Hovered
   function Nav_Item_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (96, 165, 250)),
      others => <>);

   --  Base style for class 'nav-item'::label
   function Nav_Item_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (203, 213, 225)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'tint-blue'::icon
   function Tint_Blue_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (96, 165, 250)),
      others => <>);

   --  Style for class 'tint-blue'::icon when widget State_Hovered
   function Tint_Blue_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (147, 197, 253)),
      others => <>);

   --  Base style for class 'tint-amber'::icon
   function Tint_Amber_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (251, 191, 36)),
      others => <>);

   --  Style for class 'tint-amber'::icon when widget State_Hovered
   function Tint_Amber_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (253, 224, 71)),
      others => <>);

   --  Base style for class 'tint-green'::icon
   function Tint_Green_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (74, 222, 128)),
      others => <>);

   --  Style for class 'tint-green'::icon when widget State_Hovered
   function Tint_Green_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (134, 239, 172)),
      others => <>);

   --  Base style for class 'tint-red'::icon
   function Tint_Red_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (248, 113, 113)),
      others => <>);

   --  Style for class 'tint-red'::icon when widget State_Hovered
   function Tint_Red_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (252, 165, 165)),
      others => <>);

   --  Base style for class 'tint-purple'::icon
   function Tint_Purple_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (192, 132, 252)),
      others => <>);

   --  Style for class 'tint-purple'::icon when widget State_Hovered
   function Tint_Purple_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (216, 180, 254)),
      others => <>);

   --  Base style for class 'tint-cyan'::icon
   function Tint_Cyan_Class_Icon_Base_Style return Style_Rules is
     (
      Color => Set (RGB (34, 211, 238)),
      others => <>);

   --  Style for class 'tint-cyan'::icon when widget State_Hovered
   function Tint_Cyan_Class_Icon_Widget_Hovered_Style return Style_Rules is
     (
      Color => Set (RGB (103, 232, 249)),
      others => <>);

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     From (Root_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Knob_Part_Hovered_Style)
     .Build;

   --  Complete widget style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     From (Root_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Scroll_Part_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
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
   Section_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Section_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'sprite-grid'
   Sprite_Grid_Class_Widget : constant Widget_Style :=
     From (Sprite_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'sprite-grid'
   Sprite_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sprite_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'sprite-icon'
   Sprite_Icon_Class_Widget : constant Widget_Style :=
     From (Sprite_Icon_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'sprite-icon'::icon
   Sprite_Icon_Class_Icon_Widget : constant Widget_Style :=
     From (Sprite_Icon_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'sprite-icon'
   Sprite_Icon_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sprite_Icon_Class_Widget, Enabled => True),
      Icon_Part => (Style => Sprite_Icon_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'crop-grid'
   Crop_Grid_Class_Widget : constant Widget_Style :=
     From (Crop_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'crop-grid'
   Crop_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Crop_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'crop-img'
   Crop_Img_Class_Widget : constant Widget_Style :=
     From (Crop_Img_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'crop-img'::icon
   Crop_Img_Class_Icon_Widget : constant Widget_Style :=
     From (Crop_Img_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'crop-img'
   Crop_Img_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Crop_Img_Class_Widget, Enabled => True),
      Icon_Part => (Style => Crop_Img_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'scale-grid'
   Scale_Grid_Class_Widget : constant Widget_Style :=
     From (Scale_Grid_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'scale-grid'
   Scale_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Scale_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'scale-img'
   Scale_Img_Class_Widget : constant Widget_Style :=
     From (Scale_Img_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'scale-img'::icon
   Scale_Img_Class_Icon_Widget : constant Widget_Style :=
     From (Scale_Img_Class_Icon_Base_Style)
     .Build;

   --  Part styles bundle for class 'scale-img'
   Scale_Img_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Scale_Img_Class_Widget, Enabled => True),
      Icon_Part => (Style => Scale_Img_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'card'
   Card_Class_Widget : constant Widget_Style :=
     From (Card_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'card'
   Card_Class_Part_Styles : constant Part_Style_Array :=
     [
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
   Card_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'nav-bar'
   Nav_Bar_Class_Widget : constant Widget_Style :=
     From (Nav_Bar_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'nav-bar'
   Nav_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Nav_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'nav-item'
   Nav_Item_Class_Widget : constant Widget_Style :=
     From (Nav_Item_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'nav-item'::icon
   Nav_Item_Class_Icon_Widget : constant Widget_Style :=
     From (Nav_Item_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Nav_Item_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Complete widget style for class 'nav-item'::label
   Nav_Item_Class_Label_Widget : constant Widget_Style :=
     From (Nav_Item_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'nav-item'
   Nav_Item_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Nav_Item_Class_Widget, Enabled => True),
      Icon_Part => (Style => Nav_Item_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Nav_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-blue'::icon
   Tint_Blue_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Blue_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Blue_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-blue'
   Tint_Blue_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Blue_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-amber'::icon
   Tint_Amber_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Amber_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Amber_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-amber'
   Tint_Amber_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Amber_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-green'::icon
   Tint_Green_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Green_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Green_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-green'
   Tint_Green_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Green_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-red'::icon
   Tint_Red_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Red_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Red_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-red'
   Tint_Red_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Red_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-purple'::icon
   Tint_Purple_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Purple_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Purple_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-purple'
   Tint_Purple_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Purple_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tint-cyan'::icon
   Tint_Cyan_Class_Icon_Widget : constant Widget_Style :=
     From (Tint_Cyan_Class_Icon_Base_Style)
     .On (When_State (State_Hovered), Tint_Cyan_Class_Icon_Widget_Hovered_Style)
     .Build;

   --  Part styles bundle for class 'tint-cyan'
   Tint_Cyan_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Cyan_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Assets_Example_Styles;