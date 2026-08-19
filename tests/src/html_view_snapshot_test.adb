pragma Ada_2022;

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;           use Ada.Text_IO;

with Adi.Core;              use Adi.Core;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Widget;            use Adi.Widget;
with Adi.Widget_Styles;
with Adi.Font;
with Adi.Layout_Util;
with Adi.Widget.Box;
with Adi.Widget.Html_View;
with Adi.Image;
with Adi.Widget.Html_View.Testing;
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
   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Html_View.Testing.Layout_Pass_Counter;
   use type Adi.Image.Image_Handle;
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
                & " src=" & (if It.Image_Source = Adi.Image.Null_Image_Handle then "none" else "set")
           else "");
   end Item_Line;

   Clicked : Unbounded_String := Null_Unbounded_String;

   function Probe_Loader (Self : HV.Html_View_Handle; URI : String)
     return Adi.Image.Image_Handle
   is
      pragma Unreferenced (Self, URI);
   begin
      return Adi.Image.Null_Image_Handle;
   end Probe_Loader;

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

   --  The snapshot above sits at the origin unscrolled, where document
   --  space and viewport space coincide, so it says nothing about the
   --  placement. These do.
   New_Line;
   Put_Line ("--- placement ---");
   declare
      Off_X : constant Pixel_Type := 40.0;
      Off_Y : constant Pixel_Type := 25.0;

      Moved : constant HV.Html_View_Handle := HV.Create_Handle;

      function Nth_Text (V : HV.Html_View_Handle; N : Positive)
        return Rectangle
      is
         Seen : Natural := 0;
      begin
         for I in 1 .. Item_Count (+V) loop
            if Get_Item (+V, I).Kind = Text_Item then
               Seen := Seen + 1;
               if Seen = N then
                  return Get_Item (+V, I).Geometry;
               end if;
            end if;
         end loop;
         return (0.0, 0.0, 0.0, 0.0);
      end Nth_Text;

      Base  : constant Rectangle := Nth_Text (W, 1);
      Shift : Rectangle;
   begin
      HV.Set_HTML (Moved, Document);
      Set_Geometry (+Moved, (X => Off_X, Y => Off_Y,
                             Width => View_W, Height => View_H));
      Build_Items (+Moved);
      Shift := Nth_Text (Moved, 1);

      Put_Line ("  at origin [" & Rect_Image (Base) & "]  moved ["
                & Rect_Image (Shift) & "]");

      Test_Support.Assert
        (abs (Shift.X - (Base.X + Off_X)) < 0.01
           and then abs (Shift.Y - (Base.Y + Off_Y)) < 0.01,
         "a widget moved by its parent places the same document at the "
         & "new origin");
      Test_Support.Assert
        (abs (Shift.Width - Base.Width) < 0.01
           and then abs (Shift.Height - Base.Height) < 0.01,
         "and lays it out to the same size");
   end;

   --  Scrolling moves the document under the viewport by exactly the
   --  offset, and leaves the extent it scrolls within alone.
   declare
      Delta_Y : constant Pixel_Type := 30.0;
      --  Shorter than the document, or there is nothing to scroll and
      --  the offset clamps straight back to zero.
      Short_H : constant Pixel_Type := 100.0;
      Before_Rect : Rectangle;
      Before_Ext  : Pixel_Type;
      After_Rect  : Rectangle;
   begin
      Set_Geometry (+W, (X => 0.0, Y => 0.0,
                         Width => View_W, Height => Short_H));
      Build_Items (+W);
      Before_Rect := Get_Item (+W, 3).Geometry;
      Before_Ext  := Get_Scroll_Content_Height (+W);

      Set_Scroll_Offset_Y (+W, Delta_Y);
      Build_Items (+W);
      After_Rect := Get_Item (+W, 3).Geometry;

      Put_Line ("  before [" & Rect_Image (Before_Rect) & "]  after ["
                & Rect_Image (After_Rect) & "]");

      Test_Support.Assert
        (abs (After_Rect.Y - (Before_Rect.Y - Delta_Y)) < 0.01,
         "scrolling moves an item up by exactly the offset");
      Test_Support.Assert
        (abs (After_Rect.X - Before_Rect.X) < 0.01,
         "and not sideways");
      Test_Support.Assert
        (abs (Get_Scroll_Content_Height (+W) - Before_Ext) < 0.01,
         "the scroll extent is unchanged by scrolling");
      Set_Scroll_Offset_Y (+W, 0.0);
      Set_Geometry (+W, (X => 0.0, Y => 0.0,
                         Width => View_W, Height => View_H));
      Build_Items (+W);
   end;

   --  A midpoint probe passes for any rectangle that merely contains it,
   --  so the edges are probed too: a link must answer inside its own box
   --  and stay silent a pixel outside it.
   declare
      Link_Rect : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Found     : Boolean := False;
   begin
      for I in 1 .. Item_Count (+W) loop
         declare
            G : constant Rectangle := Get_Item (+W, I).Geometry;
         begin
            if not Found and then Get_Item (+W, I).Kind = Text_Item
              and then G.Width > 0.0
              and then Href_At (W, G.X + G.Width / 2.0,
                                G.Y + G.Height / 2.0) = "#two"
            then
               Link_Rect := G;
               Found := True;
            end if;
         end;
      end loop;

      Test_Support.Assert (Found, "the list link was located");
      Put_Line ("  link box [" & Rect_Image (Link_Rect) & "]");

      Test_Support.Assert
        (Href_At (W, Link_Rect.X + 1.0,
                  Link_Rect.Y + Link_Rect.Height / 2.0) = "#two",
         "the link answers just inside its left edge");
      Test_Support.Assert
        (Href_At (W, Link_Rect.X + Link_Rect.Width - 1.0,
                  Link_Rect.Y + Link_Rect.Height / 2.0) = "#two",
         "and just inside its right edge");
      Test_Support.Assert
        (Href_At (W, Link_Rect.X - 2.0,
                  Link_Rect.Y + Link_Rect.Height / 2.0) /= "#two",
         "and not past its left edge");
      Test_Support.Assert
        (Href_At (W, Link_Rect.X + Link_Rect.Width / 2.0,
                  Link_Rect.Y - 2.0) /= "#two",
         "nor above it");
   end;

   --  A link further down the document than the viewport is short. It
   --  has to survive layout intact and become clickable once scrolled
   --  to, which it cannot do if layout clips it to the first screen.
   Put_Line ("--- a link below the fold ---");
   declare
      Tall : constant HV.Html_View_Handle := HV.Create_Handle;
      Short_H : constant Pixel_Type := 60.0;
      Target  : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Found   : Boolean := False;
   begin
      HV.Set_HTML
        (Tall,
         "<p>one</p><p>two</p><p>three</p><p>four</p><p>five</p>"
         & "<p><a href='#deep'>deep link</a></p>");
      Set_Geometry (+Tall, (X => 0.0, Y => 0.0,
                            Width => View_W, Height => Short_H));
      HV.Connect_Link_Click (Tall, On_Link_Click'Unrestricted_Access);
      Build_Items (+Tall);

      --  Where the link sits before any scrolling: below the viewport,
      --  so its geometry is off the bottom rather than flattened.
      for I in 1 .. Item_Count (+Tall) loop
         declare
            It : constant Item := Get_Item (+Tall, I);
         begin
            if not Found and then It.Kind = Text_Item
              and then Index (It.Text_Content, "deep") > 0
            then
               Target := It.Geometry;
               Found  := True;
            end if;
         end;
      end loop;

      Test_Support.Assert (Found, "the deep link's text was laid out");
      Put_Line ("  unscrolled [" & Rect_Image (Target) & "] viewport h="
                & Px_Image (Short_H));
      Test_Support.Assert
        (Target.Height > 0.0,
         "a link below the viewport keeps its height");
      Test_Support.Assert
        (Target.Y > Short_H,
         "and sits below the fold");

      --  Scroll it into view and click it.
      Set_Scroll_Offset_Y (+Tall, Target.Y);
      Build_Items (+Tall);

      declare
         Now : Rectangle := (0.0, 0.0, 0.0, 0.0);
      begin
         for I in 1 .. Item_Count (+Tall) loop
            declare
               It : constant Item := Get_Item (+Tall, I);
            begin
               if It.Kind = Text_Item
                 and then Index (It.Text_Content, "deep") > 0
               then
                  Now := It.Geometry;
               end if;
            end;
         end loop;

         Put_Line ("  scrolled to [" & Rect_Image (Now) & "]");
         Test_Support.Assert
           (Now.Y >= 0.0 and then Now.Y < Short_H,
            "scrolling brings the link into the viewport");
         Test_Support.Assert
           (Href_At (Tall, Now.X + Now.Width / 2.0,
                     Now.Y + Now.Height / 2.0) = "#deep",
            "and it answers a click once it is there");
      end;
   end;

   --  A cache that always misses renders correctly and costs what it
   --  always did, so only the pass count can tell the difference.
   Put_Line ("--- the layout is kept ---");
   declare
      C : constant HV.Html_View_Handle := HV.Create_Handle;

      Before : Adi.Widget.Html_View.Testing.Layout_Pass_Counter;

      Saved_DIP  : constant Pixel_Type := Adi.Layout_Util.Get_Active_DIP_Scale;
      Saved_UI   : constant Pixel_Type := Adi.Layout_Util.Get_Active_UI_Scale;
      Saved_Text : constant Pixel_Type :=
        Adi.Layout_Util.Get_Active_Text_Scale;
      Saved_Px_Dip : constant Boolean :=
        Adi.Layout_Util.Get_Px_Maps_To_Dip;

      procedure Rebuild is
      begin
         Build_Items (+C);
      end Rebuild;

      procedure Expect
        (Passes : Adi.Widget.Html_View.Testing.Layout_Pass_Counter;
         What   : String) is
      begin
         Test_Support.Assert
           (Adi.Widget.Html_View.Testing.Layout_Pass_Count (C) = Before + Passes,
            What & " ("
            & Adi.Widget.Html_View.Testing.Layout_Pass_Counter'Image
                (Adi.Widget.Html_View.Testing.Layout_Pass_Count (C) - Before)
            & " passes)");
         Before := Adi.Widget.Html_View.Testing.Layout_Pass_Count (C);
      end Expect;
   begin
      HV.Set_HTML (C, Document);
      Set_Geometry (+C, (X => 0.0, Y => 0.0,
                         Width => View_W, Height => 100.0));
      Rebuild;
      Before := Adi.Widget.Html_View.Testing.Layout_Pass_Count (C);

      --  Nothing a layout depends on has moved.
      Rebuild;
      Expect (0, "rebuilding unchanged lays nothing out again");

      Set_Scroll_Offset_Y (+C, 20.0);
      Rebuild;
      Expect (0, "scrolling lays nothing out again");

      Set_Geometry (+C, (X => 60.0, Y => 15.0,
                         Width => View_W, Height => 100.0));
      Rebuild;
      Expect (0, "moving the widget lays nothing out again");

      --  Each of these changes the document or how it measures.
      Set_Geometry (+C, (X => 60.0, Y => 15.0,
                         Width => View_W - 40.0, Height => 100.0));
      Rebuild;
      Expect (1, "a narrower widget lays out once");

      Set_Geometry (+C, (X => 60.0, Y => 15.0,
                         Width => View_W - 40.0, Height => 140.0));
      Rebuild;
      Expect (1, "a taller widget lays out once, since height sets the "
                 & "root font size");

      HV.Set_Content_Scale (C, 1.25);
      Rebuild;
      Expect (1, "a new content scale lays out once");

      HV.Set_HTML (C, "<p>different</p>");
      Rebuild;
      Expect (1, "new source lays out once");

      HV.Set_On_Load_Asset (C, Probe_Loader'Unrestricted_Access);
      Rebuild;
      Expect (1, "a different asset loader lays out once");

      --  Nothing about this widget changed; the font environment did.
      HV.Set_Default_Stylesheet_String (C, "p { margin-top: 4px; }");
      Rebuild;
      Expect (1, "a new stylesheet lays out once");

      --  The scales and the px mapping are process-global. Each is put
      --  back to whatever it was, not to an assumed default, so nothing
      --  here depends on what ran before it.
      Adi.Layout_Util.Set_Active_DIP_Scale (Saved_DIP + 0.5);
      Rebuild;
      Expect (1, "a new DIP scale lays out once");
      Adi.Layout_Util.Set_Active_DIP_Scale (Saved_DIP);
      Rebuild;
      Expect (1, "and restoring it lays out once more");

      Adi.Layout_Util.Set_Active_UI_Scale (Saved_UI + 0.25);
      Rebuild;
      Expect (1, "a new UI scale lays out once");
      Adi.Layout_Util.Set_Active_UI_Scale (Saved_UI);
      Rebuild;
      Expect (1, "and restoring it lays out once more");

      Adi.Layout_Util.Set_Active_Text_Scale (Saved_Text + 0.4);
      Rebuild;
      Expect (1, "a new text scale lays out once");
      Adi.Layout_Util.Set_Active_Text_Scale (Saved_Text);
      Rebuild;
      Expect (1, "and restoring it lays out once more");

      Adi.Layout_Util.Set_Px_Maps_To_Dip (not Saved_Px_Dip);
      Rebuild;
      Expect (1, "mapping px to dip lays out once");
      Adi.Layout_Util.Set_Px_Maps_To_Dip (Saved_Px_Dip);
      Rebuild;
      Expect (1, "and unmapping it lays out once more");

      --  The document's own key carries the font generation, separately
      --  from the style memo: this name is referenced by nothing, so
      --  only the generation can carry it.
      Adi.Font.Register_Name ("cache-key-probe", Null_Font);
      Rebuild;
      Expect (1, "a font environment change lays the document out once");

      --  Both parts are stored in the document layout. Change one part
      --  at a time without changing the widget's content rectangle, so
      --  neither case can miss through another cache-key field.
      Set_Part_Style
        (+C, Main_Part,
         Adi.Widget_Styles.From
           ((Background_Color =>
                Adi.CSS_Styles.Set_Bg (Adi.CSS_Styles.RGB (17, 31, 47)),
             others => <>)).Build);
      Rebuild;
      Expect (1, "a new main-part style lays out once");

      Set_Part_Style
        (+C, Text_Part,
         Adi.Widget_Styles.From
           ((Font_Size => Adi.CSS_Styles.Set_Font (Adi.CSS_Styles.Px (23.0)),
             others => <>)).Build);
      Rebuild;
      Expect (1, "a new text-part style lays out once");
   end;

   --  Resolving turns a font family named in CSS into a handle. Remap
   --  the name afterwards and the next resolution has to follow it, or
   --  a font registered at runtime never reaches anything already
   --  styled. No document here: the question is the style memo, and a
   --  handle that names no loaded face must not be laid out with.
   Put_Line ("--- a remapped font name reaches resolved styles ---");
   declare
      Probe_Widget : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Probe_Face   : constant Font_Handle := 1;
      Before_Font  : Font_Handle;
   begin
      Set_Part_Style
        (Probe_Widget, Main_Part,
         Adi.Widget_Styles.From
           ((Font_Family =>
               Adi.CSS_Styles.Set_Font_Family ("memo-probe-family"),
             others => <>)).Build);

      Before_Font :=
        Get_Resolved_Part_Style (Probe_Widget, Main_Part).Font_Family;

      --  Nothing about the widget or its styles changes here.
      Adi.Font.Register_Name ("memo-probe-family", Probe_Face);

      Put_Line ("  before=" & Font_Handle'Image (Before_Font)
                & " after=" & Font_Handle'Image
                    (Get_Resolved_Part_Style
                       (Probe_Widget, Main_Part).Font_Family));

      Test_Support.Assert
        (Before_Font /= Probe_Face,
         "the name resolved to something else beforehand");
      Test_Support.Assert
        (Get_Resolved_Part_Style (Probe_Widget, Main_Part).Font_Family
           = Probe_Face,
         "and follows the name to its new face without any style change");
   end;

   --  Swapping the name resolver changes what every unresolved family
   --  maps to, which no style or scale value can show.
   declare
      use type Adi.Font.Font_Generation;
      Before_Gen : constant Adi.Font.Font_Generation :=
        Adi.Font.Environment_Generation;
   begin
      Adi.Font.Enable_System_Font_Search;
      Test_Support.Assert
        (Adi.Font.Environment_Generation /= Before_Gen,
         "enabling system font search advances the font generation");
   end;

   --  A document far taller than its viewport emits only what the
   --  viewport can show, plus a band around it. What is left out still
   --  counts toward the document's size and its scroll extent.
   Put_Line ("--- only the visible part is emitted ---");
   declare
      Long : constant HV.Html_View_Handle := HV.Create_Handle;
      View : constant Pixel_Type := 80.0;

      Body_Text : Unbounded_String := Null_Unbounded_String;

      Top_Count, Scrolled_Count : Natural;
      Extent : Pixel_Type;

      function Has_Text (Needle : String) return Boolean is
      begin
         for I in 1 .. Item_Count (+Long) loop
            if Index (Get_Item (+Long, I).Text_Content, Needle) > 0 then
               return True;
            end if;
         end loop;
         return False;
      end Has_Text;
   begin
      for I in 1 .. 60 loop
         Append (Body_Text,
                 "<p>paragraph" & Trim (Integer'Image (I)) & "</p>");
      end loop;

      HV.Set_HTML (Long, To_String (Body_Text));
      Set_Geometry (+Long, (X => 0.0, Y => 0.0, Width => 300.0,
                            Height => View));
      Build_Items (+Long);

      Top_Count := Item_Count (+Long);
      Extent := Get_Scroll_Content_Height (+Long);

      Put_Line ("  60 paragraphs in" & Px_Image (View)
                & ": items=" & Trim (Natural'Image (Top_Count))
                & " scroll extent=" & Px_Image (Extent));

      Test_Support.Assert
        (Top_Count < 60,
         "far fewer items are emitted than the document holds");
      Test_Support.Assert
        (Extent > 10.0 * View,
         "yet the scroll extent covers the whole document");
      Test_Support.Assert
        (Has_Text ("paragraph1"),
         "the top of the document is emitted");
      Test_Support.Assert
        (not Has_Text ("paragraph60"),
         "and the far end of it is not");

      --  Scrolling to the end swaps which part is emitted, without
      --  growing the set.
      Set_Scroll_Offset_Y (+Long, Extent);
      Build_Items (+Long);
      Scrolled_Count := Item_Count (+Long);

      Put_Line ("  scrolled to the end: items="
                & Trim (Natural'Image (Scrolled_Count)));

      Test_Support.Assert
        (Has_Text ("paragraph60"),
         "the far end is emitted once scrolled to");
      Test_Support.Assert
        (not Has_Text ("paragraph1"),
         "and the top no longer is");
      Test_Support.Assert
        (Scrolled_Count <= Top_Count * 2,
         "the emitted set stays bounded by the viewport, not the document");
      Test_Support.Assert
        (abs (Get_Scroll_Content_Height (+Long) - Extent) < 0.001,
         "and the scroll extent is unchanged by which part is shown");

      --  Items keep the order the document gave them.
      declare
         Last_Y : Pixel_Type := Pixel_Type'First;
         Ordered : Boolean := True;
      begin
         for I in 2 .. Item_Count (+Long) loop
            declare
               G : constant Rectangle := Get_Item (+Long, I).Geometry;
            begin
               if G.Y < Last_Y - 0.001 then
                  Ordered := False;
               end if;
               Last_Y := G.Y;
            end;
         end loop;
         Test_Support.Assert
           (Ordered, "the emitted items keep the document's order");
      end;
   end;

   --  An item taller than the viewport starts far above it and must
   --  still be emitted, or the middle of a long block goes blank.
   Put_Line ("--- an item spanning the viewport is kept ---");
   declare
      Tall_One : constant HV.Html_View_Handle := HV.Create_Handle;
      View : constant Pixel_Type := 60.0;
   begin
      --  One paragraph long enough to wrap into a block far taller than
      --  the viewport; its panel is the spanning item.
      declare
         Long_Para : Unbounded_String :=
           To_Unbounded_String ("<p>lead</p><p>");
      begin
         for I in 1 .. 120 loop
            Append (Long_Para, "word" & Trim (Integer'Image (I)) & " ");
         end loop;
         Append (Long_Para, "</p><p>tail</p>");
         HV.Set_HTML (Tall_One, To_String (Long_Para));
      end;
      Set_Geometry (+Tall_One, (X => 0.0, Y => 0.0, Width => 300.0,
                                Height => View));
      Build_Items (+Tall_One);

      --  Scroll into the middle of the tall block, where its own origin
      --  is hundreds of pixels above the viewport.
      Set_Scroll_Offset_Y (+Tall_One, 350.0);
      Build_Items (+Tall_One);

      declare
         Spanning : Boolean := False;
      begin
         for I in 1 .. Item_Count (+Tall_One) loop
            declare
               G : constant Rectangle := Get_Item (+Tall_One, I).Geometry;
            begin
               if G.Y < 0.0 and then G.Y + G.Height > View then
                  Spanning := True;
               end if;
            end;
         end loop;
         Put_Line ("  items mid-block: "
                   & Trim (Natural'Image (Item_Count (+Tall_One))));

         Test_Support.Assert
           (Spanning,
            "a block starting above the viewport and ending below it is "
            & "still emitted");
      end;
   end;

   --  Culling asks Item_Paint_Bounds what an item can paint over, and
   --  the renderer draws Resolve_Shadow_Geometry's rectangle. These pin
   --  the arithmetic directly, since a shadow's reach is three blur
   --  radii and dropping to one silently hides items whose shadow is
   --  still on screen.
   Put_Line ("--- a shadow reaches three blur radii ---");
   declare
      Box : constant Rectangle := (X => 100.0, Y => 100.0,
                                   Width => 50.0, Height => 20.0);

      function Shadowed (S : Adi.CSS_Styles.Box_Shadow_Value)
        return Adi.CSS_Styles.Resolved_Style
      is
         St : Adi.CSS_Styles.Resolved_Style :=
           Adi.CSS_Styles.Resolve (Adi.CSS_Styles.Empty_Style);
      begin
         St.Box_Shadow := S;
         return St;
      end Shadowed;

      --  pix, so the expansion is in renderer pixels whatever the
      --  scales are doing.
      Plain : constant Adi.CSS_Styles.Box_Shadow_Value :=
        (Offset_X => Adi.CSS_Styles.Pix (0.0),
         Offset_Y => Adi.CSS_Styles.Pix (0.0),
         Blur_Radius => Adi.CSS_Styles.Pix (40.0),
         Spread_Radius => Adi.CSS_Styles.Pix (0.0),
         others => <>);
      Offset : constant Adi.CSS_Styles.Box_Shadow_Value :=
        (Offset_X => Adi.CSS_Styles.Pix (10.0),
         Offset_Y => Adi.CSS_Styles.Pix (-8.0),
         Blur_Radius => Adi.CSS_Styles.Pix (0.0),
         Spread_Radius => Adi.CSS_Styles.Pix (5.0),
         others => <>);
      Percent : constant Adi.CSS_Styles.Box_Shadow_Value :=
        (Offset_X => Adi.CSS_Styles.Pct (10.0),
         Offset_Y => Adi.CSS_Styles.Pct (50.0),
         Blur_Radius => Adi.CSS_Styles.Pix (0.0),
         Spread_Radius => Adi.CSS_Styles.Pix (0.0),
         others => <>);

      B : Rectangle;
      G : Shadow_Geometry;
      Saved_DIP_2 : constant Pixel_Type :=
        Adi.Layout_Util.Get_Active_DIP_Scale;
      Saved_Px_2 : constant Boolean := Adi.Layout_Util.Get_Px_Maps_To_Dip;
   begin
      B := Item_Paint_Bounds (Shadowed (Plain), Box);
      Put_Line ("  blur 40: bounds [" & Rect_Image (B) & "]");
      Test_Support.Assert
        (abs (B.X - (Box.X - 120.0)) < 0.01,
         "a 40 pixel blur expands the bounds by 120 on the left");
      Test_Support.Assert
        (abs (B.Width - (Box.Width + 240.0)) < 0.01,
         "and by 120 on each side");

      --  Offsets move the shadow rather than growing it symmetrically.
      G := Resolve_Shadow_Geometry (Shadowed (Offset), Box);
      B := Item_Paint_Bounds (Shadowed (Offset), Box);
      Put_Line ("  offset 10,-8 spread 5: dst [" & Rect_Image (G.Dst)
                & "] bounds [" & Rect_Image (B) & "]");
      Test_Support.Assert
        (abs (G.Dst.X - (Box.X - 5.0 + 10.0)) < 0.01
           and then abs (G.Dst.Y - (Box.Y - 5.0 - 8.0)) < 0.01,
         "spread expands and the offset moves the shadow's rectangle");
      Test_Support.Assert
        (abs (B.Y - (Box.Y - 13.0)) < 0.01,
         "the bounds reach up to the shadow's top edge");
      Test_Support.Assert
        (abs ((B.X + B.Width) - (Box.X + Box.Width + 15.0)) < 0.01,
         "and out to its right edge");

      --  An outline is drawn from raw amounts, so the bounds must use
      --  the same ones: resolving them through Length_To_Px would make
      --  the bounds smaller than the outline wherever a scale is below
      --  one, and cull something still on screen.
      declare
         Outlined : Adi.CSS_Styles.Resolved_Style :=
           Adi.CSS_Styles.Resolve (Adi.CSS_Styles.Empty_Style);
      begin
         Outlined.Outline_Style := Adi.CSS_Styles.Outline_Solid;
         Outlined.Outline_Width := Adi.CSS_Styles.Px (4.0);
         Outlined.Outline_Offset := Adi.CSS_Styles.Px (3.0);

         --  px only follows the DIP scale when mapping is on, and it
         --  has to be on here or both ways of resolving agree.
         Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
         Adi.Layout_Util.Set_Active_DIP_Scale (0.5);
         B := Item_Paint_Bounds (Outlined, Box);
         Adi.Layout_Util.Set_Active_DIP_Scale (Saved_DIP_2);
         Adi.Layout_Util.Set_Px_Maps_To_Dip (Saved_Px_2);

         Put_Line ("  outline 4+3 at DIP 0.5: bounds [" & Rect_Image (B)
                   & "]");
         Test_Support.Assert
           (abs (Outline_Expansion (Outlined) - 7.0) < 0.01,
            "an outline reaches its raw width plus offset");
         Test_Support.Assert
           (abs (B.X - (Box.X - 7.0)) < 0.01,
            "and the bounds follow it whatever the scale is doing");
      end;

      --  Percentages resolve against the box, x against width and y
      --  against height, the way the renderer resolves them.
      G := Resolve_Shadow_Geometry (Shadowed (Percent), Box);
      Put_Line ("  offset 10%,50%: dst [" & Rect_Image (G.Dst) & "]");
      Test_Support.Assert
        (abs (G.Dst.X - (Box.X + 5.0)) < 0.01,
         "a percentage x offset resolves against the width");
      Test_Support.Assert
        (abs (G.Dst.Y - (Box.Y + 10.0)) < 0.01,
         "and a percentage y offset against the height");
   end;

   Test_Support.Finish;
end Html_View_Snapshot_Test;
