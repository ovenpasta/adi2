--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Window;

package Transition_Example_UI is

   generic
   package Instance is

      function Build return Adi.Window.Window_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Transition_Example_UI;
