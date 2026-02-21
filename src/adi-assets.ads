pragma Ada_2022;

with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
with Adi.Image;                 use Adi.Image;
with Adi.Window;

package Adi.Assets is

   type Asset_Store is tagged private;

   function Create
     (Win : not null access Adi.Window.Window) return Asset_Store;
   --  Create an empty asset store.  Call Add_Path to register one or
   --  more search directories before loading assets.

   procedure Add_Path
     (Store  : in out Asset_Store;
      Path   : String;
      Scheme : String := "");
   --  Append a search directory.  If Scheme is non-empty (e.g. "app"),
   --  this directory is only searched for URIs matching "scheme://path".
   --  Directories with empty Scheme are searched for plain relative paths.

   function Get_String
     (Store : in out Asset_Store;
      Path  : String) return String;
   --  Resolve Path (plain or scheme URI) and return the file contents.
   --  Caches by Path; subsequent calls return the cached string.
   --  Returns "" and logs a warning if the file is not found.

   function Get_Image
     (Store : in out Asset_Store;
      Path  : String) return Image_Access;
   --  Resolve Path (plain or scheme URI) and load the image via
   --  Adi.Image.Load_From_File.  Caches by Path; subsequent calls
   --  return the same Image_Access.  Returns null and logs a warning
   --  if the file is not found.

private

   type Search_Entry is record
      Dir    : Unbounded_String;
      Scheme : Unbounded_String;  --  "" = default (plain paths)
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Search_Entry);

   package String_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Unbounded_String);

   package Image_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Image_Access);

   type Asset_Store is tagged record
      Win     : access Adi.Window.Window;
      Entries : Entry_Vectors.Vector;
      Strings : String_Maps.Map;
      Images  : Image_Maps.Map;
   end record;

end Adi.Assets;
