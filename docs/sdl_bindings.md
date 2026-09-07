# SDL3 Bindings for Adi

`src/adi-sdl*.ads` hold hand-crafted Ada bindings for SDL3, SDL3_ttf and SDL3_image. They use the native types `Adi.SDL` declares, Ada enumerations with `Convention => C` for C enums, and nothing from the auto-generated `bindings/` tree.

## Available Bindings

### Adi.SDL (adi-sdl.ads)
**Core SDL types and initialization**
- Type definitions: `Uint8`, `Uint16`, `Uint32`, `Uint64`, `Sint16`, `Sint32`, `C_bool`
- Geometric types: `SDL_Rect`, `SDL_FRect`, `SDL_FPoint`
- Initialization flags and functions

### Adi.SDL.Video (adi-sdl-video.ads)
**Window management**
- Window creation and management
- Window flags (fullscreen, resizable, etc.)
- Surface operations for windows

### Adi.SDL.Render (adi-sdl-render.ads)
**2D rendering with hardware acceleration**
- Renderer creation and management
- Texture creation and manipulation
- Drawing primitives (points, lines, rectangles)
- Texture rendering (basic, rotated, tiled, 9-grid)
- Viewport and clipping
- Color modulation and blending
- VSync control
- Debug text rendering

### Adi.SDL.TTF (adi-sdl-ttf.ads)
**TrueType font rendering via SDL3_ttf**
- Font loading and management
- Font properties (size, style, outline, hinting, kerning)
- Font metrics (height, ascent, descent, line skip)
- Text rendering modes:
  - **Solid**: Fast, low quality
  - **Shaded**: Better quality with background
  - **Blended**: Best quality, anti-aliased
  - **LCD**: Optimized for LCD displays
- Text size calculation
- Glyph queries and metrics

### Adi.SDL.TTF.TextEngine (adi-sdl-ttf-textengine.ads)
**Persistent `TTF_Text` objects**
- Renderer-backed and surface-backed text engines
- Text creation, font/colour/string/position/wrap-width updates
- Per-line substring metrics
- Draw command enumeration (`NOOP`, `FILL`, `COPY`) and draw operations

### Adi.SDL.Surface (adi-sdl-surface.ads)
**Software-based image manipulation**
- Surface types and pixel formats

### Adi.SDL.Pixelformat (adi-sdl-pixelformat.ads)
**Pixel format definitions**
- Common pixel formats (RGBA8888, RGB888, etc.)

### Adi.SDL.Events (adi-sdl-events.ads)
**Event handling**
- Event types and event loop management

### Adi.SDL.Mouse (adi-sdl-mouse.ads)
**Mouse input**
- Mouse state and button handling

### Adi.SDL.Dialog (adi-sdl-dialog.ads)
**File/folder dialog windows**
- File filter types
- Dialog callback type
- Open file, save file, and open folder dialogs

### Adi.SDL.Filesystem (adi-sdl-filesystem.ads)
**Filesystem paths and operations**
- Folder and path type enumerations
- Path info (type, size, timestamps)
- Base path, pref path, user folders, current directory
- Create/remove/rename/copy operations

### Adi.SDL.Misc (adi-sdl-misc.ads)
**Miscellaneous OS functions**
- URL opening (`SDL_OpenURL`)

### Adi.SDL.Image (adi-sdl-image.ads)
**Image file loading**
- Image loading via SDL3_image

### Adi.SDL.IO (adi-sdl-io.ads)
**IO streams**
- Opaque `SDL_IOStream`
- Streams over constant memory, for decoding bundled assets without a file

### Adi.SDL.Locale (adi-sdl-locale.ads)
**Preferred locales**
- `SDL_Locale` record (language, country)
- Query of the user's preferred locale list, used by `Adi.I18N`

### Adi.SDL.Properties (adi-sdl-properties.ads)
**Property sets**
- `SDL_PropertiesID`, create and destroy
- Number and pointer properties, which texture creation from a foreign GPU object reads

## Binding Pattern

All bindings follow this structure:

