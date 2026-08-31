--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget_Properties;

package Adi.Widget_Styles is

   pragma Elaborate_Body;

   --  Widget states
   type Widget_State is
     (State_Normal,
      State_Hovered,
      State_Pressed,
      State_Focused,
      State_Disabled,
      State_Selected);

   type Widget_States is array (Widget_State) of Boolean
     with Pack;

   No_States : constant Widget_States := [others => False];
   All_States : constant Widget_States := [others => True];

   -------------------------------------------------
   -- State Combinations (Selectors)
   -------------------------------------------------

   type State_Selector is record
      --  Widget-level states (:hover before ::part, e.g. list:hover::scroll)
      Widget_Required : Widget_States := No_States;
      Widget_Excluded : Widget_States := No_States;
      --  Part-level states (:hover after ::part, e.g. list::scroll:hover)
      Part_Required   : Widget_States := No_States;
      Part_Excluded   : Widget_States := No_States;
      --  The [severity] and [severity="critical"] conditions the
      --  selector carries, interned. Interning is canonical, so the
      --  index stands for the set and predefined equality on the
      --  selector stays exact.
      Properties      : Adi.Widget_Properties.Property_Conditions :=
        Adi.Widget_Properties.No_Conditions;
   end record;

   --  Match any state (always matches)
   Any_State : constant State_Selector := (others => <>);


   function Single_State (S : Widget_State) return Widget_States is
      ([No_States with delta S => True]);

   function When_State (S : Widget_State) return State_Selector is
      ((Widget_Required => Single_State (S), Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => No_States,
        others          => <>));

   function When_Not (S : Widget_State) return State_Selector is  
      ((Widget_Required => No_States,       Widget_Excluded => Single_State (S),
        Part_Required   => No_States,       Part_Excluded   => No_States,
        others          => <>));

   function When_Part_State (S : Widget_State) return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => Single_State (S), Part_Excluded  => No_States,
        others          => <>));

   function When_Part_Not (S : Widget_State) return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => Single_State (S),
        others          => <>));

   --  [severity="critical"], and [severity] whatever it is set to. What
   --  tools/css_to_ada.py emits for a bracket condition, and what an
   --  application writes by hand for the same.
   function When_Property (V : Adi.Widget_Properties.Property_Value)
     return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => No_States,
        Properties      => Adi.Widget_Properties.Conditions_On (V)));

   function When_Property_Set (P : Adi.Widget_Properties.Property)
     return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => No_States,
        Properties      => Adi.Widget_Properties.Conditions_On (P)));

   --  :not([severity="critical"]) and :not([severity]), which is how CSS
   --  spells "anything but" -- there is no not-equal attribute operator.
   function When_Not_Property (V : Adi.Widget_Properties.Property_Value)
     return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => No_States,
        Properties      => Adi.Widget_Properties.Conditions_Excluding (V)));

   function When_Not_Property_Set (P : Adi.Widget_Properties.Property)
     return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => No_States,
        Properties      => Adi.Widget_Properties.Conditions_Excluding (P)));

   --  Selector combinators
   function "and" (L, R : State_Selector) return State_Selector is
     ((Widget_Required => [for S in Widget_State => L.Widget_Required (S) or R.Widget_Required (S)],
       Widget_Excluded => [for S in Widget_State => L.Widget_Excluded (S) or R.Widget_Excluded (S)],
       Part_Required   => [for S in Widget_State => L.Part_Required (S) or R.Part_Required (S)],
       Part_Excluded   => [for S in Widget_State => L.Part_Excluded (S) or R.Part_Excluded (S)],
       Properties      =>
         Adi.Widget_Properties.Both (L.Properties, R.Properties)));

   function "or" (L, R : State_Selector) return State_Selector is
     ((Widget_Required => [for S in Widget_State => L.Widget_Required (S) and R.Widget_Required (S)],
       Widget_Excluded => [for S in Widget_State => L.Widget_Excluded (S) and R.Widget_Excluded (S)],
       Part_Required   => [for S in Widget_State => L.Part_Required (S) and R.Part_Required (S)],
       Part_Excluded   => [for S in Widget_State => L.Part_Excluded (S) and R.Part_Excluded (S)],
       Properties      =>
         Adi.Widget_Properties.Common (L.Properties, R.Properties)));

   --  Whether the selector's conditions hold: the states a pointer and
   --  a keyboard drive, and the properties the application set. A
   --  selector naming no property costs one index comparison here.
   function Matches (Selector : State_Selector;
                     Active_Widget : Widget_States;
                     Active_Part   : Widget_States;
                     Assigned      : Adi.Widget_Properties.Property_Assignment
                       := Adi.Widget_Properties.Empty_Assignment)
     return Boolean is
     ((for all S in Widget_State =>
         (if Selector.Widget_Required (S) then Active_Widget (S)) and
         (if Selector.Widget_Excluded (S) then not Active_Widget (S)) and
         (if Selector.Part_Required (S) then Active_Part (S)) and
         (if Selector.Part_Excluded (S) then not Active_Part (S)))
      and then
        (Adi.Widget_Properties."="
           (Selector.Properties, Adi.Widget_Properties.No_Conditions)
         or else Adi.Widget_Properties.Satisfied_By
                   (Selector.Properties, Assigned)));

   function Matches (Selector : State_Selector;
                     Active   : Widget_States;
                     Assigned : Adi.Widget_Properties.Property_Assignment
                       := Adi.Widget_Properties.Empty_Assignment)
     return Boolean is
     (Matches (Selector, Active, No_States, Assigned));

   --  Conditions the selector sets: states required, states excluded,
   --  and properties named. A property condition scores 1, so
   --  [severity="critical"]:hover scores 2 -- the CSS ranking.
   function Specificity (Selector : State_Selector) return Natural;


   -------------------------------------------------
   -- State Rules
   -------------------------------------------------

   type State_Rule is record
      Selector : State_Selector := Any_State;
      Style    : Rules_Handle := Empty_Rules;
      Priority : Natural := 0;  --  Explicit priority (0 = auto from specificity)
   end record;

   type State_Rule_Array is array (Positive range <>) of State_Rule;

   -------------------------------------------------
   -- Style Definition
   -------------------------------------------------

   Max_Style_Rules : constant := 16;

   --  A style as it is authored and as Add_Rule mutates it: a base rule
   --  set and up to Max_Style_Rules state rules, each named by handle.
   --  Interning turns one of these into a Widget_Style.
   type Style_Definition is record
      Base       : Rules_Handle := Empty_Rules;
      Rules      : State_Rule_Array (1 .. Max_Style_Rules) := [others => <>];
      Rule_Count : Natural := 0;
      --  Precomputed: which states appear in any rule selector
      Widget_State_Mask : Widget_States := No_States;
      Part_State_Mask   : Widget_States := No_States;
   end record;

   Empty_Style_Definition : constant Style_Definition := (others => <>);

   --  A style has room for Max_Style_Rules state rules and no more.
   Too_Many_Style_Rules : exception;

   --  Add a rule to a definition. Past the cap this raises
   --  Too_Many_Style_Rules, naming the state selector that did not fit.
   procedure Add_Rule (WS : in out Style_Definition; Rule : State_Rule);

   --  Add a rule where the caller has nowhere to report a failure to:
   --  past the cap the rule is dropped and reported through Adi.Log,
   --  and Added comes back False.
   procedure Try_Add_Rule
     (WS : in out Style_Definition; Rule : State_Rule; Added : out Boolean);

   --  Equal definitions hash equal; unequal ones may collide. Keyed only
   --  on discriminants, counts and handles, never on a string, float or
   --  access value, which do not survive being built twice.
   function Hash (S : Style_Definition) return Ada.Containers.Hash_Type;

   --  Equality over the live rules only. Nothing writes a slot past
   --  Rule_Count, so this answers as predefined "=" does without
   --  walking fifteen unused rule slots.
   function Same_Style (A, B : Style_Definition) return Boolean;

   -------------------------------------------------
   -- Interned Widget Style
   -------------------------------------------------

   --  A style definition stored once and named by a four-byte handle.
   --  Interning is canonical, so equal definitions share one handle and
   --  comparing two handles compares two styles. The store holds an
   --  entry for the life of the process.
   type Widget_Style is private;

   --  What Empty_Style_Definition interns to.
   Empty_Widget_Style : constant Widget_Style;

   function Intern (D : Style_Definition) return Widget_Style;

   function Definition (S : Widget_Style) return Style_Definition;

   --  The store index a handle carries, for a caller that keys on it.
   function Index (S : Widget_Style) return Natural;

   --  Check if any rule references a given widget/part state
   function Uses_Widget_State
     (WS : Widget_Style; S : Widget_State) return Boolean;
   function Uses_Part_State
     (WS : Widget_Style; S : Widget_State) return Boolean;

   --  Whether any rule names a widget property. A widget setting one
   --  where no rule reads it changes nothing, and this says so without
   --  resolving.
   function Uses_Properties (WS : Widget_Style) return Boolean;

   --  The rules a style takes in the states given, folded in cascade
   --  order: priority ascending, source order ascending within a
   --  priority. This is the runtime path; Compute_Style below is what
   --  the tests drive.
   function Compute_Style_Prepared
     (WS            : Widget_Style;
      Active_Widget : Widget_States;
      Active_Part   : Widget_States;
      Assigned      : Adi.Widget_Properties.Property_Assignment
        := Adi.Widget_Properties.Empty_Assignment)
     return Style_Rules;

   --  Distinct styles the store holds, and the storage elements their
   --  entries occupy. Instrumentation a test reads.
   function Interned_Styles return Natural;
   function Interned_Style_Bytes return Natural;

   --  Compute effective style given active states
   function Compute_Style (WS : Widget_Style;
                           Active : Widget_States;
                           Assigned : Adi.Widget_Properties.Property_Assignment
                             := Adi.Widget_Properties.Empty_Assignment)
     return Style_Rules;
   function Compute_Style (WS : Widget_Style;
                           Active_Widget : Widget_States;
                           Active_Part   : Widget_States;
                           Assigned : Adi.Widget_Properties.Property_Assignment
                             := Adi.Widget_Properties.Empty_Assignment)
     return Style_Rules;

   --  Compute and resolve in one step
   function Compute_Resolved (WS : Widget_Style;
                              Active : Widget_States;
                              Assigned : Adi.Widget_Properties.Property_Assignment
                                := Adi.Widget_Properties.Empty_Assignment)
     return Resolved_Style;
   function Compute_Resolved (WS : Widget_Style;
                              Active_Widget : Widget_States;
                              Active_Part   : Widget_States;
                              Assigned : Adi.Widget_Properties.Property_Assignment
                                := Adi.Widget_Properties.Empty_Assignment)
     return Resolved_Style;

   -------------------------------------------------
   -- Fluent Builder
   -------------------------------------------------

   type Style_Builder is tagged private;

   --  Start building
   function Create return Style_Builder;
   function From (Base : Style_Rules) return Style_Builder;

   --  Set base style
   function Base (B : Style_Builder; S : Style_Rules) return Style_Builder;

   --  Common state shortcuts
   function On_Normal (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Hover (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Press (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Disabled (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Selected (B : Style_Builder; S : Style_Rules) return Style_Builder;

   --  Generic state rule
   function On (B : Style_Builder; Sel : State_Selector; S : Style_Rules) return Style_Builder;
   function On (B : Style_Builder; 
                Sel : State_Selector; 
                S : Style_Rules;
                Priority : Natural) return Style_Builder;

   --  Compound state shortcuts
   function On_Hover_And_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Press_And_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Hover_Not_Disabled (B : Style_Builder; S : Style_Rules) return Style_Builder;
   function On_Selected_And_Focus (B : Style_Builder; S : Style_Rules) return Style_Builder;

   --  Set transition on the base style (all properties)
   function With_Transition (B : Style_Builder;
                             Duration : Float;
                             Easing   : Easing_Kind := Ease_In_Out) return Style_Builder;

   --  Set transition on the base style (specific properties)
   function With_Transition (B          : Style_Builder;
                             Duration   : Float;
                             Properties : Property_Set;
                             Easing     : Easing_Kind := Ease_In_Out) return Style_Builder;

   --  Finalize
   function Build (B : Style_Builder) return Widget_Style;

   -------------------------------------------------
   -- Predefined Selectors
   -------------------------------------------------

   Sel_Normal   : constant State_Selector := When_State (State_Normal);
   Sel_Hovered  : constant State_Selector := When_State (State_Hovered);
   Sel_Pressed  : constant State_Selector := When_State (State_Pressed);
   Sel_Focused  : constant State_Selector := When_State (State_Focused);
   Sel_Disabled : constant State_Selector := When_State (State_Disabled);
   Sel_Selected : constant State_Selector := When_State (State_Selected);

   Sel_Hover_And_Focus : constant State_Selector := 
     When_State (State_Hovered) and When_State (State_Focused);
   
   Sel_Hover_Not_Disabled : constant State_Selector :=
     When_State (State_Hovered) and When_Not (State_Disabled);

   Sel_Interactive : constant State_Selector := When_Not (State_Disabled);

private

   --  An index into the style store, zero for the empty style.
   type Widget_Style is new Natural;

   Empty_Widget_Style : constant Widget_Style := 0;

   type Style_Builder is tagged record
      WS : Style_Definition;
   end record;

   --  Instrumentation the tests need and applications do not: rules
   --  Try_Add_Rule has dropped, over the life of the process.
   Dropped_Rule_Count : Natural := 0;

end Adi.Widget_Styles;
