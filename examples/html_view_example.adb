pragma Ada_2022;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Adi.App;
with Adi.Assets;
with Adi.Core;
with Adi.Image;
with Adi.MCP;
with Adi.Widget;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget.Box;
with Adi.Widget.Html_View;
with Adi.Widget.Label;
with Adi.Widget.Slider;
with Adi.Widget.Stack;
with Adi.Widget.Text_Editor;
with Adi.Window;

with Html_View_Example_Styles;

procedure Html_View_Example is
   type Page_Tab is (Preview_Tab, Source_Tab);
   package Html_Stack is new Adi.Widget.Stack (Page_Tab);
   package Tab_Options is new Adi.Widget.Button.Options (Page_Tab);
   package Float_Slider is new Adi.Widget.Slider (Float);

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

      Bottom_Bar : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Zoom_Slider : constant Float_Slider.Slider_Widget_Access :=
        Float_Slider.Create (Min => 0.5, Max => 3.0, Value => 1.0);

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

      function Percent_Str (V : Float) return String is
         Pct : constant Integer := Integer (V * 100.0);
      begin
         return "Zoom:" & Trim (Pct'Image, Both) & "%";
      end Percent_Str;

      procedure On_Zoom_Changed
        (W : Float_Slider.Slider_Widget_Access; Value : Float)
      is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Html_View.Set_Content_Scale
           (View.all, Adi.Core.Pixel_Type (Value));
         Adi.Widget.Set_Label (Zoom_Slider.all, Percent_Str (Value));
      end On_Zoom_Changed;

   begin
      Float_Slider.Set_Step (Zoom_Slider.all, 0.1);

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
      Adi.Widget.Set_Part_Styles (Bottom_Bar.all, Html_View_Example_Styles.Bottom_Bar_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Zoom_Slider.all, Html_View_Example_Styles.Zoom_Slider_Class_Part_Styles);

      Tabs.Set_Button (Preview_Tab, Btn_Preview);
      Tabs.Set_Button (Source_Tab, Btn_Source);
      Tabs.Set_On_Changed (On_Tab_Changed'Unrestricted_Access);

      Adi.Widget.Html_View.Set_On_Link_Click
        (View.all, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Asset
        (View.all, On_Load_Asset'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Resource
        (View.all, On_Load_Resource'Unrestricted_Access);
      Adi.Widget.Html_View.Set_Default_Stylesheet_String
        (View.all, Adi.Assets.Get_String ("app://html/default.css"));
      Adi.Widget.Html_View.Set_HTML (View.all, HTML_Text);

      Adi.Widget.Text_Editor.Set_Text (Source_Editor.all, HTML_Text);
      Adi.Widget.Text_Editor.Set_On_Changed
        (Source_Editor.all, On_Source_Changed'Unrestricted_Access);
      Float_Slider.Set_On_Changed
        (Zoom_Slider.all, On_Zoom_Changed'Unrestricted_Access);

      Adi.Widget.Set_Label (Zoom_Slider.all, "Zoom: 100%");

      Bottom_Bar.Add_Child (Status);
      Bottom_Bar.Add_Child (Zoom_Slider);

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
      Root.Add_Child (Bottom_Bar);

      Tabs.Set_Selected (Preview_Tab);

      Adi.MCP.Initialize (W);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
      end;
   end;
end Html_View_Example;
