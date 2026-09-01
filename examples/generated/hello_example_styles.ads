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

package Hello_Example_Styles is

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
        .Background (RGB (24, 26, 32))
        .Gap (Gap (Px (16.0)))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for tag 'button'
   Button_Tag_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Cursor_Style (Cursor_Pointer)
        .Transition ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color)))
        .Padding (CSS_Box (Px (10.0), Px (16.0), Px (10.0), Px (16.0)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for tag 'button'
   Button_Tag_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Button_Tag_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'primary'
   Primary_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (37, 99, 235))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (29, 78, 216))
     .Build;

   --  Style for class 'primary'::label
   Primary_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
     .Build;

   --  Part styles bundle for class 'primary'
   Primary_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for id 'Greeting'::label
   Greeting_Id_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (220, 225, 240))
        .Font_Size (Px (18.0))
     .Build;

   --  Part styles bundle for id 'Greeting'
   Greeting_Id_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Greeting_Id_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Hello_Example_Styles;