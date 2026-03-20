pragma Ada_2022;

with Interfaces.C;         use Interfaces.C;
with Interfaces.C.Strings;
with System;

package Adi.SDL.Locale is

   ----------------------------------------------------------------------------
   --  SDL_Locale Record
   ----------------------------------------------------------------------------

   type SDL_Locale is record
      Language : Interfaces.C.Strings.chars_ptr;
      Country  : Interfaces.C.Strings.chars_ptr;
   end record with Convention => C_Pass_By_Copy;

   type SDL_Locale_Access is access all SDL_Locale with Convention => C;

   ----------------------------------------------------------------------------
   --  Raw SDL Binding
   ----------------------------------------------------------------------------

   function SDL_GetPreferredLocales
     (Count : access int) return System.Address
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetPreferredLocales";
   --  Returns a NULL-terminated heap-allocated array of SDL_Locale * (i.e.
   --  SDL_Locale **).  Caller must free the array itself with SDL_free.

   ----------------------------------------------------------------------------
   --  Ada Helper
   ----------------------------------------------------------------------------

   function Get_Preferred_Language return String;
   --  Return the user's preferred language code (e.g. "en", "fr", "pt_BR").
   --  Returns "" if locale detection fails or no locales are available.

end Adi.SDL.Locale;
