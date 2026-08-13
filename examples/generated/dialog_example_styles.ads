--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Dialog_Example_Styles is

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
      Background_Color => Set_Bg (RGB (19, 26, 38)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      others => <>);

   --  Base style for class 'container'
   function Container_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Justify_Content => Set (Flex_Start),
      Gap => Set (Gap (Px (16.0))),
      Background_Color => Set_Bg (RGB (30, 41, 59)),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (10.0))),
      others => <>);

   --  Base style for class 'title'
   function Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'hint'
   function Hint_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'hint'::label
   function Hint_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (186, 204, 230)),
      Font_Size => Set_Font (Px (13.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>);

   --  Base style for class 'status'::label
   function Status_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (147, 197, 253)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>);

   --  Base style for class 'btn-primary'
   function Btn_Primary_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (40.0))),
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      Transition => Set ((Duration => 0.15, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (9.0), Px (16.0), Px (9.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (29, 78, 216))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Style for class 'btn-primary' when widget State_Hovered
   function Btn_Primary_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>);

   --  Style for class 'btn-primary' when widget State_Pressed
   function Btn_Primary_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      Border_Color => Set (Border_Color (RGB (30, 64, 175))),
      others => <>);

   --  Base style for class 'btn-primary'::label
   function Btn_Primary_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Align => Set (Text_Center),
      Vertical_Align => Set (VA_Middle),
      White_Space => Set (WS_Nowrap),
      others => <>);

   --  Base style for class 'backdrop'
   function Backdrop_Class_Base_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (0, 0, 0, 0.45)),
      others => <>);

   --  Base style for class 'panel'
   function Panel_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Stretch),
      Gap => Set (Gap (Px (16.0))),
      Min_Width => Set (Size (Px (340.0))),
      Max_Width => Set (Size (Px (480.0))),
      Background_Color => Set_Bg (RGB (255, 255, 255)),
      Box_Shadow => Set (Shadow (Px (0.0), Px (16.0), Px (48.0), Px (0.0), RGBA (0, 0, 0, 0.3))),
      Padding => Set (CSS_Box (Px (24.0), Px (24.0), Px (24.0), Px (24.0))),
      Border_Radius => Set (Radius (Px (12.0))),
      others => <>);

   --  Base style for class 'dialog-message'
   function Dialog_Message_Class_Base_Style return Style_Rules is
     (
      Flex_Direction => Set (Row),
      Align_Items => Set (Flex_Start),
      Gap => Set (Gap (Px (12.0))),
      others => <>);

   --  Base style for class 'dialog-message'::icon
   function Dialog_Message_Class_Icon_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (32.0))),
      Height => Set (Size (Px (32.0))),
      others => <>);

   --  Base style for class 'dialog-message'::label
   function Dialog_Message_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (71, 85, 105)),
      Font_Size => Set_Font (Px (14.0)),
      Text_Wrap_Mode => Set (TWM_Wrap),
      others => <>);

   --  Base style for class 'dialog-title'
   function Dialog_Title_Class_Base_Style return Style_Rules is
     (
      others => <>);

   --  Base style for class 'dialog-title'::label
   function Dialog_Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (15, 23, 42)),
      Font_Size => Set_Font (Px (18.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'button-row'
   function Button_Row_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Justify_Content => Set (Flex_End),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      others => <>);

   --  Base style for class 'dialog-btn'
   function Dialog_Btn_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (36.0))),
      Background_Color => Set_Bg (RGB (241, 245, 249)),
      Transition => Set ((Duration => 0.12, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (7.0), Px (16.0), Px (7.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (203, 213, 225))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'dialog-btn' when widget State_Hovered
   function Dialog_Btn_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (226, 232, 240)),
      Border_Color => Set (Border_Color (RGB (148, 163, 184))),
      others => <>);

   --  Style for class 'dialog-btn' when widget State_Pressed
   function Dialog_Btn_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (203, 213, 225)),
      Border_Color => Set (Border_Color (RGB (100, 116, 139))),
      others => <>);

   --  Style for class 'dialog-btn' when widget State_Focused
   function Dialog_Btn_Class_Widget_Focused_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (59, 130, 246, 0.3))),
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      others => <>);

   --  Base style for class 'dialog-btn'::label
   function Dialog_Btn_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (30, 41, 59)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Medium),
      Text_Align => Set (Text_Center),
      Vertical_Align => Set (VA_Middle),
      White_Space => Set (WS_Nowrap),
      others => <>);

   --  Base style for class 'dialog-btn-primary'
   function Dialog_Btn_Primary_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (36.0))),
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      Transition => Set ((Duration => 0.12, Easing => Ease_Out, Properties => Props (Prop_Background_Color) + Props (Prop_Border_Color))),
      Padding => Set (CSS_Box (Px (7.0), Px (16.0), Px (7.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (29, 78, 216))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Style for class 'dialog-btn-primary' when widget State_Hovered
   function Dialog_Btn_Primary_Class_Widget_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (59, 130, 246)),
      Border_Color => Set (Border_Color (RGB (37, 99, 235))),
      others => <>);

   --  Style for class 'dialog-btn-primary' when widget State_Pressed
   function Dialog_Btn_Primary_Class_Widget_Pressed_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGB (29, 78, 216)),
      Border_Color => Set (Border_Color (RGB (30, 64, 175))),
      others => <>);

   --  Style for class 'dialog-btn-primary' when widget State_Focused
   function Dialog_Btn_Primary_Class_Widget_Focused_Style return Style_Rules is
     (
      Box_Shadow => Set (Shadow (Px (0.0), Px (0.0), Px (0.0), Px (2.0), RGBA (59, 130, 246, 0.3))),
      Border_Color => Set (Border_Color (RGB (59, 130, 246))),
      others => <>);

   --  Base style for class 'dialog-btn-primary'::label
   function Dialog_Btn_Primary_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (C (White)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Align => Set (Text_Center),
      Vertical_Align => Set (VA_Middle),
      White_Space => Set (WS_Nowrap),
      others => <>);

   --  Base style for class 'custom-content'
   function Custom_Content_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (248, 250, 252)),
      Padding => Set (CSS_Box (Px (12.0), Px (16.0), Px (12.0), Px (16.0))),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (226, 232, 240))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'detail-label'::label
   function Detail_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (51, 65, 85)),
      Font_Size => Set_Font (Px (14.0)),
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

   --  Complete widget style for class 'container'
   function Container_Class_Widget return Widget_Style is
     (From (Container_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'container'
   function Container_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
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

   --  Complete widget style for class 'hint'
   function Hint_Class_Widget return Widget_Style is
     (From (Hint_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'hint'::label
   function Hint_Class_Label_Widget return Widget_Style is
     (From (Hint_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'hint'
   function Hint_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Hint_Class_Widget, Enabled => True),
      Label_Part => (Style => Hint_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'status'::label
   function Status_Class_Label_Widget return Widget_Style is
     (From (Status_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'status'
   function Status_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'btn-primary'
   function Btn_Primary_Class_Widget return Widget_Style is
     (From (Btn_Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Btn_Primary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Btn_Primary_Class_Widget_Pressed_Style)
     .Build);

   --  Complete widget style for class 'btn-primary'::label
   function Btn_Primary_Class_Label_Widget return Widget_Style is
     (From (Btn_Primary_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'btn-primary'
   function Btn_Primary_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'backdrop'
   function Backdrop_Class_Widget return Widget_Style is
     (From (Backdrop_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'backdrop'
   function Backdrop_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Backdrop_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'panel'
   function Panel_Class_Widget return Widget_Style is
     (From (Panel_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'panel'
   function Panel_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Panel_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-message'
   function Dialog_Message_Class_Widget return Widget_Style is
     (From (Dialog_Message_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'dialog-message'::icon
   function Dialog_Message_Class_Icon_Widget return Widget_Style is
     (From (Dialog_Message_Class_Icon_Base_Style)
     .Build);

   --  Complete widget style for class 'dialog-message'::label
   function Dialog_Message_Class_Label_Widget return Widget_Style is
     (From (Dialog_Message_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-message'
   function Dialog_Message_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Message_Class_Widget, Enabled => True),
      Icon_Part => (Style => Dialog_Message_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Message_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-title'
   function Dialog_Title_Class_Widget return Widget_Style is
     (From (Dialog_Title_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'dialog-title'::label
   function Dialog_Title_Class_Label_Widget return Widget_Style is
     (From (Dialog_Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-title'
   function Dialog_Title_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'button-row'
   function Button_Row_Class_Widget return Widget_Style is
     (From (Button_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'button-row'
   function Button_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Button_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-btn'
   function Dialog_Btn_Class_Widget return Widget_Style is
     (From (Dialog_Btn_Class_Base_Style)
     .On (When_State (State_Hovered), Dialog_Btn_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Dialog_Btn_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Dialog_Btn_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'dialog-btn'::label
   function Dialog_Btn_Class_Label_Widget return Widget_Style is
     (From (Dialog_Btn_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-btn'
   function Dialog_Btn_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Btn_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dialog-btn-primary'
   function Dialog_Btn_Primary_Class_Widget return Widget_Style is
     (From (Dialog_Btn_Primary_Class_Base_Style)
     .On (When_State (State_Hovered), Dialog_Btn_Primary_Class_Widget_Hovered_Style)
     .On (When_State (State_Pressed), Dialog_Btn_Primary_Class_Widget_Pressed_Style)
     .On (When_State (State_Focused), Dialog_Btn_Primary_Class_Widget_Focused_Style)
     .Build);

   --  Complete widget style for class 'dialog-btn-primary'::label
   function Dialog_Btn_Primary_Class_Label_Widget return Widget_Style is
     (From (Dialog_Btn_Primary_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'dialog-btn-primary'
   function Dialog_Btn_Primary_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dialog_Btn_Primary_Class_Widget, Enabled => True),
      Label_Part => (Style => Dialog_Btn_Primary_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'custom-content'
   function Custom_Content_Class_Widget return Widget_Style is
     (From (Custom_Content_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'custom-content'
   function Custom_Content_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Custom_Content_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'detail-label'::label
   function Detail_Label_Class_Label_Widget return Widget_Style is
     (From (Detail_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'detail-label'
   function Detail_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Detail_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Dialog_Example_Styles;