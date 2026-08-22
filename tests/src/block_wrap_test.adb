pragma Ada_2022;

with Ada.Text_IO;       use Ada.Text_IO;
with Adi.App;
with Adi.Core;          use Adi.Core;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Support;      use Test_Support;

--  A block container hands every in-flow child the content width minus
--  that child's own margins, and knows it before the child is measured.
--  So wrapping text under block layout must come out at exactly the
--  height it comes out at under flex, which already measures its
--  children at the width it gives them.
procedure Block_Wrap_Test is

   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

   Frame_W : constant Pixel_Type := 300.0;
   Frame_H : constant Pixel_Type := 600.0;
   Eps     : constant Pixel_Type := 0.5;

   --  Long enough to need several lines at Frame_W, so a single
   --  unwrapped line is unmistakably different from the wrapped answer.
   Long_Text : constant String :=
     "A wrapping label in a block container must be measured at the "
     & "width the container is about to give it, or the container ends "
     & "up shorter than the text it holds and the tail renders outside "
     & "its bottom border.";

   function Wrap_Label return Widget_Handle is
      L : constant Widget_Handle :=
        +Adi.Widget.Label.Create_Handle (Long_Text);
      Rules : constant Style_Rules :=
        (Text_Wrap_Mode => Set (TWM_Wrap),
         Font_Size      => Set_Font (Px (16)),
         others         => <>);
   begin
      Set_Part_Style (L, Main_Part, From (Rules).Build);
      return L;
   end Wrap_Label;

   function Column_Box return Widget_Handle is
      B : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Rules : constant Style_Rules :=
        (Display        => Set (Flex),
         Flex_Direction => Set (Column),
         Align_Items    => Set (Stretch),
         others         => <>);
   begin
      Set_Part_Style (B, Main_Part, From (Rules).Build);
      return B;
   end Column_Box;

   --  Outer holds Inner holds a wrapping label. Outer is the one given a
   --  geometry, so Inner's height is whatever Outer measures it at.
   procedure Build
     (Outer, Inner, Lbl : out Widget_Handle; Flex_Layout : Boolean) is
   begin
      Outer := (if Flex_Layout then Column_Box else +Adi.Widget.Box.Create_Handle);
      Inner := (if Flex_Layout then Column_Box else +Adi.Widget.Box.Create_Handle);
      Lbl   := Wrap_Label;
      Add_Child (Inner, Lbl);
      Add_Child (Outer, Inner);
      Set_Geometry (Outer, (0.0, 0.0, Frame_W, Frame_H));
      Layout_Tree (Outer);
   end Build;

   Flex_Outer, Flex_Inner, Flex_Lbl    : Widget_Handle;
   Block_Outer, Block_Inner, Block_Lbl : Widget_Handle;
   One_Line : Pixel_Type;

