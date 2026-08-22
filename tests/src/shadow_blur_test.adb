pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

with Adi.Shadow;
with Test_Support; use Test_Support;

--  Build_Mask blurs by reading each box window off a running integral. What
--  that has to reproduce is a zero-padded box blur: samples beyond the plane
--  count as transparent and the divisor is the whole span, never the number
--  of samples actually in range. Dividing by the count instead agrees in the
--  middle and differs along the borders -- the part of the texture the
--  nine-grid stretches down every side of a widget -- and these catch it.
--
--  Clamping to the edge sample rather than padding is not caught, and cannot
--  be while the geometry holds: Pad is 3 * Blur, and each pass of a window
--  reaching Blur either side erodes that margin by Blur, so every sweep still
--  finds exactly 0.0 at both ends of the line it reads, and a clamp there
--  replicates a zero. The last sweep sits on the limit. A fourth pass, or a
--  smaller Pad, and the two conventions part company with nothing here to
--  notice it.
--
--  These pin the mask, texel for texel, against the same three box passes
--  written out sample by sample.

procedure Shadow_Blur_Test is

   type Coverage_Access is access Adi.Shadow.Coverage;
   procedure Free is new Ada.Unchecked_Deallocation
     (Adi.Shadow.Coverage, Coverage_Access);

   --  The three box passes, each output summing its whole kernel.
   function Reference_Mask (Blur, Radius : Natural) return Coverage_Access is
      G      : constant Adi.Shadow.Geometry :=
        Adi.Shadow.Geometry_For (Blur, Radius);
      Size   : constant Natural := G.Tex_Size;
      Half   : constant Float := Float (G.Interior_Half);
      Centre : constant Float := Float (Size) / 2.0;
      CR     : constant Float := Float'Min (Float (Radius), Half);
      Span   : constant Float := Float (2 * Blur + 1);

      Plane  : constant Coverage_Access :=
        new Adi.Shadow.Coverage'(0 .. Size * Size - 1 => 0.0);
      Buffer : Coverage_Access;

      function Distance (Px, Py : Float) return Float is
         Dx : constant Float := Float'Max (0.0, abs (Px - Centre) - Half + CR);
         Dy : constant Float := Float'Max (0.0, abs (Py - Centre) - Half + CR);
      begin
         return Sqrt (Dx * Dx + Dy * Dy) - CR;
      end Distance;

   begin
      for Y in 0 .. Size - 1 loop
         for X in 0 .. Size - 1 loop
            Plane (Y * Size + X) :=
              (if Distance (Float (X) + 0.5, Float (Y) + 0.5) <= 0.0
               then 1.0 else 0.0);
         end loop;
      end loop;

      if Blur = 0 then
         return Plane;
      end if;

      Buffer := new Adi.Shadow.Coverage'(0 .. Size * Size - 1 => 0.0);

      for Pass in 1 .. 3 loop
         for Y in 0 .. Size - 1 loop
            for X in 0 .. Size - 1 loop
               declare
                  Sum : Float := 0.0;
                  KX  : Integer;
               begin
                  for K in -Blur .. Blur loop
                     KX := X + K;
                     if KX >= 0 and then KX < Size then
                        Sum := Sum + Plane (Y * Size + KX);
                     end if;
                  end loop;
                  Buffer (Y * Size + X) := Sum / Span;
               end;
            end loop;
         end loop;

         for Y in 0 .. Size - 1 loop
            for X in 0 .. Size - 1 loop
               declare
                  Sum : Float := 0.0;
                  KY  : Integer;
               begin
                  for K in -Blur .. Blur loop
                     KY := Y + K;
                     if KY >= 0 and then KY < Size then
                        Sum := Sum + Buffer (KY * Size + X);
                     end if;
                  end loop;
                  Plane (Y * Size + X) := Sum / Span;
               end;
            end loop;
         end loop;
      end loop;

      Free (Buffer);
      return Plane;
   end Reference_Mask;

   --  What the texture actually stores: coverage quantised to the alpha
   --  byte, which is the only difference the renderer can express.
   function Stored_Alpha (C : Float) return Natural is
     (Natural (Float'Min (1.0, Float'Max (0.0, C)) * 255.0));

   --  Largest disagreement over every texel, in coverage and in the alpha
   --  byte the coverage becomes, and how many texels quantise differently.
   procedure Compare
     (Blur, Radius : Natural;
      Max_Diff     : out Float;
      Max_Alpha    : out Natural;
      Alpha_Count  : out Natural)
   is
      Ref  : Coverage_Access := Reference_Mask (Blur, Radius);
      Mask : constant Adi.Shadow.Coverage :=
        Adi.Shadow.Build_Mask (Blur, Radius);
      Step : Natural;
   begin
      Max_Diff := 0.0;
      Max_Alpha := 0;
      Alpha_Count := 0;
      for I in Ref'Range loop
         Max_Diff := Float'Max (Max_Diff, abs (Mask (I) - Ref (I)));
         Step := abs (Stored_Alpha (Mask (I)) - Stored_Alpha (Ref (I)));
         Max_Alpha := Natural'Max (Max_Alpha, Step);
         if Step /= 0 then
            Alpha_Count := Alpha_Count + 1;
         end if;
      end loop;
      Free (Ref);
   end Compare;

   type Case_Spec is record
      Blur   : Natural;
      Radius : Natural;
   end record;

   --  Blur off; the smallest blurs, where a window is barely wider than a
   --  texel; radii past three times the blur, so the geometry's straight run
   --  comes from the corner rather than the blur; and the dialog panel's own
   --  48 px blur over a 12 px radius.
   Cases : constant array (Positive range <>) of Case_Spec :=
     [(0, 0), (0, 12),
      (1, 0), (1, 1), (2, 3), (3, 2),
      (1, 16), (2, 24), (4, 40),
      (8, 8), (12, 4),
      (48, 12)];

   --  One step of the alpha byte the mask ends up in is 1 / 255, about
   --  0.0039. A tenth of a step is far too small to move a rendered pixel,
   --  and leaves room for the difference to grow with the plane rather than
   --  pinning today's arithmetic.
   Tolerance : constant Float := 1.0 / 2550.0;

   Worst : Float := 0.0;

begin
   Start_Suite ("Shadow blur test");

   Section ("mask against the direct box passes");

   for C of Cases loop
      declare
         Diff  : Float;
         Alpha : Natural;
         Count : Natural;
         Label : constant String :=
           "blur" & Natural'Image (C.Blur)
           & " radius" & Natural'Image (C.Radius);
      begin
         Compare (C.Blur, C.Radius, Diff, Alpha, Count);
         Worst := Float'Max (Worst, Diff);

         Ada.Text_IO.Put_Line
           ("  " & Label
            & ": max coverage difference " & Float'Image (Diff)
            & ", alpha off by" & Natural'Image (Alpha)
            & " on" & Natural'Image (Count) & " texels");

         Assert (Diff < Tolerance,
                 "Mask should match the direct box passes at " & Label);

         --  Both forms carry their own rounding, so a texel whose coverage
         --  lands on a quantisation boundary may take either neighbouring
         --  byte. A difference this far under one step can move it no
         --  further than that.
         Assert (Alpha <= 1,
                 "Stored alpha should be within one step at " & Label);
      end;
   end loop;

   Ada.Text_IO.Put_Line
     ("  worst over all cases:" & Float'Image (Worst)
      & " (tolerance" & Float'Image (Tolerance) & ")");

   Finish;
end Shadow_Blur_Test;
