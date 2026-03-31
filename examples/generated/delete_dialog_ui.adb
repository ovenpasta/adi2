--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Layout_Util;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Label; use Adi.Widget.Label;
with Dialog_Example_Styles; use Dialog_Example_Styles;

package body Delete_Dialog_UI is

   package body Instance is

   function Merge_Metadata
     (Base, Override : Adi.CSS_Parser.Stylesheet_Metadata)
      return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := Base;
   begin
      if Override.Has_Root_Style then
         if Result.Has_Root_Style then
            Result.Root_Styles :=
              Merge_Part_Styles (Result.Root_Styles, Override.Root_Styles);
         else
            Result.Root_Styles := Override.Root_Styles;
            Result.Has_Root_Style := True;
         end if;
      end if;
      if Override.Has_Root_Font_Size then
         Result.Has_Root_Font_Size := True;
         Result.Root_Font_Size := Override.Root_Font_Size;
      end if;
      return Result;
   end Merge_Metadata;

   function Static_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := (others => <>);
   begin
      Result := Merge_Metadata (Result, Dialog_Example_Styles.Root_Metadata);
      return Result;
   end Static_Root_Metadata;

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Reloaded := False;
      Success := True;
   end Tick_Styles;

   procedure Apply_Box_1_Styles
     (H : Widget_Handle) is
   begin
      Set_Part_Styles (H, Custom_Content_Class_Part_Styles);
   end Apply_Box_1_Styles;

   procedure Apply_Label_1_Styles
     (H : Widget_Handle) is
   begin
      Set_Part_Styles (H, Detail_Label_Class_Part_Styles);
   end Apply_Label_1_Styles;

   procedure Apply_Label_2_Styles
     (H : Widget_Handle) is
   begin
      Set_Part_Styles (H, Detail_Label_Class_Part_Styles);
   end Apply_Label_2_Styles;

   procedure Apply_Label_3_Styles
     (H : Widget_Handle) is
   begin
      Set_Part_Styles (H, Detail_Label_Class_Part_Styles);
   end Apply_Label_3_Styles;

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
      declare
         Root_Meta : constant Adi.CSS_Parser.Stylesheet_Metadata :=
           Static_Root_Metadata;
      begin
      end;
      Apply_Box_1_Styles (+Box_1);
      Apply_Label_1_Styles (+Label_1);
      Apply_Label_2_Styles (+Label_2);
      Apply_Label_3_Styles (+Label_3);

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
      declare
         Root_Meta : constant Adi.CSS_Parser.Stylesheet_Metadata :=
           Static_Root_Metadata;
      begin
         if Root_Meta.Has_Root_Style then
            Adi.Widget.Dialog.Set_Panel_Style (D, Root_Meta.Root_Styles);
         end if;
      end;
      return D;
   end Build;

   end Instance;

end Delete_Dialog_UI;
