--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Dialog;

package Delete_Dialog_UI is

   generic
   package Instance is

      function Build return Adi.Widget.Dialog.Dialog_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

   end Instance;

end Delete_Dialog_UI;
