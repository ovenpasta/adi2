--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Interfaces.C.Strings;
with System;
with Adi.SDL.Video;

package Adi.SDL.Dialog is

   ---------------------------------------------------------------------------
   --  Types
   ---------------------------------------------------------------------------

   type SDL_DialogFileFilter is record
      Name    : Interfaces.C.Strings.chars_ptr;
      Pattern : Interfaces.C.Strings.chars_ptr;
   end record
   with Convention => C_Pass_By_Copy;

   type SDL_DialogFileFilter_Array is
     array (Interfaces.C.int range <>) of aliased SDL_DialogFileFilter
   with Convention => C;

   --  Callback: userdata, filelist (null-terminated array of chars_ptr), filter
   type SDL_DialogFileCallback is access procedure
     (Userdata  : System.Address;
      Filelist  : System.Address;
      Filter    : Interfaces.C.int)
   with Convention => C;

   ---------------------------------------------------------------------------
   --  Functions
   ---------------------------------------------------------------------------

   procedure SDL_ShowOpenFileDialog
     (Callback         : SDL_DialogFileCallback;
      Userdata         : System.Address;
      Window           : Adi.SDL.Video.SDL_Window_Ptr;
      Filters          : access constant SDL_DialogFileFilter;
      Nfilters         : Interfaces.C.int;
      Default_Location : Interfaces.C.Strings.chars_ptr;
      Allow_Many       : C_bool)
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_ShowOpenFileDialog";

   procedure SDL_ShowSaveFileDialog
     (Callback         : SDL_DialogFileCallback;
      Userdata         : System.Address;
      Window           : Adi.SDL.Video.SDL_Window_Ptr;
      Filters          : access constant SDL_DialogFileFilter;
      Nfilters         : Interfaces.C.int;
      Default_Location : Interfaces.C.Strings.chars_ptr)
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_ShowSaveFileDialog";

   procedure SDL_ShowOpenFolderDialog
     (Callback         : SDL_DialogFileCallback;
      Userdata         : System.Address;
      Window           : Adi.SDL.Video.SDL_Window_Ptr;
      Default_Location : Interfaces.C.Strings.chars_ptr;
      Allow_Many       : C_bool)
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_ShowOpenFolderDialog";

end Adi.SDL.Dialog;
