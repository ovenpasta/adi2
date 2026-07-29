pragma Ada_2022;

with Ada.Text_IO;
with Adi.App;
with Adi.Core;          use Adi.Core;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget.Box;
with Adi.Widget.List_Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Test_Support;

procedure Min_Size_Test is
   A          : Adi.App.App;
   package Box_Row_List is new
      Adi.Widget.List_Box (Adi.Widget.Box.Box_Widget);
   package Label_Row_List is new
      Adi.Widget.List_Box (Adi.Widget.Label.Label_Widget);
   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Box_Row_List.List_Box_Handle;
   use type Label_Row_List.List_Box_Handle;
begin
   A.Init;

   Test_Support.Start_Suite ("Min Size Dispatching Test");
   Ada.Text_IO.New_Line;

   --  Test 1: the two minimum questions are answered separately.
   --  Get_Min_Size reports only what the widget demands (explicit CSS);
   --  intrinsic text goes through Get_Content_Min_Size. Consumers take
   --  the larger of the two. See docs/layout_minimums.md.
   declare
      L : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Hello");

      Min_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (300.0))), others => <>);
      Min_WS    : constant Widget_Style := From (Min_Style).Build;
      Parts     : constant Part_Style_Array :=
         [Main_Part => (Style => Min_WS, Enabled => True), others => <>];

      Min_Before : Size_2D;
      Min_After  : Size_2D;
   begin
      Min_Before := Get_Min_Size (L);
      Ada.Text_IO.Put_Line
         ("  Before CSS: min_w=" & Pixel_Type'Image (Min_Before.Width)
          & " content_min_w="
          & Pixel_Type'Image (Get_Content_Min_Size (L).Width));
      Test_Support.Assert
         (Min_Before.Width = 0.0,
          "Label demands no width of its own without CSS min-width");
      Test_Support.Assert
         (Get_Content_Min_Size (L).Width > 0.0,
          "Label reports its intrinsic text width as a content minimum");

      Set_Part_Styles (L, Parts);
      Min_After := Get_Min_Size (L);
      Ada.Text_IO.Put_Line
         ("  After CSS 300px: min_w=" & Pixel_Type'Image (Min_After.Width));
      Test_Support.Assert
         (Min_After.Width >= 300.0,
          "Label min-width with CSS 300 is >= 300");
   end;

   Ada.Text_IO.New_Line;

   --  Test 2: Flex layout respects label's Get_Min_Size
   declare
      Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      L   : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Hi");

      Row_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          others         => <>);
      Row_WS    : constant Widget_Style := From (Row_Style).Build;
      Row_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Row_WS, Enabled => True), others => <>];

      Label_Min_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (200.0))), others => <>);
      Label_WS        : constant Widget_Style :=
         From (Label_Min_Style).Build;
      Label_Parts     : constant Part_Style_Array :=
         [Main_Part => (Style => Label_WS, Enabled => True), others => <>];
   begin
      Set_Part_Styles (Row, Row_Parts);
      Set_Part_Styles (L, Label_Parts);
      Add_Child (Row, L);

      --  Give the row a geometry (simulating window allocation)
      Set_Geometry
         (Row, (X => 0.0, Y => 0.0, Width => 500.0, Height => 40.0));

      --  Run layout
      Layout (Row);

      --  Check label geometry
      declare
         Geom : constant Rectangle := Get_Geometry (L);
      begin
         Ada.Text_IO.Put_Line
            ("  Label geometry: w="
             & Pixel_Type'Image (Geom.Width)
             & " h="
             & Pixel_Type'Image (Geom.Height));
         Test_Support.Assert
            (Geom.Width >= 200.0,
             "Label width in flex >= 200 (CSS min-width)");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  Test 3: Get_Preferred_Size vs Get_Min_Size interaction
   declare
      L : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Short");

      Min_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (400.0))), others => <>);
      Min_WS    : constant Widget_Style := From (Min_Style).Build;
      Parts     : constant Part_Style_Array :=
         [Main_Part => (Style => Min_WS, Enabled => True), others => <>];

      Pref : Size_2D;
      Min  : Size_2D;
   begin
      Set_Part_Styles (L, Parts);
      Pref := Get_Preferred_Size (L);
      Min := Get_Min_Size (L);
      Ada.Text_IO.Put_Line
         ("  Pref_w="
          & Pixel_Type'Image (Pref.Width)
          & "  Min_w="
          & Pixel_Type'Image (Min.Width));
      Test_Support.Assert
         (Min.Width >= 400.0,
          "Get_Min_Size >= 400 with CSS min-width 400");
      Test_Support.Assert
         (Min.Width > Pref.Width,
          "Get_Min_Size > Get_Preferred_Size when CSS min > text width");
   end;

   Ada.Text_IO.New_Line;

   --  Test 4: Grid Measure_Content with mixed auto/fr tracks
   --  Fr columns contribute their intrinsic minimum width (CSS
   --  minmax(auto, Xfr) — the auto floor) to the grid's preferred size,
   --  so the container is wide enough to display content when content-sized.
   Ada.Text_IO.Put_Line
      ("=== Grid Measure_Content track-sizing regression ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child1   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child2   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child3   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child4   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      --  Grid: 4 columns, track list [auto, auto, auto, 1fr], no gap/padding.
      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (4)),
          Grid_Column_Tracks =>
             (Count  => 4,
              Tracks =>
                 [1      => (Track_Auto, 0.0),
                  2      => (Track_Auto, 0.0),
                  3      => (Track_Auto, 0.0),
                  4      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      --  Auto-column children: modest min-widths (80, 60, 40 px).
      function Make_Min_W_Style (W : Float) return Part_Style_Array is
         S  : constant Style_Rules :=
            (Min_Width => Set (Size (Px (W))), others => <>);
         WS : constant Widget_Style := From (S).Build;
      begin
         return [Main_Part => (Style => WS, Enabled => True), others => <>];
      end Make_Min_W_Style;

      Pref : Size_2D;
   begin
      Set_Part_Styles (Grid_Box, Grid_Parts);

      --  Children 1-3 auto-place into cols 1-3 (auto tracks).
      Set_Part_Styles (Child1, Make_Min_W_Style (80.0));
      Set_Part_Styles (Child2, Make_Min_W_Style (60.0));
      Set_Part_Styles (Child3, Make_Min_W_Style (40.0));
      --  Child 4 auto-places into col 4 (1fr track), very wide.
      Set_Part_Styles (Child4, Make_Min_W_Style (500.0));

      Add_Child (Grid_Box, Child1);
      Add_Child (Grid_Box, Child2);
      Add_Child (Grid_Box, Child3);
      Add_Child (Grid_Box, Child4);

      Pref := Get_Preferred_Size (Grid_Box);
      Ada.Text_IO.Put_Line
         ("  Grid preferred width (auto/auto/auto/1fr): "
          & Pixel_Type'Image (Pref.Width));

      --  Expected: 80 + 60 + 40 + 500 (fr content min) = 680.
      --  Fr columns contribute their intrinsic content width per CSS spec.
      Test_Support.Assert
         (Pref.Width >= 680.0,
          "Grid preferred width includes fr content (>= 680px)");
      Test_Support.Assert
         (Pref.Width < 800.0,
          "Grid preferred width reasonable (< 800px)");
   end;

   Ada.Text_IO.New_Line;

   --  Test 5: Child explicitly placed in 1fr column — fr minimum included.
   Ada.Text_IO.Put_Line
      ("=== Grid Measure_Content explicit fr placement ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Auto_C1  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Auto_C2  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Fr_Child : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (2)),
          Grid_Column_Tracks =>
             (Count  => 2,
              Tracks =>
                 [1      => (Track_Auto, 0.0),
                  2      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      --  Auto child in col 1: min-width 100px.
      Auto_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (100.0))), others => <>);
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Auto_WS, Enabled => True), others => <>];

      --  Fr child explicitly placed in col 2: min-width 800px.
      Fr_Style : constant Style_Rules :=
         (Min_Width   => Set (Size (Px (800.0))),
          Grid_Column => Set (Grid_Column_Value (2)),
          Grid_Row    => Set (Grid_Row_Value (1)),
          others      => <>);
      Fr_WS    : constant Widget_Style := From (Fr_Style).Build;
      Fr_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Fr_WS, Enabled => True), others => <>];

      Pref : Size_2D;
   begin
      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Auto_C1, Auto_Parts);
      Set_Part_Styles (Auto_C2, Auto_Parts);
      Set_Part_Styles (Fr_Child, Fr_Parts);

      Add_Child (Grid_Box, Auto_C1);
      Add_Child (Grid_Box, Fr_Child);   --  explicitly in col 2 (1fr)
      Add_Child (Grid_Box, Auto_C2);    --  auto-places into col 1, row 2

      Pref := Get_Preferred_Size (Grid_Box);
      Ada.Text_IO.Put_Line
         ("  Grid preferred width (auto/1fr, fr=800px): "
          & Pixel_Type'Image (Pref.Width));

      --  Expected: col 1 = 100px (max of Auto_C1 and Auto_C2),
      --  col 2 = 800px (fr content min).  Total = 900.
      Test_Support.Assert
         (Pref.Width >= 900.0,
          "Fr content included in grid preferred width (>= 900px)");
      Test_Support.Assert
         (Pref.Width >= 100.0,
          "Auto column sized to its content (>= 100px)");
   end;

   Ada.Text_IO.New_Line;

   --  Test 6: fr column must not expand beyond available width at layout time.
   --  Regression: pass-4 of Compute_Grid_Layout used to apply min-width to fr
   --  tracks unconditionally, pushing the total layout past the container when
   --  the window is narrower than the fr child's min-width.
   Ada.Text_IO.Put_Line ("=== fr column overflow regression (layout) ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Auto_Ch  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Fr_Ch    : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (2)),
          Grid_Column_Tracks =>
             (Count  => 2,
              Tracks =>
                 [1      => (Track_Auto, 0.0),
                  2      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      Auto_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (80.0))), others => <>);
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Auto_WS, Enabled => True), others => <>];

      --  Fr child has a large min-width — much wider than the container.
      Fr_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (800.0))), others => <>);
      Fr_WS    : constant Widget_Style := From (Fr_Style).Build;
      Fr_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Fr_WS, Enabled => True), others => <>];

      Container_W : constant Pixel_Type := 200.0;
      Fr_Geom     : Rectangle;
   begin
      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Auto_Ch, Auto_Parts);
      Set_Part_Styles (Fr_Ch, Fr_Parts);

      Add_Child (Grid_Box, Auto_Ch);
      Add_Child (Grid_Box, Fr_Ch);

      Set_Geometry
         (Grid_Box,
          (X => 0.0, Y => 0.0, Width => Container_W, Height => 100.0));
      Layout (Grid_Box);

      Fr_Geom := Get_Geometry (Fr_Ch);
      Ada.Text_IO.Put_Line
         ("  Fr child: X="
          & Pixel_Type'Image (Fr_Geom.X)
          & "  W="
          & Pixel_Type'Image (Fr_Geom.Width)
          & "  right="
          & Pixel_Type'Image (Fr_Geom.X + Fr_Geom.Width));

      --  The fr child's right edge must not exceed the container.
      Test_Support.Assert
         (Fr_Geom.X + Fr_Geom.Width <= Container_W,
          "fr column right edge <= container width (no overflow)");
      --  The fr column must not have been expanded to the child's min-width.
      Test_Support.Assert
         (Fr_Geom.Width < 800.0,
          "fr column width < fr child min-width (800px)");
   end;

   --  Test 7: text-wrap height adaptation in a grid.
   --  A label with long text placed in a narrow column should wrap onto
   --  multiple lines.  After layout the row height must accommodate the
   --  wrapped content (taller than a single line).
   Ada.Text_IO.Put_Line ("=== Grid text-wrap height adaptation ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Name_Cell : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Desc_Lbl  : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("This is a quite long description text that should "
              & "wrap onto multiple lines when placed in a narrow column");

      --  2-column grid: auto (name) + 1fr (description).
      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (2)),
          Grid_Column_Tracks =>
             (Count  => 2,
              Tracks =>
                 [1      => (Track_Auto, 0.0),
                  2      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      --  Auto column child: min-width 50px.
      Name_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (50.0))), others => <>);
      Name_WS    : constant Widget_Style := From (Name_Style).Build;
      Name_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Name_WS, Enabled => True), others => <>];

      Single_Line_H : Pixel_Type;
      Desc_Geom     : Rectangle;
   begin
      --  Measure the label's single-line preferred height before layout.
      Single_Line_H := Get_Preferred_Size (Desc_Lbl).Height;
      Ada.Text_IO.Put_Line
         ("  Single-line height: " & Pixel_Type'Image (Single_Line_H));

      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Name_Cell, Name_Parts);
      Add_Child (Grid_Box, Name_Cell);
      Add_Child (Grid_Box, Desc_Lbl);

      --  Narrow container (150px wide) forces the 1fr column to ~100px.
      Set_Geometry
         (Grid_Box, (X => 0.0, Y => 0.0, Width => 150.0, Height => 200.0));
      Layout (Grid_Box);

      Desc_Geom := Get_Geometry (Desc_Lbl);
      Ada.Text_IO.Put_Line
         ("  Desc label geometry: w="
          & Pixel_Type'Image (Desc_Geom.Width)
          & " h="
          & Pixel_Type'Image (Desc_Geom.Height));
      Test_Support.Assert
         (Desc_Geom.Width < 110.0 and then Desc_Geom.Width > 0.0,
          "Desc label width fits in fr column (< 110px)");
      Test_Support.Assert
         (Desc_Geom.Height > Single_Line_H,
          "Desc label height > single-line (text wrapped)");
   end;

   Ada.Text_IO.New_Line;

   --  Test 8: grid container grows when row content exceeds container height.
   --  Regression for the vertical overflow bug: Pass 4 can expand row heights
   --  beyond Available_H when content (e.g. wrapped text) is taller than the
   --  equal-share Cell_H.  The container must grow to avoid clipping.
   Ada.Text_IO.Put_Line ("=== Grid container grows for tall content ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child1   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child2   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Grid_Style : constant Style_Rules :=
         (Display      => Set (Grid),
          Grid_Columns => Set (Grid_Columns_Value (1)),
          others       => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      Child1_Style : constant Style_Rules :=
         (Min_Height => Set (Size (Px (60.0))), others => <>);
      Child1_WS    : constant Widget_Style := From (Child1_Style).Build;
      Child1_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Child1_WS, Enabled => True), others => <>];

      Child2_Style : constant Style_Rules :=
         (Min_Height => Set (Size (Px (40.0))), others => <>);
      Child2_WS    : constant Widget_Style := From (Child2_Style).Build;
      Child2_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Child2_WS, Enabled => True), others => <>];

      --  Container height intentionally smaller than total content (60+40=100).
      Container_H : constant Pixel_Type := 50.0;
      Grid_Geom   : Rectangle;
      C1_Geom     : Rectangle;
      C2_Geom     : Rectangle;
   begin
      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Child1, Child1_Parts);
      Set_Part_Styles (Child2, Child2_Parts);

      Add_Child (Grid_Box, Child1);
      Add_Child (Grid_Box, Child2);

      Set_Geometry
         (Grid_Box,
          (X => 0.0, Y => 0.0, Width => 200.0, Height => Container_H));
      Layout (Grid_Box);

      Grid_Geom := Get_Geometry (Grid_Box);
      C1_Geom := Get_Geometry (Child1);
      C2_Geom := Get_Geometry (Child2);

      Ada.Text_IO.Put_Line
         ("  Grid H="
          & Pixel_Type'Image (Grid_Geom.Height)
          & "  C1 H="
          & Pixel_Type'Image (C1_Geom.Height)
          & "  C2 H="
          & Pixel_Type'Image (C2_Geom.Height));

      Test_Support.Assert
         (C1_Geom.Height >= 60.0,
          "Row 1 height >= child1 min-height (60px)");
      Test_Support.Assert
         (C2_Geom.Height >= 40.0,
          "Row 2 height >= child2 min-height (40px)");
      Test_Support.Assert
         (Grid_Geom.Height >= 100.0,
          "Grid container grew beyond initial 50px");
      Test_Support.Assert
         (C2_Geom.Y + C2_Geom.Height <= Grid_Geom.Y + Grid_Geom.Height,
          "Child 2 does not overflow grid (no clipping)");
   end;

   --  Test 9: overflow:hidden grid must NOT grow when content exceeds height.
   --  Overflow modes other than visible clip rather than expanding the box.
   Ada.Text_IO.Put_Line ("=== Grid overflow:hidden does not grow ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child1   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child2   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Grid_Style : constant Style_Rules :=
         (Display      => Set (Grid),
          Grid_Columns => Set (Grid_Columns_Value (1)),
          Overflow_X   => Set_Overflow_X (Overflow_Hidden),
          Overflow_Y   => Set_Overflow_Y (Overflow_Hidden),
          others       => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      Child1_Style : constant Style_Rules :=
         (Min_Height => Set (Size (Px (60.0))), others => <>);
      Child1_WS    : constant Widget_Style := From (Child1_Style).Build;
      Child1_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Child1_WS, Enabled => True), others => <>];

      Child2_Style : constant Style_Rules :=
         (Min_Height => Set (Size (Px (40.0))), others => <>);
      Child2_WS    : constant Widget_Style := From (Child2_Style).Build;
      Child2_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Child2_WS, Enabled => True), others => <>];

      Container_H : constant Pixel_Type := 50.0;
      Grid_Geom   : Rectangle;
   begin
      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Child1, Child1_Parts);
      Set_Part_Styles (Child2, Child2_Parts);

      Add_Child (Grid_Box, Child1);
      Add_Child (Grid_Box, Child2);

      Set_Geometry
         (Grid_Box,
          (X => 0.0, Y => 0.0, Width => 200.0, Height => Container_H));
      Layout (Grid_Box);

      Grid_Geom := Get_Geometry (Grid_Box);
      Ada.Text_IO.Put_Line
         ("  Grid H="
          & Pixel_Type'Image (Grid_Geom.Height)
          & " (initial="
          & Pixel_Type'Image (Container_H)
          & ")");

      Test_Support.Assert
         (Grid_Geom.Height = Container_H,
          "overflow:hidden grid height unchanged (no growth)");
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
      Wrapper  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Auto_Ch  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Fr_Ch    : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      --  Wrapper: flex column (default), generous size.
      Wrap_Style : constant Style_Rules :=
         (Display => Set (Flex), others => <>);
      Wrap_WS    : constant Widget_Style := From (Wrap_Style).Build;
      Wrap_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Wrap_WS, Enabled => True), others => <>];

      --  Grid: 2 columns [auto, 1fr].
      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (2)),
          Grid_Column_Tracks =>
             (Count  => 2,
              Tracks =>
                 [1      => (Track_Auto, 0.0),
                  2      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      Auto_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (80.0))), others => <>);
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Auto_WS, Enabled => True), others => <>];

      Fr_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (200.0))), others => <>);
      Fr_WS    : constant Widget_Style := From (Fr_Style).Build;
      Fr_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Fr_WS, Enabled => True), others => <>];

      Grid_Pref : Size_2D;
      Fr_Geom   : Rectangle;
   begin
      Set_Part_Styles (Wrapper, Wrap_Parts);
      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Auto_Ch, Auto_Parts);
      Set_Part_Styles (Fr_Ch, Fr_Parts);

      Add_Child (Grid_Box, Auto_Ch);
      Add_Child (Grid_Box, Fr_Ch);
      Add_Child (Wrapper, Grid_Box);

      --  Measure: preferred size must include fr content.
      Grid_Pref := Get_Preferred_Size (Grid_Box);
      Ada.Text_IO.Put_Line
         ("  Grid preferred width: " & Pixel_Type'Image (Grid_Pref.Width));
      Test_Support.Assert
         (Grid_Pref.Width >= 280.0,
          "Content-sized grid includes fr content (pref >= 280)");

      --  Layout the wrapper with generous space — grid gets content-sized width.
      Set_Geometry
         (Wrapper, (X => 0.0, Y => 0.0, Width => 800.0, Height => 100.0));
      Layout (Wrapper);

      Fr_Geom := Get_Geometry (Fr_Ch);
      Ada.Text_IO.Put_Line
         ("  Fr child: W=" & Pixel_Type'Image (Fr_Geom.Width));

      --  The fr column must have a non-zero width.
      Test_Support.Assert
         (Fr_Geom.Width > 0.0,
          "Fr column width > 0 in content-sized grid");
      --  The fr column must be at least as wide as its content minimum.
      Test_Support.Assert
         (Fr_Geom.Width >= 200.0,
          "Fr column width >= content min (200px)");
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
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Auto_Ch  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Fr_Lbl   : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("This is a very long description that should wrap "
              & "when the column is narrow enough");

      --  Grid: 2 columns [auto, 1fr].
      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (2)),
          Grid_Column_Tracks =>
             (Count  => 2,
              Tracks =>
                 [1      => (Track_Auto, 0.0),
                  2      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);
      Grid_WS    : constant Widget_Style := From (Grid_Style).Build;
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Grid_WS, Enabled => True), others => <>];

      Auto_Style : constant Style_Rules :=
         (Min_Width => Set (Size (Px (80.0))), others => <>);
      Auto_WS    : constant Widget_Style := From (Auto_Style).Build;
      Auto_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Auto_WS, Enabled => True), others => <>];

      Label_Pref : Size_2D;
      Grid_Pref  : Size_2D;
      Fr_Geom    : Rectangle;
   begin
      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Auto_Ch, Auto_Parts);
      Add_Child (Grid_Box, Auto_Ch);
      Add_Child (Grid_Box, Fr_Lbl);

      --  The label's preferred width is the full unwrapped text (very wide).
      Label_Pref := Get_Preferred_Size (Fr_Lbl);
      Ada.Text_IO.Put_Line
         ("  Label preferred width: " & Pixel_Type'Image (Label_Pref.Width));

      --  Grid preferred width must NOT include the label's full preferred width.
      --  It should use only the label's min-width (intrinsic minimum).
      Grid_Pref := Get_Preferred_Size (Grid_Box);
      Ada.Text_IO.Put_Line
         ("  Grid preferred width:  " & Pixel_Type'Image (Grid_Pref.Width));

      Test_Support.Assert
         (Grid_Pref.Width < Label_Pref.Width,
          "Grid pref width < label pref width (fr uses min, not pref)");
      Test_Support.Assert
         (Grid_Pref.Width >= 80.0,
          "Grid pref width >= auto col (80px)");

      --  Layout at a width narrower than the label's preferred (but wide
      --  enough for wrapping).  Text in the fr column should wrap.
      Set_Geometry
         (Grid_Box, (X => 0.0, Y => 0.0, Width => 300.0, Height => 200.0));
      Layout (Grid_Box);

      Fr_Geom := Get_Geometry (Fr_Lbl);
      Ada.Text_IO.Put_Line
         ("  Fr label after layout: W="
          & Pixel_Type'Image (Fr_Geom.Width)
          & " H="
          & Pixel_Type'Image (Fr_Geom.Height));

      --  The fr column must have shrunk to fit the container, not stayed at
      --  full preferred width.
      Test_Support.Assert
         (Fr_Geom.Width < 230.0 and then Fr_Geom.Width > 0.0,
          "Fr label width fits in container (< 230px)");
      --  Text should have wrapped, making the label taller than single-line.
      Test_Support.Assert
         (Fr_Geom.Height > Label_Pref.Height,
          "Fr label height > single-line (text wrapped)");
   end;

   Ada.Text_IO.New_Line;

   --  Test 12: Internal-scroll list-box preferred height stays at min/chrome floor.
   Ada.Text_IO.Put_Line
      ("=== Internal-scroll list-box preferred-height floor ===");
   Ada.Text_IO.New_Line;
   declare
      LB_H          : constant Box_Row_List.List_Box_Handle :=
         Box_Row_List.Create_Handle;
      LB_Main_Style : constant Style_Rules :=
         (Min_Height   => Set (Size (Px (120.0))),
          Padding      =>
             Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
          Border_Width => Set (Border_Width (Px (2.0))),
          Border_Style => Set (Border_Style (Solid)),
          others       => <>);
      LB_Main_WS    : constant Widget_Style := From (LB_Main_Style).Build;
      LB_Styles     : constant Part_Style_Array :=
         [Main_Part => (Style => LB_Main_WS, Enabled => True), others => <>];

      Row_Style : constant Style_Rules :=
         (Height => Set (Size (Px (40.0))), others => <>);
      Row_WS    : constant Widget_Style := From (Row_Style).Build;
      Row_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Row_WS, Enabled => True), others => <>];

      LB_WH       : constant Widget_Handle := +LB_H;
      Pref_Before : Size_2D;
      Pref_After  : Size_2D;
   begin
      Box_Row_List.Set_Part_Styles (LB_H, LB_Styles);
      Pref_Before := Get_Preferred_Size (LB_WH);

      for I in 1 .. 30 loop
         pragma Unreferenced (I);
         declare
            Row : constant Adi.Widget.Box.Box_Handle :=
               Adi.Widget.Box.Create_Handle;
         begin
            Adi.Widget.Box.Set_Part_Styles (Row, Row_Parts);
            Box_Row_List.Append_Row (LB_H, +Row);
         end;
      end loop;

      Pref_After := Get_Preferred_Size (LB_WH);

      Test_Support.Assert
         (Pref_Before.Height >= 120.0,
          "List-box preferred height honors min/chrome floor before rows");
      Test_Support.Assert
         (abs (Pref_After.Height - Pref_Before.Height) <= 1.0,
          "List-box preferred height does not grow with internal row content");
      Test_Support.Assert
         (Pref_After.Height < 300.0,
          "List-box preferred height remains bounded despite many rows");
   end;

   Ada.Text_IO.New_Line;

   --  Test 13: Internal-scroll list-box preferred width stays at min/chrome floor.
   Ada.Text_IO.Put_Line
      ("=== Internal-scroll list-box preferred-width floor ===");
   Ada.Text_IO.New_Line;
   declare
      LB_H          : constant Label_Row_List.List_Box_Handle :=
         Label_Row_List.Create_Handle;
      LB_Main_Style : constant Style_Rules :=
         (Min_Width    => Set (Size (Px (120.0))),
          Padding      =>
             Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
          Border_Width => Set (Border_Width (Px (2.0))),
          Border_Style => Set (Border_Style (Solid)),
          others       => <>);
      LB_Main_WS    : constant Widget_Style := From (LB_Main_Style).Build;
      LB_Styles     : constant Part_Style_Array :=
         [Main_Part => (Style => LB_Main_WS, Enabled => True), others => <>];

      LB_WH       : constant Widget_Handle := +LB_H;
      Pref_Before : Size_2D;
      Pref_After  : Size_2D;
   begin
      Label_Row_List.Set_Part_Styles (LB_H, LB_Styles);
      Pref_Before := Get_Preferred_Size (LB_WH);

      for I in 1 .. 20 loop
         declare
            Row : constant Adi.Widget.Label.Label_Handle :=
               Adi.Widget.Label.Create_Handle
                  ("row "
                   & I'Image
                   & " with intentionally long content to force a large intrinsic width");
         begin
            Label_Row_List.Append_Row (LB_H, +Row);
         end;
      end loop;

      Pref_After := Get_Preferred_Size (LB_WH);

      Test_Support.Assert
         (Pref_Before.Width >= 120.0,
          "List-box preferred width honors min/chrome floor before rows");
      Test_Support.Assert
         (abs (Pref_After.Width - Pref_Before.Width) <= 1.0,
          "List-box preferred width does not grow with internal row content");
      Test_Support.Assert
         (Pref_After.Width < 300.0,
          "List-box preferred width remains bounded despite wide rows");
   end;

   Ada.Text_IO.New_Line;

   --  Test 14: overflow-x scrollable auto-width stays at min/chrome floor.
   Ada.Text_IO.Put_Line
      ("=== overflow-x scrollable preferred-width floor ===");
   Ada.Text_IO.New_Line;
   declare
      Parent : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child  : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("This is intentionally very long content that should not inflate "
              & "preferred width when overflow-x is scrollable.");

      Parent_Style : constant Style_Rules :=
         (Min_Width    => Set (Size (Px (120.0))),
          Padding      =>
             Set (CSS_Box (Px (8.0), Px (8.0), Px (8.0), Px (8.0))),
          Border_Width => Set (Border_Width (Px (2.0))),
          Border_Style => Set (Border_Style (Solid)),
          Overflow_X   => Set_Overflow_X (Overflow_Auto),
          others       => <>);
      Parent_WS    : constant Widget_Style := From (Parent_Style).Build;
      Parent_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Parent_WS, Enabled => True), others => <>];

      Pref_Before : Size_2D;
      Pref_After  : Size_2D;
   begin
      Set_Part_Styles (Parent, Parent_Parts);
      Pref_Before := Get_Preferred_Size (Parent);

      Add_Child (Parent, Child);
      Pref_After := Get_Preferred_Size (Parent);

      Test_Support.Assert
         (Pref_Before.Width >= 120.0,
          "overflow-x floor: preferred width honors min/chrome before child");
      Test_Support.Assert
         (abs (Pref_After.Width - Pref_Before.Width) <= 1.0,
          "overflow-x floor: preferred width does not inflate from child content");
      Test_Support.Assert
         (Pref_After.Width < 300.0,
          "overflow-x floor: preferred width remains bounded");
   end;

   Ada.Text_IO.New_Line;

   --  Test 15: hard-hide excludes from layout; visibility:hidden keeps layout.
   Ada.Text_IO.Put_Line
      ("=== display:none/visibility/Visible layout participation ===");
   Ada.Text_IO.New_Line;
   declare
      Parent  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Child_A : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Short");
      Child_B : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("This child has much longer text and should dominate width");

      Display_None_Style : constant Style_Rules :=
         (Display => Set (Display_None), others => <>);
      Display_None_WS    : constant Widget_Style :=
         From (Display_None_Style).Build;
      Display_None_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Display_None_WS, Enabled => True),
          others    => <>];

      Visibility_Hidden_Style : constant Style_Rules :=
         (Visibility => Set (Visibility_Hidden), others => <>);
      Visibility_Hidden_WS    : constant Widget_Style :=
         From (Visibility_Hidden_Style).Build;
      Visibility_Hidden_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Visibility_Hidden_WS, Enabled => True),
          others    => <>];

      Pref_Both            : Size_2D;
      Pref_Display_None    : Size_2D;
      Pref_Visibility_Hide : Size_2D;
      Pref_Visible_False   : Size_2D;
   begin
      Add_Child (Parent, Child_A);
      Add_Child (Parent, Child_B);
      Pref_Both := Get_Preferred_Size (Parent);

      Set_Part_Styles (Child_B, Display_None_Parts);
      Pref_Display_None := Get_Preferred_Size (Parent);

      Set_Part_Styles (Child_B, Visibility_Hidden_Parts);
      Pref_Visibility_Hide := Get_Preferred_Size (Parent);

      Set_Flag (Child_B, Visible, False);
      Pref_Visible_False := Get_Preferred_Size (Parent);

      Test_Support.Assert
         (Pref_Display_None.Width < Pref_Both.Width,
          "display:none child removed from parent preferred width");
      Test_Support.Assert
         (Pref_Visibility_Hide.Width >= Pref_Both.Width,
          "visibility:hidden child still contributes parent preferred width");
      Test_Support.Assert
         (Pref_Visible_False.Width < Pref_Visibility_Hide.Width,
          "Visible=False child removed from parent preferred width");
   end;

   Ada.Text_IO.New_Line;

   --  Test 16: Label internal layout honors part display:none vs visibility:hidden.
   Ada.Text_IO.Put_Line
      ("=== Label part display:none vs visibility:hidden ===");
   Ada.Text_IO.New_Line;
   declare
      L                             : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Label part text");
      Label_Display_None            : constant Style_Rules :=
         (Display => Set (Display_None), others => <>);
      Label_Display_None_WS         : constant Widget_Style :=
         From (Label_Display_None).Build;
      Label_Display_None_Parts      : constant Part_Style_Array :=
         [Label_Part => (Style => Label_Display_None_WS, Enabled => True),
          others     => <>];
      Label_Visibility_Hidden       : constant Style_Rules :=
         (Visibility => Set (Visibility_Hidden), others => <>);
      Label_Visibility_Hidden_WS    : constant Widget_Style :=
         From (Label_Visibility_Hidden).Build;
      Label_Visibility_Hidden_Parts : constant Part_Style_Array :=
         [Label_Part =>
             (Style => Label_Visibility_Hidden_WS, Enabled => True),
          others     => <>];
      Pref_Default                  : Size_2D;
      Pref_Label_None               : Size_2D;
      Pref_Label_Hidden             : Size_2D;
   begin
      Pref_Default := Get_Preferred_Size (L);
      Set_Part_Styles (L, Label_Display_None_Parts);
      Pref_Label_None := Get_Preferred_Size (L);
      Set_Part_Styles (L, Label_Visibility_Hidden_Parts);
      Pref_Label_Hidden := Get_Preferred_Size (L);

      Test_Support.Assert
         (Pref_Label_None.Width < Pref_Default.Width,
          "Label_Part display:none removes text from label internal layout");
      Test_Support.Assert
         (Pref_Label_Hidden.Width >= Pref_Default.Width,
          "Label_Part visibility:hidden keeps label internal layout size");
   end;

   Ada.Text_IO.New_Line;

   --  Automatic minimum size of flex items (CSS Flexbox 4.5).
   --
   --  A flex item may not be squeezed below its content-based minimum:
   --  min (specified size suggestion, min-content size). Adi contributes
   --  no intrinsic *height* for text (Label's Get_Min_Size returns the
   --  CSS min-height and an intrinsic width only), so a cramped column
   --  crushes labels to nothing and the text spills out of its box.
   --
   --  Expectations are measured from the widget rather than hard-coded,
   --  so they hold across fonts and DPI. For a single-line nowrap label
   --  the min-content height is its preferred height.
   declare
      Probe : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Hello");
      Nowrap_Style : constant Style_Rules :=
         (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>);
      Nowrap_WS    : constant Widget_Style := From (Nowrap_Style).Build;
      Nowrap_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Nowrap_WS, Enabled => True),
          others    => <>];
      Line_H : Pixel_Type;

      function Column_Style (Scrolls : Boolean) return Part_Style_Array is
         Base : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            others         => <>);
         Scroll_Rules : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            Overflow_Y     => Set (Overflow_Auto),
            others         => <>);
         WS : constant Widget_Style :=
           From (if Scrolls then Scroll_Rules else Base).Build;
      begin
         return [Main_Part => (Style => WS, Enabled => True), others => <>];
      end Column_Style;

      --  Lay two nowrap labels out in a column far too short for them
      --  and report the height each one ended up with.
      function Squeezed_Label_Height (Scrolls : Boolean) return Pixel_Type is
         Col : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
         A   : constant Widget_Handle :=
            +Adi.Widget.Label.Create_Handle ("Hello");
         B   : constant Widget_Handle :=
            +Adi.Widget.Label.Create_Handle ("World");
      begin
         Set_Part_Styles (Col, Column_Style (Scrolls));
         Set_Part_Styles (A, Nowrap_Parts);
         Set_Part_Styles (B, Nowrap_Parts);
         Add_Child (Col, A);
         Add_Child (Col, B);
         Set_Geometry
            (Col, (X => 0.0, Y => 0.0, Width => 200.0, Height => 10.0));
         Layout (Col);
         return Get_Geometry (A).Height;
      end Squeezed_Label_Height;

      Clipping_H  : Pixel_Type;
      Scrolling_H : Pixel_Type;
   begin
      Set_Part_Styles (Probe, Nowrap_Parts);
      Line_H := Get_Preferred_Size (Probe).Height;

      Clipping_H  := Squeezed_Label_Height (Scrolls => False);
      Scrolling_H := Squeezed_Label_Height (Scrolls => True);

      Ada.Text_IO.Put_Line
         ("  Label min-content height=" & Pixel_Type'Image (Line_H)
          & " squeezed: clipping=" & Pixel_Type'Image (Clipping_H)
          & " scrolling=" & Pixel_Type'Image (Scrolling_H));

      Test_Support.Assert
         (Clipping_H >= Line_H - 0.001,
          "flex item is not squeezed below its min-content height");

      --  The automatic minimum is a property of the item, so whether the
      --  container scrolls must not change it.
      Test_Support.Assert
         (abs (Scrolling_H - Clipping_H) <= 0.001,
          "container overflow does not change an item's automatic minimum");
   end;

   Ada.Text_IO.New_Line;

   --  Guards against over-correcting the above: the automatic minimum is
   --  capped by the specified size, so a declared height is a flex base,
   --  not a floor. Only min-height is a floor.
   declare
      Col : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Sized     : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Hi");
      Floored   : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Hi");

      Col_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Col_WS    : constant Widget_Style := From (Col_Style).Build;
      Col_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Col_WS, Enabled => True), others => <>];

      --  height: 200px — a flex base, shrinkable toward min-content.
      Sized_Style : constant Style_Rules :=
         (Height => Set (Size (Px (200.0))), others => <>);
      Sized_WS    : constant Widget_Style := From (Sized_Style).Build;
      Sized_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Sized_WS, Enabled => True), others => <>];

      --  min-height: 60px — an actual floor.
      Floored_Style : constant Style_Rules :=
         (Min_Height => Set (Size (Px (60.0))), others => <>);
      Floored_WS    : constant Widget_Style := From (Floored_Style).Build;
      Floored_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => Floored_WS, Enabled => True), others => <>];
   begin
      Set_Part_Styles (Col, Col_Parts);
      Set_Part_Styles (Sized, Sized_Parts);
      Set_Part_Styles (Floored, Floored_Parts);
      Add_Child (Col, Sized);
      Add_Child (Col, Floored);

      Set_Geometry
         (Col, (X => 0.0, Y => 0.0, Width => 200.0, Height => 100.0));
      Layout (Col);

      Ada.Text_IO.Put_Line
         ("  Sized child h=" & Pixel_Type'Image (Get_Geometry (Sized).Height)
          & " floored child h="
          & Pixel_Type'Image (Get_Geometry (Floored).Height));

      Test_Support.Assert
         (Get_Geometry (Sized).Height < 200.0,
          "declared height is a flex base, not a minimum");
      Test_Support.Assert
         (Get_Geometry (Floored).Height >= 60.0 - 0.001,
          "explicit min-height is honoured under shrink");
   end;

   Ada.Text_IO.New_Line;

   --  The remaining automatic-minimum branches (CSS Flexbox 4.5): the
   --  floor is capped by the item's specified size, and drops to zero
   --  when the item scrolls its own content in the main axis.
   declare
      function Squeezed_Height (Rules : Style_Rules) return Pixel_Type is
         Col : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
         Kid : constant Widget_Handle :=
            +Adi.Widget.Label.Create_Handle ("Hello");
         Col_Style : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            others         => <>);
         Col_Parts : constant Part_Style_Array :=
           [Main_Part => (Style => From (Col_Style).Build, Enabled => True),
            others    => <>];
         Kid_Parts : constant Part_Style_Array :=
           [Main_Part => (Style => From (Rules).Build, Enabled => True),
            others    => <>];
      begin
         Set_Part_Styles (Col, Col_Parts);
         Set_Part_Styles (Kid, Kid_Parts);
         Add_Child (Col, Kid);
         Set_Geometry
            (Col, (X => 0.0, Y => 0.0, Width => 200.0, Height => 4.0));
         Layout (Col);
         return Get_Geometry (Kid).Height;
      end Squeezed_Height;

      Nowrap : constant Style_Rules :=
        (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>);

      --  height smaller than the text: the specified size caps the floor.
      Tiny_Height : constant Style_Rules :=
        (Text_Wrap_Mode => Set (TWM_Nowrap),
         Height         => Set (Size (Px (6.0))),
         others         => <>);

      --  the item scrolls itself: no floor at all.
      Scrolling : constant Style_Rules :=
        (Text_Wrap_Mode => Set (TWM_Nowrap),
         Overflow_Y     => Set (Overflow_Auto),
         others         => <>);

      Plain_H  : constant Pixel_Type := Squeezed_Height (Nowrap);
      Capped_H : constant Pixel_Type := Squeezed_Height (Tiny_Height);
      Scroll_H : constant Pixel_Type := Squeezed_Height (Scrolling);
   begin
      Ada.Text_IO.Put_Line
         ("  Automatic minimum: plain=" & Pixel_Type'Image (Plain_H)
          & " height:6px=" & Pixel_Type'Image (Capped_H)
          & " overflow-y:auto=" & Pixel_Type'Image (Scroll_H));

      Test_Support.Assert
         (Capped_H <= 6.0 + 0.001,
          "specified height caps the automatic minimum");
      Test_Support.Assert
         (Capped_H < Plain_H,
          "an item with a small declared height shrinks past its content");
      Test_Support.Assert
         (Scroll_H < Plain_H,
          "an item that scrolls its own content has no automatic minimum");
   end;

   Ada.Text_IO.New_Line;

   --  A grid inside a column that runs out of room must not be allocated
   --  less than its rows need. When it is, the rows keep their own
   --  minimums and simply render outside the grid box — the Controls
   --  page showed exactly this, its value-input row hanging below the
   --  card that was supposed to contain it.
   Ada.Text_IO.Put_Line ("=== grid inside a squeezed column ===");
   declare
      Column : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Row_A_L  : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Alpha");
      Row_A_R  : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("One");
      Row_B_L  : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Beta");
      Row_B_R  : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Two");

      Col_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Col_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => From (Col_Style).Build, Enabled => True),
          others    => <>];

      --  Two columns, both 1fr: bare fr is minmax(auto, 1fr), so the
      --  tracks may not go below their items' minimum contribution.
      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (2)),
          Grid_Column_Tracks =>
             (Count  => 2,
              Tracks =>
                 [1      => (Track_Fr, 1.0),
                  2      => (Track_Fr, 1.0),
                  others => <>]),
          Gap                => Set (Gap (Px (30.0))),
          others             => <>);
      Grid_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => From (Grid_Style).Build, Enabled => True),
          others    => <>];

      Nowrap : constant Style_Rules :=
         (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>);
      Cell_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => From (Nowrap).Build, Enabled => True),
          others    => <>];

      Card      : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      --  Like the demo card: padded, with a gap between heading and grid.
      Card_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Padding        => Set (CSS_Box (Px (24.0))),
          others         => <>);
      Card_Parts : constant Part_Style_Array :=
         [Main_Part => (Style => From (Card_Style).Build, Enabled => True),
          others    => <>];
      Heading   : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Heading");
      Grid_Geom : Rectangle;
      Card_Geom : Rectangle;
      Cell_Geom : Rectangle;
      Cell_Min  : Size_2D;
   begin
      Set_Part_Styles (Column, Col_Parts);
      Set_Part_Styles (Card, Card_Parts);
      Set_Part_Styles (Heading, Cell_Parts);
      Set_Part_Styles (Grid_Box, Grid_Parts);
      Set_Part_Styles (Row_A_L, Cell_Parts);
      Set_Part_Styles (Row_A_R, Cell_Parts);
      Set_Part_Styles (Row_B_L, Cell_Parts);
      Set_Part_Styles (Row_B_R, Cell_Parts);
      Add_Child (Grid_Box, Row_A_L);
      Add_Child (Grid_Box, Row_A_R);
      Add_Child (Grid_Box, Row_B_L);
      Add_Child (Grid_Box, Row_B_R);

      --  Mirror the demo: a card holding a heading plus the grid, itself
      --  a flex item in a column with nowhere near enough room.
      Add_Child (Card, Heading);
      Add_Child (Card, Grid_Box);
      Add_Child (Column, Card);

      --  Far less room than two rows of text need.
      Set_Geometry
         (Column, (X => 0.0, Y => 0.0, Width => 400.0, Height => 10.0));
      Layout (Column);

      Grid_Geom := Get_Geometry (Grid_Box);
      Card_Geom := Get_Geometry (Card);
      Cell_Geom := Get_Geometry (Row_B_L);
      Cell_Min  := Get_Content_Min_Size (Row_B_L);

      Ada.Text_IO.Put_Line
         ("  card h=" & Pixel_Type'Image (Card_Geom.Height)
          & " card bottom="
          & Pixel_Type'Image (Card_Geom.Y + Card_Geom.Height)
          & " grid bottom="
          & Pixel_Type'Image (Grid_Geom.Y + Grid_Geom.Height)
          & " cell min h=" & Pixel_Type'Image (Cell_Min.Height));

      Test_Support.Assert
         (Cell_Geom.Y + Cell_Geom.Height
            <= Grid_Geom.Y + Grid_Geom.Height + 0.001,
          "grid rows stay inside the grid box");

      Test_Support.Assert
         (Grid_Geom.Y + Grid_Geom.Height
            <= Card_Geom.Y + Card_Geom.Height + 0.001,
          "the grid stays inside the card that holds it");

      --  Horizontal counterpart: an fr track may not be narrower than
      --  the cell's own content, which is what clips button labels.
      Test_Support.Assert
         (Get_Geometry (Row_A_L).Width >= Get_Content_Min_Size (Row_A_L).Width
            - 0.001,
          "an fr track is not narrower than its cell's content minimum");
   end;

   Ada.Text_IO.New_Line;

   --  A definite size on a grid item is honoured unconditionally when
   --  the item is placed, so it has to count toward the track's minimum
   --  as well. Reporting a smaller minimum promises a flexibility the
   --  grid will not deliver: the parent shrinks to that promise and the
   --  items then lay out at their declared sizes and escape the box.
   --  These children carry height but deliberately no min-height.
   Ada.Text_IO.Put_Line ("=== definite item heights count as grid minimums ===");
   declare
      Card : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Tall  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Short : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Row_Gap_Px : constant := 10.0;
      Tall_H     : constant := 60.0;
      Short_H    : constant := 40.0;

      Card_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (1)),
          Grid_Column_Tracks =>
             (Count  => 1,
              Tracks => [1 => (Track_Fr, 1.0), others => <>]),
          Gap                => Set (Gap (Px (Row_Gap_Px))),
          others             => <>);

      function Fixed_Height (H : Float) return Part_Style_Array is
         R : constant Style_Rules :=
            (Height => Set (Size (Px (H))), others => <>);
      begin
         return [Main_Part => (Style => From (R).Build, Enabled => True),
                 others    => <>];
      end Fixed_Height;

      Grid_Min : Size_2D;
   begin
      Set_Part_Styles
         (Card, [Main_Part => (Style => From (Card_Style).Build,
                               Enabled => True), others => <>]);
      Set_Part_Styles
         (Grid_Box, [Main_Part => (Style => From (Grid_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles (Tall, Fixed_Height (Tall_H));
      Set_Part_Styles (Short, Fixed_Height (Short_H));

      Add_Child (Grid_Box, Tall);
      Add_Child (Grid_Box, Short);
      Add_Child (Card, Grid_Box);

      Grid_Min := Get_Content_Min_Size (Grid_Box);
      Ada.Text_IO.Put_Line
         ("  grid content min h=" & Pixel_Type'Image (Grid_Min.Height)
          & " (rows " & Pixel_Type'Image (Tall_H)
          & " +" & Pixel_Type'Image (Short_H)
          & " + gap" & Pixel_Type'Image (Row_Gap_Px) & ")");

      Test_Support.Assert
         (Grid_Min.Height >= Tall_H + Short_H + Row_Gap_Px - 0.001,
          "grid content minimum includes its items' definite heights");

      --  Squeeze the card far below that and check nothing escapes.
      Set_Geometry
         (Card, (X => 0.0, Y => 0.0, Width => 200.0, Height => 30.0));
      Layout (Card);

      declare
         G  : constant Rectangle := Get_Geometry (Grid_Box);
         S  : constant Rectangle := Get_Geometry (Short);
      begin
         Ada.Text_IO.Put_Line
            ("  after squeeze: grid bottom="
             & Pixel_Type'Image (G.Y + G.Height)
             & " last item bottom=" & Pixel_Type'Image (S.Y + S.Height));
         Test_Support.Assert
            (S.Y + S.Height <= G.Y + G.Height + 0.001,
             "items stay inside the grid when the card is squeezed");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  Counter-test: content with no definite size must stay flexible, so
   --  preferred size does not quietly become the minimum.
   declare
      Flexible : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Flexible content here");
      Wrap_Style : constant Style_Rules :=
         (Text_Wrap_Mode => Set (TWM_Wrap), others => <>);
   begin
      Set_Part_Styles
         (Flexible, [Main_Part => (Style => From (Wrap_Style).Build,
                                   Enabled => True), others => <>]);
      Ada.Text_IO.Put_Line
         ("  flexible label: pref w="
          & Pixel_Type'Image (Get_Preferred_Size (Flexible).Width)
          & " content min w="
          & Pixel_Type'Image (Get_Content_Min_Size (Flexible).Width));
      Test_Support.Assert
         (Get_Content_Min_Size (Flexible).Width
            < Get_Preferred_Size (Flexible).Width,
          "a wrappable label's minimum stays below its preferred width");
   end;

   Ada.Text_IO.New_Line;
   Test_Support.Finish;
end Min_Size_Test;
