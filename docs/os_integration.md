# OS Integration (`Adi.OS`)

`Adi.OS` provides high-level, Ada-friendly access to native OS features: file/folder dialogs, filesystem paths, file operations, URL launching, and clipboard. It wraps low-level SDL3 bindings in `Adi.SDL.Dialog`, `Adi.SDL.Filesystem`, and `Adi.SDL.Misc`.

## File Dialogs

SDL3 file dialogs are **asynchronous** — calling `Show_*` returns immediately. SDL3 internally dispatches the callback from within `SDL_PollEvent` when the platform dialog response arrives (e.g. via D-Bus on Linux). Since `Adi.App.Run` calls `SDL_PollEvent` every frame, the callback fires during normal event processing without any special handling.

### Types

```ada
type File_Filter is record
   Name    : Unbounded_String;  -- Display name, e.g. "Text files"
   Pattern : Unbounded_String;  -- Extension(s), e.g. "txt" or "png;jpg;gif"
end record;

type File_Filter_Array is array (Positive range <>) of File_Filter;
No_Filters : constant File_Filter_Array;  -- Empty, matches all files

type String_Array is array (Positive range <>) of Unbounded_String;
Empty_Strings : constant String_Array;  -- Length 0

type Dialog_Callback is access procedure (Files : String_Array);
-- Called with selected paths, or empty array if the user cancelled.
```

### Filter Pattern Syntax

Patterns use **bare extensions** — not globs. Only `[a-zA-Z0-9_.-]` characters are allowed, or a single `*` to match all files. Separate multiple extensions with `;`.

| Pattern | Matches |
|---------|---------|
| `txt` | `*.txt` files |
| `png;jpg;gif` | `*.png`, `*.jpg`, `*.gif` |
| `*` | All files |

### Show_Open_File_Dialog

Opens a native "Open File" dialog.

```ada
procedure Show_Open_File_Dialog
  (Callback         : Dialog_Callback;
   Window           : Adi.Window.Window_Handle :=
                         Adi.Window.Null_Window_Handle;
   Filters          : File_Filter_Array := No_Filters;
   Default_Location : String := "";
   Allow_Many       : Boolean := False);

procedure Show_Open_File_Dialog
  (Callback         : Dialog_Callback;
   Window           : Adi.Window.Window_Handle;
   Filters          : File_Filter_Array := No_Filters;
   Default_Location : String := "";
   Allow_Many       : Boolean := False);
```

- **Callback** — called with the selected file path(s), or an empty array on cancel.
- **Window** — parent window for modal positioning. Use access overload for legacy code or handle overload for handle-first code.
- **Filters** — file type filters shown in the dialog.
- **Default_Location** — initial directory path (optional).
- **Allow_Many** — if `True`, multiple files can be selected.

Callback normalization details:

- The dialog trampoline filters empty returned path entries.
- If SDL reports files but every entry is empty, `Adi.OS` treats it as cancel and calls `Callback (Empty_Strings)`.
- Callback code should treat `Files'Length = 0` as the canonical cancel check.

### Show_Save_File_Dialog

Opens a native "Save File" dialog.

```ada
procedure Show_Save_File_Dialog
  (Callback         : Dialog_Callback;
   Window           : Adi.Window.Window_Handle :=
                         Adi.Window.Null_Window_Handle;
   Filters          : File_Filter_Array := No_Filters;
   Default_Location : String := "");

procedure Show_Save_File_Dialog
  (Callback         : Dialog_Callback;
   Window           : Adi.Window.Window_Handle;
   Filters          : File_Filter_Array := No_Filters;
   Default_Location : String := "");
```

### Show_Open_Folder_Dialog

Opens a native "Choose Folder" dialog.

```ada
procedure Show_Open_Folder_Dialog
  (Callback         : Dialog_Callback;
   Window           : Adi.Window.Window_Handle :=
                         Adi.Window.Null_Window_Handle;
   Default_Location : String := "";
   Allow_Many       : Boolean := False);

procedure Show_Open_Folder_Dialog
  (Callback         : Dialog_Callback;
   Window           : Adi.Window.Window_Handle;
   Default_Location : String := "";
   Allow_Many       : Boolean := False);
```

### Example

```ada
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.OS;

procedure On_File_Selected (Files : Adi.OS.String_Array) is
begin
   if Files'Length = 0 then
      --  User cancelled
      return;
   end if;
   --  Files (Files'First) contains the selected path
end On_File_Selected;

procedure Open_Click is
   Filters : constant Adi.OS.File_Filter_Array :=
     [1 => (Name    => To_Unbounded_String ("Text files"),
            Pattern => To_Unbounded_String ("txt"))];
begin
   Adi.OS.Show_Open_File_Dialog
     (Callback => On_File_Selected'Unrestricted_Access,
      Window   => My_Window,
      Filters  => Filters);
end Open_Click;
```

