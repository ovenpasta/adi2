pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Unchecked_Deallocation;
with Ada.Strings.Fixed;       use Ada.Strings.Fixed;
with Interfaces;
with Interfaces.C;            use Interfaces.C;
with Interfaces.C.Strings;
with System;

with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.Render;
with Adi.SDL;                 use Adi.SDL;
with Adi.SDL.PixelFormat;     use Adi.SDL.PixelFormat;
with Adi.SDL.Render;          use Adi.SDL.Render;
with Adi.SDL.Surface;         use Adi.SDL.Surface;
with Adi.Texture_Cache;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Texture_View; use Adi.Widget.Texture_View;
with Adi.Widget.Texture_View.Testing;
with Adi.Widget_Styles;       use Adi.Widget_Styles;

with Test_Support; use Test_Support;

--  What a view does with the handle it is given, and what it puts on the
--  screen. The second half draws through a software renderer and reads
--  the canvas back: the byte order a producer declares, what opacity
--  does to a premultiplied surface, and what a texture SDL cannot adopt
--  reports are all properties of drawn pixels, and nothing short of
--  drawing them tests any of it.

procedure Texture_View_Test is

   use type Adi.Texture_Cache.Byte_Count;

   Canvas_W : constant := 16;
   Canvas_H : constant := 16;

   type Byte_Buffer is array (Natural range <>) of Interfaces.Unsigned_8;
   type Byte_Buffer_Access is access Byte_Buffer;
   procedure Free is
     new Ada.Unchecked_Deallocation (Byte_Buffer, Byte_Buffer_Access);

   type Pixel is record
      R, G, B, A : Natural := 0;
   end record;

   --  The borrow pins the widget for as long as the reference lives, so
   --  it gets a declaration of its own: an expression temporary would
   --  leave the length of the pin to finalisation timing.
   procedure Clean (H : Texture_View_Handle) is
      Ref : constant Widget_Ref := Borrow (+H);
   begin
      Mark_Clean (Ref.Ptr.all);
   end Clean;

   ---------------------------------------------------------------------
   procedure Test_Handles is
      H : constant Texture_View_Handle := Create_Handle;
      B : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
   begin
      Section ("A view is a widget like any other");

      Assert (Is_Valid (H), "a created view is valid");
      Assert (Is_Valid (+H), "it widens to a widget handle");
      Assert (Try_As_Texture_View (+H) = H,
              "and narrows back to the same view");
      Assert (Try_As_Texture_View (Adi.Widget.Box."+" (B))
                = Null_Texture_View_Handle,
              "a box does not narrow to a view");
      Assert (not Is_Valid (Null_Texture_View_Handle),
              "the null handle is not valid");
   end Test_Handles;

   ---------------------------------------------------------------------
   procedure Test_Driver_Names is
   begin
      Section ("Every backend names the driver SDL reports");

      --  These strings are compared against Adi.Window.Render_Driver, so
      --  they have to be SDL's spelling rather than ours.
      Assert (Driver_Name (OpenGL) = "opengl", "opengl");
      Assert (Driver_Name (OpenGLES2) = "opengles2", "opengles2");
      Assert (Driver_Name (Vulkan) = "vulkan", "vulkan");
      Assert (Driver_Name (D3D11) = "direct3d11", "direct3d11");
      Assert (Driver_Name (D3D12) = "direct3d12", "direct3d12");
      Assert (Driver_Name (GPU) = "gpu", "gpu");
   end Test_Driver_Names;

   ---------------------------------------------------------------------
   procedure Test_Nothing_Set is
      H   : constant Texture_View_Handle := Create_Handle;
      Ctx : Adi.Render.Render_Context;
   begin
      Section ("A view with no texture draws its box and stops");

      Assert (Last_Error (H) = "",
              "no error before anything has been asked for");

      --  No renderer and no texture: the interesting property is that
      --  this is a normal state rather than a failure, because a
      --  producer has usually not finished a frame when the first one
      --  is composited.
      Adi.Render.Create (Ctx, null);
      Render_Tree (+H, Ctx);

      Assert (Last_Error (H) = "",
              "and none after rendering without one");

      Adi.Render.Destroy (Ctx);
   end Test_Nothing_Set;

   ---------------------------------------------------------------------
   procedure Test_Set_And_Clear is
      H : constant Texture_View_Handle := Create_Handle;
   begin
      Section ("Setting a texture marks the view for repaint");

      Set_Geometry (+H, (0.0, 0.0, 64.0, 64.0));
      Clean (H);

      Set_Texture (H, OpenGL, Interfaces.Unsigned_64 (7), 32, 32);
      Assert (Is_Dirty (+H),
              "a name the view had not seen dirties it");

      Clean (H);
      Invalidate (H);
      Assert (Is_Dirty (+H),
              "and Invalidate dirties it without changing the name, "
              & "which is the only way a producer can report new "
              & "contents under an unchanged texture");

      Clean (H);
      Clear_Texture (H);
      Assert (Is_Dirty (+H), "clearing dirties it too");
   end Test_Set_And_Clear;

   ---------------------------------------------------------------------
   procedure Test_Pointer_Backends is
      H : constant Texture_View_Handle := Create_Handle;
   begin
      Section ("Pointer backends take the other Set_Texture");

      --  Direct3D and the GPU API hand over an object rather than a
      --  name. Nothing here reaches SDL: the point is that both forms
      --  are accepted and neither disturbs the other.
      Set_Texture (H, D3D11, System.Null_Address, 16, 16);
      Assert (Last_Error (H) = "", "a pointer texture is recorded");

      Set_Texture (H, OpenGL, Interfaces.Unsigned_64 (3), 16, 16);
      Assert (Last_Error (H) = "", "and a named one replaces it");
   end Test_Pointer_Backends;

   ---------------------------------------------------------------------
   procedure Test_Pixels_Path is
      H : constant Texture_View_Handle := Create_Handle;
   begin
      Section ("Set_Pixels takes a buffer that may not outlive the call");

      Set_Geometry (+H, (0.0, 0.0, 16.0, 16.0));
      Clean (H);

      --  Scoped on purpose: a paint callback's buffer is usually gone by
      --  the time the frame is composited, so the view has to have taken
      --  a copy here rather than kept the pointer.
      declare
         Pixels : aliased Byte_Buffer (0 .. 63) := [others => 16#7F#];
      begin
         Set_Pixels (H, Pixels'Address,
                     Width  => 4,
                     Height => 4,
                     Pitch  => 16,
                     Format => BGRA,
                     Alpha  => Premultiplied);
      end;

      Assert (Is_Dirty (+H), "new pixels dirty the view");
      Assert (Last_Error (H) = "", "and report no error");

      --  A different size has to grow the copy rather than overrun it.
      Clean (H);
      declare
         Bigger : aliased Byte_Buffer (0 .. 255) := [others => 16#20#];
      begin
         Set_Pixels (H, Bigger'Address,
                     Width => 8, Height => 8, Pitch => 32);
      end;

      Assert (Is_Dirty (+H), "resizing dirties it too");
      Assert (Last_Error (H) = "", "and still reports no error");
   end Test_Pixels_Path;

   ---------------------------------------------------------------------
   procedure Test_Formats_And_Alpha is
      H : constant Texture_View_Handle := Create_Handle;
   begin
      Section ("Format and alpha travel with the texture");

      --  BGRA and premultiplied are what an off-screen browser produces;
      --  taking the defaults would fringe every antialiased glyph.
      Set_Texture (H, OpenGL, Interfaces.Unsigned_64 (5), 8, 8,
                   Format => BGRA, Alpha => Premultiplied);
      Assert (Last_Error (H) = "", "a BGRA premultiplied handle is accepted");

      Set_Texture (H, D3D11, System.Null_Address, 8, 8,
                   Format => ARGB, Alpha => Straight);
      Assert (Last_Error (H) = "", "so is an ARGB pointer handle");
   end Test_Formats_And_Alpha;

   ---------------------------------------------------------------------
   --  Drawn through a software renderer
   ---------------------------------------------------------------------

   --  One canvas, one renderer and one context, cleared to black. Each
   --  drawing test opens its own: a texture belongs to the renderer that
   --  made it, and so does the cache holding it.
   type Scene is record
      Canvas   : SDL_Surface_Ptr := null;
      Renderer : SDL_Renderer_Ptr := null;
   end record;

   procedure Open (S   : out Scene;
                   Ctx : in out Adi.Render.Render_Context)
   is
      Unused : Adi.SDL.C_bool;
   begin
      S := (others => <>);
      S.Canvas := SDL_CreateSurface (int (Canvas_W), int (Canvas_H),
                                     SDL_PIXELFORMAT_RGBA32);
      if S.Canvas = null then
         Assert (False, "SDL should provide a surface");
         return;
      end if;

      S.Renderer := SDL_CreateSoftwareRenderer (S.Canvas);
      if S.Renderer = null then
         Assert (False, "SDL should provide a software renderer");
         return;
      end if;

      Unused := SDL_SetRenderDrawColor (S.Renderer, 0, 0, 0, 255);
      Unused := SDL_RenderClear (S.Renderer);
      Adi.Render.Create (Ctx, S.Renderer);
   end Open;

   procedure Close (S : in out Scene; Ctx : in out Adi.Render.Render_Context)
   is
   begin
      --  Before the renderer, which owns the textures the cache holds.
      Adi.Render.Destroy (Ctx);
      if S.Renderer /= null then
         SDL_DestroyRenderer (S.Renderer);
         S.Renderer := null;
      end if;
      if S.Canvas /= null then
         SDL_DestroySurface (S.Canvas);
         S.Canvas := null;
      end if;
   end Close;

   procedure Present (S : Scene) is
      Unused : Adi.SDL.C_bool;
   begin
      Unused := SDL_RenderPresent (S.Renderer);
   end Present;

   --  Read through SDL, so the surface's own layout is respected rather
   --  than assumed from a packed word.
   function At_Pixel (S : Scene; X, Y : Natural) return Pixel is
      R, G, B, A : aliased Uint8;
   begin
      if S.Canvas /= null
        and then Boolean (SDL_ReadSurfacePixel
                            (S.Canvas, int (X), int (Y),
                             R'Access, G'Access, B'Access, A'Access))
      then
         return (R => Natural (R), G => Natural (G),
                 B => Natural (B), A => Natural (A));
      end if;
      Assert (False, "the canvas should be readable");
      return (others => 0);
   end At_Pixel;

   function Image (P : Pixel) return String is
     ("(" & P.R'Image & P.G'Image & P.B'Image & P.A'Image & " )");

   function Near (Value, Expected : Natural; Tolerance : Natural := 2)
                  return Boolean
   is (abs (Value - Expected) <= Tolerance);

   procedure Set_Opacity (H : Texture_View_Handle; Value : Float) is
      Rules : Style_Rules;
   begin
      Rules.Opacity := Set (Opacity_Value (Value));
      Set_Part_Style (+H, Main_Part, From (Rules).Build);
   end Set_Opacity;

   --  A square of one colour, in the byte order a producer would hand
   --  over.
   function Filled (Format     : Texture_Format;
                    R, G, B, A : Interfaces.Unsigned_8;
                    Side       : Natural := 4) return Byte_Buffer
   is
      Result : Byte_Buffer (0 .. Side * Side * 4 - 1);
      Order  : constant Byte_Buffer (0 .. 3) :=
        (case Format is
            when RGBA => [R, G, B, A],
            when BGRA => [B, G, R, A],
            when ARGB => [A, R, G, B],
            when ABGR => [A, B, G, R]);
   begin
      for I in 0 .. Side * Side - 1 loop
         Result (I * 4 .. I * 4 + 3) := Order;
      end loop;
      return Result;
   end Filled;

   ---------------------------------------------------------------------
   --  A producer says what order its bytes are in, and the view has to
   --  ask SDL for that order rather than for the packed word its own
   --  machine would produce. A swap here turns a browser's blue into red
   --  on every frame.
   procedure Test_Scrolling_Moves_The_Texture is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      H   : constant Texture_View_Handle := Create_Handle;
      Pixels : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 240, G => 30, B => 30, A => 255);
   begin
      Section ("A scrolled ancestor moves the texture with the widget");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      Set_Geometry (+H, (0.0, 0.0, 4.0, 4.0));
      Set_Pixels (H, Pixels'Address,
                  Width => 4, Height => 4, Pitch => 16, Format => RGBA);

      --  Eight rows down, so the texture leaves where layout put it
      --  entirely rather than overlapping it.
      Adi.Render.Set_Scroll_Y (Ctx, 8.0);
      Render_Tree (+H, Ctx);
      Present (S);

      declare
         Was : constant Pixel := At_Pixel (S, 1, 1);
         Now : constant Pixel := At_Pixel (S, 1, 9);
      begin
         Assert (Near (Now.R, 240) and then Near (Now.G, 30),
                 "the texture belongs where the scroll put the widget,"
                 & " eight rows down; got " & Image (Now));
         Assert (not (Near (Was.R, 240) and then Near (Was.G, 30)),
                 "and not where layout alone would have placed it, which"
                 & " is what drawing at Get_Geometry would do; got "
                 & Image (Was));
      end;

      Close (S, Ctx);
   end Test_Scrolling_Moves_The_Texture;

   ---------------------------------------------------------------------
   procedure Test_Byte_Order_Reaches_The_Canvas is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      H   : constant Texture_View_Handle := Create_Handle;
      --  Distinct in every channel, so any permutation shows.
      Pixels : aliased constant Byte_Buffer :=
        Filled (BGRA, R => 200, G => 120, B => 40, A => 255);
   begin
      Section ("BGRA reaches the canvas as BGRA");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      Set_Geometry (+H, (0.0, 0.0, 4.0, 4.0));
      Set_Pixels (H, Pixels'Address,
                  Width => 4, Height => 4, Pitch => 16, Format => BGRA);
      Render_Tree (+H, Ctx);
      Present (S);

      declare
         P : constant Pixel := At_Pixel (S, 1, 1);
      begin
         Assert (Last_Error (H) = "",
                 "a CPU surface uploads without error, but got: "
                 & Last_Error (H));
         Assert (Near (P.R, 200) and then Near (P.G, 120)
                 and then Near (P.B, 40),
                 "BGRA bytes should land in the channels the producer"
                 & " named, not the ones this machine packs; got "
                 & Image (P));
      end;

      --  The same bytes declared RGBA are the same colour read the other
      --  way round, so they must not come out the same.
      Set_Pixels (H, Pixels'Address,
                  Width => 4, Height => 4, Pitch => 16, Format => RGBA);
      Render_Tree (+H, Ctx);
      Present (S);

      declare
         P : constant Pixel := At_Pixel (S, 1, 1);
      begin
         Assert (Near (P.R, 40) and then Near (P.B, 200),
                 "and the declared order is what decides that, so the same"
                 & " bytes called RGBA come out reversed; got " & Image (P));
      end;

      Close (S, Ctx);
   end Test_Byte_Order_Reaches_The_Canvas;

   ---------------------------------------------------------------------
   --  Opacity scales what a surface contributes. On a premultiplied
   --  surface the colour already carries its alpha, so scaling only the
   --  alpha leaves the colour above it, and the composite brightens as
   --  the widget is meant to fade.
   procedure Test_Opacity_Does_Not_Brighten_Premultiplied is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;

      --  White and opaque, which is the same pixel either way: a
      --  premultiplied white at full alpha is a straight white. The two
      --  views differ in nothing but the mode they declare.
      Pixels : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 255, G => 255, B => 255, A => 255);

      Plain : constant Texture_View_Handle := Create_Handle;
      Multi : constant Texture_View_Handle := Create_Handle;
   begin
      Section ("Opacity fades a premultiplied surface rather than"
               & " brightening it");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      Set_Geometry (+Plain, (0.0, 0.0, 4.0, 4.0));
      Set_Opacity (Plain, 0.5);
      Set_Pixels (Plain, Pixels'Address,
                  Width => 4, Height => 4, Pitch => 16,
                  Format => RGBA, Alpha => Straight);

      Set_Geometry (+Multi, (8.0, 0.0, 4.0, 4.0));
      Set_Opacity (Multi, 0.5);
      Set_Pixels (Multi, Pixels'Address,
                  Width => 4, Height => 4, Pitch => 16,
                  Format => RGBA, Alpha => Premultiplied);

      Render_Tree (+Plain, Ctx);
      Render_Tree (+Multi, Ctx);
      Present (S);

      declare
         Fades : constant Pixel := At_Pixel (S, 1, 1);
         Prem  : constant Pixel := At_Pixel (S, 9, 1);
      begin
         --  Half of white over black. If this is white the opacity never
         --  reached the draw, and the comparison below would hold for
         --  the wrong reason.
         Assert (Fades.R < 200,
                 "half opacity should darken a straight surface over black;"
                 & " got " & Image (Fades));
         Assert (Prem.R <= Fades.R + 2,
                 "and a premultiplied surface must not come out brighter"
                 & " than the straight one it is identical to: straight "
                 & Image (Fades) & ", premultiplied " & Image (Prem));
      end;

      Close (S, Ctx);
   end Test_Opacity_Does_Not_Brighten_Premultiplied;

   ---------------------------------------------------------------------
   --  The mode a producer declares decides how its colour meets what is
   --  behind it. Half-transparent white is white at half coverage if it
   --  is premultiplied and a half-grey at half coverage if it is not, so
   --  over black the two land two to one.
   procedure Test_Alpha_Mode_Reaches_The_Blend is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;

      Pixels : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 128, G => 128, B => 128, A => 128);

      Plain : constant Texture_View_Handle := Create_Handle;
      Multi : constant Texture_View_Handle := Create_Handle;
   begin
      Section ("Straight and premultiplied composite differently");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      Set_Geometry (+Plain, (0.0, 0.0, 4.0, 4.0));
      Set_Pixels (Plain, Pixels'Address,
                  Width => 4, Height => 4, Pitch => 16,
                  Format => RGBA, Alpha => Straight);

      Set_Geometry (+Multi, (8.0, 0.0, 4.0, 4.0));
      Set_Pixels (Multi, Pixels'Address,
                  Width => 4, Height => 4, Pitch => 16,
                  Format => RGBA, Alpha => Premultiplied);

      Render_Tree (+Plain, Ctx);
      Render_Tree (+Multi, Ctx);
      Present (S);

      declare
         Fades : constant Pixel := At_Pixel (S, 1, 1);
         Prem  : constant Pixel := At_Pixel (S, 9, 1);
      begin
         Assert (Near (Fades.R, 64, 4),
                 "straight colour is scaled by its own alpha as it"
                 & " composites; got " & Image (Fades));
         Assert (Near (Prem.R, 128, 4),
                 "premultiplied colour carries that already and must not"
                 & " be scaled again, or every antialiased edge darkens;"
                 & " got " & Image (Prem));
      end;

      Close (S, Ctx);
   end Test_Alpha_Mode_Reaches_The_Blend;

   ---------------------------------------------------------------------
   --  A texture SDL will not make is a silent failure otherwise -- an
   --  empty widget -- so the message has to name both the backend that
   --  was asked for and the driver the renderer actually is. That pair
   --  is the whole of the diagnosis, because the usual cause is a
   --  texture from an API this renderer was not built with.
   --
   --  The mismatch itself cannot be provoked here: a software renderer
   --  ignores the properties naming a foreign object and makes a texture
   --  of its own, so what fails against it is a size SDL refuses. What
   --  is being pinned is the message either way.
   procedure Test_Foreign_Backend_Is_Explained is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      H   : constant Texture_View_Handle := Create_Handle;
   begin
      Section ("A texture the renderer cannot make says so");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      declare
         Driver : constant String :=
           Interfaces.C.Strings.Value (SDL_GetRendererName (S.Renderer));
      begin
         Set_Geometry (+H, (0.0, 0.0, 4.0, 4.0));
         Set_Texture (H, OpenGL, Interfaces.Unsigned_64 (7), 0, 0);
         Render_Tree (+H, Ctx);
         Present (S);

         declare
            Message : constant String := Last_Error (H);
         begin
            Assert (Message /= "",
                    "a GL name a " & Driver & " renderer will not take"
                    & " should report something");
            Assert (Index (Message, Driver_Name (OpenGL)) > 0,
                    "naming the backend that was asked for, in: " & Message);
            Assert (Index (Message, Driver) > 0,
                    "and the driver the renderer actually is, in: "
                    & Message);
         end;

         Assert (At_Pixel (S, 1, 1).R = 0,
                 "and nothing should be drawn for it");
      end;

      Close (S, Ctx);
   end Test_Foreign_Backend_Is_Explained;

   ---------------------------------------------------------------------
   --  A wrapper stands for a texture the application owns. It occupies
   --  none of Adi's memory, so the budget is charged nothing for it, and
   --  it stands for one description of one handle: a producer that
   --  uploads new dimensions under a name it has not changed -- what a
   --  browser does on every resize -- must not be handed the wrapper
   --  that still declares the old ones.
   procedure Test_Wrappers_Are_Keyed_And_Free is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      H   : constant Texture_View_Handle := Create_Handle;

      function Views return Natural is
        (Adi.Render.Get_Texture_Stats (Ctx).By_Kind
           (Adi.Texture_Cache.View_Texture).Count);
   begin
      Section ("A wrapped handle is charged nothing and keyed by all of"
               & " its description");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      --  Nothing here needs the name to be a real GL texture: a software
      --  renderer makes a texture of its own from the same properties,
      --  which is enough to hold the bookkeeping this is about.
      Set_Geometry (+H, (0.0, 0.0, 4.0, 4.0));
      Set_Texture (H, OpenGL, Interfaces.Unsigned_64 (7), 4, 4);
      Render_Tree (+H, Ctx);

      Assert (Views = 1, "a wrapped handle leaves an entry");
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Bytes_Used = 0,
              "charged nothing: the memory behind it is the"
              & " application's, and a budget counting it would evict"
              & " textures Adi does own to stay under a limit about"
              & " memory it does not");

      Render_Tree (+H, Ctx);
      Assert (Views = 1,
              "and drawing it again reuses the wrapper rather than paying"
              & " a create and a destroy every frame");

      Set_Texture (H, OpenGL, Interfaces.Unsigned_64 (7), 8, 8);
      Render_Tree (+H, Ctx);
      Assert (Views = 2,
              "but the same name at another size is another texture: the"
              & " wrapper describes what it was told, and that is no"
              & " longer true of this one");

      Clear_Texture (H);
      Assert (Views = 0,
              "and clearing lets go of every wrapper, which is how an"
              & " application says the handle behind them is dead");

      Close (S, Ctx);
   end Test_Wrappers_Are_Keyed_And_Free;

   ---------------------------------------------------------------------
   --  A producer repaints what changed. The region it hands over is
   --  copied into its place in the surface and uploaded on its own,
   --  while the rest keeps the frame before it.
   procedure Test_Region_Updates_Only_Its_Part is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      H   : constant Texture_View_Handle := Create_Handle;

      Whole : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 255, G => 255, B => 255, A => 255);
      --  One pixel of it, which is all a caret ever is.
      Spot  : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 255, G => 0, B => 0, A => 255, Side => 1);
   begin
      Section ("A repainted region reaches its own part of the surface");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      Set_Geometry (+H, (0.0, 0.0, 4.0, 4.0));
      Set_Pixels (H, Whole'Address, Width => 4, Height => 4, Pitch => 16);
      Render_Tree (+H, Ctx);
      Present (S);

      Assert (At_Pixel (S, 2, 2).R = 255 and then At_Pixel (S, 2, 2).B = 255,
              "the whole surface arrives white");

      Set_Pixels (H, Spot'Address,
                  Width  => 4,
                  Height => 4,
                  Pitch  => 4,
                  Region => (X => 2, Y => 2, Width => 1, Height => 1));
      Render_Tree (+H, Ctx);
      Present (S);

      declare
         Changed : constant Pixel := At_Pixel (S, 2, 2);
         Kept    : constant Pixel := At_Pixel (S, 0, 0);
      begin
         Assert (Last_Error (H) = "",
                 "a region uploads without error, but got: "
                 & Last_Error (H));
         Assert (Changed.R = 255 and then Changed.G = 0
                 and then Changed.B = 0,
                 "the pixel the producer repainted should be the one that"
                 & " changed; got " & Image (Changed));
         Assert (Kept.R = 255 and then Kept.G = 255 and then Kept.B = 255,
                 "and the rest of the surface should keep what it was last"
                 & " given; got " & Image (Kept));
      end;

      Close (S, Ctx);
   end Test_Region_Updates_Only_Its_Part;

   ---------------------------------------------------------------------
   --  A row is Pitch from the next, and only its own pixels are the
   --  view's to read. A producer that allocates a tight last row --
   --  Pitch * (Height - 1) + Width * 4 -- has nothing at Pitch * Height,
   --  so a copy of that length reads past the buffer.
   procedure Test_Padded_Pitch_And_Tight_Last_Row is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      H   : constant Texture_View_Handle := Create_Handle;

      Pitch : constant := 24;   --  four pixels, plus eight bytes of pad
      Rows  : constant := 4;

      --  Exactly what the contract asks for and not a byte more, and on
      --  the heap where a producer's paint buffer is: a read past it is
      --  a read of somebody else's memory, which is what a checker sees
      --  and a passing test cannot.
      Tight : Byte_Buffer_Access :=
        new Byte_Buffer'(0 .. Pitch * (Rows - 1) + 4 * 4 - 1 => 0);
   begin
      Section ("Rows are read to their width, not to their pitch");

      Open (S, Ctx);
      if S.Renderer = null then
         Free (Tight);
         Close (S, Ctx);
         return;
      end if;

      --  Green wherever the pixels are; the padding stays zero, so a
      --  copy that took padding for pixels would show as black.
      for Row in 0 .. Rows - 1 loop
         for Col in 0 .. 3 loop
            declare
               At_Byte : constant Natural := Row * Pitch + Col * 4;
            begin
               Tight (At_Byte)     := 0;
               Tight (At_Byte + 1) := 255;
               Tight (At_Byte + 2) := 0;
               Tight (At_Byte + 3) := 255;
            end;
         end loop;
      end loop;

      Set_Geometry (+H, (0.0, 0.0, 4.0, 4.0));
      Set_Pixels (H, Tight (Tight'First)'Address,
                  Width => 4, Height => Rows, Pitch => Pitch);
      Render_Tree (+H, Ctx);
      Present (S);

      for Row in 0 .. Rows - 1 loop
         declare
            P : constant Pixel := At_Pixel (S, 3, Row);
         begin
            Assert (P.G = 255 and then P.R = 0,
                    "every row should be found at its own pitch; row"
                    & Row'Image & " gave " & Image (P));
         end;
      end loop;

      Free (Tight);
      Close (S, Ctx);
   end Test_Padded_Pitch_And_Tight_Last_Row;

   ---------------------------------------------------------------------
   --  An upload that fails has to say so and keep the frame. Reporting
   --  nothing and dropping it shows the frame before this one for as
   --  long as the producer sends no other, which is a window that never
   --  repaints and no message anywhere.
   procedure Test_A_Failed_Upload_Is_Kept_And_Reported is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      H   : constant Texture_View_Handle := Create_Handle;

      White : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 255, G => 255, B => 255, A => 255);
      Red   : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 255, G => 0, B => 0, A => 255);
   begin
      Section ("An upload that fails keeps its frame and says why");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      Set_Geometry (+H, (0.0, 0.0, 4.0, 4.0));
      Set_Pixels (H, White'Address, Width => 4, Height => 4, Pitch => 16);
      Render_Tree (+H, Ctx);
      Present (S);
      Assert (At_Pixel (S, 1, 1).R = 255 and then At_Pixel (S, 1, 1).G = 255,
              "the first frame lands");

      Adi.Widget.Texture_View.Testing.Fail_Next_Upload;
      Set_Pixels (H, Red'Address, Width => 4, Height => 4, Pitch => 16);
      Render_Tree (+H, Ctx);
      Present (S);

      Assert (Last_Error (H) /= "",
              "a refused upload should report something rather than pass"
              & " for a frame that was drawn");
      Assert (At_Pixel (S, 1, 1).G = 255,
              "and the canvas still shows the frame that did land; got "
              & Image (At_Pixel (S, 1, 1)));

      --  The producer sends nothing further, as it would not: it was
      --  told nothing went wrong.
      Render_Tree (+H, Ctx);
      Present (S);

      declare
         P : constant Pixel := At_Pixel (S, 1, 1);
      begin
         Assert (P.R = 255 and then P.G = 0,
                 "so the frame has to still be pending, and reach the"
                 & " screen on the next one; got " & Image (P));
         Assert (Last_Error (H) = "",
                 "with the error cleared once it does: " & Last_Error (H));
      end;

      Close (S, Ctx);
   end Test_A_Failed_Upload_Is_Kept_And_Reported;

   ---------------------------------------------------------------------
   --  A view's textures live in the renderer's cache, under a key that
   --  is the whole of what SDL was told. Two views cannot share an
   --  entry, and neither can two descriptions of one view.
   procedure Test_Textures_Are_Cached_By_Description is
      S   : Scene;
      Ctx : Adi.Render.Render_Context;
      A   : constant Texture_View_Handle := Create_Handle;
      B   : constant Texture_View_Handle := Create_Handle;

      Pixels : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 10, G => 20, B => 30, A => 255);
      Bigger : aliased constant Byte_Buffer :=
        Filled (RGBA, R => 10, G => 20, B => 30, A => 255, Side => 8);

      function Views return Natural is
        (Adi.Render.Get_Texture_Stats (Ctx).By_Kind
           (Adi.Texture_Cache.View_Texture).Count);
   begin
      Section ("A view's textures are cached by everything they were"
               & " described with");

      Open (S, Ctx);
      if S.Renderer = null then
         Close (S, Ctx);
         return;
      end if;

      Set_Geometry (+A, (0.0, 0.0, 4.0, 4.0));
      Set_Pixels (A, Pixels'Address, Width => 4, Height => 4, Pitch => 16);
      Render_Tree (+A, Ctx);

      Assert (Views = 1, "a drawn surface leaves one entry");
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Bytes_Used = 4 * 4 * 4,
              "charged the pixels it uploaded into");

      --  New contents under an unchanged description upload into the
      --  texture already held.
      Set_Pixels (A, Pixels'Address, Width => 4, Height => 4, Pitch => 16);
      Render_Tree (+A, Ctx);
      Assert (Views = 1, "and new contents reuse it rather than build one");

      --  A second view is a second surface, whatever it holds.
      Set_Geometry (+B, (8.0, 0.0, 4.0, 4.0));
      Set_Pixels (B, Pixels'Address, Width => 4, Height => 4, Pitch => 16);
      Render_Tree (+B, Ctx);
      Assert (Views = 2,
              "two views uploading through one renderer need two textures:"
              & " one is not the other's to write into");

      --  A resize is a different texture. Uploading a bigger surface
      --  into the old one is what a key without dimensions would do, and
      --  SDL would refuse it.
      Set_Pixels (A, Bigger'Address, Width => 8, Height => 8, Pitch => 32);
      Render_Tree (+A, Ctx);
      Assert (Views = 3, "and a resized surface needs another again");
      Assert (Last_Error (A) = "",
              "which is why the upload after a resize succeeds rather than"
              & " being refused for not fitting: " & Last_Error (A));

      --  Clearing lets go of all of them, which is how an application
      --  says the handles it gave are dead.
      Clear_Texture (A);
      Clear_Texture (B);
      Assert (Views = 0,
              "and clearing a view releases every texture made for it");

      Close (S, Ctx);
   end Test_Textures_Are_Cached_By_Description;

begin
   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");

   Start_Suite ("Texture View Test");

   Test_Handles;
   Test_Driver_Names;
   Test_Nothing_Set;
   Test_Set_And_Clear;
   Test_Pointer_Backends;
   Test_Pixels_Path;
   Test_Formats_And_Alpha;

   Test_Scrolling_Moves_The_Texture;
   Test_Byte_Order_Reaches_The_Canvas;
   Test_Alpha_Mode_Reaches_The_Blend;
   Test_Opacity_Does_Not_Brighten_Premultiplied;
   Test_Foreign_Backend_Is_Explained;
   Test_Wrappers_Are_Keyed_And_Free;
   Test_Region_Updates_Only_Its_Part;
   Test_Padded_Pitch_And_Tight_Last_Row;
   Test_A_Failed_Upload_Is_Kept_And_Reported;
   Test_Textures_Are_Cached_By_Description;

   Finish;
end Texture_View_Test;
