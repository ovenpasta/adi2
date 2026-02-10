pragma Ada_2022;

with Ada.Directories;

with Adi.App;
with Adi.CSS_Parser;
with Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Window;

procedure Runtime_Css_Example is

   type Stylesheet_Access is access all Adi.CSS_Parser.Stylesheet;
   use type Adi.Widget.Label.Label_Widget_Access;

   type Live_Root_Widget is new Adi.Widget.Box.Box_Widget with record
      Sheet        : Stylesheet_Access := null;
      Status_Label : Adi.Widget.Label.Label_Widget_Access := null;
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
      if W.Sheet = null then
         return;
      end if;

      Adi.CSS_Parser.Reload_If_Changed (W.Sheet.all, Reloaded, Success);

      if W.Status_Label = null then
         return;
      end if;

      if not Success then
         if W.Last_OK then
            W.Status_Label.Set_Text (
              "CSS reload error: " & Adi.CSS_Parser.Get_Last_Error (W.Sheet.all));
         end if;
         W.Last_OK := False;
         return;
      end if;

      if Reloaded then
         W.Reload_Count := W.Reload_Count + 1;
         W.Status_Label.Set_Text (
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
      W : constant Adi.Window.Window_Access :=
        Adi.Window.Create_Window ("Runtime CSS Example", (980.0, 640.0));

      Sheet : aliased Adi.CSS_Parser.Stylesheet;
      CSS_Path : constant String := Resolve_CSS_Path;
      Loaded : Boolean := False;

      Root : constant Live_Root_Access :=
        new Live_Root_Widget'
          (Adi.Widget.Box.Box_Widget with
             Sheet        => Sheet'Unchecked_Access,
             Status_Label => null,
             Reload_Count => 0,
             Last_OK      => True);

      Header : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Content : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Card_Left : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Card_Right : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Runtime CSS Live Reload");
      Subtitle : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Edit the css file while this app is open.");
      Badge : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("LIVE");

      Left_Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Card One");
      Left_Body : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("This style is loaded from disk at runtime.\n"
           & "Try changing border radius, shadows, colors, and spacing.");

      Right_Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Card Two");
      Right_Body : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Hover styles and typography changes also hot-reload.\n"
           & "No codegen step is needed.");

      Status : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Waiting for CSS load...");
   begin
      Adi.Widget.Set_Geometry (Root.all, (0.0, 0.0, 980.0, 640.0));
      Adi.Widget.Set_Geometry (Header.all, (32.0, 24.0, 916.0, 120.0));
      Adi.Widget.Set_Geometry (Content.all, (32.0, 164.0, 916.0, 404.0));
      Adi.Widget.Set_Geometry (Status.all, (32.0, 584.0, 916.0, 32.0));

      Root.Status_Label := Status;

      Root.Add_Child (Header);
      Root.Add_Child (Content);
      Root.Add_Child (Status);

      Header.Add_Child (Title);
      Header.Add_Child (Subtitle);
      Header.Add_Child (Badge);

      Content.Add_Child (Card_Left);
      Content.Add_Child (Card_Right);

      Card_Left.Add_Child (Left_Title);
      Card_Left.Add_Child (Left_Body);
      Card_Right.Add_Child (Right_Title);
      Card_Right.Add_Child (Right_Body);

      Adi.CSS_Parser.Load_File (Sheet, CSS_Path, Loaded);
      if Loaded then
         Status.Set_Text ("Loaded: " & CSS_Path & " - edit and save to see live updates");
      else
         Status.Set_Text ("Initial CSS load failed: " & Adi.CSS_Parser.Get_Last_Error (Sheet));
      end if;

      Adi.CSS_Parser.Bind_Class (Sheet, "root", Root);
      Adi.CSS_Parser.Bind_Class (Sheet, "header", Header);
      Adi.CSS_Parser.Bind_Class (Sheet, "content", Content);
      Adi.CSS_Parser.Bind_Class (Sheet, "card-left", Card_Left);
      Adi.CSS_Parser.Bind_Class (Sheet, "card-right", Card_Right);

      Adi.CSS_Parser.Bind_Class (Sheet, "title", Title);
      Adi.CSS_Parser.Bind_Class (Sheet, "subtitle", Subtitle);
      Adi.CSS_Parser.Bind_Class (Sheet, "badge", Badge);
      Adi.CSS_Parser.Bind_Class (Sheet, "card-title", Left_Title);
      Adi.CSS_Parser.Bind_Class (Sheet, "card-title", Right_Title);
      Adi.CSS_Parser.Bind_Class (Sheet, "card-body", Left_Body);
      Adi.CSS_Parser.Bind_Class (Sheet, "card-body", Right_Body);
      Adi.CSS_Parser.Bind_Class (Sheet, "status", Status);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Runtime_Css_Example;
