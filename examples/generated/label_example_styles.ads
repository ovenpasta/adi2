--  Auto-generated from CSS
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;

package Label_Example_Styles is

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
      Background_Color => Set_Bg (RGB (40, 44, 52)),
      others => <>);

   --  Base style for class 'container'
   function Container_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Gap => Set (Gap (Px (20.0))),
      Background_Color => Set_Bg (RGB (60, 63, 70)),
      Padding => Set (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0))),
      Border_Radius => Set (Radius (Px (8.0))),
      others => <>);

   --  Base style for class 'label1'
   function Label1_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Background_Color => Set_Bg (RGB (97, 175, 239)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'label1'::label
   function Label1_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (18.0)),
      others => <>);

   --  Base style for class 'label2'
   function Label2_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Align_Items => Set (Center),
      Justify_Content => Set (Center),
      Background_Color => Set_Bg (RGB (152, 195, 121)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'label2'::icon
   function Label2_Class_Icon_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (32.0))),
      Height => Set (Size (Px (32.0))),
      others => <>);

   --  Base style for class 'label3'
   function Label3_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Row),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (198, 120, 221)),
      Padding => Set (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'label3'::icon
   function Label3_Class_Icon_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (24.0))),
      Height => Set (Size (Px (24.0))),
      others => <>);

   --  Base style for class 'label3'::label
   function Label3_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (255, 255, 255)),
      Font_Size => Set_Font (Px (16.0)),
      others => <>);

   --  Base style for class 'label4'
   function Label4_Class_Base_Style return Style_Rules is
     (
      Display => Set (Flex),
      Flex_Direction => Set (Column),
      Align_Items => Set (Center),
      Gap => Set (Gap (Px (8.0))),
      Background_Color => Set_Bg (RGB (229, 192, 123)),
      Padding => Set (CSS_Box (Px (15.0), Px (15.0), Px (15.0), Px (15.0))),
      Border_Radius => Set (Radius (Px (4.0))),
      others => <>);

   --  Base style for class 'label4'::icon
   function Label4_Class_Icon_Base_Style return Style_Rules is
     (
      Width => Set (Size (Px (48.0))),
      Height => Set (Size (Px (48.0))),
      others => <>);

   --  Base style for class 'label4'::label
   function Label4_Class_Label_Base_Style return Style_Rules is
     (
      Color => Set (RGB (40, 44, 52)),
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

   --  Complete widget style for class 'label1'
   function Label1_Class_Widget return Widget_Style is
     (From (Label1_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'label1'::label
   function Label1_Class_Label_Widget return Widget_Style is
     (From (Label1_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'label1'
   function Label1_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Label1_Class_Widget, Enabled => True),
      Label_Part => (Style => Label1_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'label2'
   function Label2_Class_Widget return Widget_Style is
     (From (Label2_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'label2'::icon
   function Label2_Class_Icon_Widget return Widget_Style is
     (From (Label2_Class_Icon_Base_Style)
     .Build);

   --  Part styles bundle for class 'label2'
   function Label2_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Label2_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label2_Class_Icon_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'label3'
   function Label3_Class_Widget return Widget_Style is
     (From (Label3_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'label3'::icon
   function Label3_Class_Icon_Widget return Widget_Style is
     (From (Label3_Class_Icon_Base_Style)
     .Build);

   --  Complete widget style for class 'label3'::label
   function Label3_Class_Label_Widget return Widget_Style is
     (From (Label3_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'label3'
   function Label3_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Label3_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label3_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label3_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Complete widget style for class 'label4'
   function Label4_Class_Widget return Widget_Style is
     (From (Label4_Class_Base_Style)
     .Build);

   --  Complete widget style for class 'label4'::icon
   function Label4_Class_Icon_Widget return Widget_Style is
     (From (Label4_Class_Icon_Base_Style)
     .Build);

   --  Complete widget style for class 'label4'::label
   function Label4_Class_Label_Widget return Widget_Style is
     (From (Label4_Class_Label_Base_Style)
     .Build);

   --  Part styles bundle for class 'label4'
   function Label4_Class_Part_Styles return Part_Style_Array is
     ([
      Main_Part => (Style => Label4_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label4_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label4_Class_Label_Widget, Enabled => True),
      others => <>
   ]);

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Label_Example_Styles;