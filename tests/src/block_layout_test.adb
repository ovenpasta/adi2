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
   Test_Percentage_Height_Is_Stable_Across_Passes;
   Test_Full_Percentage_Height_Fills_The_Container;
   Test_Percentage_Height_Under_Content_Sized_Parent;

   Finish;
end Block_Layout_Test;
