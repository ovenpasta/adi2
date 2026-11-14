pragma Ada_2022;

with Adi.Core;
with Adi.Widget;
with Adi.Widget.Html_View;

--  Text form of what an Html_View laid out, for tests that hold it
--  against a recorded copy.
package Html_View_Dump is

   --  Two decimals, -0.0 folded onto 0.
   function Px_Image (P : Adi.Core.Pixel_Type) return String;

   function Rect_Image (R : Adi.Core.Rectangle) return String;

   --  The fields layout decides; renderer caches and Computed_Style are
   --  left out.
   function Item_Line (I : Positive; It : Adi.Widget.Item) return String;

   --  Connect to a view for Href_At and Snapshot to see its links.
   procedure Record_Link
     (Self : Adi.Widget.Html_View.Html_View_Handle; Href : String);

   --  The href a left click at (X, Y) reports, or "".
   function Href_At
     (W    : Adi.Widget.Html_View.Html_View_Handle;
      X, Y : Adi.Core.Pixel_Type) return String;

   --  Every item, the document size, and every link found by clicking
   --  the middle of each text item.
   function Snapshot (W : Adi.Widget.Html_View.Html_View_Handle) return String;

   --  Every item and link of the document as last laid out, in document
   --  space, whatever part of it the viewport shows.
   function Document_Snapshot
     (W : Adi.Widget.Html_View.Html_View_Handle) return String;

end Html_View_Dump;
