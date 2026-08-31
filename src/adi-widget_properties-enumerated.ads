--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Widget;

--  One widget property, declared from the application's own enumeration:
--
--     type Severity is (Ok, Warning, Critical);
--
--     package Severity_Prop is new Adi.Widget_Properties.Enumerated
--       (Name => "severity", Values => Severity);
--
--     Severity_Prop.Set (Row, Critical);
--
--  The value type is the enumeration itself, so a value of one property
--  cannot be handed to another and mixing two of them fails to compile.
--  A value's index is its position in the enumeration, so nothing is
--  registered per value and nothing is looked up: `Value (Critical)` is
--  a position the compiler already knows.
--
--  A literal's CSS name is its image folded to lower case with
--  underscores as hyphens, so `Half_Open` answers to `half-open`. The
--  vocabulary is derived from the enumeration rather than written out a
--  second time.
--
--  Values are ordered, being an enumeration, so an ordering selector has
--  what it would need whenever one earns its keep.
generic
   Name : String;
   type Values is (<>);

   --  Whether a stylesheet read at run time can name this property. A
   --  dynamic sheet has nothing but the string it spells, so it resolves
   --  through the registry, which holds the name for that reason alone.
   --
   --  False keeps the property name and every value name out of the
   --  registry, leaving the property reachable through the constants a
   --  generated sheet and hand-written Ada name -- and a dynamic sheet
   --  spelling it is then rejected rather than installed as a selector
   --  that matches nothing.
   Dynamic_Lookup : Boolean := True;
package Adi.Widget_Properties.Enumerated is

   --  The registry entry the instantiation made, which
   --  Adi.Widget_Styles.When_Property_Set takes for `[severity]`.
   function Id return Property;

   --  The value at a literal, which Adi.Widget_Styles.When_Property
   --  takes for `[severity="critical"]`.
   function Value (V : Values) return Property_Value;

   --  The CSS name a literal answers to.
   function CSS_Name (V : Values) return String;

   --  Handles, as the rest of the widget API takes. A widget body with
   --  a Widget'Class of its own reaches Adi.Widget.Set_Property with
   --  Value (V).
   procedure Set (H : Adi.Widget.Widget_Handle; V : Values);
   procedure Clear (H : Adi.Widget.Widget_Handle);
   function Is_Set (H : Adi.Widget.Widget_Handle) return Boolean;

   --  What the widget holds, or Default where it names the property not
   --  at all. An enumeration carries no absent literal, so the caller
   --  says which one stands for absent.
   function Get (H : Adi.Widget.Widget_Handle; Default : Values) return Values;

private

   --  Declared here rather than in the body. Taking 'Access of a
   --  subprogram for an access type declared outside the generic is what
   --  a generic body may not do (RM 3.10.2(32)), where the private part
   --  is rechecked at every instantiation and may.
   function Resolve_Ordinal (Name : String) return Integer;
   function Name_At_Ordinal (Ordinal : Natural) return String;

   --  Elaborating the instantiation is the whole registration: the
   --  property takes the next index, and its values need none, a value
   --  being a position in Values.
   Registered : constant Property :=
     Declare_Property
       (Name     => Name,
        Values   => Values'Pos (Values'Last) - Values'Pos (Values'First) + 1,
        Resolver =>
          (if Dynamic_Lookup then Resolve_Ordinal'Access else null),
        Namer    =>
          (if Dynamic_Lookup then Name_At_Ordinal'Access else null));

end Adi.Widget_Properties.Enumerated;
