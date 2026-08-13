--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Transition_Example_Styles is

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
      Background_Color => Set_Bg (RGB (24, 24, 30)),
      others => <>);

   --  Base style for class 'content'
   function Content_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Gap => Set (Gap (Px (28.0))),
      Padding => Set (CSS_Box (Px (28.0), Px (32.0), Px (28.0), Px (32.0))),
      others => <>);

   --  Base style for class 'section'
   function Section_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (10.0))),
      others => <>);

   --  Base style for class 'section-row'
   function Section_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Gap => Set (Gap (Px (16.0))),
      Align_Items => Set (Flex_Start),
      others => <>);

   --  Base style for class 'col-style'
   function Col_Style_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Center),
      others => <>);

   --  Base style for class 'white-label'
   function White_Label_Class_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'dark-label'
   function Dark_Label_Class_Base_Style return Style_Rules is
     (
      Color => Set (RGB (200, 200, 210)),
      Font_Size => Set_Font (Px (11.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Padding => Set (CSS_Box (Px (0.0), Px (4.0), Px (0.0), Px (4.0))),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (160, 170, 190)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'desc'
   function Desc_Class_Base_Style return Style_Rules is
     (
      Padding => Set (CSS_Box (Px (2.0), Px (4.0), Px (2.0), Px (4.0))),
      others => <>);

   --  Base style for class 'desc'::label
   function Desc_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (120, 130, 150)),
      Font_Size => Set_Font (Px (10.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'demo-base'
   function Demo_Base_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (55, 65, 81)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (75, 85, 99))),
      Border_Radius => Set (Radius (Px (6.0))),
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

   --  Complete widget style for class 'content'
   function Content_Class_Widget return Widget_Style is
     (From (Content_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'content'
   function Content_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Content_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'section'
   function Section_Class_Widget return Widget_Style is
     (From (Section_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'section'
   function Section_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'section-row'
   function Section_Row_Class_Widget return Widget_Style is
     (From (Section_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'section-row'
   function Section_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Section_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'col-style'
   function Col_Style_Class_Widget return Widget_Style is
     (From (Col_Style_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'col-style'
   function Col_Style_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Col_Style_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'white-label'
   function White_Label_Class_Widget return Widget_Style is
     (From (White_Label_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'white-label'
   function White_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => White_Label_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dark-label'
   function Dark_Label_Class_Widget return Widget_Style is
     (From (Dark_Label_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dark-label'
   function Dark_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dark_Label_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'desc'
   function Desc_Class_Widget return Widget_Style is
     (From (Desc_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'desc'::label
   function Desc_Class_Label_Widget return Widget_Style is
     (From (Desc_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'desc'
   function Desc_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Desc_Class_Widget, Enabled => True),
      Label_Part => (Style => Desc_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'demo-base'
   function Demo_Base_Class_Widget return Widget_Style is
     (From (Demo_Base_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'demo-base'
   function Demo_Base_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Demo_Base_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Transition_Example_Styles;