--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System.Address_To_Access_Conversions;
with Interfaces.C.Strings; use Interfaces.C.Strings;

package body Adi.SDL.Locale is
   use type System.Address;

   --  SDL_GetPreferredLocales returns SDL_Locale **: Addr points to an array of SDL_Locale_Access, each pointing to one SDL_Locale record.

   package Array_Conversions is
     new System.Address_To_Access_Conversions (SDL_Locale_Access);

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
         First_Ptr : constant SDL_Locale_Access :=
           Array_Conversions.To_Pointer (Addr).all;
         Lang   : constant chars_ptr :=
           (if First_Ptr = null then Null_Ptr else First_Ptr.Language);
         Result : constant String :=
           (if Lang = Null_Ptr then "" else Value (Lang));
      begin
         Adi.SDL.SDL_free (Addr);
         return Result;
      end;
   end Get_Preferred_Language;

end Adi.SDL.Locale;
