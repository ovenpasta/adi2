pragma Ada_2022;

with Adi.Clock;
with Adi.Playback_Clock; use Adi.Playback_Clock;
with Test_Support;       use Test_Support;

--  Synthetic instants throughout: what a clock does with an instant is
--  arithmetic, and asserting it against real time would only measure the
--  machine.

procedure Playback_Clock_Test is
   use type Adi.Clock.Time;

   Base : constant Adi.Clock.Time := Adi.Clock.Now;

   function At_Ms (Ms : Integer) return Adi.Clock.Time is
     (Base + Adi.Clock.Microseconds (Ms * 1_000));

   --  Duration comparison with room for the conversion through
   --  microseconds, which is exact at these magnitudes but need not be.
   function Near (A, B : Duration) return Boolean is
     (abs (A - B) < 0.0005);

begin
   Start_Suite ("Playback clock test");

   ---------------------------------------------------------------------
   Section ("the first sample anchors rather than charging");
   declare
      C : Clock_State;
      R : Sample_Result;
   begin
      Assert (not Is_Anchored (C), "a fresh clock stands nowhere");

      R := Sample (C, At_Ms (1_000));
      Assert (R.Kind = Anchored,
              "The first sample anchors: there is no earlier instant to"
              & " measure from, and charging since program start would"
              & " deliver the whole history at once");
      Assert (Is_Anchored (C), "and the clock now stands somewhere");

      R := Sample (C, At_Ms (1_100));
      Assert (R.Kind = Elapsed and then Near (R.Span, 0.1),
              "and the next sample charges only the span since it");
   end;

   ---------------------------------------------------------------------
   Section ("a repeated instant is not a zero-length step");
   declare
      C : Clock_State;
      R : Sample_Result;
   begin
      R := Sample (C, At_Ms (0));
      R := Sample (C, At_Ms (500));
      Assert (R.Kind = Elapsed, "time passed once");

      R := Sample (C, At_Ms (500));
      Assert (R.Kind = Ignored,
              "The same instant again is ignored rather than reported as"
              & " no time: a second viewer sampling one tick must not"
              & " look like a first anchor to the caller");

      R := Sample (C, At_Ms (600));
      Assert (R.Kind = Elapsed and then Near (R.Span, 0.1),
              "and the anchor stayed where it was, so the next real"
              & " sample measures from there");
   end;

   ---------------------------------------------------------------------
   Section ("a sample from before the anchor is ignored");
   declare
      C : Clock_State;
      R : Sample_Result;
   begin
      R := Sample (C, At_Ms (1_000));
      R := Sample (C, At_Ms (2_000));

      R := Sample (C, At_Ms (1_500));
      Assert (R.Kind = Ignored, "an older instant charges nothing");

      R := Sample (C, At_Ms (2_400));
      Assert (R.Kind = Elapsed and then Near (R.Span, 0.4),
              "and did not drag the anchor back: measuring from 1500"
              & " would charge the interval a second time");
   end;

   ---------------------------------------------------------------------
   Section ("re-anchoring drops the gap rather than delivering it");
   declare
      C : Clock_State;
      R : Sample_Result;
   begin
      R := Sample (C, At_Ms (0));
      R := Sample (C, At_Ms (100));

      Reanchor (C);
      Assert (not Is_Anchored (C), "the clock stands nowhere again");

      R := Sample (C, At_Ms (60_000));
      Assert (R.Kind = Anchored,
              "A minute later it anchors rather than charging the minute:"
              & " this is what a resume, a reset and a step by hand all"
              & " need, none of which should replay the time since");

      R := Sample (C, At_Ms (60_100));
      Assert (R.Kind = Elapsed and then Near (R.Span, 0.1),
              "and time runs again from the new anchor");
   end;

   ---------------------------------------------------------------------
   Section ("two viewers of one tick");
   declare
      C : Clock_State;
      A, B : Sample_Result;
   begin
      A := Sample (C, At_Ms (0));

      --  Both sample the same instant, as two windows ticking one frame.
      A := Sample (C, At_Ms (16));
      B := Sample (C, At_Ms (16));
      Assert (A.Kind = Elapsed and then Near (A.Span, 0.016),
              "the first viewer charges the frame");
      Assert (B.Kind = Ignored,
              "and the second charges nothing, which is what keeps a"
              & " shared playhead from running at twice its speed");
   end;

   Finish;
end Playback_Clock_Test;
