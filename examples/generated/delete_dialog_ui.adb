--  Auto-generated from XML
--  Do not edit manually

pragma Wide_Character_Encoding (Brackets);
pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Dialog_Example_Styles;

package body Delete_Dialog_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;

   function Merge_Metadata
     (Base, Override : Adi.CSS_Parser.Stylesheet_Metadata)
      return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := Base;
   begin
      if Override.Has_Root_Style then
         if Result.Has_Root_Style then
            Result.Root_Styles :=
              Adi.Widget.Intern
                (Merge_Part_Styles
                   (Adi.Widget.Expand (Result.Root_Styles),
                    Adi.Widget.Expand (Override.Root_Styles)));
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

   procedure Attach_Window (D : Adi.Widget.Dialog.Dialog_Handle; Host : Adi.Window.Window_Handle) is
   begin
      Adi.Widget.Dialog.Attach_Window (D, Host);
   end Attach_Window;

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
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Dialog_Example_Styles.Register_Selectors (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);
      declare
         Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
      end;
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_1,
         Tag_Name   => "box",
         Class_Name => "custom-content");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_1,
         Tag_Name   => "label",
         Class_Name => "detail-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_2,
         Tag_Name   => "label",
         Class_Name => "detail-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_3,
         Tag_Name   => "label",
         Class_Name => "detail-label");

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
            Adi.Widget.Dialog.Set_Panel_Style (D, Adi.Widget.Expand (Root_Meta.Root_Styles));
         end if;
      end;
      return D;
   end Build;

   end Instance;

end Delete_Dialog_UI;
