pragma Ada_2022;

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;           use Ada.Text_IO;

with Adi.Core;              use Adi.Core;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Widget;            use Adi.Widget;
with Adi.Widget.Html_View;
with Adi.Image;
with Test_Support;

--  A characterisation of what laying out one document produces, held
--  against a literal recorded from the current implementation.
--
--  Its job is to make a refactor of Layout_And_Build provable rather
--  than asserted: the document below is small but drives every path
--  that appends an item or link and every path that goes back and
--  rewrites one afterwards -- wrapped linked text, an image, a rule,
--  nested panels and collapsing margins.
--
--  It captures what layout decides and nothing the renderer owns. Item
--  Computed_Style is left out for the same reason: Apply_Styles_To_Items
--  fills it in later, so it says nothing about this pass.
--
--  When layout legitimately changes, the printed Actual block is the new
--  expected block; read the difference before pasting it, since that
--  difference is the whole point of the test.
procedure Html_View_Snapshot_Test is

   package HV renames Adi.Widget.Html_View;
   use type Adi.Image.Image_Access;
   use type HV.Html_View_Handle;

   --  Small, but every append and back-patch path takes part: the
   --  paragraph wraps and carries a link across the break, the list
   --  nests panels, the rule and image are their own item kinds, and the
   --  adjacent margins collapse.
   Document : constant String :=
     "<h2>Heading</h2>"
     & "<p>Some prose that is long enough to wrap onto a second line, "
     & "with <a href='https://example.com/one'>a link that also wraps "
     & "across the break</a> inside it.</p>"
     & "<hr>"
     & "<ul><li>first item</li><li>second <a href='#two'>item</a></li></ul>"
     & "<p><img src='missing.png' alt='alt text'> trailing prose.</p>";

   View_W : constant Pixel_Type := 320.0;
   View_H : constant Pixel_Type := 240.0;

   function Trim (S : String) return String
     is (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   --  Two decimals: enough that a real geometry change shows, coarse
   --  enough that float noise does not.
   function Px_Image (P : Pixel_Type) return String is
      Hundredths : constant Long_Long_Integer :=
        Long_Long_Integer (Long_Float'Rounding (Long_Float (P) * 100.0));
      Magnitude  : constant Long_Long_Integer := abs Hundredths;
      Whole      : constant Long_Long_Integer := Magnitude / 100;
      Frac       : constant Long_Long_Integer := Magnitude mod 100;
      Frac_Image : constant String := Trim (Long_Long_Integer'Image (Frac));
   begin
      --  Rounding first also folds -0.0 onto 0, which the layout
      --  produces for a left edge and which would otherwise show up as
      --  a difference that is not one.
      return (if Hundredths < 0 then "-" else "")
        & Trim (Long_Long_Integer'Image (Whole)) & "."
        & (if Frac < 10 then "0" & Frac_Image else Frac_Image);
   end Px_Image;

   function Rect_Image (R : Rectangle) return String
     is (Px_Image (R.X) & "," & Px_Image (R.Y) & " "
         & Px_Image (R.Width) & "x" & Px_Image (R.Height));

   --  One line per item, in order. Only fields layout is responsible
   --  for; the TTF/font cache fields are deliberately absent.
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
                & " src=" & (if It.Image_Source = null then "none" else "set")
           else "");
   end Item_Line;

   Clicked : Unbounded_String := Null_Unbounded_String;

   procedure On_Link_Click (Self : HV.Html_View_Handle; Href : String) is
      pragma Unreferenced (Self);
   begin
      Clicked := To_Unbounded_String (Href);
   end On_Link_Click;

   --  Links carry no public accessor, so they are read the way an
   --  application reads them: click where the item is and see which
   --  href comes back. That pins geometry and href together, and it
   --  keeps working when the geometry moves to document space.
   function Href_At (W : HV.Html_View_Handle;
                     X, Y : Pixel_Type) return String is
   begin
      Clicked := Null_Unbounded_String;
      On_Mouse_Down (+W, X => X, Y => Y,
                     Button => Adi.Core.Left_Button, Clicks => 1);
      On_Mouse_Up (+W, X => X, Y => Y, Button => Adi.Core.Left_Button);
      return To_String (Clicked);
   end Href_At;

   function Snapshot (W : HV.Html_View_Handle) return String is
      Out_S : Unbounded_String := Null_Unbounded_String;
   begin
      for I in 1 .. Item_Count (+W) loop
         Append (Out_S, Item_Line (I, Get_Item (+W, I)) & ASCII.LF);
      end loop;

      --  What the document came to, and how far it scrolls.
      Append (Out_S,
              "doc: " & Px_Image (Get_Preferred_Size (+W).Width)
              & "x" & Px_Image (Get_Preferred_Size (+W).Height)
              & " scroll_h=" & Px_Image (Get_Scroll_Content_Height (+W))
              & ASCII.LF);

      --  Every link, found through its own text item's midpoint.
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

   Expected : constant String :=
       "1: PANEL_ITEM MAIN_PART z=0 [0.00,0.00 320.00x240.00]" & ASCII.LF
     & "2: PANEL_ITEM ANY_PART z=0 [0.00,0.00 320.00x19.20] override" & ASCII.LF
     & "3: TEXT_ITEM TEXT_PART z=1 [0.00,0.00 61.60x19.20] override wrap=FALSE off=0.00,0.00 text=""Heading""" & ASCII.LF
     & "4: PANEL_ITEM ANY_PART z=0 [0.00,19.20 320.00x76.80] override" & ASCII.LF
     & "5: TEXT_ITEM TEXT_PART z=1 [0.00,19.20 35.20x19.20] override wrap=FALSE off=0.00,0.00 text=""Some""" & ASCII.LF
     & "6: TEXT_ITEM TEXT_PART z=1 [35.20,19.20 52.80x19.20] override wrap=FALSE off=0.00,0.00 text="" prose""" & ASCII.LF
     & "7: TEXT_ITEM TEXT_PART z=1 [88.00,19.20 44.00x19.20] override wrap=FALSE off=0.00,0.00 text="" that""" & ASCII.LF
     & "8: TEXT_ITEM TEXT_PART z=1 [132.00,19.20 26.40x19.20] override wrap=FALSE off=0.00,0.00 text="" is""" & ASCII.LF
     & "9: TEXT_ITEM TEXT_PART z=1 [158.40,19.20 44.00x19.20] override wrap=FALSE off=0.00,0.00 text="" long""" & ASCII.LF
     & "10: TEXT_ITEM TEXT_PART z=1 [202.40,19.20 61.60x19.20] override wrap=FALSE off=0.00,0.00 text="" enough""" & ASCII.LF
     & "11: TEXT_ITEM TEXT_PART z=1 [264.00,19.20 26.40x19.20] override wrap=FALSE off=0.00,0.00 text="" to""" & ASCII.LF
     & "12: TEXT_ITEM TEXT_PART z=1 [0.00,38.40 35.20x19.20] override wrap=FALSE off=0.00,0.00 text=""wrap""" & ASCII.LF
     & "13: TEXT_ITEM TEXT_PART z=1 [35.20,38.40 44.00x19.20] override wrap=FALSE off=0.00,0.00 text="" onto""" & ASCII.LF
     & "14: TEXT_ITEM TEXT_PART z=1 [79.20,38.40 17.60x19.20] override wrap=FALSE off=0.00,0.00 text="" a""" & ASCII.LF
     & "15: TEXT_ITEM TEXT_PART z=1 [96.80,38.40 61.60x19.20] override wrap=FALSE off=0.00,0.00 text="" second""" & ASCII.LF
     & "16: TEXT_ITEM TEXT_PART z=1 [158.40,38.40 52.80x19.20] override wrap=FALSE off=0.00,0.00 text="" line,""" & ASCII.LF
     & "17: TEXT_ITEM TEXT_PART z=1 [211.20,38.40 44.00x19.20] override wrap=FALSE off=0.00,0.00 text="" with""" & ASCII.LF
     & "18: TEXT_ITEM TEXT_PART z=1 [255.20,38.40 8.80x19.20] override wrap=FALSE off=0.00,0.00 text="" """ & ASCII.LF
     & "19: TEXT_ITEM INDICATOR_PART z=1 [264.00,38.40 8.80x19.20] override wrap=FALSE off=0.00,0.00 text=""a""" & ASCII.LF
     & "20: TEXT_ITEM INDICATOR_PART z=1 [272.80,38.40 44.00x19.20] override wrap=FALSE off=0.00,0.00 text="" link""" & ASCII.LF
     & "21: TEXT_ITEM INDICATOR_PART z=1 [0.00,57.60 35.20x19.20] override wrap=FALSE off=0.00,0.00 text=""that""" & ASCII.LF
     & "22: TEXT_ITEM INDICATOR_PART z=1 [35.20,57.60 44.00x19.20] override wrap=FALSE off=0.00,0.00 text="" also""" & ASCII.LF
     & "23: TEXT_ITEM INDICATOR_PART z=1 [79.20,57.60 52.80x19.20] override wrap=FALSE off=0.00,0.00 text="" wraps""" & ASCII.LF
     & "24: TEXT_ITEM INDICATOR_PART z=1 [132.00,57.60 61.60x19.20] override wrap=FALSE off=0.00,0.00 text="" across""" & ASCII.LF
     & "25: TEXT_ITEM INDICATOR_PART z=1 [193.60,57.60 35.20x19.20] override wrap=FALSE off=0.00,0.00 text="" the""" & ASCII.LF
     & "26: TEXT_ITEM INDICATOR_PART z=1 [228.80,57.60 52.80x19.20] override wrap=FALSE off=0.00,0.00 text="" break""" & ASCII.LF
     & "27: TEXT_ITEM TEXT_PART z=1 [0.00,76.80 52.80x19.20] override wrap=FALSE off=0.00,0.00 text=""inside""" & ASCII.LF
     & "28: TEXT_ITEM TEXT_PART z=1 [52.80,76.80 35.20x19.20] override wrap=FALSE off=0.00,0.00 text="" it.""" & ASCII.LF
     & "29: PANEL_ITEM ANY_PART z=1 [0.00,105.10 320.00x1.00] override" & ASCII.LF
     & "30: PANEL_ITEM ANY_PART z=0 [0.00,115.20 320.00x38.40] override" & ASCII.LF
     & "31: PANEL_ITEM ANY_PART z=0 [0.00,115.20 320.00x19.20] override" & ASCII.LF
     & "32: IMAGE_ITEM ICON_PART z=1 [0.00,120.00 10.56x10.56] override bg=FALSE src=set" & ASCII.LF
     & "33: TEXT_ITEM TEXT_PART z=1 [16.16,115.20 44.00x19.20] override wrap=FALSE off=0.00,0.00 text=""first""" & ASCII.LF
     & "34: TEXT_ITEM TEXT_PART z=1 [60.16,115.20 44.00x19.20] override wrap=FALSE off=0.00,0.00 text="" item""" & ASCII.LF
     & "35: PANEL_ITEM ANY_PART z=0 [0.00,134.40 320.00x19.20] override" & ASCII.LF
     & "36: IMAGE_ITEM ICON_PART z=1 [0.00,139.20 10.56x10.56] override bg=FALSE src=set" & ASCII.LF
     & "37: TEXT_ITEM TEXT_PART z=1 [16.16,134.40 52.80x19.20] override wrap=FALSE off=0.00,0.00 text=""second""" & ASCII.LF
     & "38: TEXT_ITEM TEXT_PART z=1 [68.96,134.40 8.80x19.20] override wrap=FALSE off=0.00,0.00 text="" """ & ASCII.LF
     & "39: TEXT_ITEM INDICATOR_PART z=1 [77.76,134.40 35.20x19.20] override wrap=FALSE off=0.00,0.00 text=""item""" & ASCII.LF
     & "40: PANEL_ITEM ANY_PART z=0 [0.00,153.60 320.00x19.20] override" & ASCII.LF
     & "41: TEXT_ITEM TEXT_PART z=1 [0.00,153.60 70.40x19.20] override wrap=FALSE off=0.00,0.00 text=""alt text""" & ASCII.LF
     & "42: TEXT_ITEM TEXT_PART z=1 [70.40,153.60 79.20x19.20] override wrap=FALSE off=0.00,0.00 text="" trailing""" & ASCII.LF
     & "43: TEXT_ITEM TEXT_PART z=1 [149.60,153.60 61.60x19.20] override wrap=FALSE off=0.00,0.00 text="" prose.""" & ASCII.LF
     & "doc: 320.00x172.80 scroll_h=240.00" & ASCII.LF
     & "link@19 [264.00,38.40 8.80x19.20] -> https://example.com/one" & ASCII.LF
     & "link@20 [272.80,38.40 44.00x19.20] -> https://example.com/one" & ASCII.LF
     & "link@21 [0.00,57.60 35.20x19.20] -> https://example.com/one" & ASCII.LF
     & "link@22 [35.20,57.60 44.00x19.20] -> https://example.com/one" & ASCII.LF
     & "link@23 [79.20,57.60 52.80x19.20] -> https://example.com/one" & ASCII.LF
     & "link@24 [132.00,57.60 61.60x19.20] -> https://example.com/one" & ASCII.LF
     & "link@25 [193.60,57.60 35.20x19.20] -> https://example.com/one" & ASCII.LF
     & "link@26 [228.80,57.60 52.80x19.20] -> https://example.com/one" & ASCII.LF
     & "link@39 [77.76,134.40 35.20x19.20] -> #two" & ASCII.LF;

   W : constant HV.Html_View_Handle := HV.Create_Handle;

begin
   Test_Support.Start_Suite ("html_view_snapshot_test");

   HV.Connect_Link_Click (W, On_Link_Click'Unrestricted_Access);
   HV.Set_HTML (W, Document);
   Set_Geometry (+W, (X => 0.0, Y => 0.0, Width => View_W, Height => View_H));
   Build_Items (+W);

   declare
      Actual : constant String := Snapshot (W);
   begin
      if Actual /= Expected then
         Put_Line ("--- actual ---");
         Put (Actual);
         Put_Line ("--- expected ---");
         Put (Expected);
         Put_Line ("--- end ---");
      end if;

      Test_Support.Assert
        (Actual = Expected,
         "the document lays out exactly as recorded");
   end;

   Test_Support.Finish;
end Html_View_Snapshot_Test;
