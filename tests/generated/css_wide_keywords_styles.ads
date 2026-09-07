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

package CSS_Wide_Keywords_Styles is

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
   --  Style for tag 'box'
   Box_Tag_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (200, 30, 30))
        .Font_Size (Px (21.0))
        .Display (Flex)
        .Opacity (0.25)
        .Gap (Gap (Px (11.0)))
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 2.0), 3 => (Track_Fr, 3.0), others => <>]))
        .Outline_Width (Px (2.0))
        .Outline_Style (Outline_Solid)
        .Outline_Color (RGB (9, 9, 9))
        .White_Space (WS_Pre)
        .Padding (CSS_Box (Px (3.0), Px (9.0), Px (9.0), Px (9.0)))
        .Margin (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0)))
        .Border_Width (Border_Width (Px (7.0)))
        .Radius (Radius (Px (5.0)))
        .List_Style_Type (List_Style_Type_Value'(Kind => List_Style_Disc))
        .List_Style_Position (List_Inside)
        .Overflow_X (Overflow_Hidden)
        .Overflow_Y (Overflow_Hidden)
     .Build;

   --  Part styles bundle for tag 'box'
   Box_Tag_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Box_Tag_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wide'
   Wide_Class_Widget : constant Widget_Style :=
     Style_Of
        .Clear (Prop_Color)
        .Clear (Prop_Font_Size)
        .Clear (Prop_Display)
        .Clear (Prop_Opacity)
        .Clear (Prop_Outline_Width)
        .Clear (Prop_Outline_Color)
        .Clear (Prop_Outline_Style)
        .Clear (Prop_Grid_Columns)
        .Clear (Prop_Gap, Gap_Row_Part)
        .Clear (Prop_Padding, Top)
        .Clear (Prop_Margin, Left)
        .Clear (Prop_Border_Width, Top)
        .Clear (Prop_Border_Radius, Top_Left)
        .Clear (Prop_List_Style_Type)
        .Clear (Prop_List_Style_Image)
        .Clear (Prop_List_Style_Position)
        .Clear (Prop_Overflow)
     .Build;

   --  Part styles bundle for class 'wide'
   Wide_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wide_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for id 'pin'
   Pin_Id_Widget : constant Widget_Style :=
     Style_Of
        .Min_Width (Size (Px (40.0)))
     .Build;

   --  Part styles bundle for id 'pin'
   Pin_Id_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pin_Id_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end CSS_Wide_Keywords_Styles;