--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Containers.Ordered_Maps;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Log;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.TTF;           use Adi.SDL.TTF;

package body Adi.Widget.Html_View is

   package Fix renames Ada.Strings.Fixed;
   package Char renames Ada.Characters.Handling;

   --  Cached SVG marker images (created lazily on first use)
   Marker_White : constant Color_8 := (R => 255, G => 255, B => 255, A => 255);
   Marker_Clear : constant Color_8 := (R => 0, G => 0, B => 0, A => 0);
   Marker_SVG_Size : constant Size_2D := (16.0, 16.0);

   --  Built once and kept for the life of the program: every view draws
   --  the same three list markers, and nothing else can end them.
   Disc_Marker   : Image_Owner := Adi.Image.Null_Image_Owner;
   Circle_Marker : Image_Owner := Adi.Image.Null_Image_Owner;
   Square_Marker : Image_Owner := Adi.Image.Null_Image_Owner;

   procedure Ensure_Marker_Images is
   begin
      if Adi.Image.Is_Owned (Disc_Marker) then
         return;
      end if;

      --  Filled circle (disc)
      Disc_Marker := Load_SVG_Path
        (Path_Data    => "M8 2 A6 6 0 1 0 8 14 A6 6 0 1 0 8 2 Z",
         Size         => Marker_SVG_Size,
         Fill         => Marker_White,
         Stroke_Width => 0.0,
         Stroke       => Marker_Clear,
         Tintable     => True);

      --  Hollow circle
      Circle_Marker := Load_SVG_Path
        (Path_Data    => "M8 2 A6 6 0 1 0 8 14 A6 6 0 1 0 8 2 Z",
         Size         => Marker_SVG_Size,
         Fill         => Marker_Clear,
         Stroke_Width => 1.5,
         Stroke       => Marker_White,
         Tintable     => True);

      --  Filled square
      Square_Marker := Load_SVG_Path
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

   function Decode_Entities (S : String) return String;

   --  The value of attribute Name in a tag's text, character references
   --  decoded; Found False when the tag has none. An attribute written
   --  without a value is found, with value "".
   function Find_Attribute
     (Tag_Content : String;
      Name        : String;
      Found       : out Boolean) return String
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
      Found := False;
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
                        Found := True;
                        return Decode_Entities (Value);
                     end if;
                  end;
               elsif Key = Name_Low then
                  Found := True;
                  return "";
               end if;
            end if;
         end;
      end loop;

      return "";
   exception
      when others =>
         Found := False;
         return "";
   end Find_Attribute;

   --  The value of attribute Name in a tag's text, or "" when it has none.
   function Extract_Attribute
     (Tag_Content : String;
      Name        : String) return String
   is
      Found : Boolean;
   begin
      return Find_Attribute (Tag_Content, Name, Found);
   end Extract_Attribute;

   --  A tag's text after its name: the attributes alone.
   function Attribute_Text (Raw_Tag : String) return String is
      I : Natural := Raw_Tag'First;
   begin
      while I <= Raw_Tag'Last and then Is_Whitespace (Raw_Tag (I)) loop
         I := I + 1;
      end loop;
      while I <= Raw_Tag'Last
        and then not Is_Whitespace (Raw_Tag (I))
        and then Raw_Tag (I) /= '/'
      loop
         I := I + 1;
      end loop;
      return Raw_Tag (I .. Raw_Tag'Last);
   end Attribute_Text;

   --  The HTML 4 named character references, sorted by name.
   type Named_Reference is record
      Name : String (1 .. 8);
      Last : Positive;
      Code : Natural;
   end record;

   function Named (Name : String; Code : Natural) return Named_Reference is
     ((Name => Name & [1 .. 8 - Name'Length => ' '], Last => Name'Length, Code => Code));

   Named_References : constant array (Positive range <>) of Named_Reference :=
     [Named ("AElig", 198), Named ("Aacute", 193), Named ("Acirc", 194),
      Named ("Agrave", 192), Named ("Alpha", 913), Named ("Aring", 197),
      Named ("Atilde", 195), Named ("Auml", 196), Named ("Beta", 914),
      Named ("Ccedil", 199), Named ("Chi", 935), Named ("Dagger", 8225),
      Named ("Delta", 916), Named ("ETH", 208), Named ("Eacute", 201),
      Named ("Ecirc", 202), Named ("Egrave", 200), Named ("Epsilon", 917),
      Named ("Eta", 919), Named ("Euml", 203), Named ("Gamma", 915),
      Named ("Iacute", 205), Named ("Icirc", 206), Named ("Igrave", 204),
      Named ("Iota", 921), Named ("Iuml", 207), Named ("Kappa", 922),
      Named ("Lambda", 923), Named ("Mu", 924), Named ("Ntilde", 209),
      Named ("Nu", 925), Named ("OElig", 338), Named ("Oacute", 211),
      Named ("Ocirc", 212), Named ("Ograve", 210), Named ("Omega", 937),
      Named ("Omicron", 927), Named ("Oslash", 216), Named ("Otilde", 213),
      Named ("Ouml", 214), Named ("Phi", 934), Named ("Pi", 928),
      Named ("Prime", 8243), Named ("Psi", 936), Named ("Rho", 929),
      Named ("Scaron", 352), Named ("Sigma", 931), Named ("THORN", 222),
      Named ("Tau", 932), Named ("Theta", 920), Named ("Uacute", 218),
      Named ("Ucirc", 219), Named ("Ugrave", 217), Named ("Upsilon", 933),
      Named ("Uuml", 220), Named ("Xi", 926), Named ("Yacute", 221),
      Named ("Yuml", 376), Named ("Zeta", 918), Named ("aacute", 225),
      Named ("acirc", 226), Named ("acute", 180), Named ("aelig", 230),
      Named ("agrave", 224), Named ("alefsym", 8501), Named ("alpha", 945),
      Named ("amp", 38), Named ("and", 8743), Named ("ang", 8736),
      Named ("aring", 229), Named ("asymp", 8776), Named ("atilde", 227),
      Named ("auml", 228), Named ("bdquo", 8222), Named ("beta", 946),
      Named ("brvbar", 166), Named ("bull", 8226), Named ("cap", 8745),
      Named ("ccedil", 231), Named ("cedil", 184), Named ("cent", 162),
      Named ("chi", 967), Named ("circ", 710), Named ("clubs", 9827),
      Named ("cong", 8773), Named ("copy", 169), Named ("crarr", 8629),
      Named ("cup", 8746), Named ("curren", 164), Named ("dArr", 8659),
      Named ("dagger", 8224), Named ("darr", 8595), Named ("deg", 176),
      Named ("delta", 948), Named ("diams", 9830), Named ("divide", 247),
      Named ("eacute", 233), Named ("ecirc", 234), Named ("egrave", 232),
      Named ("empty", 8709), Named ("emsp", 8195), Named ("ensp", 8194),
      Named ("epsilon", 949), Named ("equiv", 8801), Named ("eta", 951),
      Named ("eth", 240), Named ("euml", 235), Named ("euro", 8364),
      Named ("exist", 8707), Named ("fnof", 402), Named ("forall", 8704),
      Named ("frac12", 189), Named ("frac14", 188), Named ("frac34", 190),
      Named ("frasl", 8260), Named ("gamma", 947), Named ("ge", 8805),
      Named ("gt", 62), Named ("hArr", 8660), Named ("harr", 8596),
      Named ("hearts", 9829), Named ("hellip", 8230), Named ("iacute", 237),
      Named ("icirc", 238), Named ("iexcl", 161), Named ("igrave", 236),
      Named ("image", 8465), Named ("infin", 8734), Named ("int", 8747),
      Named ("iota", 953), Named ("iquest", 191), Named ("isin", 8712),
      Named ("iuml", 239), Named ("kappa", 954), Named ("lArr", 8656),
      Named ("lambda", 955), Named ("lang", 9001), Named ("laquo", 171),
      Named ("larr", 8592), Named ("lceil", 8968), Named ("ldquo", 8220),
      Named ("le", 8804), Named ("lfloor", 8970), Named ("lowast", 8727),
      Named ("loz", 9674), Named ("lrm", 8206), Named ("lsaquo", 8249),
      Named ("lsquo", 8216), Named ("lt", 60), Named ("macr", 175),
      Named ("mdash", 8212), Named ("micro", 181), Named ("middot", 183),
      Named ("minus", 8722), Named ("mu", 956), Named ("nabla", 8711),
      Named ("nbsp", 160), Named ("ndash", 8211), Named ("ne", 8800),
      Named ("ni", 8715), Named ("not", 172), Named ("notin", 8713),
      Named ("nsub", 8836), Named ("ntilde", 241), Named ("nu", 957),
      Named ("oacute", 243), Named ("ocirc", 244), Named ("oelig", 339),
      Named ("ograve", 242), Named ("oline", 8254), Named ("omega", 969),
      Named ("omicron", 959), Named ("oplus", 8853), Named ("or", 8744),
      Named ("ordf", 170), Named ("ordm", 186), Named ("oslash", 248),
      Named ("otilde", 245), Named ("otimes", 8855), Named ("ouml", 246),
      Named ("para", 182), Named ("part", 8706), Named ("permil", 8240),
      Named ("perp", 8869), Named ("phi", 966), Named ("pi", 960),
      Named ("piv", 982), Named ("plusmn", 177), Named ("pound", 163),
      Named ("prime", 8242), Named ("prod", 8719), Named ("prop", 8733),
      Named ("psi", 968), Named ("quot", 34), Named ("rArr", 8658),
      Named ("radic", 8730), Named ("rang", 9002), Named ("raquo", 187),
      Named ("rarr", 8594), Named ("rceil", 8969), Named ("rdquo", 8221),
      Named ("real", 8476), Named ("reg", 174), Named ("rfloor", 8971),
      Named ("rho", 961), Named ("rlm", 8207), Named ("rsaquo", 8250),
      Named ("rsquo", 8217), Named ("sbquo", 8218), Named ("scaron", 353),
      Named ("sdot", 8901), Named ("sect", 167), Named ("shy", 173),
      Named ("sigma", 963), Named ("sigmaf", 962), Named ("sim", 8764),
      Named ("spades", 9824), Named ("sub", 8834), Named ("sube", 8838),
      Named ("sum", 8721), Named ("sup", 8835), Named ("sup1", 185),
      Named ("sup2", 178), Named ("sup3", 179), Named ("supe", 8839),
      Named ("szlig", 223), Named ("tau", 964), Named ("there4", 8756),
      Named ("theta", 952), Named ("thetasym", 977), Named ("thinsp", 8201),
      Named ("thorn", 254), Named ("tilde", 732), Named ("times", 215),
      Named ("trade", 8482), Named ("uArr", 8657), Named ("uacute", 250),
      Named ("uarr", 8593), Named ("ucirc", 251), Named ("ugrave", 249),
      Named ("uml", 168), Named ("upsih", 978), Named ("upsilon", 965),
      Named ("uuml", 252), Named ("weierp", 8472), Named ("xi", 958),
      Named ("yacute", 253), Named ("yen", 165), Named ("yuml", 255),
      Named ("zeta", 950), Named ("zwj", 8205), Named ("zwnj", 8204)];

   --  What HTML decodes a numeric reference to 128 .. 159 as: the
   --  windows-1252 character there, or the code itself where that has
   --  none.
   Windows_1252 : constant array (128 .. 159) of Natural :=
     [16#20AC#, 16#81#, 16#201A#, 16#192#, 16#201E#, 16#2026#, 16#2020#,
      16#2021#, 16#2C6#, 16#2030#, 16#160#, 16#2039#, 16#152#, 16#8D#,
      16#17D#, 16#8F#, 16#90#, 16#2018#, 16#2019#, 16#201C#, 16#201D#,
      16#2022#, 16#2013#, 16#2014#, 16#2DC#, 16#2122#, 16#161#, 16#203A#,
      16#153#, 16#9D#, 16#17E#, 16#178#];

   Replacement_Character : constant := 16#FFFD#;

   function UTF_8 (Code : Natural) return String is
     (Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode
        ([1 => Wide_Wide_Character'Val (Code)]));

   --  Character references: the HTML 4 names, case-sensitive, with the
   --  five XML ones in any case; and numeric ones, decimal or hex, to any
   --  Unicode scalar value. A reference that names nothing stays as
   --  written.
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

      --  The code a named reference stands for, or -1.
      function Named_Code (Name : String) return Integer is
      begin
         for R of Named_References loop
            if R.Name (1 .. R.Last) = Name then
               return R.Code;
            end if;
         end loop;

         if Name'Length > 4 then
            return -1;
         end if;

         declare
            Folded : constant String := Lower (Name);
         begin
            return (if Folded = "amp" then 38
                    elsif Folded = "lt" then 60
                    elsif Folded = "gt" then 62
                    elsif Folded = "quot" then 34
                    elsif Folded = "apos" then 39
                    else -1);
         end;
      end Named_Code;

      --  The code a numeric reference ("#65", "#x41") stands for, -1 when
      --  it is not one, or the replacement character when it names no
      --  Unicode scalar value.
      function Numeric_Code (Body_Text : String) return Integer is
         Hex   : constant Boolean :=
           Body_Text'Length > 1
           and then Body_Text (Body_Text'First) in 'x' | 'X';
         First : constant Positive := Body_Text'First + (if Hex then 1 else 0);
         Code  : Long_Long_Integer := 0;
      begin
         if First > Body_Text'Last then
            return -1;
         end if;
         for K in First .. Body_Text'Last loop
            declare
               D : constant Integer :=
                 (if Hex then Hex_Value (Body_Text (K))
                  elsif Body_Text (K) in '0' .. '9'
                  then Character'Pos (Body_Text (K)) - Character'Pos ('0')
                  else -1);
            begin
               if D < 0 then
                  return -1;
               end if;
               Code := Long_Long_Integer'Min
                 (16#110000#, Code * (if Hex then 16 else 10) + Long_Long_Integer (D));
            end;
         end loop;

         if Code = 0 or else Code > 16#10FFFF#
           or else Code in 16#D800# .. 16#DFFF#
         then
            return Replacement_Character;
         elsif Code in 128 .. 159 then
            return Windows_1252 (Integer (Code));
         end if;
         return Integer (Code);
      end Numeric_Code;
   begin
      while I <= S'Last loop
         if S (I) /= '&' then
            Append (Result, S (I));
            I := I + 1;
         else
            declare
               --  A reference is letters and digits after an optional #, and
               --  ends at a semicolon; the search stops at anything else.
               function Reference_End return Natural is
                  J : Positive := I + 1;
               begin
                  if J <= S'Last and then S (J) = '#' then
                     J := J + 1;
                  end if;
                  while J <= S'Last
                    and then S (J) in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9'
                  loop
                     J := J + 1;
                  end loop;
                  return (if J <= S'Last and then S (J) = ';' then J else 0);
               end Reference_End;

               Semi : constant Natural := Reference_End;
               Code : Integer := -1;
            begin
               if Semi > I + 1 then
                  declare
                     Ref_Text : constant String := S (I + 1 .. Semi - 1);
                  begin
                     Code :=
                       (if Ref_Text (Ref_Text'First) = '#'
                        then Numeric_Code (Ref_Text (Ref_Text'First + 1 .. Ref_Text'Last))
                        else Named_Code (Ref_Text));
                  end;
               end if;

               if Code >= 0 then
                  Append (Result, UTF_8 (Code));
                  I := Semi + 1;
               else
                  Append (Result, '&');
                  I := I + 1;
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
      Self.Nodes (Child_Index).Position := Parent_Node.Children.Last_Index;
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
              Position => 0,
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
              Position => 0,
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
              Parent => Natural (Parent_Index),
              Position => 0));
      Idx := Positive (Self.Nodes.Last_Index);
      Append_Child (Self, Parent_Index, Idx);
   end Append_Break_Node;


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

      --  Subscripts and superscripts sit off the baseline; their size is
      --  the stylesheet's.
      elsif Tag = "sub" or else Tag = "sup" then
         return (Display        => Set (Inline),
                 Vertical_Align => Set (if Tag = "sub" then VA_Sub else VA_Super),
                 others         => <>);

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

   function Parse_Inline_Style_Rules
     (Self        : in out Html_View;
      Inline_Text : String) return Style_Rules
   is
      Key : constant String := Trimmed (Inline_Text);
      Tmp : Adi.CSS_Parser.Rule_Sheet;
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

      Adi.CSS_Parser.Load_Rules
        (Tmp,
         ".__inline__ { " & Key & " }",
         Ok);

      if Ok then
         Out_Rules := Adi.CSS_Parser.Base_Rules
           (Tmp, Adi.CSS_Parser.Class_Selector, "__inline__");
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

   --  An HTML dimension attribute: digits with an optional fraction, then
   --  an optional `%`, after leading whitespace; anything after is
   --  ignored. No leading digit yields Unset.
   function Dimension_Attribute (S : String) return Opt_Size.Optional is
      I     : Integer := S'First;
      Value : Float := 0.0;
      Place : Float := 0.1;
   begin
      while I <= S'Last and then Is_Whitespace (S (I)) loop
         I := I + 1;
      end loop;

      if I > S'Last or else S (I) not in '0' .. '9' then
         return Opt_Size.Unset;
      end if;

      while I <= S'Last and then S (I) in '0' .. '9' loop
         Value := Float'Min
           (1.0E7,
            Value * 10.0 + Float (Character'Pos (S (I)) - Character'Pos ('0')));
         I := I + 1;
      end loop;

      if I <= S'Last and then S (I) = '.' then
         I := I + 1;
         while I <= S'Last and then S (I) in '0' .. '9' loop
            Value := Value + Place * Float (Character'Pos (S (I)) - Character'Pos ('0'));
            Place := Place / 10.0;
            I := I + 1;
         end loop;
      end if;

      if I <= S'Last and then S (I) = '%' then
         return Set (Size (Pct (Value)));
      end if;
      return Set (Size (Px (Value)));
   end Dimension_Attribute;

   ---------------------------------------------------------------------------
   --  The document as Adi.HTML_Selectors reads it. Element 1, the parse
   --  root, stands for body, under an html element numbered one past the
   --  last node.
   ---------------------------------------------------------------------------

   type View_Document (View : not null access constant Html_View) is
     new Adi.HTML_Selectors.Document with null record;

   overriding function Tag_Of (D : View_Document; E : Positive) return String;
   overriding function Id_Of (D : View_Document; E : Positive) return String;
   overriding function Has_Class
     (D : View_Document; E : Positive; Name : String) return Boolean;
   overriding function Attribute_Of
     (D : View_Document; E : Positive; Name : String; Found : out Boolean)
      return String;
   overriding function Parent_Of (D : View_Document; E : Positive) return Natural;
   overriding function Previous_Sibling_Of
     (D : View_Document; E : Positive) return Natural;
   overriding function Next_Sibling_Of
     (D : View_Document; E : Positive) return Natural;
   overriding function In_State
     (D : View_Document; E : Positive; State : Adi.HTML_Selectors.Dynamic_State)
      return Boolean;

   function Html_Element (D : View_Document'Class) return Positive is
     (Natural (D.View.Nodes.Length) + 1);

   overriding function Tag_Of (D : View_Document; E : Positive) return String is
     (if E = Html_Element (D) then "html"
      elsif E = 1 then "body"
      else To_String (D.View.Nodes (E).Tag_Name));

   overriding function Id_Of (D : View_Document; E : Positive) return String is
     (if E >= Html_Element (D) then ""
      else Trimmed (To_String (D.View.Nodes (E).Attrs.Id_Attr)));

   overriding function Has_Class
     (D : View_Document; E : Positive; Name : String) return Boolean
   is
   begin
      if E >= Html_Element (D) then
         return False;
      end if;
      declare
         Value : constant String := To_String (D.View.Nodes (E).Attrs.Class_Attr);
         I     : Natural := Value'First;
      begin
         while I <= Value'Last loop
            while I <= Value'Last and then Is_Whitespace (Value (I)) loop
               I := I + 1;
            end loop;
            declare
               Start : constant Natural := I;
            begin
               while I <= Value'Last and then not Is_Whitespace (Value (I)) loop
                  I := I + 1;
               end loop;
               if I > Start and then Lower (Value (Start .. I - 1)) = Name then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end;
   end Has_Class;

   overriding function Attribute_Of
     (D : View_Document; E : Positive; Name : String; Found : out Boolean)
      return String
   is
   begin
      Found := False;
      if E >= Html_Element (D) then
         return "";
      end if;
      return Find_Attribute (To_String (D.View.Nodes (E).Attrs.Raw_Attrs), Name, Found);
   end Attribute_Of;

   overriding function Parent_Of (D : View_Document; E : Positive) return Natural is
     (if E >= Html_Element (D) then 0
      elsif E = 1 then Html_Element (D)
      else D.View.Nodes (E).Parent);

   --  The element sibling Step away from E among its parent's children.
   function Element_Sibling
     (D : View_Document'Class; E : Positive; Step : Integer) return Natural
   is
   begin
      if E = 1 or else E >= Html_Element (D) then
         return 0;
      end if;
      declare
         Kids : Node_Index_Vectors.Vector renames
           D.View.Nodes (D.View.Nodes (E).Parent).Children;
         K    : Integer := D.View.Nodes (E).Position;
      begin
         if K = 0 then
            return 0;
         end if;
         loop
            K := K + Step;
            exit when K < Kids.First_Index or else K > Kids.Last_Index;
            if Kids (K) > 0 and then D.View.Nodes (Kids (K)).Kind = Element_Node then
               return Kids (K);
            end if;
         end loop;
         return 0;
      end;
   end Element_Sibling;

   overriding function Previous_Sibling_Of
     (D : View_Document; E : Positive) return Natural is
     (Element_Sibling (D, E, -1));

   overriding function Next_Sibling_Of
     (D : View_Document; E : Positive) return Natural is
     (Element_Sibling (D, E, +1));

   --  The hovered or pressed element, and every element it is inside.
   overriding function In_State
     (D : View_Document; E : Positive; State : Adi.HTML_Selectors.Dynamic_State)
      return Boolean
   is
      use type Adi.HTML_Selectors.Dynamic_State;
      P : Natural :=
        (if State /= Adi.HTML_Selectors.Hovered then D.View.Active_Node
         elsif Get_States (D.View.all) (State_Hovered) then D.View.Hovered_Node
         else 0);
   begin
      while P /= 0 loop
         if P = E then
            return True;
         end if;
         P := Parent_Of (D, P);
      end loop;
      return False;
   end In_State;

   --  The sheet's rules matching element E, merged by specificity and
   --  then by the order written.
   function Sheet_Rules_For (Self : Html_View; E : Positive) return Style_Rules is
      Doc   : View_Document (Self'Unrestricted_Access);
      Hits  : array (1 .. Natural (Self.Sheet_Rules.Length)) of Positive;
      Count : Natural := 0;
      Result : Style_Rules := Empty_Style;

      function Before (L, R : Positive) return Boolean is
        (Adi.HTML_Selectors."<" (Self.Sheet_Rules (L).Weight, Self.Sheet_Rules (R).Weight)
         or else (not Adi.HTML_Selectors."<" (Self.Sheet_Rules (R).Weight,
                                              Self.Sheet_Rules (L).Weight)
                  and then L < R));
      --  The subject's type and id turn most rules away before matching.
      Tag : constant String := Lower (Doc.Tag_Of (E));
      Id  : constant String := Lower (Doc.Id_Of (E));
   begin
      for I in 1 .. Natural (Self.Sheet_Rules.Length) loop
         if (Length (Self.Sheet_Rules (I).Tag) = 0
             or else To_String (Self.Sheet_Rules (I).Tag) = Tag)
           and then (Length (Self.Sheet_Rules (I).Id) = 0
                     or else To_String (Self.Sheet_Rules (I).Id) = Id)
           and then Adi.HTML_Selectors.Matches (Self.Sheet_Rules (I).Selector, Doc, E)
         then
            Count := Count + 1;
            Hits (Count) := I;
         end if;
      end loop;

      --  Insertion sort: the hits are few and nearly in order already.
      for I in 2 .. Count loop
         declare
            H : constant Positive := Hits (I);
            J : Natural := I - 1;
         begin
            while J >= 1 and then Before (H, Hits (J)) loop
               Hits (J + 1) := Hits (J);
               J := J - 1;
            end loop;
            Hits (J + 1) := H;
         end;
      end loop;

      for I in 1 .. Count loop
         Result := Merge (Result, Self.Sheet_Rules (Hits (I)).Rules);
      end loop;
      return Result;
   end Sheet_Rules_For;

   --  An element's rules: its tag's defaults, then presentational
   --  attributes, then the sheet in cascade order, then its style
   --  attribute.
   function Element_Cascade_Rules
     (Self    : in out Html_View;
      Element : Positive) return Style_Rules
   is
      Tag    : constant String := To_String (Self.Nodes (Element).Tag_Name);
      Attrs  : constant Element_Attributes := Self.Nodes (Element).Attrs;
      Result : Style_Rules := Tag_Default_Style (Tag);
   begin
      --  The parse root is body, and the html element above it has no box
      --  of its own: its rules fold into body's.
      if Element = 1 then
         return Merge
           (Merge (Tag_Default_Style ("body"),
                   Sheet_Rules_For (Self, Natural (Self.Nodes.Length) + 1)),
            Sheet_Rules_For (Self, 1));
      end if;

      --  img width/height sit below every stylesheet rule.
      if Tag = "img" then
         declare
            W : constant Opt_Size.Optional :=
              Dimension_Attribute (To_String (Attrs.Width_Attr));
            H : constant Opt_Size.Optional :=
              Dimension_Attribute (To_String (Attrs.Height_Attr));
         begin
            if Opt_Size.Is_Set (W) then
               Result.Width := W;
            end if;
            if Opt_Size.Is_Set (H) then
               Result.Height := H;
            end if;
         end;
      end if;

      Result := Merge (Result, Sheet_Rules_For (Self, Element));

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

      --  What sits inside a raised or lowered inline element moves with
      --  it; a block resets this for its own content.
      if not Opt_Vertical_Align.Is_Set (Rules.Vertical_Align) then
         Result.Vertical_Align := Parent.Vertical_Align;
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
      --  Anything that rebuilds the document invalidates a layout of
      --  the previous one.
      Self.Doc_Generation := Self.Doc_Generation + 1;
      if Length (Self.Default_CSS) > 0 then
         declare
            Combined : constant String :=
              To_String (Self.Default_CSS) & ASCII.LF & CSS_Text;
         begin
            Adi.CSS_Parser.Load_Rules (Self.CSS_Sheet, Combined, Success);
         end;
      else
         Adi.CSS_Parser.Load_Rules (Self.CSS_Sheet, CSS_Text, Success);
      end if;
      Self.Sheet_Rules.Clear;
      Self.Dynamic_Rules := False;
      for I in 1 .. Adi.CSS_Parser.Written_Count (Self.CSS_Sheet) loop
         declare
            Sel : Adi.HTML_Selectors.Selector;
         begin
            if Adi.HTML_Selectors.Parse
                 (Adi.CSS_Parser.Written_Selector (Self.CSS_Sheet, I), Sel)
            then
               Self.Sheet_Rules.Append
                 (Sheet_Rule'(Selector => Sel,
                   Tag      => To_Unbounded_String (Adi.HTML_Selectors.Subject_Tag (Sel)),
                   Id       => To_Unbounded_String (Adi.HTML_Selectors.Subject_Id (Sel)),
                   Weight   => Adi.HTML_Selectors.Specificity_Of (Sel),
                   Rules    => Adi.CSS_Parser.Written_Rules (Self.CSS_Sheet, I)));
               Self.Dynamic_Rules :=
                 Self.Dynamic_Rules or else Adi.HTML_Selectors.Is_Dynamic (Sel);
            end if;
         end;
      end loop;

      if not Success then
         Adi.Log.Error
           ("Html_View CSS parse failed: " &
            Adi.CSS_Parser.Last_Error (Self.CSS_Sheet));
      elsif Adi.CSS_Parser.Has_Root_Font_Size (Self.CSS_Sheet) then
         Self.Root_Font_Size :=
           Adi.CSS_Parser.Root_Font_Size (Self.CSS_Sheet);
      else
         Self.Root_Font_Size := Default_Font_Size;
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
      --  Anything that rebuilds the document invalidates a layout of
      --  the previous one.
      Self.Doc_Generation := Self.Doc_Generation + 1;
      Self.Nodes.Clear;
      Self.Hovered_Node := 0;
      Self.Active_Node := 0;

      Self.Nodes.Append
        (New_Item =>
           Node'
             (Kind     => Element_Node,
              Parent   => 0,
              Position => 0,
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
                                    Start_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "start")),
                                    Width_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "width")),
                                    Height_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "height")),
                                    Svg_Source_Attr => Null_Unbounded_String,
                                    Raw_Attrs  => To_Unbounded_String (Attribute_Text (Raw_Tag)));
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
                                    Start_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "start")),
                                    Width_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "width")),
                                    Height_Attr => To_Unbounded_String (Extract_Attribute (Raw_Tag, "height")),
                                    Svg_Source_Attr => Null_Unbounded_String,
                                    Raw_Attrs  => To_Unbounded_String (Attribute_Text (Raw_Tag)));
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

                              --  HTML drops one newline right after the start
                              --  tag of pre, listing and textarea.
                              if not Closing
                                and then (Name = "pre" or else Name = "listing"
                                          or else Name = "textarea")
                                and then I <= Source'Last
                              then
                                 if Source (I) = ASCII.LF then
                                    I := I + 1;
                                 elsif Source (I) = ASCII.CR then
                                    I := I + 1;
                                    if I <= Source'Last and then Source (I) = ASCII.LF then
                                       I := I + 1;
                                    end if;
                                 end if;
                              end if;

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

   --  Where this source is cached, or zero. Separate from what is
   --  cached there, because a stale borrowed entry has to be replaced
   --  rather than merely missed.
   function Cache_Index
     (Self : Html_View;
      Src  : String) return Natural
   is
   begin
      for I in 1 .. Natural (Self.Image_Cache.Length) loop
         if To_String (Self.Image_Cache.Element (Positive (I)).Src) = Src then
            return I;
         end if;
      end loop;
      return 0;
   end Cache_Index;

   function Lookup_Image
     (Self : in out Html_View;
      Src  : String) return Adi.Image.Image_Handle
   is
      At_Index : constant Natural := Cache_Index (Self, Src);
   begin
      if At_Index = 0 then
         return Adi.Image.Null_Image_Handle;
      end if;
      return Self.Image_Cache.Element (Positive (At_Index)).Img;
   end Lookup_Image;

   --  A vector finalises the elements it drops when it likes, so the
   --  images this view built are released here rather than by Clear.
   procedure Drop_Image_Cache (Self : in out Html_View);

   procedure Drop_Image_Cache (Self : in out Html_View) is
      procedure Give_Up (C : in out Cached_Image);

      procedure Give_Up (C : in out Cached_Image) is
      begin
         Adi.Image.Release (C.Own);
         C.Img := Adi.Image.Null_Image_Handle;
      end Give_Up;
   begin
      for I in 1 .. Natural (Self.Image_Cache.Length) loop
         Self.Image_Cache.Update_Element (I, Give_Up'Access);
      end loop;
      Self.Image_Cache.Clear;
   end Drop_Image_Cache;

   function Resolve_Image
     (Self : in out Html_View;
      Src  : String) return Adi.Image.Image_Handle
   is
      Img : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
   begin
      if Src'Length = 0 then
         return Adi.Image.Null_Image_Handle;
      end if;

      declare
         At_Index : constant Natural := Cache_Index (Self, Src);
      begin
         if At_Index /= 0 then
            Img := Self.Image_Cache.Element (Positive (At_Index)).Img;

            --  A borrowed image whose owner has let go. Asking again is
            --  the only way this view can recover: it cannot reload what
            --  it never owned.
            if Adi.Image.Is_Valid (Img) then
               return Img;
            end if;
            Self.Image_Cache.Delete (Positive (At_Index));
         end if;
      end;

      if Self.On_Load_Asset /= null then
         declare
            Self_H : constant Html_View_Handle :=
              Try_As_Html_View (Get_Handle (Widget'Class (Self)));
         begin
            Img := Self.On_Load_Asset (Self_H, Src);
         end;
      end if;

      --  Borrowed: whoever answered the callback owns it.
      Self.Image_Cache.Append
        (New_Item =>
           Cached_Image'(Src => To_Unbounded_String (Src),
                         Img => Img,
                         Own => Adi.Image.Null_Image_Owner));
      return Img;
   end Resolve_Image;

   function Resolve_Inline_SVG
     (Self   : in out Html_View;
      Source : String) return Adi.Image.Image_Handle
   is
      Cache_Key : constant String := "__adi_inline_svg__:" & Source;
      Img       : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
   begin
      if Source'Length = 0 then
         return Adi.Image.Null_Image_Handle;
      end if;

      Img := Lookup_Image (Self, Cache_Key);
      if Img /= Adi.Image.Null_Image_Handle then
         return Img;
      end if;

      --  Built here, so this view owns it and must end it when the
      --  cache goes.
      declare
         Own : constant Adi.Image.Image_Owner :=
           Adi.Image.Load_SVG_From_String (Source => Source);
      begin
         Img := Adi.Image.To_Handle (Own);
         Self.Image_Cache.Append
           (New_Item =>
              Cached_Image'(Src => To_Unbounded_String (Cache_Key),
                            Img => Img,
                            Own => Own));
      end;
      return Img;
   end Resolve_Inline_SVG;

   --  The default font size in device pixels at a content scale.
   function Default_Font_Px (Scale : Pixel_Type) return Pixel_Type is
     (Default_Root_Font_Size_Px * Pixel_Type'Max (0.01, Scale));

   function Html_Root_Font_Size_Px
     (Root_Font       : Length_Value;
      Scale           : Pixel_Type;
      Viewport_Width  : Pixel_Type := 0.0;
      Viewport_Height : Pixel_Type := 0.0) return Pixel_Type
   is
      Base : constant Pixel_Type :=
        Length_To_Px
          (Root_Font,
           Container_Size  => Default_Root_Font_Size_Px,
           Font_Size       => Default_Root_Font_Size_Px,
           Root_Font_Size  => Default_Root_Font_Size_Px,
           Viewport_Width  => Viewport_Width,
           Viewport_Height => Viewport_Height);
   begin
      --  Resolved against the default size, which carries no content
      --  scale, so em, rem and % take it here along with px and dip.
      if Root_Font.Unit not in Vw | Vh | Pix then
         return Base * Pixel_Type'Max (0.01, Scale);
      end if;

      return Base;
   end Html_Root_Font_Size_Px;

   --  Only px and dip take the content scale. Em and rem take it from
   --  Font_Size and Root_Font_Size, which are device pixels with the
   --  scale already in them; Pct, Vw and Vh from a container or viewport
   --  that moves with it; Pix is already device pixels.
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
      if L.Unit in Px | Dip then
         return Base * Pixel_Type'Max (0.01, Scale);
      end if;

      return Base;
   end Html_Length_To_Px;

   --  Resolve a style's font-size to device pixels, mirroring the global
   --  Font_Length_To_Px: Html_Length_To_Px plus the active text scale. The
   --  render path draws Text_Part items through Font_Length_To_Px (which
   --  applies the text scale), so measurement must apply it too — otherwise
   --  measured word advances come out narrower than the drawn glyphs and
   --  words overlap horizontally under an active text scale.
   function Html_Font_Size_To_Px
     (Style           : Resolved_Style;
      Scale           : Pixel_Type;
      Root_Font_Size  : Pixel_Type;
      Viewport_Width  : Pixel_Type;
      Viewport_Height : Pixel_Type) return Pixel_Type
   is
   begin
      return Pixel_Type'Max
        (1.0,
         Html_Length_To_Px
           (Style.Font_Size,
            Scale,
            Container_Size  => Default_Font_Px (Scale),
            Font_Size       => Default_Font_Px (Scale),
            Root_Font_Size  => Root_Font_Size,
            Viewport_Width  => Viewport_Width,
            Viewport_Height => Viewport_Height)
         * Get_Active_Text_Scale);
   end Html_Font_Size_To_Px;

   function Measure_Text
     (Style : Resolved_Style;
      S     : String;
      Scale : Pixel_Type;
      Root_Font_Size : Pixel_Type;
      Viewport_Width : Pixel_Type;
      Viewport_Height : Pixel_Type) return Size_2D
   is
      Font_Px : constant Pixel_Type :=
        Html_Font_Size_To_Px
          (Style, Scale, Root_Font_Size, Viewport_Width, Viewport_Height);
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
      Font_Px : constant Pixel_Type :=
        Html_Font_Size_To_Px
          (Style, Scale, Root_Font_Size, Viewport_Width, Viewport_Height);
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
                  Container_Size => Font_Px,
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
      Font_Px : constant Pixel_Type :=
        Html_Font_Size_To_Px
          (Style, Scale, Root_Font_Size, Viewport_Width, Viewport_Height);
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
      Font_Px : constant Pixel_Type :=
        Html_Font_Size_To_Px
          (Style, Scale, Root_Font_Size, Viewport_Width, Viewport_Height);
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

   --  The link fragment under (X, Y), or 0.
   function Link_At
     (Self : Html_View;
      X, Y : Pixel_Type) return Natural
   is
   begin
      --  Last first: what was laid out later is drawn on top.
      for I in reverse 1 .. Natural (Self.Links.Length) loop
         declare
            G : constant Rectangle := Self.Links.Element (Positive (I)).Geometry;
         begin
            if Has_Visible_Area (G)
              and then X >= G.X and then X <= G.X + G.Width
              and then Y >= G.Y and then Y <= G.Y + G.Height
            then
               return I;
            end if;
         end;
      end loop;

      return 0;
   end Link_At;

   function Find_Link_At
     (Self : Html_View;
      X, Y : Pixel_Type) return String
   is
      I : constant Natural := Link_At (Self, X, Y);
   begin
      return (if I = 0 then "" else To_String (Self.Links (I).Href));
   end Find_Link_At;

   --  The a element under (X, Y), or 0.
   function Link_Node_At
     (Self : Html_View;
      X, Y : Pixel_Type) return Natural
   is
      I : constant Natural := Link_At (Self, X, Y);
   begin
      return (if I = 0 then 0 else Self.Links (I).Node);
   end Link_Node_At;

   procedure Layout_Document
     (Self : in out Html_View; Result : out Document_Layout) is
      Main_Style       : Resolved_Style renames
        Ref (Get_Resolved_Part_Handle (Self, Main_Part)).all;
      --  Copied: read again 1400+ lines down, well past any call this
      --  function makes in between.
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
      --  The item painting body's background over the canvas, or 0.
      Canvas_Index     : Natural := 0;
      Flow_Items       : Natural := 0;

      --  Panels whose top Y was tentatively set while a margin was still
      --  pending. Their Geometry.Y is rewritten to the committed Y when
      --  Flush_Pending_Margin actually advances Y.
      package Pending_Top_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Positive);

      type List_Marker_Kind is (No_Marker, Text_Marker, Image_Marker);

      type List_Marker_Run (Kind : List_Marker_Kind := No_Marker) is record
         case Kind is
            when No_Marker =>
               null;
            when Text_Marker =>
               Text : Unbounded_String := Null_Unbounded_String;
            when Image_Marker =>
               Img : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
         end case;
      end record;

      type List_Context is record
         Node_Index  : Positive := 1;
         Ordered     : Boolean := False;
         Next_Number : Integer := 1;
      end record;

      package List_Context_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => List_Context);

      List_Stack : List_Context_Vectors.Vector;

      type Line_Run_Record is record
         Item_Index : Positive := 1;
         Link_Index : Natural := 0;
         --  vertical-align: top or bottom place the run against the
         --  finished line; it is Height tall.
         Align      : Vertical_Align_Value := VA_Baseline;
         Height     : Pixel_Type := 0.0;
      end record;

      package Line_Run_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Line_Run_Record);

      --  Normal_Sizing lays out for real. The other two are trial passes
      --  that only measure how far content reaches (Flow_State.Extent):
      --  at zero width for the min-content size, at unbounded width for
      --  the max-content size.
      type Sizing_Mode is (Normal_Sizing, Min_Content_Sizing, Max_Content_Sizing);

      --  An outside list marker, and where its item's content starts.
      type Pending_Marker is record
         Marker : List_Marker_Run;
         Width  : Pixel_Type := 0.0;
         Height : Pixel_Type := 0.0;
         Gap    : Pixel_Type := 0.0;
         Left   : Pixel_Type := 0.0;
         Style  : Resolved_Style;
      end record;

      package Pending_Marker_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Pending_Marker);

      --  An inline element with a box: one that draws a background or a
      --  border, or a link's padded or bordered element, whose box is in
      --  the link's hit area. Its line fragments sit on the baseline, as
      --  tall as its font with its vertical padding and border, and do
      --  not change the line's height.
      type Inline_Box is record
         Style   : Resolved_Style;
         Drawn   : Boolean := True;
         --  The link it is in, and that link's a element; "" and 0 when
         --  none.
         Href    : Unbounded_String;
         Node    : Natural := 0;
         Border  : Edge_Pixels := Zero_Edges;
         Padding : Edge_Pixels := Zero_Edges;
         Ascent  : Pixel_Type := 0.0;
         Descent : Pixel_Type := 0.0;
         --  Where its fragment on the current line starts; negative
         --  until its content reaches the line.
         Frag_X  : Pixel_Type := -1.0;
         --  No fragment of it is on an earlier line.
         First   : Boolean := True;
         --  The item kept for its fragment on the current line, ahead of
         --  the fragment's content so it draws beneath it; 0 while none.
         Slot    : Natural := 0;
         --  Its start margin, and its start border and padding.
         Lead, Edge  : Pixel_Type := 0.0;
         --  Any of its content is laid out.
         Has_Content : Boolean := False;
         --  A wrap is moving it, start edge and all, to the next line.
         Carry       : Boolean := False;
         --  The relative range open around it.
         Shift       : Natural := 0;
         --  vertical-align: top or bottom put it against the line's edge.
         Align       : Vertical_Align_Value := VA_Baseline;
      end record;

      package Inline_Box_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Inline_Box);

      --  A fragment of an inline box on the current line, drawn once the
      --  line's baseline is final. The side edges are on its first and
      --  last fragments only.
      type Box_Fragment is record
         Box       : Inline_Box;
         Slot      : Natural := 0;
         X1, X2    : Pixel_Type := 0.0;
         Has_Left  : Boolean := True;
         Has_Right : Boolean := True;
      end record;

      package Box_Fragment_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Box_Fragment);

      --  The flow cursor, in one record so it can be saved and restored
      --  whole. Document space: the origin is the top-left of the
      --  content box and the scroll offset is not in it. Emit_Items
      --  places the result where the widget currently is and however
      --  far it is scrolled, which is what lets one layout outlive both.
      type Flow_State is record
         Line_Left  : Pixel_Type := 0.0;
         Line_Right : Pixel_Type := 0.0;
         X : Pixel_Type := 0.0;
         Y : Pixel_Type := 0.0;

         Line_Base_H       : Pixel_Type := 1.0;
         Line_Base_Ascent  : Pixel_Type := 1.0;
         Line_Base_Descent : Pixel_Type := 0.0;
         Current_Line_H       : Pixel_Type := 1.0;
         Current_Line_Ascent  : Pixel_Type := 1.0;
         Current_Line_Descent : Pixel_Type := 0.0;
         Current_Line_Align   : Text_Align_Value := Text_Start;
         Pending_Space : Boolean := False;

         --  Vertical margin collapsing: the running pending margin, so
         --  adjacent block margins collapse to max(bottom, top) and
         --  margins propagate through transparent parents.
         Prev_Block_Margin_Bottom : Pixel_Type := 0.0;

         Pending_Tops : Pending_Top_Vectors.Vector;
         Line_Runs    : Line_Run_Vectors.Vector;

         --  Right margins and padding of the open blocks, from the line's
         --  right edge out to the box being laid out.
         Right_Inset : Pixel_Type := 0.0;
         --  The furthest any content reached, right insets included.
         Extent      : Pixel_Type := 0.0;
         Sizing      : Sizing_Mode := Normal_Sizing;
         --  What a flex or grid item's own percentage margins and
         --  padding resolve against: its container's width. Negative
         --  outside Lay_Out_Item.
         Item_Base   : Pixel_Type := -1.0;

         --  Outside list markers waiting for the first line their items
         --  put content on.
         Pending_Markers : Pending_Marker_Vectors.Vector;

         --  The inline boxes open around the content, innermost last,
         --  and the fragments the current line has closed.
         Open_Boxes     : Inline_Box_Vectors.Vector;
         Line_Fragments : Box_Fragment_Vectors.Vector;
         --  The line's content ends in a space, which a following one
         --  collapses into.
         Ends_In_Space  : Boolean := False;
      end record;

      Flow : Flow_State := (Line_Right => Content.Width, others => <>);

      --  The a element whose content is being laid out, or 0.
      Link_Node : Natural := 0;

      --  The content height of the innermost block with a declared one,
      --  what a percentage height is of; negative while that is auto.
      Block_Def_H : Pixel_Type := -1.0;

      --  Absolutely positioned elements, out of the flow and laid out
      --  after it, over it: each with where the flow would have put it and
      --  its containing block, an index into Containing or 0 for the view.
      type Absolute_Entry is record
         Element      : Positive;
         Parent_Style : Resolved_Style;
         Link         : Unbounded_String;
         Static_X     : Pixel_Type := 0.0;
         Static_Y     : Pixel_Type := 0.0;
         Block        : Natural := 0;
         --  The a element it is in, or 0.
         Link_Node    : Natural := 0;
      end record;

      package Absolute_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Absolute_Entry);

      --  A positioned block: its panel, its border, and the relative
      --  offsets open around it, which move it once the layout is done.
      --  Its padding box is read from the panel when its absolutes are
      --  laid out, after anything that sizes the panel late.
      type Containing_Block is record
         Panel  : Positive := 1;
         Border : Edge_Pixels := Zero_Edges;
         DX, DY : Pixel_Type := 0.0;
         --  The innermost clip at it or around it: what clips the
         --  absolutes it contains.
         Clip   : Natural := 0;
      end record;

      package Containing_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Containing_Block);

      Absolutes : Absolute_Vectors.Vector;
      --  The positioned blocks, and the ones open around the flow,
      --  innermost last.
      Containing      : Containing_Vectors.Vector;
      Open_Containing : Node_Index_Vectors.Vector;

      --  A relatively positioned element's items and links, moved by its
      --  offset once the layout is done; and the sum of the offsets open
      --  around the flow, which what is placed later must take on.
      type Shift_Entry is record
         First_Item, Last_Item : Natural := 0;
         First_Link, Last_Link : Natural := 0;
         DX, DY                : Pixel_Type := 0.0;
         --  The entry open around it, and whether its range is closed.
         Parent                : Natural := 0;
         Closed                : Boolean := False;
      end record;

      package Shift_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Shift_Entry);

      --  A block that clips what overflows it, on one axis or both: its
      --  panel and border, and the items and links inside it. Applied
      --  once everything has moved, the panel with the rest.
      type Clip_Entry is record
         Panel                 : Positive := 1;
         Border                : Edge_Pixels := Zero_Edges;
         Clip_X, Clip_Y        : Boolean := True;
         First_Item, Last_Item : Natural := 0;
         First_Link, Last_Link : Natural := 0;
         --  The clip open around it, or 0.
         Parent                : Natural := 0;
      end record;

      package Clip_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Clip_Entry);

      Clips : Clip_Vectors.Vector;
      --  The innermost clip open around the flow, or 0.
      Open_Clip : Natural := 0;

      Shifts : Shift_Vectors.Vector;
      --  The innermost open entry, or 0.
      Open_Shift : Natural := 0;
      Rel_DX, Rel_DY : Pixel_Type := 0.0;

      --  Drops the last item, a kept item nothing filled. A range opened
      --  after it starts where the next item now goes.
      procedure Drop_Last_Item is
         S : Natural := Open_Shift;
      begin
         Result.Items.Delete_Last;
         while S /= 0 loop
            if Shifts (S).First_Item > Natural (Result.Items.Length) + 1 then
               Shifts.Reference (S).First_Item := Natural (Result.Items.Length) + 1;
            end if;
            S := Shifts (S).Parent;
         end loop;
      end Drop_Last_Item;

      --  The offsets of the closed ranges from S outward: what a link
      --  added after they closed must take on itself.
      procedure Closed_Offsets (S : Natural; DX, DY : out Pixel_Type) is
         K : Natural := S;
      begin
         DX := 0.0;
         DY := 0.0;
         while K /= 0 loop
            if Shifts (K).Closed then
               DX := DX + Shifts (K).DX;
               DY := DY + Shifts (K).DY;
            end if;
            K := Shifts (K).Parent;
         end loop;
      end Closed_Offsets;

      Line_Left  : Pixel_Type renames Flow.Line_Left;
      Line_Right : Pixel_Type renames Flow.Line_Right;
      X : Pixel_Type renames Flow.X;
      Y : Pixel_Type renames Flow.Y;
      Line_Base_H       : Pixel_Type renames Flow.Line_Base_H;
      Line_Base_Ascent  : Pixel_Type renames Flow.Line_Base_Ascent;
      Line_Base_Descent : Pixel_Type renames Flow.Line_Base_Descent;
      Current_Line_H       : Pixel_Type renames Flow.Current_Line_H;
      Current_Line_Ascent  : Pixel_Type renames Flow.Current_Line_Ascent;
      Current_Line_Descent : Pixel_Type renames Flow.Current_Line_Descent;
      Current_Line_Align   : Text_Align_Value renames Flow.Current_Line_Align;
      Pending_Space : Boolean renames Flow.Pending_Space;
      Prev_Block_Margin_Bottom : Pixel_Type renames Flow.Prev_Block_Margin_Bottom;
      Pending_Tops : Pending_Top_Vectors.Vector renames Flow.Pending_Tops;
      Line_Runs    : Line_Run_Vectors.Vector renames Flow.Line_Runs;

      procedure Add_Text_Run
        (Text  : String;
         Href  : String;
         Style : Resolved_Style);

      procedure Add_Image_Run
        (Img        : Adi.Image.Image_Handle;
         Width      : Pixel_Type;
         Height     : Pixel_Type;
         Href       : String;
         Style      : Resolved_Style);

      procedure Flush_Pending_Margin;

      function Resolve_Box_Edges
        (Box             : CSS_Box_Value;
         Style           : Resolved_Style;
         Container_Width : Pixel_Type) return Edge_Pixels;

      --  Auto margins resolve to zero here: html_view lays out its own
      --  block flow and does not distribute leftover width.
      function Resolve_Margin_Edges
        (M               : Margin_Sides;
         Style           : Resolved_Style;
         Container_Width : Pixel_Type) return Edge_Pixels;


      function Local_Font_Size_Px (Style : Resolved_Style) return Pixel_Type is
      begin
         return Pixel_Type'Max
           (1.0,
            Html_Length_To_Px
              (Style.Font_Size,
               Self.Content_Scale,
               Container_Size => Default_Font_Px (Self.Content_Scale),
               Font_Size      => Default_Font_Px (Self.Content_Scale),
               Root_Font_Size => Root_Font_Px,
               Viewport_Width => Content.Width,
               Viewport_Height => Content.Height));
      end Local_Font_Size_Px;

      --  Fold the child's font-size against the parent's already-resolved
      --  size and store the result in place, so em/rem/% resolve against
      --  the actual parent chain instead of the default 16px. Storing as
      --  Pix marks the value as final: Local_Font_Size_Px reads it back
      --  as a literal (Pix is excluded from content_scale re-application)
      --  and passes it as the em basis when this node's own children go
      --  through the same fold.
      procedure Cascade_Font_Size
        (Result       : in out Resolved_Style;
         Parent_Style : Resolved_Style)
      is
         Parent_Px : constant Pixel_Type := Local_Font_Size_Px (Parent_Style);
         Raw       : constant Pixel_Type :=
           Length_To_Px
             (Result.Font_Size,
              Container_Size  => Parent_Px,
              Font_Size       => Parent_Px,
              Root_Font_Size  => Root_Font_Px,
              Viewport_Width  => Content.Width,
              Viewport_Height => Content.Height);
         --  Px and dip take the content scale; em and rem have it
         --  through Parent_Px and Root_Font_Px, an inherited Pix is
         --  already final, and vw/vh resolve against a viewport that is
         --  not scaled here.
         Own_Px : constant Pixel_Type :=
           Pixel_Type'Max
             (1.0,
              (if Result.Font_Size.Unit in Px | Dip then
                  Raw * Pixel_Type'Max (0.01, Self.Content_Scale)
               else
                  Raw));
      begin
         Result.Font_Size := Pix (Float (Own_Px));

         --  A line height in em or % is computed here, against the size
         --  just settled, so descendants inherit the length rather than
         --  apply the factor to their own fonts.
         if Result.Line_Height.Kind = LH_Length
           and then Result.Line_Height.Height.Unit in Em | Pct
         then
            Result.Line_Height :=
              (Kind   => LH_Length,
               Height =>
                 Pix (Result.Line_Height.Height.Amount
                      / (if Result.Line_Height.Height.Unit = Pct then 100.0 else 1.0)
                      * Float (Own_Px * Get_Active_Text_Scale)));
         end if;
      end Cascade_Font_Size;

      function Local_Length_To_Px
        (L              : Length_Value;
         Container_Size : Pixel_Type := 0.0;
         Font_Size      : Pixel_Type := Default_Font_Px (Self.Content_Scale))
         return Pixel_Type
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

      --  A declared size in pixels, or Pixel_Type'Last when there is none
      --  or it is a percentage of nothing.
      function Declared_Px
        (S : Size_Value; Of_Size : Pixel_Type; Style : Resolved_Style)
         return Pixel_Type is
        (if S.Kind = Fixed and then (S.Size.Unit /= Pct or else Of_Size > 0.0)
         then Local_Length_To_Px (S.Size, Of_Size, Local_Font_Size_Px (Style))
         else Pixel_Type'Last);

      --  A block's border-box width in normal flow, from width, min-width
      --  and max-width, with leftover space given to auto margins. Set is
      --  False when none of them applies and the block fills Avail less
      --  its margins. Percentages and auto margins drop out of intrinsic
      --  measuring.
      procedure Size_Block_Width
        (Style    : Resolved_Style;
         Avail    : Pixel_Type;
         Of_W     : Pixel_Type;
         Insets_W : Pixel_Type;
         Margins  : in out Edge_Pixels;
         Set      : out Boolean;
         W        : out Pixel_Type)
      is
         Normal : constant Boolean := Flow.Sizing = Normal_Sizing;
         Pct_Of : constant Pixel_Type := (if Normal then Of_W else 0.0);
         Auto_W : constant Pixel_Type :=
           Pixel_Type'Max (0.0, Avail - Margins.Left - Margins.Right);
         Min_W  : constant Pixel_Type := Declared_Px (Style.Min_Width, Pct_Of, Style);
      begin
         W := Declared_Px (Style.Width, Pct_Of, Style);
         if W = Pixel_Type'Last then
            W := Auto_W;
         end if;
         W := Pixel_Type'Min (W, Declared_Px (Style.Max_Width, Pct_Of, Style));
         if Min_W /= Pixel_Type'Last then
            W := Pixel_Type'Max (W, Min_W);
         end if;
         W := Pixel_Type'Max (W, Insets_W);
         Set := W /= Auto_W;

         if Set and then Normal and then Style.Margin (Left).Kind = Auto then
            declare
               Free : constant Pixel_Type := Avail - W - Margins.Left - Margins.Right;
            begin
               if Free > 0.0 then
                  Margins.Left := Margins.Left
                    + (if Style.Margin (Right).Kind = Auto then Free / 2.0 else Free);
               end if;
            end;
         end if;
      end Size_Block_Width;

      function Current_Line_Width return Pixel_Type is
      begin
         return Pixel_Type'Max (0.0, Line_Right - Line_Left);
      end Current_Line_Width;

      function Has_Line_Content return Boolean is
      begin
         return X > Line_Left or else Natural (Line_Runs.Length) > 0;
      end Has_Line_Content;

      --  An HTML integer: leading whitespace, an optional sign, then
      --  digits; anything after them is ignored.
      function Parse_Integer
        (Text  : String;
         Value : out Integer) return Boolean
      is
         I        : Natural := Text'First;
         Negative : Boolean := False;
         Mag      : Long_Long_Integer := 0;
      begin
         Value := 0;
         while I <= Text'Last and then Is_Whitespace (Text (I)) loop
            I := I + 1;
         end loop;
         if I <= Text'Last and then Text (I) in '+' | '-' then
            Negative := Text (I) = '-';
            I := I + 1;
         end if;
         if I > Text'Last or else Text (I) not in '0' .. '9' then
            return False;
         end if;
         while I <= Text'Last and then Text (I) in '0' .. '9' loop
            Mag := Long_Long_Integer'Min
              (Long_Long_Integer (Integer'Last),
               Mag * 10 + Long_Long_Integer (Character'Pos (Text (I)) - Character'Pos ('0')));
            I := I + 1;
         end loop;
         Value := Integer (if Negative then -Mag else Mag);
         return True;
      end Parse_Integer;

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
        (Kind : List_Style_Type_Kind) return Image_Handle
      is
      begin
         Ensure_Marker_Images;
         case Kind is
            when List_Style_Disc   =>
               return Adi.Image.To_Handle (Disc_Marker);
            when List_Style_Circle =>
               return Adi.Image.To_Handle (Circle_Marker);
            when List_Style_Square =>
               return Adi.Image.To_Handle (Square_Marker);
            when others            => return Adi.Image.Null_Image_Handle;
         end case;
      end Marker_Image_For;

      function Marker_Text_For
        (Style          : Resolved_Style;
         Ordered_Number : Integer) return String
      is
      begin
         case Style.List_Style_Type.Kind is
            when List_Style_Decimal =>
               return Trimmed (Integer'Image (Ordered_Number)) & ".";
            when List_Style_Custom_String =>
               return Text_Of (Style.List_Style_Type.Marker);
            when others =>
               return "";
         end case;
      end Marker_Text_For;

      procedure Resolve_List_Marker
        (Style          : Resolved_Style;
         Ordered_Number : Integer;
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
               URI : constant String := Text_Of (Style.List_Style_Image.URI);
               Img : constant Adi.Image.Image_Handle := Resolve_Image (Self, URI);
               W   : Pixel_Type := 0.0;
               H   : Pixel_Type := 0.0;
               Target_H : constant Pixel_Type := Pixel_Type'Max
                 (4.0,
                 Measure_Line_Height
                    (Style,
                     Self.Content_Scale,
                     Root_Font_Px,
                     Content.Width,
                     Content.Height) * 0.72);
            begin
               if Adi.Image.Is_Valid (Img) then
                  Adi.Image.Get_Size (Img, W, H);
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
                  Img : constant Image_Handle :=
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
                  if Img /= Adi.Image.Null_Image_Handle then
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

      --  Places the outside markers still waiting for a line on the
      --  current one, each at its own item's content edge. CSS puts an
      --  outside marker on its item's first line box, which may be inside
      --  a block that opens the item.
      procedure Place_Pending_Markers is
         Waiting : constant Pending_Marker_Vectors.Vector := Flow.Pending_Markers;
         Saved_X : constant Pixel_Type := X;
      begin
         Flow.Pending_Markers.Clear;
         for M of Waiting loop
            X := M.Left;
            Add_Outside_Marker_Run (M.Marker, M.Width, M.Height, M.Gap, M.Style);
         end loop;
         X := Saved_X;
      end Place_Pending_Markers;

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
               Item_Ref : Item renames Result.Items.Reference (Run.Item_Index).Element.all;
            begin
               --  Images are replaced content: they render at their used
               --  size (explicit CSS box or intrinsic dimensions) and are
               --  never stretched to the line box — standard CSS
               --  behavior. Only text runs take the line-box height;
               --  their geometry is the line box (selection/backgrounds)
               --  and the glyphs are unaffected by it.
               if Item_Ref.Kind /= Image_Item then
                  Item_Ref.Geometry.Height := Pixel_Type'Max (Item_Ref.Geometry.Height, Current_Line_H);
               end if;
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
               Item_Ref : Item renames Result.Items.Reference (Run.Item_Index).Element.all;
            begin
               if Item_Ref.Kind = Text_Item then
                  Item_Ref.Text_Offset_Y := Item_Ref.Text_Offset_Y + Delta_Y;
               else
                  Item_Ref.Geometry.Y := Item_Ref.Geometry.Y + Delta_Y;
               end if;
            end;

            if Run.Link_Index > 0 and then Run.Link_Index <= Natural (Result.Links.Length) then
               declare
                  Link_Ref : Link_Fragment renames
                    Result.Links.Reference (Positive (Run.Link_Index)).Element.all;
               begin
                  Link_Ref.Geometry.Y := Link_Ref.Geometry.Y + Delta_Y;
               end;
            end if;
         end loop;
      end Shift_Line;

      procedure Emit_Box_Fragments (Shift_X : Pixel_Type);

      procedure Finalize_Line is
         Used_Width : constant Pixel_Type := Pixel_Type'Max (0.0, X - Line_Left);
         Available_Width : constant Pixel_Type := Current_Line_Width;
         Shift_X : Pixel_Type := 0.0;
      begin
         Sync_Line_Heights;

         --  Runs aligned to the line's top or bottom, now that its height
         --  is known.
         for Run of Line_Runs loop
            if Run.Align in VA_Top | VA_Bottom then
               declare
                  It  : Item renames Result.Items.Reference (Run.Item_Index).Element.all;
                  Off : constant Pixel_Type :=
                    (if Run.Align = VA_Top then 0.0 else Current_Line_H - Run.Height);
               begin
                  if It.Kind = Text_Item then
                     It.Text_Offset_Y := Off;
                  else
                     It.Geometry.Y := Y + Off;
                     if Run.Link_Index > 0 then
                        Result.Links.Reference (Run.Link_Index).Geometry.Y := Y + Off;
                     end if;
                  end if;
               end;
            end if;
         end loop;

         --  An open box's fragment on this line runs to its end.
         for B of Flow.Open_Boxes loop
            if B.Frag_X >= 0.0 and then not B.Carry then
               Flow.Line_Fragments.Append
                 (Box_Fragment'(Box => B, Slot => B.Slot, X1 => B.Frag_X, X2 => X,
                                Has_Left => B.First, Has_Right => False));
               B.First := False;
               B.Frag_X := -1.0;
               B.Slot := 0;
            end if;
         end loop;

         if Natural (Line_Runs.Length) = 0 then
            Emit_Box_Fragments (0.0);
            return;
         end if;

         Flow.Extent := Pixel_Type'Max (Flow.Extent, X + Flow.Right_Inset);

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
               Item_Ref : Item renames Result.Items.Reference (Run.Item_Index).Element.all;
            begin
               Item_Ref.Geometry.X := Item_Ref.Geometry.X + Shift_X;
            end;

            if Run.Link_Index > 0 and then Run.Link_Index <= Natural (Result.Links.Length) then
               declare
                  Link_Ref : Link_Fragment renames
                    Result.Links.Reference (Positive (Run.Link_Index)).Element.all;
               begin
                  Link_Ref.Geometry.X := Link_Ref.Geometry.X + Shift_X;
               end;
            end if;
         end loop;

         Emit_Box_Fragments (Shift_X);
      end Finalize_Line;

      --  Keeps an item, ahead of the content about to be appended, for
      --  every open box that has none on this line.
      procedure Reserve_Box_Slots is
      begin
         for B of Flow.Open_Boxes loop
            if B.Drawn and then B.Slot = 0 then
               Result.Items.Append (Make_Panel (Any_Part, (0.0, 0.0, 0.0, 0.0), 0));
               B.Slot := Natural (Result.Items.Last_Index);
            end if;
         end loop;
      end Reserve_Box_Slots;

      --  Content at Run_X starts the fragment of every open box that has
      --  none on this line yet.
      procedure Note_Run (Run_X : Pixel_Type) is
      begin
         for B of Flow.Open_Boxes loop
            if B.Frag_X < 0.0 then
               B.Frag_X := Run_X;
            end if;
            B.Has_Content := True;
         end loop;
      end Note_Run;

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
         Flow.Ends_In_Space := False;
      end New_Line;

      --  How far vertical-align moves a run's baseline down from the
      --  line's, for a run Ascent above it and Descent below. The parent's
      --  font is taken from the enclosing block's line metrics.
      function Baseline_Shift
        (Style : Resolved_Style; Ascent, Descent : Pixel_Type) return Pixel_Type
      is
         Font : constant Pixel_Type := Local_Font_Size_Px (Style);
      begin
         case Style.Vertical_Align is
            when VA_Baseline | VA_Top | VA_Bottom => return 0.0;
            when VA_Sub      => return 0.3 * Font;
            when VA_Super    => return -0.5 * Font;
            when VA_Text_Top => return Ascent - Line_Base_Ascent;
            when VA_Text_Bottom => return Line_Base_Descent - Descent;
            --  The middle of the run on the parent's baseline raised by
            --  half its x-height, taken as half its ascent.
            when VA_Middle   => return (Ascent - Descent) / 2.0 - Line_Base_Ascent / 4.0;
         end case;
      end Baseline_Shift;

      --  A run aligned to the line's top or bottom sits outside the
      --  baseline's metrics; the line is at least as tall as it.
      function Line_Edge_Aligned (Style : Resolved_Style) return Boolean is
        (Style.Vertical_Align in VA_Top | VA_Bottom);

      --  A break before content that does not fit. A box whose content
      --  has not started yet goes to the next line whole, its start edge
      --  with it, rather than leaving that edge behind.
      procedure Wrap_Line is
         Back_To : Pixel_Type := -1.0;
      begin
         for B of Flow.Open_Boxes loop
            if B.Frag_X >= 0.0 and then not B.Has_Content then
               B.Carry := True;
               if Back_To < 0.0 then
                  Back_To := B.Frag_X - B.Lead;
               end if;
            end if;
         end loop;
         if Back_To >= 0.0 then
            X := Back_To;
         end if;

         New_Line;

         for B of Flow.Open_Boxes loop
            if B.Carry then
               X := X + B.Lead;
               B.Frag_X := X;
               X := X + B.Edge;
               B.Carry := False;
            end if;
         end loop;
      end Wrap_Line;

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

         Result.Links.Append
           (New_Item => Link_Fragment'(Geometry => Geom,
                                       Href     => To_Unbounded_String (Href),
                                       Node     => Link_Node));
         return Natural (Result.Links.Last_Index);
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
         if not Flow.Pending_Markers.Is_Empty then
            Place_Pending_Markers;
         end if;

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
            Wrap_Line;
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

         if Line_Edge_Aligned (Style) then
            Current_Line_H :=
              Pixel_Type'Max (Current_Line_H, Run_Ascent + Run_Descent);
         else
            declare
               Shift : constant Pixel_Type := Baseline_Shift (Style, Run_Ascent, Run_Descent);
            begin
               Run_Ascent := Run_Ascent - Shift;
               Run_Descent := Run_Descent + Shift;
            end;

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
         end if;

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
            It.Style_Override := Intern (Render_Style);
            Reserve_Box_Slots;
            Result.Items.Append (It);

            Item_Index := Positive (Result.Items.Last_Index);
            Link_Index := Add_Link_Fragment (Full_Geom, Href);
            Note_Run (Full_Geom.X);
            Flow.Ends_In_Space := False;
            Line_Runs.Append
              (New_Item =>
                 Line_Run_Record'
                   (Item_Index => Item_Index,
                    Link_Index => Link_Index,
                    Align      => Style.Vertical_Align,
                    Height     => Run_Ascent + Run_Descent));
         end;

         X := X + Run_W;
      end Add_Text_Run;

      --  Border widths as drawn: a side whose style is none or hidden has
      --  none. Lengths resolve at the content scale.
      function Border_Edges (Style : Resolved_Style) return Edge_Pixels is
         Font : constant Pixel_Type := Local_Font_Size_Px (Style);

         function Side (E : Edge) return Pixel_Type is
            Kind : constant Border_Style_Kind :=
              (case Style.Border_Style.Kind is
                  when Gap_Uniform => Style.Border_Style.All_Edges,
                  when Per_Edge    => Style.Border_Style.Edges (E));
            Width : constant Length_Value :=
              (case Style.Border_Width.Kind is
                  when Gap_Uniform => Style.Border_Width.All_Edges,
                  when Per_Edge    => Style.Border_Width.Edges (E));
         begin
            return (if Kind in None_Style | Hidden then 0.0
                    else Pixel_Type'Max (0.0, Local_Length_To_Px (Width, 0.0, Font)));
         end Side;
      begin
         return (Top    => Side (Top),
                 Right  => Side (Right),
                 Bottom => Side (Bottom),
                 Left   => Side (Left));
      end Border_Edges;

      --  Style as a block's panel draws it: border widths the layout
      --  resolved, so the drawn border is the one the content is inset by.
      function Panel_Style
        (Style : Resolved_Style; Border : Edge_Pixels) return Resolved_Style
      is
         Result : Resolved_Style := Style;
      begin
         Result.Border_Width :=
           (Kind  => Per_Edge,
            Edges => [Top    => Pixels_As_Length (Border.Top),
                      Right  => Pixels_As_Length (Border.Right),
                      Bottom => Pixels_As_Length (Border.Bottom),
                      Left   => Pixels_As_Length (Border.Left)]);
         return Result;
      end Panel_Style;

      procedure Emit_Box_Fragments (Shift_X : Pixel_Type) is
         Baseline : constant Pixel_Type := Y + Current_Line_Ascent;
      begin
         for F of Flow.Line_Fragments loop
            declare
               B      : Inline_Box renames F.Box;
               Border : Edge_Pixels := B.Border;
               Left   : constant Pixel_Type := F.X1;
               --  Its content area: on the baseline, or against the line's
               --  top or bottom edge.
               Content_Top : constant Pixel_Type :=
                 (case B.Align is
                     when VA_Top    => Y,
                     when VA_Bottom => Y + Current_Line_H - (B.Ascent + B.Descent),
                     when others    => Baseline - B.Ascent);
               Top    : constant Pixel_Type :=
                 Content_Top - B.Padding.Top - Border.Top;
               Bottom : constant Pixel_Type :=
                 Content_Top + B.Ascent + B.Descent + B.Padding.Bottom + Border.Bottom;
               Style  : Resolved_Style;
               It     : Item :=
                 Make_Panel
                   (Any_Part,
                    (X      => Left + Shift_X,
                     Y      => Top,
                     Width  => Pixel_Type'Max (0.0, F.X2 - Left),
                     Height => Bottom - Top),
                    0);
            begin
               if not F.Has_Left then
                  Border.Left := 0.0;
               end if;
               if not F.Has_Right then
                  Border.Right := 0.0;
               end if;
               Style := Panel_Style (B.Style, Border);
               --  A box broken across lines is sliced: no rounding where
               --  it breaks.
               if not (F.Has_Left and then F.Has_Right) then
                  declare
                     R : Corner_Radii :=
                       (case Style.Border_Radius.Kind is
                           when Gap_Uniform => [others => Style.Border_Radius.All_Corners],
                           when Per_Corner  => Style.Border_Radius.Corners);
                  begin
                     if not F.Has_Left then
                        R (Top_Left) := Zero_Length;
                        R (Bottom_Left) := Zero_Length;
                     end if;
                     if not F.Has_Right then
                        R (Top_Right) := Zero_Length;
                        R (Bottom_Right) := Zero_Length;
                     end if;
                     Style.Border_Radius := (Kind => Per_Corner, Corners => R);
                  end;
               end if;
               It.Has_Style_Override := True;
               It.Style_Override := Intern (Style);
               if B.Drawn then
                  Result.Items.Replace_Element (F.Slot, It);
               end if;
               if Length (B.Href) > 0 then
                  declare
                     DX, DY : Pixel_Type;
                     G      : Rectangle := It.Geometry;
                  begin
                     Closed_Offsets (B.Shift, DX, DY);
                     G.X := G.X + DX;
                     G.Y := G.Y + DY;
                     Result.Links.Append
                       (Link_Fragment'(Geometry => G, Href => B.Href, Node => B.Node));
                  end;
               end if;
            end;
         end loop;
         Flow.Line_Fragments.Clear;
      end Emit_Box_Fragments;

      procedure Add_Image_Run
        (Img        : Adi.Image.Image_Handle;
         Width      : Pixel_Type;
         Height     : Pixel_Type;
         Href       : String;
         Style      : Resolved_Style)
      is
         Run_Ascent  : Pixel_Type := Height;
         Run_Descent : Pixel_Type := 0.0;
         Top_Y       : Pixel_Type := 0.0;
         Full_Geom   : Rectangle := (0.0, 0.0, 0.0, 0.0);
      begin
         if Width <= 0.0 or else Height <= 0.0 then
            return;
         end if;

         Flush_Pending_Margin;
         if not Flow.Pending_Markers.Is_Empty then
            Place_Pending_Markers;
         end if;

         if Wrap_Allowed (Style)
           and then X > Line_Left
           and then X + Width > Line_Right
         then
            Wrap_Line;
         end if;

         if Line_Edge_Aligned (Style) then
            Current_Line_H := Pixel_Type'Max (Current_Line_H, Height);
         else
            declare
               Shift : constant Pixel_Type := Baseline_Shift (Style, Run_Ascent, Run_Descent);
            begin
               Run_Ascent := Run_Ascent - Shift;
               Run_Descent := Run_Descent + Shift;
            end;

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
         end if;

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
            declare
               Override : Resolved_Style := Panel_Style (Style, Border_Edges (Style));
            begin
               if Img /= Adi.Image.Null_Image_Handle
                 and then Adi.Image.Is_Tintable (Img)
               then
                  Override.Object_Fit := Fit_Scale_Down;
                  Override.Object_Position :=
                    Object_Position (Pos_Center, Pos_Top);
               end if;
               It.Style_Override := Intern (Override);
            end;
            Reserve_Box_Slots;
            Result.Items.Append (It);

            Item_Index := Positive (Result.Items.Last_Index);
            Link_Index := Add_Link_Fragment (Full_Geom, Href);
            Note_Run (Full_Geom.X);
            Flow.Ends_In_Space := False;
            Line_Runs.Append
              (New_Item =>
                 Line_Run_Record'
                   (Item_Index => Item_Index,
                    Link_Index => Link_Index,
                    Align      => Style.Vertical_Align,
                    Height     => Height));
         end;

         X := X + Width;
      end Add_Image_Run;

      procedure Add_Horizontal_Rule (Style : Resolved_Style) is
         Margin_Edges : Edge_Pixels :=
           Resolve_Margin_Edges (Style.Margin, Style, Current_Line_Width);
         Rule_H : Pixel_Type := 1.0;
         Rule_W : Pixel_Type;
         Sized  : Boolean;
         Rule_Geom : Rectangle;
      begin
         Size_Block_Width
           (Style, Current_Line_Width, Current_Line_Width, 0.0, Margin_Edges, Sized, Rule_W);

         if Has_Line_Content or else Pending_Space then
            New_Line;
         end if;

         --  Collapse hr's top margin with anything pending (siblings or a
         --  transparent parent), then commit Y so the rule lands beneath
         --  the collapsed gap.
         Prev_Block_Margin_Bottom :=
           Pixel_Type'Max (Prev_Block_Margin_Bottom, Margin_Edges.Top);
         Flush_Pending_Margin;

         declare
            Decl_H : constant Pixel_Type :=
              Declared_Px (Style.Height, Pixel_Type'Max (0.0, Block_Def_H), Style);
         begin
            if Decl_H /= Pixel_Type'Last then
               Rule_H := Pixel_Type'Max (1.0, Decl_H);
            end if;
         end;

          Current_Line_H := Pixel_Type'Max (Current_Line_H, Rule_H);
          Rule_Geom :=
            (X      => Line_Left + Margin_Edges.Left,
             Y      => Y + (Current_Line_H - Rule_H) / 2.0,
             Width  => Rule_W,
             Height => Rule_H);

         declare
            It : Item := Make_Panel (Any_Part, Rule_Geom, 1);
         begin
            It.Has_Style_Override := True;
            It.Style_Override := Intern (Panel_Style (Style, Border_Edges (Style)));
            Result.Items.Append (It);
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
               if Has_Line_Content and then not Flow.Ends_In_Space then
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

      --  A forced line break: rendered content, so it commits a pending
      --  margin, and the line it ends is its item's first line box if
      --  nothing came before it.
      procedure Forced_Break is
      begin
         Flush_Pending_Margin;
         if not Flow.Pending_Markers.Is_Empty then
            Place_Pending_Markers;
         end if;
         New_Line;
      end Forced_Break;

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
               --  A rendered newline is real content, like <br>.
               Forced_Break;
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

               --  A rendered newline is real content, like <br>.
               Forced_Break;
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
            Result.Items.Reference (Idx).Geometry.Y := Y;
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

         --  Flush_Pending_Margin is called inside Add_Text_Run / Add_Image_Run; whitespace-only text in collapsed mode never reaches those, so it must not commit a pending margin here.

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
            return Style.Display in Block | Flex | Inline_Flex | Grid | Inline_Grid;
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

      function Resolve_Margin_Edges
        (M               : Margin_Sides;
         Style           : Resolved_Style;
         Container_Width : Pixel_Type) return Edge_Pixels
      is
         Font_Px : constant Pixel_Type := Local_Font_Size_Px (Style);

         function To_Px (Side : Margin_Value) return Pixel_Type is
         begin
            if Side.Kind = Auto then
               return 0.0;
            end if;
            return Local_Length_To_Px
              (Side.Length,
               Container_Size => Container_Width,
               Font_Size => Font_Px);
         end To_Px;
      begin
         return
           (Top    => To_Px (M (Top)),
            Right  => To_Px (M (Right)),
            Bottom => To_Px (M (Bottom)),
            Left   => To_Px (M (Left)));
      end Resolve_Margin_Edges;

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
         Attrs      : Element_Attributes) return Integer
      is
         Ctx_Idx : constant Natural :=
           Find_List_Context (Self.Nodes.Element (Node_Index).Parent);
         Ctx : List_Context;
         Explicit_Value : Integer := 0;
         Number : Integer := 0;
      begin
         if Ctx_Idx = 0 then
            return 0;
         end if;

         Ctx := List_Stack.Element (Positive (Ctx_Idx));
         if not Ctx.Ordered then
            return 0;
         end if;

         if Length (Attrs.Value_Attr) > 0
           and then Parse_Integer (To_String (Attrs.Value_Attr), Explicit_Value)
         then
            Ctx.Next_Number := Explicit_Value;
         end if;

         Number := Ctx.Next_Number;
         if Ctx.Next_Number < Integer'Last then
            Ctx.Next_Number := Ctx.Next_Number + 1;
         end if;
         List_Stack.Replace_Element (Positive (Ctx_Idx), Ctx);
         return Number;
      end Resolve_List_Item_Number;

      procedure Layout_Node
        (Node_Index   : Positive;
         Parent_Style : Resolved_Style;
         Active_Link  : String;
         As_Item      : Boolean := False);

      --  One flex or grid item: an element child, or a run of text and
      --  breaks between element children (an anonymous item).
      type Item_Source is record
         Element     : Natural := 0;
         First, Last : Positive := 1;
      end record;

      package Item_Source_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Item_Source);

      function Is_Atomic (Tag : String) return Boolean is
        (Tag = "img" or else Tag = "svg" or else Tag = "hr");

      function Element_Style
        (Element : Positive; Parent_Style : Resolved_Style) return Resolved_Style
      is
         Style : Resolved_Style :=
           Resolve_Element_Style
             (Element_Cascade_Rules (Self, Element), Parent_Style, True);
      begin
         Cascade_Font_Size (Style, Parent_Style);
         return Style;
      end Element_Style;

      --  The in-flow items of Parent. Whitespace-only runs and elements
      --  with display: none are not items.
      --  Takes an absolutely positioned element out of the flow, to be
      --  laid out after it. Where the flow is now is where it would have
      --  gone: at the line's start, below any content on it, for a block.
      --  A fixed element's containing block is the view's.
      procedure Enqueue_Absolute
        (Element      : Positive;
         Parent_Style : Resolved_Style;
         Link         : String;
         Block_Level  : Boolean;
         Fixed        : Boolean) is
      begin
         Absolutes.Append
           (Absolute_Entry'
              (Element      => Element,
               Parent_Style => Parent_Style,
               Link         => To_Unbounded_String (Link),
               Static_X     => (if Block_Level then Line_Left else X) + Rel_DX,
               Static_Y     =>
                 (if not Block_Level then Y
                  elsif Has_Line_Content then Y + Current_Line_H
                  else Y + Prev_Block_Margin_Bottom) + Rel_DY,
               Block        =>
                 (if Fixed or else Open_Containing.Is_Empty then 0
                  else Open_Containing.Last_Element),
               Link_Node    => Link_Node));
      end Enqueue_Absolute;

      --  A flex or grid container's absolutely positioned children, which
      --  are not its items; they start from its content box's corner.
      procedure Enqueue_Absolute_Children
        (Parent : Node; Parent_Style : Resolved_Style; Link : String) is
      begin
         for Idx of Parent.Children loop
            if Idx > 0 and then Self.Nodes (Idx).Kind = Element_Node then
               declare
                  S : constant Resolved_Style := Element_Style (Idx, Parent_Style);
               begin
                  if S.Display /= Display_None and then S.Position in Absolute | Fixed then
                     Enqueue_Absolute (Idx, Parent_Style, Link, Block_Level => True,
                                       Fixed => S.Position = Fixed);
                  end if;
               end;
            end if;
         end loop;
      end Enqueue_Absolute_Children;

      function Item_Sources
        (Parent : Node; Parent_Style : Resolved_Style)
         return Item_Source_Vectors.Vector
      is
         Result_Items : Item_Source_Vectors.Vector;
         Run_First    : Natural := 0;
         Run_Has_Text : Boolean := False;

         procedure Close_Run (Last : Natural) is
         begin
            if Run_First > 0 and then Run_Has_Text then
               Result_Items.Append (Item_Source'(Element => 0, First => Run_First, Last => Last));
            end if;
            Run_First := 0;
            Run_Has_Text := False;
         end Close_Run;
      begin
         for K in 1 .. Natural (Parent.Children.Length) loop
            declare
               Idx : constant Natural := Parent.Children.Element (K);
            begin
               if Idx > 0 then
                  declare
                     C : constant Node := Self.Nodes.Element (Idx);
                  begin
                     if C.Kind = Element_Node then
                        Close_Run (K - 1);
                        declare
                           S : constant Resolved_Style := Element_Style (Idx, Parent_Style);
                        begin
                           --  An absolutely positioned child is not an item.
                           if S.Display /= Display_None
                             and then S.Position not in Absolute | Fixed
                           then
                              Result_Items.Append
                                (Item_Source'(Element => Idx, First => K, Last => K));
                           end if;
                        end;
                     else
                        if Run_First = 0 then
                           Run_First := K;
                        end if;
                        if C.Kind = Text_Node
                          and then (for some Ch of To_String (C.Text) =>
                                      not Is_Whitespace (Ch))
                        then
                           Run_Has_Text := True;
                        end if;
                     end if;
                  end;
               end if;
            end;
         end loop;
         Close_Run (Natural (Parent.Children.Length));
         return Result_Items;
      end Item_Sources;

      --  Lay out one item with its border box at Box.X, Box.Y, Box.Width,
      --  in a flow of its own, and report where it ended. Box.Height is
      --  not read: the content decides. Margin is the item's as its own
      --  block entry will resolve it against Pct_Base; zero for an
      --  atomic item, which places none.
      procedure Lay_Out_Item
        (Parent       : Node;
         Src          : Item_Source;
         Parent_Style : Resolved_Style;
         Link         : String;
         Box          : Rectangle;
         Margin       : Edge_Pixels;
         Pct_Base     : Pixel_Type;
         Sizing       : Sizing_Mode;
         Bottom       : out Pixel_Type;
         Extent       : out Pixel_Type)
      is
         Outer : constant Flow_State := Flow;
      begin
         Flow :=
           (Line_Left            => Box.X - Margin.Left,
            Line_Right           => Box.X + Box.Width + Margin.Right,
            X                    => Box.X - Margin.Left,
            Y                    => Box.Y - Pixel_Type'Max (0.0, Margin.Top),
            Line_Base_H          => Outer.Line_Base_H,
            Line_Base_Ascent     => Outer.Line_Base_Ascent,
            Line_Base_Descent    => Outer.Line_Base_Descent,
            Current_Line_H       => Outer.Line_Base_H,
            Current_Line_Ascent  => Outer.Line_Base_Ascent,
            Current_Line_Descent => Outer.Line_Base_Descent,
            Current_Line_Align   => Outer.Current_Line_Align,
            Extent               => Box.X,
            Sizing               => Sizing,
            Item_Base            => Pct_Base,
            others               => <>);

         if Src.Element > 0 then
            Layout_Node (Src.Element, Parent_Style, Link, As_Item => True);
         else
            for K in Src.First .. Src.Last loop
               if Parent.Children.Element (K) > 0 then
                  Layout_Node (Parent.Children.Element (K), Parent_Style, Link);
               end if;
            end loop;
         end if;

         --  Text, or an image, left on an unfinished line.
         if Has_Line_Content or else Pending_Space then
            New_Line;
         end if;

         Bottom := Flow.Y;
         Extent := Flow.Extent;
         Flow := Outer;
      end Lay_Out_Item;

      --  Measurements taken during this layout, so an item nested in
      --  several flex or grid containers is not laid out again for each.
      type Trial_Key is record
         Node   : Positive;
         Sizing : Sizing_Mode;
         --  Sixty-fourths of a pixel; Width is zero for the width-free
         --  modes.
         Width  : Long_Integer;
         Base   : Long_Integer;
      end record;

      function "<" (L, R : Trial_Key) return Boolean is
        (if L.Node /= R.Node then L.Node < R.Node
         elsif L.Sizing /= R.Sizing then L.Sizing < R.Sizing
         elsif L.Width /= R.Width then L.Width < R.Width
         else L.Base < R.Base);

      function Sixty_Fourths (P : Pixel_Type) return Long_Integer is
        (Long_Integer (Long_Float'Rounding (Long_Float (P) * 64.0)));

      type Trial_Result is record
         Bottom, Extent : Pixel_Type := 0.0;
      end record;

      package Trial_Maps is new Ada.Containers.Ordered_Maps
        (Key_Type => Trial_Key, Element_Type => Trial_Result);

      Trials : Trial_Maps.Map;

      --  Lay Src out at Width and throw the result away, keeping only
      --  how tall it came out and how far its content reached.
      function Trial
        (Parent       : Node;
         Src          : Item_Source;
         Parent_Style : Resolved_Style;
         Margin       : Edge_Pixels;
         Pct_Base     : Pixel_Type;
         Sizing       : Sizing_Mode;
         Width        : Pixel_Type) return Trial_Result
      is
         --  Margin follows from Pct_Base, so the key need not carry it.
         Key : constant Trial_Key :=
           (Node   => (if Src.Element > 0 then Src.Element
                       else Parent.Children.Element (Src.First)),
            Sizing => Sizing,
            Width  => (if Sizing = Normal_Sizing then Sixty_Fourths (Width) else 0),
            Base   => Sixty_Fourths (Pct_Base));
         Found : constant Trial_Maps.Cursor := Trials.Find (Key);
      begin
         if Trial_Maps.Has_Element (Found) then
            return Trial_Maps.Element (Found);
         end if;

         declare
            Item_Mark : constant Ada.Containers.Count_Type := Result.Items.Length;
            Link_Mark : constant Ada.Containers.Count_Type := Result.Links.Length;
            Lists     : constant List_Context_Vectors.Vector := List_Stack;
            Abs_Mark  : constant Ada.Containers.Count_Type := Absolutes.Length;
            Shift_Mark : constant Ada.Containers.Count_Type := Shifts.Length;
            Clip_Mark  : constant Ada.Containers.Count_Type := Clips.Length;
            R         : Trial_Result;
         begin
            Lay_Out_Item
              (Parent, Src, Parent_Style, "", (0.0, 0.0, Width, 0.0), Margin,
               Pct_Base, Sizing, R.Bottom, R.Extent);
            Result.Items.Set_Length (Item_Mark);
            Result.Links.Set_Length (Link_Mark);
            Absolutes.Set_Length (Abs_Mark);
            Shifts.Set_Length (Shift_Mark);
            Clips.Set_Length (Clip_Mark);
            List_Stack := Lists;
            Trials.Insert (Key, R);
            return R;
         end;
      end Trial;

      Unbounded_Width : constant Pixel_Type := 1.0E6;

      --  An item's min-content and max-content border-box widths.
      procedure Content_Widths
        (Parent       : Node;
         Src          : Item_Source;
         Parent_Style : Resolved_Style;
         Margin       : Edge_Pixels;
         Pct_Base     : Pixel_Type;
         Min_W, Max_W : out Pixel_Type) is
      begin
         Min_W := Pixel_Type'Max
           (0.0, Trial (Parent, Src, Parent_Style, Margin, Pct_Base,
                        Min_Content_Sizing, 0.0).Extent - Margin.Right);
         Max_W := Pixel_Type'Max
           (Min_W, Trial (Parent, Src, Parent_Style, Margin, Pct_Base,
                          Max_Content_Sizing, Unbounded_Width).Extent - Margin.Right);
      end Content_Widths;

      --  An item's border-box height at border-box width Width.
      function Height_At
        (Parent       : Node;
         Src          : Item_Source;
         Parent_Style : Resolved_Style;
         Margin       : Edge_Pixels;
         Pct_Base     : Pixel_Type;
         Width        : Pixel_Type) return Pixel_Type is
        (Pixel_Type'Max
           (0.0, Trial (Parent, Src, Parent_Style, Margin, Pct_Base,
                        Normal_Sizing, Width).Bottom));


      function Gap_Px
        (G : Gap_Value; Row_Gap : Boolean; Of_Size : Pixel_Type;
         Style : Resolved_Style) return Pixel_Type
      is
         L : constant Length_Value :=
           (case G.Kind is
               when Gap_Uniform  => G.All_Gap,
               when Gap_Separate => (if Row_Gap then G.Row_Gap else G.Column_Gap));
      begin
         return Local_Length_To_Px (L, Of_Size, Local_Font_Size_Px (Style));
      end Gap_Px;

      --  What a flex or grid container learns about each of its items
      --  before it places them.
      type Item_Measure is record
         Style       : Resolved_Style;
         --  What the solver places the item by.
         Margin      : Edge_Pixels := Zero_Edges;
         --  What the item's own flow places it by: an atomic item places
         --  nothing, and hr keeps its margins in its own flow.
         Flow_Margin : Edge_Pixels := Zero_Edges;
         Min_C       : Pixel_Type := 0.0;
         Max_C       : Pixel_Type := 0.0;
         Decl_W      : Pixel_Type := Pixel_Type'Last;
         Decl_H      : Pixel_Type := Pixel_Type'Last;
      end record;

      type Item_Measure_Array is array (Positive range <>) of Item_Measure;

      function Tag_Of (Src : Item_Source) return String is
        (if Src.Element > 0
         then To_String (Self.Nodes.Element (Src.Element).Tag_Name)
         else "");

      --  Styles, margins, declared sizes and min-/max-content widths.
      --  Percentages resolve against Pct_Base across and Of_H down.
      function Measure_Items
        (Parent   : Node;
         Style    : Resolved_Style;
         Sources  : Item_Source_Vectors.Vector;
         Pct_Base : Pixel_Type;
         Of_H     : Pixel_Type) return Item_Measure_Array
      is
         Items : Item_Measure_Array (1 .. Natural (Sources.Length));
      begin
         for I in Items'Range loop
            declare
               Src : constant Item_Source := Sources.Element (I);
               It  : Item_Measure renames Items (I);
            begin
               It.Style :=
                 (if Src.Element > 0 then Element_Style (Src.Element, Style)
                  else Resolve_Element_Style (Empty_Style, Style, True));
               It.Margin :=
                 (if Src.Element > 0 and then Tag_Of (Src) /= "hr"
                  then Resolve_Margin_Edges (It.Style.Margin, It.Style, Pct_Base)
                  else Zero_Edges);
               It.Flow_Margin :=
                 (if Is_Atomic (Tag_Of (Src)) then Zero_Edges else It.Margin);
               Content_Widths
                 (Parent, Src, Style, It.Flow_Margin, Pct_Base, It.Min_C, It.Max_C);
               It.Decl_W := Declared_Px (It.Style.Width, Pct_Base, It.Style);
               It.Decl_H := Declared_Px (It.Style.Height, Of_H, It.Style);
            end;
         end loop;
         return Items;
      end Measure_Items;

      --  Lay each item out at its border box and make its panel that box.
      procedure Place_Items
        (Parent   : Node;
         Style    : Resolved_Style;
         Link     : String;
         Sources  : Item_Source_Vectors.Vector;
         Items    : Item_Measure_Array;
         Boxes    : Rectangle_Array;
         Pct_Base : Pixel_Type)
      is
         use type Ada.Containers.Count_Type;
      begin
         for I in Items'Range loop
            declare
               Src    : constant Item_Source := Sources.Element (I);
               Mark   : constant Ada.Containers.Count_Type := Result.Items.Length;
               Bottom : Pixel_Type;
               Extent : Pixel_Type;
            begin
               Lay_Out_Item
                 (Parent, Src, Style, Link, Boxes (I), Items (I).Flow_Margin,
                  Pct_Base, Normal_Sizing, Bottom, Extent);
               --  The item's own panel is the first thing it added; the
               --  box the layout gave it overrides its content.
               if Src.Element > 0
                 and then not Is_Atomic (Tag_Of (Src))
                 and then Result.Items.Length > Mark
               then
                  Result.Items.Reference (Positive (Mark) + 1).Geometry := Boxes (I);
               end if;
            end;
         end loop;
      end Place_Items;

      --  A declared minimum that does not resolve is none.
      function Minimum_Px
        (V : Size_Value; Of_Size : Pixel_Type; Style : Resolved_Style)
         return Pixel_Type
      is
         P : constant Pixel_Type := Declared_Px (V, Of_Size, Style);
      begin
         return (if P = Pixel_Type'Last then 0.0 else P);
      end Minimum_Px;

      --  The container's content height when its own height is declared,
      --  else Pixel_Type'Last.
      --  The container's declared content height, as its block resolved
      --  it, or Pixel_Type'Last while that is auto.
      function Fixed_Content_Height return Pixel_Type is
        (if Block_Def_H < 0.0 then Pixel_Type'Last else Block_Def_H);

      --  A flex or grid container lays out no lines of its own, so outside
      --  markers waiting for one go beside its top edge, on a line that
      --  is closed without moving down.
      procedure Place_Markers_At_Top is
      begin
         if Flow.Pending_Markers.Is_Empty then
            return;
         end if;
         Place_Pending_Markers;
         Finalize_Line;
         Line_Runs.Clear;
         X := Line_Left;
         Current_Line_H := Line_Base_H;
         Current_Line_Ascent := Line_Base_Ascent;
         Current_Line_Descent := Line_Base_Descent;
      end Place_Markers_At_Top;

      --  Lay out Parent's children as flex items in the content box the
      --  enclosing block left open: Line_Left .. Line_Right from Y down.
      --  Leaves Y at the bottom of the container's content.
      procedure Layout_Flex_Container
        (Parent  : Node;
         Style   : Resolved_Style;
         Link    : String)
      is
         Dir     : constant Flex_Direction_Value := Style.Flex_Direction;
         Is_Row  : constant Boolean := Is_Row_Direction (Dir);
         Left    : constant Pixel_Type := Line_Left;
         Avail   : constant Pixel_Type := Current_Line_Width;
         --  A trial pass sizes content, not a box: percentages of the
         --  container count as nothing there.
         Pct_Base : constant Pixel_Type :=
           (if Flow.Sizing = Normal_Sizing then Avail else 0.0);
         Sources : constant Item_Source_Vectors.Vector :=
           Item_Sources (Parent, Style);
         Count   : constant Natural := Natural (Sources.Length);

         Fixed_H : constant Pixel_Type := Fixed_Content_Height;
         Of_H : constant Pixel_Type :=
           (if Fixed_H = Pixel_Type'Last then 0.0 else Fixed_H);

         Column_Gap : constant Pixel_Type := Gap_Px (Style.Gap, False, Pct_Base, Style);
         Row_Gap    : constant Pixel_Type := Gap_Px (Style.Gap, True, Of_H, Style);
         Main_Gap   : constant Pixel_Type := (if Is_Row then Column_Gap else Row_Gap);
         Cross_Gap  : constant Pixel_Type := (if Is_Row then Row_Gap else Column_Gap);
         Top        : Pixel_Type;
      begin
         Enqueue_Absolute_Children (Parent, Style, Link);
         Flush_Pending_Margin;
         Place_Markers_At_Top;
         Top := Y;

         if Count = 0 then
            Y := Top + Of_H;
            return;
         end if;

         declare
            Items     : constant Item_Measure_Array :=
              Measure_Items (Parent, Style, Sources, Pct_Base, Of_H);
            Infos     : Flex_Child_Info_Array (1 .. Count);
            Ctx       : Flex_Layout_Context;
            Content_H : Pixel_Type := 0.0;

            function Src (I : Positive) return Item_Source is (Sources.Element (I));

            function Stretches (I : Positive) return Boolean is
              ((Items (I).Style.Align_Self = Stretch
                or else (Items (I).Style.Align_Self = Auto
                         and then Style.Align_Items = Stretch))
               and then Items (I).Decl_W = Pixel_Type'Last);

            function Height_Of (I : Positive; Width : Pixel_Type) return Pixel_Type is
              (Height_At (Parent, Src (I), Style, Items (I).Flow_Margin, Pct_Base, Width));

            --  Cross size of the lines the items form, gaps included.
            function Lines_Cross return Pixel_Type is
               Ranges : Flex_Line_Array (1 .. Count);
               Lines  : Natural;
               Total  : Pixel_Type := 0.0;
            begin
               Form_Flex_Lines
                 (Get_Main_Size ((Ctx.Container.Width, Ctx.Container.Height), Dir),
                  Main_Gap, Dir, Style.Flex_Wrap, Infos, Ranges, Lines);
               for L in 1 .. Lines loop
                  declare
                     Deepest : Pixel_Type := 0.0;
                  begin
                     for I in Ranges (L).First .. Ranges (L).Last loop
                        Deepest := Pixel_Type'Max
                          (Deepest,
                           Pixel_Type'Max
                             (Infos (I).Min_Cross,
                              Pixel_Type'Min (Infos (I).Max_Cross, Infos (I).Content_Cross))
                           + (if Is_Row
                              then Items (I).Margin.Top + Items (I).Margin.Bottom
                              else Items (I).Margin.Left + Items (I).Margin.Right));
                     end loop;
                     Total := Total + Deepest;
                  end;
               end loop;
               return Total + Cross_Gap * Pixel_Type (Natural'Max (0, Lines - 1));
            end Lines_Cross;
         begin
            --  A trial pass only wants to know how wide the container's
            --  content gets.
            if Flow.Sizing /= Normal_Sizing then
               declare
                  Wide : Pixel_Type := 0.0;
               begin
                  for I in 1 .. Count loop
                     declare
                        Own : constant Pixel_Type :=
                          (if Items (I).Decl_W /= Pixel_Type'Last then Items (I).Decl_W
                           elsif Flow.Sizing = Min_Content_Sizing then Items (I).Min_C
                           else Items (I).Max_C)
                          + Items (I).Margin.Left + Items (I).Margin.Right;
                     begin
                        if Is_Row
                          and then (Flow.Sizing = Max_Content_Sizing
                                    or else Style.Flex_Wrap = No_Wrap)
                        then
                           Wide := Wide + Own + (if I > 1 then Main_Gap else 0.0);
                        else
                           Wide := Pixel_Type'Max (Wide, Own);
                        end if;
                     end;
                  end loop;
                  Flow.Extent :=
                    Pixel_Type'Max (Flow.Extent, Left + Wide + Flow.Right_Inset);
                  Y := Top + Of_H;
                  return;
               end;
            end if;

            for I in 1 .. Count loop
               declare
                  It    : Item_Measure renames Items (I);
                  S     : Resolved_Style renames It.Style;
                  M     : Edge_Pixels renames It.Margin;
                  Max_W : constant Pixel_Type := Declared_Px (S.Max_Width, Pct_Base, S);
                  Max_H : constant Pixel_Type := Declared_Px (S.Max_Height, Of_H, S);
                  Min_W : constant Pixel_Type := Minimum_Px (S.Min_Width, Pct_Base, S);
                  Min_H : constant Pixel_Type := Minimum_Px (S.Min_Height, Of_H, S);
                  Sizes : Flex_Item_Sizes;

                  function Clamp_W (W : Pixel_Type) return Pixel_Type is
                    (Pixel_Type'Max (Min_W, Pixel_Type'Min (Max_W, W)));
               begin
                  Sizes.Demand   := (Min_W, Min_H);
                  Sizes.Declared := (It.Decl_W, It.Decl_H);
                  Sizes.Max      := (Max_W, Max_H);
                  Sizes.Margin   := M;

                  if Is_Row then
                     declare
                        Pref_W : constant Pixel_Type :=
                          (if It.Decl_W /= Pixel_Type'Last then It.Decl_W else It.Max_C);
                     begin
                        Sizes.Base :=
                          (case S.Flex_Basis.Kind is
                              when Fixed =>
                                 Local_Length_To_Px
                                   (S.Flex_Basis.Size, Pct_Base, Local_Font_Size_Px (S)),
                              when CSS_Styles.Content => It.Max_C,
                              when Auto => Pref_W);
                        Sizes.Content_Min := (It.Min_C, 0.0);
                        Sizes.Preferred :=
                          (Pref_W,
                           (if It.Decl_H /= Pixel_Type'Last then It.Decl_H
                            else Height_Of
                                   (I, Clamp_W (Pixel_Type'Min
                                                  (Sizes.Base,
                                                   Pixel_Type'Max
                                                     (0.0, Avail - M.Left - M.Right))))));
                     end;
                  else
                     declare
                        Room : constant Pixel_Type :=
                          Pixel_Type'Max (0.0, Avail - M.Left - M.Right);
                        W : constant Pixel_Type := Clamp_W
                          (if It.Decl_W /= Pixel_Type'Last then It.Decl_W
                           elsif Stretches (I) then Room
                           else Pixel_Type'Min (It.Max_C, Pixel_Type'Max (It.Min_C, Room)));
                        H : constant Pixel_Type :=
                          (if It.Decl_H /= Pixel_Type'Last then It.Decl_H
                           else Height_Of (I, W));
                     begin
                        Sizes.Base :=
                          (if S.Flex_Basis.Kind = Fixed
                           then Local_Length_To_Px
                                  (S.Flex_Basis.Size, Of_H, Local_Font_Size_Px (S))
                           else H);
                        Sizes.Content_Min := (It.Min_C, H);
                        Sizes.Preferred := (W, H);
                     end;
                  end if;

                  Infos (I) := Make_Flex_Child_Info (S, Dir, Sizes);
               end;
            end loop;

            Ctx := Make_Flex_Context (Style, (Left, Top, Avail, 0.0));
            Ctx.Main_Gap  := Main_Gap;
            Ctx.Cross_Gap := Cross_Gap;

            if Is_Row then
               Ctx.Container.Height :=
                 (if Fixed_H /= Pixel_Type'Last then Fixed_H else Lines_Cross);
               Compute_Flex_Layout (Ctx, Infos);

               --  Heights depend on the widths just given out.
               declare
                  Changed : Boolean := False;
               begin
                  for I in 1 .. Count loop
                     if Items (I).Decl_H = Pixel_Type'Last then
                        declare
                           H : constant Pixel_Type := Height_Of (I, Infos (I).Computed_Main);
                        begin
                           if abs (H - Infos (I).Content_Cross) > 0.5 then
                              Infos (I).Content_Cross := H;
                              Changed := True;
                           end if;
                        end;
                     end if;
                  end loop;
                  if Changed then
                     if Fixed_H = Pixel_Type'Last then
                        Ctx.Container.Height := Lines_Cross;
                     end if;
                     Compute_Flex_Layout (Ctx, Infos);
                  end if;
               end;
            else
               if Fixed_H /= Pixel_Type'Last then
                  Ctx.Container.Height := Fixed_H;
               else
                  for I in 1 .. Count loop
                     Ctx.Container.Height := Ctx.Container.Height
                       + Hypothetical_Main_Size (Infos (I))
                       + Items (I).Margin.Top + Items (I).Margin.Bottom
                       + (if I > 1 then Main_Gap else 0.0);
                  end loop;
               end if;
               Compute_Flex_Layout (Ctx, Infos);
            end if;
            Content_H := Ctx.Container.Height;

            Place_Items
              (Parent, Style, Link, Sources, Items,
               Flex_To_Rectangles (Ctx, Infos), Pct_Base);

            Y := Top + Content_H;
         end;

         X := Line_Left;
         Pending_Space := False;
         Prev_Block_Margin_Bottom := 0.0;
      end Layout_Flex_Container;

      --  Lay out Parent's children as grid items, as Layout_Flex_Container
      --  does for flex items.
      procedure Layout_Grid_Container
        (Parent  : Node;
         Style   : Resolved_Style;
         Link    : String)
      is
         Left    : constant Pixel_Type := Line_Left;
         Avail   : constant Pixel_Type := Current_Line_Width;
         Pct_Base : constant Pixel_Type :=
           (if Flow.Sizing = Normal_Sizing then Avail else 0.0);
         Sources : constant Item_Source_Vectors.Vector :=
           Item_Sources (Parent, Style);
         Count   : constant Natural := Natural (Sources.Length);

         Fixed_H : constant Pixel_Type := Fixed_Content_Height;
         Of_H : constant Pixel_Type :=
           (if Fixed_H = Pixel_Type'Last then 0.0 else Fixed_H);
         Top     : Pixel_Type;
      begin
         Enqueue_Absolute_Children (Parent, Style, Link);
         Flush_Pending_Margin;
         Place_Markers_At_Top;
         Top := Y;

         if Count = 0 then
            Y := Top + Of_H;
            return;
         end if;

         declare
            Items : constant Item_Measure_Array :=
              Measure_Items (Parent, Style, Sources, Pct_Base, Of_H);
            Kids  : Grid_Child_Info_Array (1 .. Count);
            Ctx   : Grid_Layout_Context :=
              Make_Grid_Context (Style, (Left, Top, Pct_Base, Of_H));
            Cols  : Layout_Util.Pixel_Array (1 .. Natural'Max (1, Ctx.Columns));
            Box_W : array (1 .. Count) of Pixel_Type;
            Bottom_Edge : Pixel_Type := Top;

            function Src (I : Positive) return Item_Source is (Sources.Element (I));
            function Across (M : Edge_Pixels) return Pixel_Type is (M.Left + M.Right);
            function Down (M : Edge_Pixels) return Pixel_Type is (M.Top + M.Bottom);

            --  A grid item's percentage sizes are of its cell, which the
            --  tracks are still being sized from: none, until it has one.
            function Is_Pct (S : Size_Value) return Boolean is
              (S.Kind = Fixed and then S.Size.Unit = Pct);
            function Before_Cell (S : Size_Value; Declared : Pixel_Type)
              return Pixel_Type is
              (if Is_Pct (S) then Pixel_Type'Last else Declared);
         begin
            Ctx.Column_Gap := Gap_Px (Style.Gap, False, Pct_Base, Style);
            Ctx.Row_Gap    := Gap_Px (Style.Gap, True, Of_H, Style);
            --  Rows fit their content. Columns take their items' content
            --  widths only while the container is being measured; laid out
            --  for real, they share the width and content wraps.
            Ctx.Use_Preferred_Floor_X := Flow.Sizing /= Normal_Sizing;
            Ctx.Use_Preferred_Floor_Y := True;
            for T in 1 .. Ctx.Column_Tracks.Count loop
               if Ctx.Column_Tracks.Tracks (T).Kind = Track_Px then
                  Ctx.Column_Tracks.Tracks (T).Value :=
                    Ctx.Column_Tracks.Tracks (T).Value
                    * Float (Pixel_Type'Max (0.01, Self.Content_Scale));
               end if;
            end loop;

            for I in 1 .. Count loop
               declare
                  It     : Item_Measure renames Items (I);
                  S      : Resolved_Style renames It.Style;
                  Decl_W : constant Pixel_Type := Before_Cell (S.Width, It.Decl_W);
                  Max_W  : constant Pixel_Type :=
                    Before_Cell (S.Max_Width, Declared_Px (S.Max_Width, Pct_Base, S));
                  Min_W  : constant Pixel_Type :=
                    Pixel_Type'Min
                      (Max_W,
                       Automatic_Minimum
                         (Minimum_Declared => S.Min_Width.Kind = Fixed
                                              and then not Is_Pct (S.Min_Width),
                          Declared_Size    => Decl_W,
                          Overflow         => S.Overflow_X,
                          Demand           => Minimum_Px (S.Min_Width, 0.0, S),
                          Content_Min      => It.Min_C));
                  Pref_W : constant Pixel_Type :=
                    Pixel_Type'Max
                      (Min_W,
                       Pixel_Type'Min
                         (Max_W,
                          (if Decl_W /= Pixel_Type'Last then Decl_W
                           elsif Flow.Sizing = Min_Content_Sizing then Min_W
                           elsif Flow.Sizing = Max_Content_Sizing then It.Max_C
                           else Pixel_Type'Min
                                  (It.Max_C,
                                   Pixel_Type'Max (Min_W, Avail - Across (It.Margin))))));
                  --  Measured for its max-content width, a flexible
                  --  column holds its widest content.
                  Floor_W : constant Pixel_Type :=
                    (if Flow.Sizing = Max_Content_Sizing then Pref_W else Min_W);
               begin
                  Kids (I) := Make_Grid_Child_Info
                    (S,
                     Preferred => (Pref_W + Across (It.Margin),
                                   (if It.Decl_H /= Pixel_Type'Last
                                    then It.Decl_H + Down (It.Margin) else 0.0)),
                     Minimum   => (Floor_W + Across (It.Margin),
                                   Minimum_Px (S.Min_Height, Of_H, S) + Down (It.Margin)));
               end;
            end loop;

            Compute_Grid_Layout (Ctx, Kids, Cols);

            --  Measured, each column holds its own content; flexible
            --  columns then grow to one shared fraction, as wide as the
            --  widest of them needs per fr, which is what they get when
            --  the container is laid out at the width reported here.
            if Flow.Sizing /= Normal_Sizing then
               declare
                  Listed   : constant Boolean := Ctx.Column_Tracks.Count = Cols'Length;
                  Fraction : Pixel_Type := 0.0;
                  Wide     : Pixel_Type :=
                    Ctx.Column_Gap * Pixel_Type (Cols'Length - 1);

                  function Fr (C : Positive) return Pixel_Type is
                    (if not Listed then 1.0
                     elsif Ctx.Column_Tracks.Tracks (C).Kind = Track_Fr
                     then Pixel_Type (Ctx.Column_Tracks.Tracks (C).Value)
                     else 0.0);
               begin
                  for C in Cols'Range loop
                     if Fr (C) > 0.0 then
                        Fraction := Pixel_Type'Max (Fraction, Cols (C) / Fr (C));
                     end if;
                  end loop;
                  for C in Cols'Range loop
                     Wide := Wide
                       + (if Fr (C) > 0.0
                          then Pixel_Type'Max (Cols (C), Fraction * Fr (C))
                          else Cols (C));
                  end loop;
                  Flow.Extent :=
                    Pixel_Type'Max (Flow.Extent, Left + Wide + Flow.Right_Inset);
                  Y := Top + Of_H;
                  return;
               end;
            end if;

            --  Rows grow to what each item needs at its column's width.
            for I in 1 .. Count loop
               declare
                  It   : Item_Measure renames Items (I);
                  S    : Resolved_Style renames It.Style;
                  Cell : constant Pixel_Type := Kids (I).Computed_Width;
               begin
                  Box_W (I) := Pixel_Type'Max
                    (Minimum_Px (S.Min_Width, Cell, S),
                     Pixel_Type'Min
                       (Declared_Px (S.Max_Width, Cell, S),
                        (if Declared_Px (S.Width, Cell, S) /= Pixel_Type'Last
                         then Declared_Px (S.Width, Cell, S)
                         else Pixel_Type'Max (0.0, Cell - Across (It.Margin)))));
                  if It.Decl_H = Pixel_Type'Last then
                     Kids (I).Pref_Height :=
                       Height_At (Parent, Src (I), Style, It.Flow_Margin, Pct_Base, Box_W (I))
                       + Down (It.Margin);
                  end if;
               end;
            end loop;
            Compute_Grid_Layout (Ctx, Kids);

            declare
               Cells : constant Rectangle_Array := Grid_To_Rectangles (Kids);
               Boxes : Rectangle_Array (1 .. Count);
            begin
               for I in 1 .. Count loop
                  declare
                     It : Item_Measure renames Items (I);
                     S  : Resolved_Style renames It.Style;
                     M  : Edge_Pixels renames It.Margin;
                  begin
                     Boxes (I) :=
                       (X      => Cells (I).X + M.Left,
                        Y      => Cells (I).Y + M.Top,
                        Width  => Box_W (I),
                        Height =>
                          (if It.Decl_H /= Pixel_Type'Last then It.Decl_H
                           else Pixel_Type'Max
                                  (Minimum_Px (S.Min_Height, Of_H, S),
                                   Pixel_Type'Min
                                     (Declared_Px (S.Max_Height, Of_H, S),
                                      Pixel_Type'Max (0.0, Cells (I).Height - Down (M))))));
                     Bottom_Edge := Pixel_Type'Max
                       (Bottom_Edge, Cells (I).Y + Cells (I).Height);
                  end;
               end loop;

               Place_Items (Parent, Style, Link, Sources, Items, Boxes, Pct_Base);
            end;

            Y := (if Fixed_H /= Pixel_Type'Last then Top + Fixed_H else Bottom_Edge);
         end;

         X := Line_Left;
         Pending_Space := False;
         Prev_Block_Margin_Bottom := 0.0;
      end Layout_Grid_Container;

      --  An inline element's content. Its horizontal margin, border and
      --  padding take room on the line at its start and end; a background
      --  or border draws a box around each line's fragment of it.
      procedure Layout_Inline_Element
        (Parent       : Node;
         Style        : Resolved_Style;
         Outer_Style  : Resolved_Style;
         Link         : String;
         Outer_Link   : String)
      is
         Of_W    : constant Pixel_Type := Current_Line_Width;
         Margin  : constant Edge_Pixels := Resolve_Margin_Edges (Style.Margin, Style, Of_W);
         Border  : constant Edge_Pixels := Border_Edges (Style);
         Padding : constant Edge_Pixels := Resolve_Box_Edges (Style.Padding, Style, Of_W);
         Drawn   : constant Boolean :=
           Style.Background_Color /= Default_Background
           or else Style.Background_Image /= Default_Background_Image
           or else Border /= Zero_Edges;
         Offsets : constant Boolean :=
           Margin.Left /= 0.0 or else Margin.Right /= 0.0
           or else Border.Left > 0.0 or else Border.Right > 0.0
           or else Padding.Left > 0.0 or else Padding.Right > 0.0;
         Boxed   : constant Boolean :=
           Drawn
           or else (Link'Length > 0
                    and then (Border /= Zero_Edges or else Padding /= Zero_Edges));
         Font_Ascent  : constant Pixel_Type := Measure_Ascent
           (Style, Self.Content_Scale, Root_Font_Px, Content.Width, Content.Height);
         Font_Descent : constant Pixel_Type := Measure_Descent
           (Style, Self.Content_Scale, Root_Font_Px, Content.Width, Content.Height);
         --  Its box is off the baseline as its text is.
         Box_Shift    : constant Pixel_Type :=
           Baseline_Shift (Style, Font_Ascent, Font_Descent);
         Box_Ascent   : constant Pixel_Type := Font_Ascent - Box_Shift;
         Box_Descent  : constant Pixel_Type := Font_Descent + Box_Shift;
      begin
         if Drawn or else Offsets then
            --  A space before the element is outside its box.
            if Pending_Space and then Has_Line_Content then
               Add_Text_Run (" ", Outer_Link, Outer_Style);
               Pending_Space := False;
               Flow.Ends_In_Space := True;
            end if;
            X := X + Margin.Left;
         end if;

         if Boxed then
            Flow.Open_Boxes.Append
              (Inline_Box'
                 (Style   => Style,
                  Drawn   => Drawn,
                  Href    => To_Unbounded_String (Link),
                  Node    => Link_Node,
                  Border  => Border,
                  Padding => Padding,
                  Ascent  => Box_Ascent,
                  Descent => Box_Descent,
                  Frag_X  => X,
                  First   => True,
                  Slot    => 0,
                  Lead    => Margin.Left,
                  Edge    => Border.Left + Padding.Left,
                  Shift   => Open_Shift,
                  Align   => Style.Vertical_Align,
                  others  => <>));
            Reserve_Box_Slots;
         end if;
         X := X + Border.Left + Padding.Left;

         for Child_Idx of Parent.Children loop
            if Child_Idx > 0 then
               Layout_Node (Positive (Child_Idx), Style, Link);
            end if;
         end loop;

         --  Its end edges start a fragment of their own on a line its
         --  content has not reached, after a block inside it.
         if Boxed and then Flow.Open_Boxes.Last_Element.Frag_X < 0.0
           and then Padding.Right + Border.Right > 0.0
         then
            Reserve_Box_Slots;
            Note_Run (X);
         end if;
         X := X + Padding.Right + Border.Right;
         if Boxed then
            declare
               B : constant Inline_Box := Flow.Open_Boxes.Last_Element;
            begin
               Flow.Open_Boxes.Delete_Last;
               --  An empty element without edges has nothing to draw: its
               --  item, the last one kept, goes.
               if not B.Has_Content and then B.Frag_X = X then
                  if B.Slot > 0 and then B.Slot = Natural (Result.Items.Last_Index) then
                     Drop_Last_Item;
                  end if;
               elsif B.Frag_X >= 0.0 then
                  Flow.Line_Fragments.Append
                    (Box_Fragment'(Box => B, Slot => B.Slot, X1 => B.Frag_X, X2 => X,
                                   Has_Left => B.First, Has_Right => True));
               end if;
            end;
         end if;
         X := X + Margin.Right;
      end Layout_Inline_Element;

      procedure Layout_Node
        (Node_Index   : Positive;
         Parent_Style : Resolved_Style;
         Active_Link  : String;
         As_Item      : Boolean := False)
      is
         N : constant Node := Self.Nodes.Element (Node_Index);
      begin
         case N.Kind is
            when Text_Node =>
               Process_Text_Node (To_String (N.Text), Active_Link, Parent_Style);

            when Break_Node =>
               Forced_Break;

            when Element_Node =>
               declare
                  Tag : constant String := To_String (N.Tag_Name);
                  Rules : constant Style_Rules := Element_Cascade_Rules (Self, Node_Index);
                  Style : Resolved_Style := Resolve_Element_Style (Rules, Parent_Style, True);
                  Link_Href : constant String :=
                    (if Tag = "a" then To_String (N.Attrs.Href_Attr) else Active_Link);
                  Outer_Link_Node : constant Natural := Link_Node;
                  Rel_Shift : Natural := 0;
               begin
                  if Tag = "a" then
                     Link_Node := Node_Index;
                  end if;
                  Cascade_Font_Size (Style, Parent_Style);
                  --  Keep separator space preceding a link outside the link run
                  --  so underline/click hit regions do not extend into that
                  --  left-side collapsed gap.
                  if Tag = "a" and then Pending_Space and then X > Line_Left then
                     Add_Text_Run (" ", "", Parent_Style);
                     Pending_Space := False;
                  end if;

                  if Style.Display /= Display_None
                    and then Style.Position in Absolute | Fixed
                    and then not As_Item
                  then
                     Enqueue_Absolute
                       (Node_Index, Parent_Style, Active_Link,
                        Block_Level => Is_Block_Element (Tag, Rules, Style),
                        Fixed       => Style.Position = Fixed);
                     Link_Node := Outer_Link_Node;
                     return;
                  end if;

                  --  A relatively positioned element lays out where it
                  --  would, then moves by its offset with all it holds.
                  if Style.Position = Relative then
                     declare
                        Font : constant Pixel_Type := Local_Font_Size_Px (Style);
                        Of_W : constant Pixel_Type := Current_Line_Width;
                        Of_H : constant Pixel_Type := Pixel_Type'Max (0.0, Block_Def_H);
                        function Px (V : Inset_Value; Of_Size : Pixel_Type) return Pixel_Type is
                          (if V.Kind = Fixed
                             and then (V.Length.Unit /= Pct or else Of_Size > 0.0)
                           then Local_Length_To_Px (V.Length, Of_Size, Font)
                           else 0.0);
                     begin
                        Shifts.Append
                          (Shift_Entry'
                             (DX         =>
                                (if Style.Left.Kind = Fixed then Px (Style.Left, Of_W)
                                 else -Px (Style.Right, Of_W)),
                              DY         =>
                                (if Style.Top.Kind = Fixed then Px (Style.Top, Of_H)
                                 else -Px (Style.Bottom, Of_H)),
                              First_Item => Natural (Result.Items.Length) + 1,
                              First_Link => Natural (Result.Links.Length) + 1,
                              Parent     => Open_Shift,
                              others     => <>));
                        Rel_Shift := Natural (Shifts.Last_Index);
                        Open_Shift := Rel_Shift;
                        Rel_DX := Rel_DX + Shifts (Rel_Shift).DX;
                        Rel_DY := Rel_DY + Shifts (Rel_Shift).DY;
                     end;
                  end if;

                  if Style.Display = Display_None then
                     null;

                  elsif Tag = "img" then
                     declare
                        Src : constant String := To_String (N.Attrs.Src_Attr);
                        Alt : constant String := To_String (N.Attrs.Alt_Attr);
                        Img : constant Adi.Image.Image_Handle := Resolve_Image (Self, Src);
                        W   : Pixel_Type := 0.0;
                        H   : Pixel_Type := 0.0;
                       begin
                        if Adi.Image.Is_Valid (Img) then
                           Adi.Image.Get_Size (Img, W, H);
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
                        Img : constant Adi.Image.Image_Handle := Resolve_Inline_SVG (Self, Src);
                        W   : Pixel_Type := 0.0;
                        H   : Pixel_Type := 0.0;
                     begin
                        if Adi.Image.Is_Valid (Img) then
                           Adi.Image.Get_Size (Img, W, H);
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
                        --  A flex or grid item is a block whatever its tag,
                        --  and its margins do not collapse with what is
                        --  inside it.
                        Block_Flow : constant Boolean :=
                          As_Item or else Is_Block_Element (Tag, Rules, Style);
                        Prev_Right_Inset  : constant Pixel_Type := Flow.Right_Inset;
                        Prev_Base_H       : constant Pixel_Type := Line_Base_H;
                        Prev_Base_Ascent  : constant Pixel_Type := Line_Base_Ascent;
                        Prev_Base_Descent : constant Pixel_Type := Line_Base_Descent;
                        Prev_Line_Left    : constant Pixel_Type := Line_Left;
                        Prev_Line_Right   : constant Pixel_Type := Line_Right;
                        Prev_Line_Align   : constant Text_Align_Value := Current_Line_Align;
                        Local_Container_W : constant Pixel_Type :=
                          (if As_Item and then Flow.Item_Base >= 0.0
                           then Flow.Item_Base else Current_Line_Width);
                        Margin_Edges      : Edge_Pixels := Zero_Edges;
                        Padding_Edges     : Edge_Pixels := Zero_Edges;
                        Border_Px         : Edge_Pixels := Zero_Edges;
                        --  Padding and border together: what separates the
                        --  content from the panel's edge.
                        Inset_Edges       : Edge_Pixels := Zero_Edges;
                        List_Context_Pushed : Boolean := False;
                        Marker          : List_Marker_Run := (Kind => No_Marker);
                        Marker_W        : Pixel_Type := 0.0;
                        Marker_H        : Pixel_Type := 0.0;
                        Marker_Gap      : Pixel_Type := 0.0;
                        Marker_Gutter   : Pixel_Type := 0.0;
                        Ordered_Number  : Integer := 0;
                        Block_Item_Index : Natural := 0;
                        Block_Top_Y      : Pixel_Type := 0.0;
                        Block_Left_X     : Pixel_Type := 0.0;
                        Block_Width      : Pixel_Type := 0.0;
                        --  A border-box width that width, min-width or
                        --  max-width decided, and the border-box height
                        --  limits; a flex or grid item's container
                        --  decides those instead.
                        Box_W_Set        : Boolean := False;
                        Box_W            : Pixel_Type := 0.0;
                        Height_Set       : Boolean := False;
                        Decl_Box_H       : Pixel_Type := Pixel_Type'Last;
                        Min_Box_H        : Pixel_Type := 0.0;
                        Max_Box_H        : Pixel_Type := Pixel_Type'Last;
                        Prev_Def_H       : constant Pixel_Type := Block_Def_H;
                        Box_Closed       : Boolean := False;
                        --  Inline boxes open around this block: it splits
                        --  them, and its own lines are not part of them.
                        Outer_Boxes      : Inline_Box_Vectors.Vector;
                        --  This block's entry in Containing when it is
                        --  positioned; 0 otherwise.
                        Containing_Index : Natural := 0;
                        --  This block's entry in Clips when it clips; 0
                        --  otherwise.
                        Clip_Index : Natural := 0;
                       begin
                        if Block_Flow then
                           if Has_Line_Content or else Pending_Space then
                              New_Line;
                           end if;

                           --  vertical-align is not inherited in CSS: a
                           --  block's content starts on the baseline.
                           Style.Vertical_Align := VA_Baseline;

                           Outer_Boxes := Flow.Open_Boxes;
                           Flow.Open_Boxes.Clear;
                           --  Boxes still empty here have kept items, the
                           --  last ones, that nothing will fill.
                           for K in reverse 1 .. Natural (Outer_Boxes.Length) loop
                              if Outer_Boxes (K).Slot > 0
                                and then Outer_Boxes (K).Slot = Natural (Result.Items.Last_Index)
                              then
                                 Drop_Last_Item;
                              end if;
                           end loop;
                           for B of Outer_Boxes loop
                              if B.Frag_X >= 0.0 then
                                 B.First := False;
                              end if;
                              B.Frag_X := -1.0;
                              B.Slot := 0;
                           end loop;

                           if Tag = "ul" or else Tag = "ol" then
                              declare
                                 Start : Integer := 1;
                              begin
                                 if Tag = "ol"
                                   and then not Parse_Integer
                                                  (To_String (N.Attrs.Start_Attr), Start)
                                 then
                                    Start := 1;
                                 end if;
                                 List_Stack.Append
                                   (New_Item =>
                                      List_Context'
                                        (Node_Index  => Node_Index,
                                         Ordered     => Tag = "ol",
                                         Next_Number => Start));
                              end;
                              List_Context_Pushed := True;
                           end if;

                           Margin_Edges := Resolve_Margin_Edges (Style.Margin, Style, Local_Container_W);
                           Padding_Edges := Resolve_Box_Edges (Style.Padding, Style, Local_Container_W);
                           Border_Px := Border_Edges (Style);
                           Inset_Edges :=
                             (Top    => Padding_Edges.Top + Border_Px.Top,
                              Right  => Padding_Edges.Right + Border_Px.Right,
                              Bottom => Padding_Edges.Bottom + Border_Px.Bottom,
                              Left   => Padding_Edges.Left + Border_Px.Left);

                           declare
                              Of_H     : constant Pixel_Type := Pixel_Type'Max (0.0, Block_Def_H);
                              Insets_H : constant Pixel_Type := Inset_Edges.Top + Inset_Edges.Bottom;
                           begin
                              Decl_Box_H := Declared_Px (Style.Height, Of_H, Style);
                              Max_Box_H := Declared_Px (Style.Max_Height, Of_H, Style);
                              Min_Box_H := Declared_Px (Style.Min_Height, Of_H, Style);
                              if Min_Box_H = Pixel_Type'Last then
                                 Min_Box_H := 0.0;
                              end if;
                              Block_Def_H :=
                                (if Decl_Box_H = Pixel_Type'Last then -1.0
                                 else Pixel_Type'Max
                                        (0.0,
                                         Pixel_Type'Max
                                           (Min_Box_H, Pixel_Type'Min (Decl_Box_H, Max_Box_H))
                                         - Insets_H));

                              if not As_Item then
                                 Height_Set :=
                                   Decl_Box_H /= Pixel_Type'Last
                                   or else Max_Box_H /= Pixel_Type'Last
                                   or else Min_Box_H > 0.0;
                                 Size_Block_Width
                                   (Style, Pixel_Type'Max (0.0, Prev_Line_Right - Prev_Line_Left),
                                    Local_Container_W, Inset_Edges.Left + Inset_Edges.Right,
                                    Margin_Edges, Box_W_Set, Box_W);
                              end if;
                           end;

                           --  Vertical margin collapsing. Defer the commit
                           --  when there is no top padding/border so the
                           --  parent's top margin can collapse-through with
                           --  its first child's top margin (CSS spec).
                           declare
                              Has_Top_Sep : constant Boolean :=
                                As_Item or else Inset_Edges.Top > 0.0;
                              Combined : constant Pixel_Type :=
                                Pixel_Type'Max
                                  (Margin_Edges.Top, Prev_Block_Margin_Bottom);
                           begin
                              Prev_Block_Margin_Bottom := Combined;
                              Block_Top_Y := Y + Combined;
                              Block_Left_X := Prev_Line_Left + Margin_Edges.Left;
                              Block_Width :=
                                (if Box_W_Set then Box_W
                                 else Pixel_Type'Max
                                        (0.0,
                                         (Prev_Line_Right - Prev_Line_Left)
                                         - Margin_Edges.Left - Margin_Edges.Right));

                              declare
                                 It : Item :=
                                   Make_Panel
                                     (Any_Part,
                                      (X      => Block_Left_X,
                                       Y      => Block_Top_Y,
                                       Width  => Block_Width,
                                       Height => 0.0),
                                      0);
                                 Box_Style : Resolved_Style := Panel_Style (Style, Border_Px);
                              begin
                                 --  body's background is the canvas's.
                                 if Node_Index = 1 then
                                    Box_Style.Background_Color := Default_Background;
                                    Box_Style.Background_Image := Default_Background_Image;
                                 end if;
                                 It.Has_Style_Override := True;
                                 It.Style_Override := Intern (Box_Style);
                                 Result.Items.Append (It);
                                 Block_Item_Index := Natural (Result.Items.Last_Index);
                                 if Style.Overflow_X /= Overflow_Visible
                                   or else Style.Overflow_Y /= Overflow_Visible
                                 then
                                    Clips.Append
                                      (Clip_Entry'
                                         (Panel      => Block_Item_Index,
                                          Border     => Border_Px,
                                          Clip_X     => Style.Overflow_X /= Overflow_Visible,
                                          Clip_Y     => Style.Overflow_Y /= Overflow_Visible,
                                          First_Item => Block_Item_Index + 1,
                                          First_Link => Natural (Result.Links.Length) + 1,
                                          Parent     => Open_Clip,
                                          others     => <>));
                                    Clip_Index := Natural (Clips.Last_Index);
                                    Open_Clip := Clip_Index;
                                 end if;
                                 if Style.Position /= Static then
                                    Containing.Append
                                      (Containing_Block'
                                         (Panel  => Block_Item_Index,
                                          Border => Border_Px,
                                          DX     => Rel_DX,
                                          DY     => Rel_DY,
                                          Clip   => Open_Clip));
                                    Containing_Index := Natural (Containing.Last_Index);
                                    Open_Containing.Append (Containing_Index);
                                 end if;
                              end;

                              if Has_Top_Sep then
                                 Flush_Pending_Margin;
                                 Y := Block_Top_Y + Inset_Edges.Top;
                              else
                                 Pending_Tops.Append (Positive (Block_Item_Index));
                                 --  Y stays put; first content commits via
                                 --  Flush_Pending_Margin and the panel's Y
                                 --  is rewritten to the committed Y at that
                                 --  point.
                              end if;
                           end;

                           Line_Left := Prev_Line_Left + Margin_Edges.Left + Inset_Edges.Left;
                           Line_Right :=
                             (if Box_W_Set then Block_Left_X + Box_W - Inset_Edges.Right
                              else Prev_Line_Right - Margin_Edges.Right - Inset_Edges.Right);
                           Flow.Right_Inset :=
                             Prev_Right_Inset + Margin_Edges.Right + Inset_Edges.Right;
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
                                    Flow.Pending_Markers.Append
                                      (Pending_Marker'
                                         (Marker => Marker,
                                          Width  => Marker_W,
                                          Height => Marker_H,
                                          Gap    => Marker_Gap,
                                          Left   => Line_Left,
                                          Style  => Style));
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

                        if Block_Flow and then Style.Display in Flex | Inline_Flex then
                           Layout_Flex_Container (N, Style, Link_Href);
                        elsif Block_Flow and then Style.Display in Grid | Inline_Grid then
                           Layout_Grid_Container (N, Style, Link_Href);
                        elsif Block_Flow then
                           for Child_Idx of N.Children loop
                              if Child_Idx > 0 then
                                 Layout_Node (Positive (Child_Idx), Style, Link_Href);
                              end if;
                           end loop;
                        else
                           Layout_Inline_Element (N, Style, Parent_Style, Link_Href, Active_Link);
                        end if;

                        if Block_Flow then
                           --  An item with no content of its own still
                           --  shows its marker.
                           if Tag = "li" and then not Flow.Pending_Markers.Is_Empty then
                              Place_Pending_Markers;
                           end if;

                           if Has_Line_Content or else Pending_Space then
                              New_Line;
                           end if;

                           if List_Context_Pushed
                             and then Natural (List_Stack.Length) > 0
                           then
                              List_Stack.Delete_Last;
                           end if;

                           --  A declared height or a height limit closes the
                           --  box: what is inside stays inside, and the box
                           --  is as tall as the limits make it.
                           --  A declared height or min-height closes the box:
                           --  what is inside stays inside. max-height alone
                           --  closes it only when it cuts the content short.
                           if Height_Set then
                              declare
                                 Top : constant Pixel_Type :=
                                   Result.Items.Reference (Positive (Block_Item_Index)).Geometry.Y;
                                 Auto_H : constant Pixel_Type :=
                                   Pixel_Type'Max (Y, Top + Inset_Edges.Top) - Top
                                   + Inset_Edges.Bottom;
                                 H : Pixel_Type :=
                                   (if Decl_Box_H /= Pixel_Type'Last then Decl_Box_H else Auto_H);
                              begin
                                 H := Pixel_Type'Min (H, Max_Box_H);
                                 H := Pixel_Type'Max (H, Min_Box_H);
                                 H := Pixel_Type'Max (H, Inset_Edges.Top + Inset_Edges.Bottom);
                                 Box_Closed :=
                                   Decl_Box_H /= Pixel_Type'Last or else Min_Box_H > 0.0
                                   or else H /= Auto_H;
                                 if Box_Closed then
                                    Flush_Pending_Margin;
                                    declare
                                       Final_Top : constant Pixel_Type :=
                                         Result.Items.Reference
                                           (Positive (Block_Item_Index)).Geometry.Y;
                                    begin
                                       Y := Final_Top + H - Inset_Edges.Bottom;
                                    end;
                                 end if;
                              end;
                           end if;

                           declare
                              Has_Bot_Sep : constant Boolean :=
                                As_Item or else Box_Closed or else Inset_Edges.Bottom > 0.0;
                           begin
                              if Has_Bot_Sep then
                                 --  Bottom padding/border anchors the box;
                                 --  flush any descendant pending margin
                                 --  and then add our padding.
                                 Flush_Pending_Margin;
                                 Y := Y + Inset_Edges.Bottom;
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
                                   Result.Items.Reference
                                     (Positive (Block_Item_Index)).Geometry.Y;
                                 Block_Bottom_Y : constant Pixel_Type := Y;
                              begin
                                 Result.Items.Reference (Positive (Block_Item_Index)).Geometry :=
                                   (X      => Block_Left_X,
                                    Y      => Final_Top,
                                    Width  => Block_Width,
                                    Height => Pixel_Type'Max (0.0, Block_Bottom_Y - Final_Top));
                              end;
                           end if;

                           if Containing_Index > 0 then
                              Open_Containing.Delete_Last;
                           end if;
                           if Clip_Index > 0 then
                              Clips.Reference (Clip_Index).Last_Item := Natural (Result.Items.Length);
                              Clips.Reference (Clip_Index).Last_Link := Natural (Result.Links.Length);
                              Open_Clip := Clips (Clip_Index).Parent;
                           end if;

                           --  An empty block still spans its own insets, and
                           --  a sized one its width.
                           Flow.Extent :=
                             Pixel_Type'Max (Flow.Extent, Line_Left + Flow.Right_Inset);
                           if Box_W_Set then
                              Flow.Extent :=
                                Pixel_Type'Max
                                  (Flow.Extent,
                                   Block_Left_X + Box_W + Margin_Edges.Right + Prev_Right_Inset);
                           end if;
                           Flow.Right_Inset := Prev_Right_Inset;
                           Block_Def_H := Prev_Def_H;
                           Flow.Open_Boxes := Outer_Boxes;

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
                  if Rel_Shift > 0 then
                     declare
                        E : Shift_Entry renames Shifts.Reference (Rel_Shift);
                     begin
                        E.Last_Item := Natural (Result.Items.Length);
                        E.Last_Link := Natural (Result.Links.Length);
                        E.Closed := True;
                        Open_Shift := E.Parent;
                        Rel_DX := Rel_DX - E.DX;
                        Rel_DY := Rel_DY - E.DY;
                     end;
                  end if;
                  Link_Node := Outer_Link_Node;
               end;
         end case;
      end Layout_Node;

      --  Lays out each absolutely positioned element against its
      --  containing block: by its insets where it has them, else where the
      --  flow would have put it; as wide as its width, its two horizontal
      --  insets or its content allow. Those it positions in turn join the
      --  queue.
      procedure Lay_Out_Absolutes is
         use type Ada.Containers.Count_Type;
         I : Positive := 1;
      begin
         while I <= Natural (Absolutes.Length) loop
            declare
               E     : constant Absolute_Entry := Absolutes (I);
               function Padding_Box (C : Containing_Block) return Rectangle is
                  G : constant Rectangle := Result.Items (C.Panel).Geometry;
               begin
                  return
                    (X      => G.X + C.Border.Left + C.DX,
                     Y      => G.Y + C.Border.Top + C.DY,
                     Width  => Pixel_Type'Max (0.0, G.Width - C.Border.Left - C.Border.Right),
                     Height => Pixel_Type'Max (0.0, G.Height - C.Border.Top - C.Border.Bottom));
               end Padding_Box;

               --  Its padding box, where it will end up.
               CB    : constant Rectangle :=
                 (if E.Block = 0 then (0.0, 0.0, Content.Width, Content.Height)
                  else Padding_Box (Containing (E.Block)));
               Style : constant Resolved_Style := Element_Style (E.Element, E.Parent_Style);
               Font  : constant Pixel_Type := Local_Font_Size_Px (Style);
               N     : constant Node := Self.Nodes (E.Element);
               Src   : constant Item_Source := (Element => E.Element, First => 1, Last => 1);
               M     : constant Edge_Pixels :=
                 Resolve_Margin_Edges (Style.Margin, Style, CB.Width);

               function Px (V : Inset_Value; Of_Size : Pixel_Type) return Pixel_Type is
                 (if V.Kind = Fixed
                    and then (V.Length.Unit /= Pct or else Of_Size > 0.0)
                  then Local_Length_To_Px (V.Length, Of_Size, Font)
                  else Pixel_Type'Last);

               None : constant Pixel_Type := Pixel_Type'Last;
               L : constant Pixel_Type := Px (Style.Left, CB.Width);
               R : constant Pixel_Type := Px (Style.Right, CB.Width);
               T : constant Pixel_Type := Px (Style.Top, CB.Height);
               B : constant Pixel_Type := Px (Style.Bottom, CB.Height);

               function Clamped
                 (V : Pixel_Type; Min_S, Max_S : Size_Value; Of_Size : Pixel_Type)
                  return Pixel_Type
               is
                  Lo : constant Pixel_Type := Declared_Px (Min_S, Of_Size, Style);
               begin
                  return Pixel_Type'Max
                    ((if Lo = None then 0.0 else Lo),
                     Pixel_Type'Min (V, Declared_Px (Max_S, Of_Size, Style)));
               end Clamped;

               W, H, Box_X, Box_Y : Pixel_Type;
               Bottom, Extent     : Pixel_Type;
               Mark : constant Ada.Containers.Count_Type := Result.Items.Length;
            begin
               W := Declared_Px (Style.Width, CB.Width, Style);
               if W = None then
                  if L /= None and then R /= None then
                     W := Pixel_Type'Max (0.0, CB.Width - L - R - M.Left - M.Right);
                  else
                     declare
                        Min_C, Max_C : Pixel_Type;
                        Room : constant Pixel_Type := Pixel_Type'Max
                          (0.0, CB.Width - (if L = None then 0.0 else L)
                                - (if R = None then 0.0 else R) - M.Left - M.Right);
                     begin
                        Content_Widths (N, Src, E.Parent_Style, M, CB.Width, Min_C, Max_C);
                        W := Pixel_Type'Min (Max_C, Pixel_Type'Max (Min_C, Room));
                     end;
                  end if;
               end if;
               W := Clamped (W, Style.Min_Width, Style.Max_Width, CB.Width);

               H := Declared_Px (Style.Height, CB.Height, Style);
               if H = None and then T /= None and then B /= None then
                  H := Pixel_Type'Max (0.0, CB.Height - T - B - M.Top - M.Bottom);
               end if;
               if H /= None then
                  H := Clamped (H, Style.Min_Height, Style.Max_Height, CB.Height);
               end if;

               Box_X :=
                 (if L /= None then CB.X + L + M.Left
                  elsif R /= None then CB.X + CB.Width - R - M.Right - W
                  else E.Static_X + M.Left);
               Box_Y :=
                 (if T /= None then CB.Y + T + M.Top
                  elsif B /= None then
                    CB.Y + CB.Height - B - M.Bottom
                    - (if H /= None then H
                       else Height_At (N, Src, E.Parent_Style, M, CB.Width, W))
                  else E.Static_Y + M.Top);

               declare
                  --  The clips at or around its containing block clip it,
                  --  and whatever it positions in turn.
                  Outer_Clip : constant Natural :=
                    (if E.Block = 0 then 0 else Containing (E.Block).Clip);
                  Link_Mark  : constant Natural := Natural (Result.Links.Length);
                  C          : Natural := Outer_Clip;
               begin
                  Link_Node := E.Link_Node;
                  Open_Clip := Outer_Clip;
                  Lay_Out_Item
                    (N, Src, E.Parent_Style, To_String (E.Link), (Box_X, Box_Y, W, 0.0), M,
                     CB.Width, Normal_Sizing, Bottom, Extent);
                  Link_Node := 0;
                  Open_Clip := 0;
                  while C /= 0 loop
                     declare
                        Around : constant Clip_Entry := Clips (C);
                     begin
                        Clips.Append
                          (Clip_Entry'
                             (Panel      => Around.Panel,
                              Border     => Around.Border,
                              Clip_X     => Around.Clip_X,
                              Clip_Y     => Around.Clip_Y,
                              First_Item => Natural (Mark) + 1,
                              Last_Item  => Natural (Result.Items.Length),
                              First_Link => Link_Mark + 1,
                              Last_Link  => Natural (Result.Links.Length),
                              Parent     => 0));
                        C := Around.Parent;
                     end;
                  end loop;
               end;

               --  Its own panel is the first thing it added.
               if H /= None and then Result.Items.Length > Mark then
                  Result.Items.Reference (Positive (Mark) + 1).Geometry.Height := H;
               end if;
            end;
            I := I + 1;
         end loop;
      end Lay_Out_Absolutes;

      --  Each clipping block's padding box, where it ended up, clips the
      --  items inside it on the axes it clips, and the links too, so
      --  what is hidden takes no clicks.
      procedure Apply_Clips is
         function Meet (A, B : Rectangle) return Rectangle is
            X1 : constant Pixel_Type := Pixel_Type'Max (A.X, B.X);
            Y1 : constant Pixel_Type := Pixel_Type'Max (A.Y, B.Y);
            X2 : constant Pixel_Type := Pixel_Type'Min (A.X + A.Width, B.X + B.Width);
            Y2 : constant Pixel_Type := Pixel_Type'Min (A.Y + A.Height, B.Y + B.Height);
         begin
            return (X1, Y1, Pixel_Type'Max (0.0, X2 - X1), Pixel_Type'Max (0.0, Y2 - Y1));
         end Meet;

         Far : constant Pixel_Type := 1.0E7;
      begin
         for C of Clips loop
            declare
               G   : constant Rectangle := Result.Items (C.Panel).Geometry;
               Box : constant Rectangle :=
                 (X      => (if C.Clip_X then G.X + C.Border.Left else -Far),
                  Y      => (if C.Clip_Y then G.Y + C.Border.Top else -Far),
                  Width  =>
                    (if C.Clip_X
                     then Pixel_Type'Max (0.0, G.Width - C.Border.Left - C.Border.Right)
                     else 2.0 * Far),
                  Height =>
                    (if C.Clip_Y
                     then Pixel_Type'Max (0.0, G.Height - C.Border.Top - C.Border.Bottom)
                     else 2.0 * Far));
            begin
               for K in C.First_Item .. Natural'Min (C.Last_Item, Natural (Result.Items.Length)) loop
                  declare
                     It : Item renames Result.Items.Reference (K);
                  begin
                     It.Clip := (if It.Has_Clip then Meet (It.Clip, Box) else Box);
                     It.Has_Clip := True;
                  end;
               end loop;
               for K in C.First_Link .. Natural'Min (C.Last_Link, Natural (Result.Links.Length)) loop
                  Result.Links.Reference (K).Geometry :=
                    Meet (Result.Links (K).Geometry, Box);
               end loop;
            end;
         end loop;
      end Apply_Clips;

      procedure Apply_Shifts is
      begin
         for S of Shifts loop
            for K in S.First_Item .. Natural'Min (S.Last_Item, Natural (Result.Items.Length)) loop
               Result.Items.Reference (K).Geometry.X := Result.Items (K).Geometry.X + S.DX;
               Result.Items.Reference (K).Geometry.Y := Result.Items (K).Geometry.Y + S.DY;
            end loop;
            for K in S.First_Link .. Natural'Min (S.Last_Link, Natural (Result.Links.Length)) loop
               Result.Links.Reference (K).Geometry.X := Result.Links (K).Geometry.X + S.DX;
               Result.Links.Reference (K).Geometry.Y := Result.Links (K).Geometry.Y + S.DY;
            end loop;
         end loop;
      end Apply_Shifts;
   begin
      Result.Items.Clear;
      Result.Links.Clear;
      --  A placeholder so every index below lines up; emission gives it
      --  the widget's own box, which is not part of the document.
      Result.Items.Append
        (Make_Panel (Main_Part, (0.0, 0.0, 0.0, 0.0), 0));


      if not Has_Visible_Area (Content) then
         return;
      end if;

      if not Self.Nodes.Is_Empty then
         Document_Rules := Element_Cascade_Rules (Self, 1);
      end if;

      Document_Style := Resolve_Element_Style (Document_Rules, Text_Part_Style, True);
      Cascade_Font_Size (Document_Style, Text_Part_Style);

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
         --  body's background paints the whole canvas, behind everything.
         if Document_Style.Background_Color /= Default_Background
           or else Document_Style.Background_Image /= Default_Background_Image
         then
            declare
               Canvas : Resolved_Style;
               It     : Item := Make_Panel (Any_Part, (0.0, 0.0, 0.0, 0.0), 0);
            begin
               Canvas.Background_Color := Document_Style.Background_Color;
               Canvas.Background_Image := Document_Style.Background_Image;
               It.Has_Style_Override := True;
               It.Style_Override := Intern (Canvas);
               Result.Items.Append (It);
               Canvas_Index := Natural (Result.Items.Last_Index);
            end;
         end if;

         if Self.Nodes (1).Kind = Element_Node then
            Layout_Node (1, Text_Part_Style, "");
         end if;
      end if;

      Flush_Pending_Margin;
      Finalize_Line;

      --  The flow's own items: absolutes scroll, but do not size the
      --  document for a container that measures it.
      Flow_Items := Natural (Result.Items.Length);
      Lay_Out_Absolutes;
      Apply_Shifts;
      Apply_Clips;

      declare
         Content_End_Y : Pixel_Type :=
           (if Has_Line_Content then Y + Current_Line_H else Y);
         Flow_End_Y    : Pixel_Type := Content_End_Y;
      begin
         for I in 2 .. Natural (Result.Items.Length) loop
            declare
               It : constant Item := Result.Items.Element (I);
               Bottom : constant Pixel_Type := It.Geometry.Y + It.Geometry.Height;
            begin
               if Bottom > Content_End_Y then
                  Content_End_Y := Bottom;
               end if;
               if I <= Flow_Items and then Bottom > Flow_End_Y then
                  Flow_End_Y := Bottom;
               end if;
            end;
         end loop;

         Result.Scroll_H :=
           Pixel_Type'Max (Content.Height, Content_End_Y);
         if Canvas_Index > 0 then
            Result.Items.Reference (Canvas_Index).Geometry :=
              (0.0, 0.0, Content.Width, Result.Scroll_H);
         end if;

         --  Track the document's intrinsic size so Measure_Content can
         --  return it.  Cached_Content_H is the real (un-clamped) bottom
         --  of the last block — what the parent flex should size to,
         --  not the max(viewport, content) value that Scroll_Content_H
         --  holds for scrollbar math.
         Result.Content_W := Content.Width;
         Result.Content_H := Pixel_Type'Max (0.0, Flow_End_Y);
      end;

      Result.Viewport_H := Content.Height;
      --  Reached only when the widget had somewhere to lay out. An early
      --  return leaves the previous metrics standing, as before.
      Result.Sized := True;
   end Layout_Document;
   procedure Emit_Items (Self : in out Html_View; L : Document_Layout) is
      Main_Style : Resolved_Style renames
        Ref (Get_Resolved_Part_Handle (Self, Main_Part)).all;
      Content : constant Rectangle := Content_Box (Self.Geometry, Main_Style);
      Origin_X : constant Pixel_Type := Content.X;
      Origin_Y : constant Pixel_Type := Content.Y - Get_Scroll_Offset_Y (Self);

      function Placed (R : Rectangle) return Rectangle is
        ((X => R.X + Origin_X, Y => R.Y + Origin_Y,
          Width => R.Width, Height => R.Height));

      --  A link scrolled out of the viewport must not answer a click
      --  inside it, so the clip is applied where the viewport is known.
      function Clipped (R : Rectangle) return Rectangle is
         X1 : constant Pixel_Type := Pixel_Type'Max (R.X, Content.X);
         Y1 : constant Pixel_Type := Pixel_Type'Max (R.Y, Content.Y);
         X2 : constant Pixel_Type :=
           Pixel_Type'Min (R.X + R.Width, Content.X + Content.Width);
         Y2 : constant Pixel_Type :=
           Pixel_Type'Min (R.Y + R.Height, Content.Y + Content.Height);
      begin
         return (X => X1, Y => Y1,
                 Width  => Pixel_Type'Max (0.0, X2 - X1),
                 Height => Pixel_Type'Max (0.0, Y2 - Y1));
      end Clipped;

      --  A band above and below the viewport. It covers what paints
      --  outside a rectangle in ways this cannot measure -- an
      --  antialiased fringe, a glyph that overhangs its line box -- and
      --  keeps the emitted set from churning at the exact boundary
      --  while a scroll is under way.
      Overscan : constant Pixel_Type :=
        Pixel_Type'Max (64.0, Content.Height / 2.0);

      Band : constant Rectangle :=
        (X      => Content.X,
         Y      => Content.Y - Overscan,
         Width  => Content.Width,
         Height => Content.Height + 2.0 * Overscan);

      --  What an item can actually paint over. The same helper the
      --  renderer's expansion is derived from, so an item is never
      --  dropped while its shadow still reaches the viewport.
      function Paint_Bounds (It : Item; R : Rectangle) return Rectangle is
        (if It.Has_Style_Override
         then Item_Paint_Bounds (Ref (It.Style_Override).all, R)
         else Item_Paint_Bounds
                (Ref (Get_Resolved_Part_Handle (Self, It.Part)).all, R));

      function Overlaps_Band (R : Rectangle) return Boolean is
        (R.Y + R.Height >= Band.Y and then R.Y <= Band.Y + Band.Height);

      First : Boolean := True;
   begin
      Clear_Items (Self);
      for It of L.Items loop
         declare
            Placed_Item : Item := It;
         begin
            --  The main panel is the widget's own box, not part of the
            --  document that scrolls inside it, and it is always drawn.
            if First then
               Placed_Item.Geometry := Self.Geometry;
               First := False;
               Add_Item (Self, Placed_Item);
            else
               Placed_Item.Geometry := Placed (It.Geometry);
               if It.Has_Clip then
                  Placed_Item.Clip := Placed (It.Clip);
               end if;
               --  Only what the viewport can show is emitted. The
               --  document's size and scroll extent come from the whole
               --  layout, so what is left out costs nothing but the
               --  copy. Order and z-order survive because this walks
               --  the layout in order and only skips.
               if Overlaps_Band (Paint_Bounds (It, Placed_Item.Geometry)) then
                  Add_Item (Self, Placed_Item);
               end if;
            end if;
         end;
      end loop;

      --  Hit testing cannot reach outside the viewport either, so the
      --  same band decides which links are worth keeping.
      Self.Links.Clear;
      for Frag of L.Links loop
         declare
            Placed_Frag : constant Rectangle := Placed (Frag.Geometry);
         begin
            if Overlaps_Band (Placed_Frag) then
               Self.Links.Append
                 (Link_Fragment'(Geometry => Clipped (Placed_Frag),
                                 Href     => Frag.Href,
                                 Node     => Frag.Node));
            end if;
         end;
      end loop;

      if L.Sized then
         Self.Scroll_Content_H  := L.Scroll_H;
         Self.Cached_Content_W  := L.Content_W;
         Self.Cached_Content_H  := L.Content_H;
         Self.Scroll_Viewport_H := L.Viewport_H;
         Update_Scrollbar_Geometry (Self);
      end if;
   end Emit_Items;

   function Current_Key (Self : Html_View) return Cache_Key is
      Main_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (Self, Main_Part);
      Content : constant Rectangle := Content_Box (Self.Geometry, Main_Style);
   begin
      return
        (Valid      => True,
         Doc_Gen    => Self.Doc_Generation,
         Font_Gen   => Adi.Font.Environment_Generation,
         Store_Gen  => Adi.Resolved_Styles.Generation,
         Content_W  => Content.Width,
         Content_H  => Content.Height,
         DIP_Scale  => Get_Active_DIP_Scale,
         UI_Scale   => Get_Active_UI_Scale,
         Text_Scale => Get_Active_Text_Scale,
         HTML_Scale => Self.Content_Scale,
         Px_To_Dip  => Get_Px_Maps_To_Dip,
         Root_Font  => Self.Root_Font_Size,
         Main_Style => Main_Style,
         Text_Style => Get_Resolved_Part_Style (Self, Text_Part),
         --  A pointer that has left the view hovers nothing in it.
         Hover_Node  =>
           (if Self.Dynamic_Rules and then Get_States (Self) (State_Hovered)
            then Self.Hovered_Node else 0),
         Active_Node => (if Self.Dynamic_Rules then Self.Active_Node else 0));
   end Current_Key;

   --  The buffer must never have been rendered: rendering fills the
   --  TTF and font caches on the items it draws, and those belong to
   --  the copies in Self.Items, not to a layout that outlives them.
   function Unrendered (L : Document_Layout) return Boolean is
      use type Adi.SDL.TTF.TextEngine.TTF_Text_Access;
   begin
      return (for all It of L.Items =>
                It.Cached_TTF_Text = null and then It.Cached_Font = null);
   end Unrendered;

   procedure Layout_And_Build (Self : in out Html_View) is
      Key : constant Cache_Key := Current_Key (Self);
   begin
      if not Self.Layout_Key.Valid or else Self.Layout_Key /= Key then
         Self.Layout_Passes := Self.Layout_Passes + 1;
         Layout_Document (Self, Self.Layout_Cache);
         Self.Layout_Key := Key;
         pragma Assert (Unrendered (Self.Layout_Cache),
                        "a rendered layout must not be cached");
      end if;

      pragma Assert (Unrendered (Self.Layout_Cache),
                     "the cached layout must still be unrendered");
      Emit_Items (Self, Self.Layout_Cache);
   end Layout_And_Build;


   function Create return Html_View_Access is
      Result : constant Html_View_Access := new Html_View;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      --  No styles of its own: a fresh view brings neither appearance
      --  nor layout behaviour. Scrolling is opt-in, like any other
      --  widget -- declare overflow-y: auto to make it a viewport, or
      --  leave it visible to size the widget to its document.
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
      Drop_Image_Cache (Self);
      Self.Inline_Style_Cache.Clear;
      Set_Scroll_Offset_Y (Self, 0.0);
      Parse_HTML (Self, Source);
      --  Invalidate measure cache so next layout pass re-measures the
      --  document — the new source may be a different height.
      Self.Cached_Content_W := 0.0;
      Self.Cached_Content_H := 0.0;
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
      Drop_Image_Cache (Self);
      Self.Inline_Style_Cache.Clear;
      Load_Combined_CSS (Self, "");

      --  Everything derived from the document goes with it: the cached
      --  measurements would otherwise report the old size until another
      --  layout ran, and the offset would scroll an empty view.
      Self.Cached_Content_W := 0.0;
      Self.Cached_Content_H := 0.0;
      Set_Scroll_Offset_Y (Self, 0.0);

      --  Styling belongs to whoever applied it, and stays.
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
      Drop_Image_Cache (Self);
      Self.Doc_Generation := Self.Doc_Generation + 1;
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
      Main_Style : Resolved_Style renames
        Ref (Get_Resolved_Part_Handle (Self, Main_Part)).all;
      --  Before Layout_And_Build has run this reports a stub, so the parent
      --  flex has something to assign; afterwards the document size.
      --  Scroll_Content_H is independent of the slot.
      W : constant Pixel_Type :=
        (if Self.Cached_Content_W > 0.0 then Self.Cached_Content_W
         else 320.0);
      H : constant Pixel_Type :=
        (if Self.Cached_Content_H > 0.0 then Self.Cached_Content_H
         else 120.0);
   begin
      return Outer_Size ((W, H), Main_Style);
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

      Self.Active_Node := Link_Node_At (Self, X, Y);
      if Self.Dynamic_Rules and then Self.Active_Node /= 0 then
         Mark_Dirty (Self);
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

      declare
         Node : constant Natural := Link_Node_At (Self, X, Y);
      begin
         if Node /= Self.Hovered_Node then
            Self.Hovered_Node := Node;
            Mark_Dirty (Self);
         end if;
      end;
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
      if Self.Active_Node /= 0 then
         Self.Active_Node := 0;
         Mark_Dirty (Self);
      end if;
   end On_Mouse_Up;

end Adi.Widget.Html_View;
