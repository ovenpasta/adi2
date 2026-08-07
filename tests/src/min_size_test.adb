pragma Ada_2022;

with Ada.Text_IO;
with Adi.App;
with Adi.Core;          use Adi.Core;
with Adi.Widget;        use Adi.Widget;
with Adi.Image;
with Adi.Widget.Label;
with Adi.Widget.Box;
with Adi.Widget.List_Box;
with Adi.Widget.Stack;
with Adi.Widget.Text_Input;
with Adi.Layout_Util;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Test_Support;

procedure Min_Size_Test is
   A          : Adi.App.App;
   package Box_Row_List is new
      Adi.Widget.List_Box (Adi.Widget.Box.Box_Widget);
   package Label_Row_List is new
      Adi.Widget.List_Box (Adi.Widget.Label.Label_Widget);
   type Widget_Pair is array (Positive range <>) of Widget_Handle;

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

   --  Test 6: a flexible track may not shrink below its item's minimum;
   --  when the minimums do not fit, the grid overflows.
   --
   --  Bare Nfr is minmax(auto, Nfr), so the track's floor is its items'
   --  minimum contribution. Adi used to discard that floor to keep the
   --  layout inside its container, which silently violated an explicit
   --  min-width — the visible symptom being clipped button labels. A
   --  minimum that yields under pressure is not a minimum: the correct
   --  outcome is to honour it and overflow.
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

      --  The floor is honoured even though it does not fit.
      Test_Support.Assert
         (Fr_Geom.Width >= 800.0,
          "fr column is at least its child's min-width (800px)");
      --  And the consequence is overflow, not a violated minimum.
      Test_Support.Assert
         (Fr_Geom.X + Fr_Geom.Width > Container_W,
          "the grid overflows when the floors exceed the container");
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

      --  The card must carry that minimum outward, or its own parent
      --  will squeeze it below what the grid needs.
      Test_Support.Assert
         (Get_Content_Min_Size (Card).Height >= Grid_Min.Height - 0.001,
          "the card's content minimum covers the grid it holds");

      --  Squeeze from outside, through a column, and check nothing
      --  escapes at either level.
      declare
         Column : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      begin
         Set_Part_Styles
            (Column, [Main_Part => (Style => From (Card_Style).Build,
                                    Enabled => True), others => <>]);
         Add_Child (Column, Card);
         Set_Geometry
            (Column, (X => 0.0, Y => 0.0, Width => 200.0, Height => 30.0));
         Layout (Column);
      end;

      declare
         C  : constant Rectangle := Get_Geometry (Card);
         G  : constant Rectangle := Get_Geometry (Grid_Box);
         S  : constant Rectangle := Get_Geometry (Short);
      begin
         Ada.Text_IO.Put_Line
            ("  after squeeze: card bottom="
             & Pixel_Type'Image (C.Y + C.Height)
             & " grid bottom=" & Pixel_Type'Image (G.Y + G.Height)
             & " last item bottom=" & Pixel_Type'Image (S.Y + S.Height));
         Test_Support.Assert
            (S.Y + S.Height <= G.Y + G.Height + 0.001,
             "items stay inside the grid when the card is squeezed");
         Test_Support.Assert
            (G.Y + G.Height <= C.Y + C.Height + 0.001,
             "the grid stays inside the card when squeezed");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  Counter-test, inside a grid so it would catch the aggregation
   --  quietly using max (preferred, minimum): content with no definite
   --  size must stay flexible.
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Flexible : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("Flexible content here");
      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (1)),
          Grid_Column_Tracks =>
             (Count  => 1,
              Tracks => [1 => (Track_Fr, 1.0), others => <>]),
          others             => <>);
      Wrap_Style : constant Style_Rules :=
         (Text_Wrap_Mode => Set (TWM_Wrap), others => <>);
   begin
      Set_Part_Styles
         (Grid_Box, [Main_Part => (Style => From (Grid_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Flexible, [Main_Part => (Style => From (Wrap_Style).Build,
                                   Enabled => True), others => <>]);
      Add_Child (Grid_Box, Flexible);

      Ada.Text_IO.Put_Line
         ("  flexible label in grid: grid pref w="
          & Pixel_Type'Image (Get_Preferred_Size (Grid_Box).Width)
          & " grid content min w="
          & Pixel_Type'Image (Get_Content_Min_Size (Grid_Box).Width));
      Test_Support.Assert
         (Get_Content_Min_Size (Flexible).Width
            < Get_Preferred_Size (Flexible).Width,
          "a wrappable label's minimum stays below its preferred width");
      --  Compared against the child's preferred width, not the grid's:
      --  a grid whose only column is 1fr currently reports the
      --  min-content width as its preferred width too, so comparing the
      --  two would pass for the wrong reason. Tracked separately.
      Test_Support.Assert
         (Get_Content_Min_Size (Grid_Box).Width
            < Get_Preferred_Size (Flexible).Width,
          "a grid holding only flexible content keeps a minimum below "
          & "that content's preferred width");
   end;

   Ada.Text_IO.New_Line;

   --  A definite cross size is not flex-shrunk, so a row is at least as
   --  tall as the tallest child that declares a height. Reporting less
   --  lets an outer column squeeze the row while its children keep that
   --  height, and they spill over the row below instead of overflowing.
   --  These children carry height but deliberately no min-height.
   Ada.Text_IO.Put_Line ("=== definite cross sizes count as row minimums ===");
   declare
      Column : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Row_1  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Row_2  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Card_1 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Card_2 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Card_H    : constant := 60.0;
      Col_Gap   : constant := 10.0;
      --  Half of what the two rows and the gap need.
      Squeeze_H : constant := 65.0;

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Gap            => Set (Gap (Px (Col_Gap))),
          others         => <>);
      Row_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          others         => <>);
      Card_Style : constant Style_Rules :=
         (Height    => Set (Size (Px (Card_H))),
          Flex_Grow => Set (1.0),
          others    => <>);

      Row_Min : Pixel_Type;
   begin
      Set_Part_Styles
         (Column, [Main_Part => (Style => From (Column_Style).Build,
                                 Enabled => True), others => <>]);
      Set_Part_Styles
         (Row_1, [Main_Part => (Style => From (Row_Style).Build,
                                Enabled => True), others => <>]);
      Set_Part_Styles
         (Row_2, [Main_Part => (Style => From (Row_Style).Build,
                                Enabled => True), others => <>]);
      Set_Part_Styles
         (Card_1, [Main_Part => (Style => From (Card_Style).Build,
                                 Enabled => True), others => <>]);
      Set_Part_Styles
         (Card_2, [Main_Part => (Style => From (Card_Style).Build,
                                 Enabled => True), others => <>]);

      Add_Child (Row_1, Card_1);
      Add_Child (Row_2, Card_2);
      Add_Child (Column, Row_1);
      Add_Child (Column, Row_2);

      Row_Min := Get_Content_Min_Size (Row_1).Height;
      Ada.Text_IO.Put_Line
         ("  row content min h=" & Pixel_Type'Image (Row_Min)
          & " (card height" & Pixel_Type'Image (Card_H) & ")");

      Test_Support.Assert
         (Row_Min >= Card_H - 0.001,
          "a row's content minimum covers its child's definite height");

      Set_Geometry
         (Column, (X => 0.0, Y => 0.0, Width => 200.0, Height => Squeeze_H));
      Layout (Column);

      declare
         R1 : constant Rectangle := Get_Geometry (Row_1);
         R2 : constant Rectangle := Get_Geometry (Row_2);
         C1 : constant Rectangle := Get_Geometry (Card_1);
      begin
         Ada.Text_IO.Put_Line
            ("  squeezed to" & Pixel_Type'Image (Squeeze_H)
             & ": row1 h=" & Pixel_Type'Image (R1.Height)
             & " card1 h=" & Pixel_Type'Image (C1.Height)
             & " row2 y=" & Pixel_Type'Image (R2.Y)
             & " row1 bottom=" & Pixel_Type'Image (R1.Y + R1.Height));

         Test_Support.Assert
            (R1.Height >= Card_H - 0.001,
             "a squeezed row keeps its child's definite height");
         Test_Support.Assert
            (C1.Y + C1.Height <= R1.Y + R1.Height + 0.001,
             "the child stays inside its row when the column is squeezed");
         Test_Support.Assert
            (R2.Y >= R1.Y + R1.Height + Col_Gap - 0.001,
             "the second row starts after the first plus the gap");
         Test_Support.Assert
            (R2.Y + R2.Height > Squeeze_H,
             "the rows overflow the squeezed column rather than overlap");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  A shrinkable column of non-shrinkable children may not report a
   --  minimum below what those children occupy. The parent shrinks it to
   --  that floor, the children keep their size, and the tail escapes the
   --  box a scrollbar is measured from, so it can never be reached.
   Ada.Text_IO.Put_Line
      ("=== non-shrinkable children floor a column's minimum ===");
   declare
      Long_Text : constant String :=
         "Wrapped text whose height depends on the width it is given, "
         & "so measuring it on one line under-reports what it occupies.";

      Viewport  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Container : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid_1 : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle (Long_Text);
      Kid_2 : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle (Long_Text);

      Kid_Gap  : constant := 10.0;
      View_W   : constant := 200.0;
      --  Far shorter than the two wrapped children need.
      View_H   : constant := 100.0;

      Viewport_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
          others         => <>);
      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Gap            => Set (Gap (Px (Kid_Gap))),
          others         => <>);
      Kid_Style : constant Style_Rules :=
         (Flex_Shrink    => Set (0.0),
          Text_Wrap_Mode => Set (TWM_Wrap),
          Font_Size      => Set_Font (Px (20)),
          others         => <>);

      Needed : Pixel_Type;
   begin
      Set_Part_Styles
         (Viewport, [Main_Part => (Style => From (Viewport_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Container, [Main_Part => (Style => From (Column_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid_1, [Main_Part => (Style => From (Kid_Style).Build,
                                Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid_2, [Main_Part => (Style => From (Kid_Style).Build,
                                Enabled => True), others => <>]);

      Add_Child (Container, Kid_1);
      Add_Child (Container, Kid_2);
      Add_Child (Viewport, Container);

      Needed := Measure_At_Width (Container, View_W).Height;
      Ada.Text_IO.Put_Line
         ("  container needs" & Pixel_Type'Image (Needed)
          & " at width" & Pixel_Type'Image (View_W)
          & ", content min" & Pixel_Type'Image
              (Get_Content_Min_Size (Container).Height)
          & ", width-aware min" & Pixel_Type'Image
              (Effective_Min_Size_At_Width (Container, View_W).Height));

      Set_Geometry
         (Viewport, (X => 0.0, Y => 0.0, Width => View_W, Height => View_H));
      Layout_Tree (Viewport);

      declare
         C  : constant Rectangle := Get_Geometry (Container);
         K2 : constant Rectangle := Get_Geometry (Kid_2);
      begin
         Ada.Text_IO.Put_Line
            ("  container h=" & Pixel_Type'Image (C.Height)
             & " bottom=" & Pixel_Type'Image (C.Y + C.Height)
             & "  last child bottom=" & Pixel_Type'Image (K2.Y + K2.Height));

         Test_Support.Assert
            (C.Height >= Needed - 0.001,
             "a column of non-shrinkable children keeps the height they need");
         Test_Support.Assert
            (K2.Y + K2.Height <= C.Y + C.Height + 0.001,
             "the last child stays inside the column it belongs to");

         --  Containment alone still hides the tail if the viewport's
         --  scroll range stops short of it.
         Ada.Text_IO.Put_Line
            ("  scroll content h="
             & Pixel_Type'Image (Get_Scroll_Content_Height (Viewport))
             & " max offset y="
             & Pixel_Type'Image (Get_Scroll_Max_Offset_Y (Viewport)));
         Test_Support.Assert
            (Get_Scroll_Content_Height (Viewport) >= Needed - 0.001,
             "the viewport's scroll content covers what the column needs");
         Test_Support.Assert
            (Get_Scroll_Max_Offset_Y (Viewport) + View_H >= Needed - 0.001,
             "scrolling to the end reaches the last child");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  The floor is width-dependent, so it has to be recomputed from the
   --  width being assigned rather than read back from the last layout.
   Ada.Text_IO.Put_Line ("=== the column's floor reflows with its width ===");
   declare
      Long_Text : constant String :=
         "Wrapped text whose height depends on the width it is given, "
         & "so measuring it on one line under-reports what it occupies.";

      Viewport  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Container : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle (Long_Text);

      Narrow : constant := 200.0;
      Wide   : constant := 600.0;

      Viewport_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
          others         => <>);
      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Kid_Style : constant Style_Rules :=
         (Flex_Shrink    => Set (0.0),
          Text_Wrap_Mode => Set (TWM_Wrap),
          Font_Size      => Set_Font (Px (20)),
          others         => <>);

      procedure Lay_Out_At (W : Pixel_Type) is
      begin
         Set_Geometry
            (Viewport, (X => 0.0, Y => 0.0, Width => W, Height => 60.0));
         Layout_Tree (Viewport);
      end Lay_Out_At;

      Expected_Narrow, Expected_Wide : Pixel_Type;
      Narrow_H, Wide_H, Back_H : Pixel_Type;
   begin
      Set_Part_Styles
         (Viewport, [Main_Part => (Style => From (Viewport_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Container, [Main_Part => (Style => From (Column_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid, [Main_Part => (Style => From (Kid_Style).Build,
                              Enabled => True), others => <>]);

      Add_Child (Container, Kid);
      Add_Child (Viewport, Container);

      --  Both expectations come from measurement, before any layout has
      --  run, so no pass can be satisfied by the previous pass's geometry.
      Expected_Narrow := Measure_At_Width (Container, Narrow).Height;
      Expected_Wide   := Measure_At_Width (Container, Wide).Height;

      Test_Support.Assert
         (Expected_Wide < Expected_Narrow - 0.001,
          "a wider column measures shorter than a narrow one");

      Lay_Out_At (Narrow);
      Narrow_H := Get_Geometry (Container).Height;
      Lay_Out_At (Wide);
      Wide_H := Get_Geometry (Container).Height;
      Lay_Out_At (Narrow);
      Back_H := Get_Geometry (Container).Height;

      Ada.Text_IO.Put_Line
         ("  narrow h=" & Pixel_Type'Image (Narrow_H)
          & " (expected" & Pixel_Type'Image (Expected_Narrow) & ")"
          & "  wide h=" & Pixel_Type'Image (Wide_H)
          & " (expected" & Pixel_Type'Image (Expected_Wide) & ")"
          & "  narrow again h=" & Pixel_Type'Image (Back_H));

      Test_Support.Assert
         (abs (Narrow_H - Expected_Narrow) < 0.001,
          "the narrow layout matches what the narrow width measures");
      Test_Support.Assert
         (abs (Wide_H - Expected_Wide) < 0.001,
          "the wide layout matches what the wide width measures");
      Test_Support.Assert
         (abs (Back_H - Expected_Narrow) < 0.001,
          "returning to the narrow width restores the narrow height");
   end;

   Ada.Text_IO.New_Line;

   --  Counter-test: the floor comes from the children being unable to
   --  shrink, not from their being present. Shrinkable children with
   --  small minimums must leave the column free to collapse.
   Ada.Text_IO.Put_Line ("=== shrinkable children leave a column flexible ===");
   declare
      Container : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid_1 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid_2 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Kid_Style : constant Style_Rules :=
         (Height     => Set (Size (Px (80.0))),
          Min_Height => Set (Size (Px (5.0))),
          others     => <>);
   begin
      Set_Part_Styles
         (Container, [Main_Part => (Style => From (Column_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid_1, [Main_Part => (Style => From (Kid_Style).Build,
                                Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid_2, [Main_Part => (Style => From (Kid_Style).Build,
                                Enabled => True), others => <>]);

      Add_Child (Container, Kid_1);
      Add_Child (Container, Kid_2);

      Ada.Text_IO.Put_Line
         ("  content min h="
          & Pixel_Type'Image (Get_Content_Min_Size (Container).Height)
          & " (two shrinkable 80px children, min-height 5px)");

      Test_Support.Assert
         (abs (Get_Content_Min_Size (Container).Height - 2.0 * 5.0) < 0.001,
          "shrinkable children contribute exactly their own minimums");
   end;

   Ada.Text_IO.New_Line;

   --  flex-basis: 0 is a definite demand for nothing. A child that cannot
   --  shrink still contributes only that basis, never its preferred size.
   Ada.Text_IO.Put_Line ("=== a zero flex basis is not promoted ===");
   declare
      Container : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Kid_Style : constant Style_Rules :=
         (Flex_Shrink => Set (0.0),
          Flex_Basis  => Set (Basis (Px (0.0))),
          Height      => Set (Size (Px (90.0))),
          others      => <>);
   begin
      Set_Part_Styles
         (Container, [Main_Part => (Style => From (Column_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid, [Main_Part => (Style => From (Kid_Style).Build,
                              Enabled => True), others => <>]);
      Add_Child (Container, Kid);

      Ada.Text_IO.Put_Line
         ("  content min h="
          & Pixel_Type'Image (Get_Content_Min_Size (Container).Height)
          & " (flex-shrink 0, flex-basis 0, height 90px)");

      Test_Support.Assert
         (abs (Get_Content_Min_Size (Container).Height) < 0.001,
          "a zero flex basis contributes nothing, not the child's height");
   end;

   Ada.Text_IO.New_Line;

   --  A definite basis is the size a non-shrinkable child is laid out at,
   --  so it is exactly what the container has to reserve -- no more from
   --  the content, no less from the child's own minimum.
   Ada.Text_IO.Put_Line ("=== a definite flex basis is reserved exactly ===");
   declare
      Container : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("Wrapping content that would measure far taller than the "
              & "basis it declares, were the basis ignored.");

      Basis_Px : constant := 70.0;

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      --  min-height: 0 takes the automatic minimum out of the question,
      --  so what is left is the basis and nothing else. Without it the
      --  content-based minimum legitimately dominates a smaller basis.
      Kid_Style : constant Style_Rules :=
         (Flex_Shrink    => Set (0.0),
          Flex_Basis     => Set (Basis (Px (Basis_Px))),
          Min_Height     => Set (Size (Px (0.0))),
          Text_Wrap_Mode => Set (TWM_Wrap),
          Font_Size      => Set_Font (Px (20)),
          others         => <>);
   begin
      Set_Part_Styles
         (Container, [Main_Part => (Style => From (Column_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid, [Main_Part => (Style => From (Kid_Style).Build,
                              Enabled => True), others => <>]);
      Add_Child (Container, Kid);

      Ada.Text_IO.Put_Line
         ("  content min h="
          & Pixel_Type'Image
              (Effective_Min_Size_At_Width (Container, 200.0).Height)
          & " (flex-shrink 0, flex-basis" & Pixel_Type'Image (Basis_Px) & ")");

      Test_Support.Assert
         (abs (Effective_Min_Size_At_Width (Container, 200.0).Height
                 - Basis_Px) < 0.001,
          "a definite flex basis is reserved exactly, not the content size");
   end;

   Ada.Text_IO.New_Line;

   --  The zero-basis rule has to survive a real layout, not just the
   --  aggregation: nothing may promote the basis back to the content.
   Ada.Text_IO.Put_Line ("=== a zero basis survives layout ===");
   declare
      Viewport  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Container : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("Wrapping content with a zero basis and no minimum of its "
              & "own, which may not hold the column open.");

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Kid_Style : constant Style_Rules :=
         (Flex_Shrink    => Set (0.0),
          Flex_Basis     => Set (Basis (Px (0.0))),
          Min_Height     => Set (Size (Px (0.0))),
          Text_Wrap_Mode => Set (TWM_Wrap),
          Font_Size      => Set_Font (Px (20)),
          others         => <>);
   begin
      Set_Part_Styles
         (Viewport, [Main_Part => (Style => From (Column_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Container, [Main_Part => (Style => From (Column_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid, [Main_Part => (Style => From (Kid_Style).Build,
                              Enabled => True), others => <>]);
      Add_Child (Container, Kid);
      Add_Child (Viewport, Container);

      Set_Geometry
         (Viewport, (X => 0.0, Y => 0.0, Width => 200.0, Height => 400.0));
      Layout_Tree (Viewport);

      Ada.Text_IO.Put_Line
         ("  after layout: content min h="
          & Pixel_Type'Image
              (Effective_Min_Size_At_Width (Container, 200.0).Height));

      Test_Support.Assert
         (abs (Effective_Min_Size_At_Width (Container, 200.0).Height) < 0.001,
          "a zero basis is still zero once the tree has been laid out");
   end;

   Ada.Text_IO.New_Line;

   --  The width-aware minimum is a new primitive with a default that
   --  forwards to the old one. A widget that overrides only the old one
   --  must still be heard, which needs the forward to dispatch.
   Ada.Text_IO.Put_Line ("=== the width-aware default dispatches ===");
   declare
      --  Text_Input overrides only the widthless primitive, so it is
      --  reached through the default forward or not at all.
      Input : constant Widget_Handle :=
         Adi.Widget.Text_Input.To_Widget_Handle
           (Adi.Widget.Text_Input.Create_Handle);

      Widthless : constant Pixel_Type :=
         Get_Content_Min_Size (Input).Width;
      At_Width  : constant Pixel_Type :=
         Effective_Min_Size_At_Width (Input, 300.0).Width;
   begin
      Ada.Text_IO.Put_Line
         ("  widthless=" & Pixel_Type'Image (Widthless)
          & "  through the width-aware default="
          & Pixel_Type'Image (At_Width));

      Test_Support.Assert
         (Widthless > 0.0,
          "the widget reports a content minimum of its own");
      Test_Support.Assert
         (abs (At_Width - Widthless) < 0.001,
          "an override of the widthless primitive is reached through "
          & "the width-aware default");
   end;

   Ada.Text_IO.New_Line;

   --  flex-basis: content sizes from the content, so it reflows with the
   --  width like auto does. Aggregation and layout must agree on that:
   --  one reserving the unwrapped height while the other places the
   --  wrapped one is how a child ends up outside its parent.
   Ada.Text_IO.Put_Line ("=== flex-basis content reflows with the width ===");
   declare
      Viewport  : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Container : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("A paragraph long enough to take several lines once it is "
              & "given a narrow column to wrap inside of.");

      View_W : constant := 200.0;

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      --  min-height: 0 so the automatic minimum cannot stand in for the
      --  basis: what is reserved here is the basis or nothing.
      Kid_Style : constant Style_Rules :=
         (Flex_Shrink    => Set (0.0),
          Flex_Basis     => Set (Content_Basis),
          Min_Height     => Set (Size (Px (0.0))),
          Text_Wrap_Mode => Set (TWM_Wrap),
          Font_Size      => Set_Font (Px (20)),
          others         => <>);

      Reserved : Pixel_Type;
   begin
      Set_Part_Styles
         (Viewport, [Main_Part => (Style => From (Column_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Container, [Main_Part => (Style => From (Column_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid, [Main_Part => (Style => From (Kid_Style).Build,
                              Enabled => True), others => <>]);
      Add_Child (Container, Kid);
      Add_Child (Viewport, Container);

      Reserved := Effective_Min_Size_At_Width (Container, View_W).Height;

      Set_Geometry
         (Viewport, (X => 0.0, Y => 0.0, Width => View_W, Height => 40.0));
      Layout_Tree (Viewport);

      Ada.Text_IO.Put_Line
         ("  aggregation reserved" & Pixel_Type'Image (Reserved)
          & ", layout placed"
          & Pixel_Type'Image (Get_Geometry (Kid).Height));

      Test_Support.Assert
         (abs (Reserved - Get_Geometry (Kid).Height) < 0.001,
          "flex-basis content reserves what layout places");
   end;

   Ada.Text_IO.New_Line;

   --  A hidden or absolute sibling is not on the line, so the child that
   --  is left is a lone row child and its width follows from the box's.
   Ada.Text_IO.Put_Line ("=== out-of-flow siblings do not make a row ===");
   declare
      Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Only : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("Text that wraps to more than one line inside this row.");
      Hidden : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Floating : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Row_W : constant := 200.0;

      Row_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          others         => <>);
      Only_Style : constant Style_Rules :=
         (Flex_Grow      => Set (1.0),
          Text_Wrap_Mode => Set (TWM_Wrap),
          Font_Size      => Set_Font (Px (20)),
          others         => <>);
      Hidden_Style : constant Style_Rules :=
         (Display => Set (Display_None), others => <>);
      Floating_Style : constant Style_Rules :=
         (Position => Set (Absolute), others => <>);
   begin
      Set_Part_Styles
         (Row, [Main_Part => (Style => From (Row_Style).Build,
                              Enabled => True), others => <>]);
      Set_Part_Styles
         (Only, [Main_Part => (Style => From (Only_Style).Build,
                               Enabled => True), others => <>]);
      Set_Part_Styles
         (Hidden, [Main_Part => (Style => From (Hidden_Style).Build,
                                 Enabled => True), others => <>]);
      Set_Part_Styles
         (Floating, [Main_Part => (Style => From (Floating_Style).Build,
                                   Enabled => True), others => <>]);

      Add_Child (Row, Only);
      Add_Child (Row, Hidden);
      Add_Child (Row, Floating);

      Ada.Text_IO.Put_Line
         ("  row min at width" & Pixel_Type'Image
             (Effective_Min_Size_At_Width (Row, Row_W).Height)
          & ", child wrapped" & Pixel_Type'Image
             (Measure_At_Width (Only, Row_W).Height)
          & ", child unwrapped" & Pixel_Type'Image
             (Get_Content_Min_Size (Only).Height));

      --  Aggregation is the path that used to count stored children
      --  rather than in-flow ones, hand back Unknown, and fall through
      --  to the unwrapped minimum.
      Test_Support.Assert
         (abs (Effective_Min_Size_At_Width (Row, Row_W).Height
                 - Measure_At_Width (Only, Row_W).Height) < 0.001,
          "a row with one in-flow child aggregates at the real width");
   end;

   Ada.Text_IO.New_Line;

   --  A row of several children shares its line by the distribution, so
   --  measuring one means running it. Answering from the unconstrained
   --  preference instead reports a single line per child, and the cards
   --  are then built too short for the text they hold.
   Ada.Text_IO.Put_Line ("=== a multi-child row measures at real widths ===");
   declare
      Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Card_A : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Card_B : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Body_A : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("A line of text long enough to wrap once the card holding "
              & "it has been given half of the row.");
      Body_B : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("Another passage, also long enough that it cannot sit on a "
              & "single line inside its own card.");

      Row_W : constant := 400.0;

      Row_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          Gap            => Set (Gap (Px (10.0))),
          others         => <>);
      Card_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Flex_Grow      => Set (1.0),
          others         => <>);
      Body_Style : constant Style_Rules :=
         (Text_Wrap_Mode => Set (TWM_Wrap),
          Font_Size      => Set_Font (Px (20)),
          others         => <>);

      Measured : Pixel_Type;
   begin
      Set_Part_Styles
         (Row, [Main_Part => (Style => From (Row_Style).Build,
                              Enabled => True), others => <>]);
      for C of Widget_Pair'[Card_A, Card_B] loop
         Set_Part_Styles
            (C, [Main_Part => (Style => From (Card_Style).Build,
                               Enabled => True), others => <>]);
      end loop;
      for L of Widget_Pair'[Body_A, Body_B] loop
         Set_Part_Styles
            (L, [Main_Part => (Style => From (Body_Style).Build,
                               Enabled => True), others => <>]);
      end loop;

      Add_Child (Card_A, Body_A);
      Add_Child (Card_B, Body_B);
      Add_Child (Row, Card_A);
      Add_Child (Row, Card_B);

      Measured := Measure_At_Width (Row, Row_W).Height;

      --  Measurement is a query: asking must leave no geometry behind.
      Test_Support.Assert
         ((for all H of Widget_Pair'[Card_A, Card_B, Body_A, Body_B] =>
             Get_Geometry (H).Width = 0.0
             and then Get_Geometry (H).Height = 0.0),
          "measuring a row leaves its children's geometry alone");

      Set_Geometry
         (Row, (X => 0.0, Y => 0.0, Width => Row_W, Height => Measured));
      Layout_Tree (Row);

      Ada.Text_IO.Put_Line
         ("  measured" & Pixel_Type'Image (Measured)
          & ", laid out" & Pixel_Type'Image (Get_Geometry (Row).Height)
          & "; card A h=" & Pixel_Type'Image (Get_Geometry (Card_A).Height)
          & " body A bottom="
          & Pixel_Type'Image (Get_Geometry (Body_A).Y
                              + Get_Geometry (Body_A).Height));

      Test_Support.Assert
         (abs (Measured - Get_Geometry (Row).Height) < 0.001,
          "a row measures the height it is then laid out at");

      declare
         A  : constant Rectangle := Get_Geometry (Card_A);
         B  : constant Rectangle := Get_Geometry (Card_B);
         BA : constant Rectangle := Get_Geometry (Body_A);
         BB : constant Rectangle := Get_Geometry (Body_B);
      begin
         Test_Support.Assert
            (BA.Y + BA.Height <= A.Y + A.Height + 0.001,
             "the first card contains its wrapped text");
         Test_Support.Assert
            (BB.Y + BB.Height <= B.Y + B.Height + 0.001,
             "the second card contains its wrapped text");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  A declared width is the item's basis on the main axis, not its
   --  final width: it still shrinks when the line is too narrow, and a
   --  lone item still grows past it. Measuring at the declared width
   --  would report the wrong column to wrap text inside.
   Ada.Text_IO.Put_Line ("=== declared widths are a basis, not the answer ===");
   declare
      Narrow_Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Wide_A : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Wide_B : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Grow_Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Only : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Row_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          others         => <>);
      Two_Hundred : constant Style_Rules :=
         (Width => Set (Size (Px (200.0))), others => <>);
      Hundred_Growing : constant Style_Rules :=
         (Width     => Set (Size (Px (100.0))),
          Flex_Grow => Set (1.0),
          others    => <>);
   begin
      Set_Part_Styles
         (Narrow_Row, [Main_Part => (Style => From (Row_Style).Build,
                                     Enabled => True), others => <>]);
      Set_Part_Styles
         (Wide_A, [Main_Part => (Style => From (Two_Hundred).Build,
                                 Enabled => True), others => <>]);
      Set_Part_Styles
         (Wide_B, [Main_Part => (Style => From (Two_Hundred).Build,
                                 Enabled => True), others => <>]);
      Add_Child (Narrow_Row, Wide_A);
      Add_Child (Narrow_Row, Wide_B);

      Set_Part_Styles
         (Grow_Row, [Main_Part => (Style => From (Row_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Only, [Main_Part => (Style => From (Hundred_Growing).Build,
                               Enabled => True), others => <>]);
      Add_Child (Grow_Row, Only);

      declare
         Shrunk : constant Flex_Row_Items :=
            Flex_Row_Child_Widths (Resolve_Handle (Narrow_Row).all, 300.0);
         Grown  : constant Flex_Row_Items :=
            Flex_Row_Child_Widths (Resolve_Handle (Grow_Row).all, 300.0);
      begin
         Ada.Text_IO.Put_Line
            ("  two 200px in 300px ->" & Pixel_Type'Image (Shrunk (1).Width)
             & Pixel_Type'Image (Shrunk (2).Width)
             & "; one growing 100px in 300px ->"
             & Pixel_Type'Image (Grown (1).Width));

         --  Equal bases shrink equally: 150 each, not any pair that
         --  happens to add up to the line.
         Test_Support.Assert
            (abs (Shrunk (1).Width - 150.0) < 0.001
               and then abs (Shrunk (2).Width - 150.0) < 0.001,
             "two equal declared widths shrink to half the line each");
         Test_Support.Assert
            (abs (Grown (1).Width - 300.0) < 0.001,
             "a lone growing child passes its declared width");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  auto lets a declared main size stand in for the content;
   --  content ignores it. Accepting both and treating them alike would
   --  make the difference silently unavailable.
   Ada.Text_IO.Put_Line ("=== flex-basis content ignores a declared size ===");
   declare
      Column : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Auto_Kid : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Content_Kid : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Inner_A : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Inner_C : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Declared_H : constant := 200.0;
      Content_H  : constant := 40.0;

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Inner_Style : constant Style_Rules :=
         (Height => Set (Size (Px (Content_H))), others => <>);
      Auto_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Height         => Set (Size (Px (Declared_H))),
          Flex_Basis     => Set (Auto_Basis),
          others         => <>);
      Content_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          Height         => Set (Size (Px (Declared_H))),
          Flex_Basis     => Set (Content_Basis),
          others         => <>);
   begin
      Set_Part_Styles
         (Column, [Main_Part => (Style => From (Column_Style).Build,
                                 Enabled => True), others => <>]);
      Set_Part_Styles
         (Auto_Kid, [Main_Part => (Style => From (Auto_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Content_Kid, [Main_Part => (Style => From (Content_Style).Build,
                                      Enabled => True), others => <>]);
      Set_Part_Styles
         (Inner_A, [Main_Part => (Style => From (Inner_Style).Build,
                                  Enabled => True), others => <>]);
      Set_Part_Styles
         (Inner_C, [Main_Part => (Style => From (Inner_Style).Build,
                                  Enabled => True), others => <>]);
      Add_Child (Auto_Kid, Inner_A);
      Add_Child (Content_Kid, Inner_C);

      declare
         Auto_Base : constant Pixel_Type :=
            Resolved_Flex_Base
              (Child          => Resolve_Handle (Auto_Kid).all,
               Direction      => Adi.CSS_Styles.Column,
               Assigned_Width => 100.0,
               Container_Main => 0.0);
         Content_Base : constant Pixel_Type :=
            Resolved_Flex_Base
              (Child          => Resolve_Handle (Content_Kid).all,
               Direction      => Adi.CSS_Styles.Column,
               Assigned_Width => 100.0,
               Container_Main => 0.0);
      begin
         Ada.Text_IO.Put_Line
            ("  auto base" & Pixel_Type'Image (Auto_Base)
             & " (declared" & Pixel_Type'Image (Declared_H) & ")"
             & ", content base" & Pixel_Type'Image (Content_Base)
             & " (content" & Pixel_Type'Image (Content_H) & ")");

         Test_Support.Assert
            (abs (Auto_Base - Declared_H) < 0.001,
             "an auto basis takes the declared height");
         Test_Support.Assert
            (abs (Content_Base - Content_H) < 0.001,
             "a content basis ignores the declared height");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  A wrapping row is as deep as its lines stacked up, not as deep as
   --  its deepest item. Measuring it as one line makes the container too
   --  short for everything below the first row of items.
   Ada.Text_IO.Put_Line ("=== a wrapping row measures all its lines ===");
   declare
      Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      A : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      B : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Tile_W : constant := 60.0;
      Tile_H : constant := 40.0;
      Line_Gap : constant := 8.0;
      Row_W  : constant := 130.0;   --  two tiles per line, not three

      Row_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          Flex_Wrap      => Set (Adi.CSS_Styles.Wrap),
          Gap            => Set (Gap (Px (Line_Gap))),
          others         => <>);
      Tile_Style : constant Style_Rules :=
         (Width  => Set (Size (Px (Tile_W))),
          Height => Set (Size (Px (Tile_H))),
          Flex_Shrink => Set (0.0),
          others => <>);
   begin
      Set_Part_Styles
         (Row, [Main_Part => (Style => From (Row_Style).Build,
                              Enabled => True), others => <>]);
      for T of Widget_Pair'[A, B, C] loop
         Set_Part_Styles
            (T, [Main_Part => (Style => From (Tile_Style).Build,
                               Enabled => True), others => <>]);
      end loop;
      Add_Child (Row, A);
      Add_Child (Row, B);
      Add_Child (Row, C);

      Ada.Text_IO.Put_Line
         ("  row measures" & Pixel_Type'Image
             (Measure_At_Width (Row, Row_W).Height)
          & " at width" & Pixel_Type'Image (Row_W)
          & " (two lines of" & Pixel_Type'Image (Tile_H)
          & " plus" & Pixel_Type'Image (Line_Gap) & ")");

      Test_Support.Assert
         (abs (Measure_At_Width (Row, Row_W).Height
                 - (2.0 * Tile_H + Line_Gap)) < 0.001,
          "a wrapping row measures its lines plus the gap between them");

      --  The minimum has to agree, or a parent that squeezes this row
      --  reserves one line and the rest of them spill out.
      Ada.Text_IO.Put_Line
         ("  content min h="
          & Pixel_Type'Image
              (Effective_Min_Size_At_Width (Row, Row_W).Height));
      Test_Support.Assert
         (abs (Effective_Min_Size_At_Width (Row, Row_W).Height
                 - (2.0 * Tile_H + Line_Gap)) < 0.001,
          "a wrapping row's minimum covers every line and the gaps");

      Set_Geometry
         (Row, (X => 0.0, Y => 0.0, Width => Row_W,
                Height => Measure_At_Width (Row, Row_W).Height));
      Layout_Tree (Row);

      declare
         GA : constant Rectangle := Get_Geometry (A);
         GC : constant Rectangle := Get_Geometry (C);
      begin
         Test_Support.Assert
            (GC.Y > GA.Y + 0.001,
             "the third tile is laid out on the second line");
         Test_Support.Assert
            (GC.Y + GC.Height <= Get_Geometry (Row).Height + 0.001,
             "the second line fits inside the measured row");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  The wrapping row inside a parent with nowhere near enough room:
   --  the row must keep every line, and out-of-flow siblings must not
   --  count toward the lines at all.
   Ada.Text_IO.Put_Line ("=== a squeezed wrapping row keeps its lines ===");
   declare
      Viewport : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      A : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      B : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Hidden : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Floating : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Tile_W : constant := 60.0;
      Tile_H : constant := 40.0;
      Row_W  : constant := 130.0;

      Column_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);
      Row_Style : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          Flex_Wrap      => Set (Adi.CSS_Styles.Wrap),
          others         => <>);
      Tile_Style : constant Style_Rules :=
         (Width  => Set (Size (Px (Tile_W))),
          Height => Set (Size (Px (Tile_H))),
          Flex_Shrink => Set (0.0),
          others => <>);
      --  Wide enough to change the line breaks if it were counted.
      Out_Of_Flow : constant Style_Rules :=
         (Width  => Set (Size (Px (Tile_W))),
          Height => Set (Size (Px (Tile_H))),
          others => <>);
   begin
      Set_Part_Styles
         (Viewport, [Main_Part => (Style => From (Column_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles
         (Row, [Main_Part => (Style => From (Row_Style).Build,
                              Enabled => True), others => <>]);
      for T of Widget_Pair'[A, B, C] loop
         Set_Part_Styles
            (T, [Main_Part => (Style => From (Tile_Style).Build,
                               Enabled => True), others => <>]);
      end loop;
      Set_Part_Styles
         (Hidden, [Main_Part => (Style => From (Out_Of_Flow).Build,
                                 Enabled => True), others => <>]);
      Set_Part_Styles
         (Floating,
          [Main_Part =>
             (Style => From (Merge (Out_Of_Flow,
                                    (Position => Set (Absolute),
                                     others => <>))).Build,
              Enabled => True), others => <>]);

      --  Between the first two tiles, so a regression in the filter
      --  changes where the lines break rather than only their count.
      Add_Child (Row, A);
      Add_Child (Row, Hidden);
      Set_Visible (Hidden, False);
      Add_Child (Row, Floating);
      Add_Child (Row, B);
      Add_Child (Row, C);
      Add_Child (Viewport, Row);

      Ada.Text_IO.Put_Line
         ("  row min h="
          & Pixel_Type'Image
              (Effective_Min_Size_At_Width (Row, Row_W).Height)
          & " (two lines of" & Pixel_Type'Image (Tile_H) & ")");

      Test_Support.Assert
         (abs (Effective_Min_Size_At_Width (Row, Row_W).Height
                 - 2.0 * Tile_H) < 0.001,
          "hidden and absolute children do not form lines");

      Set_Geometry
         (Viewport, (X => 0.0, Y => 0.0, Width => Row_W, Height => 20.0));
      Layout_Tree (Viewport);

      declare
         R : constant Rectangle := Get_Geometry (Row);
         GC : constant Rectangle := Get_Geometry (C);
      begin
         Ada.Text_IO.Put_Line
            ("  squeezed to 20: row h=" & Pixel_Type'Image (R.Height)
             & " last tile bottom="
             & Pixel_Type'Image (GC.Y + GC.Height));
         Test_Support.Assert
            (GC.Y + GC.Height <= R.Y + R.Height + 0.001,
             "the squeezed wrapping row still contains its last line");
      end;
   end;

   Ada.Text_IO.New_Line;

   --  Freezing one flexible track shrinks the pool for the rest, which
   --  can push another below its own floor, and so on. Three 1fr tracks
   --  in 300px with floors 150 / 90 / 0 must settle at 150 / 90 / 60:
   --  a single pass would hand each 100 and leave the second short.
   Ada.Text_IO.Put_Line ("=== fr freezing cascades ===");
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C1 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C2 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C3 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (3)),
          Grid_Column_Tracks =>
             (Count  => 3,
              Tracks =>
                 [1      => (Track_Fr, 1.0),
                  2      => (Track_Fr, 1.0),
                  3      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);

      function Floor_Of (W : Float) return Part_Style_Array is
         R : constant Style_Rules :=
            (Min_Width => Set (Size (Px (W))), others => <>);
      begin
         return [Main_Part => (Style => From (R).Build, Enabled => True),
                 others    => <>];
      end Floor_Of;
   begin
      Set_Part_Styles
         (Grid_Box, [Main_Part => (Style => From (Grid_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles (C1, Floor_Of (150.0));
      Set_Part_Styles (C2, Floor_Of (90.0));
      Set_Part_Styles (C3, Floor_Of (0.0));
      Add_Child (Grid_Box, C1);
      Add_Child (Grid_Box, C2);
      Add_Child (Grid_Box, C3);

      Set_Geometry
         (Grid_Box, (X => 0.0, Y => 0.0, Width => 300.0, Height => 50.0));
      Layout (Grid_Box);

      Ada.Text_IO.Put_Line
         ("  widths: " & Pixel_Type'Image (Get_Geometry (C1).Width)
          & Pixel_Type'Image (Get_Geometry (C2).Width)
          & Pixel_Type'Image (Get_Geometry (C3).Width));

      Test_Support.Assert
         (abs (Get_Geometry (C1).Width - 150.0) < 0.001,
          "first track freezes at its floor");
      Test_Support.Assert
         (abs (Get_Geometry (C2).Width - 90.0) < 0.001,
          "the second freezes once the first has taken its share");
      Test_Support.Assert
         (abs (Get_Geometry (C3).Width - 60.0) < 0.001,
          "the last takes what remains");
   end;

   Ada.Text_IO.New_Line;

   --  Flex factors summing below 1 leave the rest of the space unused,
   --  rather than the single track claiming all of it.
   Ada.Text_IO.Put_Line ("=== fractional fr factors ===");
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Only     : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;

      Grid_Style : constant Style_Rules :=
         (Display            => Set (Grid),
          Grid_Columns       => Set (Grid_Columns_Value (1)),
          Grid_Column_Tracks =>
             (Count  => 1,
              Tracks => [1 => (Track_Fr, 0.5), others => <>]),
          others             => <>);
   begin
      Set_Part_Styles
         (Grid_Box, [Main_Part => (Style => From (Grid_Style).Build,
                                   Enabled => True), others => <>]);
      Add_Child (Grid_Box, Only);

      Set_Geometry
         (Grid_Box, (X => 0.0, Y => 0.0, Width => 200.0, Height => 50.0));
      Layout (Grid_Box);

      Ada.Text_IO.Put_Line
         ("  0.5fr of 200px -> "
          & Pixel_Type'Image (Get_Geometry (Only).Width));

      Test_Support.Assert
         (abs (Get_Geometry (Only).Width - 100.0) < 0.001,
          "a lone 0.5fr track takes half the space, not all of it");
   end;

   Ada.Text_IO.New_Line;

   --  An icon beside wrapping text narrows the text column, and the
   --  content minimum has to subtract the same column the preferred
   --  path does. When only one icon dimension is definite the other
   --  follows the aspect ratio, so resolving the icon differently in
   --  the two paths made the minimum wrap at the wrong width and report
   --  too few lines — the text would then be clipped vertically.
   Ada.Text_IO.Put_Line ("=== icon column matches in both measurements ===");
   declare
      L : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("Some wrapping label text that needs several lines");

      --  Only the icon's height is definite; its width comes from the
      --  aspect ratio.
      Main_Rules : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Row),
          Width          => Set (Size (Px (160.0))),
          others         => <>);
      Icon_Rules : constant Style_Rules :=
         (Height => Set (Size (Px (40.0))), others => <>);
      Text_Rules : constant Style_Rules :=
         (Text_Wrap_Mode => Set (TWM_Wrap), others => <>);

      Parts : constant Part_Style_Array :=
         [Main_Part  => (Style => From (Main_Rules).Build, Enabled => True),
          Icon_Part  => (Style => From (Icon_Rules).Build, Enabled => True),
          Label_Part => (Style => From (Text_Rules).Build, Enabled => True),
          others     => <>];

      --  The label borrows the icon, so this test owns it.
      Icon : Adi.Image.Image_Access :=
         Adi.Image.Load_SVG_From_String
           ("<svg width='20' height='10' viewBox='0 0 20 10'>"
            & "<rect width='20' height='10' fill='red'/></svg>");
   begin
      Set_Part_Styles (L, Parts);
      Adi.Widget.Label.Set_Icon
        (Adi.Widget.Label.Try_As_Label (L), Icon);
      Set_Geometry (L, (X => 0.0, Y => 0.0, Width => 160.0, Height => 200.0));
      Layout (L);

      Ada.Text_IO.Put_Line
         ("  preferred h=" & Pixel_Type'Image (Get_Preferred_Size (L).Height)
          & "  content min h at 160="
          & Pixel_Type'Image
              (Effective_Min_Size_At_Width (L, 160.0).Height));

      --  Both paths lay the text out in the same column, so the minimum
      --  height cannot be shorter than the preferred one at that width.
      --  Asked explicitly: the widthless form has no column to wrap in.
      Test_Support.Assert
         (Effective_Min_Size_At_Width (L, 160.0).Height
            >= Get_Preferred_Size (L).Height - 0.001,
          "content minimum wraps in the same column as preferred sizing");

      --  Detach before freeing: the label outlives this block.
      Adi.Widget.Label.Set_Icon
        (Adi.Widget.Label.Try_As_Label (L), null);
      Adi.Image.Free (Icon);
   end;

   Ada.Text_IO.New_Line;

   --  CSS caps an item's automatic minimum at the size it declares (the
   --  "specified size suggestion"), and a container aggregating its
   --  children has to apply the same cap. Without it a nowrap label
   --  inside a 100px box makes the box demand the full text width, and
   --  everything above it is forced open to fit text that was meant to
   --  overflow.
   Ada.Text_IO.Put_Line ("=== a definite size caps the content minimum ===");
   declare
      Long : constant String :=
         "LONG TEXT: the quick brown fox jumps over the lazy dog";

      Nowrap : constant Style_Rules :=
         (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>);

      --  Builds: container(display:flex) > label(Long, nowrap) with the
      --  label styled by Label_Rules.
      type Page_Id is (Only_Page);
      package Probe_Stack is new Adi.Widget.Stack (Page_Id);

      function Make_Case
        (Container_Rules : Style_Rules;
         Label_Rules     : Style_Rules;
         Use_Stack       : Boolean := False) return Widget_Handle
      is
         Box_H : constant Widget_Handle :=
            (if Use_Stack then Probe_Stack.To_Widget_Handle
                                 (Probe_Stack.Create_Handle)
             else +Adi.Widget.Box.Create_Handle);
         L     : constant Widget_Handle :=
            +Adi.Widget.Label.Create_Handle (Long);
      begin
         Set_Part_Style (Box_H, Main_Part, From (Container_Rules).Build);
         Set_Part_Style (L, Main_Part, From (Label_Rules).Build);
         Set_Part_Style (L, Label_Part, From (Nowrap).Build);
         Add_Child (Box_H, L);
         return Box_H;
      end Make_Case;

      Flex_Col : constant Style_Rules :=
         (Display        => Set (Flex),
          Flex_Direction => Set (Adi.CSS_Styles.Column),
          others         => <>);

      --  How wide the text really is, measured with nothing constraining
      --  it: the number the cap has to suppress.
      Uncapped : constant Widget_Handle :=
         Make_Case (Flex_Col, (others => <>));
      Text_Min : constant Pixel_Type := Get_Content_Min_Size (Uncapped).Width;

      Capped : constant Widget_Handle :=
         Make_Case (Flex_Col, (Width => Set (Size (Px (100.0))), others => <>));
      Floored : constant Widget_Handle :=
         Make_Case (Flex_Col,
                    (Width     => Set (Size (Px (100.0))),
                     Min_Width => Set (Size (Px (150.0))),
                     others    => <>));
      Percent : constant Widget_Handle :=
         Make_Case (Flex_Col, (Width => Set (Size (Pct (50.0))), others => <>));
      Stacked : constant Widget_Handle :=
         Make_Case (Flex_Col,
                    (Width => Set (Size (Px (100.0))), others => <>),
                    Use_Stack => True);
   begin
      Ada.Text_IO.Put_Line
         ("  text min w=" & Pixel_Type'Image (Text_Min)
          & "  capped=" & Pixel_Type'Image (Get_Content_Min_Size (Capped).Width)
          & "  floored="
          & Pixel_Type'Image (Get_Content_Min_Size (Floored).Width)
          & "  percent="
          & Pixel_Type'Image (Get_Content_Min_Size (Percent).Width)
          & "  stack="
          & Pixel_Type'Image (Get_Content_Min_Size (Stacked).Width));

      --  Guard the premise: the text really is wider than the caps below.
      Test_Support.Assert (Text_Min > 200.0,
          "the sample text is wider than the sizes capping it");

      Test_Support.Assert
         (abs (Get_Content_Min_Size (Capped).Width - 100.0) < 0.001,
          "a definite width caps what the container aggregates");
      Test_Support.Assert
         (abs (Get_Content_Min_Size (Floored).Width - 150.0) < 0.001,
          "an explicit min-width still floors the capped result");
      Test_Support.Assert
         (abs (Get_Content_Min_Size (Percent).Width - Text_Min) < 0.001,
          "a percentage width is not definite here, so nothing is capped");
      Test_Support.Assert
         (abs (Get_Content_Min_Size (Stacked).Width - 100.0) < 0.001,
          "a stack caps its pages the same way a box caps its children");
   end;

   Ada.Text_IO.New_Line;

   --  A box that hides or scrolls an axis shows its content a piece at a
   --  time, so it needs no room for all of it: the automatic minimum on
   --  that axis is zero. An explicit min-width/min-height is a demand
   --  rather than a contribution, and still applies.
   --  CSS Grid 2 automatic minimum size; CSS Overflow 3 classes hidden
   --  as a scrollable overflow value.
   Ada.Text_IO.Put_Line
      ("=== overflow suppresses the automatic minimum, per axis ===");
   Ada.Text_IO.New_Line;
   declare
      Sample : constant String :=
         "Supercalifragilistic wording that will not fit";

      function Label_With (R : Style_Rules) return Widget_Handle is
         L : constant Widget_Handle :=
            +Adi.Widget.Label.Create_Handle (Sample);
         Nowrap : constant Style_Rules :=
            (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>);
      begin
         Set_Part_Styles
            (L, [Main_Part =>
                    (Style => From (Merge (Nowrap, R)).Build, Enabled => True),
                 others => <>]);
         return L;
      end Label_With;

      Visible : constant Widget_Handle := Label_With ((others => <>));
      Hidden_X : constant Widget_Handle :=
         Label_With ((Overflow_X => Set_Overflow_X (Overflow_Hidden),
                      others     => <>));
      Hidden_X_Floored : constant Widget_Handle :=
         Label_With ((Overflow_X => Set_Overflow_X (Overflow_Hidden),
                      Min_Width  => Set (Size (Px (40.0))),
                      others     => <>));
      Scrolling_X : constant Widget_Handle :=
         Label_With ((Overflow_X => Set_Overflow_X (Overflow_Auto),
                      others     => <>));
   begin
      Ada.Text_IO.Put_Line
         ("  visible w=" & Pixel_Type'Image (Effective_Min_Size (Visible).Width)
          & "  hidden w=" & Pixel_Type'Image (Effective_Min_Size (Hidden_X).Width)
          & "  hidden+min w="
          & Pixel_Type'Image (Effective_Min_Size (Hidden_X_Floored).Width));

      Test_Support.Assert
         (Effective_Min_Size (Visible).Width > 0.0,
          "a visible nowrap label contributes its min-content width");
      Test_Support.Assert
         (Effective_Min_Size (Hidden_X).Width = 0.0,
          "overflow-x hidden drops that contribution to zero");
      Test_Support.Assert
         (Effective_Min_Size (Scrolling_X).Width = 0.0,
          "overflow-x auto drops it too: hidden and scroll are both "
          & "scrollable overflow");
      Test_Support.Assert
         (abs (Effective_Min_Size (Hidden_X_Floored).Width - 40.0) < 0.001,
          "an explicit min-width still wins over hidden overflow");
      Test_Support.Assert
         (abs (Effective_Min_Size (Hidden_X).Height
               - Effective_Min_Size (Visible).Height) < 0.001,
          "hiding X leaves the Y contribution alone");
   end;

   Ada.Text_IO.New_Line;

   --  The reference case in grid_example: three 1fr tracks in 300px
   --  where the third holds text too wide for its share. With that item
   --  hiding its overflow the track floors are 150/90/0, so the grid
   --  stays inside its 300px instead of being pushed wider.
   Ada.Text_IO.Put_Line
      ("=== a hidden-overflow item does not inflate its fr track ===");
   Ada.Text_IO.New_Line;
   declare
      Grid_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C1 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C2 : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      C3 : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("wording far too wide for one third of this grid");

      Grid_Style : constant Style_Rules :=
         (Display            => Set (Adi.CSS_Styles.Grid),
          Grid_Columns       => Set (Grid_Columns_Value (3)),
          Grid_Column_Tracks =>
             (Count  => 3,
              Tracks =>
                 [1      => (Track_Fr, 1.0),
                  2      => (Track_Fr, 1.0),
                  3      => (Track_Fr, 1.0),
                  others => <>]),
          others             => <>);

      function Floor_Of (W : Float) return Part_Style_Array is
         R : constant Style_Rules :=
            (Min_Width => Set (Size (Px (W))), others => <>);
      begin
         return [Main_Part => (Style => From (R).Build, Enabled => True),
                 others    => <>];
      end Floor_Of;

      Clipped : constant Style_Rules :=
         (Overflow_X     => Set_Overflow_X (Overflow_Hidden),
          Text_Wrap_Mode => Set (TWM_Nowrap),
          others         => <>);
   begin
      Set_Part_Styles
         (Grid_Box, [Main_Part => (Style => From (Grid_Style).Build,
                                   Enabled => True), others => <>]);
      Set_Part_Styles (C1, Floor_Of (150.0));
      Set_Part_Styles (C2, Floor_Of (90.0));
      Set_Part_Styles
         (C3, [Main_Part => (Style => From (Clipped).Build, Enabled => True),
               others    => <>]);
      Add_Child (Grid_Box, C1);
      Add_Child (Grid_Box, C2);
      Add_Child (Grid_Box, C3);

      Set_Geometry
         (Grid_Box, (X => 0.0, Y => 0.0, Width => 300.0, Height => 50.0));
      Layout (Grid_Box);

      Ada.Text_IO.Put_Line
         ("  widths: " & Pixel_Type'Image (Get_Geometry (C1).Width)
          & Pixel_Type'Image (Get_Geometry (C2).Width)
          & Pixel_Type'Image (Get_Geometry (C3).Width));

      Test_Support.Assert
         (abs (Get_Geometry (C1).Width - 150.0) < 0.001,
          "the 150px floor still freezes its track");
      Test_Support.Assert
         (abs (Get_Geometry (C2).Width - 90.0) < 0.001,
          "the 90px floor still freezes its track");
      Test_Support.Assert
         (abs (Get_Geometry (C3).Width - 60.0) < 0.001,
          "the clipped item takes the remainder rather than its text width");
      Test_Support.Assert
         (Get_Geometry (C1).Width + Get_Geometry (C2).Width
            + Get_Geometry (C3).Width <= 300.001,
          "so the grid stays inside the width it was given");
   end;

   Ada.Text_IO.New_Line;

   --  An explicit minimum replaces the automatic one rather than joining
   --  it, so `min-width: 0` really does let an item shrink past its own
   --  content. Combining the two with max would make the zero a no-op,
   --  and zero is the escape hatch CSS gives for exactly this.
   Ada.Text_IO.Put_Line
      ("=== an explicit minimum replaces the automatic one ===");
   Ada.Text_IO.New_Line;
   declare
      Sample : constant String := "wording far wider than the room given";

      function Label_With (R : Style_Rules) return Widget_Handle is
         L : constant Widget_Handle :=
            +Adi.Widget.Label.Create_Handle (Sample);
         Nowrap : constant Style_Rules :=
            (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>);
      begin
         Set_Part_Styles
            (L, [Main_Part =>
                    (Style => From (Merge (Nowrap, R)).Build, Enabled => True),
                 others => <>]);
         return L;
      end Label_With;

      Plain : constant Widget_Handle := Label_With ((others => <>));
      Zero  : constant Widget_Handle :=
         Label_With ((Min_Width => Set (Size (Px (0.0))), others => <>));
      Forty : constant Widget_Handle :=
         Label_With ((Min_Width => Set (Size (Px (40.0))), others => <>));
   begin
      Ada.Text_IO.Put_Line
         ("  auto=" & Pixel_Type'Image (Effective_Min_Size (Plain).Width)
          & "  zero=" & Pixel_Type'Image (Effective_Min_Size (Zero).Width)
          & "  forty=" & Pixel_Type'Image (Effective_Min_Size (Forty).Width));

      Test_Support.Assert
         (Effective_Min_Size (Plain).Width > 100.0,
          "with no explicit minimum the content's width still applies");
      Test_Support.Assert
         (Effective_Min_Size (Zero).Width = 0.0,
          "min-width: 0 drops the automatic minimum to nothing");
      Test_Support.Assert
         (abs (Effective_Min_Size (Forty).Width - 40.0) < 0.001,
          "a smaller explicit minimum replaces the automatic one, "
          & "rather than losing to it");
   end;

   Ada.Text_IO.New_Line;

   --  The same rule down the flex path: a row item that declares
   --  min-width: 0 shrinks to its share instead of holding the row open
   --  at its text width.
   Ada.Text_IO.Put_Line
      ("=== min-width: 0 lets a flex item shrink past its text ===");
   Ada.Text_IO.New_Line;
   declare
      Row_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Kid     : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("wording far wider than the row it sits in");

      Row_Style : constant Style_Rules :=
         (Display        => Set (Adi.CSS_Styles.Flex),
          Flex_Direction => Set (Row),
          others         => <>);
      Kid_Style : constant Style_Rules :=
         (Min_Width      => Set (Size (Px (0.0))),
          Text_Wrap_Mode => Set (TWM_Nowrap),
          others         => <>);
   begin
      Set_Part_Styles
         (Row_Box, [Main_Part => (Style => From (Row_Style).Build,
                                  Enabled => True), others => <>]);
      Set_Part_Styles
         (Kid, [Main_Part => (Style => From (Kid_Style).Build,
                              Enabled => True), others => <>]);
      Add_Child (Row_Box, Kid);

      Set_Geometry
         (Row_Box, (X => 0.0, Y => 0.0, Width => 100.0, Height => 40.0));
      Layout (Row_Box);

      Ada.Text_IO.Put_Line
         ("  row=100  child w=" & Pixel_Type'Image (Get_Geometry (Kid).Width));

      Test_Support.Assert
         (Get_Geometry (Kid).Width <= 100.001,
          "the item stays inside the row it was given");
   end;

   Ada.Text_IO.New_Line;

   --  `flex-basis: 0` has to survive the trip from CSS through to the
   --  layout. Two items with the same grow factor and very different
   --  preferred widths split the row evenly only if the declared zero
   --  arrives as a basis rather than as "unset" — which a test that sets
   --  the record field by hand would never catch.
   Ada.Text_IO.Put_Line
      ("=== flex-basis: 0 reaches the layout from CSS ===");
   Ada.Text_IO.New_Line;
   declare
      Basis_Row : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Narrow    : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle ("short");
      Wide      : constant Widget_Handle :=
         +Adi.Widget.Label.Create_Handle
             ("a much longer label that prefers far more room");

      Row_Style : constant Style_Rules :=
         (Display        => Set (Adi.CSS_Styles.Flex),
          Flex_Direction => Set (Row),
          others         => <>);

      --  Equal grow off a zero basis, and free to shrink past their text.
      Kid_Style : constant Style_Rules :=
         (Flex_Basis     => Set (Basis (Px (0.0))),
          Flex_Grow      => Set (1.0),
          Min_Width      => Set (Size (Px (0.0))),
          Text_Wrap_Mode => Set (TWM_Nowrap),
          others         => <>);
   begin
      Set_Part_Styles
         (Basis_Row, [Main_Part => (Style => From (Row_Style).Build,
                                    Enabled => True), others => <>]);
      Set_Part_Styles
         (Narrow, [Main_Part => (Style => From (Kid_Style).Build,
                                 Enabled => True), others => <>]);
      Set_Part_Styles
         (Wide, [Main_Part => (Style => From (Kid_Style).Build,
                               Enabled => True), others => <>]);
      Add_Child (Basis_Row, Narrow);
      Add_Child (Basis_Row, Wide);

      Set_Geometry
         (Basis_Row, (X => 0.0, Y => 0.0, Width => 300.0, Height => 40.0));
      Layout (Basis_Row);

      Ada.Text_IO.Put_Line
         ("  narrow=" & Pixel_Type'Image (Get_Geometry (Narrow).Width)
          & "  wide=" & Pixel_Type'Image (Get_Geometry (Wide).Width));

      Test_Support.Assert
         (abs (Get_Geometry (Narrow).Width - 150.0) < 0.001,
          "a declared zero basis leaves grow alone to decide, narrow half");
      Test_Support.Assert
         (abs (Get_Geometry (Wide).Width - 150.0) < 0.001,
          "and the wide item gets the same half, not more");
   end;

   Ada.Text_IO.New_Line;

   --  A Track_Px track carries an unresolved CSS number, not a pixel count,
   --  so it takes the px -> dip mapping like every other length. At a 2.0
   --  scale a 120px track is 240 device pixels on all three paths that read
   --  the track list: the child's laid-out width, the grid's preferred
   --  width, and the grid's content minimum.
   Ada.Text_IO.Put_Line
      ("=== a px grid track takes the px -> dip mapping ===");
   Ada.Text_IO.New_Line;
   declare
      Saved_Maps : constant Boolean :=
         Adi.Layout_Util.Get_Px_Maps_To_Dip;
      Saved_DIP  : constant Pixel_Type :=
         Adi.Layout_Util.Get_Active_DIP_Scale;
      Saved_UI   : constant Pixel_Type :=
         Adi.Layout_Util.Get_Active_UI_Scale;

      Child : Widget_Handle;

      --  One 120px track, in a grid far wider than it: a px track takes
      --  its own size and leaves the rest, so the child is the track.
      function Track_Grid return Widget_Handle is
         G : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
         R : constant Style_Rules :=
            (Display            => Set (Adi.CSS_Styles.Grid),
             Grid_Columns       => Set (Grid_Columns_Value (1)),
             Grid_Column_Tracks =>
                (Count  => 1,
                 Tracks => [1 => (Track_Px, 120.0), others => <>]),
             others             => <>);
      begin
         Child := +Adi.Widget.Box.Create_Handle;
         Set_Part_Styles
            (G, [Main_Part => (Style => From (R).Build, Enabled => True),
                 others    => <>]);
         Add_Child (G, Child);
         Set_Geometry
            (G, (X => 0.0, Y => 0.0, Width => 600.0, Height => 80.0));
         Layout (G);
         return G;
      end Track_Grid;
   begin
      Adi.Layout_Util.Set_Active_DIP_Scale (2.0);
      Adi.Layout_Util.Set_Active_UI_Scale (1.0);
      Adi.Layout_Util.Set_Px_Maps_To_Dip (True);

      declare
         G : constant Widget_Handle := Track_Grid;
      begin
         Ada.Text_IO.Put_Line
            ("  mapped: child w=" & Pixel_Type'Image (Get_Geometry (Child).Width)
             & "  preferred w=" & Pixel_Type'Image (Get_Preferred_Size (G).Width)
             & "  content min w="
             & Pixel_Type'Image (Get_Content_Min_Size (G).Width));

         Test_Support.Assert
            (abs (Get_Geometry (Child).Width - 240.0) < 0.001,
             "a 120px track lays its child out at 240 device pixels");
         Test_Support.Assert
            (abs (Get_Preferred_Size (G).Width - 240.0) < 0.001,
             "the grid's preferred width counts the mapped track");
         Test_Support.Assert
            (abs (Get_Content_Min_Size (G).Width - 240.0) < 0.001,
             "the grid's content minimum counts the mapped track");
      end;

      --  Mapping off leaves the number alone even at a 2.0 scale, which
      --  is what catches a conversion applied twice.
      Adi.Layout_Util.Set_Px_Maps_To_Dip (False);
      declare
         G : constant Widget_Handle := Track_Grid;
      begin
         Ada.Text_IO.Put_Line
            ("  unmapped: child w="
             & Pixel_Type'Image (Get_Geometry (Child).Width));
         Test_Support.Assert
            (abs (Get_Geometry (Child).Width - 120.0) < 0.001,
             "with the mapping off the track stays 120 pixels");
         pragma Unreferenced (G);
      end;

      Adi.Layout_Util.Set_Px_Maps_To_Dip (Saved_Maps);
      Adi.Layout_Util.Set_Active_DIP_Scale (Saved_DIP);
      Adi.Layout_Util.Set_Active_UI_Scale (Saved_UI);
   end;

   --  pix is an Adi unit meaning one renderer pixel, whatever the scales
   --  are doing. px follows the px -> dip mapping when it is on, dp
   --  always scales, and pix never does -- which is what makes it usable
   --  for a hairline that must stay one pixel.
   Ada.Text_IO.Put_Line
      ("=== pix is a renderer pixel; px and dp scale ===");
   Ada.Text_IO.New_Line;
   declare
      Saved_Maps : constant Boolean := Adi.Layout_Util.Get_Px_Maps_To_Dip;
      Saved_DIP  : constant Pixel_Type := Adi.Layout_Util.Get_Active_DIP_Scale;
      Saved_UI   : constant Pixel_Type := Adi.Layout_Util.Get_Active_UI_Scale;
      Saved_Text : constant Pixel_Type := Adi.Layout_Util.Get_Active_Text_Scale;

      function Track_Grid (Spec : Grid_Track_Spec) return Widget_Handle is
         G : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
         R : constant Style_Rules :=
            (Display            => Set (Adi.CSS_Styles.Grid),
             Grid_Columns       => Set (Grid_Columns_Value (1)),
             Grid_Column_Tracks =>
                (Count  => 1,
                 Tracks => [1 => Spec, others => <>]),
             others             => <>);
      begin
         Set_Part_Styles
            (G, [Main_Part => (Style => From (R).Build, Enabled => True),
                 others    => <>]);
         Add_Child (G, +Adi.Widget.Box.Create_Handle);
         Set_Geometry
            (G, (X => 0.0, Y => 0.0, Width => 600.0, Height => 80.0));
         Layout (G);
         return G;
      end Track_Grid;
   begin
      --  2.0 x 1.25 = 2.5, so a scaled 10 lands on 25.
      Adi.Layout_Util.Set_Active_DIP_Scale (2.0);
      Adi.Layout_Util.Set_Active_UI_Scale (1.25);
      Adi.Layout_Util.Set_Active_Text_Scale (1.0);
      Adi.Layout_Util.Set_Px_Maps_To_Dip (True);

      Ada.Text_IO.Put_Line
         ("  10px=" & Pixel_Type'Image (Adi.Layout_Util.Length_To_Px (Px (10.0)))
          & "  10dp=" & Pixel_Type'Image (Adi.Layout_Util.Length_To_Px (Dip (10.0)))
          & "  10pix=" & Pixel_Type'Image (Adi.Layout_Util.Length_To_Px (Pix (10.0))));

      Test_Support.Assert
         (abs (Adi.Layout_Util.Length_To_Px (Px (10.0)) - 25.0) < 0.001,
          "10px takes the mapping and both scales");
      Test_Support.Assert
         (abs (Adi.Layout_Util.Length_To_Px (Dip (10.0)) - 25.0) < 0.001,
          "10dp scales the same way, mapping or not");
      Test_Support.Assert
         (abs (Adi.Layout_Util.Length_To_Px (Pix (10.0)) - 10.0) < 0.001,
          "10pix is ten renderer pixels");

      --  Font sizes still take the accessibility text scale.
      Adi.Layout_Util.Set_Active_Text_Scale (2.0);
      Test_Support.Assert
         (abs (Adi.Layout_Util.Font_Length_To_Px (Pix (10.0)) - 20.0) < 0.001,
          "a font size in pix still takes the text scale");
      Adi.Layout_Util.Set_Active_Text_Scale (1.0);

      --  Turning the mapping off moves px but leaves pix and dp alone.
      Adi.Layout_Util.Set_Px_Maps_To_Dip (False);
      Test_Support.Assert
         (abs (Adi.Layout_Util.Length_To_Px (Px (10.0)) - 10.0) < 0.001
            and then abs (Adi.Layout_Util.Length_To_Px (Pix (10.0)) - 10.0)
                       < 0.001
            and then abs (Adi.Layout_Util.Length_To_Px (Dip (10.0)) - 25.0)
                       < 0.001,
          "with the mapping off px joins pix, while dp keeps scaling");

      --  A track in each unit, measured and laid out.
      Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
      declare
         Scaled : constant Widget_Handle := Track_Grid ((Track_Px, 40.0));
         Exact  : constant Widget_Handle := Track_Grid ((Track_Pix, 40.0));
      begin
         Ada.Text_IO.Put_Line
            ("  40px track=" & Pixel_Type'Image (Get_Geometry (Get_Child_Handle (Scaled, 1)).Width)
             & "  40pix track=" & Pixel_Type'Image (Get_Geometry (Get_Child_Handle (Exact, 1)).Width));

         Test_Support.Assert
            (abs (Get_Geometry (Get_Child_Handle (Scaled, 1)).Width - 100.0)
               < 0.001,
             "a 40px track lays out at 100 renderer pixels");
         Test_Support.Assert
            (abs (Get_Geometry (Get_Child_Handle (Exact, 1)).Width - 40.0)
               < 0.001,
             "a 40pix track stays at 40");
         Test_Support.Assert
            (abs (Get_Content_Min_Size (Exact).Width - 40.0) < 0.001
               and then abs (Get_Preferred_Size (Exact).Width - 40.0) < 0.001,
             "and aggregates at 40 through both width queries");
      end;

      Adi.Layout_Util.Set_Px_Maps_To_Dip (Saved_Maps);
      Adi.Layout_Util.Set_Active_DIP_Scale (Saved_DIP);
      Adi.Layout_Util.Set_Active_UI_Scale (Saved_UI);
      Adi.Layout_Util.Set_Active_Text_Scale (Saved_Text);
   end;

   Ada.Text_IO.New_Line;
   Test_Support.Finish;
end Min_Size_Test;
