pragma Ada_2022;

with Ada.Text_IO;         use Ada.Text_IO;
with Adi.Clock;
with Adi.RLottie;         use Adi.RLottie;
with Adi.RLottie.Testing; use Adi.RLottie.Testing;
with Test_Support;        use Test_Support;

--  Preparation is a state machine over time: an extent is asked for, it
--  settles, one build runs, and its result replaces what was drawable.
--  What can go wrong is invisible in the frames themselves -- a resize
--  that rebuilt at every intermediate size draws exactly what a single
--  settled build draws -- so these look at the machine rather than the
--  picture.

procedure RLottie_Prepare_Test is

   --  Four frames at eight pixels square: enough to have a frame set,
   --  small enough that a build finishes while a test waits.
   Fixture : constant String := "tests/assets/tiny_anim.json";

   --  Small, because a hundred frames of anything larger is the defect
   --  this whole exercise is about.
   Tiny_W  : constant := 16;
   Tiny_H  : constant := 12;

   --  Longer than the settle time, so a wait genuinely crosses it.
   Settled : constant Duration := 0.25;

   procedure Finish_Build (Anim : in out RLottie_Animation'Class) is
   begin
      --  Poll the machine rather than sleeping a guessed interval.
      for I in 1 .. 2_000 loop
         Service (Anim);
         exit when not Build_In_Flight (Anim);
         delay 0.005;
      end loop;
   end Finish_Build;

   procedure Test_Initial_Preparation is
      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
   begin
      Section ("loading prepares nothing, and the first extent prepares");

      Assert (Anim /= null, "the fixture loads");
      if Anim = null then
         return;
      end if;

      Assert (Is_Valid (Anim.all), "a loaded animation is valid");
      Assert (not Is_Prepared (Anim.all),
              "but nothing is rasterised until an extent is given: the"
              & " file states a viewport, not a size to draw at");
      Assert (Build_Count (Anim.all) = 0, "and no build has started");

      Prepare (Anim.all, Tiny_W, Tiny_H);

      Assert (Build_Count (Anim.all) = 1,
              "The first extent starts a build at once, since there is"
              & " nothing to draw until it exists");

      Finish_Build (Anim.all);

      Assert (Is_Prepared (Anim.all), "which becomes drawable");
      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = Tiny_W and then H = Tiny_H,
                 "at exactly the extent asked for, not the file's own");
      end;

      Destroy (Anim.all);
   end Test_Initial_Preparation;

   procedure Test_Resize_Does_Not_Rebuild_Continuously is
      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
   begin
      Section ("a resize coalesces to where it stops");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Finish_Build (Anim.all);
      Assert (Build_Count (Anim.all) = 1, "one build so far");

      --  A drag: every intermediate extent, none of them held.
      for I in 1 .. 30 loop
         Prepare (Anim.all, Tiny_W + I, Tiny_H + I);
         Service (Anim.all);
      end loop;

      Assert (Build_Count (Anim.all) = 1,
              "Passing through thirty extents should build at none of"
              & " them: a build at each would finish none of them");
      Assert (Is_Prepared (Anim.all),
              "and what was drawable stays drawable throughout");

      --  Now it stops.
      delay Settled;
      Prepare (Anim.all, Tiny_W + 30, Tiny_H + 30);
      Service (Anim.all);

      Assert (Build_Count (Anim.all) = 2,
              "Once it settles, exactly one build starts");
      Finish_Build (Anim.all);

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = Tiny_W + 30 and then H = Tiny_H + 30,
                 "and it is the extent the resize ended at");
      end;

      Destroy (Anim.all);
   end Test_Resize_Does_Not_Rebuild_Continuously;

   procedure Test_One_Worker_Under_Rapid_Supersedes is
      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
      Seen_Two : Boolean := False;
   begin
      Section ("rapid supersedes never leave a second worker");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);

      --  Supersede repeatedly while the first build is still running.
      for I in 1 .. 40 loop
         Prepare (Anim.all, Tiny_W + I, Tiny_H + I);
         Service (Anim.all);
         --  Build_Count rising by more than one per settled extent would
         --  mean a worker was started beside one already running.
         if Build_Count (Anim.all) > 2 then
            Seen_Two := True;
         end if;
      end loop;

      Assert (not Seen_Two,
              "A supersede should stop the build in flight and wait for"
              & " it, not start a second beside it");

      Finish_Build (Anim.all);
      Destroy (Anim.all);
   end Test_One_Worker_Under_Rapid_Supersedes;

   procedure Test_Superseded_Build_Is_Not_Published is
      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
   begin
      Section ("a superseded build is dropped, not installed");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Finish_Build (Anim.all);

      --  Start a second build and abandon it before it lands. The extent
      --  has to be asked for, then stand still, then be serviced: the
      --  clock starts when the asking changes.
      Prepare (Anim.all, 40, 30);
      delay Settled;
      Service (Anim.all);
      Assert (Build_In_Flight (Anim.all), "a second build is running");

      Prepare (Anim.all, 64, 48);
      Service (Anim.all);
      Assert (Build_Superseded (Anim.all),
              "and asking for another extent abandons it");

      Finish_Build (Anim.all);

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W /= 40,
                 "The abandoned generation must not be installed");
         Assert (W = Tiny_W or else W = 64,
                 "what is drawable is either the old set or the one that"
                 & " superseded it");
      end;

      Destroy (Anim.all);
   end Test_Superseded_Build_Is_Not_Published;

   procedure Test_Old_Frames_Drawable_While_Building is
      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
   begin
      Section ("preparation never blanks a running animation");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, Tiny_W, Tiny_H);
      Finish_Build (Anim.all);
      Assert (Is_Prepared (Anim.all), "drawable at the first extent");

      Prepare (Anim.all, 80, 60);
      delay Settled;
      Service (Anim.all);

      Assert (Build_In_Flight (Anim.all), "a replacement is building");
      Assert (Is_Prepared (Anim.all),
              "and the animation is still drawable while it does: the old"
              & " set goes only once the new one is in place");

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = Tiny_W,
                 "and it is still the old extent that is drawable");
      end;

      Finish_Build (Anim.all);
      Destroy (Anim.all);
   end Test_Old_Frames_Drawable_While_Building;

   procedure Test_Small_Permanent_Resize_Becomes_Exact is
      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
   begin
      Section ("a small permanent change is eventually rasterised exactly");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      Prepare (Anim.all, 40, 30);
      Finish_Build (Anim.all);

      --  One pixel wider, and it stays that way. A policy that ignored
      --  changes below some ratio would draw a scaled set for ever.
      Prepare (Anim.all, 41, 30);
      delay Settled;
      Prepare (Anim.all, 41, 30);
      Finish_Build (Anim.all);

      declare
         W, H : Natural;
      begin
         Prepared_Extent (Anim.all, W, H);
         Assert (W = 41 and then H = 30,
                 "Even a one-pixel change that persists should end up"
                 & " rasterised exactly, not scaled indefinitely");
      end;

      Destroy (Anim.all);
   end Test_Small_Permanent_Resize_Becomes_Exact;

   procedure Test_Destroy_During_Build is
      Anim : RLottie_Animation_Access := Load_From_File (Fixture);
   begin
      Section ("destroying during a build waits and terminates");
      if Anim = null then
         Assert (False, "the fixture loads");
         return;
      end if;

      --  Large enough that the build is certainly still running.
      Prepare (Anim.all, 400, 300);
      Service (Anim.all);
      Assert (Build_In_Flight (Anim.all), "a build is running");

      --  The worker renders from the model and writes into its set, so
      --  this has to establish that it has stopped before freeing either.
      --  Reaching the next line at all is the assertion.
      Destroy (Anim.all);

      Assert (not Is_Prepared (Anim.all),
              "Destroying during a build should complete, having waited"
              & " for the worker rather than freeing under it");
   end Test_Destroy_During_Build;

   ---------------------------------------------------------------------------

   --  Sampled advancement, driven by instants the test supplies rather
   --  than by the clock, so what is asserted is the arithmetic and not
   --  how fast the machine ran.
   --
   --  The fixture is four frames at ten a second, so a frame is a tenth
   --  of a second.
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
      Finish_Build (Anim.all);

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
   Test_Resize_Does_Not_Rebuild_Continuously;
   Test_One_Worker_Under_Rapid_Supersedes;
   Test_Superseded_Build_Is_Not_Published;
   Test_Old_Frames_Drawable_While_Building;
   Test_Small_Permanent_Resize_Becomes_Exact;
   Test_Destroy_During_Build;
   Test_Sampled_Advance;

   Finish;
end RLottie_Prepare_Test;