```ada
with Interfaces.C.Strings;
with Adi.SDL; use Adi.SDL;

package Adi.SDL.Subsystem is

   ----------------------------------------------------------------------------
   -- Opaque Types
   ----------------------------------------------------------------------------

   type SDL_Handle is limited null record;
   type SDL_Handle_Access is access all SDL_Handle;

   ----------------------------------------------------------------------------
   -- Enumerations
   ----------------------------------------------------------------------------

   type SDL_Flag_Type is (
      FLAG_ONE,
      FLAG_TWO
   ) with Convention => C;

   -- OR use constants for bitflags:
   type SDL_Flags is new Uint32;
   FLAG_A : constant SDL_Flags := 16#0001#;
   FLAG_B : constant SDL_Flags := 16#0002#;

   ----------------------------------------------------------------------------
   -- Functions
   ----------------------------------------------------------------------------

   function SDL_CreateSomething
      (Param : int) return SDL_Handle_Access
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateSomething";

end Adi.SDL.Subsystem;
```

## Common Types Reference

These types are defined in `Adi.SDL` and available to all child packages:

| Ada Type | C Equivalent | Description |
|----------|--------------|-------------|
| `Uint8` | `uint8_t` | 8-bit unsigned integer |
| `Uint16` | `uint16_t` | 16-bit unsigned integer |
| `Uint32` | `uint32_t` | 32-bit unsigned integer |
| `Uint64` | `uint64_t` | 64-bit unsigned integer |
| `Sint16` | `int16_t` | 16-bit signed integer |
| `Sint32` | `int32_t` | 32-bit signed integer |
| `C_bool` | `bool` | C boolean type |
| `int` | `int` | C int (from Interfaces.C) |
| `Float` | `float` | Standard Ada float |
| `Long_Float` | `double` | Standard Ada double |

## Usage Example

```ada
with Interfaces.C.Strings;
with Adi.SDL;        use Adi.SDL;
with Adi.SDL.Video;  use Adi.SDL.Video;
with Adi.SDL.Render; use Adi.SDL.Render;

procedure Example is
   Window   : SDL_Window_Ptr;
   Renderer : SDL_Renderer_Ptr;
   Success  : C_bool;
begin
   -- Initialize SDL
   if not SDL_Init (SDL_INIT_VIDEO) then
      return;
   end if;

   -- Create window and renderer
   Success := SDL_CreateWindowAndRenderer (
      Title        => Interfaces.C.Strings.New_String ("My App"),
      Width        => 800,
      Height       => 600,
      Window_Flags => SDL_WINDOW_RESIZABLE,
      Window       => Window,
      Renderer     => Renderer
   );

   if Success then
      -- Set draw color (red)
      Success := SDL_SetRenderDrawColor (Renderer, 255, 0, 0, 255);

      -- Clear screen
      Success := SDL_RenderClear (Renderer);

      -- Draw a filled rectangle
      declare
         Rect : aliased SDL_FRect := (100.0, 100.0, 200.0, 150.0);
      begin
         Success := SDL_RenderFillRect (Renderer, Rect'Access);
      end;

      -- Present
      Success := SDL_RenderPresent (Renderer);
   end if;

   -- Cleanup
   SDL_DestroyRenderer (Renderer);
end Example;
```

## Adding New Bindings

To add bindings for a new SDL subsystem:

1. Find the auto-generated binding in `bindings/sdl3_*.ads`
2. Create `src/adi-sdl-<subsystem>.ads`
3. Follow the binding pattern above
4. Use types from `Adi.SDL` (Uint8, Uint32, C_bool, etc.)
5. Convert C enums to Ada enumerations with `Convention => C`
6. Use incomplete types for opaque structures: `type T is limited null record;`

## Auto-Generated vs Hand-Crafted

The `bindings/` directory holds auto-generated bindings from the SDL3 headers. They are the reference for signatures, types and constants; the hand-crafted packages are what the library compiles, since the generated ones pull in `SDL3_SDL_stdinc_h`, `stddef_h` and raw C types throughout.

## Linking

`adi.gpr` exports `-lSDL3 -lSDL3_ttf -lSDL3_image -lm` and the platform switches as `Linker_Options`, so a project that withs it links without repeating them.
