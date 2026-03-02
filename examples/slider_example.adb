pragma Ada_2022;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;
with Adi.App;
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

   function Float_Str (V : Float) return String is
      package FIO is new Ada.Text_IO.Float_IO (Float);
      Buf : String (1 .. 64);
   begin
      FIO.Put (Buf, V, Aft => 2, Exp => 0);
      return Trim (Buf, Both);
   end Float_Str;

   --  Forward declarations for callbacks
   Slider1 : Float_Slider.Slider_Widget_Access;
   Value1  : Adi.Widget.Label.Label_Widget_Access;
   Input1  : Float_Input.Value_Input_Widget_Access;

   Slider2 : Int_Slider.Slider_Widget_Access;
   Value2  : Adi.Widget.Label.Label_Widget_Access;
   Input2  : Int_Input.Value_Input_Widget_Access;

   Value3  : Adi.Widget.Label.Label_Widget_Access;

   procedure On_Slider1_Changed
     (W : Float_Slider.Slider_Widget_Access; Value : Float) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text (Value1.all, Float_Str (Value));
      Float_Input.Set_Value (Input1.all, Value);
   end On_Slider1_Changed;

   procedure On_Input1_Changed
     (W : Float_Input.Value_Input_Widget_Access; Value : Float) is
      pragma Unreferenced (W);
   begin
      Float_Slider.Set_Value (Slider1.all, Value);
      Adi.Widget.Label.Set_Text (Value1.all, Float_Str (Value));
   end On_Input1_Changed;

   procedure On_Slider2_Changed
     (W : Int_Slider.Slider_Widget_Access; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Value2.all, Trim (Integer'Image (Value), Both));
      Int_Input.Set_Value (Input2.all, Value);
   end On_Slider2_Changed;

   procedure On_Input2_Changed
     (W : Int_Input.Value_Input_Widget_Access; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Int_Slider.Set_Value (Slider2.all, Value);
      Adi.Widget.Label.Set_Text
        (Value2.all, Trim (Integer'Image (Value), Both));
   end On_Input2_Changed;

   procedure On_Slider3_Changed
     (W : Int_Slider.Slider_Widget_Access; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Value3.all, Trim (Integer'Image (Value), Both));
   end On_Slider3_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   --  Set context menu styles
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles
     (Slider_Example_Styles.Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles
     (Slider_Example_Styles.Context_Menu_Item_Class_Part_Styles);

   declare
      W : constant Window_Access :=
        Create_Window ("Slider Example", (600.0, 400.0));

      Root     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;

      --  Section 1: Float slider + value input
      Section1 : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Heading1 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Float Slider");
      Row1     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Label1   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Opacity:");

      --  Section 2: Integer slider + value input
      Section2 : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Heading2 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Integer Slider");
      Row2     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Label2   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Red:");

      --  Section 3: Stepped slider
      Section3 : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Heading3 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Stepped Slider (step=10)");
      Row3     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Label3   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Volume:");
      Slider3  : constant Int_Slider.Slider_Widget_Access :=
        Int_Slider.Create (Min => 0, Max => 100, Value => 50);
   begin
      Slider1 := Float_Slider.Create (Min => 0.0, Max => 1.0, Value => 0.5);
      Value1  := Adi.Widget.Label.Create ("0.50");
      Input1  := Float_Input.Create (Min => 0.0, Max => 1.0, Value => 0.5);

      Slider2 := Int_Slider.Create (Min => 0, Max => 255, Value => 128);
      Value2  := Adi.Widget.Label.Create ("128");
      Input2  := Int_Input.Create (Min => 0, Max => 255, Value => 128);

      Value3  := Adi.Widget.Label.Create ("50");

      --  Configure steps
      Float_Slider.Set_Step (Slider1.all, 0.01);
      Int_Slider.Set_Step (Slider2.all, 1);
      Int_Slider.Set_Step (Slider3.all, 10);
      Float_Input.Set_Step (Input1.all, 0.01);
      Int_Input.Set_Step (Input2.all, 1);

      --  Wire callbacks
      Float_Slider.Connect_Changed
        (Slider1.all, On_Slider1_Changed'Unrestricted_Access);
      Float_Input.Connect_Value_Changed
        (Input1.all, On_Input1_Changed'Unrestricted_Access);
      Int_Slider.Connect_Changed
        (Slider2.all, On_Slider2_Changed'Unrestricted_Access);
      Int_Input.Connect_Value_Changed
        (Input2.all, On_Input2_Changed'Unrestricted_Access);
      Int_Slider.Connect_Changed
        (Slider3.all, On_Slider3_Changed'Unrestricted_Access);

      --  Apply styles
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Section1.all, Section_Class_Part_Styles);
      Set_Part_Styles (Section2.all, Section_Class_Part_Styles);
      Set_Part_Styles (Section3.all, Section_Class_Part_Styles);
      Set_Part_Styles (Heading1.all, Heading_Class_Part_Styles);
      Set_Part_Styles (Heading2.all, Heading_Class_Part_Styles);
      Set_Part_Styles (Heading3.all, Heading_Class_Part_Styles);
      Set_Part_Styles (Row1.all, Row_Class_Part_Styles);
      Set_Part_Styles (Row2.all, Row_Class_Part_Styles);
      Set_Part_Styles (Row3.all, Row_Class_Part_Styles);
      Set_Part_Styles (Label1.all, Label_Class_Part_Styles);
      Set_Part_Styles (Label2.all, Label_Class_Part_Styles);
      Set_Part_Styles (Label3.all, Label_Class_Part_Styles);
      Set_Part_Styles (Value1.all, Value_Label_Class_Part_Styles);
      Set_Part_Styles (Value2.all, Value_Label_Class_Part_Styles);
      Set_Part_Styles (Value3.all, Value_Label_Class_Part_Styles);
      Set_Part_Styles (Slider1.all, Slider_Class_Part_Styles);
      Set_Part_Styles (Slider2.all, Slider_Class_Part_Styles);
      Set_Part_Styles (Slider3.all, Slider_Class_Part_Styles);
      Set_Part_Styles (Input1.all, Value_Input_Class_Part_Styles);
      Set_Part_Styles (Input2.all, Value_Input_Class_Part_Styles);

      --  Build hierarchy
      Add_Child (Section1.all, Heading1);
      Add_Child (Row1.all, Label1);
      Add_Child (Row1.all, Slider1);
      Add_Child (Row1.all, Value1);
      Add_Child (Row1.all, Input1);
      Add_Child (Section1.all, Row1);

      Add_Child (Section2.all, Heading2);
      Add_Child (Row2.all, Label2);
      Add_Child (Row2.all, Slider2);
      Add_Child (Row2.all, Value2);
      Add_Child (Row2.all, Input2);
      Add_Child (Section2.all, Row2);

      Add_Child (Section3.all, Heading3);
      Add_Child (Row3.all, Label3);
      Add_Child (Row3.all, Slider3);
      Add_Child (Row3.all, Value3);
      Add_Child (Section3.all, Row3);

      Add_Child (Root.all, Section1);
      Add_Child (Root.all, Section2);
      Add_Child (Root.all, Section3);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Slider_Example;
