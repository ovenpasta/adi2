pragma Ada_2022;
with Ada.Text_IO;      use Ada.Text_IO;
with Adi.Core;         use Adi.Core;
with Adi.Widget;       use Adi.Widget;
with Adi.SDL.Events;   use Adi.SDL.Events;
with Adi.Widget.Text_Input;
with Adi.Widget.Value_Input;
with Adi.Widget.Integer_Value_Input;

procedure Value_Input_Test is

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

   --  Helper: get the text from a Value_Input via its Text_Input parent
   function Get_Text_Of (W : Adi.Widget.Text_Input.Text_Input_Widget'Class)
     return String
   is
   begin
      return Adi.Widget.Text_Input.Get_Text (W);
   end Get_Text_Of;

   -------------------------------------------
   --  Float value input tests
   -------------------------------------------
   package Float_Input is new Adi.Widget.Value_Input (Float);

   procedure Test_Create is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Float value input Create");
      Assert (Float_Input.Get_Value (V.all) = 50.0,
              "Value should be 50.0");
      Assert (Float_Input.Get_Min (V.all) = 0.0,
              "Min should be 0.0");
      Assert (Float_Input.Get_Max (V.all) = 100.0,
              "Max should be 100.0");
   end Test_Create;

   procedure Test_Set_Value is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float value input Set_Value");
      Float_Input.Set_Value (V.all, 75.0);
      Assert (Float_Input.Get_Value (V.all) = 75.0,
              "Value should be 75.0 after Set_Value");
   end Test_Set_Value;

   procedure Test_Clamp is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float value input clamp");
      Float_Input.Set_Value (V.all, 200.0);
      Assert (Float_Input.Get_Value (V.all) = 100.0,
              "Value should be clamped to 100.0");
      Float_Input.Set_Value (V.all, -10.0);
      Assert (Float_Input.Get_Value (V.all) = 0.0,
              "Value should be clamped to 0.0");
   end Test_Clamp;

   procedure Test_Create_Clamps is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 50.0, Value => 999.0);
   begin
      Put_Line ("Test: Float value input Create clamps value");
      Assert (Float_Input.Get_Value (V.all) = 50.0,
              "Value should be clamped to max on create");
   end Test_Create_Clamps;

   procedure Test_Set_Range is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 80.0);
   begin
      Put_Line ("Test: Float value input Set_Range reclamps");
      Float_Input.Set_Range (V.all, Min => 0.0, Max => 50.0);
      Assert (Float_Input.Get_Value (V.all) = 50.0,
              "Value should be reclamped to new max");
   end Test_Set_Range;

   procedure Test_Step is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float value input step");
      Assert (Float_Input.Get_Step (V.all) = 0.0,
              "Default step should be 0.0");
      Float_Input.Set_Step (V.all, 5.0);
      Assert (Float_Input.Get_Step (V.all) = 5.0,
              "Step should be 5.0 after Set_Step");
   end Test_Step;

   procedure Test_Flags is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 0.0);
   begin
      Put_Line ("Test: Float value input flags");
      Assert (Has_Flag (V.all, Clickable),
              "Should be Clickable");
      Assert (Has_Flag (V.all, Focusable),
              "Should be Focusable");
      Assert (Has_Flag (V.all, Visible),
              "Should be Visible");
   end Test_Flags;

   -----------------------------------------------
   --  Text <-> Value synchronization tests
   -----------------------------------------------

   procedure Test_Text_After_Create is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 50.0);
      Text : constant String := Get_Text_Of (V.all);
   begin
      Put_Line ("Test: Text after Create matches value (50.0)");
      Assert (Text = "50.0",
              "Text should be ""50.0"", got """ & Text & """");
   end Test_Text_After_Create;

   procedure Test_Text_After_Create_Zero is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => -10.0, Max => 10.0, Value => 0.0);
      Text : constant String := Get_Text_Of (V.all);
   begin
      Put_Line ("Test: Text after Create matches value (0.0)");
      Assert (Text = "0.0",
              "Text should be ""0.0"", got """ & Text & """");
   end Test_Text_After_Create_Zero;

   procedure Test_Text_After_Create_Negative is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => -100.0, Max => 100.0, Value => -22.5);
      Text : constant String := Get_Text_Of (V.all);
   begin
      Put_Line ("Test: Text after Create matches value (-22.5)");
      Assert (Text = "-22.5",
              "Text should be ""-22.5"", got """ & Text & """");
   end Test_Text_After_Create_Negative;

   procedure Test_Text_After_Set_Value is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 0.0);
      Text : String (1 .. 100);
      Len  : Natural;
   begin
      Put_Line ("Test: Text after Set_Value matches value");
      Float_Input.Set_Value (V.all, 75.0);
      declare
         T : constant String := Get_Text_Of (V.all);
      begin
         Assert (T = "75.0",
                 "Text should be ""75.0"", got """ & T & """");
      end;

      Float_Input.Set_Value (V.all, 0.5);
      declare
         T : constant String := Get_Text_Of (V.all);
      begin
         Assert (T = "0.5",
                 "Text should be ""0.5"", got """ & T & """");
      end;

      Float_Input.Set_Value (V.all, 100.0);
      declare
         T : constant String := Get_Text_Of (V.all);
      begin
         Assert (T = "100.0",
                 "Text should be ""100.0"", got """ & T & """");
      end;
   end Test_Text_After_Set_Value;

   procedure Test_Text_After_Set_Value_Clamped is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 50.0, Value => 25.0);
   begin
      Put_Line ("Test: Text after Set_Value with clamping");
      Float_Input.Set_Value (V.all, 999.0);
      declare
         T : constant String := Get_Text_Of (V.all);
      begin
         Assert (Float_Input.Get_Value (V.all) = 50.0,
                 "Value should be clamped to 50.0");
         Assert (T = "50.0",
                 "Text should be ""50.0"", got """ & T & """");
      end;
   end Test_Text_After_Set_Value_Clamped;

   --  Simulate: clear text, type new text, then lose focus
   procedure Test_Text_After_Type_And_Focus_Lost is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 10.0);
   begin
      Put_Line ("Test: Value after typing and focus lost");

      --  Simulate clearing and typing "42.5"
      Adi.Widget.Text_Input.Set_Text
        (Adi.Widget.Text_Input.Text_Input_Widget (V.all), "42.5");

      --  Value should NOT have changed yet (text was set directly)
      --  Only focus lost triggers parse
      V.On_Focus_Lost;

      declare
         Val  : constant Float := Float_Input.Get_Value (V.all);
         Text : constant String := Get_Text_Of (V.all);
      begin
         Assert (Val = 42.5,
                 "Value should be 42.5 after focus lost, got "
                 & Float'Image (Val));
         Assert (Text = "42.5",
                 "Text should be ""42.5"", got """ & Text & """");
      end;
   end Test_Text_After_Type_And_Focus_Lost;

   procedure Test_Text_After_Type_Integer_And_Focus_Lost is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 10.0);
   begin
      Put_Line ("Test: Value after typing integer string and focus lost");

      Adi.Widget.Text_Input.Set_Text
        (Adi.Widget.Text_Input.Text_Input_Widget (V.all), "75");

      V.On_Focus_Lost;

      declare
         Val  : constant Float := Float_Input.Get_Value (V.all);
         Text : constant String := Get_Text_Of (V.all);
      begin
         Assert (Val = 75.0,
                 "Value should be 75.0 after focus lost, got "
                 & Float'Image (Val));
         Assert (Text = "75.0",
                 "Text should be ""75.0"", got """ & Text & """");
      end;
   end Test_Text_After_Type_Integer_And_Focus_Lost;

   procedure Test_Text_After_Type_Over_Max_And_Focus_Lost is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 1.0, Value => 0.5);
   begin
      Put_Line ("Test: Value clamped after typing over max and focus lost");

      Adi.Widget.Text_Input.Set_Text
        (Adi.Widget.Text_Input.Text_Input_Widget (V.all), "5");

      V.On_Focus_Lost;

      declare
         Val  : constant Float := Float_Input.Get_Value (V.all);
         Text : constant String := Get_Text_Of (V.all);
      begin
         Assert (Val = 1.0,
                 "Value should be clamped to 1.0, got "
                 & Float'Image (Val));
         Assert (Text = "1.0",
                 "Text should be ""1.0"", got """ & Text & """");
      end;
   end Test_Text_After_Type_Over_Max_And_Focus_Lost;

   Callback_Fired : Boolean := False;
   Callback_Value : Float := 0.0;

   procedure On_Val_Changed
     (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Callback_Fired := True;
      Callback_Value := Value;
   end On_Val_Changed;

   procedure Test_Callback_Value_Matches_Text is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Callback value matches text after focus lost");
      Float_Input.Set_Step (V.all, 1.0);
      Float_Input.Connect_Value_Changed
        (V.all, On_Val_Changed'Unrestricted_Access);

      --  Type "33.3" and lose focus
      Adi.Widget.Text_Input.Set_Text
        (Adi.Widget.Text_Input.Text_Input_Widget (V.all), "33.3");
      Callback_Fired := False;
      V.On_Focus_Lost;

      declare
         Text : constant String := Get_Text_Of (V.all);
      begin
         Assert (Callback_Fired,
                 "Callback should fire on focus lost");
         Assert (Callback_Value = 33.3,
                 "Callback value should be 33.3, got "
                 & Float'Image (Callback_Value));
         Assert (Text = "33.3",
                 "Text should be ""33.3"", got """ & Text & """");
         Assert (Float_Input.Get_Value (V.all) = 33.3,
                 "Get_Value should be 33.3");
      end;
   end Test_Callback_Value_Matches_Text;

   procedure Test_Callback_On_Step is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Float value input callback on step");
      Float_Input.Set_Step (V.all, 1.0);
      Float_Input.Connect_Value_Changed
        (V.all, On_Val_Changed'Unrestricted_Access);
      Callback_Fired := False;
      Set_Geometry (V.all, (X => 0.0, Y => 0.0, Width => 120.0, Height => 28.0));
      V.On_Key_Down
        (Scancode => SDL_SCANCODE_UP,
         Key_Mod  => 0,
         Repeat   => False);
      Assert (Callback_Fired, "Callback should fire on Up key");
      Assert (Callback_Value > 50.0, "Value should increase");

      declare
         Text : constant String := Get_Text_Of (V.all);
         Val  : constant Float := Float_Input.Get_Value (V.all);
      begin
         Assert (Val = 51.0,
                 "Value should be 51.0 after step up, got "
                 & Float'Image (Val));
         Assert (Text = "51.0",
                 "Text should be ""51.0"" after step up, got """
                 & Text & """");
      end;
   end Test_Callback_On_Step;

   -------------------------------------------
   --  Integer value input tests
   -------------------------------------------
   package Int_Input is new Adi.Widget.Integer_Value_Input (Integer);

   procedure Test_Int_Create is
      V : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 255, Value => 128);
   begin
      Put_Line ("Test: Integer value input Create");
      Assert (Int_Input.Get_Value (V.all) = 128,
              "Value should be 128");
      Assert (Int_Input.Get_Min (V.all) = 0,
              "Min should be 0");
      Assert (Int_Input.Get_Max (V.all) = 255,
              "Max should be 255");
   end Test_Int_Create;

   procedure Test_Int_Clamp is
      V : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 100, Value => 200);
   begin
      Put_Line ("Test: Integer value input clamp");
      Assert (Int_Input.Get_Value (V.all) = 100,
              "Value should be clamped to 100");
   end Test_Int_Clamp;

   procedure Test_Int_Step is
      V : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 100, Value => 50);
   begin
      Put_Line ("Test: Integer value input step");
      Int_Input.Set_Step (V.all, 5);
      Assert (Int_Input.Get_Step (V.all) = 5,
              "Step should be 5");
   end Test_Int_Step;

   procedure Test_Int_Text_After_Create is
      V : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 255, Value => 128);
      Text : constant String := Get_Text_Of (V.all);
   begin
      Put_Line ("Test: Integer text after Create (128)");
      Assert (Text = "128",
              "Text should be ""128"", got """ & Text & """");
   end Test_Int_Text_After_Create;

   procedure Test_Int_Text_After_Set_Value is
      V : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 255, Value => 0);
   begin
      Put_Line ("Test: Integer text after Set_Value");
      Int_Input.Set_Value (V.all, 200);
      declare
         T : constant String := Get_Text_Of (V.all);
      begin
         Assert (T = "200",
                 "Text should be ""200"", got """ & T & """");
      end;
   end Test_Int_Text_After_Set_Value;

   procedure Test_Int_Text_After_Focus_Lost is
      V : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 255, Value => 100);
   begin
      Put_Line ("Test: Integer value after typing and focus lost");

      Adi.Widget.Text_Input.Set_Text
        (Adi.Widget.Text_Input.Text_Input_Widget (V.all), "42");

      V.On_Focus_Lost;

      declare
         Val  : constant Integer := Int_Input.Get_Value (V.all);
         Text : constant String := Get_Text_Of (V.all);
      begin
         Assert (Val = 42,
                 "Value should be 42, got " & Integer'Image (Val));
         Assert (Text = "42",
                 "Text should be ""42"", got """ & Text & """");
      end;
   end Test_Int_Text_After_Focus_Lost;

   procedure Test_Text_Filter is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => 0.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("Test: Text input filter (non-numeric rejected)");
      Set_Geometry (V.all,
        (X => 0.0, Y => 0.0, Width => 120.0, Height => 28.0));
      V.Build_Items;
      V.On_Text_Input ("abc");
      Assert (Float_Input.Get_Value (V.all) = 50.0,
              "Value should remain 50.0 after non-numeric input");
   end Test_Text_Filter;

   --  Test the exact round-trip: value -> text -> parse -> value
   procedure Test_Round_Trip is
      V : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => -100.0, Max => 100.0, Value => 0.0);
      Test_Values : constant array (Positive range <>) of Float :=
        (0.0, 1.0, -1.0, 0.5, -0.5, 22.5, 99.99, 100.0, -100.0,
         0.1, 0.01, 33.333);
   begin
      Put_Line ("Test: Round-trip value -> text -> parse -> value");
      for FV of Test_Values loop
         Float_Input.Set_Value (V.all, FV);
         declare
            Text : constant String := Get_Text_Of (V.all);
            Parsed : constant Float := Float'Value (Text);
         begin
            Assert (Parsed = Float_Input.Get_Value (V.all),
                    "Round-trip failed for " & Float'Image (FV)
                    & ": text=""" & Text
                    & """, parsed=" & Float'Image (Parsed)
                    & ", get_value=" & Float'Image (Float_Input.Get_Value (V.all)));
         end;
      end loop;
   end Test_Round_Trip;

   -------------------------------------------
   --  Text_Input label tests
   -------------------------------------------

   procedure Test_Label_API is
      W : constant Adi.Widget.Text_Input.Text_Input_Widget_Access :=
        Adi.Widget.Text_Input.Create;
   begin
      Put_Line ("Test: Set_Label / Get_Label");
      Assert (Adi.Widget.Get_Label (W.all) = "",
              "Label should be empty after Create");
      Adi.Widget.Set_Label (W.all, "Name");
      Assert (Adi.Widget.Get_Label (W.all) = "Name",
              "Label should be 'Name' after Set_Label");
      Adi.Widget.Set_Label (W.all, "");
      Assert (Adi.Widget.Get_Label (W.all) = "",
              "Label should be empty after Set_Label('')");
   end Test_Label_API;

   procedure Test_Label_Create is
      W : constant Adi.Widget.Text_Input.Text_Input_Widget_Access :=
        Adi.Widget.Text_Input.Create (Label => "Email");
   begin
      Put_Line ("Test: Create with label parameter");
      Assert (Adi.Widget.Get_Label (W.all) = "Email",
              "Label should be 'Email' from Create");
   end Test_Label_Create;

   procedure Test_Label_Build_Items_Count is
      W : constant Adi.Widget.Text_Input.Text_Input_Widget_Access :=
        Adi.Widget.Text_Input.Create (Label => "Test");
   begin
      Put_Line ("Test: Rebuild_All_Items creates 6 items (panel+sel+text+cursor+lbl_bg+lbl)");
      Set_Geometry (W.all,
        (X => 10.0, Y => 20.0, Width => 200.0, Height => 40.0));
      Rebuild_All_Items (W.all);
      Assert (Item_Count (W.all) = 6,
              "Should have exactly 6 items, got" & Item_Count (W.all)'Image);
      --  Second call should not add more
      Rebuild_All_Items (W.all);
      Assert (Item_Count (W.all) = 6,
              "Should still have 6 items after second Rebuild_All_Items");
   end Test_Label_Build_Items_Count;

   procedure Test_Label_Empty_Geometry is
      use Adi.Widget.Items_List;
      W : constant Adi.Widget.Text_Input.Text_Input_Widget_Access :=
        Adi.Widget.Text_Input.Create;
      Label_Items : Items_List.Vector;
   begin
      Put_Line ("Test: Empty label -> no label items created");
      Set_Geometry (W.all,
        (X => 10.0, Y => 20.0, Width => 200.0, Height => 40.0));
      Rebuild_All_Items (W.all);
      Label_Items := Get_Items_For_Part (W.all, Label_Part);
      Assert (Natural (Label_Items.Length) = 0,
              "Should have 0 label-part items when label is empty");
   end Test_Label_Empty_Geometry;

   procedure Test_Label_Items_Part is
      use Adi.Widget.Items_List;
      W : constant Adi.Widget.Text_Input.Text_Input_Widget_Access :=
        Adi.Widget.Text_Input.Create (Label => "Addr");
      Label_Items : Items_List.Vector;
   begin
      Put_Line ("Test: Label items have Label_Part");
      Set_Geometry (W.all,
        (X => 0.0, Y => 0.0, Width => 200.0, Height => 40.0));
      Rebuild_All_Items (W.all);
      Label_Items := Get_Items_For_Part (W.all, Label_Part);
      Assert (Natural (Label_Items.Length) = 2,
              "Should have exactly 2 label-part items");
      --  First should be panel (background), second should be text
      Assert (Label_Items.Element (1).Kind = Panel_Item,
              "Label item 1 should be Panel_Item");
      Assert (Label_Items.Element (2).Kind = Text_Item,
              "Label item 2 should be Text_Item");
   end Test_Label_Items_Part;

begin
   Put_Line ("========================================");
   Put_Line ("   Value Input Widget Tests");
   Put_Line ("========================================");
   New_Line;

   Test_Create;
   Test_Set_Value;
   Test_Clamp;
   Test_Create_Clamps;
   Test_Set_Range;
   Test_Step;
   Test_Flags;
   New_Line;

   Put_Line ("--- Text <-> Value Sync Tests ---");
   Test_Text_After_Create;
   Test_Text_After_Create_Zero;
   Test_Text_After_Create_Negative;
   Test_Text_After_Set_Value;
   Test_Text_After_Set_Value_Clamped;
   Test_Text_After_Type_And_Focus_Lost;
   Test_Text_After_Type_Integer_And_Focus_Lost;
   Test_Text_After_Type_Over_Max_And_Focus_Lost;
   Test_Callback_Value_Matches_Text;
   Test_Callback_On_Step;
   Test_Round_Trip;
   New_Line;

   Test_Int_Create;
   Test_Int_Clamp;
   Test_Int_Step;
   Test_Int_Text_After_Create;
   Test_Int_Text_After_Set_Value;
   Test_Int_Text_After_Focus_Lost;
   New_Line;

   Test_Text_Filter;
   New_Line;

   Put_Line ("--- Text_Input Label Tests ---");
   Test_Label_API;
   Test_Label_Create;
   Test_Label_Build_Items_Count;
   Test_Label_Empty_Geometry;
   Test_Label_Items_Part;
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
   end if;
   Put_Line ("========================================");
end Value_Input_Test;
