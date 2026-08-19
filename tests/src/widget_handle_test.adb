pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Test_Support;
with Adi.Core;
with Adi.Widget;          use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Button;
with Adi.Widget.Button.Switch;
with Adi.Widget.Slider;
with Adi.Widget.Value_Input;
with Adi.Widget.Integer_Value_Input;
with Adi.Image;
with Adi.Animated_Image;
with Adi.RLottie;
with Adi.Widget.Image;
with Adi.Widget.Animated_Image;
with Adi.Widget.RLottie;
with Adi.Widget.Html_View;
with Adi.Widget.Animated_Widget;
with Adi.Widget.Text_Input;
with Adi.Widget.Text_Editor;
with Adi.Widget.Combo_Box;
with Adi.Widget.Dialog;
with Adi.Widget.Stack;
with Adi.Widget.List_Box;

procedure Widget_Handle_Test is

   package Float_Slider is new Adi.Widget.Slider (Float);
   package Float_Input is new Adi.Widget.Value_Input (Float);
   package Int_Input is new Adi.Widget.Integer_Value_Input (Integer);

   type Test_Page is (Page_A, Page_B);
   package Test_Stack is new Adi.Widget.Stack (Test_Page);
   package Test_List_Box is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget);

   ---------------------------------------------------------------------------
   --  Test: Freshly created widgets have valid handles
   ---------------------------------------------------------------------------

   procedure Test_Create_Handle is
      Btn : constant Button.Button_Widget_Access := Button.Create ("OK");
      H   : constant Widget_Handle := Get_Handle (Btn.all);
   begin
      Put_Line ("-- Create handle tests --");
      Test_Support.Assert (Is_Valid (H), "handle from Create should be valid");

      --  Create another widget, handles should be distinct
      declare
         Lbl : constant Label.Label_Widget_Access := Label.Create ("Hi");
         H2  : constant Widget_Handle := Get_Handle (Lbl.all);
      begin
         Test_Support.Assert (Is_Valid (H2), "label handle should be valid");
      end;
   end Test_Create_Handle;

   ---------------------------------------------------------------------------
   --  Test: Null_Handle is invalid
   ---------------------------------------------------------------------------

   procedure Test_Null_Handle is
   begin
      Put_Line ("-- Null_Handle tests --");
      Test_Support.Assert (not Is_Valid (Null_Handle), "Null_Handle should be invalid");
   end Test_Null_Handle;

   ---------------------------------------------------------------------------
   --  Test: Destroy makes handle stale
   ---------------------------------------------------------------------------

   procedure Test_Destroy_Stale is
      Btn : constant Button.Button_Widget_Access := Button.Create ("X");
      H   : Widget_Handle := Get_Handle (Btn.all);
   begin
      Put_Line ("-- Destroy/stale tests --");
      Test_Support.Assert (Is_Valid (H), "before destroy: valid");
      Destroy (H);
      Test_Support.Assert (not Is_Valid (H), "after destroy: stale");
   end Test_Destroy_Stale;

   ---------------------------------------------------------------------------
   --  Test: Destroy with parent detaches child
   ---------------------------------------------------------------------------

   procedure Test_Destroy_Detaches is
      Root : constant Box.Box_Widget_Access := Box.Create;
      Btn  : constant Button.Button_Widget_Access := Button.Create ("Go");
      H    : Widget_Handle := Get_Handle (Btn.all);
   begin
      Put_Line ("-- Destroy detaches from parent --");
      Add_Child (Get_Handle (Root.all), H);
      Test_Support.Assert (Child_Count (Get_Handle (Root.all)) = 1, "child added");

      Destroy (H);
      Test_Support.Assert (Child_Count (Get_Handle (Root.all)) = 0,
              "child removed after destroy, got" &
              Child_Count (Get_Handle (Root.all))'Image);
      Test_Support.Assert (not Is_Valid (H), "destroyed handle is stale");
   end Test_Destroy_Detaches;

   ---------------------------------------------------------------------------
   --  Test: Destroy recursively marks children
   ---------------------------------------------------------------------------

   procedure Test_Destroy_Recursive is
      Root : constant Box.Box_Widget_Access := Box.Create;
      C1   : constant Label.Label_Widget_Access := Label.Create ("A");
      C2   : constant Label.Label_Widget_Access := Label.Create ("B");

      H_Root : Widget_Handle := Get_Handle (Root.all);
      H_C1   : constant Widget_Handle := Get_Handle (C1.all);
      H_C2   : constant Widget_Handle := Get_Handle (C2.all);
   begin
      Put_Line ("-- Destroy recursive tests --");
      Add_Child (H_Root, H_C1);
      Add_Child (H_Root, H_C2);
      Test_Support.Assert (Is_Valid (H_C1), "child1 valid before");
      Test_Support.Assert (Is_Valid (H_C2), "child2 valid before");

      Destroy (H_Root);
      --  Children should be marked for destruction too
      Test_Support.Assert (not Is_Valid (H_Root), "root destroyed");
      Test_Support.Assert (not Is_Valid (H_C1), "child1 destroyed recursively");
      Test_Support.Assert (not Is_Valid (H_C2), "child2 destroyed recursively");
   end Test_Destroy_Recursive;

   ---------------------------------------------------------------------------
   --  Test: Pump drains deferred widget destroys
   ---------------------------------------------------------------------------

   procedure Test_Pump is
      Btn : constant Button.Button_Widget_Access := Button.Create ("P");
      H   : Widget_Handle := Get_Handle (Btn.all);
   begin
      Put_Line ("-- Pump tests --");
      Test_Support.Assert (Is_Valid (H), "before destroy: valid");
      Destroy (H);
      Pump_Widget_Store;
      Test_Support.Assert (not Is_Valid (H), "after destroy+pump: stale");
   end Test_Pump;

   ---------------------------------------------------------------------------
   --  Test: Get_Handle round-trips correctly
   ---------------------------------------------------------------------------

   procedure Test_Get_Handle_Roundtrip is
      Lbl : constant Label.Label_Widget_Access := Label.Create ("RT");
      H   : constant Widget_Handle := Get_Handle (Lbl.all);
   begin
      Put_Line ("-- Get_Handle roundtrip tests --");
      Test_Support.Assert (Is_Valid (H), "handle valid");

      --  Get handle again from the same widget should match
      declare
         H2 : constant Widget_Handle := Get_Handle (Lbl.all);
      begin
         Test_Support.Assert (Is_Valid (H2), "second Get_Handle also valid");
      end;
   end Test_Get_Handle_Roundtrip;

   ---------------------------------------------------------------------------
   --  Test: Resolve_Handle returns non-null for valid handle
   ---------------------------------------------------------------------------

   procedure Test_Resolve_Handle is
      Btn : constant Button.Button_Widget_Access := Button.Create ("RH");
      H   : constant Widget_Handle := Get_Handle (Btn.all);
      Ptr : Widget_Access;
   begin
      Put_Line ("-- Resolve_Handle tests --");
      Ptr := Resolve_Handle (H);
      Test_Support.Assert (Ptr /= null, "Resolve_Handle returns non-null for valid handle");
      Test_Support.Assert (Ptr = Widget_Access (Btn),
              "Resolve_Handle returns same pointer");

      --  Resolve null handle should return null
      Test_Support.Assert (Resolve_Handle (Null_Handle) = null,
              "Resolve_Handle(Null_Handle) returns null");
   end Test_Resolve_Handle;

   ---------------------------------------------------------------------------
   --  Test: Create_Handle returns valid handle
   ---------------------------------------------------------------------------

   procedure Test_Create_Handle_Fn is
      H : constant Widget_Handle := Button.To_Widget_Handle
                                          (Button.Create_Handle ("CH"));
   begin
      Put_Line ("-- Create_Handle function tests --");
      Test_Support.Assert (Is_Valid (H), "Create_Handle returns valid handle");

      --  Resolve should give non-null
      Test_Support.Assert (Resolve_Handle (H) /= null,
              "Create_Handle handle resolves to non-null");
   end Test_Create_Handle_Fn;

   ---------------------------------------------------------------------------
   --  Test: Add_Child with Widget_Handle
   ---------------------------------------------------------------------------

   procedure Test_Add_Child_Handle is
      Root : constant Box.Box_Widget_Access := Box.Create;
      H    : constant Widget_Handle := Label.To_Widget_Handle
                                          (Label.Create_Handle ("ACH"));
   begin
      Put_Line ("-- Add_Child(handle) tests --");
      Add_Child (Get_Handle (Root.all), H);
      Test_Support.Assert (Child_Count (Get_Handle (Root.all)) = 1,
              "Add_Child with handle adds child, got" &
              Child_Count (Get_Handle (Root.all))'Image);
   end Test_Add_Child_Handle;

   ---------------------------------------------------------------------------
   --  Test: Add_Child with Null_Handle is a no-op
   ---------------------------------------------------------------------------

   procedure Test_Add_Child_Null_Handle is
      Root : constant Box.Box_Widget_Access := Box.Create;
   begin
      Put_Line ("-- Add_Child(Null_Handle) tests --");
      Add_Child (Get_Handle (Root.all), Null_Handle);
      Test_Support.Assert (Child_Count (Get_Handle (Root.all)) = 0,
              "Add_Child with Null_Handle is no-op, got" &
              Child_Count (Get_Handle (Root.all))'Image);
   end Test_Add_Child_Null_Handle;

   ---------------------------------------------------------------------------
   --  Test: Label_Handle typed create and methods
   ---------------------------------------------------------------------------

   procedure Test_Label_Handle is
      H : constant Label.Label_Handle := Label.Create_Handle ("Typed");
      W : constant Widget_Handle := Label.To_Widget_Handle (H);
   begin
      Put_Line ("-- Label_Handle tests --");
      Test_Support.Assert (Label.Is_Valid (H), "Label_Handle should be valid");
      Test_Support.Assert (Is_Valid (W), "To_Widget_Handle should be valid");

      --  Get/Set text via handle
      Test_Support.Assert (Label.Get_Text (H) = "Typed",
              "Get_Text via handle should return initial text");
      Label.Set_Text (H, "Changed");
      Test_Support.Assert (Label.Get_Text (H) = "Changed",
              "Get_Text via handle should return updated text");

      --  Try_As_Label roundtrip
      declare
         H2 : constant Label.Label_Handle := Label.Try_As_Label (W);
      begin
         Test_Support.Assert (Label.Is_Valid (H2),
                 "Try_As_Label on label handle should succeed");
         Test_Support.Assert (Label.Get_Text (H2) = "Changed",
                 "Try_As_Label roundtrip preserves identity");
      end;

      --  Null handle
      Test_Support.Assert (not Label.Is_Valid (Label.Null_Label_Handle),
              "Null_Label_Handle should be invalid");
   end Test_Label_Handle;

   ---------------------------------------------------------------------------
   --  Test: Button_Handle typed create and methods
   ---------------------------------------------------------------------------

   procedure On_Test_Click (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      null;
   end On_Test_Click;

   procedure Test_Button_Handle is
      H : constant Button.Button_Handle := Button.Create_Handle ("Click Me");
      W : constant Widget_Handle := Button.To_Widget_Handle (H);
   begin
      Put_Line ("-- Button_Handle tests --");
      Test_Support.Assert (Button.Is_Valid (H), "Button_Handle should be valid");
      Test_Support.Assert (Is_Valid (W), "To_Widget_Handle should be valid");

      --  Set_Toggleable / Set_Toggled via handle
      Button.Set_Toggleable (H);
      Button.Set_Toggled (H, True);

      --  Connect_Clicked via handle (function form returns connection id)
      declare
         Id : constant Button.Click_Signals.Connection_Id :=
           Button.Connect_Clicked (H, On_Test_Click'Unrestricted_Access);
         pragma Unreferenced (Id);
      begin
         Test_Support.Assert (True, "Connect_Clicked via handle compiled and ran");
      end;

      --  Try_As_Button roundtrip
      declare
         H2 : constant Button.Button_Handle := Button.Try_As_Button (W);
      begin
         Test_Support.Assert (Button.Is_Valid (H2),
                 "Try_As_Button on button handle should succeed");
      end;
   end Test_Button_Handle;

   ---------------------------------------------------------------------------
   --  Test: Box_Handle typed create and Add_Child
   ---------------------------------------------------------------------------

   procedure Test_Box_Handle is
      H  : constant Box.Box_Handle := Box.Create_Handle;
      WH : constant Widget_Handle := Box.To_Widget_Handle (H);
      Ch : constant Widget_Handle :=
        Label.To_Widget_Handle (Label.Create_Handle ("child"));
   begin
      Put_Line ("-- Box_Handle tests --");
      Test_Support.Assert (Box.Is_Valid (H), "Box_Handle should be valid");
      Test_Support.Assert (Is_Valid (WH), "To_Widget_Handle should be valid");

      --  Add_Child via typed handle
      Box.Add_Child (H, Ch);
      declare
         Ptr : constant Widget_Access := Resolve_Handle (WH);
      begin
         Test_Support.Assert (Ptr /= null and then Child_Count (WH) = 1,
                 "Add_Child via Box_Handle should add child");
      end;

      --  Try_As_Box roundtrip
      declare
         H2 : constant Box.Box_Handle := Box.Try_As_Box (WH);
      begin
         Test_Support.Assert (Box.Is_Valid (H2),
                 "Try_As_Box on box handle should succeed");
      end;
   end Test_Box_Handle;

   ---------------------------------------------------------------------------
   --  Test: Try_As_Foo on wrong type returns null handle
   ---------------------------------------------------------------------------

   procedure Test_Try_As_Wrong_Type is
      LH : constant Label.Label_Handle := Label.Create_Handle ("lbl");
      WH : constant Widget_Handle := Label.To_Widget_Handle (LH);

      --  Try to downcast a Label to Button — should fail
      BH : constant Button.Button_Handle := Button.Try_As_Button (WH);
   begin
      Put_Line ("-- Try_As wrong type tests --");
      Test_Support.Assert (not Button.Is_Valid (BH),
              "Try_As_Button on Label should return null handle");

      --  Try to downcast a Label to Box — should fail
      declare
         XH : constant Box.Box_Handle := Box.Try_As_Box (WH);
      begin
         Test_Support.Assert (not Box.Is_Valid (XH),
                 "Try_As_Box on Label should return null handle");
      end;

      --  Try_As_Label on a Button should fail
      declare
         BtnH : constant Button.Button_Handle := Button.Create_Handle ("b");
         BtnW : constant Widget_Handle := Button.To_Widget_Handle (BtnH);
         LH2  : constant Label.Label_Handle := Label.Try_As_Label (BtnW);
      begin
         --  Button inherits from Label, so Try_As_Label should succeed!
         Test_Support.Assert (Label.Is_Valid (LH2),
                 "Try_As_Label on Button should succeed (Button is a Label)");
      end;
   end Test_Try_As_Wrong_Type;

   ---------------------------------------------------------------------------
   --  Test: Slider_Handle typed create and methods
   ---------------------------------------------------------------------------

   procedure On_Slider_Changed (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W, Value);
   begin
      null;
   end On_Slider_Changed;

   procedure Test_Slider_Handle is
      H  : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 50.0);
      WH : constant Widget_Handle := Float_Slider.To_Widget_Handle (H);
   begin
      Put_Line ("-- Slider_Handle tests --");
      Test_Support.Assert (Float_Slider.Is_Valid (H), "Slider_Handle should be valid");
      Test_Support.Assert (Is_Valid (WH), "To_Widget_Handle should be valid");

      --  Get/Set value via handle
      Test_Support.Assert (Float_Slider.Get_Value (H) = 50.0,
              "Get_Value via handle should return initial value");
      Float_Slider.Set_Value (H, 75.0);
      Test_Support.Assert (Float_Slider.Get_Value (H) = 75.0,
              "Get_Value via handle should return updated value");

      --  Connect_Changed via handle (function form)
      declare
         Id : constant Float_Slider.Value_Changed_Connection_Id :=
           Float_Slider.Connect_Changed
             (H, On_Slider_Changed'Unrestricted_Access);
         pragma Unreferenced (Id);
      begin
         Test_Support.Assert (True, "Connect_Changed via handle compiled and ran");
      end;

      --  Try_As_Slider roundtrip
      declare
         H2 : constant Float_Slider.Slider_Handle :=
           Float_Slider.Try_As_Slider (WH);
      begin
         Test_Support.Assert (Float_Slider.Is_Valid (H2),
                 "Try_As_Slider on slider handle should succeed");
         Test_Support.Assert (Float_Slider.Get_Value (H2) = 75.0,
                 "Try_As_Slider roundtrip preserves identity");
      end;

      --  Try_As_Slider on wrong type should fail
      declare
         LH : constant Label.Label_Handle := Label.Create_Handle ("nope");
         LW : constant Widget_Handle := Label.To_Widget_Handle (LH);
         SH : constant Float_Slider.Slider_Handle :=
           Float_Slider.Try_As_Slider (LW);
      begin
         Test_Support.Assert (not Float_Slider.Is_Valid (SH),
                 "Try_As_Slider on Label should return null handle");
      end;

      --  Null handle
      Test_Support.Assert (not Float_Slider.Is_Valid (Float_Slider.Null_Slider_Handle),
              "Null_Slider_Handle should be invalid");
   end Test_Slider_Handle;

   ---------------------------------------------------------------------------
   --  Test: "+" operator returns valid Widget_Handle for all typed handles
   ---------------------------------------------------------------------------

   procedure Test_Plus_Operator is
      use type Adi.Widget.Box.Box_Handle;
      use type Adi.Widget.Label.Label_Handle;
      use type Adi.Widget.Button.Button_Handle;
      use type Float_Slider.Slider_Handle;
      use type Float_Input.Value_Input_Handle;

      BxH : constant Adi.Widget.Box.Box_Handle := Box.Create_Handle;
      LbH : constant Adi.Widget.Label.Label_Handle :=
        Label.Create_Handle ("plus");
      BtH : constant Adi.Widget.Button.Button_Handle :=
        Button.Create_Handle ("plus");
      SlH : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 1.0, Value => 0.5);
      ViH : constant Float_Input.Value_Input_Handle :=
        Float_Input.Create_Handle (Min => 0.0, Max => 1.0, Value => 0.5);
   begin
      Put_Line ("-- Plus operator tests --");
      Test_Support.Assert (Is_Valid (+BxH), """+""(Box_Handle) returns valid Widget_Handle");
      Test_Support.Assert (Is_Valid (+LbH),
              """+""(Label_Handle) returns valid Widget_Handle");
      Test_Support.Assert (Is_Valid (+BtH),
              """+""(Button_Handle) returns valid Widget_Handle");
      Test_Support.Assert (Is_Valid (+SlH),
              """+""(Slider_Handle) returns valid Widget_Handle");
      Test_Support.Assert (Is_Valid (+ViH),
              """+""(Value_Input_Handle) returns valid Widget_Handle");
   end Test_Plus_Operator;

   ---------------------------------------------------------------------------
   --  Test: Full Slider handle overloads
   ---------------------------------------------------------------------------

   procedure Test_Slider_Full_Overloads is
      H : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.0, Max => 100.0, Value => 50.0);
   begin
      Put_Line ("-- Slider full overloads tests --");

      --  Set_Step / Get_Step
      Float_Slider.Set_Step (H, 5.0);
      Test_Support.Assert (Float_Slider.Get_Step (H) = 5.0,
              "Slider Set_Step/Get_Step via handle");

      --  Set_Range / Get_Min / Get_Max
      Float_Slider.Set_Range (H, 10.0, 200.0);
      Test_Support.Assert (Float_Slider.Get_Min (H) = 10.0,
              "Slider Get_Min via handle after Set_Range");
      Test_Support.Assert (Float_Slider.Get_Max (H) = 200.0,
              "Slider Get_Max via handle after Set_Range");

      --  Value should be clamped to new range
      Test_Support.Assert (Float_Slider.Get_Value (H) >= 10.0
              and then Float_Slider.Get_Value (H) <= 200.0,
              "Slider value clamped after Set_Range");

      --  Disconnect_Changed
      declare
         Id : constant Float_Slider.Value_Changed_Connection_Id :=
           Float_Slider.Connect_Changed
             (H, On_Slider_Changed'Unrestricted_Access);
      begin
         Float_Slider.Disconnect_Changed (H, Id);
         Test_Support.Assert (True, "Disconnect_Changed via handle");
      end;
   end Test_Slider_Full_Overloads;

   ---------------------------------------------------------------------------
   --  Test: Full Button handle overloads
   ---------------------------------------------------------------------------

   procedure On_Test_Toggle (W : Widget_Handle; Toggled : Boolean) is
      pragma Unreferenced (W, Toggled);
   begin
      null;
   end On_Test_Toggle;

   procedure Test_Button_Full_Overloads is
      H : constant Button.Button_Handle := Button.Create_Handle ("Btn");
   begin
      Put_Line ("-- Button full overloads tests --");

      --  Is_Toggleable (initially false)
      Test_Support.Assert (not Button.Is_Toggleable (H),
              "Button not toggleable initially");

      --  Set_Toggleable + Is_Toggleable
      Button.Set_Toggleable (H);
      Test_Support.Assert (Button.Is_Toggleable (H),
              "Button toggleable after Set_Toggleable");

      --  Is_Toggled (initially false)
      Test_Support.Assert (not Button.Is_Toggled (H),
              "Button not toggled initially");

      --  Set_Toggled + Is_Toggled
      Button.Set_Toggled (H, True);
      Test_Support.Assert (Button.Is_Toggled (H),
              "Button toggled after Set_Toggled(True)");

      --  Set_Text / Get_Text
      Button.Set_Text (H, "NewText");
      Test_Support.Assert (Button.Get_Text (H) = "NewText",
              "Button Set_Text/Get_Text via handle");

      --  Connect_Toggled / Disconnect_Toggled
      declare
         Id : constant Button.Toggle_Signals.Connection_Id :=
           Button.Connect_Toggled
             (H, On_Test_Toggle'Unrestricted_Access);
      begin
         Button.Disconnect_Toggled (H, Id);
         Test_Support.Assert (True, "Connect/Disconnect_Toggled via handle");
      end;

      --  Disconnect_Clicked
      declare
         Id : constant Button.Click_Signals.Connection_Id :=
           Button.Connect_Clicked
             (H, On_Test_Click'Unrestricted_Access);
      begin
         Button.Disconnect_Clicked (H, Id);
         Test_Support.Assert (True, "Connect/Disconnect_Clicked via handle");
      end;
   end Test_Button_Full_Overloads;

   ---------------------------------------------------------------------------
   --  Test: Value_Input_Handle (float)
   ---------------------------------------------------------------------------

   procedure On_Float_Input_Changed (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W, Value);
   begin
      null;
   end On_Float_Input_Changed;

   procedure Test_Value_Input_Handle is
      H : constant Float_Input.Value_Input_Handle :=
        Float_Input.Create_Handle (Min => 0.0, Max => 100.0, Value => 42.0);
   begin
      Put_Line ("-- Value_Input_Handle tests --");
      Test_Support.Assert (Float_Input.Is_Valid (H),
              "Value_Input_Handle should be valid");

      --  Get/Set value
      Test_Support.Assert (Float_Input.Get_Value (H) = 42.0,
              "Get_Value via handle should return initial value");
      Float_Input.Set_Value (H, 77.0);
      Test_Support.Assert (Float_Input.Get_Value (H) = 77.0,
              "Get_Value via handle should return updated value");

      --  Set_Step / Get_Step
      Float_Input.Set_Step (H, 0.5);
      Test_Support.Assert (Float_Input.Get_Step (H) = 0.5,
              "Set_Step/Get_Step via handle");

      --  Set_Range / Get_Min / Get_Max
      Float_Input.Set_Range (H, 10.0, 50.0);
      Test_Support.Assert (Float_Input.Get_Min (H) = 10.0,
              "Get_Min via handle after Set_Range");
      Test_Support.Assert (Float_Input.Get_Max (H) = 50.0,
              "Get_Max via handle after Set_Range");

      --  Value should be clamped
      Test_Support.Assert (Float_Input.Get_Value (H) <= 50.0,
              "Value clamped after Set_Range");

      --  Connect / Disconnect
      declare
         Id : constant Float_Input.Value_Changed_Connection_Id :=
           Float_Input.Connect_Value_Changed
             (H, On_Float_Input_Changed'Unrestricted_Access);
      begin
         Float_Input.Disconnect_Value_Changed (H, Id);
         Test_Support.Assert (True, "Connect/Disconnect_Value_Changed via handle");
      end;

      --  Try_As roundtrip
      declare
         WH : constant Widget_Handle := Float_Input.To_Widget_Handle (H);
         H2 : constant Float_Input.Value_Input_Handle :=
           Float_Input.Try_As_Value_Input (WH);
      begin
         Test_Support.Assert (Float_Input.Is_Valid (H2),
                 "Try_As_Value_Input roundtrip should succeed");
      end;

      --  Null handle
      Test_Support.Assert (not Float_Input.Is_Valid (Float_Input.Null_Value_Input_Handle),
              "Null_Value_Input_Handle should be invalid");
   end Test_Value_Input_Handle;

   ---------------------------------------------------------------------------
   --  Test: Integer Value_Input_Handle
   ---------------------------------------------------------------------------

   procedure On_Int_Input_Changed (W : Widget_Handle; Value : Integer) is
      pragma Unreferenced (W, Value);
   begin
      null;
   end On_Int_Input_Changed;

   procedure Test_Integer_Value_Input_Handle is
      H : constant Int_Input.Value_Input_Handle :=
        Int_Input.Create_Handle (Min => 0, Max => 255, Value => 128);
   begin
      Put_Line ("-- Integer Value_Input_Handle tests --");
      Test_Support.Assert (Int_Input.Is_Valid (H),
              "Int Value_Input_Handle should be valid");

      --  Get/Set value
      Test_Support.Assert (Int_Input.Get_Value (H) = 128,
              "Int Get_Value via handle");
      Int_Input.Set_Value (H, 200);
      Test_Support.Assert (Int_Input.Get_Value (H) = 200,
              "Int Get_Value via handle after set");

      --  Set_Step / Get_Step
      Int_Input.Set_Step (H, 5);
      Test_Support.Assert (Int_Input.Get_Step (H) = 5,
              "Int Set_Step/Get_Step via handle");

      --  Connect / Disconnect
      declare
         Id : constant Int_Input.Value_Changed_Connection_Id :=
           Int_Input.Connect_Value_Changed
             (H, On_Int_Input_Changed'Unrestricted_Access);
      begin
         Int_Input.Disconnect_Value_Changed (H, Id);
         Test_Support.Assert (True, "Int Connect/Disconnect_Value_Changed via handle");
      end;
   end Test_Integer_Value_Input_Handle;

   ---------------------------------------------------------------------------
   --  Test: Image_Handle
   ---------------------------------------------------------------------------

   procedure Test_Image_Handle is
      use Adi.Widget.Image;
      H  : constant Image_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Image_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Image_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "Image To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Image_Handle := Try_As_Image (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Image roundtrip succeeds");
      end;

      --  "+" operator
      Test_Support.Assert (Adi.Widget.Is_Valid (+H),
              """+""(Image_Handle) returns valid Widget_Handle");

      --  Get_Image should be null initially
      declare
         use type Adi.Image.Image_Access;
      begin
         Test_Support.Assert (Get_Image (H) = null, "Image initially null");
      end;

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Image_Handle),
              "Null_Image_Handle should be invalid");
   end Test_Image_Handle;

   ---------------------------------------------------------------------------
   --  Test: Animated_Image_Handle
   ---------------------------------------------------------------------------

   procedure Test_Animated_Image_Handle is
      use Adi.Widget.Animated_Image;
      H  : constant Animated_Image_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Animated_Image_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Animated_Image_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "AI To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Animated_Image_Handle :=
           Try_As_Animated_Image (WH);
      begin
         Test_Support.Assert (Is_Valid (H2),
                 "Try_As_Animated_Image roundtrip succeeds");
      end;

      --  "+" operator
      Test_Support.Assert (Adi.Widget.Is_Valid (+H),
              """+""(Animated_Image_Handle) returns valid Widget_Handle");

      --  Is_Playing / Is_Looping defaults (no animation loaded → False)
      Test_Support.Assert (not Is_Playing (H), "AI not playing initially");
      Test_Support.Assert (not Is_Looping (H), "AI not looping without animation");

      --  Get_Animation should be null initially
      declare
         use type Adi.Animated_Image.Animated_Image_Access;
      begin
         Test_Support.Assert (Get_Animation (H) = null, "AI animation initially null");
      end;

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Animated_Image_Handle),
              "Null_Animated_Image_Handle should be invalid");
   end Test_Animated_Image_Handle;

   ---------------------------------------------------------------------------
   --  Test: RLottie_Handle
   ---------------------------------------------------------------------------

   procedure Test_RLottie_Handle is
      use Adi.Widget.RLottie;
      H  : constant RLottie_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- RLottie_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "RLottie_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "RL To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant RLottie_Handle := Try_As_RLottie (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_RLottie roundtrip succeeds");
      end;

      --  "+" operator
      Test_Support.Assert (Adi.Widget.Is_Valid (+H),
              """+""(RLottie_Handle) returns valid Widget_Handle");

      --  Is_Playing default (no animation → False)
      Test_Support.Assert (not Is_Playing (H), "RL not playing initially");

      --  Is_Looping default (Desired_Looping defaults True)
      Test_Support.Assert (Is_Looping (H), "RL looping by default");

      --  Set_Looping / Is_Looping
      Set_Looping (H, False);
      Test_Support.Assert (not Is_Looping (H), "RL not looping after Set_Looping(False)");

      --  Get_Animation should be null initially
      declare
         use type Adi.RLottie.Animation_Handle;
      begin
         Test_Support.Assert (Get_Animation (H) = Adi.RLottie.Null_Animation_Handle,
            "RL animation initially null");
      end;

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_RLottie_Handle),
              "Null_RLottie_Handle should be invalid");
   end Test_RLottie_Handle;

   ---------------------------------------------------------------------------
   --  Test: Html_View_Handle
   ---------------------------------------------------------------------------

   procedure Test_Html_View_Handle is
      use Adi.Widget.Html_View;
      H  : constant Html_View_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Html_View_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Html_View_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "HV To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Html_View_Handle := Try_As_Html_View (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Html_View roundtrip succeeds");
      end;

      --  "+" operator
      Test_Support.Assert (Adi.Widget.Is_Valid (+H),
              """+""(Html_View_Handle) returns valid Widget_Handle");

      --  Set_HTML / Get_HTML
      Test_Support.Assert (Get_HTML (H) = "", "HV initially empty HTML");
      Set_HTML (H, "<p>Hello</p>");
      Test_Support.Assert (Get_HTML (H) = "<p>Hello</p>", "HV Set/Get_HTML");

      --  Clear
      Clear (H);
      Test_Support.Assert (Get_HTML (H) = "", "HV empty after Clear");

      --  Content scale
      declare
         use type Adi.Core.Pixel_Type;
      begin
         Test_Support.Assert (Get_Content_Scale (H) = 1.0,
                 "HV default content scale 1.0");
         Set_Content_Scale (H, 2.0);
         Test_Support.Assert (Get_Content_Scale (H) = 2.0, "HV Set/Get_Content_Scale");
      end;

      --  Default stylesheet
      Test_Support.Assert (Get_Default_Stylesheet (H) = "",
              "HV default stylesheet initially empty");
      Set_Default_Stylesheet_String (H, "body { color: red; }");
      Test_Support.Assert (Get_Default_Stylesheet (H) = "body { color: red; }",
              "HV Set/Get default stylesheet string");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Html_View_Handle),
              "Null_Html_View_Handle should be invalid");
   end Test_Html_View_Handle;

   ---------------------------------------------------------------------------
   --  Test: Animated_Widget_Handle
   ---------------------------------------------------------------------------

   procedure Test_Animated_Widget_Handle is
      use Adi.Widget.Animated_Widget;
      H  : constant Animated_Widget_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Animated_Widget_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Animated_Widget_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "AW To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Animated_Widget_Handle := Try_As_Animated_Widget (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Animated_Widget roundtrip succeeds");
      end;

      --  Is_Playing should be false initially
      Test_Support.Assert (not Is_Playing (H), "Not playing initially");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Animated_Widget_Handle),
              "Null_Animated_Widget_Handle should be invalid");
   end Test_Animated_Widget_Handle;

   ---------------------------------------------------------------------------
   --  Test: Switch_Handle
   ---------------------------------------------------------------------------

   procedure Test_Switch_Handle is
      use Adi.Widget.Button.Switch;
      H  : constant Switch_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Switch_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Switch_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "Switch To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Switch_Handle := Try_As_Switch (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Switch roundtrip succeeds");
      end;

      --  Set_Checked / Is_Checked
      Test_Support.Assert (not Is_Checked (H), "Switch not checked initially");
      Set_Checked (H, True);
      Test_Support.Assert (Is_Checked (H), "Switch checked after Set_Checked(True)");

      --  Is_Toggleable
      Test_Support.Assert (Is_Toggleable (H), "Switch should be toggleable");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Switch_Handle),
              "Null_Switch_Handle should be invalid");
   end Test_Switch_Handle;

   ---------------------------------------------------------------------------
   --  Test: Text_Input_Handle
   ---------------------------------------------------------------------------

   procedure Test_Text_Input_Handle is
      use Adi.Widget.Text_Input;
      H  : constant Text_Input_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Text_Input_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Text_Input_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "TI To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Text_Input_Handle := Try_As_Text_Input (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Text_Input roundtrip succeeds");
      end;

      --  Set_Text / Get_Text
      Test_Support.Assert (Get_Text (H) = "", "Text_Input initially empty");
      Set_Text (H, "Hello");
      Test_Support.Assert (Get_Text (H) = "Hello", "Text_Input Set/Get_Text");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Text_Input_Handle),
              "Null_Text_Input_Handle should be invalid");
   end Test_Text_Input_Handle;

   ---------------------------------------------------------------------------
   --  Test: Text_Editor_Handle
   ---------------------------------------------------------------------------

   procedure Test_Text_Editor_Handle is
      use Adi.Widget.Text_Editor;
      H  : constant Text_Editor_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Text_Editor_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Text_Editor_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "TE To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Text_Editor_Handle := Try_As_Text_Editor (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Text_Editor roundtrip succeeds");
      end;

      --  Set_Text / Get_Text
      Set_Text (H, "Line1");
      Test_Support.Assert (Get_Text (H) = "Line1", "Text_Editor Set/Get_Text");

      --  Append_Text
      Append_Text (H, " more");
      Test_Support.Assert (Get_Text (H) = "Line1 more", "Text_Editor Append_Text");

      --  Set_Read_Only / Is_Read_Only
      Test_Support.Assert (not Is_Read_Only (H), "Not read-only initially");
      Set_Read_Only (H, True);
      Test_Support.Assert (Is_Read_Only (H), "Read-only after Set_Read_Only(True)");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Text_Editor_Handle),
              "Null_Text_Editor_Handle should be invalid");
   end Test_Text_Editor_Handle;

   ---------------------------------------------------------------------------
   --  Test: Combo_Box_Handle
   ---------------------------------------------------------------------------

   procedure Test_Combo_Box_Handle is
      use Adi.Widget.Combo_Box;
      H  : constant Combo_Box_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Combo_Box_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Combo_Box_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "CB To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Combo_Box_Handle := Try_As_Combo_Box (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Combo_Box roundtrip succeeds");
      end;

      --  Add_Item / Option_Count / Get_Selected
      Test_Support.Assert (Option_Count (H) = 0, "Combo_Box initially empty");
      Add_Item (H, "Apple");
      Add_Item (H, "Banana");
      Test_Support.Assert (Option_Count (H) = 2, "Option_Count after 2 adds");
      Test_Support.Assert (Get_Selected_Index (H) = 1, "First item auto-selected");
      Test_Support.Assert (Get_Selected_Text (H) = "Apple", "Selected text is Apple");

      --  Set_Selected_Index
      Set_Selected_Index (H, 2);
      Test_Support.Assert (Get_Selected_Index (H) = 2, "Selected index after set");
      Test_Support.Assert (Get_Selected_Text (H) = "Banana", "Selected text is Banana");

      --  Clear_Items
      Clear_Items (H);
      Test_Support.Assert (Option_Count (H) = 0, "Option_Count after clear");

      --  Is_Open
      Test_Support.Assert (not Is_Open (H), "Combo_Box not open initially");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Combo_Box_Handle),
              "Null_Combo_Box_Handle should be invalid");
   end Test_Combo_Box_Handle;

   ---------------------------------------------------------------------------
   --  Test: Dialog_Handle
   ---------------------------------------------------------------------------

   procedure Test_Dialog_Handle is
      use Adi.Widget.Dialog;
      H  : constant Dialog_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Dialog_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Dialog_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "Dlg To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Dialog_Handle := Try_As_Dialog (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Dialog roundtrip succeeds");
      end;

      --  Set_Title / Set_Message (no getter, just verify no crash)
      Set_Title (H, "Test Dialog");
      Set_Message (H, "Are you sure?");

      --  Add_Button returns index
      declare
         Idx : constant Positive := Add_Button (H, "OK");
      begin
         Test_Support.Assert (Idx = 1, "Add_Button returns 1 for first button");
      end;
      Add_Button (H, "Cancel");

      --  Get_Button_Handle
      declare
         Btn : constant Button.Button_Handle := Get_Button_Handle (H, 1);
      begin
         Test_Support.Assert (Button.Is_Valid (Btn), "Get_Button_Handle(1) returns valid");
      end;

      --  Is_Shown (not attached to window, so can't show)
      Test_Support.Assert (not Is_Shown (H), "Dialog not shown initially");

      --  Clear_Buttons
      Clear_Buttons (H);
      declare
         Btn : constant Button.Button_Handle := Get_Button_Handle (H, 1);
      begin
         Test_Support.Assert (not Button.Is_Valid (Btn),
                 "Get_Button_Handle(1) invalid after Clear_Buttons");
      end;

      --  Presets (just verify no crash)
      Set_OK_Button (H);
      Set_OK_Cancel (H);
      Set_Yes_No (H);
      Set_Yes_No_Cancel (H);

      --  Dismiss policies
      Set_Dismiss_On_Backdrop (H, False);
      Set_Dismiss_On_Escape (H, False);

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Dialog_Handle),
              "Null_Dialog_Handle should be invalid");
   end Test_Dialog_Handle;

   ---------------------------------------------------------------------------
   --  Test: Stack_Handle (generic)
   ---------------------------------------------------------------------------

   procedure Test_Stack_Handle is
      use Test_Stack;
      H  : constant Stack_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Stack_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "Stack_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "Stack To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant Stack_Handle := Try_As_Stack (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_Stack roundtrip succeeds");
      end;

      --  Add pages via handle
      declare
         PA : constant Label.Label_Handle := Label.Create_Handle ("PageA");
         PB : constant Label.Label_Handle := Label.Create_Handle ("PageB");
      begin
         Add_Page (H, Page_A, Label."+" (PA));
         Add_Page (H, Page_B, Label."+" (PB));
      end;

      --  Get_Active
      Test_Support.Assert (Get_Active (H) = Page_A, "First page is active");

      --  Set_Active
      Set_Active (H, Page_B);
      Test_Support.Assert (Get_Active (H) = Page_B, "Page_B active after set");

      --  Get_Active_Widget_Handle / Get_Page_Handle
      Test_Support.Assert (Adi.Widget.Is_Valid (Get_Active_Widget_Handle (H)),
              "Active widget handle valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (Get_Page_Handle (H, Page_A)),
              "Page_A handle valid");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_Stack_Handle),
              "Null_Stack_Handle should be invalid");
   end Test_Stack_Handle;

   ---------------------------------------------------------------------------
   --  Test: List_Box_Handle (generic)
   ---------------------------------------------------------------------------

   procedure Test_List_Box_Handle is
      use Test_List_Box;
      use type Adi.Widget.Label.Label_Handle;
      H  : constant List_Box_Handle := Create_Handle;
      WH : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- List_Box_Handle tests --");
      Test_Support.Assert (Is_Valid (H), "List_Box_Handle should be valid");
      Test_Support.Assert (Adi.Widget.Is_Valid (WH), "LB To_Widget_Handle valid");

      --  Try_As roundtrip
      declare
         H2 : constant List_Box_Handle := Try_As_List_Box (WH);
      begin
         Test_Support.Assert (Is_Valid (H2), "Try_As_List_Box roundtrip succeeds");
      end;

      --  Append_Row / Row_Count
      Test_Support.Assert (Row_Count (H) = 0, "List_Box initially empty");
      Append_Row (H, +Label.Create_Handle ("Row1"));
      Append_Row (H, +Label.Create_Handle ("Row2"));
      Append_Row (H, +Label.Create_Handle ("Row3"));
      Test_Support.Assert (Row_Count (H) = 3, "Row_Count after 3 appends");

      --  Get_Row_Handle
      Test_Support.Assert (Adi.Widget.Is_Valid (Get_Row_Handle (H, 1)),
              "Get_Row_Handle(1) valid");

      --  Selection
      Set_Selection_Mode (H, Single_Selection);
      Test_Support.Assert (Get_Selection_Mode (H) = Single_Selection,
              "Selection mode is Single");
      Select_Row (H, 2);
      Test_Support.Assert (Is_Row_Selected (H, 2), "Row 2 selected");
      Test_Support.Assert (Get_Selected_Count (H) = 1, "Selected count is 1");

      --  Current row
      Set_Current_Row (H, 3);
      Test_Support.Assert (Get_Current_Row (H) = 3, "Current row is 3");

      --  Clear
      Clear_Selection (H);
      Test_Support.Assert (Get_Selected_Count (H) = 0, "Selected count 0 after clear");

      --  Clear_Rows
      Clear_Rows (H);
      Test_Support.Assert (Row_Count (H) = 0, "Row_Count 0 after Clear_Rows");

      --  Null handle
      Test_Support.Assert (not Is_Valid (Null_List_Box_Handle),
              "Null_List_Box_Handle should be invalid");
   end Test_List_Box_Handle;

   ---------------------------------------------------------------------------
   --  Test: Widget_Handle base overloads
   ---------------------------------------------------------------------------

   procedure Test_Widget_Handle_Base_Overloads is
      H : constant Widget_Handle :=
        Label.To_Widget_Handle (Label.Create_Handle ("base"));
   begin
      Put_Line ("-- Widget_Handle base overloads tests --");

      --  Set_Visible / Is_Visible
      Test_Support.Assert (Is_Visible (H), "Widget visible by default");
      Set_Visible (H, False);
      Test_Support.Assert (not Is_Visible (H), "Widget invisible after Set_Visible(False)");
      Set_Visible (H, True);
      Test_Support.Assert (Is_Visible (H), "Widget visible after Set_Visible(True)");

      --  Set_Disabled / Is_Disabled
      Test_Support.Assert (not Is_Disabled (H), "Widget not disabled by default");
      Set_Disabled (H, True);
      Test_Support.Assert (Is_Disabled (H), "Widget disabled after Set_Disabled(True)");
      Set_Disabled (H, False);
      Test_Support.Assert (not Is_Disabled (H), "Widget not disabled after Set_Disabled(False)");

      --  Set_Focusable (no getter via handle, just verify no crash)
      Set_Focusable (H, True);

      --  Set_Label / Get_Label
      Test_Support.Assert (Get_Label (H) = "", "Label empty by default");
      Set_Label (H, "my label");
      Test_Support.Assert (Get_Label (H) = "my label", "Get_Label after Set_Label");

      --  Mark_Dirty (just verify no crash)
      Mark_Dirty (H);

      --  Stale handle returns defaults
      Test_Support.Assert (not Is_Visible (Null_Handle), "Null_Handle Is_Visible=False");
      Test_Support.Assert (not Is_Disabled (Null_Handle), "Null_Handle Is_Disabled=False");
      Test_Support.Assert (Get_Label (Null_Handle) = "", "Null_Handle Get_Label=empty");
   end Test_Widget_Handle_Base_Overloads;

   ---------------------------------------------------------------------------
   --  Test: Widget_Ref / Borrow
   ---------------------------------------------------------------------------

   procedure Test_Widget_Ref is
      use Adi.Widget.Label;
      H : constant Label_Handle := Create_Handle ("Ref");
      W : constant Widget_Handle := To_Widget_Handle (H);
   begin
      Put_Line ("-- Widget_Ref / Borrow tests --");

      --  Borrow on valid handle returns non-null Ptr
      declare
         R : constant Widget_Ref := Borrow (W);
      begin
         Test_Support.Assert (R.Ptr /= null, "Borrow valid handle: Ptr not null");
      end;

      --  Borrow on Null_Handle raises Constraint_Error
      begin
         declare
            R : constant Widget_Ref := Borrow (Null_Handle);
            pragma Unreferenced (R);
         begin
            Test_Support.Assert (False,
                    "Borrow Null_Handle should raise Constraint_Error");
         end;
      exception
         when Constraint_Error =>
            Test_Support.Assert (True, "Borrow Null_Handle raises Constraint_Error");
      end;

      --  Implicit dereference works: access label via Ref
      declare
         R : constant Widget_Ref := Borrow (W);
      begin
         Test_Support.Assert (R.Ptr.all in Adi.Widget.Widget'Class,
                 "Implicit deref: Ptr is Widget'Class");
      end;

      --  Borrow on destroyed handle raises Constraint_Error
      declare
         H2 : Widget_Handle := To_Widget_Handle
           (Create_Handle ("Temp"));
      begin
         Destroy (H2);
         Pump_Widget_Store;
         begin
            declare
               R : constant Widget_Ref := Borrow (H2);
               pragma Unreferenced (R);
            begin
               Test_Support.Assert (False,
                       "Borrow destroyed handle should raise");
            end;
         exception
            when Constraint_Error =>
               Test_Support.Assert (True,
                       "Borrow destroyed handle raises Constraint_Error");
         end;
      end;
   end Test_Widget_Ref;

   ---------------------------------------------------------------------------
   --  Test: Text_Input context menu binding after Create_Handle
   --  Regression: Ensure_Context_Menu was called before Register_Widget,
   --  so the context menu binding stored an invalid (null) handle.
   ---------------------------------------------------------------------------

   procedure Test_Text_Input_Context_Menu_Binding is
      use Adi.Widget.Text_Input;
      H : constant Text_Input_Handle := Create_Handle ("test");
   begin
      Put_Line ("-- Text_Input context menu binding regression --");
      --  After Create_Handle the widget must already have a context menu
      --  subscriber (the text context menu's Show handler).
      Test_Support.Assert (Has_Context_Menu (+H),
              "Text_Input via Create_Handle has context menu");
   end Test_Text_Input_Context_Menu_Binding;

   ---------------------------------------------------------------------------
   --  Test: Text_Editor context menu binding after Create_Handle
   --  Same regression as Text_Input.
   ---------------------------------------------------------------------------

   procedure Test_Text_Editor_Context_Menu_Binding is
      use Adi.Widget.Text_Editor;
      H : constant Text_Editor_Handle := Create_Handle;
   begin
      Put_Line ("-- Text_Editor context menu binding regression --");
      Test_Support.Assert (Has_Context_Menu (+H),
              "Text_Editor via Create_Handle has context menu");
   end Test_Text_Editor_Context_Menu_Binding;

   ---------------------------------------------------------------------------
   --  Test: Bubble_Context_Menu walks parent chain without crash
   --  Regression: Widget_Access(Get_Parent(...)) raised PROGRAM_ERROR
   --  due to accessibility check on the local access value.
   ---------------------------------------------------------------------------

   procedure Test_Bubble_Context_Menu_Parent_Walk is
      use Adi.Core;
      use type Adi.Widget.Box.Box_Handle;
      use type Adi.Widget.Button.Button_Handle;
      Root  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Child : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Leaf  : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("click");

      Got_Menu : Boolean := False;

      procedure Menu_CB (W : Widget_Handle; X, Y : Pixel_Type) is
         pragma Unreferenced (W, X, Y);
      begin
         Got_Menu := True;
      end Menu_CB;
   begin
      Put_Line ("-- Bubble_Context_Menu parent walk regression --");
      --  Build a 3-level hierarchy: Root > Child > Leaf
      Add_Child (+Root, +Child);
      Add_Child (+Child, +Leaf);

      --  Attach context menu to Root only
      Connect_Context_Menu (+Root, Menu_CB'Unrestricted_Access);

      --  Bubble from Leaf — must walk up through Child to Root without crash
      declare
         Result : Boolean;
      begin
         Result := Bubble_Context_Menu (+Leaf, 10.0, 10.0);
         Test_Support.Assert (Result, "Bubble_Context_Menu reached Root's handler");
         Test_Support.Assert (Got_Menu, "Context menu callback was invoked");
      end;

      --  Bubble from a widget with no context menu in hierarchy
      declare
         Alone  : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
         Result : Boolean;
      begin
         Result := Bubble_Context_Menu (+Alone, 10.0, 10.0);
         Test_Support.Assert (not Result,
                 "Bubble_Context_Menu returns False with no handler");
      end;
   end Test_Bubble_Context_Menu_Parent_Walk;

begin
   Test_Support.Start_Suite ("Widget Handle Tests");

   Test_Create_Handle;
   Test_Null_Handle;
   Test_Destroy_Stale;
   Test_Destroy_Detaches;
   Test_Destroy_Recursive;
   Test_Pump;
   Test_Get_Handle_Roundtrip;
   Test_Resolve_Handle;
   Test_Create_Handle_Fn;
   Test_Add_Child_Handle;
   Test_Add_Child_Null_Handle;

   --  Typed handle tests
   Test_Label_Handle;
   Test_Button_Handle;
   Test_Box_Handle;
   Test_Try_As_Wrong_Type;
   Test_Slider_Handle;

   --  Ergonomic handle tests
   Test_Plus_Operator;
   Test_Slider_Full_Overloads;
   Test_Button_Full_Overloads;
   Test_Value_Input_Handle;
   Test_Integer_Value_Input_Handle;

   --  New widget handle tests
   Test_Image_Handle;
   Test_Animated_Image_Handle;
   Test_RLottie_Handle;
   Test_Html_View_Handle;
   Test_Animated_Widget_Handle;
   Test_Switch_Handle;
   Test_Text_Input_Handle;
   Test_Text_Editor_Handle;
   Test_Combo_Box_Handle;
   Test_Dialog_Handle;
   Test_Stack_Handle;
   Test_List_Box_Handle;
   Test_Widget_Handle_Base_Overloads;
   Test_Widget_Ref;

   --  Regression tests
   Test_Text_Input_Context_Menu_Binding;
   Test_Text_Editor_Context_Menu_Binding;
   Test_Bubble_Context_Menu_Parent_Walk;

   New_Line;
   Test_Support.Finish;
end Widget_Handle_Test;
