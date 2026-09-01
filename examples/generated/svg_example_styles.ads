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

package Svg_Example_Styles is

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
        .Gap (Gap (Px (14.0)))
        .Background (RGB (14, 21, 37))
        .Padding (CSS_Box (Px (20.0), Px (22.0), Px (20.0), Px (22.0)))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'header'
   Header_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (4.0)))
        .Background (RGBA (30, 41, 59, 0.62))
        .Box_Shadow (Shadow (Px (0.0), Px (10.0), Px (24.0), Px (0.0), RGBA (2, 6, 23, 0.55)))
        .Padding (CSS_Box (Px (12.0), Px (14.0), Px (12.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (148, 163, 184, 0.35)))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'header'
   Header_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (241, 245, 249))
        .Font_Size (Px (30.0))
        .Font_Weight (Weight_Extra_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (148, 163, 184))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panel'
   Panel_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Gap (Gap (Px (10.0)))
        .Background (RGBA (15, 23, 42, 0.85))
        .Box_Shadow (Shadow (Px (0.0), Px (14.0), Px (28.0), Px (0.0), RGBA (2, 6, 23, 0.55)))
        .Min_Height (Size (Px (0.0)))
        .Padding (CSS_Box (Px (14.0), Px (14.0), Px (14.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (56, 189, 248, 0.38)))
        .Radius (Radius (Px (16.0)))
     .Build;

   --  Part styles bundle for class 'panel'
   Panel_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'panel-title'::label
   Panel_Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (186, 230, 253))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'panel-title'
   Panel_Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Panel_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'stage'
   Stage_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (0.0)))
        .Align_Items (Stretch)
        .Justify_Content (Center)
        .Gap (Gap (Px (10.0)))
        .Background (RGBA (2, 6, 23, 0.72))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (148, 163, 184, 0.26)))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'stage'
   Stage_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Stage_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'artwork'
   Artwork_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (0.0)))
     .Build;

   --  Style for class 'artwork'::icon
   Artwork_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Object_Fit (Fit_Contain)
        .Object_Position (Object_Position (Pos_Center, Pos_Center))
     .Build;

   --  Part styles bundle for class 'artwork'
   Artwork_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Artwork_Class_Widget, Enabled => True),
      Icon_Part => (Style => Artwork_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'caption'
   Caption_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'caption'::label
   Caption_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (148, 163, 184))
        .Font_Size (Px (12.0))
     .Build;

   --  Part styles bundle for class 'caption'
   Caption_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Caption_Class_Widget, Enabled => True),
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Px (34.0)))
        .Background (RGBA (15, 23, 42, 0.82))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGBA (125, 211, 252, 0.32)))
        .Radius (Radius (Px (10.0)))
     .Build;

   --  Style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (125, 211, 252))
        .Font_Size (Px (13.0))
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Svg_Example_Styles;