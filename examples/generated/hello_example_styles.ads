--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Hello_Example_Styles is

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
      Background_Color => Set_Bg (RGB (24, 26, 32)),
      Gap => Set (Gap (Px (16.0))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>);

   --  Base style for class 'welcome'::label
   function Welcome_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (220, 225, 240)),
      Font_Size => Set_Font (Px (18.0)),
      others => <>);

   --  Base style for class 'primary'
   function Primary_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      Cursor => Set (Cursor_Pointer),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Padding => Set (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Style for class 'primary' when widget State_Hovered
   function Primary_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      others => <>);

   --  Base style for class 'primary'::label
   function Primary_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
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

   --  Complete widget style for class 'welcome'::label
   function Welcome_Class_Label_Widget return Widget_Style is
     (From (Welcome_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'welcome'
   function Welcome_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Welcome_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'primary'
   function Primary_Class_Widget return Widget_Style is
     (From (Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Primary_Class_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'primary'::label
   function Primary_Class_Label_Widget return Widget_Style is
     (From (Primary_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'primary'
   function Primary_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

end Hello_Example_Styles;