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
   type Image_Widget_Access is access all Image_Widget'Class;

   --  Construction
   function Create (Img : Image_Access := null) return Image_Widget_Access;

   --  Image management
   procedure Set_Image (W : in out Image_Widget; Img : Image_Access);
   function Get_Image (W : Image_Widget) return Image_Access;

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
      Img : Image_Access := null;
   end record;

end Adi.Widget.Image;
