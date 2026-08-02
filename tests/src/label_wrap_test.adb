pragma Ada_2022;

with Ada.Text_IO;        use Ada.Text_IO;
with Adi.App;
with Adi.Core;           use Adi.Core;
with Adi.CSS_Styles;     use Adi.CSS_Styles;
with Adi.Image;
with Adi.Widget;         use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles;  use Adi.Widget_Styles;
with Test_Support;

procedure Label_Wrap_Test is
   A          : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

   procedure Check (Name : String; Cond : Boolean) is
   begin
      Test_Support.Assert (Cond, Name);
   end Check;

   --  Style helpers
   function Wrap_Label_Parts return Part_Style_Array is
      Lbl_Rules : constant Style_Rules :=
        (Text_Wrap_Mode => Set (TWM_Wrap),
         Font_Size      => Set_Font (Px (20)),
         others         => <>);
   begin
      return [Main_Part  => (Style => From (Lbl_Rules).Build, Enabled => True),
              others     => <>];
   end Wrap_Label_Parts;

   --  Wrap-enabled label with an explicit large icon column so the
   --  text-column shrink (label width − icon − gap) is clearly visible
   --  in the wrap result.
   function Wrap_Label_With_Icon_Parts return Part_Style_Array is
      Lbl_Rules : constant Style_Rules :=
        (Text_Wrap_Mode => Set (TWM_Wrap),
         Font_Size      => Set_Font (Px (20)),
         Gap            => Set (Gap (Px (8.0))),
         others         => <>);
      Icon_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (60.0))),
         Height => Set (Size (Px (60.0))),
         others => <>);
   begin
      return [Main_Part => (Style => From (Lbl_Rules).Build, Enabled => True),
              Icon_Part => (Style => From (Icon_Rules).Build, Enabled => True),
              others    => <>];
   end Wrap_Label_With_Icon_Parts;

   function Column_Box_Parts (W : Float) return Part_Style_Array is
      Box_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Align_Items    => Set (Stretch),
         Width          => Set (Size (Px (W))),
         others         => <>);
   begin
      return [Main_Part  => (Style => From (Box_Rules).Build, Enabled => True),
              others     => <>];
   end Column_Box_Parts;

   Long_Text : constant String :=
     "Same product. Same customers. Same hardware. New front-end.";

