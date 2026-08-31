pragma Ada_2022;

with Ada.Directories;
with Ada.Real_Time;
with Ada.Text_IO;  use Ada.Text_IO;
with Test_Support; use Test_Support;
with Adi.Widget;   use Adi.Widget;
with Adi.Widget.Box;
use type Adi.Widget.Box.Box_Handle;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Parser;
with Adi.CSS_Parser.Testing;
with Adi.CSS_Source;
with Adi.CSS_Source.Testing;
with Adi.OS;
use type Adi.CSS_Source.Testing.Count;
use type Adi.CSS_Parser.Testing.Count;

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

   procedure Write_Text_File (Path : String; Content : String) is
      F : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (F, Content);
      Ada.Text_IO.Close (F);
   end Write_Text_File;

   Widgets_Per_Build : constant := 24;
   Builds            : constant := 60;

   Source : Adi.CSS_Source.Style_Source;

   Sheet_Metadata : constant Adi.CSS_Parser.Stylesheet_Metadata :=
     (Has_Root_Style => True,
      Root_Styles    =>
        Main_Styles ((Background_Color => Set_Bg (RGB (1, 2, 3)),
                      others           => <>)),
      others         => <>);

   --  What the generator emits, whole: install the stylesheet, choose a
   --  mode, then bind the root and every widget under it. All of it runs
   --  again on the next Build, against the same Source.
   procedure Build is
      Root    : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Mode_Ok : Boolean := False;
   begin
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry
        (Source,
         Adi.CSS_Source.Class_Entry
           ("cell",
            Main_Styles ((Opacity => Set (0.5), others => <>))));
      Adi.CSS_Source.Set_Static_Metadata (Source, Sheet_Metadata);
      Adi.CSS_Source.Set_Mode
        (Source, Adi.CSS_Source.Static_Mode, Mode_Ok);

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
   --  A Build re-run over one tree binds the same widgets again
   ---------------------------------------------------------------------

   Section ("Re-binding a widget replaces its binding rather than adding");

   declare
      Src  : Adi.CSS_Source.Style_Source;
      Ok   : Boolean := False;
      Kept : constant := 12;
      type Row_Array is array (1 .. Kept) of Adi.Widget.Box.Box_Handle;
      Rows : Row_Array;
      After_First : Natural;
   begin
      Adi.CSS_Source.Add_Static_Entry
        (Src,
         Adi.CSS_Source.Class_Entry
           ("cell", Main_Styles ((Opacity => Set (0.5), others => <>))));
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok);

      for I in Rows'Range loop
         Rows (I) := Adi.Widget.Box.Create_Handle;
      end loop;

      for Pass in 1 .. 5 loop
         for I in Rows'Range loop
            Adi.CSS_Source.Bind_Selector_Set
              (Source     => Src,
               W          => +Rows (I),
               Tag_Name   => "box",
               Class_Name => "cell");
         end loop;

         if Pass = 1 then
            After_First := Adi.CSS_Source.Testing.Bindings_Held (Src);
         end if;
      end loop;

      Put_Line ("  bindings after one pass" & After_First'Image
                & ", after five" 
                & Adi.CSS_Source.Testing.Bindings_Held (Src)'Image);

      Assert (After_First = Kept,
              "one binding per widget after the first pass");
      Assert (Adi.CSS_Source.Testing.Bindings_Held (Src) = Kept,
              "and still one per widget after four more");
   end;

   ---------------------------------------------------------------------
   --  Finding the binding held for a widget, whatever else is held
   ---------------------------------------------------------------------

   --  Two instruments, because neither settles it alone.
   --
   --  Probe_Count is the exact one, over a narrow question: it counts
   --  the stored keys the binding map compares against, so re-binding a
   --  widget the map already holds must compare at least the key it
   --  finds, and a scan written outside the map compares nothing
   --  through Equivalent_Keys and reads as zero. Both bounds are
   --  asserted, which is why fresh keys will not do -- those land in
   --  empty buckets and read as zero for a hash and a scan alike.
   --
   --  The elapsed time is the general one. Two sources are held at
   --  sizes an order of magnitude apart and the same batch is bound to
   --  each; everything the batch touches is the same either side, so
   --  what is left between the two figures is how the container
   --  answers. A scan puts the ratio at the ratio of the sizes; a hash
   --  leaves it near one. Minimums over rounds that alternate which
   --  side goes first, so neither a scheduler hiccup nor a clock
   --  ramping up lands in the verdict.

   Section ("Finding a binding costs the same whatever else is bound");

   declare
      use Ada.Real_Time;

      Small_Src, Large_Src     : Adi.CSS_Source.Style_Source;
      Small_Sheet, Large_Sheet : Adi.CSS_Parser.Stylesheet;
      Ok : Boolean := False;

      Small_Held : constant := 1_000;
      Large_Held : constant := 16_000;
      Batch      : constant := 400;
      Rounds     : constant := 4;

      --  Widgets kept in hand so a later pass can bind them again and
      --  make the map compare keys it is holding.
      Kept : constant := 200;
      type Kept_Array is array (1 .. Kept) of Adi.Widget.Box.Box_Handle;
      Small_Kept, Large_Kept : Kept_Array;

      --  Bind Count fresh widgets to a source and to a sheet. They
      --  outlive the call, so what is bound against keeps growing.
      procedure Bind_Fresh (Src   : in out Adi.CSS_Source.Style_Source;
                            Sh    : in out Adi.CSS_Parser.Stylesheet;
                            Count : Positive) is
      begin
         for I in 1 .. Count loop
            declare
               W : constant Adi.Widget.Box.Box_Handle :=
                 Adi.Widget.Box.Create_Handle;
            begin
               Adi.CSS_Source.Bind_Selector_Set
                 (Source     => Src,
                  W          => +W,
                  Tag_Name   => "box",
                  Class_Name => "cell");
               Adi.CSS_Parser.Bind_Class (Sh, "cell", +W);
            end;
         end loop;
      end Bind_Fresh;

      --  Bind Count fresh widgets and keep their handles.
      procedure Bind_Kept (Src  : in out Adi.CSS_Source.Style_Source;
                           Sh   : in out Adi.CSS_Parser.Stylesheet;
                           Into : out Kept_Array) is
      begin
         for I in Into'Range loop
            Into (I) := Adi.Widget.Box.Create_Handle;
            Adi.CSS_Source.Bind_Selector_Set
              (Source     => Src,
               W          => +Into (I),
               Tag_Name   => "box",
               Class_Name => "cell");
            Adi.CSS_Parser.Bind_Class (Sh, "cell", +Into (I));
         end loop;
      end Bind_Kept;

      --  Bind them again, which makes each lookup find a key the map
      --  already holds, and report what the map compared to find it.
      procedure Rebind (Src    : in out Adi.CSS_Source.Style_Source;
                        Sh     : in out Adi.CSS_Parser.Stylesheet;
                        Held   : Kept_Array;
                        Probes : out Adi.CSS_Source.Testing.Count;
                        Sheet_Probes : out Adi.CSS_Parser.Testing.Count) is
      begin
         Adi.CSS_Source.Testing.Reset_Counts;
         Adi.CSS_Parser.Testing.Reset_Probes;
         for W of Held loop
            Adi.CSS_Source.Bind_Selector_Set
              (Source     => Src,
               W          => +W,
               Tag_Name   => "box",
               Class_Name => "cell");
            Adi.CSS_Parser.Bind_Class (Sh, "cell", +W);
         end loop;
         Probes := Adi.CSS_Source.Testing.Probe_Count;
         Sheet_Probes := Adi.CSS_Parser.Testing.Probe_Count;
      end Rebind;

      procedure Prepare (Src : in out Adi.CSS_Source.Style_Source;
                         Sh  : in out Adi.CSS_Parser.Stylesheet) is
      begin
         Adi.CSS_Source.Add_Static_Entry
           (Src,
            Adi.CSS_Source.Class_Entry
              ("cell", Main_Styles ((Opacity => Set (0.5), others => <>))));
         Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok);
         Assert (Ok, "static mode");
         Adi.CSS_Parser.Load_String (Sh, ".cell { opacity: 0.5; }", Ok);
         Assert (Ok, "the sheet parses");
      end Prepare;

      --  One round against one source, timed and counted.
      procedure Round (Src     : in out Adi.CSS_Source.Style_Source;
                       Sh      : in out Adi.CSS_Parser.Stylesheet;
                       Elapsed : out Time_Span;
                       Probes  : out Adi.CSS_Source.Testing.Count;
                       Sheet_Probes : out Adi.CSS_Parser.Testing.Count)
      is
         Started : Time;
      begin
         Adi.CSS_Source.Testing.Reset_Counts;
         Adi.CSS_Parser.Testing.Reset_Probes;
         Started := Clock;
         Bind_Fresh (Src, Sh, Batch);
         Elapsed := Clock - Started;
         Probes := Adi.CSS_Source.Testing.Probe_Count;
         Sheet_Probes := Adi.CSS_Parser.Testing.Probe_Count;
      end Round;

      Small_Time, Large_Time : Time_Span;
      Best_Small : Time_Span := Time_Span_Last;
      Best_Large : Time_Span := Time_Span_Last;
      Ignored_Probes : Adi.CSS_Source.Testing.Count;
      Ignored_Sheet  : Adi.CSS_Parser.Testing.Count;

      Small_Rebind, Large_Rebind : Adi.CSS_Source.Testing.Count;
      Small_Sheet_Rebind, Large_Sheet_Rebind : Adi.CSS_Parser.Testing.Count;

      Small_Us, Large_Us : Long_Float;

      Ceiling : constant Adi.CSS_Source.Testing.Count :=
        4 * Adi.CSS_Source.Testing.Count (Kept);
      Sheet_Ceiling : constant Adi.CSS_Parser.Testing.Count :=
        4 * Adi.CSS_Parser.Testing.Count (Kept);
   begin
      Prepare (Small_Src, Small_Sheet);
      Prepare (Large_Src, Large_Sheet);

      Bind_Kept (Small_Src, Small_Sheet, Small_Kept);
      Bind_Kept (Large_Src, Large_Sheet, Large_Kept);
      Bind_Fresh (Small_Src, Small_Sheet, Small_Held - Kept);
      Bind_Fresh (Large_Src, Large_Sheet, Large_Held - Kept);

      ------------------------------------------------------------------
      --  What the map compares to find a key it is holding
      ------------------------------------------------------------------

      Rebind (Small_Src, Small_Sheet, Small_Kept,
              Small_Rebind, Small_Sheet_Rebind);
      Rebind (Large_Src, Large_Sheet, Large_Kept,
              Large_Rebind, Large_Sheet_Rebind);

      Put_Line ("  keys compared re-binding" & Natural'Image (Kept)
                & " widgets:" & Small_Rebind'Image & " against"
                & Natural'Image (Small_Held) & " held,"
                & Large_Rebind'Image & " against"
                & Natural'Image (Large_Held));

      Assert (Small_Rebind >= Adi.CSS_Source.Testing.Count (Kept),
              "finding a key the map holds compares at least that key");
      Assert (Small_Sheet_Rebind >= Adi.CSS_Parser.Testing.Count (Kept),
              "on the sheet too");
      Assert (Small_Rebind <= Ceiling,
              "and a bucket's worth, not the set");
      Assert (Large_Rebind <= Ceiling,
              "and no more against an order of magnitude more bound");
      Assert (Small_Sheet_Rebind <= Sheet_Ceiling
                and then Large_Sheet_Rebind <= Sheet_Ceiling,
              "which holds for a sheet bound to directly as well");

      ------------------------------------------------------------------
      --  What binding a fresh batch costs against either set
      ------------------------------------------------------------------

      for R in 1 .. Rounds loop
         --  Alternate which side is measured first, so a clock ramping
         --  up over the pair does not always favour the same one.
         if R mod 2 = 1 then
            Round (Small_Src, Small_Sheet,
                   Small_Time, Ignored_Probes, Ignored_Sheet);
            Round (Large_Src, Large_Sheet,
                   Large_Time, Ignored_Probes, Ignored_Sheet);
         else
            Round (Large_Src, Large_Sheet,
                   Large_Time, Ignored_Probes, Ignored_Sheet);
            Round (Small_Src, Small_Sheet,
                   Small_Time, Ignored_Probes, Ignored_Sheet);
         end if;

         if Small_Time < Best_Small then
            Best_Small := Small_Time;
         end if;
         if Large_Time < Best_Large then
            Best_Large := Large_Time;
         end if;
      end loop;

      Small_Us := Long_Float (To_Duration (Best_Small)) * 1.0E6;
      Large_Us := Long_Float (To_Duration (Best_Large)) * 1.0E6;

      Put_Line ("  best of" & Natural'Image (Rounds) & " rounds binding"
                & Natural'Image (Batch) & ":"
                & Long_Float'Image (Small_Us) & " us against"
                & Long_Float'Image (Large_Us) & " us");

      Assert (Small_Us > 0.0,
              "the clock resolves a round, so the ratio means something");
      if Small_Us > 0.0 then
         Put_Line ("  ratio:" & Long_Float'Image (Large_Us / Small_Us));
         Assert (Large_Us <= 3.0 * Small_Us,
                 "and the batch costs the same against either set");
      end if;

      Assert (Adi.CSS_Source.Testing.Bindings_Held (Small_Src)
                = Small_Held + Rounds * Batch,
              "with one binding held per widget");
      Assert (Adi.CSS_Parser.Testing.Bindings_Held (Large_Sheet)
                = Large_Held + Rounds * Batch,
              "on the sheet too");
   end;

   ---------------------------------------------------------------------
   --  A selector name the text store will not hold
   ---------------------------------------------------------------------

   --  A binding names its selector by id, and the text store answers no
   --  id at all past Max_CSS_Text_Length. Applying such a name once and
   --  holding a binding that reads back as the empty selector would
   --  style the widget and unstyle it at the next replay, so the bind
   --  is refused where the name is still in hand to report.

   Section ("A selector name past the text limit binds nothing");

   declare
      Src  : Adi.CSS_Source.Style_Source;
      W    : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ctl  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Long : constant String (1 .. Max_CSS_Text_Length + 1) := [others => 'a'];
      Ok   : Boolean := False;
      Before : Natural;

      function Opacity_Of (H : Adi.Widget.Box.Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+H, Main_Part).Opacity));
   begin
      Adi.CSS_Source.Set_Static_Entries
        (Src,
         [Adi.CSS_Source.Class_Entry
            (Long, Main_Styles ((Opacity => Set (0.5), others => <>))),
          Adi.CSS_Source.Class_Entry
            ("short", Main_Styles ((Opacity => Set (0.5), others => <>)))]);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok);
      Assert (Ok, "static mode");

      Before := Adi.CSS_Source.Testing.Bindings_Held (Src);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => Long);

      Assert (Adi.CSS_Source.Testing.Bindings_Held (Src) = Before,
              "nothing is bound under a name the store will not hold");
      Assert (Opacity_Of (W) = 1.0,
              "and no styles arrive that a replay would take back");

      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +Ctl, Class_Name => "short");
      Assert (Adi.CSS_Source.Testing.Bindings_Held (Src) = Before + 1,
              "a name that fits still binds");
      Assert (Opacity_Of (Ctl) = 0.5, "and styles its widget");

      Adi.CSS_Source.Set_Static_Entries
        (Src,
         [Adi.CSS_Source.Class_Entry
            (Long, Main_Styles ((Opacity => Set (0.75), others => <>))),
          Adi.CSS_Source.Class_Entry
            ("short", Main_Styles ((Opacity => Set (0.75), others => <>)))]);

      Assert (Opacity_Of (W) = 1.0,
              "a replay leaves the widget that was never bound alone");
      Assert (Opacity_Of (Ctl) = 0.75,
              "and carries the one that was");
   end;

   Section ("A sheet bound to directly refuses the same name");

   declare
      Sheet : Adi.CSS_Parser.Stylesheet;
      W     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ctl   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Long  : constant String (1 .. Max_CSS_Text_Length + 1) := [others => 'b'];
      Ok    : Boolean := False;

      function Opacity_Of (H : Adi.Widget.Box.Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+H, Main_Part).Opacity));
   begin
      Adi.CSS_Parser.Load_String
        (Sheet,
         "." & Long & " { opacity: 0.5; } .fits { opacity: 0.5; }", Ok);
      Assert (Ok, "the sheet parses");
      Assert (Adi.CSS_Parser.Has_Class (Sheet, Long),
              "and names the long selector");

      Adi.CSS_Parser.Bind_Class (Sheet, Long, +W);
      Assert (Adi.CSS_Parser.Testing.Bindings_Held (Sheet) = 0,
              "nothing is bound under a name the store will not hold");
      Assert (Opacity_Of (W) = 1.0, "and no styles arrive");

      Adi.CSS_Parser.Bind_Class (Sheet, "fits", +Ctl);
      Assert (Adi.CSS_Parser.Testing.Bindings_Held (Sheet) = 1,
              "a name that fits still binds");
      Assert (Opacity_Of (Ctl) = 0.5, "and styles its widget");
   end;

   ---------------------------------------------------------------------
   --  What a reload owes the widgets still on screen
   ---------------------------------------------------------------------

   Section ("A reload restyles every live binding and skips the destroyed");

   declare
      Src  : Adi.CSS_Source.Style_Source;
      Ok   : Boolean := False;
      Rows : constant := 40;
      type Row_Array is array (1 .. Rows) of Adi.Widget.Box.Box_Handle;
      Kids : Row_Array;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Live : constant := Rows / 2;

      function Opacity_Of (H : Adi.Widget.Box.Box_Handle) return Float is
        (Float (Get_Resolved_Part_Style (+H, Main_Part).Opacity));

      function Root_Red (H : Adi.Widget.Box.Box_Handle) return Natural is
         R : constant Resolved_Style :=
           Get_Resolved_Part_Style (+H, Main_Part);
      begin
         return (if R.Background_Color.Kind = RGB
                 then R.Background_Color.R else 0);
      end Root_Red;
   begin
      Adi.CSS_Source.Add_Dynamic_String
        (Src,
         ":root { background-color: rgb(10, 20, 30); }"
         & " .cell { opacity: 0.25; }",
         Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the first sheet loads");

      Adi.CSS_Source.Bind_Root_Metadata (Src, +Root);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +Root, Class_Name => "cell");
      for I in Kids'Range loop
         Kids (I) := Adi.Widget.Box.Create_Handle;
         Adi.CSS_Source.Bind_Selector_Set
           (Source => Src, W => +Kids (I), Class_Name => "cell");
      end loop;

      Assert (Root_Red (Root) = 10 and then Opacity_Of (Root) = 0.25,
              "the root carries :root and the selector it is bound under");

      --  Half the rows go.
      for I in Kids'Range loop
         if I mod 2 = 0 then
            declare
               Doomed : Adi.Widget.Widget_Handle := +Kids (I);
            begin
               Adi.Widget.Destroy (Doomed);
            end;
         end if;
      end loop;
      Adi.Widget.Pump_Widget_Store;

      Assert (Adi.CSS_Source.Testing.Bindings_Held (Src) = Live + 1,
              "the destroyed rows take their bindings with them");

      Adi.CSS_Source.Testing.Reset_Counts;
      Adi.CSS_Source.Clear_Dynamic_Entries (Src);
      Adi.CSS_Source.Add_Dynamic_String
        (Src,
         ":root { background-color: rgb(40, 50, 60); }"
         & " .cell { opacity: 0.75; }",
         Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the second sheet loads");

      Put_Line ("  reload visited"
                & Adi.CSS_Source.Testing.Visit_Count'Image
                & ", restyled"
                & Adi.CSS_Source.Testing.Reapply_Count'Image
                & " of" & Natural'Image (Live + 1) & " held");

      Assert (Adi.CSS_Source.Testing.Visit_Count
                = Adi.CSS_Source.Testing.Count (Live + 1),
              "a reload looks at what is still bound and nothing else");
      Assert (Adi.CSS_Source.Testing.Reapply_Count
                = Adi.CSS_Source.Testing.Count (Live + 1),
              "and re-styles all of it");

      for I in Kids'Range loop
         if I mod 2 = 1 then
            Assert (Opacity_Of (Kids (I)) = 0.75,
                    "every surviving row takes the new styles");
         end if;
      end loop;
      Assert (Root_Red (Root) = 40 and then Opacity_Of (Root) = 0.75,
              "and the root keeps both :root and its own selector");
   end;

   ---------------------------------------------------------------------
   --  A destroyed widget takes its binding with it
   ---------------------------------------------------------------------

   Section ("Destroying a bound widget prunes what was held for it");

   declare
      Src   : Adi.CSS_Source.Style_Source;
      Ok    : Boolean := False;
      Rows  : constant := 8;
      Panel : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      type Row_Array is array (1 .. Rows) of Adi.Widget.Box.Box_Handle;
      Kids  : Row_Array;
      Doomed : Adi.Widget.Widget_Handle;
      Before, Bound : Natural;
   begin
      Adi.CSS_Source.Add_Static_Entry
        (Src,
         Adi.CSS_Source.Class_Entry
           ("cell", Main_Styles ((Opacity => Set (0.5), others => <>))));
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok);

      Before := Adi.CSS_Source.Testing.Bindings_Held (Src);

      --  A panel and its rows, the shape a list builds and drops.
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +Panel, Class_Name => "cell");
      for I in Kids'Range loop
         Kids (I) := Adi.Widget.Box.Create_Handle;
         Adi.Widget.Add_Child (+Panel, +Kids (I));
         Adi.CSS_Source.Bind_Selector_Set
           (Source => Src, W => +Kids (I), Class_Name => "cell");
      end loop;

      Bound := Adi.CSS_Source.Testing.Bindings_Held (Src);
      Assert (Bound = Before + Rows + 1,
              "every widget bound is held");

      --  Destroying the panel destroys the rows with it.
      Doomed := +Panel;
      Adi.Widget.Destroy (Doomed);
      Adi.Widget.Pump_Widget_Store;

      Put_Line ("  bindings before" & Before'Image
                & ", bound" & Bound'Image
                & ", after destroy"
                & Adi.CSS_Source.Testing.Bindings_Held (Src)'Image);

      Assert (Adi.CSS_Source.Testing.Bindings_Held (Src) = Before,
              "the subtree takes every binding with it");
   end;

   Section ("A sheet bound to directly prunes the same way");

   declare
      Sheet  : Adi.CSS_Parser.Stylesheet;
      Ok     : Boolean := False;
      Panel  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Child  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Doomed : Adi.Widget.Widget_Handle;
   begin
      Adi.CSS_Parser.Load_String
        (Sheet, ".cell { opacity: 0.5; }", Ok);
      Assert (Ok, "the sheet parses");

      Adi.Widget.Add_Child (+Panel, +Child);
      Adi.CSS_Parser.Bind_Class (Sheet, "cell", +Panel);
      Adi.CSS_Parser.Bind_Class (Sheet, "cell", +Child);

      Assert (Adi.CSS_Parser.Testing.Bindings_Held (Sheet) = 2,
              "both widgets are bound");

      Doomed := +Panel;
      Adi.Widget.Destroy (Doomed);
      Adi.Widget.Pump_Widget_Store;

      Assert (Adi.CSS_Parser.Testing.Bindings_Held (Sheet) = 0,
              "the destroyed subtree leaves no binding behind");
   end;

   ---------------------------------------------------------------------
   --  A source holds a quarter of a megabyte; destroying it gives it back
   ---------------------------------------------------------------------

   Section ("Destroying a source releases it and stops it being walked");

   declare
      Before_Sources : constant Natural :=
        Adi.CSS_Source.Testing.Live_Sources;
      Before_Sheets  : constant Natural :=
        Adi.CSS_Parser.Testing.Live_Sheets;
      Ok : Boolean := False;
   begin
      declare
         Src : Adi.CSS_Source.Style_Source;
         W   : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
         Doomed : Adi.Widget.Widget_Handle;
      begin
         Adi.CSS_Source.Add_Dynamic_String
           (Src, ".c { opacity: 0.25; }", Ok);
         Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
         Adi.CSS_Source.Bind_Selector_Set
           (Source => Src, W => +W, Class_Name => "c");

         Assert (Adi.CSS_Source.Testing.Live_Sources = Before_Sources + 1,
                 "the source holds an impl");
         Assert (Adi.CSS_Parser.Testing.Live_Sheets > Before_Sheets,
                 "and the sheet it parsed holds one too");
         Assert (Adi.CSS_Source.Testing.Bindings_Held (Src) = 1,
                 "with the widget bound");

         Adi.CSS_Source.Destroy (Src);

         Assert (Adi.CSS_Source.Testing.Live_Sources = Before_Sources,
                 "destroying it gives the impl back");
         Assert (Adi.CSS_Parser.Testing.Live_Sheets = Before_Sheets,
                 "and the sheet with it");
         Assert (Adi.CSS_Source.Testing.Bindings_Held (Src) = 0,
                 "and leaves nothing behind");

         --  Destroying a widget afterwards must not reach the source
         --  that is gone.
         Doomed := +W;
         Adi.Widget.Destroy (Doomed);
         Adi.Widget.Pump_Widget_Store;

         --  A destroyed source is empty, not broken: using it again
         --  builds a fresh impl.
         Adi.CSS_Source.Add_Dynamic_String
           (Src, ".c { opacity: 0.75; }", Ok);
         Assert (Ok, "a destroyed source can be used again");
         Adi.CSS_Source.Destroy (Src);
      end;

      Assert (Adi.CSS_Source.Testing.Live_Sources = Before_Sources,
              "and the second impl comes back too");
   end;

   ---------------------------------------------------------------------
   --  A source and a sheet are handles, so copies of them stay honest
   ---------------------------------------------------------------------

   Section ("A copy of a destroyed source answers for itself");

   declare
      Before_Sources : constant Natural :=
        Adi.CSS_Source.Testing.Live_Sources;
      Ok : Boolean := False;
      S1 : Adi.CSS_Source.Style_Source;
      S2 : Adi.CSS_Source.Style_Source;
   begin
      Adi.CSS_Source.Add_Dynamic_String (S1, ".c { opacity: 0.5; }", Ok);
      Adi.CSS_Source.Set_Mode (S1, Adi.CSS_Source.Dynamic_Mode, Ok);

      S2 := S1;
      Assert (Adi.CSS_Source.Is_Valid (S1), "the source holds a sheet");
      Assert (Adi.CSS_Source.Is_Valid (S2), "and so does the copy of it");

      Adi.CSS_Source.Destroy (S1);

      Assert (not Adi.CSS_Source.Is_Valid (S1),
              "destroying it says so");
      Assert (not Adi.CSS_Source.Is_Valid (S2),
              "and the copy says so too, rather than naming freed memory");
      Assert (Adi.CSS_Source.Testing.Bindings_Held (S2) = 0,
              "reading through the copy answers empty");

      --  The second destroy is the one that used to take the process
      --  down: a double free through the copy.
      Adi.CSS_Source.Destroy (S2);
      Assert (Adi.CSS_Source.Testing.Live_Sources = Before_Sources,
              "destroying the copy as well changes nothing");

      Adi.CSS_Source.Add_Dynamic_String (S2, ".c { opacity: 0.75; }", Ok);
      Assert (Adi.CSS_Source.Is_Valid (S2),
              "and the copy is usable again afterwards");
      Adi.CSS_Source.Destroy (S2);
   end;

   Section ("And a copy of a destroyed sheet");

   declare
      Before_Sheets : constant Natural :=
        Adi.CSS_Parser.Testing.Live_Sheets;
      Ok : Boolean := False;
      A  : Adi.CSS_Parser.Stylesheet;
      B  : Adi.CSS_Parser.Stylesheet;
   begin
      Adi.CSS_Parser.Load_String (A, ".c { opacity: 0.5; }", Ok);
      B := A;
      Assert (Adi.CSS_Parser.Is_Valid (A) and then Adi.CSS_Parser.Is_Valid (B),
              "both the sheet and its copy hold it");

      Adi.CSS_Parser.Destroy (A);
      Assert (not Adi.CSS_Parser.Is_Valid (B),
              "destroying one says so through the other");
      Assert (Adi.CSS_Parser.Testing.Bindings_Held (B) = 0,
              "reading through the copy answers empty");

      Adi.CSS_Parser.Destroy (B);
      Assert (Adi.CSS_Parser.Testing.Live_Sheets = Before_Sheets,
              "and destroying the copy as well changes nothing");
   end;

   ---------------------------------------------------------------------
   --  The counters the budgets are read from
   ---------------------------------------------------------------------

   Section ("The counters move when something really changes");

   declare
      Src : Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok  : Boolean := False;
   begin
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.25; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");

      Adi.CSS_Source.Testing.Reset_Counts;
      Adi.CSS_Source.Clear_Dynamic_Entries (Src);
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.75; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);

      --  Every budget above is an upper bound, and zero meets all of
      --  them: without this the instrumentation could be deleted and
      --  the whole suite would still pass.
      Assert (Adi.CSS_Source.Testing.Visit_Count > 0,
              "a real change is counted as a walk");
      Assert (Adi.CSS_Source.Testing.Reapply_Count > 0,
              "and as a re-style");
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
   --  Re-adding a stylesheet a source already carries
   ---------------------------------------------------------------------

   Section ("Installing the same stylesheet again is not a reload");

   declare
      Src  : Adi.CSS_Source.Style_Source;
      W    : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok   : Boolean := False;
      Base : Adi.CSS_Source.Testing.Count;
   begin
      Adi.CSS_Source.Add_Dynamic_String
        (Src, ".cell { opacity: 0.5; }", Ok);
      Assert (Ok, "the stylesheet loads");
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "cell");

      Base := Adi.CSS_Source.Testing.Visit_Count;

      --  A Build that runs its install block again replaces the sheets
      --  and re-selects the mode. The configuration ends up identical,
      --  so nothing may be re-parsed or restyled.
      for I in 1 .. 20 loop
         Adi.CSS_Source.Clear_Dynamic_Entries (Src);
         Adi.CSS_Source.Add_Dynamic_String
           (Src, ".cell { opacity: 0.5; }", Ok);
         Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      end loop;

      Assert (Adi.CSS_Source.Testing.Visit_Count = Base,
              "re-installing an unchanged stylesheet restyles nothing");
   end;

   ---------------------------------------------------------------------
   --  Order, load status, and mutation the guard must not hide
   ---------------------------------------------------------------------

   Section ("A component with three sheets installs them as one step");

   declare
      Src   : Adi.CSS_Source.Style_Source;
      Ok    : Boolean := False;
      Base  : Adi.CSS_Source.Testing.Count;
      Kept  : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
   begin
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +Kept, Class_Name => "c");

      --  What a generated Build does for a component with three linked
      --  sheets. Publishing after each add would restyle every widget
      --  bound so far, three times per build.
      for I in 1 .. 20 loop
         Adi.CSS_Source.Begin_Update (Src);
         Adi.CSS_Source.Clear_Dynamic_Entries (Src);
         Adi.CSS_Source.Add_Dynamic_String (Src, ".a { opacity: 0.1; }", Ok);
         Adi.CSS_Source.Add_Dynamic_String (Src, ".b { opacity: 0.2; }", Ok);
         Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.3; }", Ok);
         Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
         Adi.CSS_Source.End_Update (Src);

         if I = 1 then
            --  The first build is a real change and must publish once.
            Base := Adi.CSS_Source.Testing.Visit_Count;
         end if;
      end loop;

      Assert (Adi.CSS_Source.Testing.Visit_Count = Base,
              "the builds after the first restyle nothing");
   end;

   Section ("A sheet listed twice still wins the second time");

   declare
      Src : Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok  : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      --  A, B, A: the later A wins, as the cascade says. Skipping the
      --  repeat because the source already carries it would leave B.
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.25; }", Ok);
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.75; }", Ok);
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.25; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the sheets load");

      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the last copy of the sheet wins");
   end;

   Section ("A sheet that failed to load does not report success later");

   declare
      Src : Adi.CSS_Source.Style_Source;
      Ok  : Boolean := True;
   begin
      --  Start from a source that has loaded something and is in
      --  dynamic mode: a fresh source has nothing loaded either way, so
      --  it cannot tell whether a failure cleared the flag.
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.25; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "the first sheet loads and dynamic mode is entered");

      Adi.CSS_Source.Add_Dynamic_File (Src, "no/such/file.css", Ok);
      Assert (not Ok, "a missing file fails");

      --  The identical call must not pass merely because the entry is
      --  already on the list.
      Adi.CSS_Source.Add_Dynamic_File (Src, "no/such/file.css", Ok);
      Assert (not Ok, "and fails again when asked again");

      --  The failed appends left the working sheet installed, so this
      --  has the sheet it started with and not a broken configuration.
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "and dynamic mode still holds");

      Adi.CSS_Source.Reload_Dynamic (Src, Ok);
      Assert (Ok, "and the entry that failed was never appended");
   end;

   Section ("An unreadable stylesheet path fails rather than raising");

   declare
      Src    : Adi.CSS_Source.Style_Source;
      W      : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok     : Boolean := False;
      Raised : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.25; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the sheet's styles");

      --  What a generated Build does, around a path that exists and
      --  cannot be read: a directory.
      begin
         Adi.CSS_Source.Begin_Update (Src);
         Adi.CSS_Source.Clear_Dynamic_Entries (Src);
         Adi.CSS_Source.Add_Dynamic_File (Src, "tests", Ok);
         Adi.CSS_Source.End_Update (Src);
      exception
         when others =>
            Raised := True;
      end;

      Assert (not Raised,
              "a path that cannot be read is a load failure, not an"
              & " exception out of the middle of a batch");
      Assert (not Ok, "and is reported through Success");

      --  A batch left open would gate this for the rest of the run.
      Adi.CSS_Source.Clear_Dynamic_Entries (Src);
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.75; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Opacity_Of = 0.75,
              "and the source still restyles what is bound to it");
   end;

   Section ("A batch cut short by an exception still publishes");

   declare
      Src : aliased Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok  : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.25; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the sheet's styles");

      begin
         declare
            Batch : Adi.CSS_Source.Update_Scope (Src'Access);
            pragma Unreferenced (Batch);
         begin
            Adi.CSS_Source.Clear_Dynamic_Entries (Src);
            Adi.CSS_Source.Add_Dynamic_String
              (Src, ".c { opacity: 0.75; }", Ok);
            Adi.CSS_Source.Set_Mode
              (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
            raise Program_Error with "cut short";
         end;
      exception
         when Program_Error =>
            null;
      end;

      Assert (Opacity_Of = 0.75,
              "the batch publishes on the way out, however it ends");

      --  And the source is not left mid-batch: the next change reaches
      --  the widget too.
      Adi.CSS_Source.Clear_Dynamic_Entries (Src);
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.5; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Opacity_Of = 0.5, "and the source keeps restyling after it");
   end;

   Section ("Live reload survives a stylesheet that does not parse");

   declare
      Dir  : constant String := "tests/obj";
      Path : constant String := Dir & "/css_reload_probe.css";

      Src : Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok       : Boolean := False;
      Reloaded : Boolean := False;
      Success  : Boolean := False;

      procedure Write (Text : String) is
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
         Ada.Text_IO.Put_Line (F, Text);
         Ada.Text_IO.Close (F);
      end Write;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Ada.Directories.Create_Path (Dir);
      Write (".c { opacity: 0.25; }");

      Adi.CSS_Source.Add_Dynamic_File (Src, Path, Ok);
      Assert (Ok, "the stylesheet loads");
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Adi.CSS_Source.Set_Auto_Reload (Src, True);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "and styles the bound widget");

      --  Modification times decide whether there is anything to reload,
      --  and the filesystem records them to the second.
      delay 1.1;
      Write (".c { opacity: 0.75; ");
      Adi.CSS_Source.Tick (Src, Reloaded, Success);
      Assert (not Success, "a sheet that does not parse is reported");

      delay 1.1;
      Write (".c { opacity: 0.5; }");
      Adi.CSS_Source.Tick (Src, Reloaded, Success);
      Assert (Reloaded,
              "Tick still watches the file after a parse error: one bad"
              & " save must not end live reload for the run");
      Assert (Success, "the corrected sheet loads");
      Assert (Opacity_Of = 0.5, "and the bound widget is restyled from it");

      Ada.Directories.Delete_File (Path);
   end;

   Section ("A sheet coming back identical is not read as no change");

   declare
      Text : constant String := ".c { opacity: 0.25; }";

      Src : Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok  : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Adi.CSS_Source.Add_Dynamic_String (Src, Text, Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the sheet's styles");

      --  Clearing leaves the text the widgets were styled from in place,
      --  so nothing about the sheet distinguishes before from after
      --  except that there is now nothing loaded.
      Adi.CSS_Source.Clear_Dynamic_Entries (Src);

      Adi.CSS_Source.Begin_Update (Src);
      Adi.CSS_Source.End_Update (Src);
      Assert (Opacity_Of /= 0.25,
              "a source with nothing loaded has no styles to give");

      --  The same stylesheet again, byte for byte -- an undone edit.
      Adi.CSS_Source.Add_Dynamic_String (Src, Text, Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Ok, "and loads again");
      Assert (Opacity_Of = 0.25,
              "the same text loading again is a change when the last"
              & " styling was done with nothing loaded");
   end;

   Section ("Replacing the static entries restyles what is bound");

   declare
      Src : Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok  : Boolean := False;

      Metadata : constant Adi.CSS_Parser.Stylesheet_Metadata :=
        (Has_Root_Style => False, others => <>);

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Adi.CSS_Source.Add_Static_Entry
        (Src,
         Adi.CSS_Source.Class_Entry
           ("c", Main_Styles ((Opacity => Set (0.25), others => <>))));
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok);
      Adi.CSS_Source.Set_Static_Metadata (Src, Metadata);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the first styles");

      --  The same metadata and the same mode, but different styles: a
      --  guard that only compared those two would leave the widget as
      --  it was.
      Adi.CSS_Source.Clear_Static_Entries (Src);
      Adi.CSS_Source.Add_Static_Entry
        (Src,
         Adi.CSS_Source.Class_Entry
           ("c", Main_Styles ((Opacity => Set (0.75), others => <>))));
      Adi.CSS_Source.Set_Static_Metadata (Src, Metadata);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok);

      Assert (Opacity_Of = 0.75,
              "replacing the entries restyles the bound widget");
   end;

   ---------------------------------------------------------------------
   --  Static mode replays too, so the bindings are not dynamic-only
   ---------------------------------------------------------------------

   Section ("A source that never leaves static mode replays its bindings");

   declare
      Src : Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok  : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      --  Tick returns at once for a static source, but
      --  Set_Static_Entries, Set_Static_Metadata, Set_Mode and
      --  End_Update all reach Reapply_Bindings under it.
      Adi.CSS_Source.Add_Static_Entry
        (Src,
         Adi.CSS_Source.Class_Entry
           ("c", Main_Styles ((Opacity => Set (0.25), others => <>))));
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Static_Mode, Ok);
      Assert (Ok, "static mode");
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the first entries");

      Adi.CSS_Source.Testing.Reset_Counts;
      Adi.CSS_Source.Set_Static_Entries
        (Src,
         [Adi.CSS_Source.Class_Entry
            ("c", Main_Styles ((Opacity => Set (0.75), others => <>)))]);

      Assert (Adi.CSS_Source.Testing.Visit_Count = 1,
              "a static source walks the binding it holds");
      Assert (Adi.CSS_Source.Testing.Reapply_Count = 1,
              "and re-styles it");
      Assert (Opacity_Of = 0.75,
              "so the widget follows the entries it is styled from");
   end;

   Section ("Clearing the dynamic sheets restyles what is bound");

   declare
      Src : Adi.CSS_Source.Style_Source;
      W   : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Ok  : Boolean := False;

      function Opacity_Of return Float is
        (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity));
   begin
      Adi.CSS_Source.Add_Dynamic_String (Src, ".c { opacity: 0.25; }", Ok);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Adi.CSS_Source.Bind_Selector_Set
        (Source => Src, W => +W, Class_Name => "c");
      Assert (Opacity_Of = 0.25, "the widget takes the sheet's styles");

      Adi.CSS_Source.Clear_Dynamic_Entries (Src);
      Adi.CSS_Source.Set_Mode (Src, Adi.CSS_Source.Dynamic_Mode, Ok);
      Assert (Opacity_Of /= 0.25,
              "and gives them up when the sheet is cleared");
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

   Section ("Installing a configuration costs one parse");

   declare
      use Adi.CSS_Source;
      A   : constant String := Adi.OS.Temp_Path ("adi_css_growth_a.css");
      B   : constant String := Adi.OS.Temp_Path ("adi_css_growth_b.css");
      Src : Style_Source;
      Ok  : Boolean := False;
   begin
      Write_Text_File (A, ".a { opacity: 0.25; }");
      Write_Text_File (B, ".b { opacity: 0.5; }");

      Adi.CSS_Source.Testing.Reset_Counts;
      Set_Dynamic_Sources
        (Src, [CSS_File (A), CSS_File (B), CSS_Text (".c { opacity: 1; }")],
         Ok);
      Assert (Ok, "the configuration installs");
      Assert (Adi.CSS_Source.Testing.Parse_Count = 1,
              "three sheets are parsed once, not once each");
      Assert (Adi.CSS_Source.Testing.File_Read_Count = 2,
              "and each file is read once");
   end;

   Section ("Adding sheets one at a time costs what the doc says");

   declare
      use Adi.CSS_Source;
      A   : constant String := Adi.OS.Temp_Path ("adi_css_growth_a.css");
      B   : constant String := Adi.OS.Temp_Path ("adi_css_growth_b.css");
      C   : constant String := Adi.OS.Temp_Path ("adi_css_growth_c.css");
      Src : Style_Source;
      Ok  : Boolean := False;
   begin
      Write_Text_File (C, ".c { opacity: 1; }");

      Adi.CSS_Source.Testing.Reset_Counts;
      Add_Dynamic_File (Src, A, Ok);
      Add_Dynamic_File (Src, B, Ok);
      Add_Dynamic_File (Src, C, Ok);
      Assert (Ok, "the sheets install");

      --  N parses and N(N+1)/2 reads, which is the cost Add_Dynamic_File
      --  is documented to have and Set_Dynamic_Sources exists to avoid.
      Assert (Adi.CSS_Source.Testing.Parse_Count = 3,
              "each call reparses everything installed so far");
      Assert (Adi.CSS_Source.Testing.File_Read_Count = 6,
              "and rereads every file it already read");
   end;

   Test_Support.Finish;
end CSS_Binding_Growth_Test;
