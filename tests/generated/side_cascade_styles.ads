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

package Side_Cascade_Styles is

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
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Margin (CSS_Box (Px (6.0), Px (8.0), Px (6.0), Px (8.0)))
        .Border_Width (Border_Width (Px (2.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (17, 34, 51)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for tag 'box'
   Box_Tag_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Box_Tag_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tweak'
   Tweak_Class_Widget : constant Widget_Style :=
     Style_Of
        .Padding (Top, Px (4.0))
        .Margin (Bottom, Margin (Px (1.0)))
        .Border_Width (Left, Px (5.0))
        .Border_Style (Right, Dashed)
        .Border_Color (Top, RGB (68, 85, 102))
        .Radius (Bottom_Left, Px (2.0))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Padding (Bottom, Px (15.0))
        .Margin (Left, Margin (Px (9.0)))
     .Build;

   --  Part styles bundle for class 'tweak'
   Tweak_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tweak_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for id 'pin'
   Pin_Id_Widget : constant Widget_Style :=
     Style_Of
        .Padding (Right, Px (3.0))
        .Border_Width (Top, Px (7.0))
        .Border_Style (Top, Dotted)
        .Border_Color (Top, RGB (9, 9, 9))
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

end Side_Cascade_Styles;