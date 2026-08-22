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

begin
   Start_Suite ("Block Layout Test");

   Test_Zero_Height_Children_Take_No_Space;
   Test_Sized_Children_Stack;

   Finish;
end Block_Layout_Test;
