--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Dialog; use Adi.Widget.Dialog;
with Adi.Widget.Label; use Adi.Widget.Label;
with Dialog_Example_Styles; use Dialog_Example_Styles;

package body Delete_Dialog_UI is

   package body Instance is

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Reloaded := False;
      Success := True;
   end Tick_Styles;

   function Build
      return Adi.Widget.Dialog.Dialog_Handle is
      D : constant Adi.Widget.Dialog.Dialog_Handle :=
        Adi.Widget.Dialog.Create_Handle;
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Account: john@example.com");
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Created: January 2024");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Storage used: 4.2 GB");
   begin
      --  Apply precompiled styles
      Set_Part_Styles (+Box_1, Custom_Content_Class_Part_Styles);
      Set_Part_Styles (+Label_1, Detail_Label_Class_Part_Styles);
      Set_Part_Styles (+Label_2, Detail_Label_Class_Part_Styles);
      Set_Part_Styles (+Label_3, Detail_Label_Class_Part_Styles);

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_1, +Label_1);
      Adi.Widget.Add_Child (+Box_1, +Label_2);
      Adi.Widget.Add_Child (+Box_1, +Label_3);

      --  Configure dialog
      Adi.Widget.Dialog.Set_Title (D, "Delete Account");
      Adi.Widget.Dialog.Set_Message (D, "This will permanently delete your account and all associated data. This action cannot be undone.");
      Adi.Widget.Dialog.Set_Yes_No (D);
      Adi.Widget.Dialog.Set_Default_Button (D, 2);
      Adi.Widget.Dialog.Set_Dismiss_On_Escape (D, True);
      Adi.Widget.Dialog.Set_Content (D, +Box_1);
      return D;
   end Build;

   end Instance;

end Delete_Dialog_UI;
