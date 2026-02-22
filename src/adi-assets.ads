pragma Ada_2022;

with Adi.Image;          use Adi.Image;
with Adi.Animated_Image; use Adi.Animated_Image;

package Adi.Assets is

   ---------------------------------------------------------------------------
   --  Search Path Management
   ---------------------------------------------------------------------------

   procedure Add_Path (Path : String; Scheme : String := "");
   --  Append a search directory.  If Scheme is non-empty (e.g. "app"),
   --  this directory is only searched for URIs matching "scheme://path".
   --  Directories with empty Scheme are searched for plain relative paths.

   procedure Remove_Path (Path : String; Scheme : String := "");
   --  Remove the first matching search entry (directory + scheme).

   procedure Clear_Paths;
   --  Remove all search directories.

   ---------------------------------------------------------------------------
   --  Asset Loading (cached)
   ---------------------------------------------------------------------------

   function Get_String (Path : String) return String;
   --  Resolve Path (plain or scheme URI) and return the file contents.
   --  Caches by Path; subsequent calls return the cached string.
   --  Returns "" and logs a warning if the file is not found.

   function Get_Image (Path : String) return Image_Access;
   --  Resolve Path (plain or scheme URI) and load the image via
   --  Adi.Image.Load_From_File.  Caches by Path; subsequent calls
   --  return the same Image_Access.  Returns null and logs a warning
   --  if the file is not found.

   function Get_Animated_Image (Path : String) return Animated_Image_Access;
   --  Resolve Path and load via Adi.Animated_Image.Load_From_File.
   --  Caches by Path; subsequent calls return the same access value.
   --  Returns null and logs a warning if the file is not found.

   ---------------------------------------------------------------------------
   --  Cache Management
   ---------------------------------------------------------------------------

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
