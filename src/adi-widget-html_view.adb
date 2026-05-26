with Ada.Characters.Handling;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Widget_Styles;     use Adi.Widget_Styles;
with Adi.Log;
with Adi.Font;
with Adi.Image;             use Adi.Image;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.TTF;           use Adi.SDL.TTF;

package body Adi.Widget.Html_View is

   package Fix renames Ada.Strings.Fixed;
   package Char renames Ada.Characters.Handling;

   Panel_Idx : constant Positive := 1;

   --  Cached SVG marker images (created lazily on first use)
   Marker_White : constant Color_8 := (R => 255, G => 255, B => 255, A => 255);
   Marker_Clear : constant Color_8 := (R => 0, G => 0, B => 0, A => 0);
   Marker_SVG_Size : constant Size_2D := (16.0, 16.0);

   Disc_Marker_Img   : Image_Access := null;
   Circle_Marker_Img : Image_Access := null;
   Square_Marker_Img : Image_Access := null;

   procedure Ensure_Marker_Images is
   begin
      if Disc_Marker_Img /= null then
         return;
      end if;

      --  Filled circle (disc)
      Disc_Marker_Img := Load_SVG_Path
        (Path_Data    => "M8 2 A6 6 0 1 0 8 14 A6 6 0 1 0 8 2 Z",
         Size         => Marker_SVG_Size,
         Fill         => Marker_White,
         Stroke_Width => 0.0,
         Stroke       => Marker_Clear,
         Tintable     => True);

      --  Hollow circle
      Circle_Marker_Img := Load_SVG_Path
        (Path_Data    => "M8 2 A6 6 0 1 0 8 14 A6 6 0 1 0 8 2 Z",
         Size         => Marker_SVG_Size,
         Fill         => Marker_Clear,
         Stroke_Width => 1.5,
         Stroke       => Marker_White,
         Tintable     => True);

      --  Filled square
      Square_Marker_Img := Load_SVG_Path
        (Path_Data    => "M3 3 H13 V13 H3 Z",
         Size         => Marker_SVG_Size,
         Fill         => Marker_White,
         Stroke_Width => 0.0,
         Stroke       => Marker_Clear,
         Tintable     => True);
   end Ensure_Marker_Images;

   function Read_File (Path : String) return String is
      use Ada.Directories;
      File_Size : constant Natural := Natural (Size (Path));
   begin
      if File_Size = 0 then
         return "";
      end if;
      declare
         subtype Content_String is String (1 .. File_Size);
         F : Ada.Streams.Stream_IO.File_Type;
         S : Ada.Streams.Stream_IO.Stream_Access;
         Result : Content_String;
      begin
         Ada.Streams.Stream_IO.Open (F, Ada.Streams.Stream_IO.In_File, Path);
         S := Ada.Streams.Stream_IO.Stream (F);
         Content_String'Read (S, Result);
         Ada.Streams.Stream_IO.Close (F);
         return Result;
      end;
   end Read_File;

   function Lower (S : String) return String is (Char.To_Lower (S));

   function Trimmed (S : String) return String is
     (Fix.Trim (S, Ada.Strings.Both));

   function Is_Whitespace (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Is_Block_Tag (Name : String) return Boolean is
   begin
      return Name = "html"
        or else Name = "body"
        or else Name = "div"
        or else Name = "p"
        or else Name = "h1"
        or else Name = "h2"
        or else Name = "h3"
        or else Name = "h4"
        or else Name = "h5"
        or else Name = "h6"
        or else Name = "ul"
        or else Name = "ol"
        or else Name = "li"
        or else Name = "pre"
        or else Name = "blockquote"
        or else Name = "dl"
        or else Name = "dt"
        or else Name = "dd"
        or else Name = "hr"
        or else Name = "center"
        or else Name = "section"
        or else Name = "article"
        or else Name = "header"
        or else Name = "footer"
        or else Name = "nav"
        or else Name = "main"
        or else Name = "aside"
        or else Name = "figure"
        or else Name = "figcaption";
   end Is_Block_Tag;

   function Is_Void_Tag (Name : String) return Boolean is
   begin
      return Name = "br"
        or else Name = "hr"
        or else Name = "img"
        or else Name = "link"
        or else Name = "meta"
        or else Name = "input";
   end Is_Void_Tag;

   function Is_Self_Closing
     (Raw_Tag : String;
      Name    : String) return Boolean
   is
      T : constant String := Trimmed (Raw_Tag);
   begin
      if Is_Void_Tag (Name) then
         return True;
      end if;

      return T'Length > 0 and then T (T'Last) = '/';
   end Is_Self_Closing;

   function Find_Tag_End
     (Source   : String;
      Open_Pos : Positive) return Natural
   is
      I        : Positive := Open_Pos;
      In_Quote : Character := ASCII.NUL;
   begin
      while I <= Source'Last loop
         if In_Quote = ASCII.NUL then
            if Source (I) = '"' or else Source (I) = ''' then
               In_Quote := Source (I);
            elsif Source (I) = '>' then
               return I;
            end if;
         elsif Source (I) = In_Quote then
            In_Quote := ASCII.NUL;
         end if;

         I := I + 1;
      end loop;

      return 0;
   end Find_Tag_End;

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

   function Extract_Attribute
     (Tag_Content : String;
      Name        : String) return String
   is
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

   function Decode_Entities (S : String) return String is
      Result : Unbounded_String := Null_Unbounded_String;
      I      : Positive := S'First;

      function Hex_Value (C : Character) return Integer is
      begin
         if C in '0' .. '9' then
            return Character'Pos (C) - Character'Pos ('0');
         elsif C in 'a' .. 'f' then
            return 10 + Character'Pos (C) - Character'Pos ('a');
         elsif C in 'A' .. 'F' then
            return 10 + Character'Pos (C) - Character'Pos ('A');
         else
            return -1;
         end if;
      end Hex_Value;

      procedure Append_Entity_Literal (Semi : Natural) is
      begin
         if Semi > 0 then
            Append (Result, S (I .. Semi));
            I := Semi + 1;
         else
            Append (Result, S (I));
            I := I + 1;
         end if;
      end Append_Entity_Literal;
   begin
      while I <= S'Last loop
         if S (I) /= '&' then
            Append (Result, S (I));
            I := I + 1;
         else
            declare
               Semi : constant Natural := Fix.Index (S, ";", From => I + 1);
            begin
               if Semi = 0 or else Semi <= I + 1 or else Semi - I > 16 then
                  Append_Entity_Literal (Semi);
               else
                  declare
                     Entity  : constant String := Lower (S (I + 1 .. Semi - 1));
                     Decoded : Character := ASCII.NUL;
                     Valid   : Boolean := True;
                  begin
                     if Entity = "amp" then
                        Decoded := '&';
                     elsif Entity = "lt" then
                        Decoded := '<';
                     elsif Entity = "gt" then
                        Decoded := '>';
                     elsif Entity = "quot" then
                        Decoded := '"';
                     elsif Entity = "apos" or else Entity = "#39" then
                        Decoded := ''';
                     elsif Entity'Length > 1 and then Entity (Entity'First) = '#' then
                        declare
                           Code : Integer := -1;
                        begin
                           if Entity'Length > 2
                             and then (Entity (Entity'First + 1) = 'x'
                                       or else Entity (Entity'First + 1) = 'X')
                           then
                              Code := 0;
                              for K in Entity'First + 2 .. Entity'Last loop
                                 declare
                                    H : constant Integer := Hex_Value (Entity (K));
                                 begin
                                    if H < 0 then
                                       Code := -1;
                                       exit;
                                    end if;
                                    Code := Code * 16 + H;
                                 end;
                              end loop;
                           else
                              begin
                                 Code := Integer'Value (Entity (Entity'First + 1 .. Entity'Last));
                              exception
                                 when others =>
                                    Code := -1;
                              end;
                           end if;

                           if Code >= 0 and then Code <= 255 then
                              Decoded := Character'Val (Code);
                           else
                              Valid := False;
                           end if;
                        end;
                     else
                        Valid := False;
                     end if;

                     if Valid and then Decoded /= ASCII.NUL then
                        Append (Result, Decoded);
                        I := Semi + 1;
                     else
                        Append_Entity_Literal (Semi);
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;

      return To_String (Result);
   end Decode_Entities;

   procedure Append_Child
     (Self         : in out Html_View;
      Parent_Index : Positive;
      Child_Index  : Positive)
   is
      Parent_Node : Node := Self.Nodes.Element (Parent_Index);
   begin
      if Parent_Node.Kind /= Element_Node then
         return;
      end if;

      Parent_Node.Children.Append (Natural (Child_Index));
      Self.Nodes.Replace_Element (Parent_Index, Parent_Node);
   end Append_Child;

   function Append_Element_Node
     (Self   : in out Html_View;
      Parent : Natural;
      Tag    : String;
      Attrs  : Element_Attributes) return Positive
   is
      Idx : Positive;
   begin
      Self.Nodes.Append
        (New_Item =>
           Node'
             (Kind     => Element_Node,
              Parent   => Parent,
              Tag_Name => To_Unbounded_String (Lower (Tag)),
              Attrs    => Attrs,
              Children => <>));

      Idx := Positive (Self.Nodes.Last_Index);

      if Parent > 0 then
         Append_Child (Self, Positive (Parent), Idx);
      end if;

      return Idx;
   end Append_Element_Node;

   procedure Append_Text_Node
     (Self         : in out Html_View;
      Parent_Index : Positive;
      S            : String)
   is
      Decoded : constant String := Decode_Entities (S);
      Idx     : Positive;
   begin
      if Decoded'Length = 0 then
         return;
      end if;

      Self.Nodes.Append
        (New_Item =>
           Node'
             (Kind   => Text_Node,
              Parent => Natural (Parent_Index),
              Text   => To_Unbounded_String (Decoded)));
      Idx := Positive (Self.Nodes.Last_Index);
      Append_Child (Self, Parent_Index, Idx);
   end Append_Text_Node;

   procedure Append_Break_Node
     (Self         : in out Html_View;
      Parent_Index : Positive)
   is
      Idx : Positive;
   begin
      Self.Nodes.Append
        (New_Item =>
           Node'
             (Kind   => Break_Node,
              Parent => Natural (Parent_Index)));
      Idx := Positive (Self.Nodes.Last_Index);
      Append_Child (Self, Parent_Index, Idx);
   end Append_Break_Node;

   function Default_Internal_Part_Styles return Part_Style_Array is
      Main_Base : constant Style_Rules := (
        Flex_Grow => Set (1.0),
        Min_Height => Set (Size (Px (0.0))),
        Overflow_X => Set_Overflow_X (Overflow_Auto),
        Overflow_Y => Set_Overflow_Y (Overflow_Auto),
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
        Text_Part     => (Style => From (Label_Base).Build, Enabled => True),
        Indicator_Part => (Style => From (Link_Base).Build, Enabled => True),
        Scroll_Part    => (Style => From (Scroll_Base).Build, Enabled => True),
        Knob_Part      => (Style => From (Knob_Base).Build, Enabled => True),
        others         => <>];
   end Default_Internal_Part_Styles;

   function Default_Content_Style return Style_Rules is
   begin
      return
        (Display => Set (Inline),
         others => <>);
   end Default_Content_Style;

   function Tag_Default_Style (Tag : String) return Style_Rules is
      Inline_Base : constant Style_Rules := (Display => Set (Inline), others => <>);
      Block_Base  : constant Style_Rules := (Display => Set (Block), others => <>);
      Img_Base    : constant Style_Rules := (Display => Set (Inline_Block), others => <>);
      Pre_Base    : constant Style_Rules := (
        Display     => Set (Block),
        White_Space => Set (WS_Pre_Wrap),
        others      => <>);
      UL_Base     : constant Style_Rules := (
        Display             => Set (Block),
        List_Style_Type     => Set ((Kind => List_Style_Disc)),
        List_Style_Position => Set (List_Outside),
        others              => <>);
      OL_Base     : constant Style_Rules := (
        Display             => Set (Block),
        List_Style_Type     => Set ((Kind => List_Style_Decimal)),
        List_Style_Position => Set (List_Outside),
        others              => <>);
      Center_Base : constant Style_Rules := (
        Display    => Set (Block),
        Text_Align => Set (Text_Center),
        others     => <>);
   begin
      --  Lists: structural marker type and position defaults
      if Tag = "ul" then
         return UL_Base;
      elsif Tag = "ol" then
         return OL_Base;

      --  Center: structural text-align default
      elsif Tag = "center" then
         return Center_Base;

      --  Block elements
      elsif Tag = "html"
        or else Tag = "body"
        or else Tag = "div"
        or else Tag = "p"
        or else Tag = "h1"
        or else Tag = "h2"
        or else Tag = "h3"
        or else Tag = "h4"
        or else Tag = "h5"
        or else Tag = "h6"
        or else Tag = "li"
        or else Tag = "hr"
        or else Tag = "blockquote"
        or else Tag = "dl"
        or else Tag = "dt"
        or else Tag = "dd"
        or else Tag = "section"
        or else Tag = "article"
        or else Tag = "header"
        or else Tag = "footer"
        or else Tag = "nav"
        or else Tag = "main"
        or else Tag = "aside"
        or else Tag = "figure"
        or else Tag = "figcaption"
      then
         return Block_Base;

      --  Pre: block with whitespace preservation (structural, not visual)
      elsif Tag = "pre" then
         return Pre_Base;

      --  Inline-block elements (atomic inline boxes)
      elsif Tag = "img" or else Tag = "svg" then
         return Img_Base;

      --  Inline elements
      elsif Tag = "span"
        or else Tag = "a"
        or else Tag = "b"
        or else Tag = "strong"
        or else Tag = "em"
        or else Tag = "i"
        or else Tag = "code"
        or else Tag = "s"
        or else Tag = "del"
        or else Tag = "ins"
        or else Tag = "u"
        or else Tag = "small"
        or else Tag = "mark"
        or else Tag = "abbr"
        or else Tag = "kbd"
        or else Tag = "var"
        or else Tag = "samp"
        or else Tag = "q"
        or else Tag = "cite"
        or else Tag = "time"
      then
         return Inline_Base;

      --  Unknown tags: default to inline
      else
         return Default_Content_Style;
      end if;
   end Tag_Default_Style;

   function Selector_Base_Rules (Styles : Part_Style_Array) return Style_Rules is
   begin
      return Styles (Main_Part).Style.Base;
   end Selector_Base_Rules;

   function Parse_Inline_Style_Rules
     (Self        : in out Html_View;
      Inline_Text : String) return Style_Rules
   is
      Key : constant String := Trimmed (Inline_Text);
      Tmp : Adi.CSS_Parser.Stylesheet;
      Ok  : Boolean := True;
      Out_Rules : Style_Rules := Empty_Style;
   begin
      if Key'Length = 0 then
         return Empty_Style;
      end if;

      for Cache_Entry of Self.Inline_Style_Cache loop
         if To_String (Cache_Entry.Inline_Text) = Key then
            return Cache_Entry.Rules;
         end if;
      end loop;

      Adi.CSS_Parser.Load_String
        (Tmp,
         ".__inline__ { " & Key & " }",
         Ok);

      if Ok then
         Out_Rules := Selector_Base_Rules (Adi.CSS_Parser.Styles_For_Class (Tmp, "__inline__"));
      else
         Adi.Log.Debug ("Html_View: inline style parse failed: " & Key);
      end if;

      Self.Inline_Style_Cache.Append
        (New_Item =>
           Inline_Style_Cache_Entry'
             (Inline_Text => To_Unbounded_String (Key),
              Rules       => Out_Rules));
      return Out_Rules;
   end Parse_Inline_Style_Rules;

   function Element_Cascade_Rules
     (Self  : in out Html_View;
      Tag   : String;
      Attrs : Element_Attributes) return Style_Rules
   is
      Result      : Style_Rules := Tag_Default_Style (Tag);
      Class_Value : constant String := To_String (Attrs.Class_Attr);
      Id_Value    : constant String := Lower (Trimmed (To_String (Attrs.Id_Attr)));
      I           : Integer := Class_Value'First;
   begin
      if Adi.CSS_Parser.Has_Tag (Self.CSS_Sheet, Tag) then
         Result := Merge (Result, Selector_Base_Rules (Adi.CSS_Parser.Styles_For_Tag (Self.CSS_Sheet, Tag)));
      end if;

      while I <= Class_Value'Last loop
         while I <= Class_Value'Last and then Is_Whitespace (Class_Value (I)) loop
            I := I + 1;
         end loop;
         exit when I > Class_Value'Last;

         declare
            Start : constant Integer := I;
         begin
            while I <= Class_Value'Last and then not Is_Whitespace (Class_Value (I)) loop
               I := I + 1;
            end loop;

            if I > Start then
               declare
                  Name : constant String := Lower (Class_Value (Start .. I - 1));
               begin
                  if Adi.CSS_Parser.Has_Class (Self.CSS_Sheet, Name) then
                     Result := Merge
                       (Result,
                        Selector_Base_Rules (Adi.CSS_Parser.Styles_For_Class (Self.CSS_Sheet, Name)));
                  end if;
               end;
            end if;
         end;
      end loop;

      if Id_Value'Length > 0 and then Adi.CSS_Parser.Has_Id (Self.CSS_Sheet, Id_Value) then
         Result := Merge (Result, Selector_Base_Rules (Adi.CSS_Parser.Styles_For_Id (Self.CSS_Sheet, Id_Value)));
      end if;

      if Length (Attrs.Style_Attr) > 0 then
         Result := Merge (Result, Parse_Inline_Style_Rules (Self, To_String (Attrs.Style_Attr)));
      end if;

      return Result;
   end Element_Cascade_Rules;

   function Resolve_Element_Style
     (Rules      : Style_Rules;
      Parent     : Resolved_Style;
      Has_Parent : Boolean) return Resolved_Style
   is
      Result : Resolved_Style := Resolve (Rules);

      function Color_Is_Inherit (C : Color_Value) return Boolean is
      begin
         return C.Kind = Named and then C.Name = Inherit;
      end Color_Is_Inherit;
   begin
      if not Has_Parent then
         return Result;
      end if;

      if (not Opt_Text_Color.Is_Set (Rules.Color)) or else Color_Is_Inherit (Result.Color) then
         Result.Color := Parent.Color;
      end if;

      if not Opt_Font.Is_Set (Rules.Font_Family) then
         Result.Font_Family := Parent.Font_Family;
      end if;

      if not Opt_Font_Size.Is_Set (Rules.Font_Size) then
         Result.Font_Size := Parent.Font_Size;
      end if;

      if not Opt_Font_Weight.Is_Set (Rules.Font_Weight) then
         Result.Font_Weight := Parent.Font_Weight;
      end if;

      if not Opt_Font_Style.Is_Set (Rules.Font_Style) then
         Result.Font_Style := Parent.Font_Style;
      end if;

      if not Opt_Text_Decoration.Is_Set (Rules.Text_Decoration) then
         Result.Text_Decoration := Parent.Text_Decoration;
      end if;

      if not Opt_List_Style_Type.Is_Set (Rules.List_Style_Type) then
         Result.List_Style_Type := Parent.List_Style_Type;
      end if;

      if not Opt_List_Style_Image.Is_Set (Rules.List_Style_Image) then
         Result.List_Style_Image := Parent.List_Style_Image;
      end if;

      if not Opt_List_Style_Position.Is_Set (Rules.List_Style_Position) then
         Result.List_Style_Position := Parent.List_Style_Position;
      end if;

      if not Opt_Text_Align.Is_Set (Rules.Text_Align) then
         Result.Text_Align := Parent.Text_Align;
      end if;

      if not Opt_White_Space.Is_Set (Rules.White_Space) then
         Result.White_Space := Parent.White_Space;
      end if;

      if not Opt_Text_Wrap_Mode.Is_Set (Rules.Text_Wrap_Mode) then
         Result.Text_Wrap_Mode := Parent.Text_Wrap_Mode;
      end if;

      if not Opt_Line_Height.Is_Set (Rules.Line_Height) then
         Result.Line_Height := Parent.Line_Height;
      end if;

      return Result;
   end Resolve_Element_Style;

   function Load_Text_Resource
     (Self : in out Html_View;
      URI  : String) return String
   is
   begin
      if Self.On_Load_Resource /= null then
         declare
            Self_H : constant Html_View_Handle :=
              Try_As_Html_View (Get_Handle (Widget'Class (Self)));
            Txt : constant String := Self.On_Load_Resource (Self_H, URI);
         begin
            if Txt'Length > 0 then
               return Txt;
            end if;
         end;
      end if;

      return "";
   end Load_Text_Resource;

   procedure Load_Combined_CSS
     (Self     : in out Html_View;
      CSS_Text : String)
   is
      Success : Boolean := True;
   begin
      if Length (Self.Default_CSS) > 0 then
         declare
            Combined : constant String :=
              To_String (Self.Default_CSS) & ASCII.LF & CSS_Text;
         begin
            Adi.CSS_Parser.Load_String (Self.CSS_Sheet, Combined, Success);
         end;
      else
         Adi.CSS_Parser.Load_String (Self.CSS_Sheet, CSS_Text, Success);
      end if;
      if not Success then
         Adi.Log.Error
           ("Html_View CSS parse failed: " &
            Adi.CSS_Parser.Get_Last_Error (Self.CSS_Sheet));
      else
         declare
            Meta : constant Adi.CSS_Parser.Stylesheet_Metadata :=
              Adi.CSS_Parser.Get_Metadata (Self.CSS_Sheet);
         begin
            if Meta.Has_Root_Font_Size then
               Self.Root_Font_Size := Meta.Root_Font_Size;
            else
               Self.Root_Font_Size := Default_Font_Size;
            end if;
         end;
      end if;
   end Load_Combined_CSS;

   procedure Parse_HTML (Self : in out Html_View; Source : String) is
      Stack      : Node_Index_Vectors.Vector;
      CSS_Buffer : Unbounded_String := Null_Unbounded_String;

      procedure Append_CSS (S : String) is
      begin
         if S'Length = 0 then
            return;
         end if;

         Append (CSS_Buffer, S);
         Append (CSS_Buffer, ASCII.LF);
      end Append_CSS;

      function Current_Parent return Positive is
      begin
         return Positive (Stack.Element (Positive (Stack.Last_Index)));
      end Current_Parent;
   begin
      Self.Nodes.Clear;

      Self.Nodes.Append
        (New_Item =>
           Node'
             (Kind     => Element_Node,
              Parent   => 0,
              Tag_Name => To_Unbounded_String ("__root__"),
              Attrs    => (others => Null_Unbounded_String),
              Children => <>));
      Stack.Append (New_Item => 1);

      if Source'Length = 0 then
         Load_Combined_CSS (Self, "");
         return;
      end if;

      declare
         I            : Positive := Source'First;
         Text_Start   : Positive := Source'First;
         Lower_Source : constant String := Lower (Source);

         procedure Flush_Text (Stop_At : Natural) is
         begin
            if Stop_At >= Text_Start and then Text_Start <= Source'Last then
               Append_Text_Node (Self, Current_Parent, Source (Text_Start .. Stop_At));
            end if;
         end Flush_Text;

         function Find_Inline_SVG_Close_End
           (Start_After_Open_Tag : Positive) return Natural
         is
            Pos   : Integer := Start_After_Open_Tag;
            Depth : Natural := 1;
         begin
            while Pos <= Source'Last loop
               declare
                  L : constant Natural := Fix.Index (Source, "<", From => Pos);
               begin
                  exit when L = 0;

                  if L + 3 <= Source'Last and then Source (L + 1 .. L + 3) = "!--" then
                     declare
                        Comment_End : constant Natural := Fix.Index (Source, "-->", From => L + 4);
                     begin
                        exit when Comment_End = 0;
                        Pos := Integer (Comment_End) + 3;
                     end;
                  else
                     declare
                        Tag_End : Natural := Find_Tag_End (Source, L + 1);
                     begin
                        if Tag_End = 0 then
                           Tag_End := Fix.Index (Source, ">", From => L + 1);
                        end if;
                        exit when Tag_End = 0;

                        declare
                           Raw_Tag  : constant String := Source (L + 1 .. Tag_End - 1);
                           Tag_Name : constant String := Extract_Tag_Name (Raw_Tag);
                        begin
                           if Tag_Name = "svg" then
                              if Is_Closing_Tag (Raw_Tag) then
                                 if Depth = 1 then
                                    return Tag_End;
                                 end if;
                                 Depth := Depth - 1;
                              elsif not Is_Self_Closing (Raw_Tag, Tag_Name) then
                                 Depth := Depth + 1;
                              end if;
                           end if;
                        end;

                        Pos := Integer (Tag_End) + 1;
                     end;
                  end if;
               end;
            end loop;

            return 0;
         end Find_Inline_SVG_Close_End;
      begin
         while I <= Source'Last loop
            if Source (I) /= '<' then
               I := I + 1;
            else
               if I > Text_Start then
                  Flush_Text (I - 1);
               end if;

               if I + 3 <= Source'Last and then Source (I + 1 .. I + 3) = "!--" then
                  declare
                     Comment_End : constant Natural := Fix.Index (Source, "-->", From => I + 4);
                  begin
                     if Comment_End = 0 then
                        exit;
                     end if;

                     I := Comment_End + 3;
                     Text_Start := I;
                  end;
               else
                  declare
                     End_Pos : Natural := Find_Tag_End (Source, I + 1);
                  begin
                     if End_Pos = 0 then
                        End_Pos := Fix.Index (Source, ">", From => I + 1);
                     end if;

                     if End_Pos = 0 then
                        Append_Text_Node (Self, Current_Parent, Source (I .. Source'Last));
                        exit;
                     elsif End_Pos <= I + 1 then
                        I := End_Pos + 1;
                        Text_Start := I;
                     else
                        declare
                           Raw_Tag      : constant String := Source (I + 1 .. End_Pos - 1);
                           Name         : constant String := Extract_Tag_Name (Raw_Tag);
                           Closing      : constant Boolean := Is_Closing_Tag (Raw_Tag);
                           Consumed_Tag : Boolean := False;
                        begin
                           if Name'Length = 0 then
                              Append_Text_Node (Self, Current_Parent, Source (I .. End_Pos));

                           elsif Name = "style" and then not Closing then
                              declare
                                 Close_Pos : constant Natural :=
                                   Fix.Index (Lower_Source, "</style>", From => End_Pos + 1);
                              begin
                                 if Close_Pos = 0 then
                                    if End_Pos + 1 <= Source'Last then
                                       Append_CSS (Source (End_Pos + 1 .. Source'Last));
                                    end if;
                                    exit;
                                 end if;

                                 if Close_Pos > End_Pos + 1 then
                                    Append_CSS (Source (End_Pos + 1 .. Close_Pos - 1));
                                 end if;

                                 I := Close_Pos + 8;
                                 Text_Start := I;
                                 Consumed_Tag := True;
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

                           elsif Name = "br" and then not Closing then
                              Append_Break_Node (Self, Current_Parent);

                           elsif Name = "svg" and then not Closing then
                              declare
                                 Attrs : Element_Attributes :=
                                   (Id_Attr    => To_Unbounded_String (Extract_Attribute (Raw_Tag, "id")),
                                    Class_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "class")),
                                    Style_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "style")),
                                    Href_Attr  => To_Unbounded_String (Extract_Attribute (Raw_Tag, "href")),
                                    Src_Attr   => To_Unbounded_String (Extract_Attribute (Raw_Tag, "src")),
                                    Alt_Attr   => To_Unbounded_String (Extract_Attribute (Raw_Tag, "alt")),
                                    Value_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "value")),
                                    Svg_Source_Attr => Null_Unbounded_String);
                                 Svg_End : Natural := 0;
                                 begin
                                 if Is_Self_Closing (Raw_Tag, Name) then
                                    declare
                                       Empty_Svg : constant String :=
                                         "<svg xmlns=""http://www.w3.org/2000/svg""></svg>";
                                       Unused_Node_Idx : Positive;
                                    begin
                                       Attrs.Svg_Source_Attr := To_Unbounded_String (Empty_Svg);
                                       Unused_Node_Idx :=
                                         Append_Element_Node
                                         (Self,
                                          Parent => Natural (Current_Parent),
                                          Tag    => Name,
                                          Attrs  => Attrs);
                                       pragma Unreferenced (Unused_Node_Idx);
                                    end;
                                 else
                                    Svg_End := Find_Inline_SVG_Close_End (End_Pos + 1);
                                    if Svg_End > End_Pos then
                                       declare
                                          Unused_Node_Idx : Positive;
                                       begin
                                       Attrs.Svg_Source_Attr := To_Unbounded_String (Source (I .. Svg_End));
                                       Unused_Node_Idx :=
                                         Append_Element_Node
                                         (Self,
                                          Parent => Natural (Current_Parent),
                                          Tag    => Name,
                                          Attrs  => Attrs);
                                       pragma Unreferenced (Unused_Node_Idx);
                                       end;
                                       I := Svg_End + 1;
                                       Text_Start := I;
                                       Consumed_Tag := True;
                                    else
                                       Append_Text_Node (Self, Current_Parent, Source (I .. End_Pos));
                                    end if;
                                 end if;
                              end;

                           elsif Closing then
                              declare
                                 Match_Pos : Natural := 0;
                              begin
                                 for S_Pos in reverse 1 .. Natural (Stack.Length) loop
                                    declare
                                       Candidate_Idx : constant Positive :=
                                         Positive (Stack.Element (Positive (S_Pos)));
                                       Candidate : constant Node := Self.Nodes.Element (Candidate_Idx);
                                    begin
                                       if Candidate.Kind = Element_Node
                                         and then To_String (Candidate.Tag_Name) = Name
                                       then
                                          Match_Pos := S_Pos;
                                          exit;
                                       end if;
                                    end;
                                 end loop;

                                 if Match_Pos > 1 then
                                    while Natural (Stack.Length) >= Match_Pos loop
                                       Stack.Delete_Last;
                                    end loop;
                                 end if;
                              end;

                           else
                              --  Implied close: a new <li> implicitly closes any open <li>
                              --  in the same list scope (do not cross a ul/ol boundary).
                              if Name = "li" then
                                 declare
                                    Implied_Pos : Natural := 0;
                                 begin
                                    for S_Pos in reverse 1 .. Natural (Stack.Length) loop
                                       declare
                                          Candidate_Idx : constant Positive :=
                                            Positive (Stack.Element (Positive (S_Pos)));
                                          Candidate : constant Node :=
                                            Self.Nodes.Element (Candidate_Idx);
                                       begin
                                          if Candidate.Kind = Element_Node then
                                             declare
                                                T : constant String :=
                                                  To_String (Candidate.Tag_Name);
                                             begin
                                                if T = "li" then
                                                   Implied_Pos := S_Pos;
                                                   exit;
                                                elsif T = "ul" or else T = "ol" then
                                                   exit;
                                                end if;
                                             end;
                                          end if;
                                       end;
                                    end loop;

                                    if Implied_Pos > 0 then
                                       while Natural (Stack.Length) >= Implied_Pos loop
                                          Stack.Delete_Last;
                                       end loop;
                                    end if;
                                 end;
                              end if;

                              declare
                                 Attrs : constant Element_Attributes :=
                                   (Id_Attr    => To_Unbounded_String (Extract_Attribute (Raw_Tag, "id")),
                                    Class_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "class")),
                                    Style_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "style")),
                                    Href_Attr  => To_Unbounded_String (Extract_Attribute (Raw_Tag, "href")),
                                    Src_Attr   => To_Unbounded_String (Extract_Attribute (Raw_Tag, "src")),
                                    Alt_Attr   => To_Unbounded_String (Extract_Attribute (Raw_Tag, "alt")),
                                    Value_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "value")),
                                    Svg_Source_Attr => Null_Unbounded_String);
                                 New_Node_Idx : Positive;
                              begin
                                 New_Node_Idx :=
                                   Append_Element_Node
                                     (Self,
                                      Parent => Natural (Current_Parent),
                                      Tag    => Name,
                                      Attrs  => Attrs);

                                 if not Is_Self_Closing (Raw_Tag, Name) then
                                    Stack.Append (New_Item => Natural (New_Node_Idx));
                                 end if;
                              end;
                           end if;

                           if not Consumed_Tag then
                              I := End_Pos + 1;
                              Text_Start := I;
                           end if;
                        end;
                     end if;
                  end;
               end if;
            end if;
         end loop;

         if Text_Start <= Source'Last then
            Flush_Text (Source'Last);
         end if;
      end;

      Load_Combined_CSS (Self, To_String (CSS_Buffer));
   end Parse_HTML;

   function Lookup_Image
     (Self : in out Html_View;
      Src  : String) return Adi.Image.Image_Access
   is
   begin
      for I in 1 .. Natural (Self.Image_Cache.Length) loop
         declare
            Cache_Entry : constant Cached_Image := Self.Image_Cache.Element (Positive (I));
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
         declare
            Self_H : constant Html_View_Handle :=
              Try_As_Html_View (Get_Handle (Widget'Class (Self)));
         begin
            Img := Self.On_Load_Asset (Self_H, Src);
         end;
      end if;

      Self.Image_Cache.Append
        (New_Item => Cached_Image'(Src => To_Unbounded_String (Src), Img => Img));
      return Img;
   end Resolve_Image;

   function Resolve_Inline_SVG
     (Self   : in out Html_View;
      Source : String) return Adi.Image.Image_Access
   is
      Cache_Key : constant String := "__adi_inline_svg__:" & Source;
      Img       : Adi.Image.Image_Access := null;
   begin
      if Source'Length = 0 then
         return null;
      end if;

      Img := Lookup_Image (Self, Cache_Key);
      if Img /= null then
         return Img;
      end if;

      Img := Adi.Image.Load_SVG_From_String (Source => Source);

      Self.Image_Cache.Append
        (New_Item => Cached_Image'(Src => To_Unbounded_String (Cache_Key), Img => Img));
      return Img;
   end Resolve_Inline_SVG;

   function Should_Apply_Content_Scale (L : Length_Value) return Boolean is
   begin
      return L.Unit not in Pct | Vw | Vh;
   end Should_Apply_Content_Scale;

   function Html_Root_Font_Size_Px
     (Root_Font       : Length_Value;
      Scale           : Pixel_Type;
      Viewport_Width  : Pixel_Type := 0.0;
      Viewport_Height : Pixel_Type := 0.0) return Pixel_Type
   is
      Base : constant Pixel_Type :=
        Length_To_Px
          (Root_Font,
           Font_Size       => Default_Root_Font_Size_Px,
           Root_Font_Size  => Default_Root_Font_Size_Px,
           Viewport_Width  => Viewport_Width,
           Viewport_Height => Viewport_Height);
   begin
      if Should_Apply_Content_Scale (Root_Font) then
         return Base * Pixel_Type'Max (0.01, Scale);
      end if;

      return Base;
   end Html_Root_Font_Size_Px;

   function Html_Length_To_Px
     (L               : Length_Value;
      Scale           : Pixel_Type;
      Container_Size  : Pixel_Type := 0.0;
      Font_Size       : Pixel_Type := Default_Root_Font_Size_Px;
      Root_Font_Size  : Pixel_Type := Default_Root_Font_Size_Px;
      Viewport_Width  : Pixel_Type := 0.0;
      Viewport_Height : Pixel_Type := 0.0) return Pixel_Type
   is
      Base : constant Pixel_Type :=
        Length_To_Px
          (L,
           Container_Size  => Container_Size,
           Font_Size       => Font_Size,
           Root_Font_Size  => Root_Font_Size,
           Viewport_Width  => Viewport_Width,
           Viewport_Height => Viewport_Height);
   begin
      if Should_Apply_Content_Scale (L) then
         return Base * Pixel_Type'Max (0.01, Scale);
      end if;

      return Base;
   end Html_Length_To_Px;

   function Measure_Text
     (Style : Resolved_Style;
      S     : String;
      Scale : Pixel_Type;
      Root_Font_Size : Pixel_Type;
      Viewport_Width : Pixel_Type;
      Viewport_Height : Pixel_Type) return Size_2D
   is
      Font_Px : constant Pixel_Type := Pixel_Type'Max
        (1.0,
         Html_Length_To_Px
           (Style.Font_Size,
            Scale,
            Container_Size  => Viewport_Width,
            Font_Size       => Default_Root_Font_Size_Px,
            Root_Font_Size  => Root_Font_Size,
            Viewport_Width  => Viewport_Width,
            Viewport_Height => Viewport_Height));
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Style.Font_Family,
           Size       => Float (Font_Px),
           Weight     => Style.Font_Weight,
           Style      => Style.Font_Style,
           Decoration => Style.Text_Decoration);
      Measured : Size_2D;
   begin
      Measured := Adi.Font.Measure_Text (Attrs => Font_Attrs, Content => S);

      if S'Length > 0 and then (Measured.Width <= 0.0 or else Measured.Height <= 0.0) then
         return
           (Width  => Pixel_Type'Max (1.0, Pixel_Type (S'Length) * Font_Px * 0.55),
            Height => Pixel_Type'Max (1.0, Font_Px * 1.2));
      end if;

      return Measured;
   end Measure_Text;

   function Measure_Line_Height
     (Style : Resolved_Style;
      Scale : Pixel_Type;
      Root_Font_Size : Pixel_Type;
      Viewport_Width : Pixel_Type;
      Viewport_Height : Pixel_Type) return Pixel_Type
   is
      Font_Px : constant Pixel_Type := Pixel_Type'Max
        (1.0,
         Html_Length_To_Px
           (Style.Font_Size,
            Scale,
            Container_Size  => Viewport_Width,
            Font_Size       => Default_Root_Font_Size_Px,
            Root_Font_Size  => Root_Font_Size,
            Viewport_Width  => Viewport_Width,
            Viewport_Height => Viewport_Height));
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Style.Font_Family,
           Size       => Float (Font_Px),
           Weight     => Style.Font_Weight,
           Style      => Style.Font_Style,
           Decoration => Style.Text_Decoration);
      Font : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      M_H  : constant Pixel_Type :=
        Measure_Text
          (Style,
           "M",
           Scale,
           Root_Font_Size,
           Viewport_Width,
           Viewport_Height).Height;
      Natural_Line : Pixel_Type := Pixel_Type'Max (1.0, M_H);
      Result : Pixel_Type := 0.0;
   begin
      if Font /= null then
         Natural_Line := Pixel_Type'Max (Natural_Line, Pixel_Type (TTF_GetFontLineSkip (Font)));
      end if;

      case Style.Line_Height.Kind is
         when LH_Normal =>
            Result := Natural_Line;
         when LH_Number =>
            Result := Pixel_Type'Max (1.0, Font_Px * Pixel_Type (Style.Line_Height.Multiplier));
         when LH_Length =>
            Result := Pixel_Type'Max
              (1.0,
               Html_Length_To_Px
                 (Style.Line_Height.Height,
                  Scale,
                  Container_Size => Natural_Line,
                  Font_Size      => Font_Px,
                  Root_Font_Size => Root_Font_Size,
                  Viewport_Width => Viewport_Width,
                  Viewport_Height => Viewport_Height));
      end case;

      return Pixel_Type'Max (1.0, Result);
   end Measure_Line_Height;

   function Measure_Ascent
     (Style : Resolved_Style;
      Scale : Pixel_Type;
      Root_Font_Size : Pixel_Type;
      Viewport_Width : Pixel_Type;
      Viewport_Height : Pixel_Type) return Pixel_Type
   is
      Font_Px : constant Pixel_Type := Pixel_Type'Max
        (1.0,
         Html_Length_To_Px
           (Style.Font_Size,
            Scale,
            Container_Size  => Viewport_Width,
            Font_Size       => Default_Root_Font_Size_Px,
            Root_Font_Size  => Root_Font_Size,
            Viewport_Width  => Viewport_Width,
            Viewport_Height => Viewport_Height));
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Style.Font_Family,
           Size       => Float (Font_Px),
           Weight     => Style.Font_Weight,
           Style      => Style.Font_Style,
           Decoration => Style.Text_Decoration);
      Font   : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      Line_H : constant Pixel_Type :=
        Measure_Line_Height
          (Style,
           Scale,
           Root_Font_Size,
           Viewport_Width,
           Viewport_Height);
      Asc    : Pixel_Type := Line_H * 0.8;
   begin
      if Font /= null then
         Asc := Pixel_Type (TTF_GetFontAscent (Font));
         if Asc <= 0.0 then
            Asc := Line_H * 0.8;
         end if;
      end if;

      return Pixel_Type'Min (Line_H, Pixel_Type'Max (1.0, Asc));
   end Measure_Ascent;

   function Measure_Descent
     (Style : Resolved_Style;
      Scale : Pixel_Type;
      Root_Font_Size : Pixel_Type;
      Viewport_Width : Pixel_Type;
      Viewport_Height : Pixel_Type) return Pixel_Type
   is
      Font_Px : constant Pixel_Type := Pixel_Type'Max
        (1.0,
         Html_Length_To_Px
           (Style.Font_Size,
            Scale,
            Container_Size  => Viewport_Width,
            Font_Size       => Default_Root_Font_Size_Px,
            Root_Font_Size  => Root_Font_Size,
            Viewport_Width  => Viewport_Width,
            Viewport_Height => Viewport_Height));
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Style.Font_Family,
           Size       => Float (Font_Px),
           Weight     => Style.Font_Weight,
           Style      => Style.Font_Style,
           Decoration => Style.Text_Decoration);
      Font   : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      Line_H : constant Pixel_Type :=
        Measure_Line_Height
          (Style,
           Scale,
           Root_Font_Size,
           Viewport_Width,
           Viewport_Height);
      Desc   : Pixel_Type := 0.0;
   begin
      if Font = null then
         return Pixel_Type'Max
           (0.0,
            Line_H - Measure_Ascent
              (Style,
               Scale,
               Root_Font_Size,
               Viewport_Width,
               Viewport_Height));
      end if;

      Desc := Pixel_Type (TTF_GetFontDescent (Font));
      if Desc < 0.0 then
         Desc := -Desc;
      end if;

      if Desc <= 0.0 then
         Desc := Pixel_Type'Max
           (0.0,
            Line_H - Measure_Ascent
              (Style,
               Scale,
               Root_Font_Size,
               Viewport_Width,
               Viewport_Height));
      end if;

      return Pixel_Type'Min (Line_H, Pixel_Type'Max (0.0, Desc));
   end Measure_Descent;

   function Find_Link_At
     (Self : Html_View;
      X, Y : Pixel_Type) return String
   is
   begin
      for I in 1 .. Natural (Self.Links.Length) loop
         declare
            Frag : constant Link_Fragment := Self.Links.Element (Positive (I));
            G    : constant Rectangle := Frag.Geometry;
         begin
            if Has_Visible_Area (G)
              and then X >= G.X and then X <= G.X + G.Width
              and then Y >= G.Y and then Y <= G.Y + G.Height
            then
               return To_String (Frag.Href);
            end if;
         end;
      end loop;

      return "";
   end Find_Link_At;

   procedure Layout_And_Build (Self : in out Html_View) is
      Main_Style       : constant Resolved_Style := Get_Resolved_Part_Style (Self, Main_Part);
      Text_Part_Style : constant Resolved_Style := Get_Resolved_Part_Style (Self, Text_Part);
      Content          : constant Rectangle := Content_Box (Self.Geometry, Main_Style);
      Root_Font_Px     : constant Pixel_Type :=
        Pixel_Type'Max
          (1.0,
           Html_Root_Font_Size_Px
             (Self.Root_Font_Size,
              Self.Content_Scale,
              Content.Width,
              Content.Height));

      Document_Rules   : Style_Rules := Tag_Default_Style ("body");
      Document_Style   : Resolved_Style;

      Line_Left  : Pixel_Type := Content.X;
      Line_Right : Pixel_Type := Content.X + Content.Width;
      X : Pixel_Type := Content.X;
      Y : Pixel_Type := Content.Y - Get_Scroll_Offset_Y (Self);

      Line_Base_H       : Pixel_Type := 1.0;
      Line_Base_Ascent  : Pixel_Type := 1.0;
      Line_Base_Descent : Pixel_Type := 0.0;
      Current_Line_H       : Pixel_Type := 1.0;
      Current_Line_Ascent  : Pixel_Type := 1.0;
      Current_Line_Descent : Pixel_Type := 0.0;
      Current_Line_Align   : Text_Align_Value := Text_Start;
      Pending_Space : Boolean := False;

      --  Vertical margin collapsing: track the running pending margin
      --  so adjacent block margins collapse to max(bottom, top), and so
      --  margins propagate through transparent parents (collapse-through).
      Prev_Block_Margin_Bottom : Pixel_Type := 0.0;

      --  Panels whose top Y was tentatively set while a margin was still
      --  pending. Their Geometry.Y is rewritten to the committed Y when
      --  Flush_Pending_Margin actually advances Y.
      package Pending_Top_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Positive);

      Pending_Tops : Pending_Top_Vectors.Vector;

      type List_Marker_Kind is (No_Marker, Text_Marker, Image_Marker);

      type List_Marker_Run (Kind : List_Marker_Kind := No_Marker) is record
         case Kind is
            when No_Marker =>
               null;
            when Text_Marker =>
               Text : Unbounded_String := Null_Unbounded_String;
            when Image_Marker =>
               Img : Adi.Image.Image_Access := null;
         end case;
      end record;

      type List_Context is record
         Node_Index  : Positive := 1;
         Ordered     : Boolean := False;
         Next_Number : Natural := 1;
      end record;

      package List_Context_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => List_Context);

      List_Stack : List_Context_Vectors.Vector;

      type Line_Run_Record is record
         Item_Index : Positive := 1;
         Link_Index : Natural := 0;
      end record;

      package Line_Run_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Line_Run_Record);

      Line_Runs : Line_Run_Vectors.Vector;

      procedure Add_Text_Run
        (Text  : String;
         Href  : String;
         Style : Resolved_Style);

      procedure Add_Image_Run
        (Img        : Adi.Image.Image_Access;
         Width      : Pixel_Type;
         Height     : Pixel_Type;
         Href       : String;
         Style      : Resolved_Style);

      procedure Flush_Pending_Margin;

      function Resolve_Box_Edges
        (Box             : CSS_Box_Value;
         Style           : Resolved_Style;
         Container_Width : Pixel_Type) return Edge_Pixels;

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

      function Local_Font_Size_Px (Style : Resolved_Style) return Pixel_Type is
      begin
         return Pixel_Type'Max
           (1.0,
            Html_Length_To_Px
              (Style.Font_Size,
               Self.Content_Scale,
               Container_Size => Content.Height,
               Font_Size      => Default_Root_Font_Size_Px,
               Root_Font_Size => Root_Font_Px,
               Viewport_Width => Content.Width,
               Viewport_Height => Content.Height));
      end Local_Font_Size_Px;

      function Local_Length_To_Px
        (L              : Length_Value;
         Container_Size : Pixel_Type := 0.0;
         Font_Size      : Pixel_Type := Default_Root_Font_Size_Px) return Pixel_Type
      is
      begin
         return Html_Length_To_Px
           (L,
            Scale           => Self.Content_Scale,
            Container_Size  => Container_Size,
            Font_Size       => Font_Size,
            Root_Font_Size  => Root_Font_Px,
            Viewport_Width  => Content.Width,
            Viewport_Height => Content.Height);
      end Local_Length_To_Px;

      function Current_Line_Width return Pixel_Type is
      begin
         return Pixel_Type'Max (0.0, Line_Right - Line_Left);
      end Current_Line_Width;

      function Has_Line_Content return Boolean is
      begin
         return X > Line_Left or else Natural (Line_Runs.Length) > 0;
      end Has_Line_Content;

      function Parse_Positive_Natural
        (Text  : String;
         Value : out Natural) return Boolean
      is
         V : Integer;
      begin
         Value := 0;
         begin
            V := Integer'Value (Trimmed (Text));
         exception
            when others =>
               return False;
         end;

         if V <= 0 then
            return False;
         end if;

         Value := Natural (V);
         return True;
      end Parse_Positive_Natural;

      function Find_List_Context (Node_Index : Natural) return Natural is
      begin
         if Node_Index = 0 then
            return 0;
         end if;

         for I in reverse 1 .. Natural (List_Stack.Length) loop
            if List_Stack.Element (Positive (I)).Node_Index = Positive (Node_Index) then
               return I;
            end if;
         end loop;

         return 0;
      end Find_List_Context;

      function Marker_Image_For
        (Kind : List_Style_Type_Kind) return Image_Access
      is
      begin
         Ensure_Marker_Images;
         case Kind is
            when List_Style_Disc   => return Disc_Marker_Img;
            when List_Style_Circle => return Circle_Marker_Img;
            when List_Style_Square => return Square_Marker_Img;
            when others            => return null;
         end case;
      end Marker_Image_For;

      function Marker_Text_For
        (Style          : Resolved_Style;
         Ordered_Number : Natural) return String
      is
      begin
         case Style.List_Style_Type.Kind is
            when List_Style_Decimal =>
               return Trimmed (Natural'Image (Natural'Max (1, Ordered_Number))) & ".";
            when List_Style_Custom_String =>
               return To_String (Style.List_Style_Type.Marker);
            when others =>
               return "";
         end case;
      end Marker_Text_For;

      procedure Resolve_List_Marker
        (Style          : Resolved_Style;
         Ordered_Number : Natural;
         Marker         : out List_Marker_Run;
         Marker_Width   : out Pixel_Type;
         Marker_Height  : out Pixel_Type)
      is
      begin
         Marker := (Kind => No_Marker);
         Marker_Width := 0.0;
         Marker_Height := 0.0;

         --  list-style-image takes precedence
         if Style.List_Style_Image.Kind = List_Image_URL then
            declare
               URI : constant String := To_String (Style.List_Style_Image.URI);
               Img : constant Adi.Image.Image_Access := Resolve_Image (Self, URI);
               W   : Pixel_Type := 0.0;
               H   : Pixel_Type := 0.0;
               Target_H : Pixel_Type := Pixel_Type'Max
                 (4.0,
                 Measure_Line_Height
                    (Style,
                     Self.Content_Scale,
                     Root_Font_Px,
                     Content.Width,
                     Content.Height) * 0.72);
            begin
               if Img /= null and then Adi.Image.Is_Valid (Img.all) then
                  Adi.Image.Get_Size (Img.all, W, H);
                  if H > 0.0 then
                     Marker_Height := Target_H;
                     Marker_Width := Pixel_Type'Max (1.0, Target_H * (W / H));
                     Marker := (Kind => Image_Marker,
                                Img  => Img);
                     return;
                  end if;
               end if;
            end;
         end if;

         --  SVG image markers for disc/circle/square
         case Style.List_Style_Type.Kind is
            when List_Style_Disc | List_Style_Circle | List_Style_Square =>
               declare
                  Img : constant Image_Access :=
                    Marker_Image_For (Style.List_Style_Type.Kind);
                  Target_H : constant Pixel_Type := Pixel_Type'Max
                    (4.0,
                     Measure_Line_Height
                       (Style,
                        Self.Content_Scale,
                        Root_Font_Px,
                        Content.Width,
                        Content.Height) * 0.55);
               begin
                  if Img /= null then
                     Marker_Height := Target_H;
                     Marker_Width := Target_H;
                     Marker := (Kind => Image_Marker,
                                Img  => Img);
                     return;
                  end if;
               end;
            when others =>
               null;
         end case;

         --  Text markers (decimal, custom)
         declare
            Marker_Text : constant String :=
              Marker_Text_For (Style, Ordered_Number);
            Marker_Size : Size_2D;
         begin
            if Marker_Text'Length = 0 then
               return;
            end if;

            Marker_Size :=
              Measure_Text
                (Style,
                 Marker_Text,
                 Self.Content_Scale,
                 Root_Font_Px,
                 Content.Width,
                 Content.Height);
            Marker_Width := Pixel_Type'Max (1.0, Marker_Size.Width);
            Marker_Height := Pixel_Type'Max
              (1.0,
               Measure_Line_Height
                 (Style,
                  Self.Content_Scale,
                  Root_Font_Px,
                  Content.Width,
                  Content.Height));
            Marker := (Kind => Text_Marker,
                       Text => To_Unbounded_String (Marker_Text));
         end;
      end Resolve_List_Marker;

      procedure Add_Outside_Marker_Run
        (Marker       : List_Marker_Run;
         Marker_Width : Pixel_Type;
         Marker_Height : Pixel_Type;
         Marker_Gap   : Pixel_Type;
         Style        : Resolved_Style)
      is
         Saved_X  : constant Pixel_Type := X;
         Marker_X : constant Pixel_Type := Saved_X - Marker_Gap - Marker_Width;
      begin
         case Marker.Kind is
            when No_Marker =>
               null;
            when Text_Marker =>
               X := Marker_X;
               Add_Text_Run (To_String (Marker.Text), "", Style);
               X := Saved_X;
            when Image_Marker =>
               X := Marker_X;
               Add_Image_Run (Marker.Img, Marker_Width, Marker_Height, "",
                              Style);
               X := Saved_X;
         end case;
      end Add_Outside_Marker_Run;

      procedure Add_Inside_Marker_Run
        (Marker       : List_Marker_Run;
         Marker_Width : Pixel_Type;
         Marker_Height : Pixel_Type;
         Marker_Gap   : Pixel_Type;
         Style        : Resolved_Style)
      is
      begin
         case Marker.Kind is
            when No_Marker =>
               null;
            when Text_Marker =>
               Add_Text_Run (To_String (Marker.Text), "", Style);
               X := X + Marker_Gap;
            when Image_Marker =>
               Add_Image_Run (Marker.Img, Marker_Width, Marker_Height, "",
                              Style);
               X := X + Marker_Gap;
         end case;
      end Add_Inside_Marker_Run;

      procedure Sync_Line_Heights is
      begin
         for Run of Line_Runs loop
            declare
               Item_Ref : Item renames Self.Items.Reference (Run.Item_Index).Element.all;
            begin
               Item_Ref.Geometry.Height := Pixel_Type'Max (Item_Ref.Geometry.Height, Current_Line_H);
            end;
         end loop;
      end Sync_Line_Heights;

      procedure Shift_Line (Delta_Y : Pixel_Type) is
      begin
         if Delta_Y <= 0.0 then
            return;
         end if;

         for Run of Line_Runs loop
            declare
               Item_Ref : Item renames Self.Items.Reference (Run.Item_Index).Element.all;
            begin
               if Item_Ref.Kind = Text_Item then
                  Item_Ref.Text_Offset_Y := Item_Ref.Text_Offset_Y + Delta_Y;
               else
                  Item_Ref.Geometry.Y := Item_Ref.Geometry.Y + Delta_Y;
               end if;
            end;

            if Run.Link_Index > 0 and then Run.Link_Index <= Natural (Self.Links.Length) then
               declare
                  Link_Ref : Link_Fragment renames
                    Self.Links.Reference (Positive (Run.Link_Index)).Element.all;
               begin
                  Link_Ref.Geometry.Y := Link_Ref.Geometry.Y + Delta_Y;
               end;
            end if;
         end loop;
      end Shift_Line;

      procedure Finalize_Line is
         Used_Width : constant Pixel_Type := Pixel_Type'Max (0.0, X - Line_Left);
         Available_Width : constant Pixel_Type := Current_Line_Width;
         Shift_X : Pixel_Type := 0.0;
      begin
         Sync_Line_Heights;

         if Natural (Line_Runs.Length) = 0 then
            return;
         end if;

         case Current_Line_Align is
            when Text_Center =>
               if Used_Width < Available_Width then
                  Shift_X := (Available_Width - Used_Width) / 2.0;
               end if;
            when Text_Right | Text_End =>
               if Used_Width < Available_Width then
                  Shift_X := Available_Width - Used_Width;
               end if;
            when others =>
               null;
         end case;

         for Run of Line_Runs loop
            declare
               Item_Ref : Item renames Self.Items.Reference (Run.Item_Index).Element.all;
            begin
               Item_Ref.Geometry.X := Item_Ref.Geometry.X + Shift_X;
            end;

            if Run.Link_Index > 0 and then Run.Link_Index <= Natural (Self.Links.Length) then
               declare
                  Link_Ref : Link_Fragment renames
                    Self.Links.Reference (Positive (Run.Link_Index)).Element.all;
               begin
                  Link_Ref.Geometry.X := Link_Ref.Geometry.X + Shift_X;
                  Link_Ref.Geometry := Clip_To_Content (Link_Ref.Geometry);
               end;
            end if;
         end loop;
      end Finalize_Line;

      procedure New_Line is
      begin
         Finalize_Line;
         X := Line_Left;
         Y := Y + Current_Line_H;
         Current_Line_H := Line_Base_H;
         Current_Line_Ascent := Line_Base_Ascent;
         Current_Line_Descent := Line_Base_Descent;
         Line_Runs.Clear;
         Pending_Space := False;
      end New_Line;

      function Wrap_Allowed (Style : Resolved_Style) return Boolean is
      begin
         return Style.Text_Wrap_Mode = TWM_Wrap
           and then Style.White_Space /= WS_Nowrap
           and then Style.White_Space /= WS_Pre;
      end Wrap_Allowed;

      function Add_Link_Fragment
        (Geom : Rectangle;
         Href : String) return Natural is
      begin
         if Href'Length = 0 then
            return 0;
         end if;

         Self.Links.Append
           (New_Item => Link_Fragment'(Geometry => Geom, Href => To_Unbounded_String (Href)));
         return Natural (Self.Links.Last_Index);
      end Add_Link_Fragment;

      procedure Add_Text_Run
        (Text  : String;
         Href  : String;
         Style : Resolved_Style)
      is
         Slice_First : Integer := Text'First;
         Slice_Last  : constant Integer := Text'Last;
         Draw_Text   : Unbounded_String := Null_Unbounded_String;
         Run_W       : Pixel_Type := 0.0;
         Run_H       : Pixel_Type := 1.0;
         Run_Ascent  : Pixel_Type := 1.0;
         Run_Descent : Pixel_Type := 0.0;
         Full_Geom   : Rectangle := (0.0, 0.0, 0.0, 0.0);
      begin
         if Text'Length = 0 then
            return;
         end if;

         Flush_Pending_Margin;

         if Wrap_Allowed (Style)
           and then X > Line_Left
            and then X
              + Measure_Text
                  (Style,
                   Text,
                   Self.Content_Scale,
                   Root_Font_Px,
                   Content.Width,
                   Content.Height).Width > Line_Right
         then
            New_Line;
            while Slice_First <= Slice_Last and then Text (Slice_First) = ' ' loop
               Slice_First := Slice_First + 1;
            end loop;
         end if;

         if Slice_First > Slice_Last then
            return;
         end if;

         declare
            S : constant String := Text (Slice_First .. Slice_Last);
         begin
            Draw_Text := To_Unbounded_String (S);
         end;

         Run_W :=
           Measure_Text
             (Style,
              To_String (Draw_Text),
              Self.Content_Scale,
              Root_Font_Px,
              Content.Width,
              Content.Height).Width;
         Run_H :=
           Measure_Line_Height
             (Style,
              Self.Content_Scale,
              Root_Font_Px,
              Content.Width,
              Content.Height);
         Run_Ascent :=
           Measure_Ascent
             (Style,
              Self.Content_Scale,
              Root_Font_Px,
              Content.Width,
              Content.Height);
         Run_Descent :=
           Measure_Descent
             (Style,
              Self.Content_Scale,
              Root_Font_Px,
              Content.Width,
              Content.Height);

         if Run_Ascent > Current_Line_Ascent then
            declare
               Shift_Amount : constant Pixel_Type := Run_Ascent - Current_Line_Ascent;
            begin
               Current_Line_Ascent := Run_Ascent;
               Shift_Line (Shift_Amount);
            end;
         end if;

         if Run_Descent > Current_Line_Descent then
            Current_Line_Descent := Run_Descent;
         end if;

         Current_Line_H :=
           Pixel_Type'Max
             (Current_Line_H,
              Pixel_Type'Max (Run_H, Current_Line_Ascent + Current_Line_Descent));

         Full_Geom :=
           (X      => X,
            Y      => Y,
            Width  => Run_W,
            Height => Current_Line_H);

         declare
            It : Item :=
              Make_Text
                 ((if Href'Length > 0 then Indicator_Part else Text_Part),
                  Full_Geom,
                  To_String (Draw_Text),
                  1);
            Item_Index : Positive;
            Link_Index : Natural := 0;
            Render_Style : Resolved_Style := Style;
         begin
            It.Wrap_Text := False;
            It.Text_Offset_Y := Current_Line_Ascent - Run_Ascent;
            It.Has_Style_Override := True;
            Render_Style.Font_Size := Pixels_As_Length (Local_Font_Size_Px (Style));
            It.Style_Override := Render_Style;
            Add_Item (Self, It);

            Item_Index := Positive (Self.Items.Last_Index);
            Link_Index := Add_Link_Fragment (Full_Geom, Href);
            Line_Runs.Append
              (New_Item =>
                 Line_Run_Record'
                   (Item_Index => Item_Index,
                    Link_Index => Link_Index));
         end;

         X := X + Run_W;
      end Add_Text_Run;

      procedure Add_Image_Run
        (Img        : Adi.Image.Image_Access;
         Width      : Pixel_Type;
         Height     : Pixel_Type;
         Href       : String;
         Style      : Resolved_Style)
      is
         Run_Ascent  : constant Pixel_Type := Height;
         Run_Descent : constant Pixel_Type := 0.0;
         Top_Y       : Pixel_Type := 0.0;
         Full_Geom   : Rectangle := (0.0, 0.0, 0.0, 0.0);
      begin
         if Width <= 0.0 or else Height <= 0.0 then
            return;
         end if;

         Flush_Pending_Margin;

         if Wrap_Allowed (Style)
           and then X > Line_Left
           and then X + Width > Line_Right
         then
            New_Line;
         end if;

         if Run_Ascent > Current_Line_Ascent then
            declare
               Shift_Amount : constant Pixel_Type := Run_Ascent - Current_Line_Ascent;
            begin
               Current_Line_Ascent := Run_Ascent;
               Shift_Line (Shift_Amount);
            end;
         end if;

         if Run_Descent > Current_Line_Descent then
            Current_Line_Descent := Run_Descent;
         end if;

         Current_Line_H :=
           Pixel_Type'Max
             (Current_Line_H,
              Pixel_Type'Max (Height, Current_Line_Ascent + Current_Line_Descent));

         Top_Y := Y + (Current_Line_Ascent - Run_Ascent);
         Full_Geom :=
           (X      => X,
            Y      => Top_Y,
            Width  => Width,
            Height => Height);

         declare
            It : Item := Make_Image (Icon_Part, Full_Geom, Img, 1);
            Item_Index : Positive;
            Link_Index : Natural := 0;
         begin
            It.Has_Style_Override := True;
            It.Style_Override := Style;
            if Img /= null and then Adi.Image.Is_Tintable (Img.all) then
               It.Style_Override.Object_Fit := Fit_Scale_Down;
               It.Style_Override.Object_Position :=
                 Object_Position (Pos_Center, Pos_Top);
            end if;
            Add_Item (Self, It);

            Item_Index := Positive (Self.Items.Last_Index);
            Link_Index := Add_Link_Fragment (Full_Geom, Href);
            Line_Runs.Append
              (New_Item =>
                 Line_Run_Record'
                   (Item_Index => Item_Index,
                    Link_Index => Link_Index));
         end;

         X := X + Width;
      end Add_Image_Run;

      procedure Add_Horizontal_Rule (Style : Resolved_Style) is
         Margin_Edges : constant Edge_Pixels :=
           Resolve_Box_Edges (Style.Margin, Style, Current_Line_Width);
         Rule_H : Pixel_Type := 1.0;
         Rule_Geom : Rectangle;
      begin
         if Has_Line_Content or else Pending_Space then
            New_Line;
         end if;

         --  Collapse hr's top margin with anything pending (siblings or a
         --  transparent parent), then commit Y so the rule lands beneath
         --  the collapsed gap.
         Prev_Block_Margin_Bottom :=
           Pixel_Type'Max (Prev_Block_Margin_Bottom, Margin_Edges.Top);
         Flush_Pending_Margin;

         if Style.Height.Kind = Fixed then
            Rule_H := Pixel_Type'Max
              (1.0,
               Local_Length_To_Px
                 (Style.Height.Size,
                  Container_Size => Content.Height,
                  Font_Size => Local_Font_Size_Px (Style)));
         end if;

          Current_Line_H := Pixel_Type'Max (Current_Line_H, Rule_H);
          Rule_Geom :=
            (X      => Line_Left,
             Y      => Y + (Current_Line_H - Rule_H) / 2.0,
             Width  => Current_Line_Width,
             Height => Rule_H);

         declare
            It : Item := Make_Panel (Any_Part, Rule_Geom, 1);
         begin
            It.Has_Style_Override := True;
            It.Style_Override := Style;
            Add_Item (Self, It);
         end;

         New_Line;

         --  Defer hr's bottom margin so it collapses with the next
         --  sibling or propagates outward through a transparent parent.
         Prev_Block_Margin_Bottom := Margin_Edges.Bottom;
      end Add_Horizontal_Rule;

      procedure Process_Collapsed_Text
        (Text  : String;
         Href  : String;
         Style : Resolved_Style)
      is
         Start : Integer := Text'First;
         Stop  : Integer := Text'First;
      begin
         while Start <= Text'Last loop
            if Is_Whitespace (Text (Start)) then
               --  Only latch a pending space when there is real preceding
               --  inline content. Inter-block indentation/newlines must not
               --  set this flag, otherwise block-enter would call New_Line
               --  and bump Y by a line height for nothing.
               if Has_Line_Content then
                  Pending_Space := True;
               end if;
               Start := Start + 1;
            else
               Stop := Start;
               while Stop <= Text'Last and then not Is_Whitespace (Text (Stop)) loop
                  Stop := Stop + 1;
               end loop;

               declare
                  Prefix : constant String :=
                    (if Pending_Space and then X > Line_Left then " " else "");
                  Word : constant String := Text (Start .. Stop - 1);
               begin
                  Add_Text_Run (Prefix & Word, Href, Style);
               end;

               Pending_Space := False;
               Start := Stop;
            end if;
         end loop;
      end Process_Collapsed_Text;

      procedure Process_Pre_Text
        (Text  : String;
         Href  : String;
         Style : Resolved_Style)
      is
         Buffer : Unbounded_String := Null_Unbounded_String;
      begin
         for C of Text loop
            if C = ASCII.CR then
               null;
            elsif C = ASCII.LF then
               if Length (Buffer) > 0 then
                  Add_Text_Run (To_String (Buffer), Href, Style);
                  Buffer := Null_Unbounded_String;
               end if;
               --  A rendered newline is real content; commit any pending
               --  margin so it stops collapse-through, mirroring <br>.
               Flush_Pending_Margin;
               New_Line;
            else
               Append (Buffer, C);
            end if;
         end loop;

         if Length (Buffer) > 0 then
            Add_Text_Run (To_String (Buffer), Href, Style);
         end if;

         Pending_Space := False;
      end Process_Pre_Text;

      procedure Process_Pre_Line_Text
        (Text  : String;
         Href  : String;
         Style : Resolved_Style)
      is
         Segment_Start : Integer := Text'First;
         I             : Integer := Text'First;
      begin
         while I <= Text'Last loop
            if Text (I) = ASCII.LF or else Text (I) = ASCII.CR then
               if I > Segment_Start then
                  Process_Collapsed_Text (Text (Segment_Start .. I - 1), Href, Style);
               end if;

               --  A rendered newline is real content; commit any pending
               --  margin so it stops collapse-through, mirroring <br>.
               Flush_Pending_Margin;
               New_Line;
               Pending_Space := False;

               if Text (I) = ASCII.CR and then I < Text'Last and then Text (I + 1) = ASCII.LF then
                  I := I + 1;
               end if;
               Segment_Start := I + 1;
            end if;

            I := I + 1;
         end loop;

         if Segment_Start <= Text'Last then
            Process_Collapsed_Text (Text (Segment_Start .. Text'Last), Href, Style);
         end if;
      end Process_Pre_Line_Text;

      --  Commit any deferred margin and finalize the top Y of any panels
      --  whose position was tentatively set while waiting for collapse.
      procedure Flush_Pending_Margin is
      begin
         if Prev_Block_Margin_Bottom > 0.0 then
            Y := Y + Prev_Block_Margin_Bottom;
            Prev_Block_Margin_Bottom := 0.0;
         end if;
         for Idx of Pending_Tops loop
            Self.Items.Reference (Idx).Geometry.Y := Y;
         end loop;
         Pending_Tops.Clear;
      end Flush_Pending_Margin;

      procedure Process_Text_Node
        (Text  : String;
         Href  : String;
         Style : Resolved_Style)
      is
      begin
         if Text'Length = 0 then
            return;
         end if;

         --  Note: Flush_Pending_Margin is now called inside Add_Text_Run /
         --  Add_Image_Run. Whitespace-only text in collapsed mode never
         --  reaches those, so it must not commit a pending margin.

         case Style.White_Space is
            when WS_Pre | WS_Pre_Wrap =>
               Process_Pre_Text (Text, Href, Style);
            when WS_Pre_Line =>
               Process_Pre_Line_Text (Text, Href, Style);
            when others =>
               Process_Collapsed_Text (Text, Href, Style);
         end case;
      end Process_Text_Node;

      function Is_Block_Element
        (Tag   : String;
         Rules : Style_Rules;
         Style : Resolved_Style) return Boolean
      is
      begin
         if Opt_Display.Is_Set (Rules.Display) then
            return Style.Display in Block | Flex | Grid;
         end if;

         return Is_Block_Tag (Tag);
      end Is_Block_Element;

      function Resolve_Box_Edges
        (Box             : CSS_Box_Value;
         Style           : Resolved_Style;
         Container_Width : Pixel_Type) return Edge_Pixels
      is
         Font_Px : constant Pixel_Type := Local_Font_Size_Px (Style);

         function To_Px (L : Length_Value) return Pixel_Type is
         begin
            return Local_Length_To_Px
              (L,
               Container_Size => Container_Width,
               Font_Size => Font_Px);
         end To_Px;
      begin
         case Box.Kind is
            when Gap_Uniform =>
               declare
                  V : constant Pixel_Type := To_Px (Box.All_Sides);
               begin
                  return (Top => V, Right => V, Bottom => V, Left => V);
               end;

            when Axis =>
               declare
                  Vert  : constant Pixel_Type := To_Px (Box.Vertical);
                  Horiz : constant Pixel_Type := To_Px (Box.Horizontal);
               begin
                  return (Top => Vert, Right => Horiz, Bottom => Vert, Left => Horiz);
               end;

            when Per_Side =>
               return
                 (Top    => To_Px (Box.Sides (Top)),
                  Right  => To_Px (Box.Sides (Right)),
                  Bottom => To_Px (Box.Sides (Bottom)),
                  Left   => To_Px (Box.Sides (Left)));
         end case;
      end Resolve_Box_Edges;

      procedure Resolve_Image_Run_Size
        (Style : Resolved_Style;
         W     : in out Pixel_Type;
         H     : in out Pixel_Type)
      is
         Target_W : Pixel_Type := 0.0;
         Target_H : Pixel_Type := 0.0;
         Font_Px  : constant Pixel_Type := Local_Font_Size_Px (Style);
      begin
         if H <= 0.0 then
            H := Pixel_Type'Max
              (1.0,
               Measure_Line_Height
                 (Style,
                  Self.Content_Scale,
                  Root_Font_Px,
                  Content.Width,
                  Content.Height));
         end if;

         if Style.Width.Kind = Fixed then
            Target_W := Local_Length_To_Px
              (Style.Width.Size,
               Container_Size => Current_Line_Width,
               Font_Size => Font_Px);
         end if;

         if Style.Height.Kind = Fixed then
            Target_H := Local_Length_To_Px
              (Style.Height.Size,
               Container_Size => Content.Height,
               Font_Size => Font_Px);
         end if;

         if Target_W > 0.0 and then Target_H > 0.0 then
            W := Target_W;
            H := Target_H;
         elsif Target_W > 0.0 then
            if W > 0.0 and then H > 0.0 then
               H := H * (Target_W / W);
            end if;
            W := Target_W;
         elsif Target_H > 0.0 then
            if W > 0.0 and then H > 0.0 then
               W := W * (Target_H / H);
            end if;
            H := Target_H;
         end if;

         W := Pixel_Type'Max (0.0, W);
         H := Pixel_Type'Max (0.0, H);
      end Resolve_Image_Run_Size;

      function Resolve_List_Item_Number
        (Node_Index : Positive;
         Attrs      : Element_Attributes) return Natural
      is
         Ctx_Idx : constant Natural :=
           Find_List_Context (Self.Nodes.Element (Node_Index).Parent);
         Ctx : List_Context;
         Explicit_Value : Natural := 0;
         Number : Natural := 0;
      begin
         if Ctx_Idx = 0 then
            return 0;
         end if;

         Ctx := List_Stack.Element (Positive (Ctx_Idx));
         if not Ctx.Ordered then
            return 0;
         end if;

         if Length (Attrs.Value_Attr) > 0
           and then Parse_Positive_Natural (To_String (Attrs.Value_Attr), Explicit_Value)
         then
            Ctx.Next_Number := Explicit_Value;
         end if;

         Number := Ctx.Next_Number;
         Ctx.Next_Number := Ctx.Next_Number + 1;
         List_Stack.Replace_Element (Positive (Ctx_Idx), Ctx);
         return Number;
      end Resolve_List_Item_Number;

      procedure Layout_Node
        (Node_Index   : Positive;
         Parent_Style : Resolved_Style;
         Active_Link  : String)
      is
         N : constant Node := Self.Nodes.Element (Node_Index);
      begin
         case N.Kind is
            when Text_Node =>
               Process_Text_Node (To_String (N.Text), Active_Link, Parent_Style);

            when Break_Node =>
               --  <br> is rendered content; commit any pending margin so
               --  the break stops collapse-through (a forced line break
               --  cannot be papered over by margin collapsing).
               Flush_Pending_Margin;
               New_Line;

            when Element_Node =>
               declare
                  Tag : constant String := To_String (N.Tag_Name);
                  Rules : constant Style_Rules := Element_Cascade_Rules (Self, Tag, N.Attrs);
                  Style : constant Resolved_Style := Resolve_Element_Style (Rules, Parent_Style, True);
                  Link_Href : constant String :=
                    (if Tag = "a" then To_String (N.Attrs.Href_Attr) else Active_Link);
               begin
                  --  Keep separator space preceding a link outside the link run
                  --  so underline/click hit regions do not extend into that
                  --  left-side collapsed gap.
                  if Tag = "a" and then Pending_Space and then X > Line_Left then
                     Add_Text_Run (" ", "", Parent_Style);
                     Pending_Space := False;
                  end if;

                  if Style.Display = Display_None then
                     null;

                  elsif Tag = "img" then
                     declare
                        Src : constant String := To_String (N.Attrs.Src_Attr);
                        Alt : constant String := To_String (N.Attrs.Alt_Attr);
                        Img : constant Adi.Image.Image_Access := Resolve_Image (Self, Src);
                        W   : Pixel_Type := 0.0;
                        H   : Pixel_Type := 0.0;
                       begin
                        if Img /= null and then Adi.Image.Is_Valid (Img.all) then
                           Adi.Image.Get_Size (Img.all, W, H);
                           W := W * Pixel_Type'Max (0.01, Self.Content_Scale);
                           H := H * Pixel_Type'Max (0.01, Self.Content_Scale);
                        end if;

                        Resolve_Image_Run_Size (Style, W, H);

                        if W > 0.0 then
                           Add_Image_Run (Img, W, H, Link_Href, Style);
                        elsif Alt'Length > 0 then
                           Add_Text_Run (Alt, Link_Href, Style);
                        end if;

                        Pending_Space := True;
                     end;

                  elsif Tag = "svg" then
                     declare
                        Src : constant String := To_String (N.Attrs.Svg_Source_Attr);
                        Img : constant Adi.Image.Image_Access := Resolve_Inline_SVG (Self, Src);
                        W   : Pixel_Type := 0.0;
                        H   : Pixel_Type := 0.0;
                     begin
                        if Img /= null and then Adi.Image.Is_Valid (Img.all) then
                           Adi.Image.Get_Size (Img.all, W, H);
                           W := W * Pixel_Type'Max (0.01, Self.Content_Scale);
                           H := H * Pixel_Type'Max (0.01, Self.Content_Scale);
                        end if;

                        Resolve_Image_Run_Size (Style, W, H);

                        if W > 0.0 then
                           Add_Image_Run (Img, W, H, Link_Href, Style);
                        end if;

                        Pending_Space := True;
                     end;

                  elsif Tag = "hr" then
                     Add_Horizontal_Rule (Style);

                  else
                     declare
                        Block_Flow : constant Boolean := Is_Block_Element (Tag, Rules, Style);
                        Prev_Base_H       : constant Pixel_Type := Line_Base_H;
                        Prev_Base_Ascent  : constant Pixel_Type := Line_Base_Ascent;
                        Prev_Base_Descent : constant Pixel_Type := Line_Base_Descent;
                        Prev_Line_Left    : constant Pixel_Type := Line_Left;
                        Prev_Line_Right   : constant Pixel_Type := Line_Right;
                        Prev_Line_Align   : constant Text_Align_Value := Current_Line_Align;
                        Local_Container_W : constant Pixel_Type := Current_Line_Width;
                        Margin_Edges      : Edge_Pixels := Zero_Edges;
                        Padding_Edges     : Edge_Pixels := Zero_Edges;
                        List_Context_Pushed : Boolean := False;
                        Marker          : List_Marker_Run := (Kind => No_Marker);
                        Marker_W        : Pixel_Type := 0.0;
                        Marker_H        : Pixel_Type := 0.0;
                        Marker_Gap      : Pixel_Type := 0.0;
                        Marker_Gutter   : Pixel_Type := 0.0;
                        Ordered_Number  : Natural := 0;
                        Block_Item_Index : Natural := 0;
                        Block_Top_Y      : Pixel_Type := 0.0;
                        Block_Left_X     : Pixel_Type := 0.0;
                        Block_Width      : Pixel_Type := 0.0;
                       begin
                        if Block_Flow then
                           if Has_Line_Content or else Pending_Space then
                              New_Line;
                           end if;

                           if Tag = "ul" or else Tag = "ol" then
                              List_Stack.Append
                                (New_Item =>
                                   List_Context'
                                     (Node_Index  => Node_Index,
                                      Ordered     => Tag = "ol",
                                      Next_Number => 1));
                              List_Context_Pushed := True;
                           end if;

                           Margin_Edges := Resolve_Box_Edges (Style.Margin, Style, Local_Container_W);
                           Padding_Edges := Resolve_Box_Edges (Style.Padding, Style, Local_Container_W);

                           --  Vertical margin collapsing. Defer the commit
                           --  when there is no top padding/border so the
                           --  parent's top margin can collapse-through with
                           --  its first child's top margin (CSS spec).
                           declare
                              Border_Edges : constant Edge_Pixels :=
                                Get_Border_Width_Px (Style);
                              Has_Top_Sep : constant Boolean :=
                                Padding_Edges.Top > 0.0
                                  or else Border_Edges.Top > 0.0;
                              Combined : constant Pixel_Type :=
                                Pixel_Type'Max
                                  (Margin_Edges.Top, Prev_Block_Margin_Bottom);
                           begin
                              Prev_Block_Margin_Bottom := Combined;
                              Block_Top_Y := Y + Combined;
                              Block_Left_X := Prev_Line_Left + Margin_Edges.Left;
                              Block_Width :=
                                Pixel_Type'Max
                                  (0.0,
                                   (Prev_Line_Right - Prev_Line_Left)
                                   - Margin_Edges.Left - Margin_Edges.Right);

                              declare
                                 It : Item :=
                                   Make_Panel
                                     (Any_Part,
                                      (X      => Block_Left_X,
                                       Y      => Block_Top_Y,
                                       Width  => Block_Width,
                                       Height => 0.0),
                                      0);
                              begin
                                 It.Has_Style_Override := True;
                                 It.Style_Override := Style;
                                 Add_Item (Self, It);
                                 Block_Item_Index := Natural (Self.Items.Last_Index);
                              end;

                              if Has_Top_Sep then
                                 Flush_Pending_Margin;
                                 Y := Block_Top_Y + Padding_Edges.Top;
                              else
                                 Pending_Tops.Append (Positive (Block_Item_Index));
                                 --  Y stays put; first content commits via
                                 --  Flush_Pending_Margin and the panel's Y
                                 --  is rewritten to the committed Y at that
                                 --  point.
                              end if;
                           end;

                           Line_Left := Prev_Line_Left + Margin_Edges.Left + Padding_Edges.Left;
                           Line_Right := Prev_Line_Right - Margin_Edges.Right - Padding_Edges.Right;
                           if Line_Right < Line_Left then
                              Line_Right := Line_Left;
                           end if;

                           X := Line_Left;
                           Current_Line_Align := Style.Text_Align;

                           Line_Base_H := Pixel_Type'Max
                             (1.0,
               Measure_Line_Height
                 (Style,
                  Self.Content_Scale,
                  Root_Font_Px,
                  Content.Width,
                  Content.Height));
                           Line_Base_Ascent := Pixel_Type'Max
                             (1.0,
                              Measure_Ascent
                                (Style,
                                 Self.Content_Scale,
                                 Root_Font_Px,
                                 Content.Width,
                                 Content.Height));
                           Line_Base_Descent := Pixel_Type'Max
                             (0.0,
                              Measure_Descent
                                (Style,
                                 Self.Content_Scale,
                                 Root_Font_Px,
                                 Content.Width,
                                 Content.Height));
                           Current_Line_H := Line_Base_H;
                           Current_Line_Ascent := Line_Base_Ascent;
                           Current_Line_Descent := Line_Base_Descent;
                           Pending_Space := False;

                           if Tag = "li" then
                              Ordered_Number := Resolve_List_Item_Number (Node_Index, N.Attrs);
                              Resolve_List_Marker
                                (Style,
                                 Ordered_Number,
                                 Marker,
                                 Marker_W,
                                 Marker_H);

                              if Marker.Kind /= No_Marker then
                                 Marker_Gap := Pixel_Type'Max (4.0, Local_Font_Size_Px (Style) * 0.35);

                                 if Style.List_Style_Position = List_Outside then
                                    Marker_Gutter := Marker_W + Marker_Gap;
                                    Line_Left := Line_Left + Marker_Gutter;
                                    if Line_Right < Line_Left then
                                       Line_Right := Line_Left;
                                    end if;

                                    X := Line_Left;
                                    Add_Outside_Marker_Run
                                      (Marker,
                                       Marker_W,
                                       Marker_H,
                                       Marker_Gap,
                                       Style);
                                 else
                                    Add_Inside_Marker_Run
                                      (Marker,
                                       Marker_W,
                                       Marker_H,
                                       Marker_Gap,
                                       Style);
                                 end if;
                              end if;
                           end if;
                        end if;

                        for Child_Idx of N.Children loop
                           if Child_Idx > 0 then
                              Layout_Node (Positive (Child_Idx), Style, Link_Href);
                           end if;
                        end loop;

                        if Block_Flow then
                           if Has_Line_Content or else Pending_Space then
                              New_Line;
                           end if;

                           if List_Context_Pushed
                             and then Natural (List_Stack.Length) > 0
                           then
                              List_Stack.Delete_Last;
                           end if;

                           declare
                              Border_Edges : constant Edge_Pixels :=
                                Get_Border_Width_Px (Style);
                              Has_Bot_Sep : constant Boolean :=
                                Padding_Edges.Bottom > 0.0
                                  or else Border_Edges.Bottom > 0.0;
                           begin
                              if Has_Bot_Sep then
                                 --  Bottom padding/border anchors the box;
                                 --  flush any descendant pending margin
                                 --  and then add our padding.
                                 Flush_Pending_Margin;
                                 Y := Y + Padding_Edges.Bottom;
                                 Prev_Block_Margin_Bottom := Margin_Edges.Bottom;
                              else
                                 --  No bottom separation: collapse-through.
                                 --  Our bottom margin merges with whatever
                                 --  the last child deferred.
                                 Prev_Block_Margin_Bottom :=
                                   Pixel_Type'Max
                                     (Prev_Block_Margin_Bottom,
                                      Margin_Edges.Bottom);
                              end if;
                           end;

                           if Block_Item_Index > 0 then
                              declare
                                 --  Re-read panel Y in case Flush_Pending_Margin
                                 --  moved it after this block was added.
                                 Final_Top : constant Pixel_Type :=
                                   Self.Items.Reference
                                     (Positive (Block_Item_Index)).Geometry.Y;
                                 Block_Bottom_Y : constant Pixel_Type := Y;
                              begin
                                 Self.Items.Reference (Positive (Block_Item_Index)).Geometry :=
                                   (X      => Block_Left_X,
                                    Y      => Final_Top,
                                    Width  => Block_Width,
                                    Height => Pixel_Type'Max (0.0, Block_Bottom_Y - Final_Top));
                              end;
                           end if;

                           Line_Left := Prev_Line_Left;
                           Line_Right := Prev_Line_Right;
                           Current_Line_Align := Prev_Line_Align;

                           Line_Base_H := Prev_Base_H;
                           Line_Base_Ascent := Prev_Base_Ascent;
                           Line_Base_Descent := Prev_Base_Descent;
                           Current_Line_H := Line_Base_H;
                           Current_Line_Ascent := Line_Base_Ascent;
                           Current_Line_Descent := Line_Base_Descent;
                           X := Line_Left;
                           Pending_Space := False;
                        end if;
                     end;
                  end if;
               end;
         end case;
      end Layout_Node;
   begin
      if Item_Count (Self) = 0 then
         Add_Item (Self, Make_Panel (Main_Part, Self.Geometry, 0));
      end if;

      Self.Items.Reference (Panel_Idx).Geometry := Self.Geometry;
      while Item_Count (Self) > 1 loop
         Self.Items.Delete_Last;
      end loop;

      Self.Links.Clear;

      if not Has_Visible_Area (Content) then
         return;
      end if;

      if Adi.CSS_Parser.Has_Tag (Self.CSS_Sheet, "html") then
         Document_Rules :=
           Merge
             (Document_Rules,
              Selector_Base_Rules (Adi.CSS_Parser.Styles_For_Tag (Self.CSS_Sheet, "html")));
      end if;

      if Adi.CSS_Parser.Has_Tag (Self.CSS_Sheet, "body") then
         Document_Rules :=
           Merge
             (Document_Rules,
              Selector_Base_Rules (Adi.CSS_Parser.Styles_For_Tag (Self.CSS_Sheet, "body")));
      end if;

      Document_Style := Resolve_Element_Style (Document_Rules, Text_Part_Style, True);

      Line_Base_H := Pixel_Type'Max
        (1.0,
         Measure_Line_Height
           (Document_Style,
            Self.Content_Scale,
            Root_Font_Px,
            Content.Width,
            Content.Height));
      Line_Base_Ascent := Pixel_Type'Max
        (1.0,
         Measure_Ascent
           (Document_Style,
            Self.Content_Scale,
            Root_Font_Px,
            Content.Width,
            Content.Height));
      Line_Base_Descent := Pixel_Type'Max
        (0.0,
         Measure_Descent
           (Document_Style,
            Self.Content_Scale,
            Root_Font_Px,
            Content.Width,
            Content.Height));
      Current_Line_H := Line_Base_H;
      Current_Line_Ascent := Line_Base_Ascent;
      Current_Line_Descent := Line_Base_Descent;
      Current_Line_Align := Document_Style.Text_Align;

      if Natural (Self.Nodes.Length) > 0 then
         declare
            Root : constant Node := Self.Nodes.Element (1);
         begin
            if Root.Kind = Element_Node then
               for Child_Idx of Root.Children loop
                  if Child_Idx > 0 then
                     Layout_Node (Positive (Child_Idx), Document_Style, "");
                  end if;
               end loop;
            end if;
         end;
      end if;

      Flush_Pending_Margin;
      Finalize_Line;

      declare
         Scroll_Offset : constant Pixel_Type := Get_Scroll_Offset_Y (Self);
         Content_End_Y : Pixel_Type :=
           (if Has_Line_Content then Y + Current_Line_H else Y);
      begin
         for I in 2 .. Item_Count (Self) loop
            declare
               It : constant Item := Get_Item (Self, I);
               Bottom : constant Pixel_Type := It.Geometry.Y + It.Geometry.Height;
            begin
               if Bottom > Content_End_Y then
                  Content_End_Y := Bottom;
               end if;
            end;
         end loop;

         Self.Scroll_Content_H :=
           Pixel_Type'Max (Content.Height, (Content_End_Y + Scroll_Offset) - Content.Y);
      end;

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
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle return Html_View_Handle is
   begin
      return (Id => Get_Handle (Create.all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : Html_View_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Html_View (H : Widget_Handle) return Html_View_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Html_View'Class then
         return (Id => H.Id);
      end if;
      return Null_Html_View_Handle;
   end Try_As_Html_View;

   function Is_Valid (H : Html_View_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Html_View_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles
     (H : Html_View_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------------
   -- Handle methods --
   --------------------

   procedure Set_HTML (H : Html_View_Handle; Source : String) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_HTML (Html_View (Ptr.all), Source);
      end if;
   end Set_HTML;

   function Get_HTML (H : Html_View_Handle) return String is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_HTML (Html_View (Ptr.all));
      end if;
      return "";
   end Get_HTML;

   procedure Clear (H : Html_View_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Clear (Html_View (Ptr.all));
      end if;
   end Clear;

   procedure Set_Content_Scale (H : Html_View_Handle; Scale : Pixel_Type) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Content_Scale (Html_View (Ptr.all), Scale);
      end if;
   end Set_Content_Scale;

   function Get_Content_Scale (H : Html_View_Handle) return Pixel_Type is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Content_Scale (Html_View (Ptr.all));
      end if;
      return 1.0;
   end Get_Content_Scale;

   procedure Connect_Link_Click
     (H : Html_View_Handle; CB : Link_Click_Callback)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Link_Click (Html_View (Ptr.all), CB);
      end if;
   end Connect_Link_Click;

   function Connect_Link_Click
     (H : Html_View_Handle; CB : Link_Click_Callback)
      return Link_Click_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Link_Click (Html_View (Ptr.all), CB);
      end if;
      return Link_Click_Signals.No_Connection;
   end Connect_Link_Click;

   procedure Disconnect_Link_Click
     (H : Html_View_Handle; Id : Link_Click_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Link_Click (Html_View (Ptr.all), Id);
      end if;
   end Disconnect_Link_Click;

   procedure Set_On_Load_Asset
     (H : Html_View_Handle; Callback : Asset_Load_Callback)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_On_Load_Asset (Html_View (Ptr.all), Callback);
      end if;
   end Set_On_Load_Asset;

   procedure Set_On_Load_Resource
     (H : Html_View_Handle; Callback : Resource_Load_Callback)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_On_Load_Resource (Html_View (Ptr.all), Callback);
      end if;
   end Set_On_Load_Resource;

   procedure Set_Default_Stylesheet
     (H : Html_View_Handle; Path : String)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Default_Stylesheet (Html_View (Ptr.all), Path);
      end if;
   end Set_Default_Stylesheet;

   procedure Set_Default_Stylesheet_String
     (H : Html_View_Handle; CSS : String)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Default_Stylesheet_String (Html_View (Ptr.all), CSS);
      end if;
   end Set_Default_Stylesheet_String;

   function Get_Default_Stylesheet (H : Html_View_Handle) return String is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Default_Stylesheet (Html_View (Ptr.all));
      end if;
      return "";
   end Get_Default_Stylesheet;

   procedure Set_HTML
     (Self   : in out Html_View;
      Source : String)
   is
   begin
      Self.Source := To_Unbounded_String (Source);
      Self.Image_Cache.Clear;
      Self.Inline_Style_Cache.Clear;
      Set_Scroll_Offset_Y (Self, 0.0);
      Parse_HTML (Self, Source);
      Mark_Dirty (Self);
   end Set_HTML;

   function Get_HTML (Self : Html_View) return String is
   begin
      return To_String (Self.Source);
   end Get_HTML;

   procedure Clear (Self : in out Html_View) is
   begin
      Self.Source := Null_Unbounded_String;
      Self.Nodes.Clear;
      Self.Links.Clear;
      Self.Image_Cache.Clear;
      Self.Inline_Style_Cache.Clear;
      Load_Combined_CSS (Self, "");
      Set_Part_Styles (Self, Default_Internal_Part_Styles);
      Mark_Dirty (Self);
   end Clear;

   procedure Set_Content_Scale
     (Self  : in out Html_View;
      Scale : Pixel_Type)
   is
      New_Scale : constant Pixel_Type := Pixel_Type'Max (0.01, Scale);
   begin
      if abs (Self.Content_Scale - New_Scale) <= 0.0001 then
         return;
      end if;

      Self.Content_Scale := New_Scale;
      Mark_Dirty (Self);
   end Set_Content_Scale;

   function Get_Content_Scale (Self : Html_View) return Pixel_Type is
   begin
      return Self.Content_Scale;
   end Get_Content_Scale;

   procedure Connect_Link_Click
     (Self : in out Html_View; CB : Link_Click_Callback)
   is
   begin
      Self.Link_Click.Connect (CB);
   end Connect_Link_Click;

   function Connect_Link_Click
     (Self : in out Html_View; CB : Link_Click_Callback)
      return Link_Click_Signals.Connection_Id
   is
   begin
      return Self.Link_Click.Connect (CB);
   end Connect_Link_Click;

   procedure Disconnect_Link_Click
     (Self : in out Html_View; Id : Link_Click_Signals.Connection_Id)
   is
   begin
      Self.Link_Click.Disconnect (Id);
   end Disconnect_Link_Click;

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
      if Length (Self.Source) > 0 then
         Parse_HTML (Self, To_String (Self.Source));
      end if;
      Mark_Dirty (Self);
   end Set_On_Load_Resource;

   procedure Set_Default_Stylesheet
     (Self : in out Html_View;
      Path : String)
   is
   begin
      if Path'Length = 0 then
         Self.Default_CSS := Null_Unbounded_String;
      else
         begin
            Self.Default_CSS := To_Unbounded_String (Read_File (Path));
         exception
            when others =>
               Adi.Log.Error
                 ("Html_View: failed to read default stylesheet: " & Path);
               Self.Default_CSS := Null_Unbounded_String;
         end;
      end if;
      if Length (Self.Source) > 0 then
         Parse_HTML (Self, To_String (Self.Source));
      end if;
      Mark_Dirty (Self);
   end Set_Default_Stylesheet;

   procedure Set_Default_Stylesheet_String
     (Self : in out Html_View;
      CSS  : String)
   is
   begin
      Self.Default_CSS := To_Unbounded_String (CSS);
      if Length (Self.Source) > 0 then
         Parse_HTML (Self, To_String (Self.Source));
      end if;
      Mark_Dirty (Self);
   end Set_Default_Stylesheet_String;

   function Get_Default_Stylesheet (Self : Html_View) return String is
   begin
      return To_String (Self.Default_CSS);
   end Get_Default_Stylesheet;

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
        and then Self.Link_Click.Subscriber_Count > 0
      then
         declare
            S_H : constant Html_View_Handle :=
              Try_As_Html_View (Get_Handle (Widget'Class (Self)));
            H : constant String := Href;
            procedure Call (CB : Link_Click_Callback) is
            begin CB (S_H, H); end Call;
            procedure Emit is new Link_Click_Signals.For_Each (Call);
         begin
            Emit (Self.Link_Click);
         end;
      elsif Button = Left_Button and then Self.Pressed_Is_Link then
         Adi.Log.Debug ("Html_View: link click did not resolve on mouse up");
      end if;

      Self.Pressed_Is_Link := False;
      Self.Pressed_Href := Null_Unbounded_String;
   end On_Mouse_Up;

end Adi.Widget.Html_View;
