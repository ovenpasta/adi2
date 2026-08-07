--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Demo_Flex_Styles is

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
      Gap => Set (Gap (Px (18.0))),
      Background_Color => Set_Bg (RGB (24, 26, 33)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Overflow_Y => Set_Overflow_Y (Overflow_Auto),
      others => <>);

   --  Base style for class 'root'::knob
   function Root_Class_Knob_Base_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (129, 161, 193, 0.3)), Gradient_Stop_Auto (RGBA (94, 129, 172, 0.3)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => All_Properties)),
      Border_Width => Set (Border_Width (Px (1.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.1))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::knob when part State_Hovered
   function Root_Class_Knob_Part_Hovered_Style return Style_Rules is
     (
      Background_Image => Set_Bg_Image (Linear_Gradient (90.0, [Gradient_Stop_Auto (RGBA (143, 176, 209, 0.85)), Gradient_Stop_Auto (RGBA (108, 143, 186, 0.85)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black)), Gradient_Stop_Auto (C (Black))], 2)),
      Border_Color => Set (Border_Color (RGBA (236, 239, 244, 0.28))),
      others => <>);

   --  Base style for class 'root'::scroll
   function Root_Class_Scroll_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (10.0))),
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.06)),
      Transition => Set ((Duration => 0.16, Easing => Ease_Out, Properties => Props (Prop_Background_Color))),
      Border_Radius => Set (Radius (Px (5.0))),
      others => <>);

   --  Style for class 'root'::scroll when part State_Hovered
   function Root_Class_Scroll_Part_Hovered_Style return Style_Rules is
     (
      Background_Color => Set_Bg (RGBA (94, 129, 172, 0.16)),
      others => <>);

   --  Base style for class 'title'::label
   function Title_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (236, 239, 244)),
      Font_Size => Set_Font (Px (22.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'section'
   function Section_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (6.0))),
      Flex_Shrink => Set (0.0),
      Padding => Set (CSS_Box (Px (0.0), Px (14.0), Px (0.0), Px (0.0))),
      others => <>);

   --  Base style for class 'caption'::label
   function Caption_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (163, 190, 140)),
      Font_Size => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Bold),
      others => <>);

   --  Base style for class 'note'::label
   function Note_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (150, 158, 172)),
      Font_Size => Set_Font (Px (12.0)),
      others => <>);

   --  Base style for class 'cases'
   function Cases_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Flex_Wrap => Set (Wrap),
      Gap => Set (Gap (Px (12.0))),
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'case'
   function Case_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (4.0))),
      Flex_Grow => Set (1.0),
      Min_Width => Set (Size (Px (0.0))),
      others => <>);

   --  Base style for class 'case-label'::label
   function Case_Label_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (150, 158, 172)),
      Font_Size => Set_Font (Px (11.0)),
      others => <>);

   --  Base style for class 'demo'
   function Demo_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (6.0))),
      Background_Color => Set_Bg (RGB (35, 38, 48)),
      Padding => Set (CSS_Box (Px (6.0), Px (6.0), Px (6.0), Px (6.0))),
      Border_Width => Set (Border_Width (Px (2.0))),
      Border_Style => Set (Border_Style (Solid)),
      Border_Color => Set (Border_Color (RGB (94, 129, 172))),
      Border_Radius => Set (Radius (Px (6.0))),
      others => <>);

   --  Base style for class 'item'
   function Item_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Justify_Content => Set (Center),
      Align_Items => Set (Center),
      Width => Set (Size (Px (26.0))),
      Height => Set (Size (Px (26.0))),
      Background_Color => Set_Bg (RGB (94, 129, 172)),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'item'::label
   function Item_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (240, 243, 248)),
      Font_Size => Set_Font (Px (12.0)),
      Font_Weight => Set (Weight_Bold),
      Text_Align => Set (Text_Center),
      others => <>);

   --  Base style for class 'tall'
   function Tall_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (70.0))),
      others => <>);

   --  Base style for class 'short'
   function Short_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (46.0))),
      others => <>);

   --  Base style for class 'bar'
   function Bar_Class_Base_Style return Style_Rules is
     (
      Width => Set (Auto_Size),
      others => <>);

   --  Base style for class 'dir-row'
   function Dir_Row_Class_Base_Style return Style_Rules is
     (
      Flex_Direction => Set (Row),
      others => <>);

   --  Base style for class 'dir-row-rev'
   function Dir_Row_Rev_Class_Base_Style return Style_Rules is
     (
      Flex_Direction => Set (Row_Reverse),
      others => <>);

   --  Base style for class 'dir-col'
   function Dir_Col_Class_Base_Style return Style_Rules is
     (
      Flex_Direction => Set (Column),
      others => <>);

   --  Base style for class 'dir-col-rev'
   function Dir_Col_Rev_Class_Base_Style return Style_Rules is
     (
      Flex_Direction => Set (Column_Reverse),
      others => <>);

   --  Base style for class 'grow-1'
   function Grow_1_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (1.0),
      Background_Color => Set_Bg (RGB (163, 190, 140)),
      others => <>);

   --  Base style for class 'grow-2'
   function Grow_2_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (2.0),
      Background_Color => Set_Bg (RGB (235, 203, 139)),
      others => <>);

   --  Base style for class 'grow-0'
   function Grow_0_Class_Base_Style return Style_Rules is
     (
      Flex_Grow => Set (0.0),
      Width => Set (Size (Px (70.0))),
      others => <>);

   --  Base style for class 'w320'
   function W320_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (320.0))),
      others => <>);

   --  Base style for class 'shrink-yes'
   function Shrink_Yes_Class_Base_Style return Style_Rules is
     (
      Flex_Basis => Set (Basis (Px (160.0))),
      Flex_Shrink => Set (1.0),
      Min_Width => Set (Size (Px (0.0))),
      Background_Color => Set_Bg (RGB (163, 190, 140)),
      others => <>);

   --  Base style for class 'shrink-no'
   function Shrink_No_Class_Base_Style return Style_Rules is
     (
      Flex_Basis => Set (Basis (Px (160.0))),
      Flex_Shrink => Set (0.0),
      Background_Color => Set_Bg (RGB (191, 97, 106)),
      others => <>);

   --  Base style for class 'basis-40'
   function Basis_40_Class_Base_Style return Style_Rules is
     (
      Flex_Basis => Set (Basis (Px (40.0))),
      Flex_Grow => Set (1.0),
      Background_Color => Set_Bg (RGB (163, 190, 140)),
      others => <>);

   --  Base style for class 'basis-120'
   function Basis_120_Class_Base_Style return Style_Rules is
     (
      Flex_Basis => Set (Basis (Px (120.0))),
      Flex_Grow => Set (1.0),
      Background_Color => Set_Bg (RGB (235, 203, 139)),
      others => <>);

   --  Base style for class 'basis-200'
   function Basis_200_Class_Base_Style return Style_Rules is
     (
      Flex_Basis => Set (Basis (Px (200.0))),
      Flex_Grow => Set (1.0),
      Background_Color => Set_Bg (RGB (180, 142, 173)),
      others => <>);

   --  Base style for class 'just-start'
   function Just_Start_Class_Base_Style return Style_Rules is
     (
      Justify_Content => Set (Flex_Start),
      others => <>);

   --  Base style for class 'just-center'
   function Just_Center_Class_Base_Style return Style_Rules is
     (
      Justify_Content => Set (Center),
      others => <>);

   --  Base style for class 'just-end'
   function Just_End_Class_Base_Style return Style_Rules is
     (
      Justify_Content => Set (Flex_End),
      others => <>);

   --  Base style for class 'just-around'
   function Just_Around_Class_Base_Style return Style_Rules is
     (
      Justify_Content => Set (Space_Around),
      others => <>);

   --  Base style for class 'just-between'
   function Just_Between_Class_Base_Style return Style_Rules is
     (
      Justify_Content => Set (Space_Between),
      others => <>);

   --  Base style for class 'just-evenly'
   function Just_Evenly_Class_Base_Style return Style_Rules is
     (
      Justify_Content => Set (Space_Evenly),
      others => <>);

   --  Base style for class 'align-start'
   function Align_Start_Class_Base_Style return Style_Rules is
     (
      Align_Items => Set (Flex_Start),
      others => <>);

   --  Base style for class 'align-center'
   function Align_Center_Class_Base_Style return Style_Rules is
     (
      Align_Items => Set (Center),
      others => <>);

   --  Base style for class 'align-end'
   function Align_End_Class_Base_Style return Style_Rules is
     (
      Align_Items => Set (Flex_End),
      others => <>);

   --  Base style for class 'align-stretch'
   function Align_Stretch_Class_Base_Style return Style_Rules is
     (
      Align_Items => Set (Stretch),
      others => <>);

   --  Base style for class 'h20'
   function H20_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (20.0))),
      others => <>);

   --  Base style for class 'h40'
   function H40_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (40.0))),
      Background_Color => Set_Bg (RGB (94, 129, 172)),
      others => <>);

   --  Base style for class 'h-auto'
   function H_Auto_Class_Base_Style return Style_Rules is
     (
      Height => Set (Auto_Size),
      Background_Color => Set_Bg (RGB (180, 142, 173)),
      others => <>);

   --  Base style for class 'w480'
   function W480_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (480.0))),
      others => <>);

   --  Base style for class 'w170'
   function W170_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (170.0))),
      others => <>);

   --  Base style for class 'h120'
   function H120_Class_Base_Style return Style_Rules is
     (
      Height => Set (Size (Px (120.0))),
      others => <>);

   --  Base style for class 'nowrap'
   function Nowrap_Class_Base_Style return Style_Rules is
     (
      Flex_Wrap => Set (No_Wrap),
      others => <>);

   --  Base style for class 'wrap'
   function Wrap_Class_Base_Style return Style_Rules is
     (
      Flex_Wrap => Set (Wrap),
      others => <>);

   --  Base style for class 'wrap-reverse'
   function Wrap_Reverse_Class_Base_Style return Style_Rules is
     (
      Flex_Wrap => Set (Wrap_Reverse),
      others => <>);

   --  Base style for class 'ac-start'
   function Ac_Start_Class_Base_Style return Style_Rules is
     (
      Align_Content => Set (Flex_Start),
      others => <>);

   --  Base style for class 'ac-center'
   function Ac_Center_Class_Base_Style return Style_Rules is
     (
      Align_Content => Set (Center),
      others => <>);

   --  Base style for class 'ac-end'
   function Ac_End_Class_Base_Style return Style_Rules is
     (
      Align_Content => Set (Flex_End),
      others => <>);

   --  Base style for class 'ac-between'
   function Ac_Between_Class_Base_Style return Style_Rules is
     (
      Align_Content => Set (Space_Between),
      others => <>);

   --  Base style for class 'ac-around'
   function Ac_Around_Class_Base_Style return Style_Rules is
     (
      Align_Content => Set (Space_Around),
      others => <>);

   --  Base style for class 'ac-stretch'
   function Ac_Stretch_Class_Base_Style return Style_Rules is
     (
      Align_Content => Set (Stretch),
      others => <>);

   --  Base style for class 'tile'
   function Tile_Class_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (40.0))),
      Height => Set (Size (Px (34.0))),
      Flex_Grow => Set (0.0),
      Flex_Shrink => Set (0.0),
      others => <>);

   --  Base style for class 'pinned'
   function Pinned_Class_Base_Style return Style_Rules is
     (
      Flex_Basis => Set (Basis (Px (90.0))),
      Min_Width => Set (Size (Px (90.0))),
      Flex_Shrink => Set (1.0),
      Background_Color => Set_Bg (RGB (191, 97, 106)),
      others => <>);

   --  Base style for class 'elastic'
   function Elastic_Class_Base_Style return Style_Rules is
     (
      Flex_Basis => Set (Basis (Px (220.0))),
      Min_Width => Set (Size (Px (0.0))),
      Flex_Shrink => Set (1.0),
      Background_Color => Set_Bg (RGB (163, 190, 140)),
      others => <>);

   --  Complete widget style for class 'root'
   function Root_Class_Widget return Widget_Style is
     (From (Root_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'root'::knob
   function Root_Class_Knob_Widget return Widget_Style is
     (From (Root_Class_Knob_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Knob_Part_Hovered_Style)
     .Build);

   --  Complete widget style for class 'root'::scroll
   function Root_Class_Scroll_Widget return Widget_Style is
     (From (Root_Class_Scroll_Base_Style)
     .On (When_Part_State (State_Hovered), Root_Class_Scroll_Part_Hovered_Style)
     .Build);

   --  Part styles bundle for class 'root'
   function Root_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      Knob_Part => (Style => Root_Class_Knob_Widget, Enabled => True),
      Scroll_Part => (Style => Root_Class_Scroll_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'title'::label
   function Title_Class_Label_Widget return Widget_Style is
     (From (Title_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'title'
   function Title_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Title_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'section'
   function Section_Class_Widget return Widget_Style is
     (From (Section_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'section'
   function Section_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Section_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'caption'::label
   function Caption_Class_Label_Widget return Widget_Style is
     (From (Caption_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'caption'
   function Caption_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Caption_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'note'::label
   function Note_Class_Label_Widget return Widget_Style is
     (From (Note_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'note'
   function Note_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Note_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'cases'
   function Cases_Class_Widget return Widget_Style is
     (From (Cases_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'cases'
   function Cases_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Cases_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'case'
   function Case_Class_Widget return Widget_Style is
     (From (Case_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'case'
   function Case_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Case_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'case-label'::label
   function Case_Label_Class_Label_Widget return Widget_Style is
     (From (Case_Label_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'case-label'
   function Case_Label_Class_Part_Styles return Part_Style_Array is
     ([
      Label_Part => (Style => Case_Label_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'demo'
   function Demo_Class_Widget return Widget_Style is
     (From (Demo_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'demo'
   function Demo_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Demo_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'item'
   function Item_Class_Widget return Widget_Style is
     (From (Item_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'item'::label
   function Item_Class_Label_Widget return Widget_Style is
     (From (Item_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'item'
   function Item_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Item_Class_Widget, Enabled => True),
      Label_Part => (Style => Item_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tall'
   function Tall_Class_Widget return Widget_Style is
     (From (Tall_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tall'
   function Tall_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tall_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'short'
   function Short_Class_Widget return Widget_Style is
     (From (Short_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'short'
   function Short_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Short_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'bar'
   function Bar_Class_Widget return Widget_Style is
     (From (Bar_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'bar'
   function Bar_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Bar_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dir-row'
   function Dir_Row_Class_Widget return Widget_Style is
     (From (Dir_Row_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dir-row'
   function Dir_Row_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dir_Row_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dir-row-rev'
   function Dir_Row_Rev_Class_Widget return Widget_Style is
     (From (Dir_Row_Rev_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dir-row-rev'
   function Dir_Row_Rev_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dir_Row_Rev_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dir-col'
   function Dir_Col_Class_Widget return Widget_Style is
     (From (Dir_Col_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dir-col'
   function Dir_Col_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dir_Col_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'dir-col-rev'
   function Dir_Col_Rev_Class_Widget return Widget_Style is
     (From (Dir_Col_Rev_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'dir-col-rev'
   function Dir_Col_Rev_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Dir_Col_Rev_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grow-1'
   function Grow_1_Class_Widget return Widget_Style is
     (From (Grow_1_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grow-1'
   function Grow_1_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grow_1_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grow-2'
   function Grow_2_Class_Widget return Widget_Style is
     (From (Grow_2_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grow-2'
   function Grow_2_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grow_2_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'grow-0'
   function Grow_0_Class_Widget return Widget_Style is
     (From (Grow_0_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'grow-0'
   function Grow_0_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Grow_0_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'w320'
   function W320_Class_Widget return Widget_Style is
     (From (W320_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'w320'
   function W320_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => W320_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'shrink-yes'
   function Shrink_Yes_Class_Widget return Widget_Style is
     (From (Shrink_Yes_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'shrink-yes'
   function Shrink_Yes_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Shrink_Yes_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'shrink-no'
   function Shrink_No_Class_Widget return Widget_Style is
     (From (Shrink_No_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'shrink-no'
   function Shrink_No_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Shrink_No_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'basis-40'
   function Basis_40_Class_Widget return Widget_Style is
     (From (Basis_40_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'basis-40'
   function Basis_40_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Basis_40_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'basis-120'
   function Basis_120_Class_Widget return Widget_Style is
     (From (Basis_120_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'basis-120'
   function Basis_120_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Basis_120_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'basis-200'
   function Basis_200_Class_Widget return Widget_Style is
     (From (Basis_200_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'basis-200'
   function Basis_200_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Basis_200_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'just-start'
   function Just_Start_Class_Widget return Widget_Style is
     (From (Just_Start_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'just-start'
   function Just_Start_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Just_Start_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'just-center'
   function Just_Center_Class_Widget return Widget_Style is
     (From (Just_Center_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'just-center'
   function Just_Center_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Just_Center_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'just-end'
   function Just_End_Class_Widget return Widget_Style is
     (From (Just_End_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'just-end'
   function Just_End_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Just_End_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'just-around'
   function Just_Around_Class_Widget return Widget_Style is
     (From (Just_Around_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'just-around'
   function Just_Around_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Just_Around_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'just-between'
   function Just_Between_Class_Widget return Widget_Style is
     (From (Just_Between_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'just-between'
   function Just_Between_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Just_Between_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'just-evenly'
   function Just_Evenly_Class_Widget return Widget_Style is
     (From (Just_Evenly_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'just-evenly'
   function Just_Evenly_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Just_Evenly_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'align-start'
   function Align_Start_Class_Widget return Widget_Style is
     (From (Align_Start_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'align-start'
   function Align_Start_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Align_Start_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'align-center'
   function Align_Center_Class_Widget return Widget_Style is
     (From (Align_Center_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'align-center'
   function Align_Center_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Align_Center_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'align-end'
   function Align_End_Class_Widget return Widget_Style is
     (From (Align_End_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'align-end'
   function Align_End_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Align_End_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'align-stretch'
   function Align_Stretch_Class_Widget return Widget_Style is
     (From (Align_Stretch_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'align-stretch'
   function Align_Stretch_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Align_Stretch_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'h20'
   function H20_Class_Widget return Widget_Style is
     (From (H20_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'h20'
   function H20_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => H20_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'h40'
   function H40_Class_Widget return Widget_Style is
     (From (H40_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'h40'
   function H40_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => H40_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'h-auto'
   function H_Auto_Class_Widget return Widget_Style is
     (From (H_Auto_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'h-auto'
   function H_Auto_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => H_Auto_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'w480'
   function W480_Class_Widget return Widget_Style is
     (From (W480_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'w480'
   function W480_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => W480_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'w170'
   function W170_Class_Widget return Widget_Style is
     (From (W170_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'w170'
   function W170_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => W170_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'h120'
   function H120_Class_Widget return Widget_Style is
     (From (H120_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'h120'
   function H120_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => H120_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'nowrap'
   function Nowrap_Class_Widget return Widget_Style is
     (From (Nowrap_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'nowrap'
   function Nowrap_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Nowrap_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'wrap'
   function Wrap_Class_Widget return Widget_Style is
     (From (Wrap_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'wrap'
   function Wrap_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Wrap_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'wrap-reverse'
   function Wrap_Reverse_Class_Widget return Widget_Style is
     (From (Wrap_Reverse_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'wrap-reverse'
   function Wrap_Reverse_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Wrap_Reverse_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ac-start'
   function Ac_Start_Class_Widget return Widget_Style is
     (From (Ac_Start_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'ac-start'
   function Ac_Start_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Ac_Start_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ac-center'
   function Ac_Center_Class_Widget return Widget_Style is
     (From (Ac_Center_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'ac-center'
   function Ac_Center_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Ac_Center_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ac-end'
   function Ac_End_Class_Widget return Widget_Style is
     (From (Ac_End_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'ac-end'
   function Ac_End_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Ac_End_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ac-between'
   function Ac_Between_Class_Widget return Widget_Style is
     (From (Ac_Between_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'ac-between'
   function Ac_Between_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Ac_Between_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ac-around'
   function Ac_Around_Class_Widget return Widget_Style is
     (From (Ac_Around_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'ac-around'
   function Ac_Around_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Ac_Around_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'ac-stretch'
   function Ac_Stretch_Class_Widget return Widget_Style is
     (From (Ac_Stretch_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'ac-stretch'
   function Ac_Stretch_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Ac_Stretch_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'tile'
   function Tile_Class_Widget return Widget_Style is
     (From (Tile_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'tile'
   function Tile_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Tile_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'pinned'
   function Pinned_Class_Widget return Widget_Style is
     (From (Pinned_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'pinned'
   function Pinned_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Pinned_Class_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'elastic'
   function Elastic_Class_Widget return Widget_Style is
     (From (Elastic_Class_Base_Style)
     .Build);

   --  Part styles bundle for class 'elastic'
   function Elastic_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Elastic_Class_Widget, Enabled => True),
      others => <>
   ]);

end Demo_Flex_Styles;