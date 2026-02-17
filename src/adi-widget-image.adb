with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Image is

   ------------
   -- Create --
   ------------

   function Create (Img : Image_Access := null) return Image_Widget_Access is
      Result : constant Image_Widget_Access := new Image_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      Result.Img := Img;
      return Result;
   end Create;

   ---------------
   -- Set_Image --
   ---------------

   procedure Set_Image (W : in out Image_Widget; Img : Image_Access) is
   begin
      W.Img := Img;
      Mark_Dirty (W);
   end Set_Image;

   ---------------
   -- Get_Image --
   ---------------

   function Get_Image (W : Image_Widget) return Image_Access is
   begin
      return W.Img;
   end Get_Image;

   ---------------------
   -- Measure_Content --
   ---------------------

   function Measure_Content (W : Image_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Icon_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Icon_Part);

      Img_Size : Size_2D := (0.0, 0.0);
      Result   : Size_2D;

      Pad    : constant Edge_Pixels := Get_Padding_Px (Main_Style);
      Border : constant Edge_Pixels := Get_Border_Width_Px (Main_Style);
   begin
      --  Get intrinsic image size
      if W.Img /= null and then Is_Valid (W.Img.all) then
         Get_Size (W.Img.all, Img_Size.Width, Img_Size.Height);
      end if;

      --  Apply CSS width/height overrides with aspect ratio preservation
      if W.Img /= null then
         declare
            Intrinsic    : constant Size_2D := Img_Size;
            Width_Fixed  : constant Boolean := Icon_Style.Width.Kind = Fixed;
            Height_Fixed : constant Boolean := Icon_Style.Height.Kind = Fixed;
         begin
            if Width_Fixed then
               Img_Size.Width := Size_To_Px (Icon_Style.Width, W.Geometry.Width);
            end if;
            if Height_Fixed then
               Img_Size.Height := Size_To_Px (Icon_Style.Height, W.Geometry.Height);
            end if;

            --  Preserve aspect ratio when only one dimension is fixed
            if Width_Fixed and then not Height_Fixed
              and then Intrinsic.Width > 0.0
            then
               Img_Size.Height :=
                 Img_Size.Width * Intrinsic.Height / Intrinsic.Width;
            elsif Height_Fixed and then not Width_Fixed
              and then Intrinsic.Height > 0.0
            then
               Img_Size.Width :=
                 Img_Size.Height * Intrinsic.Width / Intrinsic.Height;
            end if;

            Img_Size.Width := Pixel_Type'Max (0.0, Img_Size.Width);
            Img_Size.Height := Pixel_Type'Max (0.0, Img_Size.Height);
         end;
      end if;

      Result := Img_Size;

      --  Add padding and border
      Result.Width := Result.Width + Pad.Left + Pad.Right
                      + Border.Left + Border.Right;
      Result.Height := Result.Height + Pad.Top + Pad.Bottom
                       + Border.Top + Border.Bottom;

      return Result;
   end Measure_Content;

   ------------
   -- Layout --
   ------------

   overriding procedure Layout (W : in out Image_Widget) is
      pragma Unreferenced (W);
   begin
      --  No children to lay out; image geometry is set directly in Build_Items
      null;
   end Layout;

   -----------------
   -- Build_Items --
   -----------------

   overriding procedure Build_Items (W : in out Image_Widget) is
      Main_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Content    : constant Rectangle := Content_Box (W.Geometry, Main_Style);
   begin
      if Item_Count (W) = 0 then
         --  First build: create items at fixed indices
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));          --  Panel_Idx
         Add_Item (W, Make_Image (Icon_Part, Content, W.Img, 1));      --  Img_Idx
      end if;

      --  Update panel geometry
      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

      --  Update image item
      declare
         Img_It : Item renames W.Items.Reference (Img_Idx).Element.all;
      begin
         Img_It.Image_Source := W.Img;
         Img_It.Geometry := Content;
      end;
   end Build_Items;

end Adi.Widget.Image;
