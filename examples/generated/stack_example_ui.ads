--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget.Stack;
with Adi.Window;
with Green_Page_UI;
with Red_Page_UI;

package Stack_Example_UI is

   type Tab is (Red, Green, Blue);

   package My_Stack is new Adi.Widget.Stack (Tab);
   package Tab_Options is new Adi.Widget.Button.Options (Tab);

   generic
   package Instance is

      On_Tab : My_Stack.Page_Changed_Callback := null;

      Root : Adi.Widget.Box.Box_Widget_Access;
      Tab_Bar : Adi.Widget.Box.Box_Widget_Access;
      Btn_Red : Adi.Widget.Button.Button_Widget_Access;
      Btn_Green : Adi.Widget.Button.Button_Widget_Access;
      Btn_Blue : Adi.Widget.Button.Button_Widget_Access;
      Pages : My_Stack.Stack_Widget_Access;

      package Red_Page is new Red_Page_UI.Instance;
      package Green_Page is new Green_Page_UI.Instance;

      function Build return Adi.Window.Window_Access;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Stack_Example_UI;
