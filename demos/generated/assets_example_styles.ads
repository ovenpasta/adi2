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
   --  Style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (20.0)))
        .Background (RGB (17, 24, 39))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'root'::knob
   Root_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.1)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
        .Border_Color (Border_Color (RGBA (236, 239, 244, 0.28)))
     .Build;

   --  Style for class 'root'::scroll
   Root_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (94, 129, 172, 0.06))
        .Transition ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Radius (Radius (Px (5.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (94, 129, 172, 0.16))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'section-title'
   Section_Title_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
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

   --  Style for class 'sprite-grid'
   Sprite_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (6))
        .Grid_Columns ((Count => 6, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), 5 => (Track_Fr, 1.0), 6 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'sprite-grid'
   Sprite_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sprite_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'sprite-icon'
   Sprite_Icon_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (48.0)))
     .Build;

   --  Style for class 'sprite-icon'::icon
   Sprite_Icon_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
     .Build;

   --  Part styles bundle for class 'sprite-icon'
   Sprite_Icon_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Sprite_Icon_Class_Widget, Enabled => True),
      Icon_Part => (Style => Sprite_Icon_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'crop-grid'
   Crop_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (4))
        .Grid_Columns ((Count => 4, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), 4 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'crop-grid'
   Crop_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Crop_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'crop-img'
   Crop_Img_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (80.0)))
     .Build;

   --  Style for class 'crop-img'::icon
   Crop_Img_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
     .Build;

   --  Part styles bundle for class 'crop-img'
   Crop_Img_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Crop_Img_Class_Widget, Enabled => True),
      Icon_Part => (Style => Crop_Img_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'scale-grid'
   Scale_Grid_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 1.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Gap (Gap (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'scale-grid'
   Scale_Grid_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Scale_Grid_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'scale-img'
   Scale_Img_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (100.0)))
     .Build;

   --  Style for class 'scale-img'::icon
   Scale_Img_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
     .Build;

   --  Part styles bundle for class 'scale-img'
   Scale_Img_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Scale_Img_Class_Widget, Enabled => True),
      Icon_Part => (Style => Scale_Img_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'card'
   Card_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (8.0)))
        .Background (RGB (30, 41, 59))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
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
        .Flex_Shrink (0.0)
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

   --  Style for class 'nav-bar'
   Nav_Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Gap (Gap (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'nav-bar'
   Nav_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Nav_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'nav-item'
   Nav_Item_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Background (RGB (30, 41, 59))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (71, 85, 105)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'nav-item'::icon
   Nav_Item_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (20.0)))
        .Height (Size (Px (20.0)))
        .Text_Color (RGB (148, 163, 184))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (96, 165, 250))
     .Build;

   --  Style for class 'nav-item'::label
   Nav_Item_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (203, 213, 225))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'nav-item'
   Nav_Item_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Nav_Item_Class_Widget, Enabled => True),
      Icon_Part => (Style => Nav_Item_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Nav_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-blue'::icon
   Tint_Blue_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (96, 165, 250))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (147, 197, 253))
     .Build;

   --  Part styles bundle for class 'tint-blue'
   Tint_Blue_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Blue_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-amber'::icon
   Tint_Amber_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (251, 191, 36))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (253, 224, 71))
     .Build;

   --  Part styles bundle for class 'tint-amber'
   Tint_Amber_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Amber_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-green'::icon
   Tint_Green_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (74, 222, 128))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (134, 239, 172))
     .Build;

   --  Part styles bundle for class 'tint-green'
   Tint_Green_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Green_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-red'::icon
   Tint_Red_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (248, 113, 113))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (252, 165, 165))
     .Build;

   --  Part styles bundle for class 'tint-red'
   Tint_Red_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Red_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-purple'::icon
   Tint_Purple_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (192, 132, 252))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (216, 180, 254))
     .Build;

   --  Part styles bundle for class 'tint-purple'
   Tint_Purple_Class_Part_Styles : constant Part_Style_Array :=
     [
      Icon_Part => (Style => Tint_Purple_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tint-cyan'::icon
   Tint_Cyan_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (34, 211, 238))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Text_Color (RGB (103, 232, 249))
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