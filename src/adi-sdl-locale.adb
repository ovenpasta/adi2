pragma Ada_2022;

with System.Address_To_Access_Conversions;
with Interfaces.C.Strings; use Interfaces.C.Strings;

package body Adi.SDL.Locale is
   use type System.Address;

   package Locale_Conversions is
     new System.Address_To_Access_Conversions (SDL_Locale);

   function Get_Preferred_Language return String is
      Count : aliased int := 0;
      Addr  : constant System.Address :=
        SDL_GetPreferredLocales (Count'Access);
   begin
      if Addr = System.Null_Address then
         return "";
      end if;

      if Count < 1 then
         Adi.SDL.SDL_free (Addr);
         return "";
      end if;

      declare
         Ptr    : constant Locale_Conversions.Object_Pointer :=
           Locale_Conversions.To_Pointer (Addr);
         Lang   : constant chars_ptr := Ptr.Language;
         Result : constant String :=
           (if Lang = Null_Ptr then "" else Value (Lang));
      begin
         Adi.SDL.SDL_free (Addr);
         return Result;
      end;
   end Get_Preferred_Language;

end Adi.SDL.Locale;
