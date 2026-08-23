pragma Ada_2022;

with Adi.Core;           use Adi.Core;
with Adi.CSS_Styles;     use Adi.CSS_Styles;
with Adi.Widget;         use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles;  use Adi.Widget_Styles;
with Test_Support;       use Test_Support;

procedure Block_Layout_Test is

   Eps : constant Pixel_Type := 0.01;

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Message : String) is
   begin
      Assert (abs (Actual - Expected) <= Eps,
              Message & " (got" & Actual'Image
              & ", expected" & Expected'Image & ")");
   end Assert_Close;

   ---------------------------------------------------------------------------
   --  A block container stacks its children; a child that prefers no
   --  height takes none, so it neither covers the container nor pushes
   --  its siblings down.
   ---------------------------------------------------------------------------

   procedure Test_Zero_Height_Children_Take_No_Space is
      Container_H : constant Pixel_Type := 300.0;
      Sized_H     : constant Pixel_Type := 20.0;

      Box    : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Empty1 : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Empty2 : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Sized  : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Sized_Rules : constant Style_Rules :=
        (Height => Set (Size (Px (Float (Sized_H)))), others => <>);
   begin
      Section ("zero-height children in a block container");

      Set_Part_Style (Sized, Main_Part, From (Sized_Rules).Build);

      Add_Child (Box, Empty1);
      Add_Child (Box, Empty2);
      Add_Child (Box, Sized);

      Set_Geometry (Box, (0.0, 0.0, 200.0, Container_H));
      Layout (Box);

      Assert_Close (Get_Preferred_Size (Empty1).Height, 0.0,
                    "an empty label prefers no height");

      Assert_Close (Get_Geometry (Empty1).Height, 0.0,
                    "first empty child keeps its zero height");
      Assert_Close (Get_Geometry (Empty2).Height, 0.0,
                    "second empty child keeps its zero height");

      Assert_Close (Get_Geometry (Empty1).Y, 0.0,
                    "first empty child sits at the content origin");
      Assert_Close (Get_Geometry (Empty2).Y, 0.0,
                    "second empty child sits at the content origin");
      Assert_Close (Get_Geometry (Sized).Y, 0.0,
                    "the sized child follows the empty ones"
                    & " at the content origin");

      Assert_Close (Get_Geometry (Sized).Height, Sized_H,
                    "the sized child keeps its declared height");

      Assert_Close (Get_Geometry (Empty1).Width, 200.0,
                    "a block child spans the content width");
      Assert_Close (Get_Geometry (Sized).Width, 200.0,
                    "a sized block child spans the content width");
   end Test_Zero_Height_Children_Take_No_Space;

   ---------------------------------------------------------------------------
   --  Children with height stack in order, offset by the container's
   --  padding and border.
   ---------------------------------------------------------------------------

   procedure Test_Sized_Children_Stack is
      Pad_Px : constant Pixel_Type := 10.0;
      Kid_H  : constant Pixel_Type := 30.0;

      Box   : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Kid1  : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Kid2  : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Box_Rules : constant Style_Rules :=
        (Padding => Set (CSS_Box (Px (Float (Pad_Px)))), others => <>);
      Kid_Rules : constant Style_Rules :=
        (Height => Set (Size (Px (Float (Kid_H)))), others => <>);
   begin
      Section ("sized children stack in a block container");

      Set_Part_Style (Box, Main_Part, From (Box_Rules).Build);
      Set_Part_Style (Kid1, Main_Part, From (Kid_Rules).Build);
      Set_Part_Style (Kid2, Main_Part, From (Kid_Rules).Build);

      Add_Child (Box, Kid1);
      Add_Child (Box, Kid2);

      Set_Geometry (Box, (0.0, 0.0, 200.0, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Kid1).Y, Pad_Px,
                    "first child starts below the padding");
      Assert_Close (Get_Geometry (Kid2).Y, Pad_Px + Kid_H,
                    "second child follows the first");
      Assert_Close (Get_Geometry (Kid1).Height, Kid_H,
                    "first child keeps its declared height");
      Assert_Close (Get_Geometry (Kid2).Height, Kid_H,
                    "second child keeps its declared height");
      Assert_Close (Get_Geometry (Kid1).Width, 200.0 - 2.0 * Pad_Px,
                    "a block child spans the padded content width");
   end Test_Sized_Children_Stack;

   ---------------------------------------------------------------------------
   --  A declared width is the width the child is given. Nothing centres
   --  what is left over: block centring is margin: auto, which Adi does
   --  not support, so a narrow child sits against the content edge.
   ---------------------------------------------------------------------------

   procedure Test_Declared_Width_Is_Honoured is
      Box_W  : constant Pixel_Type := 200.0;
      Kid_W  : constant Pixel_Type := 120.0;
      Left_M : constant Pixel_Type := 16.0;

      Box     : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Narrow  : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Shifted : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Auto    : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Narrow_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         others => <>);
      Shifted_Rules : constant Style_Rules :=
        (Width  => Set (Size (Px (Float (Kid_W)))),
         Height => Set (Size (Px (20.0))),
         Margin => Set_Margin (CSS_Box (Px (0.0), Px (0.0), Px (0.0),
                                        Px (Float (Left_M)))),
         others => <>);
      Auto_Rules : constant Style_Rules :=
        (Height => Set (Size (Px (20.0))), others => <>);
   begin
      Section ("a declared width in a block container");

      Set_Part_Style (Narrow, Main_Part, From (Narrow_Rules).Build);
      Set_Part_Style (Shifted, Main_Part, From (Shifted_Rules).Build);
      Set_Part_Style (Auto, Main_Part, From (Auto_Rules).Build);

      Add_Child (Box, Narrow);
      Add_Child (Box, Shifted);
      Add_Child (Box, Auto);

      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Narrow).Width, Kid_W,
                    "the child takes the width it declares");
      Assert_Close (Get_Geometry (Narrow).X, 0.0,
                    "and sits at the content origin, not centred");

      Assert_Close (Get_Geometry (Shifted).Width, Kid_W,
                    "a left margin does not shrink a declared width");
      Assert_Close (Get_Geometry (Shifted).X, Left_M,
                    "it moves the child in by the margin");

      Assert_Close (Get_Geometry (Auto).Width, Box_W,
                    "a child without a width still spans the content width");
   end Test_Declared_Width_Is_Honoured;

   ---------------------------------------------------------------------------
   --  A percentage width names a fraction of the container's content
   --  box, the same basis a percentage height uses.
   ---------------------------------------------------------------------------

   procedure Test_Percentage_Width_Resolves_Against_The_Content_Box is
      Pad_Px    : constant Pixel_Type := 10.0;
      Box_W     : constant Pixel_Type := 200.0;
      Content_W : constant Pixel_Type := Box_W - 2.0 * Pad_Px;

      Box  : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Half : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Full : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Box_Rules : constant Style_Rules :=
        (Padding => Set (CSS_Box (Px (Float (Pad_Px)))), others => <>);
      Half_Rules : constant Style_Rules :=
        (Width  => Set (Size (Pct (50.0))),
         Height => Set (Size (Px (20.0))),
         others => <>);
      Full_Rules : constant Style_Rules :=
        (Width  => Set (Size (Pct (100.0))),
         Height => Set (Size (Px (20.0))),
         others => <>);
   begin
      Section ("a percentage width in a block container");

      Set_Part_Style (Box, Main_Part, From (Box_Rules).Build);
      Set_Part_Style (Half, Main_Part, From (Half_Rules).Build);
      Set_Part_Style (Full, Main_Part, From (Full_Rules).Build);

      Add_Child (Box, Half);
      Add_Child (Box, Full);
      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));

      Assert_Close (Get_Preferred_Size (Half).Width, 0.0,
                    "the preferred size leaves a percentage unresolved");

      for Pass in 1 .. 3 loop
         Layout (Box);
         Assert_Close (Get_Geometry (Half).Width, Content_W / 2.0,
                       "pass" & Pass'Image
                       & " takes half of the padded content width");
         Assert_Close (Get_Geometry (Full).Width, Content_W,
                       "pass" & Pass'Image
                       & " fills the padded content width");
      end loop;
   end Test_Percentage_Width_Resolves_Against_The_Content_Box;

   ---------------------------------------------------------------------------
   --  min-width and max-width bound the width the child ends up with,
   --  and a minimum above a maximum wins -- CSS 2.1 10.4.
   ---------------------------------------------------------------------------

   procedure Test_Width_Is_Clamped_By_Its_Limits is
      Box_W : constant Pixel_Type := 200.0;

      Box     : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Capped  : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Floored : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Capped_Auto : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Conflict : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));

      Capped_Rules : constant Style_Rules :=
        (Width     => Set (Size (Px (180.0))),
         Max_Width => Set (Size (Px (100.0))),
         Height    => Set (Size (Px (20.0))),
         others    => <>);
      Floored_Rules : constant Style_Rules :=
        (Width     => Set (Size (Px (40.0))),
         Min_Width => Set (Size (Px (90.0))),
         Height    => Set (Size (Px (20.0))),
         others    => <>);
      Capped_Auto_Rules : constant Style_Rules :=
        (Max_Width => Set (Size (Px (150.0))),
         Height    => Set (Size (Px (20.0))),
         others    => <>);
      Conflict_Rules : constant Style_Rules :=
        (Width     => Set (Size (Px (20.0))),
         Min_Width => Set (Size (Px (140.0))),
         Max_Width => Set (Size (Px (60.0))),
         Height    => Set (Size (Px (20.0))),
         others    => <>);
   begin
      Section ("min-width and max-width bound a block child");

      Set_Part_Style (Capped, Main_Part, From (Capped_Rules).Build);
      Set_Part_Style (Floored, Main_Part, From (Floored_Rules).Build);
      Set_Part_Style (Capped_Auto, Main_Part, From (Capped_Auto_Rules).Build);
      Set_Part_Style (Conflict, Main_Part, From (Conflict_Rules).Build);

      Add_Child (Box, Capped);
      Add_Child (Box, Floored);
      Add_Child (Box, Capped_Auto);
      Add_Child (Box, Conflict);

      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Capped).Width, 100.0,
                    "max-width caps a declared width");
      Assert_Close (Get_Geometry (Floored).Width, 90.0,
                    "min-width raises a declared width");
      Assert_Close (Get_Geometry (Capped_Auto).Width, 150.0,
                    "max-width caps the width an auto child would fill");
      Assert_Close (Get_Geometry (Conflict).Width, 140.0,
                    "a minimum above the maximum wins");
   end Test_Width_Is_Clamped_By_Its_Limits;

   ---------------------------------------------------------------------------
   --  Measurement and placement read the same width. A child whose
   --  height depends on how wide it is -- a wrapping row here -- has to
   --  be measured at the width it will be given, or the container
   --  reserves room for an arrangement that never happens.
   ---------------------------------------------------------------------------

   procedure Test_A_Child_Is_Measured_At_The_Width_It_Gets is
      Box_W  : constant Pixel_Type := 400.0;
      Chip_W : constant Pixel_Type := 60.0;
      Chip_H : constant Pixel_Type := 22.0;
      Chips  : constant Positive := 3;
      Row_W  : constant Pixel_Type := 100.0;

      --  Wide enough for one chip and no more, so the row is as many
      --  lines deep as it has chips.
      Stacked_H : constant Pixel_Type := Chip_H * Pixel_Type (Chips);

      Box : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Strip : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);

      Row_Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Row),
         Flex_Wrap      => Set (Wrap),
         Width          => Set (Size (Px (Float (Row_W)))),
         others         => <>);
      Chip_Rules : constant Style_Rules :=
        (Width       => Set (Size (Px (Float (Chip_W)))),
         Height      => Set (Size (Px (Float (Chip_H)))),
         Flex_Shrink => Set (0.0),
         others      => <>);
   begin
      Section ("a block child is measured at its declared width");

      Set_Part_Style (Strip, Main_Part, From (Row_Rules).Build);
      for K in 1 .. Chips loop
         declare
            Chip : constant Widget_Handle :=
              Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
         begin
            Set_Part_Style (Chip, Main_Part, From (Chip_Rules).Build);
            Add_Child (Strip, Chip);
         end;
      end loop;
      Add_Child (Box, Strip);

      Set_Geometry (Box, (0.0, 0.0, Box_W, 300.0));
      Layout (Box);

      Assert_Close (Get_Geometry (Strip).Width, Row_W,
                    "the row is laid out at its declared width");
      Assert_Close (Get_Geometry (Strip).Height, Stacked_H,
                    "and is as tall as wrapping at that width makes it");

      Assert_Close (Measure_At_Width (Box, Box_W).Height, Stacked_H,
                    "the container measures the row at the same width");
      Assert (Effective_Min_Size_At_Width (Box, Box_W).Height
                >= Stacked_H - Eps,
              "and aggregates its minimum at that width too (got"
              & Effective_Min_Size_At_Width (Box, Box_W).Height'Image & ")");
   end Test_A_Child_Is_Measured_At_The_Width_It_Gets;

   ---------------------------------------------------------------------------
   --  A percentage height names a fraction of the container's content
   --  box. The preferred size has no container to offer, so it measures
   --  the axis as auto and the layout does the resolving -- which is
   --  what keeps the fraction the same however often the layout runs.
   ---------------------------------------------------------------------------

   procedure Test_Percentage_Height_Is_Stable_Across_Passes is
      Box  : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Half : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Half_Rules : constant Style_Rules :=
        (Height => Set (Size (Pct (50.0))), others => <>);
   begin
      Section ("percentage height is stable across layout passes");

      Set_Part_Style (Half, Main_Part, From (Half_Rules).Build);
      Add_Child (Box, Half);
      Set_Geometry (Box, (0.0, 0.0, 200.0, 300.0));

      --  A height the child already carries must not become the basis:
      --  that is what would make each pass shrink the one before it.
      Set_Geometry (Half, (0.0, 0.0, 200.0, 200.0));

      Assert_Close (Get_Preferred_Size (Half).Height, 0.0,
                    "the preferred size leaves a percentage unresolved");

      for Pass in 1 .. 3 loop
         Layout (Box);
         Assert_Close (Get_Geometry (Half).Height, 150.0,
                       "pass" & Pass'Image
                       & " takes half of the container's content height");
      end loop;
   end Test_Percentage_Height_Is_Stable_Across_Passes;

   procedure Test_Full_Percentage_Height_Fills_The_Container is
      Pad_Px : constant Pixel_Type := 10.0;

      Box  : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Full : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Box_Rules : constant Style_Rules :=
        (Padding => Set (CSS_Box (Px (Float (Pad_Px)))), others => <>);
      Full_Rules : constant Style_Rules :=
        (Height => Set (Size (Pct (100.0))), others => <>);
   begin
      Section ("100% height fills a block container");

      Set_Part_Style (Box, Main_Part, From (Box_Rules).Build);
      Set_Part_Style (Full, Main_Part, From (Full_Rules).Build);
      Add_Child (Box, Full);
      Set_Geometry (Box, (0.0, 0.0, 200.0, 300.0));

      for Pass in 1 .. 3 loop
         Layout (Box);
         Assert_Close (Get_Geometry (Full).Height, 300.0 - 2.0 * Pad_Px,
                       "pass" & Pass'Image
                       & " fills the padded content height");
      end loop;
   end Test_Full_Percentage_Height_Fills_The_Container;

   ---------------------------------------------------------------------------
   --  The basis is the container's content height whatever gave the
   --  container that height, a declared one or its own content.
   ---------------------------------------------------------------------------

   procedure Test_Percentage_Height_Under_Content_Sized_Parent is
      Anchor_H : constant Pixel_Type := 40.0;

      Outer : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Mid : constant Widget_Handle :=
        Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle);
      Anchor : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Full : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (""));
      Anchor_Rules : constant Style_Rules :=
        (Height => Set (Size (Px (Float (Anchor_H)))), others => <>);
      Full_Rules : constant Style_Rules :=
        (Height => Set (Size (Pct (100.0))), others => <>);
   begin
      Section ("100% height under a content-sized parent");

      Set_Part_Style (Anchor, Main_Part, From (Anchor_Rules).Build);
      Set_Part_Style (Full, Main_Part, From (Full_Rules).Build);
      Add_Child (Mid, Anchor);
      Add_Child (Mid, Full);
      Add_Child (Outer, Mid);
      Set_Geometry (Outer, (0.0, 0.0, 200.0, 300.0));

      for Pass in 1 .. 3 loop
         Layout (Outer);
         Assert_Close (Get_Geometry (Mid).Height, Anchor_H,
                       "pass" & Pass'Image
                       & ": the middle container takes its content height,"
                       & " which the percentage child does not inflate");
         Assert_Close (Get_Geometry (Full).Height, Anchor_H,
                       "pass" & Pass'Image
                       & ": the percentage resolves against that height");
      end loop;
   end Test_Percentage_Height_Under_Content_Sized_Parent;

begin
   Start_Suite ("Block Layout Test");

   Test_Zero_Height_Children_Take_No_Space;
   Test_Sized_Children_Stack;
   Test_Declared_Width_Is_Honoured;
   Test_Percentage_Width_Resolves_Against_The_Content_Box;
   Test_Width_Is_Clamped_By_Its_Limits;
   Test_A_Child_Is_Measured_At_The_Width_It_Gets;
   Test_Percentage_Height_Is_Stable_Across_Passes;
   Test_Full_Percentage_Height_Fills_The_Container;
   Test_Percentage_Height_Under_Content_Sized_Parent;

   Finish;
end Block_Layout_Test;
