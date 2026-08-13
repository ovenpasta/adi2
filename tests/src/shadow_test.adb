pragma Ada_2022;

with Adi.Shadow;
with Test_Support; use Test_Support;

--  A box-shadow is drawn from a cached texture stretched as a nine-grid, so
--  the texture's middle covers the widget's whole interior. If the blur has
--  not finished developing by the time that middle is sliced out, every
--  shadow renders lighter than it was asked for -- not just its fringe.
--  These pin the developed middle at full coverage across blur radii.

procedure Shadow_Test is

   --  What the texture actually stores: coverage quantised to the alpha
   --  byte, which is the only difference the renderer can express.
   function Stored_Alpha (C : Float) return Natural is
     (Natural (Float'Min (1.0, Float'Max (0.0, C)) * 255.0));

   --  Alpha at the texture centre: the texel the nine-grid stretches across
   --  the whole widget interior.
   function Centre_Alpha (Blur, Radius : Natural) return Natural is
      G    : constant Adi.Shadow.Geometry :=
        Adi.Shadow.Geometry_For (Blur, Radius);
      Mask : constant Adi.Shadow.Coverage :=
        Adi.Shadow.Build_Mask (Blur, Radius);
      Mid  : constant Natural := G.Tex_Size / 2;
   begin
      return Stored_Alpha (Mask (Mid * G.Tex_Size + Mid));
   end Centre_Alpha;

   --  Dimmest texel anywhere in the stretched middle, so a centre that
   --  happens to be opaque cannot hide a slice that is not.
   function Dimmest_Middle_Alpha (Blur, Radius : Natural) return Natural is
      G      : constant Adi.Shadow.Geometry :=
        Adi.Shadow.Geometry_For (Blur, Radius);
      Mask   : constant Adi.Shadow.Coverage :=
        Adi.Shadow.Build_Mask (Blur, Radius);
      Lowest : Natural := 255;
   begin
      for Y in G.Grid_Border .. G.Tex_Size - G.Grid_Border - 1 loop
         for X in G.Grid_Border .. G.Tex_Size - G.Grid_Border - 1 loop
            Lowest := Natural'Min
              (Lowest, Stored_Alpha (Mask (Y * G.Tex_Size + X)));
         end loop;
      end loop;
      return Lowest;
   end Dimmest_Middle_Alpha;

   --  One alpha unit short of opaque. The blur's tail never quite reaches
   --  1.0, and 254/255 is the worst any blur/radius pair gives; the sizing
   --  bug this pins gave 132.
   Opaque_Enough : constant Natural := 254;

begin
   Start_Suite ("Shadow test");

   --  Generation and slicing read one geometry, so they cannot disagree
   --  about where the developed middle starts.
   for Blur in 0 .. 12 loop
      for Radius in 0 .. 12 loop
         declare
            G : constant Adi.Shadow.Geometry :=
              Adi.Shadow.Geometry_For (Blur, Radius);
         begin
            Assert (G.Pad = 3 * Blur,
                    "Pad should carry the three box passes");
            Assert (G.Grid_Border = G.Pad + Natural'Max (G.Pad, Radius),
                    "Grid border should clear the blur and the corner");
            Assert (G.Tex_Size = 2 * G.Grid_Border + 4,
                    "Texture should be both borders plus a 4px middle");
            Assert (G.Interior_Half = G.Grid_Border - G.Pad + 2,
                    "Interior half-extent should reach the middle");
            Assert (Adi.Shadow.Build_Mask (Blur, Radius)'Length
                      = G.Tex_Size ** 2,
                    "Mask should cover the whole texture");
         end;
      end loop;
   end loop;

   --  The regression itself. A shadow's middle is opaque with no blur and
   --  has to stay opaque once blurred, or the stretched interior dilutes
   --  the entire shadow rather than just its fringe. Sizing the pre-blur
   --  rect from the corner radius alone left blur 8 at 132 here -- barely
   --  half the shadow that was asked for.
   Assert (Centre_Alpha (0, 8) = 255,
           "Unblurred shadow centre should be opaque");
   Assert (Centre_Alpha (8, 8) >= Opaque_Enough,
           "Blurred shadow centre should stay opaque");
   Assert (Dimmest_Middle_Alpha (8, 8) >= Opaque_Enough,
           "Every texel of the stretched middle should stay opaque");

   for Blur in 0 .. 16 loop
      for Radius in 0 .. 16 loop
         Assert (Dimmest_Middle_Alpha (Blur, Radius) >= Opaque_Enough,
                 "Middle should stay opaque at blur"
                 & Natural'Image (Blur) & " radius"
                 & Natural'Image (Radius));
      end loop;
   end loop;

   --  A blur past the everyday range still develops its middle. This is
   --  functional coverage only: at this size the mask's planes are well
   --  under a megabyte, so it says nothing about where they are allocated.
   --  Stack placement is a property of the compiled frame, not of a run --
   --  read it from the .su files, or exhaust the stack deliberately, which
   --  would be platform-specific.
   Assert (Dimmest_Middle_Alpha (24, 8) >= Opaque_Enough,
           "A large blur should still develop its middle");

   --  Blur only fades outward: the texture's outermost ring stays clear so
   --  the shadow has somewhere to fall off to.
   declare
      G : constant Adi.Shadow.Geometry := Adi.Shadow.Geometry_For (8, 8);
      Mask : constant Adi.Shadow.Coverage := Adi.Shadow.Build_Mask (8, 8);
   begin
      Assert (Mask (0) = 0.0, "Texture corner should be clear");
      Assert (Mask (G.Tex_Size / 2) < 0.5,
              "Texture edge should be past the shadow's falloff");
   end;

   Finish;
end Shadow_Test;
