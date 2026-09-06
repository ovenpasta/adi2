--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Containers.Hashed_Maps;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Log;

package body Adi.CSS_Styles is

   package Char renames Ada.Characters.Handling;

   Current_Resolver : Font_Name_Resolver := null;

   procedure Set_Font_Name_Resolver (Resolver : Font_Name_Resolver) is
   begin
      Current_Resolver := Resolver;
   end Set_Font_Name_Resolver;

   -------------------------------------------------
   -- Text store
   -------------------------------------------------

   --  One character blob, one span per entry, and an index from the
   --  text to its id, so interning text already held is a hash rather
   --  than a walk over the spans.
   type Text_Span is record
      First  : Positive := 1;
      Length : Natural  := 0;
   end record;

   package Span_Vectors is new Ada.Containers.Vectors (Positive, Text_Span);

   package Text_Index_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => CSS_Text_Id,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   Text_Chars : Unbounded_String;
   Text_Spans : Span_Vectors.Vector;
   Text_Index : Text_Index_Maps.Map;

   --  One entry per distinct text, never released: the store grows
   --  with the vocabulary an application names, not with how often it
   --  names it.
   function Intern_Text (Text : String) return CSS_Text_Id is
      use Text_Index_Maps;
   begin
      if Text'Length = 0 then
         return No_CSS_Text;
      end if;

      if Text'Length > Max_CSS_Text_Length then
         Adi.Log.Warning
           ("CSS text of" & Natural'Image (Text'Length)
            & " characters exceeds the" & Natural'Image (Max_CSS_Text_Length)
            & " a style value carries, and is dropped: "
            & Text (Text'First .. Text'First + 39) & "...");
         return No_CSS_Text;
      end if;

      declare
         C : constant Cursor := Text_Index.Find (Text);
      begin
         if Has_Element (C) then
            return Element (C);
         end if;
      end;

      Append (Text_Chars, Text);
      Text_Spans.Append
        (Text_Span'(First  => Length (Text_Chars) - Text'Length + 1,
                    Length => Text'Length));

      declare
         Id : constant CSS_Text_Id := CSS_Text_Id (Text_Spans.Last_Index);
      begin
         Text_Index.Insert (Text, Id);
         return Id;
      end;
   end Intern_Text;

   function Interned_Texts return Natural is (Text_Spans.Last_Index);

   --  The characters, once in the blob and once as the index's key, plus
   --  a span and an id per string. Container and allocator overhead is
   --  not in it.
   function Interned_Text_Bytes return Natural is
     (2 * Length (Text_Chars)
      + Text_Spans.Last_Index
        * (Text_Span'Max_Size_In_Storage_Elements
           + CSS_Text_Id'Max_Size_In_Storage_Elements));

   function Text_Of (Id : CSS_Text_Id) return String is
   begin
      if Id = No_CSS_Text
        or else Natural (Id) > Text_Spans.Last_Index
      then
         return "";
      end if;

      declare
         Span : constant Text_Span := Text_Spans.Element (Positive (Id));
      begin
         return Slice (Text_Chars, Span.First, Span.First + Span.Length - 1);
      end;
   end Text_Of;

   -------------------------------------------------
   -- Values built over interned text
   -------------------------------------------------

   function Background_Image_URL (URI : String) return Background_Image_Value is
      Id : constant CSS_Text_Id := Intern_Text (URI);
   begin
      if Id = No_CSS_Text then
         return (Kind => No_Image);
      end if;
      return (Kind => Url_Image, URI => Id);
   end Background_Image_URL;

   function List_Image (URI : String) return List_Style_Image_Value is
      Id : constant CSS_Text_Id := Intern_Text (URI);
   begin
      if Id = No_CSS_Text then
         return No_List_Image;
      end if;
      return (Kind => List_Image_URL, URI => Id);
   end List_Image;

   function List_String (Text : String) return List_Style_Type_Value is
     ((Kind => List_Style_Custom_String, Marker => Intern_Text (Text)));

   --  Whether text a style is asked to carry fits, said once for the
   --  four helpers below and for the composer's text setters. An empty
   --  URL is refused by the callers rather than here, and silently, as
   --  Adi.CSS_Parser refuses it.
   function Text_Fits_Style (Text : String; Property : String)
     return Boolean is
   begin
      if Text'Length <= Max_CSS_Text_Length then
         return True;
      end if;

      Adi.Log.Warning
        ("CSS " & Property & " text of" & Natural'Image (Text'Length)
         & " characters exceeds the" & Natural'Image (Max_CSS_Text_Length)
         & " a style value carries; the property is left unset");
      return False;
   end Text_Fits_Style;

   --  The four helpers a style is written with. Each leaves the
   --  property unset where Adi.CSS_Parser leaves the declaration out,
   --  so the chain, the aggregate and a parsed sheet carry the same
   --  thing for the same text.
   function Set_Font_Family (Name : String) return Opt_Font.Optional is
     (if Text_Fits_Style (Name, "font-family")
      then Opt_Font.Val ((Kind => By_Name, Name => Intern_Text (Name)))
      else Opt_Font.Unset);

   function Set_Bg_Image (URI : String) return Opt_Bg_Image.Optional is
     (if URI'Length > 0 and then Text_Fits_Style (URI, "background-image")
      then Opt_Bg_Image.Val (Background_Image_URL (URI))
      else Opt_Bg_Image.Unset);

   function Set_List_Type (Marker : String)
     return Opt_List_Style_Type.Optional is
     (if Text_Fits_Style (Marker, "list-style-type")
      then Opt_List_Style_Type.Val (List_String (Marker))
      else Opt_List_Style_Type.Unset);

   function Set_List_Image (URI : String)
     return Opt_List_Style_Image.Optional is
     (if URI'Length > 0 and then Text_Fits_Style (URI, "list-style-image")
      then Opt_List_Style_Image.Val (List_Image (URI))
      else Opt_List_Style_Image.Unset);

   -------------------------------------------------
   -- Linear_Gradient
   -------------------------------------------------

   --  A gradient is held by pointer, and a pointer is what equality on
   --  the enclosing style compares. Two equal gradients must therefore
   --  be one pointer, or a style carrying one is unequal to its own
   --  copy: it interns twice, and a source handed its own configuration
   --  again restyles every widget bound to it.
   --
   --  Scanned rather than hashed. A sheet has a handful of gradients,
   --  and the angle and stop positions are floats, where equal values
   --  need not share their bits.
   package Gradient_Vectors is new Ada.Containers.Vectors
     (Positive, Linear_Gradient_Ref);

   Gradient_Store : Gradient_Vectors.Vector;

   --  The stop array is a fixed sixteen slots of which Stop_Count are
   --  live, so two gradients that agree are the ones whose live stops
   --  agree. Comparing the whole array would make sharing depend on how
   --  each caller happened to pad it.
   function Same_Gradient (A, B : Linear_Gradient_Value) return Boolean is
   begin
      if A.Stop_Count /= B.Stop_Count or else A.Angle /= B.Angle then
         return False;
      end if;

      for I in 1 .. A.Stop_Count loop
         if A.Stops (I) /= B.Stops (I) then
            return False;
         end if;
      end loop;

      return True;
   end Same_Gradient;

   function Shared_Gradient (V : Linear_Gradient_Value)
     return Linear_Gradient_Ref is
   begin
      for G of Gradient_Store loop
         if Same_Gradient (G.all, V) then
            return G;
         end if;
      end loop;

      Gradient_Store.Append (new Linear_Gradient_Value'(V));
      return Gradient_Store.Last_Element;
   end Shared_Gradient;

   function Interned_Gradients return Natural is
     (Natural (Gradient_Store.Length));

   function Interned_Gradient_Bytes return Natural is
     (Natural (Gradient_Store.Length)
      * (Linear_Gradient_Value'Max_Size_In_Storage_Elements
         + Linear_Gradient_Ref'Max_Size_In_Storage_Elements));

   function Linear_Gradient
     (Angle : Float; Stops : Gradient_Stop_Array; Count : Natural)
      return Background_Image_Value
   is
   begin
      return (Kind     => Linear_Gradient_Image,
              Gradient => Shared_Gradient
                ((Angle      => Angle,
                  Stop_Count => Count,
                  Stops      => Stops)));
   end Linear_Gradient;

   -------------------------------------------------
   -- Get_Border_Radius_Px
   -------------------------------------------------

   function Overlay (Base, Override : Gap_Value) return Gap_Value is
      --  A uniform value names both axes, so it simply replaces Base.
      function Row_Of (G : Gap_Value) return Length_Value is
        (if G.Kind = Gap_Uniform then G.All_Gap else G.Row_Gap);
      function Col_Of (G : Gap_Value) return Length_Value is
        (if G.Kind = Gap_Uniform then G.All_Gap else G.Column_Gap);
      function Names_Row (G : Gap_Value) return Boolean is
        (G.Kind = Gap_Uniform or else G.Has_Row);
      function Names_Col (G : Gap_Value) return Boolean is
        (G.Kind = Gap_Uniform or else G.Has_Column);

      Row      : constant Length_Value :=
        (if Names_Row (Override) then Row_Of (Override) else Row_Of (Base));
      Col      : constant Length_Value :=
        (if Names_Col (Override) then Col_Of (Override) else Col_Of (Base));
      Has_R    : constant Boolean :=
        Names_Row (Override) or else Names_Row (Base);
      Has_C    : constant Boolean :=
        Names_Col (Override) or else Names_Col (Base);
   begin
      if Has_R and then Has_C and then Row = Col then
         return Gap (Row);
      end if;
      return (Kind       => Gap_Separate,
              Row_Gap    => Row,
              Column_Gap => Col,
              Has_Row    => Has_R,
              Has_Column => Has_C);
   end Overlay;

   -------------------------------------------------
   -- Per-side rule values
   -------------------------------------------------

   function Set (V : CSS_Box_Value) return Opt_Edge_Lengths is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => Opt_Length.Val (V.All_Sides)];
         when Axis =>
            return [Top | Bottom => Opt_Length.Val (V.Vertical),
                    Left | Right => Opt_Length.Val (V.Horizontal)];
         when Per_Side =>
            return [for E in Edge => Opt_Length.Val (V.Sides (E))];
      end case;
   end Set;

   function Set (V : Border_Width_Value) return Opt_Edge_Lengths is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => Opt_Length.Val (V.All_Edges)];
         when Per_Edge =>
            return [for E in Edge => Opt_Length.Val (V.Edges (E))];
      end case;
   end Set;

   function Set (V : Border_Color_Value) return Opt_Edge_Colors is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => Opt_Edge_Color.Val (V.All_Edges)];
         when Per_Edge =>
            return [for E in Edge => Opt_Edge_Color.Val (V.Edges (E))];
      end case;
   end Set;

   function Set (V : Border_Style_Value) return Opt_Edge_Styles is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => Opt_Edge_Style.Val (V.All_Edges)];
         when Per_Edge =>
            return [for E in Edge => Opt_Edge_Style.Val (V.Edges (E))];
      end case;
   end Set;

   function Set (V : Border_Radius_Value) return Opt_Corner_Lengths is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => Opt_Length.Val (V.All_Corners)];
         when Per_Corner =>
            return [for C in Corner => Opt_Length.Val (V.Corners (C))];
      end case;
   end Set;

   --  The narrowest of the equivalent shapes, so that two rule sets that
   --  say the same thing compare equal in the resolved-style caches.

   function To_Margin (O : Opt_Margin_Sides) return Margin_Sides is
   begin
      return [for E in Edge => Opt_Margin.Resolve (O (E))];
   end To_Margin;

   function Set_Margin (V : CSS_Box_Value) return Opt_Margin_Sides is
   begin
      case V.Kind is
         when Gap_Uniform =>
            return [others => Opt_Margin.Val (Margin (V.All_Sides))];
         when Axis =>
            return [Top | Bottom => Opt_Margin.Val (Margin (V.Vertical)),
                    Left | Right => Opt_Margin.Val (Margin (V.Horizontal))];
         when Per_Side =>
            return [for E in Edge => Opt_Margin.Val (Margin (V.Sides (E)))];
      end case;
   end Set_Margin;

   function To_Box (O : Opt_Edge_Lengths) return CSS_Box_Value is
      S : constant CSS_Box_Sides :=
        [for E in Edge => Opt_Length.Resolve (O (E))];
   begin
      if S (Top) = S (Right) and then S (Right) = S (Bottom)
        and then S (Bottom) = S (Left)
      then
         return CSS_Box (S (Top));
      elsif S (Top) = S (Bottom) and then S (Left) = S (Right) then
         return CSS_Box (S (Top), S (Right));
      end if;
      return CSS_Box (S (Top), S (Right), S (Bottom), S (Left));
   end To_Box;

   function To_Border_Width (O : Opt_Edge_Lengths) return Border_Width_Value is
      S : constant Edge_Lengths :=
        [for E in Edge => Opt_Length.Resolve (O (E))];
   begin
      if S (Top) = S (Right) and then S (Right) = S (Bottom)
        and then S (Bottom) = S (Left)
      then
         return Border_Width (S (Top));
      end if;
      return Border_Width (S (Top), S (Right), S (Bottom), S (Left));
   end To_Border_Width;

   function To_Border_Color (O : Opt_Edge_Colors) return Border_Color_Value is
      S : constant Edge_Colors :=
        [for E in Edge => Opt_Edge_Color.Resolve (O (E))];
   begin
      if S (Top) = S (Right) and then S (Right) = S (Bottom)
        and then S (Bottom) = S (Left)
      then
         return Border_Color (S (Top));
      end if;
      return Border_Color (S (Top), S (Right), S (Bottom), S (Left));
   end To_Border_Color;

   function To_Border_Style (O : Opt_Edge_Styles) return Border_Style_Value is
      S : constant Edge_Styles :=
        [for E in Edge => Opt_Edge_Style.Resolve (O (E))];
   begin
      if S (Top) = S (Right) and then S (Right) = S (Bottom)
        and then S (Bottom) = S (Left)
      then
         return Border_Style (S (Top));
      end if;
      return Border_Style (S (Top), S (Right), S (Bottom), S (Left));
   end To_Border_Style;

   function To_Border_Radius (O : Opt_Corner_Lengths) return Border_Radius_Value is
      S : constant Corner_Radii :=
        [for C in Corner => Opt_Length.Resolve (O (C))];
   begin
      if S (Top_Left) = S (Top_Right) and then S (Top_Right) = S (Bottom_Right)
        and then S (Bottom_Right) = S (Bottom_Left)
      then
         return Radius (S (Top_Left));
      end if;
      return Radius (S (Top_Left), S (Top_Right),
                     S (Bottom_Right), S (Bottom_Left));
   end To_Border_Radius;

   function Get_Border_Radius_Px (R : Border_Radius_Value) return Corner_Pixels is
   begin
      case R.Kind is
         when Gap_Uniform =>
            declare
               V : constant Float := R.All_Corners.Amount;
            begin
               return (V, V, V, V);
            end;
         when Per_Corner =>
            return (
               Top_Left     => R.Corners (Top_Left).Amount,
               Top_Right    => R.Corners (Top_Right).Amount,
               Bottom_Right => R.Corners (Bottom_Right).Amount,
               Bottom_Left  => R.Corners (Bottom_Left).Amount);
      end case;
   end Get_Border_Radius_Px;

   type RGB_Entry is record
      R, G, B : Natural;
   end record;

   Named_Color_RGB : constant array (Named_Color) of RGB_Entry :=
     [
      Black => (R => 0, G => 0, B => 0),
      White => (R => 255, G => 255, B => 255),
      Red => (R => 255, G => 0, B => 0),
      Green => (R => 0, G => 128, B => 0),
      Blue => (R => 0, G => 0, B => 255),
      Yellow => (R => 255, G => 255, B => 0),
      Orange => (R => 255, G => 165, B => 0),
      Purple => (R => 128, G => 0, B => 128),
      Gray => (R => 128, G => 128, B => 128),
      Light_Gray => (R => 211, G => 211, B => 211),
      Dark_Gray => (R => 169, G => 169, B => 169),
      Silver => (R => 192, G => 192, B => 192),
      Maroon => (R => 128, G => 0, B => 0),
      Fuchsia => (R => 255, G => 0, B => 255),
      Lime => (R => 0, G => 255, B => 0),
      Olive => (R => 128, G => 128, B => 0),
      Navy => (R => 0, G => 0, B => 128),
      Teal => (R => 0, G => 128, B => 128),
      Aqua => (R => 0, G => 255, B => 255),
      Alice_Blue => (R => 240, G => 248, B => 255),
      Antique_White => (R => 250, G => 235, B => 215),
      Aqua_Marine => (R => 127, G => 255, B => 212),
      Azure => (R => 240, G => 255, B => 255),
      Beige => (R => 245, G => 245, B => 220),
      Bisque => (R => 255, G => 228, B => 196),
      Blanched_Almond => (R => 255, G => 235, B => 205),
      Blue_Violet => (R => 138, G => 43, B => 226),
      Brown => (R => 165, G => 42, B => 42),
      Burly_Wood => (R => 222, G => 184, B => 135),
      Cadet_Blue => (R => 95, G => 158, B => 160),
      Chartreuse => (R => 127, G => 255, B => 0),
      Chocolate => (R => 210, G => 105, B => 30),
      Coral => (R => 255, G => 127, B => 80),
      Cornflower_Blue => (R => 100, G => 149, B => 237),
      Corn_Silk => (R => 255, G => 248, B => 220),
      Crimson => (R => 220, G => 20, B => 60),
      Cyan => (R => 0, G => 255, B => 255),
      Dark_Blue => (R => 0, G => 0, B => 139),
      Dark_Cyan => (R => 0, G => 139, B => 139),
      Dark_Goldenrod => (R => 184, G => 134, B => 11),
      Dark_Green => (R => 0, G => 100, B => 0),
      Dark_Khaki => (R => 189, G => 183, B => 107),
      Dark_Magenta => (R => 139, G => 0, B => 139),
      Dark_Olive_Green => (R => 85, G => 107, B => 47),
      Dark_Orange => (R => 255, G => 140, B => 0),
      Dark_Orchid => (R => 153, G => 50, B => 204),
      Dark_Red => (R => 139, G => 0, B => 0),
      Dark_Salmon => (R => 233, G => 150, B => 122),
      Dark_Sea_Green => (R => 143, G => 188, B => 143),
      Dark_Slate_Blue => (R => 72, G => 61, B => 139),
      Dark_Slate_Gray => (R => 47, G => 79, B => 79),
      Dark_Slate_Grey => (R => 47, G => 79, B => 79),
      Dark_Turquoise => (R => 0, G => 206, B => 209),
      Dark_Violet => (R => 148, G => 0, B => 211),
      Deep_Pink => (R => 255, G => 20, B => 147),
      Deep_Sky_Blue => (R => 0, G => 191, B => 255),
      Dim_Gray => (R => 105, G => 105, B => 105),
      Dim_Grey => (R => 105, G => 105, B => 105),
      Dodger_Blue => (R => 30, G => 144, B => 255),
      Fire_Brick => (R => 178, G => 34, B => 34),
      Floral_White => (R => 255, G => 250, B => 240),
      Forest_Green => (R => 34, G => 139, B => 34),
      Gainsboro => (R => 220, G => 220, B => 220),
      Ghost_White => (R => 248, G => 248, B => 255),
      Gold => (R => 255, G => 215, B => 0),
      Goldenrod => (R => 218, G => 165, B => 32),
      Green_Yellow => (R => 173, G => 255, B => 47),
      Honey_Dew => (R => 240, G => 255, B => 240),
      Hot_Pink => (R => 255, G => 105, B => 180),
      Indian_Red => (R => 205, G => 92, B => 92),
      Indigo => (R => 75, G => 0, B => 130),
      Ivory => (R => 255, G => 255, B => 240),
      Khaki => (R => 240, G => 230, B => 140),
      Lavender => (R => 230, G => 230, B => 250),
      Lavender_Blush => (R => 255, G => 240, B => 245),
      Lawn_Green => (R => 124, G => 252, B => 0),
      Lemon_Chiffon => (R => 255, G => 250, B => 205),
      Light_Blue => (R => 173, G => 216, B => 230),
      Light_Coral => (R => 240, G => 128, B => 128),
      Light_Cyan => (R => 224, G => 255, B => 255),
      Light_Goldenrod_Yellow => (R => 250, G => 250, B => 210),
      Light_Green => (R => 144, G => 238, B => 144),
      Light_Pink => (R => 255, G => 182, B => 193),
      Light_Salmon => (R => 255, G => 160, B => 122),
      Light_Sea_Green => (R => 32, G => 178, B => 170),
      Light_Sky_Blue => (R => 135, G => 206, B => 250),
      Light_Slate_Gray => (R => 119, G => 136, B => 153),
      Light_Slate_Grey => (R => 119, G => 136, B => 153),
      Light_Steel_Blue => (R => 176, G => 196, B => 222),
      Light_Yellow => (R => 255, G => 255, B => 224),
      Lime_Green => (R => 50, G => 205, B => 50),
      Linen => (R => 250, G => 240, B => 230),
      Magenta => (R => 255, G => 0, B => 255),
      Medium_Aqua_Marine => (R => 102, G => 205, B => 170),
      Medium_Blue => (R => 0, G => 0, B => 205),
      Medium_Orchid => (R => 186, G => 85, B => 211),
      Medium_Purple => (R => 147, G => 112, B => 219),
      Medium_Sea_Green => (R => 60, G => 179, B => 113),
      Medium_Slate_Blue => (R => 123, G => 104, B => 238),
      Medium_Spring_Green => (R => 0, G => 250, B => 154),
      Medium_Turquoise => (R => 72, G => 209, B => 204),
      Medium_Violet_Red => (R => 199, G => 21, B => 133),
      Midnight_Blue => (R => 25, G => 25, B => 112),
      Mint_Cream => (R => 245, G => 255, B => 250),
      Misty_Rose => (R => 255, G => 228, B => 225),
      Moccasin => (R => 255, G => 228, B => 181),
      Navajo_White => (R => 255, G => 222, B => 173),
      Old_Lace => (R => 253, G => 245, B => 230),
      Olive_Drab => (R => 107, G => 142, B => 35),
      Orange_Red => (R => 255, G => 69, B => 0),
      Orchid => (R => 218, G => 112, B => 214),
      Pale_Goldenrod => (R => 238, G => 232, B => 170),
      Pale_Green => (R => 152, G => 251, B => 152),
      Pale_Turquoise => (R => 175, G => 238, B => 238),
      Pale_Violet_Red => (R => 219, G => 112, B => 147),
      Papaya_Whip => (R => 255, G => 239, B => 213),
      Peach_Puff => (R => 255, G => 218, B => 185),
      Peru => (R => 205, G => 133, B => 63),
      Pink => (R => 255, G => 192, B => 203),
      Plum => (R => 221, G => 160, B => 221),
      Powder_Blue => (R => 176, G => 224, B => 230),
      Rosy_Brown => (R => 188, G => 143, B => 143),
      Royal_Blue => (R => 65, G => 105, B => 225),
      Saddle_Brown => (R => 139, G => 69, B => 19),
      Salmon => (R => 250, G => 128, B => 114),
      Sandy_Brown => (R => 244, G => 164, B => 96),
      Sea_Green => (R => 46, G => 139, B => 87),
      Sea_Shell => (R => 255, G => 245, B => 238),
      Sienna => (R => 160, G => 82, B => 45),
      Sky_Blue => (R => 135, G => 206, B => 235),
      Slate_Blue => (R => 106, G => 90, B => 205),
      Slate_Gray => (R => 112, G => 128, B => 144),
      Slate_Grey => (R => 112, G => 128, B => 144),
      Snow => (R => 255, G => 250, B => 250),
      Spring_Green => (R => 0, G => 255, B => 127),
      Steel_Blue => (R => 70, G => 130, B => 180),
      Tan => (R => 210, G => 180, B => 140),
      Thistle => (R => 216, G => 191, B => 216),
      Tomato => (R => 255, G => 99, B => 71),
      Turquoise => (R => 64, G => 224, B => 208),
      Violet => (R => 238, G => 130, B => 238),
      Wheat => (R => 245, G => 222, B => 179),
      White_Smoke => (R => 245, G => 245, B => 245),
      Yellow_Green => (R => 154, G => 205, B => 50),
      Transparent => (R => 0, G => 0, B => 0),
      Inherit => (R => 0, G => 0, B => 0),
      Current_Color => (R => 0, G => 0, B => 0)
     ];

   type Color_Name_Ref is access constant String;

   type Name_Entry is record
      Name  : Color_Name_Ref;
      Value : Named_Color;
   end record;

   Named_Color_Name_Map : constant array (Positive range <>) of Name_Entry :=
     [
      (Name => new String'("black"), Value => Black),
      (Name => new String'("silver"), Value => Silver),
      (Name => new String'("gray"), Value => Gray),
      (Name => new String'("white"), Value => White),
      (Name => new String'("maroon"), Value => Maroon),
      (Name => new String'("red"), Value => Red),
      (Name => new String'("purple"), Value => Purple),
      (Name => new String'("fuchsia"), Value => Fuchsia),
      (Name => new String'("green"), Value => Green),
      (Name => new String'("lime"), Value => Lime),
      (Name => new String'("olive"), Value => Olive),
      (Name => new String'("yellow"), Value => Yellow),
      (Name => new String'("navy"), Value => Navy),
      (Name => new String'("blue"), Value => Blue),
      (Name => new String'("teal"), Value => Teal),
      (Name => new String'("aqua"), Value => Aqua),
      (Name => new String'("aliceblue"), Value => Alice_Blue),
      (Name => new String'("antiquewhite"), Value => Antique_White),
      (Name => new String'("aquamarine"), Value => Aqua_Marine),
      (Name => new String'("azure"), Value => Azure),
      (Name => new String'("beige"), Value => Beige),
      (Name => new String'("bisque"), Value => Bisque),
      (Name => new String'("blanchedalmond"), Value => Blanched_Almond),
      (Name => new String'("blueviolet"), Value => Blue_Violet),
      (Name => new String'("brown"), Value => Brown),
      (Name => new String'("burlywood"), Value => Burly_Wood),
      (Name => new String'("cadetblue"), Value => Cadet_Blue),
      (Name => new String'("chartreuse"), Value => Chartreuse),
      (Name => new String'("chocolate"), Value => Chocolate),
      (Name => new String'("coral"), Value => Coral),
      (Name => new String'("cornflowerblue"), Value => Cornflower_Blue),
      (Name => new String'("cornsilk"), Value => Corn_Silk),
      (Name => new String'("crimson"), Value => Crimson),
      (Name => new String'("cyan"), Value => Cyan),
      (Name => new String'("darkblue"), Value => Dark_Blue),
      (Name => new String'("darkcyan"), Value => Dark_Cyan),
      (Name => new String'("darkgoldenrod"), Value => Dark_Goldenrod),
      (Name => new String'("darkgray"), Value => Dark_Gray),
      (Name => new String'("darkgreen"), Value => Dark_Green),
      (Name => new String'("darkgrey"), Value => Dark_Gray),
      (Name => new String'("darkkhaki"), Value => Dark_Khaki),
      (Name => new String'("darkmagenta"), Value => Dark_Magenta),
      (Name => new String'("darkolivegreen"), Value => Dark_Olive_Green),
      (Name => new String'("darkorange"), Value => Dark_Orange),
      (Name => new String'("darkorchid"), Value => Dark_Orchid),
      (Name => new String'("darkred"), Value => Dark_Red),
      (Name => new String'("darksalmon"), Value => Dark_Salmon),
      (Name => new String'("darkseagreen"), Value => Dark_Sea_Green),
      (Name => new String'("darkslateblue"), Value => Dark_Slate_Blue),
      (Name => new String'("darkslategray"), Value => Dark_Slate_Gray),
      (Name => new String'("darkslategrey"), Value => Dark_Slate_Grey),
      (Name => new String'("darkturquoise"), Value => Dark_Turquoise),
      (Name => new String'("darkviolet"), Value => Dark_Violet),
      (Name => new String'("deeppink"), Value => Deep_Pink),
      (Name => new String'("deepskyblue"), Value => Deep_Sky_Blue),
      (Name => new String'("dimgray"), Value => Dim_Gray),
      (Name => new String'("dimgrey"), Value => Dim_Grey),
      (Name => new String'("dodgerblue"), Value => Dodger_Blue),
      (Name => new String'("firebrick"), Value => Fire_Brick),
      (Name => new String'("floralwhite"), Value => Floral_White),
      (Name => new String'("forestgreen"), Value => Forest_Green),
      (Name => new String'("gainsboro"), Value => Gainsboro),
      (Name => new String'("ghostwhite"), Value => Ghost_White),
      (Name => new String'("gold"), Value => Gold),
      (Name => new String'("goldenrod"), Value => Goldenrod),
      (Name => new String'("greenyellow"), Value => Green_Yellow),
      (Name => new String'("grey"), Value => Gray),
      (Name => new String'("honeydew"), Value => Honey_Dew),
      (Name => new String'("hotpink"), Value => Hot_Pink),
      (Name => new String'("indianred"), Value => Indian_Red),
      (Name => new String'("indigo"), Value => Indigo),
      (Name => new String'("ivory"), Value => Ivory),
      (Name => new String'("khaki"), Value => Khaki),
      (Name => new String'("lavender"), Value => Lavender),
      (Name => new String'("lavenderblush"), Value => Lavender_Blush),
      (Name => new String'("lawngreen"), Value => Lawn_Green),
      (Name => new String'("lemonchiffon"), Value => Lemon_Chiffon),
      (Name => new String'("lightblue"), Value => Light_Blue),
      (Name => new String'("lightcoral"), Value => Light_Coral),
      (Name => new String'("lightcyan"), Value => Light_Cyan),
      (Name => new String'("lightgoldenrodyellow"), Value => Light_Goldenrod_Yellow),
      (Name => new String'("lightgray"), Value => Light_Gray),
      (Name => new String'("lightgreen"), Value => Light_Green),
      (Name => new String'("lightgrey"), Value => Light_Gray),
      (Name => new String'("lightpink"), Value => Light_Pink),
      (Name => new String'("lightsalmon"), Value => Light_Salmon),
      (Name => new String'("lightseagreen"), Value => Light_Sea_Green),
      (Name => new String'("lightskyblue"), Value => Light_Sky_Blue),
      (Name => new String'("lightslategray"), Value => Light_Slate_Gray),
      (Name => new String'("lightslategrey"), Value => Light_Slate_Grey),
      (Name => new String'("lightsteelblue"), Value => Light_Steel_Blue),
      (Name => new String'("lightyellow"), Value => Light_Yellow),
      (Name => new String'("limegreen"), Value => Lime_Green),
      (Name => new String'("linen"), Value => Linen),
      (Name => new String'("magenta"), Value => Magenta),
      (Name => new String'("mediumaquamarine"), Value => Medium_Aqua_Marine),
      (Name => new String'("mediumblue"), Value => Medium_Blue),
      (Name => new String'("mediumorchid"), Value => Medium_Orchid),
      (Name => new String'("mediumpurple"), Value => Medium_Purple),
      (Name => new String'("mediumseagreen"), Value => Medium_Sea_Green),
      (Name => new String'("mediumslateblue"), Value => Medium_Slate_Blue),
      (Name => new String'("mediumspringgreen"), Value => Medium_Spring_Green),
      (Name => new String'("mediumturquoise"), Value => Medium_Turquoise),
      (Name => new String'("mediumvioletred"), Value => Medium_Violet_Red),
      (Name => new String'("midnightblue"), Value => Midnight_Blue),
      (Name => new String'("mintcream"), Value => Mint_Cream),
      (Name => new String'("mistyrose"), Value => Misty_Rose),
      (Name => new String'("moccasin"), Value => Moccasin),
      (Name => new String'("navajowhite"), Value => Navajo_White),
      (Name => new String'("oldlace"), Value => Old_Lace),
      (Name => new String'("olivedrab"), Value => Olive_Drab),
      (Name => new String'("orange"), Value => Orange),
      (Name => new String'("orangered"), Value => Orange_Red),
      (Name => new String'("orchid"), Value => Orchid),
      (Name => new String'("palegoldenrod"), Value => Pale_Goldenrod),
      (Name => new String'("palegreen"), Value => Pale_Green),
      (Name => new String'("paleturquoise"), Value => Pale_Turquoise),
      (Name => new String'("palevioletred"), Value => Pale_Violet_Red),
      (Name => new String'("papayawhip"), Value => Papaya_Whip),
      (Name => new String'("peachpuff"), Value => Peach_Puff),
      (Name => new String'("peru"), Value => Peru),
      (Name => new String'("pink"), Value => Pink),
      (Name => new String'("plum"), Value => Plum),
      (Name => new String'("powderblue"), Value => Powder_Blue),
      (Name => new String'("rosybrown"), Value => Rosy_Brown),
      (Name => new String'("royalblue"), Value => Royal_Blue),
      (Name => new String'("saddlebrown"), Value => Saddle_Brown),
      (Name => new String'("salmon"), Value => Salmon),
      (Name => new String'("sandybrown"), Value => Sandy_Brown),
      (Name => new String'("seagreen"), Value => Sea_Green),
      (Name => new String'("seashell"), Value => Sea_Shell),
      (Name => new String'("sienna"), Value => Sienna),
      (Name => new String'("skyblue"), Value => Sky_Blue),
      (Name => new String'("slateblue"), Value => Slate_Blue),
      (Name => new String'("slategray"), Value => Slate_Gray),
      (Name => new String'("slategrey"), Value => Slate_Grey),
      (Name => new String'("snow"), Value => Snow),
      (Name => new String'("springgreen"), Value => Spring_Green),
      (Name => new String'("steelblue"), Value => Steel_Blue),
      (Name => new String'("tan"), Value => Tan),
      (Name => new String'("thistle"), Value => Thistle),
      (Name => new String'("tomato"), Value => Tomato),
      (Name => new String'("turquoise"), Value => Turquoise),
      (Name => new String'("violet"), Value => Violet),
      (Name => new String'("wheat"), Value => Wheat),
      (Name => new String'("whitesmoke"), Value => White_Smoke),
      (Name => new String'("yellowgreen"), Value => Yellow_Green),
      (Name => new String'("transparent"), Value => Transparent),
      (Name => new String'("inherit"), Value => Inherit),
      (Name => new String'("currentcolor"), Value => Current_Color)
     ];

   function Is_Whitespace (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Lower_Trimmed (Input : String) return String is
      First : Natural;
      Last  : Natural;
   begin
      if Input'Length = 0 then
         return "";
      end if;

      First := Input'First;
      Last := Input'Last;

      while First <= Input'Last and then Is_Whitespace (Input (First)) loop
         First := First + 1;
      end loop;

      while Last >= First and then Is_Whitespace (Input (Last)) loop
         Last := Last - 1;
      end loop;

      if First > Last then
         return "";
      end if;

      declare
         Result : String (1 .. Last - First + 1);
      begin
         for I in Result'Range loop
            Result (I) := Char.To_Lower (Input (First + I - 1));
         end loop;
         return Result;
      end;
   end Lower_Trimmed;

   function Parse_Named_Color
     (Name  : String;
      Value : out Named_Color) return Boolean
   is
      Key : constant String := Lower_Trimmed (Name);
   begin
      if Key'Length = 0 then
         return False;
      end if;

      for Name_Item of Named_Color_Name_Map loop
         if Key = Name_Item.Name.all then
            Value := Name_Item.Value;
            return True;
         end if;
      end loop;

      return False;
   end Parse_Named_Color;

   -------------------------------------------------
   -- Merge and the property set
   -------------------------------------------------

   --  Both walk the slots. Converting an aggregate is what costs here,
   --  and it is what leaves Style_Rules as the form an author writes
   --  and Adi.CSS_Parser fills.
   function Merge (Base, Override : Style_Rules) return Style_Rules is
     (Rules_Of (Merge (Slots_Of (Base), Slots_Of (Override))));

   function Set_Properties (S : Style_Rules) return CSS_Property_Set is
     (Set_Properties (Slots_Of (S)));

   -------------------------------------------------
   --  Inherit_From: cascade inheritable properties
   --  See Inheritable_Properties in adi-css_styles.ads
   -------------------------------------------------

   function Inherit_From (Parent, Child : Style_Rules) return Style_Rules is
     (Rules_Of (Inherit_From (Slots_Of (Parent), Slots_Of (Child))));

   -------------------------------------------------
   -- Resolve_Font_Family: resolve Font_Family_Value to Font_Handle
   -- Handles By_Handle (pass through), By_Name (comma-list lookup)
   -------------------------------------------------

   function Resolve_Font_Family (O : Opt_Font.Optional) return Font_Handle is

      function Strip_Quotes (S : String) return String is
         First : Natural := S'First;
         Last  : Natural := S'Last;
      begin
         if S'Length >= 2 then
            if (S (First) = '"' and then S (Last) = '"')
              or else (S (First) = ''' and then S (Last) = ''')
            then
               First := First + 1;
               Last  := Last - 1;
            end if;
         end if;
         if First > Last then
            return "";
         end if;
         return S (First .. Last);
      end Strip_Quotes;

      function Trim (S : String) return String is
         F : Natural := S'First;
         L : Natural := S'Last;
      begin
         while F <= S'Last and then (S (F) = ' ' or else S (F) = ASCII.HT) loop
            F := F + 1;
         end loop;
         while L >= F and then (S (L) = ' ' or else S (L) = ASCII.HT) loop
            L := L - 1;
         end loop;
         if F > L then
            return "";
         end if;
         return S (F .. L);
      end Trim;

      function Try_Name_List (Raw : String) return Font_Handle is
         Start    : Natural := Raw'First;
         I        : Natural := Raw'First;
         In_Quote : Character := ASCII.NUL;
      begin
         if Current_Resolver = null then
            return Null_Font;
         end if;

         while I <= Raw'Last loop
            if In_Quote /= ASCII.NUL then
               --  Inside a quoted string, skip until closing quote
               if Raw (I) = In_Quote then
                  In_Quote := ASCII.NUL;
               end if;
            elsif Raw (I) = '"' or else Raw (I) = ''' then
               In_Quote := Raw (I);
            elsif Raw (I) = ',' then
               declare
                  Name : constant String :=
                    Strip_Quotes (Trim (Raw (Start .. I - 1)));
                  H    : Font_Handle;
               begin
                  if Name'Length > 0 then
                     H := Current_Resolver (Name);
                     if H /= Null_Font then
                        return H;
                     end if;
                  end if;
               end;
               Start := I + 1;
            end if;
            I := I + 1;
         end loop;

         --  Last (or only) entry
         declare
            Name : constant String :=
              Strip_Quotes (Trim (Raw (Start .. Raw'Last)));
            H    : Font_Handle;
         begin
            if Name'Length > 0 then
               H := Current_Resolver (Name);
               if H /= Null_Font then
                  return H;
               end if;
            end if;
         end;

         return Null_Font;
      end Try_Name_List;

   begin
      case O.State is
         when Opt_Font.Undefined | Opt_Font.None =>
            return Default_Font;
         when Opt_Font.Set =>
            case O.Value.Kind is
               when By_Handle =>
                  return O.Value.Handle;
               when By_Name =>
                  return Try_Name_List (Text_Of (O.Value.Name));
            end case;
      end case;
   end Resolve_Font_Family;

   -------------------------------------------------
   -- Resolve: Convert Style_Rules to Resolved_Style
   -------------------------------------------------

   function Resolve (S : Style_Rules) return Resolved_Style is
      Overflow_X    : constant Overflow_Value := Opt_Overflow.Resolve (S.Overflow_X);
      Overflow_Y    : constant Overflow_Value := Opt_Overflow.Resolve (S.Overflow_Y);
   begin
      return (
         -- Colors
         Color            => Opt_Text_Color.Resolve (S.Color),
         Background_Color => Opt_Bg_Color.Resolve (S.Background_Color),
         Background_Image => Opt_Bg_Image.Resolve (S.Background_Image),

         -- Border
         Border_Radius    => To_Border_Radius (S.Border_Radius),
         Border_Width     => To_Border_Width (S.Border_Width),
         Border_Color     => To_Border_Color (S.Border_Color),
         Border_Style     => To_Border_Style (S.Border_Style),

         -- Outline
         Outline_Width    => Opt_Outline_Width.Resolve (S.Outline_Width),
         Outline_Color    => Opt_Outline_Color.Resolve (S.Outline_Color),
         Outline_Style    => Opt_Outline_Style.Resolve (S.Outline_Style),
         Outline_Offset   => Opt_Outline_Offset.Resolve (S.Outline_Offset),

         -- Spacing
         Padding          => To_Box (S.Padding),
         Margin           => To_Margin (S.Margin),

         -- Sizing
         Width            => Opt_Size.Resolve (S.Width),
         Height           => Opt_Size.Resolve (S.Height),
         Min_Width        => Opt_Size.Resolve (S.Min_Width),
         Max_Width        => Opt_Size.Resolve (S.Max_Width),
         Min_Height       => Opt_Size.Resolve (S.Min_Height),
         Max_Height       => Opt_Size.Resolve (S.Max_Height),

         -- Typography
         Font_Size        => Opt_Font_Size.Resolve (S.Font_Size),
         Font_Family      => Resolve_Font_Family (S.Font_Family),
         Font_Weight      => Opt_Font_Weight.Resolve (S.Font_Weight),
         Font_Style       => Opt_Font_Style.Resolve (S.Font_Style),
         Text_Decoration  => Opt_Text_Decoration.Resolve (S.Text_Decoration),
         List_Style_Type  => Opt_List_Style_Type.Resolve (S.List_Style_Type),
         List_Style_Image => Opt_List_Style_Image.Resolve (S.List_Style_Image),
         List_Style_Position => Opt_List_Style_Position.Resolve (S.List_Style_Position),
         White_Space      => Opt_White_Space.Resolve (S.White_Space),
         Text_Overflow    => Opt_Text_Overflow.Resolve (S.Text_Overflow),
         Text_Wrap_Mode   => Opt_Text_Wrap_Mode.Resolve (S.Text_Wrap_Mode),
         Line_Height      => Opt_Line_Height.Resolve (S.Line_Height),

         Text_Align       => Opt_Text_Align.Resolve (S.Text_Align),
         Vertical_Align   => Opt_Vertical_Align.Resolve (S.Vertical_Align),

         -- Layout
         Display          => Opt_Display.Resolve (S.Display),
         Position         => Opt_Position.Resolve (S.Position),
         Top              => Opt_Top.Resolve (S.Top),
         Right            => Opt_Right.Resolve (S.Right),
         Bottom           => Opt_Bottom.Resolve (S.Bottom),
         Left             => Opt_Left.Resolve (S.Left),
         Overflow_X       => Overflow_X,
         Overflow_Y       => Overflow_Y,
         Visibility       => Opt_Visibility.Resolve (S.Visibility),

         -- Visual
         Opacity          => Opt_Opacity.Resolve (S.Opacity),
         Cursor           => Opt_Cursor.Resolve (S.Cursor),
         Box_Shadow       => Opt_Box_Shadow.Resolve (S.Box_Shadow),

         -- Object/Image
         Object_Fit       => Opt_Object_Fit.Resolve (S.Object_Fit),
         Object_Position  => Opt_Object_Pos.Resolve (S.Object_Position),

         -- Flexbox Container
         Flex_Direction   => Opt_Flex_Dir.Resolve (S.Flex_Direction),
         Flex_Wrap        => Opt_Flex_Wrap.Resolve (S.Flex_Wrap),
         Justify_Content  => Opt_Justify.Resolve (S.Justify_Content),
         Align_Items      => Opt_Align_Items.Resolve (S.Align_Items),
         Align_Content    => Opt_Align_Content.Resolve (S.Align_Content),
         Gap              => Opt_Gap.Resolve (S.Gap),
         Grid_Columns       => Opt_Grid_Cols.Resolve (S.Grid_Columns),
         Grid_Rows          => Opt_Grid_Rows.Resolve (S.Grid_Rows),
         Grid_Column_Tracks =>
           Opt_Grid_Tracks.Resolve (S.Grid_Column_Tracks),

         -- Flexbox Item
         Align_Self       => Opt_Align_Self.Resolve (S.Align_Self),
         Flex_Grow        => Opt_Flex_Grow.Resolve (S.Flex_Grow),
         Flex_Shrink      => Opt_Flex_Shrink.Resolve (S.Flex_Shrink),
         Flex_Basis       => Opt_Flex_Basis.Resolve (S.Flex_Basis),
         Order            => Opt_Order.Resolve (S.Order),
         Grid_Column      => Opt_Grid_Column.Resolve (S.Grid_Column),
         Grid_Row         => Opt_Grid_Row.Resolve (S.Grid_Row),
         Grid_Column_Span => Opt_Grid_Col_Span.Resolve (S.Grid_Column_Span),
         Grid_Row_Span    => Opt_Grid_Row_Span.Resolve (S.Grid_Row_Span),

         -- Animation
         Transition       => Opt_Transition.Resolve (S.Transition)
      );
   end Resolve;

   procedure Copy_Property
     (P      : CSS_Property;
      Source : Resolved_Style;
      Target : in out Resolved_Style) is
   begin
      case P is
         when Prop_Color => Target.Color := Source.Color;
         when Prop_Background_Color =>
            Target.Background_Color := Source.Background_Color;
         when Prop_Background_Image =>
            Target.Background_Image := Source.Background_Image;
         when Prop_Border_Radius =>
            Target.Border_Radius := Source.Border_Radius;
         when Prop_Border_Width => Target.Border_Width := Source.Border_Width;
         when Prop_Border_Color => Target.Border_Color := Source.Border_Color;
         when Prop_Border_Style => Target.Border_Style := Source.Border_Style;
         when Prop_Outline_Width =>
            Target.Outline_Width := Source.Outline_Width;
         when Prop_Outline_Color =>
            Target.Outline_Color := Source.Outline_Color;
         when Prop_Outline_Style =>
            Target.Outline_Style := Source.Outline_Style;
         when Prop_Outline_Offset =>
            Target.Outline_Offset := Source.Outline_Offset;
         when Prop_Padding => Target.Padding := Source.Padding;
         when Prop_Margin => Target.Margin := Source.Margin;
         when Prop_Width => Target.Width := Source.Width;
         when Prop_Height => Target.Height := Source.Height;
         when Prop_Min_Width => Target.Min_Width := Source.Min_Width;
         when Prop_Max_Width => Target.Max_Width := Source.Max_Width;
         when Prop_Min_Height => Target.Min_Height := Source.Min_Height;
         when Prop_Max_Height => Target.Max_Height := Source.Max_Height;
         when Prop_Font_Family => Target.Font_Family := Source.Font_Family;
         when Prop_Font_Size => Target.Font_Size := Source.Font_Size;
         when Prop_Font_Weight => Target.Font_Weight := Source.Font_Weight;
         when Prop_Font_Style => Target.Font_Style := Source.Font_Style;
         when Prop_Text_Align => Target.Text_Align := Source.Text_Align;
         when Prop_Vertical_Align =>
            Target.Vertical_Align := Source.Vertical_Align;
         when Prop_Text_Decoration =>
            Target.Text_Decoration := Source.Text_Decoration;
         when Prop_List_Style_Type =>
            Target.List_Style_Type := Source.List_Style_Type;
         when Prop_List_Style_Image =>
            Target.List_Style_Image := Source.List_Style_Image;
         when Prop_List_Style_Position =>
            Target.List_Style_Position := Source.List_Style_Position;
         when Prop_White_Space => Target.White_Space := Source.White_Space;
         when Prop_Text_Overflow =>
            Target.Text_Overflow := Source.Text_Overflow;
         when Prop_Text_Wrap_Mode =>
            Target.Text_Wrap_Mode := Source.Text_Wrap_Mode;
         when Prop_Line_Height => Target.Line_Height := Source.Line_Height;
         when Prop_Display => Target.Display := Source.Display;
         when Prop_Position => Target.Position := Source.Position;
         when Prop_Overflow =>
            --  Shorthand metadata; the two axes carry it.
            null;
         when Prop_Overflow_X => Target.Overflow_X := Source.Overflow_X;
         when Prop_Overflow_Y => Target.Overflow_Y := Source.Overflow_Y;
         when Prop_Visibility => Target.Visibility := Source.Visibility;
         when Prop_Top => Target.Top := Source.Top;
         when Prop_Right => Target.Right := Source.Right;
         when Prop_Bottom => Target.Bottom := Source.Bottom;
         when Prop_Left => Target.Left := Source.Left;
         when Prop_Opacity => Target.Opacity := Source.Opacity;
         when Prop_Cursor => Target.Cursor := Source.Cursor;
         when Prop_Box_Shadow => Target.Box_Shadow := Source.Box_Shadow;
         when Prop_Object_Fit => Target.Object_Fit := Source.Object_Fit;
         when Prop_Object_Position =>
            Target.Object_Position := Source.Object_Position;
         when Prop_Flex_Direction =>
            Target.Flex_Direction := Source.Flex_Direction;
         when Prop_Flex_Wrap => Target.Flex_Wrap := Source.Flex_Wrap;
         when Prop_Justify_Content =>
            Target.Justify_Content := Source.Justify_Content;
         when Prop_Align_Items => Target.Align_Items := Source.Align_Items;
         when Prop_Align_Content =>
            Target.Align_Content := Source.Align_Content;
         when Prop_Gap => Target.Gap := Source.Gap;
         when Prop_Grid_Columns =>
            Target.Grid_Columns := Source.Grid_Columns;
            Target.Grid_Column_Tracks := Source.Grid_Column_Tracks;
         when Prop_Grid_Rows => Target.Grid_Rows := Source.Grid_Rows;
         when Prop_Align_Self => Target.Align_Self := Source.Align_Self;
         when Prop_Flex_Grow => Target.Flex_Grow := Source.Flex_Grow;
         when Prop_Flex_Shrink => Target.Flex_Shrink := Source.Flex_Shrink;
         when Prop_Flex_Basis => Target.Flex_Basis := Source.Flex_Basis;
         when Prop_Order => Target.Order := Source.Order;
         when Prop_Grid_Column => Target.Grid_Column := Source.Grid_Column;
         when Prop_Grid_Row => Target.Grid_Row := Source.Grid_Row;
         when Prop_Grid_Column_Span =>
            Target.Grid_Column_Span := Source.Grid_Column_Span;
         when Prop_Grid_Row_Span =>
            Target.Grid_Row_Span := Source.Grid_Row_Span;
         when Prop_Transition => Target.Transition := Source.Transition;
      end case;
   end Copy_Property;

   function Property_Differs
     (P : CSS_Property; L, R : Resolved_Style) return Boolean is
   begin
      case P is
         when Prop_Color => return L.Color /= R.Color;
         when Prop_Background_Color =>
            return L.Background_Color /= R.Background_Color;
         when Prop_Background_Image =>
            return L.Background_Image /= R.Background_Image;
         when Prop_Border_Radius => return L.Border_Radius /= R.Border_Radius;
         when Prop_Border_Width => return L.Border_Width /= R.Border_Width;
         when Prop_Border_Color => return L.Border_Color /= R.Border_Color;
         when Prop_Border_Style => return L.Border_Style /= R.Border_Style;
         when Prop_Outline_Width => return L.Outline_Width /= R.Outline_Width;
         when Prop_Outline_Color => return L.Outline_Color /= R.Outline_Color;
         when Prop_Outline_Style => return L.Outline_Style /= R.Outline_Style;
         when Prop_Outline_Offset =>
            return L.Outline_Offset /= R.Outline_Offset;
         when Prop_Padding => return L.Padding /= R.Padding;
         when Prop_Margin => return L.Margin /= R.Margin;
         when Prop_Width => return L.Width /= R.Width;
         when Prop_Height => return L.Height /= R.Height;
         when Prop_Min_Width => return L.Min_Width /= R.Min_Width;
         when Prop_Max_Width => return L.Max_Width /= R.Max_Width;
         when Prop_Min_Height => return L.Min_Height /= R.Min_Height;
         when Prop_Max_Height => return L.Max_Height /= R.Max_Height;
         when Prop_Font_Family => return L.Font_Family /= R.Font_Family;
         when Prop_Font_Size => return L.Font_Size /= R.Font_Size;
         when Prop_Font_Weight => return L.Font_Weight /= R.Font_Weight;
         when Prop_Font_Style => return L.Font_Style /= R.Font_Style;
         when Prop_Text_Align => return L.Text_Align /= R.Text_Align;
         when Prop_Vertical_Align =>
            return L.Vertical_Align /= R.Vertical_Align;
         when Prop_Text_Decoration =>
            return L.Text_Decoration /= R.Text_Decoration;
         when Prop_List_Style_Type =>
            return L.List_Style_Type /= R.List_Style_Type;
         when Prop_List_Style_Image =>
            return L.List_Style_Image /= R.List_Style_Image;
         when Prop_List_Style_Position =>
            return L.List_Style_Position /= R.List_Style_Position;
         when Prop_White_Space => return L.White_Space /= R.White_Space;
         when Prop_Text_Overflow => return L.Text_Overflow /= R.Text_Overflow;
         when Prop_Text_Wrap_Mode =>
            return L.Text_Wrap_Mode /= R.Text_Wrap_Mode;
         when Prop_Line_Height => return L.Line_Height /= R.Line_Height;
         when Prop_Display => return L.Display /= R.Display;
         when Prop_Position => return L.Position /= R.Position;
         when Prop_Overflow =>
            --  Shorthand metadata; the two axes carry it.
            return False;
         when Prop_Overflow_X => return L.Overflow_X /= R.Overflow_X;
         when Prop_Overflow_Y => return L.Overflow_Y /= R.Overflow_Y;
         when Prop_Visibility => return L.Visibility /= R.Visibility;
         when Prop_Top => return L.Top /= R.Top;
         when Prop_Right => return L.Right /= R.Right;
         when Prop_Bottom => return L.Bottom /= R.Bottom;
         when Prop_Left => return L.Left /= R.Left;
         when Prop_Opacity => return L.Opacity /= R.Opacity;
         when Prop_Cursor => return L.Cursor /= R.Cursor;
         when Prop_Box_Shadow => return L.Box_Shadow /= R.Box_Shadow;
         when Prop_Object_Fit => return L.Object_Fit /= R.Object_Fit;
         when Prop_Object_Position =>
            return L.Object_Position /= R.Object_Position;
         when Prop_Flex_Direction =>
            return L.Flex_Direction /= R.Flex_Direction;
         when Prop_Flex_Wrap => return L.Flex_Wrap /= R.Flex_Wrap;
         when Prop_Justify_Content =>
            return L.Justify_Content /= R.Justify_Content;
         when Prop_Align_Items => return L.Align_Items /= R.Align_Items;
         when Prop_Align_Content => return L.Align_Content /= R.Align_Content;
         when Prop_Gap => return L.Gap /= R.Gap;
         when Prop_Grid_Columns =>
            return L.Grid_Columns /= R.Grid_Columns
              or else L.Grid_Column_Tracks /= R.Grid_Column_Tracks;
         when Prop_Grid_Rows => return L.Grid_Rows /= R.Grid_Rows;
         when Prop_Align_Self => return L.Align_Self /= R.Align_Self;
         when Prop_Flex_Grow => return L.Flex_Grow /= R.Flex_Grow;
         when Prop_Flex_Shrink => return L.Flex_Shrink /= R.Flex_Shrink;
         when Prop_Flex_Basis => return L.Flex_Basis /= R.Flex_Basis;
         when Prop_Order => return L.Order /= R.Order;
         when Prop_Grid_Column => return L.Grid_Column /= R.Grid_Column;
         when Prop_Grid_Row => return L.Grid_Row /= R.Grid_Row;
         when Prop_Grid_Column_Span =>
            return L.Grid_Column_Span /= R.Grid_Column_Span;
         when Prop_Grid_Row_Span => return L.Grid_Row_Span /= R.Grid_Row_Span;
         when Prop_Transition => return L.Transition /= R.Transition;
      end case;
   end Property_Differs;

   -------------------------------------------------
   -- Normalize_Color
   -------------------------------------------------

   procedure Normalize_Color (C : Color_Value;
                              R, G, B : out Natural;
                              A : out Float) is
   begin
      case C.Kind is
         when Named =>
            R := Named_Color_RGB (C.Name).R;
            G := Named_Color_RGB (C.Name).G;
            B := Named_Color_RGB (C.Name).B;
            A := (if C.Name = Transparent then 0.0 else 1.0);
         when RGB =>
            R := C.R; G := C.G; B := C.B; A := 1.0;
         when RGBA =>
            R := C.RA; G := C.GA; B := C.BA; A := C.Alpha;
      end case;
   end Normalize_Color;

   -------------------------------------------------
   -- Value_Hash
   -------------------------------------------------

   package body Value_Hash is

      function Add (H : Digest; L : Length_Value) return Digest is
        (Mix (Mix (H, Num (L.Amount)), CSS_Unit'Pos (L.Unit)));

      function Add (H : Digest; C : Color_Value) return Digest is
        (case C.Kind is
            when Named => Mix (Mix (H, 1), Named_Color'Pos (C.Name)),
            when RGB   => Mix (Mix (Mix (Mix (H, 2), Digest (C.R)),
                                    Digest (C.G)), Digest (C.B)),
            when RGBA  => Mix (Mix (Mix (Mix (Mix (H, 3), Digest (C.RA)),
                                         Digest (C.GA)), Digest (C.BA)),
                               Num (C.Alpha)));

      function Add (H : Digest; S : Size_Value) return Digest is
        (case S.Kind is
            when Fixed  => Add (Mix (H, Size_Kind'Pos (S.Kind)), S.Size),
            when others => Mix (H, Size_Kind'Pos (S.Kind)));

      function Add (H : Digest; I : Inset_Value) return Digest is
        (case I.Kind is
            when Fixed => Add (Mix (H, 7), I.Length),
            when Auto  => Mix (H, 8));

      function Add (H : Digest; M : Margin_Value) return Digest is
        (case M.Kind is
            when Fixed => Add (Mix (H, 9), M.Length),
            when Auto  => Mix (H, 10));

      function Add (H : Digest; B : CSS_Box_Value) return Digest is
        (case B.Kind is
            when Gap_Uniform => Add (Mix (H, 11), B.All_Sides),
            when Axis        => Add (Add (Mix (H, 12), B.Vertical),
                                     B.Horizontal),
            when Per_Side    =>
              Add (Add (Add (Add (Mix (H, 13), B.Sides (Top)),
                             B.Sides (Right)),
                        B.Sides (Bottom)), B.Sides (Left)));

      function Add (H : Digest; W : Border_Width_Value) return Digest is
        (case W.Kind is
            when Gap_Uniform => Add (Mix (H, 14), W.All_Edges),
            when Per_Edge    =>
              Add (Add (Add (Add (Mix (H, 15), W.Edges (Top)),
                             W.Edges (Right)),
                        W.Edges (Bottom)), W.Edges (Left)));

      function Add (H : Digest; C : Border_Color_Value) return Digest is
        (case C.Kind is
            when Gap_Uniform => Add (Mix (H, 16), C.All_Edges),
            when Per_Edge    =>
              Add (Add (Add (Add (Mix (H, 17), C.Edges (Top)),
                             C.Edges (Right)),
                        C.Edges (Bottom)), C.Edges (Left)));

      function Add (H : Digest; R : Border_Radius_Value) return Digest is
        (case R.Kind is
            when Gap_Uniform => Add (Mix (H, 18), R.All_Corners),
            when Per_Corner  =>
              Add (Add (Add (Add (Mix (H, 19), R.Corners (Top_Left)),
                             R.Corners (Top_Right)),
                        R.Corners (Bottom_Right)), R.Corners (Bottom_Left)));

      function Add (H : Digest; S : Border_Style_Value) return Digest is
        (case S.Kind is
            when Gap_Uniform =>
              Mix (Mix (H, 20), Border_Style_Kind'Pos (S.All_Edges)),
            when Per_Edge    =>
              Mix (Mix (Mix (Mix (Mix (H, 21),
                                  Border_Style_Kind'Pos (S.Edges (Top))),
                             Border_Style_Kind'Pos (S.Edges (Right))),
                        Border_Style_Kind'Pos (S.Edges (Bottom))),
                   Border_Style_Kind'Pos (S.Edges (Left))));

      function Add (H : Digest; G : Gap_Value) return Digest is
        (case G.Kind is
            when Gap_Uniform  => Add (Mix (H, 22), G.All_Gap),
            when Gap_Separate =>
              Mix (Mix (Add (Add (Mix (H, 23), G.Row_Gap), G.Column_Gap),
                        Boolean'Pos (G.Has_Row)),
                   Boolean'Pos (G.Has_Column)));

      function Add (H : Digest; L : Line_Height_Value) return Digest is
        (case L.Kind is
            when LH_Normal => Mix (H, 24),
            when LH_Number => Mix (Mix (H, 25), Num (L.Multiplier)),
            when LH_Length => Add (Mix (H, 26), L.Height));

      function Add (H : Digest; F : Flex_Basis_Value) return Digest is
        (case F.Kind is
            when Fixed  => Add (Mix (H, 27), F.Size),
            when others => Mix (Mix (H, 28), Flex_Basis_Kind'Pos (F.Kind)));

      function Add (H : Digest; S : Box_Shadow_Value) return Digest is
        (Add (Add (Add (Add (Add (Mix (H, 29), S.Offset_X), S.Offset_Y),
                        S.Blur_Radius), S.Spread_Radius), S.Color));

      function Add (H : Digest; P : Object_Position_Value) return Digest is
        (case P.Kind is
            when Keyword_Pos =>
              Mix (Mix (Mix (H, 30),
                        Object_Position_Keyword'Pos (P.H_Keyword)),
                   Object_Position_Keyword'Pos (P.V_Keyword)),
            when Length_Pos  =>
              Add (Add (Mix (H, 31), P.X_Offset), P.Y_Offset));

      function Add (H : Digest; T : Transition_Spec) return Digest is
         Result : Digest := Mix (Mix (H, Num (T.Duration)),
                                 Easing_Kind'Pos (T.Easing));
      begin
         for P in Animatable_Property loop
            Result := Mix (Result, Boolean'Pos (T.Properties (P)));
         end loop;
         return Result;
      end Add;

      --  A picture reaches the digest as its kind and whether it names a
      --  live image, the two things Image_Handle answers from outside
      --  Adi.Image. A gradient reaches it through the value, which
      --  Shared_Gradient has already made canonical.
      function Add (H : Digest; B : Background_Image_Value) return Digest is
        (case B.Kind is
            when No_Image      => Mix (H, 32),
            when Picture_Image =>
              Mix (Mix (H, 33), Boolean'Pos (Adi.Image.Is_Valid (B.Image))),
            when Url_Image     => Mix (Mix (H, 34), Digest (B.URI)),
            when Linear_Gradient_Image =>
              (if B.Gradient = null then Mix (H, 35)
               else Mix (Mix (Mix (H, 36), Num (B.Gradient.Angle)),
                         Digest (B.Gradient.Stop_Count))));

      function Add (H : Digest; F : Font_Family_Value) return Digest is
        (case F.Kind is
            when By_Handle => Mix (Mix (H, 37), Digest (F.Handle)),
            when By_Name   => Mix (Mix (H, 38), Digest (F.Name)));

      function Add (H : Digest; L : List_Style_Type_Value) return Digest is
        (case L.Kind is
            when List_Style_Custom_String =>
              Mix (Mix (H, 39), Digest (L.Marker)),
            when others =>
              Mix (Mix (H, 40), List_Style_Type_Kind'Pos (L.Kind)));

      function Add (H : Digest; L : List_Style_Image_Value) return Digest is
        (case L.Kind is
            when List_Image_URL  => Mix (Mix (H, 41), Digest (L.URI)),
            when List_Image_None => Mix (H, 42));

      function Add (H : Digest; G : Grid_Track_List) return Digest is
         Result : Digest := Mix (H, Digest (G.Count));
      begin
         for I in 1 .. G.Count loop
            Result := Mix (Mix (Result,
                                Grid_Track_Kind'Pos (G.Tracks (I).Kind)),
                           Num (G.Tracks (I).Value));
         end loop;
         return Result;
      end Add;

   end Value_Hash;

   use Value_Hash;

   -------------------------------------------------
   -- Value stores
   -------------------------------------------------

   --  One store per value type wide enough to want one. Interning is by
   --  value, so RGBA (0, 0, 0, 0.25) named in six rules is one entry,
   --  and a store never releases: the vocabulary a program names is
   --  what bounds it.
   generic
      type Value_Type is private;
      with function Digest (H : Value_Hash.Digest; V : Value_Type)
        return Value_Hash.Digest;
   package Value_Store is
      function Intern (V : Value_Type) return Positive;
      function Get (I : Positive) return Value_Type;
      function Count return Natural;
      function Bytes return Natural;
   end Value_Store;

   package body Value_Store is

      package Value_Vectors is new Ada.Containers.Vectors
        (Positive, Value_Type);
      package Index_Vectors is new Ada.Containers.Vectors (Positive, Positive);

      function Same_Hash (H : Ada.Containers.Hash_Type)
        return Ada.Containers.Hash_Type is (H);

      --  Indexes grouped by digest, so interning probes a handful of
      --  candidates rather than the whole store.
      package Index_Maps is new Ada.Containers.Hashed_Maps
        (Key_Type        => Ada.Containers.Hash_Type,
         Element_Type    => Index_Vectors.Vector,
         Hash            => Same_Hash,
         Equivalent_Keys => Ada.Containers."=",
         "="             => Index_Vectors."=");

      Store    : Value_Vectors.Vector;
      By_Digest : Index_Maps.Map;

      function Count return Natural is (Natural (Store.Length));

      function Bytes return Natural is
        (Count * Value_Type'Max_Size_In_Storage_Elements);

      function Get (I : Positive) return Value_Type is (Store.Element (I));

      function Intern (V : Value_Type) return Positive is
         Key    : constant Ada.Containers.Hash_Type :=
           Digest (Value_Hash.Seed, V);
         Bucket : constant Index_Maps.Cursor := By_Digest.Find (Key);
      begin
         if Index_Maps.Has_Element (Bucket) then
            for I of Index_Maps.Element (Bucket) loop
               if Store.Element (I) = V then
                  return I;
               end if;
            end loop;
         end if;

         Store.Append (V);

         declare
            Fresh_Index : constant Positive := Positive (Store.Length);
         begin
            if Index_Maps.Has_Element (Bucket) then
               By_Digest.Reference (Bucket).Append (Fresh_Index);
            else
               declare
                  Fresh : Index_Vectors.Vector;
               begin
                  Fresh.Append (Fresh_Index);
                  By_Digest.Insert (Key, Fresh);
               end;
            end if;
            return Fresh_Index;
         end;
      end Intern;

   end Value_Store;

   function Float_Digest (H : Value_Hash.Digest; V : Float)
     return Value_Hash.Digest is (Value_Hash.Mix (H, Value_Hash.Num (V)));

   package Color_Values is new Value_Store (Color_Value, Value_Hash.Add);
   package Length_Values is new Value_Store (Length_Value, Value_Hash.Add);
   package Size_Values is new Value_Store (Size_Value, Value_Hash.Add);
   package Box_Values is new Value_Store (CSS_Box_Value, Value_Hash.Add);
   package Border_Width_Values is
     new Value_Store (Border_Width_Value, Value_Hash.Add);
   package Border_Color_Values is
     new Value_Store (Border_Color_Value, Value_Hash.Add);
   package Border_Style_Values is
     new Value_Store (Border_Style_Value, Value_Hash.Add);
   package Border_Radius_Values is
     new Value_Store (Border_Radius_Value, Value_Hash.Add);
   package Gap_Values is new Value_Store (Gap_Value, Value_Hash.Add);
   package Shadow_Values is new Value_Store (Box_Shadow_Value, Value_Hash.Add);
   package Transition_Values is
     new Value_Store (Transition_Spec, Value_Hash.Add);
   package Float_Values is new Value_Store (Float, Float_Digest);

   package Inset_Values is new Value_Store (Inset_Value, Value_Hash.Add);
   package Line_Height_Values is
     new Value_Store (Line_Height_Value, Value_Hash.Add);
   package Flex_Basis_Values is
     new Value_Store (Flex_Basis_Value, Value_Hash.Add);
   package Object_Position_Values is
     new Value_Store (Object_Position_Value, Value_Hash.Add);
   package Bg_Image_Values is
     new Value_Store (Background_Image_Value, Value_Hash.Add);
   package Font_Family_Values is
     new Value_Store (Font_Family_Value, Value_Hash.Add);
   package List_Type_Values is
     new Value_Store (List_Style_Type_Value, Value_Hash.Add);
   package List_Image_Values is
     new Value_Store (List_Style_Image_Value, Value_Hash.Add);

   --  An order is the one signed value a rule holds, so the reference
   --  carries the non-negative ones outright and the store answers for
   --  the rest.
   function Order_Digest (H : Value_Hash.Digest; V : Order_Value)
     return Value_Hash.Digest is
     (Value_Hash.Mix (H, Value_Hash.Digest (Integer (V) mod 2 ** 24)));

   package Order_Values is new Value_Store (Order_Value, Order_Digest);

   --  The two a rule set names through a slot and a chain step never
   --  does: one margin side, and the track list travelling with
   --  grid-template-columns.
   package Margin_Values is new Value_Store (Margin_Value, Value_Hash.Add);
   package Track_Values is new Value_Store (Grid_Track_List, Value_Hash.Add);

   function Interned_Values return Natural is
     (Color_Values.Count + Length_Values.Count + Size_Values.Count
      + Box_Values.Count + Border_Width_Values.Count
      + Border_Color_Values.Count + Border_Style_Values.Count
      + Border_Radius_Values.Count + Gap_Values.Count
      + Shadow_Values.Count + Transition_Values.Count
      + Float_Values.Count + Inset_Values.Count
      + Line_Height_Values.Count + Flex_Basis_Values.Count
      + Object_Position_Values.Count + Bg_Image_Values.Count
      + Font_Family_Values.Count + List_Type_Values.Count
      + List_Image_Values.Count + Order_Values.Count
      + Margin_Values.Count + Track_Values.Count);

   function Interned_Value_Bytes return Natural is
     (Color_Values.Bytes + Length_Values.Bytes + Size_Values.Bytes
      + Box_Values.Bytes + Border_Width_Values.Bytes
      + Border_Color_Values.Bytes + Border_Style_Values.Bytes
      + Border_Radius_Values.Bytes + Gap_Values.Bytes
      + Shadow_Values.Bytes + Transition_Values.Bytes
      + Float_Values.Bytes + Inset_Values.Bytes
      + Line_Height_Values.Bytes + Flex_Basis_Values.Bytes
      + Object_Position_Values.Bytes + Bg_Image_Values.Bytes
      + Font_Family_Values.Bytes + List_Type_Values.Bytes
      + List_Image_Values.Bytes + Order_Values.Bytes
      + Margin_Values.Bytes + Track_Values.Bytes);

   -------------------------------------------------
   -- Value references
   -------------------------------------------------

   Store_Bit    : constant Value_Ref := 2 ** 31;
   Payload_Mask : constant Value_Ref := Store_Bit - 1;

   function Stored (I : Positive) return Value_Ref is
     (Value_Ref (I) or Store_Bit);

   function Immediate (P : Natural) return Value_Ref is (Value_Ref (P));

   function Payload (R : Value_Ref) return Natural is
     (Natural (R and Payload_Mask));

   function Is_Stored (R : Value_Ref) return Boolean is
     ((R and Store_Bit) /= 0);

   function Stored_Index (R : Value_Ref) return Positive is
     (Positive (R and Payload_Mask));

   --  What an immediate holds a number as: a whole magnitude in sixteen
   --  bits, which is what the lengths and the flex factors a stylesheet
   --  writes are. Anything else -- a fraction, a negative, a magnitude
   --  past the bound, a NaN -- reaches the store and reads back exact.
   Whole_Limit : constant := 65_535;

   function Fits_Whole (F : Float) return Boolean is
     (F >= 0.0 and then F <= Float (Whole_Limit)
      and then F = Float'Truncation (F));

   function Whole (F : Float) return Natural is
     (Natural (Float'Truncation (F)));

   ---------------------------------------------------------------------
   --  Colours: a name, or a channel triple in eight bits each. An
   --  alpha, or a channel past 255, reaches the store.
   ---------------------------------------------------------------------

   Color_Named_Tag : constant := 0;
   Color_RGB_Tag   : constant := 1;
   Color_Tag_Unit  : constant := 2 ** 24;

   function Intern (V : Color_Value) return Value_Ref is
   begin
      case V.Kind is
         when Named =>
            return Immediate
              (Color_Named_Tag * Color_Tag_Unit + Named_Color'Pos (V.Name));
         when RGB =>
            if V.R <= 255 and then V.G <= 255 and then V.B <= 255 then
               return Immediate
                 (Color_RGB_Tag * Color_Tag_Unit
                  + V.R * 2 ** 16 + V.G * 2 ** 8 + V.B);
            end if;
         when RGBA =>
            null;
      end case;
      return Stored (Color_Values.Intern (V));
   end Intern;

   function Color_Of (R : Value_Ref) return Color_Value is
   begin
      if Is_Stored (R) then
         return Color_Values.Get (Stored_Index (R));
      end if;

      declare
         Bits : constant Natural := Payload (R) mod Color_Tag_Unit;
      begin
         if Payload (R) / Color_Tag_Unit = Color_Named_Tag then
            return C (Named_Color'Val (Bits));
         end if;
         return RGB (Bits / 2 ** 16, (Bits / 2 ** 8) mod 256, Bits mod 256);
      end;
   end Color_Of;

   ---------------------------------------------------------------------
   --  Lengths and the bare floats: the unit beside a whole magnitude.
   ---------------------------------------------------------------------

   Length_Unit_Unit : constant := 2 ** 16;

   function Intern (V : Length_Value) return Value_Ref is
     (if Fits_Whole (V.Amount)
      then Immediate
        (CSS_Unit'Pos (V.Unit) * Length_Unit_Unit + Whole (V.Amount))
      else Stored (Length_Values.Intern (V)));

   function Length_Of (R : Value_Ref) return Length_Value is
     (if Is_Stored (R) then Length_Values.Get (Stored_Index (R))
      else (Amount => Float (Payload (R) mod Length_Unit_Unit),
            Unit   => CSS_Unit'Val (Payload (R) / Length_Unit_Unit)));

   function Intern_Float (V : Float) return Value_Ref is
     (if Fits_Whole (V) then Immediate (Whole (V))
      else Stored (Float_Values.Intern (V)));

   function Float_Of (R : Value_Ref) return Float is
     (if Is_Stored (R) then Float_Values.Get (Stored_Index (R))
      else Float (Payload (R)));

   function Intern (V : Opacity_Value) return Value_Ref is
     (Intern_Float (Float (V)));

   function Opacity_Of (R : Value_Ref) return Opacity_Value is
     (Opacity_Value (Float_Of (R)));

   function Intern (V : Flex_Grow_Value) return Value_Ref is
     (Intern_Float (Float (V)));

   function Flex_Grow_Of (R : Value_Ref) return Flex_Grow_Value is
     (Flex_Grow_Value (Float_Of (R)));

   function Intern (V : Flex_Shrink_Value) return Value_Ref is
     (Intern_Float (Float (V)));

   function Flex_Shrink_Of (R : Value_Ref) return Flex_Shrink_Value is
     (Flex_Shrink_Value (Float_Of (R)));

   ---------------------------------------------------------------------
   --  The values that always reach a store.
   ---------------------------------------------------------------------

   function Intern (V : Size_Value) return Value_Ref is
     (Stored (Size_Values.Intern (V)));
   function Size_Of (R : Value_Ref) return Size_Value is
     (Size_Values.Get (Stored_Index (R)));

   function Intern (V : CSS_Box_Value) return Value_Ref is
     (Stored (Box_Values.Intern (V)));
   function Box_Of (R : Value_Ref) return CSS_Box_Value is
     (Box_Values.Get (Stored_Index (R)));

   function Intern (V : Border_Width_Value) return Value_Ref is
     (Stored (Border_Width_Values.Intern (V)));
   function Border_Width_Of (R : Value_Ref) return Border_Width_Value is
     (Border_Width_Values.Get (Stored_Index (R)));

   function Intern (V : Border_Color_Value) return Value_Ref is
     (Stored (Border_Color_Values.Intern (V)));
   function Border_Color_Of (R : Value_Ref) return Border_Color_Value is
     (Border_Color_Values.Get (Stored_Index (R)));

   function Intern (V : Border_Style_Value) return Value_Ref is
     (Stored (Border_Style_Values.Intern (V)));
   function Border_Style_Of (R : Value_Ref) return Border_Style_Value is
     (Border_Style_Values.Get (Stored_Index (R)));

   function Intern (V : Border_Radius_Value) return Value_Ref is
     (Stored (Border_Radius_Values.Intern (V)));
   function Border_Radius_Of (R : Value_Ref) return Border_Radius_Value is
     (Border_Radius_Values.Get (Stored_Index (R)));

   function Intern (V : Gap_Value) return Value_Ref is
     (Stored (Gap_Values.Intern (V)));
   function Gap_Of (R : Value_Ref) return Gap_Value is
     (Gap_Values.Get (Stored_Index (R)));

   function Intern (V : Box_Shadow_Value) return Value_Ref is
     (Stored (Shadow_Values.Intern (V)));
   function Box_Shadow_Of (R : Value_Ref) return Box_Shadow_Value is
     (Shadow_Values.Get (Stored_Index (R)));

   function Intern (V : Transition_Spec) return Value_Ref is
     (Stored (Transition_Values.Intern (V)));
   function Transition_Of (R : Value_Ref) return Transition_Spec is
     (Transition_Values.Get (Stored_Index (R)));

   function Intern (V : Inset_Value) return Value_Ref is
     (Stored (Inset_Values.Intern (V)));
   function Inset_Of (R : Value_Ref) return Inset_Value is
     (Inset_Values.Get (Stored_Index (R)));

   function Intern (V : Line_Height_Value) return Value_Ref is
     (Stored (Line_Height_Values.Intern (V)));
   function Line_Height_Of (R : Value_Ref) return Line_Height_Value is
     (Line_Height_Values.Get (Stored_Index (R)));

   function Intern (V : Flex_Basis_Value) return Value_Ref is
     (Stored (Flex_Basis_Values.Intern (V)));
   function Flex_Basis_Of (R : Value_Ref) return Flex_Basis_Value is
     (Flex_Basis_Values.Get (Stored_Index (R)));

   function Intern (V : Object_Position_Value) return Value_Ref is
     (Stored (Object_Position_Values.Intern (V)));
   function Object_Position_Of (R : Value_Ref) return Object_Position_Value is
     (Object_Position_Values.Get (Stored_Index (R)));

   function Intern (V : Background_Image_Value) return Value_Ref is
     (Stored (Bg_Image_Values.Intern (V)));
   function Background_Image_Of (R : Value_Ref)
     return Background_Image_Value is
     (Bg_Image_Values.Get (Stored_Index (R)));

   function Intern (V : Font_Family_Value) return Value_Ref is
     (Stored (Font_Family_Values.Intern (V)));
   function Font_Family_Of (R : Value_Ref) return Font_Family_Value is
     (Font_Family_Values.Get (Stored_Index (R)));

   function Intern (V : List_Style_Type_Value) return Value_Ref is
     (Stored (List_Type_Values.Intern (V)));
   function List_Style_Type_Of (R : Value_Ref) return List_Style_Type_Value is
     (List_Type_Values.Get (Stored_Index (R)));

   function Intern (V : List_Style_Image_Value) return Value_Ref is
     (Stored (List_Image_Values.Intern (V)));
   function List_Style_Image_Of (R : Value_Ref)
     return List_Style_Image_Value is
     (List_Image_Values.Get (Stored_Index (R)));

   ---------------------------------------------------------------------
   --  The one signed value: non-negative in the reference, the rest in
   --  a store.
   ---------------------------------------------------------------------

   function Intern (V : Order_Value) return Value_Ref is
     (if V >= 0 then Immediate (Natural (V))
      else Stored (Order_Values.Intern (V)));

   function Order_Of (R : Value_Ref) return Order_Value is
     (if Is_Stored (R) then Order_Values.Get (Stored_Index (R))
      else Order_Value (Payload (R)));

   ---------------------------------------------------------------------
   --  The enumerations, which are their own reference.
   ---------------------------------------------------------------------

   function Intern (V : Display_Value) return Value_Ref is
     (Immediate (Display_Value'Pos (V)));
   function Display_Of (R : Value_Ref) return Display_Value is
     (Display_Value'Val (Payload (R)));

   function Intern (V : Overflow_Value) return Value_Ref is
     (Immediate (Overflow_Value'Pos (V)));
   function Overflow_Of (R : Value_Ref) return Overflow_Value is
     (Overflow_Value'Val (Payload (R)));

   function Intern (V : Cursor_Value) return Value_Ref is
     (Immediate (Cursor_Value'Pos (V)));
   function Cursor_Of (R : Value_Ref) return Cursor_Value is
     (Cursor_Value'Val (Payload (R)));

   function Intern (V : Text_Align_Value) return Value_Ref is
     (Immediate (Text_Align_Value'Pos (V)));
   function Text_Align_Of (R : Value_Ref) return Text_Align_Value is
     (Text_Align_Value'Val (Payload (R)));

   function Intern (V : Text_Wrap_Mode_Value) return Value_Ref is
     (Immediate (Text_Wrap_Mode_Value'Pos (V)));
   function Text_Wrap_Mode_Of (R : Value_Ref) return Text_Wrap_Mode_Value is
     (Text_Wrap_Mode_Value'Val (Payload (R)));

   function Intern (V : Font_Weight_Value) return Value_Ref is
     (Immediate (Font_Weight_Value'Pos (V)));
   function Font_Weight_Of (R : Value_Ref) return Font_Weight_Value is
     (Font_Weight_Value'Val (Payload (R)));

   function Intern (V : Flex_Direction_Value) return Value_Ref is
     (Immediate (Flex_Direction_Value'Pos (V)));
   function Flex_Direction_Of (R : Value_Ref) return Flex_Direction_Value is
     (Flex_Direction_Value'Val (Payload (R)));

   function Intern (V : Justify_Content_Value) return Value_Ref is
     (Immediate (Justify_Content_Value'Pos (V)));
   function Justify_Content_Of (R : Value_Ref) return Justify_Content_Value is
     (Justify_Content_Value'Val (Payload (R)));

   function Intern (V : Align_Items_Value) return Value_Ref is
     (Immediate (Align_Items_Value'Pos (V)));
   function Align_Items_Of (R : Value_Ref) return Align_Items_Value is
     (Align_Items_Value'Val (Payload (R)));

   function Intern (V : Position_Value) return Value_Ref is
     (Immediate (Position_Value'Pos (V)));
   function Position_Of (R : Value_Ref) return Position_Value is
     (Position_Value'Val (Payload (R)));

   function Intern (V : Visibility_Value) return Value_Ref is
     (Immediate (Visibility_Value'Pos (V)));
   function Visibility_Of (R : Value_Ref) return Visibility_Value is
     (Visibility_Value'Val (Payload (R)));

   function Intern (V : Outline_Style_Kind) return Value_Ref is
     (Immediate (Outline_Style_Kind'Pos (V)));
   function Outline_Style_Of (R : Value_Ref) return Outline_Style_Kind is
     (Outline_Style_Kind'Val (Payload (R)));

   function Intern (V : Font_Style_Value) return Value_Ref is
     (Immediate (Font_Style_Value'Pos (V)));
   function Font_Style_Of (R : Value_Ref) return Font_Style_Value is
     (Font_Style_Value'Val (Payload (R)));

   function Intern (V : Vertical_Align_Value) return Value_Ref is
     (Immediate (Vertical_Align_Value'Pos (V)));
   function Vertical_Align_Of (R : Value_Ref) return Vertical_Align_Value is
     (Vertical_Align_Value'Val (Payload (R)));

   function Intern (V : Text_Decoration_Value) return Value_Ref is
     (Immediate (Text_Decoration_Value'Pos (V)));
   function Text_Decoration_Of (R : Value_Ref) return Text_Decoration_Value is
     (Text_Decoration_Value'Val (Payload (R)));

   function Intern (V : List_Style_Position_Value) return Value_Ref is
     (Immediate (List_Style_Position_Value'Pos (V)));
   function List_Style_Position_Of (R : Value_Ref)
     return List_Style_Position_Value is
     (List_Style_Position_Value'Val (Payload (R)));

   function Intern (V : White_Space_Value) return Value_Ref is
     (Immediate (White_Space_Value'Pos (V)));
   function White_Space_Of (R : Value_Ref) return White_Space_Value is
     (White_Space_Value'Val (Payload (R)));

   function Intern (V : Text_Overflow_Value) return Value_Ref is
     (Immediate (Text_Overflow_Value'Pos (V)));
   function Text_Overflow_Of (R : Value_Ref) return Text_Overflow_Value is
     (Text_Overflow_Value'Val (Payload (R)));

   function Intern (V : Object_Fit_Value) return Value_Ref is
     (Immediate (Object_Fit_Value'Pos (V)));
   function Object_Fit_Of (R : Value_Ref) return Object_Fit_Value is
     (Object_Fit_Value'Val (Payload (R)));

   function Intern (V : Flex_Wrap_Value) return Value_Ref is
     (Immediate (Flex_Wrap_Value'Pos (V)));
   function Flex_Wrap_Of (R : Value_Ref) return Flex_Wrap_Value is
     (Flex_Wrap_Value'Val (Payload (R)));

   function Intern (V : Align_Self_Value) return Value_Ref is
     (Immediate (Align_Self_Value'Pos (V)));
   function Align_Self_Of (R : Value_Ref) return Align_Self_Value is
     (Align_Self_Value'Val (Payload (R)));

   function Intern (V : Align_Content_Value) return Value_Ref is
     (Immediate (Align_Content_Value'Pos (V)));
   function Align_Content_Of (R : Value_Ref) return Align_Content_Value is
     (Align_Content_Value'Val (Payload (R)));

   ---------------------------------------------------------------------
   --  The grid counts and lines, each a Natural, which is exactly what
   --  a reference's payload holds.
   ---------------------------------------------------------------------

   function Intern (V : Grid_Columns_Value) return Value_Ref is
     (Immediate (Natural (V)));
   function Grid_Columns_Of (R : Value_Ref) return Grid_Columns_Value is
     (Grid_Columns_Value (Payload (R)));

   function Intern (V : Grid_Rows_Value) return Value_Ref is
     (Immediate (Natural (V)));
   function Grid_Rows_Of (R : Value_Ref) return Grid_Rows_Value is
     (Grid_Rows_Value (Payload (R)));

   function Intern (V : Grid_Column_Value) return Value_Ref is
     (Immediate (Natural (V)));
   function Grid_Column_Of (R : Value_Ref) return Grid_Column_Value is
     (Grid_Column_Value (Payload (R)));

   function Intern (V : Grid_Row_Value) return Value_Ref is
     (Immediate (Natural (V)));
   function Grid_Row_Of (R : Value_Ref) return Grid_Row_Value is
     (Grid_Row_Value (Payload (R)));

   function Intern (V : Grid_Column_Span_Value) return Value_Ref is
     (Immediate (Natural (V)));
   function Grid_Column_Span_Of (R : Value_Ref)
     return Grid_Column_Span_Value is
     (Grid_Column_Span_Value (Payload (R)));

   function Intern (V : Grid_Row_Span_Value) return Value_Ref is
     (Immediate (Natural (V)));
   function Grid_Row_Span_Of (R : Value_Ref) return Grid_Row_Span_Value is
     (Grid_Row_Span_Value (Payload (R)));

   ---------------------------------------------------------------------
   --  What a slot carries where a chain step carries the whole group:
   --  one margin side, one border-style edge, and the track list.
   ---------------------------------------------------------------------

   function Intern (V : Margin_Value) return Value_Ref is
     (Stored (Margin_Values.Intern (V)));
   function Margin_Of (R : Value_Ref) return Margin_Value is
     (Margin_Values.Get (Stored_Index (R)));

   function Intern (V : Border_Style_Kind) return Value_Ref is
     (Immediate (Border_Style_Kind'Pos (V)));
   function Edge_Style_Of (R : Value_Ref) return Border_Style_Kind is
     (Border_Style_Kind'Val (Payload (R)));

   function Intern (V : Grid_Track_List) return Value_Ref is
     (Stored (Track_Values.Intern (V)));
   function Tracks_Of (R : Value_Ref) return Grid_Track_List is
     (Track_Values.Get (Stored_Index (R)));

   -------------------------------------------------
   -- Folding a named property into a rule set
   -------------------------------------------------

   procedure Set_Overflow_Shorthand
     (S : in out Style_Rules; V : Overflow_Value) is
   begin
      S.Overflow_X := Set_Overflow_X (V);
      S.Overflow_Y := Set_Overflow_Y (V);
   end Set_Overflow_Shorthand;

   procedure Apply_Property
     (S : in out Style_Rules; P : CSS_Property; R : Value_Ref) is
   begin
      case P is
         when Prop_Color =>
            S.Color := Set (Color_Of (R));
         when Prop_Background_Color =>
            S.Background_Color := Set_Bg (Color_Of (R));
         when Prop_Border_Radius =>
            S.Border_Radius := Set (Border_Radius_Of (R));
         when Prop_Border_Width =>
            S.Border_Width := Set (Border_Width_Of (R));
         when Prop_Border_Color =>
            S.Border_Color := Set (Border_Color_Of (R));
         when Prop_Border_Style =>
            S.Border_Style := Set (Border_Style_Of (R));
         when Prop_Outline_Width =>
            S.Outline_Width := Set_Outline_Width (Length_Of (R));
         when Prop_Outline_Color =>
            S.Outline_Color := Set_Outline_Color (Color_Of (R));
         when Prop_Outline_Offset =>
            S.Outline_Offset := Set_Outline_Offset (Length_Of (R));
         when Prop_Padding =>
            S.Padding := Set (Box_Of (R));
         when Prop_Margin =>
            S.Margin := Set_Margin (Box_Of (R));
         when Prop_Width =>
            S.Width := Set (Size_Of (R));
         when Prop_Height =>
            S.Height := Set (Size_Of (R));
         when Prop_Min_Width =>
            S.Min_Width := Set (Size_Of (R));
         when Prop_Max_Width =>
            S.Max_Width := Set (Size_Of (R));
         when Prop_Min_Height =>
            S.Min_Height := Set (Size_Of (R));
         when Prop_Max_Height =>
            S.Max_Height := Set (Size_Of (R));
         when Prop_Font_Size =>
            S.Font_Size := Set_Font (Length_Of (R));
         when Prop_Font_Weight =>
            S.Font_Weight := Set (Font_Weight_Of (R));
         when Prop_Text_Align =>
            S.Text_Align := Set (Text_Align_Of (R));
         when Prop_Text_Wrap_Mode =>
            S.Text_Wrap_Mode := Set (Text_Wrap_Mode_Of (R));
         when Prop_Display =>
            S.Display := Set (Display_Of (R));
         when Prop_Overflow_X =>
            S.Overflow_X := Set (Overflow_Of (R));
         when Prop_Overflow_Y =>
            S.Overflow_Y := Set (Overflow_Of (R));
         when Prop_Opacity =>
            S.Opacity := Set (Opacity_Of (R));
         when Prop_Cursor =>
            S.Cursor := Set (Cursor_Of (R));
         when Prop_Box_Shadow =>
            S.Box_Shadow := Set (Box_Shadow_Of (R));
         when Prop_Flex_Direction =>
            S.Flex_Direction := Set (Flex_Direction_Of (R));
         when Prop_Justify_Content =>
            S.Justify_Content := Set (Justify_Content_Of (R));
         when Prop_Align_Items =>
            S.Align_Items := Set (Align_Items_Of (R));
         when Prop_Gap =>
            --  One field carries both axes, so a value naming one axis
            --  overlays it and leaves the other as it was, and a value
            --  naming both replaces it. Adi.CSS_Parser reads row-gap and
            --  column-gap the same way, so a chain and a sheet agree.
            S.Gap :=
              (if Opt_Gap.Is_Set (S.Gap)
               then Set (Overlay (S.Gap.Value, Gap_Of (R)))
               else Set (Gap_Of (R)));
         when Prop_Flex_Grow =>
            S.Flex_Grow := Set (Flex_Grow_Of (R));
         when Prop_Flex_Shrink =>
            S.Flex_Shrink := Set (Flex_Shrink_Of (R));
         when Prop_Transition =>
            S.Transition := Set (Transition_Of (R));
         when Prop_Background_Image =>
            S.Background_Image := Set_Bg_Image (Background_Image_Of (R));
         when Prop_Outline_Style =>
            S.Outline_Style := Set (Outline_Style_Of (R));
         when Prop_Font_Family =>
            S.Font_Family := Opt_Font.Val (Font_Family_Of (R));
         when Prop_Font_Style =>
            S.Font_Style := Set (Font_Style_Of (R));
         when Prop_Vertical_Align =>
            S.Vertical_Align := Set (Vertical_Align_Of (R));
         when Prop_Text_Decoration =>
            S.Text_Decoration := Set (Text_Decoration_Of (R));
         when Prop_List_Style_Type =>
            S.List_Style_Type := Set (List_Style_Type_Of (R));
         when Prop_List_Style_Image =>
            S.List_Style_Image := Set (List_Style_Image_Of (R));
         when Prop_List_Style_Position =>
            S.List_Style_Position := Set (List_Style_Position_Of (R));
         when Prop_White_Space =>
            S.White_Space := Set (White_Space_Of (R));
         when Prop_Text_Overflow =>
            S.Text_Overflow := Set (Text_Overflow_Of (R));
         when Prop_Line_Height =>
            S.Line_Height := Set (Line_Height_Of (R));
         when Prop_Position =>
            S.Position := Set (Position_Of (R));
         when Prop_Visibility =>
            S.Visibility := Set (Visibility_Of (R));
         when Prop_Top =>
            S.Top := Set_Top (Inset_Of (R));
         when Prop_Right =>
            S.Right := Set_Right (Inset_Of (R));
         when Prop_Bottom =>
            S.Bottom := Set_Bottom (Inset_Of (R));
         when Prop_Left =>
            S.Left := Set_Left (Inset_Of (R));
         when Prop_Object_Fit =>
            S.Object_Fit := Set (Object_Fit_Of (R));
         when Prop_Object_Position =>
            S.Object_Position := Set (Object_Position_Of (R));
         when Prop_Flex_Wrap =>
            S.Flex_Wrap := Set (Flex_Wrap_Of (R));
         when Prop_Align_Content =>
            S.Align_Content := Set (Align_Content_Of (R));
         when Prop_Align_Self =>
            S.Align_Self := Set (Align_Self_Of (R));
         when Prop_Flex_Basis =>
            S.Flex_Basis := Set (Flex_Basis_Of (R));
         when Prop_Order =>
            S.Order := Set (Order_Of (R));
         when Prop_Grid_Columns =>
            S.Grid_Columns := Set (Grid_Columns_Of (R));
         when Prop_Grid_Rows =>
            S.Grid_Rows := Set (Grid_Rows_Of (R));
         when Prop_Grid_Column =>
            S.Grid_Column := Set (Grid_Column_Of (R));
         when Prop_Grid_Row =>
            S.Grid_Row := Set (Grid_Row_Of (R));
         when Prop_Grid_Column_Span =>
            S.Grid_Column_Span := Set (Grid_Column_Span_Of (R));
         when Prop_Grid_Row_Span =>
            S.Grid_Row_Span := Set (Grid_Row_Span_Of (R));
         when Prop_Overflow =>
            --  The shorthand owns no field and is both axes, so one
            --  slot naming it moves both together.
            Set_Overflow_Shorthand (S, Overflow_Of (R));
      end case;
   end Apply_Property;

   procedure Clear_Property (S : in out Style_Rules; P : CSS_Property) is
   begin
      case P is
         when Prop_Color            => S.Color := Opt_Text_Color.Cleared;
         when Prop_Background_Color => S.Background_Color := No_Bg_Color;
         when Prop_Border_Radius    => S.Border_Radius := No_Radius;
         when Prop_Border_Width     => S.Border_Width := No_Border_Width;
         when Prop_Border_Color     => S.Border_Color := No_Border_Color;
         when Prop_Border_Style     => S.Border_Style := No_Border_Style;
         when Prop_Outline_Width  => S.Outline_Width := Opt_Outline_Width.Cleared;
         when Prop_Outline_Color  => S.Outline_Color := Opt_Outline_Color.Cleared;
         when Prop_Outline_Offset =>
            S.Outline_Offset := Opt_Outline_Offset.Cleared;
         when Prop_Padding          => S.Padding := No_Box;
         when Prop_Margin           => S.Margin := No_Margin;
         when Prop_Width            => S.Width := Opt_Size.Cleared;
         when Prop_Height           => S.Height := Opt_Size.Cleared;
         when Prop_Min_Width        => S.Min_Width := Opt_Size.Cleared;
         when Prop_Max_Width        => S.Max_Width := Opt_Size.Cleared;
         when Prop_Min_Height       => S.Min_Height := Opt_Size.Cleared;
         when Prop_Max_Height       => S.Max_Height := Opt_Size.Cleared;
         when Prop_Font_Size        => S.Font_Size := Opt_Font_Size.Cleared;
         when Prop_Font_Weight      => S.Font_Weight := Opt_Font_Weight.Cleared;
         when Prop_Text_Align       => S.Text_Align := Opt_Text_Align.Cleared;
         when Prop_Text_Wrap_Mode =>
            S.Text_Wrap_Mode := Opt_Text_Wrap_Mode.Cleared;
         when Prop_Display          => S.Display := Opt_Display.Cleared;
         when Prop_Overflow_X       => S.Overflow_X := Opt_Overflow.Cleared;
         when Prop_Overflow_Y       => S.Overflow_Y := Opt_Overflow.Cleared;
         when Prop_Opacity          => S.Opacity := Opt_Opacity.Cleared;
         when Prop_Cursor           => S.Cursor := Opt_Cursor.Cleared;
         when Prop_Box_Shadow       => S.Box_Shadow := Opt_Box_Shadow.Cleared;
         when Prop_Flex_Direction   => S.Flex_Direction := Opt_Flex_Dir.Cleared;
         when Prop_Justify_Content  => S.Justify_Content := Opt_Justify.Cleared;
         when Prop_Align_Items      => S.Align_Items := Opt_Align_Items.Cleared;
         when Prop_Gap              => S.Gap := Opt_Gap.Cleared;
         when Prop_Flex_Grow        => S.Flex_Grow := Opt_Flex_Grow.Cleared;
         when Prop_Flex_Shrink      => S.Flex_Shrink := Opt_Flex_Shrink.Cleared;
         when Prop_Transition       => S.Transition := Opt_Transition.Cleared;
         when Prop_Background_Image => S.Background_Image := No_Bg_Image;
         when Prop_Outline_Style =>
            S.Outline_Style := Opt_Outline_Style.Cleared;
         when Prop_Font_Family      => S.Font_Family := Opt_Font.Cleared;
         when Prop_Font_Style       => S.Font_Style := Opt_Font_Style.Cleared;
         when Prop_Vertical_Align =>
            S.Vertical_Align := Opt_Vertical_Align.Cleared;
         when Prop_Text_Decoration =>
            S.Text_Decoration := Opt_Text_Decoration.Cleared;
         when Prop_List_Style_Type =>
            S.List_Style_Type := Opt_List_Style_Type.Cleared;
         when Prop_List_Style_Image =>
            S.List_Style_Image := Opt_List_Style_Image.Cleared;
         when Prop_List_Style_Position =>
            S.List_Style_Position := Opt_List_Style_Position.Cleared;
         when Prop_White_Space =>
            S.White_Space := Opt_White_Space.Cleared;
         when Prop_Text_Overflow =>
            S.Text_Overflow := Opt_Text_Overflow.Cleared;
         when Prop_Line_Height =>
            S.Line_Height := Opt_Line_Height.Cleared;
         when Prop_Position         => S.Position := Opt_Position.Cleared;
         when Prop_Visibility       => S.Visibility := Opt_Visibility.Cleared;
         when Prop_Top              => S.Top := Opt_Top.Cleared;
         when Prop_Right            => S.Right := Opt_Right.Cleared;
         when Prop_Bottom           => S.Bottom := Opt_Bottom.Cleared;
         when Prop_Left             => S.Left := Opt_Left.Cleared;
         when Prop_Object_Fit       => S.Object_Fit := Opt_Object_Fit.Cleared;
         when Prop_Object_Position =>
            S.Object_Position := Opt_Object_Pos.Cleared;
         when Prop_Flex_Wrap        => S.Flex_Wrap := Opt_Flex_Wrap.Cleared;
         when Prop_Align_Content =>
            S.Align_Content := Opt_Align_Content.Cleared;
         when Prop_Align_Self       => S.Align_Self := Opt_Align_Self.Cleared;
         when Prop_Flex_Basis       => S.Flex_Basis := Opt_Flex_Basis.Cleared;
         when Prop_Order            => S.Order := Opt_Order.Cleared;
         --  The property owns a count and a track list, so clearing it
         --  reaches both. The per-part form below names one at a time.
         when Prop_Grid_Columns     =>
            S.Grid_Columns := Opt_Grid_Cols.Cleared;
            S.Grid_Column_Tracks := Opt_Grid_Tracks.Cleared;
         when Prop_Grid_Rows        => S.Grid_Rows := Opt_Grid_Rows.Cleared;
         when Prop_Grid_Column   => S.Grid_Column := Opt_Grid_Column.Cleared;
         when Prop_Grid_Row      => S.Grid_Row := Opt_Grid_Row.Cleared;
         when Prop_Grid_Column_Span =>
            S.Grid_Column_Span := Opt_Grid_Col_Span.Cleared;
         when Prop_Grid_Row_Span =>
            S.Grid_Row_Span := Opt_Grid_Row_Span.Cleared;
         when Prop_Overflow =>
            S.Overflow_X := Opt_Overflow.Cleared;
            S.Overflow_Y := Opt_Overflow.Cleared;
      end case;
   end Clear_Property;

   --  The eight properties whose values cascade one at a time, each
   --  reading Part as the edge, corner or axis it names. A rule naming
   --  border-top-width leaves the other three edges to the cascade,
   --  which is what separates the longhand from the shorthand.
   procedure Apply_Property
     (S : in out Style_Rules; P : CSS_Property; Part : Slot_Part;
      R : Value_Ref) is
   begin
      case P is
         when Prop_Border_Radius =>
            S.Border_Radius (Corner'Val (Natural (Part))) :=
              Opt_Length.Val (Length_Of (R));
         when Prop_Border_Width =>
            S.Border_Width (Edge'Val (Natural (Part))) :=
              Opt_Length.Val (Length_Of (R));
         when Prop_Padding =>
            S.Padding (Edge'Val (Natural (Part))) :=
              Opt_Length.Val (Length_Of (R));
         when Prop_Border_Color =>
            S.Border_Color (Edge'Val (Natural (Part))) :=
              Opt_Edge_Color.Val (Color_Of (R));
         when Prop_Border_Style =>
            S.Border_Style (Edge'Val (Natural (Part))) :=
              Opt_Edge_Style.Val (Edge_Style_Of (R));
         when Prop_Margin =>
            S.Margin (Edge'Val (Natural (Part))) :=
              Opt_Margin.Val (Margin_Of (R));

         --  Two axes over one field, so an axis set folds onto what an
         --  earlier one left.
         when Prop_Gap =>
            declare
               Axis : constant Gap_Value :=
                 (if Part = Gap_Row_Part
                  then Gap_Row (Length_Of (R))
                  else Gap_Column (Length_Of (R)));
            begin
               S.Gap := (if Opt_Gap.Is_Set (S.Gap)
                         then Set (Overlay (S.Gap.Value, Axis))
                         else Set (Axis));
            end;

         --  The track list has no CSS_Property literal and travels
         --  with grid-template-columns, so it is that property's
         --  second part and cascades beside the count.
         when Prop_Grid_Columns =>
            if Part = Tracks_Part then
               S.Grid_Column_Tracks := Set (Tracks_Of (R));
            else
               S.Grid_Columns := Set (Grid_Columns_Of (R));
            end if;

         when Prop_Overflow =>
            null;

         when others =>
            Apply_Property (S, P, R);
      end case;
   end Apply_Property;

   procedure Clear_Property
     (S : in out Style_Rules; P : CSS_Property; Part : Slot_Part) is
   begin
      case P is
         when Prop_Border_Radius =>
            S.Border_Radius (Corner'Val (Natural (Part))) :=
              Opt_Length.Cleared;
         when Prop_Border_Width =>
            S.Border_Width (Edge'Val (Natural (Part))) := Opt_Length.Cleared;
         when Prop_Padding =>
            S.Padding (Edge'Val (Natural (Part))) := Opt_Length.Cleared;
         when Prop_Border_Color =>
            S.Border_Color (Edge'Val (Natural (Part))) :=
              Opt_Edge_Color.Cleared;
         when Prop_Border_Style =>
            S.Border_Style (Edge'Val (Natural (Part))) :=
              Opt_Edge_Style.Cleared;
         when Prop_Margin =>
            S.Margin (Edge'Val (Natural (Part))) := Opt_Margin.Cleared;

         --  The field carries named-or-not per axis rather than
         --  cleared per axis, so a list holding one axis set and the
         --  other cleared has no Opt_Gap to land in. A cleared axis
         --  answers only where no axis is set, so the pair collapses to
         --  the axis that is set and the cleared one reads as unnamed.
         --
         --  Unnamed and cleared resolve alike here, both to
         --  Default_Gap's zero, which is what makes the collapse sound
         --  rather than merely lossless-looking. Two things hold that:
         --  Default_Gap is zero on both axes, and Get_Row_Gap /
         --  Get_Column_Gap read the axis rather than Has_Row /
         --  Has_Column. style_handle_test pins the pair, so making
         --  either of those axis-aware meets a failing test rather than
         --  a silent wrong gap.
         when Prop_Gap =>
            if not Opt_Gap.Is_Set (S.Gap) then
               S.Gap := Opt_Gap.Cleared;
            end if;

         when Prop_Grid_Columns =>
            if Part = Tracks_Part then
               S.Grid_Column_Tracks := Opt_Grid_Tracks.Cleared;
            else
               S.Grid_Columns := Opt_Grid_Cols.Cleared;
            end if;

         when Prop_Overflow =>
            null;

         when others =>
            Clear_Property (S, P);
      end case;
   end Clear_Property;

   -------------------------------------------------
   -- A rule set as a slot list
   -------------------------------------------------

   --  Ordered by property and then by part, which is the order
   --  Slots_Of writes and every walk below relies on.
   function Precedes (A, B : Prop_Slot) return Boolean is
     (if A.Prop /= B.Prop then A.Prop < B.Prop else A.Part < B.Part);

   --  Max_Rule_Slots is the values the whole vocabulary cascades, which
   --  is what makes the list long enough for any rule set: the arms
   --  below emit at most one slot per key, and a merge or an
   --  inheritance pass answers with the union of two such lists, so
   --  nothing composes past it. A sum over a table here would not fold
   --  at compile time, so what holds the figure is
   --  style_property_table_test, which measures it through Slots_Of on
   --  a rule set naming every property.

   function Slot_Count (L : Rule_Slots) return Natural is (L.Count);

   function Slot_Property (L : Rule_Slots; I : Positive) return CSS_Property is
     (L.Items (I).Prop);

   function Slot_Part_Of (L : Rule_Slots; I : Positive) return Slot_Part is
     (L.Items (I).Part);

   ---------------------------------------------------------------------
   --  Style_Rules to slots
   ---------------------------------------------------------------------

   function Slots_Of (S : Style_Rules) return Rule_Slots is
      L : Rule_Slots;

      procedure Emit (P : CSS_Property; Part : Slot_Part; R : Value_Ref);
      procedure Wipe (P : CSS_Property; Part : Slot_Part);

      procedure Emit (P : CSS_Property; Part : Slot_Part; R : Value_Ref) is
      begin
         L.Count := L.Count + 1;
         L.Items (L.Count) := (P, Part, Set_Value, R);
      end Emit;

      procedure Wipe (P : CSS_Property; Part : Slot_Part) is
      begin
         L.Count := L.Count + 1;
         L.Items (L.Count) := (P, Part, Clear_Value, No_Value_Ref);
      end Wipe;
   begin
      for P in CSS_Property loop
         case P is
            --  The six groups, each value cascading on its own.
            when Prop_Border_Radius =>
               for C in Corner loop
                  if Opt_Length.Is_Set (S.Border_Radius (C)) then
                     Emit (P, Slot_Part (Corner'Pos (C)),
                           Intern (S.Border_Radius (C).Value));
                  elsif Opt_Length.Is_None (S.Border_Radius (C)) then
                     Wipe (P, Slot_Part (Corner'Pos (C)));
                  end if;
               end loop;
            when Prop_Border_Width =>
               for E in Edge loop
                  if Opt_Length.Is_Set (S.Border_Width (E)) then
                     Emit (P, Slot_Part (Edge'Pos (E)),
                           Intern (S.Border_Width (E).Value));
                  elsif Opt_Length.Is_None (S.Border_Width (E)) then
                     Wipe (P, Slot_Part (Edge'Pos (E)));
                  end if;
               end loop;
            when Prop_Padding =>
               for E in Edge loop
                  if Opt_Length.Is_Set (S.Padding (E)) then
                     Emit (P, Slot_Part (Edge'Pos (E)),
                           Intern (S.Padding (E).Value));
                  elsif Opt_Length.Is_None (S.Padding (E)) then
                     Wipe (P, Slot_Part (Edge'Pos (E)));
                  end if;
               end loop;
            when Prop_Border_Color =>
               for E in Edge loop
                  if Opt_Edge_Color.Is_Set (S.Border_Color (E)) then
                     Emit (P, Slot_Part (Edge'Pos (E)),
                           Intern (S.Border_Color (E).Value));
                  elsif Opt_Edge_Color.Is_None (S.Border_Color (E)) then
                     Wipe (P, Slot_Part (Edge'Pos (E)));
                  end if;
               end loop;
            when Prop_Border_Style =>
               for E in Edge loop
                  if Opt_Edge_Style.Is_Set (S.Border_Style (E)) then
                     Emit (P, Slot_Part (Edge'Pos (E)),
                           Intern (S.Border_Style (E).Value));
                  elsif Opt_Edge_Style.Is_None (S.Border_Style (E)) then
                     Wipe (P, Slot_Part (Edge'Pos (E)));
                  end if;
               end loop;
            when Prop_Margin =>
               for E in Edge loop
                  if Opt_Margin.Is_Set (S.Margin (E)) then
                     Emit (P, Slot_Part (Edge'Pos (E)),
                           Intern (S.Margin (E).Value));
                  elsif Opt_Margin.Is_None (S.Margin (E)) then
                     Wipe (P, Slot_Part (Edge'Pos (E)));
                  end if;
               end loop;

            --  One field, two axes: a value naming one axis leaves the
            --  other to the cascade, which is a slot naming one part.
            when Prop_Gap =>
               if Opt_Gap.Is_Set (S.Gap) then
                  declare
                     G : Gap_Value renames S.Gap.Value;
                  begin
                     if G.Kind = Gap_Uniform then
                        Emit (P, Gap_Row_Part, Intern (G.All_Gap));
                        Emit (P, Gap_Column_Part, Intern (G.All_Gap));
                     else
                        if G.Has_Row then
                           Emit (P, Gap_Row_Part, Intern (G.Row_Gap));
                        end if;
                        if G.Has_Column then
                           Emit (P, Gap_Column_Part, Intern (G.Column_Gap));
                        end if;
                     end if;
                  end;
               elsif Opt_Gap.Is_None (S.Gap) then
                  Wipe (P, Gap_Row_Part);
                  Wipe (P, Gap_Column_Part);
               end if;

            --  The track list has no CSS_Property literal and travels
            --  with grid-template-columns, so it is that property's
            --  second part and cascades beside the count.
            when Prop_Grid_Columns =>
               if Opt_Grid_Cols.Is_Set (S.Grid_Columns) then
                  Emit (P, First_Part, Intern (S.Grid_Columns.Value));
               elsif Opt_Grid_Cols.Is_None (S.Grid_Columns) then
                  Wipe (P, First_Part);
               end if;
               if Opt_Grid_Tracks.Is_Set (S.Grid_Column_Tracks) then
                  Emit (P, Tracks_Part, Intern (S.Grid_Column_Tracks.Value));
               elsif Opt_Grid_Tracks.Is_None (S.Grid_Column_Tracks) then
                  Wipe (P, Tracks_Part);
               end if;

            --  The shorthand owns no field: a rule set holds it as its
            --  two axes, and those are the slots it carries.
            when Prop_Overflow =>
               null;

            when Prop_Color =>
               if Opt_Text_Color.Is_Set (S.Color) then
                  Emit (P, First_Part, Intern (S.Color.Value));
               elsif Opt_Text_Color.Is_None (S.Color) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Background_Color =>
               if Opt_Bg_Color.Is_Set (S.Background_Color) then
                  Emit (P, First_Part, Intern (S.Background_Color.Value));
               elsif Opt_Bg_Color.Is_None (S.Background_Color) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Background_Image =>
               if Opt_Bg_Image.Is_Set (S.Background_Image) then
                  Emit (P, First_Part, Intern (S.Background_Image.Value));
               elsif Opt_Bg_Image.Is_None (S.Background_Image) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Outline_Width =>
               if Opt_Outline_Width.Is_Set (S.Outline_Width) then
                  Emit (P, First_Part, Intern (S.Outline_Width.Value));
               elsif Opt_Outline_Width.Is_None (S.Outline_Width) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Outline_Color =>
               if Opt_Outline_Color.Is_Set (S.Outline_Color) then
                  Emit (P, First_Part, Intern (S.Outline_Color.Value));
               elsif Opt_Outline_Color.Is_None (S.Outline_Color) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Outline_Style =>
               if Opt_Outline_Style.Is_Set (S.Outline_Style) then
                  Emit (P, First_Part, Intern (S.Outline_Style.Value));
               elsif Opt_Outline_Style.Is_None (S.Outline_Style) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Outline_Offset =>
               if Opt_Outline_Offset.Is_Set (S.Outline_Offset) then
                  Emit (P, First_Part, Intern (S.Outline_Offset.Value));
               elsif Opt_Outline_Offset.Is_None (S.Outline_Offset) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Width =>
               if Opt_Size.Is_Set (S.Width) then
                  Emit (P, First_Part, Intern (S.Width.Value));
               elsif Opt_Size.Is_None (S.Width) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Height =>
               if Opt_Size.Is_Set (S.Height) then
                  Emit (P, First_Part, Intern (S.Height.Value));
               elsif Opt_Size.Is_None (S.Height) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Min_Width =>
               if Opt_Size.Is_Set (S.Min_Width) then
                  Emit (P, First_Part, Intern (S.Min_Width.Value));
               elsif Opt_Size.Is_None (S.Min_Width) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Max_Width =>
               if Opt_Size.Is_Set (S.Max_Width) then
                  Emit (P, First_Part, Intern (S.Max_Width.Value));
               elsif Opt_Size.Is_None (S.Max_Width) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Min_Height =>
               if Opt_Size.Is_Set (S.Min_Height) then
                  Emit (P, First_Part, Intern (S.Min_Height.Value));
               elsif Opt_Size.Is_None (S.Min_Height) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Max_Height =>
               if Opt_Size.Is_Set (S.Max_Height) then
                  Emit (P, First_Part, Intern (S.Max_Height.Value));
               elsif Opt_Size.Is_None (S.Max_Height) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Font_Family =>
               if Opt_Font.Is_Set (S.Font_Family) then
                  Emit (P, First_Part, Intern (S.Font_Family.Value));
               elsif Opt_Font.Is_None (S.Font_Family) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Font_Size =>
               if Opt_Font_Size.Is_Set (S.Font_Size) then
                  Emit (P, First_Part, Intern (S.Font_Size.Value));
               elsif Opt_Font_Size.Is_None (S.Font_Size) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Font_Weight =>
               if Opt_Font_Weight.Is_Set (S.Font_Weight) then
                  Emit (P, First_Part, Intern (S.Font_Weight.Value));
               elsif Opt_Font_Weight.Is_None (S.Font_Weight) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Font_Style =>
               if Opt_Font_Style.Is_Set (S.Font_Style) then
                  Emit (P, First_Part, Intern (S.Font_Style.Value));
               elsif Opt_Font_Style.Is_None (S.Font_Style) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Text_Align =>
               if Opt_Text_Align.Is_Set (S.Text_Align) then
                  Emit (P, First_Part, Intern (S.Text_Align.Value));
               elsif Opt_Text_Align.Is_None (S.Text_Align) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Vertical_Align =>
               if Opt_Vertical_Align.Is_Set (S.Vertical_Align) then
                  Emit (P, First_Part, Intern (S.Vertical_Align.Value));
               elsif Opt_Vertical_Align.Is_None (S.Vertical_Align) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Text_Decoration =>
               if Opt_Text_Decoration.Is_Set (S.Text_Decoration) then
                  Emit (P, First_Part, Intern (S.Text_Decoration.Value));
               elsif Opt_Text_Decoration.Is_None (S.Text_Decoration) then
                  Wipe (P, First_Part);
               end if;
            when Prop_List_Style_Type =>
               if Opt_List_Style_Type.Is_Set (S.List_Style_Type) then
                  Emit (P, First_Part, Intern (S.List_Style_Type.Value));
               elsif Opt_List_Style_Type.Is_None (S.List_Style_Type) then
                  Wipe (P, First_Part);
               end if;
            when Prop_List_Style_Image =>
               if Opt_List_Style_Image.Is_Set (S.List_Style_Image) then
                  Emit (P, First_Part, Intern (S.List_Style_Image.Value));
               elsif Opt_List_Style_Image.Is_None (S.List_Style_Image) then
                  Wipe (P, First_Part);
               end if;
            when Prop_List_Style_Position =>
               if Opt_List_Style_Position.Is_Set (S.List_Style_Position) then
                  Emit (P, First_Part, Intern (S.List_Style_Position.Value));
               elsif Opt_List_Style_Position.Is_None (S.List_Style_Position)
               then
                  Wipe (P, First_Part);
               end if;
            when Prop_White_Space =>
               if Opt_White_Space.Is_Set (S.White_Space) then
                  Emit (P, First_Part, Intern (S.White_Space.Value));
               elsif Opt_White_Space.Is_None (S.White_Space) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Text_Overflow =>
               if Opt_Text_Overflow.Is_Set (S.Text_Overflow) then
                  Emit (P, First_Part, Intern (S.Text_Overflow.Value));
               elsif Opt_Text_Overflow.Is_None (S.Text_Overflow) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Text_Wrap_Mode =>
               if Opt_Text_Wrap_Mode.Is_Set (S.Text_Wrap_Mode) then
                  Emit (P, First_Part, Intern (S.Text_Wrap_Mode.Value));
               elsif Opt_Text_Wrap_Mode.Is_None (S.Text_Wrap_Mode) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Line_Height =>
               if Opt_Line_Height.Is_Set (S.Line_Height) then
                  Emit (P, First_Part, Intern (S.Line_Height.Value));
               elsif Opt_Line_Height.Is_None (S.Line_Height) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Display =>
               if Opt_Display.Is_Set (S.Display) then
                  Emit (P, First_Part, Intern (S.Display.Value));
               elsif Opt_Display.Is_None (S.Display) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Position =>
               if Opt_Position.Is_Set (S.Position) then
                  Emit (P, First_Part, Intern (S.Position.Value));
               elsif Opt_Position.Is_None (S.Position) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Overflow_X =>
               if Opt_Overflow.Is_Set (S.Overflow_X) then
                  Emit (P, First_Part, Intern (S.Overflow_X.Value));
               elsif Opt_Overflow.Is_None (S.Overflow_X) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Overflow_Y =>
               if Opt_Overflow.Is_Set (S.Overflow_Y) then
                  Emit (P, First_Part, Intern (S.Overflow_Y.Value));
               elsif Opt_Overflow.Is_None (S.Overflow_Y) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Visibility =>
               if Opt_Visibility.Is_Set (S.Visibility) then
                  Emit (P, First_Part, Intern (S.Visibility.Value));
               elsif Opt_Visibility.Is_None (S.Visibility) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Top =>
               if Opt_Top.Is_Set (S.Top) then
                  Emit (P, First_Part, Intern (S.Top.Value));
               elsif Opt_Top.Is_None (S.Top) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Right =>
               if Opt_Right.Is_Set (S.Right) then
                  Emit (P, First_Part, Intern (S.Right.Value));
               elsif Opt_Right.Is_None (S.Right) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Bottom =>
               if Opt_Bottom.Is_Set (S.Bottom) then
                  Emit (P, First_Part, Intern (S.Bottom.Value));
               elsif Opt_Bottom.Is_None (S.Bottom) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Left =>
               if Opt_Left.Is_Set (S.Left) then
                  Emit (P, First_Part, Intern (S.Left.Value));
               elsif Opt_Left.Is_None (S.Left) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Opacity =>
               if Opt_Opacity.Is_Set (S.Opacity) then
                  Emit (P, First_Part, Intern (S.Opacity.Value));
               elsif Opt_Opacity.Is_None (S.Opacity) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Cursor =>
               if Opt_Cursor.Is_Set (S.Cursor) then
                  Emit (P, First_Part, Intern (S.Cursor.Value));
               elsif Opt_Cursor.Is_None (S.Cursor) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Box_Shadow =>
               if Opt_Box_Shadow.Is_Set (S.Box_Shadow) then
                  Emit (P, First_Part, Intern (S.Box_Shadow.Value));
               elsif Opt_Box_Shadow.Is_None (S.Box_Shadow) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Object_Fit =>
               if Opt_Object_Fit.Is_Set (S.Object_Fit) then
                  Emit (P, First_Part, Intern (S.Object_Fit.Value));
               elsif Opt_Object_Fit.Is_None (S.Object_Fit) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Object_Position =>
               if Opt_Object_Pos.Is_Set (S.Object_Position) then
                  Emit (P, First_Part, Intern (S.Object_Position.Value));
               elsif Opt_Object_Pos.Is_None (S.Object_Position) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Flex_Direction =>
               if Opt_Flex_Dir.Is_Set (S.Flex_Direction) then
                  Emit (P, First_Part, Intern (S.Flex_Direction.Value));
               elsif Opt_Flex_Dir.Is_None (S.Flex_Direction) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Flex_Wrap =>
               if Opt_Flex_Wrap.Is_Set (S.Flex_Wrap) then
                  Emit (P, First_Part, Intern (S.Flex_Wrap.Value));
               elsif Opt_Flex_Wrap.Is_None (S.Flex_Wrap) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Justify_Content =>
               if Opt_Justify.Is_Set (S.Justify_Content) then
                  Emit (P, First_Part, Intern (S.Justify_Content.Value));
               elsif Opt_Justify.Is_None (S.Justify_Content) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Align_Items =>
               if Opt_Align_Items.Is_Set (S.Align_Items) then
                  Emit (P, First_Part, Intern (S.Align_Items.Value));
               elsif Opt_Align_Items.Is_None (S.Align_Items) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Align_Content =>
               if Opt_Align_Content.Is_Set (S.Align_Content) then
                  Emit (P, First_Part, Intern (S.Align_Content.Value));
               elsif Opt_Align_Content.Is_None (S.Align_Content) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Grid_Rows =>
               if Opt_Grid_Rows.Is_Set (S.Grid_Rows) then
                  Emit (P, First_Part, Intern (S.Grid_Rows.Value));
               elsif Opt_Grid_Rows.Is_None (S.Grid_Rows) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Align_Self =>
               if Opt_Align_Self.Is_Set (S.Align_Self) then
                  Emit (P, First_Part, Intern (S.Align_Self.Value));
               elsif Opt_Align_Self.Is_None (S.Align_Self) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Flex_Grow =>
               if Opt_Flex_Grow.Is_Set (S.Flex_Grow) then
                  Emit (P, First_Part, Intern (S.Flex_Grow.Value));
               elsif Opt_Flex_Grow.Is_None (S.Flex_Grow) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Flex_Shrink =>
               if Opt_Flex_Shrink.Is_Set (S.Flex_Shrink) then
                  Emit (P, First_Part, Intern (S.Flex_Shrink.Value));
               elsif Opt_Flex_Shrink.Is_None (S.Flex_Shrink) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Flex_Basis =>
               if Opt_Flex_Basis.Is_Set (S.Flex_Basis) then
                  Emit (P, First_Part, Intern (S.Flex_Basis.Value));
               elsif Opt_Flex_Basis.Is_None (S.Flex_Basis) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Order =>
               if Opt_Order.Is_Set (S.Order) then
                  Emit (P, First_Part, Intern (S.Order.Value));
               elsif Opt_Order.Is_None (S.Order) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Grid_Column =>
               if Opt_Grid_Column.Is_Set (S.Grid_Column) then
                  Emit (P, First_Part, Intern (S.Grid_Column.Value));
               elsif Opt_Grid_Column.Is_None (S.Grid_Column) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Grid_Row =>
               if Opt_Grid_Row.Is_Set (S.Grid_Row) then
                  Emit (P, First_Part, Intern (S.Grid_Row.Value));
               elsif Opt_Grid_Row.Is_None (S.Grid_Row) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Grid_Column_Span =>
               if Opt_Grid_Col_Span.Is_Set (S.Grid_Column_Span) then
                  Emit (P, First_Part, Intern (S.Grid_Column_Span.Value));
               elsif Opt_Grid_Col_Span.Is_None (S.Grid_Column_Span) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Grid_Row_Span =>
               if Opt_Grid_Row_Span.Is_Set (S.Grid_Row_Span) then
                  Emit (P, First_Part, Intern (S.Grid_Row_Span.Value));
               elsif Opt_Grid_Row_Span.Is_None (S.Grid_Row_Span) then
                  Wipe (P, First_Part);
               end if;
            when Prop_Transition =>
               if Opt_Transition.Is_Set (S.Transition) then
                  Emit (P, First_Part, Intern (S.Transition.Value));
               elsif Opt_Transition.Is_None (S.Transition) then
                  Wipe (P, First_Part);
               end if;
         end case;
      end loop;
      return L;
   end Slots_Of;

   ---------------------------------------------------------------------
   --  Slots to Style_Rules
   ---------------------------------------------------------------------

   --  Apply_Property and Clear_Property answer for every property whose
   --  slot carries the whole field, which is all but the eight that
   --  carry a value per part.
   function Materialise (L : Slot_List) return Style_Rules is
      S : Style_Rules;
   begin
      for I in L'Range loop
         declare
            E : Prop_Slot renames L (I);
         begin
            case E.Op is
               when Set_Value   => Apply_Property (S, E.Prop, E.Part, E.Val);
               when Clear_Value => Clear_Property (S, E.Prop, E.Part);
            end case;
         end;
      end loop;
      return S;
   end Materialise;

   function Rules_Of (L : Rule_Slots) return Style_Rules is
     (Materialise (L.Items (1 .. L.Count)));

   function Resolve (L : Rule_Slots) return Resolved_Style is
     (Resolve (Rules_Of (L)));

   ---------------------------------------------------------------------
   --  Filling a list one value at a time
   ---------------------------------------------------------------------

   --  Insert-or-replace on the key, which holds the list ordered and
   --  one slot deep per key.
   procedure Put (L : in out Rule_Slots; E : Prop_Slot) is
      I : Positive := 1;
   begin
      while I <= L.Count and then Precedes (L.Items (I), E) loop
         I := I + 1;
      end loop;

      if I <= L.Count
        and then L.Items (I).Prop = E.Prop
        and then L.Items (I).Part = E.Part
      then
         L.Items (I) := E;
         return;
      end if;

      --  A full list holds every key Slots_Of emits, so a key arriving
      --  past the cap is one outside that set -- a property that gained
      --  a part, or a caller naming a part Slots_Of leaves unnamed.
      --  Saying so beats the slice assignment below faulting on an
      --  index nothing explains. parser_slots_test holds the set closed
      --  over every property and part the two Apply_Property can name.
      if L.Count >= Max_Rule_Slots then
         raise Program_Error with
           "css: " & E.Prop'Image & " part" & E.Part'Image
           & " is a rule-set key past the" & Natural'Image (Max_Rule_Slots)
           & " Slots_Of names";
      end if;

      L.Items (I + 1 .. L.Count + 1) := L.Items (I .. L.Count);
      L.Items (I) := E;
      L.Count := L.Count + 1;
   end Put;

   --  Leaves the key unnamed, and the freed entry at its default so
   --  that two lists carrying the same slots carry the same bytes.
   procedure Take_Out
     (L : in out Rule_Slots; P : CSS_Property; Part : Slot_Part) is
   begin
      for I in 1 .. L.Count loop
         if L.Items (I).Prop = P and then L.Items (I).Part = Part then
            L.Items (I .. L.Count - 1) := L.Items (I + 1 .. L.Count);
            L.Items (L.Count) := (others => <>);
            L.Count := L.Count - 1;
            return;
         end if;
      end loop;
   end Take_Out;

   --  What a value comes to in slots is what Slots_Of answers for a
   --  rule set naming that property alone, so the shapes carrying more
   --  than one slot -- four edges, two axes, a count beside a track
   --  list -- are stated once, where Slots_Of states them.
   procedure Take_Slots (L : in out Rule_Slots; Named : Style_Rules) is
      Fresh : constant Rule_Slots := Slots_Of (Named);
   begin
      for I in 1 .. Fresh.Count loop
         Put (L, Fresh.Items (I));
      end loop;
   end Take_Slots;

   --  Every part the property owns leaves at once, which is what a
   --  whole value answers for: a shorthand takes over from a longhand
   --  ahead of it.
   procedure Take_Out_All (L : in out Rule_Slots; P : CSS_Property) is
      Kept : Natural := 0;
   begin
      for I in 1 .. L.Count loop
         if L.Items (I).Prop /= P then
            Kept := Kept + 1;
            L.Items (Kept) := L.Items (I);
         end if;
      end loop;

      for I in Kept + 1 .. L.Count loop
         L.Items (I) := (others => <>);
      end loop;

      L.Count := Kept;
   end Take_Out_All;

   procedure Apply_Property
     (L : in out Rule_Slots; P : CSS_Property; R : Value_Ref)
   is
      Named : Style_Rules;
   begin
      Apply_Property (Named, P, R);
      Take_Out_All (L, P);
      Take_Slots (L, Named);
   end Apply_Property;

   procedure Apply_Property
     (L : in out Rule_Slots; P : CSS_Property; Part : Slot_Part;
      R : Value_Ref)
   is
      Named : Style_Rules;
   begin
      Apply_Property (Named, P, Part, R);
      Take_Out (L, P, Part);
      Take_Slots (L, Named);
   end Apply_Property;

   ---------------------------------------------------------------------
   --  Merging and inheriting: two ordered lists, one walk
   ---------------------------------------------------------------------

   function Merge_Lists (Base, Override : Slot_List) return Rule_Slots is
      L : Rule_Slots;
      I : Natural := Base'First;
      J : Natural := Override'First;

      procedure Take (E : Prop_Slot);
      procedure Take (E : Prop_Slot) is
      begin
         L.Count := L.Count + 1;
         L.Items (L.Count) := E;
      end Take;
   begin
      while I <= Base'Last and then J <= Override'Last loop
         if Precedes (Base (I), Override (J)) then
            Take (Base (I));
            I := I + 1;
         elsif Precedes (Override (J), Base (I)) then
            Take (Override (J));
            J := J + 1;
         else
            Take (Override (J));
            I := I + 1;
            J := J + 1;
         end if;
      end loop;

      while I <= Base'Last loop
         Take (Base (I));
         I := I + 1;
      end loop;

      while J <= Override'Last loop
         Take (Override (J));
         J := J + 1;
      end loop;

      return L;
   end Merge_Lists;

   function Merge (Base, Override : Rule_Slots) return Rule_Slots is
     (Merge_Lists (Base.Items (1 .. Base.Count),
                   Override.Items (1 .. Override.Count)));

   function Inherit_From (Parent, Child : Rule_Slots) return Rule_Slots is
      L : Rule_Slots;
      I : Natural := 1;
      J : Natural := 1;

      procedure Take (E : Prop_Slot);
      procedure Take_Inherited (E : Prop_Slot);

      procedure Take (E : Prop_Slot) is
      begin
         L.Count := L.Count + 1;
         L.Items (L.Count) := E;
      end Take;

      procedure Take_Inherited (E : Prop_Slot) is
      begin
         if Inheritable_Properties (E.Prop) then
            Take (E);
         end if;
      end Take_Inherited;
   begin
      while I <= Parent.Count and then J <= Child.Count loop
         if Precedes (Parent.Items (I), Child.Items (J)) then
            Take_Inherited (Parent.Items (I));
            I := I + 1;
         elsif Precedes (Child.Items (J), Parent.Items (I)) then
            Take (Child.Items (J));
            J := J + 1;
         else
            Take (Child.Items (J));
            I := I + 1;
            J := J + 1;
         end if;
      end loop;

      while I <= Parent.Count loop
         Take_Inherited (Parent.Items (I));
         I := I + 1;
      end loop;

      while J <= Child.Count loop
         Take (Child.Items (J));
         J := J + 1;
      end loop;

      return L;
   end Inherit_From;

   function Set_Properties (L : Rule_Slots) return CSS_Property_Set is
      Named : CSS_Property_Set := [others => False];
   begin
      for I in 1 .. L.Count loop
         Named (L.Items (I).Prop) := True;
      end loop;
      return Named;
   end Set_Properties;

   function Hash (L : Rule_Slots) return Ada.Containers.Hash_Type is
      H : Digest := Seed;
   begin
      for I in 1 .. L.Count loop
         H := Mix (H, CSS_Property'Pos (L.Items (I).Prop));
         H := Mix (H, Slot_Op'Pos (L.Items (I).Op));
         H := Mix (H, Digest (L.Items (I).Val));
      end loop;
      return H;
   end Hash;

   function Hash (S : Style_Rules) return Ada.Containers.Hash_Type is
     (Hash (Slots_Of (S)));

   ---------------------------------------------------------------------
   --  The store
   ---------------------------------------------------------------------

   type Slot_List_Access is access constant Slot_List;

   package Rules_Vectors is new Ada.Containers.Vectors
     (Positive, Slot_List_Access);

   Rules_Store : Rules_Vectors.Vector;

   package Rules_Handle_Vectors is new Ada.Containers.Vectors
     (Positive, Rules_Handle);

   function Same_Digest (H : Ada.Containers.Hash_Type)
     return Ada.Containers.Hash_Type is (H);

   --  Handles grouped by digest, so interning compares against a
   --  handful of candidates rather than the whole store.
   package Rules_Index_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Ada.Containers.Hash_Type,
      Element_Type    => Rules_Handle_Vectors.Vector,
      Hash            => Same_Digest,
      Equivalent_Keys => Ada.Containers."=",
      "="             => Rules_Handle_Vectors."=");

   Rules_Index : Rules_Index_Maps.Map;

   No_Slots : aliased constant Slot_List := [];

   Rule_Set_Count : Natural := 0;
   Rule_Set_Bytes : Natural := 0;

   function Interned_Rule_Sets return Natural is (Rule_Set_Count);
   function Interned_Rule_Bytes return Natural is (Rule_Set_Bytes);

   --  The stored slots in place. The address stays good for the life of
   --  the process.
   function Slot_Ref (H : Rules_Handle) return not null Slot_List_Access;

   function Slot_Ref (H : Rules_Handle) return not null Slot_List_Access is
   begin
      if H = Empty_Rules
        or else Natural (H) > Natural (Rules_Store.Length)
      then
         return No_Slots'Access;
      end if;
      return Rules_Store.Element (Positive (H));
   end Slot_Ref;

   function Slots_Of (H : Rules_Handle) return Rule_Slots is
      Stored_Slots : constant Slot_List_Access := Slot_Ref (H);
      L            : Rule_Slots;
   begin
      L.Count := Stored_Slots'Length;
      L.Items (1 .. L.Count) := Stored_Slots.all;
      return L;
   end Slots_Of;


   function Merge (Base : Rule_Slots; Override : Rules_Handle)
     return Rule_Slots is
     (Merge_Lists (Base.Items (1 .. Base.Count), Slot_Ref (Override).all));

   function Rules_Of (H : Rules_Handle) return Style_Rules is
     (Materialise (Slot_Ref (H).all));

   function Index (H : Rules_Handle) return Natural is (Natural (H));

   function Intern_Rules (L : Rule_Slots) return Rules_Handle is
   begin
      if L.Count = 0 then
         return Empty_Rules;
      end if;

      declare
         Named    : constant Slot_List := L.Items (1 .. L.Count);
         Key      : constant Ada.Containers.Hash_Type := Hash (L);
         Bucket   : constant Rules_Index_Maps.Cursor := Rules_Index.Find (Key);
         Interned : Rules_Handle;
      begin
         if Rules_Index_Maps.Has_Element (Bucket) then
            for H of Rules_Index_Maps.Element (Bucket) loop
               if Rules_Store.Element (Positive (H)).all = Named then
                  return H;
               end if;
            end loop;
         end if;

         Rules_Store.Append (new Slot_List'(Named));
         Interned := Rules_Handle (Rules_Store.Length);
         Rule_Set_Count := Natural (Rules_Store.Length);
         Rule_Set_Bytes :=
           Rule_Set_Bytes
           + Named'Length * Prop_Slot'Max_Size_In_Storage_Elements;

         if Rules_Index_Maps.Has_Element (Bucket) then
            Rules_Index.Reference (Bucket).Append (Interned);
         else
            declare
               Fresh : Rules_Handle_Vectors.Vector;
            begin
               Fresh.Append (Interned);
               Rules_Index.Insert (Key, Fresh);
            end;
         end if;

         return Interned;
      end;
   end Intern_Rules;

   function Intern_Rules (S : Style_Rules) return Rules_Handle is
     (Intern_Rules (Slots_Of (S)));

   function Merge (Base, Override : Rules_Handle) return Rules_Handle is
     (Intern_Rules (Merge (Slots_Of (Base), Override)));

end Adi.CSS_Styles;
