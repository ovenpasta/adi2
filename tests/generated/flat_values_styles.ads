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

package Flat_Values_Styles is

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
   --  Style for class 'flat-bg'
   Flat_Bg_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Background_Image_URL ("app://tests/flat-bg.png"))
        .Font_Family ("""Adi Flat Family"", monospace")
     .Build;

   --  Part styles bundle for class 'flat-bg'
   Flat_Bg_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Flat_Bg_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'flat-grad'
   Flat_Grad_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Linear_Gradient (45.0, [Gradient_Stop_Auto (RGB (1, 2, 3)), Gradient_Stop_Auto (RGB (4, 5, 6)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2))
     .Build;

   --  Part styles bundle for class 'flat-grad'
   Flat_Grad_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Flat_Grad_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'flat-list'
   Flat_List_Class_Widget : constant Widget_Style :=
     Style_Of
        .List_Style_Type (List_String ("-> "))
        .List_Style_Image (List_Image ("app://tests/flat-marker.svg"))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Font_Family ("'Second Flat Family', sans-serif")
        .Background_Image (No_Background_Image)
        .List_Style_Type (List_Style_Type_Value'(Kind => List_Style_Square))
        .List_Style_Image (No_List_Image)
     .Build;

   --  Part styles bundle for class 'flat-list'
   Flat_List_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Flat_List_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'flat-comment'
   Flat_Comment_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background_Image (Background_Image_URL ("img/a/*keep*/b.png"))
        .List_Style_Type (List_String ("/* kept */"))
        .List_Style_Image (List_Image ("img/c/*keep*/d.svg"))
     .Build;

   --  Part styles bundle for class 'flat-comment'
   Flat_Comment_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Flat_Comment_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Flat_Values_Styles;