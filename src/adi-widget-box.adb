--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Strings.Unbounded;
with Adi.Assets;
with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Box is

   function Child_At
     (W     : Widget'Class;
      Index : Positive) return Widget_Access
   is
      H : constant Widget_Handle := Get_Child_Handle (W, Index);
   begin
      return Widget_Stores.Get (H.Id);
   end Child_At;

   function Child_Participates (Child : Widget_Access) return Boolean is
   begin
      return Child /= null
        and then Has_Flag (Child.all, Visible)
        and then Get_Resolved_Part_Style (Child.all, Main_Part).Display /= Display_None;
   end Child_Participates;

   ---------------------------------------------------------------------------
   --  Construction
   ---------------------------------------------------------------------------

   function Create return Box_Widget_Access is
      Result : constant Box_Widget_Access := new Box_Widget;
   begin
      --  Boxes are not clickable/focusable by default
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   function Create (X, Y, W, H : Pixel_Type) return Box_Widget_Access is
      Result : constant Box_Widget_Access := Create;
   begin
      Result.Geometry := (X, Y, W, H);
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle return Box_Handle is
   begin
      return (Id => Get_Handle (Create.all).Id);
   end Create_Handle;

   function Create_Handle (X, Y, W, H : Pixel_Type) return Box_Handle is
   begin
      return (Id => Get_Handle (Create (X, Y, W, H).all).Id);
   end Create_Handle;

   function To_Widget_Handle (H : Box_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Box (H : Widget_Handle) return Box_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Box_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Box_Handle;
   end Try_As_Box;

   function Is_Valid (H : Box_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   procedure Add_Child (H : Box_Handle; C : Widget_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Add_Child (Ptr.all, C);
      end if;
   end Add_Child;

   function "+" (H : Box_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles (H : Box_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

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
      begin
         case Style.Background_Image.Kind is
            when Picture_Image =>
               Bg_It.Image_Source := Style.Background_Image.Image;
            when Url_Image =>
               Bg_It.Image_Source := Adi.Assets.Get_Image
                 (Ada.Strings.Unbounded.To_String
                    (Style.Background_Image.URI));
            when No_Image | Linear_Gradient_Image =>
               Bg_It.Image_Source := null;
         end case;
         --  Inset by resolved per-edge border widths so the image does not
         --  cover side-specific borders.
         Bg_It.Geometry :=
            (X      => W.Geometry.X + Border_W.Left,
             Y      => W.Geometry.Y + Border_W.Top,
             Width  =>
               Pixel_Type'Max
                 (0.0,
                  W.Geometry.Width
                    - Border_W.Left
                    - Border_W.Right),
             Height =>
               Pixel_Type'Max
                 (0.0,
                  W.Geometry.Height
                    - Border_W.Top
                    - Border_W.Bottom));
      end;
   end Build_Items;

   --  How small a child can actually get: its own content minimum, but
   --  never below the minimum it demands via CSS. A container that
   --  ignored the latter would report a content minimum smaller than the
   --  children it has to hold, and get squeezed until they overflow it.
   function Effective_Child_Min (Child : Widget'Class) return Size_2D is
      Demanded : constant Size_2D := Get_Min_Size (Child);
      Content  : constant Size_2D := Get_Content_Min_Size (Child);
   begin
      return (Width  => Pixel_Type'Max (Demanded.Width, Content.Width),
              Height => Pixel_Type'Max (Demanded.Height, Content.Height));
   end Effective_Child_Min;

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
            if Child_Participates (Child) then
               declare
                  Child_Style : constant Resolved_Style :=
                    Get_Resolved_Part_Style (Child.all, Main_Part);
               begin
                  --  Absolute children do not contribute to intrinsic size
                  if Child_Style.Position /= Absolute then
                     declare
                        Margin : constant Edge_Pixels :=
                          Get_Margin_Px (Child_Style);
                        Pref : constant Size_2D :=
                          Get_Preferred_Size (Child.all);
                        Min  : constant Size_2D :=
                          Effective_Child_Min (Child.all);
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
                            (Cross_Max,
                             Get_Cross_Size (Effective, Style.Flex_Direction)
                             + Cross_Margins);
                        Count := Count + 1;
                     end;
                  end if;
               end;
            end if;
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
               --  Track-aware measurement: auto columns sized to preferred
               --  content width, px columns use their fixed value, fr columns
               --  contribute their intrinsic minimum (CSS minmax(auto, Xfr)).
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
                     if Child_Participates (Child) then
                        declare
                           Child_Style : constant Resolved_Style :=
                             Get_Resolved_Part_Style (Child.all, Main_Part);
                        begin
                           --  Absolute children do not contribute to grid sizing
                           if Child_Style.Position /= Absolute then
                              declare
                                 Margin : constant Edge_Pixels :=
                                   Get_Margin_Px (Child_Style);
                                 Pref   : constant Size_2D :=
                                   Get_Preferred_Size (Child.all);
                                 Min    : constant Size_2D :=
                                   Effective_Child_Min (Child.all);
                                 Eff_W  : constant Pixel_Type :=
                                   Pixel_Type'Max (Pref.Width, Min.Width)
                                   + Margin.Left + Margin.Right;
                                 Min_W  : constant Pixel_Type :=
                                   Min.Width + Margin.Left + Margin.Right;
                                 C  : Natural :=
                                   Natural (Child_Style.Grid_Column);
                                 R  : constant Natural :=
                                   Natural (Child_Style.Grid_Row);
                                 CS : Natural :=
                                   Natural (Child_Style.Grid_Column_Span);
                              begin
                                 if CS = 0 then
                                    CS := 1;
                                 end if;

                                 --  Replicate placement logic from
                                 --  Compute_Grid_Layout.
                                 if C = 0 and then R = 0 then
                                    Auto_Index := Auto_Index + 1;
                                    C := ((Auto_Index - 1) mod Cols) + 1;
                                 elsif C = 0 then
                                    C := 1;
                                 elsif R = 0 then
                                    Auto_Index := Auto_Index + 1;
                                 end if;
                                 C  := Natural'Max
                                   (1, Natural'Min (C, Cols));
                                 CS := Natural'Max
                                   (1, Natural'Min (CS, Cols - C + 1));

                                 Max_Child_H := Pixel_Type'Max
                                   (Max_Child_H,
                                    Pixel_Type'Max (Pref.Height, Min.Height)
                                    + Margin.Top + Margin.Bottom);

                                 for Span_Offset in 0 .. CS - 1 loop
                                    declare
                                       Sc : constant Natural :=
                                         C + Span_Offset;
                                    begin
                                       if Tracks.Tracks (Sc).Kind =
                                         Track_Auto
                                       then
                                          Col_Max_W (Sc) := Pixel_Type'Max
                                            (Col_Max_W (Sc),
                                             Eff_W / Pixel_Type (CS));
                                       elsif Tracks.Tracks (Sc).Kind =
                                         Track_Fr
                                       then
                                          Col_Max_W (Sc) := Pixel_Type'Max
                                            (Col_Max_W (Sc),
                                             Min_W / Pixel_Type (CS));
                                       end if;
                                    end;
                                 end loop;

                                 Count := Count + 1;
                              end;
                           end if;
                        end;
                     end if;
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
                     if Child_Participates (Child) then
                        declare
                           Child_Style : constant Resolved_Style :=
                             Get_Resolved_Part_Style (Child.all, Main_Part);
                        begin
                           if Child_Style.Position /= Absolute then
                              declare
                                 Margin : constant Edge_Pixels :=
                                   Get_Margin_Px (Child_Style);
                                 Pref : constant Size_2D :=
                                   Get_Preferred_Size (Child.all);
                                 Min  : constant Size_2D :=
                                   Effective_Child_Min (Child.all);
                                 Effective : constant Size_2D :=
                                   (Width  =>
                                      Pixel_Type'Max (Pref.Width, Min.Width),
                                    Height =>
                                      Pixel_Type'Max
                                        (Pref.Height, Min.Height));
                              begin
                                 Max_Child_W := Pixel_Type'Max
                                   (Max_Child_W,
                                    Effective.Width
                                    + Margin.Left + Margin.Right);
                                 Max_Child_H := Pixel_Type'Max
                                   (Max_Child_H,
                                    Effective.Height
                                    + Margin.Top + Margin.Bottom);
                                 Count := Count + 1;
                              end;
                           end if;
                        end;
                     end if;
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
            if Child_Participates (Child) then
               declare
                  Child_Style : constant Resolved_Style :=
                    Get_Resolved_Part_Style (Child.all, Main_Part);
               begin
                  if Child_Style.Position /= Absolute then
                     declare
                        Margin : constant Edge_Pixels :=
                          Get_Margin_Px (Child_Style);
                        Pref : constant Size_2D :=
                          Get_Preferred_Size (Child.all);
                        Min  : constant Size_2D :=
                          Effective_Child_Min (Child.all);
                        Effective : constant Size_2D :=
                          (Width  =>
                             Pixel_Type'Max (Pref.Width, Min.Width),
                           Height =>
                             Pixel_Type'Max (Pref.Height, Min.Height));
                     begin
                        Result.Width := Pixel_Type'Max
                          (Result.Width,
                           Effective.Width + Margin.Left + Margin.Right);
                        Result.Height := Result.Height
                          + Effective.Height + Margin.Top + Margin.Bottom;
                     end;
                  end if;
               end;
            end if;
         end loop;
      end if;

      return Outer_Size (Result, Style);
   end Measure_Content;

   --  Shared by Get_Min_Size and Get_Content_Min_Size: identical
   --  aggregation over the children, differing only in which child
   --  measurement it sums. Content_Min selects Get_Content_Min_Size.
   function Aggregate_Child_Minimums
     (W : Box_Widget; Content_Min : Boolean) return Size_2D
   is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Gap : constant Pixel_Type := Get_Main_Gap (Style.Gap, Style.Flex_Direction);
      Row_Gap : constant Pixel_Type := Get_Row_Gap (Style.Gap);
      Col_Gap : constant Pixel_Type := Get_Column_Gap (Style.Gap);
      Count : Natural := 0;
      Main_Sum : Pixel_Type := 0.0;
      Cross_Max : Pixel_Type := 0.0;
      Result : Size_2D := (0.0, 0.0);
   begin
      if Style.Display = Flex or else Style.Display = Inline_Flex then
         for Child of W.Children loop
            if Child_Participates (Child) then
               declare
                  Child_Style : constant Resolved_Style :=
                    Get_Resolved_Part_Style (Child.all, Main_Part);
               begin
                  if Child_Style.Position /= Absolute then
                     declare
                        Margin : constant Edge_Pixels :=
                          Get_Margin_Px (Child_Style);
                        Min : constant Size_2D :=
                          (if Content_Min
                           then Effective_Child_Min (Child.all)
                           else Get_Min_Size (Child.all));
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
                          + Get_Main_Size (Min, Style.Flex_Direction)
                          + Main_Margins;
                        Cross_Max :=
                          Pixel_Type'Max
                            (Cross_Max,
                             Get_Cross_Size (Min, Style.Flex_Direction)
                             + Cross_Margins);
                        Count := Count + 1;
                     end;
                  end if;
               end;
            end if;
         end loop;

         if Count > 1 then
            Main_Sum := Main_Sum + Gap * Pixel_Type (Count - 1);
         end if;

         Result := Make_Size (Main_Sum, Cross_Max, Style.Flex_Direction);
      elsif Style.Display = Grid or else Style.Display = Inline_Grid then
         declare
            Cols   : constant Natural := Natural'Max (1, Natural (Style.Grid_Columns));
            Tracks : constant Grid_Track_List := Style.Grid_Column_Tracks;
            N      : constant Natural := Child_Count (W);

            type Child_Min_Info is record
               Active   : Boolean := False;
               Col      : Natural := 1;
               Row      : Natural := 1;
               Col_Span : Natural := 1;
               Row_Span : Natural := 1;
               Min_W    : Pixel_Type := 0.0;
               Min_H    : Pixel_Type := 0.0;
            end record;
            type Child_Min_Info_Array is array (Natural range <>) of Child_Min_Info;

            Infos       : Child_Min_Info_Array (1 .. N);
            Active_Count : Natural := 0;
            Auto_Index  : Natural := 0;
            Max_Row_End : Natural := 0;
         begin
            for I in 1 .. N loop
               declare
                  Child : constant Widget_Access := Child_At (W, Positive (I));
               begin
                  if Child_Participates (Child) then
                     declare
                        Child_Style : constant Resolved_Style :=
                          Get_Resolved_Part_Style (Child.all, Main_Part);
                     begin
                        if Child_Style.Position /= Absolute then
                           declare
                              Margin : constant Edge_Pixels :=
                                Get_Margin_Px (Child_Style);
                              --  Grid tracks size to what a child truly
                              --  needs: what it demands via CSS, and what
                              --  its own content cannot go below.
                              Min : constant Size_2D :=
                                Effective_Child_Min (Child.all);
                              C  : Natural :=
                                Natural (Child_Style.Grid_Column);
                              R  : Natural :=
                                Natural (Child_Style.Grid_Row);
                              CS : Natural :=
                                Natural (Child_Style.Grid_Column_Span);
                              RS : Natural :=
                                Natural (Child_Style.Grid_Row_Span);
                           begin
                              if CS = 0 then
                                 CS := 1;
                              end if;
                              if RS = 0 then
                                 RS := 1;
                              end if;

                              if C = 0 and then R = 0 then
                                 Auto_Index := Auto_Index + 1;
                                 C := ((Auto_Index - 1) mod Cols) + 1;
                                 R := ((Auto_Index - 1) / Cols) + 1;
                              elsif C = 0 then
                                 C := 1;
                              elsif R = 0 then
                                 Auto_Index := Auto_Index + 1;
                                 R := ((Auto_Index - 1) / Cols) + 1;
                              end if;

                              C := Natural'Max (1, Natural'Min (C, Cols));
                              CS := Natural'Max
                                (1, Natural'Min (CS, Cols - C + 1));
                              if R = 0 then
                                 R := 1;
                              end if;

                              Active_Count := Active_Count + 1;
                              Infos (Active_Count) :=
                                (Active   => True,
                                 Col      => C,
                                 Row      => R,
                                 Col_Span => CS,
                                 Row_Span => RS,
                                 Min_W    =>
                                   Min.Width + Margin.Left + Margin.Right,
                                 Min_H    =>
                                   Min.Height + Margin.Top + Margin.Bottom);
                              Max_Row_End :=
                                Natural'Max (Max_Row_End, R + RS - 1);
                           end;
                        end if;
                     end;
                  end if;
               end;
            end loop;

            declare
               Rows : constant Natural :=
                 (if Active_Count = 0 then 0
                  elsif Natural (Style.Grid_Rows) > 0 then
                    Natural'Max (Natural (Style.Grid_Rows), Max_Row_End)
                  else
                    Natural'Max (1, Max_Row_End));
            begin
               declare
                  Col_Min_W : array (1 .. Cols) of Pixel_Type := [others => 0.0];
               begin
                  if Tracks.Count = Cols then
                     for C in 1 .. Cols loop
                        if Tracks.Tracks (C).Kind = Track_Px then
                           Col_Min_W (C) := Pixel_Type (Tracks.Tracks (C).Value);
                        end if;
                     end loop;
                  end if;

                  for I in 1 .. Active_Count loop
                     declare
                        Share_W : constant Pixel_Type :=
                          Infos (I).Min_W / Pixel_Type (Infos (I).Col_Span);
                     begin
                        for Span_Offset in 0 .. Infos (I).Col_Span - 1 loop
                           declare
                              Sc : constant Natural := Infos (I).Col + Span_Offset;
                           begin
                              if Tracks.Count = Cols
                                and then Tracks.Tracks (Sc).Kind = Track_Px
                              then
                                 null;
                              else
                                 Col_Min_W (Sc) := Pixel_Type'Max (Col_Min_W (Sc), Share_W);
                              end if;
                           end;
                        end loop;
                     end;
                  end loop;

                  for C in 1 .. Cols loop
                     Result.Width := Result.Width + Col_Min_W (C);
                  end loop;
                  if Cols > 1 then
                     Result.Width := Result.Width + Pixel_Type (Cols - 1) * Col_Gap;
                  end if;
               end;

               if Rows > 0 then
                  declare
                     Row_Min_H : array (1 .. Rows) of Pixel_Type := [others => 0.0];
                  begin
                     for I in 1 .. Active_Count loop
                        declare
                           Share_H : constant Pixel_Type :=
                             Infos (I).Min_H / Pixel_Type (Infos (I).Row_Span);
                        begin
                           for Span_Offset in 0 .. Infos (I).Row_Span - 1 loop
                              declare
                                 Sr : constant Natural := Infos (I).Row + Span_Offset;
                              begin
                                 if Sr <= Rows then
                                    Row_Min_H (Sr) :=
                                      Pixel_Type'Max (Row_Min_H (Sr), Share_H);
                                 end if;
                              end;
                           end loop;
                        end;
                     end loop;

                     for R in 1 .. Rows loop
                        Result.Height := Result.Height + Row_Min_H (R);
                     end loop;
                     if Rows > 1 then
                        Result.Height := Result.Height + Pixel_Type (Rows - 1) * Row_Gap;
                     end if;
                  end;
               end if;
            end;
         end;
      else
         --  Conservative fallback for non-flex containers: keep the largest
         --  child minimum footprint.  This is sufficient as a shrink floor.
         for Child of W.Children loop
            if Child_Participates (Child) then
               declare
                  Child_Style : constant Resolved_Style :=
                    Get_Resolved_Part_Style (Child.all, Main_Part);
               begin
                  if Child_Style.Position /= Absolute then
                     declare
                        Margin : constant Edge_Pixels :=
                          Get_Margin_Px (Child_Style);
                        Min : constant Size_2D :=
                          (if Content_Min
                           then Effective_Child_Min (Child.all)
                           else Get_Min_Size (Child.all));
                     begin
                        Result.Width := Pixel_Type'Max
                          (Result.Width,
                           Min.Width + Margin.Left + Margin.Right);
                        Result.Height := Pixel_Type'Max
                          (Result.Height,
                           Min.Height + Margin.Top + Margin.Bottom);
                     end;
                  end if;
               end;
            end if;
         end loop;
      end if;

      --  A box that does not show its overflow — scrolled, or simply
      --  clipped — does not inherit its content's minimum in that axis.
      --  Scrolling shows the content a piece at a time and hiding drops
      --  the excess, so neither needs room for all of it. This matches
      --  the automatic minimum the parent computes for the same box.
      --  Without it a scrollable viewport is forced as tall as
      --  everything inside, so nothing overflows and it never scrolls.
      if Style.Overflow_Y /= Overflow_Visible then
         Result.Height := 0.0;
      end if;
      if Style.Overflow_X /= Overflow_Visible then
         Result.Width := 0.0;
      end if;

      return Outer_Size (Result, Style);
   end Aggregate_Child_Minimums;

   overriding function Get_Min_Size (W : Box_Widget) return Size_2D is
      CSS_Min : constant Size_2D := Get_Min_Size (Widget (W));
      Result  : constant Size_2D :=
        Aggregate_Child_Minimums (W, Content_Min => False);
   begin
      return
        (Width  => Pixel_Type'Max (CSS_Min.Width, Result.Width),
         Height => Pixel_Type'Max (CSS_Min.Height, Result.Height));
   end Get_Min_Size;

   overriding function Get_Content_Min_Size (W : Box_Widget) return Size_2D is
   begin
      --  A container's content cannot be squeezed smaller than what its
      --  children need; no CSS floor here, that is Get_Min_Size's job.
      return Aggregate_Child_Minimums (W, Content_Min => True);
   end Get_Content_Min_Size;

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
                  Use_Preferred_Floor => Style.Overflow_X = Overflow_Visible,
                  Column_Tracks       => Style.Grid_Column_Tracks);
               Children_Info : Grid_Child_Info_Array (1 .. N);
               Rects : Rectangle_Array (1 .. N);
            begin
               for I in 1 .. N loop
                  declare
                     Child : constant Widget_Access := Child_At (W, Positive (I));
                  begin
                     if not Child_Participates (Child) then
                        Children_Info (Positive (I)) :=
                          (Active => False, others => <>);
                     else
                        declare
                           Child_Style : constant Resolved_Style :=
                             Get_Resolved_Part_Style (Child.all, Main_Part);
                           Child_Pref : constant Size_2D :=
                             Get_Preferred_Size (Child.all);
                           --  Track sizing must see the content floor as
                           --  well as the declared minimum.
                           Child_Min  : constant Size_2D :=
                             Effective_Child_Min (Child.all);
                        begin
                           --  Absolute children are out of flow
                           if Child_Style.Position = Absolute then
                              Children_Info (Positive (I)) :=
                                (Active => False, others => <>);
                           else
                              Children_Info (Positive (I)) :=
                                (Active           => True,
                                 Grid_Column      =>
                                   Natural (Child_Style.Grid_Column),
                                 Grid_Row         =>
                                   Natural (Child_Style.Grid_Row),
                                 Grid_Column_Span =>
                                   Natural (Child_Style.Grid_Column_Span),
                                 Grid_Row_Span    =>
                                   Natural (Child_Style.Grid_Row_Span),
                                 Min_Width        => Child_Min.Width,
                                 Min_Height       => Child_Min.Height,
                                 Pref_Width       => Child_Pref.Width,
                                 Pref_Height      => Child_Pref.Height,
                                 others           => <>);
                           end if;
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
                          Child_At (W, Positive (I));
                        Provisional : Rectangle := Rects (Positive (I));
                     begin
                        if Child /= null
                          and then Children_Info (Positive (I)).Active
                          and then Provisional.Width > 0.0
                        then
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

               --  Container growth: when vertical overflow is visible (the
               --  default), grow W.Geometry if row heights exceed allocated
               --  height. For overflow-y:hidden/scroll/auto the box clips
               --  instead of growing.
               if Style.Overflow_Y = Overflow_Visible then
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
                     Child : constant Widget_Access := Child_At (W, Positive (I));
                  begin
                     if Child /= null and then Children_Info (Positive (I)).Active then
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

                           --  Apply relative offset after flow placement
                           Apply_Relative_Offset (Child.all, Content);
                        end;
                     end if;
                  end;
               end loop;

               --  Position absolute children against parent content box.
               --  Recompute content box since W.Geometry may have grown
               --  from overflow-driven height expansion above.
               declare
                  Abs_Content : constant Rectangle :=
                    Content_Box (W.Geometry, Style);
               begin
               for I in 1 .. N loop
                  declare
                     Child : constant Widget_Access :=
                       Child_At (W, Positive (I));
                  begin
                     if Child /= null
                       and then Child_Participates (Child)
                     then
                        declare
                           CS : constant Resolved_Style :=
                             Get_Resolved_Part_Style (Child.all, Main_Part);
                        begin
                           if CS.Position = Absolute then
                              Position_Absolute_Child
                                (Child.all, CS, Abs_Content);
                           end if;
                        end;
                     end if;
                  end;
               end loop;
               end;
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
            Block_Content : constant Rectangle :=
              (Content_X, Content_Y, Content_W, Content_H);

            Current_Y : Pixel_Type := Content_Y;
         begin
            --  Simple vertical stacking for block layout
            for Child of W.Children loop
               if Child_Participates (Child) then
                  declare
                     Child_Style : constant Resolved_Style :=
                       Get_Resolved_Part_Style (Child.all, Main_Part);
                  begin
                     --  Skip absolute children from normal flow
                     if Child_Style.Position /= Absolute then
                        declare
                           Margin : constant Edge_Pixels :=
                             Get_Margin_Px (Child_Style);
                           Child_Pref : constant Size_2D :=
                             Get_Preferred_Size (Child.all);
                           Child_H : Pixel_Type := Child_Pref.Height;
                           Child_X : Pixel_Type;
                           Child_Y : Pixel_Type;
                           Child_W : Pixel_Type;
                        begin
                           if Child_H = 0.0 then
                              Child_H := Pixel_Type'Max
                                (0.0,
                                 Content_H - Margin.Top - Margin.Bottom);
                           end if;

                           Child_X := Content_X + Margin.Left;
                           Child_Y := Current_Y + Margin.Top;
                           Child_W := Pixel_Type'Max
                             (0.0, Content_W - Margin.Left - Margin.Right);

                           Set_Geometry (Child.all, (
                              X      => Child_X,
                              Y      => Child_Y,
                              Width  => Child_W,
                              Height => Child_H));

                           Current_Y := Current_Y
                             + Margin.Top + Child_H + Margin.Bottom;

                           Layout_Child (Child.all);
                           Apply_Relative_Offset
                             (Child.all, Block_Content);
                        end;
                     end if;
                  end;
               end if;
            end loop;

            --  Position absolute children against content box
            for Child of W.Children loop
               if Child_Participates (Child) then
                  declare
                     CS : constant Resolved_Style :=
                       Get_Resolved_Part_Style (Child.all, Main_Part);
                  begin
                     if CS.Position = Absolute then
                        Position_Absolute_Child
                          (Child.all, CS, Block_Content);
                     end if;
                  end;
               end if;
            end loop;
         end;
      end if;
   end Layout;
end Adi.Widget.Box;
