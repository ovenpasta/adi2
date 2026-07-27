--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Interfaces.C.Strings;

package Adi.SDL.Filesystem is

   ---------------------------------------------------------------------------
   --  Enumerations
   ---------------------------------------------------------------------------

   type SDL_Folder is
     (SDL_FOLDER_HOME,
      SDL_FOLDER_DESKTOP,
      SDL_FOLDER_DOCUMENTS,
      SDL_FOLDER_DOWNLOADS,
      SDL_FOLDER_MUSIC,
      SDL_FOLDER_PICTURES,
      SDL_FOLDER_PUBLICSHARE,
      SDL_FOLDER_SAVEDGAMES,
      SDL_FOLDER_SCREENSHOTS,
      SDL_FOLDER_TEMPLATES,
      SDL_FOLDER_VIDEOS)
   with Convention => C;

   type SDL_PathType is
     (SDL_PATHTYPE_NONE,
      SDL_PATHTYPE_FILE,
      SDL_PATHTYPE_DIRECTORY,
      SDL_PATHTYPE_OTHER)
   with Convention => C;

   ---------------------------------------------------------------------------
   --  Types
   ---------------------------------------------------------------------------

   --  SDL_Time is Sint64 (nanoseconds since Unix epoch)
   subtype SDL_Time is Long_Long_Integer;

   type SDL_PathInfo is record
      Kind        : aliased SDL_PathType;
      Size        : aliased Uint64;
      Create_Time : aliased SDL_Time;
      Modify_Time : aliased SDL_Time;
      Access_Time : aliased SDL_Time;
   end record
   with Convention => C_Pass_By_Copy;

   ---------------------------------------------------------------------------
   --  Functions
   ---------------------------------------------------------------------------

   --  Returns a string owned by SDL (do NOT free). May return Null_Ptr.
   function SDL_GetBasePath return Interfaces.C.Strings.chars_ptr
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_GetBasePath";

   --  Returns a string that must be freed with SDL_free.
   function SDL_GetPrefPath
     (Org : Interfaces.C.Strings.chars_ptr;
      App : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Strings.chars_ptr
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_GetPrefPath";

   --  Returns a string owned by SDL (do NOT free). May return Null_Ptr.
   function SDL_GetUserFolder
     (Folder : SDL_Folder) return Interfaces.C.Strings.chars_ptr
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_GetUserFolder";

   --  Returns a string that must be freed with SDL_free.
   function SDL_GetCurrentDirectory return Interfaces.C.Strings.chars_ptr
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_GetCurrentDirectory";

   function SDL_CreateDirectory
     (Path : Interfaces.C.Strings.chars_ptr) return C_bool
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_CreateDirectory";

   function SDL_RemovePath
     (Path : Interfaces.C.Strings.chars_ptr) return C_bool
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_RemovePath";

   function SDL_RenamePath
     (Old_Path : Interfaces.C.Strings.chars_ptr;
      New_Path : Interfaces.C.Strings.chars_ptr) return C_bool
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_RenamePath";

   function SDL_CopyFile
     (Old_Path : Interfaces.C.Strings.chars_ptr;
      New_Path : Interfaces.C.Strings.chars_ptr) return C_bool
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_CopyFile";

   function SDL_GetPathInfo
     (Path : Interfaces.C.Strings.chars_ptr;
      Info : access SDL_PathInfo) return C_bool
   with Import        => True,
        Convention    => C,
        External_Name => "SDL_GetPathInfo";

end Adi.SDL.Filesystem;
