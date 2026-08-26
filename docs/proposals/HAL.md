# Adi HAL — Analysis Report

Status: **analysis / proposal**. No code change implied by this
document; the recommendation at the end is what we would propose
implementing if the team decides to invest in a Hardware Abstraction
Layer for Adi.

---

## 1   Executive summary

Today Adi is tightly coupled to SDL3 + SDL3_ttf + SDL3_image. Forty
or so source files outside `Adi.SDL.*` import an `Adi.SDL.*`
subpackage directly. The framework is, in practice, an SDL3
application that happens to expose a widget toolkit on top.

Introducing a Hardware Abstraction Layer (HAL) would make it
possible to:

1. Run headless for automated testing.
2. Run on platforms where SDL3 is impractical (kernel framebuffers,
   bespoke embedded environments, web canvases that prefer not to
   go through Emscripten).
3. Swap in a native windowing/text/imaging stack on a given OS for
   tighter integration (Wayland + Pango + Cairo on Linux, Win32 +
   DirectWrite + Direct2D on Windows, Cocoa + CoreText + CoreGraphics
   on macOS).
4. Layer alternate renderers (Skia, Cairo, a pure-Ada software
   blitter) without disturbing widgets, styles or layout code.

The recommendation is **option D below** — a *narrow seam*, focused
on the four primitives the rest of the framework actually depends
on (window/event loop, 2D draw target, text, image decoding) — wired
in via a **build-time backend selection** mechanism modelled on the
existing build-profile source-dir switch in `adi.gpr`. SDL3 stays the
reference and default backend. A headless backend ships first as a
test driver. Other backends become opt-in side projects with a
clear contract.

---

## 2   Current SDL surface inventory

Quantitatively: 39 non-`adi-sdl-*` source files import at least one
`Adi.SDL.*` package. Qualitatively, the surface breaks down into
seven areas. Listed in rough order of how invasive removal would be.

### 2.1 Render (very invasive)
`Adi.SDL.Render` — `SDL_Renderer`, `SDL_Texture`, `SDL_FRect`,
`SDL_RenderTexture`, `SDL_RenderGeometry`, `SDL_SetRenderClipRect`,
`SDL_SetRenderDrawColor`, `SDL_RenderPresent`. This is the inner
loop of every frame: `Adi.Widget.Render_Items`,
`Adi.Render.Render_Window`, the per-item renderers
(`Render_Text_Item`, `Render_Panel_Item`, `Render_Image_Item`).

Anything that wants to display pixels touches this.

### 2.2 TTF text engine (very invasive)
`Adi.SDL.TTF` and `Adi.SDL.TTF.TextEngine` — `TTF_Font`,
`TTF_OpenFontIO`, `TTF_GetStringSize`, `TTF_GetFontHeight`,
`TTF_CreateText`, `TTF_DrawRendererText`. `Adi.Font` is built on
top, as is the text item renderer. Text shaping (HarfBuzz),
hinting and atlas management all live inside SDL3_ttf today.

### 2.3 Surface (invasive but localised)
`Adi.SDL.Surface` — `SDL_Surface`, `SDL_CreateSurface`,
`SDL_ConvertSurface`, `SDL_DestroySurface`. Used by `Adi.Image`,
`Adi.Screenshot`, the SVG raster path, and a few places that need
CPU pixel buffers.

### 2.4 Image decoding (narrow)
`Adi.SDL.Image` wraps SDL3_image: `IMG_Load_IO`,
`IMG_LoadAnimation_IO`. Used by `Adi.Image` and
`Adi.Animated_Image`. PNG / JPEG / WebP / GIF go through this; SVG
is handled separately by an in-tree backend (`vendor/plutosvg` or
a pure-Ada one).

### 2.5 Window + event pump (narrow but central)
`Adi.SDL.Video` — `SDL_Window`, `SDL_CreateWindow`,
`SDL_SetWindowMinimumSize`, `SDL_GetDisplayForWindow`. Used by
`Adi.Window` only.

`Adi.SDL.Events` — `SDL_PollEvent`, scancode enums, mouse buttons,
key modifier flags. Used by `Adi.App.Run` to drive the main loop
and by `Adi.Widget` for input dispatch.

