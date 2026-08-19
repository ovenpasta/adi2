pragma Ada_2022;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.App;
with Adi.Layout_Util;
with Adi.Assets;
with Adi.Core;
with Adi.Image;
with Adi.MCP;
with Adi.Widget;          use Adi.Widget;
with Adi.Widget.Button;   use Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget.Box;
with Adi.Widget.Context_Menu;
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

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Adi.Widget.Html_View.Html_View_Handle;
   use type Adi.Widget.Text_Editor.Text_Editor_Handle;
   use type Html_Stack.Stack_Handle;
   use type Float_Slider.Slider_Handle;

   A : Adi.App.App;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);

   --  The context menu is an overlay a widget raises for itself, so it
   --  takes package defaults rather than a class on anything in the tree.
   Adi.Widget.Context_Menu.Set_Default_Menu_Styles
     (Html_View_Example_Styles.Context_Menu_Class_Part_Styles);
   Adi.Widget.Context_Menu.Set_Default_Item_Styles
     (Html_View_Example_Styles.Context_Menu_Item_Class_Part_Styles);

   declare
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("HTML View Example", Adi.Window.Extent (Px (672.0), Px (480.0)));

      Root : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("HTML View Widget");
      Subtitle : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Styles for content come from <style> and <link> inside HTML.");

      Tab_Bar : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Btn_Preview : constant Button_Handle := Create_Handle ("Preview");
      Btn_Source  : constant Button_Handle := Create_Handle ("Source");
      Tabs : aliased Tab_Options.Option_Group;

      Pages : Html_Stack.Stack_Handle;
      Preview_Page : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Source_Page  : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      View : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Source_Editor : constant Adi.Widget.Text_Editor.Text_Editor_Handle :=
        Adi.Widget.Text_Editor.Create_Handle;
      Status : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Edit source and switch to Preview to apply.");

      Bottom_Bar : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Zoom_Slider : constant Float_Slider.Slider_Handle :=
        Float_Slider.Create_Handle (Min => 0.5, Max => 3.0, Value => 1.0);

      Source_Dirty : Boolean := False;

      procedure Apply_Source_To_Preview is
      begin
         Adi.Widget.Html_View.Set_HTML (View, Adi.Widget.Text_Editor.Get_Text (Source_Editor));
         Source_Dirty := False;
         Adi.Widget.Label.Set_Text (Status, "Preview updated from source.");
      end Apply_Source_To_Preview;

      procedure On_Tab_Changed (Value : Page_Tab) is
      begin
         Html_Stack.Set_Active (Pages, Value);

         if Value = Preview_Tab then
            if Source_Dirty then
               Apply_Source_To_Preview;
            else
               Adi.Widget.Label.Set_Text (Status, "Preview is up to date.");
            end if;
         else
            Adi.Widget.Label.Set_Text (Status, "Edit source. Switch to Preview to apply.");
         end if;
      end On_Tab_Changed;

      procedure On_Link_Click
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         Href : String)
      is
         pragma Unreferenced (Self);
      begin
         Adi.Widget.Label.Set_Text (Status, "Link clicked: " & Href);
      end On_Link_Click;

      procedure On_Source_Changed
        (W    : Adi.Widget.Widget_Handle;
         Text : String)
      is
         pragma Unreferenced (W, Text);
      begin
         Source_Dirty := True;
         Adi.Widget.Label.Set_Text (Status, "Source changed. Switch to Preview to apply.");
      end On_Source_Changed;

      function On_Load_Asset
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         URI  : String) return Adi.Image.Image_Handle
      is
         pragma Unreferenced (Self);
      begin
         return Adi.Assets.Get_Image (URI);
      end On_Load_Asset;

      function On_Load_Resource
        (Self : Adi.Widget.Html_View.Html_View_Handle;
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
        (W : Adi.Widget.Widget_Handle; Value : Float)
      is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Html_View.Set_Content_Scale
           (View, Adi.Core.Pixel_Type (Value));
         Adi.Widget.Set_Label (+Zoom_Slider, Percent_Str (Value));
      end On_Zoom_Changed;

   begin
      Float_Slider.Set_Step (Zoom_Slider, 0.1);

      Adi.Assets.Add_Path ("examples/assets", Scheme => "app");
      Adi.Assets.Add_Path ("examples/assets");

      Pages := Html_Stack.Create_Handle;

      declare
         HTML_Text : constant String :=
           Adi.Assets.Get_String ("app://html_view_example.html");
      begin

      Adi.Widget.Box.Set_Part_Styles (Root, Html_View_Example_Styles.Root_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Html_View_Example_Styles.Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Subtitle, Html_View_Example_Styles.Subtitle_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Tab_Bar, Html_View_Example_Styles.Tab_Bar_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Btn_Preview, Html_View_Example_Styles.Tab_Left_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles (Btn_Source, Html_View_Example_Styles.Tab_Right_Class_Part_Styles);
      Html_Stack.Set_Part_Styles (Pages, Html_View_Example_Styles.Stack_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Preview_Page, Html_View_Example_Styles.Page_Preview_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Source_Page, Html_View_Example_Styles.Page_Source_Class_Part_Styles);
      Adi.Widget.Html_View.Set_Part_Styles (View, Html_View_Example_Styles.Html_View_Class_Part_Styles);
      Adi.Widget.Text_Editor.Set_Part_Styles (Source_Editor, Html_View_Example_Styles.Source_Editor_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Status, Html_View_Example_Styles.Status_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Bottom_Bar, Html_View_Example_Styles.Bottom_Bar_Class_Part_Styles);
      Float_Slider.Set_Part_Styles (Zoom_Slider, Html_View_Example_Styles.Zoom_Slider_Class_Part_Styles);

      Tab_Options.Set_Button (Tabs, Preview_Tab, Btn_Preview);
      Tab_Options.Set_Button (Tabs, Source_Tab, Btn_Source);
      Tab_Options.Connect_Changed (Tabs, On_Tab_Changed'Unrestricted_Access);

      Adi.Widget.Html_View.Connect_Link_Click
        (View, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Asset
        (View, On_Load_Asset'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Resource
        (View, On_Load_Resource'Unrestricted_Access);
      Adi.Widget.Html_View.Set_Default_Stylesheet_String
        (View, Adi.Assets.Get_String ("app://html/default.css"));
      Adi.Widget.Html_View.Set_HTML (View, HTML_Text);

      Adi.Widget.Text_Editor.Set_Text (Source_Editor, HTML_Text);
      Adi.Widget.Text_Editor.Connect_Changed
        (Source_Editor, On_Source_Changed'Unrestricted_Access);
      Float_Slider.Connect_Changed
        (Zoom_Slider, On_Zoom_Changed'Unrestricted_Access);

      Adi.Widget.Set_Label (+Zoom_Slider, "Zoom: 100%");

      Adi.Widget.Add_Child (+Bottom_Bar, +Status);
      Adi.Widget.Add_Child (+Bottom_Bar, +Zoom_Slider);

      Adi.Widget.Add_Child (+Preview_Page, +View);
      Adi.Widget.Add_Child (+Source_Page, +Source_Editor);
      Html_Stack.Add_Page (Pages, Preview_Tab, +Preview_Page);
      Html_Stack.Add_Page (Pages, Source_Tab, +Source_Page);

      Adi.Widget.Add_Child (+Tab_Bar, +Btn_Preview);
      Adi.Widget.Add_Child (+Tab_Bar, +Btn_Source);

      Adi.Widget.Add_Child (+Root, +Title);
      Adi.Widget.Add_Child (+Root, +Subtitle);
      Adi.Widget.Add_Child (+Root, +Tab_Bar);
      Adi.Widget.Add_Child (+Root, +Pages);
      Adi.Widget.Add_Child (+Root, +Bottom_Bar);

      Tab_Options.Set_Selected (Tabs, Preview_Tab);

      Adi.MCP.Initialize (W);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
      end;
   end;
end Html_View_Example;
