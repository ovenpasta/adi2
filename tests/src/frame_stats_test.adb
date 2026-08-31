pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.SDL;           use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Label;  use type Adi.Widget.Label.Label_Handle;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Window;        use Adi.Window;
with Test_Support;      use Test_Support;

--  Frame_Stats is what an application, and the MCP perf_stats command,
--  read a frame's work through. The second frame here reaches all three
--  style-cache layers -- a style nothing has resolved before runs the
--  cascade, a second widget carrying an already-resolved one answers
--  from the memo, and drawing re-reads what the widget itself holds --
--  so a snapshot that crossed two of them would not add up.
--
--  The window captures the counters after the draw, so the snapshot is
--  the whole frame: with nothing else touching a widget between the
--  capture and the reset that opens the next frame, each figure is the
--  counter itself.

procedure Frame_Stats_Test is

   procedure Ensure_SDL (Ready : out Boolean) is
      Ok : Adi.SDL.C_bool;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Assert (Ready, "SDL_Init (video|events) succeeds");
      if Ready then
         Ok := Adi.SDL.TTF.TTF_Init;
         Ready := Boolean (Ok);
         Assert (Ready, "TTF_Init succeeds");
      end if;
   end Ensure_SDL;

   Shared : constant Widget_Style :=
     From ((Display        => Set (Flex),
            Flex_Direction => Set (Column),
            Color          => Set (RGB (17, 19, 23)),
            others         => <>)).Build;

   Root : constant Adi.Widget.Box.Box_Handle :=
     Adi.Widget.Box.Create_Handle;

   procedure Build_Tree is
   begin
      Set_Part_Style (+Root, Main_Part, Shared);
      for I in 1 .. 8 loop
         declare
            L : constant Adi.Widget.Label.Label_Handle :=
              Adi.Widget.Label.Create_Handle ("row" & I'Image);
         begin
            Set_Part_Style (+L, Main_Part, Shared);
            Adi.Widget.Box.Add_Child (Root, +L);
         end;
      end loop;
   end Build_Tree;

   --  A style no earlier frame resolved, so this frame runs the cascade.
   procedure Add_Fresh_Row is
      Fresh : constant Widget_Style :=
        From ((Color     => Set (RGB (211, 5, 97)),
               Font_Size => Set_Font (Px (13.0)),
               others    => <>)).Build;
      L : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("fresh");
   begin
      Set_Part_Style (+L, Main_Part, Fresh);
      Adi.Widget.Box.Add_Child (Root, +L);
   end Add_Fresh_Row;

   Ready : Boolean;

begin
   Start_Suite ("Frame Stats Test");

   Ensure_SDL (Ready);
   if not Ready then
      Finish;
      return;
   end if;

   Build_Tree;

   declare
      Win : Window_Handle :=
        Create_Window_Handle ("Frame Stats", (320.0, 240.0));
   begin
      Set_Root (Win, +Root);
      Render (Win);

      Add_Fresh_Row;
      Render (Win);

      declare
         Stats : constant Frame_Stats := Get_Frame_Stats (Win);
      begin
         Section ("Frame_Stats carries the per-frame counters");

         Assert (Stats.Frame_No = 2, "two frames were drawn");
         Assert (Stats.Style_Resolves > 0, "the frame resolved styles");
         Assert (Stats.Layout_Calls > 0, "the frame laid widgets out");
         Assert (Stats.Pref_Calls > 0, "the frame measured widgets");
         Assert (Stats.Pref_Hits <= Stats.Pref_Calls,
                 "a preferred-size hit is one of the calls");

         --  The snapshot closes the frame, so each figure is the counter
         --  it came from. A field wired to another counter shows up here.
         Assert (Stats.Style_Resolves = Get_Perf_Style_Resolves,
                 "style resolves are the counter, drawing included");
         Assert (Stats.Style_Hits = Get_Perf_Style_Hits,
                 "per-widget cache hits are the counter");
         Assert (Stats.Style_Memo_Hits = Get_Perf_Style_Memo_Hits,
                 "memo hits are the counter");
         Assert (Stats.Style_Computes = Get_Perf_Style_Computes,
                 "cascade runs are the counter");
         Assert (Stats.Layout_Calls = Get_Perf_Layout_Calls,
                 "layout calls are the counter");
         Assert (Stats.Layout_Skips = Get_Perf_Layout_Skips,
                 "layout skips are the counter");
         Assert (Stats.Pref_Calls = Get_Perf_Pref_Calls,
                 "preferred-size calls are the counter");
         Assert (Stats.Pref_Hits = Get_Perf_Pref_Hits,
                 "preferred-size hits are the counter");
         Assert (Stats.Selector_Memo_Hits = Get_Perf_Selector_Memo_Hits,
                 "selector memo hits are the counter");
         Assert (Stats.Selector_Memo_Misses = Get_Perf_Selector_Memo_Misses,
                 "selector memo misses are the counter");

         Section ("The three style layers partition the resolve calls");

         Assert (Stats.Style_Hits > 0, "the per-widget cache answered");
         Assert (Stats.Style_Memo_Hits > 0, "the memo answered");
         Assert (Stats.Style_Computes > 0, "the cascade ran");
         Assert (Stats.Style_Hits + Stats.Style_Memo_Hits
                   + Stats.Style_Computes = Stats.Style_Resolves,
                 "hits, memo hits and cascade runs add up to the calls");
      end;

      Destroy (Win);
   end;

   Finish;
end Frame_Stats_Test;
