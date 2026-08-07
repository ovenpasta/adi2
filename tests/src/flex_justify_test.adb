pragma Ada_2022;

with Adi.Core;          use Adi.Core;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Layout_Util;   use Adi.Layout_Util;

with Ada.Text_IO;
with Test_Support;

--  justify-content: where the leftover main-axis space goes, on a line
--  at a time. Every value is pinned at exact positions, since five of
--  the six differ from flex-start only by arithmetic.
procedure Flex_Justify_Test is
   Eps : constant Pixel_Type := 0.001;

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Msg : String) is
   begin
      Test_Support.Assert
        (abs (Actual - Expected) <= Eps,
         Msg & " actual=" & Actual'Image & " expected=" & Expected'Image);
   end Assert_Close;

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
      Justify       : Justify_Content_Value;
      Dir           : Flex_Direction_Value := Row;
      Wrap          : Flex_Wrap_Value      := No_Wrap;
      Main_Gap      : Pixel_Type           := 0.0)
      return Flex_Layout_Context
   is ((Container       => (0.0, 0.0, Width, Height),
        Direction       => Dir,
        Wrap            => Wrap,
        Justify_Content => Justify,
        Align_Items     => Adi.CSS_Styles.Flex_Start,
        Align_Content   => Adi.CSS_Styles.Flex_Start,
        Main_Gap        => Main_Gap,
        Cross_Gap       => 0.0));

   --  Three 40px items in a 200px line: 80 of free space to place.
   type Triple is array (1 .. 3) of Pixel_Type;

   function Places
     (Justify  : Justify_Content_Value;
      Dir      : Flex_Direction_Value := Row;
      Main_Gap : Pixel_Type := 0.0;
      Width    : Pixel_Type := 200.0) return Triple
   is
      Ctx : constant Flex_Layout_Context :=
        Context (Width, 200.0, Justify, Dir, Main_Gap => Main_Gap);
      Kids : Flex_Child_Info_Array (1 .. 3) :=
        [Rigid (40.0), Rigid (40.0), Rigid (40.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      return [Kids (1).Computed_Pos_Main,
              Kids (2).Computed_Pos_Main,
              Kids (3).Computed_Pos_Main];
   end Places;

begin
   Test_Support.Start_Suite ("flex_justify_test");

   --  Three 40px items, 200px line, 80 free.
   Ada.Text_IO.Put_Line ("--- every value places the line differently ---");
   declare
      Start_P   : constant Triple := Places (Flex_Start);
      End_P     : constant Triple := Places (Flex_End);
      Center_P  : constant Triple := Places (Center);
      Between_P : constant Triple := Places (Space_Between);
      Around_P  : constant Triple := Places (Space_Around);
      Evenly_P  : constant Triple := Places (Space_Evenly);
   begin
      Ada.Text_IO.Put_Line
        ("  start" & Start_P (1)'Image & Start_P (2)'Image & Start_P (3)'Image
         & "  end" & End_P (1)'Image & End_P (2)'Image & End_P (3)'Image
         & "  center" & Center_P (1)'Image & Center_P (2)'Image
         & Center_P (3)'Image);
      Ada.Text_IO.Put_Line
        ("  between" & Between_P (1)'Image & Between_P (2)'Image
         & Between_P (3)'Image
         & "  around" & Around_P (1)'Image & Around_P (2)'Image
         & Around_P (3)'Image
         & "  evenly" & Evenly_P (1)'Image & Evenly_P (2)'Image
         & Evenly_P (3)'Image);

      Assert_Close (Start_P (1), 0.0,   "flex-start first");
      Assert_Close (Start_P (2), 40.0,  "flex-start second");
      Assert_Close (Start_P (3), 80.0,  "flex-start third");

      Assert_Close (End_P (1), 80.0,    "flex-end first");
      Assert_Close (End_P (2), 120.0,   "flex-end second");
      Assert_Close (End_P (3), 160.0,   "flex-end third");

      Assert_Close (Center_P (1), 40.0, "center first");
      Assert_Close (Center_P (2), 80.0, "center second");
      Assert_Close (Center_P (3), 120.0, "center third");

      --  80 free over two gaps: 40 each, outer edges flush.
      Assert_Close (Between_P (1), 0.0,   "space-between first is flush");
      Assert_Close (Between_P (2), 80.0,  "space-between second");
      Assert_Close (Between_P (3), 160.0, "space-between third is flush");

      --  80 over three items: 26.667 each, half of it at each end.
      Assert_Close (Around_P (1), 80.0 / 6.0, "space-around first");
      --  13.333 + 40 item + 26.667 share.
      Assert_Close (Around_P (2), 80.0, "space-around second");
      Assert_Close (Around_P (3), 200.0 - 40.0 - 80.0 / 6.0,
                    "space-around third mirrors the first");

      --  80 over four gaps: 20 each, including both ends.
      Assert_Close (Evenly_P (1), 20.0,  "space-evenly first");
      Assert_Close (Evenly_P (2), 80.0,  "space-evenly second");
      Assert_Close (Evenly_P (3), 140.0, "space-evenly third");
   end;

   --  A single item has no gaps to fill, so the distributing values fall
   --  back to placing that one item and nothing else.
   Ada.Text_IO.Put_Line ("--- a single item has nothing to distribute ---");
   declare
      function Lone (Justify : Justify_Content_Value) return Pixel_Type is
         Ctx : constant Flex_Layout_Context := Context (200.0, 100.0, Justify);
         Kids : Flex_Child_Info_Array (1 .. 1) := [Rigid (40.0)];
      begin
         Compute_Flex_Layout (Ctx, Kids);
         return Kids (1).Computed_Pos_Main;
      end Lone;
   begin
      Ada.Text_IO.Put_Line
        ("  start" & Lone (Flex_Start)'Image
         & " end" & Lone (Flex_End)'Image
         & " center" & Lone (Center)'Image
         & " between" & Lone (Space_Between)'Image
         & " around" & Lone (Space_Around)'Image
         & " evenly" & Lone (Space_Evenly)'Image);

      Assert_Close (Lone (Flex_Start), 0.0, "lone flex-start");
      Assert_Close (Lone (Flex_End), 160.0, "lone flex-end");
      Assert_Close (Lone (Center), 80.0, "lone center");
      --  Nothing between one item and itself, so it stays at the start.
      Assert_Close (Lone (Space_Between), 0.0, "lone space-between");
      --  One item's share, halved at each side: centred.
      Assert_Close (Lone (Space_Around), 80.0, "lone space-around");
      --  160 free split into two equal gaps: also centred.
      Assert_Close (Lone (Space_Evenly), 80.0, "lone space-evenly");
   end;

   --  Reversed directions place the first item against the far end, and
   --  justify-content measures its space from there.
   Ada.Text_IO.Put_Line ("--- reversed directions justify from the far end ---");
   declare
      Rev_Start : constant Triple := Places (Flex_Start, Row_Reverse);
      Rev_End   : constant Triple := Places (Flex_End, Row_Reverse);
      Col_Start : constant Triple := Places (Flex_Start, Adi.CSS_Styles.Column);
      Col_Rev   : constant Triple := Places (Flex_Start, Column_Reverse);
   begin
      Ada.Text_IO.Put_Line
        ("  row-reverse start" & Rev_Start (1)'Image & Rev_Start (3)'Image
         & "  end" & Rev_End (1)'Image & Rev_End (3)'Image
         & "  column start" & Col_Start (1)'Image
         & "  column-reverse start" & Col_Rev (1)'Image);

      Assert_Close (Rev_Start (1), 160.0, "row-reverse starts at the far end");
      Assert_Close (Rev_Start (3), 80.0,  "and runs backwards");
      Assert_Close (Rev_End (1), 80.0,    "row-reverse flex-end");
      Assert_Close (Rev_End (3), 0.0,     "reaches the near edge");
      Assert_Close (Col_Start (1), 0.0,   "a column starts at the top");
      Assert_Close (Col_Rev (1), 160.0,   "column-reverse starts at the bottom");
   end;

   --  Gaps are reserved before the leftover space is shared, so the two
   --  do not compete for the same pixels.
   Ada.Text_IO.Put_Line ("--- gaps are taken out before distribution ---");
   declare
      Gapped : constant Triple := Places (Space_Between, Main_Gap => 10.0);
      Centred : constant Triple := Places (Center, Main_Gap => 10.0);
   begin
      Ada.Text_IO.Put_Line
        ("  between+gap" & Gapped (1)'Image & Gapped (2)'Image
         & Gapped (3)'Image
         & "  center+gap" & Centred (1)'Image & Centred (2)'Image
         & Centred (3)'Image);

      --  200 - 120 items - 20 gaps = 60 free, 30 per gap, on top of the
      --  10px gap itself.
      Assert_Close (Gapped (1), 0.0,   "space-between with a gap: first");
      Assert_Close (Gapped (2), 80.0,  "second clears item, gap and share");
      Assert_Close (Gapped (3), 160.0, "third still ends flush");

      --  60 free, halved: 30 before the first item.
      Assert_Close (Centred (1), 30.0, "center with a gap: first");
      Assert_Close (Centred (2), 80.0, "second");
      Assert_Close (Centred (3), 130.0, "third");
   end;

   --  An overflowing line keeps the edge it was aligned to: flex-end
   --  stays flush with the end and spills off the start, center spills
   --  equally at both ends. The distributing values have nothing to
   --  distribute and fall back to the start, never folding items back
   --  over one another.
   Ada.Text_IO.Put_Line ("--- negative free space keeps the aligned edge ---");
   declare
      --  Three 40px items in 90px: 30 of overflow.
      function Overrun (Justify : Justify_Content_Value) return Triple is
        (Places (Justify, Width => 90.0));
   begin
      for J in Justify_Content_Value loop
         declare
            P : constant Triple := Overrun (J);
         begin
            Ada.Text_IO.Put_Line
              ("  " & J'Image & P (1)'Image & P (2)'Image & P (3)'Image);
            Test_Support.Assert
              (P (2) - P (1) >= 40.0 - Eps
                 and then P (3) - P (2) >= 40.0 - Eps,
               "items do not overlap under " & J'Image);
         end;
      end loop;

      Assert_Close (Overrun (Flex_Start) (1), 0.0, "overflowing flex-start");
      Assert_Close (Overrun (Flex_Start) (3), 80.0, "runs past the end");

      --  Flush with the end edge: 90 - 120 = -30.
      Assert_Close (Overrun (Flex_End) (1), -30.0, "overflowing flex-end");
      Assert_Close (Overrun (Flex_End) (2), 10.0, "second");
      Assert_Close (Overrun (Flex_End) (3), 50.0, "last ends flush at 90");

      --  Half the overflow at each end.
      Assert_Close (Overrun (Center) (1), -15.0, "overflowing center");
      Assert_Close (Overrun (Center) (2), 25.0, "second");
      Assert_Close (Overrun (Center) (3), 65.0, "third");

      --  Nothing to share out, so these fall back to the start rather
      --  than spacing items on top of each other.
      Assert_Close (Overrun (Space_Between) (1), 0.0, "overflowing between");
      Assert_Close (Overrun (Space_Around) (1), 0.0, "overflowing around");
      Assert_Close (Overrun (Space_Evenly) (1), 0.0, "overflowing evenly");
   end;

   --  Reversed placement runs its own arithmetic, so each distributing
   --  value is pinned there too: they mirror the forward positions.
   Ada.Text_IO.Put_Line ("--- reversed distributes as a mirror image ---");
   declare
      Rev_Center  : constant Triple := Places (Center, Row_Reverse);
      Rev_Between : constant Triple := Places (Space_Between, Row_Reverse);
      Rev_Around  : constant Triple := Places (Space_Around, Row_Reverse);
      Rev_Evenly  : constant Triple := Places (Space_Evenly, Row_Reverse);
   begin
      Ada.Text_IO.Put_Line
        ("  center" & Rev_Center (1)'Image & Rev_Center (3)'Image
         & "  between" & Rev_Between (1)'Image & Rev_Between (3)'Image
         & "  around" & Rev_Around (1)'Image & Rev_Around (3)'Image
         & "  evenly" & Rev_Evenly (1)'Image & Rev_Evenly (3)'Image);

      Assert_Close (Rev_Center (1), 120.0, "reversed center first");
      Assert_Close (Rev_Center (3), 40.0,  "reversed center third");

      Assert_Close (Rev_Between (1), 160.0, "reversed between is flush");
      Assert_Close (Rev_Between (2), 80.0,  "reversed between second");
      Assert_Close (Rev_Between (3), 0.0,   "and reaches the near edge");

      Assert_Close (Rev_Around (1), 200.0 - 40.0 - 80.0 / 6.0,
                    "reversed around first");
      Assert_Close (Rev_Around (2), 80.0, "reversed around second");
      Assert_Close (Rev_Around (3), 80.0 / 6.0, "reversed around third");

      Assert_Close (Rev_Evenly (1), 140.0, "reversed evenly first");
      Assert_Close (Rev_Evenly (2), 80.0,  "reversed evenly second");
      Assert_Close (Rev_Evenly (3), 20.0,  "reversed evenly third");
   end;

   --  Each line justifies on its own, so lines holding different numbers
   --  of items get different spacing from the same value.
   Ada.Text_IO.Put_Line ("--- wrapped lines justify independently ---");
   declare
      Ctx : constant Flex_Layout_Context :=
        Context (200.0, 200.0, Space_Between, Wrap => Adi.CSS_Styles.Wrap);
      --  Four 60px items: three fit the 200px line, the fourth wraps.
      Kids : Flex_Child_Info_Array (1 .. 4) :=
        [Rigid (60.0), Rigid (60.0), Rigid (60.0), Rigid (60.0)];
   begin
      Compute_Flex_Layout (Ctx, Kids);
      Ada.Text_IO.Put_Line
        ("  line 1" & Kids (1).Computed_Pos_Main'Image
         & Kids (2).Computed_Pos_Main'Image & Kids (3).Computed_Pos_Main'Image
         & "  line 2" & Kids (4).Computed_Pos_Main'Image);

      --  Line one: 20 free over two gaps.
      Assert_Close (Kids (1).Computed_Pos_Main, 0.0, "line 1 first");
      Assert_Close (Kids (2).Computed_Pos_Main, 70.0, "line 1 second");
      Assert_Close (Kids (3).Computed_Pos_Main, 140.0, "line 1 third");
      --  Line two holds one item, so space-between leaves it at the start.
      Assert_Close (Kids (4).Computed_Pos_Main, 0.0,
                    "line 2 has nothing to space and stays at the start");
   end;

   Test_Support.Finish;
end Flex_Justify_Test;
