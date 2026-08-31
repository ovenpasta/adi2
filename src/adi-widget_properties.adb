--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;
with Adi.Log;

package body Adi.Widget_Properties is

   package Char renames Ada.Characters.Handling;

   subtype Name_Position is Natural range 0 .. Max_Name_Characters;

   type Name_Span is record
      First  : Name_Position := 0;
      Length : Natural       := 0;
   end record;

   Name_Chars : String (1 .. Max_Name_Characters);
   Name_Used  : Name_Position := 0;

   type Property_Entry is record
      Name     : Name_Span;
      Values   : Natural := 0;
      Resolver : Ordinal_Resolver := null;
      Namer    : Ordinal_Namer    := null;
   end record;

   Properties     : array (1 .. Max_Properties) of Property_Entry;
   Property_Total : Natural := 0;

   ---------------------------------------------------------------------------
   --  The set store
   ---------------------------------------------------------------------------

   --  Has_Value distinguishes [severity="ok"] from [severity], the
   --  first ordinal being a value like any other. Negated is what
   --  :not() spells. An assignment never negates and always carries a
   --  value: it says what the widget holds.
   type Pair is record
      Property  : Property_Index := 0;
      Ordinal   : Value_Ordinal  := 0;
      Has_Value : Boolean        := False;
      Negated   : Boolean        := False;
   end record;

   --  Pairs one set may carry. An assignment holds at most one per
   --  property; a selector may name a property twice, which is a
   --  condition pair no assignment satisfies.
   Max_Set_Length : constant := Max_Properties;

   subtype Set_Length is Natural range 0 .. Max_Set_Length;
   type Pair_Array is array (Positive range <>) of Pair;

   type Set_Span is record
      First  : Natural    := 0;
      Length : Set_Length := 0;
      Digest : Natural    := 0;
   end record;

   Pairs      : array (1 .. Max_Set_Pairs) of Pair;
   Pairs_Used : Natural := 0;

   Sets      : array (1 .. Max_Property_Sets) of Set_Span;
   Set_Total : Natural := 0;

   ---------------------------------------------------------------------------
   --  Names
   ---------------------------------------------------------------------------

   function Text_Of (Span : Name_Span) return String is
     (Name_Chars (Span.First .. Span.First + Span.Length - 1));

   --  Names are matched the way CSS matches an identifier here: folded
   --  to lower case, with the surrounding blanks gone.
   function Folded (Name : String) return String is
      First : Natural := Name'First;
      Last  : Natural := Name'Last;
   begin
      while First <= Last and then Name (First) = ' ' loop
         First := First + 1;
      end loop;
      while Last >= First and then Name (Last) = ' ' loop
         Last := Last - 1;
      end loop;
      return Char.To_Lower (Name (First .. Last));
   end Folded;

   function Store_Name (Name : String; Span : out Name_Span) return Boolean is
   begin
      if Name'Length = 0 or else Name'Length > Max_Name_Length then
         return False;
      end if;

      if Name_Used + Name'Length > Max_Name_Characters then
         return False;
      end if;

      Span := (First => Name_Used + 1, Length => Name'Length);
      Name_Chars (Span.First .. Span.First + Span.Length - 1) := Name;
      Name_Used := Name_Used + Name'Length;
      return True;
   end Store_Name;

   ---------------------------------------------------------------------------
   --  The registry
   ---------------------------------------------------------------------------

   function Has_Names (P : Property) return Boolean is
     (P /= No_Property and then Properties (Natural (P)).Name.Length > 0);

   function Find_Property (Name : String) return Property is
      Key : constant String := Folded (Name);
   begin
      for I in 1 .. Property_Total loop
         if Properties (I).Name.Length > 0
           and then Text_Of (Properties (I).Name) = Key
         then
            return Property (I);
         end if;
      end loop;
      return No_Property;
   end Find_Property;

   function Value_At (Owner : Property; Ordinal : Natural)
     return Property_Value is
     (if Owner = No_Property or else Ordinal >= Value_Count (Owner)
      then No_Value
      else (Owner => Property_Index (Owner), Ordinal => Value_Ordinal (Ordinal)));

   function Find_Value (Owner : Property; Name : String)
     return Property_Value is
   begin
      if Owner = No_Property
        or else Properties (Natural (Owner)).Resolver = null
      then
         return No_Value;
      end if;

      declare
         Ordinal : constant Integer :=
           Properties (Natural (Owner)).Resolver (Folded (Name));
      begin
         if Ordinal < 0 then
            return No_Value;
         end if;
         return Value_At (Owner, Ordinal);
      end;
   end Find_Value;

   function Declare_Property
     (Name     : String;
      Values   : Positive;
      Resolver : Ordinal_Resolver;
      Namer    : Ordinal_Namer) return Property
   is
      Key      : constant String := Folded (Name);
      Existing : constant Property := Find_Property (Key);
      Span     : Name_Span;
   begin
      --  A second declaration of one name is that name again, so long
      --  as it spells the same vocabulary. A differing count is two
      --  properties asking for one entry, where the shorter one wins and
      --  the values past its end read as absent.
      if Existing /= No_Property then
         if Properties (Positive (Existing)).Values /= Values then
            Adi.Log.Error
              ("widget property '" & Key & "' declares" & Values'Image
               & " values where it holds"
               & Properties (Positive (Existing)).Values'Image);
            return No_Property;
         end if;
         return Existing;
      end if;

      if Values > Max_Values_Per_Property then
         Adi.Log.Error
           ("widget property '" & Key & "' declares" & Values'Image
            & " values, past the limit of"
            & Natural'Image (Max_Values_Per_Property));
         return No_Property;
      end if;

      if Property_Total >= Max_Properties then
         Adi.Log.Error
           ("widget property '" & Key & "' past the limit of"
            & Natural'Image (Max_Properties) & " properties");
         return No_Property;
      end if;

      --  A property reachable only through the constants keeps no name,
      --  which is what leaves its text out of the binary.
      Span := (First => 0, Length => 0);
      if Resolver /= null and then not Store_Name (Key, Span) then
         Adi.Log.Error
           ("widget property name '" & Key & "' does not fit the registry");
         return No_Property;
      end if;

      Property_Total := Property_Total + 1;
      Properties (Property_Total) :=
        (Name     => Span,
         Values   => Values,
         Resolver => Resolver,
         Namer    => Namer);
      return Property (Property_Total);
   end Declare_Property;

   function Property_Of (V : Property_Value) return Property is
     (Property (V.Owner));

   function Value_Count (P : Property) return Natural is
     (if P = No_Property then 0 else Properties (Natural (P)).Values);

   function Name_Of (P : Property) return String is
     (if Has_Names (P) then Text_Of (Properties (Natural (P)).Name) else "");

   function Name_Of (V : Property_Value) return String is
   begin
      if V = No_Value or else Properties (Natural (V.Owner)).Namer = null then
         return "";
      end if;
      return Properties (Natural (V.Owner)).Namer (Natural (V.Ordinal));
   end Name_Of;

   function Property_Count return Natural is (Property_Total);

   ---------------------------------------------------------------------------
   --  Interning a set
   ---------------------------------------------------------------------------

   function Rank (P : Pair) return Natural is
     (((Natural (P.Property) * Max_Values_Per_Property
        + Natural (P.Ordinal)) * 2
       + (if P.Has_Value then 1 else 0)) * 2
      + (if P.Negated then 1 else 0));

   function Precedes (L, R : Pair) return Boolean is (Rank (L) < Rank (R));

   function Digest_Of (Items : Pair_Array) return Natural is
      H : Natural := 17;
   begin
      for P of Items loop
         H := (H * 31 + Rank (P)) mod 1_048_573;
      end loop;
      return H;
   end Digest_Of;

   function Same_Set (Index : Positive; Items : Pair_Array) return Boolean is
      Span : Set_Span renames Sets (Index);
   begin
      if Span.Length /= Items'Length then
         return False;
      end if;

      for I in 0 .. Items'Length - 1 loop
         if Pairs (Span.First + I) /= Items (Items'First + I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Set;

   --  Items arrives sorted and free of repeats, which is what makes the
   --  answer canonical: equal sets are one index, so an index comparison
   --  is a set comparison and the resolved-style memo can key on it.
   function Intern_Set (Items : Pair_Array) return Set_Index is
      Digest : constant Natural := Digest_Of (Items);
   begin
      if Items'Length = 0 then
         return 0;
      end if;

      for I in 1 .. Set_Total loop
         if Sets (I).Digest = Digest and then Same_Set (I, Items) then
            return Set_Index (I);
         end if;
      end loop;

      if Set_Total >= Max_Property_Sets
        or else Pairs_Used + Items'Length > Max_Set_Pairs
      then
         Adi.Log.Error
           ("widget property set store is full at"
            & Natural'Image (Set_Total) & " sets and"
            & Natural'Image (Pairs_Used) & " pairs");
         return Set_Index (Unmatchable);
      end if;

      Set_Total := Set_Total + 1;
      Sets (Set_Total) := (First  => Pairs_Used + 1,
                           Length => Items'Length,
                           Digest => Digest);
      for I in Items'Range loop
         Pairs_Used := Pairs_Used + 1;
         Pairs (Pairs_Used) := Items (I);
      end loop;
      return Set_Index (Set_Total);
   end Intern_Set;

   --  A stored set, read back into a buffer the callers below edit.
   procedure Read_Set (Index : Set_Index;
                       Items : out Pair_Array;
                       Count : out Set_Length) is
   begin
      Count := 0;
      if Index = 0 then
         return;
      end if;

      declare
         Span : Set_Span renames Sets (Natural (Index));
      begin
         Count := Span.Length;
         for I in 1 .. Span.Length loop
            Items (Items'First + I - 1) := Pairs (Span.First + I - 1);
         end loop;
      end;
   end Read_Set;

   --  Insert in order, dropping a repeat. Answers False when the buffer
   --  is full, which is what the callers report.
   function Insert (Items : in out Pair_Array;
                    Count : in out Set_Length;
                    P     : Pair) return Boolean is
      Slot : Positive := Items'First + Count;
   begin
      for I in 0 .. Count - 1 loop
         if Items (Items'First + I) = P then
            return True;
         end if;
         if Precedes (P, Items (Items'First + I)) then
            Slot := Items'First + I;
            exit;
         end if;
      end loop;

      if Count = Max_Set_Length then
         return False;
      end if;

      for I in reverse Slot .. Items'First + Count - 1 loop
         Items (I + 1) := Items (I);
      end loop;
      Items (Slot) := P;
      Count := Count + 1;
      return True;
   end Insert;

   ---------------------------------------------------------------------------
   --  Assignments
   ---------------------------------------------------------------------------

   function With_Value (A : Property_Assignment;
                        V : Property_Value) return Property_Assignment is
      Items : Pair_Array (1 .. Max_Set_Length);
      Count : Set_Length;
   begin
      if V = No_Value then
         return A;
      end if;

      Read_Set (Set_Index (A), Items, Count);

      --  One value at a time, so the property's earlier value goes.
      declare
         Kept : Set_Length := 0;
      begin
         for I in 1 .. Count loop
            if Items (I).Property /= V.Owner then
               Kept := Kept + 1;
               Items (Kept) := Items (I);
            end if;
         end loop;
         Count := Kept;
      end;

      if not Insert (Items, Count,
                     (Property  => V.Owner,
                      Ordinal   => V.Ordinal,
                      Has_Value => True,
                      Negated   => False))
      then
         Adi.Log.Error
           ("a widget cannot carry more than"
            & Natural'Image (Max_Set_Length) & " widget properties");
         return A;
      end if;

      return Property_Assignment (Intern_Set (Items (1 .. Count)));
   end With_Value;

   function Without (A : Property_Assignment;
                     P : Property) return Property_Assignment is
      Items : Pair_Array (1 .. Max_Set_Length);
      Count : Set_Length;
      Kept  : Set_Length := 0;
   begin
      if P = No_Property or else A = Empty_Assignment then
         return A;
      end if;

      Read_Set (Set_Index (A), Items, Count);
      for I in 1 .. Count loop
         if Items (I).Property /= Property_Index (P) then
            Kept := Kept + 1;
            Items (Kept) := Items (I);
         end if;
      end loop;

      return Property_Assignment (Intern_Set (Items (1 .. Kept)));
   end Without;

   function Value_Of (A : Property_Assignment;
                      P : Property) return Property_Value is
   begin
      if P = No_Property or else A = Empty_Assignment then
         return No_Value;
      end if;

      declare
         Span : Set_Span renames Sets (Natural (A));
      begin
         for I in 1 .. Span.Length loop
            declare
               Held : Pair renames Pairs (Span.First + I - 1);
            begin
               if Held.Property = Property_Index (P) then
                  return (Owner => Held.Property, Ordinal => Held.Ordinal);
               end if;
            end;
         end loop;
      end;
      return No_Value;
   end Value_Of;

   function Assigned_Count (A : Property_Assignment) return Natural is
     (if A = Empty_Assignment then 0 else Sets (Natural (A)).Length);

   ---------------------------------------------------------------------------
   --  Conditions
   ---------------------------------------------------------------------------

   function Single (P : Pair) return Property_Conditions is
      Items : constant Pair_Array (1 .. 1) := [1 => P];
   begin
      return Property_Conditions (Intern_Set (Items));
   end Single;

   function On_Value (V : Property_Value; Negated : Boolean)
     return Property_Conditions is
     (if V = No_Value then Unmatchable
      else Single ((Property  => V.Owner,
                    Ordinal   => V.Ordinal,
                    Has_Value => True,
                    Negated   => Negated)));

   function On_Property (P : Property; Negated : Boolean)
     return Property_Conditions is
     (if P = No_Property then Unmatchable
      else Single ((Property  => Property_Index (P),
                    Ordinal   => 0,
                    Has_Value => False,
                    Negated   => Negated)));

   function Conditions_On (V : Property_Value) return Property_Conditions is
     (On_Value (V, Negated => False));

   function Conditions_On (P : Property) return Property_Conditions is
     (On_Property (P, Negated => False));

   function Conditions_Excluding (V : Property_Value)
     return Property_Conditions is
     (On_Value (V, Negated => True));

   function Conditions_Excluding (P : Property) return Property_Conditions is
     (On_Property (P, Negated => True));

   function Both (L, R : Property_Conditions) return Property_Conditions is
      Items : Pair_Array (1 .. Max_Set_Length);
      Count : Set_Length;
      Extra : Pair_Array (1 .. Max_Set_Length);
      Added : Set_Length;
   begin
      if L = No_Conditions then
         return R;
      elsif R = No_Conditions then
         return L;
      end if;

      Read_Set (Set_Index (L), Items, Count);
      Read_Set (Set_Index (R), Extra, Added);

      for I in 1 .. Added loop
         if not Insert (Items, Count, Extra (I)) then
            Adi.Log.Error
              ("a selector cannot name more than"
               & Natural'Image (Max_Set_Length) & " widget properties");
            return Unmatchable;
         end if;
      end loop;

      return Property_Conditions (Intern_Set (Items (1 .. Count)));
   end Both;

   function Common (L, R : Property_Conditions) return Property_Conditions is
      Items : Pair_Array (1 .. Max_Set_Length);
      Count : Set_Length;
      Other : Pair_Array (1 .. Max_Set_Length);
      Total : Set_Length;
      Kept  : Set_Length := 0;
   begin
      if L = No_Conditions or else R = No_Conditions then
         return No_Conditions;
      end if;

      Read_Set (Set_Index (L), Items, Count);
      Read_Set (Set_Index (R), Other, Total);

      for I in 1 .. Count loop
         for J in 1 .. Total loop
            if Items (I) = Other (J) then
               Kept := Kept + 1;
               Items (Kept) := Items (I);
               exit;
            end if;
         end loop;
      end loop;

      return Property_Conditions (Intern_Set (Items (1 .. Kept)));
   end Common;

   function Condition_Count (C : Property_Conditions) return Natural is
     (if C = No_Conditions then 0 else Sets (Natural (C)).Length);

   function Satisfied_By (C : Property_Conditions;
                          A : Property_Assignment) return Boolean is
   begin
      if C = No_Conditions then
         return True;
      end if;

      declare
         Cond : Set_Span renames Sets (Natural (C));
      begin
         for I in 1 .. Cond.Length loop
            declare
               Want  : Pair renames Pairs (Cond.First + I - 1);
               Found : Boolean := False;
            begin
               if A /= Empty_Assignment then
                  declare
                     Have : Set_Span renames Sets (Natural (A));
                  begin
                     for J in 1 .. Have.Length loop
                        declare
                           Got : Pair renames Pairs (Have.First + J - 1);
                        begin
                           --  A condition naming no value asks only that
                           --  the property is set, whatever it is set to.
                           if Got.Property = Want.Property
                             and then (not Want.Has_Value
                                       or else Got.Ordinal = Want.Ordinal)
                           then
                              Found := True;
                              exit;
                           end if;
                        end;
                     end loop;
                  end;
               end if;

               if Found = Want.Negated then
                  return False;
               end if;
            end;
         end loop;
      end;

      return True;
   end Satisfied_By;

   function Hash (A : Property_Assignment) return Ada.Containers.Hash_Type is
     (Ada.Containers.Hash_Type (A));

   function Hash (C : Property_Conditions) return Ada.Containers.Hash_Type is
     (Ada.Containers.Hash_Type (C));

   ---------------------------------------------------------------------------
   --  Instrumentation
   ---------------------------------------------------------------------------

   function Set_Count return Natural is (Set_Total);
   function Pair_Count return Natural is (Pairs_Used);

   function Name_Bytes return Natural is (Name_Used);

   function Store_Bytes return Natural is
     (Name_Chars'Size / 8
      + Properties'Size / 8
      + Pairs'Size / 8
      + Sets'Size / 8);

begin
   --  Slot 1 carries one condition on the null property, which no
   --  assignment holds, so it is the set a caller gets when the store is
   --  full: a selector matching nothing rather than everything.
   Set_Total := 1;
   Sets (1) := (First  => 1,
                Length => 1,
                Digest => Digest_Of ([1 => (0, 0, False, False)]));
   Pairs (1) := (Property => 0, Ordinal => 0,
                 Has_Value => False, Negated => False);
   Pairs_Used := 1;
end Adi.Widget_Properties;
