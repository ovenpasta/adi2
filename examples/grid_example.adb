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
      Set_Part_Styles (Tile.all, Tile_Part_Styles);
      Set_Part_Styles (Tile.all, Styles);
      Tile.Add_Child (Label);
      return Tile;
   end New_Tile;
begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("Grid Layout Example", (960.0, 620.0));

      Root  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("CSS Grid Layout");
      Hint  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Grid supports template columns/rows, gap, and item placement with row/column spans.");
      Grid  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
   begin
      Set_Part_Styles (Root.all, Root_Part_Styles);
      Set_Part_Styles (Title.all, Title_Part_Styles);
      Set_Part_Styles (Hint.all, Hint_Part_Styles);
      Set_Part_Styles (Grid.all, Grid_Part_Styles);

      Grid.Add_Child (New_Tile ("A (1 / span 2)", Tile_A_Part_Styles));
      Grid.Add_Child (New_Tile ("B (row span 2)", Tile_B_Part_Styles));
      Grid.Add_Child (New_Tile ("C", Tile_C_Part_Styles));
      Grid.Add_Child (New_Tile ("D (row span 2)", Tile_D_Part_Styles));
      Grid.Add_Child (New_Tile ("E", Tile_E_Part_Styles));
      Grid.Add_Child (New_Tile ("F", Tile_F_Part_Styles));
      Grid.Add_Child (New_Tile ("G (2 / span 3)", Tile_G_Part_Styles));

      Root.Add_Child (Title);
      Root.Add_Child (Hint);
      Root.Add_Child (Grid);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Grid_Example;
