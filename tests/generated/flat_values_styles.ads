--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Flat_Values_Styles is

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
   --  Base style for class 'flat-bg'
   function Flat_Bg_Class_Base_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Background_Image_URL ("app://tests/flat-bg.png")),
      Font_Family => Set_Font_Family ("""Adi Flat Family"", monospace"),
      others => <>);

   --  Base style for class 'flat-grad'
   function Flat_Grad_Class_Base_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (45.0, [Gradient_Stop_Auto (RGB (1, 2, 3)), Gradient_Stop_Auto (RGB (4, 5, 6)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      others => <>);

   --  Base style for class 'flat-list'
   function Flat_List_Class_Base_Style return Style_Rules is
     (
      List_Style_Type => Set (List_String ("-> ")),
      List_Style_Image => Set (List_Image ("app://tests/flat-marker.svg")),
      others => <>);

   --  Style for class 'flat-list' when widget State_Hovered
   function Flat_List_Class_Widget_Hovered_Style return Style_Rules is
     (
      Font_Family => Set_Font_Family ("'Second Flat Family', sans-serif"),
      Background_Image => Set_Bg_Image (No_Background_Image),
      List_Style_Type => Set ((Kind => List_Style_Square)),
      List_Style_Image => Set (No_List_Image),
      others => <>);

   --  Complete widget style for class 'flat-bg'
   function Flat_Bg_Class_Widget return Widget_Style is
     (From (Flat_Bg_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'flat-bg'
   function Flat_Bg_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Flat_Bg_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'flat-grad'
   function Flat_Grad_Class_Widget return Widget_Style is
     (From (Flat_Grad_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'flat-grad'
   function Flat_Grad_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Flat_Grad_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'flat-list'
   function Flat_List_Class_Widget return Widget_Style is
     (From (Flat_List_Class_Base_Style)
     .On (When_State (State_Hovered), Flat_List_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'flat-list'
   function Flat_List_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Flat_List_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Flat_Values_Styles;