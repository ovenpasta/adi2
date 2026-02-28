with System;
with System.Storage_Elements;
with Adi.Core;       use Adi.Core;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.SDL.TTF;    use Adi.SDL.TTF;

package Adi.Font is

   Default_Font_Size_Px : constant Float := Default_Font_Size.Amount;

   type Font_Attributes is record
      Family     : Font_Handle := Default_Font;
      Size       : Float := Default_Font_Size_Px;
      Weight     : Font_Weight_Value := Default_Font_Weight;
      Style      : Font_Style_Value := Default_Font_Style;
      Decoration : Text_Decoration_Value := Default_Text_Decoration;
   end record;

   function "=" (L, R : Font_Attributes) return Boolean;

   Default_Font_Attributes : constant Font_Attributes :=
     (Family     => Default_Font,
      Size       => Default_Font_Size_Px,
      Weight     => Default_Font_Weight,
      Style      => Default_Font_Style,
      Decoration => Default_Text_Decoration);

   function Quantize_Size (Size : Float) return Natural;

   function Make_Attributes (Family     : Font_Handle;
                             Size       : Float;
                             Weight     : Font_Weight_Value;
                             Style      : Font_Style_Value;
                             Decoration : Text_Decoration_Value)
      return Font_Attributes;

   ---------------------------------------------------------------------------
   --  Font loading — registers a font family file, returns a handle.
   --  Sized TTF_Font instances are created on demand and cached internally.
   --
   --  Load(Path) opens the font temporarily to auto-detect family name,
   --  weight, and style from TTF metadata.  If a font with the same family
   --  name was already loaded, the new file is registered as a variant of
   --  the existing handle (same handle is returned).
   --
   --  Load(Path, Name) uses the provided Name instead of the auto-detected
   --  family name for registry lookup/insertion.
   ---------------------------------------------------------------------------

   function Load (Path : String) return Font_Handle;
   function Load (Path : String; Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  Memory-based font loading — register a font from in-memory data.
   --
   --  Data must point to a static-lifetime buffer (e.g. a library-level
   --  Storage_Array constant) because TTF_OpenFontIO reads glyphs on demand.
   --  The buffer must outlive all sized font instances derived from this handle.
   --
   --  If Name is empty, the family name is auto-detected from TTF metadata.
   ---------------------------------------------------------------------------

   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count;
      Name   : String := "") return Font_Handle;
   procedure Register_Variant (Base   : Font_Handle;
                               Weight : Font_Weight_Value;
                               Style  : Font_Style_Value;
                               Path   : String);

   ---------------------------------------------------------------------------
   --  Name registry — register / look up fonts by family name.
   --
   --  Register_Name  — create a case-insensitive alias for an existing handle.
   --  Lookup         — return the handle for a registered name, or Null_Font.
   ---------------------------------------------------------------------------

   procedure Register_Name (Name : String; Handle : Font_Handle);
   function Lookup (Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  System font search.
   --
   --  Find searches system font directories recursively for a font whose TTF
   --  family name matches Name (case-insensitive).  If found, all weight/style
   --  variants are loaded and the family handle is returned.
   --
   --  Checks the name registry first; already-loaded fonts are returned
   --  immediately without scanning.  Names that were previously searched and
   --  not found are cached, so repeated misses are cheap.
   --
   --  System directories searched:
   --    Linux:   /usr/share/fonts, /usr/local/share/fonts,
   --             /usr/share/fonts/truetype
   --    Windows: C:\Windows\Fonts, C:\WINNT\Fonts
   ---------------------------------------------------------------------------

   function Find (Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  CSS font-family resolution mode.
   --
   --  By default, CSS font-family only resolves names registered via Load,
   --  Find, or Register_Name.  Calling Enable_System_Font_Search switches
   --  the resolver to use Find, so unregistered names trigger a system font
   --  search on first use.
   ---------------------------------------------------------------------------

   procedure Enable_System_Font_Search;

   ---------------------------------------------------------------------------
   --  Asset-relative loading — resolve via Adi.Assets then Load.
   ---------------------------------------------------------------------------

   function Load_Asset (Asset_Path : String) return Font_Handle;
   function Load_Asset (Asset_Path : String; Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  Default font — set the font used when a widget has no font-family.
   --  Overrides the automatic system font fallback (DejaVu Sans, etc.).
   ---------------------------------------------------------------------------

   procedure Set_Default_Font (Handle : Font_Handle);

   ---------------------------------------------------------------------------
   --  Font access — returns a TTF_Font opened at the given point size.
   --  Each (Handle, Size) pair is cached: first call opens the font,
   --  subsequent calls return the cached instance.
   --  When Handle is Null_Font, returns a fallback system font.
   ---------------------------------------------------------------------------

   function Get_TTF_Font (Handle : Font_Handle;
                          Size   : Float) return TTF_Font_Access;

   function Get_TTF_Font (Handle     : Font_Handle;
                          Size       : Float;
                          Weight     : Font_Weight_Value;
                          Style      : Font_Style_Value;
                          Decoration : Text_Decoration_Value)
      return TTF_Font_Access;

   function Get_TTF_Font (Attrs : Font_Attributes) return TTF_Font_Access;

   ---------------------------------------------------------------------------
   --  Text measurement
   ---------------------------------------------------------------------------

   function Measure_Text (Handle    : Font_Handle;
                          Content   : String;
                          Font_Size : Float) return Size_2D;

   function Measure_Text (Handle     : Font_Handle;
                          Content    : String;
                          Font_Size  : Float;
                          Weight     : Font_Weight_Value;
                          Style      : Font_Style_Value;
                          Decoration : Text_Decoration_Value) return Size_2D;

   function Measure_Text (Attrs   : Font_Attributes;
                          Content : String) return Size_2D;

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type) return Size_2D;

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type;
                                  Weight     : Font_Weight_Value;
                                  Style      : Font_Style_Value;
                                  Decoration : Text_Decoration_Value)
      return Size_2D;

   function Measure_Text_Wrapped (Attrs      : Font_Attributes;
                                  Content    : String;
                                  Wrap_Width : Pixel_Type) return Size_2D;

   --  Return the width of the longest word in Content.
   --  Words are separated by spaces, tabs, and newlines.
   --  This gives the minimum intrinsic width for wrappable text.
   function Measure_Min_Text_Width (Attrs   : Font_Attributes;
                                    Content : String) return Pixel_Type;

end Adi.Font;
