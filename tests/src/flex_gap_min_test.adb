pragma Ada_2022;

with Adi.Core;           use Adi.Core;
with Adi.CSS_Styles;     use Adi.CSS_Styles;
with Adi.Widget;         use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles;  use Adi.Widget_Styles;
with Test_Support;       use Test_Support;

--  A flex item's minimum bounds the size it ends up at. It is not part of
--  the size it starts from: an item that grows takes its share on top of
--  its flex base, and two items with the same base and the same grow
--  factor take the same share whatever their minimums are.
--  CSS Flexbox 9.7 "Resolving Flexible Lengths".

procedure Flex_Gap_Min_Test is

   Eps : constant Pixel_Type := 0.01;

   type Handle_Array is array (Positive range <>) of Widget_Handle;

   Inner_Gap  : constant Float := 6.0;
   Inner_Kids : constant Positive := 3;
   Inner_Gaps : constant Pixel_Type :=
     Pixel_Type (Inner_Gap) * Pixel_Type (Inner_Kids - 1);

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Message : String) is
   begin
      Assert (abs (Actual - Expected) <= Eps,
              Message & " (got" & Actual'Image
              & ", expected" & Expected'Image & ")");
   end Assert_Close;

   function New_Box return Widget_Handle is
     (Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle));

   function New_Label return Widget_Handle is
     (Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle ("")));

   Row_Rules : constant Style_Rules :=
     (Display        => Set (Flex),
      Flex_Direction => Set (Row),
      others         => <>);

   --  The flex item shape the gallery uses for an even split: no basis to
   --  start from, an equal share of what is left, and no floor of its own.
   Even_Share_Rules : constant Style_Rules :=
     (Flex_Basis => Set (Basis (Px (0.0))),
      Flex_Grow  => Set (1.0),
      Min_Width  => Set (Size (Px (0.0))),
      others     => <>);

   --  A gapped row of children that demand nothing. Its content minimum
   --  is the gaps alone.
   function Gapped_Row return Widget_Handle is
      Strip : constant Widget_Handle := New_Box;
      Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Row),
         Gap            => Set (Gap (Px (Inner_Gap))),
         others         => <>);
   begin
      Set_Part_Style (Strip, Main_Part, From (Rules).Build);
      for K in 1 .. Inner_Kids loop
         Add_Child (Strip, New_Label);
      end loop;
      return Strip;
   end Gapped_Row;

   --  A row of two grown items, the first holding whatever Content says.
   procedure Grow_Two
     (Outer_W : Pixel_Type;
      Rules   : Style_Rules;
      Content : Widget_Handle;
      Left_W  : out Pixel_Type;
      Right_W : out Pixel_Type)
   is
      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Rules).Build);
      Set_Part_Style (Right, Main_Part, From (Rules).Build);

      Add_Child (Left, Content);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Left_W := Get_Geometry (Left).Width;
      Right_W := Get_Geometry (Right).Width;
   end Grow_Two;

   ---------------------------------------------------------------------------
   --  The case the gallery hit: the item holding a gapped row took the
   --  gaps as a head start and then still took an equal share of the rest.
   ---------------------------------------------------------------------------

   procedure Test_Gapped_Content_Does_Not_Skew_The_Split is
      Outer_W : constant Pixel_Type := 551.0;
      Half    : constant Pixel_Type := Outer_W / 2.0;
      Left_W, Right_W : Pixel_Type;
   begin
      Section ("a gapped inner row does not skew an even flex split");

      Grow_Two (Outer_W, Even_Share_Rules, Gapped_Row, Left_W, Right_W);

      Assert_Close (Left_W, Half,
                    "the item holding the gapped row takes half");
      Assert_Close (Right_W, Half,
                    "its bare sibling takes the other half");
      Assert_Close (Left_W + Right_W, Outer_W,
                    "the two together fill the row");
   end Test_Gapped_Content_Does_Not_Skew_The_Split;

   ---------------------------------------------------------------------------
   --  The same skew without a gap anywhere: a declared minimum below the
   --  space on offer must not add to the item's share either.
   ---------------------------------------------------------------------------

   procedure Test_A_Minimum_Below_The_Share_Does_Not_Add is
      Outer_W : constant Pixel_Type := 200.0;
      Half    : constant Pixel_Type := Outer_W / 2.0;

      Floored : constant Style_Rules :=
        (Flex_Basis => Set (Basis (Px (0.0))),
         Flex_Grow  => Set (1.0),
         Min_Width  => Set (Size (Px (30.0))),
         others     => <>);

      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Section ("a minimum clamps an item, it does not enlarge it");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Floored).Build);
      Set_Part_Style (Right, Main_Part, From (Even_Share_Rules).Build);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Left).Width, Half,
                    "the floored item takes half, its floor unreached");
      Assert_Close (Get_Geometry (Right).Width, Half,
                    "its sibling takes the other half");
   end Test_A_Minimum_Below_The_Share_Does_Not_Add;

   ---------------------------------------------------------------------------
   --  Squeezed past the floor, the floor holds and the sibling gives up
   --  the difference.
   ---------------------------------------------------------------------------

   procedure Test_A_Minimum_Above_The_Share_Holds is
      Outer_W : constant Pixel_Type := 40.0;
      Floor_W : constant Pixel_Type := 30.0;

      Floored : constant Style_Rules :=
        (Flex_Basis => Set (Basis (Px (0.0))),
         Flex_Grow  => Set (1.0),
         Min_Width  => Set (Size (Px (Float (Floor_W)))),
         others     => <>);

      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Section ("a minimum above the share still holds");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Floored).Build);
      Set_Part_Style (Right, Main_Part, From (Even_Share_Rules).Build);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Left).Width, Floor_W,
                    "the floored item stops at its floor");
      Assert_Close (Get_Geometry (Right).Width, Outer_W - Floor_W,
                    "its sibling takes what is left");
   end Test_A_Minimum_Above_The_Share_Holds;

   ---------------------------------------------------------------------------
   --  A gapped row is content like any other: with min-width left alone,
   --  the automatic minimum keeps room for its gaps.
   ---------------------------------------------------------------------------

   procedure Test_Automatic_Minimum_Still_Holds_The_Gaps is
      Outer_W : constant Pixel_Type := 20.0;

      Auto_Min_Rules : constant Style_Rules :=
        (Flex_Basis => Set (Basis (Px (0.0))),
         Flex_Grow  => Set (1.0),
         others     => <>);

      Left_W, Right_W : Pixel_Type;
   begin
      Section ("the automatic minimum keeps room for the gaps");

      Grow_Two (Outer_W, Auto_Min_Rules, Gapped_Row, Left_W, Right_W);

      Assert_Close (Left_W, Inner_Gaps,
                    "squeezed, the item stops at the inner row's gaps");
      Assert_Close (Right_W, Outer_W - Inner_Gaps,
                    "its sibling takes what is left");
   end Test_Automatic_Minimum_Still_Holds_The_Gaps;

   ---------------------------------------------------------------------------
   --  The gaps stay in what the row's content needs; only the share is
   --  free of them.
   ---------------------------------------------------------------------------

   procedure Test_Gaps_Count_In_The_Content_Minimum is
      Strip : constant Widget_Handle := New_Box;
      Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Row),
         Gap            => Set (Gap (Px (Inner_Gap))),
         others         => <>);
      Kid_Rules : constant Style_Rules :=
        (Min_Width => Set (Size (Px (10.0))), others => <>);
      Kids : constant Pixel_Type := 10.0 * Pixel_Type (Inner_Kids);
   begin
      Section ("gaps count towards the content minimum");

      Set_Part_Style (Strip, Main_Part, From (Rules).Build);
      for K in 1 .. Inner_Kids loop
         declare
            Kid : constant Widget_Handle := New_Label;
         begin
            Set_Part_Style (Kid, Main_Part, From (Kid_Rules).Build);
            Add_Child (Strip, Kid);
         end;
      end loop;

      Assert_Close
        (Get_Content_Min_Size (Strip).Width, Kids + Inner_Gaps,
         "the content minimum spans the children and the gaps between");
   end Test_Gaps_Count_In_The_Content_Minimum;

   ---------------------------------------------------------------------------
   --  Both siblings alike, and three-way, to catch a skew a single pair
   --  could hide.
   ---------------------------------------------------------------------------

   procedure Test_Matching_Siblings_Split_Evenly is
      Outer_W : constant Pixel_Type := 551.0;
      Half    : constant Pixel_Type := Outer_W / 2.0;

      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Section ("matching siblings split evenly");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Even_Share_Rules).Build);
      Set_Part_Style (Right, Main_Part, From (Even_Share_Rules).Build);

      Add_Child (Left, Gapped_Row);
      Add_Child (Right, Gapped_Row);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Left).Width, Half,
                    "the first item takes half");
      Assert_Close (Get_Geometry (Right).Width, Half,
                    "the second item takes half");
   end Test_Matching_Siblings_Split_Evenly;

   procedure Test_Three_Way_Split is
      Outer_W : constant Pixel_Type := 539.0;
      Third   : constant Pixel_Type := Outer_W / 3.0;

      Outer : constant Widget_Handle := New_Box;
      A     : constant Widget_Handle := New_Box;
      B     : constant Widget_Handle := New_Box;
      C     : constant Widget_Handle := New_Box;
   begin
      Section ("a gapped row among three even siblings");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      for Item of Handle_Array'(A, B, C) loop
         Set_Part_Style (Item, Main_Part, From (Even_Share_Rules).Build);
         Add_Child (Outer, Item);
      end loop;
      Add_Child (B, Gapped_Row);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (A).Width, Third, "the first takes a third");
      Assert_Close (Get_Geometry (B).Width, Third,
                    "the gapped one takes a third");
      Assert_Close (Get_Geometry (C).Width, Third, "the last takes a third");
   end Test_Three_Way_Split;

   ---------------------------------------------------------------------------
   --  An item that cannot flex never gets a share to violate, so nothing
   --  in the distribution reads its limits. It starts at its base, its
   --  minimum raises it and its maximum caps it -- and where the two
   --  disagree the minimum wins, CSS 2.1 10.4.
   ---------------------------------------------------------------------------

   procedure Test_An_Inflexible_Item_Keeps_Its_Floor is
      Floor_W : constant Pixel_Type := 50.0;
      Basis_W : constant Pixel_Type := 200.0;
      Cap_W   : constant Pixel_Type := 100.0;
      Above   : constant Pixel_Type := 250.0;

      function Rigid_Width (Rules : Style_Rules) return Pixel_Type is
         Outer : constant Widget_Handle := New_Box;
         Only  : constant Widget_Handle := New_Box;
      begin
         Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
         Set_Part_Style (Only, Main_Part, From (Rules).Build);
         Add_Child (Outer, Only);

         Set_Geometry (Outer, (0.0, 0.0, 1000.0, 200.0));
         Layout (Outer);

         return Get_Geometry (Only).Width;
      end Rigid_Width;

      Capped : constant Style_Rules :=
        (Flex_Basis  => Set (Basis (Px (Float (Basis_W)))),
         Flex_Grow   => Set (0.0),
         Flex_Shrink => Set (0.0),
         Max_Width   => Set (Size (Px (Float (Cap_W)))),
         others      => <>);

      Outer : constant Widget_Handle := New_Box;
      Only  : constant Widget_Handle := New_Box;
   begin
      Section ("an item that cannot flex keeps its floor");

      Assert_Close
        (Rigid_Width ((Flex_Basis  => Set (Basis (Px (0.0))),
                       Flex_Grow   => Set (0.0),
                       Flex_Shrink => Set (0.0),
                       Min_Width   => Set (Size (Px (Float (Floor_W)))),
                       others      => <>)),
         Floor_W,
         "the item takes its floor, not its zero basis");

      Assert_Close
        (Rigid_Width ((Flex_Basis  => Set (Basis (Px (Float (Basis_W)))),
                       Flex_Grow   => Set (0.0),
                       Flex_Shrink => Set (0.0),
                       others      => <>)),
         Basis_W,
         "with nothing bounding it, the basis is the whole answer");

      Assert_Close (Rigid_Width (Capped), Cap_W,
                    "max-width caps that basis");

      Assert_Close
        (Rigid_Width ((Flex_Basis  => Set (Basis (Px (Float (Basis_W)))),
                       Flex_Grow   => Set (0.0),
                       Flex_Shrink => Set (0.0),
                       Min_Width   => Set (Size (Px (Float (Above)))),
                       Max_Width   => Set (Size (Px (Float (Cap_W)))),
                       others      => <>)),
         Above,
         "a minimum above the maximum wins over it");

      --  What the row reserves for the item follows the same cap: room
      --  it can never occupy is not room it needs.
      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Only, Main_Part, From (Capped).Build);
      Add_Child (Outer, Only);

      Assert_Close (Get_Content_Min_Size (Outer).Width, Cap_W,
                    "and the row demands no more than the cap either");
   end Test_An_Inflexible_Item_Keeps_Its_Floor;

begin
   Start_Suite ("Flex Gap Minimum Test");

   Test_Gapped_Content_Does_Not_Skew_The_Split;
   Test_A_Minimum_Below_The_Share_Does_Not_Add;
   Test_A_Minimum_Above_The_Share_Holds;
   Test_Automatic_Minimum_Still_Holds_The_Gaps;
   Test_Gaps_Count_In_The_Content_Minimum;
   Test_Matching_Siblings_Split_Evenly;
   Test_Three_Way_Split;
   Test_An_Inflexible_Item_Keeps_Its_Floor;

   Finish;
end Flex_Gap_Min_Test;
