pragma Ada_2022;
with Ada.Text_IO;       use Ada.Text_IO;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Button_Example_Styles; use Button_Example_Styles;

procedure Button_Example is
   A : Adi.App.App;

   type Align_Option is (Left, Center, Right);
   package Align_Options is new Adi.Widget.Button.Options (Align_Option);

   procedure On_Simple_Click (Btn : Button_Widget_Access) is
   begin
      Put_Line ("Simple button clicked!");
   end On_Simple_Click;

   procedure On_Toggle (Btn : Button_Widget_Access; Active : Boolean) is
   begin
      Put_Line ("Toggle button: " & Active'Image);
   end On_Toggle;

   procedure On_Align_Changed (Value : Align_Option) is
   begin
      Put_Line ("Alignment changed to: " & Value'Image);
   end On_Align_Changed;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : Window_Access := Create_Window ("Button Example", (700.0, 500.0));

      Root      : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Container : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Section1 : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Btn_Primary : Button_Widget_Access := Create ("Primary");
      Btn_Danger  : Button_Widget_Access := Create ("Delete");
      Btn_Outline : Button_Widget_Access := Create ("Cancel");

      Section2 : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Btn_Toggle : Button_Widget_Access := Create ("Bold");

      Section3 : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Btn_Left   : Button_Widget_Access := Create ("Left");
      Btn_Center : Button_Widget_Access := Create ("Center");
      Btn_Right  : Button_Widget_Access := Create ("Right");
      Align_Group : aliased Align_Options.Option_Group;
   begin
      Btn_Primary.Set_On_Clicked (On_Simple_Click'Unrestricted_Access);
      Btn_Danger.Set_On_Clicked (On_Simple_Click'Unrestricted_Access);
      Btn_Outline.Set_On_Clicked (On_Simple_Click'Unrestricted_Access);

      Btn_Toggle.Set_Toggleable;
      Btn_Toggle.Set_On_Toggled (On_Toggle'Unrestricted_Access);

      Align_Group.Set_Button (Left, Btn_Left);
      Align_Group.Set_Button (Center, Btn_Center);
      Align_Group.Set_Button (Right, Btn_Right);
      Align_Group.Set_On_Changed (On_Align_Changed'Unrestricted_Access);

      Set_Part_Styles (Root.all, Root_Part_Styles);
      Set_Part_Styles (Container.all, Container_Part_Styles);

      Set_Part_Styles (Section1.all, Section_Row_Part_Styles);
      Set_Part_Styles (Section2.all, Section_Row_Part_Styles);
      Set_Part_Styles (Section3.all, Section_Row_2_Part_Styles);

      Set_Part_Styles (Btn_Primary.all, Primary_Part_Styles);
      Set_Part_Styles (Btn_Danger.all, Danger_Part_Styles);
      Set_Part_Styles (Btn_Outline.all, Outline_Part_Styles);
      Set_Part_Styles (Btn_Toggle.all, Toggle_Part_Styles);

      Set_Part_Styles (Btn_Left.all, Option_Left_Part_Styles);
      Set_Part_Styles (Btn_Center.all, Option_Center_Part_Styles);
      Set_Part_Styles (Btn_Right.all, Option_Right_Part_Styles);

      Add_Child (Root.all, Widget_Access (Container));

      Add_Child (Container.all, Widget_Access (Section1));
      Add_Child (Section1.all, Widget_Access (Btn_Primary));
      Add_Child (Section1.all, Widget_Access (Btn_Danger));
      Add_Child (Section1.all, Widget_Access (Btn_Outline));

      Add_Child (Container.all, Widget_Access (Section2));
      Add_Child (Section2.all, Widget_Access (Btn_Toggle));

      Add_Child (Container.all, Widget_Access (Section3));
      Add_Child (Section3.all, Widget_Access (Btn_Left));
      Add_Child (Section3.all, Widget_Access (Btn_Center));
      Add_Child (Section3.all, Widget_Access (Btn_Right));

      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Button_Example;
