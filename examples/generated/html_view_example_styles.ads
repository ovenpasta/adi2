--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Html_View_Example_Styles is

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
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (244, 239, 231)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (54, 46, 37)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'subtitle'
   function Subtitle_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'subtitle'::label
   function Subtitle_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (97, 88, 77)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'tab-bar'
   function Tab_Bar_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'tab-left'
   function Tab_Left_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Background_Color => Set_Bg (RGB (224, 212, 194)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (8.0), Px (14.0), Px (8.0), Px (14.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (178, 159, 136))),
      Border_Radius => Set (Radius (Px (8.0), Px (0.0), Px (0.0), Px (8.0))),
      others => <>);

   --  Style for class 'tab-left' when widget State_Hovered
   function Tab_Left_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (233, 221, 205)),
      others => <>);

   --  Style for class 'tab-left' when widget State_Selected
   function Tab_Left_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (120, 96, 71)),
      Border_Color => Set (Border_Color (RGB (100, 80, 58))),
      others => <>);

   --  Base style for class 'tab-left'::label
   function Tab_Left_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (70, 61, 50)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Style for class 'tab-left'::label when widget State_Selected
   function Tab_Left_Class_Label_Widget_Selected_Style return Style_Rules is
     (
      Color => Set (RGB (255, 250, 242)),
      others => <>);

   --  Base style for class 'tab-right'
   function Tab_Right_Class_Base_Style return Style_Rules is
     (
      Display => Set (Inline_Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Background_Color => Set_Bg (RGB (224, 212, 194)),
      Cursor => Set (Cursor_Pointer),
      Padding => Set (CSS_Box (Px (8.0), Px (14.0), Px (8.0), Px (14.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (178, 159, 136))),
      Border_Radius => Set (Radius (Px (0.0), Px (8.0), Px (8.0), Px (0.0))),
      others => <>);

   --  Style for class 'tab-right' when widget State_Hovered
   function Tab_Right_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (233, 221, 205)),
      others => <>);

   --  Style for class 'tab-right' when widget State_Selected
   function Tab_Right_Class_Widget_Selected_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (120, 96, 71)),
      Border_Color => Set (Border_Color (RGB (100, 80, 58))),
      others => <>);

   --  Base style for class 'tab-right'::label
   function Tab_Right_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (70, 61, 50)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>);

   --  Style for class 'tab-right'::label when widget State_Selected
   function Tab_Right_Class_Label_Widget_Selected_Style return Style_Rules is
     (
      Color => Set (RGB (255, 250, 242)),
      others => <>);

   --  Base style for class 'stack'
   function Stack_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      others => <>);

   --  Base style for class 'page-preview'
   function Page_Preview_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      others => <>);

   --  Base style for class 'page-source'
   function Page_Source_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      others => <>);

   --  Base style for class 'html-view'
   function Html_View_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      Background_Color => Set_Bg (RGB (255, 252, 247)),
      Padding => Set (CSS_Box (Px (14.0), Px (14.0), Px (14.0), Px (14.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (212, 199, 183))),
      Border_Radius => Set (Radius (Px (10.0))),
      Overflow_X => Set_Overflow_X (Overflow_Auto),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'html-view'::knob
   function Html_View_Class_Knob_Base_Style return Style_Rules is
     (
      Min_Height => Set (Size (Px (26.0))),
      Background_Color => Set_Bg (RGBA (112, 92, 69, 0.7)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'html-view'::scroll
   function Html_View_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (9.0))),
      Background_Color => Set_Bg (RGBA (127, 103, 75, 0.55)),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Base style for class 'source-editor'
   function Source_Editor_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      Background_Color => Set_Bg (RGB (252, 248, 242)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (212, 199, 183))),
      Border_Radius => Set (Radius (Px (10.0))),
      Overflow_X => Set_Overflow_X (Overflow_Auto),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'source-editor'::cursor
   function Source_Editor_Class_Cursor_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (86, 69, 49)),
      others => <>);

   --  Base style for class 'source-editor'::knob
   function Source_Editor_Class_Knob_Base_Style return Style_Rules is
     (
      Min_Height => Set (Size (Px (26.0))),
      Background_Color => Set_Bg (RGBA (112, 92, 69, 0.66)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'source-editor'::scroll
   function Source_Editor_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (8.0))),
      Background_Color => Set_Bg (RGBA (160, 142, 121, 0.28)),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'source-editor'::selected
   function Source_Editor_Class_Selected_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (134, 111, 86, 0.28)),
      others => <>);

   --  Base style for class 'source-editor'::text
   function Source_Editor_Class_Text_Base_Style return Style_Rules is
     (
      Color => Set (RGB (58, 52, 45)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'bottom-bar'
   function Bottom_Bar_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Shrink => Set (0.0),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      others => <>);

   --  Base style for class 'zoom-slider'
   function Zoom_Slider_Class_Base_Style return Style_Rules is
     (
      Flex_Shrink => Set (0.0),
      Width => Set (Size (Px (200.0))),
      Height => Set (Size (Px (16.0))),
      Background_Color => Set_Bg (RGB (212, 199, 183)),
      Margin => Set (CSS_Box (Px (18.0), Px (0.0), Px (0.0), Px (0.0))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'zoom-slider'::indicator
   function Zoom_Slider_Class_Indicator_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (150, 128, 103)),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'zoom-slider'::knob
   function Zoom_Slider_Class_Knob_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (18.0))),
      Height => Set (Size (Px (18.0))),
      Background_Color => Set_Bg (RGB (120, 96, 71)),
      Border_Radius => Set (Radius (Px (9.0))),
      others => <>);

   --  Style for class 'zoom-slider'::knob when widget State_Hovered
   function Zoom_Slider_Class_Knob_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (100, 80, 58)),
      others => <>);

   --  Base style for class 'zoom-slider'::label
   function Zoom_Slider_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (97, 88, 77)),
      Font_Size => Set_Font (Px (11.0)),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      Top => Set_Top (Inset (Px (-18.0))),
      others => <>);

   --  Base style for class 'status'
   function Status_Class_Base_Style return Style_Rules is
     (
      Min_Height => Set (Size (Px (34.0))),
      Flex_Grow => Set (1.0),
      Flex_Shrink => Set (0.0),
      Background_Color => Set_Bg (RGB (236, 229, 218)),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (212, 199, 183))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (72, 65, 55)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Base style for class 'context-menu'
   function Context_Menu_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (200.0))),
      Background_Color => Set_Bg (RGB (252, 248, 242)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (10.0), Px (26.0), Px (0.0), RGBA (72, 58, 43, 0.28))),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (178, 159, 136))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'context-menu-item'
   function Context_Menu_Item_Class_Base_Style return Style_Rules is
     (
      Min_Height => Set (Size (Px (28.0))),
      Background_Color => Set_Bg (RGBA (252, 248, 242, 0.0)),
      Padding => Set (CSS_Box (Px (6.0), Px (10.0), Px (6.0), Px (10.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'context-menu-item' when widget State_Hovered
   function Context_Menu_Item_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (134, 111, 86, 0.28)),
      others => <>);

   --  Style for class 'context-menu-item' when widget State_Disabled
   function Context_Menu_Item_Class_Widget_Disabled_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (252, 248, 242, 0.0)),
      others => <>);

   --  Base style for class 'context-menu-item'::label
   function Context_Menu_Item_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (54, 46, 37)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>);

   --  Style for class 'context-menu-item'::label when widget State_Disabled
   function Context_Menu_Item_Class_Label_Widget_Disabled_Style return Style_Rules is
     (
      Color => Set (RGB (160, 142, 121)),
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

   --  Complete widget style for class 'subtitle'
   function Subtitle_Class_Widget return Widget_Style is
     (From (Subtitle_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'subtitle'::label
   function Subtitle_Class_Label_Widget return Widget_Style is
     (From (Subtitle_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'subtitle'
   function Subtitle_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tab-bar'
   function Tab_Bar_Class_Widget return Widget_Style is
     (From (Tab_Bar_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tab-bar'
   function Tab_Bar_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tab_Bar_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tab-left'
   function Tab_Left_Class_Widget return Widget_Style is
     (From (Tab_Left_Class_Base_Style)
     .On (When_State (State_Hovered), Tab_Left_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Left_Class_Widget_Selected_Style)
     .Build);

   --  Complete widget style for class 'tab-left'::label
   function Tab_Left_Class_Label_Widget return Widget_Style is
     (From (Tab_Left_Class_Label_Base_Style)
     .On (When_State (State_Selected), Tab_Left_Class_Label_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'tab-left'
   function Tab_Left_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tab_Left_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tab-right'
   function Tab_Right_Class_Widget return Widget_Style is
     (From (Tab_Right_Class_Base_Style)
     .On (When_State (State_Hovered), Tab_Right_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Right_Class_Widget_Selected_Style)
     .Build);

   --  Complete widget style for class 'tab-right'::label
   function Tab_Right_Class_Label_Widget return Widget_Style is
     (From (Tab_Right_Class_Label_Base_Style)
     .On (When_State (State_Selected), Tab_Right_Class_Label_Widget_Selected_Style)
     .Build);

   --  Part styles bundle for class 'tab-right'
   function Tab_Right_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tab_Right_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'stack'
   function Stack_Class_Widget return Widget_Style is
     (From (Stack_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'stack'
   function Stack_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Stack_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'page-preview'
   function Page_Preview_Class_Widget return Widget_Style is
     (From (Page_Preview_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'page-preview'
   function Page_Preview_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Page_Preview_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'page-source'
   function Page_Source_Class_Widget return Widget_Style is
     (From (Page_Source_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'page-source'
   function Page_Source_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Page_Source_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'html-view'
   function Html_View_Class_Widget return Widget_Style is
     (From (Html_View_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'html-view'::knob
   function Html_View_Class_Knob_Widget return Widget_Style is
     (From (Html_View_Class_Knob_Base_Style)
     .Build);

   --  Complete widget style for class 'html-view'::scroll
   function Html_View_Class_Scroll_Widget return Widget_Style is
     (From (Html_View_Class_Scroll_Base_Style)
     .Build);

   --  Part styles bundle for class 'html-view'
   function Html_View_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Html_View_Class_Widget, Enabled => True),
      Knob_Part => (Style => Html_View_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Html_View_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'source-editor'
   function Source_Editor_Class_Widget return Widget_Style is
     (From (Source_Editor_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'source-editor'::cursor
   function Source_Editor_Class_Cursor_Widget return Widget_Style is
     (From (Source_Editor_Class_Cursor_Base_Style)
     .Build);

   --  Complete widget style for class 'source-editor'::knob
   function Source_Editor_Class_Knob_Widget return Widget_Style is
     (From (Source_Editor_Class_Knob_Base_Style)
     .Build);

   --  Complete widget style for class 'source-editor'::scroll
   function Source_Editor_Class_Scroll_Widget return Widget_Style is
     (From (Source_Editor_Class_Scroll_Base_Style)
     .Build);

   --  Complete widget style for class 'source-editor'::selected
   function Source_Editor_Class_Selected_Widget return Widget_Style is
     (From (Source_Editor_Class_Selected_Base_Style)
     .Build);

   --  Complete widget style for class 'source-editor'::text
   function Source_Editor_Class_Text_Widget return Widget_Style is
     (From (Source_Editor_Class_Text_Base_Style)
     .Build);

   --  Part styles bundle for class 'source-editor'
   function Source_Editor_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Source_Editor_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Source_Editor_Class_Cursor_Widget, Enabled => True),
      Knob_Part => (Style => Source_Editor_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Source_Editor_Class_Scroll_Widget, Enabled => True),
      Selected_Part => (Style => Source_Editor_Class_Selected_Widget, Enabled => True),
      Text_Part => (Style => Source_Editor_Class_Text_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'bottom-bar'
   function Bottom_Bar_Class_Widget return Widget_Style is
     (From (Bottom_Bar_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'bottom-bar'
   function Bottom_Bar_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Bottom_Bar_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'zoom-slider'
   function Zoom_Slider_Class_Widget return Widget_Style is
     (From (Zoom_Slider_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'zoom-slider'::indicator
   function Zoom_Slider_Class_Indicator_Widget return Widget_Style is
     (From (Zoom_Slider_Class_Indicator_Base_Style)
     .Build);

   --  Complete widget style for class 'zoom-slider'::knob
   function Zoom_Slider_Class_Knob_Widget return Widget_Style is
     (From (Zoom_Slider_Class_Knob_Base_Style)
     .On (When_State (State_Hovered), Zoom_Slider_Class_Knob_Widget_Hovered_Style)
     .Build);

   --  Complete widget style for class 'zoom-slider'::label
   function Zoom_Slider_Class_Label_Widget return Widget_Style is
     (From (Zoom_Slider_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'zoom-slider'
   function Zoom_Slider_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Zoom_Slider_Class_Widget, Enabled => True),
      Indicator_Part => (Style => Zoom_Slider_Class_Indicator_Widget, Enabled => True),
      Knob_Part => (Style => Zoom_Slider_Class_Knob_Widget, Enabled => True),
      Label_Part => (Style => Zoom_Slider_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'status'
   function Status_Class_Widget return Widget_Style is
     (From (Status_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'status'::label
   function Status_Class_Label_Widget return Widget_Style is
     (From (Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'status'
   function Status_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
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

end Html_View_Example_Styles;