### 2.6 IO, pixel format, mouse, locale (small)
`Adi.SDL.IO` — `SDL_IOFromConstMem`, `SDL_CloseIO`. Used by the
asset bundle loader and by every "load from memory" code path in
font/image.

`Adi.SDL.Pixelformat` — pixel-format constants. Only the format
constants matter; they could be redefined locally.

`Adi.SDL.Mouse` — `SDL_CreateSystemCursor`, `SDL_SetCursor`,
`SDL_ShowCursor`. Used by the cursor handling in widgets.

`Adi.SDL.Locale`, `Adi.SDL.Filesystem`, `Adi.SDL.Misc`,
`Adi.SDL.Dialog` — system integration shims (paths, system
dialogs, clipboard, locale list). Used in a handful of places.

### 2.7 Constants / enums (zero cost)
Type aliases like `SDL_PixelFormat`, scancode enums, mouse-button
enums. These can be re-declared by any backend or moved into a
backend-agnostic header.

---

## 3   Motivations to consider

Five concrete demand drivers, in descending order of likelihood.

### 3.1 Headless testing
The single most common ask. Today, running widget tests against a
real `App.Run` loop requires a display, an X server, a window — a
real graphics path. A headless backend would let `tests/src/*` and
CI build a full widget tree, compute layout, dispatch synthetic
input events, capture `widget_tree`/`widget_info` snapshots and
assert on them — all without rendering anything. Layout, style
cascade, animation, signals, deferred dispatch and MCP introspection
all already work without an actual `Render` call.

### 3.2 Embedded / framebuffer
Cars, kiosks, industrial HMI panels. The CPU/GPU is fixed, the
boot image is small, and dragging in SDL3 plus its X11/Wayland/EGL
dependency chain is awkward. A direct-to-framebuffer (Linux KMS/DRM
or `/dev/fb0`) backend, or a backend over a minimal Wayland client,
would let Adi target these devices.

### 3.3 Native integration on macOS / Windows
Some applications want native menus, native dialogs, native font
rendering for consistency with the host OS, or native text input
methods (CJK IME) that route through the OS rather than through
SDL_ttf. Replacing the render / text / window leaves of the HAL
with platform code (Direct2D + DirectWrite on Windows, CoreGraphics
+ CoreText on macOS) is the right shape if that integration is
worth the maintenance.

### 3.4 Web (without Emscripten round-trip)
SDL3 builds for the web through Emscripten, but the resulting
binary is large and the canvas API is reached indirectly through a
WebGL2 emulation layer. A direct `HTMLCanvas` backend (Wasm with
small JS shim for `2D.getContext('2d')`) would produce smaller
output and would integrate naturally with surrounding JS UI. This
is more speculative; nobody has asked for it yet.

### 3.5 Alternate accelerated renderers
Skia, Cairo with the GPU surface backend, a pure-Ada vector
renderer. Probably not worth pursuing on its own merits — SDL3's
renderer is already accelerated everywhere it can be — but useful
as a research / experimentation path.

---

## 4   Design options

Four options, sketched with cost and trade-offs. Sections 4.1 and
4.2 are "abstract everything"; 4.3 and 4.4 are "abstract the seam".

### 4.1 Tagged-type backend with virtual dispatch

```ada
type Backend is abstract tagged limited private;
type Backend_Access is access all Backend'Class;

procedure Create_Window
  (B : in out Backend; W : out Window_Handle;
   Title : String; Size : Size_2D) is abstract;
procedure Present (B : in out Backend; W : Window_Handle) is abstract;
procedure Render_Geometry (...) is abstract;
procedure Render_Text     (...) is abstract;
procedure Load_Image      (...) is abstract;
function  Poll_Event      (...) return Event is abstract;
...
```

* **Pro:** Single binary can carry several backends and switch at
  startup (e.g. `--backend=headless` for tests).
* **Pro:** Idiomatic Ada, easy to teach.
* **Con:** Adds virtual dispatch to every paint call. Negligible in
  practice but measurable.
* **Con:** Backend authors have to implement a large abstract type
  in one shot; the surface is wide.
* **Con:** The whole framework has to be plumbed with a `Backend`
  parameter or a process-global backend handle, both of which are
  intrusive.

### 4.2 Generic packages with compile-time backend

