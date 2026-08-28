--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers;
with Adi.CSS_Styles; use Adi.CSS_Styles;

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

   type Widget_States is array (Widget_State) of Boolean;

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
   end record;

   --  Match any state (always matches)
   Any_State : constant State_Selector := (others => <>);


   function Single_State (S : Widget_State) return Widget_States is
      ([No_States with delta S => True]);

   function When_State (S : Widget_State) return State_Selector is
      ((Widget_Required => Single_State (S), Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => No_States));

   function When_Not (S : Widget_State) return State_Selector is  
      ((Widget_Required => No_States,       Widget_Excluded => Single_State (S),
        Part_Required   => No_States,       Part_Excluded   => No_States));

   function When_Part_State (S : Widget_State) return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => Single_State (S), Part_Excluded  => No_States));

   function When_Part_Not (S : Widget_State) return State_Selector is
      ((Widget_Required => No_States,       Widget_Excluded => No_States,
        Part_Required   => No_States,       Part_Excluded   => Single_State (S)));

   --  Selector combinators
   function "and" (L, R : State_Selector) return State_Selector is
     ((Widget_Required => [for S in Widget_State => L.Widget_Required (S) or R.Widget_Required (S)],
       Widget_Excluded => [for S in Widget_State => L.Widget_Excluded (S) or R.Widget_Excluded (S)],
       Part_Required   => [for S in Widget_State => L.Part_Required (S) or R.Part_Required (S)],
       Part_Excluded   => [for S in Widget_State => L.Part_Excluded (S) or R.Part_Excluded (S)]));

   function "or" (L, R : State_Selector) return State_Selector is
     ((Widget_Required => [for S in Widget_State => L.Widget_Required (S) and R.Widget_Required (S)],
       Widget_Excluded => [for S in Widget_State => L.Widget_Excluded (S) and R.Widget_Excluded (S)],
       Part_Required   => [for S in Widget_State => L.Part_Required (S) and R.Part_Required (S)],
       Part_Excluded   => [for S in Widget_State => L.Part_Excluded (S) and R.Part_Excluded (S)]));

   --  Check if selector matches active states
   function Matches (Selector : State_Selector;
                     Active_Widget : Widget_States;
                     Active_Part   : Widget_States) return Boolean is
     ((for all S in Widget_State =>
         (if Selector.Widget_Required (S) then Active_Widget (S)) and
         (if Selector.Widget_Excluded (S) then not Active_Widget (S)) and
         (if Selector.Part_Required (S) then Active_Part (S)) and
         (if Selector.Part_Excluded (S) then not Active_Part (S))));

   function Matches (Selector : State_Selector; Active : Widget_States) return Boolean is
     (Matches (Selector, Active, No_States));

   --  Compute specificity (number of required + excluded conditions)
   function Specificity (Selector : State_Selector) return Natural;


   -------------------------------------------------
   -- State Rules
   -------------------------------------------------

   type State_Rule is record
      Selector : State_Selector := Any_State;
      Style    : Style_Rules := Empty_Style;
      Priority : Natural := 0;  --  Explicit priority (0 = auto from specificity)
   end record;

   type State_Rule_Array is array (Positive range <>) of State_Rule;

   -------------------------------------------------
   -- Widget Style
   -------------------------------------------------

   Max_Style_Rules : constant := 16;

   type Widget_Style is record
      Base       : Style_Rules := Empty_Style;
      Rules      : State_Rule_Array (1 .. Max_Style_Rules) := [others => <>];
      Rule_Count : Natural := 0;
      --  Precomputed: which states appear in any rule selector
      Widget_State_Mask : Widget_States := No_States;
      Part_State_Mask   : Widget_States := No_States;
   end record;

   Empty_Widget_Style : constant Widget_Style := (others => <>);

   --  Add a rule to widget style
   procedure Add_Rule (WS : in out Widget_Style; Rule : State_Rule)
     with Pre => WS.Rule_Count < Max_Style_Rules;

   --  Equal styles hash equal; unequal ones may collide. Keyed only on
   --  discriminants and counts, never on a string, float or access
   --  value, which do not survive being built twice.
   function Hash (S : Widget_Style) return Ada.Containers.Hash_Type;

   --  Check if any rule references a given widget/part state
   function Uses_Widget_State
     (WS : Widget_Style; S : Widget_State) return Boolean is
     (WS.Widget_State_Mask (S));
   function Uses_Part_State
     (WS : Widget_Style; S : Widget_State) return Boolean is
     (WS.Part_State_Mask (S));

   --  Compute effective style given active states
   function Compute_Style (WS : Widget_Style; Active : Widget_States) return Style_Rules;
   function Compute_Style (WS : Widget_Style;
                           Active_Widget : Widget_States;
                           Active_Part   : Widget_States) return Style_Rules;

   --  Compute and resolve in one step
   function Compute_Resolved (WS : Widget_Style; Active : Widget_States) return Resolved_Style;
   function Compute_Resolved (WS : Widget_Style;
                              Active_Widget : Widget_States;
                              Active_Part   : Widget_States) return Resolved_Style;

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

   type Style_Builder is tagged record
      WS : Widget_Style;
   end record;

end Adi.Widget_Styles;
