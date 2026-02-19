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
   ---------------------------------------------------------------------------

   function Load (Path : String) return Font_Handle;
   procedure Register_Variant (Base   : Font_Handle;
                               Weight : Font_Weight_Value;
                               Style  : Font_Style_Value;
                               Path   : String);

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