```ada
generic
   with package R is new Adi.HAL.Renderer (...);
   with package T is new Adi.HAL.Text     (...);
package Adi.Widget.Generic_Toolkit is ... end;
```

* **Pro:** Zero runtime cost. The compiler bakes the backend in.
* **Con:** Every package in the framework becomes generic.
  Instantiation chains get long.
* **Con:** Genericity bleeds into application code (every user has
  to instantiate the toolkit).
* **Con:** Adi has many independent modules (CSS, layout,
  animation, MCP, widgets) — making them all generic over the
  backend is a big surface change.

### 4.3 Build-time selection via GPR

`adi.gpr` already selects source directories at build time from a
GPR external — the MCP layer is compiled from `src/mcp` in
development builds and from `src/mcp_stub` otherwise:

```gpr
case Build_Profile is
   when "development" => MCP_Source_Dir := "src/mcp";
   when others        => MCP_Source_Dir := "src/mcp_stub";
end case;
--  ... MCP_Source_Dir is then listed in Source_Dirs.
```

Apply the same pattern to the HAL:

```gpr
type Backend_Kind is ("sdl3", "headless", "wayland", "win32");
Backend := external ("ADI_BACKEND", "sdl3");
case Backend is
   when "sdl3"     => for Source_Dirs use (..., "src/hal/sdl3", ...);
   when "headless" => for Source_Dirs use (..., "src/hal/headless", ...);
   ...
end case;
```

Each backend lives in its own source dir and re-implements the
same set of package specs (`Adi.HAL.Window`, `Adi.HAL.Renderer`,
`Adi.HAL.Text`, `Adi.HAL.Image`, `Adi.HAL.Events`, ...). The
non-HAL code in `Adi.*` only ever calls `Adi.HAL.*` symbols, never
SDL directly.

* **Pro:** Zero runtime cost.
* **Pro:** Each backend is its own self-contained directory; no
  intrusion in widgets or styles.
* **Pro:** Matches the project's existing build-time-selection
  pattern; reviewers already understand it.
* **Pro:** Backends can be added incrementally — only the headless
  backend has to ship at the same time as the refactor.
* **Con:** One binary = one backend. Process can't switch at
  startup (acceptable in practice — release apps don't change
  their backend; tests can build twice if they want both).
* **Con:** Requires a one-time, painful refactor of every
  non-HAL file that currently imports `Adi.SDL.*`. The diff is
  mechanical but large.

### 4.4 Hybrid — narrow seam over build-time selection

Same as 4.3, but the abstract surface is deliberately small and
focused on the four areas the rest of the framework genuinely
depends on:

| HAL package        | Provides                                  | Concrete users today                           |
|--------------------|-------------------------------------------|------------------------------------------------|
| `Adi.HAL.Window`   | window create/destroy/resize/title/min   | `Adi.Window`                                   |
| `Adi.HAL.Events`   | poll one event, abstract `Event_T`        | `Adi.App.Run`, `Adi.Widget` input dispatch     |
| `Adi.HAL.Renderer` | clear / fill / stroke / textured quads / geometry / clip / present | `Adi.Widget.Render_Items`, `Adi.Render`        |
| `Adi.HAL.Texture`  | upload/destroy/scale-mode, query size     | item renderers, image cache                    |
| `Adi.HAL.Surface`  | CPU pixel buffer create/blit/destroy      | `Adi.Image`, `Adi.Screenshot`, SVG raster      |
| `Adi.HAL.Text`     | open font / measure / draw at point       | `Adi.Font`, `Render_Text_Item`                 |
| `Adi.HAL.Image`    | decode from memory/stream → CPU pixels    | `Adi.Image`, `Adi.Animated_Image`              |
| `Adi.HAL.Cursor`   | create system cursor / show / hide        | widget cursor management                       |
| `Adi.HAL.Clock`    | monotonic ticks for the frame loop        | `Adi.App`                                      |
| `Adi.HAL.Clipboard`| get/set text                              | `Adi.Widget.Text_Editor`                       |

What is *not* in the HAL: pixel-format enums (redefined once,
backends translate), keyboard scancodes (redefined once, backends
translate), the file-IO stream type (replaced by a tiny `read_all
from address+length` primitive), filesystem paths (already wrapped
by `Adi.OS`), system locale and message-box (used in two places —
can stay SDL-specific behind a flag or move to a separate
`Adi.OS.*` layer).

