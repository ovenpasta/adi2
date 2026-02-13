--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Html_View_Example_Styles is

   --  Base style for class 'root'
   Root_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (244, 239, 231)),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      others => <>
   );

   --  Base style for class 'title'
   Title_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'title'::label
   Title_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (54, 46, 37)),
      Font_Size => Set_Font (Px (24.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>
   );

   --  Base style for class 'subtitle'
   Subtitle_Class_Base_Style : constant Style_Rules := (
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'subtitle'::label
   Subtitle_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (97, 88, 77)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'tab-bar'
   Tab_Bar_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Shrink => Set (0.0),
      others => <>
   );

   --  Base style for class 'tab-left'
   Tab_Left_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (178, 159, 136))),
      Background_Color => Set_Bg (RGB (224, 212, 194)),
      Cursor => Set (Cursor_Pointer),
      Border_Radius => Set (Radius (Px (8.0), Px (0.0), Px (0.0), Px (8.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (14.0), Px (8.0), Px (14.0))),
      others => <>
   );

   --  Style for class 'tab-left' when widget State_Hovered
   Tab_Left_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (233, 221, 205)),
      others => <>
   );

   --  Style for class 'tab-left' when widget State_Selected
   Tab_Left_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (120, 96, 71)),
      Border_Color => Set (Border_Color (RGB (100, 80, 58))),
      others => <>
   );

   --  Base style for class 'tab-left'::label
   Tab_Left_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (70, 61, 50)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Style for class 'tab-left'::label when widget State_Selected
   Tab_Left_Class_Label_Widget_Selected_Style : constant Style_Rules := (
      Color => Set (RGB (255, 250, 242)),
      others => <>
   );

   --  Base style for class 'tab-right'
   Tab_Right_Class_Base_Style : constant Style_Rules := (
      Display => Set (Inline_Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (178, 159, 136))),
      Background_Color => Set_Bg (RGB (224, 212, 194)),
      Cursor => Set (Cursor_Pointer),
      Border_Radius => Set (Radius (Px (0.0), Px (8.0), Px (8.0), Px (0.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (14.0), Px (8.0), Px (14.0))),
      others => <>
   );

   --  Style for class 'tab-right' when widget State_Hovered
   Tab_Right_Class_Widget_Hovered_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (233, 221, 205)),
      others => <>
   );

   --  Style for class 'tab-right' when widget State_Selected
   Tab_Right_Class_Widget_Selected_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (120, 96, 71)),
      Border_Color => Set (Border_Color (RGB (100, 80, 58))),
      others => <>
   );

   --  Base style for class 'tab-right'::label
   Tab_Right_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (70, 61, 50)),
      Font_Size => Set_Font (Px (13.0)),
      Font_Weight => Set (Weight_Semi_Bold),
      Text_Wrap_Mode => Set (TWM_Nowrap),
      others => <>
   );

   --  Style for class 'tab-right'::label when widget State_Selected
   Tab_Right_Class_Label_Widget_Selected_Style : constant Style_Rules := (
      Color => Set (RGB (255, 250, 242)),
      others => <>
   );

   --  Base style for class 'stack'
   Stack_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      others => <>
   );

   --  Base style for class 'page-preview'
   Page_Preview_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      others => <>
   );

   --  Base style for class 'page-source'
   Page_Source_Class_Base_Style : constant Style_Rules := (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      others => <>
   );

   --  Base style for class 'html-view'
   Html_View_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      Overflow => Set (Overflow_Auto),
      Background_Color => Set_Bg (RGB (255, 252, 247)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (212, 199, 183))),
      Border_Radius => Set (Radius (Px (10.0))),
      Padding => Set (CSS_Box (Px (14.0), Px (14.0), Px (14.0), Px (14.0))),
      others => <>
   );

   --  Base style for class 'html-view'::knob
   Html_View_Class_Knob_Base_Style : constant Style_Rules := (
      Min_Height => Set (Size (Px (26.0))),
      Background_Color => Set_Bg (RGBA (112, 92, 69, 0.7)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>
   );

   --  Base style for class 'html-view'::scroll
   Html_View_Class_Scroll_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (9.0))),
      Background_Color => Set_Bg (RGBA (127, 103, 75, 0.55)),
      Border_Radius => Set (Radius (Px (5.0))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      others => <>
   );

   --  Base style for class 'source-editor'
   Source_Editor_Class_Base_Style : constant Style_Rules := (
      Flex_Grow => Set (1.0),
      Min_Height => Set (Size (Px (0.0))),
      Background_Color => Set_Bg (RGB (252, 248, 242)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (212, 199, 183))),
      Border_Radius => Set (Radius (Px (10.0))),
      Overflow => Set (Overflow_Auto),
      Padding => Set (CSS_Box (Px (12.0), Px (12.0), Px (12.0), Px (12.0))),
      others => <>
   );

   --  Base style for class 'source-editor'::cursor
   Source_Editor_Class_Cursor_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGB (86, 69, 49)),
      others => <>
   );

   --  Base style for class 'source-editor'::knob
   Source_Editor_Class_Knob_Base_Style : constant Style_Rules := (
      Min_Height => Set (Size (Px (26.0))),
      Background_Color => Set_Bg (RGBA (112, 92, 69, 0.66)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>
   );

   --  Base style for class 'source-editor'::label
   Source_Editor_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (58, 52, 45)),
      Font_Size => Set_Font (Px (14.0)),
      others => <>
   );

   --  Base style for class 'source-editor'::scroll
   Source_Editor_Class_Scroll_Base_Style : constant Style_Rules := (
      Width => Set (Size (Px (8.0))),
      Background_Color => Set_Bg (RGBA (160, 142, 121, 0.28)),
      Border_Radius => Set (Radius (Px (4.0))),
      Padding => Set (CSS_Box (Px (2.0), Px (2.0), Px (2.0), Px (2.0))),
      others => <>
   );

   --  Base style for class 'source-editor'::selected
   Source_Editor_Class_Selected_Base_Style : constant Style_Rules := (
      Background_Color => Set_Bg (RGBA (134, 111, 86, 0.28)),
      others => <>
   );

   --  Base style for class 'status'
   Status_Class_Base_Style : constant Style_Rules := (
      Min_Height => Set (Size (Px (34.0))),
      Flex_Shrink => Set (0.0),
      Background_Color => Set_Bg (RGB (236, 229, 218)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (212, 199, 183))),
      Border_Radius => Set (Radius (Px (8.0))),
      Padding => Set (CSS_Box (Px (8.0), Px (10.0), Px (8.0), Px (10.0))),
      others => <>
   );

   --  Base style for class 'status'::label
   Status_Class_Label_Base_Style : constant Style_Rules := (
      Color => Set (RGB (72, 65, 55)),
      Font_Size => Set_Font (Px (13.0)),
      others => <>
   );

   --  Complete widget style for class 'root'
   Root_Class_Widget : constant Widget_Style :=
     From (Root_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'title'
   Title_Class_Widget : constant Widget_Style :=
     From (Title_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'title'::label
   Title_Class_Label_Widget : constant Widget_Style :=
     From (Title_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'title'
   Title_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Title_Class_Widget, Enabled => True),
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'subtitle'
   Subtitle_Class_Widget : constant Widget_Style :=
     From (Subtitle_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'subtitle'::label
   Subtitle_Class_Label_Widget : constant Widget_Style :=
     From (Subtitle_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'subtitle'
   Subtitle_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Subtitle_Class_Widget, Enabled => True),
      Label_Part => (Style => Subtitle_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tab-bar'
   Tab_Bar_Class_Widget : constant Widget_Style :=
     From (Tab_Bar_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'tab-bar'
   Tab_Bar_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Bar_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tab-left'
   Tab_Left_Class_Widget : constant Widget_Style :=
     From (Tab_Left_Class_Base_Style)
     .On (When_State (State_Hovered), Tab_Left_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Left_Class_Widget_Selected_Style)
     .Build;

   --  Complete widget style for class 'tab-left'::label
   Tab_Left_Class_Label_Widget : constant Widget_Style :=
     From (Tab_Left_Class_Label_Base_Style)
     .On (When_State (State_Selected), Tab_Left_Class_Label_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for class 'tab-left'
   Tab_Left_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Left_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Left_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'tab-right'
   Tab_Right_Class_Widget : constant Widget_Style :=
     From (Tab_Right_Class_Base_Style)
     .On (When_State (State_Hovered), Tab_Right_Class_Widget_Hovered_Style)
     .On (When_State (State_Selected), Tab_Right_Class_Widget_Selected_Style)
     .Build;

   --  Complete widget style for class 'tab-right'::label
   Tab_Right_Class_Label_Widget : constant Widget_Style :=
     From (Tab_Right_Class_Label_Base_Style)
     .On (When_State (State_Selected), Tab_Right_Class_Label_Widget_Selected_Style)
     .Build;

   --  Part styles bundle for class 'tab-right'
   Tab_Right_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Tab_Right_Class_Widget, Enabled => True),
      Label_Part => (Style => Tab_Right_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'stack'
   Stack_Class_Widget : constant Widget_Style :=
     From (Stack_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'stack'
   Stack_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Stack_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-preview'
   Page_Preview_Class_Widget : constant Widget_Style :=
     From (Page_Preview_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-preview'
   Page_Preview_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Preview_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'page-source'
   Page_Source_Class_Widget : constant Widget_Style :=
     From (Page_Source_Class_Base_Style)
     .Build;

   --  Part styles bundle for class 'page-source'
   Page_Source_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Page_Source_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'html-view'
   Html_View_Class_Widget : constant Widget_Style :=
     From (Html_View_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'html-view'::knob
   Html_View_Class_Knob_Widget : constant Widget_Style :=
     From (Html_View_Class_Knob_Base_Style)
     .Build;

   --  Complete widget style for class 'html-view'::scroll
   Html_View_Class_Scroll_Widget : constant Widget_Style :=
     From (Html_View_Class_Scroll_Base_Style)
     .Build;

   --  Part styles bundle for class 'html-view'
   Html_View_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Html_View_Class_Widget, Enabled => True),
      Knob_Part => (Style => Html_View_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Html_View_Class_Scroll_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'source-editor'
   Source_Editor_Class_Widget : constant Widget_Style :=
     From (Source_Editor_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'source-editor'::cursor
   Source_Editor_Class_Cursor_Widget : constant Widget_Style :=
     From (Source_Editor_Class_Cursor_Base_Style)
     .Build;

   --  Complete widget style for class 'source-editor'::knob
   Source_Editor_Class_Knob_Widget : constant Widget_Style :=
     From (Source_Editor_Class_Knob_Base_Style)
     .Build;

   --  Complete widget style for class 'source-editor'::label
   Source_Editor_Class_Label_Widget : constant Widget_Style :=
     From (Source_Editor_Class_Label_Base_Style)
     .Build;

   --  Complete widget style for class 'source-editor'::scroll
   Source_Editor_Class_Scroll_Widget : constant Widget_Style :=
     From (Source_Editor_Class_Scroll_Base_Style)
     .Build;

   --  Complete widget style for class 'source-editor'::selected
   Source_Editor_Class_Selected_Widget : constant Widget_Style :=
     From (Source_Editor_Class_Selected_Base_Style)
     .Build;

   --  Part styles bundle for class 'source-editor'
   Source_Editor_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Source_Editor_Class_Widget, Enabled => True),
      Cursor_Part => (Style => Source_Editor_Class_Cursor_Widget, Enabled => True),
      Knob_Part => (Style => Source_Editor_Class_Knob_Widget, Enabled => True),
      Label_Part => (Style => Source_Editor_Class_Label_Widget, Enabled => True),
      Scroll_Part => (Style => Source_Editor_Class_Scroll_Widget, Enabled => True),
      Selected_Part => (Style => Source_Editor_Class_Selected_Widget, Enabled => True),
      others => <>
   ];

   --  Complete widget style for class 'status'
   Status_Class_Widget : constant Widget_Style :=
     From (Status_Class_Base_Style)
     .Build;

   --  Complete widget style for class 'status'::label
   Status_Class_Label_Widget : constant Widget_Style :=
     From (Status_Class_Label_Base_Style)
     .Build;

   --  Part styles bundle for class 'status'
   Status_Class_Part_Styles : constant Part_Style_Array := [
      Main_Part => (Style => Status_Class_Widget, Enabled => True),
      Label_Part => (Style => Status_Class_Label_Widget, Enabled => True),
      others => <>
   ];

end Html_View_Example_Styles;