with Adi.Font;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Label is

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
      return Result;
   end Create;

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

   ---------------------
   -- Measure_Content --
   ---------------------

   function Measure_Content (W : Label_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Label_Part);

      Has_Icon : constant Boolean := W.Icon /= null;
      Has_Text : constant Boolean := Length (W.Text) > 0;

      Icon_Size : Size_2D := (0.0, 0.0);
      Text_Size : Size_2D := (0.0, 0.0);
      Gap : Pixel_Type := 0.0;
      Result : Size_2D;

      Pad : constant Edge_Pixels := Get_Padding_Px (Main_Style);
      Border : constant Edge_Pixels := Get_Border_Width_Px (Main_Style);
   begin
      --  Get gap
      Gap := Get_Main_Gap (Main_Style.Gap, Main_Style.Flex_Direction);

      --  Get icon size
      if Has_Icon and then Is_Valid (W.Icon.all) then
         Get_Size (W.Icon.all, Icon_Size.Width, Icon_Size.Height);
      end if;

      --  Get text size from TTF measurement
      if Has_Text then
         declare
            Can_Wrap : constant Boolean :=
              Label_Style.Text_Wrap_Mode = TWM_Wrap
              and then Label_Style.White_Space /= WS_NoWrap;
         begin
            Text_Size := Adi.Font.Measure_Text
              (Handle    => Label_Style.Font_Family,
               Content   => To_String (W.Text),
               Font_Size => Label_Style.Font_Size.Amount);

            --  When wrapping is allowed, text can shrink in the main axis.
            if Can_Wrap then
               Text_Size.Width := 0.0;
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

      --  Add padding and border
      Result.Width := Result.Width + Pad.Left + Pad.Right + Border.Left + Border.Right;
      Result.Height := Result.Height + Pad.Top + Pad.Bottom + Border.Top + Border.Bottom;

      return Result;
   end Measure_Content;

   ------------
   -- Layout --
   ------------

   overriding procedure Layout (W : in out Label_Widget) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Icon_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Icon_Part);

      Has_Icon : constant Boolean := W.Icon /= null;
      Has_Text : constant Boolean := Length (W.Text) > 0;
   begin
      --  Clear previous layout items
      W.Layout_Items.Clear;

      --  Build layout items list
      if Has_Icon then
         declare
            Icon_Item : Layout_Item;
            Icon_Size : Size_2D;
         begin
            --  Get icon size from style or image
            if Is_Valid (W.Icon.all) then
               Get_Size (W.Icon.all, Icon_Size.Width, Icon_Size.Height);
            else
               Icon_Size := (16.0, 16.0);  -- Default icon size
            end if;

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
            Label_Style : constant Resolved_Style :=
              Get_Resolved_Part_Style (W, Label_Part);
            Text_Size   : constant Size_2D := Adi.Font.Measure_Text
              (Handle    => Label_Style.Font_Family,
               Content   => To_String (W.Text),
               Font_Size => Label_Style.Font_Size.Amount);
            Can_Wrap    : constant Boolean :=
              Label_Style.Text_Wrap_Mode = TWM_Wrap
              and then Label_Style.White_Space /= WS_NoWrap;
         begin
            Text_Item := (
               Part           => Label_Part,
               Min_Width      => (if Can_Wrap then 0.0
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
                              Wrapped : constant Size_2D :=
                                Adi.Font.Measure_Text_Wrapped
                                  (Handle     => Label_Style.Font_Family,
                                   Content    => To_String (W.Text),
                                   Font_Size  =>
                                     Label_Style.Font_Size.Amount,
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
      begin
         Text_It.Text_Content := W.Text;
         Text_It.Wrap_Text :=
           Label_Style.Text_Wrap_Mode = TWM_Wrap
           and then Label_Style.White_Space /= WS_NoWrap;
         for L_Item of W.Layout_Items loop
            if L_Item.Part = Label_Part then
               Text_It.Geometry := L_Item.Geometry;
               exit;
            end if;
         end loop;
      end;

      --  Update icon item
      declare
         Icon_It : Item renames W.Items.Reference (Icon_Idx).Element.all;
      begin
         Icon_It.Image_Source := W.Icon;
         for L_Item of W.Layout_Items loop
            if L_Item.Part = Icon_Part then
               Icon_It.Geometry := L_Item.Geometry;
               exit;
            end if;
         end loop;
      end;
   end Build_Items;

end Adi.Widget.Label;
