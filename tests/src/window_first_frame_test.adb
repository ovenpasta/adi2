pragma Ada_2022;

with Ada.Exceptions;
with Interfaces.C;         use Interfaces.C;
with Adi.App;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.SDL;
with Adi.SDL.Events;
with Adi.SDL.Render;       use Adi.SDL.Render;
with Adi.SDL.Surface;      use Adi.SDL.Surface;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget_Styles;    use Adi.Widget_Styles;
with Adi.Window;           use Adi.Window;
with Test_Support;         use Test_Support;

--  The first frame a new window draws covers the whole window, whichever
--  constructor made it. Read back before present, so no later frame can
--  stand in for it.
--
--  A renderer made at a window's 100x100 bootstrap size drew its first
--  frame into that corner: under the dummy driver with SDL 3.2, and under
--  SDL_VIDEODRIVER=offscreen SDL_RENDER_DRIVER=opengles2, where SDL 3.4
--  shows it too. Run it under both where EGL is at hand.

procedure Window_First_Frame_Test is
   use type Adi.SDL.Uint8;
   use type Adi.Widget.Box.Box_Handle;

   App : Adi.App.App;

   Fill_R : constant := 41;
   Fill_G : constant := 73;
   Fill_B : constant := 109;

   type Creation_Kind is
     (Coordinates, Px_Extent, Pct_Extent, Maximized_Extent);

   Inspected : Natural := 0;

   procedure Inspect (Win : Window_Handle; Renderer : SDL_Renderer_Ptr) is
      Surface : SDL_Surface_Ptr := null;
      Out_W, Out_H : aliased int := 0;

      procedure Check (X, Y : int) is
         R, G, B, A : aliased Adi.SDL.Uint8 := 0;
         Read : constant Boolean := Boolean
           (SDL_ReadSurfacePixel
              (Surface, X, Y, R'Access, G'Access, B'Access, A'Access));
      begin
         Assert (Read and then R = Fill_R and then G = Fill_G
                 and then B = Fill_B,
                 "pixel" & X'Image & "," & Y'Image & " is the fill (got"
                 & R'Image & G'Image & B'Image & " )");
      end Check;
   begin
      Inspected := Inspected + 1;
      if Inspected > 1 then
         return;
      end if;
      Assert (Get_Frame_Stats (Win).Frame_No = 1, "this is the first frame");
      if not Boolean (SDL_GetRenderOutputSize
                        (Renderer, Out_W'Access, Out_H'Access))
      then
         Assert (False, "the output size can be read");
         return;
      end if;
      Surface := SDL_RenderReadPixels (Renderer, null);
      Assert (Surface /= null, "the first frame can be read back");
      if Surface = null then
         return;
      end if;
      Assert (Surface.w = Out_W and then Surface.h = Out_H,
              "the read covers the whole output");
      Assert (Surface.w > 100 and then Surface.h > 100,
              "the window is past the 100x100 bootstrap");
      Check (1, 1);
      Check (Surface.w - 2, 1);
      Check (Surface.w / 2, Surface.h / 2);
      Check (1, Surface.h - 2);
      Check (Surface.w - 2, Surface.h - 2);
      SDL_DestroySurface (Surface);
   end Inspect;

   procedure Check_First_Frame (Kind : Creation_Kind) is
      Win  : Window_Handle := Null_Window_Handle;
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Event : aliased Adi.SDL.Events.SDL_Event;
   begin
      Section (Kind'Image);
      Win :=
        (case Kind is
            when Coordinates =>
              Create_Window_Handle ("First frame", (360.0, 200.0)),
            when Px_Extent =>
              Create_Window_Handle
                ("First frame", Extent (Px (360.0), Px (200.0))),
            when Pct_Extent =>
              Create_Window_Handle
                ("First frame", Extent (Pct (50.0), Pct (50.0))),
            when Maximized_Extent =>
              Create_Window_Handle
                ("First frame", Extent (Px (360.0), Px (200.0)),
                 Maximized => True));
      Set_Part_Style
        (+Root, Main_Part,
         From ((Display          => Set (Flex),
                Background_Color => Set_Bg (RGB (Fill_R, Fill_G, Fill_B)),
                others           => <>)).Build);
      Set_Root (Win, +Root);
      Connect_Post_Render (Win, Inspect'Unrestricted_Access);
      while Adi.SDL.Events.SDL_PollEvent (Event'Access) loop
         null;
      end loop;
      Inspected := 0;
      declare
         Ref : constant Window_Ref := Borrow (Win);
      begin
         Render (Ref.Ptr.all);
      end;
      Assert (Inspected = 1, "the first frame reached the inspection");
      Destroy (Win);
   exception
      when Error : others =>
         Assert (False, Ada.Exceptions.Exception_Information (Error));
         Destroy (Win);
   end Check_First_Frame;

begin
   Start_Suite ("Window First Frame Test");
   App.Init;
   for Kind in Creation_Kind loop
      Check_First_Frame (Kind);
   end loop;
   Finish;
end Window_First_Frame_Test;
