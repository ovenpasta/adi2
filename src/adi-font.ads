with Adi.Core;       use Adi.Core;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.SDL.TTF;    use Adi.SDL.TTF;

package Adi.Font is

   ---------------------------------------------------------------------------
   --  Font loading — registers a font family file, returns a handle.
   --  Sized TTF_Font instances are created on demand and cached internally.
   ---------------------------------------------------------------------------

   function Load (Path : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  Font access — returns a TTF_Font opened at the given point size.
   --  Each (Handle, Size) pair is cached: first call opens the font,
   --  subsequent calls return the cached instance.
   --  When Handle is Null_Font, returns a fallback system font.
   ---------------------------------------------------------------------------

   function Get_TTF_Font (Handle : Font_Handle;
                          Size   : Float) return TTF_Font_Access;

   ---------------------------------------------------------------------------
   --  Text measurement
   ---------------------------------------------------------------------------

   function Measure_Text (Handle    : Font_Handle;
                          Content   : String;
                          Font_Size : Float) return Size_2D;

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type) return Size_2D;

end Adi.Font;
