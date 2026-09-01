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

package Html_View_Example_Styles is

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
        .Gap (Gap (Px (8.0)))
        .Background (RGB (244, 239, 231))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
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
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (54, 46, 37))
        .Font_Size (Px (24.0))
        .Font_Weight (Weight_Bold)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'subtitle'
   Subtitle_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
     .Build;

   --  Style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (97, 88, 77))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tab-bar'
   Tab_Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Flex_Shrink (0.0)
     .Build;

   --  Part styles bundle for class 'tab-bar'
   Tab_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tab-left'
   Tab_Left_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Align_Items (Center)
        .Justify_Content (Center)
        .Background (RGB (224, 212, 194))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (8.0), Px (14.0), Px (8.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (178, 159, 136)))
        .Radius (Radius (Px (8.0), Px (0.0), Px (0.0), Px (8.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (233, 221, 205))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (120, 96, 71))
        .Border_Color (Border_Color (RGB (100, 80, 58)))
     .Build;

   --  Style for class 'tab-left'::label
   Tab_Left_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (70, 61, 50))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Semi_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (RGB (255, 250, 242))
     .Build;

   --  Part styles bundle for class 'tab-left'
   Tab_Left_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Left_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'tab-right'
   Tab_Right_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Inline_Flex)
        .Align_Items (Center)
        .Justify_Content (Center)
        .Background (RGB (224, 212, 194))
        .Cursor_Style (Cursor_Pointer)
        .Padding (CSS_Box (Px (8.0), Px (14.0), Px (8.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (178, 159, 136)))
        .Radius (Radius (Px (0.0), Px (8.0), Px (8.0), Px (0.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (233, 221, 205))
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Background (RGB (120, 96, 71))
        .Border_Color (Border_Color (RGB (100, 80, 58)))
     .Build;

   --  Style for class 'tab-right'::label
   Tab_Right_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (70, 61, 50))
        .Font_Size (Px (13.0))
        .Font_Weight (Weight_Semi_Bold)
        .Text_Wrap_Mode (TWM_Nowrap)
     --  widget State_Selected
     .On (When_State (State_Selected))
        .Text_Color (RGB (255, 250, 242))
     .Build;

   --  Part styles bundle for class 'tab-right'
   Tab_Right_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Tab_Right_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'stack'
   Stack_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'stack'
   Stack_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Stack_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'page-preview'
   Page_Preview_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'page-preview'
   Page_Preview_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Preview_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'page-source'
   Page_Source_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (0.0)))
     .Build;

   --  Part styles bundle for class 'page-source'
   Page_Source_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Page_Source_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'html-view'
   Html_View_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (0.0)))
        .Background (RGB (255, 252, 247))
        .Padding (CSS_Box (Px (14.0), Px (14.0), Px (14.0), Px (14.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (212, 199, 183)))
        .Radius (Radius (Px (10.0)))
        .Overflow_X (Overflow_Auto)
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'html-view'::knob
   Html_View_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Px (26.0)))
        .Background (RGBA (112, 92, 69, 0.7))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'html-view'::scroll
   Html_View_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (9.0)))
        .Background (RGBA (127, 103, 75, 0.55))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Radius (Radius (Px (5.0)))
     .Build;

   --  Part styles bundle for class 'html-view'
   Html_View_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Html_View_Class_Widget, Enabled => True),
      Knob_Part => (Style => Html_View_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Html_View_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'source-editor'
   Source_Editor_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Grow (1.0)
        .Min_Height (Size (Px (0.0)))
        .Background (RGB (252, 248, 242))
        .Padding (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (212, 199, 183)))
        .Radius (Radius (Px (10.0)))
        .Overflow_X (Overflow_Auto)
        .Overflow_Y (Overflow_Auto)
     .Build;

   --  Style for class 'source-editor'::cursor
   Source_Editor_Class_Cursor_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (86, 69, 49))
     .Build;

   --  Style for class 'source-editor'::knob
   Source_Editor_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Px (26.0)))
        .Background (RGBA (112, 92, 69, 0.66))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'source-editor'::scroll
   Source_Editor_Class_Scroll_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (8.0)))
        .Background (RGBA (160, 142, 121, 0.28))
        .Padding (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'source-editor'::selected
   Source_Editor_Class_Selected_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGBA (134, 111, 86, 0.28))
     .Build;

   --  Style for class 'source-editor'::text
   Source_Editor_Class_Text_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (58, 52, 45))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'source-editor'
   Source_Editor_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Source_Editor_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Source_Editor_Class_Cursor_Widget, Enabled => True),
      Knob_Part => (Style => Source_Editor_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Source_Editor_Class_Scroll_Widget, Enabled => True),
      Selected_Part => (Style => Source_Editor_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Source_Editor_Class_Text_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bottom-bar'
   Bottom_Bar_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Flex_Shrink (0.0)
        .Align_Items (Center)
        .Gap (Gap (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'bottom-bar'
   Bottom_Bar_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bottom_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'zoom-slider'
   Zoom_Slider_Class_Widget : constant Widget_Style :=
     Style_Of
        .Flex_Shrink (0.0)
        .Width (Size (Px (200.0)))
        .Height (Size (Px (16.0)))
        .Background (RGB (212, 199, 183))
        .Margin (Top, Margin (Px (18.0)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'zoom-slider'::indicator
   Zoom_Slider_Class_Indicator_Widget : constant Widget_Style :=
     Style_Of
        .Background (RGB (150, 128, 103))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'zoom-slider'::knob
   Zoom_Slider_Class_Knob_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (18.0)))
        .Height (Size (Px (18.0)))
        .Background (RGB (120, 96, 71))
        .Radius (Radius (Px (9.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGB (100, 80, 58))
     .Build;

   --  Style for class 'zoom-slider'::label
   Zoom_Slider_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (97, 88, 77))
        .Font_Size (Px (11.0))
        .Text_Wrap_Mode (TWM_Nowrap)
        .Top (Inset (Px (-18.0)))
     .Build;

   --  Part styles bundle for class 'zoom-slider'
   Zoom_Slider_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Zoom_Slider_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Zoom_Slider_Class_Indicator_Widget, Enabled => True),
      Knob_Part => (Style => Zoom_Slider_Class_Knob_Widget, Enabled => True),
      Label_Part => (Style => Zoom_Slider_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     Style_Of
        .Min_Height (Size (Px (34.0)))
        .Flex_Grow (1.0)
        .Flex_Shrink (0.0)
        .Background (RGB (236, 229, 218))
        .Padding (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (212, 199, 183)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (72, 65, 55))
        .Font_Size (Px (13.0))
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'context-menu'
   Context_Menu_Class_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (200.0)))
        .Background (RGB (252, 248, 242))
        .Box_Shadow (Shadow (Px (0.0), Px (10.0), Px (26.0), Px (0.0), RGBA (72, 58, 43, 0.28)))
        .Padding (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0)))
        .Border_Width (Border_Width (Px (1.0)))
        .Border_Style (Border_Style (Solid))
        .Border_Color (Border_Color (RGB (178, 159, 136)))
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
        .Background (RGBA (252, 248, 242, 0.0))
        .Padding (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0)))
        .Radius (Radius (Px (6.0)))
     --  widget State_Hovered
     .On (When_State (State_Hovered))
        .Background (RGBA (134, 111, 86, 0.28))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Background (RGBA (252, 248, 242, 0.0))
     .Build;

   --  Style for class 'context-menu-item'::label
   Context_Menu_Item_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (54, 46, 37))
        .Font_Size (Px (13.0))
     --  widget State_Disabled
     .On (When_State (State_Disabled))
        .Text_Color (RGB (160, 142, 121))
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

end Html_View_Example_Styles;