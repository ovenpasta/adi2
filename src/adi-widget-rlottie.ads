with Adi.Core;         use Adi.Core;
with Adi.RLottie;      use Adi.RLottie;
with Adi.Widget;       use Adi.Widget;

package Adi.Widget.RLottie is

   type RLottie_Widget is new Widget with private;
   type RLottie_Widget_Access is access all RLottie_Widget'Class;

   --  Typed handle
   type RLottie_Handle is private;
   Null_RLottie_Handle : constant RLottie_Handle;

   --  Construction
   function Create return RLottie_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create
     (Animation : RLottie_Animation_Access) return RLottie_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle return RLottie_Handle;
   function Create_Handle
     (Animation : RLottie_Animation_Access) return RLottie_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : RLottie_Handle) return Widget_Handle;
   function Try_As_RLottie (H : Widget_Handle) return RLottie_Handle;
   function Is_Valid (H : RLottie_Handle) return Boolean;
   function "+" (H : RLottie_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : RLottie_Handle; Styles : Part_Style_Array);

   --  Widget methods
   function Load_From_File
     (W    : in out RLottie_Widget;
      Path : String) return Boolean;

   procedure Set_Animation
     (W         : in out RLottie_Widget;
      Animation : RLottie_Animation_Access);
   function Get_Animation
     (W : RLottie_Widget) return RLottie_Animation_Access;

   procedure Start (W : in out RLottie_Widget);
   procedure Stop (W : in out RLottie_Widget);
   procedure Reset (W : in out RLottie_Widget);
   procedure Set_Looping (W : in out RLottie_Widget; Value : Boolean := True);
   procedure Set_Playback_Speed
     (W          : in out RLottie_Widget;
      Multiplier : Float := 1.0);

   function Is_Playing (W : RLottie_Widget) return Boolean;
   function Is_Looping (W : RLottie_Widget) return Boolean;
   procedure Set_Max_Size
     (W          : in out RLottie_Widget;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type);

   --  Handle methods
   function Load_From_File
     (H : RLottie_Handle; Path : String) return Boolean;
   procedure Set_Animation
     (H : RLottie_Handle; Animation : RLottie_Animation_Access);
   function Get_Animation (H : RLottie_Handle) return RLottie_Animation_Access;
   procedure Start (H : RLottie_Handle);
   procedure Stop (H : RLottie_Handle);
   procedure Reset (H : RLottie_Handle);
   procedure Set_Looping (H : RLottie_Handle; Value : Boolean := True);
   procedure Set_Playback_Speed
     (H : RLottie_Handle; Multiplier : Float := 1.0);
   function Is_Playing (H : RLottie_Handle) return Boolean;
   function Is_Looping (H : RLottie_Handle) return Boolean;
   procedure Set_Max_Size
     (H          : RLottie_Handle;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type);

   overriding procedure Build_Items (W : in out RLottie_Widget);
   overriding procedure Layout (W : in out RLottie_Widget);
   overriding function Measure_Content (W : RLottie_Widget) return Size_2D;
   overriding procedure On_Tick (W : in out RLottie_Widget; DT : Duration);

private

   Panel_Idx : constant Positive := 1;
   Image_Idx : constant Positive := 2;

   type RLottie_Widget is new Widget with record
      Animation              : RLottie_Animation_Access := null;
      Desired_Looping        : Boolean := True;
      Desired_Playback_Speed : Float := 1.0;
      Max_Width              : Pixel_Type := 0.0;
      Max_Height             : Pixel_Type := 0.0;
   end record;

   type RLottie_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_RLottie_Handle : constant RLottie_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.RLottie;
