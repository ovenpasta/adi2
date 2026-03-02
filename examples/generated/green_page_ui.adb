--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Stack_Example_Green_Styles; use Stack_Example_Green_Styles;

package body Green_Page_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;

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

   procedure Set_CSS_File (Path : String; Success : out Boolean) is
      Mode_OK : Boolean;
   begin
      Adi.CSS_Source.Clear_Dynamic_Entries (Source);
      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);
      if Success then
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         Adi.CSS_Source.Set_Auto_Reload (Source, True);
         Success := Mode_OK;
      end if;
   end Set_CSS_File;

   function Build
      return Adi.Widget.Widget_Access is
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Green Page");
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("This is the second page with a natural green background.");
   begin
      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-green", Page_Green_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-title", Page_Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("page-desc", Page_Desc_Class_Part_Styles));

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/stack_example_green.css", Loaded);
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

      --  Bind every widget that has a CSS class
      Adi.CSS_Source.Bind_Class (Source, "page-green", Box_1);
      Adi.CSS_Source.Bind_Class (Source, "page-title", Label_1);
      Adi.CSS_Source.Bind_Class (Source, "page-desc", Label_2);

      --  Build hierarchy
      Box_1.Add_Child (Label_1);
      Box_1.Add_Child (Label_2);

      return Adi.Widget.Widget_Access (Box_1);
   end Build;

   end Instance;

end Green_Page_UI;
