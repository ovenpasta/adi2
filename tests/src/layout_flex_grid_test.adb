pragma Ada_2022;

with Ada.Text_IO;      use Ada.Text_IO;
with Adi.Core;         use Adi.Core;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Layout_Util;  use Adi.Layout_Util;

procedure Layout_Flex_Grid_Test is
   Eps : constant Pixel_Type := 0.001;

   Checks : Natural := 0;

   procedure Assert_True (Cond : Boolean; Msg : String) is
   begin
      Checks := Checks + 1;
      if not Cond then
         Put_Line ("FAIL: " & Msg);
         raise Program_Error with Msg;
      end if;
   end Assert_True;

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

begin
   Put_Line ("Running layout_flex_grid_test...");

   Test_Flex_Grow_Resize;
   Test_Flex_Shrink_Min;
   Test_Flex_Margins;
   Test_Grid_Auto_And_Span;
   Test_Grid_Resize_And_Overflow_Policy;
   Test_Grid_Track_Sizing;

   Put_Line ("PASS: layout_flex_grid_test checks=" & Checks'Image);
end Layout_Flex_Grid_Test;
