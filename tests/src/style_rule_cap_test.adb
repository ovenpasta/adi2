pragma Ada_2022;

with Ada.Exceptions;    use Ada.Exceptions;
with Ada.Strings.Fixed;
with Adi.CSS_Source;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Style_Merge_Testing;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.Widget_Styles.Testing;
with Test_Support;      use Test_Support;

--  Past Max_Style_Rules a rule has nowhere to go. Every path that can
--  reach that point says so: Add_Rule and the fluent builder raise
--  Too_Many_Style_Rules, and a merge, which has no channel to report
--  through, drops the rule and counts it.

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
   Test_Try_Add_Rule_Reports;
   Test_One_Fold_Behind_Both_Entries;
   Test_Merge_Reports_The_Drop;

   Finish;
end Style_Rule_Cap_Test;
