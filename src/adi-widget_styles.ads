pragma Ada_2022;

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
      Required : Widget_States := No_States;  --  States that must be active
      Excluded : Widget_States := No_States;  --  States that must NOT be active
   end record;

   --  Match any state (always matches)
   Any_State : constant State_Selector := (others => <>);


   function Single_State (S : Widget_State) return Widget_States is
      ([No_States with delta S => True]);

   function When_State (S : Widget_State) return State_Selector is
      ((Required => Single_State (S), Excluded => No_States));

   function When_Not (S : Widget_State) return State_Selector is  
      ((Required => No_States, Excluded => Single_State (S)));

   --  Selector combinators
   function "and" (L, R : State_Selector) return State_Selector is
     ((Required => [for S in Widget_State => L.Required (S) or R.Required (S)],
       Excluded => [for S in Widget_State => L.Excluded (S) or R.Excluded (S)]));

   function "or" (L, R : State_Selector) return State_Selector is
     ((Required => [for S in Widget_State => L.Required (S) and R.Required (S)],
       Excluded => [for S in Widget_State => L.Excluded (S) and R.Excluded (S)]));

   --  Check if selector matches active states
   function Matches (Selector : State_Selector; Active : Widget_States) return Boolean is
     ((for all S in Widget_State =>
         (if Selector.Required (S) then Active (S)) and
         (if Selector.Excluded (S) then not Active (S))));

    --  Compute specificity (number of required + excluded conditions)
   function Specificity (Selector : State_Selector) return Natural is
     ([for S in Widget_State => (if Selector.Required (S) then 1 else 0)]'Reduce ("+", 0) +
      [for S in Widget_State => (if Selector.Excluded (S) then 1 else 0)]'Reduce ("+", 0));
         
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
   end record;

   Empty_Widget_Style : constant Widget_Style := (others => <>);

   --  Add a rule to widget style
   procedure Add_Rule (WS : in out Widget_Style; Rule : State_Rule)
     with Pre => WS.Rule_Count < Max_Style_Rules;

   --  Compute effective style given active states
   function Compute_Style (WS : Widget_Style; Active : Widget_States) return Style_Rules;

   --  Compute and resolve in one step
   function Compute_Resolved (WS : Widget_Style; Active : Widget_States) return Resolved_Style;

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