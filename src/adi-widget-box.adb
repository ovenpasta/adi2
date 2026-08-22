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
         Add_Item (W, Make_Image (Main_Part, W.Geometry, Adi.Image.Null_Image_Handle, 1,
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
               Bg_It.Image_Source := Adi.Image.Null_Image_Handle;
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

   --  A track whose size is a length rather than auto or a flex factor.
   --  Both resolve here so a pix track sizes and aggregates like a px
   --  one; only the scaling differs.
   --
   --  Written as exhaustive cases without `others` so a new track kind
   --  is a compile error here rather than a track silently treated as
   --  indefinite. Two of the three call sites are ifs, which the
   --  compiler cannot check for us.
   function Is_Definite_Track (Spec : Grid_Track_Spec) return Boolean is
     (case Spec.Kind is
         when Track_Auto | Track_Fr => False,
         when Track_Px | Track_Pix  => True);

   function Definite_Track_Px (Spec : Grid_Track_Spec) return Pixel_Type is
     (case Spec.Kind is
         when Track_Auto | Track_Fr => 0.0,
         when Track_Px              => Length_To_Px (Px (Spec.Value)),
         when Track_Pix             => Length_To_Px (Pix (Spec.Value)));

   --  How small a child can actually get. Shared with Stack, so both
   --  containers cap and floor a child the same way.
   function Effective_Child_Min (Child : Widget'Class) return Size_2D
     renames Effective_Min_Size;

   --  The width a grid child actually gets in a cell: its own declared
   --  width when it has one, the cell otherwise. Measurement and
   --  placement both go through this, so a child is never measured at a
   --  width it will not be rendered at.
   function Grid_Child_Width
     (Child : Widget'Class; Cell_Width : Pixel_Type) return Pixel_Type
   is
      Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (Child, Main_Part);
   begin
      if Style.Width.Kind = Fixed then
         return Size_To_Px (Style.Width, Cell_Width);
      end if;
      return Cell_Width;
   end Grid_Child_Width;

   --  Children that take part in this box's own layout: visible, and in
   --  flow. A hidden or absolutely positioned child is not on the line,
   --  so it neither takes width from the others nor turns a lone child
   --  into a row that has to be distributed to be known.
   function In_Flow_Count (W : Box_Widget) return Natural is
      Count : Natural := 0;
   begin
      for Child of W.Children loop
         if Child_Participates (Child)
           and then Get_Resolved_Part_Style (Child.all, Main_Part).Position
                      /= Absolute
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end In_Flow_Count;

   --  The width one child is laid out at, given the box's content width.
   --  A row of several children shares its line by the flex distribution,
   --  which the caller runs once through Flex_Row_Child_Widths and passes
   --  back in as Row_Width -- the real algorithm rather than a second
   --  implementation of it that could disagree.
   --
   --  Measurement and minimum aggregation both come through here, so a
   --  child is never measured at a width it will not be laid out at.
   function Child_Layout_Width
     (W           : Box_Widget;
      Child       : Widget'Class;
      Inner_Width : Pixel_Type;
      Row_Width   : Pixel_Type := Unknown_Assigned_Width) return Pixel_Type
   is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Child_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (Child, Main_Part);
      Margin : constant Edge_Pixels := Get_Margin_Px (Child_Style);
      Room : constant Pixel_Type :=
        Pixel_Type'Max (0.0, Inner_Width - Margin.Left - Margin.Right);
   begin
      if Inner_Width = Unknown_Assigned_Width then
         return Unknown_Assigned_Width;
      elsif Is_Row_Direction (Style.Flex_Direction) then
         --  On the main axis the distribution has the last word, even
         --  over a declared width: that width is the item's basis, and
         --  it still grows or shrinks from there.
         return Row_Width;
      elsif Child_Style.Width.Kind = Fixed then
         return Size_To_Px (Child_Style.Width, Inner_Width);
      else
         --  Column: stretch is the default, so a child without a width
         --  of its own spans the line.
         if Child_Style.Align_Self = Adi.CSS_Styles.Stretch
           or else (Child_Style.Align_Self = Auto
                    and then Style.Align_Items = Adi.CSS_Styles.Stretch)
         then
            return Room;
         end if;
         return Pixel_Type'Min (Room, Get_Preferred_Size (Child).Width);
      end if;
   end Child_Layout_Width;

   --  The width one child of a block box is laid out at. Measurement,
   --  minimum aggregation and placement all go through here, so a block
   --  child is never measured at a width it will not be given.
   function Block_Child_Width
     (Inner_Width : Pixel_Type; Margin : Edge_Pixels) return Pixel_Type
   is (Pixel_Type'Max (0.0, Inner_Width - Margin.Left - Margin.Right));

   --  How tall this box is at a given outer width.
   overriding function Measure_Content_At_Width
     (W : Box_Widget; Assigned_Width : Pixel_Type) return Size_2D
   is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Padding : constant Edge_Pixels := Get_Padding_Px (Style);
      Border  : constant Edge_Pixels := Get_Border_Width_Px (Style);
      Content_W : constant Pixel_Type :=
        Assigned_Width - Padding.Left - Padding.Right
                       - Border.Left - Border.Right;
      Gap : constant Pixel_Type :=
        Get_Main_Gap (Style.Gap, Style.Flex_Direction);

      Count : Natural := 0;
      Height : Pixel_Type := 0.0;

      --  One entry per possible line; only the first Line_Count are used.
      Line_Depth : array (1 .. Natural'Max (1, Child_Count (W)))
        of Pixel_Type := [others => 0.0];
      Line_Count : Natural := 0;

      Row_Items : constant Flex_Row_Items :=
        Flex_Row_Child_Widths (W, Content_W);
      Row_Index : Natural := 0;

      function Child_Width (Child : Widget'Class) return Pixel_Type is
        (Child_Layout_Width
           (W, Child, Content_W,
            (if Row_Index in Row_Items'Range
             then Row_Items (Row_Index).Width
             else Unknown_Assigned_Width)));

      --  A block box stacks its children down the content box, each of
      --  them spanning the line less its own margins. That width owes
      --  nothing to the children, so every one of them can be measured
      --  at the width the layout is going to hand it.
      function Block_Stack_Height return Pixel_Type is
         Total : Pixel_Type := 0.0;
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
                     begin
                        Total := Total
                          + Measure_At_Width
                              (Child.all,
                               Block_Child_Width (Content_W, Margin)).Height
                          + Margin.Top + Margin.Bottom;
                     end;
                  end if;
               end;
            end if;
         end loop;
         return Total;
      end Block_Stack_Height;
   begin
      if Content_W <= 0.0 then
         return Get_Preferred_Size (W);
      end if;

      --  Everything Layout does not send to the flex or grid algorithms
      --  it stacks as a block, so the same three-way split decides how
      --  it is measured. A grid's height at a width falls out of track
      --  sizing, which only Compute_Grid_Layout knows how to run, so it
      --  keeps the unconstrained answer here.
      case Style.Display is
         when Flex | Inline_Flex =>
            null;
         when Grid | Inline_Grid =>
            return Get_Preferred_Size (W);
         when others =>
            return (Width  => Assigned_Width,
                    Height => Block_Stack_Height
                                + Padding.Top + Padding.Bottom
                                + Border.Top + Border.Bottom);
      end case;

      Count := In_Flow_Count (W);

      if Count = 0 then
         return Get_Preferred_Size (W);
      end if;

      for Child of W.Children loop
         if Child_Participates (Child) then
            declare
               Child_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (Child.all, Main_Part);
            begin
               if Child_Style.Position /= Absolute then
                  Row_Index := Row_Index + 1;
                  declare
                     Margin : constant Edge_Pixels :=
                       Get_Margin_Px (Child_Style);
                     Kid : constant Size_2D :=
                       Measure_At_Width (Child.all, Child_Width (Child.all));
                     Outer_H : constant Pixel_Type :=
                       Kid.Height + Margin.Top + Margin.Bottom;
                  begin
                     if Is_Row_Direction (Style.Flex_Direction) then
                        --  Deepest item on each line; the lines are
                        --  added up once the loop has seen them all.
                        declare
                           L : constant Natural :=
                             (if Row_Index in Row_Items'Range
                              then Row_Items (Row_Index).Line else 1);
                        begin
                           if L in Line_Depth'Range then
                              Line_Depth (L) :=
                                Pixel_Type'Max (Line_Depth (L), Outer_H);
                              Line_Count := Natural'Max (Line_Count, L);
                           else
                              Height := Pixel_Type'Max (Height, Outer_H);
                           end if;
                        end;
                     else
                        Height := Height + Outer_H;
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;

      if Is_Row_Direction (Style.Flex_Direction) then
         for L in 1 .. Line_Count loop
            Height := Height + Line_Depth (L);
         end loop;
         if Line_Count > 1 then
            Height := Height
              + Get_Cross_Gap (Style.Gap, Style.Flex_Direction)
                * Pixel_Type (Line_Count - 1);
         end if;
      elsif Count > 1 then
         Height := Height + Gap * Pixel_Type (Count - 1);
      end if;

      return (Width  => Assigned_Width,
              Height => Height + Padding.Top + Padding.Bottom
                               + Border.Top + Border.Bottom);
   end Measure_Content_At_Width;

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
                     if Is_Definite_Track (Tracks.Tracks (C)) then
                        Col_Max_W (C) :=
                          Definite_Track_Px (Tracks.Tracks (C));
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
   --  What a grid item contributes to its track's minimum. Placement
   --  honours a definite width or height unconditionally, so a track
   --  sized from the item's minimum alone would leave the item hanging
   --  out of its own cell. Percentages resolve against the track being
   --  computed, so they contribute nothing here.
   function Grid_Min_Contribution (Child : Widget'Class) return Size_2D is
      Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (Child, Main_Part);
      Result : Size_2D := Effective_Child_Min (Child);
   begin
      if Style.Width.Kind = Fixed
        and then Style.Width.Size.Unit /= Pct
      then
         Result.Width :=
           Pixel_Type'Max (Result.Width, Size_To_Px (Style.Width, 0.0));
      end if;
      if Style.Height.Kind = Fixed
        and then Style.Height.Size.Unit /= Pct
      then
         Result.Height :=
           Pixel_Type'Max (Result.Height, Size_To_Px (Style.Height, 0.0));
      end if;
      return Result;
   end Grid_Min_Contribution;

   --  Passed when the caller has no width to offer, which keeps the
   --  aggregation width-unaware rather than inventing a width for it.
   Unknown_Width : constant Pixel_Type := Unknown_Assigned_Width;

   function Aggregate_Child_Minimums
     (W              : Box_Widget;
      Content_Min    : Boolean;
      Assigned_Width : Pixel_Type := Unknown_Width) return Size_2D
   is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      --  The box's own content width, once padding and border are taken
      --  off the width it was given.
      Inner_Width : constant Pixel_Type :=
        (if Assigned_Width = Unknown_Width then Unknown_Width
         else Pixel_Type'Max
                (0.0,
                 Content_Box
                   ((X => 0.0, Y => 0.0,
                     Width => Assigned_Width, Height => 0.0), Style).Width));

      Row_Items : constant Flex_Row_Items :=
        (if Inner_Width = Unknown_Assigned_Width then [1 .. 0 => <>]
         else Flex_Row_Child_Widths (W, Inner_Width));
      Row_Index : Natural := 0;

      function Child_Measure_Width (Child : Widget'Class) return Pixel_Type is
        (Child_Layout_Width
           (W, Child, Inner_Width,
            (if Row_Index in Row_Items'Range
             then Row_Items (Row_Index).Width
             else Unknown_Assigned_Width)));
      Gap : constant Pixel_Type := Get_Main_Gap (Style.Gap, Style.Flex_Direction);
      Row_Gap : constant Pixel_Type := Get_Row_Gap (Style.Gap);
      Col_Gap : constant Pixel_Type := Get_Column_Gap (Style.Gap);
      Count : Natural := 0;
      Main_Sum : Pixel_Type := 0.0;
      --  A container that wraps can put every item on a line of its own,
      --  so along the main axis it only ever needs room for the largest
      --  one -- and no gaps, because a line of one has nothing to space.
      Main_Max : Pixel_Type := 0.0;
      Cross_Max : Pixel_Type := 0.0;

      --  A wrapping row needs room for every line, so the cross minimum
      --  is collected per line and added up, the way the measurement
      --  does it. One entry per possible line.
      Line_Cross : array (1 .. Natural'Max (1, Child_Count (W)))
        of Pixel_Type := [others => 0.0];
      Line_Used  : Natural := 0;

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
                     Row_Index := Row_Index + 1;
                     declare
                        Margin : constant Edge_Pixels :=
                          Get_Margin_Px (Child_Style);
                        Child_W : constant Pixel_Type :=
                          Child_Measure_Width (Child.all);
                        Min : constant Size_2D :=
                          (if not Content_Min
                             then Get_Min_Size (Child.all)
                           elsif Child_W = Unknown_Width
                             then Effective_Child_Min (Child.all)
                           else Effective_Min_Size_At_Width
                                  (Child.all, Child_W));
                        --  A child that cannot shrink is laid out at its
                        --  flex base, so the box needs room for that base
                        --  even though the child would allow less. Zero is
                        --  a basis like any other and stays zero.
                        Base_Floor : constant Pixel_Type :=
                          (if Content_Min
                             and then Float (Child_Style.Flex_Shrink) = 0.0
                           then Resolved_Flex_Base
                                  (Child          => Child.all,
                                   Direction      => Style.Flex_Direction,
                                   Assigned_Width =>
                                     (if Child_W = Unknown_Width
                                      then Unknown_Assigned_Width
                                      else Child_W),
                                   Container_Main => 0.0)
                           else 0.0);
                        Main_Margins : constant Pixel_Type :=
                          (if Is_Row_Direction (Style.Flex_Direction)
                           then Margin.Left + Margin.Right
                           else Margin.Top + Margin.Bottom);
                        Cross_Margins : constant Pixel_Type :=
                          (if Is_Row_Direction (Style.Flex_Direction)
                           then Margin.Top + Margin.Bottom
                           else Margin.Left + Margin.Right);
                        Cross_Declared : constant Size_Value :=
                          (if Is_Row_Direction (Style.Flex_Direction)
                           then Child_Style.Height
                           else Child_Style.Width);
                        --  Only the main axis is flex-shrunk, so a
                        --  definite cross size is the size the child
                        --  will take. The container needs room for it,
                        --  even though as a main size it would be a
                        --  flex base and no floor at all. A percentage
                        --  resolves against the container being sized,
                        --  so it cannot floor it.
                        Cross_Floor : constant Pixel_Type :=
                          (if Content_Min
                             and then Cross_Declared.Kind = Fixed
                             and then Cross_Declared.Size.Unit /= Pct
                           then Get_Cross_Size
                                  (Get_Preferred_Size (Child.all),
                                   Style.Flex_Direction)
                           else 0.0);
                     begin
                        declare
                           Contribution : constant Pixel_Type :=
                             Pixel_Type'Max
                               (Get_Main_Size (Min, Style.Flex_Direction),
                                Base_Floor)
                             + Main_Margins;
                        begin
                           Main_Sum := Main_Sum + Contribution;
                           Main_Max :=
                             Pixel_Type'Max (Main_Max, Contribution);
                        end;
                        declare
                           Cross : constant Pixel_Type :=
                             Pixel_Type'Max
                               (Get_Cross_Size (Min, Style.Flex_Direction),
                                Cross_Floor)
                             + Cross_Margins;
                           L : constant Natural :=
                             (if Row_Index in Row_Items'Range
                              then Row_Items (Row_Index).Line else 1);
                        begin
                           Cross_Max := Pixel_Type'Max (Cross_Max, Cross);
                           if L in Line_Cross'Range then
                              Line_Cross (L) :=
                                Pixel_Type'Max (Line_Cross (L), Cross);
                              Line_Used := Natural'Max (Line_Used, L);
                           end if;
                        end;
                        Count := Count + 1;
                     end;
                  end if;
               end;
            end if;
         end loop;

         if Style.Flex_Wrap /= No_Wrap then
            Main_Sum := Main_Max;
         elsif Count > 1 then
            Main_Sum := Main_Sum + Gap * Pixel_Type (Count - 1);
         end if;

         --  Lines only exist once the widths are known, so a widthless
         --  aggregation keeps the single-line answer.
         if Line_Used > 1 then
            Cross_Max := 0.0;
            for L in 1 .. Line_Used loop
               Cross_Max := Cross_Max + Line_Cross (L);
            end loop;
            Cross_Max := Cross_Max
              + Get_Cross_Gap (Style.Gap, Style.Flex_Direction)
                * Pixel_Type (Line_Used - 1);
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
                              --  Same split as the flex branch: what the
                              --  grid *demands* is only what its children
                              --  demand, while its content minimum also
                              --  takes in their intrinsic and definite
                              --  sizes.
                              Min : constant Size_2D :=
                                (if Content_Min
                                 then Grid_Min_Contribution (Child.all)
                                 else Get_Min_Size (Child.all));
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
                        if Is_Definite_Track (Tracks.Tracks (C)) then
                           Col_Min_W (C) :=
                             Definite_Track_Px (Tracks.Tracks (C));
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
                                and then Is_Definite_Track (Tracks.Tracks (Sc))
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
                        Child_W : constant Pixel_Type :=
                          (if Inner_Width = Unknown_Width then Unknown_Width
                           else Block_Child_Width (Inner_Width, Margin));
                        Min : constant Size_2D :=
                          (if not Content_Min
                             then Get_Min_Size (Child.all)
                           elsif Child_W = Unknown_Width
                             then Effective_Child_Min (Child.all)
                           else Effective_Min_Size_At_Width
                                  (Child.all, Child_W));
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

   overriding function Get_Content_Min_Size_At_Width
     (W : Box_Widget; Assigned_Width : Pixel_Type) return Size_2D is
   begin
      return Aggregate_Child_Minimums
        (W, Content_Min => True, Assigned_Width => Assigned_Width);
   end Get_Content_Min_Size_At_Width;

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
                  Use_Preferred_Floor_X =>
                    Style.Overflow_X = Overflow_Visible,
                  Use_Preferred_Floor_Y =>
                    Style.Overflow_Y = Overflow_Visible,
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
                           --  Same contribution the aggregation uses, so
                           --  measurement and placement agree.
                           Child_Min  : constant Size_2D :=
                             Grid_Min_Contribution (Child.all);
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

               --  Sizing pass: ask each child how tall it is at the column
               --  width it just got. Wrapping text answers differently
               --  than it did unconstrained, and a row whose content
               --  grew has to be recomputed so the rest shifts down.
               --  This is a query -- no geometry is assigned here, so a
               --  child cannot end up measured against a width the grid
               --  later takes back.
               declare
                  Height_Changed : Boolean := False;
               begin
                  for I in 1 .. N loop
                     declare
                        Child : constant Widget_Access :=
                          Child_At (W, Positive (I));
                        Cell : constant Rectangle := Rects (Positive (I));
                     begin
                        if Child /= null
                          and then Children_Info (Positive (I)).Active
                          and then Cell.Width > 0.0
                        then
                           declare
                              Actual_H : constant Pixel_Type :=
                                Measure_At_Width
                                  (Child.all,
                                   Grid_Child_Width
                                     (Child.all, Cell.Width)).Height;
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
                           --  Respect explicit width, the same way the
                           --  measuring pass above did.
                           CW := Grid_Child_Width (Child.all, Cell.Width);
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
         --  Simple block layout: stack children down the content area
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
                           Child_X : constant Pixel_Type :=
                             Content_X + Margin.Left;
                           Child_Y : constant Pixel_Type :=
                             Current_Y + Margin.Top;
                           Child_W : constant Pixel_Type :=
                             Block_Child_Width (Content_W, Margin);
                           --  A percentage height is left to whoever
                           --  holds the containing block, which is this
                           --  box. Its own height is settled by the time
                           --  children are placed, so the content box is
                           --  a usable basis however that height was
                           --  arrived at, declared or taken from the
                           --  content. Demanding a declared one, as CSS
                           --  2.1 does, would collapse height: 100%
                           --  inside every container the window sizes.
                           --  Everything else is measured at the width
                           --  it is about to be given, so wrapping text
                           --  gets room for the lines it will really
                           --  take rather than for the single line it
                           --  would like unconstrained.
                           Child_H : constant Pixel_Type :=
                             (if Child_Style.Height.Kind = Fixed
                                and then Child_Style.Height.Size.Unit = Pct
                              then Size_To_Px
                                     (Child_Style.Height,
                                      Pixel_Type'Max (0.0, Content_H))
                              else Measure_At_Width
                                     (Child.all, Child_W).Height);
                        begin
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
