pragma Ada_2022;

with Ada.Exceptions;    use Ada.Exceptions;
with Ada.Strings.Fixed;
with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Style_Merge_Testing;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.Widget_Styles.Testing;
with Test_Support;      use Test_Support;

--  Past Max_Style_Rules a rule has nowhere to go. Every path that can
--  reach that point says so, and every drop is counted the same way:
--  Add_Rule and the fluent builder raise Too_Many_Style_Rules; a merge
--  and a composer chain, which have no channel to report through, drop
--  the rule and count it.

procedure Style_Rule_Cap_Test is

   --  Max_Style_Rules distinct selectors, plus one that does not fit.
   Selectors : constant array (1 .. Max_Style_Rules + 1) of State_Selector :=
     [When_State (State_Normal),        When_State (State_Hovered),
      When_State (State_Pressed),       When_State (State_Focused),
      When_State (State_Disabled),      When_State (State_Selected),
      When_Not (State_Normal),          When_Not (State_Hovered),
      When_Not (State_Pressed),         When_Not (State_Focused),
      When_Not (State_Disabled),        When_Not (State_Selected),
      When_Part_State (State_Normal),   When_Part_State (State_Hovered),
      When_Part_State (State_Pressed),  When_Part_State (State_Focused),
      When_Part_State (State_Selected)];

   Filler : constant Style_Rules :=
     (Opacity => Set (0.5), others => <>);

   function Rule (I : Positive) return State_Rule is
     ((Selector => Selectors (I),
       Style    => Intern_Rules (Filler),
       Priority => 0));

   function Full_Definition return Style_Definition is
      Result : Style_Definition := Empty_Style_Definition;
   begin
      for I in 1 .. Max_Style_Rules loop
         Add_Rule (Result, Rule (I));
      end loop;
      return Result;
   end Full_Definition;

   function Full_Style return Widget_Style is (Intern (Full_Definition));

   function Overflowing_Style return Widget_Style is
      Result : Style_Definition := Empty_Style_Definition;
   begin
      Add_Rule (Result, Rule (Max_Style_Rules + 1));
      return Intern (Result);
   end Overflowing_Style;

   function Contains (Haystack, Needle : String) return Boolean is
     (Ada.Strings.Fixed.Index (Haystack, Needle) > 0);

   ---------------------------------------------------------------------------

   procedure Test_Cap_Is_Reachable is
      WS : constant Widget_Style := Full_Style;
   begin
      Section ("Max_Style_Rules rules fit");
      Assert (Definition (WS).Rule_Count = Max_Style_Rules,
              "a style holds Max_Style_Rules rules");
   end Test_Cap_Is_Reachable;

   procedure Test_Add_Rule_Raises is
      WS : Style_Definition := Full_Definition;
   begin
      Section ("Add_Rule past the cap raises, naming the selector");
      Add_Rule (WS, Rule (Max_Style_Rules + 1));
      Assert (False, "Add_Rule past the cap raises");
   exception
      when E : Too_Many_Style_Rules =>
         Assert (True, "Add_Rule past the cap raises Too_Many_Style_Rules");
         Assert (Contains (Exception_Message (E), "::part:selected"),
                 "the message names the selector that did not fit");
      when E : others =>
         Assert (False,
                 "Add_Rule raised " & Exception_Name (E)
                 & " rather than Too_Many_Style_Rules");
   end Test_Add_Rule_Raises;

   procedure Test_Builder_Chain_Raises is
      B : Style_Builder := From (Filler);
   begin
      Section ("A .On chain past the cap raises the same way");
      for I in Selectors'Range loop
         B := B.On (Selectors (I), Filler);
      end loop;
      Assert (False, "a .On chain past the cap raises");
   exception
      when Too_Many_Style_Rules =>
         Assert (True, "a .On chain past the cap raises Too_Many_Style_Rules");
      when E : others =>
         Assert (False,
                 "the builder raised " & Exception_Name (E)
                 & " rather than Too_Many_Style_Rules");
   end Test_Builder_Chain_Raises;

   --  A chain has no channel to report through either, so it drops the
   --  rule the way a merge does. What the setters after the drop must
   --  not do is land on the rule the chain last stood on.
   procedure Test_Chain_Past_The_Cap is
      Ceiling  : Composer := Style_Of;
      Chain    : Composer := Style_Of;
      Expected : Widget_Style;
      Built    : Widget_Style;
      Before   : Natural;
   begin
      Section ("A chain naming more selectors than a style holds");

      for I in 1 .. Max_Style_Rules loop
         Ceiling := Ceiling.On (Selectors (I)).Opacity (0.5);
      end loop;
      Expected := Ceiling.Build;

      Before := Adi.Widget_Styles.Testing.Dropped_Rules;

      for I in 1 .. Max_Style_Rules loop
         Chain := Chain.On (Selectors (I)).Opacity (0.5);
      end loop;
      Chain := Chain.On (Selectors (Max_Style_Rules + 1)).Opacity (0.125);
      Built := Chain.Build;

      Assert (Adi.Widget_Styles.Testing.Dropped_Rules = Before + 1,
              "the rule past the cap is counted, as a merge's is");
      Assert (Definition (Built).Rule_Count = Max_Style_Rules,
              "the style holds the rules that fit");
      Assert (Built = Expected,
              "and the properties named after the drop go nowhere rather "
              & "than onto the rule the chain last stood on");
      Assert (Open_Chains = 0, "the chain returns its buffer");
   end Test_Chain_Past_The_Cap;

   --  A chain that has dropped a rule keeps going: naming a rule it
   --  already holds, or the base, is where the setters land again.
   procedure Test_Chain_Recovers_From_The_Drop is
      Chain    : Composer := Style_Of;
      Expected : Composer := Style_Of;
   begin
      Section ("A chain names a rule again after a drop");

      for I in 1 .. Max_Style_Rules loop
         Chain := Chain.On (Selectors (I)).Opacity (0.5);
         Expected := Expected.On (Selectors (I)).Opacity (0.5);
      end loop;

      Chain := Chain.On (Selectors (Max_Style_Rules + 1)).Opacity (0.125);
      Chain := Chain.On_Base.Opacity (0.75);
      Chain := Chain.On (Selectors (1)).Opacity (0.25);

      Expected := Expected.On_Base.Opacity (0.75);
      Expected := Expected.On (Selectors (1)).Opacity (0.25);

      Assert (Chain.Build = Expected.Build,
              "the base and a rule the chain holds take their setters "
              & "again");
   end Test_Chain_Recovers_From_The_Drop;

   procedure Test_Try_Add_Rule_Reports is
      WS    : Style_Definition := Full_Definition;
      Added : Boolean;
      Before : constant Natural := Adi.Widget_Styles.Testing.Dropped_Rules;
   begin
      Section ("Try_Add_Rule answers False past the cap and counts the drop");
      Try_Add_Rule (WS, Rule (Max_Style_Rules + 1), Added);
      Assert (not Added, "the rule past the cap is not added");
      Assert (WS.Rule_Count = Max_Style_Rules,
              "the definition is left as it was");
      Assert (Adi.Widget_Styles.Testing.Dropped_Rules = Before + 1,
              "the dropped rule is counted");
   end Test_Try_Add_Rule_Reports;

   --  Adi.CSS_Source.Merge_Part_Styles is public and generated UI bodies
   --  call it; Adi.CSS_Parser folds a sheet the same way. One fold, in
   --  Adi.Widget where Part_Style_Array is declared, keeps the two from
   --  drifting -- and keeps the cap reported rather than silent.
   --  The runtime parser has a channel to report through, so it refuses
   --  the whole sheet the way tools/css_to_ada.py refuses to generate
   --  one, and the sheet already in force is what stands.
   Kept_Sheet : constant String :=
     ".kept { opacity: 0.5; }";

   --  Max_Style_Rules + 1 distinct state selectors on one selector.
   Overflowing_Sheet : constant String :=
     ""
        & ".capped:hover { opacity: 0.01; }"
        & ".capped:active { opacity: 0.02; }"
        & ".capped:focus { opacity: 0.03; }"
        & ".capped:disabled { opacity: 0.04; }"
        & ".capped:checked { opacity: 0.05; }"
        & ".capped:not(:hover) { opacity: 0.06; }"
        & ".capped:not(:active) { opacity: 0.07; }"
        & ".capped:not(:focus) { opacity: 0.08; }"
        & ".capped:not(:disabled) { opacity: 0.09; }"
        & ".capped:not(:checked) { opacity: 0.10; }"
        & ".capped:hover:focus { opacity: 0.11; }"
        & ".capped:hover:active { opacity: 0.12; }"
        & ".capped:hover:disabled { opacity: 0.13; }"
        & ".capped:hover:checked { opacity: 0.14; }"
        & ".capped:focus:active { opacity: 0.15; }"
        & ".capped:focus:disabled { opacity: 0.16; }"
        & ".capped:focus:checked { opacity: 0.17; }";

   procedure Test_Parser_Refuses_The_Sheet is
      Sheet   : Adi.CSS_Parser.Stylesheet;
      Success : Boolean;
   begin
      Section ("The runtime parser refuses a sheet past the cap");

      Adi.CSS_Parser.Load_String (Sheet, Kept_Sheet, Success);
      Assert (Success, "a sheet under the cap loads");

      Adi.CSS_Parser.Load_String (Sheet, Overflowing_Sheet, Success);
      Assert (not Success, "a sheet past the cap does not load");
      Assert (Contains (Adi.CSS_Parser.Get_Last_Error (Sheet), "'capped'"),
              "the error names the CSS selector");
      Assert (Contains (Adi.CSS_Parser.Get_Last_Error (Sheet),
                        ":focused:selected"),
              "and the state selector that did not fit");
      Assert (Adi.CSS_Parser.Has_Class (Sheet, "kept"),
              "and the sheet in force is the one that stands");
      Assert (not Adi.CSS_Parser.Has_Class (Sheet, "capped"),
              "nothing of the refused sheet is kept");

      Adi.CSS_Parser.Destroy (Sheet);
   end Test_Parser_Refuses_The_Sheet;

   procedure Test_One_Fold_Behind_Both_Entries is
      Base : Part_Style_Array := Empty_Part_Styles;
      Over : Part_Style_Array := Empty_Part_Styles;
      Extra : Style_Definition := Empty_Style_Definition;
      Before : Natural;
   begin
      Section ("One fold behind the public entry and the parser");

      Add_Rule (Extra, Rule (1));
      Add_Rule (Extra, Rule (2));
      Base (Main_Part) := (Style => Full_Style, Enabled => True);
      Base (Label_Part) :=
        (Style => From ((Opacity => Set (0.25), others => <>)).Build,
         Enabled => True);
      Over (Main_Part) := (Style => Intern (Extra), Enabled => True);
      Over (Label_Part) :=
        (Style => From ((Opacity => Set (0.75), others => <>)).Build,
         Enabled => True);

      Assert (Adi.CSS_Source.Merge_Part_Styles (Base, Over)
                = Adi.Style_Merge_Testing.Merge (Base, Over),
              "the public entry is the shared fold");

      --  Rule (1) and Rule (2) are already in Full_Style, so they merge
      --  rather than overflow: the fold has to reach both outcomes.
      Assert (Definition (Adi.Style_Merge_Testing.Merge (Base, Over)
                            (Main_Part).Style).Rule_Count = Max_Style_Rules,
              "a selector both sides name merges in place");
      Assert (Definition (Adi.Style_Merge_Testing.Merge (Base, Over)
                            (Label_Part).Style).Base
                /= Definition (Base (Label_Part).Style).Base,
              "and the base rules fold too");

      Before := Adi.Widget_Styles.Testing.Dropped_Rules;
      Over (Main_Part) :=
        (Style => Overflowing_Style, Enabled => True);
      declare
         Merged : constant Part_Style_Array :=
           Adi.Style_Merge_Testing.Merge (Base, Over);
      begin
         Assert (Definition (Merged (Main_Part).Style).Rule_Count
                   = Max_Style_Rules,
                 "the shared fold holds the cap");
      end;
      Assert (Adi.Widget_Styles.Testing.Dropped_Rules = Before + 1,
              "and reports the rule it could not fit");
   end Test_One_Fold_Behind_Both_Entries;

   procedure Test_Merge_Reports_The_Drop is
      Base : Part_Style_Array := Empty_Part_Styles;
      Over : Part_Style_Array := Empty_Part_Styles;
      Overflow : Style_Definition := Empty_Style_Definition;
      Before : Natural;
   begin
      Section ("A merge past the cap drops the rule rather than raising");

      Add_Rule (Overflow, Rule (Max_Style_Rules + 1));
      Base (Main_Part) := (Style => Full_Style, Enabled => True);
      Over (Main_Part) := (Style => Intern (Overflow), Enabled => True);

      Before := Adi.Widget_Styles.Testing.Dropped_Rules;

      declare
         Merged : constant Part_Style_Array :=
           Adi.CSS_Source.Merge_Part_Styles (Base, Over);
      begin
         Assert (Definition (Merged (Main_Part).Style).Rule_Count
                   = Max_Style_Rules,
                 "the merged style still holds Max_Style_Rules rules");
      end;

      Assert (Adi.Widget_Styles.Testing.Dropped_Rules = Before + 1,
              "the merge counts the rule it dropped");
   end Test_Merge_Reports_The_Drop;

begin
   Start_Suite ("Style Rule Cap Test");

   Test_Cap_Is_Reachable;
   Test_Add_Rule_Raises;
   Test_Builder_Chain_Raises;
   Test_Chain_Past_The_Cap;
   Test_Chain_Recovers_From_The_Drop;
   Test_Try_Add_Rule_Reports;
   Test_Parser_Refuses_The_Sheet;
   Test_One_Fold_Behind_Both_Entries;
   Test_Merge_Reports_The_Drop;

   Finish;
end Style_Rule_Cap_Test;
