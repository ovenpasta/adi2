--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

private package Adi.I18N.Catalog is

   procedure Register
     (Language : String;
      Key      : String;
      Msg_Str  : String);

   function Lookup
     (Language : String;
      Key      : String) return String;
   --  Returns "" if not found.

   procedure Register_Plural
     (Language : String;
      Key      : String;
      Forms    : Plural_Forms);

   function Lookup_Plural
     (Language : String;
      Key      : String) return Plural_Forms;
   --  Returns empty array if not found.

   type Formula_Record is record
      N_Plurals : Positive := 2;
      Formula   : Unbounded_String := Null_Unbounded_String;
   end record;

   procedure Register_Formula
     (Language  : String;
      N_Plurals : Positive;
      Formula   : String);

   function Lookup_Formula (Language : String) return Formula_Record;
   --  Returns (2, "n != 1") if not found (English default).

   function Has_Language (Language : String) return Boolean;
   --  Returns True if any singular translation exists for the language.

   procedure Clear;

end Adi.I18N.Catalog;