begin
   A.Init;
   Test_Support.Start_Suite ("Label_Wrap_Test");
   New_Line;

   ----------------------------------------------------------------------
   --  First layout: a label that has never been laid out is a fresh
   --  child of a column whose width comes from its grandparent. The
   --  parent must hand it a slot tall enough for the wrapped text on
   --  that very first pass -- the shape a slide deck hits when it
   --  navigates to a new slide. The label itself reports its
   --  unconstrained size; the container is what discovers the wrap, by
   --  asking how tall it is at the width it assigns.
   ----------------------------------------------------------------------

   Put_Line ("--- wrapped height on the first layout ---");
   declare
      Grandparent : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Parent      : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Lbl         : constant Widget_Handle :=
        +Adi.Widget.Label.Create_Handle (Long_Text);

      Single_Line_H : Pixel_Type;
      Laid_Out_H    : Pixel_Type;
   begin
      Set_Part_Styles (Lbl, Wrap_Label_Parts);

      --  Unconstrained, the label wants one line.
      Single_Line_H := Get_Preferred_Size (Lbl).Height;
      Put_Line
        ("  unconstrained height: " & Pixel_Type'Image (Single_Line_H));

      Set_Part_Styles (Grandparent, Column_Box_Parts (200.0));
      Set_Part_Styles (Parent,      Column_Box_Parts (200.0));
      Add_Child (Grandparent, Parent);
      Add_Child (Parent,      Lbl);

      Set_Geometry (Grandparent, (0.0, 0.0, 200.0, 600.0));
      Layout (Grandparent);

      Laid_Out_H := Get_Geometry (Lbl).Height;
      Put_Line ("  laid-out height: " & Pixel_Type'Image (Laid_Out_H));

      Check
        ("the first layout already gives the label room for the wrapped "
         & "text, without it having been laid out before",
         Laid_Out_H > Single_Line_H);
   end;

   New_Line;

   ----------------------------------------------------------------------
   --  Icon-aware wrap: when a label carries an icon, the text column is
   --  narrower than the label's full width by (icon-width + gap).  The
   --  wrap pass must use the text-column width or the second line packs
   --  more glyphs than the renderer can fit, and the tail clips off the
   --  right edge ("…runtime to [ship]" with "ship" missing).
   ----------------------------------------------------------------------

   Put_Line ("--- icon-aware wrap width ---");
   declare
      Parent     : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Lbl_Plain  : constant Widget_Handle :=
        +Adi.Widget.Label.Create_Handle (Long_Text);
      Lbl_Iconed : constant Widget_Handle :=
        +Adi.Widget.Label.Create_Handle (Long_Text);

      Plain_H, Iconed_H : Pixel_Type;
   begin
      Set_Part_Styles (Parent,     Column_Box_Parts (260.0));
      Set_Part_Styles (Lbl_Plain,  Wrap_Label_Parts);
      Set_Part_Styles (Lbl_Iconed, Wrap_Label_With_Icon_Parts);

      --  Give one label an icon so its main row reserves icon+gap.
      --  Using Create_Empty gives us a non-null Image — Label.Measure_Content
      --  uses Default_Icon_Size when the image returns 0×0 from Get_Size,
      --  so the wrap pass sees a non-trivial icon column even without
      --  loaded pixel data.
      Adi.Widget.Label.Set_Icon
        (Adi.Widget.Label.Try_As_Label (Lbl_Iconed),
         Adi.Image.Create_Empty);

      Add_Child (Parent, Lbl_Plain);
      Add_Child (Parent, Lbl_Iconed);
      Set_Geometry (Parent, (0.0, 0.0, 260.0, 800.0));

      Plain_H  := Measure_At_Width (Lbl_Plain, 260.0).Height;
      Iconed_H := Measure_At_Width (Lbl_Iconed, 260.0).Height;

      Put_Line ("  plain label height : " & Pixel_Type'Image (Plain_H));
      Put_Line ("  iconed label height: " & Pixel_Type'Image (Iconed_H));

      Check
        ("Iconed label wraps to MORE lines than plain (icon column is "
         & "subtracted from wrap width, so the same text needs an extra line)",
         Iconed_H > Plain_H);

      --  The icon is 60px tall, so a taller result could come from the
      --  icon alone: require more than that to prove the extra line.
      Check
        ("the extra height is wrapped text, not just the icon's own size",
         Iconed_H > 60.0 + 0.5);
   end;

   New_Line;

   ----------------------------------------------------------------------
   --  Reflow on widen.  A wrapping label in a row that is squeezed until
   --  the text wraps must go back to one line when the row grows again.
   --  It did not: the label measured itself at its own current width, so
   --  the width it was given became the width it asked for next time --
   --  a one-way ratchet. Shrinking fed itself and widening had no way
   --  back, leaving the material demo's title stuck on two lines.
   ----------------------------------------------------------------------

   Put_Line ("--- reflow when the row widens again ---");
   declare
      Bar : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Lbl : constant Widget_Handle :=
        +Adi.Widget.Label.Create_Handle (Long_Text);

      Bar_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Row),
         Align_Items    => Set (Center),
         others         => <>);

      function Height_At (W : Pixel_Type) return Pixel_Type is
      begin
         Set_Geometry (Bar, (0.0, 0.0, W, 80.0));
         Layout (Bar);
         return Get_Geometry (Lbl).Height;
      end Height_At;

      Wide_H, Narrow_H, Again_H, One_Line_H : Pixel_Type;
   begin
      Set_Part_Style (Bar, Main_Part, From (Bar_Rules).Build);
      Set_Part_Styles (Lbl, Wrap_Label_Parts);
      Add_Child (Bar, Lbl);

      --  What one line costs, with nothing constraining the label.
      One_Line_H := Get_Preferred_Size (Lbl).Height;

      Wide_H   := Height_At (900.0);
      Narrow_H := Height_At (420.0);
      Again_H  := Height_At (900.0);

      Put_Line ("  one line: " & Pixel_Type'Image (One_Line_H));
      Put_Line ("  height at 900: " & Pixel_Type'Image (Wide_H));
      Put_Line ("  height at 420: " & Pixel_Type'Image (Narrow_H));
      Put_Line ("  height back at 900: " & Pixel_Type'Image (Again_H));

      Check ("a row wide enough for the title keeps it on one line",
             abs (Wide_H - One_Line_H) < 0.5);
      Check ("squeezing the row wraps the title onto more lines",
             Narrow_H > Wide_H + 0.5);
      Check ("widening the row again unwraps the title",
             abs (Again_H - Wide_H) < 0.5);
   end;

   New_Line;

   ----------------------------------------------------------------------
   --  A grid measures a wrapping cell at the width that cell will
   --  actually be rendered at -- its own declared width when it has one,
   --  the track width otherwise -- and a declared height still wins over
   --  whatever the text measures.
   ----------------------------------------------------------------------

   Put_Line ("--- grid measures a wrapping cell at its real width ---");
   declare
      --  One Main_Part style per case: wrap and font size have to travel
      --  with the declared size, or setting the size again would drop
      --  them and the text would not wrap at all.
      function Kid_Rules
        (Width_Px  : Pixel_Type := -1.0;
         Height_Px : Pixel_Type := -1.0) return Style_Rules
      is
         R : Style_Rules :=
           (Text_Wrap_Mode => Set (TWM_Wrap),
            Font_Size      => Set_Font (Px (20)),
            others         => <>);
      begin
         if Width_Px > 0.0 then
            R.Width := Set (Size (Px (Float (Width_Px))));
         end if;
         if Height_Px > 0.0 then
            R.Height := Set (Size (Px (Float (Height_Px))));
         end if;
         return R;
      end Kid_Rules;

      function Grid_Height (Child_Rules : Style_Rules) return Pixel_Type is
         Host : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
         Kid  : constant Widget_Handle :=
           +Adi.Widget.Label.Create_Handle (Long_Text);
         Host_Rules : constant Style_Rules :=
           (Display            => Set (Adi.CSS_Styles.Grid),
            Grid_Columns       => Set (Grid_Columns_Value (1)),
            Grid_Column_Tracks =>
              (Count  => 1,
               Tracks => [1 => (Track_Px, 300.0), others => <>]),
            others             => <>);
      begin
         Set_Part_Style (Host, Main_Part, From (Host_Rules).Build);
         Set_Part_Style (Kid, Main_Part, From (Child_Rules).Build);
         Add_Child (Host, Kid);

         --  Short host: the row grows to what the cell needs, and the
         --  grid grows with it, so the host's height is the measurement.
         Set_Geometry (Host, (0.0, 0.0, 300.0, 10.0));
         Layout (Host);
         return Get_Geometry (Host).Height;
      end Grid_Height;

      Full    : constant Pixel_Type := Grid_Height (Kid_Rules);
      Narrow  : constant Pixel_Type := Grid_Height (Kid_Rules (Width_Px => 100.0));
      Fixed_H : constant Pixel_Type := Grid_Height (Kid_Rules (Height_Px => 30.0));
   begin
      Put_Line ("  grid height: full=" & Pixel_Type'Image (Full)
                & " child width:100px=" & Pixel_Type'Image (Narrow)
                & " child height:30px=" & Pixel_Type'Image (Fixed_H));

      --  The narrow case is the one that separates the two widths: its
      --  cell is 300 wide while the child is 100, so measuring at the
      --  cell would report roughly two lines. Measured at the width it
      --  is actually rendered at, it needs many more.
      Check ("a wrapping cell is measured at its own declared width, "
             & "not at the track's",
             Narrow > 3.0 * Full);
      Check ("a declared height survives the width-constrained measurement",
             abs (Fixed_H - 30.0) < 0.5);
   end;

   New_Line;

   Test_Support.Finish;
end Label_Wrap_Test;
