--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget_Properties;
with Adi.Slot_Pool;
with Adi.Slot_Pool.Refs;

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
   -- Composing a style property by property
   -------------------------------------------------

   --  A chain names one property at a time, through a setter that takes
   --  that property's own value type, so Background (Px (14.0)) is a
   --  compile error where Background (RGB (37, 99, 235)) is not:
   --
   --     Primary : constant Widget_Style :=
   --        Style_Of
   --           .Background (RGB (37, 99, 235))
   --           .Padding    (CSS_Box (Px (12.0), Px (24.0)))
   --        .On_Hover
   --           .Background (RGB (29, 78, 216))
   --        .Build;
   --
   --  Style_Of opens a chain, .On_Hover and .On move the active rule,
   --  and .Build interns and answers a handle. A setter says "set" by
   --  existing, so clearing has a spelling of its own, .Clear (Prop_X).
   --
   --  A chain gathers eight bytes per property named, in a slot the
   --  pool below lends it, where the aggregate the same style is
   --  written as materialises a whole Style_Rules. The composer is a
   --  pool index, so a step copies the index rather than the slots.
   --
   --  A chain is linear: every value in it names one buffer, so
   --  branching off an earlier step appends to the same chain rather
   --  than starting a second.
   --
   --  A chain ends in .Build or in .Discard, either of which returns its
   --  buffer. One that ends in neither -- an exception raised between
   --  Style_Of and .Build, which evaluating a setter's argument can do --
   --  leaves its buffer held. A chain opening on a full pool therefore
   --  takes back the buffer held longest rather than doing without: a
   --  chain lives for one expression, so the oldest is overwhelmingly one
   --  that was abandoned. Acquire raises the buffer's serial, so the
   --  chain it was taken from reads as holding no buffer rather than as
   --  sharing this one, and its own .Build answers the style it opened
   --  on -- the overrides it named did not apply.

   --  Chains open at once. Ada evaluates an argument before the call it
   --  belongs to, so a chain nested inside another holds a buffer beside
   --  it.
   Max_Open_Chains : constant := 8;

   --  Properties one chain names, over all its rules.
   Max_Chain_Slots : constant := 64;

   type Composer is tagged private;

   --  A fresh chain, and one that opens on an existing style: the
   --  base's properties stand, the chain overrides what it names, and
   --  the state rules it carries come through.
   function Style_Of return Composer;
   function Style_Of (Base : Widget_Style) return Composer;

   --  Returns the chain's buffer without building. What a chain that is
   --  abandoned needs; .Build does it on the way out. A buffer already
   --  taken back is left where it is.
   procedure Discard (C : in out Composer);

   --  Whether the chain still holds a buffer, and so whether the steps
   --  on it are being kept. False once .Build or .Discard has returned
   --  the buffer, and false for a chain whose buffer was taken back --
   --  which is the one case a caller cannot otherwise see, since such a
   --  chain builds the style it opened on rather than raising.
   function Is_Live (C : Composer) return Boolean;

   -------------------------------------------------
   -- Moving the active rule
   -------------------------------------------------

   --  The rule the setters after it name. A selector already carried --
   --  by the chain or by the style it opened on -- is that rule again
   --  rather than a second one, so .On_Hover twice names one rule.
   function On (C : Composer; Sel : State_Selector) return Composer;
   function On_Base (C : Composer) return Composer;
   function On_Normal (C : Composer) return Composer;
   function On_Hover (C : Composer) return Composer;
   function On_Press (C : Composer) return Composer;
   function On_Focus (C : Composer) return Composer;
   function On_Disabled (C : Composer) return Composer;
   function On_Selected (C : Composer) return Composer;

   -------------------------------------------------
   -- Setters
   -------------------------------------------------

   function Text_Color (C : Composer; V : Color_Value) return Composer;
   function Background (C : Composer; V : Color_Value) return Composer;

   function Radius (C : Composer; V : Border_Radius_Value) return Composer;
   function Border_Width (C : Composer; V : Border_Width_Value) return Composer;
   function Border_Color (C : Composer; V : Border_Color_Value) return Composer;
   function Border_Style (C : Composer; V : Border_Style_Value) return Composer;

   function Outline_Width (C : Composer; V : Length_Value) return Composer;
   function Outline_Color (C : Composer; V : Color_Value) return Composer;
   function Outline_Offset (C : Composer; V : Length_Value) return Composer;

   function Padding (C : Composer; V : CSS_Box_Value) return Composer;
   function Margin (C : Composer; V : CSS_Box_Value) return Composer;

   function Width (C : Composer; V : Size_Value) return Composer;
   function Height (C : Composer; V : Size_Value) return Composer;
   function Min_Width (C : Composer; V : Size_Value) return Composer;
   function Max_Width (C : Composer; V : Size_Value) return Composer;
   function Min_Height (C : Composer; V : Size_Value) return Composer;
   function Max_Height (C : Composer; V : Size_Value) return Composer;

   function Font_Size (C : Composer; V : Length_Value) return Composer;
   function Font_Weight (C : Composer; V : Font_Weight_Value) return Composer;
   function Text_Align (C : Composer; V : Text_Align_Value) return Composer;
   function Text_Wrap_Mode
     (C : Composer; V : Text_Wrap_Mode_Value) return Composer;

   function Display (C : Composer; V : Display_Value) return Composer;
   function Overflow_X (C : Composer; V : Overflow_Value) return Composer;
   function Overflow_Y (C : Composer; V : Overflow_Value) return Composer;

   function Opacity (C : Composer; V : Opacity_Value) return Composer;
   function Cursor_Style (C : Composer; V : Cursor_Value) return Composer;
   function Box_Shadow (C : Composer; V : Box_Shadow_Value) return Composer;

   function Flex_Direction
     (C : Composer; V : Flex_Direction_Value) return Composer;
   function Justify_Content
     (C : Composer; V : Justify_Content_Value) return Composer;
   function Align_Items (C : Composer; V : Align_Items_Value) return Composer;
   function Gap (C : Composer; V : Gap_Value) return Composer;
   function Flex_Grow (C : Composer; V : Flex_Grow_Value) return Composer;
   function Flex_Shrink (C : Composer; V : Flex_Shrink_Value) return Composer;

   function Transition (C : Composer; V : Transition_Spec) return Composer;

   --  Names the property as holding no value, which is what stops a
   --  rule earlier in the cascade showing through. A property outside
   --  Composable_Properties is reported and leaves the chain alone.
   function Clear (C : Composer; P : CSS_Property) return Composer;

   -------------------------------------------------
   -- Finishing
   -------------------------------------------------

   --  Folds the chain's slots into the rule sets they name, interns
   --  each, and answers the handle for the style they make. The same
   --  style written as an aggregate through From/.On/.Build answers the
   --  same handle: interning is canonical, so this is equality rather
   --  than equivalence.
   --
   --  A chain whose buffer was taken back answers the style it opened
   --  on, which is Empty_Widget_Style for a chain that opened on none.
   function Build (C : Composer) return Widget_Style;

   -------------------------------------------------
   -- Instrumentation
   -------------------------------------------------

   --  Chains open at this moment, buffers taken back from a chain that
   --  had not finished with one, and steps a full chain buffer dropped --
   --  the last two over the life of the process. Either rising says a
   --  chain somewhere is abandoning its buffer or naming more than
   --  Max_Chain_Slots properties; perf_stats reports all three.
   function Open_Chains return Natural;
   function Reclaimed_Chains return Natural;
   function Dropped_Chain_Slots return Natural;

   --  Storage elements a chain step and a chain slot occupy, which a
   --  test pins rather than measures.
   function Slot_Bytes return Natural;
   function Composer_Bytes return Natural;

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

   --  A chain step. Prop says how Val reads, and a slot is read only by
   --  something that knows which property it holds, so a variant record
   --  has nothing to add -- and a variant would stand as wide as the
   --  widest value type rather than at these eight bytes.
   type Slot_Op is (Set_Value, Clear_Value);

   --  0 is the base rule; 1 .. Max_Style_Rules are the state rules the
   --  chain named, in the order it named them.
   type Rule_Slot is range 0 .. Max_Style_Rules;

   type Slot is record
      Rule : Rule_Slot;
      Prop : CSS_Property;
      Op   : Slot_Op;
      Val  : Value_Ref;
   end record;

   type Slot_Array is array (1 .. Max_Chain_Slots) of Slot;

   --  A selector as a chain buffer holds it: the same five fields as a
   --  State_Selector with no component default, which is what lets the
   --  pool instantiation below carry its restrictions.
   type Chain_Selector is record
      Widget_Required : Widget_States;
      Widget_Excluded : Widget_States;
      Part_Required   : Widget_States;
      Part_Excluded   : Widget_States;
      Properties      : Adi.Widget_Properties.Property_Conditions;
   end record;

   type Selector_Array is array (1 .. Max_Style_Rules) of Chain_Selector;

   type Chain_Buffer is record
      Slots      : Slot_Array;
      Selectors  : Selector_Array;
      Count      : Natural;
      Rule_Count : Natural;
      --  Whether a step found the buffer full, so the drop is reported
      --  once for the chain rather than once for the step.
      Dropped    : Boolean;
   end record;

   package Chain_Pool is new Adi.Slot_Pool
     (Payload => Chain_Buffer, Capacity => Max_Open_Chains)
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   package Chain_Refs is new Chain_Pool.Refs
     with Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations);

   --  The chain names its buffer by the pair Chain_Pool.Named takes
   --  back rather than by a Chain_Pool.Slot: a tagged type with a
   --  component of the instance's own private type is charged against
   --  the instance's Local_Restrictions, and the pair is what
   --  Adi.Slot_Pool publishes for a caller carrying a slot inside a
   --  name of its own.
   type Chain_Ordinal is range 0 .. Max_Open_Chains;

   --  Seed rides in the composer rather than in the buffer, so a chain
   --  whose buffer was taken back still knows the style it opened on and
   --  .Build can answer that rather than the empty style.
   type Composer is tagged record
      Serial  : Natural := 0;
      Seed    : Widget_Style := Empty_Widget_Style;
      Ordinal : Chain_Ordinal := 0;
      Active  : Rule_Slot := 0;
   end record;

   --  Buffers taken back from an unfinished chain, and steps dropped by
   --  a full buffer, over the life of the process.
   Reclaimed_Chain_Count : Natural := 0;
   Dropped_Slot_Count    : Natural := 0;

end Adi.Widget_Styles;
