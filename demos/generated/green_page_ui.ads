--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget;

package Green_Page_UI is

   generic
   package Instance is

      function Build return Adi.Widget.Widget_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Green_Page_UI;
