pragma Ada_2022;

with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Text_IO;             use Ada.Text_IO;
with Adi.Core;
with Adi.CSS_Source;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;          use Adi.Widget.Box;
with Adi.Widget.Testing;
with Adi.Widget_Properties;   use Adi.Widget_Properties;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Test_Properties;
with Test_Support;            use Test_Support;
with Widget_Property_Static_Styles;
with Widget_Property_Styles;

--  Domain state as a selector: [severity="critical"] on a widget the
--  application moves from ok to critical while it runs.
procedure Widget_Property_Test is

   package TP renames Test_Properties;

   use type TP.Severity_Level;
   use type TP.Link_State;
   use type Adi.Core.Normalized;

   Corpus_Path : constant String := "tests/css/widget_property.css";

   type Selector_Array is array (Positive range <>) of Unbounded_String;

   function Is_RGB (C : Color_Value; R, G, B : Natural) return Boolean is
     (C.Kind = RGB and then C.R = R and then C.G = G and then C.B = B);

   function Pad_Amount (S : Resolved_Style) return Float is
     (case S.Padding.Kind is
        when Gap_Uniform => S.Padding.All_Sides.Amount,
        when Axis        => S.Padding.Vertical.Amount,
        when Per_Side    => S.Padding.Sides (Top).Amount);

   function Border_Amount (S : Resolved_Style) return Float is
     (case S.Border_Width.Kind is
        when Gap_Uniform => S.Border_Width.All_Edges.Amount,
        when Per_Edge    => S.Border_Width.Edges (Top).Amount);

   ---------------------------------------------------------------------------
   --  The registry, which the runtime parser reaches by name
   ---------------------------------------------------------------------------

   procedure Test_Registry is
   begin
      Section ("vocabulary");

      Assert (TP.Severity.Id /= No_Property,
              "an instantiation registers its property");
      Assert (TP.Severity.Value (TP.Critical) /= No_Value,
              "and every literal of its enumeration");
      Assert (Property_Of (TP.Severity.Value (TP.Critical)) = TP.Severity.Id,
              "a value names the property it was declared under");
      Assert (Name_Of (TP.Severity.Id) = "severity",
              "the registry keeps the name it was built from");
      Assert (Name_Of (TP.Severity.Value (TP.Critical)) = "critical",
              "and the literal's image, folded");

      Assert (Find_Property ("severity") = TP.Severity.Id,
              "a name resolves to the entry declared under it");
      Assert (Find_Property ("SEVERITY") = TP.Severity.Id,
              "and does so whatever the case");
      Assert (Find_Property ("nonesuch") = No_Property,
              "a name never declared has no entry");
      Assert (Find_Value (TP.Severity.Id, "critical")
                = TP.Severity.Value (TP.Critical),
              "a value resolves under its own property");
      Assert (Find_Value (TP.Severity.Id, "nonesuch") = No_Value,
              "and a name the enumeration does not carry resolves to none");
      Assert (Find_Value (TP.Link.Id, "critical") = No_Value,
              "and not under another's");

      --  Two properties carrying a value of the same name reach two
      --  entries, which is what the generated sheet leans on.
      Assert (TP.Power.Value (TP.On) /= TP.Radio.Value (TP.On),
              "one value name under two properties is two entries");
      Assert (Find_Value (TP.Power.Id, "on") = TP.Power.Value (TP.On),
              "and each resolves under its own property");
      Assert (Find_Value (TP.Radio.Id, "on") = TP.Radio.Value (TP.On),
              "both ways round");

      Assert (Property_Count >= 5, "the properties declared are counted");
      Assert (Value_Count (TP.Severity.Id) = 3,
              "a property carries the values its enumeration has");
      Assert (Value_Count (TP.Link.Id) = 2, "each of its own");
      Assert (Value_Count (No_Property) = 0, "and the null entry none");
   end Test_Registry;

   --  A property is reachable by name only where it asked to be. The
   --  runtime parser is the one caller that has nothing but a name, so
   --  the gate sits at the property and covers its values with it.
   procedure Test_Name_Gating is
   begin
      Section ("names, which only dynamic CSS text needs");

      Assert (Has_Names (TP.Severity.Id),
              "a property declared for dynamic lookup keeps its name");
      Assert (not Has_Names (TP.Quiet.Id),
              "and one declared without it keeps none");

      Assert (Find_Property ("quiet") = No_Property,
              "so a dynamic sheet cannot name it");
      Assert (Find_Value (TP.Quiet.Id, "yes") = No_Value,
              "nor any of its values");
      Assert (Name_Of (TP.Quiet.Id) = "",
              "and the registry has no name to answer with");
      Assert (Name_Of (TP.Quiet.Value (TP.Yes)) = "",
              "for the property or its values");

      --  The constants still work, which is the whole point.
      Assert (TP.Quiet.Id /= No_Property,
              "the property is declared all the same");
      Assert (TP.Quiet.Value (TP.Yes) /= No_Value, "and so are its values");
      Assert (TP.Quiet.Value (TP.Yes) /= TP.Quiet.Value (TP.No),
              "which stay distinct");
      Assert (TP.Quiet.CSS_Name (TP.Yes) = "yes",
              "and the enumeration still answers what it is called");
   end Test_Name_Gating;

   ---------------------------------------------------------------------------
   --  The typed facade, which is what an application writes
   ---------------------------------------------------------------------------

   procedure Test_Enumerated is
      W : constant Box_Handle := Create_Handle;
   begin
      Section ("the enumeration a property is declared from");

      Assert (TP.Severity.CSS_Name (TP.Critical) = "critical",
              "a literal's CSS name is its image, folded");
      Assert (TP.Link.CSS_Name (TP.Offline) = "offline",
              "for every literal of the enumeration");

      Assert (not TP.Severity.Is_Set (+W),
              "a fresh widget names no property");
      Assert (TP.Severity.Get (+W, TP.Ok) = TP.Ok,
              "and answers the default it was given");

      TP.Severity.Set (+W, TP.Critical);
      Assert (TP.Severity.Is_Set (+W), "setting one names it");
      Assert (TP.Severity.Get (+W, TP.Ok) = TP.Critical,
              "and it answers the literal set");

      TP.Severity.Set (+W, TP.Warning);
      Assert (TP.Severity.Get (+W, TP.Ok) = TP.Warning,
              "setting it again replaces what it held");

      --  A second property on the same widget leaves the first alone.
      TP.Link.Set (+W, TP.Degraded);
      Assert (TP.Severity.Get (+W, TP.Ok) = TP.Warning
                and then TP.Link.Get (+W, TP.Offline) = TP.Degraded,
              "two properties sit on one widget");

      TP.Severity.Clear (+W);
      Assert (not TP.Severity.Is_Set (+W), "clearing one takes it off");
      Assert (TP.Link.Is_Set (+W), "and leaves the other");
   end Test_Enumerated;

   ---------------------------------------------------------------------------

   procedure Test_Assignments is
      Critical : constant Property_Value := TP.Severity.Value (TP.Critical);
      Ok       : constant Property_Value := TP.Severity.Value (TP.Ok);
      Degraded : constant Property_Value := TP.Link.Value (TP.Degraded);

      A : constant Property_Assignment := With_Value (Empty_Assignment, Critical);
      B : constant Property_Assignment := With_Value (Empty_Assignment, Critical);
      C : constant Property_Assignment := With_Value (Empty_Assignment, Ok);
      Two : constant Property_Assignment := With_Value (A, Degraded);
      Swapped : constant Property_Assignment :=
        With_Value (With_Value (Empty_Assignment, Degraded), Critical);
   begin
      Section ("assignments intern canonically");

      Assert (Assigned_Count (Empty_Assignment) = 0,
              "a widget naming no property carries nothing");
      Assert (A = B, "equal assignments are one index");
      Assert (A /= C, "different values are different indices");
      Assert (Value_Of (A, TP.Severity.Id) = Critical,
              "an assignment answers the value it holds");
      Assert (Value_Of (A, TP.Link.Id) = No_Value,
              "and nothing for a property it does not");

      Assert (Assigned_Count (Two) = 2, "two properties, two pairs");
      Assert (Two = Swapped, "the order they were set in leaves no trace");

      Assert (With_Value (A, Ok) = C,
              "setting a property again replaces what it held");
      Assert (Without (Two, TP.Link.Id) = A, "clearing one leaves the other");
      Assert (Without (A, TP.Severity.Id) = Empty_Assignment,
              "clearing the last one empties the assignment");
      Assert (Without (A, TP.Link.Id) = A,
              "clearing a property never set changes nothing");
   end Test_Assignments;

   procedure Test_Conditions is
      Crit_V   : constant Property_Value := TP.Severity.Value (TP.Critical);
      Ok_V     : constant Property_Value := TP.Severity.Value (TP.Ok);
      Degr_V   : constant Property_Value := TP.Link.Value (TP.Degraded);

      Critical : constant Property_Conditions := Conditions_On (Crit_V);
      Any_Link : constant Property_Conditions := Conditions_On (TP.Link.Id);
      Pair     : constant Property_Conditions := Both (Critical, Any_Link);
      Not_Crit : constant Property_Conditions := Conditions_Excluding (Crit_V);
      No_Link  : constant Property_Conditions :=
        Conditions_Excluding (TP.Link.Id);

      Crit_Only : constant Property_Assignment :=
        With_Value (Empty_Assignment, Crit_V);
      Crit_Link : constant Property_Assignment :=
        With_Value (Crit_Only, Degr_V);
      Ok_Only   : constant Property_Assignment :=
        With_Value (Empty_Assignment, Ok_V);
   begin
      Section ("conditions");

      Assert (Condition_Count (No_Conditions) = 0,
              "a selector naming no property sets no condition");
      Assert (Condition_Count (Critical) = 1, "an equality is one condition");
      Assert (Condition_Count (Pair) = 2, "two of them are two");
      Assert (Condition_Count (Not_Crit) = 1,
              "a negated condition is one as well");

      --  Common is what "or" folds two selectors' conditions with, and
      --  the pair it keeps is the one both sides name.
      Assert (Condition_Count (Common (Pair, Critical)) = 1,
              "Common keeps the condition both sides name");
      Assert (Satisfied_By (Common (Pair, Critical), Crit_Only),
              "which holds of an assignment naming that one alone");
      Assert (Common (Pair, Critical) = Common (Critical, Pair),
              "and answers the same either way round");
      Assert (Condition_Count (Common (Critical, Any_Link)) = 0,
              "conditions with nothing in common fold to none");
      Assert (Common (Pair, No_Conditions) = No_Conditions,
              "and anything folded with none is none");

      Assert (Satisfied_By (No_Conditions, Empty_Assignment),
              "no conditions hold of every assignment");
      Assert (Satisfied_By (No_Conditions, Crit_Link),
              "including one that names properties");

      Assert (Satisfied_By (Critical, Crit_Only),
              "an equality holds when the value matches");
      Assert (not Satisfied_By (Critical, Ok_Only),
              "and fails when it does not");
      Assert (not Satisfied_By (Critical, Empty_Assignment),
              "and fails when the property is unset");

      Assert (Satisfied_By (Any_Link, Crit_Link),
              "an existence condition holds whatever the value");
      Assert (not Satisfied_By (Any_Link, Crit_Only),
              "and fails when the property is unset");

      Assert (Satisfied_By (Pair, Crit_Link),
              "two conditions hold when both do");
      Assert (not Satisfied_By (Pair, Crit_Only),
              "and fail when one does not");

      --  :not() is the only way CSS says "anything but", so it has to
      --  hold of a widget naming the property not at all.
      Assert (not Satisfied_By (Not_Crit, Crit_Only),
              "a negated equality fails against the value it names");
      Assert (Satisfied_By (Not_Crit, Ok_Only),
              "holds against another value");
      Assert (Satisfied_By (Not_Crit, Empty_Assignment),
              "and holds against a widget naming no property at all");

      Assert (not Satisfied_By (No_Link, Crit_Link),
              "a negated existence fails when the property is set");
      Assert (Satisfied_By (No_Link, Crit_Only),
              "and holds when it is not");

      --  A required and an excluded condition on one value is the
      --  selector that matches nothing, which is what CSS says of it.
      Assert (not Satisfied_By (Both (Critical, Not_Crit), Crit_Only),
              "requiring and excluding one value matches nothing");
      Assert (not Satisfied_By (Both (Critical, Not_Crit), Empty_Assignment),
              "whatever the widget names");

      Assert (Both (Critical, No_Conditions) = Critical,
              "adding nothing to a condition set changes nothing");
      Assert (Both (Critical, Critical) = Critical,
              "and neither does adding what it already names");
      Assert (Both (Critical, Any_Link) = Both (Any_Link, Critical),
              "the order they were combined in leaves no trace");
      Assert (Critical /= Not_Crit,
              "a condition and its negation are two distinct sets");
   end Test_Conditions;

   procedure Test_Selectors is
      Crit_V : constant Property_Value := TP.Severity.Value (TP.Critical);
      Crit : constant State_Selector := When_Property (Crit_V);
      Hot  : constant State_Selector :=
        When_Property (Crit_V) and When_State (State_Hovered);
      Not_Crit : constant State_Selector := When_Not_Property (Crit_V);
      Crit_Only : constant Property_Assignment :=
        With_Value (Empty_Assignment, Crit_V);
   begin
      Section ("selectors");

      Assert (Specificity (Crit) = 1, "a property condition scores one");
      Assert (Specificity (Hot) = 2,
              "[severity=critical]:hover scores two");
      Assert (Specificity (Not_Crit) = 1,
              "a negated condition scores one, as :not() does");
      Assert (Specificity (Any_State) = 0, "and any-state still scores none");

      Assert (Matches (Crit, No_States, No_States, Crit_Only),
              "a property selector matches the assignment naming it");
      Assert (not Matches (Crit, No_States, No_States, Empty_Assignment),
              "and does not match a widget naming no property");
      Assert (not Matches (Crit, No_States),
              "a call naming no assignment reads as the empty one");

      Assert (not Matches (Not_Crit, No_States, No_States, Crit_Only),
              "a negated selector fails against the value it names");
      Assert (Matches (Not_Crit, No_States, No_States, Empty_Assignment),
              "and holds against a widget naming no property");

      Assert (not Matches (Hot, No_States, No_States, Crit_Only),
              "the hover half still has to hold");
      Assert (Matches (Hot, Single_State (State_Hovered), No_States,
                       Crit_Only),
              "and holds when it does");

      --  A state selector carrying no property is what every selector
      --  written before this was, and must still match on states alone.
      Assert (Matches (When_State (State_Hovered),
                       Single_State (State_Hovered), No_States,
                       Crit_Only),
              "a state-only selector ignores what the widget names");
      Assert (Matches (Any_State, No_States, No_States, Crit_Only),
              "and so does any-state");
   end Test_Selectors;

   ---------------------------------------------------------------------------

   procedure Test_Widget_Cascade is
      Source : Adi.CSS_Source.Style_Source;
      W      : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;

      function Margin_Top return Float is
        (Get_Resolved_Part_Style (+W, Main_Part).Margin (Top).Length.Amount);
      function Outline return Float is
        (Get_Resolved_Part_Style (+W, Main_Part).Outline_Width.Amount);
   begin
      Section ("a widget restyled by its domain state");

      Adi.CSS_Source.Add_Dynamic_File (Source, Corpus_Path, OK);
      Assert (OK, "the corpus should be readable from the repository root");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "and should install");

      Adi.CSS_Source.Bind_Class (Source, "alarm", +W);

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Assert (Is_RGB (R.Background_Color, 20, 20, 20),
                 "a widget naming no property gets the base rule");
         Assert (Pad_Amount (R) = 4.0, "and the base padding");
      end;

      Assert (Outline = 2.0,
              ":not([severity=critical]) holds of a widget naming nothing");
      Assert (Margin_Top = 7.0,
              "and so does :not([link])");

      declare
         Resolves : constant Natural := Adi.Widget.Get_Perf_Style_Resolves;
      begin
         TP.Severity.Set (+W, TP.Critical);
         Assert (Adi.Widget.Get_Perf_Style_Resolves > Resolves,
                 "a property the rules do name is asked what it changed");
      end;

      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Assert (Is_RGB (R.Background_Color, 200, 0, 0),
                 "setting the property selects its rule");
         Assert (Pad_Amount (R) = 8.0, "and the rest of that rule with it");
      end;
      Assert (Outline = 0.0,
              "and takes the :not() rule off");

      TP.Severity.Set (+W, TP.Warning);
      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Assert (Is_RGB (R.Background_Color, 200, 160, 0),
                 "moving to another value selects the other rule");
         Assert (Pad_Amount (R) = 6.0, "and its padding");
      end;
      Assert (Outline = 2.0,
              "which the :not() rule is back for");

      TP.Severity.Clear (+W);
      declare
         R : constant Resolved_Style := Get_Resolved_Part_Style (+W, Main_Part);
      begin
         Assert (Is_RGB (R.Background_Color, 20, 20, 20),
                 "clearing it goes back to the base rule");
         Assert (Pad_Amount (R) = 4.0, "and the base padding");
      end;

      --  [link] with no value, against [link="degraded"] paired with a
      --  second condition, and :not([link]) beside both.
      TP.Link.Set (+W, TP.Degraded);
      Assert (Border_Amount (Get_Resolved_Part_Style (+W, Main_Part)) = 3.0,
              "an existence condition holds whatever the value");
      Assert (Margin_Top = 0.0,
              "and its negation gives way");

      TP.Severity.Set (+W, TP.Critical);
      Assert (Border_Amount (Get_Resolved_Part_Style (+W, Main_Part)) = 5.0,
              "a rule naming two properties wins over one naming one");

      TP.Link.Clear (+W);
      Assert (Border_Amount (Get_Resolved_Part_Style (+W, Main_Part)) = 1.0,
              "and drops back when one of the two goes");

      --  A pseudo-class beside a property condition.
      Set_Hovered (+W);
      Assert (Is_RGB (Get_Resolved_Part_Style (+W, Main_Part).Background_Color,
                      255, 0, 0),
              "[severity=critical]:hover outranks [severity=critical]");
      Set_Hovered (+W, False);
      Assert (Is_RGB (Get_Resolved_Part_Style (+W, Main_Part).Background_Color,
                      200, 0, 0),
              "and gives way when the hover ends");

      --  A sub-part inherits the main part's rules, so a property
      --  condition on ::label has to reach it too.
      Assert (Is_RGB (Get_Resolved_Part_Style (+W, Label_Part).Color,
                      255, 255, 255),
              "a property condition on a part selects that part's rule");

      --  Two properties whose values share a name select apart.
      TP.Power.Set (+W, TP.On);
      Assert (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity) = 0.5,
              "[power=on] selects the power rule");
      Assert (Float (Get_Resolved_Part_Style (+W, Main_Part).Flex_Grow) = 0.0,
              "and leaves the radio rule alone");
      TP.Radio.Set (+W, TP.On);
      Assert (Float (Get_Resolved_Part_Style (+W, Main_Part).Flex_Grow) = 3.0,
              "[radio=on] selects the radio rule");

      Adi.CSS_Source.Destroy (Source);
   end Test_Widget_Cascade;

   procedure Test_Widget_Reads is
      W : constant Box_Handle := Create_Handle;
   begin
      Section ("what a widget answers about its properties");

      Assert (Get_Properties (+W) = Empty_Assignment,
              "a fresh widget carries the empty assignment");
      Assert (not Has_Property (+W, TP.Severity.Id), "and names no property");
      Assert (Get_Property (+W, TP.Severity.Id) = No_Value,
              "and holds no value for one");

      Set_Property (+W, TP.Severity.Value (TP.Ok));
      Assert (Has_Property (+W, TP.Severity.Id), "setting one names it");
      Assert (Get_Property (+W, TP.Severity.Id) = TP.Severity.Value (TP.Ok),
              "and holds the value set");

      Clear_Property (+W, TP.Severity.Id);
      Assert (Get_Properties (+W) = Empty_Assignment,
              "clearing the last one goes back to the empty assignment");
   end Test_Widget_Reads;

   --  A widget naming no property must reach the memo the way it did
   --  before there were any: two widgets carrying the same style and the
   --  same states share one entry.
   procedure Test_No_Property_Costs_Nothing is
      Source   : Adi.CSS_Source.Style_Source;
      A, B     : constant Box_Handle := Create_Handle;
      OK       : Boolean := False;
      Before   : Natural;
      Resolves : Natural;
   begin
      Section ("a widget naming no property");

      Adi.CSS_Source.Add_Dynamic_String
        (Source, ".plain { background-color: rgb(1, 2, 3); }", OK);
      Assert (OK, "the plain sheet should parse");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "and install");

      Adi.CSS_Source.Bind_Class (Source, "plain", +A);
      Adi.CSS_Source.Bind_Class (Source, "plain", +B);

      declare
         Unused : constant Resolved_Style :=
           Get_Resolved_Part_Style (+A, Main_Part);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
      Before := Adi.Widget.Testing.Memo_Entries;

      declare
         Unused : constant Resolved_Style :=
           Get_Resolved_Part_Style (+B, Main_Part);
         pragma Unreferenced (Unused);
      begin
         null;
      end;

      Assert (Adi.Widget.Testing.Memo_Entries = Before,
              "the second widget hits the entry the first one made");
      Assert (Get_Properties (+A) = Empty_Assignment
                and then Get_Properties (+B) = Empty_Assignment,
              "and neither of them names a property");

      --  Setting a property no rule reads leaves the widget's
      --  appearance where it was, and costs nothing to establish: the
      --  prepared style records that none of its rules names a property,
      --  so the change reaches no resolve at all.
      Resolves := Adi.Widget.Get_Perf_Style_Resolves;
      TP.Severity.Set (+A, TP.Critical);
      Assert (Adi.Widget.Get_Perf_Style_Resolves = Resolves,
              "a property no rule names costs no resolve");
      Assert (Is_RGB (Get_Resolved_Part_Style (+A, Main_Part).Background_Color,
                      1, 2, 3),
              "and changes nothing that draws");

      Adi.CSS_Source.Destroy (Source);
   end Test_No_Property_Costs_Nothing;

   --  The runtime parser resolves a name against the registry, where the
   --  generated pipeline resolves it at compile time. A name neither
   --  knows must stop the sheet rather than install a selector that
   --  matches nothing.
   procedure Test_Unknown_Name_Rolls_Back is
      Source : Adi.CSS_Source.Style_Source;
      W      : constant Box_Handle := Create_Handle;
      OK     : Boolean := False;
   begin
      Section ("a name the application never declared");

      Adi.CSS_Source.Add_Dynamic_String
        (Source, ".row { background-color: rgb(9, 9, 9); }", OK);
      Assert (OK, "the first sheet should parse");
      Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "and install");
      Adi.CSS_Source.Bind_Class (Source, "row", +W);

      Adi.CSS_Source.Set_Dynamic_Sources
        (Source,
         [Adi.CSS_Source.CSS_Text
            (".row { background-color: rgb(9, 9, 9); }" & ASCII.LF
             & ".row[nonesuch=""x""] { background-color: rgb(7, 7, 7); }")],
         OK);
      Assert (not OK, "a sheet naming an undeclared property should fail");
      Assert (Adi.CSS_Source.Get_Last_Error (Source) /= "",
              "and should say why");
      Assert (Is_RGB (Get_Resolved_Part_Style (+W, Main_Part).Background_Color,
                      9, 9, 9),
              "leaving the last good sheet standing");

      --  Every shape tools/css_to_ada.py refuses, refused here too: a
      --  selector one pipeline took and the other did not would resolve
      --  the same file two ways.
      declare
         Refused : constant Selector_Array :=
           [To_Unbounded_String (".row[severity=""nonesuch""]"),
            To_Unbounded_String (".row:not([severity=""nonesuch""])"),
            To_Unbounded_String (".row[severity>2]"),
            To_Unbounded_String (".row[severity~=""ok""]"),
            To_Unbounded_String (".row[severity*=""ok""]"),
            To_Unbounded_String (".row[]"),
            To_Unbounded_String (".row[severity=""ok"""),
            To_Unbounded_String (".row:not([severity=""ok""]"),
            To_Unbounded_String (".row[1severity=""ok""]"),
            To_Unbounded_String (".row[quiet=""yes""]"),
            To_Unbounded_String (".row[severity=""a b""]")];
      begin
         for Bad of Refused loop
            Adi.CSS_Source.Set_Dynamic_Sources
              (Source,
               [Adi.CSS_Source.CSS_Text
                  (To_String (Bad) & " { background-color: rgb(7, 7, 7); }")],
               OK);
            Assert (not OK, To_String (Bad) & " should be refused");
         end loop;
      end;

      Adi.CSS_Source.Destroy (Source);
   end Test_Unknown_Name_Rolls_Back;

   --  tools/css_to_ada.py reads tests/css/widget_property.css at build
   --  time and Adi.CSS_Parser reads it at run time. A file that resolves
   --  differently depending on which pipeline loaded it is what this
   --  section catches, so both are driven from the one file.
   procedure Test_Pipeline_Agreement is
      Generated : Adi.CSS_Source.Style_Source;
      Parsed    : Adi.CSS_Source.Style_Source;
      Gen_W     : constant Box_Handle := Create_Handle;
      Par_W     : constant Box_Handle := Create_Handle;
      OK        : Boolean := False;

      function Sides_Of (B : CSS_Box_Value) return CSS_Box_Sides is
        (case B.Kind is
           when Gap_Uniform => [others => B.All_Sides],
           when Axis        => [Top | Bottom => B.Vertical,
                                Left | Right => B.Horizontal],
           when Per_Side    => B.Sides);

      function Edges_Of (B : Border_Width_Value) return Edge_Lengths is
        (case B.Kind is
           when Gap_Uniform => [others => B.All_Edges],
           when Per_Edge    => B.Edges);

      procedure Compare (Label : String) is
         G : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Gen_W, Main_Part);
         P : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Main_Part);
         GL : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Gen_W, Label_Part);
         PL : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Label_Part);
      begin
         Assert (G.Background_Color = P.Background_Color,
                 Label & ": background agrees between the two pipelines");
         Assert (Sides_Of (G.Padding) = Sides_Of (P.Padding),
                 Label & ": padding agrees between the two pipelines");
         Assert (Edges_Of (G.Border_Width) = Edges_Of (P.Border_Width),
                 Label & ": border width agrees between the two pipelines");
         Assert (G.Outline_Width = P.Outline_Width,
                 Label & ": the :not() rule agrees between the two");
         Assert (G.Margin = P.Margin,
                 Label & ": and so does the other one");
         Assert (G.Opacity = P.Opacity and then G.Flex_Grow = P.Flex_Grow,
                 Label & ": two values of one name land apart in both");
         Assert (GL.Color = PL.Color,
                 Label & ": the label part agrees too");
      end Compare;

      --  Agreement alone would pass with both pipelines wrong the same
      --  way, so the value each should reach is spelled out here.
      procedure Expect (R, G, B : Natural; Pad : Float; Label : String) is
         S : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Main_Part);
      begin
         Assert (Is_RGB (S.Background_Color, R, G, B),
                 Label & ": the background the rule names");
         Assert (Sides_Of (S.Padding) (Top).Amount = Pad,
                 Label & ": and the padding");
      end Expect;

      procedure Set_Both (V : TP.Severity_Level) is
      begin
         TP.Severity.Set (+Gen_W, V);
         TP.Severity.Set (+Par_W, V);
      end Set_Both;

   begin
      Section ("generated and parsed pipelines agree");

      Widget_Property_Styles.Register_Selectors (Generated);
      Adi.CSS_Source.Set_Mode (Generated, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "the generated stylesheet should install");

      Adi.CSS_Source.Add_Dynamic_File (Parsed, Corpus_Path, OK);
      Assert (OK, "the corpus should be readable from the repository root");
      Adi.CSS_Source.Set_Mode (Parsed, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "and the parsed stylesheet should install");

      Adi.CSS_Source.Bind_Class (Generated, "alarm", +Gen_W);
      Adi.CSS_Source.Bind_Class (Parsed, "alarm", +Par_W);

      Compare ("unset");
      Expect (20, 20, 20, 4.0, "unset");

      Set_Both (TP.Ok);
      Compare ("ok");
      Expect (0, 128, 0, 4.0, "ok");

      Set_Both (TP.Warning);
      Compare ("warning");
      Expect (200, 160, 0, 6.0, "warning");

      Set_Both (TP.Critical);
      Compare ("critical");
      Expect (200, 0, 0, 8.0, "critical");

      TP.Link.Set (+Gen_W, TP.Degraded);
      TP.Link.Set (+Par_W, TP.Degraded);
      Compare ("critical and degraded");

      TP.Power.Set (+Gen_W, TP.On);
      TP.Power.Set (+Par_W, TP.On);
      TP.Radio.Set (+Gen_W, TP.On);
      TP.Radio.Set (+Par_W, TP.On);
      Compare ("power and radio on");

      Set_Hovered (+Gen_W);
      Set_Hovered (+Par_W);
      Compare ("critical, degraded and hovered");
      Expect (255, 0, 0, 8.0, "critical and hovered");
   end Test_Pipeline_Agreement;

   --  A property no dynamic sheet can name still styles through the
   --  generated one, which is what Dynamic_Lookup => False is for.
   procedure Test_Static_Only_Property is
      Generated : Adi.CSS_Source.Style_Source;
      Parsed    : Adi.CSS_Source.Style_Source;
      W         : constant Box_Handle := Create_Handle;
      OK        : Boolean := False;
      Text      : constant String :=
        ".hush { opacity: 1.0; }" & ASCII.LF
        & ".hush[quiet=""yes""] { opacity: 0.25; }" & ASCII.LF;
   begin
      Section ("a property reachable through the constants alone");

      Widget_Property_Static_Styles.Register_Selectors (Generated);
      Adi.CSS_Source.Set_Mode (Generated, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "the generated sheet should install");
      Adi.CSS_Source.Bind_Class (Generated, "hush", +W);

      Assert (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity) = 1.0,
              "the base rule stands while the property is unset");
      TP.Quiet.Set (+W, TP.Yes);
      Assert (Float (Get_Resolved_Part_Style (+W, Main_Part).Opacity) = 0.25,
              "and the property selects its rule through the constants");

      Adi.CSS_Source.Add_Dynamic_String (Parsed, Text, OK);
      Assert (not OK,
              "the same text read at run time cannot name the property");

      Adi.CSS_Source.Destroy (Generated);
      Adi.CSS_Source.Destroy (Parsed);
   end Test_Static_Only_Property;

   procedure Report_Sizes is
   begin
      Section ("one name over two vocabularies");

      --  Test_Properties.Clash declares "severity" again over four
      --  literals where three stand. The registry keeps the first and
      --  refuses the second, so the clashing instantiation names nothing
      --  and the original answers as it did.
      Assert (Test_Properties.Clash.Id = Adi.Widget_Properties.No_Property,
              "a second vocabulary under one name is refused");
      Assert (Test_Properties.Severity.Id /= Adi.Widget_Properties.No_Property,
              "leaving the first standing");
      Assert (Adi.Widget_Properties.Value_Count
                (Test_Properties.Severity.Id) = 3,
              "with the value count it was declared with");

      Section ("what the vocabulary costs");
      Put_Line ("      registry and set store, bytes:"
                & Natural'Image (Store_Bytes));
      Put_Line ("      name characters held:" & Natural'Image (Name_Bytes));
      Put_Line ("      sets held:" & Natural'Image (Set_Count)
                & ", pairs:" & Natural'Image (Pair_Count));
      Put_Line ("      Widget, bytes:"
                & Natural'Image (Adi.Widget.Testing.Widget_Bytes));
      Put_Line ("      State_Selector, bytes:"
                & Natural'Image
                    (State_Selector'Max_Size_In_Storage_Elements));
      Put_Line ("      Property_Assignment, bytes:"
                & Natural'Image
                    (Property_Assignment'Max_Size_In_Storage_Elements));

      Assert (Property_Assignment'Max_Size_In_Storage_Elements <= 4,
              "an assignment is an index, not a list");
      --  severity, link, power and radio; quiet keeps none.
      Assert (Name_Bytes = 8 + 4 + 5 + 5,
              "only a property declared for dynamic lookup costs name bytes");
      Assert (Adi.Widget.Testing.Widget_Bytes <= 4096,
              "a widget is still under four kilobytes");
   end Report_Sizes;

begin
   Start_Suite ("Widget Property Test");

   Test_Registry;
   Test_Name_Gating;
   Test_Enumerated;
   Test_Static_Only_Property;
   Test_Assignments;
   Test_Conditions;
   Test_Selectors;
   Test_Widget_Cascade;
   Test_Widget_Reads;
   Test_No_Property_Costs_Nothing;
   Test_Unknown_Name_Rolls_Back;
   Test_Pipeline_Agreement;
   Report_Sizes;

   Finish;
end Widget_Property_Test;
