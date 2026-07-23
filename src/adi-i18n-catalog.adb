--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Indefinite_Ordered_Maps;

package body Adi.I18N.Catalog is

   ---------------------------------------------------------------------------
   --  Singular Translation Maps
   ---------------------------------------------------------------------------

   package Msg_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => String);

   package Lang_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Msg_Maps.Map,
      "="          => Msg_Maps."=");

   Singular_Registry : Lang_Maps.Map;

   ---------------------------------------------------------------------------
   --  Plural Translation Maps
   ---------------------------------------------------------------------------

   --  Fixed-size plural forms (up to 6 forms covers all known languages)
   Max_Plural_Forms : constant := 6;

   type Plural_Array is
     array (0 .. Max_Plural_Forms - 1) of Unbounded_String;

   type Stored_Plural is record
      Count : Natural := 0;
      Forms : Plural_Array := [others => Null_Unbounded_String];
   end record;

   package Plural_Msg_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Stored_Plural);

   package Plural_Lang_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Plural_Msg_Maps.Map,
      "="          => Plural_Msg_Maps."=");

   Plural_Registry : Plural_Lang_Maps.Map;

   ---------------------------------------------------------------------------
   --  Formula Maps
   ---------------------------------------------------------------------------

   package Formula_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Formula_Record);

   Formula_Registry : Formula_Maps.Map;

   Default_Formula : constant Formula_Record :=
     (N_Plurals => 2,
      Formula   => To_Unbounded_String ("n != 1"));

   ---------------------------------------------------------------------------
   --  Singular Translation
   ---------------------------------------------------------------------------

   procedure Register
     (Language : String;
      Key      : String;
      Msg_Str  : String)
   is
      use Lang_Maps;
      Pos : Cursor := Singular_Registry.Find (Language);
   begin
      if Pos = No_Element then
         Singular_Registry.Insert (Language, Msg_Maps.Empty_Map);
         Pos := Singular_Registry.Find (Language);
      end if;

      declare
         procedure Update (L : in String; M : in out Msg_Maps.Map) is
            pragma Unreferenced (L);
         begin
            if M.Contains (Key) then
               M.Replace (Key, Msg_Str);
            else
               M.Insert (Key, Msg_Str);
            end if;
         end Update;
      begin
         Singular_Registry.Update_Element (Pos, Update'Access);
      end;
   end Register;

   function Lookup
     (Language : String;
      Key      : String) return String
   is
      use Lang_Maps;
      Lang_Pos : constant Cursor := Singular_Registry.Find (Language);
   begin
      if Lang_Pos = No_Element then
         return "";
      end if;

      declare
         use type Msg_Maps.Cursor;
         Msgs    : Msg_Maps.Map renames Element (Lang_Pos);
         Msg_Pos : constant Msg_Maps.Cursor := Msgs.Find (Key);
      begin
         if Msg_Pos /= Msg_Maps.No_Element then
            return Msg_Maps.Element (Msg_Pos);
         end if;
      end;
      return "";
   end Lookup;

   ---------------------------------------------------------------------------
   --  Plural Translation
   ---------------------------------------------------------------------------

   procedure Register_Plural
     (Language : String;
      Key      : String;
      Forms    : Plural_Forms)
   is
      use Plural_Lang_Maps;
      Pos : Cursor := Plural_Registry.Find (Language);
      SP  : Stored_Plural;
   begin
      SP.Count := Natural'Min (Forms'Length, Max_Plural_Forms);
      for I in 0 .. SP.Count - 1 loop
         SP.Forms (I) := Forms (Forms'First + I);
      end loop;

      if Pos = No_Element then
         Plural_Registry.Insert (Language, Plural_Msg_Maps.Empty_Map);
         Pos := Plural_Registry.Find (Language);
      end if;

      declare
         procedure Update (L : in String; M : in out Plural_Msg_Maps.Map) is
            pragma Unreferenced (L);
         begin
            if M.Contains (Key) then
               M.Replace (Key, SP);
            else
               M.Insert (Key, SP);
            end if;
         end Update;
      begin
         Plural_Registry.Update_Element (Pos, Update'Access);
      end;
   end Register_Plural;

   function Lookup_Plural
     (Language : String;
      Key      : String) return Plural_Forms
   is
      use Plural_Lang_Maps;
      Lang_Pos : constant Cursor := Plural_Registry.Find (Language);
      Empty    : Plural_Forms (1 .. 0);
   begin
      if Lang_Pos = No_Element then
         return Empty;
      end if;

      declare
         use type Plural_Msg_Maps.Cursor;
         Msgs    : Plural_Msg_Maps.Map renames Element (Lang_Pos);
         Msg_Pos : constant Plural_Msg_Maps.Cursor := Msgs.Find (Key);
      begin
         if Msg_Pos /= Plural_Msg_Maps.No_Element then
            declare
               SP     : Stored_Plural renames
                 Plural_Msg_Maps.Element (Msg_Pos);
               Result : Plural_Forms (0 .. SP.Count - 1);
            begin
               for I in Result'Range loop
                  Result (I) := SP.Forms (I);
               end loop;
               return Result;
            end;
         end if;
      end;
      return Empty;
   end Lookup_Plural;

   ---------------------------------------------------------------------------
   --  Formula
   ---------------------------------------------------------------------------

   procedure Register_Formula
     (Language  : String;
      N_Plurals : Positive;
      Formula   : String)
   is
      Rec : constant Formula_Record :=
        (N_Plurals => N_Plurals,
         Formula   => To_Unbounded_String (Formula));
   begin
      if Formula_Registry.Contains (Language) then
         Formula_Registry.Replace (Language, Rec);
      else
         Formula_Registry.Insert (Language, Rec);
      end if;
   end Register_Formula;

   function Lookup_Formula (Language : String) return Formula_Record is
      use Formula_Maps;
      Pos : constant Cursor := Formula_Registry.Find (Language);
   begin
      if Pos /= No_Element then
         return Element (Pos);
      end if;
      return Default_Formula;
   end Lookup_Formula;

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------

   function Has_Language (Language : String) return Boolean is
   begin
      return Singular_Registry.Contains (Language)
        or else Plural_Registry.Contains (Language);
   end Has_Language;

   ---------------------------------------------------------------------------
   --  Clear
   ---------------------------------------------------------------------------

   procedure Clear is
   begin
      Singular_Registry.Clear;
      Plural_Registry.Clear;
      Formula_Registry.Clear;
   end Clear;

end Adi.I18N.Catalog;
