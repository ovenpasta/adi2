pragma Ada_2022;

with Ada.Environment_Variables;
with Adi.Animated_Image;         use Adi.Animated_Image;
with Adi.Animated_Image.Testing; use Adi.Animated_Image.Testing;
with Adi.Assets;
with Adi.Clock;
with Adi.Core;                   use Adi.Core;
with Adi.Image;                  use Adi.Image;
with Adi.Image.Testing;
with Adi.SDL;
with Adi.Texture_Cache;
with Adi.Widget;                 use Adi.Widget;
with Adi.Widget.Animated_Image;
with Adi.Widget.Animated_Widget;
with Adi.Window;
with Test_Support;               use Test_Support;

--  An animated image is named by a handle, not owned by a pointer, and
--  may be drawn by several widgets at once. What that has to guarantee
--  is invisible in the picture, so these look at the machine.

procedure Animated_Image_Test is

   --  Eight frames. Shared with the example rather than copied: it is a
   --  licensed binary and one of it is enough.
   Fixture : constant String := "examples/assets/animhorse.gif";

   use type Adi.Texture_Cache.Event_Count;

   ---------------------------------------------------------------------

   procedure Test_Ownership is
      use type Adi.Clock.Time;
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Anim  : Animation_Handle := Load_From_File (Fixture);
      Copy  : Animation_Handle;
      Gone  : Animation_Handle := Null_Animation_Handle;
      Later : Animation_Handle;
   begin
      Section ("destroying an animation stales every handle to it");

      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      Copy := Anim;
      Assert (Is_Valid (Copy), "a copy names the same animation");
      Assert (Handle_Is_Registered (Copy), "the store has a slot for it");

      Destroy (Anim);
      Assert (Anim = Null_Animation_Handle, "the destroyed handle is null");
      Assert (not Handle_Is_Registered (Copy),
              "The slot is retired, not merely emptied: a record torn"
              & " down in place would leave every copy resolving to it");
      Assert (not Is_Valid (Copy), "so the copy is stale");

      Later := Load_From_File (Fixture);
      Assert (Is_Valid (Later), "a second animation loads");
      Assert (not Is_Valid (Copy),
              "and reusing the slot does not revive the stale handle");

      --  Every result shape has a documented answer for a handle that
      --  names nothing, including the one reporting through out
      --  parameters, which cannot signal by its return.
      Assert (Get_Frame_Count (Copy) = 0, "a stale handle reports no frames");
      Assert (Get_Current_Frame_Index (Copy) = 0, "no current frame");
      Assert (Get_Current_Image (Copy) = Adi.Image.Null_Image_Handle, "nothing to draw");
      Assert (not Is_Playing (Copy) and then not Is_Looping (Copy),
              "and answers no to each ask");
      Assert (not Advance (Copy, 0.1)
              and then not Advance_At (Copy, Base),
              "and does not advance either way");

      declare
         GW, GH : Pixel_Type := 99.0;
      begin
         Get_Size (Copy, GW, GH);
         Assert (GW = 0.0 and then GH = 0.0,
                 "An out parameter is written even so: leaving it alone"
                 & " would hand back whatever the caller had there");
      end;

      Start (Copy);
      Stop (Copy);
      Reset (Copy);
      Set_Looping (Copy, False);

      Destroy (Copy);
      Assert (Copy = Null_Animation_Handle,
              "Destroying a stale handle still nulls it: an early return"
              & " for staleness would leave the caller holding it");
      Destroy (Gone);
      Assert (Gone = Null_Animation_Handle,
              "and destroying a null one is no work at all");

      Destroy (Later);
   end Test_Ownership;

   ---------------------------------------------------------------------

   --  One animation, sampled twice at the same instant. The second
   --  viewer must contribute nothing, or a shared playhead runs at a
   --  multiple of its speed.
   procedure Test_Shared_Playhead is
      use type Adi.Clock.Time;
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Anim  : Animation_Handle := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));
      After_One : Float;
   begin
      Section ("two viewers of one instant charge it once");
      if not Is_Valid (Anim) then
         Assert (False, "the fixture loads");
         return;
      end if;

      Moved := Advance_At (Anim, At_Ms (0));       --  anchors
      Moved := Advance_At (Anim, At_Ms (50));
      After_One := Elapsed_MS (Anim);

      Moved := Advance_At (Anim, At_Ms (50));
      Assert (Elapsed_MS (Anim) = After_One,
              "The same instant again charges nothing, which is what"
              & " keeps a second viewer from doubling the playhead");

      Destroy (Anim);
   end Test_Shared_Playhead;

   ---------------------------------------------------------------------

   --  Resuming must not deliver the pause in one leap, and stepping by
   --  hand must not leave the sampled clock charging for it twice.
   procedure Test_Anchor_Rules is
      use type Adi.Clock.Time;
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Anim  : Animation_Handle := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));
      Was : Natural;
   begin
      Section ("the anchor survives what should not charge time");
      if not Is_Valid (Anim) then
         Assert (False, "the fixture loads");
         return;
      end if;

      Moved := Advance_At (Anim, At_Ms (0));
      Stop (Anim);
      Was := Get_Current_Frame_Index (Anim);

      Moved := Advance_At (Anim, At_Ms (30_000));
      Assert (Get_Current_Frame_Index (Anim) = Was,
              "a stopped animation does not move, however long it waits");

      Start (Anim);
      Moved := Advance_At (Anim, At_Ms (30_100));
      Assert (Get_Current_Frame_Index (Anim) = Was,
              "and resuming re-anchors, so the seconds spent stopped are"
              & " not delivered at once");

      Destroy (Anim);
   end Test_Anchor_Rules;

   ---------------------------------------------------------------------

   --  A cached animation belongs to the cache. Clearing it stales every
   --  handle handed out, rather than leaving one pointing at freed
   --  storage.
   procedure Test_Asset_Invalidation is
      A, B : Animation_Handle;
   begin
      Section ("clearing the cache stales the handles it handed out");

      --  The cache resolves through its own search path, not the
      --  working directory.
      Adi.Assets.Add_Path ("examples/assets");
      A := Adi.Assets.Get_Animated_Image ("animhorse.gif");
      if not Is_Valid (A) then
         Assert (False, "the cache resolves the fixture");
         Adi.Assets.Remove_Path ("examples/assets");
         return;
      end if;

      B := Adi.Assets.Get_Animated_Image ("animhorse.gif");
      Assert (Is_Valid (B), "a second ask resolves too");
      Assert (Handle_Is_Registered (A) and then Handle_Is_Registered (B),
              "and both name a live animation");

      Adi.Assets.Clear_Animated_Image_Cache;

      Assert (not Handle_Is_Registered (A)
              and then not Handle_Is_Registered (B),
              "Clearing retires the slot, so every handle the cache gave"
              & " out is stale rather than dangling");
      Assert (Get_Current_Image (A) = Adi.Image.Null_Image_Handle,
              "and asking one for a frame is answered, not dereferenced");

      Adi.Assets.Remove_Path ("examples/assets");
   end Test_Asset_Invalidation;

   ---------------------------------------------------------------------

   --  The two ways a widget can draw an animated image. They reach it
   --  through different code, so each is pinned on its own: one test
   --  covering both would pass with either broken.
   type Viewer_Kind is (Direct, Through_Backend);

   function Label (K : Viewer_Kind) return String is
     (case K is
         when Direct          => "Adi.Widget.Animated_Image",
         when Through_Backend => "Adi.Widget.Animated_Widget");

   procedure Make_Viewer
     (K    : Viewer_Kind;
      Name : String;
      Anim : Animation_Handle;
      W    : out Adi.Window.Window_Handle;
      Root : out Widget_Handle)
   is
   begin
      W := Adi.Window.Create_Window_Handle (Name, (160.0, 120.0));
      case K is
         when Direct =>
            declare
               B : constant Adi.Widget.Animated_Image.Animated_Image_Handle
                 := Adi.Widget.Animated_Image.Create_Handle;
            begin
               Adi.Widget.Animated_Image.Set_Animation (B, Anim);
               Root := Adi.Widget.Animated_Image.To_Widget_Handle (B);
            end;
         when Through_Backend =>
            declare
               B : constant Adi.Widget.Animated_Widget
                     .Animated_Widget_Handle
                 := Adi.Widget.Animated_Widget.Create_Handle;
            begin
               Adi.Widget.Animated_Widget.Set_Animation (B, Anim);
               Root := Adi.Widget.Animated_Widget.To_Widget_Handle (B);
            end;
      end case;
      Adi.Window.Set_Root (W, Root);
   end Make_Viewer;

   procedure Tick (W : Adi.Window.Window_Handle; DT : Duration) is
      R : constant Adi.Window.Window_Ref := Adi.Window.Borrow (W);
   begin
      Adi.Window.Tick (R.Ptr.all, DT);
   end Tick;

   ---------------------------------------------------------------------

   --  The widgets sample the clock rather than the delta handed to
   --  them, so a delta larger than a frame must move nothing when no
   --  time has actually passed. Reset before each attempt so a whole
   --  frame's worth of time is available: an animation already part way
   --  through one could cross its boundary honestly inside a span the
   --  budget would otherwise accept.
   --
   --  After Reset the clock is unanchored, so the first tick anchors and
   --  the second charges only the span measured here. Code stepping by
   --  the delta moves on the first tick, which is what this catches.
   procedure Test_Shared_Playhead (K : Viewer_Kind) is
      use type Adi.Clock.Time;

      Anim   : Animation_Handle := Load_From_File (Fixture);
      WA, WB : Adi.Window.Window_Handle;
      RA, RB : Widget_Handle;
      Was    : Natural;
      Usable : Boolean := False;
      Span   : Duration := 0.0;
      Budget : Duration := 0.0;
      Step   : Duration;
   begin
      Section (Label (K) & ": two viewers share one playhead");
      if not Is_Valid (Anim) then
         Assert (False, "the fixture loads");
         return;
      end if;
      Set_Looping (Anim, True);

      Make_Viewer (K, "Share A", Anim, WA, RA);
      Make_Viewer (K, "Share B", Anim, WB, RB);

      for Try in 1 .. 8 loop
         Reset (Anim);
         Was := Get_Current_Frame_Index (Anim);
         Step :=
           Duration (Float (Current_Frame_Delay_MS (Anim)) / 1000.0) + 0.050;
         Budget :=
           Duration (Float (Current_Frame_Delay_MS (Anim)) / 4000.0);

         declare
            T0 : constant Adi.Clock.Time := Adi.Clock.Now;
         begin
            Tick (WA, Step);
            Tick (WB, Step);
            Span := Adi.Clock.To_Duration (Adi.Clock.Now - T0);
         end;

         Usable := Budget > 0.0 and then Span < Budget;
         exit when Usable;
      end loop;

      Assert (Usable,
              "both ticks must land well inside one frame for this to"
              & " mean anything: span" & Span'Image & "s against a"
              & " quarter-frame budget of" & Budget'Image & "s");
      if Usable then
         Assert (Get_Current_Frame_Index (Anim) = Was,
                 "A delta larger than a frame moves nothing when no time"
                 & " has passed: the playhead follows the clock, not the"
                 & " deltas, and two viewers of one tick contribute once");
      end if;

      Adi.Window.Destroy (WA);
      Adi.Window.Destroy (WB);
      Destroy (Anim);
   end Test_Shared_Playhead;

   ---------------------------------------------------------------------


   --  Only one viewer gets True from the step that moved the timeline,
   --  so a widget taking that as its cue would leave every other viewer
   --  showing the frame it drew last.
   procedure Test_Both_Viewers_Dirty (K : Viewer_Kind) is
      Anim   : Animation_Handle := Load_From_File (Fixture);
      WA, WB : Adi.Window.Window_Handle;
      RA, RB : Widget_Handle;
   begin
      Section (Label (K) & ": a shared frame change dirties every viewer");
      if not Is_Valid (Anim) then
         Assert (False, "the fixture loads");
         return;
      end if;

      --  Not looping: a pause long enough to lap the animation could
      --  land back on the frame already drawn, and nothing would dirty.
      Set_Looping (Anim, False);

      Make_Viewer (K, "Dirty A", Anim, WA, RA);
      Make_Viewer (K, "Dirty B", Anim, WB, RB);

      Tick (WA, 0.010);
      Tick (WB, 0.010);
      Adi.Window.Render (WA);
      Adi.Window.Render (WB);

      Assert (not Is_Dirty (RA) and then not Is_Dirty (RB),
              "Both start clean, having just drawn: otherwise what"
              & " follows would hold with no frame change at all");

      --  Real time, because the frame has to actually change.
      delay 0.150;
      Tick (WA, 0.010);
      Tick (WB, 0.010);

      Assert (Is_Dirty (RA),
              "the viewer whose tick moved the timeline redraws");
      Assert (Is_Dirty (RB),
              "and so does the one whose tick moved nothing, because the"
              & " frame it drew is no longer the current one");

      Adi.Window.Destroy (WA);
      Adi.Window.Destroy (WB);
      Destroy (Anim);
   end Test_Both_Viewers_Dirty;

   ---------------------------------------------------------------------

   --  Frames must join the animation's group as they are created, and
   --  destruction must release it, or the textures made from them
   --  linger in every renderer until something else evicts them.
   procedure Test_Group_Release_Across_Contexts is
      Anim   : Animation_Handle := Load_From_File (Fixture);
      WA, WB : Adi.Window.Window_Handle;
      RA, RB : Widget_Handle;

      function Rasters (W : Adi.Window.Window_Handle) return Natural is
        (Adi.Window.Get_Texture_Stats (W).By_Kind
           (Adi.Texture_Cache.Raster_Texture).Count);

      function Released (W : Adi.Window.Window_Handle)
                         return Adi.Texture_Cache.Event_Count is
        (Adi.Window.Get_Texture_Stats (W).By_Kind
           (Adi.Texture_Cache.Raster_Texture).Released);

      Was_A, Was_B : Natural;
      Rel_A, Rel_B : Adi.Texture_Cache.Event_Count;
      Drawn        : Adi.Image.Image_Handle;
   begin
      Section ("destroying an animation frees its frames in every renderer");
      if not Is_Valid (Anim) then
         Assert (False, "the fixture loads");
         return;
      end if;

      Make_Viewer (Direct, "Group A", Anim, WA, RA);
      Make_Viewer (Direct, "Group B", Anim, WB, RB);

      Tick (WA, 0.010);
      Tick (WB, 0.010);
      Adi.Window.Render (WA);
      Adi.Window.Render (WB);

      Was_A := Rasters (WA);
      Was_B := Rasters (WB);
      Assert (Was_A > 0 and then Was_B > 0,
              "each renderer made a texture of the frame it drew");

      Rel_A := Released (WA);
      Rel_B := Released (WB);

      --  Both widgets stay attached and keep the handles they drew
      --  through. Nothing detaches: the animation owns its frames, so
      --  destroying it is allowed to happen under viewers.
      Drawn := Get_Current_Image (Anim);
      Assert (Adi.Image.Testing.Handle_Is_Registered (Drawn),
              "the frame both widgets drew is a live image");

      Destroy (Anim);

      Assert (not Adi.Image.Testing.Handle_Is_Registered (Drawn),
              "Destroying the animation ends its frames, so what the"
              & " render items still name is a stale handle rather than"
              & " a pointer into freed storage");
      Assert (not Adi.Image.Is_Valid (Drawn),
              "and it has nothing to draw");

      --  Forced rather than dirtied: marking the widgets dirty would
      --  rebuild their items and replace the very handles under test.
      declare
         RefA : constant Adi.Window.Window_Ref := Adi.Window.Borrow (WA);
         RefB : constant Adi.Window.Window_Ref := Adi.Window.Borrow (WB);
      begin
         Adi.Window.Request_Redraw (RefA.Ptr.all);
         Adi.Window.Request_Redraw (RefB.Ptr.all);
      end;
      Adi.Window.Render (WA);
      Adi.Window.Render (WB);

      Assert (Rasters (WA) = 0 and then Rasters (WB) = 0,
              "Destroying takes its frames from every renderer that held"
              & " them, not merely the last");
      Assert (Released (WA) = Rel_A + Adi.Texture_Cache.Event_Count (Was_A)
              and then Released (WB)
                       = Rel_B + Adi.Texture_Cache.Event_Count (Was_B),
              "exactly what each held, counted as released with its group"
              & " rather than as anything else");

      Adi.Window.Destroy (WA);
      Adi.Window.Destroy (WB);
   end Test_Group_Release_Across_Contexts;

   ---------------------------------------------------------------------

   --  Invalidate is a separate branch from clearing the whole cache.
   procedure Test_Invalidate_Stales is
      H : Animation_Handle;
   begin
      Section ("invalidating one path stales the handles for it");

      Adi.Assets.Add_Path ("examples/assets");
      H := Adi.Assets.Get_Animated_Image ("animhorse.gif");
      if not Is_Valid (H) then
         Assert (False, "the cache resolves the fixture");
         Adi.Assets.Remove_Path ("examples/assets");
         return;
      end if;
      Assert (Handle_Is_Registered (H), "and the handle names it");

      Adi.Assets.Invalidate ("animhorse.gif");

      Assert (not Handle_Is_Registered (H),
              "Invalidating retires the slot, so the handle it gave out"
              & " is stale rather than dangling");
      Adi.Assets.Remove_Path ("examples/assets");
   end Test_Invalidate_Stales;

   ---------------------------------------------------------------------

   --  Playback_Clock pins the rule; these pin that this package applies
   --  it at the three call sites that must.
   procedure Test_Reanchor_Call_Sites is
      use type Adi.Clock.Time;
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Anim  : Animation_Handle := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));
      Was : Natural;
   begin
      Section ("stepping by hand and resetting both re-anchor");
      if not Is_Valid (Anim) then
         Assert (False, "the fixture loads");
         return;
      end if;
      Set_Looping (Anim, True);

      Moved := Advance_At (Anim, At_Ms (0));       --  anchors here
      Was := Get_Current_Frame_Index (Anim);

      --  A step by hand moves the timeline without the clock knowing.
      Moved := Advance (Anim, 0.150);
      Assert (Get_Current_Frame_Index (Anim) /= Was, "the step moves it");
      Was := Get_Current_Frame_Index (Anim);

      --  Had Advance not re-anchored, this would charge the whole gap.
      Moved := Advance_At (Anim, At_Ms (10_000));
      Assert (Get_Current_Frame_Index (Anim) = Was,
              "and the next sample anchors rather than charging the ten"
              & " seconds since the last one");

      Reset (Anim);
      Was := Get_Current_Frame_Index (Anim);
      Moved := Advance_At (Anim, At_Ms (20_000));
      Assert (Get_Current_Frame_Index (Anim) = Was,
              "and a reset re-anchors the same way");

      Destroy (Anim);
   end Test_Reanchor_Call_Sites;

   --  A step far outside what a frame clock produces. Walking it one
   --  frame delay at a time takes unbounded iterations, and once the
   --  ratio passes 2**24 the subtraction stops moving a Float at all.
   procedure Test_Extreme_Step is
      Anim  : Animation_Handle := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
   begin
      Section ("a step far outside a frame clock's range");
      if not Is_Valid (Anim) then
         Assert (False, "the fixture loads");
         return;
      end if;

      Set_Looping (Anim, True);
      Start (Anim);

      Moved := Advance (Anim, 1.0e9);
      Assert (Elapsed_MS (Anim) >= 0.0
                and then Elapsed_MS (Anim) < 10_000.0,
              "A billion seconds leaves the playhead inside one cycle --"
              & " eight frames of a GIF run in well under ten seconds --"
              & " got" & Float'Image (Elapsed_MS (Anim)));
      Assert (Get_Current_Frame_Index (Anim)
                in 1 .. Get_Frame_Count (Anim),
              "and on a frame that exists");

      --  A step backwards leaves the playhead where the next honest
      --  step can still charge from it.
      Reset (Anim);
      Moved := Advance (Anim, -1.0);
      Assert (Elapsed_MS (Anim) >= 0.0,
              "A backwards step does not park the playhead before the"
              & " start, got" & Float'Image (Elapsed_MS (Anim)));

      Destroy (Anim);
   end Test_Extreme_Step;

begin
   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   Start_Suite ("Animated image test");

   if not Boolean (Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO)) then
      Assert (False, "SDL_Init(video) should succeed");
      Finish;
      return;
   end if;

   Test_Ownership;
   Test_Shared_Playhead;
   Test_Anchor_Rules;
   Test_Asset_Invalidation;
   Test_Group_Release_Across_Contexts;
   Test_Invalidate_Stales;
   Test_Reanchor_Call_Sites;
   Test_Extreme_Step;

   for K in Viewer_Kind loop
      Test_Shared_Playhead (K);
      Test_Both_Viewers_Dirty (K);
   end loop;

   Finish;
end Animated_Image_Test;
