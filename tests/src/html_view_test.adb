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
with Adi.Resolved_Styles; use Adi.Resolved_Styles;
with Adi.Widget_Styles;
with Adi.Widget;
with Adi.CSS_Parser.Testing;
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

      --  Built again while it is still owned; re-laid out first so this actually re-resolves rather than reusing a clean layout.
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
              (Is_RGB (Ref (It.Computed_Style).Color, 77, 88, 99),
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
              (Is_RGB (Ref (It.Computed_Style).Color, 30, 60, 90),
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
              (Is_RGB (Ref (It.Computed_Style).Color, 20, 40, 60),
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
              (Is_Named_Color (Ref (It.Computed_Style).Color, Adi.CSS_Styles.Cornflower_Blue),
               "cornflowerblue maps to Named_Color enum");
         end;
      end if;

      if Span_Idx > 0 then
         declare
            It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Span_Idx));
         begin
            Assert
              (Is_Named_Color (Ref (It.Computed_Style).Color, Adi.CSS_Styles.Dark_Slate_Gray),
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
              (Is_Named_Color (Ref (It.Computed_Style).Color, Adi.CSS_Styles.Gray),
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

   --  Standard CSS never stretches replaced content (e.g. an image) to the line box height.
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

   --  40x20 intrinsic, so a kept aspect ratio is visible.
   Wide_Owner : Adi.Image.Image_Owner := Adi.Image.Null_Image_Owner;

   function Wide_Asset
     (Self : Adi.Widget.Html_View.Html_View_Handle;
      URI  : String) return Adi.Image.Image_Handle
   is
      pragma Unreferenced (Self, URI);
   begin
      return Adi.Image.To_Handle (Wide_Owner);
   end Wide_Asset;

   procedure Test_Img_Dimension_Attributes is
      Tol : constant := 0.5;

      procedure Check
        (Markup : String; Want_W, Want_H : Adi.Core.Pixel_Type; What : String;
         Default_CSS : String := "")
      is
         W : constant Adi.Widget.Html_View.Html_View_Handle :=
           Adi.Widget.Html_View.Create_Handle;
         Idx : Natural;
      begin
         Adi.Widget.Html_View.Set_On_Load_Asset (W, Wide_Asset'Unrestricted_Access);
         Adi.Widget.Html_View.Set_Default_Stylesheet_String (W, Default_CSS);
         Adi.Widget.Set_Geometry
           (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 300.0));
         Adi.Widget.Html_View.Set_HTML (W, Markup);
         Adi.Widget.Build_Items (+W);

         Idx := Find_First_Image_Item_Index (W);
         Assert (Idx > 0, What & ": image item exists");
         if Idx > 0 then
            declare
               G : constant Adi.Core.Rectangle :=
                 Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry;
            begin
               Assert (abs (G.Width - Want_W) < Tol and then abs (G.Height - Want_H) < Tol,
                       What & ": expected" & Want_W'Image & " x" & Want_H'Image
                       & ", got" & G.Width'Image & " x" & G.Height'Image);
            end;
         end if;
      end Check;
   begin
      Put_Line ("Test: img width/height attributes");

      Wide_Owner := Adi.Image.Load_SVG_From_String
        ("<svg xmlns='http://www.w3.org/2000/svg' width='40' height='20'>"
         & "<rect width='40' height='20'/></svg>");

      Check ("<p><img src='a'></p>", 40.0, 20.0, "no attributes keep intrinsic size");
      Check ("<p><img src='a' width='32' height='32'></p>", 32.0, 32.0, "both attributes");
      Check ("<p><img src='a' width='80'></p>", 80.0, 40.0, "width alone keeps aspect");
      Check ("<p><img src='a' height='10'></p>", 20.0, 10.0, "height alone keeps aspect");
      Check ("<p><img src='a' width='25%'></p>", 100.0, 50.0, "percentage of the line");
      Check ("<p><img src='a' width=' 60px'></p>", 60.0, 30.0, "trailing text after digits is ignored");
      Check ("<p><img src='a' width='wide'></p>", 40.0, 20.0, "no leading digit is ignored");
      Check ("<p><img src='a' width='12.5' height='7.5'></p>", 12.5, 7.5, "fractions");
      Check ("<style>img { width: 16px; }</style><p><img src='a' width='80'></p>",
             16.0, 8.0, "a stylesheet rule overrides the attribute");
      Check ("<p><img src='a' width='80' style='height: 10px'></p>",
             80.0, 10.0, "inline style and attribute combine");
      Check ("<style>.s { width: 16px; }</style><p><img class='s' src='a' width='80'></p>",
             16.0, 8.0, "a class rule overrides the attribute");
      Check ("<p><img src='a' width='80'></p>", 16.0, 8.0,
             "the default stylesheet overrides the attribute",
             Default_CSS => "img { width: 16px; }");
      Check ("<p><img src='a' width='" & ASCII.HT & ASCII.LF & "60'></p>",
             60.0, 30.0, "leading tab and newline are skipped");
      Check ("<p><img src='a' width='1e3'></p>", 1.0, 0.5, "an exponent is trailing text");
      Check ("<p><img src='a' width='-5'></p>", 40.0, 20.0, "a sign is not a digit");
      Check ("<p><img src='a' width='.5'></p>", 40.0, 20.0, "a leading point is not a digit");
      Check ("<p><img src='a' width='%'></p>", 40.0, 20.0, "a bare percent sign is ignored");
      Check ("<p><img src='a' width='99999999999999999999999999999999999999999999'></p>",
             1.0E7, 5.0E6, "a huge value saturates");

      Wide_Owner := Adi.Image.Null_Image_Owner;
      New_Line;
   end Test_Img_Dimension_Attributes;

   procedure Test_Grid_Px_Track_Follows_Content_Scale is
      W   : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural;
   begin
      Put_Line ("Test: grid px tracks follow the content scale");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 300.0));
      Adi.Widget.Html_View.Set_Content_Scale (W, 2.0);
      Adi.Widget.Html_View.Set_HTML
        (W, "<div style='display: grid; grid-template-columns: 100px 1fr'>"
            & "<div style='height: 10px'></div><div>r</div></div>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "r");
      Assert (Idx > 0, "second cell text exists");
      if Idx > 0 then
         Assert (abs (Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry.X - 200.0) < 0.5,
                 "a 100px track is 200 wide at content scale 2");
      end if;
      New_Line;
   end Test_Grid_Px_Track_Follows_Content_Scale;

   --  Twice the content scale in twice the width lays every nested text
   --  run, em and rem margin, root font size and line height out at
   --  exactly twice the geometry:
   --  the fallback metrics this test measures with are linear in size.
   procedure Test_Content_Scale_Is_Linear is
      Doc : constant String :=
        "<style>:root { font-size: 20px; } body { font-size: 18px; }"
        & " h1 { font-size: 2em; margin: 0.5em 0px; line-height: 1.5em; }"
        & " div { padding: 1em; } p { margin: 1rem 0px; line-height: 30px; }</style>"
        & "<div><div><h1>deep heading</h1><p>deep text</p>"
        & "<div style='display: flex; gap: 1em'><span>flex one</span><span>two</span></div>"
        & "</div></div>";

      function Geometry_Of
        (Scale : Adi.Core.Pixel_Type; Needle : String) return Adi.Core.Rectangle
      is
         W : constant Adi.Widget.Html_View.Html_View_Handle :=
           Adi.Widget.Html_View.Create_Handle;
         Idx : Natural;
      begin
         Adi.Widget.Set_Geometry
           (+W, (X => 0.0, Y => 0.0, Width => 600.0 * Scale, Height => 600.0 * Scale));
         Adi.Widget.Html_View.Set_Content_Scale (W, Scale);
         Adi.Widget.Html_View.Set_HTML (W, Doc);
         Adi.Widget.Build_Items (+W);
         Idx := Find_Text_Item_Index (W, Needle);
         Assert (Idx > 0, Needle & " exists at scale" & Scale'Image);
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry
                 else (0.0, 0.0, 0.0, 0.0));
      end Geometry_Of;

      procedure Check (Needle : String) is
         One : constant Adi.Core.Rectangle := Geometry_Of (1.0, Needle);
         Two : constant Adi.Core.Rectangle := Geometry_Of (2.0, Needle);
      begin
         Assert (Nearly_Equal (Two.X, 2.0 * One.X, 0.5)
                 and then Nearly_Equal (Two.Y, 2.0 * One.Y, 0.5)
                 and then Nearly_Equal (Two.Width, 2.0 * One.Width, 0.5)
                 and then Nearly_Equal (Two.Height, 2.0 * One.Height, 0.5),
                 Needle & " doubles at scale 2: " & One.X'Image & One.Y'Image
                 & One.Width'Image & One.Height'Image & " ->" & Two.X'Image
                 & Two.Y'Image & Two.Width'Image & Two.Height'Image);
      end Check;
   begin
      Put_Line ("Test: content scale is linear at depth");
      Check ("heading");
      Check ("text");
      Check ("one");
      Check ("two");
      New_Line;
   end Test_Content_Scale_Is_Linear;

   --  A percentage font size is of the parent's, and a percentage line
   --  height of the element's own font size. The fallback metrics this
   --  test measures with are linear in size, so the ratios are exact.
   procedure Test_Percent_Font_And_Line_Height is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Item_Of (Needle : String) return Adi.Widget.Item is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx))
                 else Adi.Widget.Get_Item (+W, 1));
      end Item_Of;
   begin
      Put_Line ("Test: percentage font size and line height");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));
      Adi.Widget.Html_View.Set_HTML
        (W, "<style>body { font-size: 16px; line-height: 1.0; }</style>"
            & "<p>base</p>"
            & "<p style='font-size: 150%'>half</p>"
            & "<div style='font-size: 200%'><p style='font-size: 50%'>back</p></div>"
            & "<p style='line-height: 200%'>tall</p>"
            & "<p style='font-size: 150%; line-height: 200%'>both</p>");
      Adi.Widget.Build_Items (+W);

      declare
         Base : constant Adi.Widget.Item := Item_Of ("base");
         Half : constant Adi.Widget.Item := Item_Of ("half");
         Back : constant Adi.Widget.Item := Item_Of ("back");
         Tall : constant Adi.Widget.Item := Item_Of ("tall");
         Both : constant Adi.Widget.Item := Item_Of ("both");
      begin
         Assert (Nearly_Equal (Half.Geometry.Width, 1.5 * Base.Geometry.Width),
                 "font-size: 150% is half again the parent's:"
                 & Base.Geometry.Width'Image & " ->" & Half.Geometry.Width'Image);
         Assert (Nearly_Equal (Back.Geometry.Width, Base.Geometry.Width),
                 "200% then 50% comes back to the parent's size:"
                 & Back.Geometry.Width'Image);
         Assert (Nearly_Equal (Tall.Geometry.Height, 32.0),
                 "line-height: 200% of a 16px font is 32px:"
                 & Tall.Geometry.Height'Image);
         Assert (Nearly_Equal (Both.Geometry.Height, 48.0),
                 "line-height: 200% follows the element's own 24px font:"
                 & Both.Geometry.Height'Image);
      end;
      --  A percentage root size is of the default 16px.
      Adi.Widget.Html_View.Set_HTML
        (W, "<style>:root { font-size: 150%; } body { font-size: 1rem; line-height: 1.0; }</style>"
            & "<p>root</p>");
      Adi.Widget.Build_Items (+W);
      Assert (Nearly_Equal (Item_Of ("root").Geometry.Height, 24.0),
              "1rem under :root { font-size: 150% } is 24px:"
              & Item_Of ("root").Geometry.Height'Image);

      --  A percentage line height is a length once computed: a child
      --  with a bigger font inherits it rather than doubling it.
      Adi.Widget.Html_View.Set_HTML
        (W, "<style>body { font-size: 16px; line-height: 1.0; }</style>"
            & "<p style='line-height: 200%'>outer <span style='font-size: 200%'>inner</span></p>");
      Adi.Widget.Build_Items (+W);
      Assert (Nearly_Equal (Item_Of ("inner").Geometry.Height, 32.0),
              "a 32px font inherits the parent's computed 32px line:"
              & Item_Of ("inner").Geometry.Height'Image);
      New_Line;
   end Test_Percent_Font_And_Line_Height;

   --  Sheet rules select with compounds, combinators and pseudo-classes,
   --  and cascade by specificity, then by the order written. Under
   --  line-height: 1.0 a line is as tall as its largest font, so the
   --  height of a word alone on its line reads the size a rule set.
   procedure Test_Selectors is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Size_Of (Needle : String) return Float is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0
                 then Float (Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry.Height)
                 else 0.0);
      end Size_Of;

      procedure Expect (Needle : String; Px : Float; What : String) is
         Got : constant Float := Size_Of (Needle);
      begin
         Assert (abs (Got - Px) < 0.01, What & ":" & Got'Image);
      end Expect;

      Base : constant String :=
        "<style>body { font-size: 16px; line-height: 1.0; } ";
   begin
      Put_Line ("Test: sheet selectors");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));

      Adi.Widget.Html_View.Set_HTML
        (W, Base
            & "p span { font-size: 20px; } "
            & "div > em { font-size: 24px; } "
            & ".a.b { font-size: 28px; } "
            & "h6 + p { font-size: 12px; } "
            & "h5 ~ p { font-size: 10px; } "
            & "li:first-child { font-size: 30px; } "
            & "li:last-child { font-size: 8px; } "
            & "a[href] { font-size: 19px; } "
            & "p::before, .kept { font-size: 18px; } "
            & "body div i { font-size: 22px; } "
            & "html i.top { font-size: 26px; } "
            & "b + u { font-size: 21px; } s ~ q { font-size: 23px; } "
            & "[data-k] { font-size: 25px; } [title=Hi] { font-size: 27px; } "
            & "[open] { font-size: 29px; } a[href=''] { font-size: 31px; } "
            & "[lang=en] { font-size: 33px; } [p] { font-size: 35px; }"
            & "</style>"
            & "<p><span>inside</span></p><div><span>outside</span></div>"
            & "<div><em>child</em><p><em>grandchild</em></p></div>"
            & "<p class='b a'>both</p><p class='a'>one</p>"
            & "<h6>h</h6><p>next</p><p>after</p>"
            & "<div><h5>h</h5><h4>x</h4><p>later</p></div>"
            & "<ul><li>first</li><li>middle</li><li>last</li></ul>"
            & "<p><a href='#x'>link</a></p><p><a>bare</a></p>"
            & "<p class='kept'>kept</p>"
            & "<div><i>deep</i></div><i class='top'>top</i>"
            & "<div><b>b</b> text <!-- note --> <u>skips text</u></div>"
            & "<div><s>s</s> <b>b</b><br><q>over others</q></div>"
            & "<p data-k='1'>data</p><p title='Hi'>titled</p><p title='hi'>case</p>"
            & "<p open>valueless attribute</p><p><a href=''>empty href</a></p>"
            & "<p lang=en>unquoted</p><p>tagname</p>");
      Adi.Widget.Build_Items (+W);

      Expect ("inside", 20.0, "p span selects a descendant");
      Expect ("outside", 16.0, "p span skips a span outside any p");
      Expect ("child", 24.0, "div > em selects a child");
      Expect ("grandchild", 16.0, "div > em skips a grandchild");
      Expect ("both", 28.0, ".a.b selects an element with both classes");
      Expect ("one", 16.0, ".a.b skips an element with one");
      Expect ("next", 12.0, "h6 + p selects the next sibling");
      Expect ("after", 16.0, "h6 + p skips a later one");
      Expect ("later", 10.0, "h5 ~ p selects a later sibling");
      Expect ("first", 30.0, ":first-child");
      Expect ("middle", 16.0, "neither first nor last");
      Expect ("last", 8.0, ":last-child");
      Expect ("link", 19.0, "a[href] selects a link");
      Expect ("bare", 16.0, "a[href] skips an a without one");
      Expect ("kept", 18.0, "a selector outside the grammar drops only itself");
      Expect ("deep", 22.0, "the document root is body");
      Expect ("top", 26.0, "body sits under html");
      Expect ("skips", 21.0, "+ looks past text and comments to the element before");
      Expect ("over", 23.0, "~ looks past other elements");
      Expect ("data", 25.0, "[data-k] selects any attribute");
      Expect ("titled", 27.0, "[title=Hi]");
      Expect ("case", 16.0, "attribute values match case-sensitively");
      Expect ("valueless", 29.0, "an attribute without a value is present");
      Expect ("empty", 31.0, "an empty value is present, and equals ''");
      Expect ("unquoted", 33.0, "an unquoted value");
      Expect ("tagname", 16.0, "a tag's name is not one of its attributes");

      --  Specificity outweighs order; at equal weight the later rule wins;
      --  the style attribute outweighs every rule.
      Adi.Widget.Html_View.Set_HTML
        (W, Base
            & "#i { font-size: 30px; } p.c { font-size: 24px; } "
            & ".c { font-size: 8px; } p { font-size: 9px; } "
            & ".d { font-size: 12px; } .e { font-size: 14px; }"
            & "</style>"
            & "<p id='i' class='c'>id</p><p class='c'>class</p>"
            & "<p class='e d'>order</p>"
            & "<p id='i' style='font-size: 11px'>inline</p>");
      Adi.Widget.Build_Items (+W);
      Expect ("id", 30.0, "an id outweighs classes written after it");
      Expect ("class", 24.0, "p.c outweighs a later .c");
      Expect ("order", 14.0, "the later of two equal rules wins");
      Expect ("inline", 11.0, "the style attribute outweighs an id");

      --  :hover and :active follow the link under the pointer, and the
      --  elements it is inside.
      Adi.Widget.Html_View.Set_HTML
        (W, Base
            & "a:hover { font-size: 24px; } p:hover .x { font-size: 20px; } "
            & "a:active { font-size: 32px; }"
            & "</style>"
            & "<p><a href='#a'>hot</a><br><span class='x'>near</span></p>"
            & "<p><span class='x'>far</span></p>");
      Adi.Widget.Build_Items (+W);
      Expect ("hot", 16.0, "nothing is hovered at first");
      Expect ("near", 16.0, "nor is its paragraph");

      Adi.Widget.Set_Hovered (+W);
      declare
         G : constant Adi.Core.Rectangle :=
           Adi.Widget.Get_Item (+W, Find_Text_Item_Index (W, "hot")).Geometry;
         X : constant Adi.Core.Pixel_Type := G.X + G.Width / 2.0;
         Y : constant Adi.Core.Pixel_Type := G.Y + G.Height / 2.0;
      begin
         Adi.Widget.On_Mouse_Move (+W, X => X, Y => Y);
         Adi.Widget.Build_Items (+W);
         Expect ("hot", 24.0, "a:hover selects the link under the pointer");
         Expect ("near", 20.0, "p:hover selects the paragraph holding it");
         Expect ("far", 16.0, "another paragraph is not hovered");

         Adi.Widget.On_Mouse_Down
           (+W, X => X, Y => Y, Button => Adi.Core.Left_Button, Clicks => 1);
         Adi.Widget.Build_Items (+W);
         Expect ("hot", 32.0, "a:active selects the pressed link");
         Adi.Widget.On_Mouse_Up (+W, X => X, Y => Y, Button => Adi.Core.Left_Button);
         Adi.Widget.Build_Items (+W);
         Expect ("hot", 24.0, "releasing it leaves it hovered");
      end;

      Adi.Widget.Set_Hovered (+W, False);
      Adi.Widget.Build_Items (+W);
      Expect ("hot", 16.0, "a pointer outside the view hovers nothing in it");

      --  A new document starts with nothing hovered or pressed.
      Adi.Widget.Set_Hovered (+W);
      Adi.Widget.Html_View.Set_HTML
        (W, Base & "a:hover { font-size: 24px; } a:active { font-size: 32px; }</style>"
            & "<p><a href='#a'>cold</a></p>");
      Adi.Widget.Build_Items (+W);
      Expect ("cold", 16.0, "a reparse forgets the hovered link");
      New_Line;
   end Test_Selectors;

   --  width, height, their limits and auto margins size a block in normal
   --  flow, border-box; a percentage height is of a declared one.
   procedure Test_Block_Sizing is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Geom (Needle : String) return Adi.Core.Rectangle is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry
                 else (0.0, 0.0, 0.0, 0.0));
      end Geom;

      procedure Expect (What : String; Got, Want : Adi.Core.Pixel_Type) is
      begin
         Assert (abs (Got - Want) < 0.01, What & ":" & Got'Image & " /=" & Want'Image);
      end Expect;

      function Gap (Above, Below : String) return Adi.Core.Pixel_Type is
        (Geom (Below).Y - Geom (Above).Y);
   begin
      Put_Line ("Test: block sizing");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));
      Adi.Widget.Html_View.Set_HTML
        (W, "<style>body { font-size: 16px; line-height: 1.0; } p { margin: 0; }</style>"
            & "<div style='width: 200px; margin-left: auto'>right</div>"
            & "<div style='max-width: 300px; margin: 0 auto'>centred</div>"
            & "<div style='width: 50%; margin: 0 auto'>half</div>"
            & "<div style='width: 200px; padding-left: 20px; margin-left: auto'>borderbox</div>"
            & "<div style='min-width: 300px; max-width: 100px; margin-left: auto'>minwins</div>"
            & "<div style='width: 900px; margin: 0 auto'>toowide</div>"
            & "<div style='width: 200px; margin-right: auto; margin-left: 10px'>leftauto</div>"
            & "<div style='width: 100px'>narrow words wrap here</div>"
            & "<div style='height: 100px'>tall</div><div>aftertall</div>"
            & "<div style='height: 10px'>short<br>overflow</div><div>aftershort</div>"
            & "<div style='height: 100px; padding: 10px'>padded</div><div>afterpadded</div>"
            & "<div style='min-height: 50px'>minh</div><div>afterminh</div>"
            & "<div style='max-height: 20px'>maxh<br>b<br>c</div><div>aftermaxh</div>"
            & "<div style='height: 200px'><div style='height: 50%'>pct</div><div>afterpct</div></div>"
            & "<div><div style='height: 50%'>autopct</div><div>afterautopct</div></div>"
            & "<div style='height: 50px'><p style='margin-bottom: 30px'>inner</p></div><div>afterinner</div>"
            & "<div style='display: flex'><div><div style='width: 150px'>fixed</div></div><div>beside</div></div>"
            & "<div style='display: flex'><div><div style='width: 50%'>pctin</div></div><div>pctbeside</div></div>"
            & "<p>flextop</p><div style='height: 200px'><div style='display: flex; "
            & "flex-direction: column; justify-content: flex-end; height: 50%'><div>flexend</div></div></div>"
            & "<div style='max-height: 100px'><p style='margin-bottom: 20px'>capm</p></div>"
            & "<p style='margin-top: 30px'>aftercapm</p>"
            & "<hr style='width: 50%; margin: 0 auto; height: 4px; border: none'>");
      Adi.Widget.Build_Items (+W);

      Expect ("margin-left: auto pushes a sized block right", Geom ("right").X, 400.0);
      Expect ("max-width with auto margins centres", Geom ("centred").X, 150.0);
      Expect ("a percentage width with auto margins centres", Geom ("half").X, 150.0);
      Expect ("width is border-box", Geom ("borderbox").X, 420.0);
      Expect ("min-width outweighs max-width", Geom ("minwins").X, 300.0);
      Expect ("auto margins of an overwide block are zero", Geom ("toowide").X, 0.0);
      Expect ("margin-right: auto keeps the left margin", Geom ("leftauto").X, 10.0);
      Assert (Geom ("wrap").Y > Geom ("narrow").Y, "content wraps at the declared width");

      Expect ("height", Gap ("tall", "aftertall"), 100.0);
      Expect ("content overflows a short height", Gap ("short", "aftershort"), 10.0);
      Expect ("height is border-box", Gap ("padded", "afterpadded"), 100.0 - 10.0);
      Expect ("min-height", Gap ("minh", "afterminh"), 50.0);
      Expect ("max-height", Gap ("maxh", "aftermaxh"), 20.0);
      Expect ("a percentage of a declared height", Gap ("pct", "afterpct"), 100.0);
      Expect ("a percentage of an auto height is auto", Gap ("autopct", "afterautopct"), 16.0);
      Expect ("a child's margin stays inside a declared height", Gap ("inner", "afterinner"), 50.0);
      Expect ("a sized block counts at its width in a flex item's measure",
              Geom ("beside").X, 150.0);
      Expect ("a percentage width counts as auto in a flex item's measure",
              Geom ("pctbeside").X, Geom ("pctin").Width);
      Expect ("a flex container's percentage height is of its block's",
              Gap ("flextop", "flexend"), 16.0 + 100.0 - 16.0);
      Expect ("max-height alone lets the last child's margin collapse",
              Gap ("capm", "aftercapm"), 16.0 + 30.0);

      declare
         Found : Boolean := False;
      begin
         for I in 1 .. Adi.Widget.Item_Count (+W) loop
            declare
               G : constant Adi.Core.Rectangle := Adi.Widget.Get_Item (+W, I).Geometry;
            begin
               if abs (G.Height - 4.0) < 0.01 then
                  Found := True;
                  Expect ("hr width", G.Width, 300.0);
                  Expect ("hr centred by auto margins", G.X, 150.0);
               end if;
            end;
         end loop;
         Assert (Found, "the 4px hr is laid out");
      end;
      New_Line;
   end Test_Block_Sizing;

   --  body is a block box of its own; its background paints the canvas.
   procedure Test_Body_Box is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Geom (Needle : String) return Adi.Core.Rectangle is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry
                 else (0.0, 0.0, 0.0, 0.0));
      end Geom;

      procedure Expect (What : String; Got, Want : Adi.Core.Pixel_Type) is
      begin
         Assert (abs (Got - Want) < 0.01, What & ":" & Got'Image & " /=" & Want'Image);
      end Expect;

      procedure Load (CSS, Markup : String) is
      begin
         Adi.Widget.Html_View.Set_HTML
           (W, "<style>body { font-size: 16px; line-height: 1.0; } p { margin: 0; } "
               & CSS & "</style>" & Markup);
         Adi.Widget.Build_Items (+W);
      end Load;

      --  Panels spanning the whole canvas: the view is 600x900 and the
      --  documents here are short.
      function Canvas_Panels return Natural is
         Count : Natural := 0;
      begin
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            declare
               It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, I);
               G  : constant Adi.Core.Rectangle := It.Geometry;
            begin
               if Adi.Widget."=" (It.Kind, Adi.Widget.Panel_Item)
                 and then G.X = 0.0 and then G.Y = 0.0
                 and then G.Width = 600.0 and then G.Height = 900.0
               then
                  Count := Count + 1;
               end if;
            end;
         end loop;
         return Count;
      end Canvas_Panels;
   begin
      Put_Line ("Test: body box");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));

      Load ("body { max-width: 300px; margin: 0 auto; padding: 10px; }", "<p>page</p>");
      Expect ("body is centred by max-width and auto margins", Geom ("page").X, 160.0);
      Expect ("body's padding insets its content", Geom ("page").Y, 10.0);

      Load ("html { padding-left: 20px; }", "<p>outer</p>");
      Expect ("html's box folds into body's", Geom ("outer").X, 20.0);

      Load ("body { border: 2px solid black; }", "<p>bordered</p>");
      Expect ("body's border insets its content", Geom ("bordered").X, 2.0);

      Load ("body { margin-top: 10px; } p.m { margin-top: 30px; }", "<p class='m'>collapsed</p>");
      Expect ("body's top margin collapses with its first child's",
              Geom ("collapsed").Y, 30.0);

      Load ("body { display: flex; }", "<div>left</div><div>right</div>");
      Expect ("body lays its children out as flex items", Geom ("right").Y, Geom ("left").Y);
      Assert (Geom ("right").X > Geom ("left").X, "flex items sit side by side");

      Load ("", "<p>plain</p>");
      Assert (Canvas_Panels = 0, "no canvas panel without a body background");
      Load ("body { background-color: #ffeedd; max-width: 300px; margin: 0 auto; }",
            "<p>painted</p>");
      Assert (Canvas_Panels = 1, "body's background paints the whole canvas");
      --  body's own panel is the first item at its centred place.
      declare
         Own : Natural := 0;
      begin
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            if Adi.Widget.Get_Item (+W, I).Geometry.X = 150.0 then
               Own := I;
               exit;
            end if;
         end loop;
         Assert (Own > 0, "body's own box is laid out at its centred place");
         Assert (Own > 0
                 and then Adi.CSS_Styles."="
                   (Ref (Adi.Widget.Get_Item (+W, Own).Style_Override).Background_Color,
                    Adi.CSS_Styles.Default_Background),
                 "body's own box does not paint the background again");
      end;

      --  The canvas covers a document taller than the view, body's bottom
      --  margin included.
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 100.0));
      Load ("body { margin: 50px 0; background-color: #ffeedd; }", "<p>tall</p>");
      Expect ("the scroll range counts body's bottom margin",
              Adi.Widget.Get_Scroll_Max_Offset_Y (+W), 50.0 + 16.0 + 50.0 - 100.0);
      Expect ("the canvas is as tall as the document",
              Adi.Widget.Get_Item (+W, 2).Geometry.Height, 116.0);
      New_Line;
   end Test_Body_Box;

   --  An inline element's horizontal margin, border and padding take room
   --  on the line; a background or border draws a box on each line's
   --  fragment, as tall as its font and vertical padding, leaving the line
   --  height alone.
   procedure Test_Inline_Boxes is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Geom (Needle : String) return Adi.Core.Rectangle is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry
                 else (0.0, 0.0, 0.0, 0.0));
      end Geom;

      procedure Expect (What : String; Got, Want : Adi.Core.Pixel_Type) is
      begin
         Assert (abs (Got - Want) < 0.01, What & ":" & Got'Image & " /=" & Want'Image);
      end Expect;

      --  The inline box panels (narrower than the view, unlike a block's)
      --  centred on the 16px line starting at Top, left to right.
      View_W : Adi.Core.Pixel_Type := 600.0;
      Clicks : Natural := 0;

      procedure On_Link_Click
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         Href : String)
      is
         pragma Unreferenced (Self, Href);
      begin
         Clicks := Clicks + 1;
      end On_Link_Click;

      procedure Click (X, Y : Adi.Core.Pixel_Type) is
      begin
         Adi.Widget.On_Mouse_Down
           (+W, X => X, Y => Y, Button => Adi.Core.Left_Button, Clicks => 1);
         Adi.Widget.On_Mouse_Up (+W, X => X, Y => Y, Button => Adi.Core.Left_Button);
      end Click;

      type Rect_Array is array (1 .. 8) of Adi.Core.Rectangle;
      Boxes : Rect_Array;
      Box_Count : Natural := 0;

      procedure Find_Boxes (Top : Adi.Core.Pixel_Type) is
      begin
         Box_Count := 0;
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            declare
               It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, I);
               G  : constant Adi.Core.Rectangle := It.Geometry;
            begin
               if Adi.Widget."=" (It.Kind, Adi.Widget.Panel_Item)
                 and then G.Width < View_W
                 and then G.Y + G.Height / 2.0 >= Top
                 and then G.Y + G.Height / 2.0 < Top + 16.0
                 and then Box_Count < Boxes'Last
               then
                  Box_Count := Box_Count + 1;
                  Boxes (Box_Count) := G;
               end if;
            end;
         end loop;
      end Find_Boxes;

      procedure Load (Markup : String) is
      begin
         Adi.Widget.Html_View.Set_HTML
           (W, "<style>body { font-size: 16px; line-height: 1.0; } p { margin: 0; }</style>"
               & Markup);
         Adi.Widget.Build_Items (+W);
      end Load;
   begin
      Put_Line ("Test: inline boxes");
      Adi.Widget.Html_View.Connect_Link_Click (W, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));

      Load ("<p>ab<span style='padding: 0 10px; background-color: red'>cd</span>ef</p>"
            & "<p>gh<span style='padding: 5px 10px; background-color: red'>ij</span></p>");
      Expect ("left padding takes room before the content",
              Geom ("cd").X, Geom ("ab").X + Geom ("ab").Width + 10.0);
      Expect ("right padding takes room after it",
              Geom ("ef").X, Geom ("cd").X + Geom ("cd").Width + 10.0);
      Expect ("vertical padding leaves the line height alone", Geom ("ij").Height, 16.0);
      Find_Boxes (Geom ("cd").Y);
      Assert (Box_Count = 1, "one box on the first line:" & Box_Count'Image);
      if Box_Count = 1 then
         Expect ("the box starts at the left padding", Boxes (1).X, Geom ("cd").X - 10.0);
         Expect ("and ends past the right padding", Boxes (1).Width, Geom ("cd").Width + 20.0);
         declare
            Plain : constant Adi.Core.Rectangle := Boxes (1);
         begin
            Find_Boxes (Geom ("ij").Y);
            Assert (Box_Count = 1, "one box on the second line");
            if Box_Count = 1 then
               Expect ("vertical padding grows the box", Boxes (1).Height, Plain.Height + 10.0);
               Expect ("about the same baseline", Boxes (1).Y + 5.0 - Geom ("ij").Y,
                       Plain.Y - Geom ("cd").Y);
            end if;
         end;
      end if;

      --  Items draw in order, so a box comes before what it holds.
      declare
         Text_Index : constant Natural := Find_Text_Item_Index (W, "ij");
         Box_Index  : Natural := 0;
      begin
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            if Adi.Widget."=" (Adi.Widget.Get_Item (+W, I).Kind, Adi.Widget.Panel_Item)
              and then Adi.Widget.Get_Item (+W, I).Geometry.Width < View_W
              and then abs (Adi.Widget.Get_Item (+W, I).Geometry.X
                            - (Geom ("ij").X - 10.0)) < 0.01
            then
               Box_Index := I;
            end if;
         end loop;
         Assert (Box_Index > 0 and then Box_Index < Text_Index,
                 "the box is drawn beneath its text:" & Box_Index'Image & Text_Index'Image);
      end;

      --  A block inside a box splits it: the block's lines are not in it,
      --  the box's edges are on lines of their own before and after.
      Load ("<span style='padding: 0 7px; background-color: red'><p>inblock</p></span>");
      Find_Boxes (Geom ("inblock").Y);
      Assert (Box_Count = 0, "the block's line is not in the box");
      Find_Boxes (Geom ("inblock").Y - 16.0);
      Assert (Box_Count = 1 and then abs (Boxes (1).Width - 7.0) < 0.01,
              "the start edge sits on the line before");
      Find_Boxes (Geom ("inblock").Y + 16.0);
      Assert (Box_Count = 1 and then abs (Boxes (1).Width - 7.0) < 0.01,
              "the end edge sits on the line after");

      --  Nested boxes draw outer first, the inner inside the outer.
      Load ("<p><span style='padding: 0 6px; background-color: red'>out "
            & "<span style='padding: 0 3px; background-color: blue'>in</span></span></p>");
      Find_Boxes (Geom ("in").Y);
      Assert (Box_Count = 2, "two nested boxes");
      if Box_Count = 2 then
         Assert (Boxes (1).X < Boxes (2).X
                 and then Boxes (1).X + Boxes (1).Width > Boxes (2).X + Boxes (2).Width,
                 "the outer box, drawn first, holds the inner");
         Expect ("the inner box is padded", Boxes (2).X, Geom ("in").X - 3.0);
      end if;

      --  Centred text moves its boxes with it.
      Load ("<p style='text-align: center'><span style='padding: 0 5px; "
            & "background-color: red'>mid</span></p>");
      Find_Boxes (Geom ("mid").Y);
      Assert (Box_Count = 1 and then abs (Boxes (1).X - (Geom ("mid").X - 5.0)) < 0.01,
              "a centred box stays around its text");

      --  A link's padding and border are in its hit area, drawn or not.
      Load ("<p><a href='#b' style='padding: 0 12px; border-left: 3px solid red'>btn</a></p>"
            & "<p><a href='#c' style='padding: 4px 12px; background-color: red'>btn2</a></p>"
            & "<p><span style='padding: 0 12px'>plain</span></p>"
            & "<p><a href='#d' style='padding: 0 12px'>padonly</a></p>");
      Clicks := 0;
      Click (Geom ("btn").X - 6.0, Geom ("btn").Y + 8.0);
      Assert (Clicks = 1, "a link's padding is clickable");
      Click (Geom ("btn").X - 13.5, Geom ("btn").Y + 8.0);
      Assert (Clicks = 2, "and so is its border");
      Click (Geom ("btn2").X - 6.0, Geom ("btn2").Y + 8.0);
      Assert (Clicks = 3, "a drawn link box's padding is clickable");
      Click (Geom ("plain").X - 6.0, Geom ("plain").Y + 8.0);
      Assert (Clicks = 3, "padding outside any link is not");
      Click (Geom ("padonly").X - 6.0, Geom ("padonly").Y + 8.0);
      Assert (Clicks = 4, "a link with padding alone is clickable there");
      Find_Boxes (Geom ("padonly").Y);
      Assert (Box_Count = 0, "and draws no box");

      --  An empty element without edges leaves no item behind.
      declare
         Before : Natural;
      begin
         Load ("<p>q</p>");
         Before := Adi.Widget.Item_Count (+W);
         Load ("<p>q<span style='background-color: red'></span></p>");
         Assert (Adi.Widget.Item_Count (+W) = Before,
                 "an empty element with a background adds no item:"
                 & Before'Image & Adi.Widget.Item_Count (+W)'Image);
         Load ("<p><span style='background-color: red'><p>q</p></span></p>");
         Find_Boxes (Geom ("q").Y - 16.0);
         Assert (Box_Count = 0, "nor does one emptied by a block");
      end;

      Load ("<p>xx <span style='background-color: red'> yy</span></p>");
      Find_Boxes (Geom ("yy").Y);
      Assert (Box_Count = 1, "a background alone draws a box");
      if Box_Count = 1 then
         Expect ("the space before the element is outside its box", Boxes (1).X, Geom ("yy").X);
         Expect ("and is not doubled inside it", Boxes (1).Width, Geom ("yy").Width);
      end if;

      Load ("<p>aa<span style='margin: 0 20px'>bb</span>cc</p>");
      Expect ("a margin alone moves the content", Geom ("bb").X,
              Geom ("aa").X + Geom ("aa").Width + 20.0);
      Find_Boxes (Geom ("bb").Y);
      Assert (Box_Count = 0, "a margin alone draws no box");

      View_W := 200.0;
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => View_W, Height => 900.0));
      Load ("<p>start <span style='border: 2px solid red; padding: 0 4px'>"
            & "one two three four five six seven</span></p>");
      declare
         First_Line : constant Adi.Core.Rectangle := Geom ("one");
         Last_Line  : constant Adi.Core.Rectangle := Geom ("seven");
      begin
         Assert (Last_Line.Y > First_Line.Y, "the element wraps");
         Find_Boxes (First_Line.Y);
         Assert (Box_Count = 1, "one fragment on the first line");
         if Box_Count = 1 then
            Expect ("the first fragment has the left edge", Boxes (1).X, First_Line.X - 6.0);
         end if;
         Find_Boxes (Last_Line.Y);
         Assert (Box_Count = 1, "one fragment on the last line");
         if Box_Count = 1 then
            Expect ("a later fragment starts at the line's start", Boxes (1).X, 0.0);
            Expect ("and has the right edge", Boxes (1).X + Boxes (1).Width,
                    Last_Line.X + Last_Line.Width + 6.0);
         end if;
      end;

      --  An element whose first word does not fit goes to the next line
      --  with its start edge.
      Load ("<p>aaaaaaaaaaaaaaaaaaa "
            & "<span style='padding: 0 10px; background-color: red'>wrapped</span></p>");
      Assert (Geom ("wrapped").Y > Geom ("aaaa").Y, "the element's word wraps");
      Expect ("its start padding comes with it", Geom ("wrapped").X, 10.0);
      Find_Boxes (Geom ("aaaa").Y);
      Assert (Box_Count = 0, "no edge is left on the line before");
      Find_Boxes (Geom ("wrapped").Y);
      Assert (Box_Count = 1 and then Boxes (1).X = 0.0
              and then abs (Boxes (1).Width - (Geom ("wrapped").Width + 20.0)) < 0.01,
              "one whole box on the new line");
      New_Line;
   end Test_Inline_Boxes;

   --  position: relative moves an element after the flow placed it;
   --  absolute takes it out of the flow, against its containing block.
   procedure Test_Positioning is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Clicked : Unbounded_String;

      procedure On_Link_Click
        (Self : Adi.Widget.Html_View.Html_View_Handle;
         Href : String)
      is
         pragma Unreferenced (Self);
      begin
         Clicked := To_Unbounded_String (Href);
      end On_Link_Click;

      function Geom (Needle : String) return Adi.Core.Rectangle is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry
                 else (0.0, 0.0, 0.0, 0.0));
      end Geom;

      procedure Expect (What : String; Got, Want : Adi.Core.Pixel_Type) is
      begin
         Assert (abs (Got - Want) < 0.01, What & ":" & Got'Image & " /=" & Want'Image);
      end Expect;

      procedure Load (Markup : String) is
      begin
         Adi.Widget.Html_View.Set_HTML
           (W, "<style>body { font-size: 16px; line-height: 1.0; } p { margin: 0; }</style>"
               & Markup);
         Adi.Widget.Build_Items (+W);
      end Load;
   begin
      Put_Line ("Test: positioning");
      Adi.Widget.Html_View.Connect_Link_Click (W, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));

      Load ("<p>before</p><p style='position: relative; left: 20px; top: 5px'>moved</p>"
            & "<p style='position: relative; right: 10px; bottom: 4px'>back</p><p>after</p>"
            & "<p>aa<span style='position: relative; top: -3px'>up</span>bb</p>");
      Expect ("left moves right", Geom ("moved").X, 20.0);
      Expect ("top moves down", Geom ("moved").Y, 16.0 + 5.0);
      Expect ("right moves left", Geom ("back").X, -10.0);
      Expect ("bottom moves up", Geom ("back").Y, 32.0 - 4.0);
      Expect ("the flow is where it was", Geom ("after").Y, 48.0);
      Expect ("an inline element moves alone", Geom ("up").Y, Geom ("aa").Y - 3.0);
      Expect ("and its neighbours stay", Geom ("bb").X, Geom ("up").X + Geom ("up").Width);

      Load ("<p>first</p><div style='position: absolute; left: 100px; top: 50px'>abs</div>"
            & "<p>second</p>");
      Expect ("absolute left", Geom ("abs").X, 100.0);
      Expect ("absolute top", Geom ("abs").Y, 50.0);
      Expect ("out of the flow", Geom ("second").Y, 16.0);
      Assert (Find_Text_Item_Index (W, "abs") > Find_Text_Item_Index (W, "second"),
              "drawn after the flow, over it");

      Load ("<p>top</p><div style='position: relative; margin-left: 40px; padding: 10px; "
            & "height: 100px'><p>in</p><div style='position: absolute; right: 0; bottom: 0; "
            & "width: 50px'>corner</div></div>");
      Expect ("right: 0 against the positioned block's padding box",
              Geom ("corner").X, 40.0 + 560.0 - 50.0);
      Expect ("bottom: 0 against it", Geom ("corner").Y, Geom ("in").Y - 10.0 + 100.0 - 16.0);

      Load ("<p>xx</p><div style='position: absolute'>static</div>"
            & "<p>aa<span style='position: absolute'>inl</span></p>");
      Expect ("a block's static place is below", Geom ("static").Y, 16.0);
      Expect ("at the line's start", Geom ("static").X, 0.0);
      Expect ("an inline's static place is beside", Geom ("inl").X,
              Geom ("aa").X + Geom ("aa").Width);

      Load ("<div style='position: absolute; left: 10px; right: 20px; top: 0; "
            & "text-align: right'>span</div>");
      Expect ("left and right give the width", Geom ("span").X + Geom ("span").Width, 580.0);

      Load ("<div style='position: absolute; left: 100px; top: 200px; width: 200px; "
            & "height: 100px'><div style='position: absolute; right: 0; top: 10px'>nested</div></div>");
      Expect ("an absolute element contains its own", Geom ("nested").X + Geom ("nested").Width,
              300.0);
      Expect ("nested top", Geom ("nested").Y, 210.0);

      Load ("<div style='position: relative; left: 30px; top: 30px'><p>rel</p>"
            & "<div style='position: absolute; left: 0; top: 20px'>inrel</div></div>");
      Expect ("a relative block moves what it positions", Geom ("inrel").X, 30.0);
      Expect ("both ways", Geom ("inrel").Y, 30.0 + 20.0);

      Load ("<div style='display: flex'><div>f1</div>"
            & "<div style='position: absolute; left: 300px; top: 0'>fa</div><div>f2</div></div>");
      Expect ("an absolute flex child is no item", Geom ("f2").X, Geom ("f1").Width);
      Expect ("and is placed by its insets", Geom ("fa").X, 300.0);

      Load ("<div style='position: relative; margin-left: 50px'><p>host</p>"
            & "<div style='position: fixed; left: 5px; top: 300px'>fixed</div></div>");
      Expect ("fixed is against the view, not a positioned block", Geom ("fixed").X, 5.0);

      Load ("<p style='margin-bottom: 20px'>above</p><div style='position: absolute'>gap</div>"
            & "<p style='margin-bottom: 20px'>above2</p><div style='display: flex'>"
            & "<span style='position: absolute'>flexgap</span><span>f</span></div>");
      Expect ("a static place follows the collapsed margin", Geom ("gap").Y, 16.0 + 20.0);
      Expect ("in a flex container too", Geom ("flexgap").Y, Geom ("f").Y);

      Load ("<div style='display: flex; height: 100px'><div style='position: relative'>"
            & "<p>item</p><div style='position: absolute; bottom: 0; left: 0'>low</div></div></div>");
      Expect ("a stretched flex item contains at its stretched height", Geom ("low").Y, 100.0 - 16.0);

      Load ("<span style='background-color: red'><div style='position: relative; left: 5px; "
            & "background-color: blue'>shifted</div></span>");
      declare
         Moved : Natural := 0;
      begin
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            if Adi.Widget."=" (Adi.Widget.Get_Item (+W, I).Kind, Adi.Widget.Panel_Item)
              and then Adi.Widget.Get_Item (+W, I).Geometry.Width = 600.0
              and then Adi.Widget.Get_Item (+W, I).Geometry.X = 5.0
            then
               Moved := Moved + 1;
            end if;
         end loop;
         Assert (Moved = 1, "a relative block's panel moves with its text:" & Moved'Image);
         Expect ("its text", Geom ("shifted").X, 5.0);
      end;

      Load ("<p><a href='#box' style='position: relative; top: 30px; padding: 0 12px; "
            & "background-color: gray'>boxed</a></p>");
      Clicked := Null_Unbounded_String;
      Adi.Widget.On_Mouse_Down
        (+W, X => Geom ("boxed").X - 6.0, Y => Geom ("boxed").Y + 8.0,
         Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.On_Mouse_Up
        (+W, X => Geom ("boxed").X - 6.0, Y => Geom ("boxed").Y + 8.0,
         Button => Adi.Core.Left_Button);
      Assert (To_String (Clicked) = "#box", "a moved link's padding moves with it");

      Load ("<p>flow</p><div style='position: absolute; top: 700px'>far</div>");
      Expect ("an absolute does not size the document", Adi.Widget.Get_Preferred_Size (+W).Height,
              16.0);

      Load ("<p><a href='#under'>underneath</a></p>"
            & "<a href='#over' style='position: absolute; left: 0; top: 0'>OVERLAY</a>");
      Adi.Widget.On_Mouse_Down
        (+W, X => 5.0, Y => 8.0, Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.On_Mouse_Up (+W, X => 5.0, Y => 8.0, Button => Adi.Core.Left_Button);
      Assert (To_String (Clicked) = "#over", "the link on top takes the click: " & To_String (Clicked));
      New_Line;
   end Test_Positioning;

   --  overflow: hidden clips a block's content to its padding box, per
   --  item, and keeps hidden links from taking clicks.
   procedure Test_Overflow_Clip is
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

      function Get (Needle : String) return Adi.Widget.Item is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return Adi.Widget.Get_Item (+W, (if Idx > 0 then Positive (Idx) else 1));
      end Get;

      procedure Expect (What : String; Got, Want : Adi.Core.Pixel_Type) is
      begin
         Assert (abs (Got - Want) < 0.01, What & ":" & Got'Image & " /=" & Want'Image);
      end Expect;

      procedure Load (Markup : String) is
      begin
         Adi.Widget.Html_View.Set_HTML
           (W, "<style>body { font-size: 16px; line-height: 1.0; } p { margin: 0; }</style>"
               & Markup);
         Adi.Widget.Build_Items (+W);
      end Load;
   begin
      Put_Line ("Test: overflow clip");
      Adi.Widget.Html_View.Connect_Link_Click (W, On_Link_Click'Unrestricted_Access);
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));

      Load ("<p>above</p><div style='height: 30px; overflow: hidden; padding: 5px; "
            & "border: 2px solid black'><p>one</p><p><a href='#x'>two</a></p><p>three</p></div>"
            & "<p>below</p>");
      declare
         Three : constant Adi.Widget.Item := Get ("three");
      begin
         Assert (Three.Has_Clip, "an item inside the block is clipped");
         Expect ("to the padding box's left", Three.Clip.X, 2.0);
         Expect ("top", Three.Clip.Y, 16.0 + 2.0);
         Expect ("width", Three.Clip.Width, 600.0 - 4.0);
         Expect ("height", Three.Clip.Height, 30.0 - 4.0);
      end;
      Assert (not Get ("below").Has_Clip, "what follows the block is not clipped");
      Assert (not Get ("above").Has_Clip, "nor what precedes it");

      --  "two" runs from 39 to 55, across the padding box's bottom edge
      --  at 44: a click above the edge takes, one below it does not.
      Expect ("the link line straddles the edge", Get ("two").Geometry.Y, 39.0);
      Clicks := 0;
      Adi.Widget.On_Mouse_Down
        (+W, X => Get ("two").Geometry.X + 4.0, Y => 50.0,
         Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.On_Mouse_Up
        (+W, X => Get ("two").Geometry.X + 4.0, Y => 50.0, Button => Adi.Core.Left_Button);
      Assert (Clicks = 0, "a link where it is clipped away takes no click");
      Adi.Widget.On_Mouse_Down
        (+W, X => Get ("two").Geometry.X + 4.0, Y => 42.0,
         Button => Adi.Core.Left_Button, Clicks => 1);
      Adi.Widget.On_Mouse_Up
        (+W, X => Get ("two").Geometry.X + 4.0, Y => 42.0, Button => Adi.Core.Left_Button);
      Assert (Clicks = 1, "where it shows, it does");

      Load ("<div style='width: 100px; overflow-x: hidden'><p style='white-space: nowrap'>"
            & "wide line of text that runs on</p></div>");
      declare
         Wide : constant Adi.Widget.Item := Get ("wide");
      begin
         Assert (Wide.Has_Clip, "overflow-x clips");
         Expect ("across", Wide.Clip.Width, 100.0);
         Assert (Wide.Clip.Height > 1.0E6, "but not down");
      end;

      Load ("<div style='height: 40px; padding-top: 30px; overflow: hidden'>"
            & "<div style='height: 20px; overflow: hidden'><p>nested</p></div></div>");
      Expect ("nested clips meet", Get ("nested").Clip.Y, 30.0);
      Expect ("at the outer's bottom", Get ("nested").Clip.Height, 10.0);

      Load ("<div style='position: relative; top: 50px; height: 20px; overflow: hidden'>"
            & "<p style='position: relative; left: 7px'>moved</p></div>");
      Expect ("a moved block's clip moves with it", Get ("moved").Clip.Y, 50.0);
      Expect ("a moved child keeps its parent's clip", Get ("moved").Clip.X, 0.0);
      Expect ("while it moves", Get ("moved").Geometry.X, 7.0);

      --  An absolute element is clipped by the clips around its
      --  containing block, not by others between it and the flow.
      Load ("<div style='position: relative; height: 20px; overflow: hidden'>"
            & "<span style='position: absolute; top: 50px'>held</span></div>"
            & "<div style='height: 20px; overflow: hidden'>"
            & "<span style='position: absolute; top: 200px'>free</span></div>");
      Assert (Get ("held").Has_Clip, "its containing block clips it");
      Expect ("to the block's box", Get ("held").Clip.Height, 20.0);
      Assert (not Get ("free").Has_Clip, "a clip around it but not its containing block does not");

      Load ("<div style='position: relative; height: 20px; overflow-y: hidden'>"
            & "<p>tall</p><p>cut</p></div>");
      Assert (Get ("cut").Clip.Width > 1.0E6, "overflow-y does not clip across");
      Expect ("only down", Get ("cut").Clip.Height, 20.0);
      New_Line;
   end Test_Overflow_Clip;

   --  vertical-align moves a run off the baseline, or to the line's top
   --  or bottom, and sub and sup default to it. Runs of one font size
   --  compare by their text offsets alone.
   procedure Test_Vertical_Align is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Get (Needle : String) return Adi.Widget.Item is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return Adi.Widget.Get_Item (+W, (if Idx > 0 then Positive (Idx) else 1));
      end Get;

      --  Where the run's glyphs start down the line.
      function Top_Of (Needle : String) return Adi.Core.Pixel_Type is
        (Get (Needle).Geometry.Y + Get (Needle).Text_Offset_Y);

      procedure Expect (What : String; Got, Want : Adi.Core.Pixel_Type) is
      begin
         Assert (abs (Got - Want) < 0.01, What & ":" & Got'Image & " /=" & Want'Image);
      end Expect;

      procedure Load (Markup : String) is
      begin
         Adi.Widget.Html_View.Set_HTML
           (W, "<style>body { font-size: 16px; line-height: 1.0; } p { margin: 0; } "
               & "sub, sup { font-size: 16px; }</style>" & Markup);
         Adi.Widget.Build_Items (+W);
      end Load;
   begin
      Put_Line ("Test: vertical-align");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));

      Load ("<p>xa<sup>up</sup></p><p>xb<sub>down</sub></p>"
            & "<p>xc<span style='vertical-align: super'>css</span></p>"
            & "<p>xd<sup><a href='#n'>inner</a></sup></p>"
            & "<p style='vertical-align: super'>block</p><p>plain</p>");
      Expect ("sup raises by half its font", Top_Of ("up"), Top_Of ("xa") - 8.0);
      Expect ("sub lowers by three tenths", Top_Of ("down"), Top_Of ("xb") + 4.8);
      Expect ("vertical-align: super from a stylesheet", Top_Of ("css"), Top_Of ("xc") - 8.0);
      Expect ("what is inside a sup rises with it", Top_Of ("inner"), Top_Of ("xd") - 8.0);
      Expect ("a block's own vertical-align does not move its text",
              Top_Of ("block") - Get ("block").Geometry.Y,
              Top_Of ("plain") - Get ("plain").Geometry.Y);
      Assert (Get ("xa").Geometry.Height > 16.0, "a raised run grows its line");

      Load ("<p>big<span style='font-size: 40px'>BIG</span>"
            & "<span style='vertical-align: top'>tt</span>"
            & "<span style='vertical-align: bottom'>bb</span>"
            & "<span style='vertical-align: text-top; font-size: 8px'>xt</span></p>");
      Expect ("top sits at the line's top", Get ("tt").Text_Offset_Y, 0.0);
      Assert (Get ("bb").Text_Offset_Y > Get ("big").Text_Offset_Y,
              "bottom sits below the baseline's runs");
      Expect ("text-top lifts a small run to its parent's font top",
              Get ("xt").Text_Offset_Y, Get ("big").Text_Offset_Y);

      --  A top-aligned element's box sits against the line's top with
      --  its text, not on the baseline.
      Load ("<p>xx<span style='font-size: 40px'>BIG</span>"
            & "<span style='vertical-align: top; background-color: red'>tb</span></p>");
      declare
         Found : Boolean := False;
      begin
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            declare
               It : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, I);
            begin
               if Adi.Widget."=" (It.Kind, Adi.Widget.Panel_Item)
                 and then It.Geometry.Width < 600.0
                 and then abs (It.Geometry.X - Get ("tb").Geometry.X) < 0.01
               then
                  Found := True;
                  Expect ("the box's top is the line's", It.Geometry.Y, Get ("tb").Geometry.Y);
               end if;
            end;
         end loop;
         Assert (Found, "the top-aligned element draws its box");
      end;
      New_Line;
   end Test_Vertical_Align;

   --  Tables: cells on a grid, columns shared by content, rows as tall
   --  as their cells, implied end tags.
   procedure Test_Tables is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Geom (Needle : String) return Adi.Core.Rectangle is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry
                 else (0.0, 0.0, 0.0, 0.0));
      end Geom;

      procedure Expect (What : String; Got, Want : Adi.Core.Pixel_Type) is
      begin
         Assert (abs (Got - Want) < 0.01, What & ":" & Got'Image & " /=" & Want'Image);
      end Expect;

      procedure Load (Markup : String) is
      begin
         Adi.Widget.Html_View.Set_HTML
           (W, "<style>body { font-size: 16px; line-height: 1.0; } p { margin: 0; } "
               & "td, th { padding: 0; }</style>" & Markup);
         Adi.Widget.Build_Items (+W);
      end Load;
   begin
      Put_Line ("Test: tables");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 900.0));

      Load ("<table><tr><td>aa</td><td>bbbb</td></tr><tr><td>cccccc</td><td>d</td></tr></table>"
            & "<p>after</p>");
      Expect ("cells sit side by side", Geom ("bbbb").Y, Geom ("aa").Y);
      Expect ("rows stack", Geom ("cccccc").Y, Geom ("aa").Y + 16.0);
      Expect ("a column is as wide as its widest cell", Geom ("bbbb").X, Geom ("cccccc").Width);
      Expect ("columns line up across rows", Geom ("d").X, Geom ("bbbb").X);
      Expect ("the table ends after its rows", Geom ("after").Y, 32.0);

      Load ("<table><tr><td>x<td>y<tr><td>z<td>w</table>");
      Expect ("an open cell closes at the next", Geom ("y").Y, Geom ("x").Y);
      Expect ("an open row closes at the next", Geom ("z").Y, Geom ("x").Y + 16.0);
      Expect ("and its cells line up", Geom ("w").X, Geom ("y").X);

      Load ("<table><tr><td colspan='2'>wide span here</td><td>ee</td></tr>"
            & "<tr><td>ff</td><td>gg</td><td>hh</td></tr></table>");
      Assert (Geom ("ee").X >= Geom ("wide").X + Geom ("wide").Width + Geom ("span").Width,
              "a cell after a colspan sits past it");
      Expect ("the spanned columns hold the span", Geom ("hh").X, Geom ("ee").X);

      Load ("<table><tr><td rowspan='2'>tall</td><td>r1</td></tr><tr><td>r2</td></tr></table>");
      Expect ("a cell beside a rowspan takes the next column", Geom ("r2").X, Geom ("r1").X);
      Expect ("a rowspan cell centres across its rows", Geom ("tall").Y, Geom ("r1").Y + 8.0);

      Load ("<table style='width: 100%'><tr><td style='width: 25%'>q</td><td>r</td></tr></table>");
      Expect ("a percentage cell width of the table", Geom ("r").X, 150.0);

      Load ("<table><tr><td style='vertical-align: top'>t</td><td style='vertical-align: bottom'>"
            & "b</td><td>m</td><td>1<br>2<br>3</td></tr></table>");
      Expect ("top", Geom ("t").Y, 0.0);
      Expect ("bottom", Geom ("b").Y, 32.0);
      Expect ("middle by default", Geom ("m").Y, 16.0);

      Load ("<table cellspacing='5'><tr><td>s1</td><td>s2</td></tr></table>");
      Expect ("cellspacing before the first cell", Geom ("s1").X, 5.0);
      Expect ("and between cells", Geom ("s2").X, 5.0 + Geom ("s1").Width + 5.0);

      Load ("<table><caption>cap</caption><tr><td>under</td></tr></table>");
      Expect ("the caption is above the rows", Geom ("under").Y, 16.0);

      Load ("<table style='margin: 0 auto'><tr><td>centred</td></tr></table>");
      Expect ("an auto-width table shrinks and centres", Geom ("centred").X,
              (600.0 - Geom ("centred").Width) / 2.0);

      Load ("<table><tr><td><table><tr><td>in1</td><td>in2</td></tr></table></td>"
            & "<td>out</td></tr></table>");
      Expect ("a nested table lays out in its cell", Geom ("in2").X, Geom ("in1").Width);
      Expect ("and its cell is as wide as it", Geom ("out").X,
              Geom ("in1").Width + Geom ("in2").Width);

      --  A middle-aligned cell's panel fills its row; its content, its
      --  clip and its padding move with the alignment.
      Load ("<table><tr><td style='padding: 4px; overflow: hidden; margin: 30px'>mid</td>"
            & "<td>1<br>2<br>3</td></tr></table>");
      Expect ("cell margins are ignored", Geom ("mid").X, 4.0);
      Expect ("content centres in the padded cell", Geom ("mid").Y, (48.0 - 24.0) / 2.0 + 4.0);
      Assert (Adi.Widget.Get_Item (+W, Find_Text_Item_Index (W, "mid")).Has_Clip,
              "the cell clips its content");
      Expect ("to its whole box", Adi.Widget.Get_Item (+W, Find_Text_Item_Index (W, "mid")).Clip.Y,
              0.0);
      Expect ("all its rows' height", Adi.Widget.Get_Item (+W, Find_Text_Item_Index (W, "mid")).Clip.Height,
              48.0);

      Load ("<table style='margin: 0 auto'><caption style='margin-bottom: 10px'>"
            & "unbreakablecaptionword</caption><tr><td style='text-align: right'>zz</td></tr></table>");
      Expect ("a caption's margin stays below it", Geom ("zz").Y, 26.0);
      Expect ("a caption widens a shrunk table", Geom ("zz").X + Geom ("zz").Width,
              Geom ("unbreakablecaptionword").X + Geom ("unbreakablecaptionword").Width);

      Load ("<table><tr><td rowspan='2'>rs</td><td>t1</td><td>t2</td></tr>"
            & "<tr><td colspan='2'>both</td></tr></table>");
      Expect ("a colspan beside a rowspan starts past it", Geom ("both").X, Geom ("t1").X);

      Load ("<table><tr><td colspan='100000'>huge</td><td>after</td></tr>"
            & "<tr><td>row2</td></tr></table>");
      Assert (Geom ("after").X > 0.0, "a huge colspan is bounded");

      Load ("<ul><li>outer<table><tr><td><li>inner</li></td></tr></table> tail</li></ul>");
      Assert (Geom ("tail").Y > Geom ("inner").Y,
              "an li in a cell does not close the li around the table");

      Load ("<table><thead><tr><th>head</th></tr></thead><tr style='display: none'><td>gone</td></tr>"
            & "<tfoot><tr><td>foot</td></tr></tfoot><tr><td>body</td></tr></table>");
      Assert (Find_Text_Item_Index (W, "gone") = 0, "a hidden row is not laid out");
      Assert (Geom ("foot").Y > Geom ("head").Y and then Geom ("body").Y > Geom ("foot").Y,
              "rows keep document order, tfoot included");

      Load ("<table><tr style='background-color: red'><td>bg</td></tr></table>");
      declare
         Row_Panels : Natural := 0;
      begin
         for I in 2 .. Adi.Widget.Item_Count (+W) loop
            if Adi.Widget."=" (Adi.Widget.Get_Item (+W, I).Kind, Adi.Widget.Panel_Item)
              and then Adi.Widget.Get_Item (+W, I).Has_Style_Override
              and then Adi.CSS_Styles."/="
                (Ref (Adi.Widget.Get_Item (+W, I).Style_Override).Background_Color,
                 Adi.CSS_Styles.Default_Background)
            then
               Row_Panels := Row_Panels + 1;
            end if;
         end loop;
         Assert (Row_Panels = 1, "a row's background is drawn once:" & Row_Panels'Image);
      end;
      New_Line;
   end Test_Tables;

   --  A block's content is inset by the border it draws, and at a content
   --  scale the drawn width follows it.
   procedure Test_Border_Insets_At_Scale is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
   begin
      Put_Line ("Test: borders inset content and scale with it");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 1200.0, Height => 600.0));
      Adi.Widget.Html_View.Set_Content_Scale (W, 2.0);
      Adi.Widget.Html_View.Set_HTML
        (W, "<div style='border: 10px solid black; padding: 5px'>inset</div>");
      Adi.Widget.Build_Items (+W);

      declare
         Idx : constant Natural := Find_Text_Item_Index (W, "inset");
      begin
         Assert (Idx > 0, "the text exists");
         if Idx > 0 then
            declare
               Text  : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx));
               Panel : constant Adi.Widget.Item := Adi.Widget.Get_Item (+W, Positive (Idx) - 1);
               Edges : constant Adi.Layout_Util.Edge_Pixels :=
                 Adi.Layout_Util.Get_Border_Width_Px (Ref (Panel.Computed_Style).all);
            begin
               Assert (Nearly_Equal (Text.Geometry.X - Panel.Geometry.X, 30.0)
                       and then Nearly_Equal (Text.Geometry.Y - Panel.Geometry.Y, 30.0),
                       "a 10px border and 5px padding at scale 2 inset the text by 30:"
                       & Float'Image (Float (Text.Geometry.X - Panel.Geometry.X)));
               Assert (Nearly_Equal (Edges.Left, 20.0) and then Nearly_Equal (Edges.Bottom, 20.0),
                       "the panel draws its 10px border 20 wide at scale 2:"
                       & Float'Image (Float (Edges.Left)));
            end;
         end if;
      end;
      New_Line;
   end Test_Border_Insets_At_Scale;

   --  Character references decode to UTF-8: the HTML 4 names, numeric
   --  references to any code point, and what HTML maps the rest to.
   procedure Test_Character_References is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function U (Code : Natural) return String is
        (WW_Encode.Encode
           (Item => [1 => Wide_Wide_Character'Val (Code)], Output_BOM => False));

      --  Decodes one reference between brackets, so it lands in one text
      --  item, and compares what was drawn.
      procedure Check (Reference, Expected, What : String) is
      begin
         Adi.Widget.Html_View.Set_HTML (W, "<p>[" & Reference & "]</p>");
         Adi.Widget.Build_Items (+W);
         declare
            Idx : constant Natural := Find_Text_Item_Index (W, "[");
            Got : constant String :=
              (if Idx = 0 then "<none>"
               else To_String (Adi.Widget.Get_Item (+W, Positive (Idx)).Text_Content));
         begin
            Assert (Got = "[" & Expected & "]", What & ": got " & Got);
         end;
      end Check;
   begin
      Put_Line ("Test: character references");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 200.0));

      Check ("&amp;", "&", "amp");
      Check ("&AMP;", "&", "the XML five match in any case");
      Check ("&nbsp;", U (16#A0#), "nbsp is a no-break space");
      Check ("&copy;", U (16#A9#), "copy");
      Check ("&eacute;", U (16#E9#), "eacute");
      Check ("&Eacute;", U (16#C9#), "Eacute is a different character");
      Check ("&mdash;", U (16#2014#), "mdash");
      Check ("&hellip;", U (16#2026#), "hellip");
      Check ("&euro;", U (16#20AC#), "euro");
      Check ("&#233;", U (16#E9#), "a decimal reference past 127 is UTF-8, not a raw byte");
      Check ("&#8364;", U (16#20AC#), "a decimal reference past 255");
      Check ("&#x20AC;", U (16#20AC#), "a hex reference");
      Check ("&#X1F600;", U (16#1F600#), "a reference outside the basic plane");
      Check ("&#150;", U (16#2013#), "128 .. 159 map as windows-1252 does");
      Check ("&#0;", U (16#FFFD#), "zero is the replacement character");
      Check ("&#xD800;", U (16#FFFD#), "a surrogate is the replacement character");
      Check ("&#99999999;", U (16#FFFD#), "past U+10FFFF is the replacement character");
      Check ("&bogus;", "&bogus;", "an unknown name stays as written");
      Check ("&Copy;", "&Copy;", "a name in the wrong case is unknown");
      Check ("&#x;", "&#x;", "a reference with no digits stays as written");
      Check ("&#;", "&#;", "a bare # stays as written");
      Check ("&lArr;", U (16#21D0#), "lArr");
      Check ("&larr;", U (16#2190#), "larr is a different arrow");
      Check ("&Delta;", U (16#394#), "Delta");
      Check ("&delta;", U (16#3B4#), "delta");
      Check ("&#x41;", "A", "a lowercase x");
      Check ("&#00000000065;", "A", "leading zeros");
      Check ("&#128;", U (16#20AC#), "128 is the euro sign");
      Check ("&#159;", U (16#178#), "159 is Y with diaeresis");
      Check ("&#x10FFFF;", U (16#10FFFF#), "the last code point");
      Check ("&#x110000;", U (16#FFFD#), "one past it");
      Check ("&#xDFFF;", U (16#FFFD#), "the last surrogate");
      Check ("&#99999999999999999999;", U (16#FFFD#), "a number past 64 bits");
      Check ("&&amp;", "&&", "a bare ampersand before a reference");
      Check ("&amp", "&amp", "a reference without its semicolon stays as written");
      Check ("&lt;b&gt;", "<b>", "decoded angle brackets are text, not a tag");
      Check ("a&nbsp;&nbsp;b", "a" & U (16#A0#) & U (16#A0#) & "b",
             "no-break spaces neither collapse nor break the word");

      --  Attribute values are decoded too.
      Adi.Widget.Html_View.Set_HTML
        (W, "<p><img src='missing.png' alt='Caf&eacute; &amp; more'></p>");
      Adi.Widget.Build_Items (+W);
      declare
         Idx : constant Natural := Find_Text_Item_Index (W, "Caf");
      begin
         Assert (Idx > 0
                 and then To_String (Adi.Widget.Get_Item (+W, Positive (Idx)).Text_Content)
                          = "Caf" & U (16#E9#) & " & more",
                 "an img alt attribute is decoded");
      end;
      New_Line;
   end Test_Character_References;

   --  An outside marker sits on its item's first line box, even when a
   --  block opens the item.
   procedure Test_Marker_Beside_Opening_Block is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Marker, Text : Natural;
   begin
      Put_Line ("Test: an outside marker beside a block that opens its item");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 300.0));
      Adi.Widget.Html_View.Set_HTML
        (W, "<style>p { margin: 0px; }</style>"
            & "<ol><li><p>first</p></li><li><div><p>nested</p></div></li></ol>");
      Adi.Widget.Build_Items (+W);

      Marker := Find_Text_Item_Index (W, "1.");
      Text := Find_Text_Item_Index (W, "first");
      Assert (Marker > 0 and then Text > 0
              and then Nearly_Equal (Adi.Widget.Get_Item (+W, Marker).Geometry.Y,
                                     Adi.Widget.Get_Item (+W, Text).Geometry.Y),
              "the marker is on the paragraph's first line");

      Marker := Find_Text_Item_Index (W, "2.");
      Text := Find_Text_Item_Index (W, "nested");
      Assert (Marker > 0 and then Text > 0
              and then Nearly_Equal (Adi.Widget.Get_Item (+W, Marker).Geometry.Y,
                                     Adi.Widget.Get_Item (+W, Text).Geometry.Y),
              "and on the first line of a paragraph nested deeper");
      New_Line;
   end Test_Marker_Beside_Opening_Block;

   --  One newline right after <pre> is dropped, as HTML parsing does;
   --  a second one is content.
   procedure Test_Pre_Leading_Newline is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      function Top_Of (Needle : String) return Adi.Core.Pixel_Type is
         Idx : constant Natural := Find_Text_Item_Index (W, Needle);
      begin
         Assert (Idx > 0, Needle & " exists");
         return (if Idx > 0 then Adi.Widget.Get_Item (+W, Positive (Idx)).Geometry.Y else -1.0);
      end Top_Of;
   begin
      Put_Line ("Test: a newline right after <pre> is dropped");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 300.0));

      Adi.Widget.Html_View.Set_HTML (W, "<pre>" & ASCII.LF & "one</pre>");
      Adi.Widget.Build_Items (+W);
      Assert (Nearly_Equal (Top_Of ("one"), 0.0), "the first line holds the text");

      Adi.Widget.Html_View.Set_HTML
        (W, "<pre>" & ASCII.CR & ASCII.LF & "crlf</pre>");
      Adi.Widget.Build_Items (+W);
      Assert (Nearly_Equal (Top_Of ("crlf"), 0.0), "a CR LF counts as one newline");

      Adi.Widget.Html_View.Set_HTML
        (W, "<pre>" & ASCII.LF & ASCII.LF & "two</pre>");
      Adi.Widget.Build_Items (+W);
      Assert (Top_Of ("two") > 1.0, "a second newline is kept");
      New_Line;
   end Test_Pre_Leading_Newline;

   --  An ordered list counts from its start attribute, an item's value
   --  resets the count, and both may be zero or negative.
   procedure Test_Ordered_List_Start is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;

      procedure Expect (Markup, Marker, What : String) is
      begin
         Adi.Widget.Html_View.Set_HTML (W, Markup);
         Adi.Widget.Build_Items (+W);
         Assert (Find_Text_Item_Index (W, Marker) > 0, What & ": no " & Marker);
      end Expect;
   begin
      Put_Line ("Test: ordered list start");
      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 600.0, Height => 300.0));
      Expect ("<ol start='5'><li>a</li><li>b</li></ol>", "6.", "start 5 then 6");
      Expect ("<ol start=' 3x'><li>a</li></ol>", "3.", "trailing text after the digits");
      Expect ("<ol start='0'><li>a</li></ol>", "0.", "zero");
      Expect ("<ol start='-2'><li>a</li><li>b</li></ol>", "-1.", "negative");
      Expect ("<ol start='9'><li>a</li><li value='20'>b</li><li>c</li></ol>", "21.",
              "a value resets the count after start");
      Expect ("<ol start='x'><li>a</li></ol>", "1.", "no digits counts from 1");
      Expect ("<ol start='2147483647'><li>a</li><li>b</li></ol>", "2147483647.",
              "the count stops at the largest integer");
      New_Line;
   end Test_Ordered_List_Start;

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
         = CSS_Box (Px (7.0)),
         "the applied padding survives Clear");
      Assert (Adi.Widget.Html_View.Get_HTML (W) = "",
              "the document is gone");
      Assert (Adi.Widget.Get_Scroll_Offset_Y (+W) = 0.0,
              "the scroll offset goes with it");
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

   ---------------------------------------------------------------------------
   --  A link-click callback may destroy the view it is running under.
   --
   --  On_Mouse_Up (Widget_Handle, ...) borrows for the length of the
   --  call, so the Link_Click subscriber array — which lives inside the
   --  view — is still there when the emit moves on to the next
   --  subscriber.
   ---------------------------------------------------------------------------

   Doomed_View     : Adi.Widget.Widget_Handle := Adi.Widget.Null_Handle;
   First_Link_Ran  : Boolean := False;
   Late_Link_Ran   : Boolean := False;

   procedure Destroy_Own_View
     (Self : Adi.Widget.Html_View.Html_View_Handle; Href : String)
   is
      pragma Unreferenced (Href);
      Target : Adi.Widget.Widget_Handle :=
        Adi.Widget.Html_View.To_Widget_Handle (Self);
   begin
      First_Link_Ran := True;
      Adi.Widget.Destroy (Target);
   end Destroy_Own_View;

   procedure Late_Link
     (Self : Adi.Widget.Html_View.Html_View_Handle; Href : String)
   is
      pragma Unreferenced (Self, Href);
   begin
      Late_Link_Ran := True;
   end Late_Link;

   procedure Test_Link_Click_Destroys_Own_View is
      W : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
   begin
      Put_Line ("Test: link-click callback destroys its own view");

      First_Link_Ran := False;
      Late_Link_Ran  := False;
      Doomed_View    := Adi.Widget.Html_View.To_Widget_Handle (W);

      Adi.Widget.Html_View.Connect_Link_Click
        (W, Destroy_Own_View'Unrestricted_Access);
      Adi.Widget.Html_View.Connect_Link_Click
        (W, Late_Link'Unrestricted_Access);
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<p><a href='app://gone'>a link long enough to click</a></p>");

      --  Same padding and text size as the hit-testing test above, so
      --  the click coordinate below means what it says.
      declare
         use Adi.CSS_Styles;
         use Adi.Widget_Styles;
         Main_Rules : constant Style_Rules :=
           (Padding => Set (CSS_Box (Px (14.0))), others => <>);
         Text_Rules : constant Style_Rules :=
           (Font_Size => Set_Font (Px (15.0)), others => <>);
      begin
         Adi.Widget.Set_Part_Styles
           (+W,
            [Adi.Widget.Main_Part =>
               (Style => From (Main_Rules).Build, Enabled => True),
             Adi.Widget.Text_Part =>
               (Style => From (Text_Rules).Build, Enabled => True),
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

      Assert (First_Link_Ran, "the destroying link callback ran");
      Assert (Late_Link_Ran,
              "a Link_Click subscriber queued behind the destroying one"
              & " still runs");

      Adi.Widget.Pump_Widget_Store;
      Assert (not Adi.Widget.Is_Valid (Doomed_View),
              "the view is gone once the dispatch has unwound");

      New_Line;
   end Test_Link_Click_Destroys_Own_View;

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
              (Ref (It.Computed_Style).Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
               "baseline inherited unit is px");
            Assert
              (Ref (It.Computed_Style).Font_Size.Amount >= 15.0
               and then Ref (It.Computed_Style).Font_Size.Amount <= 17.0,
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
              (Ref (It.Computed_Style).Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
               "large inherited unit is px");
            Assert
              (Ref (It.Computed_Style).Font_Size.Amount >= 39.0,
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
              (Ref (It.Computed_Style).Text_Decoration = Adi.CSS_Styles.Decoration_Overline,
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
              (Ref (It.Computed_Style).Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
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
      --  line-height: <number> multiplies font-size, not line-skip: font-size 20px with line-height 2 should produce ~40px line advance.
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
            --  h1 #2 -> p collapse-through center's last-child boundary: max(30, 10) = 30.
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
              (Ref (H1_It.Computed_Style).Font_Size.Amount >
               Ref (P_It.Computed_Style).Font_Size.Amount,
               "default stylesheet h1 font-size > p font-size");
            --  h1 is 2em with body 16px = 32px; verify it's near 32px.
            Assert
              (Nearly_Equal
                 (Adi.Core.Pixel_Type (Ref (H1_It.Computed_Style).Font_Size.Amount),
                  32.0, 4.0),
               "default stylesheet h1 em resolves near 32px (2em * 16px)");
            Assert
              (Adi.Core.Pixel_Type (Ref (H1_It.Computed_Style).Font_Size.Amount) < 100.0,
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
              (Ref (It.Computed_Style).Font_Size.Unit in Adi.CSS_Styles.Px | Adi.CSS_Styles.Dip,
               "user CSS override h1 font-size is in px");
            Assert
              (Nearly_Equal
                 (Adi.Core.Pixel_Type (Ref (It.Computed_Style).Font_Size.Amount),
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
              (Ref (H1_It.Computed_Style).Font_Size.Amount >
               Ref (P_It.Computed_Style).Font_Size.Amount,
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
                 Ref (Adi.Widget.Get_Item (+W2, Positive (Idx))
                        .Computed_Style).Font_Size.Amount;
            begin
               Adi.Widget.Html_View.Set_Default_Stylesheet_String
                 (W2, "h1 { font-size: 48px; }");
               Adi.Widget.Build_Items (+W2);
               Idx := Find_Text_Item_Index (W2, "Late");
               Assert (Idx > 0, "late default reparse: text item exists");
               if Idx > 0 then
                  declare
                     After : constant Float :=
                       Ref (Adi.Widget.Get_Item (+W2, Positive (Idx))
                              .Computed_Style).Font_Size.Amount;
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

   --  A view parses the document's own CSS and every inline style
   --  attribute in it, on every Set_HTML. Two things must hold of what
   --  that leaves: nothing reaches a store that never releases, and
   --  nothing outlives the view.
   procedure Test_Parsing_A_Document_Leaves_Nothing_Behind is
      Before : constant Natural := Adi.CSS_Parser.Testing.Live_Sheets;

      --  One document per call, no two alike: a rule block the stores
      --  have seen already interns onto the entry it is already holding,
      --  so only distinct blocks show what a parse leaves behind.
      function Doc (N : Natural) return String is
        ("<style>p { color: rgb(" & Natural'Image (N) & ", 20, 30); }"
         & " .n { color: rgb(1," & Natural'Image (N) & ",3); }"
         & "</style>"
         & "<p class='n' style='color: rgb(11," & Natural'Image (N)
         & ", 13);'>one</p>"
         & "<p style='color: rgb(21, 22," & Natural'Image (N)
         & ");'>two</p>");

      Documents : constant := 8;
      Rules_Before : constant Natural :=
        Adi.CSS_Parser.Testing.Live_Rule_Sheets;

      Peak       : Natural := 0;
      After      : Natural := 0;
      Rules_Peak : Natural := 0;

      Rule_Sets_Before : Natural := 0;
      Styles_Before    : Natural := 0;
   begin
      Put_Line ("Test: parsing a document leaves nothing behind");

      declare
         W : constant Adi.Widget.Html_View.Html_View_Handle :=
           Adi.Widget.Html_View.Create_Handle;
         Doomed : Adi.Widget.Widget_Handle;
      begin
         Adi.Widget.Set_Geometry
           (+W, (X => 0.0, Y => 0.0, Width => 400.0, Height => 300.0));

         --  A first document, so the measurement below starts with the
         --  view warm and every store it touches for other reasons
         --  already holding what it will hold.
         Adi.Widget.Html_View.Set_HTML (W, Doc (0));
         Adi.Widget.Build_Items (+W);

         Rule_Sets_Before := Adi.CSS_Styles.Interned_Rule_Sets;
         Styles_Before    := Adi.Widget_Styles.Interned_Styles;

         for N in 1 .. Documents loop
            Adi.Widget.Html_View.Set_HTML (W, Doc (N));
            Adi.Widget.Build_Items (+W);
         end loop;

         Put_Line ("  interned by" & Natural'Image (Documents)
                   & " distinct documents: rule sets"
                   & Natural'Image (Adi.CSS_Styles.Interned_Rule_Sets
                                    - Rule_Sets_Before)
                   & ", styles"
                   & Natural'Image (Adi.Widget_Styles.Interned_Styles
                                    - Styles_Before));
         Assert (Adi.CSS_Styles.Interned_Rule_Sets = Rule_Sets_Before,
                 "a document the view cascades itself interns no rule set");
         Assert (Adi.Widget_Styles.Interned_Styles = Styles_Before,
                 "and no style");

         Peak := Adi.CSS_Parser.Testing.Live_Sheets;
         Rules_Peak := Adi.CSS_Parser.Testing.Live_Rule_Sheets;

         Doomed := +W;
         Adi.Widget.Destroy (Doomed);
      end;
      Adi.Widget.Pump_Widget_Store;
      After := Adi.CSS_Parser.Testing.Live_Sheets;

      Put_Line ("  sheet impls live:" & Before'Image & " before,"
                & Peak'Image & " at peak," & After'Image & " after");
      Put_Line ("  rule sheets live:" & Rules_Before'Image & " before,"
                & Rules_Peak'Image & " at peak,"
                & Natural'Image (Adi.CSS_Parser.Testing.Live_Rule_Sheets)
                & " after");

      Assert (Peak <= Before,
              "cascading a document holds no sheet in the store");
      Assert (After = Before,
              "and a destroyed view leaves none of them behind");

      --  One per view for the document, and none for the inline styles:
      --  each of those is parsed into a sheet that dies with the call.
      Assert (Rules_Peak = Rules_Before + 1,
              "a view holds one rule sheet, for its document");
      Assert (Adi.CSS_Parser.Testing.Live_Rule_Sheets = Rules_Before,
              "and releases it with itself");

      New_Line;
   end Test_Parsing_A_Document_Leaves_Nothing_Behind;

   --  :root { font-size } is the document's rem base, and it reaches the
   --  view through the Rule_Sheet: Load_Rules copies it out of the
   --  parse metadata, Load_Combined_CSS reads it back, and every rem in
   --  the document resolves against it. A break anywhere on that seam
   --  changes no colour and fails no parse -- it silently re-sizes the
   --  whole document to the default 16px base.
   procedure Test_Root_Font_Size_Drives_Rem is
      W   : constant Adi.Widget.Html_View.Html_View_Handle :=
        Adi.Widget.Html_View.Create_Handle;
      Idx : Natural := 0;

      Rooted  : Adi.Core.Pixel_Type := 0.0;
      Default : Adi.Core.Pixel_Type := 0.0;

      --  The resolved font size of the paragraph, in pixels.
      function Probe_Font_Size return Adi.Core.Pixel_Type is
         It : constant Adi.Widget.Item :=
           Adi.Widget.Get_Item (+W, Positive (Idx));
      begin
         return Adi.Core.Pixel_Type
           (Ref (It.Computed_Style).Font_Size.Amount);
      end Probe_Font_Size;
   begin
      Put_Line ("Test: :root font-size drives rem");

      Adi.Widget.Set_Geometry
        (+W, (X => 0.0, Y => 0.0, Width => 620.0, Height => 300.0));

      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>:root { font-size: 20px; } p { font-size: 2rem; }</style>" &
         "<p>remprobe</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "remprobe");
      Assert (Idx > 0, "the rem paragraph lays out to a text item");
      if Idx > 0 then
         Rooted := Probe_Font_Size;
         Put_Line ("  2rem against a 20px :root:"
                   & Adi.Core.Pixel_Type'Image (Rooted) & " px");
         Assert (Nearly_Equal (Rooted, 40.0),
                 "2rem resolves against the document's own :root font-size");
      end if;

      --  The same document with no :root block: the base falls back to
      --  16px, so the same rule resolves smaller. This is also what
      --  pins the seam being read afresh per document rather than left
      --  standing from the last one.
      Adi.Widget.Html_View.Set_HTML
        (W,
         "<style>p { font-size: 2rem; }</style><p>remprobe</p>");
      Adi.Widget.Build_Items (+W);

      Idx := Find_Text_Item_Index (W, "remprobe");
      Assert (Idx > 0, "the same paragraph without :root lays out too");
      if Idx > 0 then
         Default := Probe_Font_Size;
         Put_Line ("  2rem against the default base:"
                   & Adi.Core.Pixel_Type'Image (Default) & " px");
         Assert (Nearly_Equal (Default, 32.0),
                 "and against the default 16px base with no :root");
      end if;

      Assert (Rooted > Default + 4.0,
              "so a :root font-size is what separates the two");

      New_Line;
   end Test_Root_Font_Size_Drives_Rem;

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
   Test_Img_Dimension_Attributes;
   Test_Content_Scale_Is_Linear;
   Test_Percent_Font_And_Line_Height;
   Test_Selectors;
   Test_Block_Sizing;
   Test_Body_Box;
   Test_Inline_Boxes;
   Test_Positioning;
   Test_Overflow_Clip;
   Test_Vertical_Align;
   Test_Tables;
   Test_Border_Insets_At_Scale;
   Test_Character_References;
   Test_Marker_Beside_Opening_Block;
   Test_Pre_Leading_Newline;
   Test_Ordered_List_Start;
   Test_Grid_Px_Track_Follows_Content_Scale;
   Test_Mixed_Inline_Baseline;
   Test_Fresh_View_Is_Neutral;
   Test_Clear_Keeps_Applied_Styles;
   Test_Clipping_Aware_Link_Hit_Test;
   Test_Link_Click_Destroys_Own_View;
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
   Test_Parsing_A_Document_Leaves_Nothing_Behind;
   Test_Root_Font_Size_Drives_Rem;

   Test_Support.Finish;
end Html_View_Test;