* **Pro:** All the advantages of 4.3.
* **Pro:** The surface is small enough that a new backend is a
  weekend's work, not a project.
* **Pro:** The refactor of existing code is bounded — each
  non-HAL file changes at most a handful of imports + a handful
  of type names.
* **Con:** Loses access to less common SDL3 features (audio,
  gamepad, etc.). Applications that want those can still
  `with Adi.SDL.*` directly when the SDL3 backend is in use, but
  that path is non-portable by definition.

---

## 5   Recommended approach

**Option 4.4 (narrow seam) on top of 4.3 (build-time GPR
selection).** Specifically:

1. A new `Adi.HAL.*` namespace with the ten package specs in §4.4.
2. Each backend implements those specs and lives in
   `src/hal/<backend>/`. The reference backend, `sdl3`, contains
   roughly the current `Adi.SDL.*` files renamed and adapted.
3. `adi.gpr` adds `ADI_BACKEND` external with the same
   case-by-case `Source_Dirs` pattern already used for
   `ADI_SVG_BACKEND`.
4. Every non-HAL Adi file that currently imports `Adi.SDL.*` is
   migrated to import `Adi.HAL.*`. Names mostly carry over —
   `Adi.SDL.Render.SDL_RenderClear` becomes
   `Adi.HAL.Renderer.Clear` — but a handful require small
   adaptations (e.g. the text engine's `TTF_CreateText`/
   `TTF_DrawRendererText` pair becomes
   `Adi.HAL.Text.Make_Text` + `Adi.HAL.Text.Draw_At`).

The refactor is invasive but mechanical and bounded.

---

## 6   Required surface area in detail

For each HAL package, here is the minimum API the framework would
need. Concrete numbers reflect the current usage scanned across the
39 non-HAL files.

### 6.1 `Adi.HAL.Window`
```ada
type Window is private;
type Window_Access is access all Window;

function Create
  (Title  : String;
   Width  : Natural;
   Height : Natural;
   HiDPI  : Boolean := True) return Window_Access;

procedure Destroy   (W : in out Window_Access);
procedure Set_Title (W : Window_Access; Title : String);
procedure Set_Min_Size (W : Window_Access; Min_W, Min_H : Natural);
procedure Set_Position (W : Window_Access; X, Y : Integer);
procedure Get_Size     (W : Window_Access; W_Out, H_Out : out Natural);
procedure Get_Pixel_Density (W : Window_Access; D : out Float);
function  Is_Maximized (W : Window_Access) return Boolean;
function  Is_Fullscreen (W : Window_Access) return Boolean;
```
8 entry points, all currently mapping 1:1 to SDL3 calls.

### 6.2 `Adi.HAL.Events`
```ada
type Event_Kind is (None, Quit, Window_Resized, Window_Close,
                    Mouse_Down, Mouse_Up, Mouse_Move, Mouse_Wheel,
                    Key_Down, Key_Up, Text_Input, ...);
type Event_T (Kind : Event_Kind := None) is record
   case Kind is
      when Mouse_Down | Mouse_Up =>
         Button : Mouse_Button;
         X, Y   : Float;
      when Key_Down | Key_Up =>
         Code   : Key_Code;
         Mods   : Modifier_Set;
      ...
   end case;
end record;

function Poll (E : out Event_T) return Boolean;
```
One protocol-style record. The framework keeps its existing
`Adi.Core.Mouse_Button` and gains a HAL-neutral `Key_Code` enum.

### 6.3 `Adi.HAL.Renderer`
```ada
type Renderer is private;

function For_Window (W : Window_Access) return Renderer;

procedure Set_Draw_Color (R : Renderer; C : Color_8);
procedure Clear          (R : Renderer);
procedure Fill_Rect      (R : Renderer; Rect : Rectangle);
procedure Draw_Rect      (R : Renderer; Rect : Rectangle);
procedure Fill_Geometry  (R : Renderer; Vertices : Vertex_Array;
                          Indices : Index_Array);

procedure Draw_Texture   (R : Renderer; T : Texture;
                          Source : Rectangle; Dest : Rectangle);
procedure Set_Clip_Rect  (R : Renderer; Rect : Rectangle);
procedure Clear_Clip_Rect (R : Renderer);

procedure Present        (R : Renderer);
```
The most important contract. `Fill_Geometry` is the workhorse for
gradients, rounded corners and the SVG raster path; everything
else can be implemented in terms of textured quads and rect fills.

