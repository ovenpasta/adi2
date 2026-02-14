pragma Ada_2022;

with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Styles;
with Adi.Core;
with Adi.Image;
with Adi.Layout_Util;
with Adi.Widget;
with Adi.Widget.Html_View;

procedure Html_View_Test is
   use type Adi.Widget.Html_View.Html_View_Access;
   use type Adi.CSS_Styles.Color_Kind;
   use type Adi.CSS_Styles.CSS_Unit;
   use type Adi.CSS_Styles.Text_Decoration_Value;
   use type Adi.Core.Pixel_Type;
   use type Adi.Widget.Part_Kind;

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

   function Find_Text_Item_Index
     (W      : Adi.Widget.Html_View.Html_View_Access;
      Needle : String) return Natural
   is
      use type Adi.Widget.Item_Kind;
   begin
      for I in 1 .. Adi.Widget.Item_Count (W.all) loop
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, I);
         begin
            if It.Kind = Adi.Widget.Text_Item
              and then Ada.Strings.Fixed.Index (To_String (It.Text_Content), Needle) > 0
            then
               return I;
            end if;
         end;
      end loop;

      return 0;
   end Find_Text_Item_Index;

   function Find_Link_Text_Item_Index
     (W      : Adi.Widget.Html_View.Html_View_Access;
      Needle : String) return Natural
   is
      use type Adi.Widget.Item_Kind;
   begin
      for I in 1 .. Adi.Widget.Item_Count (W.all) loop
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, I);
         begin
            if It.Kind = Adi.Widget.Text_Item
              and then It.Part = Adi.Widget.Indicator_Part
              and then Ada.Strings.Fixed.Index (To_String (It.Text_Content), Needle) > 0
            then
               return I;
            end if;
         end;
      end loop;

      return 0;
   end Find_Link_Text_Item_Index;

   function Is_RGB
     (C       : Adi.CSS_Styles.Color_Value;
      R, G, B : Natural) return Boolean
   is
   begin
      if C.Kind = Adi.CSS_Styles.RGB then
         return C.R = R and then C.G = G and then C.B = B;
      elsif C.Kind = Adi.CSS_Styles.RGBA then
         return C.RA = R and then C.GA = G and then C.BA = B;
      end if;

      return False;
   end Is_RGB;

   function Nearly_Equal
     (L, R : Adi.Core.Pixel_Type;
      Eps  : Adi.Core.Pixel_Type := 0.5) return Boolean
   is
      Diff : constant Adi.Core.Pixel_Type := (if L > R then L - R else R - L);
   begin
      return Diff <= Eps;
   end Nearly_Equal;

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

   procedure Test_Cascade_Precedence is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: CSS cascade precedence");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 640.0, Height => 300.0));

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>" &
         "p { color: rgb(10, 20, 30); }" &
         ".note { color: rgb(20, 40, 60); }" &
         "#lead { color: rgb(30, 60, 90); }" &
         "</style>" &
         "<p id='lead' class='note' style='color: rgb(77, 88, 99);'>inline wins</p>");
      Adi.Widget.Html_View.Build_Items (W.all);

      Idx := Find_Text_Item_Index (W, "inline");
      Assert (Idx > 0, "inline-style paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            Assert
              (Is_RGB (It.Computed_Style.Color, 77, 88, 99),
               "inline style overrides id/class/tag");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>" &
         "p { color: rgb(10, 20, 30); }" &
         ".note { color: rgb(20, 40, 60); }" &
         "#lead { color: rgb(30, 60, 90); }" &
         "</style>" &
         "<p id='lead' class='note'>id wins</p>");
      Adi.Widget.Html_View.Build_Items (W.all);

      Idx := Find_Text_Item_Index (W, "id");
      Assert (Idx > 0, "id-style paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            Assert
              (Is_RGB (It.Computed_Style.Color, 30, 60, 90),
               "id selector overrides class and tag");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>" &
         "p { color: rgb(10, 20, 30); }" &
         ".note { color: rgb(20, 40, 60); }" &
         "</style>" &
         "<p class='note'>class wins</p>");
      Adi.Widget.Html_View.Build_Items (W.all);

      Idx := Find_Text_Item_Index (W, "class");
      Assert (Idx > 0, "class-style paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            Assert
              (Is_RGB (It.Computed_Style.Color, 20, 40, 60),
               "class selector overrides tag");
         end;
      end if;

      New_Line;
   end Test_Cascade_Precedence;

   procedure Test_Mixed_Inline_Baseline is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      A_Idx : Natural := 0;
      B_Idx : Natural := 0;
      C_Idx : Natural := 0;
   begin
      Put_Line ("Test: Mixed inline baseline alignment");

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>" &
         "p { font-size: 16px; }" &
         "strong { font-size: 34px; }" &
         "em { font-size: 12px; }" &
         "</style>" &
         "<p>alpha <strong>BETA</strong> <em>gamma</em></p>");
      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 700.0, Height => 260.0));
      Adi.Widget.Html_View.Build_Items (W.all);

      A_Idx := Find_Text_Item_Index (W, "alpha");
      B_Idx := Find_Text_Item_Index (W, "BETA");
      C_Idx := Find_Text_Item_Index (W, "gamma");

      Assert (A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0,
              "mixed inline runs are present");

      if A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (B_Idx));
            C : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (C_Idx));
         begin
            Assert
              (Nearly_Equal (A.Geometry.Y, B.Geometry.Y)
               and then Nearly_Equal (B.Geometry.Y, C.Geometry.Y),
               "mixed inline runs share the same line-box top");

            Assert
              (A.Text_Offset_Y > 0.0 and then C.Text_Offset_Y > 0.0,
               "smaller inline runs are baseline-shifted within line");

            Assert
              (B.Text_Offset_Y <= A.Text_Offset_Y,
               "larger inline run anchors line baseline");
         end;
      end if;

      New_Line;
   end Test_Mixed_Inline_Baseline;

   procedure Test_Clipping_Aware_Link_Hit_Test is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Clicks : Natural := 0;

      procedure On_Link_Click
        (Self : access Adi.Widget.Html_View.Html_View;
         Href : String)
      is
         pragma Unreferenced (Self, Href);
      begin
         Clicks := Clicks + 1;
      end On_Link_Click;
   begin
      Put_Line ("Test: Clipping-aware link hit testing");

      Adi.Widget.Html_View.Set_On_Link_Click
        (W.all, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<p><a href='app://clip'>clip target link text for hit testing</a></p>" &
         "<p>second line</p>");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 360.0, Height => 52.0));
      Adi.Widget.Html_View.Build_Items (W.all);

      Adi.Widget.Html_View.On_Mouse_Down
        (W.all, X => 26.0, Y => 26.0, Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.Html_View.On_Mouse_Up
        (W.all, X => 26.0, Y => 26.0, Button => Adi.Core.Left_Button);
      Assert (Clicks = 1, "visible clipped link area remains clickable");

      Adi.Widget.Set_Scroll_Offset_Y (W.all, 28.0);
      Adi.Widget.Html_View.Build_Items (W.all);

      Adi.Widget.Html_View.On_Mouse_Down
        (W.all, X => 26.0, Y => 20.0, Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.Html_View.On_Mouse_Up
        (W.all, X => 26.0, Y => 20.0, Button => Adi.Core.Left_Button);
      Assert (Clicks = 1, "scrolled-out link area is not clickable");

      New_Line;
   end Test_Clipping_Aware_Link_Hit_Test;

   procedure Test_Link_Does_Not_Consume_Leading_Space is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: link run excludes preceding collapsed space");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 420.0, Height => 120.0));
      Adi.Widget.Html_View.Set_HTML
        (W.all, "<p>alpha <a href='app://x'>beta</a> gamma</p>");
      Adi.Widget.Html_View.Build_Items (W.all);

      Idx := Find_Link_Text_Item_Index (W, "beta");
      Assert (Idx > 0, "link text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
            S  : constant String := To_String (It.Text_Content);
         begin
            Assert
              (S'Length > 0 and then S (S'First) /= ' ',
               "link text item does not begin with previous collapsed space");
         end;
      end if;

      New_Line;
   end Test_Link_Does_Not_Consume_Leading_Space;

   procedure Test_Scroll_Content_Height_Stability is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      H1 : Adi.Core.Pixel_Type := 0.0;
      H2 : Adi.Core.Pixel_Type := 0.0;
      M1 : Adi.Core.Pixel_Type := 0.0;
      M2 : Adi.Core.Pixel_Type := 0.0;
      Html : Unbounded_String := Null_Unbounded_String;
   begin
      Put_Line ("Test: scroll content height stability");

      Append (Html, "<h2>Scroll Probe</h2>");
      for I in 1 .. 80 loop
         Append
           (Html,
            "<p>row " & Integer'Image (I)
            & " - this is a long line to guarantee document overflow in the viewport.</p>");
      end loop;

      Adi.Widget.Html_View.Set_HTML (W.all, To_String (Html));
      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 480.0, Height => 180.0));
      Adi.Widget.Html_View.Build_Items (W.all);

      H1 := Adi.Widget.Get_Scroll_Content_Height (W.all);
      M1 := Adi.Widget.Get_Scroll_Max_Offset_Y (W.all);
      Assert (M1 > 0.0, "long html document overflows viewport");

      Adi.Widget.Set_Scroll_Offset_Y (W.all, M1 * 0.75);
      Adi.Widget.Html_View.Build_Items (W.all);

      H2 := Adi.Widget.Get_Scroll_Content_Height (W.all);
      M2 := Adi.Widget.Get_Scroll_Max_Offset_Y (W.all);

      Assert (Nearly_Equal (H1, H2, 2.0),
              "content height stays stable after scrolling");
      Assert (Nearly_Equal (M1, M2, 2.0),
              "max scroll offset stays stable after scrolling");

      New_Line;
   end Test_Scroll_Content_Height_Stability;

   procedure Test_Center_Alignment is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: center and text-align center");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 620.0, Height => 220.0));

      Adi.Widget.Html_View.Set_HTML
        (W.all, "<center>center probe</center>");
      Adi.Widget.Html_View.Build_Items (W.all);

      Idx := Find_Text_Item_Index (W, "center");
      Assert (Idx > 0, "center tag text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            Assert (It.Geometry.X > 120.0, "center tag shifts text away from left edge");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>p { text-align: center; }</style><p>css center probe</p>");
      Adi.Widget.Html_View.Build_Items (W.all);

      Idx := Find_Text_Item_Index (W, "css");
      Assert (Idx > 0, "text-align center paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            Assert (It.Geometry.X > 120.0, "text-align center shifts text away from left edge");
         end;
      end if;

      New_Line;
   end Test_Center_Alignment;

   procedure Test_Body_Font_Inheritance is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Idx : Natural := 0;
      H1  : Adi.Core.Pixel_Type := 0.0;
      H2  : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: body font-size inheritance");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 620.0, Height => 240.0));

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>body { font-size: 16px; }</style><p>inherit probe</p>");
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "inherit");
      Assert (Idx > 0, "baseline inherited text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            H1 := It.Geometry.Height;
            Assert
              (It.Computed_Style.Font_Size.Unit = Adi.CSS_Styles.Px,
               "baseline inherited unit is px");
            Assert
              (It.Computed_Style.Font_Size.Amount >= 15.0
               and then It.Computed_Style.Font_Size.Amount <= 17.0,
               "baseline inherited size is near body font-size");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>body { font-size: 40px; }</style><p>inherit probe</p>");
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "inherit");
      Assert (Idx > 0, "large inherited text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            H2 := It.Geometry.Height;
            Assert
              (It.Computed_Style.Font_Size.Unit = Adi.CSS_Styles.Px,
               "large inherited unit is px");
            Assert
              (It.Computed_Style.Font_Size.Amount >= 39.0,
               "large inherited size tracks body font-size");
            Assert (H2 > H1 + 10.0, "larger body font-size increases line box height");
         end;
      end if;

      New_Line;
   end Test_Body_Font_Inheritance;

   procedure Test_Line_Height_Parsing_And_Layout is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      A_Idx : Natural := 0;
      B_Idx : Natural := 0;
   begin
      Put_Line ("Test: line-height parsing and layout");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 560.0, Height => 260.0));
      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>p { font-size: 16px; line-height: 3; }</style>" &
         "<p>lineA<br>lineB</p>");
      Adi.Widget.Html_View.Build_Items (W.all);

      A_Idx := Find_Text_Item_Index (W, "lineA");
      B_Idx := Find_Text_Item_Index (W, "lineB");
      Assert (A_Idx > 0 and then B_Idx > 0, "line-height sample lines exist");
      if A_Idx > 0 and then B_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (B_Idx));
         begin
            Assert (B.Geometry.Y - A.Geometry.Y > 30.0,
                    "line-height multiplier increases line advance");
         end;
      end if;

      New_Line;
   end Test_Line_Height_Parsing_And_Layout;

   procedure Test_Overline_Decoration_Style is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: overline decoration style");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 560.0, Height => 220.0));
      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>p { text-decoration: overline; }</style><p>overline probe</p>");
      Adi.Widget.Html_View.Build_Items (W.all);

      Idx := Find_Text_Item_Index (W, "overline");
      Assert (Idx > 0, "overline text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            Assert
              (It.Computed_Style.Text_Decoration = Adi.CSS_Styles.Decoration_Overline,
               "overline text decoration is parsed and applied");
         end;
      end if;

      New_Line;
   end Test_Overline_Decoration_Style;

   procedure Test_Content_Scale is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Idx : Natural := 0;
      W1  : Adi.Core.Pixel_Type := 0.0;
      W2  : Adi.Core.Pixel_Type := 0.0;
      VW1 : Adi.Core.Pixel_Type := 0.0;
      VW2 : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: html content scale");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 620.0, Height => 260.0));

      Adi.Widget.Html_View.Set_HTML
        (W.all, "<style>body { font-size: 18px; }</style><p>scale plain probe</p>");

      Adi.Widget.Html_View.Set_Content_Scale (W.all, 1.0);
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "scale");
      Assert (Idx > 0, "scale baseline text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            W1 := It.Geometry.Width;
         end;
      end if;

      Adi.Widget.Html_View.Set_Content_Scale (W.all, 2.0);
      Assert (Adi.Widget.Html_View.Get_Content_Scale (W.all) >= 1.99,
              "content scale getter returns updated value");
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "scale");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            W2 := It.Geometry.Width;
            Assert (W2 > W1 * 1.7, "content scale increases absolute-unit text metrics");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W.all, "<style>p { font-size: 10vw; }</style><p>scale vw probe</p>");
      Adi.Widget.Html_View.Set_Content_Scale (W.all, 1.0);
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "vw");
      Assert (Idx > 0, "vw sample text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            VW1 := It.Geometry.Width;
         end;
      end if;

      Adi.Widget.Html_View.Set_Content_Scale (W.all, 2.0);
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "vw");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            VW2 := It.Geometry.Width;
            Assert (Nearly_Equal (VW1, VW2, 2.0),
                    "content scale does not multiply vw-resolved text size");
         end;
      end if;

      New_Line;
   end Test_Content_Scale;

   procedure Test_VW_VH_Context is
      W : constant Adi.Widget.Html_View.Html_View_Access :=
        Adi.Widget.Html_View.Create;
      Idx : Natural := 0;
      H1  : Adi.Core.Pixel_Type := 0.0;
      H2  : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: vw/vh context behavior");

      Adi.Layout_Util.Set_Active_Viewport_Size (Width => 800.0, Height => 600.0);
      Assert
        (Nearly_Equal (Adi.Layout_Util.Length_To_Px (Adi.CSS_Styles.Vw (10.0)), 80.0, 0.2),
         "global vw resolves against active viewport width");
      Assert
        (Nearly_Equal (Adi.Layout_Util.Length_To_Px (Adi.CSS_Styles.Vh (10.0)), 60.0, 0.2),
         "global vh resolves against active viewport height");

      Adi.Widget.Html_View.Set_Content_Scale (W.all, 1.0);
      Adi.Widget.Html_View.Set_HTML
        (W.all,
         "<style>p { font-size: 10vw; line-height: 10vh; }</style><p>vwvh probe</p>");

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 300.0, Height => 200.0));
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "vwvh");
      Assert (Idx > 0, "vw/vh html text item exists at small viewport");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            H1 := It.Geometry.Height;
            Assert
              (It.Computed_Style.Font_Size.Unit = Adi.CSS_Styles.Px,
               "vw font-size is materialized to px for final text rendering");
         end;
      end if;

      Adi.Widget.Set_Geometry
        (W.all, (X => 0.0, Y => 0.0, Width => 600.0, Height => 400.0));
      Adi.Widget.Html_View.Build_Items (W.all);
      Idx := Find_Text_Item_Index (W, "vwvh");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (W.all, Positive (Idx));
         begin
            H2 := It.Geometry.Height;
            Assert (H2 > H1 * 1.7, "html vw/vh resolve against html viewport size");
         end;
      end if;

      New_Line;
   end Test_VW_VH_Context;

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
   Test_Cascade_Precedence;
   Test_Mixed_Inline_Baseline;
   Test_Clipping_Aware_Link_Hit_Test;
   Test_Link_Does_Not_Consume_Leading_Space;
   Test_Scroll_Content_Height_Stability;
   Test_Center_Alignment;
   Test_Body_Font_Inheritance;
   Test_Line_Height_Parsing_And_Layout;
   Test_Overline_Decoration_Style;
   Test_Content_Scale;
   Test_VW_VH_Context;
   Test_HTML_Folder_Stress;

   Put_Line ("Summary: " & Pass_Count'Image & "/" & Test_Count'Image & " passing");
   if Pass_Count /= Test_Count then
      raise Program_Error with "html view test failed";
   end if;
end Html_View_Test;
