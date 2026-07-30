pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
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
      --  A part style belongs to the widget that owns the part, and
      --  inheritance runs between a widget's own parts, not down the
      --  tree: `.tile::label` is the box's label part, not this child
      --  label's text. Style the label itself, or it keeps the default
      --  text colour.
      Set_Part_Style (+Label, Label_Part, Tile_Class_Label_Widget);
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
      Set_Part_Style (+Label, Label_Part, Tr_Cell_Class_Label_Widget);
      Add_Child (+Cell, +Label);
      return Cell;
   end New_Cell;
begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle := Create_Window_Handle ("Grid Layout Example", (1600.0, 780.0));

      Root  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      --  Two side-by-side columns: four sections do not fit stacked.
      Columns : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Left    : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Right   : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

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

      --  Third section: mixed track kinds, per-axis gaps, an implicit row
      --  and a nested grid.
      Title3 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Mixed Tracks: 120px / 2fr / 0.5fr / auto");
      Hint3  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("row-gap 4px and column-gap 14px are set separately; 2fr takes "
           & "four times the width of 0.5fr once 120px and auto are sized.");
      Mix    : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Nested : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      --  Fourth section: a grid container that scrolls itself.
      Title4 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Scrolling Grid: overflow-y auto");
      Hint4  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("The grid is 150px tall with more rows than fit, so it scrolls instead of growing.");
      Scroll : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
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

      Adi.Widget.Label.Set_Part_Styles (Title3, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hint3, Hint_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Mix, Mix_Grid_Class_Part_Styles);

      --  Row 1: one cell per track kind, in track order.
      Add_Child (+Mix, +New_Cell ("120px",  Mx_Fixed_Class_Part_Styles));
      Add_Child (+Mix, +New_Cell ("2fr",    Mx_Wide_Class_Part_Styles));
      Add_Child (+Mix, +New_Cell ("0.5fr",  Mx_Narrow_Class_Part_Styles));
      Add_Child (+Mix, +New_Cell ("auto",   Mx_Auto_Class_Part_Styles));

      --  Row 2: a nested grid on the left, sized by the legacy count form,
      --  and a note spanning the two remaining columns.
      Adi.Widget.Box.Set_Part_Styles (Nested, Nested_Host_Class_Part_Styles);
      Add_Child (+Nested, +New_Cell ("nested 1", Nested_Cell_Class_Part_Styles));
      Add_Child (+Nested, +New_Cell ("nested 2", Nested_Cell_Class_Part_Styles));
      Add_Child (+Nested, +New_Cell ("nested 3", Nested_Cell_Class_Part_Styles));
      Add_Child (+Mix, +Nested);
      Add_Child (+Mix, +New_Cell ("nested grid, count form",
                                  Mx_Note_Class_Part_Styles));

      --  Row 3 does not exist in grid-template-rows: the grid grows one.
      Add_Child (+Mix, +New_Cell ("implicit row 3 — grid-template-rows only declares 2",
                                  Mx_Implicit_Class_Part_Styles));

      Adi.Widget.Label.Set_Part_Styles (Title4, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Hint4, Hint_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Scroll, Scroll_Grid_Class_Part_Styles);

      for I in 1 .. 14 loop
         Add_Child
           (+Scroll,
            +New_Cell ("row" & Integer'Image ((I + 1) / 2) & " cell"
                       & Integer'Image (I), Sc_Cell_Class_Part_Styles));
      end loop;

      Adi.Widget.Box.Set_Part_Styles (Columns, Columns_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Left, Column_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Right, Column_Class_Part_Styles);

      Add_Child (+Left, +Title);
      Add_Child (+Left, +Hint);
      Add_Child (+Left, +Grid);
      Add_Child (+Left, +Title2);
      Add_Child (+Left, +Hint2);
      Add_Child (+Left, +Track);

      Add_Child (+Right, +Title3);
      Add_Child (+Right, +Hint3);
      Add_Child (+Right, +Mix);
      Add_Child (+Right, +Title4);
      Add_Child (+Right, +Hint4);
      Add_Child (+Right, +Scroll);

      Add_Child (+Columns, +Left);
      Add_Child (+Columns, +Right);
      Add_Child (+Root, +Columns);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
   end;
end Grid_Example;
