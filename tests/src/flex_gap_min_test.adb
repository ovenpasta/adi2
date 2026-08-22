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

   ---------------------------------------------------------------------------
   --  An item that cannot flex is settled before the free space is
   --  measured, so its floor is space already spent. A grow sibling
   --  divides what is left over that floor, not what is left over the
   --  item's bare base.
   --  CSS Flexbox 9.7 step 3: an item with a flex factor of zero freezes
   --  at its hypothetical main size, which step 4 then counts as used.
   ---------------------------------------------------------------------------

   procedure Test_A_Floor_Beside_A_Grow_Sibling_Is_Reserved is
      Outer_W : constant Pixel_Type := 200.0;
      Floor_W : constant Pixel_Type := 60.0;

      Rigid : constant Style_Rules :=
        (Flex_Grow   => Set (0.0),
         Flex_Shrink => Set (0.0),
         Min_Width   => Set (Size (Px (Float (Floor_W)))),
         others      => <>);

      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Section ("a floor beside a grow sibling is reserved, not overrun");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Rigid).Build);
      Set_Part_Style (Right, Main_Part, From (Even_Share_Rules).Build);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Left).Width, Floor_W,
                    "the rigid item stands at its floor");
      Assert_Close (Get_Geometry (Right).Width, Outer_W - Floor_W,
                    "its grow sibling takes only what is left over it");
      Assert_Close
        (Get_Geometry (Left).Width + Get_Geometry (Right).Width, Outer_W,
         "and the two together fill the row exactly");
   end Test_A_Floor_Beside_A_Grow_Sibling_Is_Reserved;

   ---------------------------------------------------------------------------
   --  The same the other way up: room the cap denies a rigid item is
   --  room the grow sibling gets, not room the line leaves empty.
   ---------------------------------------------------------------------------

   procedure Test_A_Cap_Beside_A_Grow_Sibling_Is_Released is
      Outer_W : constant Pixel_Type := 200.0;
      Basis_W : constant Pixel_Type := 150.0;
      Cap_W   : constant Pixel_Type := 40.0;

      Rigid : constant Style_Rules :=
        (Flex_Basis  => Set (Basis (Px (Float (Basis_W)))),
         Flex_Grow   => Set (0.0),
         Flex_Shrink => Set (0.0),
         Max_Width   => Set (Size (Px (Float (Cap_W)))),
         others      => <>);

      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Section ("a cap beside a grow sibling releases the room it denies");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Rigid).Build);
      Set_Part_Style (Right, Main_Part, From (Even_Share_Rules).Build);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Left).Width, Cap_W,
                    "the rigid item stops at its cap");
      Assert_Close (Get_Geometry (Right).Width, Outer_W - Cap_W,
                    "its grow sibling takes the room the cap gave up");
   end Test_A_Cap_Beside_A_Grow_Sibling_Is_Released;

   ---------------------------------------------------------------------------
   --  Whether the line grows or shrinks is read from the sizes its items
   --  ask for, not from the bases those sizes were clamped out of. An
   --  item capped well under its basis asks for the cap; a line reading
   --  the basis instead believes it is overflowing and sets about
   --  shrinking a sibling that has nothing to give.
   --  CSS Flexbox 9.7 step 1.
   ---------------------------------------------------------------------------

   procedure Test_A_Cap_Decides_The_Factor_Not_The_Basis is
      Outer_W : constant Pixel_Type := 200.0;
      Basis_W : constant Pixel_Type := 500.0;
      Cap_W   : constant Pixel_Type := 100.0;

      --  Still shrinkable, so nothing settles it up front: the line has
      --  to have read its cap to size the pair at all.
      Capped : constant Style_Rules :=
        (Flex_Basis  => Set (Basis (Px (Float (Basis_W)))),
         Flex_Grow   => Set (1.0),
         Flex_Shrink => Set (1.0),
         Max_Width   => Set (Size (Px (Float (Cap_W)))),
         others      => <>);

      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Section ("a cap decides the factor, not the basis it caps");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Capped).Build);
      Set_Part_Style (Right, Main_Part, From (Even_Share_Rules).Build);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Left).Width, Cap_W,
                    "the capped item stands at its cap");
      Assert_Close (Get_Geometry (Right).Width, Outer_W - Cap_W,
                    "its sibling takes the rest, not nothing");
   end Test_A_Cap_Decides_The_Factor_Not_The_Basis;

   ---------------------------------------------------------------------------
   --  A basis the cap has already overruled is not an overflow. Reading
   --  one where none exists costs a sibling room it never had to give.
   ---------------------------------------------------------------------------

   procedure Test_A_Capped_Basis_Is_Not_An_Overflow is
      Outer_W : constant Pixel_Type := 100.0;
      Cap_W   : constant Pixel_Type := 30.0;
      Kept_W  : constant Pixel_Type := 60.0;

      Capped : constant Style_Rules :=
        (Flex_Basis => Set (Basis (Px (90.0))),
         Flex_Grow  => Set (0.0),
         Max_Width  => Set (Size (Px (Float (Cap_W)))),
         others     => <>);

      Plain : constant Style_Rules :=
        (Flex_Basis => Set (Basis (Px (Float (Kept_W)))),
         Flex_Grow  => Set (0.0),
         others     => <>);

      Outer : constant Widget_Handle := New_Box;
      Left  : constant Widget_Handle := New_Box;
      Right : constant Widget_Handle := New_Box;
   begin
      Section ("a basis its cap overruled is not an overflow");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Left, Main_Part, From (Capped).Build);
      Set_Part_Style (Right, Main_Part, From (Plain).Build);
      Add_Child (Outer, Left);
      Add_Child (Outer, Right);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Left).Width, Cap_W,
                    "the capped item takes its cap");
      Assert_Close (Get_Geometry (Right).Width, Kept_W,
                    "and its sibling keeps its basis, unshrunk");
   end Test_A_Capped_Basis_Is_Not_An_Overflow;

   ---------------------------------------------------------------------------
   --  A floor settled before the sharing starts leaves the line's own
   --  arithmetic to absorb it, so the row still ends where it began. Read
   --  too late, the floor arrives after the last item that could have
   --  given way is already frozen.
   ---------------------------------------------------------------------------

   procedure Test_A_Late_Floor_Does_Not_Overflow_The_Row is
      Outer_W : constant Pixel_Type := 110.0;
      Floor_W : constant Pixel_Type := 90.0;
      Field_W : constant Pixel_Type := 20.0;

      Rigid : constant Style_Rules :=
        (Flex_Grow   => Set (0.0),
         Flex_Shrink => Set (0.0),
         Min_Width   => Set (Size (Px (Float (Floor_W)))),
         others      => <>);

      Field : constant Style_Rules :=
        (Flex_Basis => Set (Basis (Px (0.0))),
         Flex_Grow  => Set (1.0),
         Min_Width  => Set (Size (Px (Float (Field_W)))),
         others     => <>);

      Filler : constant Style_Rules :=
        (Flex_Basis => Set (Basis (Px (30.0))),
         Flex_Grow  => Set (1.0),
         Min_Width  => Set (Size (Px (0.0))),
         others     => <>);

      Outer : constant Widget_Handle := New_Box;
      R     : constant Widget_Handle := New_Box;
      F     : constant Widget_Handle := New_Box;
      X     : constant Widget_Handle := New_Box;
      Total : Pixel_Type := 0.0;
   begin
      Section ("a floor read in time does not overflow the row");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (R, Main_Part, From (Rigid).Build);
      Set_Part_Style (F, Main_Part, From (Field).Build);
      Set_Part_Style (X, Main_Part, From (Filler).Build);
      Add_Child (Outer, R);
      Add_Child (Outer, F);
      Add_Child (Outer, X);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (R).Width, Floor_W,
                    "the rigid item stands at its floor");
      Assert_Close (Get_Geometry (F).Width, Field_W,
                    "the field stands at its own");
      Assert_Close (Get_Geometry (X).Width, 0.0,
                    "and the last item gives up everything it had");

      for K in 1 .. Child_Count (Outer) loop
         Total := Total + Get_Geometry (Get_Child_Handle (Outer, K)).Width;
      end loop;

      Assert_Close (Total, Outer_W, "the row spends its width exactly once");
   end Test_A_Late_Floor_Does_Not_Overflow_The_Row;

   ---------------------------------------------------------------------------
   --  Flex factors are a fraction of the free space, not merely a ratio
   --  between the items. Where they sum to less than one they take that
   --  fraction and leave the remainder of the line unfilled; only once
   --  they reach one is the whole of it spoken for.
   --  CSS Flexbox 9.7 step 4b.
   ---------------------------------------------------------------------------

   procedure Test_Factors_Under_One_Leave_Space_Unfilled is
      Outer_W : constant Pixel_Type := 200.0;

      function Grown (Factor : Float; Kids : Positive) return Pixel_Type is
         Rules : constant Style_Rules :=
           (Flex_Basis => Set (Basis (Px (0.0))),
            Flex_Grow  => Set (Flex_Grow_Value (Factor)),
            Min_Width  => Set (Size (Px (0.0))),
            others     => <>);
         Outer : constant Widget_Handle := New_Box;
         First : Widget_Handle;
      begin
         Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
         for K in 1 .. Kids loop
            declare
               Kid : constant Widget_Handle := New_Box;
            begin
               Set_Part_Style (Kid, Main_Part, From (Rules).Build);
               Add_Child (Outer, Kid);
               if K = 1 then
                  First := Kid;
               end if;
            end;
         end loop;

         Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
         Layout (Outer);

         return Get_Geometry (First).Width;
      end Grown;
   begin
      Section ("factors under one leave the rest of the line unfilled");

      Assert_Close (Grown (0.5, 1), Outer_W * 0.5,
                    "a lone item at 0.5 takes half the free space");
      Assert_Close (Grown (0.25, 2), Outer_W * 0.25,
                    "two at 0.25 take a quarter each, half the row unused");
      Assert_Close (Grown (0.5, 2), Outer_W * 0.5,
                    "two at 0.5 sum to one and share the whole row");
      Assert_Close (Grown (1.0, 1), Outer_W,
                    "and a lone item at one still takes all of it");
   end Test_Factors_Under_One_Leave_Space_Unfilled;

   ---------------------------------------------------------------------------
   --  The same fraction applies to shrinking: half a shrink factor gives
   --  up half the overflow and the item stays over the line.
   ---------------------------------------------------------------------------

   procedure Test_A_Half_Shrink_Gives_Up_Half_The_Overflow is
      Outer_W : constant Pixel_Type := 100.0;
      Basis_W : constant Pixel_Type := 200.0;

      Slow : constant Style_Rules :=
        (Flex_Basis  => Set (Basis (Px (Float (Basis_W)))),
         Flex_Grow   => Set (0.0),
         Flex_Shrink => Set (0.5),
         Min_Width   => Set (Size (Px (0.0))),
         others      => <>);

      Outer : constant Widget_Handle := New_Box;
      Only  : constant Widget_Handle := New_Box;
   begin
      Section ("half a shrink factor gives up half the overflow");

      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (Only, Main_Part, From (Slow).Build);
      Add_Child (Outer, Only);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close (Get_Geometry (Only).Width, 150.0,
                    "it gives up half of the hundred it overflows by");
   end Test_A_Half_Shrink_Gives_Up_Half_The_Overflow;

   ---------------------------------------------------------------------------
   --  Three items, sized together, so the second pass has more than one
   --  item to share between and the proportions are visible.
   ---------------------------------------------------------------------------

   procedure Lay_Out_Three
     (Outer_W : Pixel_Type;
      A, B, C : Style_Rules;
      A_W, B_W, C_W : out Pixel_Type)
   is
      Outer : constant Widget_Handle := New_Box;
      X     : constant Widget_Handle := New_Box;
      Y     : constant Widget_Handle := New_Box;
      Z     : constant Widget_Handle := New_Box;
   begin
      Set_Part_Style (Outer, Main_Part, From (Row_Rules).Build);
      Set_Part_Style (X, Main_Part, From (A).Build);
      Set_Part_Style (Y, Main_Part, From (B).Build);
      Set_Part_Style (Z, Main_Part, From (C).Build);
      Add_Child (Outer, X);
      Add_Child (Outer, Y);
      Add_Child (Outer, Z);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 100.0));
      Layout (Outer);

      A_W := Get_Geometry (X).Width;
      B_W := Get_Geometry (Y).Width;
      C_W := Get_Geometry (Z).Width;
   end Lay_Out_Three;

   ---------------------------------------------------------------------------
   --  Freezing an item at its floor does not turn the line around. What
   --  is left over the floor is still space to grow into, shared from the
   --  bases in the grow factors' proportion -- not taken back off the
   --  sizes the first pass had already handed out.
   --  CSS Flexbox 9.7 step 4c: the target is the flex base size plus a
   --  fraction, and the factor in use is settled once, in step 1.
   ---------------------------------------------------------------------------

   procedure Test_A_Second_Pass_Still_Grows_From_The_Bases is
      Outer_W : constant Pixel_Type := 120.0;
      A_W, B_W, C_W : Pixel_Type;
   begin
      Section ("a second pass grows from the bases, it does not claw back");

      Lay_Out_Three
        (Outer_W,
         --  Floored well above the share it is due, so it violates and
         --  freezes, forcing the pass that follows.
         (Flex_Basis  => Set (Basis (Px (0.0))),
          Flex_Grow   => Set (1.0),
          Flex_Shrink => Set (1.0),
          Min_Width   => Set (Size (Px (60.0))),
          others      => <>),
         (Flex_Basis  => Set (Basis (Px (40.0))),
          Flex_Grow   => Set (1.0),
          Flex_Shrink => Set (1.0),
          Min_Width   => Set (Size (Px (0.0))),
          others      => <>),
         (Flex_Basis  => Set (Basis (Px (0.0))),
          Flex_Grow   => Set (3.0),
          Flex_Shrink => Set (1.0),
          Min_Width   => Set (Size (Px (0.0))),
          others      => <>),
         A_W, B_W, C_W);

      Assert_Close (A_W, 60.0, "the floored item stands at its floor");
      Assert_Close (B_W, 45.0, "its basis of 40 keeps a quarter of the 20 left");
      Assert_Close (C_W, 15.0, "and the item at three times the factor takes the rest");
      Assert_Close (A_W + B_W + C_W, Outer_W, "the three fill the row");
      Assert (B_W >= 40.0, "and nothing is grown to less than its own basis");
   end Test_A_Second_Pass_Still_Grows_From_The_Bases;

   ---------------------------------------------------------------------------
   --  A maximum is a ceiling, not a target. Where one item's floor takes
   --  more of the line than the share it was due, the line has less to go
   --  round, and a capped item settles below its cap rather than holding
   --  it while a sibling gives up the difference.
   --  CSS Flexbox 9.7 steps 4d and 4e: the violations are summed over the
   --  line, and a positive total freezes only the items that hit a floor.
   ---------------------------------------------------------------------------

   procedure Test_A_Cap_Yields_When_A_Floor_Takes_More is
      Outer_W : constant Pixel_Type := 100.0;
      A_W, B_W, C_W : Pixel_Type;
   begin
      Section ("a cap yields when a floor elsewhere takes more");

      Lay_Out_Three
        (Outer_W,
         (Flex_Basis => Set (Basis (Px (0.0))),
          Flex_Grow  => Set (1.0),
          Min_Width  => Set (Size (Px (60.0))),
          others     => <>),
         (Flex_Basis => Set (Basis (Px (0.0))),
          Flex_Grow  => Set (1.0),
          Min_Width  => Set (Size (Px (0.0))),
          Max_Width  => Set (Size (Px (25.0))),
          others     => <>),
         (Flex_Basis => Set (Basis (Px (0.0))),
          Flex_Grow  => Set (1.0),
          Min_Width  => Set (Size (Px (0.0))),
          others     => <>),
         A_W, B_W, C_W);

      Assert_Close (A_W, 60.0, "the floored item stands at its floor");
      Assert_Close (B_W, 20.0, "the capped item settles under its cap");
      Assert_Close (C_W, 20.0, "its unbounded sibling takes the same");
      Assert_Close (B_W, C_W, "the two that still flex end up equal");
   end Test_A_Cap_Yields_When_A_Floor_Takes_More;

   ---------------------------------------------------------------------------
   --  The shape a toolbar takes: a run of rigid controls holding their
   --  own widths and one field growing into what they leave.
   ---------------------------------------------------------------------------

   procedure Test_A_Toolbar_Row_Fits_Its_Container is
      Outer_W  : constant Pixel_Type := 600.0;
      Combo_W  : constant Pixel_Type := 120.0;
      Combos   : constant Positive := 3;
      Gap_W    : constant Float := 10.0;
      Gaps     : constant Pixel_Type :=
        Pixel_Type (Gap_W) * Pixel_Type (Combos);

      Gapped : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Row),
         Gap            => Set (Gap (Px (Gap_W))),
         others         => <>);

      Rigid : constant Style_Rules :=
        (Flex_Grow   => Set (0.0),
         Flex_Shrink => Set (0.0),
         Min_Width   => Set (Size (Px (Float (Combo_W)))),
         others      => <>);

      Outer : constant Widget_Handle := New_Box;
      Field : constant Widget_Handle := New_Box;
      Total : Pixel_Type := 0.0;
   begin
      Section ("a toolbar of rigid controls and one grown field fits");

      Set_Part_Style (Outer, Main_Part, From (Gapped).Build);
      for K in 1 .. Combos loop
         declare
            Combo : constant Widget_Handle := New_Box;
         begin
            Set_Part_Style (Combo, Main_Part, From (Rigid).Build);
            Add_Child (Outer, Combo);
         end;
      end loop;
      Set_Part_Style (Field, Main_Part, From (Even_Share_Rules).Build);
      Add_Child (Outer, Field);

      Set_Geometry (Outer, (0.0, 0.0, Outer_W, 200.0));
      Layout (Outer);

      Assert_Close
        (Get_Geometry (Field).Width,
         Outer_W - Pixel_Type (Combos) * Combo_W - Gaps,
         "the field takes what the controls and gaps leave");

      for K in 1 .. Child_Count (Outer) loop
         Total := Total + Get_Geometry (Get_Child_Handle (Outer, K)).Width;
      end loop;

      Assert_Close (Total + Gaps, Outer_W,
                    "and the row spends its width exactly once");
   end Test_A_Toolbar_Row_Fits_Its_Container;

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
   Test_A_Floor_Beside_A_Grow_Sibling_Is_Reserved;
   Test_A_Cap_Beside_A_Grow_Sibling_Is_Released;
   Test_A_Cap_Decides_The_Factor_Not_The_Basis;
   Test_A_Capped_Basis_Is_Not_An_Overflow;
   Test_A_Late_Floor_Does_Not_Overflow_The_Row;
   Test_Factors_Under_One_Leave_Space_Unfilled;
   Test_A_Half_Shrink_Gives_Up_Half_The_Overflow;
   Test_A_Second_Pass_Still_Grows_From_The_Bases;
   Test_A_Cap_Yields_When_A_Floor_Takes_More;
   Test_A_Toolbar_Row_Fits_Its_Container;

   Finish;
end Flex_Gap_Min_Test;
