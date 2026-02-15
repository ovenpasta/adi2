with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Adi.SVG.Parser;

package Adi.SVG.Ada_Cache is

   type Cache is private;
   type Cache_Access is access all Cache;
   pragma No_Strict_Aliasing (Cache_Access);

   function Create return Cache_Access;
   procedure Destroy (Obj : in out Cache_Access);

   function Find_Path_Contours
     (Obj      : in out Cache;
      Path_Pos : Natural;
      D        : String;
      M        : Adi.SVG.Parser.Matrix;
      Contours : out Adi.SVG.Parser.Contour_Vectors.Vector) return Boolean;

   procedure Store_Path_Contours
     (Obj      : in out Cache;
      Path_Pos : Natural;
      D        : String;
      M        : Adi.SVG.Parser.Matrix;
      Contours : Adi.SVG.Parser.Contour_Vectors.Vector);

   function Find_Render_Buffer
     (Obj      : in out Cache;
      Width    : Positive;
      Height   : Positive;
      AA_Scale : Positive;
      Pixels   : out Pixel_Buffer_Access) return Boolean;

   procedure Store_Render_Buffer
     (Obj      : in out Cache;
      Width    : Positive;
      Height   : Positive;
      AA_Scale : Positive;
      Pixels   : Pixel_Buffer_Access);

private

   package US renames Ada.Strings.Unbounded;

   type Matrix_Key is record
      A, B, C, D, E, F : Integer := 0;
   end record;

   type Path_Variant is record
      Key      : Matrix_Key;
      Contours : Adi.SVG.Parser.Contour_Vectors.Vector;
   end record;

   package Variant_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Path_Variant);

   type Path_Entry is record
      Pos      : Natural := 0;
      D_Text   : US.Unbounded_String := US.Null_Unbounded_String;
      Variants : Variant_Vectors.Vector;
   end record;

   package Path_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Path_Entry);

   type Render_Entry is record
      Width    : Positive := 1;
      Height   : Positive := 1;
      AA_Scale : Positive := 1;
      Pixels   : Pixel_Buffer_Access := null;
   end record;

   package Render_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Render_Entry);

   type Cache is record
      Paths : Path_Vectors.Vector;
      --  Cache of fully rendered frames by output size/AA scale.
      --  Stored buffers are owned by the cache.
      Renders : Render_Vectors.Vector;
   end record;

end Adi.SVG.Ada_Cache;
