--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget.Dialog;
with Adi.Window;

package Delete_Dialog_UI is

   generic
   package Instance is

      function Build return Adi.Widget.Dialog.Dialog_Handle;

      procedure Tick_Styles (Reloaded : out Boolean;
                             Success  : out Boolean);

      procedure Attach_Window (D : Adi.Widget.Dialog.Dialog_Handle; Host : Adi.Window.Window_Handle);

   end Instance;

end Delete_Dialog_UI;
