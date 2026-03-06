pragma Ada_2022;
with Ada.Unchecked_Conversion;
with Interfaces.C;         use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;
with System;
with System.Storage_Elements;
with Adi.Log;
with Adi.SDL;
with Adi.SDL.Dialog;
with Adi.SDL.Filesystem;
with Adi.SDL.Misc;
with Adi.SDL.Video;

package body Adi.OS is

   use Adi.Window;

   ---------------------------------------------------------------------------
   --  Dialog Callback Trampoline
   ---------------------------------------------------------------------------
   --  SDL3 dialog functions are asynchronous — they invoke a C callback with
   --  results.  We store the user's Ada callback in a package-level variable,
   --  provide a C-convention trampoline that converts the C strings into Ada
   --  String_Array, then invokes the stored callback.
   ---------------------------------------------------------------------------

   Stored_Callback : Dialog_Callback := null;

   --  Read a chars_ptr from a pointer-sized slot at the given address.
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

   --  Helper: count null-terminated array of chars_ptr at given address.
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
      Stored_Callback := null;

      if CB = null then
         Adi.Log.Warning ("[Adi.OS] Dialog_Trampoline: no stored callback");
         return;
      end if;

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
         CB (Empty_Strings);
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
            CB (Empty_Strings);
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
            CB (Files);
         end;
      end;
   end Dialog_Trampoline;

   ---------------------------------------------------------------------------
   --  Dialog Helpers
   ---------------------------------------------------------------------------

   procedure Prepare_Filters
     (Filters     : File_Filter_Array;
      C_Filters   : out Adi.SDL.Dialog.SDL_DialogFileFilter_Array;
      C_Names     : out Interfaces.C.Strings.chars_ptr_array;
      C_Patterns  : out Interfaces.C.Strings.chars_ptr_array)
   is
      use Ada.Strings.Unbounded;
   begin
      for I in Filters'Range loop
         C_Names (size_t (I - Filters'First))   :=
           New_String (To_String (Filters (I).Name));
         C_Patterns (size_t (I - Filters'First)) :=
           New_String (To_String (Filters (I).Pattern));
         C_Filters (int (I - Filters'First)) :=
           (Name    => C_Names (size_t (I - Filters'First)),
            Pattern => C_Patterns (size_t (I - Filters'First)));
      end loop;
   end Prepare_Filters;

   procedure Free_Filter_Strings
     (C_Names    : in out Interfaces.C.Strings.chars_ptr_array;
      C_Patterns : in out Interfaces.C.Strings.chars_ptr_array;
      Count      : Natural)
   is
   begin
      for I in 0 .. size_t (Count) - 1 loop
         Free (C_Names (I));
         Free (C_Patterns (I));
      end loop;
   end Free_Filter_Strings;

   function Get_Window_Ptr
     (Window : Adi.Window.Window_Access)
      return Adi.SDL.Video.SDL_Window_Ptr
   is
   begin
      if Window = null then
         return null;
      end if;
      return Adi.Window.Get_SDL_Window (Window.all);
   end Get_Window_Ptr;

   ---------------------------------------------------------------------------
   --  Dialog API
   ---------------------------------------------------------------------------

   procedure Show_Open_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Access := null;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "";
      Allow_Many       : Boolean := False)
   is
      C_Loc : chars_ptr := (if Default_Location = ""
                             then Null_Ptr
                             else New_String (Default_Location));
      N     : constant int := Filters'Length;
   begin
      Adi.Log.Info ("[Adi.OS] Show_Open_File_Dialog: N_filters=" &
                    int'Image (N));
      Stored_Callback := Callback;
      declare
         Unused : constant Adi.SDL.C_bool := Adi.SDL.SDL_ClearError;
         pragma Unreferenced (Unused);
      begin
         null;
      end;

      if N = 0 then
         Adi.SDL.Dialog.SDL_ShowOpenFileDialog
           (Callback         => Dialog_Trampoline'Access,
            Userdata         => System.Null_Address,
            Window           => Get_Window_Ptr (Window),
            Filters          => null,
            Nfilters         => 0,
            Default_Location => C_Loc,
            Allow_Many       => Adi.SDL.C_bool (Allow_Many));
      else
         declare
            C_Filters  : Adi.SDL.Dialog.SDL_DialogFileFilter_Array (0 .. N - 1);
            C_Names    : chars_ptr_array (0 .. size_t (N) - 1);
            C_Patterns : chars_ptr_array (0 .. size_t (N) - 1);
         begin
            Prepare_Filters (Filters, C_Filters, C_Names, C_Patterns);
            Adi.SDL.Dialog.SDL_ShowOpenFileDialog
              (Callback         => Dialog_Trampoline'Access,
               Userdata         => System.Null_Address,
               Window           => Get_Window_Ptr (Window),
               Filters          => C_Filters (C_Filters'First)'Access,
               Nfilters         => N,
               Default_Location => C_Loc,
               Allow_Many       => Adi.SDL.C_bool (Allow_Many));
            Free_Filter_Strings (C_Names, C_Patterns, Natural (N));
         end;
      end if;

      declare
         Err : constant String := Value (Adi.SDL.SDL_GetError);
      begin
         --  When callback fired synchronously, Dialog_Trampoline already
         --  logged cancellation/error; avoid duplicate error lines here.
         if Stored_Callback /= null and then Err'Length > 0 then
            Log_Dialog_Error
              ("[Adi.OS] SDL error after ShowOpenFileDialog: ", Err);
         end if;
      end;

      if C_Loc /= Null_Ptr then
         Free (C_Loc);
      end if;
   end Show_Open_File_Dialog;

   procedure Show_Open_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "";
      Allow_Many       : Boolean := False)
   is
   begin
      Show_Open_File_Dialog
        (Callback         => Callback,
         Window           => Adi.Window.Resolve_Window_Handle (Window),
         Filters          => Filters,
         Default_Location => Default_Location,
         Allow_Many       => Allow_Many);
   end Show_Open_File_Dialog;

   procedure Show_Save_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Access := null;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "")
   is
      C_Loc : chars_ptr := (if Default_Location = ""
                             then Null_Ptr
                             else New_String (Default_Location));
      N     : constant int := Filters'Length;
   begin
      Stored_Callback := Callback;
      declare
         Unused : constant Adi.SDL.C_bool := Adi.SDL.SDL_ClearError;
         pragma Unreferenced (Unused);
      begin
         null;
      end;

      if N = 0 then
         Adi.SDL.Dialog.SDL_ShowSaveFileDialog
           (Callback         => Dialog_Trampoline'Access,
            Userdata         => System.Null_Address,
            Window           => Get_Window_Ptr (Window),
            Filters          => null,
            Nfilters         => 0,
            Default_Location => C_Loc);
      else
         declare
            C_Filters  : Adi.SDL.Dialog.SDL_DialogFileFilter_Array (0 .. N - 1);
            C_Names    : chars_ptr_array (0 .. size_t (N) - 1);
            C_Patterns : chars_ptr_array (0 .. size_t (N) - 1);
         begin
            Prepare_Filters (Filters, C_Filters, C_Names, C_Patterns);
            Adi.SDL.Dialog.SDL_ShowSaveFileDialog
              (Callback         => Dialog_Trampoline'Access,
               Userdata         => System.Null_Address,
               Window           => Get_Window_Ptr (Window),
               Filters          => C_Filters (C_Filters'First)'Access,
               Nfilters         => N,
               Default_Location => C_Loc);
            Free_Filter_Strings (C_Names, C_Patterns, Natural (N));
         end;
      end if;

      if C_Loc /= Null_Ptr then
         Free (C_Loc);
      end if;
   end Show_Save_File_Dialog;

   procedure Show_Save_File_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle;
      Filters          : File_Filter_Array := No_Filters;
      Default_Location : String := "")
   is
   begin
      Show_Save_File_Dialog
        (Callback         => Callback,
         Window           => Adi.Window.Resolve_Window_Handle (Window),
         Filters          => Filters,
         Default_Location => Default_Location);
   end Show_Save_File_Dialog;

   procedure Show_Open_Folder_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Access := null;
      Default_Location : String := "";
      Allow_Many       : Boolean := False)
   is
      C_Loc : chars_ptr := (if Default_Location = ""
                             then Null_Ptr
                             else New_String (Default_Location));
   begin
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

      if C_Loc /= Null_Ptr then
         Free (C_Loc);
      end if;
   end Show_Open_Folder_Dialog;

   procedure Show_Open_Folder_Dialog
     (Callback         : Dialog_Callback;
      Window           : Adi.Window.Window_Handle;
      Default_Location : String := "";
      Allow_Many       : Boolean := False)
   is
   begin
      Show_Open_Folder_Dialog
        (Callback         => Callback,
         Window           => Adi.Window.Resolve_Window_Handle (Window),
         Default_Location => Default_Location,
         Allow_Many       => Allow_Many);
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

   procedure Set_Clipboard_Text (Text : String) is
      C_Text  : chars_ptr := New_String (Text);
      Ignore  : Adi.SDL.C_bool;
   begin
      Ignore := Adi.SDL.SDL_SetClipboardText (C_Text);
      Free (C_Text);
   end Set_Clipboard_Text;

   function Has_Clipboard_Text return Boolean is
   begin
      return Boolean (Adi.SDL.SDL_HasClipboardText);
   end Has_Clipboard_Text;

end Adi.OS;
