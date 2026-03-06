pragma Ada_2022;

with Adi.App;
with Adi.Window;           use Adi.Window;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Grid_Example_Styles;  use Grid_Example_Styles;

procedure Grid_Example is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

   function New_Tile
     (Text   : String;
      Styles : Part_Style_Array) return Adi.Widget.Box.Box_Handle
   is
      Tile  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Text);
   begin
      Adi.Widget.Box.Set_Part_Styles (Tile, Tile_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Tile, Styles);
      Add_Child (+Tile, +Label);
      return Tile;
   end New_Tile;

   function New_Cell
     (Text   : String;
      Styles : Part_Style_Array) return Adi.Widget.Box.Box_Handle
   is
      Cell  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle (Text);
   begin
      Adi.Widget.Box.Set_Part_Styles (Cell, Tr_Cell_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Cell, Styles);
      Add_Child (+Cell, +Label);
      return Cell;
   end New_Cell;
begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle := Create_Window_Handle ("Grid Layout Example", (640.0, 780.0));

      Root  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("CSS Grid Layout");
      Hint  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Grid supports template columns/rows, gap, and item placement with row/column spans.");
      Grid  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      --  Second section: track-sizing demo (auto / auto / auto / 1fr)
      Title2 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Track Sizing: auto / auto / auto / 1fr");
      Hint2  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("First 3 columns fit their content; the 4th column (1fr) stretches to fill the remainder.");
      Track  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
   begin
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hint, Hint_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Grid, Grid_Class_Part_Styles);

      Add_Child (+Grid, +New_Tile ("A (1 / span 2)", Tile_A_Class_Part_Styles));
      Add_Child (+Grid, +New_Tile ("B (row span 2)", Tile_B_Class_Part_Styles));
      Add_Child (+Grid, +New_Tile ("C", Tile_C_Class_Part_Styles));
      Add_Child (+Grid, +New_Tile ("D (row span 2)", Tile_D_Class_Part_Styles));
      Add_Child (+Grid, +New_Tile ("E", Tile_E_Class_Part_Styles));
      Add_Child (+Grid, +New_Tile ("F", Tile_F_Class_Part_Styles));
      Add_Child (+Grid, +New_Tile ("G (2 / span 3)", Tile_G_Class_Part_Styles));

      Adi.Widget.Label.Set_Part_Styles (Title2, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hint2, Hint_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Track, Track_Grid_Class_Part_Styles);

      --  Row 1
      Add_Child (+Track, +New_Cell ("Font Size",  Tr_Name_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("14",          Tr_Val_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("px",          Tr_Unit_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("Controls the base font size for all text rendered in the application",
                                 Tr_Desc_Class_Part_Styles));
      --  Row 2
      Add_Child (+Track, +New_Cell ("Language",   Tr_Name_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("EN",          Tr_Val_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("--",          Tr_Unit_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("Sets the display language used throughout the application interface",
                                 Tr_Desc_Class_Part_Styles));
      --  Row 3
      Add_Child (+Track, +New_Cell ("Theme",      Tr_Name_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("Dark",        Tr_Val_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("--",          Tr_Unit_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("Choose between light and dark themes for the application window",
                                 Tr_Desc_Class_Part_Styles));
      --  Row 4
      Add_Child (+Track, +New_Cell ("Spacing",    Tr_Name_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("8",           Tr_Val_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("dp",          Tr_Unit_Class_Part_Styles));
      Add_Child (+Track, +New_Cell ("Base unit applied to all padding, margin, and gap values throughout",
                                 Tr_Desc_Class_Part_Styles));

      Add_Child (+Root, +Title);
      Add_Child (+Root, +Hint);
      Add_Child (+Root, +Grid);
      Add_Child (+Root, +Title2);
      Add_Child (+Root, +Hint2);
      Add_Child (+Root, +Track);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
   end;
end Grid_Example;
