pragma Ada_2022;
with Ada.Command_Line;
with Ada.Text_IO;      use Ada.Text_IO;
with Adi.Widget;       use Adi.Widget;
with Adi.SDL.Events;   use Adi.SDL.Events;
with Adi.Widget.Slider;
with Adi.Widget.Integer_Slider;

procedure Slider_Test is

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

   -------------------------------------------
   --  Float slider tests
   -------------------------------------------
   package Float_Slider is new Adi.Widget.Slider (Float);
   use type Float_Slider.Orientation;
   use type Float_Slider.Slider_Handle;

   procedure Test_Create is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Float slider Create");
      Assert (Float_Slider.Get_Value (S) = 50.0,
              "Value should be 50.0");
      Assert (Float_Slider.Get_Min (S) = 0.0,
              "Min should be 0.0");
      Assert (Float_Slider.Get_Max (S) = 100.0,
              "Max should be 100.0");
   end Test_Create;

   procedure Test_Set_Value is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider Set_Value");
      Float_Slider.Set_Value (S, 75.0);
      Assert (Float_Slider.Get_Value (S) = 75.0,
              "Value should be 75.0 after Set_Value");
   end Test_Set_Value;

   procedure Test_Clamp_Above_Max is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider clamp above max");
      Float_Slider.Set_Value (S, 200.0);
      Assert (Float_Slider.Get_Value (S) = 100.0,
              "Value should be clamped to 100.0");
   end Test_Clamp_Above_Max;

   procedure Test_Clamp_Below_Min is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 10.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Float slider clamp below min");
      Float_Slider.Set_Value (S, 5.0);
      Assert (Float_Slider.Get_Value (S) = 10.0,
              "Value should be clamped to 10.0");
   end Test_Clamp_Below_Min;

   procedure Test_Create_Clamps is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 50.0, Value => 999.0);
   begin
      Put_Line ("Test: Float slider Create clamps value");
      Assert (Float_Slider.Get_Value (S) = 50.0,
              "Value should be clamped to max on create");
   end Test_Create_Clamps;

   procedure Test_Set_Range is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 80.0);
   begin
      Put_Line ("Test: Float slider Set_Range reclamps value");
      Float_Slider.Set_Range (S, Min => 0.0, Max => 50.0);
      Assert (Float_Slider.Get_Value (S) = 50.0,
              "Value should be reclamped to new max");
      Assert (Float_Slider.Get_Max (S) = 50.0,
              "Max should be updated to 50.0");
   end Test_Set_Range;

   procedure Test_Step is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider step default");
      Assert (Float_Slider.Get_Step (S) = 0.0,
              "Default step should be 0.0 (continuous)");
      Float_Slider.Set_Step (S, 10.0);
      Assert (Float_Slider.Get_Step (S) = 10.0,
              "Step should be 10.0 after Set_Step");
   end Test_Step;

   procedure Test_Orientation is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider orientation");
      Assert (Float_Slider.Get_Orientation (S) = Float_Slider.Horizontal,
              "Default orientation should be Horizontal");
      Float_Slider.Set_Orientation (S, Float_Slider.Vertical);
      Assert (Float_Slider.Get_Orientation (S) = Float_Slider.Vertical,
              "Orientation should be Vertical after set");
   end Test_Orientation;

   procedure Test_Flags is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider has correct flags");
      Assert (Has_Flag (+S, Clickable),
              "Slider should be Clickable");
      Assert (Has_Flag (+S, Focusable),
              "Slider should be Focusable");
      Assert (Has_Flag (+S, Visible),
              "Slider should be Visible");
   end Test_Flags;

   Callback_Fired : Boolean := False;
   Callback_Value : Float := 0.0;

   procedure On_Changed
     (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Callback_Fired := True;
      Callback_Value := Value;
   end On_Changed;

   procedure Test_Callback is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider callback");
      Float_Slider.Connect_Changed (S, On_Changed'Unrestricted_Access);
      Callback_Fired := False;
      --  Simulate keyboard: need geometry first for item-based logic
      Set_Geometry (+S, (X => 0.0, Y => 0.0, Width => 200.0, Height => 24.0));
      Build_Items (+S);
      On_Key_Down
        (+S,
         Scancode => Adi.SDL.Events.SDL_SCANCODE_RIGHT,
         Key_Mod  => 0,
         Repeat   => False);
      Assert (Callback_Fired, "Callback should fire on key right");
      Assert (Callback_Value > 0.0, "Value should increase on key right");
   end Test_Callback;

   -------------------------------------------
   --  Integer slider tests
   -------------------------------------------
   package Int_Slider is new Adi.Widget.Integer_Slider (Integer);

   procedure Test_Int_Create is
      S : constant Int_Slider.Slider_Handle :=
        Int_Slider.Create_Handle (Min => 0, Max => 255, Value => 128);
   begin
      Put_Line ("Test: Integer slider Create");
      Assert (Int_Slider.Get_Value (S) = 128,
              "Value should be 128");
      Assert (Int_Slider.Get_Min (S) = 0,
              "Min should be 0");
      Assert (Int_Slider.Get_Max (S) = 255,
              "Max should be 255");
   end Test_Int_Create;

   procedure Test_Int_Clamp is
      S : constant Int_Slider.Slider_Handle :=
        Int_Slider.Create_Handle (Min => 0, Max => 100, Value => 200);
   begin
      Put_Line ("Test: Integer slider clamp");
      Assert (Int_Slider.Get_Value (S) = 100,
              "Value should be clamped to 100");
   end Test_Int_Clamp;

   procedure Test_Int_Step is
      S : constant Int_Slider.Slider_Handle :=
        Int_Slider.Create_Handle (Min => 0, Max => 100, Value => 50);
   begin
      Put_Line ("Test: Integer slider step");
      Int_Slider.Set_Step (S, 5);
      Assert (Int_Slider.Get_Step (S) = 5,
              "Step should be 5");
   end Test_Int_Step;

   procedure Test_Key_Home_End is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Key Home/End");
      Set_Geometry (+S, (X => 0.0, Y => 0.0, Width => 200.0, Height => 24.0));
      Build_Items (+S);
      On_Key_Down (+S, SDL_SCANCODE_HOME, 0, False);
      Assert (Float_Slider.Get_Value (S) = 0.0,
              "Home should set value to min");
      On_Key_Down (+S, SDL_SCANCODE_END, 0, False);
      Assert (Float_Slider.Get_Value (S) = 100.0,
              "End should set value to max");
   end Test_Key_Home_End;

begin
   Put_Line ("========================================");
   Put_Line ("   Slider Widget Tests");
   Put_Line ("========================================");
   New_Line;

   Test_Create;
   Test_Set_Value;
   Test_Clamp_Above_Max;
   Test_Clamp_Below_Min;
   Test_Create_Clamps;
   Test_Set_Range;
   Test_Step;
   Test_Orientation;
   Test_Flags;
   Test_Callback;
   New_Line;

   Test_Int_Create;
   Test_Int_Clamp;
   Test_Int_Step;
   New_Line;

   Test_Key_Home_End;
   New_Line;

   Put_Line ("========================================");
   Put_Line ("   Test Summary");
   Put_Line ("========================================");
   Put_Line ("Total tests:" & Test_Count'Image);
   Put_Line ("Passed:     " & Pass_Count'Image);
   Put_Line ("Failed:     " & Fail_Count'Image);
   New_Line;

   if Fail_Count = 0 then
      Put_Line ("All tests PASSED!");
   else
      Put_Line ("Some tests FAILED!");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
   Put_Line ("========================================");
end Slider_Test;
