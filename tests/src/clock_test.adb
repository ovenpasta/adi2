pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;

with Adi.Clock; use Adi.Clock;

procedure Clock_Test is
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Assert;

   procedure Test_Conversions is
   begin
      Put_Line ("Test: span conversions");
      Assert (To_Duration (Microseconds (0)) = 0.0,
              "Microseconds (0) is zero");
      Assert (To_Duration (Microseconds (1_000_000)) = 1.0,
              "Microseconds (1_000_000) is one second");
      Assert (To_Duration (Microseconds (16_667)) = 0.016_667,
              "Microseconds (16_667) is exact (~60 FPS period)");
      Assert (To_Duration (Microseconds (-500)) = -0.000_5,
              "negative spans convert");
   end Test_Conversions;

   procedure Test_Arithmetic is
      A : constant Time := Zero + Microseconds (250);
      B : constant Time := Zero + Microseconds (1_000);
   begin
      Put_Line ("Test: instant arithmetic");
      Assert (To_Duration (B - A) = 0.000_75,
              "difference of instants is the expected span");
      Assert (To_Duration (A - B) = -0.000_75,
              "reversed difference is negated");
      Assert (B - Zero = Microseconds (1_000),
              "span equality after round trip through an instant");
   end Test_Arithmetic;

   procedure Test_Monotonic is
      A : constant Time := Now;
      B : Time;
   begin
      Put_Line ("Test: clock is monotonic");
      Assert (To_Duration (A - Zero) >= 0.0, "clock starts at/after epoch");
      for I in 1 .. 1_000 loop
         B := Now;
         if To_Duration (B - A) < 0.0 then
            Assert (False, "clock never goes backwards");
            return;
         end if;
      end loop;
      Assert (True, "clock never goes backwards");
   end Test_Monotonic;

   procedure Test_Sleep_Until is
      Period : constant Time_Span := Microseconds (10_000);
      Start  : constant Time := Now;
   begin
      Put_Line ("Test: Sleep_Until");
      Sleep_Until (Start + Period);
      Assert (To_Duration (Now - Start) >= 0.01,
              "Sleep_Until waits at least the requested 10 ms");
      Sleep_Until (Start);
      Assert (True, "Sleep_Until with a past instant returns");
   end Test_Sleep_Until;

begin
   Put_Line ("========================================");
   Put_Line ("   Adi.Clock Test Suite");
   Put_Line ("========================================");

   Test_Conversions;
   Test_Arithmetic;
   Test_Monotonic;
   Test_Sleep_Until;

   Put_Line ("Total:" & Test_Count'Image
             & "  Passed:" & Pass_Count'Image
             & "  Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Put_Line ("FAILED");
   else
      Put_Line ("All tests PASSED!");
   end if;
end Clock_Test;