## Paths

### Base_Path

Returns the directory where the application executable resides. Trailing separator included.

```ada
function Base_Path return String;
-- Returns "" on failure.
```

### Pref_Path

Returns a per-user, per-application writable directory for preferences and save data. The directory is created automatically if it does not exist.

```ada
function Pref_Path (Org, App : String) return String;
-- Returns "" on failure.
```

Example: `Pref_Path ("MyCompany", "MyApp")` might return `"/home/user/.local/share/MyCompany/MyApp/"`.

### Get_User_Folder

Returns the path to a well-known user folder.

```ada
type User_Folder is
  (Home, Desktop, Documents, Downloads, Music,
   Pictures, Public_Share, Saved_Games,
   Screenshots, Templates, Videos);

function Get_User_Folder (Folder : User_Folder) return String;
-- Returns "" if the folder is unavailable on this platform.
```

### Current_Directory

Returns the current working directory.

```ada
function Current_Directory return String;
```

### Temp_Directory and Temp_Path

`Temp_Directory` returns the directory the system hands out for scratch
files, without a trailing separator: `TMPDIR` if set, else `TEMP`, else
`TMP`, else `/tmp` (`C:\Windows\Temp` on Windows). `Temp_Path` places a
name inside it, joined with `Path_Separator`.

```ada
Path_Separator : constant Character;  --  '\' on Windows, '/' elsewhere

function Temp_Directory return String;
function Temp_Path (Name : String) return String;
```

`Temp_Path ("session.log")` gives `/tmp/session.log` on Linux and
`C:\Users\you\AppData\Local\Temp\session.log` on Windows. Neither
function creates anything; a subdirectory below `Temp_Directory` is yours
to create.

## Filesystem Operations

All functions return `True` on success, `False` on failure.

### Get_Path_Info

Query metadata about a filesystem path.

```ada
type Path_Kind is (None, File, Directory, Other);

type Path_Info is record
   Kind        : Path_Kind;
   Size        : Unsigned_64;       -- File size in bytes
   Create_Time : Long_Long_Integer; -- Nanoseconds since Unix epoch
   Modify_Time : Long_Long_Integer;
   Access_Time : Long_Long_Integer;
end record;

function Get_Path_Info (Path : String) return Path_Info;
-- Returns Kind => None if the path does not exist or on error.
```

### Create_Directory

```ada
function Create_Directory (Path : String) return Boolean;
```

### Remove_Path

Removes a file or empty directory.

```ada
function Remove_Path (Path : String) return Boolean;
```

### Rename_Path

```ada
function Rename_Path (Old_Path, New_Path : String) return Boolean;
```

### Copy_File

```ada
function Copy_File (Source, Destination : String) return Boolean;
```

## URL Launching

### Open_URL

Opens a URL in the user's default browser or application handler.

```ada
function Open_URL (URL : String) return Boolean;
-- Returns True on success.
```

Works with `http://`, `https://`, and platform-specific schemes (e.g. `file://`).

## Clipboard

### Get_Clipboard_Text

```ada
function Get_Clipboard_Text return String;
-- Returns "" if the clipboard is empty or does not contain text.
```

### Set_Clipboard_Text

```ada
function Set_Clipboard_Text (Text : String) return Boolean;
-- True when the text reached the clipboard. It does not on a platform
-- without one, nor before the video subsystem is up.
```

### Has_Clipboard_Text

```ada
function Has_Clipboard_Text return Boolean;
```

## Low-Level SDL Bindings

The high-level `Adi.OS` API is built on three hand-crafted SDL3 binding packages. These are available for advanced use but most applications should use `Adi.OS` instead.

| Package | File | Wraps |
|---------|------|-------|
| `Adi.SDL.Dialog` | `src/adi-sdl-dialog.ads` | `SDL_ShowOpenFileDialog`, `SDL_ShowSaveFileDialog`, `SDL_ShowOpenFolderDialog`, filter/callback types |
| `Adi.SDL.Filesystem` | `src/adi-sdl-filesystem.ads` | `SDL_GetBasePath`, `SDL_GetPrefPath`, `SDL_GetUserFolder`, `SDL_GetCurrentDirectory`, `SDL_CreateDirectory`, `SDL_RemovePath`, `SDL_RenamePath`, `SDL_CopyFile`, `SDL_GetPathInfo`, folder/path enums |
| `Adi.SDL.Misc` | `src/adi-sdl-misc.ads` | `SDL_OpenURL` |

## Platform Notes

- **Linux**: SDL file dialogs require a supported dialog driver (`portal` or `zenity`). If neither is available, SDL reports a driver error and no dialog is shown.
- **macOS/Windows**: Native system dialogs are used.
- Clipboard functions require SDL video subsystem to be initialized (handled by `Adi.App.Init`).
