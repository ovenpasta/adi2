--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Text_Editor_Example_Styles is

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
   --  Base style for class 'root'
   function Root_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      Background_Color => Set_Bg (RGB (20, 24, 31)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Overflow_X => Set_Overflow_X (Overflow_Hidden),
      Overflow_Y => Set_Overflow_Y (Overflow_Hidden),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (20.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      others => <>);

   --  Base style for class 'controls'
   function Controls_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (10.0))),
      others => <>);

   --  Base style for class 'open-btn'
   function Open_Btn_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (49, 50, 68)),
      Padding => Set (CSS_Box (Px (6.0), Px (14.0), Px (6.0), Px (14.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (69, 71, 90))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'open-btn' when widget State_Hovered
   function Open_Btn_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (69, 71, 90)),
      Border_Color => Set (Border_Color (RGB (137, 180, 250))),
      others => <>);

   --  Style for class 'open-btn' when widget State_Pressed
   function Open_Btn_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (88, 91, 112)),
      others => <>);

   --  Base style for class 'open-btn'::label
   function Open_Btn_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      Font_Size => Set_Font (Px (13.0)),
      White_Space => Set (WS_Nowrap),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'wrap-status'::label
   function Wrap_Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (166, 173, 200)),
      Font_Size => Set_Font (Px (13.0)),
      White_Space => Set (WS_Nowrap),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'ro-status'::label
   function Ro_Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (166, 173, 200)),
      Font_Size => Set_Font (Px (13.0)),
      White_Space => Set (WS_Nowrap),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Base style for class 'wrap-switch'
   function Wrap_Switch_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (56.0))),
      Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGB (88, 91, 112)),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (108, 112, 134))),
      Border_Radius => Set (Radius (Px (14.0))),
      others => <>);

   --  Style for class 'wrap-switch' when widget State_Selected
   function Wrap_Switch_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (116, 199, 236)),
      Border_Color => Set (Border_Color (RGB (137, 220, 255))),
      others => <>);

   --  Base style for class 'wrap-switch'::knob
   function Wrap_Switch_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGB (239, 241, 245)),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'ro-switch'
   function Ro_Switch_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (56.0))),
      Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGB (88, 91, 112)),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (108, 112, 134))),
      Border_Radius => Set (Radius (Px (14.0))),
      others => <>);

   --  Style for class 'ro-switch' when widget State_Selected
   function Ro_Switch_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (116, 199, 236)),
      Border_Color => Set (Border_Color (RGB (137, 220, 255))),
      others => <>);

   --  Base style for class 'ro-switch'::knob
   function Ro_Switch_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGB (239, 241, 245)),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'editor'
   function Editor_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Cursor => Set (Cursor_Text),
      Background_Color => Set_Bg (RGB (30, 30, 46)),
      Box_Shadow => Set (No_Shadow),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (69, 71, 90))),
      Border_Radius => Set (Radius (Px (8.0))),
      Overflow_X => Set_Overflow_X (Overflow_Auto),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Style for class 'editor' when widget State_Focused
   function Editor_Class_Widget_Focused_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (8.0), Px (2.0), RGBA (137, 180, 250, 0.25))),
      Border_Color => Set (Border_Color (RGB (137, 180, 250))),
      others => <>);

   --  Base style for class 'editor'::cursor
   function Editor_Class_Cursor_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (245, 224, 220)),
      others => <>);

   --  Base style for class 'editor'::knob
   function Editor_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (6.0))),
      Min_Height => Set (Size (Px (24.0))),
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.4)),
      Border_Radius => Set (Radius (Px (3.0))),
      others => <>);

   --  Style for class 'editor'::knob when part State_Hovered
   function Editor_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.6)),
      others => <>);

   --  Style for class 'editor'::knob when part State_Pressed
   function Editor_Class_Knob_Part_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.8)),
      others => <>);

   --  Base style for class 'editor'::scroll
   function Editor_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (8.0))),
      Background_Color => Set_Bg (RGBA (69, 71, 90, 0.3)),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Style for class 'editor'::scroll when part State_Hovered
   function Editor_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (69, 71, 90, 0.6)),
      others => <>);

   --  Base style for class 'editor'::selected
   function Editor_Class_Selected_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.3)),
      others => <>);

   --  Base style for class 'editor'::text
   function Editor_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      White_Space => Set (WS_Normal),
      others => <>);

   --  Base style for class 'context-menu'
   function Context_Menu_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (200.0))),
      Background_Color => Set_Bg (RGB (24, 24, 37)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (26.0), Px (0.0), RGBA (0, 0, 0, 0.45))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (137, 180, 250))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'context-menu-item'
   function Context_Menu_Item_Class_Base_Style return Style_Rules is
     (
      Min_Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGBA (24, 24, 37, 0.0)),
      Padding => Set (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'context-menu-item' when widget State_Hovered
   function Context_Menu_Item_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (137, 180, 250, 0.28)),
      others => <>);

   --  Style for class 'context-menu-item' when widget State_Disabled
   function Context_Menu_Item_Class_Widget_Disabled_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (24, 24, 37, 0.0)),
      others => <>);

   --  Base style for class 'context-menu-item'::label
   function Context_Menu_Item_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (205, 214, 244)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Style for class 'context-menu-item'::label when widget State_Disabled
   function Context_Menu_Item_Class_Label_Widget_Disabled_Style return Style_Rules is
     (
      Color => Set (RGB (108, 112, 134)),
      others => <>);

   --  Complete widget style for class 'root'
   function Root_Class_Widget return Widget_Style is
     (From (Root_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'root'
   function Root_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'
   function Title_Class_Widget return Widget_Style is
     (From (Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'controls'
   function Controls_Class_Widget return Widget_Style is
     (From (Controls_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'controls'
   function Controls_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Controls_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'open-btn'
   function Open_Btn_Class_Widget return Widget_Style is
     (From (Open_Btn_Class_Base_Style)
     .On (When_State (State_Hovered), Open_Btn_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Open_Btn_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'open-btn'::label
   function Open_Btn_Class_Label_Widget return Widget_Style is
     (From (Open_Btn_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'open-btn'
   function Open_Btn_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Open_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Open_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'wrap-status'::label
   function Wrap_Status_Class_Label_Widget return Widget_Style is
     (From (Wrap_Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'wrap-status'
   function Wrap_Status_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Wrap_Status_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ro-status'::label
   function Ro_Status_Class_Label_Widget return Widget_Style is
     (From (Ro_Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'ro-status'
   function Ro_Status_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Ro_Status_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'wrap-switch'
   function Wrap_Switch_Class_Widget return Widget_Style is
     (From (Wrap_Switch_Class_Base_Style)
     .On (When_State (State_Selected), Wrap_Switch_Class_Widget_Selected_Style)
     .Build);

   --  Complete widget style for class 'wrap-switch'::knob
   function Wrap_Switch_Class_Knob_Widget return Widget_Style is
     (From (Wrap_Switch_Class_Knob_Base_Style)
     .Build);

   --  Part styles bundle for class 'wrap-switch'
   function Wrap_Switch_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Wrap_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Wrap_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ro-switch'
   function Ro_Switch_Class_Widget return Widget_Style is
     (From (Ro_Switch_Class_Base_Style)
     .On (When_State (State_Selected), Ro_Switch_Class_Widget_Selected_Style)
     .Build);

   --  Complete widget style for class 'ro-switch'::knob
   function Ro_Switch_Class_Knob_Widget return Widget_Style is
     (From (Ro_Switch_Class_Knob_Base_Style)
     .Build);

   --  Part styles bundle for class 'ro-switch'
   function Ro_Switch_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Ro_Switch_Class_Widget, Enabled => True),
      Knob_Part => (Style => Ro_Switch_Class_Knob_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'editor'
   function Editor_Class_Widget return Widget_Style is
     (From (Editor_Class_Base_Style)
     .On (When_State (State_Focused), Editor_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'editor'::cursor
   function Editor_Class_Cursor_Widget return Widget_Style is
     (From (Editor_Class_Cursor_Base_Style)
     .Build);

   --  Complete widget style for class 'editor'::knob
   function Editor_Class_Knob_Widget return Widget_Style is
     (From (Editor_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Editor_Class_Knob_Part_Hovered_Style)
     .On (When_Part_State (State_Pressed), Editor_Class_Knob_Part_Pressed_Style)
     .Build);

   --  Complete widget style for class 'editor'::scroll
   function Editor_Class_Scroll_Widget return Widget_Style is
     (From (Editor_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Editor_Class_Scroll_Part_Hovered_Style)
     .Build);

   --  Complete widget style for class 'editor'::selected
   function Editor_Class_Selected_Widget return Widget_Style is
     (From (Editor_Class_Selected_Base_Style)
     .Build);

   --  Complete widget style for class 'editor'::text
   function Editor_Class_Text_Widget return Widget_Style is
     (From (Editor_Class_Text_Base_Style)
     .Build);

   --  Part styles bundle for class 'editor'
   function Editor_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Editor_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Editor_Class_Cursor_Widget, Enabled => True),
      Knob_Part => (Style => Editor_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Editor_Class_Scroll_Widget, Enabled => True),
      Selected_Part => (Style => Editor_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Editor_Class_Text_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'context-menu'
   function Context_Menu_Class_Widget return Widget_Style is
     (From (Context_Menu_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'context-menu'
   function Context_Menu_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Context_Menu_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'context-menu-item'
   function Context_Menu_Item_Class_Widget return Widget_Style is
     (From (Context_Menu_Item_Class_Base_Style)
     .On (When_State (State_Hovered), Context_Menu_Item_Class_Widget_Hovered_Style)
     .On (When_State (State_Disabled), Context_Menu_Item_Class_Widget_Disabled_Style)
     .Build);

   --  Complete widget style for class 'context-menu-item'::label
   function Context_Menu_Item_Class_Label_Widget return Widget_Style is
     (From (Context_Menu_Item_Class_Label_Base_Style)
     .On (When_State (State_Disabled), Context_Menu_Item_Class_Label_Widget_Disabled_Style)
     .Build);

   --  Part styles bundle for class 'context-menu-item'
   function Context_Menu_Item_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Context_Menu_Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Context_Menu_Item_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Text_Editor_Example_Styles;