### 6.4 `Adi.HAL.Texture`
```ada
type Texture is private;

function From_Surface (R : Renderer; S : Surface) return Texture;
procedure Destroy     (T : in out Texture);
procedure Set_Scale_Mode (T : Texture; Mode : Scale_Mode);
procedure Get_Size    (T : Texture; W, H : out Natural);
procedure Set_Color_Mod (T : Texture; C : Color_8);
procedure Set_Alpha_Mod (T : Texture; A : Float);
```
Backed by GPU textures on accelerated backends, by CPU pixel
buffers on software ones.

### 6.5 `Adi.HAL.Surface`
```ada
type Surface is private;

function Create
  (Width, Height : Natural;
   Format        : Pixel_Format := RGBA32) return Surface;
function From_Pixels
  (Address : System.Address;
   Width, Height, Pitch : Natural;
   Format  : Pixel_Format) return Surface;

procedure Convert  (S : in out Surface; To : Pixel_Format);
procedure Destroy  (S : in out Surface);

function  Width    (S : Surface) return Natural;
function  Height   (S : Surface) return Natural;
function  Pitch    (S : Surface) return Natural;
function  Pixels   (S : Surface) return System.Address;
```

### 6.6 `Adi.HAL.Text`
```ada
type Font is private;
type Text_Object is private;

function Open_Font (Data : Storage_Array; Size_Px : Float) return Font;
procedure Destroy  (F : in out Font);

function Get_Height  (F : Font) return Natural;
function Get_Ascent  (F : Font) return Natural;
function Get_Descent (F : Font) return Natural;

procedure Measure
  (F : Font; Content : String; W, H : out Natural);

function  Make_Text  (R : Renderer; F : Font; Content : String) return Text_Object;
procedure Set_Color  (T : Text_Object; C : Color_8);
procedure Set_Wrap_Width (T : Text_Object; Px : Natural);
procedure Draw_At    (T : Text_Object; R : Renderer; X, Y : Float);
procedure Destroy    (T : in out Text_Object);
```
The hardest backend to write outside SDL3 (text shaping +
rasterization + atlas). A pure-software backend can lean on FreeType
+ HarfBuzz directly; a Cocoa backend can use CoreText.

### 6.7 `Adi.HAL.Image`
```ada
function Decode_From_Memory
  (Data : Storage_Array) return Surface;

type Animation is private;
function Decode_Animation_From_Memory
  (Data : Storage_Array) return Animation;
function Frame_Count    (A : Animation) return Natural;
function Frame_Delay_Ms (A : Animation; Index : Positive) return Natural;
function Frame_Surface  (A : Animation; Index : Positive) return Surface;
```

### 6.8 `Adi.HAL.Cursor`, `Adi.HAL.Clipboard`, `Adi.HAL.Clock`
Single-function-each shims. Each backend implements them or
returns reasonable defaults (headless: no-op cursor, in-memory
clipboard, system-clock ticks).

---

## 7   Phased plan

Five phases. Each is independently shippable; the framework only
changes externally after Phase 2 lands.

### Phase 1 — Define the HAL specs without implementing
Land `src/hal/*.ads` only, no bodies. Make sure the API closes
over what the rest of the framework needs by writing each spec
against actual call sites scanned out of the current code. No
behaviour change yet; nobody imports the new packages.

### Phase 2 — Implement the SDL3 backend, migrate the framework
Add `src/hal/sdl3/*.adb` that wraps current `Adi.SDL.*` calls
behind the HAL specs. Move all non-HAL Adi files to import
`Adi.HAL.*` instead of `Adi.SDL.*`. `Adi.SDL.*` itself stays for
backward compatibility (apps that use SDL features Adi doesn't
expose can keep importing it directly).

Wire `ADI_BACKEND` external into `adi.gpr` with `"sdl3"` as the
only allowed value for now. The SDL3 backend is selected
automatically and the existing build is unchanged.

This phase is the painful one — ~40 files change their imports.
Diff is mechanical. Tests must pass identically.

