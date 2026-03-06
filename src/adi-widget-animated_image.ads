with Adi.Core;            use Adi.Core;
with Adi.Animated_Image;  use Adi.Animated_Image;
with Adi.Widget;          use Adi.Widget;

package Adi.Widget.Animated_Image is

   type Animated_Image_Widget is new Widget with private;
   type Animated_Image_Widget_Access is access all Animated_Image_Widget'Class;

   --  Typed handle
   type Animated_Image_Handle is private;
   Null_Animated_Image_Handle : constant Animated_Image_Handle;

   --  Construction
   function Create return Animated_Image_Widget_Access;
   function Create
     (Animation : Animated_Image_Access) return Animated_Image_Widget_Access;
   function Create_Handle return Animated_Image_Handle;
   function Create_Handle
     (Animation : Animated_Image_Access) return Animated_Image_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Animated_Image_Handle) return Widget_Handle;
   function Try_As_Animated_Image
     (H : Widget_Handle) return Animated_Image_Handle;
   function Is_Valid (H : Animated_Image_Handle) return Boolean;
   function "+" (H : Animated_Image_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Animated_Image_Handle; Styles : Part_Style_Array);

   --  Convenience loader for this widget.
   --  Returns True on success.
   function Load_From_File
     (W    : in out Animated_Image_Widget;
      Path : String) return Boolean;

   procedure Set_Animation
     (W         : in out Animated_Image_Widget;
      Animation : Animated_Image_Access);
   function Get_Animation
     (W : Animated_Image_Widget) return Animated_Image_Access;

   procedure Start (W : in out Animated_Image_Widget);
   procedure Stop (W : in out Animated_Image_Widget);
   procedure Reset (W : in out Animated_Image_Widget);

   procedure Set_Looping
     (W     : in out Animated_Image_Widget;
      Value : Boolean := True);
   function Is_Looping (W : Animated_Image_Widget) return Boolean;
   function Is_Playing (W : Animated_Image_Widget) return Boolean;

   --  Handle methods
   function Load_From_File
     (H : Animated_Image_Handle; Path : String) return Boolean;
   procedure Set_Animation
     (H : Animated_Image_Handle; Animation : Animated_Image_Access);
   function Get_Animation
     (H : Animated_Image_Handle) return Animated_Image_Access;
   procedure Start (H : Animated_Image_Handle);
   procedure Stop (H : Animated_Image_Handle);
   procedure Reset (H : Animated_Image_Handle);
   procedure Set_Looping
     (H : Animated_Image_Handle; Value : Boolean := True);
   function Is_Looping (H : Animated_Image_Handle) return Boolean;
   function Is_Playing (H : Animated_Image_Handle) return Boolean;

   overriding procedure Build_Items (W : in out Animated_Image_Widget);
   overriding procedure Layout (W : in out Animated_Image_Widget);
   overriding function Measure_Content (W : Animated_Image_Widget) return Size_2D;
   overriding procedure On_Tick (W : in out Animated_Image_Widget; DT : Duration);

private

   Panel_Idx : constant Positive := 1;
   Image_Idx : constant Positive := 2;

   type Animated_Image_Widget is new Widget with record
      Animation : Animated_Image_Access := null;
   end record;

   type Animated_Image_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Animated_Image_Handle : constant Animated_Image_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.Animated_Image;
