pragma Ada_2022;

with Ada.Directories;

with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.App;
with Adi.Layout_Util;
with Adi.CSS_Source;
with Adi.MCP;
with Adi.Widget;
with Adi.Widget.Button;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Window;
with Runtime_Css_Example_Styles;
with Runtime_Css_Live_Root;
with Runtime_Css_Properties;

procedure Runtime_Css_Example is

   use type Adi.CSS_Source.Source_Mode;
   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Runtime_Css_Live_Root.Handle;

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
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);

   declare
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Runtime CSS Example", Adi.Window.Extent (Px (672.0), Px (439.0)));

      Source : Adi.CSS_Source.Style_Source
        renames Runtime_Css_Live_Root.Source;
      CSS_Path : constant String := Resolve_CSS_Path;
      Loaded : Boolean := False;
      Mode_OK : Boolean := False;

      Root : constant Runtime_Css_Live_Root.Handle :=
        Runtime_Css_Live_Root.Create_Handle;
      Root_H : Adi.Widget.Widget_Handle;

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
      Severity_Button : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Severity: none");

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

      procedure Register_Static_Styles is
      begin
         Adi.CSS_Source.Clear_Static_Entries (Source);
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("root", Runtime_Css_Example_Styles.Root_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("header", Runtime_Css_Example_Styles.Header_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("content", Runtime_Css_Example_Styles.Content_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("card-left", Runtime_Css_Example_Styles.Card_Left_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("card-right", Runtime_Css_Example_Styles.Card_Right_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("title", Runtime_Css_Example_Styles.Title_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("subtitle", Runtime_Css_Example_Styles.Subtitle_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("badge", Runtime_Css_Example_Styles.Badge_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("mode-button", Runtime_Css_Example_Styles.Mode_Button_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Tag_Entry
              ("button", Runtime_Css_Example_Styles.Button_Tag_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Id_Entry
              ("mode-switch", Runtime_Css_Example_Styles.Mode_Switch_Id_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("card-title", Runtime_Css_Example_Styles.Card_Title_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("card-body", Runtime_Css_Example_Styles.Card_Body_Class_Part_Styles));
         Adi.CSS_Source.Add_Static_Entry
           (Source,
            Adi.CSS_Source.Class_Entry
              ("status", Runtime_Css_Example_Styles.Status_Class_Part_Styles));
      end Register_Static_Styles;

      --  Domain state, cycled while the application runs. The cards
      --  carry no style of their own for it: the stylesheet names the
      --  value and the cascade does the rest.
      Severity_On  : Boolean := False;
      Severity_Now : Runtime_Css_Properties.Severity_Level :=
        Runtime_Css_Properties.Ok;

      procedure Show_Severity (WH : Adi.Widget.Widget_Handle) is
      begin
         if Severity_On then
            Runtime_Css_Properties.Severity.Set (WH, Severity_Now);
         else
            Runtime_Css_Properties.Severity.Clear (WH);
         end if;
      end Show_Severity;

      procedure Cycle_Severity (WH : Adi.Widget.Widget_Handle) is
         pragma Unreferenced (WH);
         use type Runtime_Css_Properties.Severity_Level;
      begin
         if not Severity_On then
            Severity_On := True;
            Severity_Now := Runtime_Css_Properties.Severity_Level'First;
         elsif Severity_Now = Runtime_Css_Properties.Severity_Level'Last then
            Severity_On := False;
         else
            Severity_Now :=
              Runtime_Css_Properties.Severity_Level'Succ (Severity_Now);
         end if;

         Show_Severity (+Card_Left);
         Show_Severity (+Card_Right);
         Show_Severity (+Left_Title);
         Show_Severity (+Right_Title);

         Adi.Widget.Button.Set_Text
           (Severity_Button,
            "Severity: "
            & (if Severity_On
               then Runtime_Css_Properties.Severity.CSS_Name (Severity_Now)
               else "none"));
      end Cycle_Severity;

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
      Root_H := +Root;

      Adi.Widget.Set_Geometry (Root_H, (0.0, 0.0, 980.0, 640.0));
      Adi.Widget.Set_Geometry (+Header, (32.0, 24.0, 916.0, 120.0));
      Adi.Widget.Set_Geometry (+Content, (32.0, 164.0, 916.0, 404.0));
      Adi.Widget.Set_Geometry (+Status, (32.0, 584.0, 916.0, 32.0));

      Runtime_Css_Live_Root.Set_Status_Label (Root, Status);

      Adi.Widget.Add_Child (Root_H, +Header);
      Adi.Widget.Add_Child (Root_H, +Content);
      Adi.Widget.Add_Child (Root_H, +Status);

      Adi.Widget.Add_Child (+Header, +Title);
      Adi.Widget.Add_Child (+Header, +Subtitle);
      Adi.Widget.Add_Child (+Header, +Badge);
      Adi.Widget.Add_Child (+Header, +Mode_Button);
      Adi.Widget.Add_Child (+Header, +Severity_Button);

      Adi.Widget.Add_Child (+Content, +Card_Left);
      Adi.Widget.Add_Child (+Content, +Card_Right);

      Adi.Widget.Add_Child (+Card_Left, +Left_Title);
      Adi.Widget.Add_Child (+Card_Left, +Left_Body);
      Adi.Widget.Add_Child (+Card_Right, +Right_Title);
      Adi.Widget.Add_Child (+Card_Right, +Right_Body);

      Register_Static_Styles;
      if Runtime_Css_Example_Styles.Has_Root_Styles
        or else Runtime_Css_Example_Styles.Has_Root_Font_Size
      then
         Adi.CSS_Source.Set_Static_Metadata
           (Source, Runtime_Css_Example_Styles.Root_Metadata);
      end if;
      Adi.CSS_Source.Set_Dynamic_Sources
        (Source, [Adi.CSS_Source.CSS_File (CSS_Path)], Loaded);
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
      Adi.Widget.Button.Connect_Clicked
        (Severity_Button, Cycle_Severity'Unrestricted_Access);

      Adi.CSS_Source.Bind_Root_Metadata (Source, Root_H);
      Adi.CSS_Source.Bind_Class (Source, "root", Root_H);
      Adi.CSS_Source.Bind_Class (Source, "header", +Header);
      Adi.CSS_Source.Bind_Class (Source, "content", +Content);
      Adi.CSS_Source.Bind_Class (Source, "card-left", +Card_Left);
      Adi.CSS_Source.Bind_Class (Source, "card-right", +Card_Right);

      Adi.CSS_Source.Bind_Class (Source, "title", +Title);
      Adi.CSS_Source.Bind_Class (Source, "subtitle", +Subtitle);
      Adi.CSS_Source.Bind_Class (Source, "badge", +Badge);
      Adi.CSS_Source.Bind_Selector_Set (
        Source     => Source,
        W          => +Mode_Button,
        Tag_Name   => "button",
        Class_Name => "mode-button",
        Id_Name    => "mode-switch");
      Adi.CSS_Source.Bind_Selector_Set (
        Source     => Source,
        W          => +Severity_Button,
        Tag_Name   => "button",
        Class_Name => "mode-button");
      Adi.CSS_Source.Bind_Class (Source, "card-title", +Left_Title);
      Adi.CSS_Source.Bind_Class (Source, "card-title", +Right_Title);
      Adi.CSS_Source.Bind_Class (Source, "card-body", +Left_Body);
      Adi.CSS_Source.Bind_Class (Source, "card-body", +Right_Body);
      Adi.CSS_Source.Bind_Class (Source, "status", +Status);

      if Mode_OK then
         Update_Mode_UI;
      end if;

      Adi.Window.Set_Root (W, Root_H);
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Runtime_Css_Example;
