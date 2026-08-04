--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Svg_Example_Styles is

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
      Gap => Set (Gap (Px (14.0))),
      Background_Color => Set_Bg (RGB (14, 21, 37)),
      Padding => Set (CSS_Box (Px (20.0), Px (22.0), Px (20.0), Px (22.0))),
      others => <>);

   --  Base style for class 'header'
   function Header_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (4.0))),
      Background_Color => Set_Bg (RGBA (30, 41, 59, 0.62)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (24.0), Px (0.0), RGBA (2, 6, 23, 0.55))),
      Padding => Set (CSS_Box (Px (12.0), Px (14.0), Px (12.0), Px (14.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (148, 163, 184, 0.35))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (241, 245, 249)),
      Font_Size => Set_Font (Px (30.0)),
      Font_Weight => Set (Weight_Extra_Bold),
      others => <>);

   --  Base style for class 'subtitle'::label
   function Subtitle_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'panel'
   function Panel_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (10.0))),
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.85)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (14.0), Px (28.0), Px (0.0), RGBA (2, 6, 23, 0.55))),
      Min_Height => Set (Size (Px (0.0))),
      Padding => Set (CSS_Box (Px (14.0), Px (14.0), Px (14.0), Px (14.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (56, 189, 248, 0.38))),
      Border_Radius => Set (Radius (Px (16.0))),
      others => <>);

   --  Base style for class 'panel-title'::label
   function Panel_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (186, 230, 253)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'stage'
   function Stage_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Center),
      Gap => Set (Gap (Px (10.0))),
      Background_Color => Set_Bg (RGBA (2, 6, 23, 0.72)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (148, 163, 184, 0.26))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'artwork'
   function Artwork_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      others => <>);

   --  Base style for class 'artwork'::icon
   function Artwork_Class_Icon_Base_Style return Style_Rules is
     (
      Object_Fit => Set (Fit_Contain),
      Object_Position => Set (Object_Position (Pos_Center, Pos_Center)),
      others => <>);

   --  Base style for class 'caption'
   function Caption_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'caption'::label
   function Caption_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (148, 163, 184)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>);

   --  Base style for class 'status'
   function Status_Class_Base_Style return Style_Rules is
     (
      Min_Height => Set (Size (Px (34.0))),
      Background_Color => Set_Bg (RGBA (15, 23, 42, 0.82)),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (125, 211, 252, 0.32))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (125, 211, 252)),
      Font_Size => Set_Font (Px (13.0)),
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

   --  Complete widget style for class 'header'
   function Header_Class_Widget return Widget_Style is
     (From (Header_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'header'
   function Header_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Header_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'subtitle'::label
   function Subtitle_Class_Label_Widget return Widget_Style is
     (From (Subtitle_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'subtitle'
   function Subtitle_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'panel'
   function Panel_Class_Widget return Widget_Style is
     (From (Panel_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'panel'
   function Panel_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'panel-title'::label
   function Panel_Title_Class_Label_Widget return Widget_Style is
     (From (Panel_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'panel-title'
   function Panel_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Panel_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'stage'
   function Stage_Class_Widget return Widget_Style is
     (From (Stage_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'stage'
   function Stage_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Stage_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'artwork'
   function Artwork_Class_Widget return Widget_Style is
     (From (Artwork_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'artwork'::icon
   function Artwork_Class_Icon_Widget return Widget_Style is
     (From (Artwork_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'artwork'
   function Artwork_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Artwork_Class_Widget, Enabled => True),
      Icon_Part => (Style => Artwork_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'caption'
   function Caption_Class_Widget return Widget_Style is
     (From (Caption_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'caption'::label
   function Caption_Class_Label_Widget return Widget_Style is
     (From (Caption_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'caption'
   function Caption_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Caption_Class_Widget, Enabled => True),
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'status'
   function Status_Class_Widget return Widget_Style is
     (From (Status_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'status'::label
   function Status_Class_Label_Widget return Widget_Style is
     (From (Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'status'
   function Status_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

end Svg_Example_Styles;