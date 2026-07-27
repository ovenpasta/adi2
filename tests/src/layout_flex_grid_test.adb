pragma Ada_2022;

with Adi.Core;         use Adi.Core;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Layout_Util;  use Adi.Layout_Util;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget.Box;   use type Adi.Widget.Box.Box_Handle;
with Adi.Widget_Styles; use Adi.Widget_Styles;

with Test_Support;

procedure Layout_Flex_Grid_Test is
   Eps : constant Pixel_Type := 0.001;

   procedure Assert_True (Cond : Boolean; Msg : String)
     renames Test_Support.Assert;

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Msg : String) is
   begin
      Assert_True
        (abs (Actual - Expected) <= Eps,
         Msg & " actual=" & Actual'Image & " expected=" & Expected'Image);
   end Assert_Close;

   procedure Test_Flex_Grow_Resize is
      Ctx : Flex_Layout_Context;
      Kids : Flex_Child_Info_Array (1 .. 3);
      Rects : Rectangle_Array (1 .. 3);
   begin
      Ctx := (
         Container       => (0.0, 0.0, 300.0, 60.0),
         Direction       => Row,
         Wrap            => No_Wrap,
         Justify_Content => Flex_Start,
         Align_Items     => Stretch,
         Align_Content   => Stretch,
         Row_Gap         => 0.0,
         Column_Gap      => 0.0
      );

      Kids (1) := (Flex_Grow => 1.0, Flex_Shrink => 1.0, Flex_Basis => 0.0,
                   Min_Main => 0.0, Max_Main => Pixel_Type'Last,
                   Min_Cross => 0.0, Max_Cross => Pixel_Type'Last,
                   Content_Main => 0.0, Content_Cross => 20.0, others => <>);
      Kids (2) := (Flex_Grow => 2.0, Flex_Shrink => 1.0, Flex_Basis => 0.0,
                   Min_Main => 0.0, Max_Main => Pixel_Type'Last,
                   Min_Cross => 0.0, Max_Cross => Pixel_Type'Last,
                   Content_Main => 0.0, Content_Cross => 20.0, others => <>);
      Kids (3) := (Flex_Grow => 1.0, Flex_Shrink => 1.0, Flex_Basis => 0.0,
                   Min_Main => 0.0, Max_Main => Pixel_Type'Last,
                   Min_Cross => 0.0, Max_Cross => Pixel_Type'Last,
                   Content_Main => 0.0, Content_Cross => 20.0, others => <>);

      Compute_Flex_Layout (Ctx, Kids);
      Rects := Flex_To_Rectangles (Ctx, Kids);
      Assert_Close (Rects (1).Width, 75.0, "flex grow 1/2/1 @300 first");
      Assert_Close (Rects (2).Width, 150.0, "flex grow 1/2/1 @300 second");
      Assert_Close (Rects (3).Width, 75.0, "flex grow 1/2/1 @300 third");

      Ctx.Container.Width := 200.0;
      Compute_Flex_Layout (Ctx, Kids);
      Rects := Flex_To_Rectangles (Ctx, Kids);
      Assert_Close (Rects (1).Width, 50.0, "flex grow 1/2/1 @200 first");
      Assert_Close (Rects (2).Width, 100.0, "flex grow 1/2/1 @200 second");
      Assert_Close (Rects (3).Width, 50.0, "flex grow 1/2/1 @200 third");
   end Test_Flex_Grow_Resize;

   procedure Test_Flex_Shrink_Min is
      Ctx : Flex_Layout_Context := (
         Container       => (0.0, 0.0, 180.0, 40.0),
         Direction       => Row,
         Wrap            => No_Wrap,
         Justify_Content => Flex_Start,
         Align_Items     => Stretch,
         Align_Content   => Stretch,
         Row_Gap         => 0.0,
         Column_Gap      => 0.0
      );
      Kids : Flex_Child_Info_Array (1 .. 2);
      Rects : Rectangle_Array (1 .. 2);
   begin
      Kids (1) := (Flex_Grow => 0.0, Flex_Shrink => 1.0, Flex_Basis => 120.0,
                   Min_Main => 100.0, Max_Main => Pixel_Type'Last,
                   Min_Cross => 0.0, Max_Cross => Pixel_Type'Last,
                   Content_Main => 120.0, Content_Cross => 20.0, others => <>);
      Kids (2) := (Flex_Grow => 0.0, Flex_Shrink => 1.0, Flex_Basis => 120.0,
                   Min_Main => 60.0, Max_Main => Pixel_Type'Last,
                   Min_Cross => 0.0, Max_Cross => Pixel_Type'Last,
                   Content_Main => 120.0, Content_Cross => 20.0, others => <>);

      Compute_Flex_Layout (Ctx, Kids);
      Rects := Flex_To_Rectangles (Ctx, Kids);
      Assert_True (Rects (1).Width >= 100.0 - Eps, "flex shrink keeps first min");
      Assert_True (Rects (2).Width >= 60.0 - Eps, "flex shrink keeps second min");
      Assert_True (Rects (1).Width + Rects (2).Width >= 180.0 - Eps,
                   "flex overflow instead of overlap when mins exceed container");
      Assert_True (Rects (2).X >= Rects (1).X + Rects (1).Width - Eps,
                   "flex items remain non-overlapping in order");
   end Test_Flex_Shrink_Min;

   procedure Test_Flex_Margins is
      Ctx : Flex_Layout_Context := (
         Container       => (0.0, 0.0, 200.0, 80.0),
         Direction       => Row,
         Wrap            => No_Wrap,
         Justify_Content => Flex_Start,
         Align_Items     => Stretch,
         Align_Content   => Stretch,
         Row_Gap         => 10.0,
         Column_Gap      => 0.0
      );
      Kids : Flex_Child_Info_Array (1 .. 2);
      Rects : Rectangle_Array (1 .. 2);
   begin
      Kids (1) := (
         Flex_Grow => 0.0,
         Flex_Shrink => 0.0,
         Flex_Basis => 50.0,
         Min_Main => 0.0,
         Max_Main => Pixel_Type'Last,
         Min_Cross => 0.0,
         Max_Cross => Pixel_Type'Last,
         Content_Main => 50.0,
         Content_Cross => 12.0,
         Margin => (Top => 5.0, Right => 20.0, Bottom => 7.0, Left => 10.0),
         others => <>);

      Kids (2) := (
         Flex_Grow => 0.0,
         Flex_Shrink => 0.0,
         Flex_Basis => 50.0,
         Min_Main => 0.0,
         Max_Main => Pixel_Type'Last,
         Min_Cross => 0.0,
         Max_Cross => Pixel_Type'Last,
         Content_Main => 50.0,
         Content_Cross => 12.0,
         Margin => (Top => 2.0, Right => 6.0, Bottom => 3.0, Left => 4.0),
         others => <>);

      Compute_Flex_Layout (Ctx, Kids);
      Rects := Flex_To_Rectangles (Ctx, Kids);

      Assert_Close (Rects (1).X, 10.0, "flex margins row first x");
      Assert_Close (Rects (1).Width, 50.0, "flex margins row first width");
      Assert_Close (Rects (1).Y, 5.0, "flex margins row first y");
      Assert_Close (Rects (1).Height, 68.0, "flex margins row first stretched height");

      Assert_Close (Rects (2).X, 94.0, "flex margins row second x includes first right+gap+own left");
      Assert_Close (Rects (2).Width, 50.0, "flex margins row second width");
      Assert_Close (Rects (2).Y, 2.0, "flex margins row second y");
      Assert_Close (Rects (2).Height, 75.0, "flex margins row second stretched height");
   end Test_Flex_Margins;

   procedure Test_Grid_Auto_And_Span is
      Ctx : Grid_Layout_Context := (
         Container => (0.0, 0.0, 300.0, 150.0),
         Columns => 3,
         Explicit_Rows => 0,
         Row_Gap => 0.0,
         Column_Gap => 0.0,
         Use_Preferred_Floor => False,
         others => <>
      );
      Kids : Grid_Child_Info_Array (1 .. 4);
      Rects : Rectangle_Array (1 .. 4);
   begin
      Kids (1) := (Active => True, Grid_Column => 0, Grid_Row => 0,
                   Grid_Column_Span => 1, Grid_Row_Span => 1, others => <>);
      Kids (2) := (Active => True, Grid_Column => 0, Grid_Row => 0,
                   Grid_Column_Span => 2, Grid_Row_Span => 1, others => <>);
      Kids (3) := (Active => True, Grid_Column => 0, Grid_Row => 0,
                   Grid_Column_Span => 1, Grid_Row_Span => 1, others => <>);
      Kids (4) := (Active => True, Grid_Column => 0, Grid_Row => 0,
                   Grid_Column_Span => 1, Grid_Row_Span => 2, others => <>);

      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);

      Assert_Close (Rects (1).X, 0.0, "grid auto first col");
      Assert_Close (Rects (1).Y, 0.0, "grid auto first row");
      Assert_Close (Rects (1).Width, 100.0, "grid cell width");
      Assert_Close (Rects (1).Height, 50.0, "grid cell height");

      Assert_Close (Rects (2).X, 100.0, "grid explicit col start");
      Assert_Close (Rects (2).Width, 200.0, "grid col span width");

      Assert_Close (Rects (4).Height, 100.0, "grid row span height");
   end Test_Grid_Auto_And_Span;

   procedure Test_Grid_Resize_And_Overflow_Policy is
      Kids : Grid_Child_Info_Array (1 .. 2) := (
         1 => (Active => True, Grid_Column => 1, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Min_Width => 0.0, Min_Height => 0.0,
               Pref_Width => 140.0, Pref_Height => 40.0, others => <>),
         2 => (Active => True, Grid_Column => 2, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Min_Width => 0.0, Min_Height => 0.0,
               Pref_Width => 60.0, Pref_Height => 40.0, others => <>)
      );
      Ctx : Grid_Layout_Context := (
         Container => (0.0, 0.0, 240.0, 80.0),
         Columns => 2,
         Explicit_Rows => 1,
         Row_Gap => 0.0,
         Column_Gap => 0.0,
         Use_Preferred_Floor => False,
         others => <>
      );
      Rects : Rectangle_Array (1 .. 2);
   begin
      --  Shrink: no preferred floor (overflow hidden-style policy).
      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);
      Assert_Close (Rects (1).Width, 120.0, "grid shrink width hidden policy item1");
      Assert_Close (Rects (2).Width, 120.0, "grid shrink width hidden policy item2");

      --  Enable preferred floor (overflow visible policy): item1 keeps 140.
      Ctx.Use_Preferred_Floor := True;
      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);
      Assert_True (Rects (1).Width >= 140.0 - Eps,
                   "grid visible policy keeps preferred width");
      Assert_True (Rects (2).X >= Rects (1).X + Rects (1).Width - Eps,
                   "grid visible policy remains non-overlapping");

      --  Grow container and re-run.
      Ctx.Container.Width := 320.0;
      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);
      Assert_True (Rects (1).Width > 140.0 + Eps,
                   "grid grow expands track width");
      Assert_True (Rects (2).Width > 100.0 + Eps,
                   "grid grow expands second track width");
   end Test_Grid_Resize_And_Overflow_Policy;

   procedure Test_Grid_Track_Sizing is
      --  400px container, 4 columns: auto auto auto 1fr, no gaps.
      --  Cols 1-3 are sized to child preferred widths (60, 80, 40).
      --  Col 4 (1fr) gets the remaining 220px.
      Tracks_4 : constant Grid_Track_List :=
        (Count  => 4,
         Tracks => [1 => (Track_Auto, 0.0),
                    2 => (Track_Auto, 0.0),
                    3 => (Track_Auto, 0.0),
                    4 => (Track_Fr, 1.0),
                    others => <>]);
      Ctx : Grid_Layout_Context :=
        (Container     => (0.0, 0.0, 400.0, 50.0),
         Columns       => 4,
         Explicit_Rows => 1,
         Row_Gap       => 0.0,
         Column_Gap    => 0.0,
         Column_Tracks => Tracks_4,
         others        => <>);
      Kids : Grid_Child_Info_Array (1 .. 4) :=
        (1 => (Active => True, Grid_Column => 1, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 60.0, Min_Width => 0.0, others => <>),
         2 => (Active => True, Grid_Column => 2, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 80.0, Min_Width => 0.0, others => <>),
         3 => (Active => True, Grid_Column => 3, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 40.0, Min_Width => 0.0, others => <>),
         4 => (Active => True, Grid_Column => 4, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 50.0, Min_Width => 0.0, others => <>));
      Rects : Rectangle_Array (1 .. 4);
   begin
      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);

      --  Auto columns = child pref width
      Assert_Close (Rects (1).Width, 60.0,  "track auto col1 width");
      Assert_Close (Rects (2).Width, 80.0,  "track auto col2 width");
      Assert_Close (Rects (3).Width, 40.0,  "track auto col3 width");
      --  Fr column = remaining 400 - 60 - 80 - 40 = 220
      Assert_Close (Rects (4).Width, 220.0, "track fr col4 width");
      --  Columns are left-to-right, no overlap
      Assert_Close (Rects (2).X, Rects (1).X + 60.0, "track col2 x");
      Assert_Close (Rects (3).X, Rects (2).X + 80.0, "track col3 x");
      Assert_Close (Rects (4).X, Rects (3).X + 40.0, "track col4 x");

      --  2fr / 1fr split: col4 gets 2/3 and col5 gets 1/3 of remaining 120.
      --  Container 300, cols: auto(60) auto(80) fr(2) fr(1) -- only 4 cols, so:
      --  Actually reuse ctx with a 2fr+1fr pair across two columns.
      declare
         Tracks_2fr : constant Grid_Track_List :=
           (Count  => 2,
            Tracks => [1 => (Track_Fr, 2.0),
                       2 => (Track_Fr, 1.0),
                       others => <>]);
         Ctx2 : Grid_Layout_Context :=
           (Container     => (0.0, 0.0, 300.0, 50.0),
            Columns       => 2,
            Explicit_Rows => 1,
            Row_Gap       => 0.0,
            Column_Gap    => 0.0,
            Column_Tracks => Tracks_2fr,
            others        => <>);
         Kids2 : Grid_Child_Info_Array (1 .. 2) :=
           (1 => (Active => True, Grid_Column => 1, Grid_Row => 1,
                  Grid_Column_Span => 1, Grid_Row_Span => 1, others => <>),
            2 => (Active => True, Grid_Column => 2, Grid_Row => 1,
                  Grid_Column_Span => 1, Grid_Row_Span => 1, others => <>));
         Rects2 : Rectangle_Array (1 .. 2);
      begin
         Compute_Grid_Layout (Ctx2, Kids2);
         Rects2 := Grid_To_Rectangles (Kids2);
         Assert_Close (Rects2 (1).Width, 200.0, "2fr col width");
         Assert_Close (Rects2 (2).Width, 100.0, "1fr col width");
      end;

      --  Legacy: no track list → equal distribution still works.
      declare
         Ctx3 : Grid_Layout_Context :=
           (Container     => (0.0, 0.0, 300.0, 50.0),
            Columns       => 3,
            Explicit_Rows => 1,
            Row_Gap       => 0.0,
            Column_Gap    => 0.0,
            others        => <>);  --  Column_Tracks.Count = 0
         Kids3 : Grid_Child_Info_Array (1 .. 3) :=
           (others => (Active => True, Grid_Column => 0, Grid_Row => 0,
                       Grid_Column_Span => 1, Grid_Row_Span => 1, others => <>));
         Rects3 : Rectangle_Array (1 .. 3);
      begin
         Compute_Grid_Layout (Ctx3, Kids3);
         Rects3 := Grid_To_Rectangles (Kids3);
         Assert_Close (Rects3 (1).Width, 100.0, "legacy equal col1 width");
         Assert_Close (Rects3 (2).Width, 100.0, "legacy equal col2 width");
         Assert_Close (Rects3 (3).Width, 100.0, "legacy equal col3 width");
      end;
   end Test_Grid_Track_Sizing;

   --  Regression: fr columns in a content-sized grid must not collapse to zero.
   --  Measure_Content (Fix A) includes fr content in the container width.
   --  This test simulates that: container = auto cols + fr content + gaps.
   --  3 columns: auto(60) auto(40) 1fr(child=120), gap=8.
   --  Container = 60 + 40 + 120 + 2*8 = 236.
   --  Fr column should get remaining: 236 - 2*8 - 60 - 40 = 120.
   procedure Test_Grid_Fr_Content_Sized is
      Tracks : constant Grid_Track_List :=
        (Count  => 3,
         Tracks => [1 => (Track_Auto, 0.0),
                    2 => (Track_Auto, 0.0),
                    3 => (Track_Fr,   1.0),
                    others => <>]);
      Ctx : Grid_Layout_Context :=
        (Container     => (0.0, 0.0, 236.0, 50.0),
         Columns       => 3,
         Explicit_Rows => 1,
         Row_Gap       => 0.0,
         Column_Gap    => 8.0,
         Column_Tracks => Tracks,
         others        => <>);
      Kids : Grid_Child_Info_Array (1 .. 3) :=
        (1 => (Active => True, Grid_Column => 1, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 60.0, Min_Width => 60.0, others => <>),
         2 => (Active => True, Grid_Column => 2, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 40.0, Min_Width => 40.0, others => <>),
         3 => (Active => True, Grid_Column => 3, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 120.0, Min_Width => 120.0, others => <>));
      Rects : Rectangle_Array (1 .. 3);
   begin
      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);

      --  Auto columns keep their content widths.
      Assert_Close (Rects (1).Width, 60.0, "fr-content-sized auto col1 width");
      Assert_Close (Rects (2).Width, 40.0, "fr-content-sized auto col2 width");

      --  Fr column gets the remaining space = 120 (matches its content).
      Assert_Close (Rects (3).Width, 120.0,
                    "fr-content-sized fr col3 width = 120 (not collapsed)");
   end Test_Grid_Fr_Content_Sized;

   --  Regression: with ample container space, fr columns still distribute
   --  remaining space correctly (ensure the fix didn't break normal fr sizing).
   --  Helper: make a flex container with position-styled children
   function Make_Flex_Container
     (W, H : Pixel_Type) return Widget_Handle
   is
      BH : constant Widget_Handle :=
        +Adi.Widget.Box.Create_Handle;
      Flex_Style : constant Style_Rules := (
        Display => Set (Flex),
        Flex_Direction => Set (Row),
        others => <>);
      Parts : constant Part_Style_Array := [
        Main_Part => (Style => From (Flex_Style).Build, Enabled => True),
        others => <>];
   begin
      Set_Part_Styles (BH, Parts);
      Set_Geometry (BH, (0.0, 0.0, W, H));
      return BH;
   end Make_Flex_Container;

   function Make_Child
     (S : Style_Rules) return Widget_Handle
   is
      CH : constant Widget_Handle :=
        +Adi.Widget.Box.Create_Handle;
      Parts : constant Part_Style_Array := [
        Main_Part => (Style => From (S).Build, Enabled => True),
        others => <>];
   begin
      Set_Part_Styles (CH, Parts);
      return CH;
   end Make_Child;

   procedure Test_Relative_Subtree is
      --  A relative parent's descendants must move with the offset.
      --  Container (400x200, flex row)
      --    └─ Middle (100x80, position:relative, left:15, top:10, flex column)
      --         ├─ GrandA (100x30, static)
      --         └─ GrandB (100x30, static)
      Container : constant Widget_Handle :=
        Make_Flex_Container (400.0, 200.0);

      Middle_Rules : constant Style_Rules := (
        Width     => Set (Size (Px (100.0))),
        Height    => Set (Size (Px (80.0))),
        Display   => Set (Flex),
        Flex_Direction => Set (Column),
        Position  => Set (Relative),
        Left      => Set_Left (Inset (Px (15.0))),
        Top       => Set_Top (Inset (Px (10.0))),
        others    => <>);
      Middle : constant Widget_Handle := Make_Child (Middle_Rules);
      --  Re-apply with flex-column so it lays out children vertically
      Middle_Parts : constant Part_Style_Array := [
        Main_Part => (Style => From (Middle_Rules).Build, Enabled => True),
        others => <>];

      GrandA : constant Widget_Handle :=
        Make_Child ((Width  => Set (Size (Px (100.0))),
                     Height => Set (Size (Px (30.0))),
                     others => <>));
      GrandB : constant Widget_Handle :=
        Make_Child ((Width  => Set (Size (Px (100.0))),
                     Height => Set (Size (Px (30.0))),
                     others => <>));

      GM, GA, GB : Rectangle;
   begin
      Set_Part_Styles (Middle, Middle_Parts);
      Add_Child (Middle, GrandA);
      Add_Child (Middle, GrandB);
      Add_Child (Container, Middle);
      Layout_Tree (Container);

      GM := Get_Geometry (Middle);
      GA := Get_Geometry (GrandA);
      GB := Get_Geometry (GrandB);

      --  Middle shifted by left:15, top:10
      Assert_Close (GM.X, 15.0, "rel-subtree: middle X = 0 + left:15");
      Assert_Close (GM.Y, 10.0, "rel-subtree: middle Y = 0 + top:10");

      --  GrandA must be inside Middle's shifted box
      Assert_Close (GA.X, 15.0,
                    "rel-subtree: grandA X = middle.X (15)");
      Assert_Close (GA.Y, 10.0,
                    "rel-subtree: grandA Y = middle.Y (10)");
      Assert_Close (GA.Height, 30.0,
                    "rel-subtree: grandA height = 30");

      --  GrandB stacks below GrandA in column direction
      Assert_Close (GB.X, 15.0,
                    "rel-subtree: grandB X = middle.X (15)");
      Assert_Close (GB.Y, 40.0,
                    "rel-subtree: grandB Y = middle.Y (10) + grandA.H (30)");
   end Test_Relative_Subtree;

   procedure Test_Relative_Offset_Px is
      --  A relative child should keep its flow position but shift visually
      Container : constant Widget_Handle :=
        Make_Flex_Container (400.0, 100.0);
      Child1 : constant Widget_Handle :=
        Make_Child ((Width => Set (Size (Px (80.0))),
                     Height => Set (Size (Px (40.0))),
                     others => <>));
      Child2 : constant Widget_Handle :=
        Make_Child ((Width => Set (Size (Px (80.0))),
                     Height => Set (Size (Px (40.0))),
                     Position => Set (Relative),
                     Left => Set_Left (Inset (Px (10.0))),
                     Top => Set_Top (Inset (Px (5.0))),
                     others => <>));
      Child3 : constant Widget_Handle :=
        Make_Child ((Width => Set (Size (Px (80.0))),
                     Height => Set (Size (Px (40.0))),
                     others => <>));
      G1, G2, G3 : Rectangle;
   begin
      Add_Child (Container, Child1);
      Add_Child (Container, Child2);
      Add_Child (Container, Child3);
      Layout_Tree (Container);

      G1 := Get_Geometry (Child1);
      G2 := Get_Geometry (Child2);
      G3 := Get_Geometry (Child3);

      --  Child1 at flow start
      Assert_Close (G1.X, 0.0, "rel: child1 X at flow start");
      --  Child2 shifted by left:10, top:5 from its flow position (80)
      Assert_Close (G2.X, 90.0, "rel: child2 X = 80 + left:10");
      Assert_Close (G2.Y, 5.0, "rel: child2 Y = 0 + top:5");
      --  Child3 at its normal flow position (not affected by child2's offset)
      Assert_Close (G3.X, 160.0, "rel: child3 X at normal flow (160)");
   end Test_Relative_Offset_Px;

   procedure Test_Absolute_Basic is
      --  An absolute child should be positioned against parent content box
      --  and excluded from flow
      Container : constant Widget_Handle :=
        Make_Flex_Container (400.0, 200.0);
      Flow_Child : constant Widget_Handle :=
        Make_Child ((Width => Set (Size (Px (100.0))),
                     Height => Set (Size (Px (50.0))),
                     others => <>));
      Abs_Child : constant Widget_Handle :=
        Make_Child ((Width => Set (Size (Px (60.0))),
                     Height => Set (Size (Px (30.0))),
                     Position => Set (Absolute),
                     Left => Set_Left (Inset (Px (20.0))),
                     Top => Set_Top (Inset (Px (10.0))),
                     others => <>));
      Flow2 : constant Widget_Handle :=
        Make_Child ((Width => Set (Size (Px (100.0))),
                     Height => Set (Size (Px (50.0))),
                     others => <>));
      GF1, GA, GF2 : Rectangle;
   begin
      Add_Child (Container, Flow_Child);
      Add_Child (Container, Abs_Child);
      Add_Child (Container, Flow2);
      Layout_Tree (Container);

      GF1 := Get_Geometry (Flow_Child);
      GA  := Get_Geometry (Abs_Child);
      GF2 := Get_Geometry (Flow2);

      --  Flow children should be adjacent (absolute child excluded from flow)
      Assert_Close (GF1.X, 0.0, "abs: flow child1 X");
      Assert_Close (GF2.X, 100.0, "abs: flow child2 X = 100 (abs excluded)");
      --  Absolute child positioned at left:20, top:10
      Assert_Close (GA.X, 20.0, "abs: absolute X = left:20");
      Assert_Close (GA.Y, 10.0, "abs: absolute Y = top:10");
      Assert_Close (GA.Width, 60.0, "abs: absolute width = explicit 60");
      Assert_Close (GA.Height, 30.0, "abs: absolute height = explicit 30");
   end Test_Absolute_Basic;

   procedure Test_Absolute_Dual_Inset_Sizing is
      --  When both left+right (or top+bottom) are set and no explicit size,
      --  width/height should be derived from container - insets
      Container : constant Widget_Handle :=
        Make_Flex_Container (400.0, 200.0);
      Abs_Child : constant Widget_Handle :=
        Make_Child ((Position => Set (Absolute),
                     Left => Set_Left (Inset (Px (30.0))),
                     Right => Set_Right (Inset (Px (50.0))),
                     Top => Set_Top (Inset (Px (10.0))),
                     Bottom => Set_Bottom (Inset (Px (20.0))),
                     others => <>));
      GA : Rectangle;
   begin
      Add_Child (Container, Abs_Child);
      Layout_Tree (Container);

      GA := Get_Geometry (Abs_Child);

      Assert_Close (GA.X, 30.0, "dual-inset: X = left:30");
      Assert_Close (GA.Y, 10.0, "dual-inset: Y = top:10");
      Assert_Close (GA.Width, 320.0,
                    "dual-inset: W = 400 - 30 - 50 = 320");
      Assert_Close (GA.Height, 170.0,
                    "dual-inset: H = 200 - 10 - 20 = 170");
   end Test_Absolute_Dual_Inset_Sizing;

   procedure Test_Absolute_Right_Bottom_Anchor is
      --  When only right/bottom are set, child anchors from those edges
      Container : constant Widget_Handle :=
        Make_Flex_Container (400.0, 200.0);
      Abs_Child : constant Widget_Handle :=
        Make_Child ((Width => Set (Size (Px (80.0))),
                     Height => Set (Size (Px (40.0))),
                     Position => Set (Absolute),
                     Right => Set_Right (Inset (Px (10.0))),
                     Bottom => Set_Bottom (Inset (Px (20.0))),
                     others => <>));
      GA : Rectangle;
   begin
      Add_Child (Container, Abs_Child);
      Layout_Tree (Container);

      GA := Get_Geometry (Abs_Child);

      --  X = container_width - right - width = 400 - 10 - 80 = 310
      Assert_Close (GA.X, 310.0, "right-anchor: X = 400-10-80");
      --  Y = container_height - bottom - height = 200 - 20 - 40 = 140
      Assert_Close (GA.Y, 140.0, "bottom-anchor: Y = 200-20-40");
   end Test_Absolute_Right_Bottom_Anchor;

   procedure Test_Absolute_Zero_Inset_Explicit is
      --  Regression: left:0 should be treated as "set" (not same as unset).
      --  With left:0 and right:10, this is dual-inset → width = 400-0-10 = 390
      Container : constant Widget_Handle :=
        Make_Flex_Container (400.0, 200.0);
      Abs_Child : constant Widget_Handle :=
        Make_Child ((Position => Set (Absolute),
                     Left => Set_Left (Inset (Px (0.0))),
                     Right => Set_Right (Inset (Px (10.0))),
                     Top => Set_Top (Inset (Px (0.0))),
                     Bottom => Set_Bottom (Inset (Px (0.0))),
                     others => <>));
      GA : Rectangle;
   begin
      Add_Child (Container, Abs_Child);
      Layout_Tree (Container);

      GA := Get_Geometry (Abs_Child);

      Assert_Close (GA.X, 0.0, "zero-inset: X = left:0");
      Assert_Close (GA.Y, 0.0, "zero-inset: Y = top:0");
      Assert_Close (GA.Width, 390.0,
                    "zero-inset: W = 400-0-10 (left:0 is set, dual-inset)");
      Assert_Close (GA.Height, 200.0,
                    "zero-inset: H = 200-0-0 (top:0 and bottom:0 both set)");
   end Test_Absolute_Zero_Inset_Explicit;

   procedure Test_Grid_Fr_Ample_Space is
      --  2 columns: auto(80) 1fr, container=400, no gap.
      --  Fr column should get 400-80 = 320.
      Tracks : constant Grid_Track_List :=
        (Count  => 2,
         Tracks => [1 => (Track_Auto, 0.0),
                    2 => (Track_Fr,   1.0),
                    others => <>]);
      Ctx : Grid_Layout_Context :=
        (Container     => (0.0, 0.0, 400.0, 50.0),
         Columns       => 2,
         Explicit_Rows => 1,
         Row_Gap       => 0.0,
         Column_Gap    => 0.0,
         Column_Tracks => Tracks,
         others        => <>);
      Kids : Grid_Child_Info_Array (1 .. 2) :=
        (1 => (Active => True, Grid_Column => 1, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 80.0, Min_Width => 80.0, others => <>),
         2 => (Active => True, Grid_Column => 2, Grid_Row => 1,
               Grid_Column_Span => 1, Grid_Row_Span => 1,
               Pref_Width => 50.0, Min_Width => 50.0, others => <>));
      Rects : Rectangle_Array (1 .. 2);
   begin
      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);

      Assert_Close (Rects (1).Width, 80.0, "fr-ample auto col width");
      Assert_Close (Rects (2).Width, 320.0, "fr-ample fr col gets remaining 320");
      Assert_Close (Rects (2).X, 80.0, "fr-ample fr col position");
   end Test_Grid_Fr_Ample_Space;

begin
   Test_Support.Start_Suite ("layout_flex_grid_test");

   Test_Flex_Grow_Resize;
   Test_Flex_Shrink_Min;
   Test_Flex_Margins;
   Test_Grid_Auto_And_Span;
   Test_Grid_Resize_And_Overflow_Policy;
   Test_Grid_Track_Sizing;
   Test_Grid_Fr_Content_Sized;
   Test_Grid_Fr_Ample_Space;

   --  Position layout tests
   Test_Relative_Subtree;
   Test_Relative_Offset_Px;
   Test_Absolute_Basic;
   Test_Absolute_Dual_Inset_Sizing;
   Test_Absolute_Right_Bottom_Anchor;
   Test_Absolute_Zero_Inset_Explicit;

   Test_Support.Finish;
end Layout_Flex_Grid_Test;
