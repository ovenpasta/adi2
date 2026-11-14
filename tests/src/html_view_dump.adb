pragma Ada_2022;

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Adi.Image;

package body Html_View_Dump is

   use Adi.Core;
   use Adi.Widget;
   use type Adi.Image.Image_Handle;

   function Trim (S : String) return String
     is (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   function Px_Image (P : Pixel_Type) return String is
      Hundredths : constant Long_Long_Integer :=
        Long_Long_Integer (Long_Float'Rounding (Long_Float (P) * 100.0));
      Magnitude  : constant Long_Long_Integer := abs Hundredths;
      Whole      : constant Long_Long_Integer := Magnitude / 100;
      Frac       : constant Long_Long_Integer := Magnitude mod 100;
      Frac_Image : constant String := Trim (Long_Long_Integer'Image (Frac));
   begin
      return (if Hundredths < 0 then "-" else "")
        & Trim (Long_Long_Integer'Image (Whole)) & "."
        & (if Frac < 10 then "0" & Frac_Image else Frac_Image);
   end Px_Image;

   function Rect_Image (R : Rectangle) return String
     is (Px_Image (R.X) & "," & Px_Image (R.Y) & " "
         & Px_Image (R.Width) & "x" & Px_Image (R.Height));

   function Item_Line (I : Positive; It : Item) return String is
      Text : constant String := To_String (It.Text_Content);
   begin
      return Trim (Positive'Image (I)) & ": "
        & Item_Kind'Image (It.Kind) & " "
        & Part_Kind'Image (It.Part)
        & " z=" & Trim (Natural'Image (It.Z_Order))
        & " [" & Rect_Image (It.Geometry) & "]"
        & (if It.Has_Style_Override then " override" else "")
        & (if It.Kind = Text_Item
           then " wrap=" & Boolean'Image (It.Wrap_Text)
                & " off=" & Px_Image (It.Text_Offset_X)
                & "," & Px_Image (It.Text_Offset_Y)
                & " text=""" & Text & """"
           else "")
        & (if It.Kind = Image_Item
           then " bg=" & Boolean'Image (It.Is_Background)
                & " src=" & (if It.Image_Source = Adi.Image.Null_Image_Handle
                             then "none" else "set")
           else "");
   end Item_Line;

   Clicked : Unbounded_String := Null_Unbounded_String;

   procedure Record_Link
     (Self : Adi.Widget.Html_View.Html_View_Handle; Href : String)
   is
      pragma Unreferenced (Self);
   begin
      Clicked := To_Unbounded_String (Href);
   end Record_Link;

   function Href_At
     (W    : Adi.Widget.Html_View.Html_View_Handle;
      X, Y : Pixel_Type) return String
   is
      use Adi.Widget.Html_View;
   begin
      Clicked := Null_Unbounded_String;
      On_Mouse_Down (+W, X => X, Y => Y,
                     Button => Adi.Core.Left_Button, Clicks => 1);
      On_Mouse_Up (+W, X => X, Y => Y, Button => Adi.Core.Left_Button);
      return To_String (Clicked);
   end Href_At;

   function Snapshot (W : Adi.Widget.Html_View.Html_View_Handle) return String is
      use Adi.Widget.Html_View;
      Out_S : Unbounded_String := Null_Unbounded_String;
   begin
      for I in 1 .. Item_Count (+W) loop
         Append (Out_S, Item_Line (I, Get_Item (+W, I)) & ASCII.LF);
      end loop;

      Append (Out_S,
              "doc: " & Px_Image (Get_Preferred_Size (+W).Width)
              & "x" & Px_Image (Get_Preferred_Size (+W).Height)
              & " scroll_h=" & Px_Image (Get_Scroll_Content_Height (+W))
              & ASCII.LF);

      for I in 1 .. Item_Count (+W) loop
         declare
            It : constant Item := Get_Item (+W, I);
            G  : constant Rectangle := It.Geometry;
         begin
            if It.Kind = Text_Item and then G.Width > 0.0
              and then G.Height > 0.0
            then
               declare
                  Href : constant String :=
                    Href_At (W, G.X + G.Width / 2.0, G.Y + G.Height / 2.0);
               begin
                  if Href /= "" then
                     Append (Out_S,
                             "link@" & Trim (Positive'Image (I))
                             & " [" & Rect_Image (G) & "] -> " & Href
                             & ASCII.LF);
                  end if;
               end;
            end if;
         end;
      end loop;

      return To_String (Out_S);
   end Snapshot;

end Html_View_Dump;
