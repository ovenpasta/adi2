--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Unchecked_Deallocation;

package body Adi.Shadow is

   --  The blur's scratch plane, on the heap and released with the block that
   --  declares it, exception or not.
   --
   --  It is Tex_Size ** 2 floats, and Tex_Size grows with the blur: a
   --  hundred-pixel blur wants five megabytes. As a plain local that is an
   --  alloca on the primary stack, so a stylesheet asking for a large blur
   --  would overflow it. Nothing bounds what a stylesheet may ask for.
   type Coverage_Access is access Coverage;
   procedure Free is new Ada.Unchecked_Deallocation
     (Coverage, Coverage_Access);

   type Scratch_Plane (Last : Natural) is
     new Ada.Finalization.Limited_Controlled with record
      Data : Coverage_Access;
   end record;

   overriding procedure Initialize (Plane : in out Scratch_Plane);
   overriding procedure Finalize (Plane : in out Scratch_Plane);

   overriding procedure Initialize (Plane : in out Scratch_Plane) is
   begin
      Plane.Data := new Coverage'(0 .. Plane.Last => 0.0);
   end Initialize;

   overriding procedure Finalize (Plane : in out Scratch_Plane) is
   begin
      Free (Plane.Data);
   end Finalize;

   --  A line's running integral, entry I holding the sum of the line's
   --  first I samples. A box window is then the difference of two entries,
   --  whatever its width.
   --
   --  An entry carries a whole line where the window it is read back as
   --  carries 2 * Blur + 1 samples, so the entries are held to wider
   --  precision: the difference is then as accurate as summing the window
   --  on its own, and the line length cannot erode the result.
   type Running_Sum is array (Natural range <>) of Long_Float;
   type Running_Sum_Access is access Running_Sum;
   procedure Free is new Ada.Unchecked_Deallocation
     (Running_Sum, Running_Sum_Access);

   type Scratch_Line (Last : Natural) is
     new Ada.Finalization.Limited_Controlled with record
      Data : Running_Sum_Access;
   end record;

   overriding procedure Initialize (Line : in out Scratch_Line);
   overriding procedure Finalize (Line : in out Scratch_Line);

   overriding procedure Initialize (Line : in out Scratch_Line) is
   begin
      Line.Data := new Running_Sum'(0 .. Line.Last => 0.0);
   end Initialize;

   overriding procedure Finalize (Line : in out Scratch_Line) is
   begin
      Free (Line.Data);
   end Finalize;

   function Geometry_For (Blur, Radius : Natural) return Geometry is
      --  Three box passes carry the blur 3 * Blur beyond the shape edge.
      Pad : constant Natural := 3 * Blur;
      --  The straight run each edge needs before the blur has finished:
      --  enough for the blur itself, and never less than the corner radius,
      --  or the corners would eat into the middle.
      Run : constant Natural := Natural'Max (Pad, Radius);
   begin
      return (Pad           => Pad,
              Interior_Half => Run + 2,
              Grid_Border   => Pad + Run,
              Tex_Size      => 2 * (Pad + Run) + 4);
   end Geometry_For;

   function Slice_Border (Geom : Geometry; Extent : Float) return Float is
      --  Whole pixels, one held back so the two sides cannot meet.
      Room : constant Float := Float'Floor ((Extent - 1.0) / 2.0);
   begin
      return Float'Max (0.0, Float'Min (Float (Geom.Grid_Border), Room));
   end Slice_Border;

   function Build_Mask (Blur, Radius : Natural) return Coverage is
      G        : constant Geometry := Geometry_For (Blur, Radius);
      Size     : constant Natural := G.Tex_Size;
      Half     : constant Float := Float (G.Interior_Half);
      Centre   : constant Float := Float (Size) / 2.0;
      CR       : constant Float := Float'Min (Float (Radius), Half);
      Span     : constant Long_Float := Long_Float (2 * Blur + 1);

      Plane : Scratch_Plane (Last => Size * Size - 1);

      --  Signed distance to the rounded rect, negative inside.
      function Distance (Px, Py : Float) return Float is
         Dx : constant Float := Float'Max (0.0, abs (Px - Centre) - Half + CR);
         Dy : constant Float := Float'Max (0.0, abs (Py - Centre) - Half + CR);
      begin
         return Sqrt (Dx * Dx + Dy * Dy) - CR;
      end Distance;

   begin
      for Y in 0 .. Size - 1 loop
         for X in 0 .. Size - 1 loop
            Plane.Data (Y * Size + X) :=
              (if Distance (Float (X) + 0.5, Float (Y) + 0.5) <= 0.0
               then 1.0 else 0.0);
         end loop;
      end loop;

      if Blur = 0 then
         return Plane.Data.all;
      end if;

      --  Three box passes approximate a Gaussian. Samples off the edge count
      --  as transparent, which the texture's Pad margin guarantees they are.
      --  The second plane belongs to the passes: a sharp shadow never needs
      --  it, and it is not small.
      declare
         Buffer : Scratch_Plane (Last => Size * Size - 1);
         --  One line's integral, rebuilt by each sweep. A line is the
         --  square root of a plane that has already been allocated, so it
         --  costs nothing beside the two planes.
         Total  : Scratch_Line (Last => Size);

         --  One box pass along the Size samples that begin at Base and lie
         --  Step apart. The window over Blur either side of a sample is the
         --  integral's two ends subtracted, and samples beyond the line are
         --  simply absent from it, so they count as transparent while the
         --  divisor stays the full span.
         procedure Sweep (From, Into : Coverage_Access; Base, Step : Natural)
         is
            Sum : Long_Float := 0.0;
            Lo  : Natural;
            Hi  : Natural;
         begin
            Total.Data (0) := 0.0;
            for I in 0 .. Size - 1 loop
               Sum := Sum + Long_Float (From (Base + I * Step));
               Total.Data (I + 1) := Sum;
            end loop;

            for I in 0 .. Size - 1 loop
               Lo := Integer'Max (0, I - Blur);
               Hi := Integer'Min (Size - 1, I + Blur);
               Into (Base + I * Step) :=
                 Float ((Total.Data (Hi + 1) - Total.Data (Lo)) / Span);
            end loop;
         end Sweep;

      begin
         for Pass in 1 .. 3 loop
            for Y in 0 .. Size - 1 loop
               Sweep (Plane.Data, Buffer.Data, Base => Y * Size, Step => 1);
            end loop;

            for X in 0 .. Size - 1 loop
               Sweep (Buffer.Data, Plane.Data, Base => X, Step => Size);
            end loop;
         end loop;
      end;

      return Plane.Data.all;
   end Build_Mask;

end Adi.Shadow;
