with Adi.Core;            use Adi.Core;
with Adi.SDL.Render;      use Adi.SDL.Render;
with Adi.Animated_Image;  use Adi.Animated_Image;
with Adi.Widget;          use Adi.Widget;

package Adi.Widget.Animated_Image is

   type Animated_Image_Widget is new Widget with private;
   type Animated_Image_Widget_Access is access all Animated_Image_Widget'Class;

   function Create return Animated_Image_Widget_Access;
   function Create
     (Animation : Animated_Image_Access) return Animated_Image_Widget_Access;

   --  Convenience loader for this widget.
   --  Returns True on success.
   function Load_From_File
     (W        : in out Animated_Image_Widget;
      Renderer : SDL_Renderer_Ptr;
      Path     : String) return Boolean;

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

end Adi.Widget.Animated_Image;
