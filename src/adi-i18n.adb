--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling; use Ada.Characters.Handling;
with Adi.I18N.Catalog;
with Adi.I18N.Plural;
with Adi.SDL.Locale;

package body Adi.I18N is

   Current_Language : Unbounded_String := Null_Unbounded_String;
   Language_Set     : Boolean := False;

   ---------------------------------------------------------------------------
   --  Locale Helpers
   ---------------------------------------------------------------------------

   function Canonicalize (Lang : String) return String is
      Result : String := To_Lower (Lang);
   begin
      for I in Result'Range loop
         if Result (I) = '-' then
            Result (I) := '_';
         end if;
      end loop;
      return Result;
   end Canonicalize;

   function Base_Language (Lang : String) return String is
   begin
      for I in Lang'Range loop
         if Lang (I) = '_' then
            return Lang (Lang'First .. I - 1);
         end if;
      end loop;
      return "";
   end Base_Language;

   function Make_Key (Context : String; Msg_Id : String) return String is
   begin
      if Context'Length > 0 then
         return Context & ASCII.NUL & Msg_Id;
      end if;
      return Msg_Id;
   end Make_Key;

   ---------------------------------------------------------------------------
   --  Language Management
   ---------------------------------------------------------------------------

   procedure Set_Language (Lang : String) is
   begin
      Current_Language := To_Unbounded_String (Canonicalize (Lang));
      Language_Set := True;
   end Set_Language;

   function Get_Language return String is
   begin
      if not Language_Set then
         declare
            Detected : constant String :=
              Adi.SDL.Locale.Get_Preferred_Language;
         begin
            Current_Language :=
              To_Unbounded_String (Canonicalize (Detected));
            Language_Set := True;
         end;
      end if;
      return To_String (Current_Language);
   end Get_Language;

   ---------------------------------------------------------------------------
   --  Lookup with Fallback
   ---------------------------------------------------------------------------

   function Lookup_With_Fallback
     (Lang : String;
      Key  : String) return String
   is
      --  Try exact canonical language
      Result : constant String := Catalog.Lookup (Lang, Key);
   begin
      if Result'Length > 0 then
         return Result;
      end if;

      --  Try base language (strip region)
      declare
         Base : constant String := Base_Language (Lang);
      begin
         if Base'Length > 0 and then Base /= Lang then
            return Catalog.Lookup (Base, Key);
         end if;
      end;

      return "";
   end Lookup_With_Fallback;

   function Lookup_Plural_With_Fallback
     (Lang : String;
      Key  : String) return Plural_Forms
   is
      --  Try exact canonical language
      Result : constant Plural_Forms := Catalog.Lookup_Plural (Lang, Key);
   begin
      if Result'Length > 0 then
         return Result;
      end if;

      --  Try base language (strip region)
      declare
         Base : constant String := Base_Language (Lang);
      begin
         if Base'Length > 0 and then Base /= Lang then
            return Catalog.Lookup_Plural (Base, Key);
         end if;
      end;

      declare
         Empty : Plural_Forms (1 .. 0);
      begin
         return Empty;
      end;
   end Lookup_Plural_With_Fallback;

   function Lookup_Formula_With_Fallback
     (Lang : String) return Catalog.Formula_Record
   is
      Result : constant Catalog.Formula_Record := Catalog.Lookup_Formula (Lang);
   begin
      --  If we got the default and there's a base language, try that
      if Result.Formula = To_Unbounded_String ("n != 1") then
         declare
            Base : constant String := Base_Language (Lang);
         begin
            if Base'Length > 0 and then Base /= Lang then
               declare
                  Base_Result : constant Catalog.Formula_Record :=
                    Catalog.Lookup_Formula (Base);
               begin
                  if Base_Result.Formula /=
                    To_Unbounded_String ("n != 1")
                  then
                     return Base_Result;
                  end if;
               end;
            end if;
         end;
      end if;
      return Result;
   end Lookup_Formula_With_Fallback;

   ---------------------------------------------------------------------------
   --  Simple Translation
   ---------------------------------------------------------------------------

   function Translate (Msg_Id : String) return String is
      Lang   : constant String := Get_Language;
      Key    : constant String := Msg_Id;
      Result : constant String := Lookup_With_Fallback (Lang, Key);
   begin
      if Result'Length > 0 then
         return Result;
      end if;
      return Msg_Id;
   end Translate;

   function Translate (Context : String; Msg_Id : String) return String is
      Lang   : constant String := Get_Language;
      Key    : constant String := Make_Key (Context, Msg_Id);
      Result : constant String := Lookup_With_Fallback (Lang, Key);
   begin
      if Result'Length > 0 then
         return Result;
      end if;
      return Msg_Id;
   end Translate;

   ---------------------------------------------------------------------------
   --  Plural Translation
   ---------------------------------------------------------------------------

   function Do_Translate_Plural
     (Lang          : String;
      Key           : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String
   is
      Forms : constant Plural_Forms :=
        Lookup_Plural_With_Fallback (Lang, Key);
   begin
      if Forms'Length > 0 then
         declare
            FR    : constant Catalog.Formula_Record :=
              Lookup_Formula_With_Fallback (Lang);
            Index : Natural :=
              Plural.Evaluate (To_String (FR.Formula), N);
         begin
            --  Clamp to valid range
            if Index > Forms'Last then
               Index := Forms'Last;
            end if;
            return To_String (Forms (Index));
         end;
      end if;

      --  Fallback: English singular/plural
      if N = 1 then
         return Msg_Id;
      else
         return Msg_Id_Plural;
      end if;
   end Do_Translate_Plural;

   function Translate_Plural
     (Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String
   is
   begin
      return Do_Translate_Plural
        (Get_Language, Msg_Id, Msg_Id, Msg_Id_Plural, N);
   end Translate_Plural;

   function Translate_Plural
     (Context       : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String
   is
   begin
      return Do_Translate_Plural
        (Get_Language, Make_Key (Context, Msg_Id), Msg_Id, Msg_Id_Plural, N);
   end Translate_Plural;

   ---------------------------------------------------------------------------
   --  Explicit-Language Translation
   ---------------------------------------------------------------------------

   function Translate_Language
     (Language : String; Msg_Id : String) return String
   is
      Lang   : constant String := Canonicalize (Language);
      Result : constant String := Lookup_With_Fallback (Lang, Msg_Id);
   begin
      if Result'Length > 0 then
         return Result;
      end if;
      return Msg_Id;
   end Translate_Language;

   function Translate_Language
     (Language : String; Context : String; Msg_Id : String) return String
   is
      Lang   : constant String := Canonicalize (Language);
      Key    : constant String := Make_Key (Context, Msg_Id);
      Result : constant String := Lookup_With_Fallback (Lang, Key);
   begin
      if Result'Length > 0 then
         return Result;
      end if;
      return Msg_Id;
   end Translate_Language;

   function Translate_Plural_Language
     (Language      : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String
   is
   begin
      return Do_Translate_Plural
        (Canonicalize (Language), Msg_Id, Msg_Id, Msg_Id_Plural, N);
   end Translate_Plural_Language;

   function Translate_Plural_Language
     (Language      : String;
      Context       : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String
   is
   begin
      return Do_Translate_Plural
        (Canonicalize (Language),
         Make_Key (Context, Msg_Id), Msg_Id, Msg_Id_Plural, N);
   end Translate_Plural_Language;

   ---------------------------------------------------------------------------
   --  Registration
   ---------------------------------------------------------------------------

   procedure Register
     (Language : String;
      Msg_Id   : String;
      Msg_Str  : String;
      Context  : String := "")
   is
      Lang : constant String := Canonicalize (Language);
      Key  : constant String := Make_Key (Context, Msg_Id);
   begin
      Catalog.Register (Lang, Key, Msg_Str);
   end Register;

   procedure Register_Plural
     (Language : String;
      Msg_Id   : String;
      Forms    : Plural_Forms;
      Context  : String := "")
   is
      Lang : constant String := Canonicalize (Language);
      Key  : constant String := Make_Key (Context, Msg_Id);
   begin
      Catalog.Register_Plural (Lang, Key, Forms);
   end Register_Plural;

   procedure Register_Plural_Formula
     (Language  : String;
      N_Plurals : Positive;
      Formula   : String)
   is
      Lang : constant String := Canonicalize (Language);
   begin
      Catalog.Register_Formula (Lang, N_Plurals, Formula);
   end Register_Plural_Formula;

   ---------------------------------------------------------------------------
   --  Clear
   ---------------------------------------------------------------------------

   procedure Clear is
   begin
      Catalog.Clear;
      Current_Language := Null_Unbounded_String;
      Language_Set := False;
   end Clear;

end Adi.I18N;
