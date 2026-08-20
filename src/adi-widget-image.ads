--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package Adi.Widget.Image is

   ---------------------------------------------------------------------------
   --  Image Widget - Displays a single image
   --
   --  Parts:
   --    - Main_Part : Container panel (background, border)
   --    - Icon_Part : Image rendering and sizing
   --
   --  Layout:
   --    No children. Image fills the widget geometry, respecting CSS
   --    width/height with aspect-ratio preservation.
   ---------------------------------------------------------------------------

   type Image_Widget is new Widget with private;

   --  Typed handle
   type Image_Handle is private;
   Null_Image_Handle : constant Image_Handle;

   --  Construction
   function Create_Handle (Img : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle) return Image_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Image_Handle) return Widget_Handle;
   function Try_As_Image (H : Widget_Handle) return Image_Handle;
   function Is_Valid (H : Image_Handle) return Boolean;
   function "+" (H : Image_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : Image_Handle; Styles : Part_Style_Array);

   --  Image management
   procedure Set_Image (W : in out Image_Widget; Img : Adi.Image.Image_Handle);
   function Get_Image (W : Image_Widget) return Adi.Image.Image_Handle;

   --  Handle methods
   procedure Set_Image (H : Image_Handle; Img : Adi.Image.Image_Handle);
   function Get_Image (H : Image_Handle) return Adi.Image.Image_Handle;

   --  Override abstract methods
   overriding procedure Build_Items (W : in out Image_Widget);
   overriding procedure Layout (W : in out Image_Widget);

   --  Override size calculation
   overriding function Measure_Content (W : Image_Widget) return Size_2D;

private

   --  Fixed item indices for Image_Widget items vector
   Panel_Idx : constant Positive := 1;
   Img_Idx   : constant Positive := 2;

   type Image_Widget is new Widget with record
      Img : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
   end record;

   type Image_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Image_Handle : constant Image_Handle :=
     (Id => Widget_Stores.Null_Id);

   type Image_Widget_Access is access all Image_Widget'Class;

end Adi.Widget.Image;
