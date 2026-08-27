--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source;
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

      Root : Adi.Widget.Box.Box_Handle;
      Tab_Bar : Adi.Widget.Box.Box_Handle;
      Btn_Red : Adi.Widget.Button.Button_Handle;
      Btn_Green : Adi.Widget.Button.Button_Handle;
      Btn_Blue : Adi.Widget.Button.Button_Handle;
      Pages : My_Stack.Stack_Handle;

      package Red_Page is new Red_Page_UI.Instance;
      package Green_Page is new Green_Page_UI.Instance;

      function Build return Adi.Window.Window_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      --  This package declares more than one <link> sheet, so
      --  naming one of them would replace them all. Any
      --  <style> rules keep their place after these.
      procedure Set_CSS_Sheets
        (Sheets  : Adi.CSS_Source.Dynamic_Source_Entry_Array;
         Success : out Boolean);

   end Instance;

end Stack_Example_UI;
