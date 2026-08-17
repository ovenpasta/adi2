pragma Ada_2022;

with Ada.Text_IO;         use Ada.Text_IO;
with Adi.Clock;
with Adi.Image;       use Adi.Image;
with Adi.RLottie;         use Adi.RLottie;
with Adi.RLottie.Testing; use Adi.RLottie.Testing;
with Test_Support;        use Test_Support;

--  Frames are rasterised when playback reaches them and kept afterwards.
--  What that costs is invisible in the picture -- a frame drawn from a
--  retained image looks exactly like one rasterised again for the
--  occasion -- so these count rasterisations rather than looking at
--  frames. Timing belongs in a benchmark, not here.

procedure RLottie_Prepare_Test is

   --  Four frames at eight pixels square, ten a second.
   Fixture : constant String := "tests/assets/tiny_anim.json";
   Frames  : constant := 4;

   Tiny_W  : constant := 16;
   Tiny_H  : constant := 12;

   --  Longer than the settle interval, so a wait genuinely crosses it.
   Settled : constant Duration := 0.25;

   --  Let a requested extent settle and be taken up, without drawing.
   procedure Settle_Extent (Anim : in out RLottie_Animation'Class) is
   begin
      delay Settled;
      Service (Anim);
   end Settle_Extent;

   ---------------------------------------------------------------------------

   procedure Test_Initial_Preparation is
      Anim : constant RLottie_Animation_Access := Load_From_File (Fixture);
   begin
      Section ("loading and preparing rasterise nothing");

      Assert (Anim /= null, "the fixture loads");
      if Anim = null then
         return;
      end if;

      Assert (Is_Valid (Anim.all), "a loaded animation is valid");
      Assert (Rasterisations (Anim.all) = 0, "loading rasterises nothing");

      Prepare (Anim.all, Tiny_W, Tiny_H);

      Assert (Rasterisations (Anim.all) = 0,
              "Preparing an extent rasterises nothing either: the extent"
              & " says what a frame would be drawn at, not that any frame"
              & " is wanted yet");
      Assert (not Is_Prepared (Anim.all),
              "and nothing is drawable, an accepted extent being a size"
              & " rather than a picture");

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = Tiny_W and then H = Tiny_H,
                 "though the extent is reported from the moment it is"
                 & " accepted");
      end;

      Destroy (Anim.all);
   end Test_Initial_Preparation;

   ---------------------------------------------------------------------------

   procedure Test_First_Request_Rasterises_Once is
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
   begin
      Section ("a frame is rasterised the first time it is reached");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Moved := Advance_At (Anim.all, Adi.Clock.Now);

      Assert (Rasterisations (Anim.all) = 1,
              "The first sample rasterises exactly one frame");
      Assert (Frame_Is_Retained (Anim.all, 1), "and keeps it");
      Assert (Is_Prepared (Anim.all), "and the animation is drawable");
      Assert (Get_Current_Image (Anim.all) /= null, "with an image to draw");

      Destroy (Anim.all);
   end Test_First_Request_Rasterises_Once;

   ---------------------------------------------------------------------------

   procedure Test_Second_Loop_Is_Free is
      use type Adi.Clock.Time;
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Moved : Boolean;
      pragma Unreferenced (Moved);
      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));
      First_Loop : Natural;
   begin
      Section ("a second loop rasterises nothing");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Set_Looping (Anim.all, True);
      Prepare (Anim.all, Tiny_W, Tiny_H);

      --  One whole loop: every frame reached once.
      for I in 0 .. Frames - 1 loop
         Moved := Advance_At (Anim.all, At_Ms (I * 100));
      end loop;
      First_Loop := Rasterisations (Anim.all);
      Assert (First_Loop = Frames,
              "The first loop rasterises each frame once");

      --  And round again.
      for I in Frames .. 2 * Frames - 1 loop
         Moved := Advance_At (Anim.all, At_Ms (I * 100));
      end loop;

      Assert (Rasterisations (Anim.all) = First_Loop,
              "The second adds none: what a loop returns to is what it"
              & " already has, which is the whole point of keeping it");

      Destroy (Anim.all);
   end Test_Second_Loop_Is_Free;

   ---------------------------------------------------------------------------

   procedure Test_Skipped_Frames_Stay_Null is
      use type Adi.Clock.Time;
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Moved : Boolean;
      pragma Unreferenced (Moved);
      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));
   begin
      Section ("a frame never reached is never rasterised");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Moved := Advance_At (Anim.all, At_Ms (0));     --  frame 1
      Moved := Advance_At (Anim.all, At_Ms (200));   --  frame 3, skipping 2

      Assert (Get_Current_Frame_Index (Anim.all) = 3, "the playhead skips");
      Assert (Rasterisations (Anim.all) = 2,
              "Two frames were reached, so two were rasterised");
      Assert (Frame_Is_Retained (Anim.all, 1)
              and then Frame_Is_Retained (Anim.all, 3),
              "and those two are kept");
      Assert (not Frame_Is_Retained (Anim.all, 2)
              and then not Frame_Is_Retained (Anim.all, 4),
              "while the ones passed over cost nothing at all");

      Destroy (Anim.all);
   end Test_Skipped_Frames_Stay_Null;

   ---------------------------------------------------------------------------

   procedure Test_Reset_Costs is
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
      Before : Natural;
   begin
      Section ("resetting costs a frame only when it has none");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Assert (not Frame_Is_Retained (Anim.all, 1), "frame one is absent");

      Reset (Anim.all);
      Assert (Rasterisations (Anim.all) = 1,
              "Resetting to a frame nothing has rasterised rasterises it");
      Assert (Get_Current_Image (Anim.all) /= null, "and shows it");

      Before := Rasterisations (Anim.all);
      Reset (Anim.all);
      Assert (Rasterisations (Anim.all) = Before,
              "Resetting again costs nothing: the frame is already kept");

      Destroy (Anim.all);
   end Test_Reset_Costs;

   ---------------------------------------------------------------------------

   --  Paused throughout, so a tick cannot legitimately rasterise the
   --  replacement's current frame and then the next playback frame.
   procedure Test_Resize_Rasterises_Only_Current is
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
      Before : Natural;
   begin
      Section ("a settled resize rasterises exactly the current frame");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Moved := Advance_At (Anim.all, Adi.Clock.Now);
      Stop (Anim.all);
      Before := Rasterisations (Anim.all);
      Assert (Retired_Set_Count (Anim.all) = 0, "nothing retired yet");

      Prepare (Anim.all, 80, 60);
      Settle_Extent (Anim.all);

      Assert (Rasterisations (Anim.all) = Before + 1,
              "One frame at the new extent, the one on screen. The rest"
              & " are rasterised if and when playback reaches them");
      Assert (Retired_Set_Count (Anim.all) = 1,
              "and the extent it replaced is retired, exactly once");
      Assert (Get_Current_Image (Anim.all) /= null,
              "with something to draw throughout: a paused animation"
              & " would never ask for a frame to fill a blank set");

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = 80 and then H = 60, "at the extent asked for");
      end;

      Destroy (Anim.all);
   end Test_Resize_Rasterises_Only_Current;

   ---------------------------------------------------------------------------

   procedure Test_Resize_Preserves_Timeline is
      use type Adi.Clock.Time;
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Moved : Boolean;
      pragma Unreferenced (Moved);
      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));
      Was_Frame   : Natural;
      Was_Elapsed : Duration;
   begin
      Section ("a resize does not rewind playback");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Moved := Advance_At (Anim.all, At_Ms (0));
      Moved := Advance_At (Anim.all, At_Ms (200));
      Stop (Anim.all);

      Was_Frame := Get_Current_Frame_Index (Anim.all);
      Was_Elapsed := Elapsed (Anim.all);
      Assert (Was_Frame = 3, "the playhead stands part way through");

      Prepare (Anim.all, 80, 60);
      Settle_Extent (Anim.all);

      Assert (Get_Current_Frame_Index (Anim.all) = Was_Frame,
              "Resizing changes how the animation is presented, not where"
              & " it has got to, so the frame index stands");
      Assert (Elapsed (Anim.all) = Was_Elapsed,
              "and so does the elapsed time behind it");

      --  Resuming re-anchors, so the sample after it establishes where
      --  the clock now stands and the one after that charges for it.
      Start (Anim.all);
      Moved := Advance_At (Anim.all, At_Ms (300));
      Moved := Advance_At (Anim.all, At_Ms (400));
      Assert (Get_Current_Frame_Index (Anim.all) = 4,
              "and playback carries on from where it stood rather than"
              & " restarting at the beginning");

      Destroy (Anim.all);
   end Test_Resize_Preserves_Timeline;

   ---------------------------------------------------------------------------

   procedure Test_Failed_Replacement is
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Moved : Boolean;
      pragma Unreferenced (Moved);
      Was_Frame   : Natural;
      Was_Elapsed : Duration;
      Was_Image   : Image_Access;
      Was_Count   : Natural;
   begin
      Section ("a replacement that fails keeps what was drawable");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Moved := Advance_At (Anim.all, Adi.Clock.Now);
      Stop (Anim.all);

      Was_Frame := Get_Current_Frame_Index (Anim.all);
      Was_Elapsed := Elapsed (Anim.all);
      Was_Image := Get_Current_Image (Anim.all);
      Was_Count := Rasterisations (Anim.all);

      Fail_Next_Rasterisation (Anim.all);
      Prepare (Anim.all, 80, 60);
      Settle_Extent (Anim.all);

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = Tiny_W and then H = Tiny_H,
                 "The old extent is still the one in use: a replacement"
                 & " is published only once it has a frame to show");
      end;
      Assert (Get_Current_Image (Anim.all) = Was_Image,
              "the same image is still drawable");
      Assert (Get_Current_Frame_Index (Anim.all) = Was_Frame
              and then Elapsed (Anim.all) = Was_Elapsed,
              "and the timeline is untouched");
      Assert (Retired_Set_Count (Anim.all) = 0,
              "nothing was retired, nothing having been replaced");

      --  Backed off rather than abandoned.
      Service (Anim.all);
      Assert (Rasterisations (Anim.all) = Was_Count,
              "Retrying at once would hammer whatever just failed, so an"
              & " immediate service does not");

      Settle_Extent (Anim.all);
      Assert (Rasterisations (Anim.all) = Was_Count + 1,
              "but the request is not dropped: after the interval it is"
              & " taken up, for the cost of the one frame on screen");
      Assert (Retired_Set_Count (Anim.all) = 1, "retiring exactly one set");
      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = 80 and then H = 60, "at the extent asked for");
      end;

      Destroy (Anim.all);
   end Test_Failed_Replacement;

   ---------------------------------------------------------------------------

   --  Nothing here calls Service: the sampled entry point is the only
   --  thing turning the machine, which is what preparation has to work
   --  through when the playhead is not moving.
   procedure Test_Paused_Preparation_Completes is
      use type Adi.Clock.Time;
      Anim  : RLottie_Animation_Access := Load_From_File (Fixture);
      Base  : constant Adi.Clock.Time := Adi.Clock.Now;
      Moved : Boolean;
      pragma Unreferenced (Moved);
      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));
   begin
      Section ("a paused animation still takes up a new extent");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Moved := Advance_At (Anim.all, At_Ms (0));
      Stop (Anim.all);
      Assert (not Is_Playing (Anim.all), "playback is stopped");

      Prepare (Anim.all, 80, 60);
      for I in 1 .. 400 loop
         Moved := Advance_At (Anim.all, At_Ms (100 + I * 10));
         declare
            W, H : Natural;
         begin
            Prepared_Extent (Anim.all, W, H);
            exit when W = 80;
         end;
         delay 0.005;
      end loop;

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = 80 and then H = 60,
                 "Ticking alone takes it up: preparation that only turned"
                 & " while the playhead did would stall on a pause");
      end;
      Assert (not Is_Playing (Anim.all),
              "and taking it up did not restart playback");
      Assert (Get_Current_Image (Anim.all) /= null,
              "and left a frame to draw");

      Destroy (Anim.all);
   end Test_Paused_Preparation_Completes;

   ---------------------------------------------------------------------------

   procedure Test_Sampled_Advance is
      use type Adi.Clock.Time;

      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
      Base : constant Adi.Clock.Time := Adi.Clock.Now;

      function At_Ms (Ms : Integer) return Adi.Clock.Time is
        (Base + Adi.Clock.Microseconds (Ms * 1_000));

      Moved : Boolean;
   begin
      Section ("advancing to an instant rather than by a step");

      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);

      --  The first sample has no elapsed time to charge, but it does
      --  settle which frame is visible: anchoring must not mean showing
      --  nothing until a second sample happens along.
      Moved := Advance_At (Anim.all, At_Ms (0));
      Assert (Moved,
              "The first sample reports a frame becoming visible");
      Assert (Get_Current_Frame_Index (Anim.all) = 1,
              "which is the first, at zero elapsed");

      Moved := Advance_At (Anim.all, At_Ms (0));
      Assert (not Moved and then Get_Current_Frame_Index (Anim.all) = 1,
              "and repeating that instant reports nothing further");

      --  Two viewers of one animation, sampling the same instant. The
      --  second must contribute nothing, which is the whole point.
      Moved := Advance_At (Anim.all, At_Ms (100));
      declare
         After_First : constant Natural :=
           Get_Current_Frame_Index (Anim.all);
         Second : constant Boolean := Advance_At (Anim.all, At_Ms (100));
      begin
         Assert (Moved and then After_First = 2,
                 "A tenth of a second is one frame, so the first viewer"
                 & " advances the animation by exactly one");
         Assert (not Second,
                 "and the second viewer sampling the same instant adds"
                 & " nothing: elapsed time belongs to the clock, not to"
                 & " the number of things watching");
         Assert (Get_Current_Frame_Index (Anim.all) = After_First,
                 "so the frame is where the first viewer left it");
      end;

      --  A sample that has gone backwards is ignored, and must not move
      --  the anchor: doing so would make the next honest sample pay for
      --  the gap twice.
      Set_Looping (Anim.all, False);
      declare
         Before : constant Natural := Get_Current_Frame_Index (Anim.all);
      begin
         --  Far enough back that charging for it would run past the end.
         Moved := Advance_At (Anim.all, At_Ms (-5_000));
         Assert (not Moved, "A sample older than the last does nothing");
         Assert (Get_Current_Frame_Index (Anim.all) = Before,
                 "and leaves the frame alone");

         Moved := Advance_At (Anim.all, At_Ms (200));
         Assert (Get_Current_Frame_Index (Anim.all) = Before + 1,
                 "while the next honest sample advances by exactly the"
                 & " tenth of a second that passed -- an anchor moved to"
                 & " the rewind would charge five seconds and land at the"
                 & " end");
      end;
      Set_Looping (Anim.all, True);

      --  Stepping by hand and then sampling again must not charge for
      --  both the step and everything since the old anchor.
      declare
         Ignored : Boolean := Advance (Anim.all, 0.100);
         After_Manual : constant Natural :=
           Get_Current_Frame_Index (Anim.all);
      begin
         Moved := Advance_At (Anim.all, At_Ms (5_000));
         Assert (not Moved,
                 "The first sample after a manual step anchors: the manual"
                 & " step already moved the timeline, and the seconds"
                 & " since the old anchor were never owed");
         Assert (Get_Current_Frame_Index (Anim.all) = After_Manual,
                 "so the frame is where the manual step left it");
      end;

      --  Paused: the anchor keeps moving so that resuming does not
      --  deliver the pause in one go.
      Stop (Anim.all);
      declare
         Paused_At : constant Natural := Get_Current_Frame_Index (Anim.all);
      begin
         Moved := Advance_At (Anim.all, At_Ms (5_100));
         Assert (not Moved, "A paused animation does not advance");
         Moved := Advance_At (Anim.all, At_Ms (9_000));
         Assert (Get_Current_Frame_Index (Anim.all) = Paused_At,
                 "however long it is left paused");

         Start (Anim.all);
         Moved := Advance_At (Anim.all, At_Ms (9_500));
         Assert (Get_Current_Frame_Index (Anim.all) = Paused_At,
                 "and resuming re-anchors, so the seconds spent paused are"
                 & " not delivered at once");
      end;

      --  Speed scales elapsed time, so half a frame's worth of clock at
      --  double speed is a whole frame. It does not re-anchor: the time
      --  that passed still passed, and only what it buys has changed.
      Reset (Anim.all);
      Moved := Advance_At (Anim.all, At_Ms (30_000));   --  anchors

      --  Set after the anchor is established, so this also shows that
      --  changing speed keeps it: clearing it here would make the next
      --  sample anchor instead of advancing, and nothing would move.
      Set_Playback_Speed (Anim.all, 2.0);
      declare
         From : constant Natural := Get_Current_Frame_Index (Anim.all);
      begin
         Moved := Advance_At (Anim.all, At_Ms (30_050));
         Assert (Moved and then Get_Current_Frame_Index (Anim.all) = From + 1,
                 "Fifty milliseconds at double speed is one frame of a ten"
                 & " a second animation");
      end;
      Set_Playback_Speed (Anim.all, 1.0);

      --  Reset puts the timeline back and re-anchors with it.
      Reset (Anim.all);
      declare
         From_Reset : constant Natural :=
           Get_Current_Frame_Index (Anim.all);
      begin
         Moved := Advance_At (Anim.all, At_Ms (20_000));
         Assert (Get_Current_Frame_Index (Anim.all) = From_Reset,
                 "The first sample after a reset anchors rather than"
                 & " replaying everything since the last one");
      end;

      Destroy (Anim.all);
   end Test_Sampled_Advance;

begin
   Start_Suite ("RLottie prepare test");

   Test_Initial_Preparation;
   Test_First_Request_Rasterises_Once;
   Test_Second_Loop_Is_Free;
   Test_Skipped_Frames_Stay_Null;
   Test_Reset_Costs;
   Test_Resize_Rasterises_Only_Current;
   Test_Resize_Preserves_Timeline;
   Test_Failed_Replacement;
   Test_Paused_Preparation_Completes;
   Test_Sampled_Advance;

   Finish;
end RLottie_Prepare_Test;
