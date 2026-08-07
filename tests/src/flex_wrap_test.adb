pragma Ada_2022;

with Adi.Core;          use Adi.Core;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Layout_Util;   use Adi.Layout_Util;

with Ada.Text_IO;
with Test_Support;

--  Flex line formation: which items share a line, how the lines are
--  sized and stacked, and that each line flexes on its own.
procedure Flex_Wrap_Test is
   Eps : constant Pixel_Type := 0.001;

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Msg : String) is
   begin
      Test_Support.Assert
        (abs (Actual - Expected) <= Eps,
         Msg & " actual=" & Actual'Image & " expected=" & Expected'Image);
   end Assert_Close;

   --  An item that asks for a fixed main size and nothing else.
   function Rigid
     (Main : Pixel_Type; Cross : Pixel_Type := 20.0) return Flex_Child_Info
   is (Flex_Grow    => 0.0,
       Flex_Shrink  => 0.0,
       Flex_Basis   => Main,
       Basis_Is_Definite => True,
       Min_Main     => 0.0,
       Max_Main     => Pixel_Type'Last,
       Min_Cross    => 0.0,
       Max_Cross    => Pixel_Type'Last,
       Content_Main => Main,
       Content_Cross => Cross,
       Cross_Is_Definite => True,
       others       => <>);

   function Context
     (Width, Height : Pixel_Type;
      Wrap          : Flex_Wrap_Value                := Adi.CSS_Styles.Wrap;
      Dir           : Flex_Direction_Value           := Row;
      Align_Content : Align_Content_Value            := Stretch;
      Align_Items   : Align_Items_Value              := Flex_Start;
      Main_Gap      : Pixel_Type                     := 0.0;
      Cross_Gap     : Pixel_Type                     := 0.0)
      return Flex_Layout_Context
   is ((Container       => (0.0, 0.0, Width, Height),
        Direction       => Dir,
        Wrap            => Wrap,
        Justify_Content => Flex_Start,
        Align_Items     => Align_Items,
        Align_Content   => Align_Content,
        Main_Gap        => Main_Gap,
        Cross_Gap       => Cross_Gap));

