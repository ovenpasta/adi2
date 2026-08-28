pragma Ada_2022;

with Test_Support;      use Test_Support;
with Adi.CSS_Source;
with Adi.CSS_Source.Testing;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Testing;
with Adi.Widget_Styles; use Adi.Widget_Styles;

--  Styles registered on a Style_Source are interned: the source keeps
--  handles, and the styles themselves are stored once for the process.
--  An application that builds one source per generated UI package
--  registers the same table from every one of them, so what must not
--  scale with the number of sources is either the size of an entry or
--  the number of stored styles.
procedure Style_Interning_Test is

   function Main_Styles (Rules : Style_Rules) return Part_Style_Array is
     ([Main_Part => (Style => From (Rules).Build, Enabled => True),
       others    => <>]);

   function Interned_Styles return Natural
     renames Adi.Widget.Testing.Interned_Styles;

   --  Built by a function, not held in a constant: the point is that
   --  each source constructs its own equal copies, as generated code
   --  does, rather than sharing one table.
   function Table return Adi.CSS_Source.Static_Style_Entry_Array is
     ([Adi.CSS_Source.Class_Entry
         ("panel",
          Main_Styles ((Background_Color => Set_Bg (RGB (17, 23, 31)),
                        Padding          => Set (CSS_Box (Px (8.0), Px (8.0),
                                                          Px (8.0), Px (8.0))),
                        others           => <>))),
       Adi.CSS_Source.Class_Entry
         ("title",
          Main_Styles ((Color     => Set (C (White)),
                        Font_Size => Set_Font (Px (18.0)),
                        others    => <>))),
       Adi.CSS_Source.Id_Entry
         ("root",
          Main_Styles ((Display => Set (Flex), others => <>)))]);

   procedure Test_Entry_Is_Small is
   begin
      Section ("size of a registered selector");
      Assert (Adi.CSS_Source.Testing.Static_Entry_Bytes <= 256,
              "a registered selector costs at most 256 bytes");
   end Test_Entry_Is_Small;

   procedure Test_Same_Table_From_Many_Sources is
      Sources     : array (1 .. 8) of Adi.CSS_Source.Style_Source;
      Before      : constant Natural := Interned_Styles;
      After_First : Natural;
   begin
      Section ("the same table registered from many sources");

      Adi.CSS_Source.Set_Static_Entries (Sources (1), Table);
      After_First := Interned_Styles;

      for I in 2 .. Sources'Last loop
         Adi.CSS_Source.Set_Static_Entries (Sources (I), Table);
      end loop;

      Assert (After_First > Before,
              "registering a table stores the styles it names");
      Assert (Interned_Styles = After_First,
              "registering an equal table again stores nothing further");
   end Test_Same_Table_From_Many_Sources;

   --  A style is a wall of discriminated records holding strings and an
   --  access value. Two equal ones built by separate calls share no
   --  bytes, so anything that keys on their bytes stores each of them.
   procedure Test_Equal_Styles_Carrying_A_String is
      function Named return Part_Style_Array is
        (Main_Styles ((Font_Family => Set_Font_Family ("DejaVu Sans"),
                       others      => <>)));

      First  : constant Interned_Part_Styles := Intern (Named);
      Middle : constant Natural              := Interned_Styles;
      Second : constant Interned_Part_Styles := Intern (Named);
   begin
      Section ("equal styles built twice");
      Assert (First = Second,
              "two equal styles carrying a string intern alike");
      Assert (Interned_Styles = Middle,
              "and the second stores nothing further");
   end Test_Equal_Styles_Carrying_A_String;

   procedure Test_Round_Trip is
      Original : Part_Style_Array := Empty_Part_Styles;
   begin
      Section ("intern and expand");

      Original (Main_Part) :=
        (Style   => From ((Color            => Set (C (White)),
                           Background_Color => Set_Bg (RGB (9, 9, 9)),
                           others           => <>))
                      .On (When_State (State_Hovered),
                           (Color  => Set (RGB (1, 2, 3)), others => <>))
                      .On (When_Part_State (State_Disabled),
                           (Opacity => Set (0.5), others => <>))
                      .Build,
         Enabled => True);

      --  A part that carries a style and is switched off is not the same
      --  as a part with no style: Merge_Part_Styles skips the first and
      --  would fold in the second.
      Original (Label_Part) :=
        (Style   => From ((Color => Set (RGB (7, 7, 7)), others => <>)).Build,
         Enabled => False);

      Assert (Expand (Intern (Original)) = Original,
              "interning and expanding returns what went in");
      Assert (not Expand (Intern (Original)) (Label_Part).Enabled,
              "a part switched off stays switched off");
   end Test_Round_Trip;

   --  A gradient is held by pointer, and a pointer is what equality on
   --  the enclosing style compares, so a style carrying one is equal to
   --  its own copy only if equal gradients are one pointer.
   procedure Test_Gradients_Are_Shared is
      function Fade (To : Color_Value) return Part_Style_Array is
        (Main_Styles
           ((Background_Image => Set_Bg_Image
               (Linear_Gradient
                  (90.0,
                   [1      => Gradient_Stop_Auto (C (Black)),
                    2      => Gradient_Stop_Auto (To),
                    others => <>],
                   2)),
             others => <>)));

      Before : constant Natural              := Interned_Styles;
      First  : constant Interned_Part_Styles := Intern (Fade (C (White)));
      Middle : constant Natural              := Interned_Styles;
      Second : constant Interned_Part_Styles := Intern (Fade (C (White)));
   begin
      Section ("styles carrying a gradient");
      Assert (Middle > Before, "a gradient style is stored");
      Assert (Fade (C (White)) = Fade (C (White)),
              "equal gradients make equal styles");
      Assert (Fade (C (White)) /= Fade (RGB (1, 2, 3)),
              "different gradients make different styles");
      Assert (First = Second,
              "two equal gradients built separately intern alike");
      Assert (Interned_Styles = Middle,
              "and the second stores nothing further");
      Assert (Expand (First) = Fade (C (White)),
              "a gradient survives interning");
   end Test_Gradients_Are_Shared;

begin
   Start_Suite ("Style Interning Test");

   Test_Entry_Is_Small;
   Test_Same_Table_From_Many_Sources;
   Test_Equal_Styles_Carrying_A_String;
   Test_Round_Trip;
   Test_Gradients_Are_Shared;

   Finish;
end Style_Interning_Test;