begin
   A.Init;
   Start_Suite ("Block Wrap Test");

   Section ("a wrapping label in a block container");

   Build (Flex_Outer, Flex_Inner, Flex_Lbl, Flex_Layout => True);
   Build (Block_Outer, Block_Inner, Block_Lbl, Flex_Layout => False);

   One_Line := Get_Preferred_Size (Wrap_Label).Height;

   Put_Line ("  one unwrapped line:" & Pixel_Type'Image (One_Line));
   Put_Line ("  flex : label h="
             & Pixel_Type'Image (Get_Geometry (Flex_Lbl).Height)
             & "  container h="
             & Pixel_Type'Image (Get_Geometry (Flex_Inner).Height));
   Put_Line ("  block: label h="
             & Pixel_Type'Image (Get_Geometry (Block_Lbl).Height)
             & "  container h="
             & Pixel_Type'Image (Get_Geometry (Block_Inner).Height));

   --  The fixture is only a fixture if the text really does wrap at
   --  Frame_W; otherwise both layouts agree for the wrong reason.
   Assert (Get_Geometry (Flex_Lbl).Height > One_Line + Eps,
           "the text wraps onto more than one line at"
           & Pixel_Type'Image (Frame_W)
           & " (wrapped" & Pixel_Type'Image (Get_Geometry (Flex_Lbl).Height)
           & ", one line" & Pixel_Type'Image (One_Line) & ")");

   Assert (Get_Geometry (Block_Lbl).Width = Get_Geometry (Flex_Lbl).Width,
           "both labels are laid out at the same width (block"
           & Pixel_Type'Image (Get_Geometry (Block_Lbl).Width)
           & ", flex" & Pixel_Type'Image (Get_Geometry (Flex_Lbl).Width) & ")");

   Assert (abs (Get_Geometry (Block_Lbl).Height
                - Get_Geometry (Flex_Lbl).Height) <= Eps,
           "a block container gives the label the same height a flex"
           & " column does (block"
           & Pixel_Type'Image (Get_Geometry (Block_Lbl).Height)
           & ", flex" & Pixel_Type'Image (Get_Geometry (Flex_Lbl).Height) & ")");

   Assert (abs (Get_Geometry (Block_Inner).Height
                - Get_Geometry (Flex_Inner).Height) <= Eps,
           "and takes the same height itself (block"
           & Pixel_Type'Image (Get_Geometry (Block_Inner).Height)
           & ", flex" & Pixel_Type'Image (Get_Geometry (Flex_Inner).Height)
           & ")");

   --  The room the text needs at the width the label was actually given.
   --  Comparing the label's box against its own height instead would
   --  hold whatever the container decided, since the container took its
   --  height from that same decision.
   declare
      Needed : constant Pixel_Type :=
        Measure_At_Width (Block_Lbl, Get_Geometry (Block_Lbl).Width).Height;
      Lbl_G  : constant Rectangle := Get_Geometry (Block_Lbl);
      Box_G  : constant Rectangle := Get_Geometry (Block_Inner);
   begin
      Put_Line ("  block label needs" & Pixel_Type'Image (Needed)
                & " at width" & Pixel_Type'Image (Lbl_G.Width));

      Assert (Lbl_G.Height >= Needed - Eps,
              "the label's box holds all of its wrapped text (box"
              & Pixel_Type'Image (Lbl_G.Height)
              & ", text" & Pixel_Type'Image (Needed) & ")");

      Assert (Lbl_G.Y + Needed <= Box_G.Y + Box_G.Height + Eps,
              "so the last line falls inside the container's bottom border"
              & " (text bottom" & Pixel_Type'Image (Lbl_G.Y + Needed)
              & ", container bottom"
              & Pixel_Type'Image (Box_G.Y + Box_G.Height) & ")");
   end;

   Section ("a block container's measurement at a width");

   --  The container answers the width query the same way the layout
   --  places at it, so a parent that sizes it from the query and a
   --  parent that lays it out cannot disagree.
   declare
      Measured : constant Pixel_Type :=
        Measure_At_Width (Block_Inner, Frame_W).Height;
   begin
      Put_Line ("  block container measured at"
                & Pixel_Type'Image (Frame_W) & ":"
                & Pixel_Type'Image (Measured));
      Assert (abs (Measured - Get_Geometry (Block_Inner).Height) <= Eps,
              "the measured height matches the laid-out one (measured"
              & Pixel_Type'Image (Measured) & ", laid out"
              & Pixel_Type'Image (Get_Geometry (Block_Inner).Height) & ")");
   end;

   Section ("a block container's content minimum at a width");

   --  A container that has never been laid out has no geometry to read,
   --  so the offered width is the only thing that can tell it how far
   --  its text wraps. Answering out of the geometry it will have later
   --  would make the minimum one pass late.
   declare
      Fresh_Box : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Fresh_Lbl : constant Widget_Handle := Wrap_Label;
      Wrapped   : Pixel_Type;
      Floor     : Pixel_Type;
   begin
      Add_Child (Fresh_Box, Fresh_Lbl);
      Wrapped := Measure_At_Width (Fresh_Lbl, Frame_W).Height;
      Floor   := Effective_Min_Size_At_Width (Fresh_Box, Frame_W).Height;

      Put_Line ("  fresh container floor:" & Pixel_Type'Image (Floor)
                & "  wrapped text:" & Pixel_Type'Image (Wrapped));

      Assert (Floor >= Wrapped - Eps,
              "the floor covers the text wrapped at that width (floor"
              & Pixel_Type'Image (Floor) & ", text"
              & Pixel_Type'Image (Wrapped) & ")");
   end;

   Finish;
end Block_Wrap_Test;
