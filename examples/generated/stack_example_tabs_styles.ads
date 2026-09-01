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

package Stack_Example_Tabs_Styles is

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
   --  Style for class 'tab-left'
   Tab_Left_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (55, 65, 81))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
        .Radius (Radius (Px (8.0), Px (0.0), Px (0.0), Px (8.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (75, 85, 99))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     .Build;

   --  Style for class 'tab-left'::label
   Tab_Left_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'tab-left'
   Tab_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Left_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tab-center'
   Tab_Center_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (55, 65, 81))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (75, 85, 99))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     .Build;

   --  Style for class 'tab-center'::label
   Tab_Center_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'tab-center'
   Tab_Center_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Center_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Center_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tab-right'
   Tab_Right_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Justify_Content (Center)
        .Align_Items (Center)
        .Background (RGB (55, 65, 81))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (10.0), Px (20.0), Px (10.0), Px (20.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (75, 85, 99)))
        .Radius (Radius (Px (0.0), Px (8.0), Px (8.0), Px (0.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (75, 85, 99))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (59, 130, 246))
        .Border_Color (Border_Color (RGB (37, 99, 235)))
     .Build;

   --  Style for class 'tab-right'::label
   Tab_Right_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (14.0))
        .Font_Weight (Weight_Medium)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'tab-right'
   Tab_Right_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Right_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Stack_Example_Tabs_Styles;