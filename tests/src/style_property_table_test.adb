pragma Ada_2022;

with Adi.Animation;  use Adi.Animation;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Resolved_Styles;
with Test_Support;   use Test_Support;

--  Two per-property tables replaced two hand-maintained field lists:
--  Layout_Affecting_Properties for the layout/repaint decision, and the
--  snap set Interpolate applies below T = 0.5. Neither changed what the
--  code does, and this test is what says so — the old lists are kept
--  here and every one of the 66 properties is classified against them.

procedure Style_Property_Table_Test is

   --  The chain Adi.Widget carried before the property table, kept
   --  here as the oracle the table has to agree with.
   function Reference_Layout_Affecting_Diff
     (L, R : Resolved_Style) return Boolean is
     (L.Border_Width        /= R.Border_Width
      or else L.Padding           /= R.Padding
      or else L.Margin            /= R.Margin
      or else L.Width             /= R.Width
      or else L.Height            /= R.Height
      or else L.Min_Width         /= R.Min_Width
      or else L.Max_Width         /= R.Max_Width
      or else L.Min_Height        /= R.Min_Height
      or else L.Max_Height        /= R.Max_Height
      or else L.Font_Family       /= R.Font_Family
      or else L.Font_Size         /= R.Font_Size
      or else L.Font_Weight       /= R.Font_Weight
      or else L.Font_Style        /= R.Font_Style
      or else L.Text_Decoration   /= R.Text_Decoration
      or else L.List_Style_Type   /= R.List_Style_Type
      or else L.List_Style_Image  /= R.List_Style_Image
      or else L.List_Style_Position /= R.List_Style_Position
      or else L.White_Space       /= R.White_Space
      or else L.Text_Overflow     /= R.Text_Overflow
      or else L.Text_Wrap_Mode    /= R.Text_Wrap_Mode
      or else L.Line_Height       /= R.Line_Height
      or else L.Display           /= R.Display
      or else L.Position          /= R.Position
      or else L.Top               /= R.Top
      or else L.Right             /= R.Right
      or else L.Bottom            /= R.Bottom
      or else L.Left              /= R.Left
      or else L.Overflow_X        /= R.Overflow_X
      or else L.Overflow_Y        /= R.Overflow_Y
      or else L.Flex_Direction    /= R.Flex_Direction
      or else L.Flex_Wrap         /= R.Flex_Wrap
      or else L.Justify_Content   /= R.Justify_Content
      or else L.Align_Items       /= R.Align_Items
      or else L.Align_Content     /= R.Align_Content
      or else L.Gap               /= R.Gap
      or else L.Grid_Columns      /= R.Grid_Columns
      or else L.Grid_Rows         /= R.Grid_Rows
      or else L.Grid_Column_Tracks /= R.Grid_Column_Tracks
      or else L.Align_Self        /= R.Align_Self
      or else L.Flex_Grow         /= R.Flex_Grow
      or else L.Flex_Shrink       /= R.Flex_Shrink
      or else L.Flex_Basis        /= R.Flex_Basis
      or else L.Order             /= R.Order
      or else L.Grid_Column       /= R.Grid_Column
      or else L.Grid_Row          /= R.Grid_Row
      or else L.Grid_Column_Span  /= R.Grid_Column_Span
      or else L.Grid_Row_Span     /= R.Grid_Row_Span);

   --  A style that differs from the default in every one of the 66
   --  fields, so copying one property's fields out of it is a change
   --  the test can see.
   Contrast : constant Resolved_Style :=
     (Color               => RGB (1, 2, 3),
      Background_Color    => RGB (4, 5, 6),
      Background_Image    => Background_Image_URL ("bg.png"),
      Border_Radius       => Radius (Px (3.0)),
      Border_Width        => Border_Width (Px (2.0)),
      Border_Color        => Border_Color (RGB (7, 8, 9)),
      Border_Style        => Border_Style (Solid),
      Outline_Width       => Px (5.0),
      Outline_Color       => RGB (10, 11, 12),
      Outline_Style       => Outline_Solid,
      Outline_Offset      => Px (6.0),
      Padding             => CSS_Box (Px (7.0)),
      Margin              => [others => Margin (Px (8.0))],
      Width               => Size (Px (100.0)),
      Height              => Size (Px (101.0)),
      Min_Width           => Size (Px (102.0)),
      Max_Width           => Size (Px (103.0)),
      Min_Height          => Size (Px (104.0)),
      Max_Height          => Size (Px (105.0)),
      Font_Family         => Font_Handle (7),
      Font_Size           => Px (13.0),
      Font_Weight         => Weight_Bold,
      Font_Style          => Style_Italic,
      Text_Align          => Text_Center,
      Vertical_Align      => VA_Middle,
      Text_Decoration     => Decoration_Underline,
      List_Style_Type     => List_String ("*"),
      List_Style_Image    => List_Image ("marker.png"),
      List_Style_Position => List_Inside,
      White_Space         => WS_Pre,
      Text_Overflow       => Overflow_Ellipsis,
      Text_Wrap_Mode      => TWM_Nowrap,
      Line_Height         => Line_Height (1.7),
      Display             => Flex,
      Position            => Absolute,
      Top                 => Inset (Px (9.0)),
      Right               => Inset (Px (10.0)),
      Bottom              => Inset (Px (11.0)),
      Left                => Inset (Px (12.0)),
      Overflow_X          => Overflow_Hidden,
      Overflow_Y          => Overflow_Scroll,
      Visibility          => Visibility_Hidden,
      Opacity             => 0.5,
      Cursor              => Cursor_Pointer,
      Box_Shadow          => Shadow (Px (1.0), Px (2.0), Px (3.0), Px (4.0),
                                     RGB (13, 14, 15)),
      Object_Fit          => Fit_Cover,
      Object_Position     => Object_Position (Pos_Left, Pos_Top),
      Flex_Direction      => Column,
      Flex_Wrap           => Wrap,
      Justify_Content     => Space_Between,
      Align_Items         => Center,
      Align_Content       => Flex_End,
      Gap                 => Gap (Px (14.0)),
      Grid_Columns        => 3,
      Grid_Rows           => 4,
      Grid_Column_Tracks  => (Count  => 1,
                              Tracks => [others => (Kind  => Track_Px,
                                                    Value => 20.0)]),
      Align_Self          => Flex_Start,
      Flex_Grow           => 2.0,
      Flex_Shrink         => 3.0,
      Flex_Basis          => Basis (Px (15.0)),
      Order               => 5,
      Grid_Column         => 6,
      Grid_Row            => 7,
      Grid_Column_Span    => 2,
      Grid_Row_Span       => 3,
      Transition          => (Duration   => 0.5,
                              Easing     => Ease_In,
                              Properties => No_Properties));

   --  The fields Interpolate snapped to From below T = 0.5 before the
   --  property table, one property each.
   Reference_Snap : constant CSS_Property_Set :=
     [Prop_Border_Style        | Prop_Display          | Prop_Position     |
      Prop_Visibility          | Prop_Cursor           | Prop_Overflow_X   |
      Prop_Overflow_Y          | Prop_Flex_Direction   | Prop_Flex_Wrap    |
      Prop_Justify_Content     | Prop_Align_Items      | Prop_Align_Content |
      Prop_Align_Self          | Prop_Font_Weight      | Prop_Font_Style   |
      Prop_Text_Align          | Prop_Vertical_Align   |
      Prop_Text_Decoration     | Prop_List_Style_Type  |
      Prop_List_Style_Image    | Prop_List_Style_Position |
      Prop_White_Space         | Prop_Text_Overflow    |
      Prop_Text_Wrap_Mode      | Prop_Object_Fit       | Prop_Object_Position
        => True,
      others => False];

   --  Every property named, so what Inherit_From carries over is
   --  exactly what the inheritance table claims.
   All_Set : constant Style_Rules :=
     (Color               => Set (RGB (1, 2, 3)),
      Background_Color    => Set_Bg (RGB (4, 5, 6)),
      Background_Image    => Set_Bg_Image (Background_Image_URL ("bg.png")),
      Border_Radius       => Set (Radius (Px (3.0))),
      Border_Width        => Set (Border_Width (Px (2.0))),
      Border_Color        => Set (Border_Color (RGB (7, 8, 9))),
      Border_Style        => Set (Border_Style (Solid)),
      Outline_Width       => Set_Outline_Width (Px (5.0)),
      Outline_Color       => Set_Outline_Color (RGB (10, 11, 12)),
      Outline_Style       => Set (Outline_Solid),
      Outline_Offset      => Set_Outline_Offset (Px (6.0)),
      Padding             => Set (CSS_Box (Px (7.0))),
      Margin              => Set_Margin (CSS_Box (Px (8.0))),
      Width               => Set (Size (Px (100.0))),
      Height              => Set (Size (Px (101.0))),
      Min_Width           => Set (Size (Px (102.0))),
      Max_Width           => Set (Size (Px (103.0))),
      Min_Height          => Set (Size (Px (104.0))),
      Max_Height          => Set (Size (Px (105.0))),
      Font_Family         => Set (Font_Handle (7)),
      Font_Size           => Set_Font (Px (13.0)),
      Font_Weight         => Set (Weight_Bold),
      Font_Style          => Set (Style_Italic),
      Text_Align          => Set (Text_Center),
      Vertical_Align      => Set (VA_Middle),
      Text_Decoration     => Set (Decoration_Underline),
      List_Style_Type     => Set (List_String ("*")),
      List_Style_Image    => Set (List_Image ("marker.png")),
      List_Style_Position => Set (List_Inside),
      White_Space         => Set (WS_Pre),
      Text_Overflow       => Set (Overflow_Ellipsis),
      Text_Wrap_Mode      => Set (TWM_Nowrap),
      Line_Height         => Set (Line_Height (1.7)),
      Display             => Set (Flex),
      Position            => Set (Absolute),
      Top                 => Set_Top (Inset (Px (9.0))),
      Right               => Set_Right (Inset (Px (10.0))),
      Bottom              => Set_Bottom (Inset (Px (11.0))),
      Left                => Set_Left (Inset (Px (12.0))),
      Overflow_X          => Set_Overflow_X (Overflow_Hidden),
      Overflow_Y          => Set_Overflow_Y (Overflow_Scroll),
      Visibility          => Set (Visibility_Hidden),
      Opacity             => Set (Opacity_Value'(0.5)),
      Cursor              => Set (Cursor_Pointer),
      Box_Shadow          => Set (Shadow (Px (1.0), Px (2.0), Px (3.0),
                                          Px (4.0), RGB (13, 14, 15))),
      Object_Fit          => Set (Fit_Cover),
      Object_Position     => Set (Object_Position (Pos_Left, Pos_Top)),
      Flex_Direction      => Set (Column),
      Flex_Wrap           => Set (Wrap),
      Justify_Content     => Set (Space_Between),
      Align_Items         => Set (Center),
      Align_Content       => Set (Flex_End),
      Gap                 => Set (Gap (Px (14.0))),
      Grid_Columns        => Set (Grid_Columns_Value'(3)),
      Grid_Rows           => Set (Grid_Rows_Value'(4)),
      Grid_Column_Tracks  => (Count  => 1,
                              Tracks => [others => (Kind  => Track_Px,
                                                    Value => 20.0)]),
      Align_Self          => Set (Align_Self_Value'(Flex_Start)),
      Flex_Grow           => Set (Flex_Grow_Value'(2.0)),
      Flex_Shrink         => Set (Flex_Shrink_Value'(3.0)),
      Flex_Basis          => Set (Basis (Px (15.0))),
      Order               => Set (Order_Value'(5)),
      Grid_Column         => Set (Grid_Column_Value'(6)),
      Grid_Row            => Set (Grid_Row_Value'(7)),
      Grid_Column_Span    => Set (Grid_Column_Span_Value'(2)),
      Grid_Row_Span       => Set (Grid_Row_Span_Value'(3)),
      Transition          => Set (Transition_Spec'(Duration   => 0.5,
                                                   Easing     => Ease_In,
                                                   Properties => No_Properties)));

   --  What the hand-written Inherit_From merged from the parent before
   --  the table drove it: the fifteen text and typography properties,
   --  cursor, and visibility. Transcribed here so the table is checked
   --  against something other than itself.
   Reference_Inherited : constant CSS_Property_Set :=
     [Prop_Color | Prop_Font_Family | Prop_Font_Size | Prop_Font_Weight |
      Prop_Font_Style | Prop_Text_Align | Prop_Vertical_Align |
      Prop_Text_Decoration | Prop_Text_Overflow | Prop_Text_Wrap_Mode |
      Prop_Line_Height | Prop_White_Space | Prop_Cursor |
      Prop_List_Style_Type | Prop_List_Style_Image |
      Prop_List_Style_Position | Prop_Visibility
        => True,
      others => False];

   Base : constant Resolved_Style := (others => <>);

   ---------------------------------------------------------------------------

   procedure Test_Every_Property_Moves is
   begin
      Section ("The contrast style differs from the default everywhere");

      for P in CSS_Property loop
         declare
            Mutated : Resolved_Style := Base;
         begin
            Copy_Property (P, Contrast, Mutated);

            if P = Prop_Overflow then
               --  Shorthand metadata: no field of its own.
               Assert (Mutated = Base,
                       "the overflow shorthand copies nothing");
            else
               Assert (Mutated /= Base,
                       "the contrast style differs in " & P'Image);
               Assert (Property_Differs (P, Base, Mutated),
                       P'Image & " reports its own field as differing");
            end if;
         end;
      end loop;
   end Test_Every_Property_Moves;

   procedure Test_Layout_Diff_Matches_The_Chain is
   begin
      Section ("The property table classifies as the old chain did");

      Assert (Layout_Affecting_Diff (Base, Base)
                = Reference_Layout_Affecting_Diff (Base, Base),
              "two equal styles: no layout-affecting difference");

      for P in CSS_Property loop
         declare
            Mutated : Resolved_Style := Base;
         begin
            Copy_Property (P, Contrast, Mutated);

            Assert (Layout_Affecting_Diff (Base, Mutated)
                      = Reference_Layout_Affecting_Diff (Base, Mutated),
                    "a change to " & P'Image
                    & " is classified as it was before");
         end;
      end loop;

      --  Grid_Column_Tracks has no property of its own and travels with
      --  grid-template-columns, so it needs a pair of its own.
      declare
         Tracks_Only : Resolved_Style := Base;
      begin
         Tracks_Only.Grid_Column_Tracks := Contrast.Grid_Column_Tracks;
         Assert (Property_Differs (Prop_Grid_Columns, Base, Tracks_Only),
                 "the grid track list travels with grid-template-columns");
         Assert (Layout_Affecting_Diff (Base, Tracks_Only)
                   = Reference_Layout_Affecting_Diff (Base, Tracks_Only),
                 "a change to the track list alone is classified as before");
      end;
   end Test_Layout_Diff_Matches_The_Chain;

   --  The store interns each entry's layout-affecting properties on
   --  their own, and Adi.Resolved_Styles.Layout_Affecting_Diff is one
   --  equality on that second handle. Canonical interning makes the two
   --  answers the same answer, and this is what says so.
   procedure Test_Layout_Handles_Match_The_Table is
      use Adi.Resolved_Styles;
      Base_Handle : constant Resolved_Handle := Intern (Base);
   begin
      Section ("the layout handle agrees with the property table");

      Assert (not Adi.Resolved_Styles.Layout_Affecting_Diff
                    (Base_Handle, Intern (Base)),
              "a style compared against itself reports no layout change");

      for P in CSS_Property loop
         declare
            Mutated : Resolved_Style := Base;
         begin
            Copy_Property (P, Contrast, Mutated);

            Assert (Adi.Resolved_Styles.Layout_Affecting_Diff
                      (Base_Handle, Intern (Mutated))
                      = Layout_Affecting_Diff (Base, Mutated),
                    "a change to " & P'Image
                    & " reaches the layout handle exactly as the table "
                    & "classifies it");
         end;
      end loop;

      declare
         Tracks_Only : Resolved_Style := Base;
      begin
         Tracks_Only.Grid_Column_Tracks := Contrast.Grid_Column_Tracks;
         Assert (Adi.Resolved_Styles.Layout_Affecting_Diff
                   (Base_Handle, Intern (Tracks_Only)),
                 "and so does the grid track list on its own");
      end;
   end Test_Layout_Handles_Match_The_Table;

   procedure Test_Interpolate_Snaps_As_Before is
      --  Nothing is animated, so every property either snaps to From
      --  below the midpoint or keeps the target.
      Mid : constant Resolved_Style :=
        Interpolate (From => Contrast, To => Base, T => 0.25);
   begin
      Section ("Interpolate snaps the properties it always snapped");

      for P in CSS_Property loop
         if P /= Prop_Overflow then
            declare
               Snapped : constant Boolean :=
                 not Property_Differs (P, Mid, Contrast);
            begin
               Assert (Snapped = Reference_Snap (P),
                       P'Image & " snaps below the midpoint as it did");
            end;
         end if;
      end loop;
   end Test_Interpolate_Snaps_As_Before;

   procedure Test_Inheritance_Table_Matches is
      --  A child that names nothing, so every property the result names
      --  is one Inherit_From carried over from the parent.
      Inherited : constant Style_Rules := Inherit_From (All_Set, Empty_Style);
      Carried   : constant CSS_Property_Set := Set_Properties (Inherited);
   begin
      Section ("Inherit_From carries what the inheritance table claims");

      Assert (Set_Properties (All_Set)
                = CSS_Property_Set'[Prop_Overflow => False, others => True],
              "the parent style names every property");

      --  Two claims, and the table is only honest if both hold: that it
      --  still says what the hand-written Inherit_From did, and that the
      --  implementation carries what it says.
      for P in CSS_Property loop
         Assert (Inheritable_Properties (P) = Reference_Inherited (P),
                 P'Image & " inherits as it did before the table");
      end loop;

      for P in CSS_Property loop
         Assert (Carried (P) = Inheritable_Properties (P),
                 P'Image & " is inherited exactly when the table says so");
      end loop;
   end Test_Inheritance_Table_Matches;

begin
   Start_Suite ("Style Property Table Test");

   Test_Every_Property_Moves;
   Test_Layout_Diff_Matches_The_Chain;
   Test_Layout_Handles_Match_The_Table;
   Test_Interpolate_Snaps_As_Before;
   Test_Inheritance_Table_Matches;

   Finish;
end Style_Property_Table_Test;
