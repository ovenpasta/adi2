--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.SDL is

   ---------------------------------------------------------------------------
   --  SDL_Assert
   ---------------------------------------------------------------------------

   procedure SDL_Assert (Result : C_bool; Func_Name : String) is
   begin
      pragma Assert (Result, "SDL function failed: " & Func_Name);
   end SDL_Assert;

end Adi.SDL;
