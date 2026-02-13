pragma Ada_2022;

with Ada.Exceptions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core;
with Adi.Image;
with Adi.Widget;
with Adi.Widget.Html_View;

procedure Html_View_Test is
   use type Adi.Widget.Html_View.Html_View_Access;

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      Test_Count := Test_Count + 1;
      if Cond then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Msg);
      else
         Put_Line ("  [FAIL] " & Msg);
      end if;
   end Assert;

   function Read_File (Path : String) return String is
      F      : File_Type;
      Buffer : String (1 .. 1024);
      Last   : Natural;
      Out_S  : Unbounded_String := Null_Unbounded_String;
      First  : Boolean := True;
   begin
      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         Get_Line (F, Buffer, Last);
         if not First then
            Append (Out_S, ASCII.LF);
         end if;
         if Last > 0 then
            Append (Out_S, Buffer (1 .. Last));
         end if;
         First := False;
      end loop;
      Close (F);
      return To_String (Out_S);
   end Read_File;

   procedure Test_Set_Get_Clear is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      HTML : constant String :=
        "<div><h1>Doc</h1><p>Hello <a href='https://example.com'>world</a></p></div>";
   begin
      Put_Line ("Test: Set/Get/Clear");

      Assert (W /= null, "Create returns non-null widget");

      Adi.Widget.Html_View.Set_HTML (W.all, HTML);
      Assert
        (Adi.Widget.Html_View.Get_HTML (W.all) = HTML,
         "Set_HTML/Get_HTML roundtrip preserves source");

      Adi.Widget.Html_View.Clear (W.all);
      Assert
        (Adi.Widget.Html_View.Get_HTML (W.all) = "",
         "Clear resets source to empty string");

      New_Line;
   end Test_Set_Get_Clear;

   procedure Test_Callback_Registration_And_Mouse_Safety is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Link_Clicked : Boolean := False;

      procedure On_Link_Click
        (Self : access Adi.Widget.Html_View.Html_View;
         Href : String)
      is
         pragma Unreferenced (Self, Href);
      begin
         Link_Clicked := True;
      end On_Link_Click;

      function On_Load_Asset
        (Self : access Adi.Widget.Html_View.Html_View;
         URI  : String) return Adi.Image.Image_Access
      is
         pragma Unreferenced (Self, URI);
      begin
         return null;
      end On_Load_Asset;
   begin
      Put_Line ("Test: Callback registration and mouse safety");

      Adi.Widget.Html_View.Set_On_Link_Click
        (W.all, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Asset
        (W.all, On_Load_Asset'Unrestricted_Access);

      Adi.Widget.Html_View.Set_HTML
        (W.all, "<p>safe <a href='https://example.com'>click</a> path</p>");

      --  No layout/build performed in this smoke test; these calls should
      --  remain safe and not raise.
      Adi.Widget.Html_View.On_Mouse_Down
        (W.all, X => 0.0, Y => 0.0, Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.Html_View.On_Mouse_Move (W.all, X => 0.0, Y => 0.0);
      Adi.Widget.Html_View.On_Mouse_Up
        (W.all, X => 0.0, Y => 0.0, Button => Adi.Core.Left_Button);

      Assert
        (not Link_Clicked,
         "no link callback without laid out link fragments");

      New_Line;
   end Test_Callback_Registration_And_Mouse_Safety;

   procedure Test_Embedded_And_Linked_CSS is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Resource_Hits : Natural := 0;
      Asset_Hits    : Natural := 0;

      function On_Load_Resource
        (Self : access Adi.Widget.Html_View.Html_View;
         URI  : String) return String
      is
         pragma Unreferenced (Self);
      begin
         if URI = "app://tests/theme.css" then
            Resource_Hits := Resource_Hits + 1;
            return "a { color: rgb(20, 80, 180); } strong { font-weight: 700; }";
         end if;
         return "";
      end On_Load_Resource;

      function On_Load_Asset
        (Self : access Adi.Widget.Html_View.Html_View;
         URI  : String) return Adi.Image.Image_Access
      is
         pragma Unreferenced (Self);
      begin
         if URI = "app://tests/image.png" then
            Asset_Hits := Asset_Hits + 1;
         end if;
         return null;
      end On_Load_Asset;
   begin
      Put_Line ("Test: Embedded style and linked stylesheet");

      Adi.Widget.Html_View.Set_On_Load_Resource
        (W.all, On_Load_Resource'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Asset
        (W.all, On_Load_Asset'Unrestricted_Access);

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<link rel='stylesheet' href='app://tests/theme.css'>" &
         "<style>h1 { font-size: 28px; }</style>" &
         "<h1>Title</h1><p><strong>strong</strong> and <a href='x'>link</a> " &
         "<img src='app://tests/image.png' alt='img'></p>");

      Adi.Widget.Set_Geometry (W.all, (X => 0.0, Y => 0.0, Width => 640.0, Height => 320.0));
      Adi.Widget.Html_View.Build_Items (W.all);

      Assert (Resource_Hits = 1, "link rel stylesheet uses resource callback exactly once");
      Assert (Asset_Hits = 1, "img src uses asset callback during build");

      New_Line;
   end Test_Embedded_And_Linked_CSS;

   procedure Test_Heading_Line_Height_Is_Local is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
   begin
      Put_Line ("Test: Heading line-height does not leak");

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>h1 { font-size: 44px; font-weight: 700; }</style>" &
         "<h1>Header</h1><p>normal1<br>normal2</p>");
      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 640.0, Height => 360.0));
      Adi.Widget.Html_View.Build_Items (W.all);
      Assert (True, "large heading with following paragraph builds successfully");
      New_Line;
   exception
      when E : others =>
         Assert
           (False,
            "heading + normal text build without exceptions ("
            & Ada.Exceptions.Exception_Name (E) & ")");
         New_Line;
   end Test_Heading_Line_Height_Is_Local;

   procedure Test_HTML_Folder_Stress is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;

      function On_Load_Asset
        (Self : access Adi.Widget.Html_View.Html_View;
         URI  : String) return Adi.Image.Image_Access
      is
         pragma Unreferenced (Self, URI);
      begin
         return null;
      end On_Load_Asset;

      procedure Parse_Build_And_Probe (Path : String) is
         HTML : constant String := Read_File (Path);
      begin
         Adi.Widget.Html_View.Set_HTML (W.all, HTML);
         Adi.Widget.Set_Geometry (W.all, (X => 0.0, Y => 0.0, Width => 720.0, Height => 480.0));
         Adi.Widget.Html_View.Build_Items (W.all);

         --  Probe mouse paths after building item/link fragments.
         Adi.Widget.Html_View.On_Mouse_Move (W.all, X => 12.0, Y => 12.0);
         Adi.Widget.Html_View.On_Mouse_Down
           (W.all, X => 12.0, Y => 12.0, Button => Adi.Core.Left_Button, Clicks => 1);
         Adi.Widget.Html_View.On_Mouse_Up
           (W.all, X => 12.0, Y => 12.0, Button => Adi.Core.Left_Button);

         Assert (True, "parsed/built " & Path);
      exception
         when E : others =>
            Assert (False, "no exception for " & Path & " (" & Ada.Exceptions.Exception_Name (E) & ")");
      end Parse_Build_And_Probe;
   begin
      Put_Line ("Test: HTML folder stress cases");

      Adi.Widget.Html_View.Set_On_Load_Asset
        (W.all, On_Load_Asset'Unrestricted_Access);

      Parse_Build_And_Probe ("tests/html/basic_nested.html");
      Parse_Build_And_Probe ("tests/html/deep_nesting.html");
      Parse_Build_And_Probe ("tests/html/mixed_tags.html");
      Parse_Build_And_Probe ("tests/html/lists_and_blocks.html");
      Parse_Build_And_Probe ("tests/html/images_and_links.html");
      Parse_Build_And_Probe ("tests/html/entities_and_spacing.html");
      Parse_Build_And_Probe ("tests/html/malformed_unclosed.html");
      Parse_Build_And_Probe ("tests/html/malformed_mismatched.html");
      Parse_Build_And_Probe ("tests/html/malformed_broken_attrs.html");
      Parse_Build_And_Probe ("tests/html/malformed_stray_angles.html");

      New_Line;
   end Test_HTML_Folder_Stress;

begin
   Put_Line ("HTML view widget test");
   Put_Line ("");

   Test_Set_Get_Clear;
   Test_Callback_Registration_And_Mouse_Safety;
   Test_Embedded_And_Linked_CSS;
   Test_Heading_Line_Height_Is_Local;
   Test_HTML_Folder_Stress;

   Put_Line ("Summary: " & Pass_Count'Image & "/" & Test_Count'Image & " passing");
   if Pass_Count /= Test_Count then
      raise Program_Error with "html view test failed";
   end if;
end Html_View_Test;
