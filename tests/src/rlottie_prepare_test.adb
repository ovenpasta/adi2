pragma Ada_2022;

with Ada.Text_IO;         use Ada.Text_IO;
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

begin
   Start_Suite ("RLottie prepare test");

   Test_Initial_Preparation;
   Test_Resize_Does_Not_Rebuild_Continuously;
   Test_One_Worker_Under_Rapid_Supersedes;
   Test_Superseded_Build_Is_Not_Published;
   Test_Old_Frames_Drawable_While_Building;
   Test_Small_Permanent_Resize_Becomes_Exact;
   Test_Destroy_During_Build;

   Finish;
end RLottie_Prepare_Test;
