pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Text_IO;                        use Ada.Text_IO;
with Adi.Clock;
with Adi.Core;                           use Adi.Core;
with Adi.Image;
with Adi.Image.Testing;
with Adi.RLottie;                        use Adi.RLottie;
with Adi.RLottie.Testing;                use Adi.RLottie.Testing;
with Adi.SDL;
with Adi.Texture_Cache;
with Adi.Widget;                         use Adi.Widget;
with Adi.Widget.Animated_Widget;
with Adi.Widget.Animated_Widget.RLottie;
with Adi.Widget.Box;
with Adi.Widget.RLottie;
with Adi.Widget_Styles;              use Adi.Widget_Styles;
with Adi.CSS_Styles;                 use Adi.CSS_Styles;
with Adi.Window;
with Test_Support;                       use Test_Support;

--  Two widgets draw rlottie animations, and each has to tell the
--  animation what pixel extent it will be drawn at. Nothing in the
--  frames shows whether it did: an animation never told rasterises
--  nothing and simply draws blank, which no assertion about the picture
--  distinguishes from a widget that is merely empty. These look at what
--  the widget asked the animation for.

procedure RLottie_Widget_Test is

   Fixture : constant String := "tests/assets/tiny_anim.json";

   --  Every wait is bounded: a state machine that never settles must
   --  fail the suite rather than hang it.
   Deadline : constant := 400;   --  × 5 ms

   --  One frame of the application loop: a tick then a render, in that
   --  order, which is what App.Run does. Rendering alone never asks the
   --  animation for a frame, so a helper that only rendered would wait
   --  for something nothing was going to do.
   procedure Step_Frame
     (W : Adi.Window.Window_Handle; DT : Duration := 0.005) is
      R : constant Adi.Window.Window_Ref := Adi.Window.Borrow (W);
   begin
      Adi.Window.Tick (R.Ptr.all, DT);
      Adi.Window.Render (W);
   end Step_Frame;

   --  Steps until the widget has told the animation what extent it
   --  occupies and a frame at that extent exists.
   procedure Pump
     (W    : Adi.Window.Window_Handle;
      Anim : Animation_Handle)
   is
   begin
      for I in 1 .. Deadline loop
         Step_Frame (W);
         if Is_Valid (Anim) then
            Service (Anim);
            exit when Is_Prepared (Anim);
         end if;
         delay 0.005;
      end loop;
   end Pump;

   --  Steps until frames are being rasterised at the given height. A
   --  resize has to stand still before it is taken up, so this crosses
   --  that interval rather than assuming one render does.
   procedure Pump_Until_Height
     (W      : Adi.Window.Window_Handle;
      Anim   : Animation_Handle;
      Height : Natural)
   is
      PW, PH : Natural;
   begin
      for I in 1 .. Deadline loop
         Step_Frame (W);
         Service (Anim);
         Prepared_Extent (Anim, PW, PH);
         exit when PH = Height;
         delay 0.005;
      end loop;
   end Pump_Until_Height;

   ---------------------------------------------------------------------------

   --  The direct widget. Its Build_Items is a different call site from
   --  the animated widget's, so it needs its own animation and its own
   --  assertion: one covering both would pass with either broken.
   procedure Test_RLottie_Widget_Prepares is
      W    : Adi.Window.Window_Handle;
      Box  : Adi.Widget.RLottie.RLottie_Handle;
      Anim : Animation_Handle := Null_Animation_Handle;
   begin
      Section ("Adi.Widget.RLottie asks at its own extent");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("RLottie Widget", (200.0, 200.0));
      Box := Adi.Widget.RLottie.Create_Handle (Anim);
      Adi.Widget.RLottie.Set_Max_Size (Box, 64.0, 48.0);
      Adi.Window.Set_Root (W, Adi.Widget.RLottie.To_Widget_Handle (Box));

      Pump (W, Anim);

      Assert (Rasterisations (Anim) = 1,
              "Rendering rasterises exactly the frame on screen: never is"
              & " a blank widget, and the rest of the animation is not"
              & " wanted until playback reaches it");
      Assert (Is_Prepared (Anim), "and leaves it drawable");

      declare
         PW, PH : Natural;
      begin
         Prepared_Extent (Anim, PW, PH);
         Assert (PW > 0 and then PH > 0,
                 "at a real extent");
         --  The widget is the root of a 200 by 200 window and stretches
         --  to it, so that is the extent it draws at and the extent its
         --  frames must be rasterised at -- not the file's own 8 by 8,
         --  and not the measurement bound, which constrains only how
         --  large the widget asks to be when something else decides.
         Assert (PW = 200 and then PH = 200,
                 "at exactly the extent the widget occupies");
      end;

      Adi.Window.Destroy (W);
      Destroy (Anim);
   end Test_RLottie_Widget_Prepares;

   ---------------------------------------------------------------------------

   procedure Test_Animated_Widget_Prepares is
      W    : Adi.Window.Window_Handle;
      Box  : Adi.Widget.Animated_Widget.Animated_Widget_Handle;
      Anim : Animation_Handle := Null_Animation_Handle;
   begin
      Section ("Adi.Widget.Animated_Widget asks through its backend");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("Animated Widget", (200.0, 200.0));
      Box := Adi.Widget.Animated_Widget.Create_Handle;
      Adi.Widget.Animated_Widget.RLottie.Set_Animation (Box, Anim);
      Adi.Widget.Animated_Widget.Set_Max_Size (Box, 64.0, 48.0);
      Adi.Window.Set_Root
        (W, Adi.Widget.Animated_Widget.To_Widget_Handle (Box));

      Pump (W, Anim);

      Assert (Rasterisations (Anim) = 1,
              "The backend path rasterises exactly one frame too: it is a"
              & " separate call site and fails separately");
      Assert (Is_Prepared (Anim), "and leaves it drawable");

      declare
         PW, PH : Natural;
      begin
         Prepared_Extent (Anim, PW, PH);
         Assert (PW > 0 and then PH > 0, "at a real extent");
         Assert (PW = 200 and then PH = 200,
                 "at exactly the extent the widget occupies");
      end;

      Adi.Window.Destroy (W);
      Destroy (Anim);
   end Test_Animated_Widget_Prepares;

   ---------------------------------------------------------------------------

   --  Scale is process-global here, so it is restored whatever happens:
   --  a test that raised while it was changed would leave every later
   --  test measuring in the wrong units.
   procedure Test_Scale_Change_Reprepares is
      W     : Adi.Window.Window_Handle;
      Box   : Adi.Widget.RLottie.RLottie_Handle;
      Root  : Adi.Widget.Box.Box_Handle;
      Anim  : Animation_Handle;
      Was_W : Natural := 0;
      Was_H : Natural := 0;
      Was_Frame : Adi.Image.Image_Handle;

      procedure Body_Of_Test is
      begin
         Pump (W, Anim);
         Assert (Rasterisations (Anim) = 1, "one frame at the first scale");
         Prepared_Extent (Anim, Was_W, Was_H);
         Assert (Was_W = 40 and then Was_H = 30,
                 "forty by thirty dip is forty by thirty pixels at unit"
                 & " scale");

         Was_Frame := Get_Current_Image (Anim);
         Assert (Adi.Image.Testing.Handle_Is_Registered (Was_Frame),
                 "the frame of the first extent is a live image");

         --  Same logical geometry, twice the pixels behind it.
         Adi.Window.Set_UI_Scale (W, 2.0);
         Adi.Window.Render (W);

         Assert (Is_Prepared (Anim),
                 "The old extent stays drawable across a scale change,"
                 & " rather than blanking while it re-rasterises");
         declare
            PW, PH : Natural;
         begin
            Prepared_Extent (Anim, PW, PH);
            Assert (PW = Was_W and then PH = Was_H,
                    "and it is still the old one being drawn while the"
                    & " replacement is pending");
         end;

         Pump_Until_Height (W, Anim, 60);

         Assert (not Adi.Image.Testing.Handle_Is_Registered (Was_Frame),
                 "the extent the scale change replaced is ended, so the"
                 & " frame it was drawing is a stale handle now");

         declare
            PW, PH : Natural;
         begin
            Prepared_Extent (Anim, PW, PH);
            Assert (PH = 60,
                    "thirty dip is sixty pixels at double scale, so the"
                    & " frames are rasterised at the size actually drawn");
            Assert (PW = 80,
                    "and forty dip is eighty, both axes following the"
                    & " scale because both are dip lengths");
         end;
      end Body_Of_Test;

   begin
      Section ("a scale change re-prepares at the new physical size");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("RLottie Scale", (200.0, 200.0));
      Box := Adi.Widget.RLottie.Create_Handle (Anim);

      --  Sized in dip rather than stretched to the window: a root widget
      --  filling a window of fixed pixels occupies the same pixels at any
      --  scale, so it could not show a scale change either way.
      declare
         Rules : Style_Rules;
      begin
         Rules.Width := Set (Size (Dip (40.0)));
         Rules.Height := Set (Size (Dip (30.0)));
         Set_Part_Style (Adi.Widget.RLottie.To_Widget_Handle (Box),
                         Main_Part, From (Rules).Build);
      end;

      Root := Adi.Widget.Box.Create_Handle;
      Adi.Widget.Box.Add_Child
        (Root, Adi.Widget.RLottie.To_Widget_Handle (Box));
      Adi.Window.Set_Root (W, Adi.Widget.Box.To_Widget_Handle (Root));

      begin
         Body_Of_Test;
      exception
         when E : others =>
            Assert (False,
                    "the scale test should not raise: "
                    & Ada.Exceptions.Exception_Name (E));
      end;

      --  Restored whether the body succeeded, failed or raised.
      Adi.Window.Set_UI_Scale (W, 1.0);
      Adi.Window.Destroy (W);
      Destroy (Anim);
   end Test_Scale_Change_Reprepares;

   ---------------------------------------------------------------------------

   --  The two ways a widget can draw an rlottie animation. They reach the
   --  animation through different code, so each is asserted on its own:
   --  one test covering both would pass with either broken.
   type Viewer_Kind is (Direct, Through_Backend);

   function Label (Kind : Viewer_Kind) return String is
     (case Kind is
         when Direct          => "Adi.Widget.RLottie",
         when Through_Backend => "Adi.Widget.Animated_Widget");

   procedure Make_Viewer
     (Kind  : Viewer_Kind;
      Title : String;
      Anim  : Animation_Handle;
      W     : out Adi.Window.Window_Handle;
      Root  : out Widget_Handle)
   is
   begin
      W := Adi.Window.Create_Window_Handle (Title, (160.0, 120.0));
      case Kind is
         when Direct =>
            Root := Adi.Widget.RLottie.To_Widget_Handle
                      (Adi.Widget.RLottie.Create_Handle (Anim));
         when Through_Backend =>
            declare
               B : constant Adi.Widget.Animated_Widget
                     .Animated_Widget_Handle :=
                 Adi.Widget.Animated_Widget.Create_Handle;
            begin
               Adi.Widget.Animated_Widget.RLottie.Set_Animation (B, Anim);
               Root := Adi.Widget.Animated_Widget.To_Widget_Handle (B);
            end;
      end case;
      Adi.Window.Set_Root (W, Root);
   end Make_Viewer;

   type Window_Array is
     array (Positive range <>) of Adi.Window.Window_Handle;

   procedure Tick_All (Wins : Window_Array; DT : Duration) is
   begin
      for H of Wins loop
         declare
            R : constant Adi.Window.Window_Ref := Adi.Window.Borrow (H);
         begin
            Adi.Window.Tick (R.Ptr.all, DT);
         end;
      end loop;
   end Tick_All;

   ---------------------------------------------------------------------------

   --  How the measured runs are driven: one anchoring tick, then Steps
   --  more with a real pause before each.
   Steps : constant := 15;
   Step  : constant Duration := 0.010;

   --  What a stepped implementation would have charged the animation for
   --  such a run: every viewer's tick adds its own Step, at each of the
   --  Steps + 1 ticks. A sampled one charges the real span instead, which
   --  is what makes the two distinguishable -- but only when the host
   --  keeps up, and only for more than one viewer.
   function Stepped_Span (Viewers : Positive) return Duration is
     (Step * (Viewers * (Steps + 1)));

   --  Runs one animation under a given number of viewers for a fixed span
   --  of real time, and reports how far its playhead travelled against how
   --  much time actually passed.
   procedure Run_Viewers
     (Kind    : Viewer_Kind;
      Viewers : Positive;
      Played  : out Duration;
      Wall    : out Duration)
   is
      use type Adi.Clock.Time;

      Wins  : Window_Array (1 .. Viewers);
      Root  : Widget_Handle;
      Anim  : Animation_Handle;
      T0    : Adi.Clock.Time;
   begin
      Played := 0.0;
      Wall := 0.0;

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      --  Clamped rather than wrapped. A playhead that has lapped the
      --  timeline reads exactly like one that has not, which would hide
      --  the difference being measured; the span below stays well inside
      --  the fixture's 400 ms so neither happens.
      Set_Looping (Anim, False);

      for I in Wins'Range loop
         Make_Viewer (Kind, "Viewer" & I'Image, Anim, Wins (I), Root);
      end loop;

      Pump (Wins (1), Anim);
      for H of Wins loop
         Adi.Window.Render (H);
      end loop;

      --  The animation has one anchor, not one per viewer. This tick sets
      --  it; the measured span starts after.
      Tick_All (Wins, Step);
      T0 := Adi.Clock.Now;

      for S in 1 .. Steps loop
         delay Step;
         Tick_All (Wins, Step);
      end loop;

      Wall := Adi.Clock.To_Duration (Adi.Clock.Now - T0);
      Played := Elapsed (Anim);

      for H of Wins loop
         Adi.Window.Destroy (H);
      end loop;
      Destroy (Anim);
   end Run_Viewers;

   --  Time passes at one second per second however many widgets are
   --  watching. A widget that stepped the timeline by its own frame delta
   --  would run a shared animation at a multiple of its speed, one
   --  multiple per viewer, and no single-viewer test would notice.
   procedure Test_Shared_Playhead (Kind : Viewer_Kind) is
      Tolerance : constant Duration := 0.050;
      Attempts  : constant := 5;
      Stepped   : constant Duration := Stepped_Span (2);

      One_P, One_W, Two_P, Two_W : Duration;
      Usable : Boolean := False;
   begin
      Section (Label (Kind) & ": viewers share one playhead");

      --  A baseline, not a discriminator: with one viewer a stepped
      --  implementation and a sampled one agree, and both are right.
      Run_Viewers (Kind, 1, One_P, One_W);
      Assert (abs (One_P - One_W) <= Tolerance,
              "One viewer's playhead tracks the clock: played"
              & One_P'Image & "s over" & One_W'Image & "s");

      --  A host slow enough that the real span drifts out to what a
      --  stepped run would have charged makes the two indistinguishable,
      --  and a passing measurement would mean nothing. Take another
      --  sample rather than judge on that one.
      for Try in 1 .. Attempts loop
         Run_Viewers (Kind, 2, Two_P, Two_W);
         Usable := abs (Stepped - Two_W) > Tolerance;
         exit when Usable;
      end loop;

      Assert (Usable,
              "the measurement must be able to tell a stepped playhead"
              & " from a sampled one: a stepped run would have played"
              & Stepped'Image & "s and the real span reached" & Two_W'Image
              & "s, which are not far enough apart to judge");
      if not Usable then
         return;
      end if;

      Assert (abs (Two_P - Two_W) <= Tolerance,
              "and a second viewer of the same animation must not move it"
              & " again: played" & Two_P'Image & "s over" & Two_W'Image
              & "s");
   end Test_Shared_Playhead;

   ---------------------------------------------------------------------------

   --  Only one viewer gets True from the step that moved the timeline, so
   --  a widget that took that return as its cue to redraw would leave
   --  every other viewer showing the frame it drew last.
   procedure Test_Both_Viewers_Dirty (Kind : Viewer_Kind) is
      WA, WB : Adi.Window.Window_Handle;
      RA, RB : Widget_Handle;
      Anim   : Animation_Handle;
   begin
      Section (Label (Kind) & ": a shared frame change dirties every viewer");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;
      Set_Looping (Anim, False);

      Make_Viewer (Kind, "Dirty A", Anim, WA, RA);
      Make_Viewer (Kind, "Dirty B", Anim, WB, RB);

      Pump (WA, Anim);
      Adi.Window.Render (WA);
      Adi.Window.Render (WB);

      Assert (not Is_Dirty (RA) and then not Is_Dirty (RB),
              "Both viewers start clean, having just drawn: otherwise the"
              & " assertion below would hold with no frame change at all");

      --  Past a frame boundary: the fixture runs at 10 fps.
      delay 0.150;
      Tick_All (Window_Array'(WA, WB), 0.150);

      Assert (Is_Dirty (RA),
              "the viewer whose tick moved the timeline redraws");
      Assert (Is_Dirty (RB),
              "and so does the one whose tick moved nothing, because the"
              & " frame it drew is no longer the current one");

      Adi.Window.Destroy (WA);
      Adi.Window.Destroy (WB);
      Destroy (Anim);
   end Test_Both_Viewers_Dirty;

   ---------------------------------------------------------------------------

   --  Two viewers of one animation showing the same frame at the same
   --  extent. The frame is the animation's, not the viewer's, so it is
   --  rasterised once however many windows are drawing it.
   procedure Test_Two_Viewers_Rasterise_Once is
      WA, WB : Adi.Window.Window_Handle;
      RA, RB : Widget_Handle;
      Anim   : Animation_Handle;
      Before : Natural;
   begin
      Section ("two viewers of one frame rasterise it once");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      Make_Viewer (Direct, "Once A", Anim, WA, RA);
      Make_Viewer (Direct, "Once B", Anim, WB, RB);

      Pump (WA, Anim);
      Adi.Window.Render (WB);
      Before := Rasterisations (Anim);
      Assert (Before = 1, "one frame so far");

      --  The widgets sample the clock rather than the delta handed to
      --  them, so the frame moves only when time actually passes.
      delay 0.120;
      Tick_All (Window_Array'(WA, WB), 0.120);
      Adi.Window.Render (WA);
      Adi.Window.Render (WB);

      Assert (Rasterisations (Anim) = Before + 1,
              "The frame they moved to is rasterised once, not once per"
              & " window: what they share is the animation");

      Adi.Window.Destroy (WA);
      Adi.Window.Destroy (WB);
      Destroy (Anim);
   end Test_Two_Viewers_Rasterise_Once;

   ---------------------------------------------------------------------------

   --  A texture evicted under budget pressure is rebuilt by uploading the
   --  surface the frame kept, not by rasterising the frame again. That is
   --  the whole reason the surface is retained.
   procedure Test_Eviction_Uploads_Rather_Than_Rasterises is
      use type Adi.Texture_Cache.Byte_Count;
      use type Adi.Texture_Cache.Event_Count;
      W      : Adi.Window.Window_Handle;
      Root   : Widget_Handle;
      Anim   : Animation_Handle;
      Before : Natural;
      Full_Count, Evicted_Count : Natural;
      Was_Stores : Adi.Texture_Cache.Event_Count;
   begin
      Section ("eviction costs an upload, not a rasterisation");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      Make_Viewer (Direct, "Evict", Anim, W, Root);
      Pump (W, Anim);

      --  Walk the whole animation so every frame is rasterised and every
      --  texture made, then take the textures away.
      for I in 1 .. 12 loop
         delay 0.050;
         Step_Frame (W, 0.050);
      end loop;
      Before := Rasterisations (Anim);
      Assert (Before > 1, "more than one frame has been rasterised");

      --  A budget of nothing evicts everything not being drawn.
      Full_Count := Adi.Window.Get_Texture_Stats (W).By_Kind
                      (Adi.Texture_Cache.Raster_Texture).Count;
      Was_Stores := Adi.Window.Get_Texture_Stats (W).By_Kind
                      (Adi.Texture_Cache.Raster_Texture).Stores;

      Adi.Window.Set_Texture_Budget (W, 0);
      delay 0.050;
      Step_Frame (W, 0.050);
      Evicted_Count := Adi.Window.Get_Texture_Stats (W).By_Kind
                         (Adi.Texture_Cache.Raster_Texture).Count;
      Assert (Evicted_Count < Full_Count,
              "and the renderer has given most of them up");

      Adi.Window.Set_Texture_Budget
        (W, Adi.Texture_Cache.Byte_Count (64 * 1024 * 1024));
      for I in 1 .. 12 loop
         delay 0.050;
         Step_Frame (W, 0.050);
      end loop;

      Assert (Rasterisations (Anim) = Before,
              "Drawing them all again rasterises nothing: a frame that"
              & " lost its texture still has the pixels it was made from");
      Assert (Adi.Window.Get_Texture_Stats (W).By_Kind
                (Adi.Texture_Cache.Raster_Texture).Count = Full_Count,
              "and every texture that was evicted is back");
      Assert (Adi.Window.Get_Texture_Stats (W).By_Kind
                (Adi.Texture_Cache.Raster_Texture).Stores > Was_Stores,
              "having been uploaded again, which is what the retained"
              & " pixels are for");

      Adi.Window.Destroy (W);
      Destroy (Anim);
   end Test_Eviction_Uploads_Rather_Than_Rasterises;

   ---------------------------------------------------------------------------

   --  Replacing an extent has to take that extent's textures out of every
   --  renderer that made one, and must not leave another window drawing
   --  through a handle to what it replaced.
   procedure Test_Resize_Releases_And_Does_Not_Dangle is
      use type Adi.Texture_Cache.Event_Count;

      WA, WB : Adi.Window.Window_Handle;
      RA, RB : Widget_Handle;
      Anim   : Animation_Handle;

      function Released (W : Adi.Window.Window_Handle)
                         return Adi.Texture_Cache.Event_Count is
        (Adi.Window.Get_Texture_Stats (W).By_Kind
           (Adi.Texture_Cache.Raster_Texture).Released);

      Rel_A, Rel_B : Adi.Texture_Cache.Event_Count;

      --  What B drew, captured while the extent it belongs to is still
      --  the live one.
      Drawn_By_B : Adi.Image.Image_Handle;
   begin
      Section ("a resize releases the old extent everywhere it was drawn");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      --  Sized in dip inside a box, so a scale change actually changes
      --  the pixel extent. A root widget stretched to a window of fixed
      --  pixels occupies the same pixels at any scale.
      declare
         procedure Build (W    : out Adi.Window.Window_Handle;
                          Root : out Widget_Handle;
                          Name : String)
         is
            Box   : Adi.Widget.RLottie.RLottie_Handle;
            Outer : Adi.Widget.Box.Box_Handle;
            Rules : Style_Rules;
         begin
            W := Adi.Window.Create_Window_Handle (Name, (200.0, 200.0));
            Box := Adi.Widget.RLottie.Create_Handle (Anim);
            Rules.Width := Set (Size (Dip (40.0)));
            Rules.Height := Set (Size (Dip (30.0)));
            Set_Part_Style (Adi.Widget.RLottie.To_Widget_Handle (Box),
                            Main_Part, From (Rules).Build);
            Outer := Adi.Widget.Box.Create_Handle;
            Adi.Widget.Box.Add_Child
              (Outer, Adi.Widget.RLottie.To_Widget_Handle (Box));
            Root := Adi.Widget.Box.To_Widget_Handle (Outer);
            Adi.Window.Set_Root (W, Root);
         end Build;
      begin
         Build (WA, RA, "Rel A");
         Build (WB, RB, "Rel B");
      end;

      Pump (WA, Anim);
      Step_Frame (WB);
      Assert (Adi.Window.Get_Texture_Stats (WA).By_Kind
                (Adi.Texture_Cache.Raster_Texture).Count > 0
              and then Adi.Window.Get_Texture_Stats (WB).By_Kind
                (Adi.Texture_Cache.Raster_Texture).Count > 0,
              "each renderer made a texture of the frame it drew");

      Rel_A := Released (WA);
      Rel_B := Released (WB);
      Drawn_By_B := Get_Current_Image (Anim);
      Assert (Adi.Image.Testing.Handle_Is_Registered (Drawn_By_B),
              "the frame B drew is a live image before the resize");

      Adi.Window.Set_UI_Scale (WA, 2.0);
      Pump_Until_Height (WA, Anim, 60);

      Assert (Released (WA) > Rel_A and then Released (WB) > Rel_B,
              "and its textures are released in both renderers, not left"
              & " in the one that did not drive the resize");

      --  B's render item still names the frame of the replaced extent.
      Assert (not Adi.Image.Testing.Handle_Is_Registered (Drawn_By_B),
              "Replacing the extent destroys the frames it was made of,"
              & " so what B's render item names is a stale handle rather"
              & " than a pointer into freed storage");

      --  Forced rather than dirtied: marking the widget dirty would
      --  rebuild its items and replace the very pointer under test, and
      --  a clean window renders nothing at all.
      declare
         R : constant Adi.Window.Window_Ref := Adi.Window.Borrow (WB);
      begin
         Adi.Window.Request_Redraw (R.Ptr.all);
      end;
      Adi.Window.Render (WB);

      Assert (not Adi.Image.Testing.Handle_Is_Registered (Drawn_By_B)
              and then not Adi.Image.Is_Valid (Drawn_By_B),
              "and drawing through it draws nothing: a stale handle"
              & " resolves to no image rather than to freed storage");

      Adi.Window.Set_UI_Scale (WA, 1.0);
      Adi.Window.Destroy (WA);
      Adi.Window.Destroy (WB);
      Destroy (Anim);
   end Test_Resize_Releases_And_Does_Not_Dangle;

   ---------------------------------------------------------------------------

   --  One animation drawn by two widgets in two windows. Its textures
   --  belong to the animation, so no widget's death takes them and the
   --  animation's death takes all of them, in both renderers.
   --
   procedure Test_Shared_Animation_Group is
      use type Adi.Texture_Cache.Event_Count;

      WA, WB  : Adi.Window.Window_Handle;
      BA, BB  : Adi.Widget.RLottie.RLottie_Handle;
      Anim    : Animation_Handle;
      Copy_A, Copy_B : Animation_Handle;

      function Rasters (W : Adi.Window.Window_Handle) return Natural is
        (Adi.Window.Get_Texture_Stats (W).By_Kind
           (Adi.Texture_Cache.Raster_Texture).Count);

      function Released (W : Adi.Window.Window_Handle)
                         return Adi.Texture_Cache.Event_Count is
        (Adi.Window.Get_Texture_Stats (W).By_Kind
           (Adi.Texture_Cache.Raster_Texture).Released);
   begin
      Section ("one animation, two widgets, two renderers");

      Anim := Load_From_File (Fixture);
      Assert (Is_Valid (Anim), "the fixture loads");
      if not Is_Valid (Anim) then
         return;
      end if;

      WA := Adi.Window.Create_Window_Handle ("Shared A", (160.0, 120.0));
      WB := Adi.Window.Create_Window_Handle ("Shared B", (160.0, 120.0));
      BA := Adi.Widget.RLottie.Create_Handle (Anim);
      BB := Adi.Widget.RLottie.Create_Handle (Anim);
      Adi.Window.Set_Root (WA, Adi.Widget.RLottie.To_Widget_Handle (BA));
      Adi.Window.Set_Root (WB, Adi.Widget.RLottie.To_Widget_Handle (BB));

      --  Prepared through window A, then a tick in each window and a
      --  draw. The animation has one anchor, which the first of those
      --  ticks sets while settling the first frame; nothing here selects a
      --  frame by hand, so the initial-frame path is exercised rather than
      --  stepped over.
      Pump (WA, Anim);

      declare
         RA : constant Adi.Window.Window_Ref := Adi.Window.Borrow (WA);
         RB : constant Adi.Window.Window_Ref := Adi.Window.Borrow (WB);
      begin
         Adi.Window.Tick (RA.Ptr.all, 0.020);
         Adi.Window.Tick (RB.Ptr.all, 0.020);
      end;
      Adi.Window.Render (WA);
      Adi.Window.Render (WB);

      Assert (Rasters (WA) = 1 and then Rasters (WB) = 1,
              "one drawn frame is one texture in each renderer: a texture"
              & " belongs to the renderer that made it, so two windows"
              & " make two of them");

      --  What each widget holds, taken while both are alive.
      Copy_A := Adi.Widget.RLottie.Get_Animation (BA);
      Copy_B := Adi.Widget.RLottie.Get_Animation (BB);
      Assert (Is_Valid (Copy_A) and then Is_Valid (Copy_B),
              "both widgets name the same live animation");

      declare
         Was_A : constant Natural := Rasters (WA);
         Was_B : constant Natural := Rasters (WB);
         Rel_A : constant Adi.Texture_Cache.Event_Count := Released (WA);
         Rel_B : constant Adi.Texture_Cache.Event_Count := Released (WB);
      begin
         --  A widget going is not the animation going.
         declare
            HA : Widget_Handle := Adi.Widget.RLottie.To_Widget_Handle (BA);
         begin
            Adi.Widget.Destroy (HA);
         end;
         Adi.Widget.Pump_Widget_Store;
         Assert (Rasters (WA) = Was_A and then Rasters (WB) = Was_B,
                 "Destroying one widget releases nothing: the frames"
                 & " belong to the animation, which the other widget is"
                 & " still drawing");

         declare
            HB : Widget_Handle := Adi.Widget.RLottie.To_Widget_Handle (BB);
         begin
            Adi.Widget.Destroy (HB);
         end;
         Adi.Widget.Pump_Widget_Store;
         Assert (Rasters (WA) = Was_A and then Rasters (WB) = Was_B,
                 "and destroying the second changes nothing either");

         --  The animation going is.
         Destroy (Anim);

         Assert (Rasters (WA) = 0 and then Rasters (WB) = 0,
                 "Destroying the animation takes its frames from every"
                 & " renderer that held them, not merely the last");
         Assert (Released (WA) = Rel_A + 1
                   and then Released (WB) = Rel_B + 1,
                 "exactly the one texture each held, counted as released"
                 & " with its group rather than as anything else");

         --  Two widgets shared one animation, so two handles named it.
         --  One destroy stales both, which a raw pointer could not do.
         Assert (Anim = Null_Animation_Handle,
                 "the destroyed handle is null");
         Assert (not Is_Valid (Copy_A) and then not Is_Valid (Copy_B),
                 "and every handle that named it is stale, rather than a"
                 & " pointer into freed storage");
      end;

      Adi.Window.Destroy (WA);
      Adi.Window.Destroy (WB);
   end Test_Shared_Animation_Group;

begin
   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   Start_Suite ("RLottie widget test");

   if not Boolean (Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO)) then
      Assert (False, "SDL_Init(video) should succeed");
      Finish;
      return;
   end if;

   Test_RLottie_Widget_Prepares;
   Test_Animated_Widget_Prepares;
   Test_Scale_Change_Reprepares;
   Test_Two_Viewers_Rasterise_Once;
   Test_Eviction_Uploads_Rather_Than_Rasterises;
   Test_Resize_Releases_And_Does_Not_Dangle;
   Test_Shared_Animation_Group;

   for Kind in Viewer_Kind loop
      Test_Shared_Playhead (Kind);
      Test_Both_Viewers_Dirty (Kind);
   end loop;

   Finish;
end RLottie_Widget_Test;