begin
   Test_Support.Start_Suite ("flex_wrap_test");

   --  nowrap keeps every item on one line whatever the container's
   --  width, and the line overflows rather than breaking.
   Ada.Text_IO.Put_Line ("--- nowrap stays on one line ---");
   declare
      Ctx : constant Flex_Layout_Context :=
        Context (100.0, 100.0, Wrap => No_Wrap);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (60.0), Rigid (60.0), Rigid (60.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (1).Computed_Pos_Main, 0.0, "nowrap first");
      Assert_Close (Kids (2).Computed_Pos_Main, 60.0, "nowrap second");
      Assert_Close (Kids (3).Computed_Pos_Main, 120.0, "nowrap third");
      Test_Support.Assert
        (Kids (1).Computed_Pos_Cross = Kids (3).Computed_Pos_Cross,
         "nowrap leaves every item on the same line");
   end;

   --  wrap breaks where the next item no longer fits.
   Ada.Text_IO.Put_Line ("--- wrap forms lines ---");
   declare
      Ctx : constant Flex_Layout_Context := Context (100.0, 100.0);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (60.0), Rigid (60.0), Rigid (60.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (1).Computed_Pos_Main, 0.0, "wrap item 1 main");
      Assert_Close (Kids (2).Computed_Pos_Main, 0.0, "wrap item 2 main");
      Assert_Close (Kids (3).Computed_Pos_Main, 0.0, "wrap item 3 main");
      Test_Support.Assert
        (Kids (1).Computed_Pos_Cross < Kids (2).Computed_Pos_Cross
           and then Kids (2).Computed_Pos_Cross < Kids (3).Computed_Pos_Cross,
         "each item that did not fit starts a new line");
   end;

   --  An item wider than the container takes a line of its own rather
   --  than opening an empty one ahead of itself.
   Ada.Text_IO.Put_Line ("--- an oversized item still gets a line ---");
   declare
      Ctx : constant Flex_Layout_Context := Context (50.0, 100.0);
      Kids : Flex_Child_Info_Array (1 .. 2) := [Rigid (80.0), Rigid (20.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (1).Computed_Pos_Main, 0.0, "oversized main");
      Test_Support.Assert
        (Kids (1).Computed_Pos_Cross < Kids (2).Computed_Pos_Cross,
         "the oversized item does not share its line");
   end;

   --  wrap-reverse stacks the same lines from the far cross edge.
   Ada.Text_IO.Put_Line ("--- wrap-reverse reverses line order ---");
   declare
      Ctx : constant Flex_Layout_Context :=
        Context (100.0, 100.0, Wrap => Wrap_Reverse,
                 Align_Content => Adi.CSS_Styles.Flex_Start);
      Kids : Flex_Child_Info_Array (1 .. 2) := [Rigid (60.0), Rigid (60.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Test_Support.Assert
        (Kids (1).Computed_Pos_Cross > Kids (2).Computed_Pos_Cross,
         "wrap-reverse puts the first line furthest along the cross axis");
      Assert_Close
        (Kids (1).Computed_Pos_Cross + Kids (1).Computed_Cross, 100.0,
         "the first line ends at the container's far edge");
   end;

   --  Growing is per line: an item alone on the second line takes that
   --  whole line, not what was left over from the first.
   Ada.Text_IO.Put_Line ("--- grow is distributed per line ---");
   declare
      Ctx : constant Flex_Layout_Context := Context (100.0, 100.0);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (60.0), Rigid (60.0), Rigid (60.0)];
   begin
      for K of Kids loop
         K.Flex_Grow := 1.0;
         K.Basis_Is_Definite := False;
      end loop;
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (3).Computed_Main, 100.0,
                    "the lone item on the last line takes the whole line");
      Assert_Close (Kids (1).Computed_Main, 100.0,
                    "the first line's item grows within its own line");
   end;

   --  Shrinking is per line for the same reason.
   Ada.Text_IO.Put_Line ("--- shrink is distributed per line ---");
   declare
      Ctx : constant Flex_Layout_Context := Context (100.0, 200.0);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (60.0), Rigid (60.0), Rigid (120.0)];
   begin
      for K of Kids loop
         K.Flex_Shrink := 1.0;
      end loop;
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (3).Computed_Main, 100.0,
                    "the oversized item shrinks to its own line");
      Assert_Close (Kids (1).Computed_Main, 60.0,
                    "an item that already fits its line is left alone");
   end;

   --  The two gaps act on different axes: one separates items along a
   --  line, the other separates the lines.
   Ada.Text_IO.Put_Line ("--- main gap and cross gap act on their own axes ---");
   declare
      Ctx : constant Flex_Layout_Context :=
        Context (100.0, 200.0, Align_Content => Adi.CSS_Styles.Flex_Start,
                 Main_Gap => 10.0, Cross_Gap => 30.0);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (40.0), Rigid (40.0), Rigid (40.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (2).Computed_Pos_Main, 50.0,
                    "the main gap separates items on a line");
      Assert_Close (Kids (3).Computed_Pos_Main, 0.0,
                    "the third item did not fit and wrapped");
      Assert_Close (Kids (3).Computed_Pos_Cross, 50.0,
                    "the cross gap separates the lines");
   end;

   --  Cross alignment is per line: an item aligns within its own line's
   --  depth, not the container's. Deep and shallow items on different
   --  lines would otherwise all align against the same edge.
   Ada.Text_IO.Put_Line ("--- align-items applies within each line ---");
   declare
      --  Line one is 50 deep, line two is 20.
      function Kids_At (AI : Align_Items_Value) return Flex_Child_Info_Array is
         --  130 wide: two 60px items per line, so each line holds a deep
         --  item and a shallow one to align against it.
         Ctx : constant Flex_Layout_Context :=
           Context (130.0, 200.0, Align_Content => Adi.CSS_Styles.Flex_Start,
                    Align_Items => AI);
         Kids : Flex_Child_Info_Array (1 .. 4) :=
           [Rigid (60.0, 50.0), Rigid (60.0, 20.0),
            Rigid (60.0, 20.0), Rigid (60.0, 10.0)];
      begin
         --  Only stretch may resize an item, and only one that left its
         --  cross size to the layout.
         for K of Kids loop
            K.Cross_Is_Definite := False;
         end loop;
         Compute_Flex_Layout (Ctx, Kids);
         return Kids;
      end Kids_At;

      Starts : constant Flex_Child_Info_Array :=
        Kids_At (Adi.CSS_Styles.Flex_Start);
      Ends   : constant Flex_Child_Info_Array :=
        Kids_At (Adi.CSS_Styles.Flex_End);
      Middle : constant Flex_Child_Info_Array :=
        Kids_At (Adi.CSS_Styles.Center);
      Filled : constant Flex_Child_Info_Array := Kids_At (Stretch);
   begin
      Ada.Text_IO.Put_Line
        ("  line 1 depth" & Starts (1).Computed_Cross'Image
         & "  shallow item at start" & Starts (2).Computed_Pos_Cross'Image
         & " end" & Ends (2).Computed_Pos_Cross'Image
         & " center" & Middle (2).Computed_Pos_Cross'Image
         & " stretch h" & Filled (2).Computed_Cross'Image);

      Assert_Close (Starts (2).Computed_Pos_Cross, 0.0,
                    "flex-start puts the shallow item at its line's top");
      Assert_Close (Ends (2).Computed_Pos_Cross, 30.0,
                    "flex-end drops it to its line's bottom");
      Assert_Close (Middle (2).Computed_Pos_Cross, 15.0,
                    "center halves the slack within the line");
      Assert_Close (Filled (2).Computed_Cross, 50.0,
                    "stretch fills the line's depth, not the container's");

      --  Second line is only 20 deep, so its items align against that.
      Assert_Close (Ends (4).Computed_Pos_Cross, 60.0,
                    "the second line aligns within its own shallower depth");
      Assert_Close (Filled (4).Computed_Cross, 20.0,
                    "and stretch there fills only that depth");
   end;

   --  align-self overrides the container's align-items for one item,
   --  still relative to that item's own line.
   Ada.Text_IO.Put_Line ("--- align-self overrides within the line ---");
   declare
      Ctx : constant Flex_Layout_Context :=
        Context (130.0, 200.0, Align_Content => Adi.CSS_Styles.Flex_Start,
                 Align_Items => Adi.CSS_Styles.Flex_Start);
      Kids : Flex_Child_Info_Array (1 .. 2) :=
        [Rigid (60.0, 50.0), Rigid (60.0, 20.0)];
   begin
      Kids (2).Align_Self := Adi.CSS_Styles.Flex_End;
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (1).Computed_Pos_Cross, 0.0,
                    "the container's align-items still holds for item 1");
      Assert_Close (Kids (2).Computed_Pos_Cross, 30.0,
                    "align-self moves item 2 to its line's bottom");
   end;

   --  Every align-content value places the lines differently when the
   --  container has cross space to spare.
   Ada.Text_IO.Put_Line ("--- align-content values differ ---");
   declare
      type Placement is array (1 .. 2) of Pixel_Type;

      function Lines_At (AC : Align_Content_Value) return Placement is
         Ctx : constant Flex_Layout_Context :=
           Context (100.0, 200.0, Align_Content => AC);
         Kids : Flex_Child_Info_Array (1 .. 2) := [Rigid (60.0), Rigid (60.0)];
      begin
         Compute_Flex_Layout (Ctx, Kids);
         return [Kids (1).Computed_Pos_Cross, Kids (2).Computed_Pos_Cross];
      end Lines_At;

      Starts  : constant Placement := Lines_At (Adi.CSS_Styles.Flex_Start);
      Ends    : constant Placement := Lines_At (Adi.CSS_Styles.Flex_End);
      Centred : constant Placement := Lines_At (Adi.CSS_Styles.Center);
      Between : constant Placement := Lines_At (Adi.CSS_Styles.Space_Between);
      Around  : constant Placement := Lines_At (Adi.CSS_Styles.Space_Around);
      Stretched : constant Placement := Lines_At (Stretch);
   begin
      Ada.Text_IO.Put_Line
        ("  start" & Starts (1)'Image & Starts (2)'Image
         & "  end" & Ends (1)'Image & Ends (2)'Image
         & "  center" & Centred (1)'Image & Centred (2)'Image
         & "  between" & Between (1)'Image & Between (2)'Image
         & "  around" & Around (1)'Image & Around (2)'Image
         & "  stretch" & Stretched (1)'Image & Stretched (2)'Image);

      Assert_Close (Starts (1), 0.0, "flex-start puts the first line at 0");
      Assert_Close (Ends (2) + 20.0, 200.0,
                    "flex-end ends the last line at the far edge");
      Assert_Close (Centred (1), 80.0, "center leaves equal space either side");
      Assert_Close (Between (1), 0.0, "space-between starts at 0");
      Assert_Close (Between (2), 180.0, "space-between pushes the last line out");
      Assert_Close (Around (1), 40.0, "space-around halves the outer space");
      Assert_Close (Stretched (1), 0.0, "stretch starts at 0");
      Assert_Close (Stretched (2), 100.0, "stretch shares the space into the lines");

      Test_Support.Assert
        (Starts (2) /= Ends (2) and then Ends (2) /= Centred (2)
           and then Centred (2) /= Between (2)
           and then Between (2) /= Around (2)
           and then Around (2) /= Stretched (2),
         "no two align-content values place the lines alike");
   end;

   --  Column wrapping forms columns out of the available height and
   --  runs over horizontally, mirroring the row case.
   Ada.Text_IO.Put_Line ("--- columns wrap on the height ---");
   declare
      Ctx : constant Flex_Layout_Context :=
        Context (200.0, 100.0, Dir => Column,
                 Align_Content => Adi.CSS_Styles.Flex_Start);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (60.0, 30.0), Rigid (60.0, 30.0), Rigid (60.0, 30.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (1).Computed_Pos_Main, 0.0, "column item 1 main");
      Assert_Close (Kids (2).Computed_Pos_Main, 0.0, "column item 2 wrapped");
      Test_Support.Assert
        (Kids (1).Computed_Pos_Cross < Kids (2).Computed_Pos_Cross,
         "a wrapped column starts a new column across");
   end;

   --  Reversed directions place items from the far main edge, and
   --  wrapping is unaffected by that.
   Ada.Text_IO.Put_Line ("--- reversed directions wrap the same way ---");
   declare
      Ctx : constant Flex_Layout_Context :=
        Context (100.0, 200.0, Dir => Row_Reverse,
                 Align_Content => Adi.CSS_Styles.Flex_Start);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (60.0), Rigid (60.0), Rigid (60.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (1).Computed_Pos_Main, 40.0,
                    "row-reverse places the first item against the far edge");
      Test_Support.Assert
        (Kids (1).Computed_Pos_Cross < Kids (3).Computed_Pos_Cross,
         "row-reverse still wraps onto later lines");
   end;

   declare
      Ctx : constant Flex_Layout_Context :=
        Context (200.0, 100.0, Dir => Column_Reverse,
                 Align_Content => Adi.CSS_Styles.Flex_Start);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (60.0, 30.0), Rigid (60.0, 30.0), Rigid (60.0, 30.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Assert_Close (Kids (1).Computed_Pos_Main, 40.0,
                    "column-reverse places the first item at the bottom");
      Test_Support.Assert
        (Kids (1).Computed_Pos_Cross < Kids (2).Computed_Pos_Cross,
         "column-reverse still wraps into later columns");
   end;

   --  Laying out the same items at one width, then another, then back
   --  gives the first answer again: nothing is carried between passes.
   Ada.Text_IO.Put_Line ("--- wrapping is stable across widths ---");
   declare
      function Lines_At (Width : Pixel_Type) return Pixel_Type is
         Ctx : constant Flex_Layout_Context :=
           Context (Width, 300.0, Align_Content => Adi.CSS_Styles.Flex_Start);
         Kids : Flex_Child_Info_Array (1 .. 4) :=
           [Rigid (50.0), Rigid (50.0), Rigid (50.0), Rigid (50.0)];
      begin
         Compute_Flex_Layout (Ctx, Kids);
         return Kids (4).Computed_Pos_Cross;
      end Lines_At;

      Narrow : constant Pixel_Type := Lines_At (100.0);
      Wide   : constant Pixel_Type := Lines_At (200.0);
      Again  : constant Pixel_Type := Lines_At (100.0);
   begin
      Ada.Text_IO.Put_Line
        ("  narrow" & Narrow'Image & "  wide" & Wide'Image
         & "  narrow again" & Again'Image);
      --  Two per line at 100, so the fourth sits on the second line,
      --  one line's depth down.
      Assert_Close (Narrow, 20.0, "four 50px items make two lines at 100");
      Assert_Close (Wide, 0.0, "and one line at 200");
      Assert_Close (Again, Narrow, "returning to the first width repeats it");
   end;

   Test_Support.Finish;
end Flex_Wrap_Test;
