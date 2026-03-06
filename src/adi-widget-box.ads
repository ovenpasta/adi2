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

   --  Typed handle
   type Box_Handle is private;
   Null_Box_Handle : constant Box_Handle;

   --  Construction
   function Create return Box_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create (X, Y, W, H : Pixel_Type) return Box_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle return Box_Handle;
   function Create_Handle (X, Y, W, H : Pixel_Type) return Box_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Box_Handle) return Widget_Handle;
   function Try_As_Box (H : Widget_Handle) return Box_Handle;
   function Is_Valid (H : Box_Handle) return Boolean;

   --  Typed handle methods
   procedure Add_Child (H : Box_Handle; C : Widget_Handle);
   function "+" (H : Box_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : Box_Handle; Styles : Part_Style_Array);

   --  Implement abstract methods
   overriding procedure Build_Items (W : in out Box_Widget);
   overriding procedure Layout (W : in out Box_Widget);
   overriding function Measure_Content (W : Box_Widget) return Size_2D;
   overriding function Get_Min_Size (W : Box_Widget) return Size_2D;

private

   --  Fixed item indices for Box_Widget items vector
   Panel_Idx    : constant Positive := 1;
   Bg_Image_Idx : constant Positive := 2;

   type Box_Widget is new Widget with null record;

   type Box_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Box_Handle : constant Box_Handle := (Id => Widget_Stores.Null_Id);

end Adi.Widget.Box;
