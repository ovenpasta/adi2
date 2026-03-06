with Adi.Font;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Label is

   Default_Icon_Size : constant Size_2D := (16.0, 16.0);

   ------------
   -- Create --
   ------------

   function Create (Text : String := "") return Label_Widget_Access is
      Result : constant Label_Widget_Access := new Label_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      if Text /= "" then
         Result.Text := To_Unbounded_String (Text);
      end if;
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle (Text : String := "") return Label_Handle is
   begin
      return (Id => Get_Handle (Create (Text).all).Id);
   end Create_Handle;

   -----------------------
   -- To_Widget_Handle --
   -----------------------

   function To_Widget_Handle (H : Label_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   -------------------
   -- Try_As_Label --
   -------------------

   function Try_As_Label (H : Widget_Handle) return Label_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Label_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Label_Handle;
   end Try_As_Label;

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (H : Label_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   --------------
   -- Set_Text --
   --------------

   procedure Set_Text (W : in out Label_Widget; Text : String) is
   begin
      W.Text := To_Unbounded_String (Text);
      Mark_Dirty (W);
   end Set_Text;

   --------------
   -- Get_Text --
   --------------

   function Get_Text (W : Label_Widget) return String is
   begin
      return To_String (W.Text);
   end Get_Text;

   --------------
   -- Set_Icon --
   --------------

   procedure Set_Icon (W : in out Label_Widget; Icon : Image_Access) is
   begin
      W.Icon := Icon;
      Mark_Dirty (W);
   end Set_Icon;

   --------------
   -- Get_Icon --
   --------------

   function Get_Icon (W : Label_Widget) return Image_Access is
   begin
      return W.Icon;
   end Get_Icon;

   ---------------------------------------------------------------------------
   --  Typed handle method overloads
   ---------------------------------------------------------------------------

   procedure Set_Text (H : Label_Handle; Text : String) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Text (Label_Widget (Ptr.all), Text);
      end if;
   end Set_Text;

   function Get_Text (H : Label_Handle) return String is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Text (Label_Widget (Ptr.all));
      end if;
      return "";
   end Get_Text;

   procedure Set_Icon (H : Label_Handle; Icon : Image_Access) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Icon (Label_Widget (Ptr.all), Icon);
      end if;
   end Set_Icon;

   function "+" (H : Label_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles (H : Label_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   ---------------------
   -- Measure_Content --
   ---------------------

   function Measure_Content (W : Label_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Label_Part);
      Icon_Style  : constant Resolved_Style := Get_Resolved_Part_Style (W, Icon_Part);

      Has_Icon : constant Boolean :=
        W.Icon /= null and then Icon_Style.Display /= Display_None;
      Has_Text : constant Boolean :=
        Length (W.Text) > 0 and then Label_Style.Display /= Display_None;

      Icon_Size : Size_2D := (0.0, 0.0);
      Text_Size : Size_2D := (0.0, 0.0);
      Gap : Pixel_Type := 0.0;
      Result : Size_2D;
   begin
      --  Get gap
      Gap := Get_Main_Gap (Main_Style.Gap, Main_Style.Flex_Direction);

      --  Get icon size
      if Has_Icon and then Is_Valid (W.Icon.all) then
         Get_Size (W.Icon.all, Icon_Size.Width, Icon_Size.Height);
      elsif Has_Icon then
         Icon_Size := Default_Icon_Size;
      end if;

      if Has_Icon then
         declare
            Intrinsic : constant Size_2D := Icon_Size;
            Width_Fixed  : constant Boolean := Icon_Style.Width.Kind = Fixed;
            Height_Fixed : constant Boolean := Icon_Style.Height.Kind = Fixed;
         begin
            if Width_Fixed then
               Icon_Size.Width := Size_To_Px (Icon_Style.Width, W.Geometry.Width);
            end if;
            if Height_Fixed then
               Icon_Size.Height := Size_To_Px (Icon_Style.Height, W.Geometry.Height);
            end if;

            if Width_Fixed and then not Height_Fixed and then Intrinsic.Width > 0.0 then
               Icon_Size.Height := Icon_Size.Width * Intrinsic.Height / Intrinsic.Width;
            elsif Height_Fixed and then not Width_Fixed and then Intrinsic.Height > 0.0 then
               Icon_Size.Width := Icon_Size.Height * Intrinsic.Width / Intrinsic.Height;
            end if;

            Icon_Size.Width := Pixel_Type'Max (0.0, Icon_Size.Width);
            Icon_Size.Height := Pixel_Type'Max (0.0, Icon_Size.Height);
         end;
      end if;

      --  Get text size from TTF measurement.
      --  When text-wrap is enabled and the widget already has a geometry width
      --  (e.g. set by a parent's sizing pass), use Measure_Text_Wrapped so that
      --  Get_Preferred_Size returns the correct multi-line height.
      if Has_Text then
         declare
            Font_Attrs : constant Adi.Font.Font_Attributes :=
              Adi.Font.Make_Attributes
                (Family     => Label_Style.Font_Family,
                 Size       => Float (Length_To_Px (Label_Style.Font_Size)),
                 Weight     => Label_Style.Font_Weight,
                 Style      => Label_Style.Font_Style,
                 Decoration => Label_Style.Text_Decoration);
            Can_Wrap : constant Boolean :=
              Label_Style.Text_Wrap_Mode = TWM_Wrap
              and then Label_Style.White_Space /= WS_NoWrap;
            Wrap_W : constant Pixel_Type :=
              Content_Box (W.Geometry, Main_Style).Width;
         begin
            if Can_Wrap and then Wrap_W > 0.0 then
               Text_Size := Adi.Font.Measure_Text_Wrapped
                 (Attrs      => Font_Attrs,
                  Content    => To_String (W.Text),
                  Wrap_Width => Wrap_W);
            else
               Text_Size := Adi.Font.Measure_Text
                 (Attrs   => Font_Attrs,
                  Content => To_String (W.Text));
            end if;
         end;
      end if;

      --  Calculate total size based on flex direction
      declare
         Dir : constant Flex_Direction_Value := Main_Style.Flex_Direction;
         Icon_Main  : constant Pixel_Type := Get_Main_Size (Icon_Size, Dir);
         Icon_Cross : constant Pixel_Type := Get_Cross_Size (Icon_Size, Dir);
         Text_Main  : constant Pixel_Type := Get_Main_Size (Text_Size, Dir);
         Text_Cross : constant Pixel_Type := Get_Cross_Size (Text_Size, Dir);
         Total_Main  : Pixel_Type := Icon_Main + Text_Main;
         Total_Cross : constant Pixel_Type := Pixel_Type'Max (Icon_Cross, Text_Cross);
      begin
         if Has_Icon and Has_Text then
            Total_Main := Total_Main + Gap;
         end if;
         Result := Make_Size (Total_Main, Total_Cross, Dir);
      end;

      return Outer_Size (Result, Main_Style);
   end Measure_Content;

   ------------------
   -- Get_Min_Size --
   ------------------

   overriding function Get_Min_Size (W : Label_Widget) return Size_2D is
      --  Return max(CSS min-width, intrinsic text min-width).
      --  Intrinsic min = longest word width (wrappable) or full text (nowrap).
      CSS_Min     : constant Size_2D := Get_Min_Size (Widget (W));
      Main_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Label_Part);
      Has_Text    : constant Boolean := Length (W.Text) > 0;
      Min_W       : Pixel_Type := CSS_Min.Width;
   begin
      if Has_Text then
         declare
            Font_Attrs : constant Adi.Font.Font_Attributes :=
              Adi.Font.Make_Attributes
                (Family     => Label_Style.Font_Family,
                 Size       => Float (Length_To_Px (Label_Style.Font_Size)),
                 Weight     => Label_Style.Font_Weight,
                 Style      => Label_Style.Font_Style,
                 Decoration => Label_Style.Text_Decoration);
            Can_Wrap    : constant Boolean :=
              Label_Style.Text_Wrap_Mode = TWM_Wrap
              and then Label_Style.White_Space /= WS_NoWrap;
            Text_Min_W  : Pixel_Type;
         begin
            if Can_Wrap then
               Text_Min_W := Adi.Font.Measure_Min_Text_Width
                 (Attrs => Font_Attrs, Content => To_String (W.Text));
            else
               Text_Min_W := Adi.Font.Measure_Text
                 (Attrs => Font_Attrs, Content => To_String (W.Text)).Width;
            end if;

            --  Include padding + border chrome around the text min-width
            declare
               Content_Min : constant Size_2D := (Text_Min_W, 0.0);
               Outer_Min   : constant Size_2D :=
                 Outer_Size (Content_Min, Main_Style);
            begin
               Min_W := Pixel_Type'Max (Min_W, Outer_Min.Width);
            end;
         end;
      end if;

      return (Min_W, CSS_Min.Height);
   end Get_Min_Size;

   ------------
   -- Layout --
   ------------

   overriding procedure Layout (W : in out Label_Widget) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Icon_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Icon_Part);
      Label_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Label_Part);

      Has_Icon : constant Boolean :=
        W.Icon /= null and then Icon_Style.Display /= Display_None;
      Has_Text : constant Boolean :=
        Length (W.Text) > 0 and then Label_Style.Display /= Display_None;
   begin
      --  Clear previous layout items
      W.Layout_Items.Clear;

      --  Build layout items list
      if Has_Icon then
         declare
            Icon_Item : Layout_Item;
            Icon_Size : Size_2D;
            Intrinsic : Size_2D;
            Width_Fixed  : constant Boolean := Icon_Style.Width.Kind = Fixed;
            Height_Fixed : constant Boolean := Icon_Style.Height.Kind = Fixed;
         begin
            --  Get icon size from style or image
            if Is_Valid (W.Icon.all) then
               Get_Size (W.Icon.all, Intrinsic.Width, Intrinsic.Height);
            else
               Intrinsic := Default_Icon_Size;
            end if;

            Icon_Size := Intrinsic;

            --  Honor fixed icon size from Icon_Part style.
            if Width_Fixed then
               Icon_Size.Width := Size_To_Px (Icon_Style.Width, W.Geometry.Width);
            end if;
            if Height_Fixed then
               Icon_Size.Height := Size_To_Px (Icon_Style.Height, W.Geometry.Height);
            end if;

            --  If only one dimension is fixed, preserve intrinsic aspect ratio.
            if Width_Fixed and then not Height_Fixed
              and then Intrinsic.Width > 0.0
            then
               Icon_Size.Height := Icon_Size.Width * Intrinsic.Height / Intrinsic.Width;
            elsif Height_Fixed and then not Width_Fixed
              and then Intrinsic.Height > 0.0
            then
               Icon_Size.Width := Icon_Size.Height * Intrinsic.Width / Intrinsic.Height;
            end if;

            Icon_Size.Width := Pixel_Type'Max (0.0, Icon_Size.Width);
            Icon_Size.Height := Pixel_Type'Max (0.0, Icon_Size.Height);

            Icon_Item := (
               Part           => Icon_Part,
               Min_Width      => Float (Icon_Size.Width),
               Min_Height     => Float (Icon_Size.Height),
               Max_Width      => Float (Icon_Size.Width),
               Max_Height     => Float (Icon_Size.Height),
               Content_Width  => Float (Icon_Size.Width),
               Content_Height => Float (Icon_Size.Height),
               Flex           => (
                  Grow       => 0.0,   -- Don't grow
                  Shrink     => 0.0,   -- Don't shrink
                  Basis      => Float (Icon_Size.Width),
                  Align_Self => Icon_Style.Align_Self
               ),
               Geometry       => <>,
               Index          => 1  -- Icon is first
            );

            W.Layout_Items.Append (Icon_Item);
         end;
      end if;

      if Has_Text then
         declare
            Text_Item   : Layout_Item;
            Font_Attrs  : constant Adi.Font.Font_Attributes :=
              Adi.Font.Make_Attributes
                (Family     => Label_Style.Font_Family,
                 Size       => Float (Length_To_Px (Label_Style.Font_Size)),
                 Weight     => Label_Style.Font_Weight,
                 Style      => Label_Style.Font_Style,
                 Decoration => Label_Style.Text_Decoration);
            Text_Size   : constant Size_2D :=
              Adi.Font.Measure_Text (Attrs => Font_Attrs,
                                     Content => To_String (W.Text));
            Can_Wrap    : constant Boolean :=
              Label_Style.Text_Wrap_Mode = TWM_Wrap
              and then Label_Style.White_Space /= WS_NoWrap;
         begin
            Text_Item := (
               Part           => Label_Part,
               Min_Width      => (if Can_Wrap then
                                    Float (Adi.Font.Measure_Min_Text_Width
                                      (Font_Attrs, To_String (W.Text)))
                                  else Float (Text_Size.Width)),
               Min_Height     => Float (Text_Size.Height),
               Max_Width      => Float'Last,
               Max_Height     => Float'Last,
               Content_Width  => Float (Text_Size.Width),
               Content_Height => Float (Text_Size.Height),
               Flex           => (
                  Grow       => 1.0,
                  Shrink     => (if Can_Wrap then 1.0 else 0.0),
                  Basis      => 0.0,
                  Align_Self => Label_Style.Align_Self
               ),
               Geometry       => <>,
               Index          => 2
            );

            W.Layout_Items.Append (Text_Item);
         end;
      end if;

      --  Run item-based flex layout
      if not W.Layout_Items.Is_Empty then
         --  Use content box (geometry minus padding/border) for flex layout
         declare
            Content : constant Rectangle := Content_Box (W.Geometry, Main_Style);
            Pad : constant Edge_Pixels := Get_Padding_Px (Main_Style);
            Border : constant Edge_Pixels := Get_Border_Width_Px (Main_Style);
         begin
            Perform_Item_Flex_Layout (
               Container_Geom  => Content,
               Container_Style => Main_Style,
               Items           => W.Layout_Items
            );

            --  Re-measure text with assigned width to get wrapped height
            if Has_Text then
               declare
                  Label_Style : constant Resolved_Style :=
                    Get_Resolved_Part_Style (W, Label_Part);
                  Wrapped_Changed : Boolean := False;
               begin
                  if Label_Style.Text_Wrap_Mode = TWM_Wrap then
                     for L_Item of W.Layout_Items loop
                        if L_Item.Part = Label_Part
                          and then L_Item.Geometry.Width > 0.0
                        then
                           declare
                              Font_Attrs : constant Adi.Font.Font_Attributes :=
                                Adi.Font.Make_Attributes
                                  (Family     => Label_Style.Font_Family,
                                   Size       => Float (Length_To_Px (Label_Style.Font_Size)),
                                   Weight     => Label_Style.Font_Weight,
                                   Style      => Label_Style.Font_Style,
                                   Decoration => Label_Style.Text_Decoration);
                              Wrapped : constant Size_2D :=
                                Adi.Font.Measure_Text_Wrapped
                                  (Attrs      => Font_Attrs,
                                   Content    => To_String (W.Text),
                                   Wrap_Width => L_Item.Geometry.Width);
                           begin
                              if Wrapped.Height /= L_Item.Geometry.Height
                              then
                                 L_Item.Geometry.Height := Wrapped.Height;
                                 L_Item.Content_Width :=
                                   Float (L_Item.Geometry.Width);
                                 L_Item.Content_Height :=
                                    Float (Wrapped.Height);
                                 L_Item.Min_Height :=
                                    Float (Wrapped.Height);
                                 Wrapped_Changed := True;
                              end if;
                           end;
                           exit;
                        end if;
                     end loop;
                  end if;

                  --  Update widget height to fit wrapped content.
                  --  Compute needed height directly from content sizes
                  --  (not from flex-positioned items, which may have been
                  --  shrunk/packed in a too-small content box).
                  if Wrapped_Changed then
                     declare
                        Content_H : Pixel_Type := 0.0;
                        Item_Gap  : Pixel_Type := 0.0;
                        Num_Items : Natural := 0;
                        Needed    : Pixel_Type;
                        Reflow_Content : Rectangle;
                     begin
                        --  Get gap between items
                        Item_Gap := Get_Main_Gap
                          (Main_Style.Gap, Main_Style.Flex_Direction);

                        --  Sum content sizes based on direction
                        declare
                           Dir       : constant Flex_Direction_Value :=
                             Main_Style.Flex_Direction;
                           Main_Sum  : Pixel_Type := 0.0;
                           Cross_Max : Pixel_Type := 0.0;
                           Item_S    : Size_2D;
                        begin
                           for L_Item of W.Layout_Items loop
                              Item_S := (Pixel_Type (L_Item.Content_Width),
                                         Pixel_Type (L_Item.Content_Height));
                              Main_Sum  := Main_Sum
                                + Get_Main_Size (Item_S, Dir);
                              Cross_Max := Pixel_Type'Max
                                (Cross_Max, Get_Cross_Size (Item_S, Dir));
                              Num_Items := Num_Items + 1;
                           end loop;
                           if Num_Items > 1 then
                              Main_Sum := Main_Sum
                                + Item_Gap * Pixel_Type (Num_Items - 1);
                           end if;
                           Content_H := Make_Size
                             (Main_Sum, Cross_Max, Dir).Height;
                        end;

                        Needed := Content_H
                                  + Pad.Top + Pad.Bottom
                                  + Border.Top + Border.Bottom;
                        if Needed > W.Geometry.Height then
                           W.Geometry.Height := Needed;
                        end if;

                        --  Re-run flex layout with updated content box
                        --  so items get properly aligned (centered etc.)
                        Reflow_Content := Content_Box
                          (W.Geometry, Main_Style);
                        Perform_Item_Flex_Layout (
                           Container_Geom  => Reflow_Content,
                           Container_Style => Main_Style,
                           Items           => W.Layout_Items);
                     end;
                  end if;
               end;
            end if;
         end;
      end if;
   end Layout;

   -----------------
   -- Build_Items --
   -----------------

   overriding procedure Build_Items (W : in out Label_Widget) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Content    : constant Rectangle := Content_Box (W.Geometry, Main_Style);

      function Clamp_Horizontal_To_Content (R : Rectangle) return Rectangle is
         X1 : constant Pixel_Type := Pixel_Type'Max (R.X, Content.X);
         Y1 : constant Pixel_Type := Pixel_Type'Max (R.Y, Content.Y);
         X2 : constant Pixel_Type := Pixel_Type'Min (R.X + R.Width,
                                                     Content.X + Content.Width);
      begin
         if X2 <= X1 then
            return (X => X1, Y => Y1, Width => 0.0, Height => R.Height);
         end if;
         return (X => X1, Y => R.Y, Width => X2 - X1, Height => R.Height);
      end Clamp_Horizontal_To_Content;

   begin
      if Item_Count (W) = 0 then
         --  First build: create items at fixed indices
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));       --  Panel_Idx
         Add_Item (W, Make_Text (Label_Part, W.Geometry, "", 1));   --  Text_Idx
         Add_Item (W, Make_Image (Icon_Part, W.Geometry, null, 1)); --  Icon_Idx
      end if;

      --  Update panel geometry
      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

      --  Update text item
      declare
         Text_It : Item renames W.Items.Reference (Text_Idx).Element.all;
         Label_Style : constant Resolved_Style :=
           Get_Resolved_Part_Style (W, Label_Part);
         Found : Boolean := False;
      begin
         Text_It.Text_Content := W.Text;
         Text_It.Wrap_Text :=
           Label_Style.Text_Wrap_Mode = TWM_Wrap
           and then Label_Style.White_Space /= WS_NoWrap;
         Text_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         for L_Item of W.Layout_Items loop
            if L_Item.Part = Label_Part then
               Text_It.Geometry := Clamp_Horizontal_To_Content (L_Item.Geometry);
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            Text_It.Text_Content := Null_Unbounded_String;
         end if;
      end;

      --  Update icon item
      declare
         Icon_It : Item renames W.Items.Reference (Icon_Idx).Element.all;
         Found : Boolean := False;
      begin
         Icon_It.Image_Source := W.Icon;
         Icon_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         for L_Item of W.Layout_Items loop
            if L_Item.Part = Icon_Part then
               Icon_It.Geometry := L_Item.Geometry;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            Icon_It.Image_Source := null;
         end if;
      end;
   end Build_Items;

end Adi.Widget.Label;
