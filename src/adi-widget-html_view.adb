with Ada.Characters.Handling;
with Ada.Containers.Vectors;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Widget_Styles;     use Adi.Widget_Styles;
with Adi.Log;
with Adi.Font;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.TTF;           use Adi.SDL.TTF;

package body Adi.Widget.Html_View is

   package Fix renames Ada.Strings.Fixed;
   package Char renames Ada.Characters.Handling;
   use type Adi.Window.Window_Access;

   Panel_Idx : constant Positive := 1;

   function Lower (S : String) return String is (Char.To_Lower (S));

   function Is_Whitespace (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Is_Block_Tag (Name : String) return Boolean is
   begin
      return Name = "div"
        or else Name = "p"
        or else Name = "h1"
        or else Name = "h2"
        or else Name = "ul"
        or else Name = "ol"
        or else Name = "li"
        or else Name = "center";
   end Is_Block_Tag;

   function Extract_Tag_Name (S : String) return String is
      I : Positive := S'First;
      J : Natural := 0;
   begin
      while I <= S'Last and then Is_Whitespace (S (I)) loop
         I := I + 1;
      end loop;

      if I <= S'Last and then S (I) = '/' then
         I := I + 1;
      end if;

      J := I;
      while J <= S'Last loop
         exit when Is_Whitespace (S (J))
           or else S (J) = '/'
           or else S (J) = '>';
         J := J + 1;
      end loop;

      if I > S'Last or else J <= I then
         return "";
      end if;

      return Lower (S (I .. J - 1));
   end Extract_Tag_Name;

   function Is_Closing_Tag (S : String) return Boolean is
      I : Positive := S'First;
   begin
      while I <= S'Last and then Is_Whitespace (S (I)) loop
         I := I + 1;
      end loop;
      return I <= S'Last and then S (I) = '/';
   end Is_Closing_Tag;

   function Extract_Attribute (Tag_Content : String; Name : String) return String is
      Name_Low : constant String := Lower (Name);
      I        : Integer := Tag_Content'First;

      procedure Skip_Spaces is
      begin
         while I <= Tag_Content'Last and then Is_Whitespace (Tag_Content (I)) loop
            I := I + 1;
         end loop;
      end Skip_Spaces;

      function Read_Ident return String is
         Start : constant Integer := I;
      begin
         while I <= Tag_Content'Last loop
            exit when Is_Whitespace (Tag_Content (I))
              or else Tag_Content (I) = '='
              or else Tag_Content (I) = '>';
            I := I + 1;
         end loop;

         if Start > Tag_Content'Last or else I <= Start then
            return "";
         end if;
         return Lower (Tag_Content (Start .. I - 1));
      end Read_Ident;

      function Read_Value return String is
         Quote : Character;
         Start : Integer;
      begin
         if I > Tag_Content'Last then
            return "";
         end if;

         if Tag_Content (I) = '"' or else Tag_Content (I) = ''' then
            Quote := Tag_Content (I);
            I := I + 1;
            Start := I;
            while I <= Tag_Content'Last and then Tag_Content (I) /= Quote loop
               I := I + 1;
            end loop;
            if I <= Tag_Content'Last then
               return Tag_Content (Start .. I - 1);
            end if;
            return "";
         end if;

         Start := I;
         while I <= Tag_Content'Last loop
            exit when Is_Whitespace (Tag_Content (I)) or else Tag_Content (I) = '>';
            I := I + 1;
         end loop;

         if I <= Start then
            return "";
         end if;
         return Tag_Content (Start .. I - 1);
      end Read_Value;
   begin
      while I <= Tag_Content'Last loop
         Skip_Spaces;
         exit when I > Tag_Content'Last;
         exit when Tag_Content (I) = '>';

         declare
            Key : constant String := Read_Ident;
         begin
            if Key'Length = 0 then
               I := I + 1;
            else
               Skip_Spaces;
               if I <= Tag_Content'Last and then Tag_Content (I) = '=' then
                  I := I + 1;
                  Skip_Spaces;
                  declare
                     Value : constant String := Read_Value;
                  begin
                     if Key = Name_Low then
                        return Value;
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;

      return "";
   exception
      when others =>
         return "";
   end Extract_Attribute;

   function Merge_Widget_Style (Base, Override : Widget_Style) return Widget_Style is
      Result : Widget_Style := Base;
      Rule_Index : Natural := 0;
   begin
      Result.Base := Merge (Result.Base, Override.Base);

      for I in 1 .. Override.Rule_Count loop
         Rule_Index := 0;
         for J in 1 .. Result.Rule_Count loop
            if Result.Rules (J).Selector = Override.Rules (I).Selector then
               Rule_Index := J;
               exit;
            end if;
         end loop;

         if Rule_Index = 0 then
            if Result.Rule_Count < Max_Style_Rules then
               Add_Rule (Result, Override.Rules (I));
            end if;
         else
            Result.Rules (Rule_Index).Style :=
              Merge (Result.Rules (Rule_Index).Style, Override.Rules (I).Style);
         end if;
      end loop;

      return Result;
   end Merge_Widget_Style;

   function Default_Internal_Part_Styles return Part_Style_Array is
      Main_Base : constant Style_Rules := (
        Flex_Grow => Set (1.0),
        Min_Height => Set (Size (Px (0.0))),
        Overflow => Set (Overflow_Auto),
        Background_Color => Set_Bg (RGB (255, 252, 247)),
        Border_Width => Set (Border_Width (Px (1.0))),
        Border_Style => Set (Border_Style (Solid)),
        Border_Color => Set (Border_Color (RGB (212, 199, 183))),
        Border_Radius => Set (Radius (Px (10.0))),
        Padding => Set (CSS_Box (Px (14.0))),
        others => <>);

      Label_Base : constant Style_Rules := (
        Color => Set (RGB (51, 46, 39)),
        Font_Size => Set_Font (Px (15.0)),
        others => <>);

      Link_Base : constant Style_Rules := (
        Color => Set (RGB (24, 96, 186)),
        Text_Decoration => Set (Decoration_Underline),
        Font_Size => Set_Font (Px (15.0)),
        others => <>);

      H1_Base : constant Style_Rules := (
        Color => Set (RGB (35, 31, 27)),
        Font_Size => Set_Font (Px (28.0)),
        Font_Weight => Set (Weight_Bold),
        others => <>);

      H2_Base : constant Style_Rules := (
        Color => Set (RGB (48, 43, 37)),
        Font_Size => Set_Font (Px (20.0)),
        Font_Weight => Set (Weight_Semi_Bold),
        others => <>);

      Code_Base : constant Style_Rules := (
        Color => Set (RGB (66, 57, 46)),
        Font_Size => Set_Font (Px (14.0)),
        others => <>);

      Bold_Base : constant Style_Rules := (
        Color => Set (RGB (40, 35, 30)),
        Font_Weight => Set (Weight_Bold),
        others => <>);

      Italic_Base : constant Style_Rules := (
        Color => Set (RGB (74, 66, 56)),
        Font_Style => Set (Style_Italic),
        others => <>);

      Icon_Base : constant Style_Rules := (
        Object_Fit => Set (Fit_None),
        others => <>);

      Scroll_Base : constant Style_Rules := (
        Width => Set (Size (Px (9.0))),
        Background_Color => Set_Bg (RGBA (127, 103, 75, 0.55)),
        Border_Radius => Set (Radius (Px (5.0))),
        Padding => Set (CSS_Box (Px (2.0))),
        others => <>);

      Knob_Base : constant Style_Rules := (
        Min_Height => Set (Size (Px (26.0))),
        Background_Color => Set_Bg (RGBA (112, 92, 69, 0.70)),
        Border_Radius => Set (Radius (Px (4.0))),
        others => <>);
   begin
      return [
        Main_Part      => (Style => From (Main_Base).Build, Enabled => True),
        Label_Part     => (Style => From (Label_Base).Build, Enabled => True),
        Indicator_Part => (Style => From (Link_Base).Build, Enabled => True),
        Cursor_Part    => (Style => From (H1_Base).Build, Enabled => True),
        Items_Part     => (Style => From (H2_Base).Build, Enabled => True),
        Any_Part       => (Style => From (Code_Base).Build, Enabled => True),
        Selected_Part  => (Style => From (Bold_Base).Build, Enabled => True),
        Custom_Part    => (Style => From (Italic_Base).Build, Enabled => True),
        Icon_Part      => (Style => From (Icon_Base).Build, Enabled => True),
        Scroll_Part    => (Style => From (Scroll_Base).Build, Enabled => True),
        Knob_Part      => (Style => From (Knob_Base).Build, Enabled => True),
        others         => <>];
   end Default_Internal_Part_Styles;

   function Load_Text_Resource
     (Self : in out Html_View;
      URI  : String) return String
   is
   begin
      if Self.On_Load_Resource /= null then
         declare
            Txt : constant String := Self.On_Load_Resource (Self'Unchecked_Access, URI);
         begin
            if Txt'Length > 0 then
               return Txt;
            end if;
         end;
      end if;

      return "";
   end Load_Text_Resource;

   procedure Apply_Embedded_CSS
     (Self    : in out Html_View;
      CSS_Text : String)
   is
      Combined : Part_Style_Array := Default_Internal_Part_Styles;
      Success  : Boolean := True;

      procedure Merge_Tag_Main
        (Tag  : String;
         Part : Part_Kind)
      is
      begin
         if not Adi.CSS_Parser.Has_Tag (Self.CSS_Sheet, Tag) then
            return;
         end if;

         declare
            Styles : constant Part_Style_Array := Adi.CSS_Parser.Styles_For_Tag (Self.CSS_Sheet, Tag);
         begin
            Combined (Part).Style :=
              Merge_Widget_Style (Combined (Part).Style, Styles (Main_Part).Style);
         end;
      end Merge_Tag_Main;
   begin
      if CSS_Text'Length > 0 then
         Adi.CSS_Parser.Load_String (Self.CSS_Sheet, CSS_Text, Success);
         if not Success then
            Adi.Log.Error
              ("Html_View CSS parse failed: " & Adi.CSS_Parser.Get_Last_Error (Self.CSS_Sheet));
         else
            Merge_Tag_Main ("html", Main_Part);
            Merge_Tag_Main ("body", Main_Part);
            Merge_Tag_Main ("p", Label_Part);
            Merge_Tag_Main ("div", Label_Part);
            Merge_Tag_Main ("span", Label_Part);
            Merge_Tag_Main ("li", Label_Part);
            Merge_Tag_Main ("a", Indicator_Part);
            Merge_Tag_Main ("h1", Cursor_Part);
            Merge_Tag_Main ("h2", Items_Part);
            Merge_Tag_Main ("code", Any_Part);
            Merge_Tag_Main ("strong", Selected_Part);
            Merge_Tag_Main ("b", Selected_Part);
            Merge_Tag_Main ("em", Custom_Part);
            Merge_Tag_Main ("i", Custom_Part);
            Merge_Tag_Main ("img", Icon_Part);
            Merge_Tag_Main ("hr", Scroll_Part);
         end if;
      end if;

      Set_Part_Styles (Self, Combined);
   end Apply_Embedded_CSS;

   procedure Append_Token
     (Self  : in out Html_View;
      Value : Token)
   is
   begin
      Self.Tokens.Append (Value);
   end Append_Token;

   procedure Append_Text
     (Self : in out Html_View;
      S    : String;
      Href : String;
      Style_Kind : Text_Style_Kind)
   is
   begin
      if S'Length = 0 then
         return;
      end if;

      Append_Token
        (Self,
         (Kind      => Text_Token,
          Link_Href => To_Unbounded_String (Href),
          Text      => To_Unbounded_String (S),
          Style_Kind => Style_Kind));
   end Append_Text;

   procedure Append_Break (Self : in out Html_View) is
   begin
      Append_Token (Self, (Kind => Break_Token, Link_Href => Null_Unbounded_String));
   end Append_Break;

   procedure Parse_HTML (Self : in out Html_View; Source : String) is
      I            : Positive := Source'First;
      Text_Start   : Positive := Source'First;
      Lower_Source : constant String := Lower (Source);
      CSS_Buffer   : Unbounded_String := Null_Unbounded_String;
      Active_Href  : Unbounded_String := Null_Unbounded_String;
      H1_Depth     : Natural := 0;
      H2_Depth     : Natural := 0;
      Code_Depth   : Natural := 0;
      Bold_Depth   : Natural := 0;
      Italic_Depth : Natural := 0;
      Last_Was_Brk : Boolean := False;

      function Current_Text_Style return Text_Style_Kind is
      begin
         if Code_Depth > 0 then
            return Code_Text;
         elsif H1_Depth > 0 then
            return Heading_1_Text;
         elsif H2_Depth > 0 then
            return Heading_2_Text;
         elsif Bold_Depth > 0 and then Italic_Depth > 0 then
            return Bold_Italic_Text;
         elsif Bold_Depth > 0 then
            return Bold_Text;
         elsif Italic_Depth > 0 then
            return Italic_Text;
         else
            return Normal_Text;
         end if;
      end Current_Text_Style;

      procedure Flush_Text (Stop_At : Natural) is
      begin
         if Stop_At >= Text_Start then
            Append_Text
              (Self,
               Source (Text_Start .. Stop_At),
               To_String (Active_Href),
               Current_Text_Style);
            Last_Was_Brk := False;
         end if;
      end Flush_Text;

      procedure Ensure_Break is
      begin
         if not Last_Was_Brk then
            Append_Break (Self);
            Last_Was_Brk := True;
         end if;
      end Ensure_Break;

      procedure Append_CSS (S : String) is
      begin
         if S'Length = 0 then
            return;
         end if;
         Append (CSS_Buffer, S);
         Append (CSS_Buffer, ASCII.LF);
      end Append_CSS;
   begin
      Self.Tokens.Clear;

      while I <= Source'Last loop
         if Source (I) = '<' then
            declare
               Close_I : constant Natural := Fix.Index (Source, ">", From => I);
               End_Pos : Natural;
            begin
               if Close_I = 0 then
                  exit;
               end if;

               End_Pos := Close_I;
               if I > Text_Start then
                  Flush_Text (I - 1);
               end if;

               if End_Pos > I + 1 then
                  declare
                     Raw_Tag : constant String := Source (I + 1 .. End_Pos - 1);
                     Name    : constant String := Extract_Tag_Name (Raw_Tag);
                     Closing : constant Boolean := Is_Closing_Tag (Raw_Tag);
                     Consumed_Style_Block : Boolean := False;
                  begin
                     if Name = "br" then
                        Ensure_Break;
                     elsif Name = "style" and then not Closing then
                        declare
                           Close_Pos : constant Natural :=
                             Fix.Index (Lower_Source, "</style>", From => End_Pos + 1);
                        begin
                           if Close_Pos > 0 then
                              if Close_Pos > End_Pos + 1 then
                                 Append_CSS (Source (End_Pos + 1 .. Close_Pos - 1));
                              end if;
                              I := Close_Pos + 8;
                              Text_Start := I;
                              Consumed_Style_Block := True;
                           end if;
                        end;
                     elsif Name = "link" and then not Closing then
                        declare
                           Rel  : constant String := Lower (Extract_Attribute (Raw_Tag, "rel"));
                           Href : constant String := Extract_Attribute (Raw_Tag, "href");
                        begin
                           if Rel = "stylesheet" and then Href'Length > 0 then
                              declare
                                 CSS_Text : constant String := Load_Text_Resource (Self, Href);
                              begin
                                 if CSS_Text'Length > 0 then
                                    Append_CSS (CSS_Text);
                                 else
                                    Adi.Log.Debug ("Html_View: stylesheet not found: " & Href);
                                 end if;
                              end;
                           end if;
                        end;
                     elsif Name = "hr" then
                        Ensure_Break;
                        Append_Token (Self, (Kind => Hr_Token, Link_Href => Null_Unbounded_String));
                        Ensure_Break;
                     elsif Name = "img" and then not Closing then
                        declare
                           Src : constant String := Extract_Attribute (Raw_Tag, "src");
                           Alt : constant String := Extract_Attribute (Raw_Tag, "alt");
                        begin
                           if Src'Length = 0 then
                              Adi.Log.Debug ("Html_View: img tag without src");
                           end if;
                           Append_Token
                             (Self,
                              (Kind      => Image_Token,
                               Link_Href => Active_Href,
                               Src       => To_Unbounded_String (Src),
                               Alt       => To_Unbounded_String (Alt)));
                           Last_Was_Brk := False;
                        end;
                     elsif Name = "a" then
                        if Closing then
                           Active_Href := Null_Unbounded_String;
                        else
                           Active_Href := To_Unbounded_String (Extract_Attribute (Raw_Tag, "href"));
                           if Length (Active_Href) = 0 then
                              Adi.Log.Debug ("Html_View: a tag without href");
                           end if;
                        end if;
                     elsif Name = "h1" then
                        Ensure_Break;
                        if Closing then
                           if H1_Depth > 0 then
                              H1_Depth := H1_Depth - 1;
                           end if;
                        else
                           H1_Depth := H1_Depth + 1;
                        end if;
                     elsif Name = "h2" then
                        Ensure_Break;
                        if Closing then
                           if H2_Depth > 0 then
                              H2_Depth := H2_Depth - 1;
                           end if;
                        else
                           H2_Depth := H2_Depth + 1;
                        end if;
                     elsif Name = "code" then
                        if Closing then
                           if Code_Depth > 0 then
                              Code_Depth := Code_Depth - 1;
                           end if;
                        else
                           Code_Depth := Code_Depth + 1;
                        end if;
                     elsif Name = "b" or else Name = "strong" then
                        if Closing then
                           if Bold_Depth > 0 then
                              Bold_Depth := Bold_Depth - 1;
                           end if;
                        else
                           Bold_Depth := Bold_Depth + 1;
                        end if;
                     elsif Name = "em" or else Name = "i" then
                        if Closing then
                           if Italic_Depth > 0 then
                              Italic_Depth := Italic_Depth - 1;
                           end if;
                        else
                           Italic_Depth := Italic_Depth + 1;
                        end if;
                     elsif Is_Block_Tag (Name) then
                        Ensure_Break;
                        if not Closing and then Name = "li" then
                           Append_Text (Self, "* ", "", Current_Text_Style);
                        end if;
                     end if;

                     if not Consumed_Style_Block then
                        I := End_Pos + 1;
                        Text_Start := I;
                     end if;
                  end;
               end if;

               if I <= End_Pos then
                  I := End_Pos + 1;
                  Text_Start := I;
               end if;
            end;
         else
            I := I + 1;
         end if;
      end loop;

      if Text_Start <= Source'Last then
         Flush_Text (Source'Last);
      end if;

      Apply_Embedded_CSS (Self, To_String (CSS_Buffer));
   end Parse_HTML;

   function Lookup_Image
     (Self : in out Html_View;
      Src  : String) return Adi.Image.Image_Access
   is
   begin
      for I in 1 .. Natural (Self.Image_Cache.Length) loop
         declare
            Cache_Entry : constant Cached_Image := Self.Image_Cache.Element (I);
         begin
            if To_String (Cache_Entry.Src) = Src then
               return Cache_Entry.Img;
            end if;
         end;
      end loop;

      return null;
   end Lookup_Image;

   function Resolve_Image
     (Self : in out Html_View;
      Src  : String) return Adi.Image.Image_Access
   is
      Img : Adi.Image.Image_Access := null;
   begin
      if Src'Length = 0 then
         return null;
      end if;

      Img := Lookup_Image (Self, Src);
      if Img /= null then
         return Img;
      end if;

      if Self.On_Load_Asset /= null then
         Img := Self.On_Load_Asset (Self'Unchecked_Access, Src);
      end if;

      Self.Image_Cache.Append
        (Cached_Image'(Src => To_Unbounded_String (Src), Img => Img));
      return Img;
   end Resolve_Image;

   function Measure_Text
     (Style : Resolved_Style;
      S     : String) return Size_2D
   is
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Style.Font_Family,
           Size       => Float (Length_To_Px (Style.Font_Size)),
           Weight     => Style.Font_Weight,
           Style      => Style.Font_Style,
           Decoration => Style.Text_Decoration);
   begin
      return Adi.Font.Measure_Text (Attrs => Font_Attrs, Content => S);
   end Measure_Text;

   function Measure_Line_Height
     (Style : Resolved_Style) return Pixel_Type
   is
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Style.Font_Family,
           Size       => Float (Length_To_Px (Style.Font_Size)),
           Weight     => Style.Font_Weight,
           Style      => Style.Font_Style,
           Decoration => Style.Text_Decoration);
      Font : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      M_H  : constant Pixel_Type := Measure_Text (Style, "M").Height;
   begin
      if Font = null then
         return Pixel_Type'Max (1.0, M_H);
      end if;

      return Pixel_Type'Max (Pixel_Type (TTF_GetFontLineSkip (Font)), Pixel_Type'Max (1.0, M_H));
   end Measure_Line_Height;

   function Measure_Ascent
     (Style : Resolved_Style) return Pixel_Type
   is
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Style.Font_Family,
           Size       => Float (Length_To_Px (Style.Font_Size)),
           Weight     => Style.Font_Weight,
           Style      => Style.Font_Style,
           Decoration => Style.Text_Decoration);
      Font : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      Line_H : constant Pixel_Type := Measure_Line_Height (Style);
   begin
      if Font = null then
         return Pixel_Type'Max (1.0, Line_H * 0.8);
      end if;

      return
        Pixel_Type'Max
          (1.0,
           Pixel_Type'Max
             (Pixel_Type (TTF_GetFontAscent (Font)),
              Line_H * 0.6));
   end Measure_Ascent;

   function Find_Link_At
     (Self : Html_View;
      X, Y : Pixel_Type) return String
   is
   begin
      for I in 1 .. Natural (Self.Links.Length) loop
         declare
            Frag : constant Link_Fragment := Self.Links.Element (I);
            G    : constant Rectangle := Frag.Geometry;
         begin
            if X >= G.X and then X <= G.X + G.Width
              and then Y >= G.Y and then Y <= G.Y + G.Height
            then
               return To_String (Frag.Href);
            end if;
         end;
      end loop;

      return "";
   end Find_Link_At;

   procedure Layout_And_Build (Self : in out Html_View) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (Self, Main_Part);
      Text_Style : constant Resolved_Style := Get_Resolved_Part_Style (Self, Label_Part);
      Link_Style : constant Resolved_Style := Get_Resolved_Part_Style (Self, Indicator_Part);
      H1_Style   : constant Resolved_Style := Get_Resolved_Part_Style (Self, Cursor_Part);
      H2_Style   : constant Resolved_Style := Get_Resolved_Part_Style (Self, Items_Part);
      Code_Style : constant Resolved_Style := Get_Resolved_Part_Style (Self, Any_Part);
      Bold_Style : constant Resolved_Style := Get_Resolved_Part_Style (Self, Selected_Part);
      Italic_Style : constant Resolved_Style := Get_Resolved_Part_Style (Self, Custom_Part);
      Content    : constant Rectangle := Content_Box (Self.Geometry, Main_Style);

      X : Pixel_Type := Content.X;
      Y : Pixel_Type := Content.Y - Get_Scroll_Offset_Y (Self);
      Base_Line_H : constant Pixel_Type :=
        Pixel_Type'Max (1.0, Measure_Line_Height (Text_Style));
      Base_Ascent : constant Pixel_Type :=
        Pixel_Type'Max (1.0, Measure_Ascent (Text_Style));
      Current_Line_H : Pixel_Type := Base_Line_H;
      Current_Line_Ascent : Pixel_Type := Base_Ascent;
      Pending_Space : Boolean := False;

      type Line_Run_Record is record
         Item_Index : Positive := 1;
      end record;

      package Line_Run_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Line_Run_Record);

      Line_Runs : Line_Run_Vectors.Vector;

      function Clip_To_Content (R : Rectangle) return Rectangle is
         X1 : constant Pixel_Type := Pixel_Type'Max (R.X, Content.X);
         Y1 : constant Pixel_Type := Pixel_Type'Max (R.Y, Content.Y);
         X2 : constant Pixel_Type := Pixel_Type'Min (R.X + R.Width, Content.X + Content.Width);
         Y2 : constant Pixel_Type := Pixel_Type'Min (R.Y + R.Height, Content.Y + Content.Height);
      begin
         return
           (X      => X1,
            Y      => Y1,
            Width  => Pixel_Type'Max (0.0, X2 - X1),
            Height => Pixel_Type'Max (0.0, Y2 - Y1));
      end Clip_To_Content;

      procedure New_Line is
      begin
         X := Content.X;
         Y := Y + Current_Line_H;
         Current_Line_H := Base_Line_H;
         Current_Line_Ascent := Base_Ascent;
         Line_Runs.Clear;
         Pending_Space := False;
      end New_Line;

      procedure Add_Link_Fragment
        (Geom : Rectangle;
         Href : String)
      is
      begin
         if Href'Length = 0 or else Geom.Width <= 0.0 or else Geom.Height <= 0.0 then
            return;
         end if;

         Self.Links.Append
           (Link_Fragment'(Geometry => Geom, Href => To_Unbounded_String (Href)));
      end Add_Link_Fragment;

      procedure Add_Text_Run
        (Text : String;
         Href : String;
         Style_Kind : Text_Style_Kind)
      is
         Style       : constant Resolved_Style :=
           (if Href'Length > 0 then
               Link_Style
            elsif Style_Kind = Heading_1_Text then
               H1_Style
            elsif Style_Kind = Heading_2_Text then
               H2_Style
            elsif Style_Kind = Code_Text then
               Code_Style
            elsif Style_Kind = Bold_Text then
               Bold_Style
            elsif Style_Kind = Italic_Text then
               Italic_Style
            elsif Style_Kind = Bold_Italic_Text then
               (Bold_Style with delta Font_Style => Italic_Style.Font_Style)
            else
               Text_Style);
         Slice_First : Integer := Text'First;
         Run_W       : Pixel_Type := Measure_Text (Style, Text).Width;
         Geom        : Rectangle;
         Text_Part   : Part_Kind := Label_Part;
      begin
         if Text'Length = 0 then
            return;
         end if;

         if X > Content.X and then X + Run_W > Content.X + Content.Width then
            New_Line;
            if Slice_First <= Text'Last and then Text (Slice_First) = ' ' then
               Slice_First := Slice_First + 1;
               if Slice_First > Text'Last then
                  return;
               end if;
               Run_W := Measure_Text (Style, Text (Slice_First .. Text'Last)).Width;
            end if;
         end if;

         if Href'Length > 0 then
            Text_Part := Indicator_Part;
         elsif Style_Kind = Heading_1_Text then
            Text_Part := Cursor_Part;
         elsif Style_Kind = Heading_2_Text then
            Text_Part := Items_Part;
         elsif Style_Kind = Code_Text then
            Text_Part := Any_Part;
         elsif Style_Kind = Bold_Text then
            Text_Part := Selected_Part;
         elsif Style_Kind = Italic_Text or else Style_Kind = Bold_Italic_Text then
            Text_Part := Custom_Part;
         else
            Text_Part := Label_Part;
         end if;

         declare
            Draw_This : constant String := Text (Slice_First .. Text'Last);
            Run_H     : constant Pixel_Type := Measure_Line_Height (Style);
            Run_Ascent : constant Pixel_Type := Measure_Ascent (Style);
            Full_Geom : Rectangle;
            Hit_Geom  : Rectangle;
            Baseline_Shift : Pixel_Type := 0.0;
         begin
            if Run_Ascent > Current_Line_Ascent then
               Baseline_Shift := Run_Ascent - Current_Line_Ascent;
               Current_Line_Ascent := Run_Ascent;

               for J in 1 .. Natural (Line_Runs.Length) loop
                  declare
                     Idx : constant Positive := Line_Runs.Element (J).Item_Index;
                  begin
                     Self.Items.Reference (Idx).Text_Offset_Y :=
                       Self.Items.Reference (Idx).Text_Offset_Y + Baseline_Shift;
                  end;
               end loop;
            end if;

            Full_Geom :=
              (X      => X,
               Y      => Y,
               Width  => Run_W,
               Height => Run_H);
            Hit_Geom := Clip_To_Content (Full_Geom);

            if Hit_Geom.Width > 0.0 and then Hit_Geom.Height > 0.0 then
               Geom := Full_Geom;
               Add_Item (Self,
                         Make_Text (Text_Part,
                                    Geom,
                                    Draw_This,
                                    1));
               Self.Items.Reference (Positive (Self.Items.Last_Index)).Text_Offset_Y :=
                 Current_Line_Ascent - Run_Ascent;
               Self.Items.Reference (Positive (Self.Items.Last_Index)).Wrap_Text := False;
               Line_Runs.Append
                 (Line_Run_Record'(Item_Index => Positive (Self.Items.Last_Index)));
               Add_Link_Fragment (Hit_Geom, Href);
            end if;

            Current_Line_H := Pixel_Type'Max (Current_Line_H, Run_H);

            X := X + Run_W;
         end;
      end Add_Text_Run;
   begin
      if Item_Count (Self) = 0 then
         Add_Item (Self, Make_Panel (Main_Part, Self.Geometry, 0));
      end if;
      Self.Items.Reference (Panel_Idx).Geometry := Self.Geometry;
      while Item_Count (Self) > 1 loop
         Self.Items.Delete_Last;
      end loop;

      Self.Links.Clear;

      if Content.Width <= 0.0 or else Content.Height <= 0.0 then
         return;
      end if;

      for I in 1 .. Natural (Self.Tokens.Length) loop
         declare
            T : constant Token := Self.Tokens.Element (I);
         begin
            case T.Kind is
               when Break_Token =>
                  New_Line;

               when Hr_Token =>
                  if X > Content.X then
                     New_Line;
                  end if;
                  Add_Item
                    (Self,
                     Make_Panel
                        (Scroll_Part,
                         (X      => Content.X,
                          Y      => Y + 2.0,
                          Width  => Content.Width,
                          Height => 1.0),
                         1));
                  Y := Y + Current_Line_H;
                  Current_Line_H := Base_Line_H;
                  Current_Line_Ascent := Base_Ascent;
                  Line_Runs.Clear;
                  X := Content.X;
                  Pending_Space := False;

               when Image_Token =>
                  declare
                     Src : constant String := To_String (T.Src);
                     Alt : constant String := To_String (T.Alt);
                     Href : constant String := To_String (T.Link_Href);
                     Img : constant Adi.Image.Image_Access := Resolve_Image (Self, Src);
                     Img_W : Pixel_Type := 0.0;
                     Img_H : Pixel_Type := 0.0;
                  begin
                     if Img /= null and then Adi.Image.Is_Valid (Img.all) then
                        Adi.Image.Get_Size (Img.all, Img_W, Img_H);
                        if Img_H <= 0.0 then
                           Img_H := Base_Line_H;
                        end if;
                     else
                        Img_W := 0.0;
                        Img_H := Base_Line_H;
                     end if;

                     if Img_W > 0.0 then
                        if X > Content.X and then X + Img_W > Content.X + Content.Width then
                           New_Line;
                        end if;
                        declare
                           Full_Geom : constant Rectangle :=
                              (X => X,
                               Y => Y,
                               Width => Img_W,
                               Height => Img_H);
                           Geom : constant Rectangle := Clip_To_Content (Full_Geom);
                        begin
                           if Geom.Width > 0.0 and then Geom.Height > 0.0 then
                              Add_Item (Self, Make_Image (Icon_Part, Full_Geom, Img, 1));
                              Add_Link_Fragment (Geom, Href);
                           end if;
                           X := X + Img_W;
                           Current_Line_H := Pixel_Type'Max (Current_Line_H, Img_H);
                        end;
                     elsif Alt'Length > 0 then
                        Add_Text_Run (Alt, Href, Normal_Text);
                     end if;

                     Pending_Space := True;
                  end;

               when Text_Token =>
                  declare
                     S : constant String := To_String (T.Text);
                     Href : constant String := To_String (T.Link_Href);
                     Token_Style : constant Text_Style_Kind := T.Style_Kind;
                     Start : Natural := S'First;
                     Stop  : Natural := S'First;
                  begin
                     while Start <= S'Last loop
                        if Is_Whitespace (S (Start)) then
                           Pending_Space := True;
                           Start := Start + 1;
                        else
                           Stop := Start;
                           while Stop <= S'Last and then not Is_Whitespace (S (Stop)) loop
                              Stop := Stop + 1;
                           end loop;

                           declare
                              Prefix : constant String :=
                                 (if Pending_Space and then X > Content.X then " " else "");
                              Word : constant String := S (Start .. Stop - 1);
                           begin
                              Add_Text_Run (Prefix & Word, Href, Token_Style);
                           end;
                           Pending_Space := False;
                           Start := Stop;
                        end if;
                     end loop;
                  end;
            end case;
         end;
      end loop;

      Self.Scroll_Content_H := Pixel_Type'Max (Content.Height, (Y + Current_Line_H) - Content.Y);
      Self.Scroll_Viewport_H := Content.Height;
      Update_Scrollbar_Geometry (Self);
   end Layout_And_Build;

   function Create return Html_View_Access is
      Result : constant Html_View_Access := new Html_View;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Scrollable, True);
      Set_Part_Styles (Result.all, Default_Internal_Part_Styles);
      return Result;
   end Create;

   procedure Attach_Window
     (Self : in out Html_View;
      Host : Adi.Window.Window_Access)
   is
   begin
      Self.Host := Host;
      Mark_Dirty (Self);
   end Attach_Window;

   procedure Set_HTML
     (Self   : in out Html_View;
      Source : String)
   is
   begin
      Self.Source := To_Unbounded_String (Source);
      Parse_HTML (Self, Source);
      Self.Image_Cache.Clear;
      Mark_Dirty (Self);
   end Set_HTML;

   function Get_HTML (Self : Html_View) return String is
   begin
      return To_String (Self.Source);
   end Get_HTML;

   procedure Clear (Self : in out Html_View) is
   begin
      Self.Source := Null_Unbounded_String;
      Self.Tokens.Clear;
      Self.Links.Clear;
      Self.Image_Cache.Clear;
      Set_Part_Styles (Self, Default_Internal_Part_Styles);
      Mark_Dirty (Self);
   end Clear;

   procedure Set_On_Link_Click
     (Self     : in out Html_View;
      Callback : Link_Click_Callback)
   is
   begin
      Self.On_Link_Click := Callback;
   end Set_On_Link_Click;

   procedure Set_On_Load_Asset
     (Self     : in out Html_View;
      Callback : Asset_Load_Callback)
   is
   begin
      Self.On_Load_Asset := Callback;
      Self.Image_Cache.Clear;
      Mark_Dirty (Self);
   end Set_On_Load_Asset;

   procedure Set_On_Load_Resource
     (Self     : in out Html_View;
      Callback : Resource_Load_Callback)
   is
   begin
      Self.On_Load_Resource := Callback;
      Mark_Dirty (Self);
   end Set_On_Load_Resource;

   overriding procedure Build_Items (Self : in out Html_View) is
   begin
      Layout_And_Build (Self);
   end Build_Items;

   overriding procedure Layout (Self : in out Html_View) is
   begin
      null;
   end Layout;

   overriding function Measure_Content (Self : Html_View) return Size_2D is
      pragma Unreferenced (Self);
   begin
      return (Width => 320.0, Height => 120.0);
   end Measure_Content;

   overriding procedure On_Mouse_Down
     (Self   : in out Html_View;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (Clicks);
      Href : constant String := Find_Link_At (Self, X, Y);
   begin
      if Button /= Left_Button then
         return;
      end if;

      if Handle_Scroll_Mouse_Down (Self, X, Y, Button) then
         return;
      end if;

      if Href'Length > 0 then
         Self.Pressed_Is_Link := True;
         Self.Pressed_Href := To_Unbounded_String (Href);
      else
         Self.Pressed_Is_Link := False;
         Self.Pressed_Href := Null_Unbounded_String;
      end if;
   end On_Mouse_Down;

   overriding procedure On_Mouse_Move
     (Self : in out Html_View;
      X, Y : Pixel_Type)
   is
      Href : constant String := Find_Link_At (Self, X, Y);
   begin
      Handle_Scroll_Mouse_Move (Self, X, Y);

      if Href /= To_String (Self.Hovered_Href) then
         Self.Hovered_Href := To_Unbounded_String (Href);
         Mark_Dirty (Self);
      end if;
   end On_Mouse_Move;

   overriding procedure On_Mouse_Up
     (Self   : in out Html_View;
      X, Y   : Pixel_Type;
      Button : Mouse_Button)
   is
      Href : constant String := Find_Link_At (Self, X, Y);
   begin
      Handle_Scroll_Mouse_Up (Self, Button);

      if Button = Left_Button
        and then Self.Pressed_Is_Link
        and then Href'Length > 0
        and then Href = To_String (Self.Pressed_Href)
        and then Self.On_Link_Click /= null
      then
         Self.On_Link_Click (Self'Unchecked_Access, Href);
      elsif Button = Left_Button and then Self.Pressed_Is_Link then
         Adi.Log.Debug ("Html_View: link click did not resolve on mouse up");
      end if;

      Self.Pressed_Is_Link := False;
      Self.Pressed_Href := Null_Unbounded_String;
   end On_Mouse_Up;

end Adi.Widget.Html_View;
