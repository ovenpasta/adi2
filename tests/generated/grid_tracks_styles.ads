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

package Grid_Tracks_Styles is

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
   --  Style for tag 'box'
   Box_Tag_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
        .Grid_Columns (Grid_Columns_Value (3))
        .Grid_Columns ((Count => 3, Tracks => [1 => (Track_Fr, 1.0), 2 => (Track_Fr, 2.0), 3 => (Track_Fr, 1.0), others => <>]))
        .Grid_Rows (Grid_Rows_Value (3))
     .Build;

   --  Part styles bundle for tag 'box'
   Box_Tag_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Box_Tag_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'plain'
   Plain_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (0))
        .Grid_Columns (Default_Grid_Track_List)
        .Grid_Rows (Grid_Rows_Value (0))
     .Build;

   --  Part styles bundle for class 'plain'
   Plain_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Plain_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'wide'
   Wide_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (2))
        .Grid_Columns ((Count => 2, Tracks => [1 => (Track_Px, 120.0), 2 => (Track_Fr, 1.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'wide'
   Wide_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Wide_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'last-wins'
   Last_Wins_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (0))
        .Grid_Columns (Default_Grid_Track_List)
     .Build;

   --  Part styles bundle for class 'last-wins'
   Last_Wins_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Last_Wins_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'list-after-none'
   List_After_None_Class_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (2))
        .Grid_Columns ((Count => 2, Tracks => [1 => (Track_Px, 60.0), 2 => (Track_Px, 40.0), others => <>]))
     .Build;

   --  Part styles bundle for class 'list-after-none'
   List_After_None_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => List_After_None_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Style for id 'pin'
   Pin_Id_Widget : constant Widget_Style :=
     Style_Of
        .Grid_Columns (Grid_Columns_Value (0))
        .Grid_Columns (Default_Grid_Track_List)
     .Build;

   --  Part styles bundle for id 'pin'
   Pin_Id_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Pin_Id_Widget, Enabled => True),
      others => <>
   ];

   --  Style for class 'bad-tracks'
   Bad_Tracks_Class_Widget : constant Widget_Style :=
     Style_Of
        .Display (Grid)
     .Build;

   --  Part styles bundle for class 'bad-tracks'
   Bad_Tracks_Class_Part_Styles : constant Part_Style_Array :=
     [
      Main_Part => (Style => Bad_Tracks_Class_Widget, Enabled => True),
      others => <>
   ];

   --  Register every selector this stylesheet defines, in
   --  source order. A consumer that knows only the package
   --  name can install the whole sheet without reparsing the
   --  CSS or guessing which constants exist.
   procedure Register_Selectors
     (S : in out Adi.CSS_Source.Style_Source);

end Grid_Tracks_Styles;