--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget;

package Red_Page_UI is

   generic
   package Instance is

      function Build return Adi.Widget.Widget_Access;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Set_CSS_File (Path : String; Success : out Boolean);

   end Instance;

end Red_Page_UI;
