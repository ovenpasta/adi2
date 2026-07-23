--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

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
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle (Img : Image_Access := null) return Image_Handle is
   begin
      return (Id => Get_Handle (Create (Img).all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : Image_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Image (H : Widget_Handle) return Image_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Image_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Image_Handle;
   end Try_As_Image;

   function Is_Valid (H : Image_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Image_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles (H : Image_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------------
   -- Handle methods --
   --------------------

   procedure Set_Image (H : Image_Handle; Img : Image_Access) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Image (Image_Widget (Ptr.all), Img);
      end if;
   end Set_Image;

   function Get_Image (H : Image_Handle) return Image_Access is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Image (Image_Widget (Ptr.all));
      end if;
      return null;
   end Get_Image;

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

      Width_Fixed  : constant Boolean := Icon_Style.Width.Kind = Fixed;
      Height_Fixed : constant Boolean := Icon_Style.Height.Kind = Fixed;
   begin
      --  When explicit CSS width/height is set on the icon part, use those
      --  dimensions (with aspect-ratio preservation for one-sided overrides).
      --  Otherwise report (0, 0): images are scalable content whose size is
      --  determined by the layout, not the intrinsic pixel dimensions.
      if Width_Fixed or Height_Fixed then
         --  Get intrinsic image size for aspect ratio calculations
         if W.Img /= null and then Is_Valid (W.Img.all) then
            Get_Size (W.Img.all, Img_Size.Width, Img_Size.Height);
         end if;

         declare
            Intrinsic : constant Size_2D := Img_Size;
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

      return Outer_Size (Img_Size, Main_Style);
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
