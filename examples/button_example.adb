pragma Ada_2022;
with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Log;
with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Button; use type Adi.Widget.Button.Button_Handle;
with Adi.Widget.Button.Switch; use type Adi.Widget.Button.Switch.Switch_Handle;
with Adi.Widget.Button.Options;
with Button_Example_Styles; use Button_Example_Styles;

procedure Button_Example is
   A : Adi.App.App;

   type Align_Option is (Left, Center, Right);
   package Align_Options is new Adi.Widget.Button.Options (Align_Option);

   procedure On_Simple_Click (W : Widget_Handle) is
      pragma Unreferenced (W);
   begin
      Adi.Log.Info ("Simple button clicked!");
   end On_Simple_Click;

   procedure On_Toggle (W : Widget_Handle; Active : Boolean) is
      pragma Unreferenced (W);
   begin
      Adi.Log.Info ("Toggle button: " & Active'Image);
   end On_Toggle;

   procedure On_Align_Changed (Value : Align_Option) is
   begin
      Adi.Log.Info ("Alignment changed to: " & Value'Image);
   end On_Align_Changed;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle := Create_Window_Handle ("Button Example", Adi.Window.Extent (Px (480.0), Px (343.0)));

      Root      : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Container : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Section1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Btn_Primary : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Primary");
      Btn_Danger  : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Delete");
      Btn_Outline : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Cancel");

      Section2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Btn_Toggle : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Bold");
      Btn_Switch : constant Adi.Widget.Button.Switch.Switch_Handle :=
        Adi.Widget.Button.Switch.Create_Handle (False);

      Section3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Btn_Left   : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Left");
      Btn_Center : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Center");
      Btn_Right  : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Right");
      Align_Group : aliased Align_Options.Option_Group;
   begin
      Adi.Widget.Button.Connect_Clicked (Btn_Primary, On_Simple_Click'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked (Btn_Danger,  On_Simple_Click'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked (Btn_Outline, On_Simple_Click'Unrestricted_Access);

      Adi.Widget.Button.Set_Toggleable (Btn_Toggle);
      Adi.Widget.Button.Connect_Toggled (Btn_Toggle, On_Toggle'Unrestricted_Access);
      Adi.Widget.Button.Switch.Connect_Toggled (Btn_Switch, On_Toggle'Unrestricted_Access);

      Align_Options.Set_Button (Align_Group, Left,   Btn_Left);
      Align_Options.Set_Button (Align_Group, Center, Btn_Center);
      Align_Options.Set_Button (Align_Group, Right,  Btn_Right);
      Align_Options.Connect_Changed (Align_Group, On_Align_Changed'Unrestricted_Access);

      Adi.Widget.Box.Set_Part_Styles (Root,      Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Container, Container_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Section1, Section_Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section2, Section_Row_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Section3, Section_Row_2_Class_Part_Styles);

      Adi.Widget.Button.Set_Part_Styles (Btn_Primary, Primary_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Btn_Danger,  Danger_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Btn_Outline, Outline_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Btn_Toggle,  Toggle_Class_Part_Styles);
      Adi.Widget.Button.Switch.Set_Part_Styles (Btn_Switch, Switch_Class_Part_Styles);

      Adi.Widget.Button.Set_Part_Styles (Btn_Left,   Option_Left_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Btn_Center, Option_Center_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Btn_Right,  Option_Right_Class_Part_Styles);

      Adi.Widget.Box.Add_Child (Root,      +Container);
      Adi.Widget.Box.Add_Child (Container, +Section1);
      Adi.Widget.Box.Add_Child (Section1,  +Btn_Primary);
      Adi.Widget.Box.Add_Child (Section1,  +Btn_Danger);
      Adi.Widget.Box.Add_Child (Section1,  +Btn_Outline);

      Adi.Widget.Box.Add_Child (Container, +Section2);
      Adi.Widget.Box.Add_Child (Section2,  +Btn_Toggle);
      Adi.Widget.Box.Add_Child (Section2,  +Btn_Switch);

      Adi.Widget.Box.Add_Child (Container, +Section3);
      Adi.Widget.Box.Add_Child (Section3,  +Btn_Left);
      Adi.Widget.Box.Add_Child (Section3,  +Btn_Center);
      Adi.Widget.Box.Add_Child (Section3,  +Btn_Right);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Button_Example;
