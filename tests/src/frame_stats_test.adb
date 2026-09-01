pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;   use Ada.Text_IO;
with Adi.SDL;           use Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Label;  use type Adi.Widget.Label.Label_Handle;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Window;        use Adi.Window;
with Adi.Window.Testing;
with Test_Support;      use Test_Support;

--  Frame_Stats is what an application, and the MCP perf_stats command,
--  read a frame's work through. The second frame here reaches all three
--  style-cache layers -- a style nothing has resolved before runs the
--  cascade, a second widget carrying an already-resolved one answers
--  from the memo, and drawing re-reads what the widget itself holds --
--  so a snapshot that crossed two of them would not add up.
--
--  A frame's counters open where the frame before it closed, so the
--  snapshot covers the work done between two draws as well as the
--  update, layout and draw of the frame itself. That is what puts a
--  state change -- the two resolves per part a widget's own
--  Widget_State_Style_Effect runs, the most expensive style work the
--  library does -- inside the frame that draws its result, where a
--  window that reset at its own draw counted it and then wiped it.

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
            others         => <>))
       .On_Hover ((Color => Set (RGB (23, 19, 17)), others => <>))
       .Build;

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

   Win    : Window_Handle;
   Closes : Natural := 0;

   --  Runs where a frame closes: the snapshot has been taken and the
   --  counters have not reset yet, so each field of Frame_Stats stands
   --  beside the counter it is fed from. A field wired to another
   --  counter shows up here, and nowhere else -- perf_stats carries
   --  these onward to MCP, where a mis-wire reads as a plausible wrong
   --  number rather than as a failure.
   procedure Hold_Fields_To_Counters is
      Stats : constant Frame_Stats := Get_Frame_Stats (Win);
   begin
      Closes := Closes + 1;

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
   end Hold_Fields_To_Counters;

begin
   Start_Suite ("Frame Stats Test");

   Ensure_SDL (Ready);
   if not Ready then
      Finish;
      return;
   end if;

   Build_Tree;

   declare
   begin
      Win := Create_Window_Handle ("Frame Stats", (320.0, 240.0));
      Set_Root (Win, +Root);
      Render (Win);

      Assert (Get_Perf_Style_Resolves = 0
                and then Get_Perf_Style_Hits = 0
                and then Get_Perf_Style_Memo_Hits = 0
                and then Get_Perf_Style_Computes = 0
                and then Get_Perf_Layout_Calls = 0
                and then Get_Perf_Layout_Skips = 0
                and then Get_Perf_Pref_Calls = 0
                and then Get_Perf_Pref_Hits = 0
                and then Get_Perf_Selector_Memo_Hits = 0
                and then Get_Perf_Selector_Memo_Misses = 0,
              "a drawn frame closes every counter behind it");

      Add_Fresh_Row;

      Section ("Each Frame_Stats field is fed from its own counter");

      Adi.Window.Testing.At_Frame_Close
        (Hold_Fields_To_Counters'Unrestricted_Access);
      Render (Win);
      Adi.Window.Testing.At_Frame_Close (null);

      Assert (Closes = 1,
              "the frame closed once, and held its fields to the counters "
              & "there");

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

         Section ("The three style layers partition the resolve calls");

         Assert (Stats.Style_Hits > 0, "the per-widget cache answered");
         Assert (Stats.Style_Memo_Hits > 0, "the memo answered");
         Assert (Stats.Style_Computes > 0, "the cascade ran");
         Assert (Stats.Style_Hits + Stats.Style_Memo_Hits
                   + Stats.Style_Computes = Stats.Style_Resolves,
                 "hits, memo hits and cascade runs add up to the calls");
      end;

      --  Two frames over one tree, alike in everything the frame itself
      --  does: both find the root render-dirty and rebuild its items,
      --  both lay out and draw the same widgets. One of them is preceded
      --  by a state change, and the two resolves that change runs are
      --  the whole of the difference.
      Section ("A frame carrying a state change costs more than one "
               & "that does not");

      declare
         Plain, Changed : Frame_Stats;
      begin
         Mark_Render_Dirty (+Root);
         Render (Win);
         Plain := Get_Frame_Stats (Win);

         Set_State (+Root, State_Hovered, True);
         Render (Win);
         Changed := Get_Frame_Stats (Win);

         Put_Line ("  plain frame:" & Plain.Style_Resolves'Image
                   & " resolves, frame after a state change:"
                   & Changed.Style_Resolves'Image);

         Assert (Changed.Style_Resolves >= Plain.Style_Resolves + 2,
                 "the state change resolves the states the widget left "
                 & "and the states it entered, and the frame counts both");
      end;

      Destroy (Win);
   end;

   Finish;
end Frame_Stats_Test;
