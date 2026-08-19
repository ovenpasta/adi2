pragma Ada_2022;

with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Styles;
with Adi.Core;
with Adi.Image;
with Adi.Layout_Util;
with Adi.Widget_Styles;
with Adi.Widget;
with Adi.Widget.Html_View;
with Test_Support; use Test_Support;

procedure Html_View_Test is
   package WW_Encode renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings;

   use type Adi.CSS_Styles.Color_Kind;
   use type Adi.CSS_Styles.Named_Color;
   use type Adi.CSS_Styles.CSS_Unit;
   use type Adi.CSS_Styles.Text_Decoration_Value;
   use type Adi.Core.Pixel_Type;
   use type Adi.Widget.Part_Kind;
   use type Adi.Image.Image_Handle;
   use type Adi.Widget.Html_View.Html_View_Handle;

   UTF8_Disc : constant String :=
     WW_Encode.Encode
       (Item => Wide_Wide_String'("•"),
        Output_BOM => False);
   UTF8_Square : constant String :=
     WW_Encode.Encode
       (Item => Wide_Wide_String'("■"),
        Output_BOM => False);

   function Find_Text_Item_Index
     (W      : Adi.Widget.Html_View.Html_View_Handle;
      Needle : String) return Natural
   is
      use type Adi.Widget.Item_Kind;
   begin
      for I in 1 .. Adi.Widget.Item_Count (+W) loop
         declare
            It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, I);
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
     (W      : Adi.Widget.Html_View.Html_View_Handle;
      Needle : String) return Natural
   is
      use type Adi.Widget.Item_Kind;
   begin
      for I in 1 .. Adi.Widget.Item_Count (+W) loop
         declare
            It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, I);
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

   function Find_Exact_Text_Item_Index
     (W      : Adi.Widget.Html_View.Html_View_Handle;
      Needle : String) return Natural
   is
      use type Adi.Widget.Item_Kind;
   begin
      for I in 1 .. Adi.Widget.Item_Count (+W) loop
         declare
            It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, I);
         begin
            if It.Kind = Adi.Widget.Text_Item
              and then To_String (It.Text_Content) = Needle
            then
               return I;
            end if;
         end;
      end loop;

      return 0;
   end Find_Exact_Text_Item_Index;

   function Find_First_Image_Item_Index
     (W : Adi.Widget.Html_View.Html_View_Handle) return Natural
   is
      use type Adi.Widget.Item_Kind;
   begin
      for I in 1 .. Adi.Widget.Item_Count (+W) loop
         declare
            It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, I);
         begin
            if It.Kind = Adi.Widget.Image_Item then
               return I;
            end if;
         end;
      end loop;

      return 0;
   end Find_First_Image_Item_Index;

   function Has_Image_Item_Before
     (W    : Adi.Widget.Html_View.Html_View_Handle;
      Text : String) return Boolean
   is
      use type Adi.Widget.Item_Kind;
      Text_Idx : constant Natural := Find_Text_Item_Index (W, Text);
   begin
      if Text_Idx = 0 then
         return False;
      end if;
      for I in 1 .. Text_Idx - 1 loop
         declare
            It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, I);
         begin
            if It.Kind = Adi.Widget.Image_Item then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Image_Item_Before;

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

   function Is_Named_Color
     (C    : Adi.CSS_Styles.Color_Value;
      Name : Adi.CSS_Styles.Named_Color) return Boolean
   is
   begin
      return C.Kind = Adi.CSS_Styles.Named and then C.Name = Name;
   end Is_Named_Color;

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
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      HTML : constant String :=
        "<div><h1>Doc</h1><p>Hello <a href='https://example.com'>world</a></p></div>";
   begin
      Put_Line ("Test: Set/Get/Clear");

      Assert (Adi.Widget.Html_View.Is_Valid (W), "Create_Handle returns valid handle");

      Adi.Widget.Html_View.Set_HTML (W, HTML);
      Assert
        (Adi.Widget.Html_View.Get_HTML (W) = HTML,
         "Set_HTML/Get_HTML roundtrip preserves source");

      Adi.Widget.Html_View.Clear (W);
      Assert
        (Adi.Widget.Html_View.Get_HTML (W) = "",
         "Clear resets source to empty string");

      New_Line;
   end Test_Set_Get_Clear;

   procedure Test_Callback_Registration_And_Mouse_Safety is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Link_Clicked : Boolean := False;

      procedure On_Link_Click
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         Href : String)
      is
         pragma Unreferenced (Self, Href);
      begin
         Link_Clicked := True;
      end On_Link_Click;

      function On_Load_Asset
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         URI  : String) return Adi.Image.Image_Handle
      is
         pragma Unreferenced (Self, URI);
      begin
         return Adi.Image.Null_Image_Handle;
      end On_Load_Asset;
   begin
      Put_Line ("Test: Callback registration and mouse safety");

      Adi.Widget.Html_View.Connect_Link_Click
        (W, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Asset
        (W, On_Load_Asset'Unrestricted_Access);

      Adi.Widget.Html_View.Set_HTML
        (W, "<p>safe <a href='https://example.com'>click</a> path</p>");

      --  No layout/build performed in this smoke test; these calls should
      --  remain safe and not raise.
      Adi.Widget.On_Mouse_Down
        (+W, X => 0.0, Y => 0.0, Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.On_Mouse_Move (+W, X => 0.0, Y => 0.0);
      Adi.Widget.On_Mouse_Up
        (+W, X => 0.0, Y => 0.0, Button => Adi.Core.Left_Button);

      Assert
        (not Link_Clicked,
         "no link callback without laid out link fragments");

      New_Line;
   end Test_Callback_Registration_And_Mouse_Safety;

   procedure Test_Embedded_And_Linked_CSS is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Resource_Hits : Natural := 0;
      Asset_Hits    : Natural := 0;

      function On_Load_Resource
        (Self : Adi.Widget.Html_View.Html_View_Handle;
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
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         URI  : String) return Adi.Image.Image_Handle
      is
         pragma Unreferenced (Self);
      begin
         if URI = "app://tests/image.png" then
            Asset_Hits := Asset_Hits + 1;
         end if;
         return Adi.Image.Null_Image_Handle;
      end On_Load_Asset;
   begin
      Put_Line ("Test: Embedded style and linked stylesheet");

      Adi.Widget.Html_View.Set_On_Load_Resource
        (W, On_Load_Resource'Unrestricted_Access);
      Adi.Widget.Html_View.Set_On_Load_Asset
        (W, On_Load_Asset'Unrestricted_Access);

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<link rel='stylesheet' href='app://tests/theme.css'>" &
         "<style>h1 { font-size: 28px; }</style>" &
         "<h1>Title</h1><p><strong>strong</strong> and <a href='x'>link</a> " &
         "<img src='app://tests/image.png' alt='img'></p>");

      Adi.Widget.Set_Geometry (+W, (X => 0.0, Y => 0.0, Width => 640.0, Height => 320.0));
      Adi.Widget.Build_Items (+W);

      Assert (Resource_Hits = 1, "link rel stylesheet uses resource callback exactly once");
      Assert (Asset_Hits = 1, "img src uses asset callback during build");

      New_Line;
   end Test_Embedded_And_Linked_CSS;

   --  A callback that owns what it hands out, and lets it go. The view
   --  keeps only a view, so releasing has to reach it.
   Reload_Owner : Adi.Image.Image_Owner;
   Reload_Hits  : Natural := 0;

   function Reload_Asset
     (Self : Adi.Widget.Html_View.Html_View_Handle;
      URI  : String) return Adi.Image.Image_Handle
   is
      pragma Unreferenced (Self);
      Q : constant Character := '"';
   begin
      if URI /= "app://tests/reload.svg" then
         return Adi.Image.Null_Image_Handle;
      end if;

      Reload_Hits := Reload_Hits + 1;
      Reload_Owner := Adi.Image.Load_SVG_From_String
        ("<svg xmlns=" & Q & "http://www.w3.org/2000/svg" & Q
         & " width=" & Q & "8" & Q & " height=" & Q & "8" & Q & ">"
         & "<rect width=" & Q & "8" & Q & " height=" & Q & "8" & Q
         & "/></svg>");
      return Adi.Image.To_Handle (Reload_Owner);
   end Reload_Asset;

   procedure Test_Released_Asset_Is_Asked_For_Again is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      First_Seen : Adi.Image.Image_Handle;
   begin
      Put_Line ("Test: a released callback image is asked for again");

      Adi.Widget.Html_View.Set_On_Load_Asset
        (W, Reload_Asset'Unrestricted_Access);
      Adi.Widget.Html_View.Set_HTML
        (W, "<p><img src='app://tests/reload.svg' alt='r'></p>");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 200.0, Height => 100.0));

      Adi.Widget.Build_Items (+W);
      Assert (Reload_Hits = 1, "the callback answers once");
      First_Seen := Adi.Image.To_Handle (Reload_Owner);
      Assert (Adi.Image.Is_Valid (First_Seen), "with a live image");

      --  Built again while it is still owned. Re-laid out first, so
      --  that this really re-resolves rather than reusing a clean
      --  layout and telling us nothing.
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 220.0, Height => 100.0));
      Adi.Widget.Build_Items (+W);
      Assert (Reload_Hits = 1, "and is not asked again while it holds");

      Adi.Image.Release (Reload_Owner);
      Assert (not Adi.Image.Is_Valid (First_Seen),
              "releasing the owner stales the view the cache holds");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 240.0, Height => 100.0));
      Adi.Widget.Build_Items (+W);
      Assert (Reload_Hits = 2,
              "The view asks again rather than keeping the stale entry:"
              & " it never owned the image, so asking is the only way it"
              & " can get one back");
      Assert (Adi.Image.Is_Valid (Adi.Image.To_Handle (Reload_Owner)),
              "and what it gets is a live image again");
      Assert (Adi.Image.To_Handle (Reload_Owner) /= First_Seen,
              "of a later generation than the one that went");

      Adi.Image.Release (Reload_Owner);
      New_Line;
   end Test_Released_Asset_Is_Asked_For_Again;

   procedure Test_Heading_Line_Height_Is_Local is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
   begin
      Put_Line ("Test: Heading line-height does not leak");

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>h1 { font-size: 44px; font-weight: 700; }</style>" &
         "<h1>Header</h1><p>normal1<br>normal2</p>");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 640.0, Height => 360.0));
      Adi.Widget.Build_Items (+W);
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
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: CSS cascade precedence");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 640.0, Height => 300.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { color: rgb(10, 20, 30); }" &
         ".note { color: rgb(20, 40, 60); }" &
         "#lead { color: rgb(30, 60, 90); }" &
         "</style>" &
         "<p id='lead' class='note' style='color: rgb(77, 88, 99);'>inline wins</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "inline");
      Assert (Idx > 0, "inline-style paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            Assert
              (Is_RGB (It.Computed_Style.Color, 77, 88, 99),
               "inline style overrides id/class/tag");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { color: rgb(10, 20, 30); }" &
         ".note { color: rgb(20, 40, 60); }" &
         "#lead { color: rgb(30, 60, 90); }" &
         "</style>" &
         "<p id='lead' class='note'>id wins</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "id");
      Assert (Idx > 0, "id-style paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            Assert
              (Is_RGB (It.Computed_Style.Color, 30, 60, 90),
               "id selector overrides class and tag");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { color: rgb(10, 20, 30); }" &
         ".note { color: rgb(20, 40, 60); }" &
         "</style>" &
         "<p class='note'>class wins</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "class");
      Assert (Idx > 0, "class-style paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            Assert
              (Is_RGB (It.Computed_Style.Color, 20, 40, 60),
               "class selector overrides tag");
         end;
      end if;

      New_Line;
   end Test_Cascade_Precedence;

   procedure Test_SVG_Named_Colors is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Body_Idx : Natural := 0;
      Span_Idx : Natural := 0;
      Alias_Idx : Natural := 0;
   begin
      Put_Line ("Test: SVG named colors in Html_View");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 640.0, Height => 260.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { color: cornflowerblue; background-color: lightgoldenrodyellow; }" &
         "span { color: darkslategray; }" &
         "</style>" &
         "<p>named color <span>nested tone</span></p>");
      Adi.Widget.Build_Items (+W);

      Body_Idx := Find_Text_Item_Index (W, "named");
      Span_Idx := Find_Text_Item_Index (W, "nested");

      Assert (Body_Idx > 0, "named color text item exists");
      Assert (Span_Idx > 0, "nested named color text item exists");

      if Body_Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Body_Idx));
         begin
            Assert
              (Is_Named_Color (It.Computed_Style.Color, Adi.CSS_Styles.Cornflower_Blue),
               "cornflowerblue maps to Named_Color enum");
         end;
      end if;

      if Span_Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Span_Idx));
         begin
            Assert
              (Is_Named_Color (It.Computed_Style.Color, Adi.CSS_Styles.Dark_Slate_Gray),
               "darkslategray maps to Named_Color enum");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>em { color: grey; }</style><p><em>alias color</em></p>");
      Adi.Widget.Build_Items (+W);

      Alias_Idx := Find_Text_Item_Index (W, "alias");
      Assert (Alias_Idx > 0, "grey alias text item exists");
      if Alias_Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Alias_Idx));
         begin
            Assert
              (Is_Named_Color (It.Computed_Style.Color, Adi.CSS_Styles.Gray),
               "grey alias resolves to Gray enum");
         end;
      end if;

      New_Line;
   end Test_SVG_Named_Colors;

   procedure Test_Inline_SVG_Element is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Image_Idx : Natural := 0;
   begin
      Put_Line ("Test: inline <svg> element rendering");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 480.0, Height => 220.0));
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<p>icon <svg viewBox='0 0 24 24'>" &
         "<path fill='tomato' d='M4 4 L20 4 L20 20 L4 20 Z'/>" &
         "</svg> inline</p>");
      Adi.Widget.Build_Items (+W);

      Image_Idx := Find_First_Image_Item_Index (W);
      Assert (Image_Idx > 0, "inline svg element produces an image item");
      if Image_Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Image_Idx));
         begin
            Assert (It.Image_Source /= Adi.Image.Null_Image_Handle, "inline svg image item has image source");
            Assert (It.Geometry.Width > 0.0 and then It.Geometry.Height > 0.0,
                    "inline svg image item resolves non-zero geometry");
         end;
      end if;

      New_Line;
   end Test_Inline_SVG_Element;

   --  Regression: Sync_Line_Heights used to floor every run's geometry
   --  height at the line height. Images fill their geometry, so any
   --  image smaller than the line box was stretched vertically
   --  (requested width x floored height). Standard CSS never stretches
   --  replaced content to the line box.
   procedure Test_Image_Not_Stretched_To_Line_Height is
      Tol : constant := 0.5;
   begin
      Put_Line ("Test: images keep their used size (no line-height stretch)");

      --  Explicit CSS box smaller than the surrounding line height
      declare
         W : constant Adi.Widget.Html_View.Html_View_Handle :=
           Adi.Widget.Html_View.Create_Handle;
         Idx : Natural := 0;
      begin
         Adi.Widget.Set_Geometry
           (+W, (X => 0.0, Y => 0.0, Width => 480.0, Height => 220.0));
         Adi.Widget.Html_View.Set_HTML
           (W,
            "<style>" &
            "p { font-size: 20px; line-height: 1.5; }" &
            "svg { width: 12px; height: 12px; }" &
            "</style>" &
            "<p>text <svg viewBox='0 0 24 24'>" &
            "<path fill='tomato' d='M4 4 L20 4 L20 20 L4 20 Z'/>" &
            "</svg> more</p>");
         Adi.Widget.Build_Items (+W);

         Idx := Find_First_Image_Item_Index (W);
         Assert (Idx > 0, "sized icon produces an image item");
         if Idx > 0 then
            declare
               It : constant Adi.Widget.Item :=
                 Adi.Widget.Get_Item (+W, Positive (Idx));
            begin
               Assert (abs (It.Geometry.Width - 12.0) < Tol,
                       "sized icon keeps requested width");
               Assert (abs (It.Geometry.Height - 12.0) < Tol,
                       "sized icon keeps requested height " &
                       "(not floored to line height)");
            end;
         end if;
      end;

      --  Unsized image: intrinsic size, likewise never stretched
      declare
         W : constant Adi.Widget.Html_View.Html_View_Handle :=
           Adi.Widget.Html_View.Create_Handle;
         Idx : Natural := 0;
      begin
         Adi.Widget.Set_Geometry
           (+W, (X => 0.0, Y => 0.0, Width => 480.0, Height => 220.0));
         Adi.Widget.Html_View.Set_HTML
           (W,
            "<style>p { font-size: 40px; line-height: 1.5; }</style>" &
            "<p>text <svg width='24' height='24' viewBox='0 0 24 24'>" &
            "<path fill='tomato' d='M4 4 L20 4 L20 20 L4 20 Z'/>" &
            "</svg> more</p>");
         Adi.Widget.Build_Items (+W);

         Idx := Find_First_Image_Item_Index (W);
         Assert (Idx > 0, "unsized icon produces an image item");
         if Idx > 0 then
            declare
               It : constant Adi.Widget.Item :=
                 Adi.Widget.Get_Item (+W, Positive (Idx));
            begin
               Assert (abs (It.Geometry.Height - 24.0) < Tol,
                       "unsized icon keeps intrinsic height " &
                       "(not stretched to 60px line box)");
            end;
         end if;
      end;

      New_Line;
   end Test_Image_Not_Stretched_To_Line_Height;

   procedure Test_Mixed_Inline_Baseline is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx : Natural := 0;
      B_Idx : Natural := 0;
      C_Idx : Natural := 0;
   begin
      Put_Line ("Test: Mixed inline baseline alignment");

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { font-size: 16px; }" &
         "strong { font-size: 34px; }" &
         "em { font-size: 12px; }" &
         "</style>" &
         "<p>alpha <strong>BETA</strong> <em>gamma</em></p>");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 700.0, Height => 260.0));
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "alpha");
      B_Idx := Find_Text_Item_Index (W, "BETA");
      C_Idx := Find_Text_Item_Index (W, "gamma");

      Assert (A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0,
              "mixed inline runs are present");

      if A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            C : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (C_Idx));
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

   --  A fresh view brings nothing of its own -- no background, border,
   --  padding, and no scrolling either. Appearance and layout behaviour
   --  both belong to the stylesheet that uses it.
   procedure Test_Fresh_View_Is_Neutral is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      use Adi.CSS_Styles;
      R : constant Resolved_Style :=
        Adi.Widget.Get_Resolved_Part_Style (+W, Adi.Widget.Main_Part);
   begin
      Put_Line ("Test: a fresh Html_View brings no appearance of its own");

      --  Including its layout behaviour: scrolling is opt-in, declared
      --  by whoever wants a viewport, not assumed by the widget.
      Assert (R.Overflow_Y = Overflow_Visible,
              "no scrolling of its own until asked for");
      Assert (R.Background_Color = Default_Background,
              "no background of its own");
      Assert (R.Border_Width = Default_Border_Width,
              "no border of its own");
      Assert (R.Padding = CSS_Box (Zero_Length),
              "no padding of its own");
      New_Line;
   end Test_Fresh_View_Is_Neutral;

   --  Clearing the document clears the document. The styling an
   --  application applied is not the widget's to throw away.
   procedure Test_Clear_Keeps_Applied_Styles is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      use Adi.CSS_Styles;
      use Adi.Widget_Styles;
      Rules : constant Style_Rules :=
        (Padding => Set (CSS_Box (Px (7.0))), others => <>);
   begin
      Put_Line ("Test: Clear keeps the styles the application applied");

      Adi.Widget.Set_Part_Styles
        (+W,
         [Adi.Widget.Main_Part =>
            (Style => From (Rules).Build, Enabled => True),
          others => <>]);
      --  A document big enough to scroll, laid out and scrolled, so the
      --  measurements and offset Clear has to reset are non-zero.
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<p>one</p><p>two</p><p>three</p><p>four</p><p>five</p>" &
         "<p>six</p><p>seven</p><p>eight</p><p>nine</p><p>ten</p>");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 200.0, Height => 40.0));
      Adi.Widget.Build_Items (+W);
      Adi.Widget.Set_Scroll_Offset_Y (+W, 20.0);

      Assert (Adi.Widget.Get_Scroll_Offset_Y (+W) > 0.0,
              "the document scrolled before clearing");
      Assert (Adi.Widget.Measure_Content (+W).Height > 40.0,
              "and measures taller than the viewport");

      Adi.Widget.Html_View.Clear (W);

      Assert
        (Adi.Widget.Get_Resolved_Part_Style
           (+W, Adi.Widget.Main_Part).Padding
         = Set (CSS_Box (Px (7.0))).Value,
         "the applied padding survives Clear");
      Assert (Adi.Widget.Html_View.Get_HTML (W) = "",
              "the document is gone");
      Assert (Adi.Widget.Get_Scroll_Offset_Y (+W) = 0.0,
              "the scroll offset goes with it");
      --  Back to what a view with no document reports, rather than the
      --  size of the one it used to hold.
      declare
         Fresh : constant Adi.Widget.Html_View.Html_View_Handle :=
           Adi.Widget.Html_View.Create_Handle;
      begin
         Adi.Widget.Set_Part_Styles
           (+Fresh,
            [Adi.Widget.Main_Part =>
               (Style => From (Rules).Build, Enabled => True),
             others => <>]);
         Assert (abs (Adi.Widget.Measure_Content (+W).Height
                      - Adi.Widget.Measure_Content (+Fresh).Height) < 0.5,
                 "and it measures like a view that never had one");
      end;
      New_Line;
   end Test_Clear_Keeps_Applied_Styles;

   procedure Test_Clipping_Aware_Link_Hit_Test is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Clicks : Natural := 0;

      procedure On_Link_Click
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         Href : String)
      is
         pragma Unreferenced (Self, Href);
      begin
         Clicks := Clicks + 1;
      end On_Link_Click;
   begin
      Put_Line ("Test: Clipping-aware link hit testing");

      Adi.Widget.Html_View.Connect_Link_Click
        (W, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<p><a href='app://clip'>clip target link text for hit testing</a></p>" &
         "<p>second line</p><p>third line</p><p>fourth line</p>" &
         "<p>fifth line</p><p>sixth line</p>");

      --  The coordinates below assume this padding and text size, so the
      --  test states them rather than leaning on widget defaults. The
      --  overflow is what makes the scrolled-out half unclickable.
      declare
         use Adi.CSS_Styles;
         use Adi.Widget_Styles;
         Main_Rules : constant Style_Rules :=
           (Padding    => Set (CSS_Box (Px (14.0))),
            Overflow_Y => Set_Overflow_Y (Overflow_Auto),
            others     => <>);
         Text_Rules : constant Style_Rules :=
           (Font_Size => Set_Font (Px (15.0)), others => <>);
      begin
         Adi.Widget.Set_Part_Styles
           (+W,
            [Adi.Widget.Main_Part =>
               (Style => From (Main_Rules).Build, Enabled => True),
             Adi.Widget.Text_Part =>
               (Style => From (Text_Rules).Build, Enabled => True),
             --  Links are drawn from Indicator_Part; same size as the
             --  body text, or the line box changes height and the
             --  coordinates below stop meaning what they say.
             Adi.Widget.Indicator_Part =>
               (Style => From (Text_Rules).Build, Enabled => True),
             others => <>]);
      end;

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 360.0, Height => 52.0));
      Adi.Widget.Build_Items (+W);

      Adi.Widget.On_Mouse_Down
        (+W, X => 26.0, Y => 26.0, Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.On_Mouse_Up
        (+W, X => 26.0, Y => 26.0, Button => Adi.Core.Left_Button);
      Assert (Clicks = 1, "visible clipped link area remains clickable");

      --  Scroll the link fully out of the viewport. The document has to
      --  be tall enough for that: a short one clamps the offset and the
      --  link stays half visible, which proves nothing.
      Assert (Adi.Widget.Get_Scroll_Max_Offset_Y (+W) >= 40.0,
              "the document is tall enough to scroll the link away");
      Adi.Widget.Set_Scroll_Offset_Y (+W, 40.0);
      Adi.Widget.Build_Items (+W);

      Adi.Widget.On_Mouse_Down
        (+W, X => 26.0, Y => 20.0, Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.On_Mouse_Up
        (+W, X => 26.0, Y => 20.0, Button => Adi.Core.Left_Button);
      Assert (Clicks = 1, "scrolled-out link area is not clickable");

      New_Line;
   end Test_Clipping_Aware_Link_Hit_Test;

   procedure Test_Link_Does_Not_Consume_Leading_Space is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: link run excludes preceding collapsed space");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 420.0, Height => 120.0));
      Adi.Widget.Html_View.Set_HTML
        (W, "<p>alpha <a href='app://x'>beta</a> gamma</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Link_Text_Item_Index (W, "beta");
      Assert (Idx > 0, "link text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
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
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
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

      Adi.Widget.Html_View.Set_HTML (W, To_String (Html));
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 480.0, Height => 180.0));
      Adi.Widget.Build_Items (+W);

      H1 := Adi.Widget.Get_Scroll_Content_Height (+W);
      M1 := Adi.Widget.Get_Scroll_Max_Offset_Y (+W);
      Assert (M1 > 0.0, "long html document overflows viewport");

      Adi.Widget.Set_Scroll_Offset_Y (+W, M1 * 0.75);
      Adi.Widget.Build_Items (+W);

      H2 := Adi.Widget.Get_Scroll_Content_Height (+W);
      M2 := Adi.Widget.Get_Scroll_Max_Offset_Y (+W);

      Assert (Nearly_Equal (H1, H2, 2.0),
              "content height stays stable after scrolling");
      Assert (Nearly_Equal (M1, M2, 2.0),
              "max scroll offset stays stable after scrolling");

      New_Line;
   end Test_Scroll_Content_Height_Stability;

   procedure Test_Center_Alignment is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: center and text-align center");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 620.0, Height => 220.0));

      Adi.Widget.Html_View.Set_HTML
        (W, "<center>center probe</center>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "center");
      Assert (Idx > 0, "center tag text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            Assert (It.Geometry.X > 120.0, "center tag shifts text away from left edge");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>p { text-align: center; }</style><p>css center probe</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "css");
      Assert (Idx > 0, "text-align center paragraph text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            Assert (It.Geometry.X > 120.0, "text-align center shifts text away from left edge");
         end;
      end if;

      New_Line;
   end Test_Center_Alignment;

   procedure Test_Body_Font_Inheritance is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;
      H1  : Adi.Core.Pixel_Type := 0.0;
      H2  : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: body font-size inheritance");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 620.0, Height => 240.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>body { font-size: 16px; }</style><p>inherit probe</p>");
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "inherit");
      Assert (Idx > 0, "baseline inherited text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            H1 := It.Geometry.Height;
            Assert
              (It.Computed_Style.Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
               "baseline inherited unit is px");
            Assert
              (It.Computed_Style.Font_Size.Amount >= 15.0
               and then It.Computed_Style.Font_Size.Amount <= 17.0,
               "baseline inherited size is near body font-size");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>body { font-size: 40px; }</style><p>inherit probe</p>");
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "inherit");
      Assert (Idx > 0, "large inherited text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            H2 := It.Geometry.Height;
            Assert
              (It.Computed_Style.Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
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
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx : Natural := 0;
      B_Idx : Natural := 0;
   begin
      Put_Line ("Test: line-height parsing and layout");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 560.0, Height => 260.0));
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>p { font-size: 16px; line-height: 3; }</style>" &
         "<p>lineA<br>lineB</p>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "lineA");
      B_Idx := Find_Text_Item_Index (W, "lineB");
      Assert (A_Idx > 0 and then B_Idx > 0, "line-height sample lines exist");
      if A_Idx > 0 and then B_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
         begin
            Assert (B.Geometry.Y - A.Geometry.Y > 30.0,
                    "line-height multiplier increases line advance");
         end;
      end if;

      New_Line;
   end Test_Line_Height_Parsing_And_Layout;

   procedure Test_List_Markers_And_LI_Value is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Star_Idx   : Natural := 0;
      Four_Idx   : Natural := 0;
      Five_Idx   : Natural := 0;
   begin
      Put_Line ("Test: list markers and li value override");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 280.0));
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<ol><li value='4'>alpha</li><li>beta</li></ol>" &
         "<ul><li>gamma</li></ul>");
      Adi.Widget.Build_Items (+W);

      Four_Idx := Find_Exact_Text_Item_Index (W, "4.");
      Five_Idx := Find_Exact_Text_Item_Index (W, "5.");
      Star_Idx := Find_Text_Item_Index (W, "*");

      Assert (Four_Idx > 0, "li value attribute overrides ordered-list marker number");
      Assert (Five_Idx > 0, "ordered-list numbering continues after li value override");
      Assert (Has_Image_Item_Before (W, "gamma"),
              "unordered list default marker renders as disc bullet");
      Assert (Star_Idx = 0, "unordered list markers no longer render as asterisk text");

      New_Line;
   end Test_List_Markers_And_LI_Value;

   procedure Test_List_Style_Shorthand_And_Image_Callback is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Marker_Asset_Hits : Natural := 0;
      Arrow_Idx : Natural := 0;

      function On_Load_Asset
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         URI  : String) return Adi.Image.Image_Handle
      is
         pragma Unreferenced (Self);
      begin
         if URI = "app://tests/marker.png" then
            Marker_Asset_Hits := Marker_Asset_Hits + 1;
         end if;

         return Adi.Image.Null_Image_Handle;
      end On_Load_Asset;
   begin
      Put_Line ("Test: list-style shorthand and image markers");

      Adi.Widget.Html_View.Set_On_Load_Asset
        (W, On_Load_Asset'Unrestricted_Access);
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 640.0, Height => 320.0));
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         ".custom { list-style: ""-> "" inside; }" &
         ".icons { list-style: url(app://tests/marker.png) square outside; }" &
         "</style>" &
         "<ul class='custom'><li>inline marker</li></ul>" &
         "<ul class='icons'><li>icon marker a</li><li>icon marker b</li></ul>");
      Adi.Widget.Build_Items (+W);

      Arrow_Idx := Find_Exact_Text_Item_Index (W, "-> ");

      Assert (Arrow_Idx > 0, "list-style shorthand supports quoted custom marker text");
      Assert (Has_Image_Item_Before (W, "icon"),
              "list-style shorthand falls back to type when marker image is unavailable");
      Assert (Marker_Asset_Hits > 0,
              "list-style-image URL uses asset callback for marker resolution");

      New_Line;
   end Test_List_Style_Shorthand_And_Image_Callback;

   procedure Test_Unclosed_Li_Items is
      use type Adi.Widget.Item_Kind;

      procedure Check_Li_Siblings
        (W      : Adi.Widget.Html_View.Html_View_Handle;
         Label  : String;
         First  : String;
         Second : String;
         Third  : String)
      is
         First_Idx  : constant Natural := Find_Text_Item_Index (W, First);
         Second_Idx : constant Natural := Find_Text_Item_Index (W, Second);
         Third_Idx  : constant Natural := Find_Text_Item_Index (W, Third);
         First_X    : Adi.Core.Pixel_Type;
         Second_X   : Adi.Core.Pixel_Type;
         Third_X    : Adi.Core.Pixel_Type;
      begin
         Assert (First_Idx > 0,  Label & ": first li text present");
         Assert (Second_Idx > 0, Label & ": second li text present");
         Assert (Third_Idx > 0,  Label & ": third li text present");

         if First_Idx > 0 and then Second_Idx > 0 and then Third_Idx > 0 then
            First_X  := Adi.Widget.Get_Item (+W, First_Idx).Geometry.X;
            Second_X := Adi.Widget.Get_Item (+W, Second_Idx).Geometry.X;
            Third_X  := Adi.Widget.Get_Item (+W, Third_Idx).Geometry.X;
            Assert (Nearly_Equal (First_X, Second_X),
                    Label & ": second li at same indent as first (not nested)");
            Assert (Nearly_Equal (Second_X, Third_X),
                    Label & ": third li at same indent as second (not nested)");
         end if;
      end Check_Li_Siblings;

      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
   begin
      Put_Line ("Test: unclosed li items treated as siblings");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 300.0));

      --  Case 1: all implicit closes — no </li> at all
      Adi.Widget.Html_View.Set_HTML
        (W, "<ul><li>alpha<li>beta<li>gamma</ul>");
      Adi.Widget.Build_Items (+W);
      Check_Li_Siblings (W, "all-implicit", "alpha", "beta", "gamma");

      --  Case 2: mixed explicit and implicit closes
      Adi.Widget.Html_View.Set_HTML
        (W, "<ul><li>alpha</li><li>beta<li>gamma</ul>");
      Adi.Widget.Build_Items (+W);
      Check_Li_Siblings (W, "mixed-explicit", "alpha", "beta", "gamma");

      New_Line;
   end Test_Unclosed_Li_Items;

   procedure Test_Overline_Decoration_Style is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;
   begin
      Put_Line ("Test: overline decoration style");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 560.0, Height => 220.0));
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>p { text-decoration: overline; }</style><p>overline probe</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "overline");
      Assert (Idx > 0, "overline text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            Assert
              (It.Computed_Style.Text_Decoration = Adi.CSS_Styles.Decoration_Overline,
               "overline text decoration is parsed and applied");
         end;
      end if;

      New_Line;
   end Test_Overline_Decoration_Style;

   procedure Test_Content_Scale is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;
      W1  : Adi.Core.Pixel_Type := 0.0;
      W2  : Adi.Core.Pixel_Type := 0.0;
      VW1 : Adi.Core.Pixel_Type := 0.0;
      VW2 : Adi.Core.Pixel_Type := 0.0;
   begin
      Put_Line ("Test: html content scale");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 620.0, Height => 260.0));

      Adi.Widget.Html_View.Set_HTML
        (W, "<style>body { font-size: 18px; }</style><p>scale plain probe</p>");

      Adi.Widget.Html_View.Set_Content_Scale (W, 1.0);
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "scale");
      Assert (Idx > 0, "scale baseline text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            W1 := It.Geometry.Width;
         end;
      end if;

      Adi.Widget.Html_View.Set_Content_Scale (W, 2.0);
      Assert (Adi.Widget.Html_View.Get_Content_Scale (W) >= 1.99,
              "content scale getter returns updated value");
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "scale");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            W2 := It.Geometry.Width;
            Assert (W2 > W1 * 1.7, "content scale increases absolute-unit text metrics");
         end;
      end if;

      Adi.Widget.Html_View.Set_HTML
        (W, "<style>p { font-size: 10vw; }</style><p>scale vw probe</p>");
      Adi.Widget.Html_View.Set_Content_Scale (W, 1.0);
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "vw");
      Assert (Idx > 0, "vw sample text item exists");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            VW1 := It.Geometry.Width;
         end;
      end if;

      Adi.Widget.Html_View.Set_Content_Scale (W, 2.0);
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "vw");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            VW2 := It.Geometry.Width;
            Assert (Nearly_Equal (VW1, VW2, 2.0),
                    "content scale does not multiply vw-resolved text size");
         end;
      end if;

      New_Line;
   end Test_Content_Scale;

   procedure Test_VW_VH_Context is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
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

      Adi.Widget.Html_View.Set_Content_Scale (W, 1.0);
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>p { font-size: 10vw; line-height: 10vh; }</style><p>vwvh probe</p>");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 300.0, Height => 200.0));
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "vwvh");
      Assert (Idx > 0, "vw/vh html text item exists at small viewport");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            H1 := It.Geometry.Height;
            Assert
              (It.Computed_Style.Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
               "vw font-size is materialized to px for final text rendering");
         end;
      end if;

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 400.0));
      Adi.Widget.Build_Items (+W);
      Idx := Find_Text_Item_Index (W, "vwvh");
      if Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
         begin
            H2 := It.Geometry.Height;
            Assert (H2 > H1 * 1.7, "html vw/vh resolve against html viewport size");
         end;
      end if;

      New_Line;
   end Test_VW_VH_Context;

   procedure Test_HTML_Folder_Stress is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function On_Load_Asset
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         URI  : String) return Adi.Image.Image_Handle
      is
         pragma Unreferenced (Self, URI);
      begin
         return Adi.Image.Null_Image_Handle;
      end On_Load_Asset;

      procedure Parse_Build_And_Probe (Path : String) is
         HTML : constant String := Read_File (Path);
      begin
         Adi.Widget.Html_View.Set_HTML (W, HTML);
         Adi.Widget.Set_Geometry (+W, (X => 0.0, Y => 0.0, Width => 720.0, Height => 480.0));
         Adi.Widget.Build_Items (+W);

         --  Probe mouse paths after building item/link fragments.
         Adi.Widget.On_Mouse_Move (+W, X => 12.0, Y => 12.0);
         Adi.Widget.On_Mouse_Down
           (+W, X => 12.0, Y => 12.0, Button => Adi.Core.Left_Button, Clicks => 1);
         Adi.Widget.On_Mouse_Up
           (+W, X => 12.0, Y => 12.0, Button => Adi.Core.Left_Button);

         Assert (True, "parsed/built " & Path);
      exception
         when E : others =>
            Assert (False, "no exception for " & Path & " (" & Ada.Exceptions.Exception_Name (E) & ")");
      end Parse_Build_And_Probe;
   begin
      Put_Line ("Test: HTML folder stress cases");

      Adi.Widget.Html_View.Set_On_Load_Asset
        (W, On_Load_Asset'Unrestricted_Access);

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

   Default_CSS : constant String :=
     "body { font-size: 16px; }" & ASCII.LF &
     "h1 { font-size: 2em; font-weight: 700; }" & ASCII.LF &
     "strong { font-weight: 700; }" & ASCII.LF &
     "a { text-decoration: underline; }";

   procedure Test_Line_Height_Number_Uses_Font_Size is
      --  Verify that line-height: <number> multiplies font-size, not line-skip.
      --  font-size: 20px with line-height: 2 should produce ~40px line advance.
      --  Before the fix, it was ~20 * 1.2 * 2 = ~48px (line-skip based).
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx : Natural := 0;
      B_Idx : Natural := 0;
   begin
      Put_Line ("Test: line-height number multiplies font-size");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 200.0));
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>p { font-size: 20px; line-height: 2; }</style>" &
         "<p>topLine<br>botLine</p>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "topLine");
      B_Idx := Find_Text_Item_Index (W, "botLine");
      Assert (A_Idx > 0 and then B_Idx > 0,
              "line-height number: both lines exist");
      if A_Idx > 0 and then B_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            Advance : constant Adi.Core.Pixel_Type := B.Geometry.Y - A.Geometry.Y;
         begin
            --  line-height: 2 * font-size: 20px = 40px expected advance.
            --  Allow +-4px tolerance for font metrics rounding.
            Assert (Advance >= 36.0 and then Advance <= 44.0,
                    "line-height number: advance ~40px (got" & Advance'Image & ")");
            --  Old bug would give ~48px (line-skip * 2).
            Assert (Advance < 46.0,
                    "line-height number: not inflated by line-skip");
         end;
      end if;

      New_Line;
   end Test_Line_Height_Number_Uses_Font_Size;

   procedure Test_Margin_Collapsing is
      --  Adjacent block margins should collapse to max(bottom, top).
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx : Natural := 0;
      B_Idx : Natural := 0;
      C_Idx : Natural := 0;
   begin
      Put_Line ("Test: vertical margin collapsing");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 400.0));

      --  h1 margin-bottom: 30px, h2 margin-top: 20px → collapsed gap = 30px
      --  h2 margin-bottom: 20px, p margin-top: 10px → collapsed gap = 20px
      --  Without collapsing: gaps would be 50px and 30px respectively.
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "h1 { font-size: 16px; line-height: 1; margin: 0 0 30px 0; }" &
         "h2 { font-size: 16px; line-height: 1; margin: 20px 0 20px 0; }" &
         "p  { font-size: 16px; line-height: 1; margin: 10px 0 0 0; }" &
         "</style>" &
         "<h1>heading1</h1><h2>heading2</h2><p>para</p>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "heading1");
      B_Idx := Find_Text_Item_Index (W, "heading2");
      C_Idx := Find_Text_Item_Index (W, "para");
      Assert (A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0,
              "margin collapse: all three blocks exist");

      if A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            C : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (C_Idx));
            --  Gap between text baselines includes line height + margin
            Gap_AB : constant Adi.Core.Pixel_Type := B.Geometry.Y - (A.Geometry.Y + A.Geometry.Height);
            Gap_BC : constant Adi.Core.Pixel_Type := C.Geometry.Y - (B.Geometry.Y + B.Geometry.Height);
         begin
            --  Collapsed gap h1→h2: max(30, 20) = 30px (±4px tolerance)
            Assert (Gap_AB >= 26.0 and then Gap_AB <= 34.0,
                    "margin collapse h1-h2: gap ~30px (got" & Gap_AB'Image & ")");
            --  Without collapsing it would be 50px
            Assert (Gap_AB < 42.0,
                    "margin collapse h1-h2: not sum of both margins");
            --  Collapsed gap h2→p: max(20, 10) = 20px (±4px tolerance)
            Assert (Gap_BC >= 16.0 and then Gap_BC <= 24.0,
                    "margin collapse h2-p: gap ~20px (got" & Gap_BC'Image & ")");
            Assert (Gap_BC < 26.0,
                    "margin collapse h2-p: not sum of both margins");
         end;
      end if;

      New_Line;
   end Test_Margin_Collapsing;

   procedure Test_Margin_Collapse_Through_Last_Child is
      --  Pretty-printed HTML: a transparent <center> wraps a styled
      --  heading. The heading's bottom margin must collapse with the next
      --  sibling's top margin even though center sits between them, and
      --  whitespace-only text nodes from indentation must not commit any
      --  margin or insert a blank line.
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx, B_Idx, C_Idx : Natural := 0;
   begin
      Put_Line ("Test: margin collapse-through last child (pretty-printed)");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 400.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "h1 { font-size: 16px; line-height: 1; margin: 30px 0 30px 0; }" &
         "p  { font-size: 16px; line-height: 1; margin: 10px 0 0 0; }" &
         "center { margin: 0px; padding: 0px; }" &
         "</style>" &
         "<h1>aaa</h1>" & ASCII.LF &
         "<center>" & ASCII.LF &
         "  <h1>bbb</h1>" & ASCII.LF &
         "</center>" & ASCII.LF &
         "<p>ccc</p>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "aaa");
      B_Idx := Find_Text_Item_Index (W, "bbb");
      C_Idx := Find_Text_Item_Index (W, "ccc");
      Assert (A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0,
              "collapse-through last child: all three blocks exist");

      if A_Idx > 0 and then B_Idx > 0 and then C_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            C : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (C_Idx));
            Gap_AB : constant Adi.Core.Pixel_Type :=
              B.Geometry.Y - (A.Geometry.Y + A.Geometry.Height);
            Gap_BC : constant Adi.Core.Pixel_Type :=
              C.Geometry.Y - (B.Geometry.Y + B.Geometry.Height);
         begin
            --  h1 #1 -> h1 #2 sibling collapse through transparent
            --  center: max(30, 30) = 30, not 30 + 30 = 60.
            Assert (Gap_AB >= 26.0 and then Gap_AB <= 34.0,
                    "collapse-through: h1->h1 gap ~30px (got" & Gap_AB'Image & ")");
            --  h1 #2 -> p collapse-through center's last-child boundary:
            --  max(30, 10) = 30, not 10 (current bug drops 30).
            Assert (Gap_BC >= 26.0 and then Gap_BC <= 34.0,
                    "collapse-through last child: h1->p gap ~30px (got" & Gap_BC'Image & ")");
            Assert (Gap_BC > 16.0,
                    "collapse-through last child: not just next sibling's margin");
         end;
      end if;

      New_Line;
   end Test_Margin_Collapse_Through_Last_Child;

   procedure Test_Margin_Collapse_Through_First_Child is
      --  Symmetric to last-child: the prior sibling's bottom margin must
      --  collapse with the first child's top margin even though center
      --  sits between them.
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx, B_Idx : Natural := 0;
   begin
      Put_Line ("Test: margin collapse-through first child (pretty-printed)");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 400.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p  { font-size: 16px; line-height: 1; margin: 0 0 10px 0; }" &
         "h1 { font-size: 16px; line-height: 1; margin: 30px 0 0 0; }" &
         "center { margin: 0px; padding: 0px; }" &
         "</style>" &
         "<p>aaa</p>" & ASCII.LF &
         "<center>" & ASCII.LF &
         "  <h1>bbb</h1>" & ASCII.LF &
         "</center>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "aaa");
      B_Idx := Find_Text_Item_Index (W, "bbb");
      Assert (A_Idx > 0 and then B_Idx > 0,
              "collapse-through first child: both blocks exist");

      if A_Idx > 0 and then B_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            Gap : constant Adi.Core.Pixel_Type :=
              B.Geometry.Y - (A.Geometry.Y + A.Geometry.Height);
         begin
            --  Should be max(10, 30, 0) = 30, not 10 + 30 = 40.
            Assert (Gap >= 26.0 and then Gap <= 34.0,
                    "collapse-through first child: gap ~30px (got" & Gap'Image & ")");
            Assert (Gap < 36.0,
                    "collapse-through first child: not sum of margins");
         end;
      end if;

      New_Line;
   end Test_Margin_Collapse_Through_First_Child;

   procedure Test_Margin_Padding_Stops_Collapse is
      --  A parent with non-zero top padding traps the inner block's top
      --  margin: collapse-through stops at the padding edge.
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx, B_Idx : Natural := 0;
   begin
      Put_Line ("Test: padding/border stops margin collapse-through");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 400.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { font-size: 16px; line-height: 1; margin: 0 0 20px 0; }" &
         ".padbox { padding: 14px; margin: 0px; }" &
         "</style>" &
         "<p>aaa</p>" & ASCII.LF &
         "<div class=""padbox"">" & ASCII.LF &
         "  <p style=""margin: 20px 0 0 0;"">bbb</p>" & ASCII.LF &
         "</div>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "aaa");
      B_Idx := Find_Text_Item_Index (W, "bbb");
      Assert (A_Idx > 0 and then B_Idx > 0,
              "padding stops collapse: both blocks exist");

      if A_Idx > 0 and then B_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            Gap : constant Adi.Core.Pixel_Type :=
              B.Geometry.Y - (A.Geometry.Y + A.Geometry.Height);
         begin
            --  Outside collapse: max(p.bottom=20, div.top=0) = 20.
            --  Then div has padding-top 14 which traps the inner p's
            --  top margin (20).
            --  So total gap = 20 + 14 + 20 = 54 (±5 tolerance).
            Assert (Gap >= 49.0 and then Gap <= 59.0,
                    "padding traps inner margin: gap ~54px (got" & Gap'Image & ")");
         end;
      end if;

      New_Line;
   end Test_Margin_Padding_Stops_Collapse;

   procedure Test_Br_Stops_Collapse_Through is
      --  <br> is rendered content; it must commit pending margins so the
      --  h1 below cannot collapse-through with the parent's own outer
      --  margin context.
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx, B_Idx : Natural := 0;
   begin
      Put_Line ("Test: <br> blocks margin collapse-through");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 400.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p  { font-size: 16px; line-height: 1; margin: 0 0 20px 0; }" &
         "h1 { font-size: 16px; line-height: 1; margin: 30px 0 0 0; }" &
         "div { margin: 0px; padding: 0px; }" &
         "</style>" &
         "<p>aaa</p>" & ASCII.LF &
         "<div>" & ASCII.LF &
         "  <br>" & ASCII.LF &
         "  <h1>bbb</h1>" & ASCII.LF &
         "</div>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "aaa");
      B_Idx := Find_Text_Item_Index (W, "bbb");
      Assert (A_Idx > 0 and then B_Idx > 0,
              "br stops collapse-through: both blocks exist");

      if A_Idx > 0 and then B_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            Gap : constant Adi.Core.Pixel_Type :=
              B.Geometry.Y - (A.Geometry.Y + A.Geometry.Height);
         begin
            --  Without <br> blocking, this would be max(20, 30) = 30.
            --  With <br>, p.margin_bottom=20 commits, then <br> adds a
            --  line height (~16), then h1.margin_top=30 collapses with
            --  no pending margin (br already committed) so adds 30.
            --  Total ≥ 30 + line_height ≈ 46+.
            Assert (Gap > 40.0,
                    "br stops collapse-through: gap > 40px (got" & Gap'Image & ")");
         end;
      end if;

      New_Line;
   end Test_Br_Stops_Collapse_Through;

   procedure Test_Pre_Line_Newline_Stops_Collapse_Through is
      --  A rendered newline inside white-space: pre-line is real content
      --  (it produces a visible line break), so it must commit pending
      --  margins. Otherwise the following block child can collapse-through
      --  with the previous sibling's bottom margin past content that
      --  should separate them.
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx, B_Idx : Natural := 0;
   begin
      Put_Line ("Test: pre-line rendered newline blocks margin collapse-through");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 400.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { font-size: 16px; line-height: 1; margin: 0 0 20px 0; }" &
         "h1 { font-size: 16px; line-height: 1; margin: 30px 0 0 0; }" &
         "div { margin: 0; padding: 0; white-space: pre-line; }" &
         "</style>" &
         "<p>aaa</p>" & ASCII.LF &
         "<div>" & ASCII.LF &
         "  <h1>bbb</h1>" & ASCII.LF &
         "</div>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "aaa");
      B_Idx := Find_Text_Item_Index (W, "bbb");
      Assert (A_Idx > 0 and then B_Idx > 0,
              "pre-line newline stops collapse: both blocks exist");

      if A_Idx > 0 and then B_Idx > 0 then
         declare
            A : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
            B : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (B_Idx));
            Gap : constant Adi.Core.Pixel_Type :=
              B.Geometry.Y - (A.Geometry.Y + A.Geometry.Height);
         begin
            --  With the rendered \n committing margins:
            --    p.bottom (20) + line_h (~16) + h1.top (30) ≈ 66.
            --  Without (bug): h1.top collapses past the \n with p.bottom,
            --    giving line_h + max(30, 20) ≈ 46.
            Assert (Gap > 55.0,
                    "pre-line newline stops collapse: gap > 55px (got" & Gap'Image & ")");
         end;
      end if;

      New_Line;
   end Test_Pre_Line_Newline_Stops_Collapse_Through;

   procedure Test_Hr_Margin_Collapse is
      --  <hr> margins must participate in the unified collapse model.
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      A_Idx, C_Idx : Natural := 0;

      function Find_Hr_Item_Index return Natural is
         use type Adi.Widget.Item_Kind;
      begin
         --  hr renders as a Panel_Item with very small height.
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            declare
               It : constant Adi.Widget.Item :=
                 Adi.Widget.Get_Item (+W, I);
            begin
               if It.Kind = Adi.Widget.Panel_Item
                 and then It.Geometry.Height > 0.0
                 and then It.Geometry.Height <= 3.0
                 and then It.Geometry.Width > 100.0
               then
                  return I;
               end if;
            end;
         end loop;
         return 0;
      end Find_Hr_Item_Index;
   begin
      Put_Line ("Test: <hr> participates in margin collapsing");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 400.0));

      --  Sibling collapse: <p m_bot=20><hr m_top=30> should be max(20, 30) = 30.
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>" &
         "p { font-size: 16px; line-height: 1; margin: 0 0 20px 0; }" &
         ".after { margin: 30px 0 0 0; }" &
         "hr { height: 1px; margin: 30px 0 30px 0; }" &
         "</style>" &
         "<p>aaa</p>" & ASCII.LF &
         "<hr>" & ASCII.LF &
         "<p class=""after"">ccc</p>");
      Adi.Widget.Build_Items (+W);

      A_Idx := Find_Text_Item_Index (W, "aaa");
      C_Idx := Find_Text_Item_Index (W, "ccc");
      declare
         Hr_Idx : constant Natural := Find_Hr_Item_Index;
      begin
         Assert (A_Idx > 0 and then C_Idx > 0 and then Hr_Idx > 0,
                 "hr collapse: text and hr items exist");

         if A_Idx > 0 and then C_Idx > 0 and then Hr_Idx > 0 then
            declare
               A  : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (A_Idx));
               H  : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Hr_Idx));
               C  : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (C_Idx));
               Top_Gap : constant Adi.Core.Pixel_Type :=
                 H.Geometry.Y - (A.Geometry.Y + A.Geometry.Height);
               Bot_Gap : constant Adi.Core.Pixel_Type :=
                 C.Geometry.Y - (H.Geometry.Y + H.Geometry.Height);
            begin
               --  Sibling collapse on top side: max(20, 30) = 30. The hr
               --  is centered within Current_Line_H so the rendered Y is
               --  offset by up to half a line height (~8px); allow that.
               Assert (Top_Gap >= 26.0 and then Top_Gap <= 42.0,
                       "hr top sibling collapse: gap ~30-40px (got" & Top_Gap'Image & ")");
               Assert (Top_Gap < 46.0,
                       "hr top: not the additive sum of margins (50)");
               --  Sibling collapse on bottom side: max(30, 30) = 30, same
               --  centering offset.
               Assert (Bot_Gap >= 22.0 and then Bot_Gap <= 42.0,
                       "hr bottom sibling collapse: gap ~30-40px (got" & Bot_Gap'Image & ")");
               Assert (Bot_Gap < 56.0,
                       "hr bottom: not the additive sum of margins (60)");
            end;
         end if;
      end;

      New_Line;
   end Test_Hr_Margin_Collapse;

   procedure Test_Default_Stylesheet is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      H1_Idx : Natural := 0;
      P_Idx  : Natural := 0;
   begin
      Put_Line ("Test: default stylesheet");

      --  Set_Default_Stylesheet_String / Get round-trip
      Adi.Widget.Html_View.Set_Default_Stylesheet_String
        (W, Default_CSS);
      Assert
        (Adi.Widget.Html_View.Get_Default_Stylesheet (W) = Default_CSS,
         "get default stylesheet returns set CSS text");

      --  Set_Default_Stylesheet from file path
      Adi.Widget.Html_View.Set_Default_Stylesheet
        (W, "examples/assets/html/default.css");
      Assert
        (Adi.Widget.Html_View.Get_Default_Stylesheet (W)'Length > 0,
         "set default stylesheet from file loads non-empty CSS");

      --  Set_Default_Stylesheet from bad path logs error, clears CSS
      Adi.Widget.Html_View.Set_Default_Stylesheet
        (W, "/nonexistent/path/bad.css");
      Assert
        (Adi.Widget.Html_View.Get_Default_Stylesheet (W)'Length = 0,
         "set default stylesheet from bad path clears CSS gracefully");

      --  Use string variant for remaining tests
      Adi.Widget.Html_View.Set_Default_Stylesheet_String
        (W, Default_CSS);

      --  Default heading size: h1 font size > p font size
      Adi.Widget.Html_View.Set_HTML
        (W, "<h1>Big</h1><p>Normal</p>");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 400.0));
      Adi.Widget.Build_Items (+W);

      H1_Idx := Find_Text_Item_Index (W, "Big");
      P_Idx  := Find_Text_Item_Index (W, "Normal");
      Assert (H1_Idx > 0 and then P_Idx > 0,
              "default stylesheet h1 and p text items exist");
      if H1_Idx > 0 and then P_Idx > 0 then
         declare
            H1_It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, Positive (H1_Idx));
            P_It  : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, Positive (P_Idx));
         begin
            Assert
              (H1_It.Computed_Style.Font_Size.Amount >
               P_It.Computed_Style.Font_Size.Amount,
               "default stylesheet h1 font-size > p font-size");
            --  h1 is 2em with body 16px = 32px; verify it's near 32px
            --  (catches the old bug where em resolved against viewport height)
            Assert
              (Nearly_Equal
                 (Adi.Core.Pixel_Type (H1_It.Computed_Style.Font_Size.Amount),
                  32.0, 4.0),
               "default stylesheet h1 em resolves near 32px (2em * 16px)");
            Assert
              (Adi.Core.Pixel_Type (H1_It.Computed_Style.Font_Size.Amount) < 100.0,
               "default stylesheet h1 em does not resolve against viewport");
         end;
      end if;

      --  User CSS overrides defaults
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>h1 { font-size: 40px; }</style><h1>Custom</h1>");
      Adi.Widget.Build_Items (+W);

      H1_Idx := Find_Text_Item_Index (W, "Custom");
      Assert (H1_Idx > 0, "custom override h1 text item exists");
      if H1_Idx > 0 then
         declare
            It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, Positive (H1_Idx));
         begin
            Assert
              (It.Computed_Style.Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
               "user CSS override h1 font-size is in px");
            Assert
              (Nearly_Equal
                 (Adi.Core.Pixel_Type (It.Computed_Style.Font_Size.Amount),
                  40.0, 1.0),
               "user CSS overrides default h1 font-size to 40px");
         end;
      end if;

      --  Defaults survive Clear + re-set
      Adi.Widget.Html_View.Clear (W);
      Adi.Widget.Html_View.Set_HTML
        (W, "<h1>After</h1><p>Clear</p>");
      Adi.Widget.Build_Items (+W);

      H1_Idx := Find_Text_Item_Index (W, "After");
      P_Idx  := Find_Text_Item_Index (W, "Clear");
      Assert (H1_Idx > 0 and then P_Idx > 0,
              "defaults survive clear: h1 and p text items exist");
      if H1_Idx > 0 and then P_Idx > 0 then
         declare
            H1_It : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, Positive (H1_Idx));
            P_It  : constant Adi.Widget.Item :=
              Adi.Widget.Get_Item (+W, Positive (P_Idx));
         begin
            Assert
              (H1_It.Computed_Style.Font_Size.Amount >
               P_It.Computed_Style.Font_Size.Amount,
               "defaults survive clear: h1 still larger than p");
         end;
      end if;

      --  Set_Default_Stylesheet_String after Set_HTML triggers reparse
      declare
         W2 : constant Adi.Widget.Html_View.Html_View_Handle :=
           Adi.Widget.Html_View.Create_Handle;
         Idx : Natural := 0;
      begin
         Adi.Widget.Html_View.Set_HTML
           (W2, "<h1>Late</h1>");
         Adi.Widget.Set_Geometry
           (+W2, (X => 0.0, Y => 0.0, Width => 600.0, Height => 400.0));
         Adi.Widget.Build_Items (+W2);
         Idx := Find_Text_Item_Index (W2, "Late");
         if Idx > 0 then
            declare
               Before : constant Float :=
                 Adi.Widget.Get_Item (+W2, Positive (Idx))
                   .Computed_Style.Font_Size.Amount;
            begin
               Adi.Widget.Html_View.Set_Default_Stylesheet_String
                 (W2, "h1 { font-size: 48px; }");
               Adi.Widget.Build_Items (+W2);
               Idx := Find_Text_Item_Index (W2, "Late");
               Assert (Idx > 0, "late default reparse: text item exists");
               if Idx > 0 then
                  declare
                     After : constant Float :=
                       Adi.Widget.Get_Item (+W2, Positive (Idx))
                         .Computed_Style.Font_Size.Amount;
                  begin
                     Assert
                       (After > Before,
                        "set default stylesheet string after set_html triggers reparse");
                  end;
               end if;
            end;
         end if;
      end;

      New_Line;
   end Test_Default_Stylesheet;

