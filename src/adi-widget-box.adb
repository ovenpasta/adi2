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

   overriding function Measure_Content (W : Box_Widget) return Size_2D is
      Style  : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Pad    : constant Edge_Pixels := Get_Padding_Px (Style);
      Border : constant Edge_Pixels := Get_Border_Width_Px (Style);
      Gap    : constant Pixel_Type := Get_Main_Gap (Style.Gap, Style.Flex_Direction);
      Row_Gap : constant Pixel_Type := Get_Row_Gap (Style.Gap);
      Col_Gap : constant Pixel_Type := Get_Column_Gap (Style.Gap);
      Count  : Natural := 0;
      Main_Sum  : Pixel_Type := 0.0;
      Cross_Max : Pixel_Type := 0.0;
      Result : Size_2D := (0.0, 0.0);
   begin
      if Style.Display = Flex or else Style.Display = Inline_Flex then
         for Child of W.Children loop
            declare
               Pref : constant Size_2D := Get_Preferred_Size (Child.all);
               Min  : constant Size_2D := Get_Min_Size (Child.all);
               Effective : constant Size_2D :=
                 (Width  => Pixel_Type'Max (Pref.Width, Min.Width),
                  Height => Pixel_Type'Max (Pref.Height, Min.Height));
            begin
               Main_Sum := Main_Sum + Get_Main_Size (Effective, Style.Flex_Direction);
               Cross_Max :=
                 Pixel_Type'Max
                   (Cross_Max, Get_Cross_Size (Effective, Style.Flex_Direction));
               Count := Count + 1;
            end;
         end loop;

         if Count > 1 then
            Main_Sum := Main_Sum + Gap * Pixel_Type (Count - 1);
         end if;

         Result := Make_Size (Main_Sum, Cross_Max, Style.Flex_Direction);
      elsif Style.Display = Grid or else Style.Display = Inline_Grid then
         declare
            Cols       : constant Natural := Natural'Max (1, Natural (Style.Grid_Columns));
            Max_Child_W : Pixel_Type := 0.0;
            Max_Child_H : Pixel_Type := 0.0;
            Rows        : Natural := 0;
         begin
            for Child of W.Children loop
               declare
                  Pref : constant Size_2D := Get_Preferred_Size (Child.all);
                  Min  : constant Size_2D := Get_Min_Size (Child.all);
                  Effective : constant Size_2D :=
                    (Width  => Pixel_Type'Max (Pref.Width, Min.Width),
                     Height => Pixel_Type'Max (Pref.Height, Min.Height));
               begin
                  Max_Child_W := Pixel_Type'Max (Max_Child_W, Effective.Width);
                  Max_Child_H := Pixel_Type'Max (Max_Child_H, Effective.Height);
                  Count := Count + 1;
               end;
            end loop;

            if Count > 0 then
               if Natural (Style.Grid_Rows) > 0 then
                  Rows := Natural (Style.Grid_Rows);
               else
                  Rows := (Count + Cols - 1) / Cols;
               end if;
            end if;

            if Rows = 0 then
               Rows := 1;
            end if;

            Result.Width :=
              Pixel_Type (Cols) * Max_Child_W
              + Pixel_Type'Max (0.0, Pixel_Type (Cols - 1) * Col_Gap);
            Result.Height :=
              Pixel_Type (Rows) * Max_Child_H
              + Pixel_Type'Max (0.0, Pixel_Type (Rows - 1) * Row_Gap);
         end;
      else
         for Child of W.Children loop
            declare
               Pref : constant Size_2D := Get_Preferred_Size (Child.all);
               Min  : constant Size_2D := Get_Min_Size (Child.all);
               Effective : constant Size_2D :=
                 (Width  => Pixel_Type'Max (Pref.Width, Min.Width),
                  Height => Pixel_Type'Max (Pref.Height, Min.Height));
            begin
               Result.Width := Pixel_Type'Max (Result.Width, Effective.Width);
               Result.Height := Result.Height + Effective.Height;
            end;
         end loop;
      end if;

      Result.Width := Result.Width + Pad.Left + Pad.Right + Border.Left + Border.Right;
      Result.Height := Result.Height + Pad.Top + Pad.Bottom + Border.Top + Border.Bottom;
      return Result;
   end Measure_Content;

overriding procedure Layout (W : in out Box_Widget) is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
   begin
      --  Check if this is a flex container
      if Style.Display = Flex or Style.Display = Inline_Flex then
         --  Use flex layout algorithm
         Perform_Flex_Layout(Widget'Class(W));
      elsif Style.Display = Grid or else Style.Display = Inline_Grid then
         declare
            N : constant Natural := Child_Count (W);
            Content : constant Rectangle := Content_Box (W.Geometry, Style);
         begin
            if N = 0 then
               return;
            end if;

            declare
               Context : constant Grid_Layout_Context :=
                 (Container           => Content,
                  Columns             => Natural (Style.Grid_Columns),
                  Explicit_Rows       => Natural (Style.Grid_Rows),
                  Row_Gap             => Get_Row_Gap (Style.Gap),
                  Column_Gap          => Get_Column_Gap (Style.Gap),
                  Use_Preferred_Floor => Style.Overflow = Overflow_Visible);
               Children_Info : Grid_Child_Info_Array (1 .. N);
               Rects : Rectangle_Array (1 .. N);
            begin
               for I in 1 .. N loop
                  declare
                     Child : constant Widget_Access := Get_Child (W, Positive (I));
                  begin
                     if Child = null then
                        Children_Info (Positive (I)) :=
                          (Active => False, others => <>);
                     else
                        declare
                           Child_Style : constant Resolved_Style :=
                             Get_Resolved_Part_Style (Child.all, Main_Part);
                           Child_Pref : constant Size_2D :=
                             Get_Preferred_Size (Child.all);
                           Child_Min  : constant Size_2D :=
                             Get_Min_Size (Child.all);
                        begin
                           Children_Info (Positive (I)) :=
                             (Active           => True,
                              Grid_Column      => Natural (Child_Style.Grid_Column),
                              Grid_Row         => Natural (Child_Style.Grid_Row),
                              Grid_Column_Span => Natural (Child_Style.Grid_Column_Span),
                              Grid_Row_Span    => Natural (Child_Style.Grid_Row_Span),
                              Min_Width        => Child_Min.Width,
                              Min_Height       => Child_Min.Height,
                              Pref_Width       => Child_Pref.Width,
                              Pref_Height      => Child_Pref.Height,
                              others           => <>);
                        end;
                     end if;
                  end;
               end loop;

               Compute_Grid_Layout (Context, Children_Info);
               Rects := Grid_To_Rectangles (Children_Info);

               for I in 1 .. N loop
                  declare
                     Child : constant Widget_Access := Get_Child (W, Positive (I));
                  begin
                     if Child /= null then
                        Set_Geometry (Child.all, Rects (Positive (I)));
                        Layout (Child.all);
                     end if;
                  end;
               end loop;
            end;
         end;
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
