with Interfaces.C.Strings;
with Adi.SDL.Video;       use Adi.SDL.Video;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;
with Adi.SDL.Surface;     use Adi.SDL.Surface;

package Adi.SDL.Render is

   ----------------------------------------------------------------------------
   -- Opaque Types
   ----------------------------------------------------------------------------

   type SDL_Renderer is limited null record;
   type SDL_Renderer_Ptr is access all SDL_Renderer;

   type SDL_Texture is record
      Format   : aliased SDL_PixelFormat;
      W        : aliased int;
      H        : aliased int;
      Refcount : aliased int;
   end record with Convention => C_Pass_By_Copy;

   type SDL_Texture_Ptr is access all SDL_Texture;
   subtype SDL_Texture_Access is SDL_Texture_Ptr;

   ----------------------------------------------------------------------------
   -- Enumerations
   ----------------------------------------------------------------------------

   type SDL_TextureAccess is (
      SDL_TEXTUREACCESS_STATIC,
      SDL_TEXTUREACCESS_STREAMING,
      SDL_TEXTUREACCESS_TARGET
   ) with Convention => C;

   type SDL_RendererLogicalPresentation is (
      SDL_LOGICAL_PRESENTATION_DISABLED,
      SDL_LOGICAL_PRESENTATION_STRETCH,
      SDL_LOGICAL_PRESENTATION_LETTERBOX,
      SDL_LOGICAL_PRESENTATION_OVERSCAN,
      SDL_LOGICAL_PRESENTATION_INTEGER_SCALE
   ) with Convention => C;

   -- Blend modes (simplified - can expand later)
   type SDL_BlendMode is new Uint32;
   SDL_BLENDMODE_NONE  : constant SDL_BlendMode := 16#0000_0000#;
   SDL_BLENDMODE_BLEND : constant SDL_BlendMode := 16#0000_0001#;
   SDL_BLENDMODE_ADD   : constant SDL_BlendMode := 16#0000_0002#;
   SDL_BLENDMODE_MOD   : constant SDL_BlendMode := 16#0000_0004#;
   SDL_BLENDMODE_MUL   : constant SDL_BlendMode := 16#0000_0008#;

   -- Scale modes
   type SDL_ScaleMode is (
      SDL_SCALEMODE_NEAREST,
      SDL_SCALEMODE_LINEAR
   ) with Convention => C;

   -- Flip modes
   type SDL_FlipMode is new Uint32;
   SDL_FLIP_NONE       : constant SDL_FlipMode := 16#0000_0000#;
   SDL_FLIP_HORIZONTAL : constant SDL_FlipMode := 16#0000_0001#;
   SDL_FLIP_VERTICAL   : constant SDL_FlipMode := 16#0000_0002#;

   -- VSync constants
   SDL_RENDERER_VSYNC_DISABLED : constant := 0;
   SDL_RENDERER_VSYNC_ADAPTIVE : constant := -1;

   ----------------------------------------------------------------------------
   -- Renderer Creation and Management
   ----------------------------------------------------------------------------

   function SDL_GetNumRenderDrivers return int
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetNumRenderDrivers";

   function SDL_GetRenderDriver (Index : int) return Interfaces.C.Strings.chars_ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderDriver";

   function SDL_CreateWindowAndRenderer
      (Title        : Interfaces.C.Strings.chars_ptr;
       Width        : int;
       Height       : int;
       Window_Flags : SDL_WindowFlags;
       Window       : out SDL_Window_Ptr;
       Renderer     : out SDL_Renderer_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateWindowAndRenderer";

   function SDL_CreateRenderer
      (Window : SDL_Window_Ptr;
       Name   : Interfaces.C.Strings.chars_ptr) return SDL_Renderer_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateRenderer";

   function SDL_CreateSoftwareRenderer
      (Surface : access SDL_Surface) return SDL_Renderer_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateSoftwareRenderer";

   function SDL_GetRenderer (Window : SDL_Window_Ptr) return SDL_Renderer_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderer";

   function SDL_GetRenderWindow
      (Renderer : SDL_Renderer_Ptr) return SDL_Window_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderWindow";

   function SDL_GetRendererName
      (Renderer : SDL_Renderer_Ptr) return Interfaces.C.Strings.chars_ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRendererName";

   procedure SDL_DestroyRenderer (Renderer : SDL_Renderer_Ptr)
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_DestroyRenderer";

   ----------------------------------------------------------------------------
   -- Renderer Properties and Settings
   ----------------------------------------------------------------------------

   function SDL_GetRenderOutputSize
      (Renderer : SDL_Renderer_Ptr;
       W        : access int;
       H        : access int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderOutputSize";

   function SDL_SetRenderLogicalPresentation
      (Renderer : SDL_Renderer_Ptr;
       W        : int;
       H        : int;
       Mode     : SDL_RendererLogicalPresentation) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderLogicalPresentation";

   function SDL_GetRenderLogicalPresentation
      (Renderer : SDL_Renderer_Ptr;
       W        : access int;
       H        : access int;
       Mode     : access SDL_RendererLogicalPresentation) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderLogicalPresentation";

   function SDL_SetRenderVSync
      (Renderer : SDL_Renderer_Ptr;
       Vsync    : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderVSync";

   function SDL_GetRenderVSync
      (Renderer : SDL_Renderer_Ptr;
       Vsync    : access int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderVSync";

   ----------------------------------------------------------------------------
   -- Texture Creation and Management
   ----------------------------------------------------------------------------

   function SDL_CreateTexture
      (Renderer : SDL_Renderer_Ptr;
       Format   : SDL_PixelFormat;
       Access_Mode : SDL_TextureAccess;
       W        : int;
       H        : int) return SDL_Texture_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateTexture";

   function SDL_CreateTextureFromSurface
      (Renderer : SDL_Renderer_Ptr;
       Surface  : access SDL_Surface) return SDL_Texture_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateTextureFromSurface";

   procedure SDL_DestroyTexture (Texture : SDL_Texture_Ptr)
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_DestroyTexture";

   function SDL_GetTextureSize
      (Texture : SDL_Texture_Ptr;
       W       : access Float;
       H       : access Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetTextureSize";

   ----------------------------------------------------------------------------
   -- Texture Properties
   ----------------------------------------------------------------------------

   function SDL_SetTextureColorMod
      (Texture : SDL_Texture_Ptr;
       R       : Uint8;
       G       : Uint8;
       B       : Uint8) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetTextureColorMod";

   function SDL_SetTextureColorModFloat
      (Texture : SDL_Texture_Ptr;
       R       : Float;
       G       : Float;
       B       : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetTextureColorModFloat";

   function SDL_GetTextureColorMod
      (Texture : SDL_Texture_Ptr;
       R       : access Uint8;
       G       : access Uint8;
       B       : access Uint8) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetTextureColorMod";

   function SDL_SetTextureAlphaMod
      (Texture : SDL_Texture_Ptr;
       Alpha   : Uint8) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetTextureAlphaMod";

   function SDL_SetTextureAlphaModFloat
      (Texture : SDL_Texture_Ptr;
       Alpha   : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetTextureAlphaModFloat";

   function SDL_GetTextureAlphaMod
      (Texture : SDL_Texture_Ptr;
       Alpha   : access Uint8) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetTextureAlphaMod";

   function SDL_SetTextureBlendMode
      (Texture   : SDL_Texture_Ptr;
       BlendMode : SDL_BlendMode) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetTextureBlendMode";

   function SDL_GetTextureBlendMode
      (Texture   : SDL_Texture_Ptr;
       BlendMode : access SDL_BlendMode) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetTextureBlendMode";

   function SDL_SetTextureScaleMode
      (Texture   : SDL_Texture_Ptr;
       ScaleMode : SDL_ScaleMode) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetTextureScaleMode";

   function SDL_GetTextureScaleMode
      (Texture   : SDL_Texture_Ptr;
       ScaleMode : access SDL_ScaleMode) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetTextureScaleMode";

   ----------------------------------------------------------------------------
   -- Render Target
   ----------------------------------------------------------------------------

   function SDL_SetRenderTarget
      (Renderer : SDL_Renderer_Ptr;
       Texture  : SDL_Texture_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderTarget";

   function SDL_GetRenderTarget
      (Renderer : SDL_Renderer_Ptr) return SDL_Texture_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderTarget";

   ----------------------------------------------------------------------------
   -- Viewport and Clipping
   ----------------------------------------------------------------------------

   function SDL_SetRenderViewport
      (Renderer : SDL_Renderer_Ptr;
       Rect     : access constant SDL_Rect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderViewport";

   function SDL_GetRenderViewport
      (Renderer : SDL_Renderer_Ptr;
       Rect     : access SDL_Rect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderViewport";

   function SDL_SetRenderClipRect
      (Renderer : SDL_Renderer_Ptr;
       Rect     : access constant SDL_Rect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderClipRect";

   function SDL_GetRenderClipRect
      (Renderer : SDL_Renderer_Ptr;
       Rect     : access SDL_Rect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderClipRect";

   function SDL_RenderClipEnabled
      (Renderer : SDL_Renderer_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderClipEnabled";

   ----------------------------------------------------------------------------
   -- Render Scale
   ----------------------------------------------------------------------------

   function SDL_SetRenderScale
      (Renderer : SDL_Renderer_Ptr;
       ScaleX   : Float;
       ScaleY   : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderScale";

   function SDL_GetRenderScale
      (Renderer : SDL_Renderer_Ptr;
       ScaleX   : access Float;
       ScaleY   : access Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderScale";

   ----------------------------------------------------------------------------
   -- Drawing State (Color and Blend Mode)
   ----------------------------------------------------------------------------

   function SDL_SetRenderDrawColor
      (Renderer : SDL_Renderer_Ptr;
       R        : Uint8;
       G        : Uint8;
       B        : Uint8;
       A        : Uint8) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderDrawColor";

   function SDL_SetRenderDrawColorFloat
      (Renderer : SDL_Renderer_Ptr;
       R        : Float;
       G        : Float;
       B        : Float;
       A        : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderDrawColorFloat";

   function SDL_GetRenderDrawColor
      (Renderer : SDL_Renderer_Ptr;
       R        : access Uint8;
       G        : access Uint8;
       B        : access Uint8;
       A        : access Uint8) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderDrawColor";

   function SDL_GetRenderDrawColorFloat
      (Renderer : SDL_Renderer_Ptr;
       R        : access Float;
       G        : access Float;
       B        : access Float;
       A        : access Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderDrawColorFloat";

   function SDL_SetRenderDrawBlendMode
      (Renderer  : SDL_Renderer_Ptr;
       BlendMode : SDL_BlendMode) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetRenderDrawBlendMode";

   function SDL_GetRenderDrawBlendMode
      (Renderer  : SDL_Renderer_Ptr;
       BlendMode : access SDL_BlendMode) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRenderDrawBlendMode";

   ----------------------------------------------------------------------------
   -- Basic Drawing Primitives
   ----------------------------------------------------------------------------

   function SDL_RenderClear (Renderer : SDL_Renderer_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderClear";

   function SDL_RenderPoint
      (Renderer : SDL_Renderer_Ptr;
       X        : Float;
       Y        : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderPoint";

   function SDL_RenderPoints
      (Renderer : SDL_Renderer_Ptr;
       Points   : access constant SDL_FPoint;
       Count    : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderPoints";

   function SDL_RenderLine
      (Renderer : SDL_Renderer_Ptr;
       X1       : Float;
       Y1       : Float;
       X2       : Float;
       Y2       : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderLine";

   function SDL_RenderLines
      (Renderer : SDL_Renderer_Ptr;
       Points   : access constant SDL_FPoint;
       Count    : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderLines";

   function SDL_RenderRect
      (Renderer : SDL_Renderer_Ptr;
       Rect     : access constant SDL_FRect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderRect";

   function SDL_RenderRects
      (Renderer : SDL_Renderer_Ptr;
       Rects    : access constant SDL_FRect;
       Count    : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderRects";

   function SDL_RenderFillRect
      (Renderer : SDL_Renderer_Ptr;
       Rect     : access constant SDL_FRect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderFillRect";

   function SDL_RenderFillRects
      (Renderer : SDL_Renderer_Ptr;
       Rects    : access constant SDL_FRect;
       Count    : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderFillRects";

   ----------------------------------------------------------------------------
   -- Texture Rendering
   ----------------------------------------------------------------------------

   function SDL_RenderTexture
      (Renderer : SDL_Renderer_Ptr;
       Texture  : SDL_Texture_Ptr;
       Srcrect  : access constant SDL_FRect;
       Dstrect  : access constant SDL_FRect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderTexture";

   function SDL_RenderTextureRotated
      (Renderer : SDL_Renderer_Ptr;
       Texture  : SDL_Texture_Ptr;
       Srcrect  : access constant SDL_FRect;
       Dstrect  : access constant SDL_FRect;
       Angle    : Long_Float;
       Center   : access constant SDL_FPoint;
       Flip     : SDL_FlipMode) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderTextureRotated";

   function SDL_RenderTextureTiled
      (Renderer : SDL_Renderer_Ptr;
       Texture  : SDL_Texture_Ptr;
       Srcrect  : access constant SDL_FRect;
       Scale    : Float;
       Dstrect  : access constant SDL_FRect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderTextureTiled";

   function SDL_RenderTexture9Grid
      (Renderer     : SDL_Renderer_Ptr;
       Texture      : SDL_Texture_Ptr;
       Srcrect      : access constant SDL_FRect;
       Left_Width   : Float;
       Right_Width  : Float;
       Top_Height   : Float;
       Bottom_Height : Float;
       Scale        : Float;
       Dstrect      : access constant SDL_FRect) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderTexture9Grid";

   ----------------------------------------------------------------------------
   -- Presentation and Flushing
   ----------------------------------------------------------------------------

   function SDL_RenderPresent (Renderer : SDL_Renderer_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderPresent";

   function SDL_FlushRenderer (Renderer : SDL_Renderer_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_FlushRenderer";

   ----------------------------------------------------------------------------
   -- Debug Text Rendering
   ----------------------------------------------------------------------------

   function SDL_RenderDebugText
      (Renderer : SDL_Renderer_Ptr;
       X        : Float;
       Y        : Float;
       Str      : Interfaces.C.Strings.chars_ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_RenderDebugText";

end Adi.SDL.Render;
