pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;  use Ada.Text_IO;
with Adi.SDL;      use Adi.SDL;
with Adi.SDL.TTF;
with Adi.App;
with Adi.Window;   use Adi.Window;
with Adi.Widget.Box;
with Test_Support;

--  Destroying the window from a Tick callback does not take effect at
--  once: Tick runs under a dispatch guard, so the destroy is queued and
--  the window stays valid for the rest of that frame -- Render still
--  runs against it. Pump_Window_Store at the top of the next frame
--  carries the destroy out, and the check after it ends the loop.
--
--  What this pins is that the queued destroy is pumped before another
--  Tick, so the callback fires exactly once. Holding a borrow across the
--  run defers the destroy past that pump: the window stays alive, Tick
--  keeps firing, and the loop keeps driving it.
--
--  It does not pin that every check re-resolves the handle. SDL posts
--  SDL_EVENT_QUIT when the last window closes, so a second window is
--  kept open here to stop that path from ending the run instead.
procedure App_Loop_Test is

   A          : Adi.App.App;
   Main       : Window_Handle := Null_Window_Handle;
   --  A second window stays open for the whole run. Without it SDL
   --  posts SDL_EVENT_QUIT when the last window closes, and the loop
   --  would end through that instead of through the check under test.
   Keep_Alive : Window_Handle := Null_Window_Handle;
   Ticks      : Natural := 0;
   Destroyed  : Boolean := False;

   --  Destroys the main window from inside a per-frame callback, which
   --  is where an application would close its own window.
   procedure Destroy_From_Tick (DT : Duration) is
      pragma Unreferenced (DT);
   begin
      Ticks := Ticks + 1;
      if Ticks = 1 then
         Destroy (Main);
         Destroyed := True;
      end if;
   end Destroy_From_Tick;

   procedure Ensure_SDL_Initialized (Ready : out Boolean) is
      Ok     : Adi.SDL.C_bool;
      Ttf_Ok : Adi.SDL.C_bool;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Test_Support.Assert (Ready, "SDL_Init(video|events) should succeed");
      if Ready then
         Ttf_Ok := Adi.SDL.TTF.TTF_Init;
         Ready := Boolean (Ttf_Ok);
         Test_Support.Assert (Ready, "TTF_Init should succeed");
      end if;
   end Ensure_SDL_Initialized;

   Ready : Boolean;

begin
   Test_Support.Start_Suite ("App Loop Test");
   Ensure_SDL_Initialized (Ready);
   if not Ready then
      Test_Support.Finish;
      return;
   end if;

   A.Init;
   Keep_Alive := Create_Window_Handle ("Keep Alive", (160.0, 120.0));
   Main := Create_Window_Handle ("App Loop", (320.0, 240.0));
   Set_Root (Main, Adi.Widget.Box."+" (Adi.Widget.Box.Create_Handle));
   Connect_Tick (Main, Destroy_From_Tick'Unrestricted_Access);
   A.Add_Window (Main);

   A.Run;

   Test_Support.Assert (Destroyed, "the tick callback ran and destroyed");
   Test_Support.Assert (Ticks = 1,
                        "the queued destroy was pumped before another tick");
   Test_Support.Assert (not Is_Valid (Main),
                        "the loop left the window handle stale");
   Test_Support.Assert (Is_Valid (Keep_Alive),
                        "the other window was untouched");
   Destroy (Keep_Alive);

   Test_Support.Finish;
end App_Loop_Test;
