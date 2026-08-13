--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Window;

package Hello_Example_UI is

   generic
   package Instance is

      On_Hello_Click : Adi.Widget.Button.Click_Callback := null;

      Greeting : Adi.Widget.Label.Label_Handle;

      function Build return Adi.Window.Window_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Hello_Example_UI;
