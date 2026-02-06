-- Example demonstrating how to use the Adi.SDL.TTF binding
-- This shows basic font loading and text rendering

with Interfaces.C.Strings; 
with Adi.SDL;           use Adi.SDL;
with Adi.SDL.Video;     use Adi.SDL.Video;
with Adi.SDL.Render;    use Adi.SDL.Render;
with Adi.SDL.Surface;   use Adi.SDL.Surface;
with Adi.SDL.TTF;       use Adi.SDL.TTF;

procedure TTF_Example is
   Window   : SDL_Window_Ptr;
   Renderer : SDL_Renderer_Ptr;
   Font     : TTF_Font_Access;
   Surface  : access SDL_Surface;
   Texture  : access SDL_Texture;
   use type Interfaces.C.int;
   subtype int is Interfaces.C.int;

   -- Define a white color for text
   White : constant TTF_Color := (R => 255, G => 255, B => 255, A => 255);

   Success : Adi.SDL.C_bool;
begin
   -- Initialize SDL
   pragma Assert(SDL_Init (SDL_INIT_VIDEO),"SDL_Init");
   
   -- Initialize SDL_ttf
   pragma Assert(TTF_Init,"TTF_Init");

   -- Create window and renderer
   Adi.SDL.SDL_Assert (SDL_CreateWindowAndRenderer (
      Title        => Interfaces.C.Strings.New_String ("SDL_TTF Example"),
      Width        => 800,
      Height       => 600,
      Window_Flags => SDL_WINDOW_RESIZABLE,
      Window       => Window,
      Renderer     => Renderer
   ),"SDL_CreateWindowAndRenderer");

   -- Load a font (adjust path as needed)
   Font := TTF_OpenFont (
      File   => Interfaces.C.Strings.New_String ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
      Ptsize => 24.0
   );

   if Font = null then
      TTF_Quit;
      return;
   end if;

   -- Set font style to bold
   TTF_SetFontStyle (Font, TTF_STYLE_BOLD);

   -- Render text to a surface using the "Blended" mode (best quality)
   Surface := TTF_RenderText_Blended (
      Font   => Font,
      Text   => Interfaces.C.Strings.New_String ("Hello, SDL_TTF from Ada!"),
      Length => 0,  -- 0 means null-terminated string
      FG     => White
   );

   if Surface /= null then
      -- Create texture from surface
      Texture := SDL_CreateTextureFromSurface (Renderer, Surface);

      -- TODO: Render the texture to the screen
      -- This would typically be done in a render loop

      -- Clean up (in a real app, you'd keep the texture around)
      -- SDL_DestroyTexture (Texture);
      -- SDL_DestroySurface (Surface);
   end if;

   -- Get some font metrics
   declare
      Height   : constant int := TTF_GetFontHeight (Font);
      Ascent   : constant int := TTF_GetFontAscent (Font);
      Descent  : constant int := TTF_GetFontDescent (Font);
      LineSkip : constant int := TTF_GetFontLineSkip (Font);

      -- Query text size
      Text_W, Text_H : aliased Interfaces.C.int;
      Size_Success   : C_bool;
   begin
      Size_Success := TTF_GetStringSize (
         Font   => Font,
         Text   => Interfaces.C.Strings.New_String ("Hello, World!"),
         Length => 0,
         W      => Text_W'Access,
         H      => Text_H'Access
      );

      -- In a real app, you'd use these values for layout
   end;

   -- Clean up
   TTF_CloseFont (Font);
   TTF_Quit;

end TTF_Example;
