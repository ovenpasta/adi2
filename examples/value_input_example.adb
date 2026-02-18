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
with Adi.Widget.Text_Input;
with Adi.Widget.Value_Input;
with Adi.Widget.Integer_Value_Input;

with Value_Input_Example_Styles; use Value_Input_Example_Styles;

procedure Value_Input_Example is
   A : Adi.App.App;

   package Float_Input is new Adi.Widget.Value_Input (Float);
   package Int_Input is new Adi.Widget.Integer_Value_Input (Integer);

   function Float_Str (V : Float) return String is
      package FIO is new Ada.Text_IO.Float_IO (Float);
      Buf : String (1 .. 64);
   begin
      FIO.Put (Buf, V, Aft => 2, Exp => 0);
      return Trim (Buf, Both);
   end Float_Str;

   --  Widgets that callbacks reference
   Float_Echo : Adi.Widget.Label.Label_Widget_Access;
   Int_Echo   : Adi.Widget.Label.Label_Widget_Access;
   Range_Echo : Adi.Widget.Label.Label_Widget_Access;

   procedure On_Float_Changed
     (W : Float_Input.Value_Input_Widget_Access; Value : Float) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text (Float_Echo.all, Float_Str (Value));
   end On_Float_Changed;

   procedure On_Int_Changed
     (W : Int_Input.Value_Input_Widget_Access; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Int_Echo.all, Trim (Integer'Image (Value), Both));
   end On_Int_Changed;

   procedure On_Range_Changed
     (W : Float_Input.Value_Input_Widget_Access; Value : Float) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text (Range_Echo.all, Float_Str (Value));
   end On_Range_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   --  Set context menu styles
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles
     (Value_Input_Example_Styles.Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles
     (Value_Input_Example_Styles.Context_Menu_Item_Class_Part_Styles);

   declare
      Win : constant Window_Access :=
        Create_Window ("Value Input Example", (600.0, 420.0));

      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;

      --  Section 1: Float value input
      Section1 : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Heading1 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Float Value Input");
      Row1     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Label1   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Temperature (C):");
      Input1   : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => -40.0, Max => 100.0, Value => 22.5);

      --  Section 2: Integer value input
      Section2 : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Heading2 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Integer Value Input");
      Row2     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Label2   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Port number:");
      Input2   : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 1, Max => 65535, Value => 8080);

      --  Section 3: Stepped float input with large range
      Section3 : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Heading3 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Stepped Float (step=0.25)");
      Row3     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Label3   : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Gain (dB):");
      Input3   : constant Float_Input.Value_Input_Widget_Access :=
        Float_Input.Create (Min => -20.0, Max => 20.0, Value => 0.0);

      --  Section 4: Multiple inputs in a row
      Section4 : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Heading4 : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("RGB Color Picker");
      Row4     : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Label_R  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("R:");
      Input_R  : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 255, Value => 137);
      Label_G  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("G:");
      Input_G  : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 255, Value => 180);
      Label_B  : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("B:");
      Input_B  : constant Int_Input.Value_Input_Widget_Access :=
        Int_Input.Create (Min => 0, Max => 255, Value => 250);
   begin
      Float_Echo := Adi.Widget.Label.Create (Float_Str (22.5));
      Int_Echo   := Adi.Widget.Label.Create ("8080");
      Range_Echo := Adi.Widget.Label.Create (Float_Str (0.0));

      --  Configure steps
      Float_Input.Set_Step (Input1.all, 0.5);
      Int_Input.Set_Step (Input2.all, 1);
      Float_Input.Set_Step (Input3.all, 0.25);
      Int_Input.Set_Step (Input_R.all, 1);
      Int_Input.Set_Step (Input_G.all, 1);
      Int_Input.Set_Step (Input_B.all, 1);

      --  Wire callbacks
      Float_Input.Set_On_Value_Changed
        (Input1.all, On_Float_Changed'Unrestricted_Access);
      Int_Input.Set_On_Value_Changed
        (Input2.all, On_Int_Changed'Unrestricted_Access);
      Float_Input.Set_On_Value_Changed
        (Input3.all, On_Range_Changed'Unrestricted_Access);

      --  Apply styles
      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Section1.all, Section_Class_Part_Styles);
      Set_Part_Styles (Section2.all, Section_Class_Part_Styles);
      Set_Part_Styles (Section3.all, Section_Class_Part_Styles);
      Set_Part_Styles (Section4.all, Section_Class_Part_Styles);
      Set_Part_Styles (Heading1.all, Heading_Class_Part_Styles);
      Set_Part_Styles (Heading2.all, Heading_Class_Part_Styles);
      Set_Part_Styles (Heading3.all, Heading_Class_Part_Styles);
      Set_Part_Styles (Heading4.all, Heading_Class_Part_Styles);
      Set_Part_Styles (Row1.all, Row_Class_Part_Styles);
      Set_Part_Styles (Row2.all, Row_Class_Part_Styles);
      Set_Part_Styles (Row3.all, Row_Class_Part_Styles);
      Set_Part_Styles (Row4.all, Row_Class_Part_Styles);
      Set_Part_Styles (Label1.all, Label_Class_Part_Styles);
      Set_Part_Styles (Label2.all, Label_Class_Part_Styles);
      Set_Part_Styles (Label3.all, Label_Class_Part_Styles);
      Set_Part_Styles (Label_R.all, Label_Class_Part_Styles);
      Set_Part_Styles (Label_G.all, Label_Class_Part_Styles);
      Set_Part_Styles (Label_B.all, Label_Class_Part_Styles);
      Set_Part_Styles (Float_Echo.all, Value_Label_Class_Part_Styles);
      Set_Part_Styles (Int_Echo.all, Value_Label_Class_Part_Styles);
      Set_Part_Styles (Range_Echo.all, Value_Label_Class_Part_Styles);
      Set_Part_Styles (Input1.all, Value_Input_Class_Part_Styles);
      Set_Part_Styles (Input2.all, Int_Input_Class_Part_Styles);
      Set_Part_Styles (Input3.all, Wide_Input_Class_Part_Styles);
      Set_Part_Styles (Input_R.all, Int_Input_Class_Part_Styles);
      Set_Part_Styles (Input_G.all, Int_Input_Class_Part_Styles);
      Set_Part_Styles (Input_B.all, Int_Input_Class_Part_Styles);

      --  Attach windows for text input context menus
      Adi.Widget.Text_Input.Attach_Window
        (Adi.Widget.Text_Input.Text_Input_Widget (Input1.all), Win);
      Adi.Widget.Text_Input.Attach_Window
        (Adi.Widget.Text_Input.Text_Input_Widget (Input2.all), Win);
      Adi.Widget.Text_Input.Attach_Window
        (Adi.Widget.Text_Input.Text_Input_Widget (Input3.all), Win);
      Adi.Widget.Text_Input.Attach_Window
        (Adi.Widget.Text_Input.Text_Input_Widget (Input_R.all), Win);
      Adi.Widget.Text_Input.Attach_Window
        (Adi.Widget.Text_Input.Text_Input_Widget (Input_G.all), Win);
      Adi.Widget.Text_Input.Attach_Window
        (Adi.Widget.Text_Input.Text_Input_Widget (Input_B.all), Win);

      --  Build hierarchy
      Add_Child (Section1.all, Heading1);
      Add_Child (Row1.all, Label1);
      Add_Child (Row1.all, Input1);
      Add_Child (Row1.all, Float_Echo);
      Add_Child (Section1.all, Row1);

      Add_Child (Section2.all, Heading2);
      Add_Child (Row2.all, Label2);
      Add_Child (Row2.all, Input2);
      Add_Child (Row2.all, Int_Echo);
      Add_Child (Section2.all, Row2);

      Add_Child (Section3.all, Heading3);
      Add_Child (Row3.all, Label3);
      Add_Child (Row3.all, Input3);
      Add_Child (Row3.all, Range_Echo);
      Add_Child (Section3.all, Row3);

      Add_Child (Section4.all, Heading4);
      Add_Child (Row4.all, Label_R);
      Add_Child (Row4.all, Input_R);
      Add_Child (Row4.all, Label_G);
      Add_Child (Row4.all, Input_G);
      Add_Child (Row4.all, Label_B);
      Add_Child (Row4.all, Input_B);
      Add_Child (Section4.all, Row4);

      Add_Child (Root.all, Section1);
      Add_Child (Root.all, Section2);
      Add_Child (Root.all, Section3);
      Add_Child (Root.all, Section4);

      Win.Set_Root (Root);
      A.Add_Window (Win);
      A.Run;
   end;
end Value_Input_Example;
