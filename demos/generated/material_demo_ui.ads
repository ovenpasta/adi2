--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget.Button.Switch;
with Adi.Widget.Combo_Box;
with Adi.Widget.Integer_Value_Input;
with Adi.Widget.Label;
with Adi.Widget.Slider;
with Adi.Widget.Stack;
with Adi.Widget.Text_Input;
with Adi.Widget.Value_Input;
with Adi.Window;

package Material_Demo_UI is

   type Page is (Home, Forms, Settings, Controls);

   package Page_Stack is new Adi.Widget.Stack (Page);
   package Nav_Options is new Adi.Widget.Button.Options (Page);
   package Float_Slider is new Adi.Widget.Slider (Float);
   package Float_Value_Input is new Adi.Widget.Value_Input (Float);
   package Int_Value_Input is new Adi.Widget.Integer_Value_Input (Integer);

   generic
   package Instance is

      On_Page : Page_Stack.Page_Changed_Callback := null;
      On_Dark_Mode : Adi.Widget.Button.Toggle_Callback := null;
      On_Get_Started : Adi.Widget.Button.Click_Callback := null;
      On_Lock_UI : Adi.Widget.Button.Toggle_Callback := null;
      On_UI_Scale : Float_Slider.Value_Changed_Callback := null;
      On_Text_Scale : Float_Slider.Value_Changed_Callback := null;
      On_Control_Slider : Float_Slider.Value_Changed_Callback := null;
      On_Control_Value : Float_Value_Input.Value_Changed_Callback := null;

      Root : Adi.Widget.Box.Box_Handle;
      App_Title : Adi.Widget.Label.Label_Handle;
      Nav_Bar : Adi.Widget.Box.Box_Handle;
      Btn_Home : Adi.Widget.Button.Button_Handle;
      Btn_Forms : Adi.Widget.Button.Button_Handle;
      Btn_Settings : Adi.Widget.Button.Button_Handle;
      Btn_Controls : Adi.Widget.Button.Button_Handle;
      Pages : Page_Stack.Stack_Handle;
      Name_Input : Adi.Widget.Text_Input.Text_Input_Handle;
      Country_Combo : Adi.Widget.Combo_Box.Combo_Box_Handle;
      Enabled_Input : Adi.Widget.Text_Input.Text_Input_Handle;
      Disabled_Input : Adi.Widget.Text_Input.Text_Input_Handle;
      Enabled_Combo : Adi.Widget.Combo_Box.Combo_Box_Handle;
      Disabled_Combo : Adi.Widget.Combo_Box.Combo_Box_Handle;
      Enabled_Slider : Float_Slider.Slider_Handle;
      Disabled_Slider : Float_Slider.Slider_Handle;
      Enabled_Value_Input : Float_Value_Input.Value_Input_Handle;
      Disabled_Value_Input : Int_Value_Input.Value_Input_Handle;
      Dark_Switch : Adi.Widget.Button.Switch.Switch_Handle;
      UI_Scale_Slider : Float_Slider.Slider_Handle;
      Text_Scale_Slider : Float_Slider.Slider_Handle;
      Lock_Bar : Adi.Widget.Box.Box_Handle;
      Lock_Switch : Adi.Widget.Button.Switch.Switch_Handle;

      Nav_Options_Group : aliased Nav_Options.Option_Group;
      Nav_Options_Group_Conn : Nav_Options.Option_Changed_Signals.Connection_Id :=
        Nav_Options.Option_Changed_Signals.No_Connection;

      function Build return Adi.Window.Window_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Material_Demo_UI;
