with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;
with Adi.Log;
with Adi.SVG.Parser;

package body Adi.SVG_Sprites is

   type Symbol_Entry is record
      Id       : Unbounded_String;
      View_Box : Unbounded_String;  --  e.g. "0 0 320 512"
      Content  : Unbounded_String;  --  inner XML between <symbol> and </symbol>
      Next     : Symbol_Entry_Access := null;
   end record;

   procedure Free_Entry is
     new Ada.Unchecked_Deallocation (Symbol_Entry, Symbol_Entry_Access);
   procedure Free_Buckets is
     new Ada.Unchecked_Deallocation (Bucket_Array, Bucket_Array_Access);

   Num_Buckets : constant := 256;

   function Hash (S : String) return Natural is
      H : Natural := 5381;
   begin
      for C of S loop
         H := H * 33 + Character'Pos (C);
         H := H mod 2 ** 24;
      end loop;
      return H mod Num_Buckets;
   end Hash;

   function Lookup
     (Sheet : Sprite_Sheet;
      Id    : String) return Symbol_Entry_Access
   is
      E : Symbol_Entry_Access;
   begin
      if Sheet.Buckets = null then
         return null;
      end if;
      E := Sheet.Buckets (Hash (Id));
      while E /= null loop
         if To_String (E.Id) = Id then
            return E;
         end if;
         E := E.Next;
      end loop;
      return null;
   end Lookup;

   procedure Insert
     (Sheet : in out Sprite_Sheet;
      Id    : String;
      VB    : String;
      Content : String)
   is
      Idx : constant Natural := Hash (Id);
      E   : Symbol_Entry_Access;
   begin
      if Sheet.Buckets = null then
         Sheet.Buckets := new Bucket_Array'(0 .. Num_Buckets - 1 => null);
      end if;

      E := new Symbol_Entry'
        (Id       => To_Unbounded_String (Id),
         View_Box => To_Unbounded_String (VB),
         Content  => To_Unbounded_String (Content),
         Next     => Sheet.Buckets (Idx));
      Sheet.Buckets (Idx) := E;
      Sheet.Count := Sheet.Count + 1;
   end Insert;

   ---------------------------------------------------------------------------
   --  File reading (same pattern as Adi.CSS_Source)
   ---------------------------------------------------------------------------

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

   ---------------------------------------------------------------------------
   --  Parse viewBox to extract width and height (3rd and 4th numbers)
   ---------------------------------------------------------------------------

   procedure Parse_View_Box
     (VB     : String;
      Width  : out Natural;
      Height : out Natural)
   is
      use Adi.SVG.Parser;
      I     : Integer := VB'First;
      Num   : Natural := 0;
      Token_Start : Integer;
   begin
      Width  := 0;
      Height := 0;

      while I <= VB'Last and then Num < 4 loop
         --  Skip whitespace and commas
         while I <= VB'Last
           and then (VB (I) = ' ' or else VB (I) = ',' or else VB (I) = ASCII.HT)
         loop
            I := I + 1;
         end loop;
         exit when I > VB'Last;

         Token_Start := I;
         while I <= VB'Last
           and then VB (I) /= ' ' and then VB (I) /= ',' and then VB (I) /= ASCII.HT
         loop
            I := I + 1;
         end loop;

         Num := Num + 1;
         if Num = 3 then
            Width := Natural (Float'Rounding (Parse_Number (VB (Token_Start .. I - 1))));
         elsif Num = 4 then
            Height := Natural (Float'Rounding (Parse_Number (VB (Token_Start .. I - 1))));
         end if;
      end loop;
   end Parse_View_Box;

   ---------------------------------------------------------------------------
   --  Parse all <symbol> elements from SVG source
   ---------------------------------------------------------------------------

   procedure Parse_Symbols
     (Sheet  : in out Sprite_Sheet;
      Source : String)
   is
      use Adi.SVG.Parser;
      I : Integer := Source'First;
      Tag_End  : Natural;
   begin
      while I <= Source'Last loop
         --  Find next '<'
         while I <= Source'Last and then Source (I) /= '<' loop
            I := I + 1;
         end loop;
         exit when I > Source'Last;

         --  Skip comments and processing instructions
         if I + 3 <= Source'Last and then Source (I .. I + 3) = "<!--" then
            --  Find end of comment
            declare
               J : Integer := I + 4;
            begin
               while J + 2 <= Source'Last loop
                  exit when Source (J .. J + 2) = "-->";
                  J := J + 1;
               end loop;
               I := J + 3;
            end;
         elsif I + 1 <= Source'Last and then Source (I + 1) = '?' then
            --  Processing instruction: skip to ?>
            declare
               J : Integer := I + 2;
            begin
               while J + 1 <= Source'Last loop
                  exit when Source (J .. J + 1) = "?>";
                  J := J + 1;
               end loop;
               I := J + 2;
            end;
         else
            --  Regular tag
            Tag_End := Find_Tag_End (Source, I);
            exit when Tag_End = 0;

            declare
               Tag_Content : constant String := Source (I + 1 .. Tag_End - 1);
               Name        : constant String := Tag_Name (Tag_Content);
            begin
               if Name = "symbol" and then not Is_Closing_Tag (Tag_Content) then
                  declare
                     Id : constant String := Attribute_Value (Tag_Content, "id");
                     VB : constant String := Attribute_Value (Tag_Content, "viewBox");
                  begin
                     if Id'Length > 0 then
                        if Is_Self_Closing_Tag (Tag_Content) then
                           --  Self-closing <symbol .../> (unlikely but handle it)
                           Insert (Sheet, Id, VB, "");
                        else
                           --  Find matching </symbol>
                           declare
                              Content_Start : constant Integer := Tag_End + 1;
                              J : Integer := Content_Start;
                              Depth : Natural := 1;
                              Inner_Tag_End : Natural;
                           begin
                              while J <= Source'Last and then Depth > 0 loop
                                 while J <= Source'Last and then Source (J) /= '<' loop
                                    J := J + 1;
                                 end loop;
                                 exit when J > Source'Last;

                                 Inner_Tag_End := Find_Tag_End (Source, J);
                                 exit when Inner_Tag_End = 0;

                                 declare
                                    Inner_Tag : constant String :=
                                      Source (J + 1 .. Inner_Tag_End - 1);
                                    Inner_Name : constant String := Tag_Name (Inner_Tag);
                                 begin
                                    if Inner_Name = "symbol" then
                                       if Is_Closing_Tag (Inner_Tag) then
                                          Depth := Depth - 1;
                                       elsif not Is_Self_Closing_Tag (Inner_Tag) then
                                          Depth := Depth + 1;
                                       end if;
                                    end if;
                                 end;

                                 J := Inner_Tag_End + 1;
                              end loop;

                              --  Content is everything between <symbol...> and </symbol>
                              --  J points past the '>' of </symbol>, so content ends
                              --  at the '<' of </symbol>.
                              declare
                                 --  Find the '<' of the closing </symbol> tag
                                 Close_Start : Integer := J - 1;
                              begin
                                 --  J is past '>'; go back to find '<'
                                 while Close_Start >= Content_Start
                                   and then Source (Close_Start) /= '<'
                                 loop
                                    Close_Start := Close_Start - 1;
                                 end loop;

                                 if Close_Start >= Content_Start then
                                    Insert
                                      (Sheet, Id, VB,
                                       Source (Content_Start .. Close_Start - 1));
                                 else
                                    Insert (Sheet, Id, VB, "");
                                 end if;
                              end;

                              I := J;
                           end;
                        end if;
                     else
                        I := Tag_End + 1;
                     end if;
                  end;
               else
                  I := Tag_End + 1;
               end if;
            end;
         end if;
      end loop;
   end Parse_Symbols;

   ---------------------------------------------------------------------------
   --  Public API
   ---------------------------------------------------------------------------

   function Load (Path : String) return Sprite_Sheet_Access is
   begin
      if not Ada.Directories.Exists (Path) then
         Adi.Log.Error ("SVG sprite file not found: " & Path);
         return null;
      end if;

      declare
         Source : constant String := Read_File (Path);
      begin
         if Source'Length = 0 then
            Adi.Log.Error ("SVG sprite file is empty: " & Path);
            return null;
         end if;
         return Load_From_String (Source);
      end;
   end Load;

   function Load_From_String (Source : String) return Sprite_Sheet_Access is
      Sheet : Sprite_Sheet_Access;
   begin
      if Source'Length = 0 then
         return null;
      end if;

      Sheet := new Sprite_Sheet;
      Parse_Symbols (Sprite_Sheet (Sheet.all), Source);

      if Sheet.Count = 0 then
         Adi.Log.Warning ("No <symbol> elements found in SVG sprite source");
      end if;

      return Sheet;
   end Load_From_String;

   function Has_Symbol
     (Sheet : Sprite_Sheet;
      Id    : String) return Boolean
   is
   begin
      return Lookup (Sheet, Id) /= null;
   end Has_Symbol;

   function Symbol_Count (Sheet : Sprite_Sheet) return Natural is
   begin
      return Sheet.Count;
   end Symbol_Count;

   function Get_Image
     (Sheet    : Sprite_Sheet;
      Id       : String;
      Tintable : Boolean := False) return Image_Access
   is
      E  : constant Symbol_Entry_Access := Lookup (Sheet, Id);
      VB : Unbounded_String;
      W, H : Natural;
      W_Str, H_Str : Unbounded_String;
      SVG_Source : Unbounded_String;
      Fill_Attr : constant String :=
        (if Tintable then " fill=""#ffffff""" else "");
   begin
      if E = null then
         return null;
      end if;

      VB := E.View_Box;
      Parse_View_Box (To_String (VB), W, H);

      --  Fall back to reasonable defaults
      if W = 0 then
         W := 512;
      end if;
      if H = 0 then
         H := 512;
      end if;

      declare
         function Trim_Img (V : Natural) return String is
           (Ada.Strings.Fixed.Trim (Natural'Image (V), Ada.Strings.Both));
      begin
         W_Str := To_Unbounded_String (Trim_Img (W));
         H_Str := To_Unbounded_String (Trim_Img (H));
      end;

      SVG_Source :=
        To_Unbounded_String
          ("<svg xmlns=""http://www.w3.org/2000/svg""" & Fill_Attr
           & " viewBox=""" & To_String (VB)
           & """ width=""" & To_String (W_Str)
           & """ height=""" & To_String (H_Str) & """>"
           & To_String (E.Content)
           & "</svg>");

      return Adi.Image.Load_SVG_From_String
        (Source   => To_String (SVG_Source),
         Tintable => Tintable);
   end Get_Image;

   procedure Destroy (Sheet : in out Sprite_Sheet) is
      E, Next : Symbol_Entry_Access;
   begin
      if Sheet.Buckets /= null then
         for I in Sheet.Buckets'Range loop
            E := Sheet.Buckets (I);
            while E /= null loop
               Next := E.Next;
               Free_Entry (E);
               E := Next;
            end loop;
         end loop;
         Free_Buckets (Sheet.Buckets);
      end if;
      Sheet.Count := 0;
   end Destroy;

end Adi.SVG_Sprites;