begin
   Test_Support.Start_Suite ("HTML view widget test");

   Test_Set_Get_Clear;
   Test_Callback_Registration_And_Mouse_Safety;
   Test_Embedded_And_Linked_CSS;
   Test_Released_Asset_Is_Asked_For_Again;
   Test_Heading_Line_Height_Is_Local;
   Test_Cascade_Precedence;
   Test_SVG_Named_Colors;
   Test_Inline_SVG_Element;
   Test_Image_Not_Stretched_To_Line_Height;
   Test_Mixed_Inline_Baseline;
   Test_Fresh_View_Is_Neutral;
   Test_Clear_Keeps_Applied_Styles;
   Test_Clipping_Aware_Link_Hit_Test;
   Test_Link_Does_Not_Consume_Leading_Space;
   Test_Scroll_Content_Height_Stability;
   Test_Center_Alignment;
   Test_Body_Font_Inheritance;
   Test_Line_Height_Parsing_And_Layout;
   Test_List_Markers_And_LI_Value;
   Test_List_Style_Shorthand_And_Image_Callback;
   Test_Unclosed_Li_Items;
   Test_Overline_Decoration_Style;
   Test_Content_Scale;
   Test_VW_VH_Context;
   Test_HTML_Folder_Stress;
   Test_Line_Height_Number_Uses_Font_Size;
   Test_Margin_Collapsing;
   Test_Margin_Collapse_Through_Last_Child;
   Test_Margin_Collapse_Through_First_Child;
   Test_Margin_Padding_Stops_Collapse;
   Test_Br_Stops_Collapse_Through;
   Test_Pre_Line_Newline_Stops_Collapse_Through;
   Test_Hr_Margin_Collapse;
   Test_Default_Stylesheet;

   Test_Support.Finish;
end Html_View_Test;
