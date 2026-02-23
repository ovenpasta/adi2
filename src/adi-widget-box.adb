with Ada.Strings.Unbounded;
with Adi.Assets;
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
         case Style.Background_Image.Kind is
            when Picture_Image =>
               Bg_It.Image_Source := Style.Background_Image.Image;
            when Url_Image =>
               Bg_It.Image_Source := Adi.Assets.Get_Image
                 (Ada.Strings.Unbounded.To_String
                    (Style.Background_Image.URI));
            when No_Image =>
               Bg_It.Image_Source := null;
         end case;
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
               Child_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (Child.all, Main_Part);
               Margin : constant Edge_Pixels := Get_Margin_Px (Child_Style);
               Pref : constant Size_2D := Get_Preferred_Size (Child.all);
               Min  : constant Size_2D := Get_Min_Size (Child.all);
               Effective : constant Size_2D :=
                 (Width  => Pixel_Type'Max (Pref.Width, Min.Width),
                  Height => Pixel_Type'Max (Pref.Height, Min.Height));
               Main_Margins : constant Pixel_Type :=
                 (if Is_Row_Direction (Style.Flex_Direction)
                  then Margin.Left + Margin.Right
                  else Margin.Top + Margin.Bottom);
               Cross_Margins : constant Pixel_Type :=
                 (if Is_Row_Direction (Style.Flex_Direction)
                  then Margin.Top + Margin.Bottom
                  else Margin.Left + Margin.Right);
            begin
               Main_Sum := Main_Sum
                 + Get_Main_Size (Effective, Style.Flex_Direction)
                 + Main_Margins;
               Cross_Max :=
                 Pixel_Type'Max
                   (Cross_Max, Get_Cross_Size (Effective, Style.Flex_Direction) + Cross_Margins);
               Count := Count + 1;
            end;
         end loop;

         if Count > 1 then
            Main_Sum := Main_Sum + Gap * Pixel_Type (Count - 1);
         end if;

         Result := Make_Size (Main_Sum, Cross_Max, Style.Flex_Direction);
      elsif Style.Display = Grid or else Style.Display = Inline_Grid then
         declare
            Cols        : constant Natural := Natural'Max (1, Natural (Style.Grid_Columns));
            Tracks      : constant Grid_Track_List := Style.Grid_Column_Tracks;
            Max_Child_H : Pixel_Type := 0.0;
            Rows        : Natural := 0;
         begin
            if Tracks.Count = Cols then
               --  Track-aware measurement: auto columns sized to content,
               --  px columns use their fixed value, fr columns contribute 0.
               declare
                  Col_Max_W  : array (1 .. Cols) of Pixel_Type := [others => 0.0];
                  Auto_Index : Natural := 0;
               begin
                  --  Pre-pass: seed px column widths (regardless of child occupancy).
                  for C in 1 .. Cols loop
                     if Tracks.Tracks (C).Kind = Track_Px then
                        Col_Max_W (C) := Pixel_Type (Tracks.Tracks (C).Value);
                     end if;
                  end loop;

                  for Child of W.Children loop
                     declare
                        Child_Style : constant Resolved_Style :=
                          Get_Resolved_Part_Style (Child.all, Main_Part);
                        Margin : constant Edge_Pixels := Get_Margin_Px (Child_Style);
                        Pref   : constant Size_2D := Get_Preferred_Size (Child.all);
                        Min    : constant Size_2D := Get_Min_Size (Child.all);
                        Eff_W  : constant Pixel_Type :=
                          Pixel_Type'Max (Pref.Width, Min.Width)
                          + Margin.Left + Margin.Right;
                        C  : Natural := Natural (Child_Style.Grid_Column);
                        R  : constant Natural := Natural (Child_Style.Grid_Row);
                        CS : Natural := Natural (Child_Style.Grid_Column_Span);
                     begin
                        if CS = 0 then
                           CS := 1;
                        end if;

                        --  Replicate placement logic from Compute_Grid_Layout.
                        if C = 0 and then R = 0 then
                           Auto_Index := Auto_Index + 1;
                           C := ((Auto_Index - 1) mod Cols) + 1;
                        elsif C = 0 then
                           C := 1;
                        elsif R = 0 then
                           Auto_Index := Auto_Index + 1;
                           --  C is already explicit; auto_index tracks row only.
                        end if;
                        C  := Natural'Max (1, Natural'Min (C, Cols));
                        CS := Natural'Max (1, Natural'Min (CS, Cols - C + 1));

                        Max_Child_H := Pixel_Type'Max
                          (Max_Child_H,
                           Pixel_Type'Max (Pref.Height, Min.Height)
                           + Margin.Top + Margin.Bottom);

                        --  Distribute child width evenly across spanned columns.
                        --  Only auto tracks update Col_Max_W; fr and px are unaffected.
                        for Span_Offset in 0 .. CS - 1 loop
                           declare
                              Sc : constant Natural := C + Span_Offset;
                           begin
                              if Tracks.Tracks (Sc).Kind = Track_Auto then
                                 Col_Max_W (Sc) := Pixel_Type'Max
                                   (Col_Max_W (Sc), Eff_W / Pixel_Type (CS));
                              end if;
                           end;
                        end loop;

                        Count := Count + 1;
                     end;
                  end loop;

                  for C in 1 .. Cols loop
                     Result.Width := Result.Width + Col_Max_W (C);
                  end loop;
                  if Cols > 1 then
                     Result.Width := Result.Width + Pixel_Type (Cols - 1) * Col_Gap;
                  end if;
               end;
            else
               --  No track list: fall back to equal-column estimate.
               declare
                  Max_Child_W : Pixel_Type := 0.0;
               begin
                  for Child of W.Children loop
                     declare
                        Child_Style : constant Resolved_Style :=
                          Get_Resolved_Part_Style (Child.all, Main_Part);
                        Margin : constant Edge_Pixels := Get_Margin_Px (Child_Style);
                        Pref : constant Size_2D := Get_Preferred_Size (Child.all);
                        Min  : constant Size_2D := Get_Min_Size (Child.all);
                        Effective : constant Size_2D :=
                          (Width  => Pixel_Type'Max (Pref.Width, Min.Width),
                           Height => Pixel_Type'Max (Pref.Height, Min.Height));
                     begin
                        Max_Child_W := Pixel_Type'Max
                          (Max_Child_W, Effective.Width + Margin.Left + Margin.Right);
                        Max_Child_H := Pixel_Type'Max
                          (Max_Child_H, Effective.Height + Margin.Top + Margin.Bottom);
                        Count := Count + 1;
                     end;
                  end loop;

                  Result.Width :=
                    Pixel_Type (Cols) * Max_Child_W
                    + Pixel_Type'Max (0.0, Pixel_Type (Cols - 1) * Col_Gap);
               end;
            end if;

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

            Result.Height :=
              Pixel_Type (Rows) * Max_Child_H
              + Pixel_Type'Max (0.0, Pixel_Type (Rows - 1) * Row_Gap);
         end;
      else
         for Child of W.Children loop
            declare
               Child_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (Child.all, Main_Part);
               Margin : constant Edge_Pixels := Get_Margin_Px (Child_Style);
               Pref : constant Size_2D := Get_Preferred_Size (Child.all);
               Min  : constant Size_2D := Get_Min_Size (Child.all);
               Effective : constant Size_2D :=
                 (Width  => Pixel_Type'Max (Pref.Width, Min.Width),
                  Height => Pixel_Type'Max (Pref.Height, Min.Height));
            begin
               Result.Width := Pixel_Type'Max
                 (Result.Width, Effective.Width + Margin.Left + Margin.Right);
               Result.Height := Result.Height + Effective.Height + Margin.Top + Margin.Bottom;
            end;
         end loop;
      end if;

      return Outer_Size (Result, Style);
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
                  Use_Preferred_Floor => Style.Overflow = Overflow_Visible,
                  Column_Tracks       => Style.Grid_Column_Tracks);
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

               --  Sizing pass: give each child its assigned column width and a
               --  large provisional height, then run Layout_Child so that labels
               --  with text-wrap enabled can re-measure at that width.
               --  Measure_Content for Label is width-aware when geometry.Width > 0,
               --  so Get_Preferred_Size afterwards returns the wrapped height.
               --  If any child needs more height, re-run Compute_Grid_Layout so
               --  row heights grow to accommodate the wrapped content.
               declare
                  Height_Changed : Boolean := False;
                  Large_H : constant Pixel_Type := 32768.0;
               begin
                  for I in 1 .. N loop
                     declare
                        Child : constant Widget_Access :=
                          Get_Child (W, Positive (I));
                        Provisional : Rectangle := Rects (Positive (I));
                     begin
                        if Child /= null and then Provisional.Width > 0.0 then
                           Provisional.Height := Large_H;
                           Set_Geometry (Child.all, Provisional);
                           Layout_Child (Child.all);
                           declare
                              Actual_H : constant Pixel_Type :=
                                Get_Preferred_Size (Child.all).Height;
                           begin
                              if Actual_H > Children_Info (Positive (I)).Pref_Height
                              then
                                 Children_Info (Positive (I)).Pref_Height :=
                                   Actual_H;
                                 Height_Changed := True;
                              end if;
                           end;
                        end if;
                     end;
                  end loop;

                  if Height_Changed then
                     Compute_Grid_Layout (Context, Children_Info);
                     Rects := Grid_To_Rectangles (Children_Info);
                  end if;
               end;

               --  Container growth: when overflow is visible (the default),
               --  grow W.Geometry if row heights exceed the allocated height.
               --  For overflow:hidden/scroll/auto the box clips instead of
               --  growing, matching CSS behaviour for those modes.
               if Style.Overflow = Overflow_Visible then
                  declare
                     Content_Bottom : constant Pixel_Type :=
                       Content.Y + Content.Height;
                     Max_Bottom : Pixel_Type := Content.Y;
                  begin
                     for I in 1 .. N loop
                        if Rects (Positive (I)).Width > 0.0 then
                           Max_Bottom := Pixel_Type'Max
                             (Max_Bottom,
                              Rects (Positive (I)).Y
                                + Rects (Positive (I)).Height);
                        end if;
                     end loop;
                     if Max_Bottom > Content_Bottom then
                        W.Geometry.Height :=
                          W.Geometry.Height + (Max_Bottom - Content_Bottom);
                     end if;
                  end;
               end if;

               for I in 1 .. N loop
                  declare
                     Child : constant Widget_Access := Get_Child (W, Positive (I));
                  begin
                     if Child /= null then
                        declare
                           Cell : Rectangle := Rects (Positive (I));
                           CS   : constant Resolved_Style :=
                             Get_Resolved_Part_Style (Child.all, Main_Part);
                           CW   : Pixel_Type := Cell.Width;
                           CH   : Pixel_Type := Cell.Height;
                        begin
                           --  Respect explicit width
                           if CS.Width.Kind = Fixed then
                              CW := Size_To_Px (CS.Width, Cell.Width);
                           end if;
                           --  Respect explicit height
                           if CS.Height.Kind = Fixed then
                              CH := Size_To_Px (CS.Height, Cell.Height);
                           end if;

                           --  Align horizontally within cell
                           if CW < Cell.Width then
                              case CS.Align_Self is
                                 when Adi.CSS_Styles.Center =>
                                    Cell.X := Cell.X +
                                      (Cell.Width - CW) / 2.0;
                                 when Adi.CSS_Styles.Flex_End =>
                                    Cell.X := Cell.X +
                                      Cell.Width - CW;
                                 when others =>
                                    null;  --  default: left-aligned
                              end case;
                           end if;

                           --  Align vertically within cell
                           if CH < Cell.Height then
                              case CS.Align_Self is
                                 when Adi.CSS_Styles.Center =>
                                    Cell.Y := Cell.Y +
                                      (Cell.Height - CH) / 2.0;
                                 when Adi.CSS_Styles.Flex_End =>
                                    Cell.Y := Cell.Y +
                                      Cell.Height - CH;
                                 when others =>
                                    null;  --  default: top-aligned
                              end case;
                           end if;

                           Cell.Width := CW;
                           Cell.Height := CH;
                           Set_Geometry (Child.all, Cell);
                           Layout_Child (Child.all);
                        end;
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
                  Child_Style : constant Resolved_Style :=
                    Get_Resolved_Part_Style (Child.all, Main_Part);
                  Margin : constant Edge_Pixels := Get_Margin_Px (Child_Style);
                  Child_Pref : constant Size_2D := Get_Preferred_Size(Child.all);
                  Child_H : Pixel_Type := Child_Pref.Height;
                  Child_X : Pixel_Type;
                  Child_Y : Pixel_Type;
                  Child_W : Pixel_Type;
               begin
                  --  Child takes full width, preferred height
                  if Child_H = 0.0 then
                     Child_H := Pixel_Type'Max (0.0, Content_H - Margin.Top - Margin.Bottom);
                  end if;

                  Child_X := Content_X + Margin.Left;
                  Child_Y := Current_Y + Margin.Top;
                  Child_W := Pixel_Type'Max (0.0, Content_W - Margin.Left - Margin.Right);

                  Set_Geometry(Child.all, (
                     X      => Child_X,
                     Y      => Child_Y,
                     Width  => Child_W,
                     Height => Child_H));

                  Current_Y := Current_Y + Margin.Top + Child_H + Margin.Bottom;

                  --  Recursively layout child
                  Layout_Child(Child.all);
               end;
            end loop;
         end;
      end if;
   end Layout;
end Adi.Widget.Box;
