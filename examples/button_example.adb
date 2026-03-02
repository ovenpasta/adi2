pragma Ada_2022;
with Adi.Log;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Switch;
with Adi.Widget.Button.Options;
with Button_Example_Styles; use Button_Example_Styles;

procedure Button_Example is
   A : Adi.App.App;

   type Align_Option is (Left, Center, Right);
   package Align_Options is new Adi.Widget.Button.Options (Align_Option);

   procedure On_Simple_Click (Btn : Button_Widget_Access) is
      pragma Unreferenced (Btn);
   begin
      Adi.Log.Info ("Simple button clicked!");
   end On_Simple_Click;

   procedure On_Toggle (Btn : Button_Widget_Access; Active : Boolean) is
      pragma Unreferenced (Btn);
   begin
      Adi.Log.Info ("Toggle button: " & Active'Image);
   end On_Toggle;

   procedure On_Align_Changed (Value : Align_Option) is
   begin
      Adi.Log.Info ("Alignment changed to: " & Value'Image);
   end On_Align_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("Button Example", (700.0, 500.0));

      Root      : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Section1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Btn_Primary : constant Button_Widget_Access := Create ("Primary");
      Btn_Danger  : constant Button_Widget_Access := Create ("Delete");
      Btn_Outline : constant Button_Widget_Access := Create ("Cancel");

      Section2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Btn_Toggle : constant Button_Widget_Access := Create ("Bold");
      Btn_Switch : constant Adi.Widget.Button.Switch.Switch_Widget_Access :=
        Adi.Widget.Button.Switch.Create (False);

      Section3 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Btn_Left   : constant Button_Widget_Access := Create ("Left");
      Btn_Center : constant Button_Widget_Access := Create ("Center");
      Btn_Right  : constant Button_Widget_Access := Create ("Right");
      Align_Group : aliased Align_Options.Option_Group;
   begin
      Btn_Primary.Connect_Clicked (On_Simple_Click'Unrestricted_Access);
      Btn_Danger.Connect_Clicked (On_Simple_Click'Unrestricted_Access);
      Btn_Outline.Connect_Clicked (On_Simple_Click'Unrestricted_Access);

      Btn_Toggle.Set_Toggleable;
      Btn_Toggle.Connect_Toggled (On_Toggle'Unrestricted_Access);
      Btn_Switch.Connect_Toggled (On_Toggle'Unrestricted_Access);

      Align_Group.Set_Button (Left, Btn_Left);
      Align_Group.Set_Button (Center, Btn_Center);
      Align_Group.Set_Button (Right, Btn_Right);
      Align_Group.Connect_Changed (On_Align_Changed'Unrestricted_Access);

      Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Set_Part_Styles (Container.all, Container_Class_Part_Styles);

      Set_Part_Styles (Section1.all, Section_Row_Class_Part_Styles);
      Set_Part_Styles (Section2.all, Section_Row_Class_Part_Styles);
      Set_Part_Styles (Section3.all, Section_Row_2_Class_Part_Styles);

      Set_Part_Styles (Btn_Primary.all, Primary_Class_Part_Styles);
      Set_Part_Styles (Btn_Danger.all, Danger_Class_Part_Styles);
      Set_Part_Styles (Btn_Outline.all, Outline_Class_Part_Styles);
      Set_Part_Styles (Btn_Toggle.all, Toggle_Class_Part_Styles);
      Set_Part_Styles (Btn_Switch.all, Switch_Class_Part_Styles);

      Set_Part_Styles (Btn_Left.all, Option_Left_Class_Part_Styles);
      Set_Part_Styles (Btn_Center.all, Option_Center_Class_Part_Styles);
      Set_Part_Styles (Btn_Right.all, Option_Right_Class_Part_Styles);

      Root.Add_Child (Container);

      Container.Add_Child (Section1);
      Section1.Add_Child (Btn_Primary);
      Section1.Add_Child (Btn_Danger);
      Section1.Add_Child (Btn_Outline);

      Container.Add_Child (Section2);
      Section2.Add_Child (Btn_Toggle);
      Section2.Add_Child (Btn_Switch);

      Container.Add_Child (Section3);
      Section3.Add_Child (Btn_Left);
      Section3.Add_Child (Btn_Center);
      Section3.Add_Child (Btn_Right);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Button_Example;
