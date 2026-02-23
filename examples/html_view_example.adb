pragma Ada_2022;

with Ada.Text_IO;

with Adi.App;
with Adi.Assets;
with Adi.Image;
with Adi.Widget;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget.Box;
with Adi.Widget.Html_View;
with Adi.Widget.Label;
with Adi.Widget.Stack;
with Adi.Widget.Text_Editor;
with Adi.Window;

with Html_View_Example_Styles;

procedure Html_View_Example is
   type Page_Tab is (Preview_Tab, Source_Tab);
   package Html_Stack is new Adi.Widget.Stack (Page_Tab);
   package Tab_Options is new Adi.Widget.Button.Options (Page_Tab);

   A : Adi.App.App;

begin
   A.Init;

   declare
      W : constant Adi.Window.Window_Access :=
        Adi.Window.Create_Window ("HTML View Example", (980.0, 700.0));

      Root : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("HTML View Widget");
      Subtitle : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Styles for content come from <style> and <link> inside HTML.");

      Tab_Bar : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Btn_Preview : constant Button_Widget_Access := Create ("Preview");
      Btn_Source  : constant Button_Widget_Access := Create ("Source");
      Tabs : aliased Tab_Options.Option_Group;

      Pages : Html_Stack.Stack_Widget_Access;
      Preview_Page : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Source_Page  : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      View : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Source_Editor : constant Adi.Widget.Text_Editor.Text_Editor_Widget_Access :=
        Adi.Widget.Text_Editor.Create;
      Status : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Edit source and switch to Preview to apply.");

      Source_Dirty : Boolean := False;

      procedure Apply_Source_To_Preview is
      begin
         Adi.Widget.Html_View.Set_HTML (View.all, Adi.Widget.Text_Editor.Get_Text (Source_Editor.all));
         Source_Dirty := False;
         Status.Set_Text ("Preview updated from source.");
      end Apply_Source_To_Preview;

      procedure On_Tab_Changed (Value : Page_Tab) is
      begin
         Pages.Set_Active (Value);

         if Value = Preview_Tab then
            if Source_Dirty then
               Apply_Source_To_Preview;
            else
               Status.Set_Text ("Preview is up to date.");
            end if;
         else
            Status.Set_Text ("Edit source. Switch to Preview to apply.");
         end if;
      end On_Tab_Changed;

      procedure On_Link_Click
        (Self : access Adi.Widget.Html_View.Html_View;
         Href : String)
      is
         pragma Unreferenced (Self);
      begin
         Status.Set_Text ("Link clicked: " & Href);
      end On_Link_Click;

      procedure On_Source_Changed
        (Editor : Adi.Widget.Text_Editor.Text_Editor_Widget_Access;
         Text   : String)
      is
         pragma Unreferenced (Editor, Text);
      begin
         Source_Dirty := True;
         Status.Set_Text ("Source changed. Switch to Preview to apply.");
      end On_Source_Changed;

      function On_Load_Asset
        (Self : access Adi.Widget.Html_View.Html_View;
         URI  : String) return Adi.Image.Image_Access
      is
         pragma Unreferenced (Self);
      begin
         return Adi.Assets.Get_Image (URI);
      end On_Load_Asset;

      function On_Load_Resource
        (Self : access Adi.Widget.Html_View.Html_View;
         URI  : String) return String
      is
         pragma Unreferenced (Self);
      begin
         return Adi.Assets.Get_String (URI);
      end On_Load_Resource;

   begin
      Adi.Assets.Add_Path ("examples/assets", Scheme => "app");
      Adi.Assets.Add_Path ("examples/assets");

      Pages := Html_Stack.Create;

      declare
         HTML_Text : constant String :=
           Adi.Assets.Get_String ("app://html_view_example.html");
      begin

      Adi.Widget.Set_Part_Styles (Root.all, Html_View_Example_Styles.Root_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Title.all, Html_View_Example_Styles.Title_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Subtitle.all, Html_View_Example_Styles.Subtitle_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Tab_Bar.all, Html_View_Example_Styles.Tab_Bar_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Preview.all, Html_View_Example_Styles.Tab_Left_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Source.all, Html_View_Example_Styles.Tab_Right_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Pages.all, Html_View_Example_Styles.Stack_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Preview_Page.all, Html_View_Example_Styles.Page_Preview_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Source_Page.all, Html_View_Example_Styles.Page_Source_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (View.all, Html_View_Example_Styles.Html_View_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Source_Editor.all, Html_View_Example_Styles.Source_Editor_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Status.all, Html_View_Example_Styles.Status_Class_Part_Styles);

      Tabs.Set_Button (Preview_Tab, Btn_Preview);
      Tabs.Set_Button (Source_Tab, Btn_Source);
      Tabs.Set_On_Changed (On_Tab_Changed'Unrestricted_Access);

      Adi.Widget.Html_View.Set_On_Link_Click
        (View.all, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Asset
        (View.all, On_Load_Asset'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Resource
        (View.all, On_Load_Resource'Unrestricted_Access);
      Adi.Widget.Html_View.Set_HTML (View.all, HTML_Text);

      Adi.Widget.Text_Editor.Attach_Window (Source_Editor.all, W);
      Adi.Widget.Text_Editor.Set_Text (Source_Editor.all, HTML_Text);
      Adi.Widget.Text_Editor.Set_On_Changed
        (Source_Editor.all, On_Source_Changed'Unrestricted_Access);

      Preview_Page.Add_Child (View);
      Source_Page.Add_Child (Source_Editor);
      Pages.Add_Page (Preview_Tab, Preview_Page);
      Pages.Add_Page (Source_Tab, Source_Page);

      Tab_Bar.Add_Child (Btn_Preview);
      Tab_Bar.Add_Child (Btn_Source);

      Root.Add_Child (Title);
      Root.Add_Child (Subtitle);
      Root.Add_Child (Tab_Bar);
      Root.Add_Child (Pages);
      Root.Add_Child (Status);

      Tabs.Set_Selected (Preview_Tab);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
      end;
   end;
end Html_View_Example;
