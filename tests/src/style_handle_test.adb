--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers;
with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Testing;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Side_Cascade_Styles;
with Test_Support;      use Test_Support;

--  A style is stored once and named by a four-byte handle. Interning is
--  canonical, so a handle comparison is a value comparison in both
--  directions, and the store is what every layer above carries in place
--  of the record.

procedure Style_Handle_Test is

   use type Ada.Containers.Hash_Type;

   function Interned_Styles return Natural
     renames Adi.Widget.Testing.Interned_Styles;

   function Main_Styles (Rules : Style_Rules) return Part_Style_Array is
     ([Main_Part => (Style => From (Rules).Build, Enabled => True),
       others    => <>]);

   ---------------------------------------------------------------------
   --  Widths
   ---------------------------------------------------------------------

   procedure Test_Widths is
   begin
      Section ("what each type carries");

      Assert (Widget_Style'Object_Size = 4 * 8,
              "a Widget_Style is four bytes");
      Assert (Part_Style'Object_Size = 8 * 8,
              "a Part_Style is a handle and a flag, eight bytes");
      Assert (Part_Style_Array'Object_Size = 96 * 8,
              "a Part_Style_Array is 96 bytes");
      Assert (State_Rule'Object_Size = 16 * 8,
              "a State_Rule is a selector, a rules handle and a priority");
      Assert (Style_Rules'Object_Size = 1080 * 8,
              "a Style_Rules stays 1080 bytes, behind the handle, not"
              & Natural'Image (Style_Rules'Object_Size / 8));
      Assert (Style_Definition'Object_Size <= 288 * 8,
              "a Style_Definition is the sixteen slots and their counts");
   end Test_Widths;

   ---------------------------------------------------------------------
   --  Handle equality is value equality
   ---------------------------------------------------------------------

   procedure Test_Equal_Definitions_Share_A_Handle is
      D : constant Style_Definition :=
        Definition (From ((Color   => Set (C (White)),
                           Padding => Set (CSS_Box (Px (4.0))),
                           others  => <>))
                      .On (When_State (State_Hovered),
                           (Color => Set (RGB (1, 2, 3)), others => <>))
                      .Build);
      First  : constant Widget_Style := Intern (D);
      Middle : constant Natural      := Interned_Styles;
      Second : constant Widget_Style := Intern (D);
   begin
      Section ("equal definitions share a handle");

      Assert (First = Second, "interning the same definition twice agrees");
      Assert (Interned_Styles = Middle, "and stores nothing further");
      Assert (First /= Empty_Widget_Style,
              "a definition that sets something is not the empty style");
   end Test_Equal_Definitions_Share_A_Handle;

   procedure Test_Different_Definitions_Differ is
      A : constant Widget_Style :=
        From ((Color => Set (C (White)), others => <>)).Build;
      B : constant Widget_Style :=
        From ((Color => Set (C (Black)), others => <>)).Build;
      C_Style : constant Widget_Style :=
        From ((Color => Set (C (White)), others => <>))
          .On (When_State (State_Hovered),
               (Color => Set (C (Black)), others => <>))
          .Build;
      D_Style : constant Widget_Style :=
        From ((Color => Set (C (White)), others => <>))
          .On (When_State (State_Pressed),
               (Color => Set (C (Black)), others => <>))
          .Build;
   begin
      Section ("different definitions get different handles");

      Assert (A /= B, "a different base rule set is a different handle");
      Assert (A /= C_Style, "a state rule added is a different handle");
      Assert (C_Style /= D_Style,
              "the same rule under a different selector is a different handle");
      Assert (Empty_Widget_Style
                = From (Empty_Style).Build,
              "a style that sets nothing is the empty handle");
   end Test_Different_Definitions_Differ;

   --  Two rule sets the digest cannot tell apart. Set_Properties reports
   --  Prop_Padding for both, and To_Box resolves an unset side to zero,
   --  so a single zero side on either edge digests as a uniform zero
   --  box. The store answers on the values, so the handles differ.
   procedure Test_Colliding_Rule_Sets_Stay_Apart is
      Zero_Top : constant Style_Rules :=
        (Padding => [Top    => Opt_Length.Val (Zero_Length),
                     others => Opt_Length.Unset],
         others  => <>);
      Zero_Left : constant Style_Rules :=
        (Padding => [Left   => Opt_Length.Val (Zero_Length),
                     others => Opt_Length.Unset],
         others  => <>);
   begin
      Section ("a digest collision does not merge two rule sets");

      Assert (Zero_Top /= Zero_Left, "the two rule sets differ");
      Assert (Hash (Zero_Top) = Hash (Zero_Left),
              "and hash alike, which is what makes this a collision");
      Assert (Intern_Rules (Zero_Top) /= Intern_Rules (Zero_Left),
              "the store keeps them apart");
      Assert (Rules_Of (Intern_Rules (Zero_Top)) = Zero_Top,
              "and each handle answers with what went in");
      Assert (Rules_Of (Intern_Rules (Zero_Left)) = Zero_Left,
              "for both sides of the collision");

      Assert (From (Zero_Top).Build /= From (Zero_Left).Build,
              "and two styles built on them are two handles");
   end Test_Colliding_Rule_Sets_Stay_Apart;

   procedure Test_Rule_Sets_Intern_Once is
      R : constant Style_Rules :=
        (Order => Set (Order_Value (987_654)), others => <>);
      Before       : constant Natural      := Interned_Rule_Sets;
      Bytes_Before : constant Natural      := Interned_Rule_Bytes;
      First        : constant Rules_Handle := Intern_Rules (R);
      Middle       : constant Natural      := Interned_Rule_Sets;
      Second       : constant Rules_Handle := Intern_Rules (R);
      After        : constant Natural      := Interned_Rule_Sets;
   begin
      Section ("a rule set is stored once");

      Assert (Middle = Before + 1,
              "a rule set the store has not seen is added");
      Assert (First = Second, "an equal one answers the same handle");
      Assert (After = Middle, "and stores nothing further");
      Assert (Interned_Rule_Bytes > Bytes_Before, "the entry costs storage");
      Assert (Intern_Rules (Empty_Style) = Empty_Rules,
              "the empty rule set is handle zero");
      Assert (Rules_Of (Empty_Rules) = Empty_Style,
              "which reads back as the empty rule set");
   end Test_Rule_Sets_Intern_Once;

   ---------------------------------------------------------------------
   --  Round trip
   ---------------------------------------------------------------------

   procedure Test_Definition_Round_Trips is
      Built : constant Widget_Style :=
        From ((Background_Color => Set_Bg (RGB (9, 9, 9)),
               Font_Size        => Set_Font (Px (13.0)),
               others           => <>))
          .On (When_State (State_Hovered),
               (Opacity => Set (0.5), others => <>))
          .On (When_Part_State (State_Disabled),
               (Opacity => Set (0.25), others => <>), 7)
          .Build;
      D : constant Style_Definition := Definition (Built);
   begin
      Section ("Definition and Intern are each other's inverse");

      Assert (Intern (D) = Built,
              "a definition read back interns to the handle it came from");
      Assert (Same_Style (Definition (Intern (D)), D),
              "and reading it again answers the same definition");
      Assert (D.Rule_Count = 2, "both state rules survive the store");
      Assert (D.Rules (2).Priority = 7, "an explicit priority survives");
      Assert (Opt_Font_Size.Is_Set (Rules_Of (D.Base).Font_Size),
              "and so does the base rule set");
      Assert (Uses_Widget_State (Built, State_Hovered),
              "the state masks are answered from the store");
      Assert (Uses_Part_State (Built, State_Disabled),
              "for part states too");
      Assert (not Uses_Widget_State (Built, State_Focused),
              "and a state no rule names is reported as unused");
   end Test_Definition_Round_Trips;

   ---------------------------------------------------------------------
   --  Merge
   ---------------------------------------------------------------------

   procedure Test_Merge_Re_Interns is
      Base : constant Part_Style_Array :=
        Main_Styles ((Color   => Set (C (White)),
                      Padding => Set (CSS_Box (Px (4.0))),
                      others  => <>));
      Over : constant Part_Style_Array :=
        Main_Styles ((Color  => Set (C (Black)), others => <>));

      Folded : constant Part_Style_Array :=
        Adi.CSS_Source.Merge_Part_Styles (Base, Over);

      Expected : constant Widget_Style :=
        From (Merge (Rules_Of (Definition (Base (Main_Part).Style).Base),
                     Rules_Of (Definition (Over (Main_Part).Style).Base)))
          .Build;
   begin
      Section ("a merge folds the values and interns the answer");

      Assert (Folded (Main_Part).Style = Expected,
              "the folded style is the handle its value interns to");
      Assert (Folded (Main_Part).Style /= Base (Main_Part).Style
                and then Folded (Main_Part).Style /= Over (Main_Part).Style,
              "and neither contributor's own handle");
      Assert (Opt_Text_Color.Resolve
                (Rules_Of
                   (Definition (Folded (Main_Part).Style).Base).Color)
                = C (Black),
              "the override wins the property both name");
      Assert (Opt_Length.Is_Set
                (Rules_Of
                   (Definition (Folded (Main_Part).Style).Base).Padding (Top)),
              "and the base keeps the one only it names");
   end Test_Merge_Re_Interns;

   procedure Test_One_Contributor_Passes_Through is
      Over : constant Part_Style_Array :=
        Main_Styles ((Color => Set (C (Black)), others => <>));
      Before : Natural;
   begin
      Section ("one contributor answers with its own handle");

      Before := Interned_Styles;
      Assert (Adi.CSS_Source.Merge_Part_Styles (Empty_Part_Styles, Over)
                = Over,
              "folding onto nothing answers the override");
      Assert (Adi.CSS_Source.Merge_Part_Styles (Over, Empty_Part_Styles)
                = Over,
              "and folding nothing on answers the base");
      Assert (Interned_Styles = Before,
              "neither fold stores a style");
   end Test_One_Contributor_Passes_Through;

   ---------------------------------------------------------------------
   --  Elaboration order
   ---------------------------------------------------------------------

   --  Side_Cascade_Styles is generated by tools/css_to_ada.py and holds
   --  its styles in library-level constants, so its .Build calls run as
   --  it elaborates -- ahead of this procedure's body, and with no
   --  window, source or widget in existence. The handles it holds have
   --  to name live entries all the same.
   procedure Test_Styles_Elaborate_Before_Anything_Else is
      Box_Style : constant Widget_Style :=
        Side_Cascade_Styles.Box_Tag_Part_Styles (Main_Part).Style;
      D : constant Style_Definition := Definition (Box_Style);
      Padding : constant CSS_Box_Value := To_Box (Rules_Of (D.Base).Padding);
   begin
      Section ("a generated sheet interns as it elaborates");

      Assert (Interned_Styles > 0,
              "styles are in the store before the test body runs");
      Assert (Box_Style /= Empty_Widget_Style,
              "a generated constant names a stored style");
      Assert (Intern (D) = Box_Style,
              "and the entry it names is the one its definition interns to");
      Assert (Padding.Kind = Gap_Uniform
                and then Padding.All_Sides = Px (12.0),
              "which holds what the stylesheet said");
      Assert (Side_Cascade_Styles.Box_Tag_Part_Styles (Main_Part).Enabled,
              "with the part it was declared on switched on");
   end Test_Styles_Elaborate_Before_Anything_Else;

   ---------------------------------------------------------------------
   --  What a stored rule set costs
   ---------------------------------------------------------------------

   --  A rule set is stored as the properties it names, eight bytes each,
   --  and a property whose values cascade one at a time names one slot
   --  per value.
   procedure Test_A_Rule_Set_Costs_Its_Properties is
      One : constant Rule_Slots :=
        Slots_Of (Style_Rules'(Order => Set (Order_Value (7)), others => <>));
      Three : constant Rule_Slots :=
        Slots_Of (Style_Rules'(Order       => Set (Order_Value (7)),
                               Font_Size   => Set_Font (Px (13.0)),
                               Flex_Grow   => Set (Flex_Grow_Value (1.0)),
                               others      => <>));
      Box : constant Rule_Slots :=
        Slots_Of (Style_Rules'(Padding => Set (CSS_Box (Px (4.0))),
                               others  => <>));
      Before : constant Natural := Interned_Rule_Bytes;
      Unused : constant Rules_Handle := Intern_Rules (Three);
   begin
      Section ("a rule set costs the properties it names");

      Assert (Slot_Count (One) = 1, "one property is one slot");
      Assert (Slot_Count (Three) = 3, "three properties are three slots");
      Assert (Slot_Count (Box) = 4,
              "and a padding shorthand is one slot per side");
      Assert (Interned_Rule_Bytes = Before + 3 * 8,
              "which is eight bytes each in the store, not"
              & Natural'Image (Interned_Rule_Bytes - Before));
      Assert (Unused /= Empty_Rules, "the rule set is stored");
   end Test_A_Rule_Set_Costs_Its_Properties;

   ---------------------------------------------------------------------
   --  A cleared gap beside a single axis
   ---------------------------------------------------------------------

   --  A gap axis has no cleared state of its own -- Opt_Gap holds one
   --  Gap_Value, whose flags say named or not -- so a fold that reaches
   --  one axis set beside the other cleared carries the set axis and
   --  leaves the other reading as unnamed. That resolves as the clear
   --  would, Default_Gap being zero on both axes, and Get_Row_Gap and
   --  Get_Column_Gap read the axis rather than the flag. This pins the
   --  pair, so making either of those axis-aware fails here rather than
   --  answering a silently wrong gap.
   procedure Test_Cleared_Gap_Under_One_Axis is
      Wiped : Style_Rules := Empty_Style;

      Row : constant Style_Rules :=
        (Gap => Set (Gap_Row (Px (4.0))), others => <>);
      Col : constant Style_Rules :=
        (Gap => Set (Gap_Column (Px (8.0))), others => <>);

      Over_Row : Rules_Handle;
      Over_Col : Rules_Handle;
   begin
      Section ("a cleared gap under a rule naming one axis");

      Clear_Property (Wiped, Prop_Gap);
      Assert (Opt_Gap.Is_None (Wiped.Gap),
              "clearing the gap clears the one field, so both axes");

      Over_Row := Merge (Intern_Rules (Wiped), Intern_Rules (Row));
      Over_Col := Merge (Intern_Rules (Wiped), Intern_Rules (Col));

      declare
         R : constant Gap_Value := Opt_Gap.Resolve (Rules_Of (Over_Row).Gap);
         C : constant Gap_Value := Opt_Gap.Resolve (Rules_Of (Over_Col).Gap);
      begin
         Assert (Opt_Gap.Is_Set (Rules_Of (Over_Row).Gap)
                   and then R.Kind = Gap_Separate,
                 "the axis the override names stands over the clear");
         Assert (R.Kind = Gap_Separate
                   and then R.Has_Row and then R.Row_Gap = Px (4.0),
                 "carrying the row gap it named");
         Assert (R.Kind = Gap_Separate
                   and then not R.Has_Column
                   and then R.Column_Gap = Zero_Length,
                 "and the cleared column axis reading as unnamed and zero, "
                 & "which is what the clear resolves to");

         Assert (C.Kind = Gap_Separate
                   and then C.Has_Column and then C.Column_Gap = Px (8.0),
                 "and the same the other way round for the column axis");
         Assert (C.Kind = Gap_Separate
                   and then not C.Has_Row
                   and then C.Row_Gap = Zero_Length,
                 "with the cleared row axis unnamed and zero");
      end;

      Assert (Merge (Intern_Rules (Wiped), Empty_Rules)
                = Intern_Rules (Wiped),
              "and a clear with nothing over it stays a clear on both axes");
   end Test_Cleared_Gap_Under_One_Axis;

   ---------------------------------------------------------------------
   --  Order is not part of a rule set
   ---------------------------------------------------------------------

   --  The store holds a rule set as a slot list in property order, and
   --  a group's parts in part order, so the order the properties were
   --  named in cannot reach it. Two chains, two sheets and one of each
   --  answer one handle.
   procedure Test_Naming_Order_Interns_Once is
      By_One : constant Widget_Style :=
        Style_Of
          .Text_Color (C (White))
          .Font_Size (Px (13.0))
          .Padding (CSS_Box (Px (4.0)))
        .Build;
      By_Other : constant Widget_Style :=
        Style_Of
          .Padding (CSS_Box (Px (4.0)))
          .Text_Color (C (White))
          .Font_Size (Px (13.0))
        .Build;

      --  The two edges apart, and together, so a fold in either
      --  direction is checked against the value it stands for.
      Left_Edge : constant Rules_Handle :=
        Intern_Rules ((Border_Width => [Left   => Opt_Length.Val (Px (2.0)),
                                        others => Opt_Length.Unset],
                       others       => <>));
      Top_Edge  : constant Rules_Handle :=
        Intern_Rules ((Border_Width => [Top    => Opt_Length.Val (Px (1.0)),
                                        others => Opt_Length.Unset],
                       others       => <>));
      Both_Edges : constant Rules_Handle :=
        Intern_Rules ((Border_Width => [Top    => Opt_Length.Val (Px (1.0)),
                                        Left   => Opt_Length.Val (Px (2.0)),
                                        others => Opt_Length.Unset],
                       others       => <>));

      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;
   begin
      Section ("the order a rule set was named in does not reach the store");

      Assert (By_One = By_Other,
              "two chains naming three properties in two orders are one "
              & "handle");

      Assert (Merge (Left_Edge, Top_Edge) = Both_Edges,
              "folding two border edges answers the rule set naming both");
      Assert (Merge (Top_Edge, Left_Edge) = Both_Edges,
              "and folding them the other way answers the same handle");

      Adi.CSS_Parser.Load_String
        (Sheet,
         ".sides1 { border-top-width: 1px; border-left-width: 2px;"
         & " row-gap: 4px; column-gap: 8px; }"
         & ".sides2 { column-gap: 8px; border-left-width: 2px;"
         & " row-gap: 4px; border-top-width: 1px; }"
         & ".mix { font-size: 13px; padding: 4px; color: white; }",
         OK);
      Assert (OK, "the probe stylesheet parses");
      if not OK then
         return;
      end if;

      declare
         Sides1 : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, "sides1");
         Sides2 : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, "sides2");
         Mix    : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, "mix");
      begin
         Assert (Sides1 (Main_Part).Style = Sides2 (Main_Part).Style,
                 "and so are two sheets naming the same border edges and "
                 & "gap axes in two orders");
         Assert (Mix (Main_Part).Style = By_One,
                 "and a sheet against the chain that spells it");
      end;

      Adi.CSS_Parser.Destroy (Sheet);
   end Test_Naming_Order_Interns_Once;

   ---------------------------------------------------------------------
   --  The parser reaches the same store
   ---------------------------------------------------------------------

   procedure Test_Parsed_Sheet_Shares_The_Store is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;
   begin
      Section ("a parsed selector interns where a built one does");

      Adi.CSS_Parser.Load_String
        (Sheet, ".probe { color: white; }", OK);
      Assert (OK, "the probe stylesheet parses");
      if not OK then
         return;
      end if;

      declare
         Parsed : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, "probe");
         Built  : constant Widget_Style :=
           From ((Color => Set (C (White)), others => <>)).Build;
      begin
         Assert (Parsed (Main_Part).Style = Built,
                 "the parsed style is the handle the built one interns to");
      end;

      Adi.CSS_Parser.Destroy (Sheet);
   end Test_Parsed_Sheet_Shares_The_Store;

begin
   Start_Suite ("Style Handle Test");

   Test_Widths;
   Test_Styles_Elaborate_Before_Anything_Else;
   Test_Equal_Definitions_Share_A_Handle;
   Test_Different_Definitions_Differ;
   Test_Colliding_Rule_Sets_Stay_Apart;
   Test_Rule_Sets_Intern_Once;
   Test_Definition_Round_Trips;
   Test_Merge_Re_Interns;
   Test_One_Contributor_Passes_Through;
   Test_A_Rule_Set_Costs_Its_Properties;
   Test_Cleared_Gap_Under_One_Axis;
   Test_Naming_Order_Interns_Once;
   Test_Parsed_Sheet_Shares_The_Store;

   Finish;
end Style_Handle_Test;
