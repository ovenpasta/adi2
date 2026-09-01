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

package Widget_Defaults_Styles is

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
   --  Style for class 'button'
   Button_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Min_Height (Size (Px (34.0)))
        .Background (RGB (240, 244, 249))
        .Padding (CSS_Box (Px (8.0), Px (14.0), Px (8.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (181, 191, 205)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (228, 235, 244))
        .Border_Color (Border_Color (RGB (150, 164, 183)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (214, 223, 235))
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Border_Color (Border_Color (RGB (59, 130, 246)))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.6)
     .Build;

   --  Style for class 'button'::label
   Button_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (30, 41, 59))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'button'
   Button_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Button_Class_Widget, Enabled => True),
      Label_Part => (Style => Button_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'text-input'
   Text_Input_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Px (38.0)))
        .Background (RGB (255, 255, 255))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (186, 198, 212)))
        .Radius (Radius (Px (7.0)))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Opacity (0.6)
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Border_Color (Border_Color (RGB (59, 130, 246)))
     .Build;

   --  Style for class 'text-input'::cursor
   Text_Input_Class_Cursor_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (59, 130, 246))
        .Width (Size (Px (1.0)))
     .Build;

   --  Style for class 'text-input'::selected
   Text_Input_Class_Selected_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (59, 130, 246, 0.22))
     .Build;

   --  Style for class 'text-input'::text
   Text_Input_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (15, 23, 42))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'text-input'
   Text_Input_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Text_Input_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Text_Input_Class_Cursor_Widget, Enabled => True),
      Selected_Part => (Style => Text_Input_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Text_Input_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'list-box'
   List_Box_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (255, 255, 255))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (198, 208, 220)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'list-box'::knob
   List_Box_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Min_Height (Size (Px (24.0)))
        .Background (RGBA (71, 85, 105, 0.85))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Style for class 'list-box'::scroll
   List_Box_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (10.0)))
        .Background (RGBA (148, 163, 184, 0.22))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Margin (CSS_Box (Px (0.0), Px (0.0), Px (0.0), Px (6.0)))
        .Radius (Radius (Px (6.0)))
     .Build;

   --  Part styles bundle for class 'list-box'
   List_Box_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => List_Box_Class_Widget, Enabled => True),
      Knob_Part => (Style => List_Box_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => List_Box_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'list-row'
   List_Row_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (255, 255, 255))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0), Px (0.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (222, 229, 238)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (239, 246, 255))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
     .Build;

   --  Style for class 'list-row'::label
   List_Row_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (30, 41, 59))
        .Font_Size (Px (14.0))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (RGB (255, 255, 255))
     .Build;

   --  Part styles bundle for class 'list-row'
   List_Row_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => List_Row_Class_Widget, Enabled => True),
      Label_Part => (Style => List_Row_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Widget_Defaults_Styles;