--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Parser;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Support; use Test_Support;

--  The composer against the aggregate it replaces. Interning is
--  canonical, so a style written either way answers one handle and the
--  two paths agree exactly rather than equivalently -- the shape
--  tests/src/side_longhand_test.adb uses for the two CSS pipelines.
procedure Style_Composer_Test is

   Blue   : constant Color_Value := RGB (37, 99, 235);
   Deep   : constant Color_Value := RGB (29, 78, 216);
   Danger : constant Color_Value := RGB (200, 30, 30);

   Pad    : constant CSS_Box_Value := CSS_Box (Px (12.0), Px (24.0));
   Round  : constant Border_Radius_Value := Radius (Px (6.0));
   Drop   : constant Box_Shadow_Value :=
     Shadow (Px (0.0), Px (2.0), Px (4.0), Px (0.0), RGBA (0, 0, 0, 0.3));

   ---------------------------------------------------------------------
   --  Widths
   ---------------------------------------------------------------------

   procedure Test_Widths is
   begin
      Section ("what a chain step costs");

      Assert (Slot_Bytes = 8,
              "a chain step is eight bytes, not" & Slot_Bytes'Image);
      Assert (Composer_Bytes = 24,
              "a composer is twenty-four bytes, not" & Composer_Bytes'Image);

      Put_Line
        ("      slot" & Slot_Bytes'Image
         & " B, composer" & Composer_Bytes'Image
         & " B, an eight-property rule" & Natural'Image (8 * Slot_Bytes)
         & " B against a Style_Rules at"
         & Natural'Image (Style_Rules'Max_Size_In_Storage_Elements) & " B");
   end Test_Widths;

   ---------------------------------------------------------------------
   --  Value references
   ---------------------------------------------------------------------

   procedure Test_Value_Refs is
      Wide  : constant Color_Value := RGBA (9, 9, 9, 0.5);
      Before : Natural;
      First, Second : Value_Ref;
   begin
      Section ("a value narrow enough reaches no store");

      Assert (not Is_Stored (Intern (C (Red))),
              "a named colour sits in the reference");
      Assert (Color_Of (Intern (C (Red))) = C (Red),
              "and reads back as itself");

      Assert (not Is_Stored (Intern (RGB (12, 34, 56))),
              "a channel triple in eight bits each sits in the reference");
      Assert (Color_Of (Intern (RGB (12, 34, 56))) = RGB (12, 34, 56),
              "and reads back as itself");

      Assert (Is_Stored (Intern (RGB (300, 0, 0))),
              "a channel past 255 reaches the store");
      Assert (Color_Of (Intern (RGB (300, 0, 0))) = RGB (300, 0, 0),
              "and reads back exact");

      Assert (Is_Stored (Intern (Wide)), "an alpha reaches the store");
      Assert (Color_Of (Intern (Wide)) = Wide, "and reads back exact");

      Assert (not Is_Stored (Intern (Px (12.0))),
              "a whole length sits in the reference");
      Assert (Length_Of (Intern (Px (12.0))) = Px (12.0),
              "and reads back as itself");
      Assert (not Is_Stored (Intern (Em (2.0))),
              "the unit rides beside the magnitude");
      Assert (Length_Of (Intern (Em (2.0))) = Em (2.0),
              "and reads back as itself");

      Assert (Is_Stored (Intern (Px (12.5))),
              "a fractional length reaches the store");
      Assert (Length_Of (Intern (Px (12.5))) = Px (12.5),
              "and reads back exact");
      Assert (Is_Stored (Intern (Px (-4.0))),
              "a negative length reaches the store");
      Assert (Length_Of (Intern (Px (-4.0))) = Px (-4.0),
              "and reads back exact");

      Assert (not Is_Stored (Intern (Flex)),
              "an enumeration is its own reference");
      Assert (Display_Of (Intern (Flex)) = Flex, "and reads back as itself");

      Assert (Is_Stored (Intern (Pad)), "a side box reaches the store");
      Assert (Box_Of (Intern (Pad)) = Pad, "and reads back exact");
      Assert (Is_Stored (Intern (Drop)), "a shadow reaches the store");
      Assert (Box_Shadow_Of (Intern (Drop)) = Drop, "and reads back exact");
      Assert (Is_Stored (Intern (Border_Color (C (Red)))),
              "a border colour reaches the store");
      Assert (Border_Color_Of (Intern (Border_Color (C (Red))))
                = Border_Color (C (Red)),
              "and reads back exact");

      Section ("equal values share one entry");

      Before := Interned_Values;
      First := Intern (RGBA (9, 9, 9, 0.25));
      Assert (Interned_Values = Before + 1, "a fresh value takes an entry");
      Second := Intern (RGBA (9, 9, 9, 0.25));
      Assert (First = Second, "an equal value answers the same reference");
      Assert (Interned_Values = Before + 1, "and takes no second entry");
      Assert (Interned_Value_Bytes >= 4 * Interned_Values,
              "and the stores report the storage their entries occupy");
   end Test_Value_Refs;

   ---------------------------------------------------------------------
   --  The two authoring paths
   ---------------------------------------------------------------------

   procedure Test_One_Property is
      By_Aggregate : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue), others => <>)).Build;
      By_Chain : constant Widget_Style := Style_Of.Background (Blue).Build;
   begin
      Section ("one property, either way");

      Assert (By_Aggregate = By_Chain,
              "a chain of one property interns to the aggregate's handle");
   end Test_One_Property;

   procedure Test_Several_Properties is
      By_Aggregate : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue),
               Padding          => Set (Pad),
               Border_Radius    => Set (Round),
               Border_Color     => Set (Border_Color (C (Red))),
               Box_Shadow       => Set (Drop),
               Display          => Set (Flex),
               Font_Size        => Set_Font (Px (14.0)),
               Flex_Grow        => Set (Flex_Grow_Value (1.0)),
               Cursor           => Set (Cursor_Pointer),
               Gap              => Set (Gap (Px (8.0))),
               others           => <>)).Build;

      By_Chain : constant Widget_Style :=
        Style_Of
          .Background (Blue)
          .Padding (Pad)
          .Radius (Round)
          .Border_Color (Border_Color (C (Red)))
          .Box_Shadow (Drop)
          .Display (Flex)
          .Font_Size (Px (14.0))
          .Flex_Grow (1.0)
          .Cursor_Style (Cursor_Pointer)
          .Gap (Gap (Px (8.0)))
        .Build;
   begin
      Section ("every value shape, either way");

      Assert (By_Aggregate = By_Chain,
              "a chain over ten properties interns to the aggregate's "
              & "handle");
   end Test_Several_Properties;

   procedure Test_Several_Rules is
      By_Aggregate : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue),
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             others           => <>))
          .On (Sel_Focused, (Border_Color => Set (Border_Color (C (White))),
                             others       => <>))
          .Build;

      By_Chain : constant Widget_Style :=
        Style_Of
          .Background (Blue)
          .Padding (Pad)
        .On_Hover
          .Background (Deep)
        .On_Focus
          .Border_Color (Border_Color (C (White)))
        .Build;
   begin
      Section ("a base and two state rules, either way");

      Assert (By_Aggregate = By_Chain,
              "a chain over three rules interns to the aggregate's handle");
   end Test_Several_Rules;

   procedure Test_Rule_Reuse is
      By_Aggregate : constant Widget_Style :=
        From (Empty_Style)
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             Color            => Set (C (White)),
                             others           => <>))
          .Build;

      By_Chain : constant Widget_Style :=
        Style_Of
        .On_Hover
          .Background (Deep)
        .On_Hover
          .Text_Color (C (White))
        .Build;
      --  Past Max_Style_Rules moves, a chain that took a fresh rule per
      --  move would run out and fold the rest onto whichever rule it
      --  was left standing on.
      Alternating : Composer := Style_Of;
   begin
      Section ("a selector named twice is one rule");

      Assert (By_Aggregate = By_Chain,
              ".On_Hover twice fills one rule rather than adding a second");

      for Unused_Pass in 1 .. Max_Style_Rules loop
         Alternating := Alternating.On_Hover.Background (Deep);
         Alternating := Alternating.On_Focus.Text_Color (C (White));
      end loop;
      Alternating := Alternating.On_Hover.Background (Deep);

      Assert (Alternating.Build
                = From (Empty_Style)
                    .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                                       others           => <>))
                    .On (Sel_Focused, (Color  => Set (C (White)),
                                       others => <>))
                    .Build,
              "moving between two selectors many times keeps two rules");
   end Test_Rule_Reuse;

   procedure Test_Empty_Chain is
      By_Builder : constant Widget_Style := Create.Build;
      By_Chain   : constant Widget_Style := Style_Of.Build;
   begin
      Section ("a chain that names nothing");

      Assert (By_Chain = By_Builder,
              "an empty chain interns to what an empty builder does");
      Assert (By_Chain = Empty_Widget_Style,
              "which is the empty style");
   end Test_Empty_Chain;

   ---------------------------------------------------------------------
   --  Every setter, one at a time
   ---------------------------------------------------------------------

   --  A setter that named the wrong field would compile and pass every
   --  test above, so each of the 34 gets an assertion of its own: the
   --  chain naming one property against the aggregate naming that field.
   procedure Same (Chain : Widget_Style; Agg : Style_Rules; Prop : String) is
   begin
      Assert (Chain = From (Agg).Build,
              "the " & Prop & " setter names the " & Prop & " field");
   end Same;

   procedure Test_Every_Setter is
      L  : constant Length_Value := Px (7.0);
      Sz : constant Size_Value := Size (Px (120.0));
   begin
      Section ("each setter against the field it names");

      Same (Style_Of.Text_Color (C (Red)).Build,
            (Color => Set (C (Red)), others => <>), "color");
      Same (Style_Of.Background (Blue).Build,
            (Background_Color => Set_Bg (Blue), others => <>),
            "background-color");
      Same (Style_Of.Radius (Round).Build,
            (Border_Radius => Set (Round), others => <>), "border-radius");
      Same (Style_Of.Border_Width (Border_Width (L)).Build,
            (Border_Width => Set (Border_Width (L)), others => <>),
            "border-width");
      Same (Style_Of.Border_Color (Border_Color (C (Lime))).Build,
            (Border_Color => Set (Border_Color (C (Lime))), others => <>),
            "border-color");
      Same (Style_Of.Border_Style (Border_Style (Dashed)).Build,
            (Border_Style => Set (Border_Style (Dashed)), others => <>),
            "border-style");
      Same (Style_Of.Outline_Width (L).Build,
            (Outline_Width => Set_Outline_Width (L), others => <>),
            "outline-width");
      Same (Style_Of.Outline_Color (C (Teal)).Build,
            (Outline_Color => Set_Outline_Color (C (Teal)), others => <>),
            "outline-color");
      Same (Style_Of.Outline_Offset (L).Build,
            (Outline_Offset => Set_Outline_Offset (L), others => <>),
            "outline-offset");
      Same (Style_Of.Padding (Pad).Build,
            (Padding => Set (Pad), others => <>), "padding");
      Same (Style_Of.Margin (Pad).Build,
            (Margin => Set_Margin (Pad), others => <>), "margin");
      Same (Style_Of.Width (Sz).Build,
            (Width => Set (Sz), others => <>), "width");
      Same (Style_Of.Height (Sz).Build,
            (Height => Set (Sz), others => <>), "height");
      Same (Style_Of.Min_Width (Sz).Build,
            (Min_Width => Set (Sz), others => <>), "min-width");
      Same (Style_Of.Max_Width (Sz).Build,
            (Max_Width => Set (Sz), others => <>), "max-width");
      Same (Style_Of.Min_Height (Sz).Build,
            (Min_Height => Set (Sz), others => <>), "min-height");
      Same (Style_Of.Max_Height (Sz).Build,
            (Max_Height => Set (Sz), others => <>), "max-height");
      Same (Style_Of.Font_Size (L).Build,
            (Font_Size => Set_Font (L), others => <>), "font-size");
      Same (Style_Of.Font_Weight (Weight_Bold).Build,
            (Font_Weight => Set (Weight_Bold), others => <>), "font-weight");
      Same (Style_Of.Text_Align (Text_Center).Build,
            (Text_Align => Set (Text_Center), others => <>), "text-align");
      Same (Style_Of.Text_Wrap_Mode (TWM_Nowrap).Build,
            (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>),
            "text-wrap-mode");
      Same (Style_Of.Display (Flex).Build,
            (Display => Set (Flex), others => <>), "display");
      Same (Style_Of.Overflow_X (Overflow_Scroll).Build,
            (Overflow_X => Set (Overflow_Scroll), others => <>), "overflow-x");
      Same (Style_Of.Overflow_Y (Overflow_Scroll).Build,
            (Overflow_Y => Set (Overflow_Scroll), others => <>), "overflow-y");
      Same (Style_Of.Opacity (0.5).Build,
            (Opacity => Set (Opacity_Value (0.5)), others => <>), "opacity");
      Same (Style_Of.Cursor_Style (Cursor_Pointer).Build,
            (Cursor => Set (Cursor_Pointer), others => <>), "cursor");
      Same (Style_Of.Box_Shadow (Drop).Build,
            (Box_Shadow => Set (Drop), others => <>), "box-shadow");
      Same (Style_Of.Flex_Direction (Column).Build,
            (Flex_Direction => Set (Column), others => <>), "flex-direction");
      Same (Style_Of.Justify_Content (Space_Between).Build,
            (Justify_Content => Set (Space_Between), others => <>),
            "justify-content");
      Same (Style_Of.Align_Items (Baseline).Build,
            (Align_Items => Set (Baseline), others => <>), "align-items");
      Same (Style_Of.Gap (Gap (Px (8.0))).Build,
            (Gap => Set (Gap (Px (8.0))), others => <>), "gap");
      Same (Style_Of.Flex_Grow (2.0).Build,
            (Flex_Grow => Set (Flex_Grow_Value (2.0)), others => <>),
            "flex-grow");
      Same (Style_Of.Flex_Shrink (3.0).Build,
            (Flex_Shrink => Set (Flex_Shrink_Value (3.0)), others => <>),
            "flex-shrink");
      Same (Style_Of.Transition ((0.2, Ease_Out, All_Properties)).Build,
            (Transition => Set ((0.2, Ease_Out, All_Properties)),
             others => <>),
            "transition");
   end Test_Every_Setter;

   ---------------------------------------------------------------------
   --  The gap axes
   ---------------------------------------------------------------------

   --  What a chain answers for the main part with no state active.
   function Base_Of (S : Widget_Style) return Style_Rules is
     (Rules_Of (Definition (S).Base));

   procedure Test_Gap_Axes is
      Both : constant Widget_Style :=
        Style_Of.Gap (Gap_Row (Px (4.0))).Gap (Gap_Column (Px (8.0))).Build;
      Then_Uniform : constant Widget_Style :=
        Style_Of.Gap (Gap_Row (Px (4.0))).Gap (Gap (Px (8.0))).Build;

      G : constant Gap_Value := Opt_Gap.Resolve (Base_Of (Both).Gap);
      U : constant Gap_Value := Opt_Gap.Resolve (Base_Of (Then_Uniform).Gap);
   begin
      Section ("one field, two axes");

      Assert (G.Kind = Gap_Separate, "two longhands leave the axes apart");
      if G.Kind = Gap_Separate then
         Assert (G.Row_Gap = Px (4.0) and then G.Has_Row,
                 "the row gap named first survives the column gap");
         Assert (G.Column_Gap = Px (8.0) and then G.Has_Column,
                 "and the column gap is the one named second");
      end if;

      Assert (U.Kind = Gap_Uniform and then U.All_Gap = Px (8.0),
              "a value naming both axes replaces one naming a single axis");
   end Test_Gap_Axes;

   ---------------------------------------------------------------------
   --  Against the runtime parser
   ---------------------------------------------------------------------

   --  The standing rule in this repository: the two pipelines resolve
   --  the same CSS the same way. Here one side is a chain and the other
   --  is Adi.CSS_Parser reading the declarations the chain names.
   procedure Test_Agrees_With_Parser is
      Source : constant String :=
        ".c {" & ASCII.LF
        & "  color: #ffffff;" & ASCII.LF
        & "  background-color: #2563eb;" & ASCII.LF
        & "  font-size: 14px;" & ASCII.LF
        & "  display: flex;" & ASCII.LF
        & "  flex-grow: 1;" & ASCII.LF
        & "  row-gap: 4px;" & ASCII.LF
        & "  column-gap: 8px;" & ASCII.LF
        & "}" & ASCII.LF;

      Sheet   : Adi.CSS_Parser.Rule_Sheet;
      Loaded  : Boolean;

      By_Chain : constant Widget_Style :=
        Style_Of
          .Text_Color (RGB (255, 255, 255))
          .Background (RGB (37, 99, 235))
          .Font_Size (Px (14.0))
          .Display (Flex)
          .Flex_Grow (1.0)
          .Gap (Gap_Row (Px (4.0)))
          .Gap (Gap_Column (Px (8.0)))
        .Build;
   begin
      Section ("a chain against the sheet it spells");

      Adi.CSS_Parser.Load_Rules (Sheet, Source, Loaded);
      Assert (Loaded, "the sheet parses");

      Assert (Intern_Rules
                (Adi.CSS_Parser.Base_Rules
                   (Sheet, Adi.CSS_Parser.Class_Selector, "c"))
              = Definition (By_Chain).Base,
              "the parser and the chain fold the same declarations to "
              & "one interned rule set");
   end Test_Agrees_With_Parser;

   ---------------------------------------------------------------------
   --  Deriving
   ---------------------------------------------------------------------

   Primary : constant Widget_Style :=
     Style_Of
       .Background (Blue)
       .Padding (Pad)
     .On_Hover
       .Background (Deep)
     .Build;

   procedure Test_Derived is
      Derived : constant Widget_Style :=
        Style_Of (Primary).Background (Danger).Build;

      Expected : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Danger),
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             others           => <>))
          .Build;
   begin
      Section ("a chain that opens on an existing style");

      Assert (Derived = Expected,
              "the base's other properties stand, the named one changes, "
              & "and the state rule comes through");
      Assert (Derived /= Primary, "and the derived style is a second one");
   end Test_Derived;

   procedure Test_Derived_State_Rule is
      Derived : constant Widget_Style :=
        Style_Of (Primary).On_Hover.Text_Color (C (White)).Build;

      Expected : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue),
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             Color            => Set (C (White)),
                             others           => <>))
          .Build;
   begin
      Section ("a derived chain reaching a rule the base already carries");

      Assert (Derived = Expected,
              "the hover rule takes the override rather than a rule of "
              & "its own");
   end Test_Derived_State_Rule;

   procedure Test_Clear is
      Cleared : constant Widget_Style :=
        Style_Of (Primary).Clear (Prop_Background_Color).Build;

      Expected : constant Widget_Style :=
        From ((Background_Color => No_Bg_Color,
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             others           => <>))
          .Build;
   begin
      Section ("clearing a property the base set");

      Assert (Cleared = Expected,
              ".Clear interns to the aggregate that names the property "
              & "cleared");
      Assert (Cleared /= Style_Of (Primary).Build,
              "and a cleared property is not an unset one");
   end Test_Clear;

   ---------------------------------------------------------------------
   --  What a repeat build costs
   ---------------------------------------------------------------------

   procedure Test_Repeat_Build_Interns_Nothing is
      Values : constant Natural := Interned_Values;
      Rules  : constant Natural := Interned_Rule_Sets;
      Styles : constant Natural := Interned_Styles;

      Again : constant Widget_Style :=
        Style_Of
          .Background (Blue)
          .Padding (Pad)
        .On_Hover
          .Background (Deep)
        .Build;
   begin
      Section ("a chain built a second time");

      Assert (Again = Primary, "answers the handle the first build did");
      Assert (Interned_Values = Values, "and interns no further value");
      Assert (Interned_Rule_Sets = Rules, "no further rule set");
      Assert (Interned_Styles = Styles, "and no further style");
   end Test_Repeat_Build_Interns_Nothing;

   ---------------------------------------------------------------------
   --  Degrading
   ---------------------------------------------------------------------

   procedure Test_Is_Live is
      Open_One : Composer := Style_Of;
      Built    : constant Composer := Style_Of;
      Unused   : Widget_Style;
   begin
      Section ("whether a chain still holds its buffer");

      Assert (Is_Live (Open_One), "a chain the pool granted holds one");

      Unused := Built.Background (Blue).Build;
      Assert (not Is_Live (Built), ".Build returns it");
      Assert (Unused /= Empty_Widget_Style, "and builds what it named");

      Open_One.Discard;
      Assert (not Is_Live (Open_One), ".Discard returns it too");
      Assert (Open_Chains = 0, "and the pool is empty again");
   end Test_Is_Live;

   procedure Test_Reclaim_Is_Visible is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Extra  : Composer;
      Before : constant Natural := Reclaimed_Chains;
      Answer : Widget_Style;
   begin
      Section ("a chain can see that its buffer was taken back");

      Held (1) := Style_Of (Primary);
      for I in 2 .. Held'Last loop
         Held (I) := Style_Of;
      end loop;
      Assert (Is_Live (Held (1)), "the oldest chain holds a buffer");

      Extra := Style_Of;
      Assert (Reclaimed_Chains = Before + 1, "opening on a full pool reclaims");
      Assert (not Is_Live (Held (1)),
              "and the chain it took the buffer from can see it is gone");
      Assert (Is_Live (Extra), "while the chain that took it holds one");

      --  The answer is plausible rather than wrong, which is why the
      --  predicate above and the report at .Build both exist.
      Answer := Held (1).Background (Danger).Build;
      Assert (Answer = Primary,
              "its .Build answers the style it opened on");

      Extra.Discard;
      for I in 2 .. Held'Last loop
         Held (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and every buffer comes back");
   end Test_Reclaim_Is_Visible;

   --  Discarding a chain whose buffer was already taken back must leave
   --  the ledger entry of whoever holds that buffer now alone. If it
   --  did not, the new holder would stop being orderable and would
   --  never be chosen as the oldest.
   procedure Test_Discard_After_Reclaim_Leaves_The_Ledger is
      First  : array (1 .. Max_Open_Chains) of Composer;
      Fresh  : array (1 .. Max_Open_Chains - 1) of Composer;
      Taker  : Composer;
      Last   : Composer;
   begin
      Section ("discarding a chain whose buffer moved on");

      for I in First'Range loop
         First (I) := Style_Of;
      end loop;

      Taker := Style_Of;
      Assert (not Is_Live (First (1)), "the oldest lost its buffer");

      --  The discard that must not touch Taker's ledger entry.
      First (1).Discard;
      for I in 2 .. First'Last loop
         First (I).Discard;
      end loop;
      Assert (Open_Chains = 1, "only the taker is left holding one");

      --  Taker is now the oldest of a full pool, so it is what the next
      --  chain must take back.
      for I in Fresh'Range loop
         Fresh (I) := Style_Of;
      end loop;
      Assert (Open_Chains = Max_Open_Chains, "the pool is full again");

      Last := Style_Of;
      Assert (not Is_Live (Taker),
              "the taker is still orderable, and is the oldest");
      for I in Fresh'Range loop
         Assert (Is_Live (Fresh (I)), "and no younger buffer was taken");
      end loop;

      Last.Discard;
      Taker.Discard;
      for I in Fresh'Range loop
         Fresh (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and every buffer comes back");
   end Test_Discard_After_Reclaim_Leaves_The_Ledger;

   procedure Test_Cascading_Reclaims is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Before : constant Natural := Reclaimed_Chains;
      Rounds : constant := 5;
   begin
      Section ("reclaiming again and again");

      for I in Held'Range loop
         Held (I) := Style_Of;
      end loop;

      --  Each of these finds the pool full, takes the oldest buffer and
      --  keeps it, so the pool stays exactly full throughout and the
      --  count rises by exactly one a time.
      for Round in 1 .. Rounds loop
         declare
            Taker : Composer := Style_Of;
         begin
            Assert (Reclaimed_Chains = Before + Round,
                    "each reclaim is counted once");
            Assert (Open_Chains = Max_Open_Chains,
                    "and the pool stays exactly full");
            Assert (Is_Live (Taker), "the taker holds the buffer");
            Taker.Discard;
            Assert (Open_Chains = Max_Open_Chains - 1,
                    "discarding it frees exactly one");
            Held (Round) := Style_Of;
         end;
      end loop;

      for I in Held'Range loop
         Held (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and nothing is left held");
   end Test_Cascading_Reclaims;

   procedure Test_Clock_Survives_Churn is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Before : constant Natural := Reclaimed_Chains;
      Unused : Widget_Style;
   begin
      Section ("ordering after the pool has emptied many times");

      --  Every one of these empties the pool, which is what resets the
      --  clock that orders the held buffers.
      for I in 1 .. 200 loop
         Unused := Style_Of.Flex_Grow (Flex_Grow_Value (Float (I mod 8)))
                     .Build;
      end loop;
      Assert (Open_Chains = 0, "the churn leaves nothing held");
      Assert (Reclaimed_Chains = Before,
              "and never had to reclaim, the pool never being full");

      --  The oldest is still the oldest after all that.
      for I in Held'Range loop
         Held (I) := Style_Of;
      end loop;
      declare
         Taker : Composer := Style_Of;
      begin
         Assert (not Is_Live (Held (1)),
                 "the buffer taken back is the one held longest");
         for I in 2 .. Held'Last loop
            Assert (Is_Live (Held (I)), "and no other is disturbed");
         end loop;
         Taker.Discard;
      end;

      for I in Held'Range loop
         Held (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and every buffer comes back");
      Assert (Unused /= Empty_Widget_Style, "the churn built real styles");
   end Test_Clock_Survives_Churn;

   procedure Test_Full_Pool_Reclaims is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Extra  : Composer;
      Before : constant Natural := Reclaimed_Chains;
   begin
      Section ("a pool with every chain buffer held");

      Assert (Open_Chains = 0, "the pool starts with nothing open");

      --  The first is the oldest, and opens on a style, so what it
      --  answers once reclaimed says what a reclaim costs a caller.
      Held (1) := Style_Of (Primary);
      for I in 2 .. Held'Last loop
         Held (I) := Style_Of;
      end loop;
      Assert (Open_Chains = Max_Open_Chains, "every buffer is held");

      Extra := Style_Of;
      Assert (Reclaimed_Chains = Before + 1,
              "a chain opening on a full pool takes the oldest buffer back");
      Assert (Open_Chains = Max_Open_Chains,
              "and holds that one rather than adding a ninth");

      Assert (Held (1).Background (Danger).Build = Primary,
              "the reclaimed chain answers the style it opened on, with "
              & "the override it named not applied");

      Assert (Extra.Background (Blue).Build
                = From ((Background_Color => Set_Bg (Blue),
                         others           => <>)).Build,
              "and the chain that took the buffer builds normally");

      for I in 2 .. Held'Last loop
         Held (I).Discard;
      end loop;
      Held (1).Discard;
      Assert (Open_Chains = 0,
              "discarding returns every buffer, and discarding a "
              & "reclaimed chain takes none from its new holder");
   end Test_Full_Pool_Reclaims;

   procedure Test_Full_Buffer is
      Before : constant Natural := Dropped_Chain_Slots;
      Full   : Composer := Style_Of;
      Built  : Widget_Style;

      Expected : constant Widget_Style :=
        From ((Flex_Grow => Set (Flex_Grow_Value (Float (Max_Chain_Slots))),
               others    => <>)).Build;
   begin
      Section ("a chain longer than its buffer");

      for I in 1 .. Max_Chain_Slots loop
         Full := Full.Flex_Grow (Flex_Grow_Value (Float (I)));
      end loop;
      Assert (Dropped_Chain_Slots = Before,
              "a chain filling the buffer exactly drops nothing");

      Full := Full.Background (Blue);
      Assert (Dropped_Chain_Slots = Before + 1,
              "the step past the buffer is dropped and counted");

      Full := Full.Text_Color (C (White));
      Assert (Dropped_Chain_Slots = Before + 2,
              "and so is the next");

      Built := Full.Build;
      Assert (Built = Expected,
              "what fits is what the style carries, and the chain builds "
              & "rather than raising");
      Assert (Open_Chains = 0, "and the buffer comes back");
   end Test_Full_Buffer;

   procedure Test_Uncomposable_Property is
      Before : constant Widget_Style := Style_Of.Background (Blue).Build;
      After  : constant Widget_Style :=
        Style_Of.Background (Blue).Clear (Prop_Font_Family).Build;
   begin
      Section ("a property the chain carries no setter for");

      Assert (not Composable_Properties (Prop_Font_Family),
              "font-family is outside the composed set");
      Assert (After = Before,
              "clearing one is reported and leaves the chain alone");
   end Test_Uncomposable_Property;

   procedure Test_Chain_Leaves_No_Buffer is
   begin
      Section ("what the suite leaves behind");

      Assert (Open_Chains = 0,
              "every chain built or discarded above returned its buffer");
   end Test_Chain_Leaves_No_Buffer;

begin
   Start_Suite ("Style Composer Test");

   Test_Widths;
   Test_Value_Refs;
   Test_One_Property;
   Test_Several_Properties;
   Test_Several_Rules;
   Test_Every_Setter;
   Test_Gap_Axes;
   Test_Agrees_With_Parser;
   Test_Rule_Reuse;
   Test_Empty_Chain;
   Test_Derived;
   Test_Derived_State_Rule;
   Test_Clear;
   Test_Repeat_Build_Interns_Nothing;
   Test_Is_Live;
   Test_Full_Pool_Reclaims;
   Test_Reclaim_Is_Visible;
   Test_Discard_After_Reclaim_Leaves_The_Ledger;
   Test_Cascading_Reclaims;
   Test_Clock_Survives_Churn;
   Test_Full_Buffer;
   Test_Uncomposable_Property;
   Test_Chain_Leaves_No_Buffer;

   Finish;
end Style_Composer_Test;
