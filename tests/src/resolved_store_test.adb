--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Resolved_Styles; use Adi.Resolved_Styles;
with Adi.Resolved_Styles.Testing;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Html_View;
use type Adi.Widget.Html_View.Html_View_Handle;
with Adi.Widget.Testing;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Support; use Test_Support;

--  Resolved styles live once, in one store, and every holder keeps a
--  handle into it. The store evicts, so what a holder does with a
--  handle taken before an eviction is the question this test settles,
--  along with the ceiling the animation scratch pool puts on the
--  per-frame styles a transition mints.
procedure Resolved_Store_Test is

   function Coloured (R, G, B : Natural) return Resolved_Style is
      Result : Resolved_Style := (others => <>);
   begin
      Result.Background_Color := RGB (R, G, B);
      return Result;
   end Coloured;

   function Ordered (N : Integer) return Resolved_Style is
      Result : Resolved_Style := (others => <>);
   begin
      Result.Order := Order_Value (N);
      return Result;
   end Ordered;

   --  Enough distinct styles to reach a lowered cap several times over,
   --  with the Collect between them that a frame loop supplies.
   procedure Fill (Count : Positive) is
      Ignored : Resolved_Handle;
   begin
      for I in 1 .. Count loop
         Ignored := Intern (Ordered (I));
         Collect;
      end loop;
   end Fill;

   ---------------------------------------------------------------------
   --  Interning
   ---------------------------------------------------------------------

   procedure Test_Interning_Is_Canonical is
      A : constant Resolved_Handle := Intern (Coloured (10, 20, 30));
      B : constant Resolved_Handle := Intern (Coloured (10, 20, 30));
      C : constant Resolved_Handle := Intern (Coloured (10, 20, 31));
      Held : constant Natural := Entry_Count;
      D : constant Resolved_Handle := Intern (Coloured (10, 20, 30));
   begin
      Section ("interning is canonical");

      Assert (A = B, "two equal styles take one handle");
      Assert (A /= C, "two different styles take different handles");
      Assert (Value (A) = Coloured (10, 20, 30),
              "the handle reads back the value that was stored");
      Assert (Ref (A).Background_Color = RGB (10, 20, 30),
              "and a component reads in place");
      Assert (D = A and then Entry_Count = Held,
              "interning an equal style again stores nothing further");
   end Test_Interning_Is_Canonical;

   procedure Test_Default_Handle is
      Empty : constant Resolved_Style := (others => <>);
   begin
      Section ("the default handle");

      Assert (Value (Default_Handle) = Empty,
              "the default handle carries the default style");
      Assert (Intern (Empty) = Default_Handle,
              "and interning the default style answers with it");
      Assert (Resolve (Empty_Style) = Empty,
              "a style with nothing set resolves to the same value, so "
              & "one handle serves both");
      Assert (Is_Held (Default_Handle),
              "the default handle is always answerable");
      Assert (Layout_Of (Default_Handle) = Layout_Of (Default_Handle),
              "and its layout projection is stable");
   end Test_Default_Handle;

   procedure Test_Layout_Handle is
      Plain     : constant Resolved_Style := Coloured (1, 2, 3);
      Repainted : Resolved_Style := Plain;
      Relaid    : Resolved_Style := Plain;
   begin
      Section ("the layout handle separates repaint from re-layout");

      Repainted.Background_Color := RGB (4, 5, 6);
      Relaid.Padding := CSS_Box (Px (11.0));

      Assert (not Adi.Resolved_Styles.Layout_Affecting_Diff
                    (Intern (Plain), Intern (Repainted)),
              "a colour change leaves the layout handle alone");
      Assert (Adi.Resolved_Styles.Layout_Affecting_Diff
                (Intern (Plain), Intern (Relaid)),
              "a padding change moves it");
      Assert (Layout_Of (Intern (Plain)) = Layout_Of (Intern (Repainted)),
              "two styles with equal layout inputs share one layout handle");
      Assert (Layout_Projection (Plain) = Layout_Projection (Repainted),
              "which is the projection they share");
      Assert (Layout_Projection (Plain).Background_Color
                = Resolved_Style'(others => <>).Background_Color,
              "the projection drops what layout does not read");
   end Test_Layout_Handle;

   ---------------------------------------------------------------------
   --  Eviction
   ---------------------------------------------------------------------

   procedure Test_Eviction_Invalidates_Old_Handles is
      Cap   : constant Positive := 64;
      Kept  : Resolved_Handle;
      Gen   : Natural;
   begin
      Section ("an eviction with handles outstanding");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap (Cap);
      Kept := Intern (Coloured (200, 201, 202));
      Gen := Generation;

      Assert (Is_Held (Kept), "a fresh handle is answerable");

      Fill (4 * Cap);

      Assert (Generation > Gen, "the store clears at its cap");
      Assert (not Is_Held (Kept),
              "a handle taken before the clear is no longer held");
      Assert (Value (Kept) = Resolved_Style'(others => <>),
              "and reads as the default style rather than as another "
              & "entry's value");
      --  A Collect acts on the cap rather than the intern that crossed
      --  it, so the store stands at most one style and its projection
      --  past the line.
      Assert (Entry_Count <= Cap + 2,
              "the store stays at its cap");

      declare
         Again : constant Resolved_Handle := Intern (Coloured (200, 201, 202));
      begin
         Assert (Is_Held (Again) and then Value (Again).Background_Color
                   = RGB (200, 201, 202),
                 "interning the same style again answers with a live handle");
         Assert (Again /= Kept,
                 "which the stale handle does not compare equal to");
      end;

      Adi.Resolved_Styles.Testing.Set_Entry_Cap
        (Adi.Resolved_Styles.Testing.Default_Entry_Cap);
   end Test_Eviction_Invalidates_Old_Handles;

   --  A style and the layout projection behind it are two entries, and
   --  the cap falls between them at some point in every fill. A clear
   --  taken between the two would hand back a handle naming the
   --  projection rather than the style.
   procedure Test_Interning_Across_The_Cap is
      Cap : constant Positive := 16;

      --  One layout-affecting property and one that only repaints, so
      --  the projection is a distinct value the store has to hold too.
      function Pair (N : Natural) return Resolved_Style is
         Result : Resolved_Style := (others => <>);
      begin
         Result.Background_Color := RGB (N mod 256, 1, 2);
         Result.Order := Order_Value (N);
         return Result;
      end Pair;

      Wrong : Natural := 0;
   begin
      Section ("interning a style whose projection crosses the cap");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap (Cap);
      for N in 1 .. 8 * Cap loop
         Collect;
         declare
            H : constant Resolved_Handle := Intern (Pair (N));
         begin
            if Value (H) /= Pair (N) then
               Wrong := Wrong + 1;
            end if;
         end;
      end loop;

      Assert (Wrong = 0,
              "every handle reads back the style it was asked for,"
              & Wrong'Image & " did not");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap
        (Adi.Resolved_Styles.Testing.Default_Entry_Cap);
   end Test_Interning_Across_The_Cap;

   --  A widget keeps handles across frames. An eviction under it has to
   --  leave it resolving the same style, not the style whose entry took
   --  the slot.
   procedure Test_Eviction_Under_A_Live_Widget is
      Cap : constant Positive := 64;
      W   : constant Box_Handle := Create_Handle;
      Style : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (33, 44, 55)),
               Padding          => Set (CSS_Box (Px (6.0))),
               Color            => Set (C (White)),
               others           => <>)).Build;
      Before : Resolved_Style;
   begin
      Section ("an eviction under a live widget");

      Set_Part_Style (+W, Main_Part, Style);
      Before := Get_Resolved_Part_Style (+W, Main_Part);
      Assert (Before.Background_Color = RGB (33, 44, 55),
              "the widget resolves the style it was given");
      Assert (Is_Held (Get_Resolved_Part_Handle
                         (Widget_Handle'(+W), Main_Part)),
              "and answers with a handle the store holds");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap (Cap);
      Fill (4 * Cap);

      Assert (Get_Resolved_Part_Style (+W, Main_Part) = Before,
              "and resolves the same style again across an eviction");
      Assert (Is_Held (Get_Resolved_Part_Handle
                         (Widget_Handle'(+W), Main_Part)),
              "into an entry the store holds now");

      --  The items a widget renders from carry handles too.
      Rebuild_All_Items (Widget_Handle'(+W));
      Assert (Item_Count (+W) > 0, "the widget carries items to style");
      Assert (Value (Get_Item (+W, 1).Computed_Style).Background_Color
                = RGB (33, 44, 55),
              "an item's computed style survives the eviction");

      Fill (4 * Cap);
      Rebuild_All_Items (Widget_Handle'(+W));
      Assert (Value (Get_Item (+W, 1).Computed_Style).Background_Color
                = RGB (33, 44, 55),
              "and again after a second one");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap
        (Adi.Resolved_Styles.Testing.Default_Entry_Cap);
   end Test_Eviction_Under_A_Live_Widget;

   ---------------------------------------------------------------------
   --  Animation scratch
   ---------------------------------------------------------------------

   procedure Test_Scratch_Pool is
      Slots : array (1 .. Scratch_Slots) of Scratch_Slot;
      Over  : Scratch_Slot;
      Held  : constant Natural := Entry_Count;
      One   : Resolved_Handle;
   begin
      Section ("the animation scratch pool");

      Assert (Held_Scratch = 0, "the pool starts empty");

      for I in Slots'Range loop
         Slots (I) := Acquire_Scratch;
         Assert (Slots (I) /= No_Scratch,
                 "slot" & I'Image & " is there to take");
      end loop;

      Over := Acquire_Scratch;
      Assert (Over = No_Scratch,
              "a start that finds the pool full is refused a slot");
      Assert (Held_Scratch = Scratch_Slots, "every slot is taken");

      One := Current_Cell (Slots (1));
      Write (One, Coloured (7, 7, 7));
      Assert (Value (One).Background_Color = RGB (7, 7, 7),
              "a scratch cell reads back what was written to it");
      Assert (From_Cell (Slots (1)) /= Current_Cell (Slots (1)),
              "the two cells of a slot are distinct");
      Assert (Entry_Count = Held,
              "and an interpolated style never enters the store");

      for I in Slots'Range loop
         Release_Scratch (Slots (I));
      end loop;
      Assert (Held_Scratch = 0, "released slots go back to the pool");
      Assert (not Is_Held (One),
              "and a handle into a released slot stops being answerable");
      Assert (Value (One) = Resolved_Style'(others => <>),
              "reading it gives the default style rather than the next "
              & "animation's");

      declare
         Reused : Scratch_Slot := Acquire_Scratch;
      begin
         Assert (Reused /= No_Scratch, "the pool hands the slot out again");
         Write (One, Coloured (9, 9, 9));
         Assert (Value (Current_Cell (Reused))
                   /= Coloured (9, 9, 9),
                 "a write through the stale handle does not reach it");
         Release_Scratch (Reused);
      end;
   end Test_Scratch_Pool;

   --  An item caches its style by handle, and Apply_Styles_To_Items is
   --  the only thing that puts a live one back. Update reaches that
   --  through Is_Dirty alone, so a widget that has gone clean is asked
   --  nothing until something dirties it again -- while rendering reads
   --  the handle with no resolution behind it. Rebuild_All_Items would
   --  re-apply unconditionally and step over the gate under test, so it
   --  has no place here.
   procedure Test_Eviction_Under_A_Clean_Widget is
      Cap   : constant Positive := 64;
      W     : constant Box_Handle := Create_Handle;
      Style : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (61, 72, 83)),
               Padding          => Set (CSS_Box (Px (4.0))),
               others           => <>)).Build;
      Gen   : Natural;
   begin
      Section ("an eviction under a widget that has gone clean");

      Set_Part_Style (+W, Main_Part, Style);
      Set_Geometry (+W, (X => 0.0, Y => 0.0, Width => 120.0, Height => 40.0));
      Update (Widget_Handle'(+W));

      Assert (Item_Count (+W) > 0, "the widget carries items to draw");
      Assert (Value (Get_Item (+W, 1).Computed_Style).Background_Color
                = RGB (61, 72, 83),
              "and an item carries the widget's own style");
      Assert (not Is_Dirty (Widget_Handle'(+W)),
              "the widget is clean, so Update will not revisit it");

      Gen := Generation;
      Adi.Resolved_Styles.Testing.Set_Entry_Cap (Cap);
      Fill (4 * Cap);
      Assert (Generation > Gen, "churn elsewhere cleared the store");
      Assert (not Is_Dirty (Widget_Handle'(+W)),
              "and dirtied nothing, so nothing has asked this widget "
              & "for a style since");

      --  The ordinary frame that follows: Update, then the draw reads
      --  what Update left in the items.
      Update (Widget_Handle'(+W));
      Assert (Value (Get_Item (+W, 1).Computed_Style).Background_Color
                = RGB (61, 72, 83),
              "the item draws the widget's own style rather than the "
              & "default the store answers a stale handle with");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap
        (Adi.Resolved_Styles.Testing.Default_Entry_Cap);
   end Test_Eviction_Under_A_Clean_Widget;

   --  The same for a child: Update descends only into a dirty child, so
   --  a clean leaf under a dirty parent is reached only by a walk that
   --  does not consult Is_Dirty on the way down.
   procedure Test_Eviction_Under_A_Clean_Child is
      Cap    : constant Positive := 64;
      Parent : constant Box_Handle := Create_Handle;
      Child  : constant Box_Handle := Create_Handle;
      Style  : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (91, 102, 113)),
               others           => <>)).Build;
   begin
      Section ("an eviction under a clean child of a dirty parent");

      Add_Child (Widget_Handle'(+Parent), Widget_Handle'(+Child));
      Set_Part_Style (+Child, Main_Part, Style);
      Set_Geometry (+Parent,
                    (X => 0.0, Y => 0.0, Width => 200.0, Height => 80.0));
      Set_Geometry (+Child,
                    (X => 0.0, Y => 0.0, Width => 100.0, Height => 40.0));
      Update (Widget_Handle'(+Parent));

      Assert (Item_Count (+Child) > 0, "the child carries items to draw");
      Assert (not Is_Dirty (Widget_Handle'(+Child)),
              "and is clean after the update");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap (Cap);
      Fill (4 * Cap);

      --  Only the parent is dirtied, which is what an ordinary frame
      --  looks like when one widget changed and the rest did not.
      Mark_Render_Dirty (Widget_Handle'(+Parent));
      Update (Widget_Handle'(+Parent));

      Assert (Value (Get_Item (+Child, 1).Computed_Style).Background_Color
                = RGB (91, 102, 113),
              "the child's item draws the child's own style");

      Adi.Resolved_Styles.Testing.Set_Entry_Cap
        (Adi.Resolved_Styles.Testing.Default_Entry_Cap);
   end Test_Eviction_Under_A_Clean_Child;

   --  An Html_View lays its document out once and keeps the result,
   --  items and all. Those items hold their styles by handle, and the
   --  key that decides whether the layout still stands is made of the
   --  document, the fonts, the scales and two resolved values -- none of
   --  which moves when the store lets go. Update dirties the subtree and
   --  Build_Items runs, but a layout whose key still matches is emitted
   --  rather than rebuilt, so what it hands on are the handles the store
   --  has released.
   procedure Test_Eviction_Under_A_Cached_Html_Layout is
      Cap : constant Positive := 64;
      V   : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;
      Gen : Natural;

      function First_Text return Natural is
      begin
         for I in 1 .. Item_Count (+V) loop
            if Get_Item (+V, I).Kind = Adi.Widget.Text_Item then
               return I;
            end if;
         end loop;
         return 0;
      end First_Text;

      function Text_Colour return Color_Value is
        (Value (Get_Item (+V, Positive (Idx)).Computed_Style).Color);
   begin
      Section ("an eviction under a cached html layout");

      Set_Geometry (+V, (X => 0.0, Y => 0.0, Width => 400.0, Height => 200.0));
      Adi.Widget.Html_View.Set_HTML
        (V, "<p style='color: rgb(61, 72, 83);'>paragraph</p>");
      Update (Widget_Handle'(+V));

      Idx := First_Text;
      Assert (Idx > 0, "the document lays out to a text item");
      if Idx > 0 then
         Assert (Text_Colour = RGB (61, 72, 83),
                 "carrying the colour the document gave it");
      end if;

      Gen := Generation;
      Adi.Resolved_Styles.Testing.Set_Entry_Cap (Cap);
      Fill (4 * Cap);
      Assert (Generation > Gen, "churn elsewhere cleared the store");

      --  The ordinary frame that follows.
      Update (Widget_Handle'(+V));

      Idx := First_Text;
      Assert (Idx > 0, "the item is still there after that frame");
      if Idx > 0 then
         Assert (Text_Colour = RGB (61, 72, 83),
                 "and still draws the document's colour rather than the "
                 & "default the store answers a stale handle with");
      end if;

      Adi.Resolved_Styles.Testing.Set_Entry_Cap
        (Adi.Resolved_Styles.Testing.Default_Entry_Cap);
   end Test_Eviction_Under_A_Cached_Html_Layout;

   ---------------------------------------------------------------------
   --  A transition against the pool
   ---------------------------------------------------------------------

   --  Two states apart in one property, with a transition long enough
   --  that it is still running when the test looks.
   function Animated_Style return Widget_Style is
     (From ((Background_Color => Set_Bg (RGB (10, 10, 10)),
             Transition       =>
               Set (Transition_Spec'(Duration   => 10.0,
                                     Easing     => Linear,
                                     Properties => All_Properties)),
             others           => <>))
        .On (When_State (State_Hovered),
             (Background_Color => Set_Bg (RGB (200, 10, 10)),
              others           => <>))
        .Build);

   --  Drives a widget from its resting style into its hovered one.
   procedure Hover (W : Box_Handle) is
   begin
      Set_Part_Style (+W, Main_Part, Animated_Style);
      Rebuild_All_Items (Widget_Handle'(+W));
      Set_Hovered (+W, True);
      Rebuild_All_Items (Widget_Handle'(+W));
   end Hover;

   procedure Test_A_Transition_Takes_A_Slot is
      Before : constant Natural := Held_Scratch;
      W      : constant Box_Handle := Create_Handle;
      Mid    : Resolved_Style;
   begin
      Section ("a running transition holds one scratch slot");

      Hover (W);
      Assert (Held_Scratch = Before + 1,
              "starting a transition takes a slot");

      Mid := Value (Get_Item (+W, 1).Computed_Style);
      Assert (Mid.Background_Color /= RGB (10, 10, 10)
                and then Mid.Background_Color /= RGB (200, 10, 10),
              "and the item renders a style between the two ends");

      declare
         H : Widget_Handle := +W;
      begin
         Destroy (H);
      end;
      Assert (Held_Scratch = Before,
              "destroying the widget gives the slot back");
   end Test_A_Transition_Takes_A_Slot;

   --  Past the pool a transition cannot start, and the part takes its
   --  target outright -- the path a zero duration already takes.
   procedure Test_A_Full_Pool_Snaps is
      Widgets : array (1 .. Scratch_Slots + 4) of Box_Handle;
      Snapped : Natural := 0;
   begin
      Section ("a start that finds the pool full");

      for I in Widgets'Range loop
         Widgets (I) := Create_Handle;
         Hover (Widgets (I));
      end loop;

      Assert (Held_Scratch = Scratch_Slots, "every slot is taken");

      for I in Widgets'Range loop
         if Value (Get_Item (+Widgets (I), 1).Computed_Style).Background_Color
              = RGB (200, 10, 10)
         then
            Snapped := Snapped + 1;
         end if;
      end loop;
      Assert (Snapped = Widgets'Length - Scratch_Slots,
              "the widgets past the pool show the target outright");

      for I in Widgets'Range loop
         declare
            H : Widget_Handle := +Widgets (I);
         begin
            Destroy (H);
         end;
      end loop;
      Assert (Held_Scratch = 0, "and every slot comes back");
   end Test_A_Full_Pool_Snaps;

   ---------------------------------------------------------------------
   --  Size chain
   ---------------------------------------------------------------------

   procedure Test_Sizes is
      procedure Row (Name : String; Bytes : Natural) is
         Pad : constant String := [1 .. 28 - Name'Length => ' '];
      begin
         Put_Line ("      " & Name & Pad & Natural'Image (Bytes));
      end Row;
   begin
      Section ("size chain, bytes: 'Max_Size_In_Storage_Elements");

      Row ("Resolved_Style",
           Resolved_Style'Max_Size_In_Storage_Elements);
      Row ("Resolved_Handle",
           Resolved_Handle'Max_Size_In_Storage_Elements);
      Row ("Part_Transition", Adi.Widget.Testing.Part_Transition_Bytes);
      Row ("Cached_Resolved", Adi.Widget.Testing.Cached_Resolved_Bytes);
      Row ("Transitions", Adi.Widget.Testing.Transitions_Bytes);
      Row ("Item", Adi.Widget.Testing.Item_Bytes);
      Row ("Widget", Adi.Widget.Testing.Widget_Bytes);
      Row ("Widget + 2.72 items",
           Adi.Widget.Testing.Widget_Bytes
           + (272 * Adi.Widget.Testing.Item_Bytes) / 100);
      Row ("store, entries", Entry_Count);
      Row ("store, bytes", Entry_Bytes);

      --  Nothing here may put finalization back on the chain: a
      --  controlled component would make every style-typed object
      --  controlled again.
      Assert (Resolved_Handle'Finalization_Size = 0,
              "a handle is flat");
      Assert (Resolved_Style'Finalization_Size = 0,
              "and so is the value it names");

      --  Twelve parts and a pair of handles per part, against the
      --  twelve records each of these arrays carried by value.
      Assert (Adi.Widget.Testing.Cached_Resolved_Bytes <= 128,
              "the per-part resolved cache is twelve handles");
      Assert (Adi.Widget.Testing.Transitions_Bytes <= 512,
              "and a widget's transitions carry handles too");
      Assert (Adi.Widget.Testing.Item_Bytes
                < Resolved_Style'Max_Size_In_Storage_Elements,
              "an item is smaller than one resolved style");
      Assert (Adi.Widget.Testing.Widget_Bytes <= 4096,
              "a widget is under four kilobytes");
   end Test_Sizes;

begin
   Start_Suite ("Resolved Store Test");

   Test_Interning_Is_Canonical;
   Test_Default_Handle;
   Test_Layout_Handle;
   Test_Scratch_Pool;
   Test_Eviction_Invalidates_Old_Handles;
   Test_Interning_Across_The_Cap;
   Test_Eviction_Under_A_Live_Widget;
   Test_Eviction_Under_A_Clean_Widget;
   Test_Eviction_Under_A_Clean_Child;
   Test_Eviction_Under_A_Cached_Html_Layout;
   Test_A_Transition_Takes_A_Slot;
   Test_A_Full_Pool_Snaps;
   Test_Sizes;

   Finish;
end Resolved_Store_Test;
