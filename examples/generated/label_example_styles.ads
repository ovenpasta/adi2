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

package Label_Example_Styles is

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
        .Background (RGB (40, 44, 52))
     .Build;

   --  Part styles bundle for class 'root'
   Root_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Root_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'container'
   Container_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Gap (Gap (Px (20.0)))
        .Background (RGB (60, 63, 70))
        .Padding (CSS_Box (Px (20.0), Px (20.0), Px (20.0), Px (20.0)))
        .Radius (Radius (Px (8.0)))
     .Build;

   --  Part styles bundle for class 'container'
   Container_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Container_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'label1'
   Label1_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Align_Items (Center)
        .Background (RGB (97, 175, 239))
        .Padding (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'label1'::label
   Label1_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (255, 255, 255))
        .Font_Size (Px (18.0))
     .Build;

   --  Part styles bundle for class 'label1'
   Label1_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label1_Class_Widget, Enabled => True),
      Label_Part => (Style => Label1_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'label2'
   Label2_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Align_Items (Center)
        .Justify_Content (Center)
        .Background (RGB (152, 195, 121))
        .Padding (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'label2'::icon
   Label2_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (32.0)))
        .Height (Size (Px (32.0)))
     .Build;

   --  Part styles bundle for class 'label2'
   Label2_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label2_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label2_Class_Icon_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'label3'
   Label3_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Row)
        .Align_Items (Center)
        .Gap (Gap (Px (8.0)))
        .Background (RGB (198, 120, 221))
        .Padding (CSS_Box (Px (10.0), Px (10.0), Px (10.0), Px (10.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'label3'::icon
   Label3_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (24.0)))
        .Height (Size (Px (24.0)))
     .Build;

   --  Style for class 'label3'::label
   Label3_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (255, 255, 255))
        .Font_Size (Px (16.0))
     .Build;

   --  Part styles bundle for class 'label3'
   Label3_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label3_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label3_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label3_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'label4'
   Label4_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Flex)
        .Flex_Direction (Column)
        .Align_Items (Center)
        .Gap (Gap (Px (8.0)))
        .Background (RGB (229, 192, 123))
        .Padding (CSS_Box (Px (15.0), Px (15.0), Px (15.0), Px (15.0)))
        .Radius (Radius (Px (4.0)))
     .Build;

   --  Style for class 'label4'::icon
   Label4_Class_Icon_Widget : constant Widget_Style :=
     Style_Of
        .Width (Size (Px (48.0)))
        .Height (Size (Px (48.0)))
     .Build;

   --  Style for class 'label4'::label
   Label4_Class_Label_Widget : constant Widget_Style :=
     Style_Of
        .Text_Color (RGB (40, 44, 52))
        .Font_Size (Px (14.0))
     .Build;

   --  Part styles bundle for class 'label4'
   Label4_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Label4_Class_Widget, Enabled => True),
      Icon_Part => (Style => Label4_Class_Icon_Widget, Enabled => True),
      Label_Part => (Style => Label4_Class_Label_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Label_Example_Styles;