pragma Ada_2022;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;
with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;          use Adi.Window;
with Adi.Widget;          use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Context_Menu;
with Adi.Widget.Value_Input;
with Adi.Widget.Integer_Value_Input;

with Value_Input_Example_Styles; use Value_Input_Example_Styles;

procedure Value_Input_Example is
   A : Adi.App.App;

   package Float_Input is new Adi.Widget.Value_Input (Float);
   package Int_Input is new Adi.Widget.Integer_Value_Input (Integer);

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Float_Input.Value_Input_Handle;
   use type Int_Input.Value_Input_Handle;

   function Float_Str (V : Float) return String is
      package FIO is new Ada.Text_IO.Float_IO (Float);
      Buf : String (1 .. 64);
   begin
      FIO.Put (Buf, V, Aft => 2, Exp => 0);
      return Trim (Buf, Both);
   end Float_Str;

   --  Widgets that callbacks reference
   Float_Echo : Adi.Widget.Label.Label_Handle;
   Int_Echo   : Adi.Widget.Label.Label_Handle;
   Range_Echo : Adi.Widget.Label.Label_Handle;

   procedure On_Float_Changed
     (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text (Float_Echo, Float_Str (Value));
   end On_Float_Changed;

   procedure On_Int_Changed
     (W : Widget_Handle; Value : Integer) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text
        (Int_Echo, Trim (Integer'Image (Value), Both));
   end On_Int_Changed;

   procedure On_Range_Changed
     (W : Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Adi.Widget.Label.Set_Text (Range_Echo, Float_Str (Value));
   end On_Range_Changed;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   --  Set context menu styles
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles
     (Value_Input_Example_Styles.Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles
     (Value_Input_Example_Styles.Context_Menu_Item_Class_Part_Styles);

   declare
      Win : constant Window_Handle :=
        Create_Window_Handle ("Value Input Example", (600.0, 420.0));

      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;

      --  Section 1: Float value input
      Section1 : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Heading1 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Float Value Input");
      Row1     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Label1   : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Temperature (C):");
      Input1   : constant Float_Input.Value_Input_Handle :=
        Float_Input.Create_Handle (Min => -40.0, Max => 100.0, Value => 22.5);

      --  Section 2: Integer value input
      Section2 : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Heading2 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Integer Value Input");
      Row2     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Label2   : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Port number:");
      Input2   : constant Int_Input.Value_Input_Handle :=
        Int_Input.Create_Handle (Min => 1, Max => 65535, Value => 8080);

      --  Section 3: Stepped float input with large range
      Section3 : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Heading3 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Stepped Float (step=0.25)");
      Row3     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Label3   : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Gain (dB):");
      Input3   : constant Float_Input.Value_Input_Handle :=
        Float_Input.Create_Handle (Min => -20.0, Max => 20.0, Value => 0.0);

      --  Section 4: Multiple inputs in a row
      Section4 : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Heading4 : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("RGB Color Picker");
      Row4     : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Label_R  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("R:");
      Input_R  : constant Int_Input.Value_Input_Handle :=
        Int_Input.Create_Handle (Min => 0, Max => 255, Value => 137);
      Label_G  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("G:");
      Input_G  : constant Int_Input.Value_Input_Handle :=
        Int_Input.Create_Handle (Min => 0, Max => 255, Value => 180);
      Label_B  : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("B:");
      Input_B  : constant Int_Input.Value_Input_Handle :=
        Int_Input.Create_Handle (Min => 0, Max => 255, Value => 250);
   begin
      Float_Echo := Adi.Widget.Label.Create_Handle (Float_Str (22.5));
      Int_Echo   := Adi.Widget.Label.Create_Handle ("8080");
      Range_Echo := Adi.Widget.Label.Create_Handle (Float_Str (0.0));

      --  Configure steps
      Float_Input.Set_Step (Input1, 0.5);
      Int_Input.Set_Step (Input2, 1);
      Float_Input.Set_Step (Input3, 0.25);
      Int_Input.Set_Step (Input_R, 1);
      Int_Input.Set_Step (Input_G, 1);
      Int_Input.Set_Step (Input_B, 1);

      --  Wire callbacks
      Float_Input.Connect_Value_Changed
        (Input1, On_Float_Changed'Unrestricted_Access);
      Int_Input.Connect_Value_Changed
        (Input2, On_Int_Changed'Unrestricted_Access);
      Float_Input.Connect_Value_Changed
        (Input3, On_Range_Changed'Unrestricted_Access);

      --  Apply styles
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section1, Section_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section2, Section_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section3, Section_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section4, Section_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Heading1, Heading_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Heading2, Heading_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Heading3, Heading_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Heading4, Heading_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Row1, Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Row2, Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Row3, Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Row4, Row_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label1, Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label2, Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label3, Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label_R, Label_Narrow_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label_G, Label_Narrow_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Label_B, Label_Narrow_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Float_Echo, Value_Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Int_Echo, Value_Label_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Range_Echo, Value_Label_Class_Part_Styles);
      Float_Input.Set_Part_Styles (Input1, Value_Input_Class_Part_Styles);
      Int_Input.Set_Part_Styles (Input2, Int_Input_Class_Part_Styles);
      Float_Input.Set_Part_Styles (Input3, Wide_Input_Class_Part_Styles);
      Int_Input.Set_Part_Styles (Input_R, Int_Input_Class_Part_Styles);
      Int_Input.Set_Part_Styles (Input_G, Int_Input_Class_Part_Styles);
      Int_Input.Set_Part_Styles (Input_B, Int_Input_Class_Part_Styles);

      --  Build hierarchy
      Add_Child (+Section1, +Heading1);
      Add_Child (+Row1, +Label1);
      Add_Child (+Row1, +Input1);
      Add_Child (+Row1, +Float_Echo);
      Add_Child (+Section1, +Row1);

      Add_Child (+Section2, +Heading2);
      Add_Child (+Row2, +Label2);
      Add_Child (+Row2, +Input2);
      Add_Child (+Row2, +Int_Echo);
      Add_Child (+Section2, +Row2);

      Add_Child (+Section3, +Heading3);
      Add_Child (+Row3, +Label3);
      Add_Child (+Row3, +Input3);
      Add_Child (+Row3, +Range_Echo);
      Add_Child (+Section3, +Row3);

      Add_Child (+Section4, +Heading4);
      Add_Child (+Row4, +Label_R);
      Add_Child (+Row4, +Input_R);
      Add_Child (+Row4, +Label_G);
      Add_Child (+Row4, +Input_G);
      Add_Child (+Row4, +Label_B);
      Add_Child (+Row4, +Input_B);
      Add_Child (+Section4, +Row4);

      Add_Child (+Root, +Section1);
      Add_Child (+Root, +Section2);
      Add_Child (+Root, +Section3);
      Add_Child (+Root, +Section4);

      Adi.Window.Set_Root (Win, Widget_Handle'(+Root));
      Adi.MCP.Initialize (Win);
      A.Add_Window (Win);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Value_Input_Example;