### Phase 3 — Headless backend
Add `src/hal/headless/*.adb`. The window opens (returning a
dummy handle), events come from an injectable queue, the renderer
records primitive calls into a log/buffer rather than painting
anything, text and image decoding go through stub backends (or
real ones if available — headless doesn't strictly mean no
HarfBuzz). `ADI_BACKEND=headless` becomes valid.

Tests that today need a real X server move to this backend. CI
gets a `gprbuild -XADI_BACKEND=headless` run that exercises the
full widget pipeline without a display.

### Phase 4 — Documentation + first community backend
Document the HAL contract (`docs/HAL_contract.md`), publish a
"writing a new backend" tutorial, and pick one community-driven
backend as the proof point — probably a Linux Wayland +
Cairo/Skia stack, or a Win32/Direct2D one, depending on who
volunteers.

### Phase 5 — Optional advanced backends
Web (HTMLCanvas / WebGPU), embedded (KMS/DRM or Wayland-only),
native macOS / Windows / iOS. None of these block the framework
itself; they live in separate repositories or `src/hal/<name>/`
subdirs and are maintained independently of the core.

---

## 8   Risks and open questions

### 8.1 Text rendering is the long pole
SDL3_ttf does an enormous amount of work — HarfBuzz shaping, BiDi,
hinting, sub-pixel positioning, atlas management for the renderer
text engine. Any non-SDL backend that wants real text quality has
to bring its own stack. The realistic options are FreeType +
HarfBuzz (re-implement what SDL_ttf does), or a platform-native
shaper (CoreText, DirectWrite, Pango). The headless backend can
short-circuit by using SDL_ttf with a software renderer surface
internally, even though everything else is stubbed.

### 8.2 Pixel format and color enums
SDL3 has a rich `SDL_PixelFormat` enum. Adi only really uses a
handful of formats (RGBA32, ARGB8888, RGB24, plus whatever
SDL3_image decodes). The HAL should define a small `Pixel_Format`
enum and have each backend translate. This is mechanical but
needs a single source-of-truth decision early.

### 8.3 Threading model
Today Adi is single-task with `Adi.Dispatch.Post` for cross-task
work. Some backends (notably native macOS) require all UI work
on the main thread, and may forbid creating any UI object until
a specific runtime hook is reached. The HAL contract has to be
explicit: "all `Adi.HAL.*` calls must happen on the task that
called `Adi.App.Run`." This matches today's reality but should
be a documented invariant rather than an emergent one.

### 8.4 Maintenance cost
Every backend is code to maintain forever. The recommendation
keeps SDL3 as the reference, adds headless for tests, and treats
all other backends as opt-in side projects. This is the only way
the project can keep its current velocity while not closing the
door on portability work.

### 8.5 ABI / API stability
Once external authors start writing backends, the HAL contract
becomes hard to change without breaking them. Phase 1 should
take its time and stabilise the surface before publishing it —
the contract is in effect a small standard library for "drawing
2D UI in Ada". Easier to add to than to take away from.

### 8.6 Where does `Adi.SDL.*` go?
After Phase 2, the existing `Adi.SDL.*` packages are still used
by the SDL3 backend internally but no longer imported by
framework code. They could either:
- stay as-is, marked "implementation detail of the SDL3 backend
  but available to applications that want them",
- move under `src/hal/sdl3/binding/` and stop appearing in the
  public Adi namespace entirely.

The first is friendlier to apps already using `Adi.SDL.*`
directly; the second is cleaner architecturally. Decision worth
making before Phase 2 lands.

---

## 9   Conclusion

A HAL is feasible. The current SDL coupling, while extensive, is
focused on a small number of operations (draw, present, measure
text, decode image, pump events, create window). A narrow
`Adi.HAL.*` namespace built around those operations and selected
at build time via a GPR external mirrors a pattern already in the
project (the MCP dev/stub source-dir switch) and would unlock at minimum a headless
test backend, with room for native platform backends as
contributors arrive.

The recommendation is to plan for Phases 1–3 explicitly
(definition, SDL3 migration, headless backend) and treat
everything after that as opportunistic. The biggest unknowns are
text rendering on non-SDL backends and the maintenance discipline
needed once multiple backends exist; both are solvable but neither
is free.
