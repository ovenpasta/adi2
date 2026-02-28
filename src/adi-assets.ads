pragma Ada_2022;

with System;
with System.Storage_Elements;
with Adi.Image;          use Adi.Image;
with Adi.Animated_Image; use Adi.Animated_Image;

package Adi.Assets is

   ---------------------------------------------------------------------------
   --  Asset Resolution Mode
   ---------------------------------------------------------------------------

   type Asset_Mode is (File_Mode, Bundle_Mode);

   procedure Set_Mode (Mode : Asset_Mode);
   --  Set the asset resolution mode.  Must be called before any asset is
   --  loaded (Get_Image, Get_String, Get_Animated_Image, or Font.Load_Asset).
   --  Raises Program_Error if called after any asset has been loaded.
   --  Default is File_Mode.

   function Get_Mode return Asset_Mode;

   ---------------------------------------------------------------------------
   --  Bundle Registration (for Bundle_Mode)
   ---------------------------------------------------------------------------

   type Asset_Data is record
      Addr   : System.Address                       := System.Null_Address;
      Length : System.Storage_Elements.Storage_Count := 0;
   end record;

   Null_Asset : constant Asset_Data :=
     (Addr => System.Null_Address, Length => 0);

   procedure Register
     (Path   : String;
      Addr   : System.Address;
      Length : System.Storage_Elements.Storage_Count);
   --  Register an embedded asset for Bundle_Mode.  The Address must point to
   --  static-lifetime data (e.g. a library-level Storage_Array constant).
   --  Data is NOT copied.  Keys may be plain relative paths ("icons.svg")
   --  or scheme URIs ("app://icons.svg").  The key is stored exactly as given.

   function Bundle_Lookup (Path : String) return Asset_Data;
   --  Look up a registered bundle entry.  Returns Null_Asset if not found.

   ---------------------------------------------------------------------------
   --  Search Path Management
   ---------------------------------------------------------------------------

   procedure Add_Path
     (Path    : String;
      Scheme  : String  := "";
      Flatten : Boolean := False);
   --  Append a search directory.  If Scheme is non-empty (e.g. "app"),
   --  this directory is only searched for URIs matching "scheme://path".
   --  Directories with empty Scheme are searched for plain relative paths.
   --
   --  When Flatten is True, the asset is looked up by basename only
   --  (directory components in the requested path are ignored).  The root
   --  of Path is tried first; if not found, subdirectories are walked
   --  depth-first and the first file whose Simple_Name matches is returned.
   --  Note: traversal order is filesystem-dependent, so duplicate basenames
   --  across subdirectories may resolve differently on different platforms.

   procedure Remove_Path
     (Path    : String;
      Scheme  : String  := "";
      Flatten : Boolean := False);
   --  Remove the first matching search entry (directory + scheme + flatten).
   --  A flattened entry requires Flatten => True to match; the default
   --  False will not match a flattened entry.

   procedure Clear_Paths;
   --  Remove all search directories.

   ---------------------------------------------------------------------------
   --  Path Resolution
   ---------------------------------------------------------------------------

   function Resolve_Path (Path : String) return String;
   --  Resolve Path (plain or scheme URI) through the registered search
   --  directories and return the full filesystem path.
   --  Returns "" if the file is not found.

   ---------------------------------------------------------------------------
   --  Asset Loading (cached)
   ---------------------------------------------------------------------------

   function Get_String (Path : String) return String;
   --  Resolve Path (plain or scheme URI) and return the file contents.
   --  Caches by Path; subsequent calls return the cached string.
   --  Returns "" and logs a warning if the file is not found.

   function Get_Image (Path : String) return Image_Access;
   --  Resolve Path (plain or scheme URI) and load the image.
   --  Caches by Path; subsequent calls return the same Image_Access.
   --  Returns null and logs a warning if the file is not found.
   --
   --  Sprite syntax via query parameters:
   --    "icons.svg?id=home"            — SVG sprite: extract <symbol id>
   --                                     from a cached sprite sheet.
   --                                     Result is tintable by default.
   --    "sheet.png?x=0&y=32&w=16&h=16" — Raster crop: extract pixel region
   --                                     from the source image.
   --    "tile.png?render=pixelated"    — Set texture scale mode.
   --                                     Values: pixelated, nearest, linear.
   --                                     Combinable with sprite/crop params.
   --  Parameters may be separated by '&' or ';'.  Use ';' in XML attributes
   --  to avoid &amp; escaping (e.g. "sheet.png?x=0;y=32;w=16;h=16").
   --  Query values must be plain identifiers/integers (no URL-encoding).
   --  Crop coordinates are clamped to source image bounds.

   function Get_Animated_Image (Path : String) return Animated_Image_Access;
   --  Resolve Path and load via Adi.Animated_Image.Load_From_File.
   --  Caches by Path; subsequent calls return the same access value.
   --  Returns null and logs a warning if the file is not found.

   ---------------------------------------------------------------------------
   --  Cache Management
   ---------------------------------------------------------------------------

   procedure Mark_Asset_Loaded;
   --  Signal that an asset has been loaded.  After this call, Set_Mode
   --  will raise Program_Error.  Called internally by Get_Image, Get_String,
   --  Get_Animated_Image, and Font.Load_Asset.

   procedure Clear_Cache;
   --  Drop all cached strings, images, and animated images.
   --  Frees resources and deallocates objects.  Previously returned
   --  access values become invalid — callers must reacquire.

   procedure Clear_String_Cache;
   --  Drop cached strings only.

   procedure Clear_Image_Cache;
   --  Drop cached images only.
   --  Frees image resources and deallocates Image objects.  Previously
   --  returned Image_Access values become invalid — callers must reacquire
   --  via Get_Image.

   procedure Clear_Animated_Image_Cache;
   --  Drop cached animated images only.
   --  Callers holding previous Animated_Image_Access values must reacquire.

   procedure Invalidate (Path : String);
   --  Remove one entry (matching Path key) from all caches.
   --  Frees resources and deallocates objects if present.
   --  Previously returned access values for this path become invalid.

end Adi.Assets;
