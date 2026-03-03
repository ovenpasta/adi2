with Interfaces.C.Strings;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
with Adi.SDL.IO;              use Adi.SDL.IO;
with Adi.SDL.Surface;         use Adi.SDL.Surface;
with Adi.SDL.Render;          use Adi.SDL.Render;

package Adi.SDL.TTF is

   -- Version constants
   SDL_TTF_MAJOR_VERSION : constant := 3;
   SDL_TTF_MINOR_VERSION : constant := 2;
   SDL_TTF_MICRO_VERSION : constant := 2;

   ----------------------------------------------------------------------------
   -- Opaque Types
   ----------------------------------------------------------------------------

   type TTF_Font is limited null record;
   type TTF_Font_Access is access all TTF_Font;

   ----------------------------------------------------------------------------
   -- Font Style Flags
   ----------------------------------------------------------------------------

   subtype TTF_FontStyleFlags is Uint32;

   TTF_STYLE_NORMAL        : constant TTF_FontStyleFlags := 16#00#;
   TTF_STYLE_BOLD          : constant TTF_FontStyleFlags := 16#01#;
   TTF_STYLE_ITALIC        : constant TTF_FontStyleFlags := 16#02#;
   TTF_STYLE_UNDERLINE     : constant TTF_FontStyleFlags := 16#04#;
   TTF_STYLE_STRIKETHROUGH : constant TTF_FontStyleFlags := 16#08#;

   ----------------------------------------------------------------------------
   -- Font Weight
   ----------------------------------------------------------------------------

   TTF_FONT_WEIGHT_THIN         : constant := 100;
   TTF_FONT_WEIGHT_EXTRA_LIGHT  : constant := 200;
   TTF_FONT_WEIGHT_LIGHT        : constant := 300;
   TTF_FONT_WEIGHT_NORMAL       : constant := 400;
   TTF_FONT_WEIGHT_MEDIUM       : constant := 500;
   TTF_FONT_WEIGHT_SEMI_BOLD    : constant := 600;
   TTF_FONT_WEIGHT_BOLD         : constant := 700;
   TTF_FONT_WEIGHT_EXTRA_BOLD   : constant := 800;
   TTF_FONT_WEIGHT_BLACK        : constant := 900;
   TTF_FONT_WEIGHT_EXTRA_BLACK  : constant := 950;

   ----------------------------------------------------------------------------
   -- Hinting Flags
   ----------------------------------------------------------------------------

   type TTF_HintingFlags is (
      TTF_HINTING_INVALID,
      TTF_HINTING_NORMAL,
      TTF_HINTING_LIGHT,
      TTF_HINTING_MONO,
      TTF_HINTING_NONE,
      TTF_HINTING_LIGHT_SUBPIXEL
   ) with Convention => C;
   for TTF_HintingFlags use (
      TTF_HINTING_INVALID        => -1,
      TTF_HINTING_NORMAL         => 0,
      TTF_HINTING_LIGHT          => 1,
      TTF_HINTING_MONO           => 2,
      TTF_HINTING_NONE           => 3,
      TTF_HINTING_LIGHT_SUBPIXEL => 4
   );

   ----------------------------------------------------------------------------
   -- Horizontal Alignment
   ----------------------------------------------------------------------------

   type TTF_HorizontalAlignment is (
      TTF_HORIZONTAL_ALIGN_INVALID,
      TTF_HORIZONTAL_ALIGN_LEFT,
      TTF_HORIZONTAL_ALIGN_CENTER,
      TTF_HORIZONTAL_ALIGN_RIGHT
   ) with Convention => C;
   for TTF_HorizontalAlignment use (
      TTF_HORIZONTAL_ALIGN_INVALID => -1,
      TTF_HORIZONTAL_ALIGN_LEFT    => 0,
      TTF_HORIZONTAL_ALIGN_CENTER  => 1,
      TTF_HORIZONTAL_ALIGN_RIGHT   => 2
   );

   ----------------------------------------------------------------------------
   -- Text Direction
   ----------------------------------------------------------------------------

   type TTF_Direction is (
      TTF_DIRECTION_INVALID,
      TTF_DIRECTION_LTR,
      TTF_DIRECTION_RTL,
      TTF_DIRECTION_TTB,
      TTF_DIRECTION_BTT
   ) with Convention => C;
   for TTF_Direction use (
      TTF_DIRECTION_INVALID => 0,
      TTF_DIRECTION_LTR     => 4,
      TTF_DIRECTION_RTL     => 5,
      TTF_DIRECTION_TTB     => 6,
      TTF_DIRECTION_BTT     => 7
   );

   ----------------------------------------------------------------------------
   -- Image Type (for glyph rendering)
   ----------------------------------------------------------------------------

   type TTF_ImageType is (
      TTF_IMAGE_INVALID,
      TTF_IMAGE_ALPHA,
      TTF_IMAGE_COLOR,
      TTF_IMAGE_SDF
   ) with Convention => C;

   ----------------------------------------------------------------------------
   -- Color Type (matching SDL_Color)
   ----------------------------------------------------------------------------

   type TTF_Color is record
      R : Uint8;
      G : Uint8;
      B : Uint8;
      A : Uint8;
   end record with Convention => C_Pass_By_Copy;

   ----------------------------------------------------------------------------
   -- Initialization and Cleanup
   ----------------------------------------------------------------------------

   function TTF_Init return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_Init";

   procedure TTF_Quit
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_Quit";

   function TTF_WasInit return int
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_WasInit";

   ----------------------------------------------------------------------------
   -- Font Loading and Management
   ----------------------------------------------------------------------------

   function TTF_OpenFont
      (File   : Interfaces.C.Strings.chars_ptr;
       Ptsize : Float) return TTF_Font_Access
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_OpenFont";

   function TTF_OpenFontIO
      (Src     : SDL_IOStream_Ptr;
       Closeio : C_bool;
       Ptsize  : Float) return TTF_Font_Access
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_OpenFontIO";

   procedure TTF_CloseFont (Font : TTF_Font_Access)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_CloseFont";

   ----------------------------------------------------------------------------
   -- Font Properties
   ----------------------------------------------------------------------------

   function TTF_SetFontSize
      (Font   : TTF_Font_Access;
       Ptsize : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontSize";

   function TTF_GetFontSize (Font : TTF_Font_Access) return Float
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontSize";

   procedure TTF_SetFontStyle
      (Font  : TTF_Font_Access;
       Style : TTF_FontStyleFlags)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontStyle";

   function TTF_GetFontStyle
      (Font : access constant TTF_Font) return TTF_FontStyleFlags
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontStyle";

   function TTF_SetFontOutline
      (Font    : TTF_Font_Access;
       Outline : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontOutline";

   function TTF_GetFontOutline
      (Font : access constant TTF_Font) return int
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontOutline";

   procedure TTF_SetFontHinting
      (Font    : TTF_Font_Access;
       Hinting : TTF_HintingFlags)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontHinting";

   function TTF_GetFontHinting
      (Font : access constant TTF_Font) return TTF_HintingFlags
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontHinting";

   procedure TTF_SetFontWrapAlignment
      (Font  : TTF_Font_Access;
       Align : TTF_HorizontalAlignment)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontWrapAlignment";

   function TTF_GetFontWrapAlignment
      (Font : access constant TTF_Font) return TTF_HorizontalAlignment
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontWrapAlignment";

   ----------------------------------------------------------------------------
   -- Font Metrics
   ----------------------------------------------------------------------------

   function TTF_GetFontHeight
      (Font : access constant TTF_Font) return int
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontHeight";

   function TTF_GetFontAscent
      (Font : access constant TTF_Font) return int
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontAscent";

   function TTF_GetFontDescent
      (Font : access constant TTF_Font) return int
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontDescent";

   procedure TTF_SetFontLineSkip
      (Font     : TTF_Font_Access;
       Lineskip : int)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontLineSkip";

   function TTF_GetFontLineSkip
      (Font : access constant TTF_Font) return int
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontLineSkip";

   procedure TTF_SetFontKerning
      (Font    : TTF_Font_Access;
       Enabled : C_bool)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontKerning";

   function TTF_GetFontKerning
      (Font : access constant TTF_Font) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontKerning";

   ----------------------------------------------------------------------------
   -- Font Information
   ----------------------------------------------------------------------------

   function TTF_FontIsFixedWidth
      (Font : access constant TTF_Font) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_FontIsFixedWidth";

   function TTF_FontIsScalable
      (Font : access constant TTF_Font) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_FontIsScalable";

   function TTF_GetFontFamilyName
      (Font : access constant TTF_Font) return Interfaces.C.Strings.chars_ptr
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontFamilyName";

   function TTF_GetFontStyleName
      (Font : access constant TTF_Font) return Interfaces.C.Strings.chars_ptr
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontStyleName";

   function TTF_GetFontWeight
      (Font : access constant TTF_Font) return int
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetFontWeight";

   ----------------------------------------------------------------------------
   -- Text Size Calculation
   ----------------------------------------------------------------------------

   function TTF_GetStringSize
      (Font   : TTF_Font_Access;
       Text   : Interfaces.C.Strings.chars_ptr;
       Length : Interfaces.C.size_t;
       W      : access int;
       H      : access int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetStringSize";

   function TTF_GetStringSizeWrapped
      (Font      : TTF_Font_Access;
       Text      : Interfaces.C.Strings.chars_ptr;
       Length    : Interfaces.C.size_t;
       Wrap_Width : int;
       W         : access int;
       H         : access int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetStringSizeWrapped";

   function TTF_MeasureString
      (Font            : TTF_Font_Access;
       Text            : Interfaces.C.Strings.chars_ptr;
       Length          : Interfaces.C.size_t;
       Max_Width       : int;
       Measured_Width  : access int;
       Measured_Length : access Interfaces.C.size_t) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_MeasureString";

   ----------------------------------------------------------------------------
   -- Text Rendering (Solid - Quick and Dirty)
   ----------------------------------------------------------------------------

   function TTF_RenderText_Solid
      (Font   : TTF_Font_Access;
       Text   : Interfaces.C.Strings.chars_ptr;
       Length : Interfaces.C.size_t;
       FG     : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_Solid";

   function TTF_RenderText_Solid_Wrapped
      (Font       : TTF_Font_Access;
       Text       : Interfaces.C.Strings.chars_ptr;
       Length     : Interfaces.C.size_t;
       FG         : TTF_Color;
       Wrap_Length : int) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_Solid_Wrapped";

   function TTF_RenderGlyph_Solid
      (Font : TTF_Font_Access;
       Ch   : Uint32;
       FG   : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderGlyph_Solid";

   ----------------------------------------------------------------------------
   -- Text Rendering (Shaded - Slow and Nice, with Background)
   ----------------------------------------------------------------------------

   function TTF_RenderText_Shaded
      (Font   : TTF_Font_Access;
       Text   : Interfaces.C.Strings.chars_ptr;
       Length : Interfaces.C.size_t;
       FG     : TTF_Color;
       BG     : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_Shaded";

   function TTF_RenderText_Shaded_Wrapped
      (Font       : TTF_Font_Access;
       Text       : Interfaces.C.Strings.chars_ptr;
       Length     : Interfaces.C.size_t;
       FG         : TTF_Color;
       BG         : TTF_Color;
       Wrap_Width : int) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_Shaded_Wrapped";

   function TTF_RenderGlyph_Shaded
      (Font : TTF_Font_Access;
       Ch   : Uint32;
       FG   : TTF_Color;
       BG   : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderGlyph_Shaded";

   ----------------------------------------------------------------------------
   -- Text Rendering (Blended - Slow but Beautiful, Anti-aliased)
   ----------------------------------------------------------------------------

   function TTF_RenderText_Blended
      (Font   : TTF_Font_Access;
       Text   : Interfaces.C.Strings.chars_ptr;
       Length : Interfaces.C.size_t;
       FG     : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_Blended";

   function TTF_RenderText_Blended_Wrapped
      (Font       : TTF_Font_Access;
       Text       : Interfaces.C.Strings.chars_ptr;
       Length     : Interfaces.C.size_t;
       FG         : TTF_Color;
       Wrap_Width : int) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_Blended_Wrapped";

   function TTF_RenderGlyph_Blended
      (Font : TTF_Font_Access;
       Ch   : Uint32;
       FG   : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderGlyph_Blended";

   ----------------------------------------------------------------------------
   -- Text Rendering (LCD - For LCD displays)
   ----------------------------------------------------------------------------

   function TTF_RenderText_LCD
      (Font   : TTF_Font_Access;
       Text   : Interfaces.C.Strings.chars_ptr;
       Length : Interfaces.C.size_t;
       FG     : TTF_Color;
       BG     : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_LCD";

   function TTF_RenderText_LCD_Wrapped
      (Font       : TTF_Font_Access;
       Text       : Interfaces.C.Strings.chars_ptr;
       Length     : Interfaces.C.size_t;
       FG         : TTF_Color;
       BG         : TTF_Color;
       Wrap_Width : int) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderText_LCD_Wrapped";

   function TTF_RenderGlyph_LCD
      (Font : TTF_Font_Access;
       Ch   : Uint32;
       FG   : TTF_Color;
       BG   : TTF_Color) return access SDL_Surface
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_RenderGlyph_LCD";

   ----------------------------------------------------------------------------
   -- Glyph Queries
   ----------------------------------------------------------------------------

   function TTF_FontHasGlyph
      (Font : TTF_Font_Access;
       Ch   : Uint32) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_FontHasGlyph";

   function TTF_GetGlyphMetrics
      (Font    : TTF_Font_Access;
       Ch      : Uint32;
       Minx    : access int;
       Maxx    : access int;
       Miny    : access int;
       Maxy    : access int;
       Advance : access int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetGlyphMetrics";

   function TTF_GetGlyphKerning
      (Font        : TTF_Font_Access;
       Previous_Ch : Uint32;
       Ch          : Uint32;
       Kerning     : access int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_GetGlyphKerning";

   ----------------------------------------------------------------------------
   -- Font Language
   ----------------------------------------------------------------------------

   function TTF_SetFontLanguage
     (Font           : TTF_Font_Access;
      Language_BCP47 : Interfaces.C.Strings.chars_ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetFontLanguage";

end Adi.SDL.TTF;
