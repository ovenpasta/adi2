package Adi.Widget.Box is

   ---------------------------------------------------------------------------
   --  Box Widget - Simple container with background and optional border
   --
   --  Items:
   --    - Panel_Item (Main_Part) - Background and border
   --    - Image_Item (Icon_Part) - Optional background image
   ---------------------------------------------------------------------------

   type Box_Widget is new Widget with private;
   type Box_Widget_Access is access all Box_Widget'Class;

   --  Construction
   function Create return Box_Widget_Access;
   function Create (X, Y, W, H : Pixel_Type) return Box_Widget_Access;

   --  Implement abstract methods
   overriding procedure Build_Items (W : in out Box_Widget);
   overriding procedure Layout (W : in out Box_Widget);

private

   --  Fixed item index for Box_Widget items vector
   Panel_Idx : constant Positive := 1;

   type Box_Widget is new Widget with null record;

end Adi.Widget.Box;