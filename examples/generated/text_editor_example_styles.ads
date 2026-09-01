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

package Text_Editor_Example_Styles is

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
        .Align_Items (Stretch)
        .Justify_Content (Flex_Start)
        .Gap (Gap (Px (12.0)))
        .Background (RGB (20, 24, 31))
        .Padding (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0)))
        .Overflow_X (Overflow_Hidden)
        .Overflow_Y (Overflow_Hidden)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     Style_Of
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (C (White))
        .Font_Size (Px (20.0))
        .Font_Weight (Weight_Semi_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'controls'
   Controls_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
        .Gap (Gap (Px (10.0)))
     .Build;

   --  Part styles bundle for class 'controls'
   Controls_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Controls_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'open-btn'
   Open_Btn_Class_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (49, 50, 68))
        .Padding (CSS_Box (Px (6.0), Px (14.0), Px (6.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (69, 71, 90)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (69, 71, 90))
        .Border_Color (Border_Color (RGB (137, 180, 250)))
     --  widget State_Pressed
     .On (When_State (State_Pressed))
        .Background (RGB (88, 91, 112))
     .Build;

   --  Style for class 'open-btn'::label
   Open_Btn_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (205, 214, 244))
        .Font_Size (Px (13.0))
        .White_Space (WS_Nowrap)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'open-btn'
   Open_Btn_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Open_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Open_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wrap-status'::label
   Wrap_Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (166, 173, 200))
        .Font_Size (Px (13.0))
        .White_Space (WS_Nowrap)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'wrap-status'
   Wrap_Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Wrap_Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ro-status'::label
   Ro_Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (166, 173, 200))
        .Font_Size (Px (13.0))
        .White_Space (WS_Nowrap)
        .Text_Wrap_Mode (TWM_Nowrap)
     .Build;

   --  Part styles bundle for class 'ro-status'
   Ro_Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Label_Part => (Style => Ro_Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wrap-switch'
   Wrap_Switch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (56.0)))
        .Height (Size (Px (28.0)))
        .Background (RGB (88, 91, 112))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (108, 112, 134)))
        .Radius (Radius (Px (14.0)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (116, 199, 236))
        .Border_Color (Border_Color (RGB (137, 220, 255)))
     .Build;

   --  Style for class 'wrap-switch'::knob
   Wrap_Switch_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (24.0)))
        .Height (Size (Px (24.0)))
        .Background (RGB (239, 241, 245))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'wrap-switch'
   Wrap_Switch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wrap_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Wrap_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'ro-switch'
   Ro_Switch_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (56.0)))
        .Height (Size (Px (28.0)))
        .Background (RGB (88, 91, 112))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (108, 112, 134)))
        .Radius (Radius (Px (14.0)))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (116, 199, 236))
        .Border_Color (Border_Color (RGB (137, 220, 255)))
     .Build;

   --  Style for class 'ro-switch'::knob
   Ro_Switch_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (24.0)))
        .Height (Size (Px (24.0)))
        .Background (RGB (239, 241, 245))
        .Radius (Radius (Px (12.0)))
     .Build;

   --  Part styles bundle for class 'ro-switch'
   Ro_Switch_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Ro_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Ro_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'editor'
   Editor_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Cursor_Style (Cursor_Text)
        .Background (RGB (30, 30, 46))
        .Box_Shadow (No_Shadow)
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (69, 71, 90)))
        .Radius (Radius (Px (8.0)))
        .Overflow_X (Overflow_Auto)
        .Overflow_Y (Overflow_Auto)
     --  widget State_Focused
     .On (When_State (State_Focused))
        .Box_Shadow (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (137, 180, 250, 0.25)))
        .Border_Color (Border_Color (RGB (137, 180, 250)))
     .Build;

   --  Style for class 'editor'::cursor
   Editor_Class_Cursor_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (245, 224, 220))
     .Build;

   --  Style for class 'editor'::knob
   Editor_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (6.0)))
        .Min_Height (Size (Px (24.0)))
        .Background (RGBA (137, 180, 250, 0.4))
        .Radius (Radius (Px (3.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (137, 180, 250, 0.6))
     --  part State_Pressed
     .On (When_Part_State (State_Pressed))
        .Background (RGBA (137, 180, 250, 0.8))
     .Build;

   --  Style for class 'editor'::scroll
   Editor_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (8.0)))
        .Background (RGBA (69, 71, 90, 0.3))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Radius (Radius (Px (4.0)))
     --  part State_Hovered
     .On (When_Part_State (State_Hovered))
        .Background (RGBA (69, 71, 90, 0.6))
     .Build;

   --  Style for class 'editor'::selected
   Editor_Class_Selected_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (137, 180, 250, 0.3))
     .Build;

   --  Style for class 'editor'::text
   Editor_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (205, 214, 244))
        .Font_Size (Px (14.0))
        .Text_Wrap_Mode (TWM_Wrap)
        .White_Space (WS_Normal)
     .Build;

   --  Part styles bundle for class 'editor'
   Editor_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Editor_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Editor_Class_Cursor_Widget, Enabled => True),
      Knob_Part => (Style => Editor_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Editor_Class_Scroll_Widget, Enabled => True),
      Selected_Part => (Style => Editor_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Editor_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'context-menu'
   Context_Menu_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (200.0)))
        .Background (RGB (24, 24, 37))
        .Box_Shadow (Shadow (Px (0.0), Px (10.0), Px (26.0), Px (0.0), RGBA (0, 0, 0, 0.45)))
        .Padding (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (137, 180, 250)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'context-menu'
   Context_Menu_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Context_Menu_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'context-menu-item'
   Context_Menu_Item_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Px (28.0)))
        .Background (RGBA (24, 24, 37, 0.0))
        .Padding (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (137, 180, 250, 0.28))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Background (RGBA (24, 24, 37, 0.0))
     .Build;

   --  Style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (205, 214, 244))
        .Font_Size (Px (13.0))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Text_Color (RGB (108, 112, 134))
     .Build;

   --  Part styles bundle for class 'context-menu-item'
   Context_Menu_Item_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Context_Menu_Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Context_Menu_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Text_Editor_Example_Styles;