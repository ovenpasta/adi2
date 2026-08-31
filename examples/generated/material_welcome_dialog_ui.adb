--  Auto-generated from XML
--  Do not edit manually

pragma Wide_Character_Encoding (Brackets);
pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Label; use Adi.Widget.Label;
with Material_Demo_Styles; use Material_Demo_Styles;

package body Material_Welcome_Dialog_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;
   Live_CSS_Host : Adi.Window.Window_Handle := Adi.Window.Null_Window_Handle;

   function Merge_Metadata
     (Base, Override : Adi.CSS_Parser.Stylesheet_Metadata)
      return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := Base;
   begin
      if Override.Has_Root_Style then
         if Result.Has_Root_Style then
            Result.Root_Styles :=
              Merge_Part_Styles
                (Result.Root_Styles, Override.Root_Styles);
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
      Result := Merge_Metadata (Result, Material_Demo_Styles.Root_Metadata);
      return Result;
   end Static_Root_Metadata;
   use type Adi.Window.Window_Handle;

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Reloaded := False;
      Success := True;
      declare
         Local_Reloaded : Boolean := False;
         Local_Success  : Boolean := True;
      begin
         Adi.CSS_Source.Tick (Source, Local_Reloaded, Local_Success);
         Reloaded := Reloaded or Local_Reloaded;
         Success := Success and Local_Success;
      end;
   end Tick_Styles;

   procedure Tick_Styles_CB (DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded, Success : Boolean;
   begin
      Tick_Styles (Reloaded, Success);
   end Tick_Styles_CB;

   procedure Attach_Window (D : Adi.Widget.Dialog.Dialog_Handle; Host : Adi.Window.Window_Handle) is
   begin
      Adi.Widget.Dialog.Attach_Window (D, Host);
      if Live_CSS_Host /= Host then
         Adi.Window.Connect_Tick (Host, Tick_Styles_CB'Unrestricted_Access);
         Live_CSS_Host := Host;
      end if;
   end Attach_Window;

   procedure Set_CSS_File (Path : String; Success : out Boolean) is
      Mode_OK : Boolean;
   begin
      Adi.CSS_Source.Set_Dynamic_Sources
        (Source, [Adi.CSS_Source.CSS_File (Path)], Success);
      if Success then
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         Adi.CSS_Source.Set_Auto_Reload (Source, True);
         Success := Mode_OK;
      end if;
   end Set_CSS_File;

   function Build
      return Adi.Widget.Dialog.Dialog_Handle is
      D : constant Adi.Widget.Dialog.Dialog_Handle :=
        Adi.Widget.Dialog.Create_Handle;
   begin
      --  Install the stylesheets as one batch: precompiled
      --  styles as static fallback, then dynamic CSS and the mode
      declare
         Update : Adi.CSS_Source.Update_Scope (Source'Access);
         pragma Unreferenced (Update);
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Static_Entries (Source);
         Material_Demo_Styles.Register_Selectors (Source);
         Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

         Adi.CSS_Source.Set_Dynamic_Sources
           (Source,
            [Adi.CSS_Source.CSS_File ("examples/css/material_demo.css")],
            Loaded);
         if Loaded then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         else
            Mode_OK := False;
         end if;
         if not Mode_OK then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
         end if;
      end;

      --  Bind every widget under the selectors naming it

      --  Configure dialog
      Adi.Widget.Dialog.Set_OK_Button (D);
      Adi.Widget.Dialog.Set_Button_Style (D, Dialog_Btn_Class_Part_Styles);
      --  Bind dialog live CSS
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Adi.Widget.Dialog.Get_Content_Panel_Handle (D));
      Adi.CSS_Source.Bind_Class (Source, "dialog-backdrop", Adi.Widget.Dialog.To_Widget_Handle (D));
      Adi.CSS_Source.Bind_Class (Source, "dialog-panel", +Adi.Widget.Dialog.Get_Content_Panel_Handle (D));
      Adi.CSS_Source.Bind_Class (Source, "dialog-title", +Adi.Widget.Dialog.Get_Title_Handle (D));
      Adi.CSS_Source.Bind_Class (Source, "dialog-message", +Adi.Widget.Dialog.Get_Message_Handle (D));
      Adi.CSS_Source.Bind_Class (Source, "dialog-btn-row", +Adi.Widget.Dialog.Get_Button_Row_Handle (D));
      Adi.CSS_Source.Bind_Class (Source, "dialog-btn", +Adi.Widget.Dialog.Get_Button_Handle (D, 1));
      return D;
   end Build;

   end Instance;

end Material_Welcome_Dialog_UI;
