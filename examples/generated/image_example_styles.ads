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

package Image_Example_Styles is

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
   --  Style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (16.0)))
        .Background (RGB (17, 24, 39))
        .Padding (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0)))
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (241, 245, 249))
        .Font_Size (Px (24.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'subtitle'
   Subtitle_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (148, 163, 184))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section-title'
   Section_Title_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'section-title'::label
   Section_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (191, 204, 224))
        .Font_Size (Px (18.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'section-title'
   Section_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Section_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Section_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'format-grid'
   Format_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (4))
        .Grid_Columns ((Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (16.0)))
        .Flex_Grow (1.0)
     .Build;

   --  Part styles bundle for class 'format-grid'
   Format_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Format_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'fit-grid'
   Fit_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (5))
        .Grid_Columns ((Count => 5, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), 5 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (16.0)))
        .Flex_Grow (0.0)
        .Height (Size (Px (96.0)))
     .Build;

   --  Part styles bundle for class 'fit-grid'
   Fit_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Fit_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card'
   Card_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (8.0)))
        .Background (RGB (30, 41, 59))
        .Padding (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (71, 85, 105)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'card'
   Card_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card-label'
   Card_Label_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'card-label'::label
   Card_Label_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (148, 163, 184))
        .Font_Size (Px (12.0))
     .Build;

   --  Part styles bundle for class 'card-label'
   Card_Label_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Card_Label_Class_Widget, Enabled => True),
      Label_Part => (Style => Card_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'image'
   Image_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
     .Build;

   --  Style for class 'image'::icon
   Image_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
        .Object_Position (Object_Position (Pos_Center, Pos_Center))
     .Build;

   --  Part styles bundle for class 'image'
   Image_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Image_Class_Widget, Enabled => True),
      Icon_Part => (Style => Image_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'fit-fill'::icon
   Fit_Fill_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Fill)
     .Build;

   --  Part styles bundle for class 'fit-fill'
   Fit_Fill_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Fit_Fill_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'fit-contain'::icon
   Fit_Contain_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
     .Build;

   --  Part styles bundle for class 'fit-contain'
   Fit_Contain_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Fit_Contain_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'fit-cover'::icon
   Fit_Cover_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Cover)
     .Build;

   --  Part styles bundle for class 'fit-cover'
   Fit_Cover_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Fit_Cover_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'fit-none'::icon
   Fit_None_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_None)
     .Build;

   --  Part styles bundle for class 'fit-none'
   Fit_None_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Fit_None_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'fit-scale-down'::icon
   Fit_Scale_Down_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Scale_Down)
     .Build;

   --  Part styles bundle for class 'fit-scale-down'
   Fit_Scale_Down_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Fit_Scale_Down_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-grid'
   Tint_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (4))
        .Grid_Columns ((Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (16.0)))
        .Flex_Grow (1.0)
     .Build;

   --  Part styles bundle for class 'tint-grid'
   Tint_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tint_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-card'
   Tint_Card_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (8.0)))
        .Background (RGB (30, 41, 59))
        .Padding (CSS_Box (Px (16.0), Px (16.0), Px (16.0), Px (16.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (71, 85, 105)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'tint-card'
   Tint_Card_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tint_Card_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-icon'
   Tint_Icon_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
     .Build;

   --  Style for class 'tint-icon'::icon
   Tint_Icon_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
     .Build;

   --  Part styles bundle for class 'tint-icon'
   Tint_Icon_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tint_Icon_Class_Widget, Enabled => True),
      Icon_Part => (Style => Tint_Icon_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-default'::icon
   Tint_Default_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (148, 163, 184))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (96, 165, 250))
     .Build;

   --  Part styles bundle for class 'tint-default'
   Tint_Default_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Default_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-warm'::icon
   Tint_Warm_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (251, 191, 36))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (253, 224, 71))
     .Build;

   --  Part styles bundle for class 'tint-warm'
   Tint_Warm_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Warm_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-success'::icon
   Tint_Success_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (74, 222, 128))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (134, 239, 172))
     .Build;

   --  Part styles bundle for class 'tint-success'
   Tint_Success_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Success_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-danger'::icon
   Tint_Danger_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (248, 113, 113))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (252, 165, 165))
     .Build;

   --  Part styles bundle for class 'tint-danger'
   Tint_Danger_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Danger_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Image_Example_Styles;