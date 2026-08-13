--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Box-shadow texture geometry and mask.
--
--  A shadow is drawn from a small cached texture stretched as a nine-grid,
--  so the texture's middle is what covers the widget's interior. That middle
--  has to be the fully developed part of the blur: the blur must have run
--  its course before the slice line, or the whole shadow renders lighter
--  than asked for rather than only its fringe. Generation and slicing
--  therefore share one geometry, computed here.

package Adi.Shadow is

   --  Pad           distance the blur carries beyond the shape edge, so the
   --                texture's transparent margin
   --  Interior_Half half-extent of the opaque rounded rect before blurring,
   --                large enough that its centre survives the blur intact
   --  Grid_Border   nine-grid edge: texture edge to the developed middle
   --  Tex_Size      square texture side, a 4 px middle plus both borders
   type Geometry is record
      Pad           : Natural;
      Interior_Half : Natural;
      Grid_Border   : Natural;
      Tex_Size      : Natural;
   end record;

   function Geometry_For (Blur, Radius : Natural) return Geometry
     with Post =>
       Geometry_For'Result.Tex_Size
         = 2 * Geometry_For'Result.Grid_Border + 4
       and then Geometry_For'Result.Interior_Half
         = Geometry_For'Result.Grid_Border - Geometry_For'Result.Pad + 2;

   --  Nine-grid border to slice with for a destination of this extent.
   --
   --  SDL draws the corner quads at the border size it is given, so two
   --  borders that meet cover the line between them twice and blend it
   --  twice, leaving a dark seam. Whole pixels with at least one left over
   --  keep the side quads apart; the corners keep their size, so the blur
   --  reaches as far on a short widget as on a tall one.
   function Slice_Border (Geom : Geometry; Extent : Float) return Float
     with Post => Slice_Border'Result >= 0.0
       and then 2.0 * Slice_Border'Result < Float'Max (1.0, Extent);

   --  Coverage per texel, row-major over Tex_Size ** 2, in 0.0 .. 1.0.
   type Coverage is array (Natural range <>) of Float;

   --  The rounded rect of Geometry_For (Blur, Radius), blurred by three box
   --  passes. Blur = 0 returns the unblurred mask.
   function Build_Mask (Blur, Radius : Natural) return Coverage
     with Post => Build_Mask'Result'Length
       = Geometry_For (Blur, Radius).Tex_Size ** 2;

end Adi.Shadow;
