with Adi.Core;            use Adi.Core;
with Adi.Animated_Image;  use Adi.Animated_Image;
with Adi.Image;           use Adi.Image;
with Adi.Widget;          use Adi.Widget;

package Adi.Widget.Animated_Widget is

   type Animated_Widget is new Widget with private;
   type Animated_Widget_Access is access all Animated_Widget'Class;

   function Create return Animated_Widget_Access;
   function Create
     (Animation : Animated_Image_Access) return Animated_Widget_Access;

   function Load_Image_From_File
     (W    : in out Animated_Widget;
      Path : String) return Boolean;

   procedure Set_Animation
     (W         : in out Animated_Widget;
      Animation : Animated_Image_Access);
   function Get_Image_Animation
     (W : Animated_Widget) return Animated_Image_Access;

   procedure Start (W : in out Animated_Widget);
   procedure Stop (W : in out Animated_Widget);
   procedure Reset (W : in out Animated_Widget);
   procedure Set_Looping
     (W     : in out Animated_Widget;
      Value : Boolean := True);
   procedure Set_Playback_Speed
     (W          : in out Animated_Widget;
      Multiplier : Float := 1.0);
   function Is_Looping (W : Animated_Widget) return Boolean;
   function Is_Playing (W : Animated_Widget) return Boolean;
   procedure Set_Max_Size
     (W          : in out Animated_Widget;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type);

   overriding procedure Build_Items (W : in out Animated_Widget);
   overriding procedure Layout (W : in out Animated_Widget);
   overriding function Measure_Content (W : Animated_Widget) return Size_2D;
   overriding procedure On_Tick (W : in out Animated_Widget; DT : Duration);

private

   Panel_Idx : constant Positive := 1;
   Image_Idx : constant Positive := 2;

   type Animation_Backend is abstract tagged limited null record;
   type Animation_Backend_Access is access all Animation_Backend'Class;

   procedure Get_Size
     (B      : Animation_Backend;
      Width  : out Pixel_Type;
      Height : out Pixel_Type) is abstract;
   function Get_Current_Image
     (B : Animation_Backend) return Image_Access is abstract;
   function Advance
     (B  : in out Animation_Backend;
      DT : Duration) return Boolean is abstract;
   procedure Start (B : in out Animation_Backend) is abstract;
   procedure Stop (B : in out Animation_Backend) is abstract;
   procedure Reset (B : in out Animation_Backend) is abstract;
   procedure Set_Looping
     (B     : in out Animation_Backend;
      Value : Boolean) is abstract;
   procedure Set_Playback_Speed
     (B          : in out Animation_Backend;
      Multiplier : Float) is abstract;
   function Is_Looping (B : Animation_Backend) return Boolean is abstract;
   function Is_Playing (B : Animation_Backend) return Boolean is abstract;

   procedure Set_Backend
     (W        : in out Animated_Widget'Class;
      Backend  : Animation_Backend_Access;
      As_Image : Animated_Image_Access := null);

   type Animated_Widget is new Widget with record
      Image_Animation : Animated_Image_Access := null;
      Backend         : Animation_Backend_Access := null;
      Max_Width       : Pixel_Type := 0.0;
      Max_Height      : Pixel_Type := 0.0;
   end record;

end Adi.Widget.Animated_Widget;
