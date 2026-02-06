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
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));  --  Panel_Idx
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;
   end Build_Items;

--    ---------------------------------------------------------------------------
--    --  Layout - Calculate layout for children
--    ---------------------------------------------------------------------------
--
--    overriding procedure Layout (W : in out Box_Widget) is
--       Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
--
--       --  Get padding values from style
--       Pad_Top, Pad_Right, Pad_Bottom, Pad_Left : Pixel_Type := 0.0;
--
--       Content_X, Content_Y, Content_W, Content_H : Pixel_Type;
--    begin
--       --  Extract padding from resolved style
--       case Style.Padding.Kind is
--          when Gap_Uniform =>
--             Pad_Top := Pixel_Type (Style.Padding.All_Sides.Amount);
--             Pad_Right := Pad_Top;
--             Pad_Bottom := Pad_Top;
--             Pad_Left := Pad_Top;
--          when Axis =>
--             Pad_Top := Pixel_Type (Style.Padding.Vertical.Amount);
--             Pad_Bottom := Pad_Top;
--             Pad_Left := Pixel_Type (Style.Padding.Horizontal.Amount);
--             Pad_Right := Pad_Left;
--          when Per_Side =>
--             Pad_Top := Pixel_Type (Style.Padding.Sides (Top).Amount);
--             Pad_Right := Pixel_Type (Style.Padding.Sides (Right).Amount);
--             Pad_Bottom := Pixel_Type (Style.Padding.Sides (Bottom).Amount);
--             Pad_Left := Pixel_Type (Style.Padding.Sides (Left).Amount);
--       end case;
--
--       --  Calculate content area
--       Content_X := W.Geometry.X + Pad_Left;
--       Content_Y := W.Geometry.Y + Pad_Top;
--       Content_W := W.Geometry.Width - Pad_Left - Pad_Right;
--       Content_H := W.Geometry.Height - Pad_Top - Pad_Bottom;
--
--       --  Simple layout: children use full content area
--       for Child of W.Children loop
--          Set_Geometry (Child.all, (Content_X, Content_Y, Content_W, Content_H));
--          Layout (Child.all);
--       end loop;
--    end Layout;
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