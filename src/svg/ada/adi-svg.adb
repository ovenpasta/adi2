with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Containers.Vectors;
with Ada.Numerics.Elementary_Functions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Ada.Environment_Variables;
with System;
with Adi.CSS_Styles;
with Adi.SVG.Ada_Cache;
with Adi.SVG.Constants;
with Adi.SVG.Parser;
with Adi.SVG.Renderer;
with Interfaces;

package body Adi.SVG is

   package Ch renames Ada.Characters.Handling;
   package Fix renames Ada.Strings.Fixed;
   package Math renames Ada.Numerics.Elementary_Functions;
   package US renames Ada.Strings.Unbounded;

   procedure Free_String is new Ada.Unchecked_Deallocation (String, String_Access);
   procedure Free_Pixel_Buffer is
     new Ada.Unchecked_Deallocation (Pixel_Buffer, Pixel_Buffer_Access);

   function To_Address is new Ada.Unchecked_Conversion
     (Source => Adi.SVG.Ada_Cache.Cache_Access,
      Target => System.Address);

   function To_Cache_Access is new Ada.Unchecked_Conversion
     (Source => System.Address,
      Target => Adi.SVG.Ada_Cache.Cache_Access);

   function To_U8 (V : Integer) return Interfaces.Unsigned_8
     renames Adi.SVG.Renderer.To_U8;

   function Pack_ARGB
     (A, R, G, B : Interfaces.Unsigned_8) return Uint32
     renames Adi.SVG.Renderer.Pack_ARGB;

   function Starts_With (S, Prefix : String) return Boolean is
   begin
      return S'Length >= Prefix'Length
        and then S (S'First .. S'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Hex_Digit (C : Character) return Integer is
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
   end Hex_Digit;

   procedure Skip_Number_Separators
     (S            : String;
      Pos          : in out Integer;
      Allow_Comma  : Boolean := True)
   is
   begin
      while Pos <= S'Last loop
         exit when not Adi.SVG.Parser.Is_WS (S (Pos))
           and then (not Allow_Comma or else S (Pos) /= ',');
         Pos := Pos + 1;
      end loop;
   end Skip_Number_Separators;

   function Has_Number_At
     (S            : String;
      Pos          : Integer;
      Allow_Comma  : Boolean := True) return Boolean
   is
      P : Integer := Pos;
   begin
      Skip_Number_Separators (S, P, Allow_Comma => Allow_Comma);
      if P > S'Last then
         return False;
      end if;

      return S (P) in '+' | '-' | '.' | '0' .. '9';
   end Has_Number_At;

   function Read_Number_At
     (S            : String;
      Pos          : in out Integer;
      V            : out Float;
      Allow_Comma  : Boolean := True) return Boolean
   is
      Start     : Integer;
      P         : Integer := Pos;
      Saw_Digit : Boolean := False;
   begin
      Skip_Number_Separators (S, P, Allow_Comma => Allow_Comma);
      if P > S'Last then
         return False;
      end if;

      Start := P;
      if S (P) = '+' or else S (P) = '-' then
         P := P + 1;
      end if;

      while P <= S'Last and then S (P) in '0' .. '9' loop
         Saw_Digit := True;
         P := P + 1;
      end loop;

      if P <= S'Last and then S (P) = '.' then
         P := P + 1;
         while P <= S'Last and then S (P) in '0' .. '9' loop
            Saw_Digit := True;
            P := P + 1;
         end loop;
      end if;

      if not Saw_Digit then
         return False;
      end if;

      if P <= S'Last and then (S (P) = 'e' or else S (P) = 'E') then
         declare
            E_Pos : Integer := P + 1;
            E_Dig : Boolean := False;
         begin
            if E_Pos <= S'Last and then (S (E_Pos) = '+' or else S (E_Pos) = '-') then
               E_Pos := E_Pos + 1;
            end if;

            while E_Pos <= S'Last and then S (E_Pos) in '0' .. '9' loop
               E_Dig := True;
               E_Pos := E_Pos + 1;
            end loop;

            if E_Dig then
               P := E_Pos;
            end if;
         end;
      end if;

      begin
         V := Float'Value (S (Start .. P - 1));
      exception
         when others =>
            return False;
      end;

      Pos := P;
      return True;
   end Read_Number_At;

   function Parse_Color (S : String; Opacity : Float := 1.0) return Uint32 is
      T : constant String := Ch.To_Lower (Fix.Trim (S, Ada.Strings.Both));
      R, G, B : Integer := 0;
      Alpha   : constant Integer :=
        Integer (Float'Max (0.0, Float'Min (1.0, Opacity)) * 255.0);
   begin
      if T = "none" or else T'Length = 0 then
         return 0;
      end if;

      declare
         Named : Adi.CSS_Styles.Named_Color;
      begin
         if Adi.CSS_Styles.Parse_Named_Color (T, Named) then
            declare
               NR, NG, NB : Natural := 0;
               NA         : Float := 1.0;
            begin
               Adi.CSS_Styles.Normalize_Color
                 (C => Adi.CSS_Styles.C (Named),
                  R => NR,
                  G => NG,
                  B => NB,
                  A => NA);

               return Pack_ARGB
                 (To_U8
                    (Integer
                       (255.0 * Float'Max (0.0, Float'Min (1.0, Opacity * NA)))),
                  To_U8 (Integer (NR)),
                  To_U8 (Integer (NG)),
                  To_U8 (Integer (NB)));
            end;
         end if;
      end;

      if T'Length = 7 and then T (T'First) = '#' then
         R := Hex_Digit (T (T'First + 1)) * 16 + Hex_Digit (T (T'First + 2));
         G := Hex_Digit (T (T'First + 3)) * 16 + Hex_Digit (T (T'First + 4));
         B := Hex_Digit (T (T'First + 5)) * 16 + Hex_Digit (T (T'First + 6));
         if R < 0 or else G < 0 or else B < 0 then
            return 0;
         end if;
         return Pack_ARGB (To_U8 (Alpha), To_U8 (R), To_U8 (G), To_U8 (B));

      elsif T'Length = 4 and then T (T'First) = '#' then
         R := Hex_Digit (T (T'First + 1));
         G := Hex_Digit (T (T'First + 2));
         B := Hex_Digit (T (T'First + 3));
         if R < 0 or else G < 0 or else B < 0 then
            return 0;
         end if;
         return Pack_ARGB
           (To_U8 (Alpha),
            To_U8 (R * 17),
            To_U8 (G * 17),
            To_U8 (B * 17));

      elsif Starts_With (T, "rgb(") and then T (T'Last) = ')' then
         declare
            RGB_Body : constant String := T (T'First + 4 .. T'Last - 1);
            C1 : constant Natural := Fix.Index (RGB_Body, ",");
            C2 : Natural := 0;
         begin
            if C1 > 0 then
               C2 := Fix.Index (RGB_Body, ",", From => C1 + 1);
            end if;

            if C1 = 0 or else C2 = 0 then
               return 0;
            end if;

            begin
               R := Integer'Value
                 (Fix.Trim (RGB_Body (RGB_Body'First .. C1 - 1), Ada.Strings.Both));
               G := Integer'Value
                 (Fix.Trim (RGB_Body (C1 + 1 .. C2 - 1), Ada.Strings.Both));
               B := Integer'Value
                 (Fix.Trim (RGB_Body (C2 + 1 .. RGB_Body'Last), Ada.Strings.Both));
               return Pack_ARGB (To_U8 (Alpha), To_U8 (R), To_U8 (G), To_U8 (B));
            exception
               when others =>
                  return 0;
            end;
         end;
      end if;

      return 0;
   end Parse_Color;

   function Parse_Number (S : String; Default : Float := 0.0) return Float is
   begin
      return Adi.SVG.Parser.Parse_Number (S, Default);
   end Parse_Number;

   function Parse_Length
     (S         : String;
      Axis_Size : Float;
      Default   : Float := 0.0) return Float
   is
   begin
      return Adi.SVG.Parser.Parse_Length (S, Axis_Size, Default);
   end Parse_Length;

   function Attribute_Value (Tag : String; Name : String) return String is
   begin
      return Adi.SVG.Parser.Attribute_Value (Tag, Name);
   end Attribute_Value;

   function Load_File_Text (Path : String) return String_Access is
      use Ada.Streams;
      package SIO renames Ada.Streams.Stream_IO;
      use type SIO.Count;

      F    : SIO.File_Type;
      Buf  : String_Access := null;
   begin
      SIO.Open (F, SIO.In_File, Path);
      declare
         File_Size : constant SIO.Count := SIO.Size (F);
      begin
         if File_Size = 0 then
            SIO.Close (F);
            return null;
         end if;

         declare
            Data : Stream_Element_Array (1 .. Stream_Element_Offset (File_Size));
            Last : Stream_Element_Offset;
         begin
            SIO.Read (F, Data, Last);
            SIO.Close (F);

            if Last < Data'First then
               return null;
            end if;

            Buf := new String (1 .. Integer (Last));
            for I in 1 .. Integer (Last) loop
               Buf (I) := Character'Val (Data (Stream_Element_Offset (I)));
            end loop;
         end;
      end;

      return Buf;
   exception
      when others =>
         if SIO.Is_Open (F) then
            SIO.Close (F);
         end if;
         return null;
   end Load_File_Text;

   function Is_Valid (Doc : Document) return Boolean is
   begin
      return Doc.Valid and then Doc.Source /= null;
   end Is_Valid;

   procedure Get_Size
     (Doc    : Document;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
   begin
      Width := Doc.Width;
      Height := Doc.Height;
   end Get_Size;

   function Load_From_File (Path : String) return Document_Access is
      Source    : constant String_Access := Load_File_Text (Path);
      Doc       : Document_Access := new Document;
      W         : Float := 0.0;
      H         : Float := 0.0;
      Svg_Open  : Natural;
      Svg_Close : Natural;
   begin
      if Source = null then
         return Doc;
      end if;

      Svg_Open := Fix.Index (Source.all, "<svg");
      if Svg_Open = 0 then
         Svg_Open := Fix.Index (Source.all, "<SVG");
      end if;

      if Svg_Open > 0 then
         Svg_Close := Adi.SVG.Parser.Find_Tag_End (Source.all, Positive (Svg_Open + 1));
         if Svg_Close > Svg_Open then
            declare
               Svg_Tag : constant String := Source.all (Svg_Open + 1 .. Svg_Close - 1);
            begin
               W := Parse_Length (Attribute_Value (Svg_Tag, "width"), 0.0, 0.0);
               H := Parse_Length (Attribute_Value (Svg_Tag, "height"), 0.0, 0.0);

               if W <= 0.0 or else H <= 0.0 then
                  declare
                     VB : constant String := Attribute_Value (Svg_Tag, "viewBox");
                     Pos : Integer := VB'First;
                     Min_X, Min_Y : Float := 0.0;
                  begin
                     if VB'Length > 0
                       and then Read_Number_At (VB, Pos, Min_X)
                       and then Read_Number_At (VB, Pos, Min_Y)
                       and then Read_Number_At (VB, Pos, W)
                       and then Read_Number_At (VB, Pos, H)
                     then
                        null;
                     end if;
                  end;
               end if;
            end;
         end if;
      end if;

      if W <= 0.0 then
         W := Adi.SVG.Constants.Default_SVG_Width;
      end if;

      if H <= 0.0 then
         H := Adi.SVG.Constants.Default_SVG_Height;
      end if;

      Doc.Source := Source;
      Doc.Width := Pixel_Type (W);
      Doc.Height := Pixel_Type (H);
      Doc.Valid := True;
      declare
         Cache : constant Adi.SVG.Ada_Cache.Cache_Access := Adi.SVG.Ada_Cache.Create;
      begin
         Doc.Handle := To_Address (Cache);
      end;
      return Doc;
   end Load_From_File;

   function Render_ARGB32
     (Doc    : Document;
      Width  : Positive;
      Height : Positive) return Pixel_Buffer_Access
   is
      use type Ada.Containers.Count_Type;
      use type US.Unbounded_String;
      use type Interfaces.Unsigned_8;
      use type Adi.SVG.Ada_Cache.Cache_Access;

      function Effective_AA_Scale return Positive is
         package Env renames Ada.Environment_Variables;
         S : constant String := Env.Value ("ADI_SVG_AA_SCALE", "");
      begin
         if S'Length > 0 then
            begin
               declare
                  V : constant Integer := Integer'Value (S);
               begin
                  if V >= 1 and then V <= 8 then
                     return Positive (V);
                  end if;
               end;
            exception
               when others =>
                  null;
            end;
         end if;

         return Adi.SVG.Constants.Default_AA_Scale;
      end Effective_AA_Scale;

      AA_Scale : constant Positive := Effective_AA_Scale;
      Render_W : constant Positive := Width * AA_Scale;
      Render_H : constant Positive := Height * AA_Scale;
      SW       : constant Float := Float (Pixel_Type'Max (1.0, Doc.Width));
      SH       : constant Float := Float (Pixel_Type'Max (1.0, Doc.Height));
      Doc_Cache : constant Adi.SVG.Ada_Cache.Cache_Access := To_Cache_Access (Doc.Handle);

      subtype Matrix is Adi.SVG.Parser.Matrix;
      subtype Fill_Rule_Kind is Adi.SVG.Renderer.Fill_Rule_Kind;
      subtype Stroke_Line_Cap_Kind is Adi.SVG.Renderer.Stroke_Line_Cap_Kind;
      subtype Stroke_Line_Join_Kind is Adi.SVG.Renderer.Stroke_Line_Join_Kind;

      use type Fill_Rule_Kind;

      type Paint_Kind is (No_Paint, Solid_Paint, Gradient_Paint);

      type Paint_Value is record
         Kind   : Paint_Kind := No_Paint;
         Color  : Uint32 := 0;
         Ref_Id : US.Unbounded_String := US.Null_Unbounded_String;
      end record;

      type Spread_Method_Kind is (Pad_Spread, Reflect_Spread, Repeat_Spread);
      type Gradient_Kind is (Linear_Gradient, Radial_Gradient);

      type Color_Stop is record
         Offset : Float := 0.0;
         Color  : Uint32 := 0;
      end record;

      package Stop_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Color_Stop);

      type Gradient_Def is record
         Id                : US.Unbounded_String := US.Null_Unbounded_String;
         Kind              : Gradient_Kind := Linear_Gradient;
         Href              : US.Unbounded_String := US.Null_Unbounded_String;
         Units_Object_BBox : Boolean := True;
         Has_Units         : Boolean := False;
         Spread            : Spread_Method_Kind := Pad_Spread;
         Has_Spread        : Boolean := False;
         Transform         : Matrix := Adi.SVG.Parser.Identity_Matrix;
         Has_Transform     : Boolean := False;
         X1                : Float := 0.0;
         Y1                : Float := 0.0;
         X2                : Float := 1.0;
         Y2                : Float := 0.0;
         Has_X1            : Boolean := False;
         Has_Y1            : Boolean := False;
         Has_X2            : Boolean := False;
         Has_Y2            : Boolean := False;
         CX                : Float := 0.5;
         CY                : Float := 0.5;
         R                 : Float := 0.5;
         FX                : Float := 0.5;
         FY                : Float := 0.5;
         Has_CX            : Boolean := False;
         Has_CY            : Boolean := False;
         Has_R             : Boolean := False;
         Has_FX            : Boolean := False;
         Has_FY            : Boolean := False;
         Stops             : Stop_Vectors.Vector;
      end record;

      package Gradient_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Gradient_Def);

      type Element_Def is record
         Id      : US.Unbounded_String := US.Null_Unbounded_String;
         Name    : US.Unbounded_String := US.Null_Unbounded_String;
         Open_LT : Natural := 0;
         End_GT  : Natural := 0;
      end record;

      package Element_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Element_Def);

      package Id_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => US.Unbounded_String,
         "="          => US."=");

      type Bounds_Record is record
         Valid : Boolean := False;
         Min_X : Float := 0.0;
         Min_Y : Float := 0.0;
         Max_X : Float := 0.0;
         Max_Y : Float := 0.0;
      end record;

      type Style_State is record
         Fill_Paint         : Paint_Value :=
           (Kind => Solid_Paint,
            Color => Pack_ARGB (255, 0, 0, 0),
            Ref_Id => US.Null_Unbounded_String);
         Stroke_Paint       : Paint_Value :=
           (Kind => No_Paint,
            Color => 0,
            Ref_Id => US.Null_Unbounded_String);
         Stroke_Width       : Float := 1.0;
         Stroke_Line_Cap    : Stroke_Line_Cap_Kind := Adi.SVG.Renderer.Butt_Cap;
         Stroke_Line_Join   : Stroke_Line_Join_Kind := Adi.SVG.Renderer.Miter_Join;
         Stroke_Miter_Limit : Float := 4.0;
         Stroke_Dash_Array  : Adi.SVG.Renderer.Dash_Vectors.Vector :=
           Adi.SVG.Renderer.Dash_Vectors.Empty_Vector;
         Stroke_Dash_Offset : Float := 0.0;
         Opacity            : Float := 1.0;
         Fill_Opacity       : Float := 1.0;
         Stroke_Opacity     : Float := 1.0;
         Fill_Rule          : Fill_Rule_Kind := Adi.SVG.Renderer.Non_Zero;
         Display_None       : Boolean := False;
         Visibility_Hidden  : Boolean := False;
      end record;

      type Render_State is record
         Style  : Style_State;
         M      : Matrix;
         Hidden : Boolean := False;
      end record;

      package State_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Render_State);

      subtype Point is Adi.SVG.Parser.Point;
      subtype Contour is Adi.SVG.Parser.Contour;
      package Contour_Vectors renames Adi.SVG.Parser.Contour_Vectors;

      Pixels : Pixel_Buffer_Access := null;

      Gradients : Gradient_Vectors.Vector;
      Elements  : Element_Vectors.Vector;

      function Parse_Percent_Or_Number
        (S       : String;
         Default : Float := 0.0) return Float
      is
         T : constant String := Fix.Trim (S, Ada.Strings.Both);
      begin
         if T'Length = 0 then
            return Default;
         elsif T (T'Last) = '%' then
            return Parse_Number (T (T'First .. T'Last - 1), Default) / 100.0;
         else
            return Parse_Number (T, Default);
         end if;
      end Parse_Percent_Or_Number;

      function Extract_Ref_Id (Value : String) return String is
         T : constant String := Fix.Trim (Value, Ada.Strings.Both);
      begin
         if T'Length = 0 then
            return "";
         elsif T (T'First) = '#' and then T'Length > 1 then
            return T (T'First + 1 .. T'Last);
         elsif Starts_With (Ch.To_Lower (T), "url(") and then T (T'Last) = ')' then
            declare
               Inner : constant String :=
                 Fix.Trim (T (T'First + 4 .. T'Last - 1), Ada.Strings.Both);
            begin
               if Inner'Length > 1 and then Inner (Inner'First) = '#' then
                  return Inner (Inner'First + 1 .. Inner'Last);
               end if;
            end;
         end if;
         return "";
      end Extract_Ref_Id;

      function In_Id_Stack
        (Stack : Id_Vectors.Vector;
         Id    : String) return Boolean
      is
      begin
         for V of Stack loop
            if US.To_String (V) = Id then
               return True;
            end if;
         end loop;
         return False;
      end In_Id_Stack;

      function Find_Element_Index (Id : String) return Natural is
      begin
         for I in 1 .. Natural (Elements.Length) loop
            if US.To_String (Elements.Element (Positive (I)).Id) = Id then
               return I;
            end if;
         end loop;
         return 0;
      end Find_Element_Index;

      function Find_Gradient_Index (Id : String) return Natural is
      begin
         for I in 1 .. Natural (Gradients.Length) loop
            if US.To_String (Gradients.Element (Positive (I)).Id) = Id then
               return I;
            end if;
         end loop;
         return 0;
      end Find_Gradient_Index;

      procedure Parse_Dash_Array_Text
        (Text   : String;
         Dashes : in out Adi.SVG.Renderer.Dash_Vectors.Vector)
      is
         T : constant String := Fix.Trim (Text, Ada.Strings.Both);
         P : Integer := T'First;
      begin
         Dashes.Clear;
         if T'Length = 0 or else Ch.To_Lower (T) = "none" then
            return;
         end if;

         while P <= T'Last loop
            while P <= T'Last and then (Adi.SVG.Parser.Is_WS (T (P)) or else T (P) = ',') loop
               P := P + 1;
            end loop;
            exit when P > T'Last;

            declare
               S0 : constant Integer := P;
            begin
               while P <= T'Last and then not Adi.SVG.Parser.Is_WS (T (P)) and then T (P) /= ',' loop
                  P := P + 1;
               end loop;

               if P > S0 then
                  declare
                     Token : constant String := T (S0 .. P - 1);
                     V     : constant Float := Parse_Length (Token, Float'Min (SW, SH), 0.0);
                  begin
                     if V > 0.0 then
                        Dashes.Append (V);
                     end if;
                  end;
               end if;
            end;
         end loop;
      end Parse_Dash_Array_Text;

      procedure Set_Paint_From_Text
        (Value : String;
         Paint : in out Paint_Value)
      is
          T      : constant String := Fix.Trim (Value, Ada.Strings.Both);
          TL     : constant String := Ch.To_Lower (T);
          Url_Pos : constant Natural := Fix.Index (TL, "url(");
          Close_Pos : Natural := 0;
      begin
          if TL = "none" then
             Paint.Kind := No_Paint;
             Paint.Color := 0;
             Paint.Ref_Id := US.Null_Unbounded_String;

         elsif Url_Pos = 1 then
            for I in Url_Pos + 4 .. T'Last loop
               if T (I) = ')' then
                  Close_Pos := I;
                  exit;
               end if;
            end loop;

            if Close_Pos > Url_Pos + 4 then
               declare
                  Inner : String := Fix.Trim (T (Url_Pos + 4 .. Close_Pos - 1), Ada.Strings.Both);
               begin
                  if Inner'Length >= 2
                    and then ((Inner (Inner'First) = '"' and then Inner (Inner'Last) = '"')
                              or else (Inner (Inner'First) = ''' and then Inner (Inner'Last) = '''))
                  then
                     Inner := Fix.Trim (Inner (Inner'First + 1 .. Inner'Last - 1), Ada.Strings.Both);
                  end if;

                  if Inner'Length > 1 and then Inner (Inner'First) = '#' then
                     Paint.Kind := Gradient_Paint;
                     Paint.Ref_Id := US.To_Unbounded_String (Inner (Inner'First + 1 .. Inner'Last));

                     if Close_Pos < T'Last then
                        declare
                           Fallback : constant String := Fix.Trim (T (Close_Pos + 1 .. T'Last), Ada.Strings.Both);
                        begin
                           if Fallback'Length > 0 then
                              Paint.Color := Parse_Color (Fallback, 1.0);
                           else
                              Paint.Color := 0;
                           end if;
                        end;
                     else
                        Paint.Color := 0;
                     end if;

                     return;
                  end if;
               end;
            end if;

            Paint.Kind := Solid_Paint;
            Paint.Color := Parse_Color (T, 1.0);
            Paint.Ref_Id := US.Null_Unbounded_String;

         else
            Paint.Kind := Solid_Paint;
            Paint.Color := Parse_Color (T, 1.0);
            Paint.Ref_Id := US.Null_Unbounded_String;
          end if;
      end Set_Paint_From_Text;

      procedure Find_Matching_Close
        (Source   : String;
         Open_GT  : Natural;
         Name     : String;
         Close_LT : out Natural;
         Close_GT : out Natural)
      is
         Pos   : Integer := Integer (Open_GT) + 1;
         Depth : Natural := 1;
      begin
         Close_LT := 0;
         Close_GT := 0;

         while Pos <= Source'Last loop
            declare
               L : constant Natural := Fix.Index (Source, "<", From => Pos);
            begin
               exit when L = 0;

               if L + 1 <= Source'Last and then Source (L + 1) = '!' then
                  if L + 3 <= Source'Last and then Source (L + 2 .. L + 3) = "--" then
                     declare
                        C_End : constant Natural := Fix.Index (Source, "-->", From => L + 4);
                     begin
                        exit when C_End = 0;
                        Pos := Integer (C_End) + 3;
                     end;
                  else
                     declare
                        R0 : constant Natural := Fix.Index (Source, ">", From => L + 2);
                     begin
                        exit when R0 = 0;
                        Pos := Integer (R0) + 1;
                     end;
                  end if;
               elsif L + 1 <= Source'Last and then Source (L + 1) = '?' then
                  declare
                     Q_End : constant Natural := Fix.Index (Source, "?>", From => L + 2);
                  begin
                     exit when Q_End = 0;
                     Pos := Integer (Q_End) + 2;
                  end;
               else
                  declare
                     R : constant Natural := Adi.SVG.Parser.Find_Tag_End (Source, Positive (L + 1));
                  begin
                     exit when R = 0;

                     declare
                        Tag      : constant String := Source (L + 1 .. R - 1);
                        Tag_Name : constant String := Adi.SVG.Parser.Tag_Name (Tag);
                     begin
                        if Tag_Name = Name then
                           if Adi.SVG.Parser.Is_Closing_Tag (Tag) then
                              Depth := Depth - 1;
                              if Depth = 0 then
                                 Close_LT := L;
                                 Close_GT := R;
                                 return;
                              end if;
                           elsif not Adi.SVG.Parser.Is_Self_Closing_Tag (Tag) then
                              Depth := Depth + 1;
                           end if;
                        end if;
                     end;
                     Pos := Integer (R) + 1;
                  end;
               end if;
            end;
         end loop;
      end Find_Matching_Close;

      function Style_Property_Value
        (Style_Text : String;
         Name       : String) return String
      is
         N : constant String := Ch.To_Lower (Fix.Trim (Name, Ada.Strings.Both));
         P : Integer := Style_Text'First;
      begin
         while P <= Style_Text'Last loop
            declare
               Semi : constant Natural := Fix.Index (Style_Text, ";", From => P);
               Last : constant Integer := (if Semi = 0 then Style_Text'Last else Semi - 1);
            begin
               if Last >= P then
                  declare
                     Chunk : constant String := Fix.Trim (Style_Text (P .. Last), Ada.Strings.Both);
                     C     : constant Natural := Fix.Index (Chunk, ":");
                  begin
                     if C > 0 then
                        declare
                           K : constant String :=
                             Ch.To_Lower (Fix.Trim (Chunk (Chunk'First .. C - 1), Ada.Strings.Both));
                        begin
                           if K = N then
                              return Fix.Trim (Chunk (C + 1 .. Chunk'Last), Ada.Strings.Both);
                           end if;
                        end;
                     end if;
                  end;
               end if;

               exit when Semi = 0;
               P := Integer (Semi) + 1;
            end;
         end loop;
         return "";
      end Style_Property_Value;

      procedure Parse_Gradient_Stops
        (Body_Text : String;
         G    : in out Gradient_Def)
      is
         Pos : Integer := Body_Text'First;
      begin
         while Pos <= Body_Text'Last loop
            declare
               L : constant Natural := Fix.Index (Body_Text, "<", From => Pos);
            begin
               exit when L = 0;

               if L + 1 <= Body_Text'Last and then Body_Text (L + 1) = '!' then
                  if L + 3 <= Body_Text'Last and then Body_Text (L + 2 .. L + 3) = "--" then
                     declare
                        C_End : constant Natural := Fix.Index (Body_Text, "-->", From => L + 4);
                     begin
                        exit when C_End = 0;
                        Pos := Integer (C_End) + 3;
                     end;
                  else
                     declare
                        R0 : constant Natural := Fix.Index (Body_Text, ">", From => L + 2);
                     begin
                        exit when R0 = 0;
                        Pos := Integer (R0) + 1;
                     end;
                  end if;
               else
                  declare
                     R : constant Natural := Adi.SVG.Parser.Find_Tag_End (Body_Text, Positive (L + 1));
                  begin
                     exit when R = 0;

                     declare
                        Tag      : constant String := Body_Text (L + 1 .. R - 1);
                        Tag_Name : constant String := Adi.SVG.Parser.Tag_Name (Tag);
                     begin
                        if Tag_Name = "stop" and then not Adi.SVG.Parser.Is_Closing_Tag (Tag) then
                           declare
                              Offset_Text  : constant String := Attribute_Value (Tag, "offset");
                              Style_Text   : constant String := Attribute_Value (Tag, "style");
                              Color_Text_1 : constant String := Attribute_Value (Tag, "stop-color");
                              Color_Text_2 : constant String := Style_Property_Value (Style_Text, "stop-color");
                              Alpha_Text_1 : constant String := Attribute_Value (Tag, "stop-opacity");
                              Alpha_Text_2 : constant String := Style_Property_Value (Style_Text, "stop-opacity");
                              Color_Text   : constant String :=
                                (if Color_Text_1'Length > 0 then Color_Text_1 else Color_Text_2);
                              Alpha_Text   : constant String :=
                                (if Alpha_Text_1'Length > 0 then Alpha_Text_1 else Alpha_Text_2);
                              Offset       : constant Float :=
                                Adi.SVG.Parser.Clamp01 (Parse_Percent_Or_Number (Offset_Text, 0.0));
                              Opacity      : constant Float :=
                                Adi.SVG.Parser.Clamp01
                                  (Parse_Number ((if Alpha_Text'Length > 0 then Alpha_Text else "1"), 1.0));
                              Color        : constant Uint32 :=
                                Parse_Color ((if Color_Text'Length > 0 then Color_Text else "black"), Opacity);
                           begin
                              G.Stops.Append (Color_Stop'(Offset => Offset, Color => Color));
                           end;
                        end if;
                     end;

                     Pos := Integer (R) + 1;
                  end;
               end if;
            end;
         end loop;

         if G.Stops.Length > 1 then
            for I in 1 .. Natural (G.Stops.Length) - 1 loop
               for J in I + 1 .. Natural (G.Stops.Length) loop
                  if G.Stops.Element (Positive (J)).Offset < G.Stops.Element (Positive (I)).Offset then
                     declare
                        A : constant Color_Stop := G.Stops.Element (Positive (I));
                        B : constant Color_Stop := G.Stops.Element (Positive (J));
                     begin
                        G.Stops.Replace_Element (Positive (I), B);
                        G.Stops.Replace_Element (Positive (J), A);
                     end;
                  end if;
               end loop;
            end loop;
         end if;
      end Parse_Gradient_Stops;

      procedure Parse_Gradient_Tag
        (Tag  : String;
         Body_Text : String;
         Kind : Gradient_Kind)
      is
         G              : Gradient_Def;
         Units_Text     : constant String := Ch.To_Lower (Attribute_Value (Tag, "gradientUnits"));
         Spread_Text    : constant String := Ch.To_Lower (Attribute_Value (Tag, "spreadMethod"));
         Transform_Text : constant String := Attribute_Value (Tag, "gradientTransform");
         Href_Text_1    : constant String := Attribute_Value (Tag, "href");
         Href_Text_2    : constant String := Attribute_Value (Tag, "xlink:href");
         Href_Text      : constant String := (if Href_Text_1'Length > 0 then Href_Text_1 else Href_Text_2);
      begin
         G.Kind := Kind;
         G.Id := US.To_Unbounded_String (Attribute_Value (Tag, "id"));
         if G.Id = US.Null_Unbounded_String then
            return;
         end if;

         if Href_Text'Length > 0 then
            declare
               Ref_Id : constant String := Extract_Ref_Id (Href_Text);
            begin
               if Ref_Id'Length > 0 then
                  G.Href := US.To_Unbounded_String (Ref_Id);
               end if;
            end;
         end if;

         if Units_Text = "userspaceonuse" then
            G.Units_Object_BBox := False;
            G.Has_Units := True;
         elsif Units_Text = "objectboundingbox" then
            G.Units_Object_BBox := True;
            G.Has_Units := True;
         end if;

         if Spread_Text = "reflect" then
            G.Spread := Reflect_Spread;
            G.Has_Spread := True;
         elsif Spread_Text = "repeat" then
            G.Spread := Repeat_Spread;
            G.Has_Spread := True;
         elsif Spread_Text = "pad" then
            G.Spread := Pad_Spread;
            G.Has_Spread := True;
         end if;

         if Transform_Text'Length > 0 then
            G.Transform := Adi.SVG.Parser.Parse_Transform (Transform_Text);
            G.Has_Transform := True;
         end if;

         if Kind = Linear_Gradient then
            declare
               X1_Text : constant String := Attribute_Value (Tag, "x1");
               Y1_Text : constant String := Attribute_Value (Tag, "y1");
               X2_Text : constant String := Attribute_Value (Tag, "x2");
               Y2_Text : constant String := Attribute_Value (Tag, "y2");
            begin
               if X1_Text'Length > 0 then
                  G.X1 := (if G.Units_Object_BBox then Parse_Percent_Or_Number (X1_Text, G.X1) else Parse_Length (X1_Text, SW, G.X1));
                  G.Has_X1 := True;
               end if;
               if Y1_Text'Length > 0 then
                  G.Y1 := (if G.Units_Object_BBox then Parse_Percent_Or_Number (Y1_Text, G.Y1) else Parse_Length (Y1_Text, SH, G.Y1));
                  G.Has_Y1 := True;
               end if;
               if X2_Text'Length > 0 then
                  G.X2 := (if G.Units_Object_BBox then Parse_Percent_Or_Number (X2_Text, G.X2) else Parse_Length (X2_Text, SW, G.X2));
                  G.Has_X2 := True;
               end if;
               if Y2_Text'Length > 0 then
                  G.Y2 := (if G.Units_Object_BBox then Parse_Percent_Or_Number (Y2_Text, G.Y2) else Parse_Length (Y2_Text, SH, G.Y2));
                  G.Has_Y2 := True;
               end if;
            end;
         else
            declare
               CX_Text : constant String := Attribute_Value (Tag, "cx");
               CY_Text : constant String := Attribute_Value (Tag, "cy");
               R_Text  : constant String := Attribute_Value (Tag, "r");
               FX_Text : constant String := Attribute_Value (Tag, "fx");
               FY_Text : constant String := Attribute_Value (Tag, "fy");
            begin
               if CX_Text'Length > 0 then
                  G.CX := (if G.Units_Object_BBox then Parse_Percent_Or_Number (CX_Text, G.CX) else Parse_Length (CX_Text, SW, G.CX));
                  G.Has_CX := True;
               end if;
               if CY_Text'Length > 0 then
                  G.CY := (if G.Units_Object_BBox then Parse_Percent_Or_Number (CY_Text, G.CY) else Parse_Length (CY_Text, SH, G.CY));
                  G.Has_CY := True;
               end if;
               if R_Text'Length > 0 then
                  G.R := (if G.Units_Object_BBox then Parse_Percent_Or_Number (R_Text, G.R) else Parse_Length (R_Text, Float'Min (SW, SH), G.R));
                  G.Has_R := True;
               end if;
               if FX_Text'Length > 0 then
                  G.FX := (if G.Units_Object_BBox then Parse_Percent_Or_Number (FX_Text, G.FX) else Parse_Length (FX_Text, SW, G.FX));
                  G.Has_FX := True;
               end if;
               if FY_Text'Length > 0 then
                  G.FY := (if G.Units_Object_BBox then Parse_Percent_Or_Number (FY_Text, G.FY) else Parse_Length (FY_Text, SH, G.FY));
                  G.Has_FY := True;
               end if;
            end;
         end if;

         Parse_Gradient_Stops (Body_Text, G);
         Gradients.Append (G);
      end Parse_Gradient_Tag;

      procedure Collect_Definitions (Source : String) is
         Pos : Integer := Source'First;
      begin
         while Pos <= Source'Last loop
            declare
               L : constant Natural := Fix.Index (Source, "<", From => Pos);
            begin
               exit when L = 0;

               if L + 1 <= Source'Last and then Source (L + 1) = '!' then
                  if L + 3 <= Source'Last and then Source (L + 2 .. L + 3) = "--" then
                     declare
                        C_End : constant Natural := Fix.Index (Source, "-->", From => L + 4);
                     begin
                        exit when C_End = 0;
                        Pos := Integer (C_End) + 3;
                     end;
                  else
                     declare
                        R0 : constant Natural := Fix.Index (Source, ">", From => L + 2);
                     begin
                        exit when R0 = 0;
                        Pos := Integer (R0) + 1;
                     end;
                  end if;
               elsif L + 1 <= Source'Last and then Source (L + 1) = '?' then
                  declare
                     Q_End : constant Natural := Fix.Index (Source, "?>", From => L + 2);
                  begin
                     exit when Q_End = 0;
                     Pos := Integer (Q_End) + 2;
                  end;
               else
                  declare
                     R : constant Natural := Adi.SVG.Parser.Find_Tag_End (Source, Positive (L + 1));
                  begin
                     exit when R = 0;

                     declare
                        Tag      : constant String := Source (L + 1 .. R - 1);
                        Name     : constant String := Adi.SVG.Parser.Tag_Name (Tag);
                        Id_Text  : constant String := Attribute_Value (Tag, "id");
                        Self_Cls : constant Boolean := Adi.SVG.Parser.Is_Self_Closing_Tag (Tag);
                        Close_LT : Natural := 0;
                        Close_GT : Natural := 0;
                        End_GT   : Natural := R;
                     begin
                        if Name'Length > 0 and then not Adi.SVG.Parser.Is_Closing_Tag (Tag) then
                           if not Self_Cls
                             and then (Name = "svg"
                                       or else Name = "g"
                                       or else Name = "symbol"
                                       or else Name = "defs"
                                       or else Name = "lineargradient"
                                       or else Name = "radialgradient")
                           then
                              Find_Matching_Close (Source, R, Name, Close_LT, Close_GT);
                              if Close_GT > 0 then
                                 End_GT := Close_GT;
                              end if;
                           end if;

                           if Name = "lineargradient" then
                              declare
                                 Body_Text : constant String :=
                                   (if Close_LT > R + 1 then Source (R + 1 .. Close_LT - 1) else "");
                              begin
                                 Parse_Gradient_Tag (Tag, Body_Text, Linear_Gradient);
                              end;
                           elsif Name = "radialgradient" then
                              declare
                                 Body_Text : constant String :=
                                   (if Close_LT > R + 1 then Source (R + 1 .. Close_LT - 1) else "");
                              begin
                                 Parse_Gradient_Tag (Tag, Body_Text, Radial_Gradient);
                              end;
                           end if;

                           if Id_Text'Length > 0 then
                              Elements.Append
                                (Element_Def'
                                   (Id      => US.To_Unbounded_String (Id_Text),
                                    Name    => US.To_Unbounded_String (Name),
                                    Open_LT => L,
                                    End_GT  => End_GT));
                           end if;
                        end if;
                     end;

                     Pos := Integer (R) + 1;
                  end;
               end if;
            end;
         end loop;
      end Collect_Definitions;

      function Invert_Matrix
        (M     : Matrix;
         Inv_M : out Matrix) return Boolean
      is
         Det : constant Float := M.A * M.D - M.B * M.C;
      begin
         if abs Det < 1.0E-9 then
            Inv_M := Adi.SVG.Parser.Identity_Matrix;
            return False;
         end if;

         Inv_M :=
           (A => M.D / Det,
            B => -M.B / Det,
            C => -M.C / Det,
            D => M.A / Det,
            E => (M.C * M.F - M.D * M.E) / Det,
            F => (M.B * M.E - M.A * M.F) / Det);
         return True;
      end Invert_Matrix;

      function Contours_Bounds
        (Contours : Contour_Vectors.Vector) return Bounds_Record
      is
         B : Bounds_Record;
      begin
         for C of Contours loop
            for P of C.Points loop
               if not B.Valid then
                  B.Valid := True;
                  B.Min_X := P.X;
                  B.Max_X := P.X;
                  B.Min_Y := P.Y;
                  B.Max_Y := P.Y;
               else
                  B.Min_X := Float'Min (B.Min_X, P.X);
                  B.Max_X := Float'Max (B.Max_X, P.X);
                  B.Min_Y := Float'Min (B.Min_Y, P.Y);
                  B.Max_Y := Float'Max (B.Max_Y, P.Y);
               end if;
            end loop;
         end loop;
         return B;
      end Contours_Bounds;

      function Apply_Spread
        (T      : Float;
         Spread : Spread_Method_Kind) return Float
      is
         U : Float := T;
      begin
         case Spread is
            when Pad_Spread =>
               return Adi.SVG.Parser.Clamp01 (U);
            when Repeat_Spread =>
               U := U - Float'Floor (U);
               if U < 0.0 then
                  U := U + 1.0;
               end if;
               return U;
            when Reflect_Spread =>
               U := U - Float'Floor (U / 2.0) * 2.0;
               if U < 0.0 then
                  U := U + 2.0;
               end if;
               if U > 1.0 then
                  return 2.0 - U;
               else
                  return U;
               end if;
         end case;
      end Apply_Spread;

      function Interpolate_Color
        (C1, C2 : Uint32;
         T      : Float) return Uint32
      is
         TT : constant Float := Adi.SVG.Parser.Clamp01 (T);
         A1, R1, G1, B1 : Interfaces.Unsigned_8;
         A2, R2, G2, B2 : Interfaces.Unsigned_8;
      begin
         Adi.SVG.Renderer.Unpack_ARGB (C1, A1, R1, G1, B1);
         Adi.SVG.Renderer.Unpack_ARGB (C2, A2, R2, G2, B2);

         return Pack_ARGB
           (To_U8 (Integer (Float (A1) + (Float (A2) - Float (A1)) * TT)),
            To_U8 (Integer (Float (R1) + (Float (R2) - Float (R1)) * TT)),
            To_U8 (Integer (Float (G1) + (Float (G2) - Float (G1)) * TT)),
            To_U8 (Integer (Float (B1) + (Float (B2) - Float (B1)) * TT)));
      end Interpolate_Color;

      function Sample_Stops
        (Stops : Stop_Vectors.Vector;
         T     : Float) return Uint32
      is
      begin
         if Stops.Length = 0 then
            return 0;
         elsif Stops.Length = 1 then
            return Stops.First_Element.Color;
         end if;

         if T <= Stops.First_Element.Offset then
            return Stops.First_Element.Color;
         elsif T >= Stops.Last_Element.Offset then
            return Stops.Last_Element.Color;
         end if;

         for I in 1 .. Natural (Stops.Length) - 1 loop
            declare
               A : constant Color_Stop := Stops.Element (Positive (I));
               B : constant Color_Stop := Stops.Element (Positive (I + 1));
            begin
               if T >= A.Offset and then T <= B.Offset then
                  if abs (B.Offset - A.Offset) < 1.0E-6 then
                     return B.Color;
                  else
                     return Interpolate_Color (A.Color, B.Color, (T - A.Offset) / (B.Offset - A.Offset));
                  end if;
               end if;
            end;
         end loop;

         return Stops.Last_Element.Color;
      end Sample_Stops;

      function Resolve_Gradient
        (Id       : String;
         Stack    : in out Id_Vectors.Vector;
         Resolved : out Gradient_Def) return Boolean
      is
         Idx  : constant Natural := Find_Gradient_Index (Id);
         Base : Gradient_Def;
      begin
         if Idx = 0 then
            return False;
         end if;

         if In_Id_Stack (Stack, Id) then
            return False;
         end if;

         Resolved := Gradients.Element (Positive (Idx));

         if Resolved.Href /= US.Null_Unbounded_String then
            declare
               Ref : constant String := US.To_String (Resolved.Href);
               OK  : Boolean;
            begin
               Stack.Append (US.To_Unbounded_String (Id));
               OK := Resolve_Gradient (Ref, Stack, Base);
               Stack.Delete_Last;

               if OK then
                  if not Resolved.Has_Units then
                     Resolved.Units_Object_BBox := Base.Units_Object_BBox;
                  end if;
                  if not Resolved.Has_Spread then
                     Resolved.Spread := Base.Spread;
                  end if;
                  if not Resolved.Has_Transform then
                     Resolved.Transform := Base.Transform;
                  end if;
                  if not Resolved.Has_X1 then
                     Resolved.X1 := Base.X1;
                  end if;
                  if not Resolved.Has_Y1 then
                     Resolved.Y1 := Base.Y1;
                  end if;
                  if not Resolved.Has_X2 then
                     Resolved.X2 := Base.X2;
                  end if;
                  if not Resolved.Has_Y2 then
                     Resolved.Y2 := Base.Y2;
                  end if;
                  if not Resolved.Has_CX then
                     Resolved.CX := Base.CX;
                  end if;
                  if not Resolved.Has_CY then
                     Resolved.CY := Base.CY;
                  end if;
                  if not Resolved.Has_R then
                     Resolved.R := Base.R;
                  end if;
                  if not Resolved.Has_FX then
                     Resolved.FX := Base.FX;
                  end if;
                  if not Resolved.Has_FY then
                     Resolved.FY := Base.FY;
                  end if;
                  if Resolved.Stops.Length = 0 then
                     Resolved.Stops := Base.Stops;
                  end if;
               end if;
            end;
         end if;

         if Resolved.Stops.Length = 0 then
            Resolved.Stops.Append (Color_Stop'(Offset => 0.0, Color => Pack_ARGB (255, 0, 0, 0)));
            Resolved.Stops.Append (Color_Stop'(Offset => 1.0, Color => Pack_ARGB (255, 0, 0, 0)));
         end if;

         return True;
      end Resolve_Gradient;

      procedure Apply_Style_Property
        (Key   : String;
         Value : String;
         Style : in out Style_State)
      is
         K : constant String := Ch.To_Lower (Fix.Trim (Key, Ada.Strings.Both));
         V : constant String := Fix.Trim (Value, Ada.Strings.Both);
         L : constant String := Ch.To_Lower (V);
      begin
         if K = "fill" then
            Set_Paint_From_Text (V, Style.Fill_Paint);

         elsif K = "stroke" then
            Set_Paint_From_Text (V, Style.Stroke_Paint);

         elsif K = "stroke-width" then
            Style.Stroke_Width := Float'Max (0.0, Parse_Number (V, Style.Stroke_Width));

         elsif K = "stroke-linecap" then
            if L = "round" then
               Style.Stroke_Line_Cap := Adi.SVG.Renderer.Round_Cap;
            elsif L = "square" then
               Style.Stroke_Line_Cap := Adi.SVG.Renderer.Square_Cap;
            else
               Style.Stroke_Line_Cap := Adi.SVG.Renderer.Butt_Cap;
            end if;

         elsif K = "stroke-linejoin" then
            if L = "round" then
               Style.Stroke_Line_Join := Adi.SVG.Renderer.Round_Join;
            elsif L = "bevel" then
               Style.Stroke_Line_Join := Adi.SVG.Renderer.Bevel_Join;
            else
               Style.Stroke_Line_Join := Adi.SVG.Renderer.Miter_Join;
            end if;

         elsif K = "stroke-miterlimit" then
            Style.Stroke_Miter_Limit := Float'Max (1.0, Parse_Number (V, Style.Stroke_Miter_Limit));

         elsif K = "stroke-dasharray" then
            Parse_Dash_Array_Text (V, Style.Stroke_Dash_Array);

         elsif K = "stroke-dashoffset" then
            Style.Stroke_Dash_Offset := Parse_Length (V, Float'Min (SW, SH), Style.Stroke_Dash_Offset);

         elsif K = "opacity" then
            Style.Opacity := Adi.SVG.Parser.Clamp01 (Parse_Number (V, Style.Opacity));

         elsif K = "fill-opacity" then
            Style.Fill_Opacity :=
              Adi.SVG.Parser.Clamp01 (Parse_Number (V, Style.Fill_Opacity));

         elsif K = "stroke-opacity" then
            Style.Stroke_Opacity :=
              Adi.SVG.Parser.Clamp01 (Parse_Number (V, Style.Stroke_Opacity));

         elsif K = "display" then
            Style.Display_None := L = "none";

         elsif K = "visibility" then
            Style.Visibility_Hidden := L = "hidden" or else L = "collapse";

         elsif K = "fill-rule" then
            if L = "evenodd" then
               Style.Fill_Rule := Adi.SVG.Renderer.Even_Odd;
            else
               Style.Fill_Rule := Adi.SVG.Renderer.Non_Zero;
            end if;
         end if;
      end Apply_Style_Property;

      procedure Apply_Tag_State
        (Tag   : String;
         State : in out Render_State)
      is
         procedure Apply_Attr (Attr : String; Prop : String := "") is
            V : constant String := Attribute_Value (Tag, Attr);
            P : constant String := (if Prop'Length = 0 then Attr else Prop);
         begin
            if V'Length > 0 then
               Apply_Style_Property (P, V, State.Style);
            end if;
         end Apply_Attr;

         Style_Text : constant String := Attribute_Value (Tag, "style");
         T          : constant String := Attribute_Value (Tag, "transform");
      begin
         Apply_Attr ("fill");
         Apply_Attr ("stroke");
         Apply_Attr ("stroke-width");
         Apply_Attr ("stroke-linecap");
         Apply_Attr ("stroke-linejoin");
         Apply_Attr ("stroke-miterlimit");
         Apply_Attr ("stroke-dasharray");
         Apply_Attr ("stroke-dashoffset");
         Apply_Attr ("opacity");
         Apply_Attr ("fill-opacity");
         Apply_Attr ("stroke-opacity");
         Apply_Attr ("display");
         Apply_Attr ("visibility");
         Apply_Attr ("fill-rule");

         if Style_Text'Length > 0 then
            declare
               P : Integer := Style_Text'First;
            begin
               while P <= Style_Text'Last loop
                  declare
                     Semi : constant Natural := Fix.Index (Style_Text, ";", From => P);
                     Last : constant Integer :=
                       (if Semi = 0 then Style_Text'Last else Semi - 1);
                  begin
                     if Last >= P then
                        declare
                           Chunk : constant String :=
                             Fix.Trim (Style_Text (P .. Last), Ada.Strings.Both);
                           C : constant Natural := Fix.Index (Chunk, ":");
                        begin
                           if C > 0 then
                              Apply_Style_Property
                                (Chunk (Chunk'First .. C - 1),
                                 Chunk (C + 1 .. Chunk'Last),
                                 State.Style);
                           end if;
                        end;
                     end if;

                     exit when Semi = 0;
                     P := Integer (Semi) + 1;
                  end;
               end loop;
            end;
         end if;

         if T'Length > 0 then
            State.M :=
              Adi.SVG.Parser.Multiply_Matrix
                (State.M,
                 Adi.SVG.Parser.Parse_Transform (T));
         end if;

         if State.Style.Display_None or else State.Style.Visibility_Hidden then
            State.Hidden := True;
         end if;
      end Apply_Tag_State;

      procedure Add_Transformed_Point
        (C : in out Contour;
         M : Matrix;
         X : Float;
         Y : Float)
      is
         TX, TY : Float;
      begin
         Adi.SVG.Parser.Map_Point (M, X, Y, TX, TY);

         if C.Points.Length > 0 then
            declare
               Last_P : constant Point := C.Points.Last_Element;
            begin
               if abs (Last_P.X - TX) < Adi.SVG.Constants.Point_Epsilon
                 and then abs (Last_P.Y - TY) < Adi.SVG.Constants.Point_Epsilon
               then
                  return;
               end if;
            end;
         end if;

         C.Points.Append (Point'(X => TX, Y => TY));
      end Add_Transformed_Point;

      procedure Fill_Contours_Gradient
        (Contours       : Contour_Vectors.Vector;
         Rule           : Fill_Rule_Kind;
         Gradient       : Gradient_Def;
         State          : Render_State;
         Opacity_Factor : Float)
      is
         type Float_Array is array (Positive range <>) of Float;
         type Int_Array is array (Positive range <>) of Integer;

         B : constant Bounds_Record := Contours_Bounds (Contours);
         Min_Y : Float := 0.0;
         Max_Y : Float := 0.0;
         Have_Bounds : Boolean := False;
         Edge_Capacity : Natural := 0;

         Inv_State : Matrix := Adi.SVG.Parser.Identity_Matrix;
         Has_Inv_State : constant Boolean := Invert_Matrix (State.M, Inv_State);
         Inv_Grad : Matrix := Adi.SVG.Parser.Identity_Matrix;
         Has_Inv_Grad : constant Boolean :=
           (if Gradient.Has_Transform then Invert_Matrix (Gradient.Transform, Inv_Grad) else True);

         function Sample_At (X, Y : Float) return Uint32 is
            GX : Float := X;
            GY : Float := Y;
            BW : constant Float := B.Max_X - B.Min_X;
            BH : constant Float := B.Max_Y - B.Min_Y;
            T  : Float := 0.0;
         begin
            if not B.Valid then
               return 0;
            end if;

            if Gradient.Units_Object_BBox then
               if BW <= 1.0E-6 or else BH <= 1.0E-6 then
                  return 0;
               end if;
               GX := (X - B.Min_X) / BW;
               GY := (Y - B.Min_Y) / BH;
            else
               if not Has_Inv_State then
                  return 0;
               end if;
               Adi.SVG.Parser.Map_Point (Inv_State, X, Y, GX, GY);
            end if;

            if Gradient.Has_Transform then
               if not Has_Inv_Grad then
                  return 0;
               end if;
               Adi.SVG.Parser.Map_Point (Inv_Grad, GX, GY, GX, GY);
            end if;

            if Gradient.Kind = Linear_Gradient then
               declare
                  DX  : constant Float := Gradient.X2 - Gradient.X1;
                  DY  : constant Float := Gradient.Y2 - Gradient.Y1;
                  Den : constant Float := DX * DX + DY * DY;
               begin
                  if Den > 1.0E-9 then
                     T := ((GX - Gradient.X1) * DX + (GY - Gradient.Y1) * DY) / Den;
                  end if;
               end;
            else
               declare
                  FX : constant Float := (if Gradient.Has_FX then Gradient.FX else Gradient.CX);
                  FY : constant Float := (if Gradient.Has_FY then Gradient.FY else Gradient.CY);
                  RR : constant Float := abs Gradient.R;
               begin
                  if RR > 1.0E-9 then
                     T := Math.Sqrt ((GX - FX) * (GX - FX) + (GY - FY) * (GY - FY)) / RR;
                  end if;
               end;
            end if;

            T := Apply_Spread (T, Gradient.Spread);
            return Adi.SVG.Renderer.Apply_Opacity (Sample_Stops (Gradient.Stops, T), Opacity_Factor);
         end Sample_At;
      begin
         for C of Contours loop
            if Natural (C.Points.Length) >= 3 then
               Edge_Capacity := Edge_Capacity + Natural (C.Points.Length);
               for P of C.Points loop
                  if not Have_Bounds then
                     Min_Y := P.Y;
                     Max_Y := P.Y;
                     Have_Bounds := True;
                  else
                     Min_Y := Float'Min (Min_Y, P.Y);
                     Max_Y := Float'Max (Max_Y, P.Y);
                  end if;
               end loop;
            end if;
         end loop;

         if not Have_Bounds or else Edge_Capacity = 0 then
            return;
         end if;

         declare
            Inter_X : Float_Array (1 .. Positive (Edge_Capacity));
            Inter_W : Int_Array (1 .. Positive (Edge_Capacity));

            procedure Fill_Span (Scan : Integer; X1, X2 : Float) is
            begin
               if X2 <= X1 then
                  return;
               end if;

               for X in Integer (Float'Floor (X1)) .. Integer (Float'Ceiling (X2)) - 1 loop
                  declare
                     Color : constant Uint32 := Sample_At (Float (X) + 0.5, Float (Scan) + 0.5);
                  begin
                     if Color /= 0 then
                        Adi.SVG.Renderer.Blend_Pixel (Pixels.all, Render_W, Render_H, X, Scan, Color);
                     end if;
                  end;
               end loop;
            end Fill_Span;
         begin
            for Scan in Integer (Float'Floor (Min_Y)) .. Integer (Float'Ceiling (Max_Y)) - 1 loop
               declare
                  Y : constant Float := Float (Scan) + 0.5;
                  N : Natural := 0;
               begin
                  for C of Contours loop
                     declare
                        Count : constant Natural := Natural (C.Points.Length);
                     begin
                        if Count >= 3 then
                           for I in 1 .. Count loop
                              declare
                                 J  : constant Positive := (if I = Count then 1 else I + 1);
                                 P1 : constant Point := C.Points.Element (Positive (I));
                                 P2 : constant Point := C.Points.Element (J);
                                 Y1 : constant Float := P1.Y;
                                 Y2 : constant Float := P2.Y;
                              begin
                                 if (Y1 <= Y and then Y2 > Y) or else (Y2 <= Y and then Y1 > Y) then
                                    N := N + 1;
                                    Inter_X (N) := P1.X + (Y - Y1) * (P2.X - P1.X) / (Y2 - Y1);
                                    Inter_W (N) := (if Y2 > Y1 then 1 else -1);
                                 end if;
                              end;
                           end loop;
                        end if;
                     end;
                  end loop;

                  if N >= 2 then
                     for I in 1 .. N - 1 loop
                        for J in I + 1 .. N loop
                           if Inter_X (J) < Inter_X (I) then
                              declare
                                 TX : constant Float := Inter_X (I);
                                 TW : constant Integer := Inter_W (I);
                              begin
                                 Inter_X (I) := Inter_X (J);
                                 Inter_W (I) := Inter_W (J);
                                 Inter_X (J) := TX;
                                 Inter_W (J) := TW;
                              end;
                           end if;
                        end loop;
                     end loop;

                     if Rule = Adi.SVG.Renderer.Even_Odd then
                        declare
                           K : Natural := 1;
                        begin
                           while K + 1 <= N loop
                              Fill_Span (Scan, Inter_X (K), Inter_X (K + 1));
                              K := K + 2;
                           end loop;
                        end;
                     else
                        declare
                           Winding : Integer := 0;
                        begin
                           for I in 1 .. N - 1 loop
                              Winding := Winding + Inter_W (I);
                              if Winding /= 0 then
                                 Fill_Span (Scan, Inter_X (I), Inter_X (I + 1));
                              end if;
                           end loop;
                        end;
                     end if;
                  end if;
               end;
            end loop;
         end;
      end Fill_Contours_Gradient;

      procedure Stroke_Contours_Gradient
        (Contours       : Contour_Vectors.Vector;
         Gradient       : Gradient_Def;
         State          : Render_State;
         Stroke_Width   : Float;
         Opacity_Factor : Float)
      is
         B : constant Bounds_Record := Contours_Bounds (Contours);

         Inv_State : Matrix := Adi.SVG.Parser.Identity_Matrix;
         Has_Inv_State : constant Boolean := Invert_Matrix (State.M, Inv_State);
         Inv_Grad : Matrix := Adi.SVG.Parser.Identity_Matrix;
         Has_Inv_Grad : constant Boolean :=
           (if Gradient.Has_Transform then Invert_Matrix (Gradient.Transform, Inv_Grad) else True);

         Mask : Pixel_Buffer_Access :=
           new Pixel_Buffer (0 .. Render_W * Render_H - 1);

         function Sample_At (X, Y : Float) return Uint32 is
            GX : Float := X;
            GY : Float := Y;
            BW : constant Float := B.Max_X - B.Min_X;
            BH : constant Float := B.Max_Y - B.Min_Y;
            T  : Float := 0.0;
         begin
            if not B.Valid then
               return 0;
            end if;

            if Gradient.Units_Object_BBox then
               if BW <= 1.0E-6 or else BH <= 1.0E-6 then
                  return 0;
               end if;
               GX := (X - B.Min_X) / BW;
               GY := (Y - B.Min_Y) / BH;
            else
               if not Has_Inv_State then
                  return 0;
               end if;
               Adi.SVG.Parser.Map_Point (Inv_State, X, Y, GX, GY);
            end if;

            if Gradient.Has_Transform then
               if not Has_Inv_Grad then
                  return 0;
               end if;
               Adi.SVG.Parser.Map_Point (Inv_Grad, GX, GY, GX, GY);
            end if;

            if Gradient.Kind = Linear_Gradient then
               declare
                  DX  : constant Float := Gradient.X2 - Gradient.X1;
                  DY  : constant Float := Gradient.Y2 - Gradient.Y1;
                  Den : constant Float := DX * DX + DY * DY;
               begin
                  if Den > 1.0E-9 then
                     T := ((GX - Gradient.X1) * DX + (GY - Gradient.Y1) * DY) / Den;
                  end if;
               end;
            else
               declare
                  FX : constant Float := (if Gradient.Has_FX then Gradient.FX else Gradient.CX);
                  FY : constant Float := (if Gradient.Has_FY then Gradient.FY else Gradient.CY);
                  RR : constant Float := abs Gradient.R;
               begin
                  if RR > 1.0E-9 then
                     T := Math.Sqrt ((GX - FX) * (GX - FX) + (GY - FY) * (GY - FY)) / RR;
                  end if;
               end;
            end if;

            T := Apply_Spread (T, Gradient.Spread);
            return Adi.SVG.Renderer.Apply_Opacity (Sample_Stops (Gradient.Stops, T), Opacity_Factor);
         end Sample_At;
      begin
         if not B.Valid or else Stroke_Width <= 0.0 then
            Free_Pixel_Buffer (Mask);
            return;
         end if;

         for I in Mask'Range loop
            Mask (I) := 0;
         end loop;

         Adi.SVG.Renderer.Stroke_Contours
           (Pixels       => Mask.all,
            Width        => Render_W,
            Height       => Render_H,
            Contours     => Contours,
            Stroke       => Pack_ARGB (255, 255, 255, 255),
            Stroke_Width => Stroke_Width,
            Line_Cap     => State.Style.Stroke_Line_Cap,
            Line_Join    => State.Style.Stroke_Line_Join,
            Miter_Limit  => State.Style.Stroke_Miter_Limit,
            Dash_Array   => State.Style.Stroke_Dash_Array,
            Dash_Offset  => State.Style.Stroke_Dash_Offset);

         for I in Mask'Range loop
            declare
               A_M, R_M, G_M, B_M : Interfaces.Unsigned_8;
            begin
               Adi.SVG.Renderer.Unpack_ARGB (Mask (I), A_M, R_M, G_M, B_M);

               if A_M /= 0 then
                  declare
                     X : constant Integer := Integer (I mod Render_W);
                     Y : constant Integer := Integer (I / Render_W);
                     G_Color : constant Uint32 := Sample_At (Float (X) + 0.5, Float (Y) + 0.5);
                     GA, GR, GG, GB : Interfaces.Unsigned_8;
                  begin
                     if G_Color /= 0 then
                        Adi.SVG.Renderer.Unpack_ARGB (G_Color, GA, GR, GG, GB);

                        if GA /= 0 then
                           declare
                              Out_A : constant Interfaces.Unsigned_8 :=
                                To_U8 ((Integer (GA) * Integer (A_M) + 127) / 255);
                           begin
                              if Out_A /= 0 then
                                 Adi.SVG.Renderer.Blend_Pixel
                                   (Pixels.all,
                                    Render_W,
                                    Render_H,
                                    X,
                                    Y,
                                    Pack_ARGB (Out_A, GR, GG, GB));
                              end if;
                           end;
                        end if;
                     end if;
                  end;
               end if;
            end;
         end loop;

         Free_Pixel_Buffer (Mask);
      exception
         when others =>
            if Mask /= null then
               Free_Pixel_Buffer (Mask);
            end if;
            raise;
      end Stroke_Contours_Gradient;

      procedure Draw_Contours
        (Contours : Contour_Vectors.Vector;
         State    : Render_State)
      is
         Fill_Alpha   : constant Float := State.Style.Opacity * State.Style.Fill_Opacity;
         Stroke_Alpha : constant Float := State.Style.Opacity * State.Style.Stroke_Opacity;
         Stroke_W : constant Float :=
           Float'Max (0.0, State.Style.Stroke_Width * Adi.SVG.Parser.Matrix_Scale (State.M));
         Gradient : Gradient_Def;
         G_Stack  : Id_Vectors.Vector;
      begin
         if State.Style.Fill_Paint.Kind = Solid_Paint then
            declare
               Fill_Color : constant Uint32 :=
                 Adi.SVG.Renderer.Apply_Opacity (State.Style.Fill_Paint.Color, Fill_Alpha);
            begin
               if Fill_Color /= 0 then
                  Adi.SVG.Renderer.Fill_Contours
                    (Pixels   => Pixels.all,
                     Width    => Render_W,
                     Height   => Render_H,
                     Contours => Contours,
                     Rule     => State.Style.Fill_Rule,
                     Fill     => Fill_Color);
               end if;
            end;
         elsif State.Style.Fill_Paint.Kind = Gradient_Paint then
            if Resolve_Gradient (US.To_String (State.Style.Fill_Paint.Ref_Id), G_Stack, Gradient) then
               Fill_Contours_Gradient (Contours, State.Style.Fill_Rule, Gradient, State, Fill_Alpha);
            else
               declare
                  Fallback : constant Uint32 :=
                    Adi.SVG.Renderer.Apply_Opacity (State.Style.Fill_Paint.Color, Fill_Alpha);
               begin
                  if Fallback /= 0 then
                     Adi.SVG.Renderer.Fill_Contours
                       (Pixels   => Pixels.all,
                        Width    => Render_W,
                        Height   => Render_H,
                        Contours => Contours,
                        Rule     => State.Style.Fill_Rule,
                        Fill     => Fallback);
                  end if;
               end;
            end if;
         end if;

         if Stroke_W > 0.0 and then State.Style.Stroke_Paint.Kind /= No_Paint then
            if State.Style.Stroke_Paint.Kind = Gradient_Paint then
               if Resolve_Gradient (US.To_String (State.Style.Stroke_Paint.Ref_Id), G_Stack, Gradient) then
                  Stroke_Contours_Gradient
                    (Contours       => Contours,
                     Gradient       => Gradient,
                     State          => State,
                     Stroke_Width   => Stroke_W,
                     Opacity_Factor => Stroke_Alpha);
               else
                  declare
                     Fallback : constant Uint32 :=
                       Adi.SVG.Renderer.Apply_Opacity (State.Style.Stroke_Paint.Color, Stroke_Alpha);
                  begin
                     if Fallback /= 0 then
                        Adi.SVG.Renderer.Stroke_Contours
                          (Pixels       => Pixels.all,
                           Width        => Render_W,
                           Height       => Render_H,
                           Contours     => Contours,
                           Stroke       => Fallback,
                           Stroke_Width => Stroke_W,
                           Line_Cap     => State.Style.Stroke_Line_Cap,
                           Line_Join    => State.Style.Stroke_Line_Join,
                           Miter_Limit  => State.Style.Stroke_Miter_Limit,
                           Dash_Array   => State.Style.Stroke_Dash_Array,
                           Dash_Offset  => State.Style.Stroke_Dash_Offset);
                     end if;
                  end;
               end if;
            else
               declare
                  Stroke_Color : constant Uint32 :=
                    Adi.SVG.Renderer.Apply_Opacity (State.Style.Stroke_Paint.Color, Stroke_Alpha);
               begin
                  if Stroke_Color /= 0 then
                     Adi.SVG.Renderer.Stroke_Contours
                       (Pixels       => Pixels.all,
                        Width        => Render_W,
                        Height       => Render_H,
                        Contours     => Contours,
                        Stroke       => Stroke_Color,
                        Stroke_Width => Stroke_W,
                        Line_Cap     => State.Style.Stroke_Line_Cap,
                        Line_Join    => State.Style.Stroke_Line_Join,
                        Miter_Limit  => State.Style.Stroke_Miter_Limit,
                        Dash_Array   => State.Style.Stroke_Dash_Array,
                        Dash_Offset  => State.Style.Stroke_Dash_Offset);
                  end if;
               end;
            end if;
         end if;
      end Draw_Contours;

      procedure Draw_Contour
        (C     : Contour;
         State : Render_State)
      is
         Contours : Contour_Vectors.Vector;
      begin
         Contours.Append (C);
         Draw_Contours (Contours, State);
      end Draw_Contour;

      procedure Draw_Path_Tag
        (Tag_Pos : Natural;
         Tag   : String;
         State : Render_State)
      is
         D        : constant String := Attribute_Value (Tag, "d");
         Contours : Contour_Vectors.Vector;
      begin
         if D'Length = 0 then
            return;
         end if;

         if Doc_Cache = null
           or else not Adi.SVG.Ada_Cache.Find_Path_Contours
             (Obj      => Doc_Cache.all,
              Path_Pos => Tag_Pos,
              D        => D,
              M        => State.M,
              Contours => Contours)
         then
            Contours := Adi.SVG.Parser.Build_Path_Contours (D, State.M);

            if Doc_Cache /= null then
               Adi.SVG.Ada_Cache.Store_Path_Contours
                 (Obj      => Doc_Cache.all,
                  Path_Pos => Tag_Pos,
                  D        => D,
                  M        => State.M,
                  Contours => Contours);
            end if;
         end if;

         Draw_Contours (Contours, State);
      end Draw_Path_Tag;

      procedure Draw_Points_Tag
        (Tag    : String;
         State  : Render_State;
         Closed : Boolean)
      is
         Data : constant String := Attribute_Value (Tag, "points");
         C    : Contour;
         Pos  : Integer := Data'First;
         X, Y : Float;
      begin
         if Data'Length = 0 then
            return;
         end if;

         while Has_Number_At (Data, Pos) loop
            exit when not Read_Number_At (Data, Pos, X);
            exit when not Read_Number_At (Data, Pos, Y);
            Add_Transformed_Point (C, State.M, X, Y);
         end loop;

         C.Closed := Closed;
         Draw_Contour (C, State);
      end Draw_Points_Tag;

      procedure Draw_Rect_Tag
        (Tag   : String;
         State : Render_State)
      is
         X : constant Float := Parse_Length (Attribute_Value (Tag, "x"), SW, 0.0);
         Y : constant Float := Parse_Length (Attribute_Value (Tag, "y"), SH, 0.0);
         W : constant Float := Parse_Length (Attribute_Value (Tag, "width"), SW, 0.0);
         H : constant Float := Parse_Length (Attribute_Value (Tag, "height"), SH, 0.0);
         C : Contour;
      begin
         if W <= 0.0 or else H <= 0.0 then
            return;
         end if;

         Add_Transformed_Point (C, State.M, X, Y);
         Add_Transformed_Point (C, State.M, X + W, Y);
         Add_Transformed_Point (C, State.M, X + W, Y + H);
         Add_Transformed_Point (C, State.M, X, Y + H);
         C.Closed := True;
         Draw_Contour (C, State);
      end Draw_Rect_Tag;

      procedure Draw_Line_Tag
        (Tag   : String;
         State : Render_State)
      is
         X1 : constant Float := Parse_Length (Attribute_Value (Tag, "x1"), SW, 0.0);
         Y1 : constant Float := Parse_Length (Attribute_Value (Tag, "y1"), SH, 0.0);
         X2 : constant Float := Parse_Length (Attribute_Value (Tag, "x2"), SW, 0.0);
         Y2 : constant Float := Parse_Length (Attribute_Value (Tag, "y2"), SH, 0.0);
         C : Contour;
      begin
         Add_Transformed_Point (C, State.M, X1, Y1);
         Add_Transformed_Point (C, State.M, X2, Y2);
         Draw_Contour (C, State);
      end Draw_Line_Tag;

      procedure Draw_Circle_Tag
        (Tag   : String;
         State : Render_State)
      is
         Segs   : constant Positive := Adi.SVG.Constants.Circle_Segment_Count;
         Two_Pi : constant Float := Adi.SVG.Constants.Full_Circle_Radians;
         CX0    : constant Float := Parse_Length (Attribute_Value (Tag, "cx"), SW, 0.0);
         CY0    : constant Float := Parse_Length (Attribute_Value (Tag, "cy"), SH, 0.0);
         R0     : constant Float :=
           Parse_Length (Attribute_Value (Tag, "r"), Float'Min (SW, SH), 0.0);
         C      : Contour;
      begin
         if R0 <= 0.0 then
            return;
         end if;

         for I in 0 .. Segs - 1 loop
            declare
               A : constant Float := Two_Pi * Float (I) / Float (Segs);
               X : constant Float := CX0 + R0 * Math.Cos (A);
               Y : constant Float := CY0 + R0 * Math.Sin (A);
            begin
               Add_Transformed_Point (C, State.M, X, Y);
            end;
         end loop;

         C.Closed := True;
         Draw_Contour (C, State);
      end Draw_Circle_Tag;

      procedure Draw_Ellipse_Tag
        (Tag   : String;
         State : Render_State)
      is
         Segs   : constant Positive := Adi.SVG.Constants.Circle_Segment_Count;
         Two_Pi : constant Float := Adi.SVG.Constants.Full_Circle_Radians;
         CX0    : constant Float := Parse_Length (Attribute_Value (Tag, "cx"), SW, 0.0);
         CY0    : constant Float := Parse_Length (Attribute_Value (Tag, "cy"), SH, 0.0);
         RX0    : constant Float := Parse_Length (Attribute_Value (Tag, "rx"), SW, 0.0);
         RY0    : constant Float := Parse_Length (Attribute_Value (Tag, "ry"), SH, 0.0);
         C      : Contour;
      begin
         if RX0 <= 0.0 or else RY0 <= 0.0 then
            return;
         end if;

         for I in 0 .. Segs - 1 loop
            declare
               A : constant Float := Two_Pi * Float (I) / Float (Segs);
               X : constant Float := CX0 + RX0 * Math.Cos (A);
               Y : constant Float := CY0 + RY0 * Math.Sin (A);
            begin
               Add_Transformed_Point (C, State.M, X, Y);
            end;
         end loop;

         C.Closed := True;
         Draw_Contour (C, State);
      end Draw_Ellipse_Tag;

      function Next_Token
        (S   : String;
         Pos : in out Integer) return String
      is
         Start : Integer;
      begin
         while Pos <= S'Last and then Adi.SVG.Parser.Is_WS (S (Pos)) loop
            Pos := Pos + 1;
         end loop;

         if Pos > S'Last then
            return "";
         end if;

         Start := Pos;
         while Pos <= S'Last and then not Adi.SVG.Parser.Is_WS (S (Pos)) loop
            Pos := Pos + 1;
         end loop;

         return Ch.To_Lower (S (Start .. Pos - 1));
      end Next_Token;

      procedure Parse_Preserve_Aspect_Ratio
        (PAR_Text   : String;
         Align_None : out Boolean;
         Align_X    : out Float;
         Align_Y    : out Float;
         Use_Slice  : out Boolean)
      is
         P : Integer := PAR_Text'First;
         T1 : constant String := Next_Token (PAR_Text, P);
         T2 : constant String := Next_Token (PAR_Text, P);
         T3 : constant String := Next_Token (PAR_Text, P);
         Align_Token : constant String := (if T1 = "defer" then T2 else T1);
         Mode_Token  : constant String := (if T1 = "defer" then T3 else T2);
      begin
         Align_None := False;
         Align_X := 0.5;
         Align_Y := 0.5;
         Use_Slice := False;

         if Align_Token = "none" then
            Align_None := True;
            return;
         end if;

         if Align_Token'Length > 0 then
            if Fix.Index (Align_Token, "xmax") = 1 then
               Align_X := 1.0;
            elsif Fix.Index (Align_Token, "xmin") = 1 then
               Align_X := 0.0;
            end if;

            if Fix.Index (Align_Token, "ymax") > 0 then
               Align_Y := 1.0;
            elsif Fix.Index (Align_Token, "ymin") > 0 then
               Align_Y := 0.0;
            end if;
         end if;

         Use_Slice := Mode_Token = "slice";
      end Parse_Preserve_Aspect_Ratio;

      function ViewBox_To_Viewport_Transform
        (Min_X      : Float;
         Min_Y      : Float;
         ViewBox_W  : Float;
         ViewBox_H  : Float;
         Viewport_W : Float;
         Viewport_H : Float;
         PAR_Text   : String) return Matrix
      is
         SX : Float := Viewport_W / ViewBox_W;
         SY : Float := Viewport_H / ViewBox_H;
         TX : Float := -Min_X * SX;
         TY : Float := -Min_Y * SY;
         Align_None : Boolean := False;
         Align_X : Float := 0.5;
         Align_Y : Float := 0.5;
         Use_Slice : Boolean := False;
      begin
         Parse_Preserve_Aspect_Ratio (PAR_Text, Align_None, Align_X, Align_Y, Use_Slice);

         if not Align_None then
            declare
               S : constant Float :=
                 (if Use_Slice then Float'Max (SX, SY) else Float'Min (SX, SY));
            begin
               SX := S;
               SY := S;
               TX := -Min_X * SX + (Viewport_W - ViewBox_W * SX) * Align_X;
               TY := -Min_Y * SY + (Viewport_H - ViewBox_H * SY) * Align_Y;
            end;
         end if;

         return (A => SX, B => 0.0, C => 0.0, D => SY, E => TX, F => TY);
      end ViewBox_To_Viewport_Transform;

      procedure Render_Range
         (Source      : String;
          Start_Pos   : Natural;
          End_Pos     : Natural;
          Root_State  : Render_State;
          Use_Stack   : in out Id_Vectors.Vector;
          Allow_Start_Symbol : Boolean := False);

      procedure Draw_Use_Tag
        (Source    : String;
         Tag       : String;
         State     : Render_State;
         Use_Stack : in out Id_Vectors.Vector)
      is
         Href_1 : constant String := Attribute_Value (Tag, "href");
         Href_2 : constant String := Attribute_Value (Tag, "xlink:href");
         Href   : constant String := (if Href_1'Length > 0 then Href_1 else Href_2);
         Ref_Id : constant String := Extract_Ref_Id (Href);
         X      : constant Float := Parse_Length (Attribute_Value (Tag, "x"), SW, 0.0);
         Y      : constant Float := Parse_Length (Attribute_Value (Tag, "y"), SH, 0.0);
         Use_W  : constant Float := Parse_Length (Attribute_Value (Tag, "width"), SW, -1.0);
         Use_H  : constant Float := Parse_Length (Attribute_Value (Tag, "height"), SH, -1.0);
         Use_PAR : constant String := Attribute_Value (Tag, "preserveAspectRatio");
         Idx    : constant Natural := Find_Element_Index (Ref_Id);
         Use_State : Render_State := State;
      begin
         if Ref_Id'Length = 0 or else Idx = 0 then
            return;
         end if;

         if In_Id_Stack (Use_Stack, Ref_Id) then
            return;
         end if;

         Use_Stack.Append (US.To_Unbounded_String (Ref_Id));
         declare
            E : constant Element_Def := Elements.Element (Positive (Idx));
            Target_Is_Symbol : constant Boolean := US.To_String (E.Name) = "symbol";
            Use_Transform : Matrix :=
              (A => 1.0, B => 0.0, C => 0.0, D => 1.0, E => X, F => Y);
           begin
            if Target_Is_Symbol then
               declare
                  Open_GT : constant Natural :=
                    Adi.SVG.Parser.Find_Tag_End (Source, Positive (E.Open_LT + 1));
               begin
                  if Open_GT > E.Open_LT then
                     declare
                        Symbol_Tag : constant String := Source (E.Open_LT + 1 .. Open_GT - 1);
                        VB_Text    : constant String := Attribute_Value (Symbol_Tag, "viewBox");
                        Symbol_PAR : constant String := Attribute_Value (Symbol_Tag, "preserveAspectRatio");
                        PAR_Text   : constant String :=
                          (if Use_PAR'Length > 0 then Use_PAR else Symbol_PAR);
                        P          : Integer := VB_Text'First;
                        Min_X      : Float := 0.0;
                        Min_Y      : Float := 0.0;
                        VBW        : Float := 0.0;
                        VBH        : Float := 0.0;
                     begin
                        if VB_Text'Length > 0
                          and then Read_Number_At (VB_Text, P, Min_X)
                          and then Read_Number_At (VB_Text, P, Min_Y)
                          and then Read_Number_At (VB_Text, P, VBW)
                          and then Read_Number_At (VB_Text, P, VBH)
                          and then VBW > 1.0E-6
                         and then VBH > 1.0E-6
                        then
                           declare
                              Final_W : constant Float :=
                                (if Use_W > 0.0 then Use_W else VBW);
                              Final_H : constant Float :=
                                (if Use_H > 0.0 then Use_H else VBH);
                              VB_M : constant Matrix :=
                                ViewBox_To_Viewport_Transform
                                  (Min_X,
                                   Min_Y,
                                   VBW,
                                   VBH,
                                   Final_W,
                                   Final_H,
                                   PAR_Text);
                           begin
                              Use_Transform :=
                                Adi.SVG.Parser.Multiply_Matrix
                                  (Use_Transform, VB_M);
                           end;
                        end if;
                     end;
                  end if;
               end;
            end if;

            Use_State.M := Adi.SVG.Parser.Multiply_Matrix (Use_State.M, Use_Transform);

            Render_Range
              (Source,
               E.Open_LT,
               E.End_GT,
               Use_State,
               Use_Stack,
               Allow_Start_Symbol => Target_Is_Symbol);
          end;
          Use_Stack.Delete_Last;
       end Draw_Use_Tag;

      procedure Render_Range
         (Source      : String;
          Start_Pos   : Natural;
          End_Pos     : Natural;
          Root_State  : Render_State;
          Use_Stack   : in out Id_Vectors.Vector;
          Allow_Start_Symbol : Boolean := False)
      is
         States : State_Vectors.Vector;
         Pos    : Integer := Integer (Start_Pos);
      begin
         States.Append (Root_State);

         while Pos <= Integer (End_Pos) loop
            declare
               L : constant Natural := Fix.Index (Source, "<", From => Pos);
            begin
               exit when L = 0 or else L > End_Pos;

               if L + 1 <= Source'Last and then Source (L + 1) = '!' then
                  if L + 3 <= Source'Last and then Source (L + 2 .. L + 3) = "--" then
                     declare
                        C_End : constant Natural := Fix.Index (Source, "-->", From => L + 4);
                     begin
                        exit when C_End = 0;
                        Pos := Integer (C_End) + 3;
                     end;
                  else
                     declare
                        R0 : constant Natural := Fix.Index (Source, ">", From => L + 2);
                     begin
                        exit when R0 = 0;
                        Pos := Integer (R0) + 1;
                     end;
                  end if;

               elsif L + 1 <= Source'Last and then Source (L + 1) = '?' then
                  declare
                     Q_End : constant Natural := Fix.Index (Source, "?>", From => L + 2);
                  begin
                     exit when Q_End = 0;
                     Pos := Integer (Q_End) + 2;
                  end;

               else
                  declare
                     R : constant Natural := Adi.SVG.Parser.Find_Tag_End (Source, Positive (L + 1));
                  begin
                     exit when R = 0;

                     declare
                        Tag  : constant String := Source (L + 1 .. R - 1);
                        Name : constant String := Adi.SVG.Parser.Tag_Name (Tag);
                     begin
                        if Name'Length > 0 then
                           if Adi.SVG.Parser.Is_Closing_Tag (Tag) then
                              if Adi.SVG.Parser.Is_Container_Name (Name)
                                and then States.Length > 1
                              then
                                 States.Delete_Last;
                              end if;
                           else
                              declare
                                 State : Render_State := States.Last_Element;
                              begin
                                 Apply_Tag_State (Tag, State);

                                 if Name = "defs" then
                                    State.Hidden := True;
                                 elsif Name = "symbol"
                                   and then not (Allow_Start_Symbol and then L = Start_Pos)
                                 then
                                    State.Hidden := True;
                                 end if;

                                 if not State.Hidden then
                                    if Name = "path" then
                                       Draw_Path_Tag (L, Tag, State);
                                    elsif Name = "line" then
                                       Draw_Line_Tag (Tag, State);
                                    elsif Name = "rect" then
                                       Draw_Rect_Tag (Tag, State);
                                    elsif Name = "circle" then
                                       Draw_Circle_Tag (Tag, State);
                                    elsif Name = "ellipse" then
                                       Draw_Ellipse_Tag (Tag, State);
                                    elsif Name = "polygon" then
                                       Draw_Points_Tag (Tag, State, Closed => True);
                                    elsif Name = "polyline" then
                                       Draw_Points_Tag (Tag, State, Closed => False);
                                    elsif Name = "use" then
                                       Draw_Use_Tag (Source, Tag, State, Use_Stack);
                                    end if;
                                 end if;

                                 if Adi.SVG.Parser.Is_Container_Name (Name)
                                   and then not Adi.SVG.Parser.Is_Self_Closing_Tag (Tag)
                                 then
                                    States.Append (State);
                                 end if;
                              end;
                           end if;
                        end if;
                     end;

                     Pos := Integer (R) + 1;
                  end;
               end if;
            end;
         end loop;
      end Render_Range;

   begin
      if not Is_Valid (Doc) then
         return null;
      end if;

      if Doc_Cache /= null
        and then Adi.SVG.Ada_Cache.Find_Render_Buffer
          (Obj      => Doc_Cache.all,
           Width    => Width,
           Height   => Height,
           AA_Scale => AA_Scale,
           Pixels   => Pixels)
      then
         return Pixels;
      end if;

      Pixels := new Pixel_Buffer (0 .. Render_W * Render_H - 1);

      for K in Pixels'Range loop
         Pixels (K) := 16#00000000#;
      end loop;

      declare
         S : String renames Doc.Source.all;

         Root_M : Matrix :=
           (A => Float (Render_W) / SW,
            B => 0.0,
            C => 0.0,
            D => Float (Render_H) / SH,
            E => 0.0,
            F => 0.0);

         Svg_Open : Natural := Fix.Index (S, "<svg");

         Root : Render_State :=
           (Style  =>
              (Fill_Paint         =>
                 (Kind => Solid_Paint,
                  Color => Pack_ARGB (255, 0, 0, 0),
                  Ref_Id => US.Null_Unbounded_String),
               Stroke_Paint       =>
                 (Kind => No_Paint,
                  Color => 0,
                  Ref_Id => US.Null_Unbounded_String),
               Stroke_Width       => 1.0,
               Stroke_Line_Cap    => Adi.SVG.Renderer.Butt_Cap,
               Stroke_Line_Join   => Adi.SVG.Renderer.Miter_Join,
               Stroke_Miter_Limit => 4.0,
               Stroke_Dash_Array  => Adi.SVG.Renderer.Dash_Vectors.Empty_Vector,
               Stroke_Dash_Offset => 0.0,
               Opacity            => 1.0,
               Fill_Opacity       => 1.0,
               Stroke_Opacity     => 1.0,
                Fill_Rule          => Adi.SVG.Renderer.Non_Zero,
                Display_None       => False,
                Visibility_Hidden  => False),
            M      => Root_M,
            Hidden => False);

         Use_Stack : Id_Vectors.Vector;
      begin
         if Svg_Open = 0 then
            Svg_Open := Fix.Index (S, "<SVG");
         end if;

         if Svg_Open > 0 then
            declare
               Svg_Close : constant Natural :=
                 Adi.SVG.Parser.Find_Tag_End (S, Positive (Svg_Open + 1));
            begin
               if Svg_Close > Svg_Open then
                  declare
                     Svg_Tag : constant String := S (Svg_Open + 1 .. Svg_Close - 1);
                     VB_Text : constant String := Attribute_Value (Svg_Tag, "viewBox");
                     PAR_Text : constant String := Attribute_Value (Svg_Tag, "preserveAspectRatio");
                     P : Integer := VB_Text'First;
                     Min_X : Float := 0.0;
                     Min_Y : Float := 0.0;
                     VBW : Float := 0.0;
                     VBH : Float := 0.0;
                  begin
                     if VB_Text'Length > 0
                       and then Read_Number_At (VB_Text, P, Min_X)
                       and then Read_Number_At (VB_Text, P, Min_Y)
                       and then Read_Number_At (VB_Text, P, VBW)
                       and then Read_Number_At (VB_Text, P, VBH)
                       and then VBW > 1.0E-6
                       and then VBH > 1.0E-6
                     then
                        Root_M :=
                          ViewBox_To_Viewport_Transform
                            (Min_X,
                             Min_Y,
                             VBW,
                             VBH,
                             Float (Render_W),
                             Float (Render_H),
                             PAR_Text);
                     end if;
                  end;
               end if;
            end;
         end if;

         Root.M := Root_M;

         Collect_Definitions (S);
         Render_Range (S, S'First, S'Last, Root, Use_Stack);
      end;

      if AA_Scale = 1 then
         if Doc_Cache /= null then
            Adi.SVG.Ada_Cache.Store_Render_Buffer
              (Obj      => Doc_Cache.all,
               Width    => Width,
               Height   => Height,
               AA_Scale => AA_Scale,
               Pixels   => Pixels);
         end if;

         return Pixels;
      else
         declare
            Out_Pixels : constant Pixel_Buffer_Access :=
              Adi.SVG.Renderer.Downsample
                (Source        => Pixels,
                 Source_Width  => Render_W,
                 Source_Height => Render_H,
                 Target_Width  => Width,
                 Target_Height => Height,
                 Scale         => AA_Scale);
         begin
            Free_Pixel_Buffer (Pixels);

            if Doc_Cache /= null and then Out_Pixels /= null then
               Adi.SVG.Ada_Cache.Store_Render_Buffer
                 (Obj      => Doc_Cache.all,
                  Width    => Width,
                  Height   => Height,
                  AA_Scale => AA_Scale,
                  Pixels   => Out_Pixels);
            end if;

            return Out_Pixels;
         end;
      end if;

   exception
      when others =>
         if Pixels /= null then
            Free_Pixel_Buffer (Pixels);
         end if;
         raise;
   end Render_ARGB32;

   procedure Destroy (Doc : in out Document) is
      Cache : Adi.SVG.Ada_Cache.Cache_Access := To_Cache_Access (Doc.Handle);
      use type Adi.SVG.Ada_Cache.Cache_Access;
   begin
      if Cache /= null then
         Adi.SVG.Ada_Cache.Destroy (Cache);
      end if;

      if Doc.Source /= null then
         Free_String (Doc.Source);
      end if;
      Doc.Handle := System.Null_Address;
      Doc.Valid := False;
      Doc.Width := 0.0;
      Doc.Height := 0.0;
   end Destroy;

   function Backend_Name return String is
   begin
      return "ada";
   end Backend_Name;

end Adi.SVG;
