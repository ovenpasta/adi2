pragma Ada_2022;

with Ada.Text_IO;  use Ada.Text_IO;
with Test_Support; use Test_Support;
with Adi.Widget;   use Adi.Widget;
with Adi.Widget.Box;
use type Adi.Widget.Box.Box_Handle;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Source.Testing;

--  A generated Build binds a root and then every widget under it, and an
--  application may call Build many times on one shared Style_Source --
--  once per row of a list, say. The bindings accumulate on purpose: a
--  CSS reload has to restyle every row already on screen.
--
--  What must not accumulate is the work each Build does. Binding a fresh
--  tree changes nothing about the trees bound before it, so re-styling
--  them is waste that grows with every row, and a list long enough turns
--  it into a hang.
procedure CSS_Binding_Growth_Test is

   function Main_Styles (Rules : Style_Rules) return Part_Style_Array is
     ([Main_Part => (Style => From (Rules).Build, Enabled => True),
       others    => <>]);

   Widgets_Per_Build : constant := 24;
   Builds            : constant := 60;

   Source : Adi.CSS_Source.Style_Source;

   --  What the generator emits: bind the root's metadata, then bind each
   --  widget in the tree under the selectors naming it. The root is one
   --  of those widgets.
   procedure Build is
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
   begin
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Root);
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Root,
         Tag_Name   => "box",
         Class_Name => "row");

      for I in 2 .. Widgets_Per_Build loop
         declare
            Child : constant Adi.Widget.Box.Box_Handle :=
              Adi.Widget.Box.Create_Handle;
         begin
            Adi.Widget.Add_Child (+Root, +Child);
            Adi.CSS_Source.Bind_Selector_Set
              (Source     => Source,
               W          => +Child,
               Tag_Name   => "box",
               Class_Name => "cell");
         end;
      end loop;
   end Build;

