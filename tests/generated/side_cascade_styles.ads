--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Side_Cascade_Styles is

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
   --  Base style for tag 'box'
   function Box_Tag_Base_Style return Style_Rules is
     (
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Margin => Set_Margin (CSS_Box (Px (6.0), Px (8.0), Px (6.0), Px (8.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (17, 34, 51))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'tweak'
   function Tweak_Class_Base_Style return Style_Rules is
     (
      Padding => [Top => Set (Px (4.0)), others => <>],
      Margin => [Bottom => Set_Margin_Side (Px (1.0)), others => <>],
      Border_Width => [Left => Set (Px (5.0)), others => <>],
      Border_Style => [Right => Set_Edge_Style (Dashed), others => <>],
      Border_Color => [Top => Set_Edge_Color (RGB (68, 85, 102)), others => <>],
      Border_Radius => [Bottom_Left => Set (Px (2.0)), others => <>],
      others => <>);

   --  Style for class 'tweak' when widget State_Hovered
   function Tweak_Class_Widget_Hovered_Style return Style_Rules is
     (
      Padding => [Bottom => Set (Px (15.0)), others => <>],
      Margin => [Left => Set_Margin_Side (Px (9.0)), others => <>],
      others => <>);

   --  Base style for id 'pin'
   function Pin_Id_Base_Style return Style_Rules is
     (
      Padding => [Right => Set (Px (3.0)), others => <>],
      Border_Width => [Top => Set (Px (7.0)), others => <>],
      Border_Style => [Top => Set_Edge_Style (Dotted), others => <>],
      Border_Color => [Top => Set_Edge_Color (RGB (9, 9, 9)), others => <>],
      others => <>);

   --  Complete widget style for tag 'box'
   function Box_Tag_Widget return Widget_Style is
     (From (Box_Tag_Base_Style)
     .Build);

   --  Part styles bundle for tag 'box'
   function Box_Tag_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Box_Tag_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tweak'
   function Tweak_Class_Widget return Widget_Style is
     (From (Tweak_Class_Base_Style)
     .On (When_State (State_Hovered), Tweak_Class_Widget_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'tweak'
   function Tweak_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tweak_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for id 'pin'
   function Pin_Id_Widget return Widget_Style is
     (From (Pin_Id_Base_Style)
     .Build);

   --  Part styles bundle for id 'pin'
   function Pin_Id_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Pin_Id_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Side_Cascade_Styles;