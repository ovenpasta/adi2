--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Box;
with Adi.Window;

package Demo_Block_UI is

   generic
   package Instance is

      Root : Adi.Widget.Box.Box_Handle;

      function Build return Adi.Window.Window_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Demo_Block_UI;
