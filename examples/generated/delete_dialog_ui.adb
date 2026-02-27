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
      return Adi.Widget.Dialog.Dialog_Widget_Access is
      D : constant Adi.Widget.Dialog.Dialog_Widget_Access :=
        Adi.Widget.Dialog.Create;
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Account: john@example.com");
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Created: January 2024");
      Label_3 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Storage used: 4.2 GB");
   begin
      --  Apply precompiled styles
      Set_Part_Styles (Box_1.all, Custom_Content_Class_Part_Styles);
      Set_Part_Styles (Label_1.all, Detail_Label_Class_Part_Styles);
      Set_Part_Styles (Label_2.all, Detail_Label_Class_Part_Styles);
      Set_Part_Styles (Label_3.all, Detail_Label_Class_Part_Styles);

      --  Build hierarchy
      Box_1.Add_Child (Label_1);
      Box_1.Add_Child (Label_2);
      Box_1.Add_Child (Label_3);

      --  Configure dialog
      D.Set_Title ("Delete Account");
      D.Set_Message ("This will permanently delete your account and all associated data. This action cannot be undone.");
      D.Set_Yes_No;
      D.Set_Default_Button (2);
      D.Set_Dismiss_On_Escape (True);
      D.Set_Content (Box_1);
      return D;
   end Build;

   end Instance;

end Delete_Dialog_UI;
