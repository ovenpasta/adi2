pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.SDL;             use Adi.SDL;
with Adi.SDL.Render;      use Adi.SDL.Render;
with Adi.SDL.Surface;     use Adi.SDL.Surface;
with Adi.SDL.PixelFormat; use Adi.SDL.PixelFormat;
with Adi.Clock;
with Adi.Render;
with Adi.Texture_Cache;
with Adi.Window;
with Test_Support;        use Test_Support;

--  The texture cache belongs to a render context, because the textures in
--  it belong to that context's renderer. This covers the wiring: that a
--  context has a cache with a budget, that only drawn frames age it, and
--  that two windows hold two independent caches rather than sharing one.
--
--  Nothing is migrated into the cache yet, so what is stored here is stored
--  by the test.

procedure Render_Textures_Test is

   use type Adi.Texture_Cache.Byte_Count;
   use type Adi.Texture_Cache.Frame_Count;
   use type Adi.Texture_Cache.Texture_Handle;

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

   SDL_DestroyRenderer (Renderer);
   SDL_DestroySurface (Canvas);

   Test_Window_Budget_Is_Per_Window;
   Test_Only_Drawn_Frames_Age_The_Cache;

   Finish;
end Render_Textures_Test;
