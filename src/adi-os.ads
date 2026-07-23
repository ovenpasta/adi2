--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Interfaces;
with Ada.Strings.Unbounded;
with Adi.Window;
with Adi.SDL.Filesystem;

package Adi.OS is

   ---------------------------------------------------------------------------
   --  String Array Type
   ---------------------------------------------------------------------------

   type String_Array is
     array (Positive range <>) of Ada.Strings.Unbounded.Unbounded_String;

   Empty_Strings : constant String_Array (1 .. 0) := [others => <>];

   ---------------------------------------------------------------------------
   --  File Dialog Types
   ---------------------------------------------------------------------------

   type File_Filter is record
      Name    : Ada.Strings.Unbounded.Unbounded_String;
      Pattern : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type File_Filter_Array is array (Positive range <>) of File_Filter;

   No_Filters : constant File_Filter_Array (1 .. 0) := [others => <>];

   --  Callback receives the selected file paths (empty array if cancelled).
   type Dialog_Callback is access procedure (Files : String_Array);

   procedure Show_Open_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle :=
                            Adi.Window.Null_Window_Handle;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "";
      Allow_Many       : Boolean := False);

   procedure Show_Save_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle :=
                            Adi.Window.Null_Window_Handle;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "");

   procedure Show_Open_Folder_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle :=
                            Adi.Window.Null_Window_Handle;
      Default_Location : String := "";
      Allow_Many       : Boolean := False);

   ---------------------------------------------------------------------------
   --  Paths
   ---------------------------------------------------------------------------

   --  Returns the directory where the application was run from.
   function Base_Path return String;

   --  Returns a per-user, per-app preferences directory.
   --  The directory is created if it does not exist.
   function Pref_Path (Org, App : String) return String;

   type User_Folder is
     (Home,
      Desktop,
      Documents,
      Downloads,
      Music,
      Pictures,
      Public_Share,
      Saved_Games,
      Screenshots,
      Templates,
      Videos);

   --  Returns the path to a well-known user folder, or "" if unavailable.
   function Get_User_Folder (Folder : User_Folder) return String;

   --  Returns the current working directory.
   function Current_Directory return String;

   ---------------------------------------------------------------------------
   --  Filesystem Operations
   ---------------------------------------------------------------------------

   type Path_Kind is (None, File, Directory, Other);

   type Path_Info is record
      Kind        : Path_Kind := None;
      Size        : Interfaces.Unsigned_64 := 0;
      Create_Time : Long_Long_Integer := 0;
      Modify_Time : Long_Long_Integer := 0;
      Access_Time : Long_Long_Integer := 0;
   end record;

   function Get_Path_Info (Path : String) return Path_Info;
   function Create_Directory (Path : String) return Boolean;
   function Remove_Path (Path : String) return Boolean;
   function Rename_Path (Old_Path, New_Path : String) return Boolean;
   function Copy_File (Source, Destination : String) return Boolean;

   ---------------------------------------------------------------------------
   --  Misc
   ---------------------------------------------------------------------------

   --  Open a URL in the user's default browser/handler. Returns True on
   --  success.
   function Open_URL (URL : String) return Boolean;

   ---------------------------------------------------------------------------
   --  Clipboard
   ---------------------------------------------------------------------------

   function Get_Clipboard_Text return String;
   procedure Set_Clipboard_Text (Text : String);
   function Has_Clipboard_Text return Boolean;

private
   --  Maps Ada User_Folder to SDL SDL_Folder
   function To_SDL_Folder
     (Folder : User_Folder) return Adi.SDL.Filesystem.SDL_Folder;

end Adi.OS;
