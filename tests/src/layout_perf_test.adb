pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Test_Support;      use Test_Support;
with Adi.Core;          use Adi.Core;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Label;  use type Adi.Widget.Label.Label_Handle;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;

--  Tests for layout performance optimisations:
--    1. Resolved-style cache (Phase 1)
--    2. Epoch-based duplicate-layout elimination (Phase 2)
--    3. Perf-counter infrastructure (Phase 0)

procedure Layout_Perf_Test is

   ---------------------------------------------------------------------------
   --  Test: Layout_Tree on a root with children must actually lay them out.
   --  This is the regression that triggered the epoch fix: when both
   --  Current_Layout_Epoch and Last_Layout_Epoch start at 0, the root
   --  (and its children) must not be skipped.
   ---------------------------------------------------------------------------

   procedure Test_Layout_Tree_First_Frame is
      Root   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Child1 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("A");
      Child2 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("B");
   begin
      Put_Line ("Test: Layout_Tree first-frame regression");

      Set_Geometry (+Root, (0.0, 0.0, 400.0, 300.0));
      Add_Child (+Root, +Child1);
      Add_Child (+Root, +Child2);

      --  Give root a flex style so children get positioned
      declare
         Flex_Style : constant Widget_Style :=
           From ((Display        => Set (Flex),
                  Flex_Direction => Set (Column),
                  others         => <>)).Build;
      begin
         Set_Part_Style (+Root, Main_Part, Flex_Style);
      end;

      Reset_Perf_Counters;
      Layout_Tree (+Root);

      --  Children should have been laid out (non-zero geometry)
      Assert (Get_Geometry (+Child1).Width > 0.0,
              "child1 has non-zero width after first Layout_Tree");
      Assert (Get_Geometry (+Child2).Width > 0.0,
              "child2 has non-zero width after first Layout_Tree");

      --  Root layout must have been called (not skipped)
      Assert (Get_Perf_Layout_Calls > 0,
              "layout calls > 0 on first frame");
   end Test_Layout_Tree_First_Frame;

   ---------------------------------------------------------------------------
   --  Test: Layout_Child stamps the epoch so Layout_Tree skips re-layout.
   ---------------------------------------------------------------------------

   procedure Test_Epoch_Dedup is
      Root  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Child : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("C");
   begin
      Put_Line ("Test: epoch-based layout deduplication");

      Set_Geometry (+Root, (0.0, 0.0, 400.0, 300.0));
      Add_Child (+Root, +Child);

      --  Give root a flex style
      declare
         Flex_Style : constant Widget_Style :=
           From ((Display        => Set (Flex),
                  Flex_Direction => Set (Column),
                  others         => <>)).Build;
      begin
         Set_Part_Style (+Root, Main_Part, Flex_Style);
      end;

      --  First pass: everything gets laid out
      Reset_Perf_Counters;
      Layout_Tree (+Root);

      declare
         Calls_1 : constant Natural := Get_Perf_Layout_Calls;
         Skips_1 : constant Natural := Get_Perf_Layout_Skips;
      begin
         --  Flex layout calls Layout_Child on its children, then
         --  Layout_Tree recurses into them and should skip.
         Assert (Calls_1 >= 2,
                 "first pass: at least 2 layout calls (root + child)");
         Assert (Skips_1 >= 1,
                 "first pass: at least 1 skip (child already done by flex)");
      end;
   end Test_Epoch_Dedup;

   ---------------------------------------------------------------------------
   --  Test: Resolved-style cache returns same result and records hits.
   ---------------------------------------------------------------------------

   procedure Test_Style_Cache_Hits is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("cached");
   begin
      Put_Line ("Test: resolved-style cache hits");

      Set_Geometry (+W, (0.0, 0.0, 200.0, 40.0));

      Reset_Perf_Counters;

      --  First call: cache miss
      declare
         S1 : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Assert (Get_Perf_Style_Resolves = 1,
                 "first resolve counted");
         Assert (Get_Perf_Style_Hits = 0,
                 "first resolve is a miss");

         --  Second call: cache hit (same version + states)
         declare
            S2 : constant Resolved_Style :=
              Get_Resolved_Part_Style (+W, Main_Part);
         begin
            Assert (Get_Perf_Style_Hits = 1,
                    "second resolve is a hit");
            Assert (S1 = S2,
                    "cached result equals original");
         end;
      end;
   end Test_Style_Cache_Hits;

   ---------------------------------------------------------------------------
   --  Test: Style cache invalidates when widget state changes.
   ---------------------------------------------------------------------------

   procedure Test_Style_Cache_Invalidation is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("inv");
   begin
      Put_Line ("Test: style cache invalidation on state change");

      Set_Geometry (+W, (0.0, 0.0, 200.0, 40.0));

      --  Prime the cache
      declare
         S1 : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
         pragma Unreferenced (S1);
      begin
         null;
      end;

      Reset_Perf_Counters;

      --  Change state (hover)
      Set_State (+W, State_Hovered, True);

      --  Next resolve must be a miss (state changed)
      declare
         S2 : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
         pragma Unreferenced (S2);
      begin
         Assert (Get_Perf_Style_Resolves = 1,
                 "resolve after state change counted");
         Assert (Get_Perf_Style_Hits = 0,
                 "resolve after state change is a miss");
      end;
   end Test_Style_Cache_Invalidation;

   ---------------------------------------------------------------------------
   --  Test: Sub-part cache invalidates when widget state changes.
   --  Regression: resolving Main_Part after a state change updated the
   --  shared cache key, making a subsequent Label_Part lookup falsely
   --  hit — returning a stale style (e.g. selected text color after
   --  deselection).
   ---------------------------------------------------------------------------

   procedure Test_Subpart_Cache_Invalidation is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("sub");
      --  Give the label a style where :selected changes text color
      Selected_Color : constant Style_Rules :=
        (Color => Set (RGBA (255, 255, 255, 1.0)),
         others => <>);
      WS : constant Widget_Style :=
        From ((Color => Set (RGBA (0, 0, 0, 1.0)),
               others => <>))
          .On_Selected (Selected_Color)
          .Build;
   begin
      Put_Line ("Test: sub-part cache invalidation on state change");

      Set_Geometry (+W, (0.0, 0.0, 200.0, 40.0));
      Set_Part_Style (+W, Main_Part, WS);

      --  Select → prime cache for Main_Part AND Label_Part
      Set_State (+W, State_Selected, True);
      declare
         S_Main_Sel : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Main_Part);
         S_Label_Sel : constant Resolved_Style :=
           Get_Resolved_Part_Style (+W, Label_Part);
      begin
         --  Deselect
         Set_State (+W, State_Selected, False);

         --  Both parts must reflect the deselected state
         declare
            S_Main_Desel : constant Resolved_Style :=
              Get_Resolved_Part_Style (+W, Main_Part);
            S_Label_Desel : constant Resolved_Style :=
              Get_Resolved_Part_Style (+W, Label_Part);
         begin
            Assert (S_Main_Desel.Color /= S_Main_Sel.Color,
                    "main part color changes after deselect");
            Assert (S_Label_Desel.Color /= S_Label_Sel.Color,
                    "label part color changes after deselect (was stale)");
         end;
      end;
   end Test_Subpart_Cache_Invalidation;

   ---------------------------------------------------------------------------
   --  Test: Multiple Layout_Tree passes on the same tree work correctly.
   ---------------------------------------------------------------------------

   procedure Test_Multiple_Layout_Passes is
      Root  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Child : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("multi");
   begin
      Put_Line ("Test: multiple Layout_Tree passes");

      Set_Geometry (+Root, (0.0, 0.0, 400.0, 300.0));
      Add_Child (+Root, +Child);

      declare
         Flex_Style : constant Widget_Style :=
           From ((Display        => Set (Flex),
                  Flex_Direction => Set (Column),
                  others         => <>)).Build;
      begin
         Set_Part_Style (+Root, Main_Part, Flex_Style);
      end;

      --  First pass
      Layout_Tree (+Root);
      declare
         W1 : constant Pixel_Type := Get_Geometry (+Child).Width;
      begin
         Assert (W1 > 0.0, "pass 1: child laid out");

         --  Second pass (simulates next frame)
         Reset_Perf_Counters;
         Layout_Tree (+Root);

         declare
            W2 : constant Pixel_Type := Get_Geometry (+Child).Width;
         begin
            Assert (W2 = W1, "pass 2: child geometry unchanged");
            Assert (Get_Perf_Layout_Calls >= 2,
                    "pass 2: layout calls still happen");
         end;
      end;
   end Test_Multiple_Layout_Passes;

   ---------------------------------------------------------------------------
   --  Test: Preferred size cache returns cached result on second call.
   ---------------------------------------------------------------------------

   procedure Test_Pref_Size_Cache_Hit is
      --  Use a standalone label (not inside a flex container) so that
      --  Layout_Tree does not pre-warm the cache via Perform_Flex_Layout.
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("pref");
   begin
      Put_Line ("Test: preferred size cache hit");

      Set_Geometry (+W, (0.0, 0.0, 200.0, 40.0));

      --  Layout_Tree establishes a layout epoch.  Label's Layout does
      --  not call Get_Preferred_Size on itself.
      Layout_Tree (+W);

      Reset_Perf_Counters;

      --  First call: cache miss
      declare
         S1 : constant Size_2D := Get_Preferred_Size (+W);
      begin
         Assert (Get_Perf_Pref_Calls = 1,
                 "first pref-size call counted");
         Assert (Get_Perf_Pref_Hits = 0,
                 "first pref-size call is a miss");

         --  Second call: cache hit (same epoch + version + states + geom)
         declare
            S2 : constant Size_2D := Get_Preferred_Size (+W);
         begin
            Assert (Get_Perf_Pref_Hits = 1,
                    "second pref-size call is a hit");
            Assert (S1 = S2,
                    "cached pref size equals original");
         end;
      end;
   end Test_Pref_Size_Cache_Hit;

   ---------------------------------------------------------------------------
   --  Test: Preferred size cache invalidates on state change.
   ---------------------------------------------------------------------------

   procedure Test_Pref_Size_Cache_Invalidation is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("pinv");
   begin
      Put_Line ("Test: preferred size cache invalidation");

      Set_Geometry (+W, (0.0, 0.0, 200.0, 40.0));

      --  Layout_Tree establishes a layout epoch
      Layout_Tree (+W);

      --  Prime the cache
      declare
         S1 : constant Size_2D := Get_Preferred_Size (+W);
         pragma Unreferenced (S1);
      begin
         null;
      end;

      Reset_Perf_Counters;

      --  Change state
      Set_State (+W, State_Hovered, True);

      --  Next call must be a miss (state changed)
      declare
         S2 : constant Size_2D := Get_Preferred_Size (+W);
         pragma Unreferenced (S2);
      begin
         Assert (Get_Perf_Pref_Calls = 1,
                 "pref-size after state change counted");
         Assert (Get_Perf_Pref_Hits = 0,
                 "pref-size after state change is a miss");
      end;
   end Test_Pref_Size_Cache_Invalidation;

   ---------------------------------------------------------------------------
   --  Test: Preferred size cache invalidates on content mutation (Set_Text).
   --  Regression guard: Content_Version must cause a cache miss even when
   --  Style_Version, states, and geometry are unchanged.
   ---------------------------------------------------------------------------

   procedure Test_Pref_Size_Content_Invalidation is
      W : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("before");
   begin
      Put_Line ("Test: preferred size cache invalidation on content change");

      Set_Geometry (+W, (0.0, 0.0, 200.0, 40.0));

      --  Layout_Tree establishes a layout epoch
      Layout_Tree (+W);

      --  Prime the cache
      declare
         S1 : constant Size_2D := Get_Preferred_Size (+W);
         pragma Unreferenced (S1);
      begin
         Reset_Perf_Counters;

         --  Mutate content without changing style or state
         Adi.Widget.Label.Set_Text (W, "after - different length");

         --  Next call must be a miss (Content_Version changed)
         declare
            S2 : constant Size_2D := Get_Preferred_Size (+W);
            pragma Unreferenced (S2);
         begin
            Assert (Get_Perf_Pref_Calls = 1,
                    "pref-size after Set_Text counted");
            Assert (Get_Perf_Pref_Hits = 0,
                    "pref-size after Set_Text is a miss");
         end;
      end;
   end Test_Pref_Size_Content_Invalidation;

begin
   Start_Suite ("Layout Performance Test Suite");

   Test_Layout_Tree_First_Frame;
   Test_Epoch_Dedup;
   Test_Style_Cache_Hits;
   Test_Style_Cache_Invalidation;
   Test_Subpart_Cache_Invalidation;
   Test_Multiple_Layout_Passes;
   Test_Pref_Size_Cache_Hit;
   Test_Pref_Size_Cache_Invalidation;
   Test_Pref_Size_Content_Invalidation;

   Put_Line ("");
   Test_Support.Finish;
end Layout_Perf_Test;
