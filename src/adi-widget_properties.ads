--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers;

--  Domain state a stylesheet can select on: an alarm row at ok, warning
--  or critical, a field valid, invalid or pending, a link connected,
--  degraded or offline. `:hover` and its siblings describe what a
--  pointer and a keyboard are doing; these describe what the
--  application knows.
--
--  A property is declared through Adi.Widget_Properties.Enumerated,
--  from an enumeration of the application's own:
--
--     type Severity_Level is (Ok, Warning, Critical);
--
--     package Severity is new Adi.Widget_Properties.Enumerated
--       (Name => "severity", Values => Severity_Level);
--
--  Elaboration gives the property a dense index, and a value's index is
--  its position in the enumeration, so neither is looked up by name on
--  any path a generated stylesheet takes: tools/css_to_ada.py emits
--  `Severity.Value (Critical)` and the reference resolves to whatever
--  elaboration assigned.
--
--  What this package holds is therefore an index per property, the name
--  beside it that dynamic CSS text resolves against, and the store of
--  interned condition sets and widget assignments. Registration is
--  elaboration-only, and that bound is what buys the rest: the registry
--  is a fixed set of arrays and a count, it allocates nothing, it needs
--  no lock, and it is read-only for the whole of the run.
package Adi.Widget_Properties is

   pragma Elaborate_Body;

   --  Properties an application may declare, and values one of them may
   --  carry. A property's values are an enumeration, so its count is
   --  checked at the instantiation rather than value by value.
   Max_Properties          : constant := 64;
   Max_Values_Per_Property : constant := 256;
   Max_Name_Characters     : constant := 4096;
   Max_Name_Length         : constant := 64;

   --  Distinct (property, value) sets the process holds. A widget's
   --  assignment and a selector's conditions are both one of these, so
   --  they share a store, and interning is canonical: equal sets are one
   --  index, which is what lets the resolved-style memo key on it.
   Max_Property_Sets   : constant := 1024;
   Max_Set_Pairs       : constant := 4096;

   type Property is private;
   type Property_Value is private;

   No_Property : constant Property;
   No_Value    : constant Property_Value;

   function Property_Of (V : Property_Value) return Property;

   --  Values a property carries, which is the length of the enumeration
   --  it was declared from.
   function Value_Count (P : Property) return Natural;
   function Property_Count return Natural;

   ---------------------------------------------------------------------------
   --  Names, which only dynamic CSS text needs
   ---------------------------------------------------------------------------

   --  A stylesheet read at run time has nothing but the string it
   --  spells, so a property declared with Dynamic_Lookup keeps its name
   --  and answers here. One declared without it is reachable through
   --  the constants alone, and answers the null entry to every lookup --
   --  which is how a dynamic sheet naming it is rejected rather than
   --  installed as a selector that matches nothing.
   function Has_Names (P : Property) return Boolean;

   function Find_Property (Name : String) return Property;
   function Find_Value (Owner : Property; Name : String) return Property_Value;

   function Name_Of (P : Property) return String;
   function Name_Of (V : Property_Value) return String;

   ---------------------------------------------------------------------------
   --  What a widget assigns
   ---------------------------------------------------------------------------

   type Property_Assignment is private;

   --  What a widget naming no property carries.
   Empty_Assignment : constant Property_Assignment;

   --  A property holds one value at a time, so setting it again
   --  replaces what it held.
   function With_Value (A : Property_Assignment;
                        V : Property_Value) return Property_Assignment;
   function Without (A : Property_Assignment;
                     P : Property) return Property_Assignment;

   function Value_Of (A : Property_Assignment;
                      P : Property) return Property_Value;
   function Assigned_Count (A : Property_Assignment) return Natural;

   ---------------------------------------------------------------------------
   --  What a selector requires
   ---------------------------------------------------------------------------

   type Property_Conditions is private;

   --  What a selector naming no property requires, which every
   --  assignment satisfies.
   No_Conditions : constant Property_Conditions;

   --  [severity="critical"], and [severity] whatever it is set to.
   function Conditions_On (V : Property_Value) return Property_Conditions;
   function Conditions_On (P : Property) return Property_Conditions;

   --  :not([severity="critical"]), and :not([severity]). CSS has no
   --  not-equal attribute operator, so negation is the only way to write
   --  "anything but", which is what a default rule beside a set of
   --  values needs. A widget that names the property not at all
   --  satisfies :not([severity="critical"]), as it does in CSS, and
   --  fails :not([severity]).
   function Conditions_Excluding (V : Property_Value)
     return Property_Conditions;
   function Conditions_Excluding (P : Property) return Property_Conditions;

   function Both (L, R : Property_Conditions) return Property_Conditions;
   function Common (L, R : Property_Conditions) return Property_Conditions;

   function Condition_Count (C : Property_Conditions) return Natural;

   function Satisfied_By (C : Property_Conditions;
                          A : Property_Assignment) return Boolean;

   ---------------------------------------------------------------------------
   --  Hashing
   ---------------------------------------------------------------------------

   --  Interning is canonical, so equal sets are one index and these are
   --  exact: equal hashes for equal sets, and a distinct hash for every
   --  distinct one. The resolved-style memo keys on an assignment
   --  beside the packed states it already holds.
   function Hash (A : Property_Assignment) return Ada.Containers.Hash_Type;
   function Hash (C : Property_Conditions) return Ada.Containers.Hash_Type;

   ---------------------------------------------------------------------------
   --  Instrumentation the tests read
   ---------------------------------------------------------------------------

   --  Sets the store holds, and pairs across them. Both stop rising once
   --  an application has named every assignment and condition it uses.
   function Set_Count return Natural;
   function Pair_Count return Natural;

   --  Storage the registry and the set store occupy, resident for the
   --  life of the process and independent of what an application
   --  declares.
   function Store_Bytes return Natural;

   --  Name characters the registry holds. A property declared without
   --  Dynamic_Lookup adds none.
   function Name_Bytes return Natural;