begin
   Start_Suite ("CSS Binding Growth Test");
   Section ("Repeated Build does not re-style what it did not change");

   Adi.CSS_Source.Testing.Reset_Counts;

   for N in 1 .. Builds loop
      Build;
   end loop;

   declare
      Visits  : constant Natural :=
        Natural (Adi.CSS_Source.Testing.Visit_Count);
      Applied : constant Natural :=
        Natural (Adi.CSS_Source.Testing.Reapply_Count);
      --  Quadratic growth is what the bug looks like: every Build
      --  re-styles every binding made so far.
      --  Two walks per Build: Bind_Root_Metadata, then binding the root
      --  itself. Build i walks 24i and then 24i+1.
      Quadratic : constant Natural :=
        48 * (Builds * (Builds - 1) / 2) + Builds;
      --  A few re-applications per Build is fine -- changing the root
      --  target does change the styles of the widget losing the role and
      --  the one taking it.
      Budget : constant Natural := 8 * Builds;
   begin
      Put_Line ("  visited" & Visits'Image
                & ", reapplied" & Applied'Image
                & "; quadratic would be" & Quadratic'Image
                & ", budget" & Budget'Image);
      --  Visits, not applications: a walk that finds the two changed
      --  entries by scanning everything costs the same as one that
      --  re-styles everything.
      Assert (Visits <= Budget,
              "Build looks at what changed, not everything bound before");
      Assert (Applied <= Budget,
              "and re-styles only that");
   end;

   ---------------------------------------------------------------------
   --  What the cheap path has to preserve
   ---------------------------------------------------------------------

   Section ("Handing the root role over restyles both widgets");

   declare
      Metadata : constant Adi.CSS_Parser.Stylesheet_Metadata :=
        (Has_Root_Style => True,
         Root_Styles    =>
           Main_Styles ((Background_Color => Set_Bg (RGB (10, 20, 30)),
                         others           => <>)),
         others         => <>);

      Styled : Adi.CSS_Source.Style_Source;
      Ok     : Boolean := False;

      First  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Second : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;

      function Is_Root_Bg (H : Adi.Widget.Box.Box_Handle) return Boolean is
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+H, Main_Part);
      begin
         return R.Background_Color.Kind = RGB
           and then R.Background_Color.R = 10
           and then R.Background_Color.G = 20
           and then R.Background_Color.B = 30;
      end Is_Root_Bg;

      function Has_Row_Border (H : Adi.Widget.Box.Box_Handle) return Boolean is
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+H, Main_Part);
      begin
         return R.Border_Width.Kind = Gap_Uniform
           and then R.Border_Width.All_Edges.Amount = 3.0;
      end Has_Row_Border;
   begin
      Adi.CSS_Source.Add_Static_Entry
        (Styled,
         Adi.CSS_Source.Class_Entry
           ("plain",
            Main_Styles ((Opacity => Set (0.5), others => <>))));
      Adi.CSS_Source.Add_Static_Entry
        (Styled,
         Adi.CSS_Source.Class_Entry
           ("row",
            Main_Styles ((Border_Width => Set (Border_Width (Px (3.0))),
                          others       => <>))));
      Adi.CSS_Source.Set_Mode (Styled, Adi.CSS_Source.Static_Mode, Ok);
      Assert (Ok, "static mode");
      Adi.CSS_Source.Set_Static_Metadata (Styled, Metadata);

      --  First is the root and carries .row.
      Adi.CSS_Source.Bind_Root_Metadata (Styled, +First);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Styled, W => +First, Class_Name => "row");

      Assert (Is_Root_Bg (First), "the root has the :root background");
      Assert (Has_Row_Border (First), "and its own .row border");

      --  Second takes the role.
      Adi.CSS_Source.Bind_Root_Metadata (Styled, +Second);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Styled, W => +Second, Class_Name => "row");

      Assert (not Is_Root_Bg (First),
              "the old root loses the :root background");
      Assert (Has_Row_Border (First),
              "but keeps the .row border it was bound under");
      Assert (Is_Root_Bg (Second),
              "the new root gains the :root background");
      Assert (Has_Row_Border (Second), "and its own .row border");

      --  Binding the same root again must not strip what it is bound
      --  under: applying the :root styles alone replaces a widget's part
      --  styles rather than merging into them.
      Adi.CSS_Source.Bind_Root_Metadata (Styled, +Second);
      Assert (Is_Root_Bg (Second), "rebinding the same root keeps :root");
      Assert (Has_Row_Border (Second),
              "and keeps the selectors it was bound under");

      --  Handing the role to a widget that was already bound, without
      --  binding it again afterwards.
      Adi.CSS_Source.Bind_Root_Metadata (Styled, +First);
      Assert (Is_Root_Bg (First),
              "a root bound earlier gains :root on handover");
      Assert (Has_Row_Border (First),
              "and keeps its selectors without being rebound");
      Assert (not Is_Root_Bg (Second),
              "and the one before it loses :root");
      Assert (Has_Row_Border (Second), "keeping its own selectors");

      --  Switching back again.
      Adi.CSS_Source.Bind_Root_Metadata (Styled, +Second);
      Assert (Is_Root_Bg (Second) and then Has_Row_Border (Second),
              "switching back restores :root and keeps selectors");
      Assert (not Is_Root_Bg (First) and then Has_Row_Border (First),
              "and the other gives :root up but keeps selectors");

      --  Rebinding the current root under a different selector, then
      --  handing the role away: the widget must keep the selector it was
      --  last bound under, not the one before it.
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Styled, W => +Second, Class_Name => "plain");
      Assert (not Has_Row_Border (Second),
              "rebinding the root under another selector drops .row");
      Adi.CSS_Source.Bind_Root_Metadata (Styled, +First);
      Assert (not Has_Row_Border (Second),
              "and handing the role away does not bring .row back");
   end;

   ---------------------------------------------------------------------
   --  A root that was never bound under a selector
   ---------------------------------------------------------------------

   Section ("An unbound root gives the :root styles back");

   declare
      Metadata : constant Adi.CSS_Parser.Stylesheet_Metadata :=
        (Has_Root_Style => True,
         Root_Styles    =>
           Main_Styles ((Background_Color => Set_Bg (RGB (10, 20, 30)),
                         others           => <>)),
         others         => <>);

      Styled : Adi.CSS_Source.Style_Source;
      Ok     : Boolean := False;
      A      : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      B      : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;

      function Is_Root_Bg (H : Adi.Widget.Box.Box_Handle) return Boolean is
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+H, Main_Part);
      begin
         return R.Background_Color.Kind = RGB
           and then R.Background_Color.R = 10;
      end Is_Root_Bg;
   begin
      Adi.CSS_Source.Set_Mode (Styled, Adi.CSS_Source.Static_Mode, Ok);
      Adi.CSS_Source.Set_Static_Metadata (Styled, Metadata);

      --  A is made root and never bound under any selector.
      Adi.CSS_Source.Bind_Root_Metadata (Styled, +A);
      Assert (Is_Root_Bg (A), "the unbound root takes the :root styles");

      Adi.CSS_Source.Bind_Root_Metadata (Styled, +B);
      Assert (not Is_Root_Bg (A),
              "and gives them back when the role moves on");
      Assert (Is_Root_Bg (B), "which the new root takes up");
   end;

   ---------------------------------------------------------------------
   --  The same rules, driven through Adi.CSS_Parser
   ---------------------------------------------------------------------

   Section ("Adi.CSS_Parser keeps the last binding of a rebound root");

   declare
      Sheet : Adi.CSS_Parser.Stylesheet;
      Ok    : Boolean := False;
      Root  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Other : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;

      function Opacity_Of (H : Adi.Widget.Box.Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+H, Main_Part).Opacity));
   begin
      Adi.CSS_Parser.Load_String
        (Sheet,
         ".alpha { opacity: 0.25; } .beta { opacity: 0.75; }",
         Ok);
      Assert (Ok, "the stylesheet parses");

      Adi.CSS_Parser.Bind_Root_Metadata (Sheet, +Root);
      Adi.CSS_Parser.Bind_Class (Sheet, "alpha", +Root);
      Assert (Opacity_Of (Root) = 0.25, "the root is bound under .alpha");

      --  Rebinding the current root replaces its entry rather than
      --  appending a second one.
      Adi.CSS_Parser.Bind_Class (Sheet, "beta", +Root);
      Assert (Opacity_Of (Root) = 0.75, "and rebound under .beta");

      --  Handing the role away restyles it from the binding in force,
      --  which is the later one.
      Adi.CSS_Parser.Bind_Root_Metadata (Sheet, +Other);
      Assert (Opacity_Of (Root) = 0.75,
              "handing the root away keeps .beta, not .alpha");
   end;

   Test_Support.Finish;
end CSS_Binding_Growth_Test;
