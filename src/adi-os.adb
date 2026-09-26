--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;
with Ada.Containers.Indefinite_Holders;
with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Interfaces.C;         use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;
with System;
with System.Storage_Elements;
with Ada.Environment_Variables;
with Adi.Dispatch;
with Adi.Log;
with Adi.SDL;
with Adi.SDL.Dialog;
with Adi.SDL.Misc;
with Adi.SDL.Video;

package body Adi.OS is

   use Adi.Window;

   function Is_Separator (C : Character) return Boolean is
     (C = '/' or else C = '\');

   --  Windows spells %TEMP% both with and without a trailing backslash,
   --  and either platform tolerates a repeated one. A root is all
   --  separator and keeps it: "C:" without the slash names the current
   --  directory on C:, not the drive.
   function Trim_Separator (Path : String) return String is
      Last : Natural := Path'Last;
   begin
      while Last > Path'First and then Is_Separator (Path (Last)) loop
         Last := Last - 1;
      end loop;

      if Last < Path'Last
        and then Last > Path'First
        and then Path (Last) = ':'
      then
         return Path (Path'First .. Last + 1);
      end if;

      return Path (Path'First .. Last);
   end Trim_Separator;

   --  SDL3 dialog callbacks arrive as C calls, on whichever thread SDL
   --  chooses; Stored_Callback and the trampoline carry them to
   --  Post_Dialog_Result.

   Stored_Callback : Dialog_Callback := null;

   --  Main thread only. Set when a Show_* opens a dialog and cleared when
   --  its answer is delivered, so one answer at most is ever in flight.
   Dialog_Open : Boolean := False;

   type Filter_List is access Adi.SDL.Dialog.SDL_DialogFileFilter_Array;

   --  SDL reads the open dialog's filters until it answers, so they are
   --  freed when the answer is delivered. Main thread only.
   Open_Filters : Filter_List;

   function New_Filters (Filters : File_Filter_Array) return Filter_List is
      use Ada.Strings.Unbounded;
      List : Filter_List;
   begin
      if Filters'Length = 0 then
         return null;
      end if;
      List := new Adi.SDL.Dialog.SDL_DialogFileFilter_Array
                    (0 .. Filters'Length - 1);
      for I in Filters'Range loop
         List (int (I - Filters'First)) :=
           (Name    => New_String (To_String (Filters (I).Name)),
            Pattern => New_String (To_String (Filters (I).Pattern)));
      end loop;
      return List;
   end New_Filters;

   procedure Free_Filters (List : in out Filter_List) is
      procedure Free_List is new Ada.Unchecked_Deallocation
        (Adi.SDL.Dialog.SDL_DialogFileFilter_Array, Filter_List);
   begin
      if List = null then
         return;
      end if;
      for Filter of List.all loop
         Free (Filter.Name);
         Free (Filter.Pattern);
      end loop;
      Free_List (List);
   end Free_Filters;

   --  The answering thread fills this before Adi.Dispatch.Post, and the
   --  main thread empties it after Drain, so Dispatch orders the two.

   type Dialog_Result (Count : Natural) is record
      Callback : Dialog_Callback;
      Files    : String_Array (1 .. Count);
   end record;

   package Result_Holders is new Ada.Containers.Indefinite_Holders
     (Dialog_Result);

   Pending_Result : Result_Holders.Holder;

   procedure Deliver_Dialog_Result is
      Result : constant Dialog_Result := Pending_Result.Element;
   begin
      Pending_Result.Clear;
      Free_Filters (Open_Filters);
      Dialog_Open := False;
      if Result.Callback /= null then
         Result.Callback (Result.Files);
      end if;
   end Deliver_Dialog_Result;

   procedure Post_Dialog_Result
     (Callback : Dialog_Callback;
      Files    : String_Array)
   is
   begin
      Pending_Result.Replace_Element
        (Dialog_Result'(Count    => Files'Length,
                        Callback => Callback,
                        Files    => Files));
      Adi.Dispatch.Post (Deliver_Dialog_Result'Access);
   end Post_Dialog_Result;

   function Claim_Dialog return Boolean is
   begin
      if Dialog_Open then
         Adi.Log.Error
           ("[Adi.OS] A file dialog is already open; not showing another");
         return False;
      end if;
      Dialog_Open := True;
      return True;
   end Claim_Dialog;

   function Read_Chars_Ptr (Addr : System.Address) return chars_ptr is
      type Chars_Ptr_Ptr is access all chars_ptr with Convention => C;
      function To_Ptr is new Ada.Unchecked_Conversion
        (System.Address, Chars_Ptr_Ptr);
   begin
      return To_Ptr (Addr).all;
   end Read_Chars_Ptr;

   use System.Storage_Elements;

   Ptr_Size : constant Storage_Offset :=
     System.Address'Size / System.Storage_Unit;

   function Count_File_List (Addr : System.Address) return Natural is
      use System;
      N    : Natural := 0;
      Cur  : System.Address := Addr;
   begin
      if Addr = System.Null_Address then
         return 0;
      end if;
      while Read_Chars_Ptr (Cur) /= Null_Ptr loop
         N   := N + 1;
         Cur := Cur + Ptr_Size;
      end loop;
      return N;
   end Count_File_List;

   procedure Dialog_Trampoline
     (Userdata : System.Address;
      Filelist : System.Address;
      Filter   : int)
   with Convention => C;

   procedure Log_Dialog_Error (Where : String; Err : String) is
   begin
      if Err'Length = 0 then
         return;
      end if;
      Adi.Log.Error
        (Where & Err &
         " (file dialog backend on Linux must be 'zenity' or 'portal')");
   end Log_Dialog_Error;

   procedure Dialog_Trampoline
     (Userdata : System.Address;
      Filelist : System.Address;
      Filter   : int)
   is
      pragma Unreferenced (Userdata, Filter);
      use Ada.Strings.Unbounded;

      N  : constant Natural := Count_File_List (Filelist);
      CB : constant Dialog_Callback := Stored_Callback;
   begin
      Adi.Log.Info ("[Adi.OS] Dialog_Trampoline called, N=" & Natural'Image (N));

      if N = 0 then
         declare
            Err : constant String := Value (Adi.SDL.SDL_GetError);
         begin
            if Err'Length = 0 then
               Adi.Log.Info ("[Adi.OS] Dialog cancelled (empty file list)");
            else
               Log_Dialog_Error ("[Adi.OS] Dialog failed: ", Err);
            end if;
         end;
         Post_Dialog_Result (CB, Empty_Strings);
         return;
      end if;

      declare
         Cur             : System.Address := Filelist;
         Non_Empty_Count : Natural := 0;
      begin
         --  Some backends may report N > 0 but include empty path entries.
         --  Treat those as cancellation/no selection.
         for I in 1 .. N loop
            declare
               Path : constant String := Value (Read_Chars_Ptr (Cur));
            begin
               if Path'Length > 0 then
                  Non_Empty_Count := Non_Empty_Count + 1;
               end if;
            end;
            Cur := Cur + Ptr_Size;
         end loop;

         if Non_Empty_Count = 0 then
            Adi.Log.Info ("[Adi.OS] Dialog returned only empty paths; treating as cancel");
            Post_Dialog_Result (CB, Empty_Strings);
            return;
         end if;

         Cur := Filelist;
         declare
            Files : String_Array (1 .. Non_Empty_Count);
            J     : Natural := 0;
         begin
            for I in 1 .. N loop
               declare
                  Path : constant String := Value (Read_Chars_Ptr (Cur));
               begin
                  if Path'Length > 0 then
                     J := J + 1;
                     Files (J) := To_Unbounded_String (Path);
                  end if;
               end;
               Cur := Cur + Ptr_Size;
            end loop;
            Post_Dialog_Result (CB, Files);
         end;
      end;
   end Dialog_Trampoline;

   function Get_Window_Ptr
     (Window : Adi.Window.Window_Handle)
      return Adi.SDL.Video.SDL_Window_Ptr
   is (Adi.Window.Get_SDL_Window (Window));

   ---------------------------------------------------------------------------
   --  Dialog API
   ---------------------------------------------------------------------------

   procedure Show_Open_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle :=
                            Adi.Window.Null_Window_Handle;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "";
      Allow_Many       : Boolean := False)
   is
      C_Filters : Filter_List := New_Filters (Filters);
      C_Loc     : chars_ptr := (if Default_Location = ""
                                 then Null_Ptr
                                 else New_String (Default_Location));
   begin
      Adi.Log.Info ("[Adi.OS] Show_Open_File_Dialog: N_filters=" &
                    Natural'Image (Filters'Length));
      if not Claim_Dialog then
         Free_Filters (C_Filters);
         Free (C_Loc);
         return;
      end if;
      Open_Filters    := C_Filters;
      Stored_Callback := Callback;
      declare
         Unused : constant Adi.SDL.C_bool := Adi.SDL.SDL_ClearError;
         pragma Unreferenced (Unused);
      begin
         null;
      end;

      Adi.SDL.Dialog.SDL_ShowOpenFileDialog
        (Callback         => Dialog_Trampoline'Access,
         Userdata         => System.Null_Address,
         Window           => Get_Window_Ptr (Window),
         Filters          => (if C_Filters = null then null
                              else C_Filters (0)'Access),
         Nfilters         => Filters'Length,
         Default_Location => C_Loc,
         Allow_Many       => Adi.SDL.C_bool (Allow_Many));

      Free (C_Loc);
   end Show_Open_File_Dialog;

   procedure Show_Save_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle :=
                            Adi.Window.Null_Window_Handle;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "")
   is
      C_Filters : Filter_List := New_Filters (Filters);
      C_Loc     : chars_ptr := (if Default_Location = ""
                                 then Null_Ptr
                                 else New_String (Default_Location));
   begin
      if not Claim_Dialog then
         Free_Filters (C_Filters);
         Free (C_Loc);
         return;
      end if;
      Open_Filters    := C_Filters;
      Stored_Callback := Callback;
      declare
         Unused : constant Adi.SDL.C_bool := Adi.SDL.SDL_ClearError;
         pragma Unreferenced (Unused);
      begin
         null;
      end;

      Adi.SDL.Dialog.SDL_ShowSaveFileDialog
        (Callback         => Dialog_Trampoline'Access,
         Userdata         => System.Null_Address,
         Window           => Get_Window_Ptr (Window),
         Filters          => (if C_Filters = null then null
                              else C_Filters (0)'Access),
         Nfilters         => Filters'Length,
         Default_Location => C_Loc);

      Free (C_Loc);
   end Show_Save_File_Dialog;

   procedure Show_Open_Folder_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle :=
                            Adi.Window.Null_Window_Handle;
      Default_Location : String := "";
      Allow_Many       : Boolean := False)
   is
      C_Loc : chars_ptr := (if Default_Location = ""
                             then Null_Ptr
                             else New_String (Default_Location));
   begin
      if not Claim_Dialog then
         Free (C_Loc);
         return;
      end if;
      Stored_Callback := Callback;
      declare
         Unused : constant Adi.SDL.C_bool := Adi.SDL.SDL_ClearError;
         pragma Unreferenced (Unused);
      begin
         null;
      end;

      Adi.SDL.Dialog.SDL_ShowOpenFolderDialog
        (Callback         => Dialog_Trampoline'Access,
         Userdata         => System.Null_Address,
         Window           => Get_Window_Ptr (Window),
         Default_Location => C_Loc,
         Allow_Many       => Adi.SDL.C_bool (Allow_Many));

      Free (C_Loc);
   end Show_Open_Folder_Dialog;

   ---------------------------------------------------------------------------
   --  Paths
   ---------------------------------------------------------------------------

   function Base_Path return String is
      C_Path : constant chars_ptr := Adi.SDL.Filesystem.SDL_GetBasePath;
   begin
      if C_Path = Null_Ptr then
         return "";
      end if;
      --  SDL_GetBasePath returns a static string — do NOT free.
      return Value (C_Path);
   end Base_Path;

   function Pref_Path (Org, App : String) return String is
      C_Org  : chars_ptr := New_String (Org);
      C_App  : chars_ptr := New_String (App);
      C_Path : constant chars_ptr :=
        Adi.SDL.Filesystem.SDL_GetPrefPath (C_Org, C_App);
      Result : constant String :=
        (if C_Path = Null_Ptr then "" else Value (C_Path));
   begin
      Free (C_Org);
      Free (C_App);
      if C_Path /= Null_Ptr then
         Adi.SDL.SDL_free (C_Path);
      end if;
      return Result;
   end Pref_Path;

   function To_SDL_Folder
     (Folder : User_Folder) return Adi.SDL.Filesystem.SDL_Folder
   is
      use Adi.SDL.Filesystem;
   begin
      return (case Folder is
                when Home         => SDL_FOLDER_HOME,
                when Desktop      => SDL_FOLDER_DESKTOP,
                when Documents    => SDL_FOLDER_DOCUMENTS,
                when Downloads    => SDL_FOLDER_DOWNLOADS,
                when Music        => SDL_FOLDER_MUSIC,
                when Pictures     => SDL_FOLDER_PICTURES,
                when Public_Share => SDL_FOLDER_PUBLICSHARE,
                when Saved_Games  => SDL_FOLDER_SAVEDGAMES,
                when Screenshots  => SDL_FOLDER_SCREENSHOTS,
                when Templates    => SDL_FOLDER_TEMPLATES,
                when Videos       => SDL_FOLDER_VIDEOS);
   end To_SDL_Folder;

   function Get_User_Folder (Folder : User_Folder) return String is
      C_Path : constant chars_ptr :=
        Adi.SDL.Filesystem.SDL_GetUserFolder (To_SDL_Folder (Folder));
   begin
      if C_Path = Null_Ptr then
         return "";
      end if;
      --  SDL_GetUserFolder returns a static string — do NOT free.
      return Value (C_Path);
   end Get_User_Folder;

   function Current_Directory return String is
      C_Path : constant chars_ptr :=
        Adi.SDL.Filesystem.SDL_GetCurrentDirectory;
      Result : constant String :=
        (if C_Path = Null_Ptr then "" else Value (C_Path));
   begin
      if C_Path /= Null_Ptr then
         Adi.SDL.SDL_free (C_Path);
      end if;
      return Result;
   end Current_Directory;

   function Temp_Directory return String is
      use Ada.Environment_Variables;

      --  A variable set to the empty string is no more usable than an
      --  unset one.
      function Named (Var : String) return String is
        (if Exists (Var) then Value (Var) else "");

      TMPDIR : constant String := Named ("TMPDIR");
      TEMP   : constant String := Named ("TEMP");
      TMP    : constant String := Named ("TMP");
   begin
      if TMPDIR /= "" then
         return Trim_Separator (TMPDIR);
      elsif TEMP /= "" then
         return Trim_Separator (TEMP);
      elsif TMP /= "" then
         return Trim_Separator (TMP);
      end if;

      case Adi.Build_Target.Platform is
         when Adi.Build_Target.Windows =>
            return "C:\Windows\Temp";
         when others =>
            return "/tmp";
      end case;
   end Temp_Directory;

   function Temp_Path (Name : String) return String is
      Dir : constant String := Temp_Directory;
   begin
      --  A root directory carries its own separator already.
      if Dir'Length > 0 and then Is_Separator (Dir (Dir'Last)) then
         return Dir & Name;
      end if;
      return Dir & Path_Separator & Name;
   end Temp_Path;

   ---------------------------------------------------------------------------
   --  Filesystem Operations
   ---------------------------------------------------------------------------

   function To_Path_Kind
     (K : Adi.SDL.Filesystem.SDL_PathType) return Path_Kind
   is
      use Adi.SDL.Filesystem;
   begin
      return (case K is
                when SDL_PATHTYPE_NONE      => None,
                when SDL_PATHTYPE_FILE      => File,
                when SDL_PATHTYPE_DIRECTORY => Directory,
                when SDL_PATHTYPE_OTHER     => Other);
   end To_Path_Kind;

   function Get_Path_Info (Path : String) return Path_Info is
      C_Path : chars_ptr := New_String (Path);
      Info   : aliased Adi.SDL.Filesystem.SDL_PathInfo;
      Ok     : Adi.SDL.C_bool;
   begin
      Ok := Adi.SDL.Filesystem.SDL_GetPathInfo (C_Path, Info'Access);
      Free (C_Path);
      if not Ok then
         return (Kind        => None,
                 Size        => 0,
                 Create_Time => 0,
                 Modify_Time => 0,
                 Access_Time => 0);
      end if;
      return (Kind        => To_Path_Kind (Info.Kind),
              Size        => Interfaces.Unsigned_64 (Info.Size),
              Create_Time => Long_Long_Integer (Info.Create_Time),
              Modify_Time => Long_Long_Integer (Info.Modify_Time),
              Access_Time => Long_Long_Integer (Info.Access_Time));
   end Get_Path_Info;

   function Create_Directory (Path : String) return Boolean is
      C_Path : chars_ptr := New_String (Path);
      Ok     : Adi.SDL.C_bool;
   begin
      Ok := Adi.SDL.Filesystem.SDL_CreateDirectory (C_Path);
      Free (C_Path);
      return Boolean (Ok);
   end Create_Directory;

   function Remove_Path (Path : String) return Boolean is
      C_Path : chars_ptr := New_String (Path);
      Ok     : Adi.SDL.C_bool;
   begin
      Ok := Adi.SDL.Filesystem.SDL_RemovePath (C_Path);
      Free (C_Path);
      return Boolean (Ok);
   end Remove_Path;

   function Rename_Path (Old_Path, New_Path : String) return Boolean is
      C_Old : chars_ptr := New_String (Old_Path);
      C_New : chars_ptr := New_String (New_Path);
      Ok    : Adi.SDL.C_bool;
   begin
      Ok := Adi.SDL.Filesystem.SDL_RenamePath (C_Old, C_New);
      Free (C_Old);
      Free (C_New);
      return Boolean (Ok);
   end Rename_Path;

   function Copy_File (Source, Destination : String) return Boolean is
      C_Src  : chars_ptr := New_String (Source);
      C_Dest : chars_ptr := New_String (Destination);
      Ok     : Adi.SDL.C_bool;
   begin
      Ok := Adi.SDL.Filesystem.SDL_CopyFile (C_Src, C_Dest);
      Free (C_Src);
      Free (C_Dest);
      return Boolean (Ok);
   end Copy_File;

   ---------------------------------------------------------------------------
   --  Misc
   ---------------------------------------------------------------------------

   function Open_URL (URL : String) return Boolean is
      C_URL : chars_ptr := New_String (URL);
      Ok    : Adi.SDL.C_bool;
   begin
      Ok := Adi.SDL.Misc.SDL_OpenURL (C_URL);
      Free (C_URL);
      return Boolean (Ok);
   end Open_URL;

   ---------------------------------------------------------------------------
   --  Clipboard
   ---------------------------------------------------------------------------

   function Get_Clipboard_Text return String is
      C_Text : constant chars_ptr := Adi.SDL.SDL_GetClipboardText;
      Result : constant String :=
        (if C_Text = Null_Ptr then "" else Value (C_Text));
   begin
      if C_Text /= Null_Ptr then
         Adi.SDL.SDL_free (C_Text);
      end if;
      return Result;
   end Get_Clipboard_Text;

   function Set_Clipboard_Text (Text : String) return Boolean is
      C_Text : chars_ptr := New_String (Text);
      Ok     : Adi.SDL.C_bool;
   begin
      Ok := Adi.SDL.SDL_SetClipboardText (C_Text);
      Free (C_Text);
      return Boolean (Ok);
   end Set_Clipboard_Text;

   function Has_Clipboard_Text return Boolean is
   begin
      return Boolean (Adi.SDL.SDL_HasClipboardText);
   end Has_Clipboard_Text;

end Adi.OS;
