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
   --  First-show wrap: the label is a fresh child of a flex column
   --  whose width is set on the grandparent (not the immediate parent),
   --  and the label itself has no geometry yet — the same shape the
   --  slide deck hits when navigating to a new slide.  Without the
   --  ancestor-walk fallback in Label.Measure_Content, Get_Preferred_Size
   --  returns the unwrapped single-line height and the parent flex
   --  reserves a slot too small for the wrapped text to render.
   ----------------------------------------------------------------------

   Put_Line ("--- ancestor-walk wrap fallback ---");
   declare
      Grandparent : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Parent      : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Lbl         : constant Widget_Handle :=
        +Adi.Widget.Label.Create_Handle (Long_Text);

      Single_Line_H : Pixel_Type;
      Pref          : Size_2D;
   begin
      --  Configure the label as wrap-enabled, then measure its single-line
      --  height (with no parent → fallback width).
      Set_Part_Styles (Lbl, Wrap_Label_Parts);

      Single_Line_H := Get_Preferred_Size (Lbl).Height;
      Put_Line
        ("  single-line height (no parent): "
         & Pixel_Type'Image (Single_Line_H));

      --  Now assemble the tree:
      --     grandparent (width: 200px, column-flex)
      --       └ parent  (no geometry, no width set)
      --            └ label
      --  After Add_Child the label has Parent = parent (Geometry = 0),
      --  Parent.Parent = grandparent (Geometry = 0 until we Set_Geometry).
      Set_Part_Styles (Grandparent, Column_Box_Parts (200.0));
      Set_Part_Styles (Parent,      Column_Box_Parts (200.0));
      Add_Child (Grandparent, Parent);
      Add_Child (Parent,      Lbl);

      --  Set the grandparent's geometry only.  The immediate parent's
      --  Geometry stays at (0, 0, 0, 0).
      Set_Geometry (Grandparent, (0.0, 0.0, 200.0, 600.0));

      Pref := Get_Preferred_Size (Lbl);
      Put_Line
        ("  preferred height with grandparent width: "
         & Pixel_Type'Image (Pref.Height));

      Check
        ("Label.Measure_Content walks past Parent (Geometry = 0) up to "
         & "Grandparent (width 200px) and reports the wrapped height",
         Pref.Height > Single_Line_H);
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

      Plain_H  := Get_Preferred_Size (Lbl_Plain).Height;
      Iconed_H := Get_Preferred_Size (Lbl_Iconed).Height;

      Put_Line ("  plain label height : " & Pixel_Type'Image (Plain_H));
      Put_Line ("  iconed label height: " & Pixel_Type'Image (Iconed_H));

      Check
        ("Iconed label wraps to MORE lines than plain (icon column is "
         & "subtracted from wrap width, so the same text needs an extra line)",
         Iconed_H > Plain_H);
   end;

   New_Line;

   Test_Support.Finish;
end Label_Wrap_Test;
