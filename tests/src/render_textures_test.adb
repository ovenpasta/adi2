pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.SDL;             use Adi.SDL;
with Adi.SDL.Render;      use Adi.SDL.Render;
with Adi.SDL.Surface;     use Adi.SDL.Surface;
with Adi.SDL.PixelFormat; use Adi.SDL.PixelFormat;
with Adi.Clock;
with Adi.Core;            use Adi.Core;
with Adi.CSS_Styles;      use Adi.CSS_Styles;
with Adi.Image;
with Adi.Render;
with Adi.Shadow;
with Adi.Texture_Cache;
with Adi.Widget;          use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles;   use Adi.Widget_Styles;
with Adi.Window;
with Test_Support;        use Test_Support;

--  The texture cache belongs to a render context, because the textures in
--  it belong to that context's renderer. This covers the wiring: that a
--  context has a cache with a budget, that only drawn frames age it, and
--  that two windows hold two independent caches rather than sharing one.
--
--  Box shadows are the cache's first real producer, so the last sections
--  drive the widget render path and read the cache back through the
--  context: what the shape of a shadow costs, that drawing it twice builds
--  it once, and what a budget too small for two of them does.

procedure Render_Textures_Test is

   use type Adi.Texture_Cache.Byte_Count;
   use type Adi.Texture_Cache.Frame_Count;
   use type Adi.Texture_Cache.Texture_Handle;
   use type Adi.Image.Image_Access;

   MB : constant Adi.Texture_Cache.Byte_Count := 1024 * 1024;

   Canvas   : SDL_Surface_Ptr;
   Renderer : SDL_Renderer_Ptr;

   function Shadow_Key (N : Natural) return Adi.Texture_Cache.Texture_Key is
     ((Kind => Adi.Texture_Cache.Shadow_Texture, Extent_A => N,
       others => <>));

   function New_Texture return SDL_Texture_Ptr is
      Surf : constant SDL_Surface_Ptr :=
        SDL_CreateSurface (4, 4, SDL_PIXELFORMAT_RGBA32);
      Tex  : SDL_Texture_Ptr;
   begin
      Tex := SDL_CreateTextureFromSurface (Renderer, Surf);
      SDL_DestroySurface (Surf);
      return Tex;
   end New_Texture;

   ---------------------------------------------------------------------------

   procedure Test_Context_Owns_A_Cache is
      Ctx : Adi.Render.Render_Context;
   begin
      Section ("a context owns a cache");

      Adi.Render.Create (Ctx, Renderer);

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Budget
                = Adi.Render.Default_Texture_Budget,
              "A new context should start at the default budget");

      --  One cache per context, not one per call: a handle from an earlier
      --  store has to resolve against a later lookup.
      declare
         H : constant Adi.Texture_Cache.Texture_Handle :=
           Adi.Render.Store_Texture
             (Ctx,
              Key    => Shadow_Key (4),
              Texture => New_Texture,
              Width => 4, Height => 4, Bytes => 64,
              Build_Time => Adi.Clock.Microseconds (100));
      begin
         Assert (Adi.Render.Is_Valid_Texture (Ctx, H),
                 "A handle should still resolve through a later lookup of"
                 & " the same context's cache");
         Assert (Adi.Render.Find_Texture (Ctx, Shadow_Key (4)) = H,
                 "and the key it was stored under should find it");
         Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 1,
                 "and the entry should be resident");
      end;

      Adi.Render.Destroy (Ctx);
   end Test_Context_Owns_A_Cache;

   ---------------------------------------------------------------------------

   --  Destroying a context has to release the textures it holds, and has to
   --  do it while the renderer that owns them is still alive. A borrow held
   --  across the destruction is what makes that observable: the borrow keeps
   --  the bookkeeping alive, so its region can still be read afterwards, and
   --  the texture it names is gone.
   procedure Test_Destroy_Releases_Textures is
      Ctx : Adi.Render.Render_Context;
      H   : Adi.Texture_Cache.Texture_Handle;
   begin
      Section ("destroying a context releases its textures");

      Adi.Render.Create (Ctx, Renderer);
      H := Adi.Render.Store_Texture
             (Ctx, Shadow_Key (7), New_Texture,
              Width => 4, Height => 4, Bytes => 64,
              Build_Time => Adi.Clock.Microseconds (100));

      declare
         Ref : constant Adi.Texture_Cache.Texture_Ref :=
           Adi.Render.Borrow_Texture (Ctx, H);
      begin
         Assert (Ref.Texture /= null,
                 "A borrow taken while the context lives should name a"
                 & " texture");

         Adi.Render.Destroy (Ctx);

         Assert (Ref.Texture = null,
                 "Destroying a context should destroy its textures, even one"
                 & " a draw is holding: they belong to the renderer, which"
                 & " goes next");
         Assert (Ref.Width = 4 and then Ref.Height = 4,
                 "and the borrow should still be readable, so ending it"
                 & " touches live bookkeeping");
      end;

      Assert (not Adi.Render.Is_Valid_Texture (Ctx, H),
              "A handle into a destroyed context should resolve to nothing");

      --  Borrowing from a context that is already gone must behave like
      --  borrowing a stale handle, not raise: a caller that checks the
      --  region it gets back is checking the same thing either way.
      declare
         Late : constant Adi.Texture_Cache.Texture_Ref :=
           Adi.Render.Borrow_Texture (Ctx, H);
      begin
         Assert (Late.Texture = null,
                 "Borrowing from a destroyed context should yield an empty"
                 & " borrow rather than raising");
         Assert (Late.Width = 0 and then Late.Height = 0,
                 "and that borrow should describe nothing");
      end;

      --  Everything else here tolerates a destroyed context, and the
      --  renderer has to as well: Adi.Image reaches it through this on the
      --  way to a lease, and promises a null result rather than an
      --  exception.
      Assert (Adi.Render.Get_Renderer (Ctx) = null,
              "A destroyed context should report no renderer");
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 0,
              "and hold nothing");
   end Test_Destroy_Releases_Textures;

   ---------------------------------------------------------------------------

   procedure Test_Advance_Frame_Threads_Through is
      Ctx : Adi.Render.Render_Context;
   begin
      Section ("advancing a context advances its cache");

      Adi.Render.Create (Ctx, Renderer);

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Frames = 0,
              "A new context should have drawn nothing");

      for I in 1 .. 5 loop
         Adi.Render.Advance_Frame (Ctx);
      end loop;

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Frames = 5,
              "Each advance should reach the cache");

      Adi.Render.Destroy (Ctx);
   end Test_Advance_Frame_Threads_Through;

   ---------------------------------------------------------------------------

   procedure Test_Window_Budget_Is_Per_Window is
      A, B : Adi.Window.Window_Handle;
   begin
      Section ("each window carries its own budget");

      A := Adi.Window.Create_Window_Handle ("Textures A", (160.0, 120.0));
      B := Adi.Window.Create_Window_Handle ("Textures B", (160.0, 120.0));

      Assert (Adi.Window.Get_Texture_Stats (A).Budget
                = Adi.Render.Default_Texture_Budget,
              "A new window should start at the default budget");

      Adi.Window.Set_Texture_Budget (A, 8 * MB);

      Assert (Adi.Window.Get_Texture_Stats (A).Budget = 8 * MB,
              "Setting a window's budget should take effect");
      Assert (Adi.Window.Get_Texture_Stats (B).Budget
                = Adi.Render.Default_Texture_Budget,
              "and must not reach another window: two renderers cannot"
              & " share a texture, so they cannot share a cache");

      Adi.Window.Destroy (A);
      Adi.Window.Destroy (B);
   end Test_Window_Budget_Is_Per_Window;

   ---------------------------------------------------------------------------

   procedure Test_Only_Drawn_Frames_Age_The_Cache is
      W : Adi.Window.Window_Handle;
   begin
      Section ("idle ticks do not age the cache");

      W := Adi.Window.Create_Window_Handle ("Textures Idle", (160.0, 120.0));

      --  Nothing is dirty in an empty window, so ask for the frame that
      --  the rest of this measures against.
      declare
         Ref : constant Adi.Window.Window_Ref := Adi.Window.Borrow (W);
      begin
         Adi.Window.Request_Redraw (Ref.Ptr.all);
      end;
      Adi.Window.Render (W);

      declare
         Drawn : constant Adi.Texture_Cache.Frame_Count :=
           Adi.Window.Get_Texture_Stats (W).Frames;
      begin
         Assert (Drawn > 0, "A drawn frame should advance the cache");

         --  Nothing has changed, so these ticks draw nothing.
         for I in 1 .. 20 loop
            Adi.Window.Render (W);
         end loop;

         Assert (Adi.Window.Get_Texture_Stats (W).Frames = Drawn,
                 "Ticks that draw nothing must not age entries that had no"
                 & " chance to be used");

         --  A frame that does draw resumes counting.
         declare
            Ref : constant Adi.Window.Window_Ref := Adi.Window.Borrow (W);
         begin
            Adi.Window.Request_Redraw (Ref.Ptr.all);
         end;
         Adi.Window.Render (W);

         Assert (Adi.Window.Get_Texture_Stats (W).Frames > Drawn,
                 "and a frame that is drawn should count again");
      end;

      Adi.Window.Destroy (W);
   end Test_Only_Drawn_Frames_Age_The_Cache;

   ---------------------------------------------------------------------------
   --  Raster images through the lease path
   ---------------------------------------------------------------------------

   --  Scale mode is texture state, so it identifies a raster texture just
   --  as it does an SVG one. Holding the first lease is what makes this
   --  discriminate: the entry stays pinned, so a texture built for the
   --  second mode has to be a distinct live one rather than an address
   --  that happens to be reused.
   procedure Test_Raster_Scale_Mode_Is_Keyed is
      Ctx  : Adi.Render.Render_Context;
      Surf : constant SDL_Surface_Ptr :=
        SDL_CreateSurface (8, 8, SDL_PIXELFORMAT_RGBA32);
      Img  : Adi.Image.Image_Access;
   begin
      Section ("a raster's scale mode identifies its texture");

      Adi.Render.Create (Ctx, Renderer);
      Img := Adi.Image.Create_From_Surface (Surf);
      Assert (Img /= null, "a surface makes a raster image");

      if Img /= null then
         declare
            Linear : constant Adi.Texture_Cache.Texture_Ref :=
              Adi.Image.Acquire_Texture (Img.all, Ctx, 8.0, 8.0);
         begin
            Assert (Linear.Texture /= null,
                    "a raster leases under the default mode");

            Adi.Image.Set_Scale_Mode (Img.all, Adi.Image.Scale_Nearest);

            declare
               Nearest : constant Adi.Texture_Cache.Texture_Ref :=
                 Adi.Image.Acquire_Texture (Img.all, Ctx, 8.0, 8.0);
            begin
               Assert (Nearest.Texture /= null,
                       "and under another mode");
               Assert (Nearest.Texture /= Linear.Texture,
                       "which must be a separate texture: a raster's scale"
                       & " mode is part of what identifies it, as an SVG's"
                       & " is");

               --  A raster does not vary with the requested size, so a
               --  different one leases the entry already held. The lease
               --  above is still open, so a rebuild would have to be a
               --  distinct live texture.
               declare
                  Bigger : constant Adi.Texture_Cache.Texture_Ref :=
                    Adi.Image.Acquire_Texture (Img.all, Ctx, 64.0, 40.0);
               begin
                  Assert (Bigger.Texture = Nearest.Texture,
                          "another requested size should lease the raster"
                          & " already held, not rasterise one");
               end;
            end;
         end;

         Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 2,
                 "so two modes leave two entries, and the second size adds"
                 & " no third");
         Assert (Adi.Render.Get_Texture_Stats (Ctx).Bytes_Used
                   = 2 * 8 * 8 * 4,
                 "each charged the eight-by-eight surface it uploaded");

         Adi.Image.Free (Img);
      end if;

      Adi.Render.Destroy (Ctx);
   end Test_Raster_Scale_Mode_Is_Keyed;

   ---------------------------------------------------------------------------
   --  Box shadows through the widget render path
   ---------------------------------------------------------------------------

   --  Blur and corner radius are the whole of a shadow's shape, so they are
   --  the whole of its key. Everything else about a shadow -- its colour,
   --  its offset, the widget it belongs to -- is applied when it is drawn.
   function Shadowed_Box
     (Blur_Px, Radius_Px, Spread_Px : Float)
      return Adi.Widget.Box.Box_Handle
   is
      B     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle (40.0, 40.0, 60.0, 60.0);
      Rules : Style_Rules;
   begin
      Rules.Background_Color := Set_Bg (RGBA (255, 255, 255, 1.0));
      Rules.Border_Radius := Set (Radius (Px (Radius_Px)));
      Rules.Box_Shadow := Set (Shadow (Offset_X => Px (0.0),
                                       Offset_Y => Px (2.0),
                                       Blur     => Px (Blur_Px),
                                       Spread   => Px (Spread_Px),
                                       Color    => RGBA (0, 0, 0, 0.6)));
      Set_Part_Style (Adi.Widget.Box.To_Widget_Handle (B), Main_Part,
                      From (Rules).Build);
      return B;
   end Shadowed_Box;

   procedure Draw_Once
     (Ctx : in out Adi.Render.Render_Context;
      B   : Adi.Widget.Box.Box_Handle)
   is
      H : constant Widget_Handle := Adi.Widget.Box.To_Widget_Handle (B);
   begin
      Layout_Tree (H);
      Adi.Widget.Update (H);
      Adi.Widget.Render_Tree (H, Ctx);
   end Draw_Once;

   procedure Drop (B : Adi.Widget.Box.Box_Handle) is
      H : Widget_Handle := Adi.Widget.Box.To_Widget_Handle (B);
   begin
      Adi.Widget.Destroy (H);
   end Drop;

   --  The key Render_Box_Shadow stores a shadow under. Naming it here is
   --  what lets a test hold a handle into the cache across a draw.
   function Shape_Key (Blur, Radius : Natural)
                       return Adi.Texture_Cache.Texture_Key
   is ((Kind     => Adi.Texture_Cache.Shadow_Texture,
        Extent_A => Blur,
        Extent_B => Radius,
        others   => <>));

   --  What Render_Box_Shadow charges: the generated texture is square, of
   --  the side Adi.Shadow decides, at four bytes a pixel.
   function Shadow_Charge (Blur, Radius : Natural)
                           return Adi.Texture_Cache.Byte_Count
   is
      Geom : constant Adi.Shadow.Geometry :=
        Adi.Shadow.Geometry_For (Blur, Radius);
   begin
      return Adi.Texture_Cache.Byte_Count (Geom.Tex_Size)
             * Adi.Texture_Cache.Byte_Count (Geom.Tex_Size) * 4;
   end Shadow_Charge;

   procedure Test_Shadow_Is_Cached_And_Charged is
      Ctx : Adi.Render.Render_Context;
      Box : Adi.Widget.Box.Box_Handle;
   begin
      Section ("a drawn shadow is cached at its real size");

      Adi.Render.Create (Ctx, Renderer);
      Box := Shadowed_Box (Blur_Px => 8.0, Radius_Px => 6.0, Spread_Px => 0.0);

      Draw_Once (Ctx, Box);

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 1,
              "Drawing a box shadow should leave its texture in the cache");
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Bytes_Used
                = Shadow_Charge (8, 6),
              "and charge it the whole texture at four bytes a pixel");

      --  The key is the shape, so the same shape drawn again is the same
      --  entry. Counting entries cannot tell reuse from rebuilding over
      --  the same key -- both leave one. Holding a handle can: a rebuild
      --  retires what it replaces, and the handle stops resolving.
      declare
         Held : constant Adi.Texture_Cache.Texture_Handle :=
           Adi.Render.Find_Texture (Ctx, Shape_Key (8, 6));
      begin
         Assert (Adi.Render.Is_Valid_Texture (Ctx, Held),
                 "The shadow should be findable under its shape");

         Draw_Once (Ctx, Box);

         Assert (Adi.Render.Is_Valid_Texture (Ctx, Held),
                 "Drawing the same shadow again should reuse the entry"
                 & " rather than build over it");
      end;

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 1,
              "and leave exactly one entry");
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Bytes_Used
                = Shadow_Charge (8, 6),
              "charged nothing further for it");

      Drop (Box);
      Adi.Render.Destroy (Ctx);
   end Test_Shadow_Is_Cached_And_Charged;

   procedure Test_Distinct_Shapes_Are_Distinct_Entries is
      Ctx : Adi.Render.Render_Context;
      A, B, C : Adi.Widget.Box.Box_Handle;
   begin
      Section ("each shadow shape is its own entry");

      Adi.Render.Create (Ctx, Renderer);

      --  Same radius, different blur.
      A := Shadowed_Box (Blur_Px => 4.0, Radius_Px => 6.0, Spread_Px => 0.0);
      --  Same blur, different radius.
      B := Shadowed_Box (Blur_Px => 4.0, Radius_Px => 14.0, Spread_Px => 0.0);
      --  Same shape as A, different spread: spread moves and grows the
      --  destination rectangle, it does not change the texture.
      C := Shadowed_Box (Blur_Px => 4.0, Radius_Px => 6.0, Spread_Px => 3.0);

      Draw_Once (Ctx, A);
      Draw_Once (Ctx, B);

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 2,
              "Blur and radius each identify a shadow, so two shapes should"
              & " occupy two entries");
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Bytes_Used
                = Shadow_Charge (4, 6) + Shadow_Charge (4, 14),
              "charged as the sum of both textures");

      Draw_Once (Ctx, C);

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 2,
              "Spread is not part of a shadow's texture, so it should not"
              & " produce a third entry");

      Drop (A);
      Drop (B);
      Drop (C);
      Adi.Render.Destroy (Ctx);
   end Test_Distinct_Shapes_Are_Distinct_Entries;

   procedure Test_Budget_Retains_Idle_Shadows is
      Ctx : Adi.Render.Render_Context;
      A, B : Adi.Widget.Box.Box_Handle;
   begin
      Section ("the budget retains idle shadows, not drawn ones");

      Adi.Render.Create (Ctx, Renderer);

      A := Shadowed_Box (Blur_Px => 4.0, Radius_Px => 6.0, Spread_Px => 0.0);
      B := Shadowed_Box (Blur_Px => 12.0, Radius_Px => 6.0, Spread_Px => 0.0);

      --  Room to retain one shadow that nothing is drawing any more.
      Adi.Render.Set_Texture_Budget (Ctx, Shadow_Charge (12, 6));

      Draw_Once (Ctx, A);
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 1,
              "The first shadow should be resident");

      --  Both drawn in the same frame: both are in the scene, so both
      --  stay even though together they exceed the budget. Evicting
      --  either would rebuild it on the next frame that drew it.
      Draw_Once (Ctx, B);
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 2,
              "Two shadows the frame is drawing should both be resident,"
              & " whatever the budget retains");

      --  Now stop drawing them and let the frames pass. Both fall out of
      --  the scene, and the budget keeps only what it has room for.
      for I in 1 .. 3 loop
         Adi.Render.Advance_Frame (Ctx);
      end loop;

      Assert (Adi.Render.Get_Texture_Stats (Ctx).Count = 1,
              "Once nothing is drawing them, the budget should retain one");
      Assert (Adi.Render.Get_Texture_Stats (Ctx).Bytes_Used
                <= Shadow_Charge (12, 6),
              "and idle residency should be inside the budget");

      Drop (A);
      Drop (B);
      Adi.Render.Destroy (Ctx);
   end Test_Budget_Retains_Idle_Shadows;

begin
   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");

   Start_Suite ("Render textures test");

   Canvas := SDL_CreateSurface (8, 8, SDL_PIXELFORMAT_RGBA32);
   if Canvas = null then
      Assert (False, "SDL should provide a surface");
      Finish;
      return;
   end if;

   Renderer := SDL_CreateSoftwareRenderer (Canvas);
   if Renderer = null then
      Assert (False, "SDL should provide a software renderer");
      Finish;
      return;
   end if;

   Test_Context_Owns_A_Cache;
   Test_Destroy_Releases_Textures;
   Test_Advance_Frame_Threads_Through;

   Test_Raster_Scale_Mode_Is_Keyed;
   Test_Shadow_Is_Cached_And_Charged;
   Test_Distinct_Shapes_Are_Distinct_Entries;
   Test_Budget_Retains_Idle_Shadows;

   SDL_DestroyRenderer (Renderer);
   SDL_DestroySurface (Canvas);

   Test_Window_Budget_Is_Per_Window;
   Test_Only_Drawn_Frames_Age_The_Cache;

   Finish;
end Render_Textures_Test;
