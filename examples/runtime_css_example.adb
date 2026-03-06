pragma Ada_2022;

with Ada.Directories;

with Adi.App;
with Adi.CSS_Source;
with Adi.Widget;
with Adi.Widget.Button;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Window;
with Runtime_Css_Example_Styles;

procedure Runtime_Css_Example is

   type Style_Source_Access is access all Adi.CSS_Source.Style_Source;
   use type Adi.CSS_Source.Source_Mode;
   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Label.Label_Handle;

   type Live_Root_Widget is new Adi.Widget.Box.Box_Widget with record
      Source       : Style_Source_Access := null;
      Status_Label : Adi.Widget.Label.Label_Handle;
      Reload_Count : Natural := 0;
      Last_OK      : Boolean := True;
   end record;

   type Live_Root_Access is access all Live_Root_Widget'Class;

   overriding procedure On_Tick (W : in out Live_Root_Widget; DT : Duration);

   overriding procedure On_Tick (W : in out Live_Root_Widget; DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded : Boolean := False;
      Success  : Boolean := False;
   begin
      if W.Source = null then
         return;
      end if;

      Adi.CSS_Source.Tick (W.Source.all, Reloaded, Success);

      if not Adi.Widget.Label.Is_Valid (W.Status_Label) then
         return;
      end if;

      if not Success then
         if W.Last_OK then
            Adi.Widget.Label.Set_Text (W.Status_Label,
              "CSS reload error: " & Adi.CSS_Source.Get_Last_Error (W.Source.all));
         end if;
         W.Last_OK := False;
         return;
      end if;

      if Reloaded and then Adi.CSS_Source.Get_Mode (W.Source.all) = Adi.CSS_Source.Dynamic_Mode then
         W.Reload_Count := W.Reload_Count + 1;
         Adi.Widget.Label.Set_Text (W.Status_Label,
           "Live reload OK (" & W.Reload_Count'Image & ") - edit css/runtime_css_example.css");
      end if;

      W.Last_OK := True;
   end On_Tick;

   function Resolve_CSS_Path return String is
   begin
      if Ada.Directories.Exists ("examples/css/runtime_css_example.css") then
         return "examples/css/runtime_css_example.css";
      elsif Ada.Directories.Exists ("css/runtime_css_example.css") then
         return "css/runtime_css_example.css";
      elsif Ada.Directories.Exists ("../css/runtime_css_example.css") then
         return "../css/runtime_css_example.css";
      else
         return "examples/css/runtime_css_example.css";
      end if;
   end Resolve_CSS_Path;

   A : Adi.App.App;

begin
   A.Init;

   declare
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Runtime CSS Example", (980.0, 640.0));

      Source : aliased Adi.CSS_Source.Style_Source;
      CSS_Path : constant String := Resolve_CSS_Path;
      Loaded : Boolean := False;
      Mode_OK : Boolean := False;

      Root : constant Live_Root_Access :=
        new Live_Root_Widget'
          (Adi.Widget.Box.Box_Widget with
             Source       => Source'Unchecked_Access,
             Status_Label => Adi.Widget.Label.Null_Label_Handle,
             Reload_Count => 0,
             Last_OK      => True);

      Header : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Content : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Card_Left : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Card_Right : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;

      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Runtime CSS Live Reload");
      Subtitle : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Edit the css file while this app is open.");
      Badge : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("LIVE");
      Mode_Button : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Mode: Dynamic CSS");

      Left_Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Card One");
      Left_Body : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("This style is loaded from disk at runtime." & ASCII.LF
           & "Try changing border radius, shadows, colors, and spacing.");

      Right_Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Card Two");
      Right_Body : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Hover styles and typography changes also hot-reload." & ASCII.LF
           & "No codegen step is needed.");

      Status : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Waiting for CSS load...");

      Static_Entries : constant Adi.CSS_Source.Static_Style_Entry_Array := [
        Adi.CSS_Source.Class_Entry ("root", Runtime_Css_Example_Styles.Root_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("header", Runtime_Css_Example_Styles.Header_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("content", Runtime_Css_Example_Styles.Content_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("card-left", Runtime_Css_Example_Styles.Card_Left_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("card-right", Runtime_Css_Example_Styles.Card_Right_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("title", Runtime_Css_Example_Styles.Title_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("subtitle", Runtime_Css_Example_Styles.Subtitle_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("badge", Runtime_Css_Example_Styles.Badge_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("mode-button", Runtime_Css_Example_Styles.Mode_Button_Class_Part_Styles),
        Adi.CSS_Source.Tag_Entry ("button", Runtime_Css_Example_Styles.Button_Tag_Part_Styles),
        Adi.CSS_Source.Id_Entry ("mode-switch", Runtime_Css_Example_Styles.Mode_Switch_Id_Part_Styles),
        Adi.CSS_Source.Class_Entry ("card-title", Runtime_Css_Example_Styles.Card_Title_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("card-body", Runtime_Css_Example_Styles.Card_Body_Class_Part_Styles),
        Adi.CSS_Source.Class_Entry ("status", Runtime_Css_Example_Styles.Status_Class_Part_Styles)];

      procedure Update_Mode_UI is
      begin
         if Adi.CSS_Source.Get_Mode (Source) = Adi.CSS_Source.Dynamic_Mode then
            Adi.Widget.Button.Set_Text (Mode_Button, "Mode: Dynamic CSS");
            Adi.Widget.Label.Set_Text (Status, "Dynamic mode: edit " & CSS_Path & " and save to live reload");
         else
            Adi.Widget.Button.Set_Text (Mode_Button, "Mode: Static CSS");
            Adi.Widget.Label.Set_Text (Status, "Static mode: using compiled Ada styles");
         end if;
      end Update_Mode_UI;

      procedure Toggle_Mode (WH : Adi.Widget.Widget_Handle) is
         pragma Unreferenced (WH);
      begin
         if Adi.CSS_Source.Get_Mode (Source) = Adi.CSS_Source.Dynamic_Mode then
            Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
         else
            Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         end if;

         if Mode_OK then
            Update_Mode_UI;
         else
            Adi.Widget.Label.Set_Text (Status,
              "Cannot switch to dynamic mode: " & Adi.CSS_Source.Get_Last_Error (Source));
         end if;
      end Toggle_Mode;
   begin
      Adi.Widget.Set_Geometry (Root.all, (0.0, 0.0, 980.0, 640.0));
      Adi.Widget.Set_Geometry (Adi.Widget.Borrow (+Header).Ptr.all, (32.0, 24.0, 916.0, 120.0));
      Adi.Widget.Set_Geometry (Adi.Widget.Borrow (+Content).Ptr.all, (32.0, 164.0, 916.0, 404.0));
      Adi.Widget.Set_Geometry (Adi.Widget.Borrow (+Status).Ptr.all, (32.0, 584.0, 916.0, 32.0));

      Root.Status_Label := Status;

      Adi.Widget.Add_Child (Root.all, +Header);
      Adi.Widget.Add_Child (Root.all, +Content);
      Adi.Widget.Add_Child (Root.all, +Status);

      Adi.Widget.Add_Child (+Header, +Title);
      Adi.Widget.Add_Child (+Header, +Subtitle);
      Adi.Widget.Add_Child (+Header, +Badge);
      Adi.Widget.Add_Child (+Header, +Mode_Button);

      Adi.Widget.Add_Child (+Content, +Card_Left);
      Adi.Widget.Add_Child (+Content, +Card_Right);

      Adi.Widget.Add_Child (+Card_Left, +Left_Title);
      Adi.Widget.Add_Child (+Card_Left, +Left_Body);
      Adi.Widget.Add_Child (+Card_Right, +Right_Title);
      Adi.Widget.Add_Child (+Card_Right, +Right_Body);

      Adi.CSS_Source.Set_Static_Entries (Source, Static_Entries);
      Adi.CSS_Source.Add_Dynamic_File (Source, CSS_Path, Loaded);
      if Loaded then
         Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
      else
         Mode_OK := False;
      end if;

      if not Mode_OK then
         Adi.CSS_Source.Set_Mode (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
         Adi.Widget.Label.Set_Text (Status,
           "Dynamic CSS load failed; using static styles. Error: "
           & Adi.CSS_Source.Get_Last_Error (Source));
      end if;

      Adi.Widget.Button.Connect_Clicked (Mode_Button, Toggle_Mode'Unrestricted_Access);

      Adi.CSS_Source.Bind_Class (Source, "root", Root);
      Adi.CSS_Source.Bind_Class (Source, "header", +Header);
      Adi.CSS_Source.Bind_Class (Source, "content", +Content);
      Adi.CSS_Source.Bind_Class (Source, "card-left", +Card_Left);
      Adi.CSS_Source.Bind_Class (Source, "card-right", +Card_Right);

      Adi.CSS_Source.Bind_Class (Source, "title", +Title);
      Adi.CSS_Source.Bind_Class (Source, "subtitle", +Subtitle);
      Adi.CSS_Source.Bind_Class (Source, "badge", +Badge);
      Adi.CSS_Source.Bind_Selector_Set (
        Source     => Source,
        W          => Adi.Widget.Resolve_Handle (+Mode_Button),
        Tag_Name   => "button",
        Class_Name => "mode-button",
        Id_Name    => "mode-switch");
      Adi.CSS_Source.Bind_Class (Source, "card-title", +Left_Title);
      Adi.CSS_Source.Bind_Class (Source, "card-title", +Right_Title);
      Adi.CSS_Source.Bind_Class (Source, "card-body", +Left_Body);
      Adi.CSS_Source.Bind_Class (Source, "card-body", +Right_Body);
      Adi.CSS_Source.Bind_Class (Source, "status", +Status);

      if Mode_OK then
         Update_Mode_UI;
      end if;

      Adi.Window.Set_Root (W, Root);
      A.Add_Window (W);
      A.Run;
   end;
end Runtime_Css_Example;
