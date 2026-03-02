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

      Root : Adi.Widget.Box.Box_Widget_Access;
      App_Title : Adi.Widget.Label.Label_Widget_Access;
      Nav_Bar : Adi.Widget.Box.Box_Widget_Access;
      Btn_Home : Adi.Widget.Button.Button_Widget_Access;
      Btn_Forms : Adi.Widget.Button.Button_Widget_Access;
      Btn_Settings : Adi.Widget.Button.Button_Widget_Access;
      Btn_Controls : Adi.Widget.Button.Button_Widget_Access;
      Pages : Page_Stack.Stack_Widget_Access;
      Name_Input : Adi.Widget.Text_Input.Text_Input_Widget_Access;
      Country_Combo : Adi.Widget.Combo_Box.Combo_Box_Widget_Access;
      Enabled_Input : Adi.Widget.Text_Input.Text_Input_Widget_Access;
      Disabled_Input : Adi.Widget.Text_Input.Text_Input_Widget_Access;
      Enabled_Combo : Adi.Widget.Combo_Box.Combo_Box_Widget_Access;
      Disabled_Combo : Adi.Widget.Combo_Box.Combo_Box_Widget_Access;
      Enabled_Slider : Float_Slider.Slider_Widget_Access;
      Disabled_Slider : Float_Slider.Slider_Widget_Access;
      Enabled_Value_Input : Float_Value_Input.Value_Input_Widget_Access;
      Disabled_Value_Input : Int_Value_Input.Value_Input_Widget_Access;
      Dark_Switch : Adi.Widget.Button.Switch.Switch_Widget_Access;
      Lock_Bar : Adi.Widget.Box.Box_Widget_Access;
      Lock_Switch : Adi.Widget.Button.Switch.Switch_Widget_Access;

      Nav_Options_Group : aliased Nav_Options.Option_Group;
      Nav_Options_Group_Conn : Nav_Options.Option_Changed_Signals.Connection_Id :=
        Nav_Options.Option_Changed_Signals.No_Connection;

      function Build return Adi.Window.Window_Access;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Material_Demo_UI;
