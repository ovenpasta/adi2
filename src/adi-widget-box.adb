with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Box is

   ---------------------------------------------------------------------------
   --  Construction
   ---------------------------------------------------------------------------

   function Create return Box_Widget_Access is
      Result : constant Box_Widget_Access := new Box_Widget;
   begin
      --  Boxes are not clickable/focusable by default
      Result.Flags := [Visible => True, others => False];
      return Result;
   end Create;

   function Create (X, Y, W, H : Pixel_Type) return Box_Widget_Access is
      Result : constant Box_Widget_Access := Create;
   begin
      Result.Geometry := (X, Y, W, H);
      return Result;
   end Create;

   ---------------------------------------------------------------------------
   --  Build_Items - Create the renderable items for this box
   ---------------------------------------------------------------------------

   overriding procedure Build_Items (W : in out Box_Widget) is
   begin
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));       --  Panel_Idx
         Add_Item (W, Make_Image (Main_Part, W.Geometry, null, 1,
                                  Is_Background => True)); --  Bg_Image_Idx
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

      --  Update background image from resolved style
      declare
         Bg_It : Item renames W.Items.Reference (Bg_Image_Idx).Element.all;
         Style : constant Resolved_Style :=
            Get_Resolved_Part_Style (W, Main_Part);
         Border_W : constant Edge_Pixels := Get_Border_Width_Px (Style);
         BW : constant Pixel_Type := Pixel_Type (Border_W.Top);
      begin
         if Style.Background_Image.Kind = Picture_Image then
            Bg_It.Image_Source := Style.Background_Image.Image;
         else
            Bg_It.Image_Source := null;
         end if;
         --  Inset by border width so the image doesn't cover the border
         Bg_It.Geometry :=
            (X      => W.Geometry.X + BW,
             Y      => W.Geometry.Y + BW,
             Width  => Pixel_Type'Max (0.0, W.Geometry.Width - 2.0 * BW),
             Height => Pixel_Type'Max (0.0, W.Geometry.Height - 2.0 * BW));
      end;
   end Build_Items;

overriding procedure Layout (W : in out Box_Widget) is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      --  Check if this is a flex container
      if Style.Display = Flex or Style.Display = Inline_Flex then
         --  Use flex layout algorithm
         Perform_Flex_Layout(Widget'Class(W));
      else
         --  Simple block layout: stack children or fill content area
         declare
            --  Get padding values from style
            Pad : constant Edge_Pixels := Get_Padding_Px(Style);
            Border : constant Edge_Pixels := Get_Border_Width_Px(Style);

            Content_X : constant Pixel_Type :=
               W.Geometry.X + Pad.Left + Border.Left;
            Content_Y : constant Pixel_Type :=
               W.Geometry.Y + Pad.Top + Border.Top;
            Content_W : constant Pixel_Type :=
               W.Geometry.Width - Pad.Left - Pad.Right - Border.Left - Border.Right;
            Content_H : constant Pixel_Type :=
               W.Geometry.Height - Pad.Top - Pad.Bottom - Border.Top - Border.Bottom;

            Current_Y : Pixel_Type := Content_Y;
         begin
            --  Simple vertical stacking for block layout
            for Child of W.Children loop
               declare
                  Child_Pref : constant Size_2D := Get_Preferred_Size(Child.all);
                  Child_H : Pixel_Type := Child_Pref.Height;
               begin
                  --  Child takes full width, preferred height
                  if Child_H = 0.0 then
                     Child_H := Content_H;  -- Fallback to container height
                  end if;

                  Set_Geometry(Child.all, (
                     X      => Content_X,
                     Y      => Current_Y,
                     Width  => Content_W,
                     Height => Child_H));

                  Current_Y := Current_Y + Child_H;

                  --  Recursively layout child
                  Layout(Child.all);
               end;
            end loop;
         end;
      end if;
   end Layout;
end Adi.Widget.Box;