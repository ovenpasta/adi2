pragma Ada_2022;

with Ada.Text_IO;
with Adi.App;
with Adi.Core;          use Adi.Core;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;

procedure Min_Size_Test is
   A : Adi.App.App;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Name : String; Cond : Boolean) is
   begin
      if Cond then
         Ada.Text_IO.Put_Line ("  [PASS] " & Name);
         Pass_Count := Pass_Count + 1;
      else
         Ada.Text_IO.Put_Line ("  [FAIL] " & Name);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   A.Init;

   Ada.Text_IO.Put_Line ("=== Min Size Dispatching Test ===");
   Ada.Text_IO.New_Line;

   --  Test 1: Label Get_Min_Size dispatches with CSS min-width
   declare
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Hello");

      Min_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (300.0))),
         others => <>
      );
      Min_WS : constant Widget_Style := From (Min_Style).Build;
      Parts : constant Part_Style_Array := [
         Main_Part => (Style => Min_WS, Enabled => True),
         others => <>
      ];

      Min_Before : Size_2D;
      Min_After  : Size_2D;
   begin
      Min_Before := Get_Min_Size (Widget'Class (L.all));
      Ada.Text_IO.Put_Line ("  Before CSS: min_w=" &
        Pixel_Type'Image (Min_Before.Width));
      Check ("Label min-width without CSS is intrinsic text width",
             Min_Before.Width > 0.0);

      Set_Part_Styles (L.all, Parts);
      Min_After := Get_Min_Size (Widget'Class (L.all));
      Ada.Text_IO.Put_Line ("  After CSS 300px: min_w=" &
        Pixel_Type'Image (Min_After.Width));
      Check ("Label min-width with CSS 300 is >= 300",
             Min_After.Width >= 300.0);
   end;

   Ada.Text_IO.New_Line;

   --  Test 2: Flex layout respects label's Get_Min_Size
   declare
      Row : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Hi");

      Row_Style : constant Style_Rules := (
         Display        => Set (Flex),
         Flex_Direction => Set (Adi.CSS_Styles.Row),
         others => <>
      );
      Row_WS : constant Widget_Style := From (Row_Style).Build;
      Row_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Row_WS, Enabled => True),
         others => <>
      ];

      Label_Min_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (200.0))),
         others => <>
      );
      Label_WS : constant Widget_Style := From (Label_Min_Style).Build;
      Label_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Label_WS, Enabled => True),
         others => <>
      ];
   begin
      Set_Part_Styles (Row.all, Row_Parts);
      Set_Part_Styles (L.all, Label_Parts);
      Add_Child (Row.all, L);

      --  Give the row a geometry (simulating window allocation)
      Set_Geometry (Widget'Class (Row.all), (X => 0.0, Y => 0.0,
                              Width => 500.0, Height => 40.0));

      --  Run layout
      Layout (Widget'Class (Row.all));

      --  Check label geometry
      declare
         Geom : constant Rectangle := Get_Geometry (Widget'Class (L.all));
      begin
         Ada.Text_IO.Put_Line ("  Label geometry: w=" &
           Pixel_Type'Image (Geom.Width) &
           " h=" & Pixel_Type'Image (Geom.Height));
         Check ("Label width in flex >= 200 (CSS min-width)",
                Geom.Width >= 200.0);
      end;
   end;

   Ada.Text_IO.New_Line;

   --  Test 3: Get_Preferred_Size vs Get_Min_Size interaction
   declare
      L : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Short");

      Min_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (400.0))),
         others => <>
      );
      Min_WS : constant Widget_Style := From (Min_Style).Build;
      Parts : constant Part_Style_Array := [
         Main_Part => (Style => Min_WS, Enabled => True),
         others => <>
      ];

      Pref : Size_2D;
      Min  : Size_2D;
   begin
      Set_Part_Styles (L.all, Parts);
      Pref := Get_Preferred_Size (Widget'Class (L.all));
      Min  := Get_Min_Size (Widget'Class (L.all));
      Ada.Text_IO.Put_Line ("  Pref_w=" & Pixel_Type'Image (Pref.Width) &
        "  Min_w=" & Pixel_Type'Image (Min.Width));
      Check ("Get_Min_Size >= 400 with CSS min-width 400",
             Min.Width >= 400.0);
      Check ("Get_Min_Size > Get_Preferred_Size when CSS min > text width",
             Min.Width > Pref.Width);
   end;

   Ada.Text_IO.New_Line;

   --  Test 4: Grid Measure_Content with mixed auto/fr tracks
   --  Fr columns contribute their intrinsic minimum width (CSS
   --  minmax(auto, Xfr) — the auto floor) to the grid's preferred size,
   --  so the container is wide enough to display content when content-sized.
   Ada.Text_IO.Put_Line ("=== Grid Measure_Content track-sizing regression ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Child1   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Child2   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Child3   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Child4   : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      --  Grid: 4 columns, track list [auto, auto, auto, 1fr], no gap/padding.
      Grid_Style : constant Style_Rules := (
         Display            => Set (Grid),
         Grid_Columns       => Set (Grid_Columns_Value (4)),
         Grid_Column_Tracks => (Count  => 4,
                                Tracks => [1 => (Track_Auto, 0.0),
                                           2 => (Track_Auto, 0.0),
                                           3 => (Track_Auto, 0.0),
                                           4 => (Track_Fr,   1.0),
                                           others => <>]),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      --  Auto-column children: modest min-widths (80, 60, 40 px).
      function Make_Min_W_Style (W : Float) return Part_Style_Array is
         S  : constant Style_Rules := (Min_Width => Set (Size (Px (W))), others => <>);
         WS : constant Widget_Style := From (S).Build;
      begin
         return [Main_Part => (Style => WS, Enabled => True), others => <>];
      end Make_Min_W_Style;

      Pref : Size_2D;
   begin
      Set_Part_Styles (Grid_Box.all, Grid_Parts);

      --  Children 1-3 auto-place into cols 1-3 (auto tracks).
      Set_Part_Styles (Child1.all, Make_Min_W_Style (80.0));
      Set_Part_Styles (Child2.all, Make_Min_W_Style (60.0));
      Set_Part_Styles (Child3.all, Make_Min_W_Style (40.0));
      --  Child 4 auto-places into col 4 (1fr track), very wide.
      Set_Part_Styles (Child4.all, Make_Min_W_Style (500.0));

      Add_Child (Grid_Box.all, Child1);
      Add_Child (Grid_Box.all, Child2);
      Add_Child (Grid_Box.all, Child3);
      Add_Child (Grid_Box.all, Child4);

      Pref := Get_Preferred_Size (Widget'Class (Grid_Box.all));
      Ada.Text_IO.Put_Line ("  Grid preferred width (auto/auto/auto/1fr): " &
                            Pixel_Type'Image (Pref.Width));

      --  Expected: 80 + 60 + 40 + 500 (fr content min) = 680.
      --  Fr columns contribute their intrinsic content width per CSS spec.
      Check ("Grid preferred width includes fr content (>= 680px)",
             Pref.Width >= 680.0);
      Check ("Grid preferred width reasonable (< 800px)",
             Pref.Width < 800.0);
   end;

   Ada.Text_IO.New_Line;

   --  Test 5: Child explicitly placed in 1fr column — fr minimum included.
   Ada.Text_IO.Put_Line ("=== Grid Measure_Content explicit fr placement ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Auto_C1  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Auto_C2  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Fr_Child : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Grid_Style : constant Style_Rules := (
         Display            => Set (Grid),
         Grid_Columns       => Set (Grid_Columns_Value (2)),
         Grid_Column_Tracks => (Count  => 2,
                                Tracks => [1 => (Track_Auto, 0.0),
                                           2 => (Track_Fr,   1.0),
                                           others => <>]),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      --  Auto child in col 1: min-width 100px.
      Auto_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (100.0))),
         others => <>
      );
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Auto_WS, Enabled => True),
         others => <>
      ];

      --  Fr child explicitly placed in col 2: min-width 800px.
      Fr_Style : constant Style_Rules := (
         Min_Width    => Set (Size (Px (800.0))),
         Grid_Column  => Set (Grid_Column_Value (2)),
         Grid_Row     => Set (Grid_Row_Value (1)),
         others => <>
      );
      Fr_WS    : constant Widget_Style := From (Fr_Style).Build;
      Fr_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Fr_WS, Enabled => True),
         others => <>
      ];

      Pref : Size_2D;
   begin
      Set_Part_Styles (Grid_Box.all, Grid_Parts);
      Set_Part_Styles (Auto_C1.all, Auto_Parts);
      Set_Part_Styles (Auto_C2.all, Auto_Parts);
      Set_Part_Styles (Fr_Child.all, Fr_Parts);

      Add_Child (Grid_Box.all, Auto_C1);
      Add_Child (Grid_Box.all, Fr_Child);   --  explicitly in col 2 (1fr)
      Add_Child (Grid_Box.all, Auto_C2);    --  auto-places into col 1, row 2

      Pref := Get_Preferred_Size (Widget'Class (Grid_Box.all));
      Ada.Text_IO.Put_Line ("  Grid preferred width (auto/1fr, fr=800px): " &
                            Pixel_Type'Image (Pref.Width));

      --  Expected: col 1 = 100px (max of Auto_C1 and Auto_C2),
      --  col 2 = 800px (fr content min).  Total = 900.
      Check ("Fr content included in grid preferred width (>= 900px)",
             Pref.Width >= 900.0);
      Check ("Auto column sized to its content (>= 100px)",
             Pref.Width >= 100.0);
   end;

   Ada.Text_IO.New_Line;

   --  Test 6: fr column must not expand beyond available width at layout time.
   --  Regression: pass-4 of Compute_Grid_Layout used to apply min-width to fr
   --  tracks unconditionally, pushing the total layout past the container when
   --  the window is narrower than the fr child's min-width.
   Ada.Text_IO.Put_Line ("=== fr column overflow regression (layout) ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Auto_Ch  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Fr_Ch    : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Grid_Style : constant Style_Rules := (
         Display            => Set (Grid),
         Grid_Columns       => Set (Grid_Columns_Value (2)),
         Grid_Column_Tracks => (Count  => 2,
                                Tracks => [1 => (Track_Auto, 0.0),
                                           2 => (Track_Fr,   1.0),
                                           others => <>]),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      Auto_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (80.0))),
         others => <>
      );
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Auto_WS, Enabled => True),
         others => <>
      ];

      --  Fr child has a large min-width — much wider than the container.
      Fr_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (800.0))),
         others => <>
      );
      Fr_WS    : constant Widget_Style := From (Fr_Style).Build;
      Fr_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Fr_WS, Enabled => True),
         others => <>
      ];

      Container_W : constant Pixel_Type := 200.0;
      Fr_Geom     : Rectangle;
   begin
      Set_Part_Styles (Grid_Box.all, Grid_Parts);
      Set_Part_Styles (Auto_Ch.all, Auto_Parts);
      Set_Part_Styles (Fr_Ch.all, Fr_Parts);

      Add_Child (Grid_Box.all, Auto_Ch);
      Add_Child (Grid_Box.all, Fr_Ch);

      Set_Geometry (Widget'Class (Grid_Box.all),
                    (X => 0.0, Y => 0.0,
                     Width => Container_W, Height => 100.0));
      Layout (Widget'Class (Grid_Box.all));

      Fr_Geom := Get_Geometry (Widget'Class (Fr_Ch.all));
      Ada.Text_IO.Put_Line
        ("  Fr child: X=" & Pixel_Type'Image (Fr_Geom.X) &
         "  W=" & Pixel_Type'Image (Fr_Geom.Width) &
         "  right=" & Pixel_Type'Image (Fr_Geom.X + Fr_Geom.Width));

      --  The fr child's right edge must not exceed the container.
      Check ("fr column right edge <= container width (no overflow)",
             Fr_Geom.X + Fr_Geom.Width <= Container_W);
      --  The fr column must not have been expanded to the child's min-width.
      Check ("fr column width < fr child min-width (800px)",
             Fr_Geom.Width < 800.0);
   end;

   --  Test 7: text-wrap height adaptation in a grid.
   --  A label with long text placed in a narrow column should wrap onto
   --  multiple lines.  After layout the row height must accommodate the
   --  wrapped content (taller than a single line).
   Ada.Text_IO.Put_Line ("=== Grid text-wrap height adaptation ===" );
   Ada.Text_IO.New_Line;
   declare
      Grid_Box  : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Name_Cell : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Desc_Lbl  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("This is a quite long description text that should " &
           "wrap onto multiple lines when placed in a narrow column");

      --  2-column grid: auto (name) + 1fr (description).
      Grid_Style : constant Style_Rules := (
         Display            => Set (Grid),
         Grid_Columns       => Set (Grid_Columns_Value (2)),
         Grid_Column_Tracks => (Count  => 2,
                                Tracks => [1 => (Track_Auto, 0.0),
                                           2 => (Track_Fr,   1.0),
                                           others => <>]),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      --  Auto column child: min-width 50px.
      Name_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (50.0))),
         others => <>
      );
      Name_WS    : constant Widget_Style := From (Name_Style).Build;
      Name_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Name_WS, Enabled => True),
         others => <>
      ];

      Single_Line_H : Pixel_Type;
      Desc_Geom     : Rectangle;
   begin
      --  Measure the label's single-line preferred height before layout.
      Single_Line_H := Get_Preferred_Size (Widget'Class (Desc_Lbl.all)).Height;
      Ada.Text_IO.Put_Line ("  Single-line height: " &
        Pixel_Type'Image (Single_Line_H));

      Set_Part_Styles (Grid_Box.all, Grid_Parts);
      Set_Part_Styles (Name_Cell.all, Name_Parts);
      Add_Child (Grid_Box.all, Name_Cell);
      Add_Child (Grid_Box.all, Desc_Lbl);

      --  Narrow container (150px wide) forces the 1fr column to ~100px.
      Set_Geometry (Widget'Class (Grid_Box.all),
                    (X => 0.0, Y => 0.0, Width => 150.0, Height => 200.0));
      Layout (Widget'Class (Grid_Box.all));

      Desc_Geom := Get_Geometry (Widget'Class (Desc_Lbl.all));
      Ada.Text_IO.Put_Line ("  Desc label geometry: w=" &
        Pixel_Type'Image (Desc_Geom.Width) &
        " h=" & Pixel_Type'Image (Desc_Geom.Height));
      Check ("Desc label width fits in fr column (< 110px)",
             Desc_Geom.Width < 110.0 and then Desc_Geom.Width > 0.0);
      Check ("Desc label height > single-line (text wrapped)",
             Desc_Geom.Height > Single_Line_H);
   end;

   Ada.Text_IO.New_Line;

   --  Test 8: grid container grows when row content exceeds container height.
   --  Regression for the vertical overflow bug: Pass 4 can expand row heights
   --  beyond Available_H when content (e.g. wrapped text) is taller than the
   --  equal-share Cell_H.  The container must grow to avoid clipping.
   Ada.Text_IO.Put_Line ("=== Grid container grows for tall content ===" );
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child1   : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child2   : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;

      Grid_Style : constant Style_Rules := (
         Display      => Set (Grid),
         Grid_Columns => Set (Grid_Columns_Value (1)),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      Child1_Style : constant Style_Rules := (
         Min_Height => Set (Size (Px (60.0))),
         others => <>
      );
      Child1_WS    : constant Widget_Style := From (Child1_Style).Build;
      Child1_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Child1_WS, Enabled => True),
         others => <>
      ];

      Child2_Style : constant Style_Rules := (
         Min_Height => Set (Size (Px (40.0))),
         others => <>
      );
      Child2_WS    : constant Widget_Style := From (Child2_Style).Build;
      Child2_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Child2_WS, Enabled => True),
         others => <>
      ];

      --  Container height intentionally smaller than total content (60+40=100).
      Container_H  : constant Pixel_Type := 50.0;
      Grid_Geom    : Rectangle;
      C1_Geom      : Rectangle;
      C2_Geom      : Rectangle;
   begin
      Set_Part_Styles (Grid_Box.all, Grid_Parts);
      Set_Part_Styles (Child1.all, Child1_Parts);
      Set_Part_Styles (Child2.all, Child2_Parts);

      Add_Child (Grid_Box.all, Child1);
      Add_Child (Grid_Box.all, Child2);

      Set_Geometry (Widget'Class (Grid_Box.all),
                    (X => 0.0, Y => 0.0,
                     Width => 200.0, Height => Container_H));
      Layout (Widget'Class (Grid_Box.all));

      Grid_Geom := Get_Geometry (Widget'Class (Grid_Box.all));
      C1_Geom   := Get_Geometry (Widget'Class (Child1.all));
      C2_Geom   := Get_Geometry (Widget'Class (Child2.all));

      Ada.Text_IO.Put_Line
        ("  Grid H=" & Pixel_Type'Image (Grid_Geom.Height) &
         "  C1 H=" & Pixel_Type'Image (C1_Geom.Height) &
         "  C2 H=" & Pixel_Type'Image (C2_Geom.Height));

      Check ("Row 1 height >= child1 min-height (60px)",
             C1_Geom.Height >= 60.0);
      Check ("Row 2 height >= child2 min-height (40px)",
             C2_Geom.Height >= 40.0);
      Check ("Grid container grew beyond initial 50px",
             Grid_Geom.Height >= 100.0);
      Check ("Child 2 does not overflow grid (no clipping)",
             C2_Geom.Y + C2_Geom.Height <= Grid_Geom.Y + Grid_Geom.Height);
   end;

   --  Test 9: overflow:hidden grid must NOT grow when content exceeds height.
   --  Overflow modes other than visible clip rather than expanding the box.
   Ada.Text_IO.Put_Line ("=== Grid overflow:hidden does not grow ===" );
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child1   : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Child2   : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;

      Grid_Style : constant Style_Rules := (
         Display      => Set (Grid),
         Grid_Columns => Set (Grid_Columns_Value (1)),
         Overflow     => Set (Overflow_Hidden),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      Child1_Style : constant Style_Rules := (
         Min_Height => Set (Size (Px (60.0))),
         others => <>
      );
      Child1_WS    : constant Widget_Style := From (Child1_Style).Build;
      Child1_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Child1_WS, Enabled => True),
         others => <>
      ];

      Child2_Style : constant Style_Rules := (
         Min_Height => Set (Size (Px (40.0))),
         others => <>
      );
      Child2_WS    : constant Widget_Style := From (Child2_Style).Build;
      Child2_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Child2_WS, Enabled => True),
         others => <>
      ];

      Container_H : constant Pixel_Type := 50.0;
      Grid_Geom   : Rectangle;
   begin
      Set_Part_Styles (Grid_Box.all, Grid_Parts);
      Set_Part_Styles (Child1.all, Child1_Parts);
      Set_Part_Styles (Child2.all, Child2_Parts);

      Add_Child (Grid_Box.all, Child1);
      Add_Child (Grid_Box.all, Child2);

      Set_Geometry (Widget'Class (Grid_Box.all),
                    (X => 0.0, Y => 0.0,
                     Width => 200.0, Height => Container_H));
      Layout (Widget'Class (Grid_Box.all));

      Grid_Geom := Get_Geometry (Widget'Class (Grid_Box.all));
      Ada.Text_IO.Put_Line
        ("  Grid H=" & Pixel_Type'Image (Grid_Geom.Height) &
         " (initial=" & Pixel_Type'Image (Container_H) & ")");

      Check ("overflow:hidden grid height unchanged (no growth)",
             Grid_Geom.Height = Container_H);
   end;

   --  Test 10: fr column in a content-sized grid must not collapse to zero.
   --  Regression: when a grid has no explicit width (content-sized via flex
   --  parent with align-items:flex-start), Measure_Content must include fr
   --  column content in the preferred size, and layout must give the fr
   --  column a non-zero width.
   Ada.Text_IO.Put_Line ("=== fr column content-sized grid regression ===");
   Ada.Text_IO.New_Line;
   declare
      --  Outer flex container that shrink-wraps children (align-items default).
      Wrapper  : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Grid_Box : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Auto_Ch  : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Fr_Ch    : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;

      --  Wrapper: flex column (default), generous size.
      Wrap_Style : constant Style_Rules := (
         Display => Set (Flex),
         others => <>
      );
      Wrap_WS    : constant Widget_Style := From (Wrap_Style).Build;
      Wrap_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Wrap_WS, Enabled => True),
         others => <>
      ];

      --  Grid: 2 columns [auto, 1fr].
      Grid_Style : constant Style_Rules := (
         Display            => Set (Grid),
         Grid_Columns       => Set (Grid_Columns_Value (2)),
         Grid_Column_Tracks => (Count  => 2,
                                Tracks => [1 => (Track_Auto, 0.0),
                                           2 => (Track_Fr,   1.0),
                                           others => <>]),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      Auto_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (80.0))),
         others => <>
      );
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Auto_WS, Enabled => True),
         others => <>
      ];

      Fr_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (200.0))),
         others => <>
      );
      Fr_WS    : constant Widget_Style := From (Fr_Style).Build;
      Fr_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Fr_WS, Enabled => True),
         others => <>
      ];

      Grid_Pref : Size_2D;
      Fr_Geom   : Rectangle;
   begin
      Set_Part_Styles (Wrapper.all, Wrap_Parts);
      Set_Part_Styles (Grid_Box.all, Grid_Parts);
      Set_Part_Styles (Auto_Ch.all, Auto_Parts);
      Set_Part_Styles (Fr_Ch.all, Fr_Parts);

      Add_Child (Grid_Box.all, Auto_Ch);
      Add_Child (Grid_Box.all, Fr_Ch);
      Add_Child (Wrapper.all, Grid_Box);

      --  Measure: preferred size must include fr content.
      Grid_Pref := Get_Preferred_Size (Widget'Class (Grid_Box.all));
      Ada.Text_IO.Put_Line
        ("  Grid preferred width: " & Pixel_Type'Image (Grid_Pref.Width));
      Check ("Content-sized grid includes fr content (pref >= 280)",
             Grid_Pref.Width >= 280.0);

      --  Layout the wrapper with generous space — grid gets content-sized width.
      Set_Geometry (Widget'Class (Wrapper.all),
                    (X => 0.0, Y => 0.0, Width => 800.0, Height => 100.0));
      Layout (Widget'Class (Wrapper.all));

      Fr_Geom := Get_Geometry (Widget'Class (Fr_Ch.all));
      Ada.Text_IO.Put_Line
        ("  Fr child: W=" & Pixel_Type'Image (Fr_Geom.Width));

      --  The fr column must have a non-zero width.
      Check ("Fr column width > 0 in content-sized grid",
             Fr_Geom.Width > 0.0);
      --  The fr column must be at least as wide as its content minimum.
      Check ("Fr column width >= content min (200px)",
             Fr_Geom.Width >= 200.0);
   end;

   --  Test 11: fr column uses intrinsic minimum (not preferred) in measurement.
   --  Regression: Measure_Content used Max(Pref, Min) for fr columns, which
   --  is the full unwrapped text width for labels.  This inflated the grid's
   --  preferred width, preventing the grid from shrinking when the parent
   --  constrains width, and blocking text wrapping in the fr column.
   --  The fix uses Min_Width only for fr columns (CSS minmax(auto, Xfr)
   --  floor = intrinsic minimum, not preferred).
   Ada.Text_IO.Put_Line
     ("=== fr column uses min (not pref) in measurement ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Auto_Ch  : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Fr_Lbl   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("This is a very long description that should wrap " &
           "when the column is narrow enough");

      --  Grid: 2 columns [auto, 1fr].
      Grid_Style : constant Style_Rules := (
         Display            => Set (Grid),
         Grid_Columns       => Set (Grid_Columns_Value (2)),
         Grid_Column_Tracks => (Count  => 2,
                                Tracks => [1 => (Track_Auto, 0.0),
                                           2 => (Track_Fr,   1.0),
                                           others => <>]),
         others => <>
      );
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Grid_WS, Enabled => True),
         others => <>
      ];

      Auto_Style : constant Style_Rules := (
         Min_Width => Set (Size (Px (80.0))),
         others => <>
      );
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array := [
         Main_Part => (Style => Auto_WS, Enabled => True),
         others => <>
      ];

      Label_Pref  : Size_2D;
      Grid_Pref   : Size_2D;
      Fr_Geom     : Rectangle;
   begin
      Set_Part_Styles (Grid_Box.all, Grid_Parts);
      Set_Part_Styles (Auto_Ch.all, Auto_Parts);
      Add_Child (Grid_Box.all, Auto_Ch);
      Add_Child (Grid_Box.all, Fr_Lbl);

      --  The label's preferred width is the full unwrapped text (very wide).
      Label_Pref := Get_Preferred_Size (Widget'Class (Fr_Lbl.all));
      Ada.Text_IO.Put_Line
        ("  Label preferred width: " & Pixel_Type'Image (Label_Pref.Width));

      --  Grid preferred width must NOT include the label's full preferred width.
      --  It should use only the label's min-width (intrinsic minimum).
      Grid_Pref := Get_Preferred_Size (Widget'Class (Grid_Box.all));
      Ada.Text_IO.Put_Line
        ("  Grid preferred width:  " & Pixel_Type'Image (Grid_Pref.Width));

      Check ("Grid pref width < label pref width (fr uses min, not pref)",
             Grid_Pref.Width < Label_Pref.Width);
      Check ("Grid pref width >= auto col (80px)",
             Grid_Pref.Width >= 80.0);

      --  Layout at a width narrower than the label's preferred (but wide
      --  enough for wrapping).  Text in the fr column should wrap.
      Set_Geometry (Widget'Class (Grid_Box.all),
                    (X => 0.0, Y => 0.0, Width => 300.0, Height => 200.0));
      Layout (Widget'Class (Grid_Box.all));

      Fr_Geom := Get_Geometry (Widget'Class (Fr_Lbl.all));
      Ada.Text_IO.Put_Line
        ("  Fr label after layout: W=" & Pixel_Type'Image (Fr_Geom.Width) &
         " H=" & Pixel_Type'Image (Fr_Geom.Height));

      --  The fr column must have shrunk to fit the container, not stayed at
      --  full preferred width.
      Check ("Fr label width fits in container (< 230px)",
             Fr_Geom.Width < 230.0 and then Fr_Geom.Width > 0.0);
      --  Text should have wrapped, making the label taller than single-line.
      Check ("Fr label height > single-line (text wrapped)",
             Fr_Geom.Height > Label_Pref.Height);
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("Summary: " & Natural'Image (Pass_Count) & "/"
     & Natural'Image (Pass_Count + Fail_Count) & " passing");

   if Fail_Count > 0 then
      Ada.Text_IO.Put_Line ("FAILURES DETECTED");
   end if;
end Min_Size_Test;
