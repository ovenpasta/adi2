pragma Ada_2022;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;
with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;          use Adi.Window;
with Adi.Widget;          use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Context_Menu;
with Adi.Widget.Slider;
with Adi.Widget.Integer_Slider;
with Adi.Widget.Value_Input;
with Adi.Widget.Integer_Value_Input;

with Slider_Example_Styles; use Slider_Example_Styles;

procedure Slider_Example is
   A : Adi.App.App;

   package Float_Slider is new Adi.Widget.Slider (Float);
   package Int_Slider is new Adi.Widget.Integer_Slider (Integer);
   package Float_Input is new Adi.Widget.Value_Input (Float);
   package Int_Input is new Adi.Widget.Integer_Value_Input (Integer);

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Float_Slider.Slider_Handle;
   use type Int_Slider.Slider_Handle;
   use type Float_Input.Value_Input_Handle;
   use type Int_Input.Value_Input_Handle;

   function Float_Str (V : Float) return String is
      package FIO is new Ada.Text_IO.Float_IO (Float);
      Buf : String (1 .. 64);
   begin
      FIO.Put (Buf, V, Aft => 2, Exp => 0);
      return Trim (Buf, Both);
   end Float_Str;

   --  Typed handles for cross-widget access in callbacks
   Slider1_H : Float_Slider.Slider_Handle;
   Value1_H  : Adi.Widget.Label.Label_Handle;
   Input1_H  : Float_Input.Value_Input_Handle;

   Slider2_H : Int_Slider.Slider_Handle;
   Value2_H  : Adi.Widget.Label.Label_Handle;
   Input2_H  : Int_Input.Value_Input_Handle;

   Value3_H  : Adi.Widget.Label.Label_Handle;

   procedure On_Slider1_Changed
     (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text (Value1_H, Float_Str (Value));
      Float_Input.Set_Value (Input1_H, Value);
   end On_Slider1_Changed;

   procedure On_Input1_Changed
     (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Float_Slider.Set_Value (Slider1_H, Value);
      Adi.Widget.Label.Set_Text (Value1_H, Float_Str (Value));
   end On_Input1_Changed;

   procedure On_Slider2_Changed
     (W : Widget_Handle; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Value2_H, Trim (Integer'Image (Value), Both));
      Int_Input.Set_Value (Input2_H, Value);
   end On_Slider2_Changed;

   procedure On_Input2_Changed
     (W : Widget_Handle; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Int_Slider.Set_Value (Slider2_H, Value);
      Adi.Widget.Label.Set_Text
        (Value2_H, Trim (Integer'Image (Value), Both));
   end On_Input2_Changed;

   procedure On_Slider3_Changed
     (W : Widget_Handle; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Value3_H, Trim (Integer'Image (Value), Both));
   end On_Slider3_Changed;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   --  Set context menu styles
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles
     (Slider_Example_Styles.Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles
     (Slider_Example_Styles.Context_Menu_Item_Class_Part_Styles);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("Slider Example", Adi.Window.Extent (Px (411.0), Px (290.0)));

      --  All widgets created via typed handles
      Root     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;

      --  Section 1: Float slider + value input
      Section1 : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Heading1 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Float Slider (knob inside the bar)");
      Row1     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Label1   : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Opacity:");

      --  Section 2: Integer slider + value input
      Section2 : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Heading2 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Integer Slider (gradient bar)");
      Row2     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Label2   : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Red:");

      --  Section 3: Stepped slider
      Section3 : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Heading3 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Stepped Slider (square knob)");
      Row3     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Label3   : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Volume:");

      Slider3_H : constant Int_Slider.Slider_Handle :=
        Int_Slider.Create_Handle (Min => 0, Max => 100, Value => 50);
   begin
      Slider1_H := Float_Slider.Create_Handle
        (Min => 0.0, Max => 1.0, Value => 0.5);
      Value1_H  := Adi.Widget.Label.Create_Handle ("0.50");

      Slider2_H := Int_Slider.Create_Handle
        (Min => 0, Max => 255, Value => 128);
      Value2_H  := Adi.Widget.Label.Create_Handle ("128");

      Value3_H  := Adi.Widget.Label.Create_Handle ("50");

      --  Value inputs via typed handles
      Input1_H := Float_Input.Create_Handle
        (Min => 0.0, Max => 1.0, Value => 0.5);
      Input2_H := Int_Input.Create_Handle
        (Min => 0, Max => 255, Value => 128);

      Float_Input.Set_Step (Input1_H, 0.01);
      Int_Input.Set_Step (Input2_H, 1);

      Float_Input.Connect_Value_Changed
        (Input1_H, On_Input1_Changed'Unrestricted_Access);
      Int_Input.Connect_Value_Changed
        (Input2_H, On_Input2_Changed'Unrestricted_Access);

      Float_Input.Set_Part_Styles (Input1_H, Value_Input_Class_Part_Styles);
      Int_Input.Set_Part_Styles (Input2_H, Value_Input_Class_Part_Styles);

      --  Configure steps via typed handles
      Float_Slider.Set_Step (Slider1_H, 0.01);
      Int_Slider.Set_Step (Slider2_H, 1);
      Int_Slider.Set_Step (Slider3_H, 10);

      --  Wire callbacks via typed handles
      Float_Slider.Connect_Changed
        (Slider1_H, On_Slider1_Changed'Unrestricted_Access);
      Int_Slider.Connect_Changed
        (Slider2_H, On_Slider2_Changed'Unrestricted_Access);
      Int_Slider.Connect_Changed
        (Slider3_H, On_Slider3_Changed'Unrestricted_Access);

      --  Apply styles via typed handles
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section1, Section_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section2, Section_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section3, Section_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Heading1, Heading_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Heading2, Heading_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Heading3, Heading_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Row1, Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Row2, Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Row3, Row_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label1, Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label2, Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label3, Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Value1_H, Value_Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Value2_H, Value_Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Value3_H, Value_Label_Class_Part_Styles);
      --  One knob style each: the bar and the knob are separate parts,
      --  so the knob is only the bar's size where the CSS says so.
      Float_Slider.Set_Part_Styles (Slider1_H, Slider_Class_Part_Styles);
      Int_Slider.Set_Part_Styles
        (Slider2_H, Slider_Gradient_Class_Part_Styles);
      Int_Slider.Set_Part_Styles
        (Slider3_H, Slider_Square_Class_Part_Styles);

      --  Build hierarchy via "+" operator
      Add_Child (+Section1, +Heading1);
      Add_Child (+Row1, +Label1);
      Add_Child (+Row1, +Slider1_H);
      Add_Child (+Row1, +Value1_H);
      Add_Child (+Row1, +Input1_H);
      Add_Child (+Section1, +Row1);

      Add_Child (+Section2, +Heading2);
      Add_Child (+Row2, +Label2);
      Add_Child (+Row2, +Slider2_H);
      Add_Child (+Row2, +Value2_H);
      Add_Child (+Row2, +Input2_H);
      Add_Child (+Section2, +Row2);

      Add_Child (+Section3, +Heading3);
      Add_Child (+Row3, +Label3);
      Add_Child (+Row3, +Slider3_H);
      Add_Child (+Row3, +Value3_H);
      Add_Child (+Section3, +Row3);

      Add_Child (+Root, +Section1);
      Add_Child (+Root, +Section2);
      Add_Child (+Root, +Section3);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Slider_Example;
