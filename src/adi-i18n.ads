pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Adi.I18N is

   ---------------------------------------------------------------------------
   --  Plural Forms Type
   ---------------------------------------------------------------------------

   type Plural_Forms is array (Natural range <>) of Unbounded_String;

   ---------------------------------------------------------------------------
   --  Language Management
   ---------------------------------------------------------------------------

   procedure Set_Language (Lang : String);
   --  Set the current language code (e.g. "fr", "de", "pt_BR").
   --  Must be called before UI build.  If not called, the language is
   --  auto-detected from SDL_GetPreferredLocales on first Translate call.

   function Get_Language return String;
   --  Return the current language code.  Auto-detects from SDL on first
   --  call if Set_Language was not called.

   ---------------------------------------------------------------------------
   --  Simple Translation
   ---------------------------------------------------------------------------

   function Translate (Msg_Id : String) return String;
   --  Look up Msg_Id in the current language catalog.
   --  Returns Msg_Id unchanged if no translation is found (passthrough).

   function Translate (Context : String; Msg_Id : String) return String;
   --  Look up Msg_Id with context disambiguation.
   --  Context corresponds to gettext's msgctxt.

   function T (Msg_Id : String) return String renames Translate;
   --  Short alias for Translate.

   ---------------------------------------------------------------------------
   --  Plural Translation
   ---------------------------------------------------------------------------

   function Translate_Plural
     (Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String;
   --  Look up the correct plural form for N.
   --  Msg_Id is the singular form (also the lookup key).
   --  Msg_Id_Plural is the English plural (fallback when no translation).

   function Translate_Plural
     (Context       : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String;
   --  Plural translation with context disambiguation.

   function Tn
     (Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String renames Translate_Plural;
   --  Short alias for Translate_Plural.

   ---------------------------------------------------------------------------
   --  Explicit-Language Translation
   ---------------------------------------------------------------------------
   --  These variants accept an explicit language code instead of using the
   --  global language.  They do not read or modify the global language state.

   function Translate_Language
     (Language : String; Msg_Id : String) return String;
   --  Look up Msg_Id in the catalog for Language.
   --  Returns Msg_Id unchanged if no translation is found.

   function Translate_Language
     (Language : String; Context : String; Msg_Id : String) return String;
   --  Explicit-language lookup with context disambiguation.

   function TL (Language : String; Msg_Id : String) return String
     renames Translate_Language;
   --  Short alias for Translate_Language (no-context form).

   function Translate_Plural_Language
     (Language      : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String;
   --  Explicit-language plural translation.

   function Translate_Plural_Language
     (Language      : String;
      Context       : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String;
   --  Explicit-language plural translation with context.

   function TnL
     (Language      : String;
      Msg_Id        : String;
      Msg_Id_Plural : String;
      N             : Natural) return String
     renames Translate_Plural_Language;
   --  Short alias for Translate_Plural_Language (no-context form).

   ---------------------------------------------------------------------------
   --  Registration (called from generated packages)
   ---------------------------------------------------------------------------

   procedure Register
     (Language : String;
      Msg_Id   : String;
      Msg_Str  : String;
      Context  : String := "");
   --  Register a single translation entry.

   procedure Register_Plural
     (Language : String;
      Msg_Id   : String;
      Forms    : Plural_Forms;
      Context  : String := "");
   --  Register plural form translations.

   procedure Register_Plural_Formula
     (Language  : String;
      N_Plurals : Positive;
      Formula   : String);
   --  Register the plural formula for a language.
   --  Formula is a C-like expression using variable 'n'.
   --  Example: "n != 1" (English), "n > 1" (French).

   ---------------------------------------------------------------------------
   --  Catalog Management
   ---------------------------------------------------------------------------

   procedure Clear;
   --  Remove all registered translations, formulas, and reset language.

end Adi.I18N;