private

   type Property_Index is range 0 .. Max_Properties;
   type Value_Ordinal  is range 0 .. Max_Values_Per_Property - 1;
   type Set_Index      is range 0 .. Max_Property_Sets;

   type Property is new Property_Index;

   --  A value is its property and its position in that property's
   --  enumeration. Nothing assigns it: the position is what the
   --  declaration already fixed.
   type Property_Value is record
      Owner   : Property_Index := 0;
      Ordinal : Value_Ordinal  := 0;
   end record;

   No_Property : constant Property := 0;
   No_Value    : constant Property_Value := (Owner => 0, Ordinal => 0);

   type Property_Assignment is new Set_Index;
   type Property_Conditions is new Set_Index;

   --  Slot 0 is the empty set. Slot 1 carries one condition on the null
   --  property, which no assignment holds, so it is the set a caller
   --  gets when the store is full: a selector that matches nothing,
   --  rather than one that matches everything.
   Empty_Assignment : constant Property_Assignment := 0;
   No_Conditions    : constant Property_Conditions := 0;

   Unmatchable : constant Property_Conditions := 1;

   ---------------------------------------------------------------------------
   --  The write side, which Adi.Widget_Properties.Enumerated is
   ---------------------------------------------------------------------------

   --  A property declared with Dynamic_Lookup hands over the two
   --  questions its enumeration can answer: a name to a position, and a
   --  position back to a name. Nothing else knows what the values are,
   --  so a property declared without them costs no value names anywhere
   --  -- the registry never held them, and the enumeration's own image
   --  table is what the two answer from.
   --
   type Ordinal_Resolver is access function (Name : String) return Integer;
   type Ordinal_Namer is access function (Ordinal : Natural) return String;

   --  Answers No_Property when the registry is full, when the name does
   --  not fit, or when the enumeration carries more than
   --  Max_Values_Per_Property literals; each is reported through
   --  Adi.Log. Declaring a name twice answers the entry it has.
   function Declare_Property
     (Name     : String;
      Values   : Positive;
      Resolver : Ordinal_Resolver;
      Namer    : Ordinal_Namer) return Property;

   --  The value at a position of a property's enumeration.
   function Value_At (Owner : Property; Ordinal : Natural)
     return Property_Value;

end Adi.Widget_Properties;
