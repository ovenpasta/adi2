pragma Ada_2022;
with Ada.Text_IO;      use Ada.Text_IO;
with Adi.Core;        use Adi.Core;
with Adi.CSS_Styles;   use Adi.CSS_Styles;
with Adi.Widget;       use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.SDL.Events;   use Adi.SDL.Events;
with Adi.Widget.Slider;
with Adi.Widget.Integer_Slider;
with Test_Support;

procedure Slider_Test is

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
      Test_Support.Assert (Float_Slider.Get_Value (S) = 50.0,
              "Value should be 50.0");
      Test_Support.Assert (Float_Slider.Get_Min (S) = 0.0,
              "Min should be 0.0");
      Test_Support.Assert (Float_Slider.Get_Max (S) = 100.0,
              "Max should be 100.0");
   end Test_Create;

   procedure Test_Set_Value is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider Set_Value");
      Float_Slider.Set_Value (S, 75.0);
      Test_Support.Assert (Float_Slider.Get_Value (S) = 75.0,
              "Value should be 75.0 after Set_Value");
   end Test_Set_Value;

   procedure Test_Clamp_Above_Max is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider clamp above max");
      Float_Slider.Set_Value (S, 200.0);
      Test_Support.Assert (Float_Slider.Get_Value (S) = 100.0,
              "Value should be clamped to 100.0");
   end Test_Clamp_Above_Max;

   procedure Test_Clamp_Below_Min is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 10.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Float slider clamp below min");
      Float_Slider.Set_Value (S, 5.0);
      Test_Support.Assert (Float_Slider.Get_Value (S) = 10.0,
              "Value should be clamped to 10.0");
   end Test_Clamp_Below_Min;

   procedure Test_Create_Clamps is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 50.0, Value => 999.0);
   begin
      Put_Line ("Test: Float slider Create clamps value");
      Test_Support.Assert (Float_Slider.Get_Value (S) = 50.0,
              "Value should be clamped to max on create");
   end Test_Create_Clamps;

   procedure Test_Set_Range is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 80.0);
   begin
      Put_Line ("Test: Float slider Set_Range reclamps value");
      Float_Slider.Set_Range (S, Min => 0.0, Max => 50.0);
      Test_Support.Assert (Float_Slider.Get_Value (S) = 50.0,
              "Value should be reclamped to new max");
      Test_Support.Assert (Float_Slider.Get_Max (S) = 50.0,
              "Max should be updated to 50.0");
   end Test_Set_Range;

   procedure Test_Step is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider step default");
      Test_Support.Assert (Float_Slider.Get_Step (S) = 0.0,
              "Default step should be 0.0 (continuous)");
      Float_Slider.Set_Step (S, 10.0);
      Test_Support.Assert (Float_Slider.Get_Step (S) = 10.0,
              "Step should be 10.0 after Set_Step");
   end Test_Step;

   procedure Test_Orientation is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider orientation");
      Test_Support.Assert (Float_Slider.Get_Orientation (S) = Float_Slider.Horizontal,
              "Default orientation should be Horizontal");
      Float_Slider.Set_Orientation (S, Float_Slider.Vertical);
      Test_Support.Assert (Float_Slider.Get_Orientation (S) = Float_Slider.Vertical,
              "Orientation should be Vertical after set");
   end Test_Orientation;

   procedure Test_Flags is
      S : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float slider has correct flags");
      Test_Support.Assert (Has_Flag (+S, Clickable),
              "Slider should be Clickable");
      Test_Support.Assert (Has_Flag (+S, Focusable),
              "Slider should be Focusable");
      Test_Support.Assert (Has_Flag (+S, Visible),
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
      Test_Support.Assert (Callback_Fired, "Callback should fire on key right");
      Test_Support.Assert (Callback_Value > 0.0, "Value should increase on key right");
   end Test_Callback;

   --  The bar is the ::scroll part, drawn inside the widget rather than
   --  filling it, so a bar thinner than the knob still leaves the knob
   --  round and the whole widget height still takes the press.
   procedure Test_Track_Band is
      --  A part with no item is a failure to report, not one to raise
      --  on: First_Element would abort the binary and take every later
      --  test with it.
      Nothing : constant Item := (others => <>);

      function Only_Item (S : Float_Slider.Slider_Handle; P : Part_Kind)
        return Item
      is
         Found : constant Items_List.Vector := Get_Items_For_Part (+S, P);
      begin
         Test_Support.Assert (Natural (Found.Length) = 1,
                 "exactly one item for the part");
         return (if Found.Is_Empty then Nothing else Found.First_Element);
      end Only_Item;

      Thin : constant Part_Style_Array :=
        [Scroll_Part =>
           (Style   => From ((Height => Set (Size (Px (6.0))), others => <>))
                         .Build,
            Enabled => True),
         Knob_Part =>
           (Style   => From ((Width => Set (Size (Px (18.0))), others => <>))
                         .Build,
            Enabled => True),
         others => <>];

      Plain : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
      Banded : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: slider track band");

      --  Nothing said about ::scroll: the bar fills the box.
      Set_Geometry (+Plain, (X => 0.0, Y => 0.0, Width => 200.0, Height => 24.0));
      Build_Items (+Plain);
      Test_Support.Assert
        (Only_Item (Plain, Scroll_Part).Geometry.Height = 24.0,
         "an unstyled bar fills the widget");
      Test_Support.Assert
        (Only_Item (Plain, Indicator_Part).Geometry.Height = 24.0,
         "and so does the fill");

      Set_Geometry (+Banded, (X => 0.0, Y => 0.0, Width => 200.0, Height => 24.0));
      Set_Part_Styles (+Banded, Thin);
      Build_Items (+Banded);

      declare
         Bar  : constant Item := Only_Item (Banded, Scroll_Part);
         Fill : constant Item := Only_Item (Banded, Indicator_Part);
         Knob : constant Item := Only_Item (Banded, Knob_Part);
      begin
         Test_Support.Assert (Bar.Geometry.Height = 6.0,
                 "a bar takes the height ::scroll asks for");
         Test_Support.Assert (Bar.Geometry.Y = 9.0,
                 "and is centred in the widget");
         Test_Support.Assert (Bar.Geometry.Width = 200.0,
                 "the bar spans the widget");

         Test_Support.Assert (Fill.Geometry.Height = 6.0,
                 "the fill matches the bar rather than the widget");
         Test_Support.Assert (Fill.Geometry.Y = Bar.Geometry.Y,
                 "and sits on it");

         Test_Support.Assert (Knob.Geometry.Height = 24.0,
                 "the knob spans the widget, not the bar");
         Test_Support.Assert (Knob.Geometry.Width = 18.0,
                 "and takes its width from ::knob");
      end;

      --  The vertical branch reads ::scroll's width and gives the knob
      --  the widget's, which is the horizontal case turned a quarter.
      declare
         Upright : constant Float_Slider.Slider_Handle :=
           Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 0.0);
         Sideways : constant Part_Style_Array :=
           [Scroll_Part =>
              (Style   =>
                 From ((Width => Set (Size (Px (6.0))), others => <>)).Build,
               Enabled => True),
            Knob_Part =>
              (Style   =>
                 From ((Height => Set (Size (Px (18.0))), others => <>)).Build,
               Enabled => True),
            others => <>];
      begin
         Float_Slider.Set_Orientation (Upright, Float_Slider.Vertical);
         Set_Geometry
           (+Upright, (X => 0.0, Y => 0.0, Width => 24.0, Height => 200.0));
         Set_Part_Styles (+Upright, Sideways);
         Build_Items (+Upright);

         declare
            Bar  : constant Item := Only_Item (Upright, Scroll_Part);
            Fill : constant Item := Only_Item (Upright, Indicator_Part);
            Knob : constant Item := Only_Item (Upright, Knob_Part);
         begin
            Test_Support.Assert (Bar.Geometry.Width = 6.0,
                    "an upright bar takes the width ::scroll asks for");
            Test_Support.Assert (Bar.Geometry.X = 9.0,
                    "and is centred in the widget");
            Test_Support.Assert (Bar.Geometry.Height = 200.0,
                    "the bar spans the widget");
            Test_Support.Assert (Fill.Geometry.Width = 6.0,
                    "the fill matches the bar");
            Test_Support.Assert (Fill.Geometry.X = Bar.Geometry.X,
                    "and sits on it");
            Test_Support.Assert (Knob.Geometry.Width = 24.0,
                    "the knob spans the widget, not the bar");
            Test_Support.Assert (Knob.Geometry.Height = 18.0,
                    "and takes its height from ::knob");
         end;
      end;
   end Test_Track_Band;

   -------------------------------------------
   --  Integer slider tests
   -------------------------------------------
   package Int_Slider is new Adi.Widget.Integer_Slider (Integer);

   procedure Test_Int_Create is
      S : constant Int_Slider.Slider_Handle :=
        Int_Slider.Create_Handle (Min => 0, Max => 255, Value => 128);
   begin
      Put_Line ("Test: Integer slider Create");
      Test_Support.Assert (Int_Slider.Get_Value (S) = 128,
              "Value should be 128");
      Test_Support.Assert (Int_Slider.Get_Min (S) = 0,
              "Min should be 0");
      Test_Support.Assert (Int_Slider.Get_Max (S) = 255,
              "Max should be 255");
   end Test_Int_Create;

   procedure Test_Int_Clamp is
      S : constant Int_Slider.Slider_Handle :=
        Int_Slider.Create_Handle (Min => 0, Max => 100, Value => 200);
   begin
      Put_Line ("Test: Integer slider clamp");
      Test_Support.Assert (Int_Slider.Get_Value (S) = 100,
              "Value should be clamped to 100");
   end Test_Int_Clamp;

   procedure Test_Int_Step is
      S : constant Int_Slider.Slider_Handle :=
        Int_Slider.Create_Handle (Min => 0, Max => 100, Value => 50);
   begin
      Put_Line ("Test: Integer slider step");
      Int_Slider.Set_Step (S, 5);
      Test_Support.Assert (Int_Slider.Get_Step (S) = 5,
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
      Test_Support.Assert (Float_Slider.Get_Value (S) = 0.0,
              "Home should set value to min");
      On_Key_Down (+S, SDL_SCANCODE_END, 0, False);
      Test_Support.Assert (Float_Slider.Get_Value (S) = 100.0,
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
   Test_Track_Band;
   New_Line;

   Test_Int_Create;
   Test_Int_Clamp;
   Test_Int_Step;
   New_Line;

   Test_Key_Home_End;
   New_Line;

   Test_Support.Finish;
end Slider_Test;
