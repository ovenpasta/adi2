pragma Ada_2022;

with Adi.App;
with Adi.Window;           use Adi.Window;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Grid_Example_Styles;  use Grid_Example_Styles;

procedure Grid_Example is
   A : Adi.App.App;

   function New_Tile
     (Text   : String;
      Styles : Part_Style_Array) return Adi.Widget.Box.Box_Widget_Access
   is
      Tile  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Styles (Tile.all, Tile_Class_Part_Styles);
      Set_Part_Styles (Tile.all, Styles);
      Tile.Add_Child (Label);
      return Tile;
   end New_Tile;

   function New_Cell
     (Text   : String;
      Styles : Part_Style_Array) return Adi.Widget.Box.Box_Widget_Access
   is
      Cell  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create (Text);
   begin
      Set_Part_Styles (Cell.all, Tr_Cell_Class_Part_Styles);
      Set_Part_Styles (Cell.all, Styles);
      Cell.Add_Child (Label);
      return Cell;
   end New_Cell;
begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("Grid Layout Example", (640.0, 780.0));

      Root  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("CSS Grid Layout");
      Hint  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Grid supports template columns/rows, gap, and item placement with row/column spans.");
      Grid  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Second section: track-sizing demo (auto / auto / auto / 1fr)
      Title2 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Track Sizing: auto / auto / auto / 1fr");
      Hint2  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("First 3 columns fit their content; the 4th column (1fr) stretches to fill the remainder.");
      Track  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
   begin
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Class_Part_Styles);
      Set_Part_Styles (Grid.all, Grid_Class_Part_Styles);

      Grid.Add_Child (New_Tile ("A (1 / span 2)", Tile_A_Class_Part_Styles));
      Grid.Add_Child (New_Tile ("B (row span 2)", Tile_B_Class_Part_Styles));
      Grid.Add_Child (New_Tile ("C", Tile_C_Class_Part_Styles));
      Grid.Add_Child (New_Tile ("D (row span 2)", Tile_D_Class_Part_Styles));
      Grid.Add_Child (New_Tile ("E", Tile_E_Class_Part_Styles));
      Grid.Add_Child (New_Tile ("F", Tile_F_Class_Part_Styles));
      Grid.Add_Child (New_Tile ("G (2 / span 3)", Tile_G_Class_Part_Styles));

      Set_Part_Styles (Title2.all, Title_Class_Part_Styles);
      Set_Part_Styles (Hint2.all, Hint_Class_Part_Styles);
      Set_Part_Styles (Track.all, Track_Grid_Class_Part_Styles);

      --  Row 1
      Track.Add_Child (New_Cell ("Font Size",  Tr_Name_Class_Part_Styles));
      Track.Add_Child (New_Cell ("14",          Tr_Val_Class_Part_Styles));
      Track.Add_Child (New_Cell ("px",          Tr_Unit_Class_Part_Styles));
      Track.Add_Child (New_Cell ("Controls the base font size for all text rendered in the application",
                                 Tr_Desc_Class_Part_Styles));
      --  Row 2
      Track.Add_Child (New_Cell ("Language",   Tr_Name_Class_Part_Styles));
      Track.Add_Child (New_Cell ("EN",          Tr_Val_Class_Part_Styles));
      Track.Add_Child (New_Cell ("--",          Tr_Unit_Class_Part_Styles));
      Track.Add_Child (New_Cell ("Sets the display language used throughout the application interface",
                                 Tr_Desc_Class_Part_Styles));
      --  Row 3
      Track.Add_Child (New_Cell ("Theme",      Tr_Name_Class_Part_Styles));
      Track.Add_Child (New_Cell ("Dark",        Tr_Val_Class_Part_Styles));
      Track.Add_Child (New_Cell ("--",          Tr_Unit_Class_Part_Styles));
      Track.Add_Child (New_Cell ("Choose between light and dark themes for the application window",
                                 Tr_Desc_Class_Part_Styles));
      --  Row 4
      Track.Add_Child (New_Cell ("Spacing",    Tr_Name_Class_Part_Styles));
      Track.Add_Child (New_Cell ("8",           Tr_Val_Class_Part_Styles));
      Track.Add_Child (New_Cell ("dp",          Tr_Unit_Class_Part_Styles));
      Track.Add_Child (New_Cell ("Base unit applied to all padding, margin, and gap values throughout",
                                 Tr_Desc_Class_Part_Styles));

      Root.Add_Child (Title);
      Root.Add_Child (Hint);
      Root.Add_Child (Grid);
      Root.Add_Child (Title2);
      Root.Add_Child (Hint2);
      Root.Add_Child (Track);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Grid_Example;
