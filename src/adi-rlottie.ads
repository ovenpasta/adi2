with Adi.Core;         use Adi.Core;
with Adi.Image;        use Adi.Image;
with Adi.SDL.Render;   use Adi.SDL.Render;
with Adi.SDL.Surface;  use Adi.SDL.Surface;
with Interfaces;
with System;

package Adi.RLottie is

   type RLottie_Backend_Kind is (Primitive_Backend, Texture_Backend);

   type RLottie_Animation is tagged private;
   type RLottie_Animation_Access is access all RLottie_Animation'Class;

   function Load_From_File
     (Renderer : SDL_Renderer_Ptr;
      Path     : String;
      Backend  : RLottie_Backend_Kind := Primitive_Backend)
      return RLottie_Animation_Access;

   function Is_Valid (Anim : RLottie_Animation) return Boolean;

   procedure Get_Size
     (Anim   : RLottie_Animation;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);

   function Get_Frame_Count (Anim : RLottie_Animation) return Natural;
   function Get_Frame_Rate (Anim : RLottie_Animation) return Float;
   function Get_Duration (Anim : RLottie_Animation) return Duration;
   function Get_Preloaded_Frame_Count (Anim : RLottie_Animation) return Natural;
   function Is_Preload_Complete (Anim : RLottie_Animation) return Boolean;
   procedure Set_Preload_Threshold
     (Anim              : in out RLottie_Animation;
      Min_Ready_Frames  : Natural);

   function Get_Current_Frame_Index (Anim : RLottie_Animation) return Natural;
   function Get_Current_Image (Anim : RLottie_Animation) return Image_Access;

   procedure Start (Anim : in out RLottie_Animation);
   procedure Stop (Anim : in out RLottie_Animation);
   function Is_Playing (Anim : RLottie_Animation) return Boolean;
   procedure Set_Looping (Anim : in out RLottie_Animation; Value : Boolean := True);
   function Is_Looping (Anim : RLottie_Animation) return Boolean;
   procedure Set_Playback_Speed
     (Anim       : in out RLottie_Animation;
      Multiplier : Float := 1.0);
   function Get_Playback_Speed (Anim : RLottie_Animation) return Float;
   procedure Reset (Anim : in out RLottie_Animation);

   procedure Set_Backend
     (Anim    : in out RLottie_Animation;
      Backend : RLottie_Backend_Kind);
   function Get_Requested_Backend
     (Anim : RLottie_Animation) return RLottie_Backend_Kind;
   function Get_Active_Backend
     (Anim : RLottie_Animation) return RLottie_Backend_Kind;

   --  Advance timeline and consume preloaded surfaces.
   --  Returns True when a new frame becomes visible.
   function Advance
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Boolean;

   procedure Destroy (Anim : in out RLottie_Animation);

private

   type Surface_Array is array (Positive range <>) of SDL_Surface_Ptr;
   type Surface_Array_Access is access Surface_Array;

   protected type Preload_State is
      procedure Set_Ready_Count (Value : Natural);
      function Ready_Count return Natural;
      procedure Mark_Done;
      function Done return Boolean;
      procedure Signal_Stop;
      function Stop_Requested return Boolean;
   private
      Ready      : Natural := 0;
      Completed  : Boolean := False;
      Stop_Flag  : Boolean := False;
   end Preload_State;
   type Preload_State_Access is access all Preload_State;

   type Address_Access is access all System.Address;

   task type Preload_Task
     (Animation   : not null Address_Access;
      Surfaces    : not null Surface_Array_Access;
      Width       : Positive;
      Height      : Positive;
      Frame_Count : Positive;
      State       : not null Preload_State_Access);
   type Preload_Task_Access is access Preload_Task;

   type RLottie_Animation is tagged record
      Handle            : aliased System.Address := System.Null_Address;
      Width             : Pixel_Type := 0.0;
      Height            : Pixel_Type := 0.0;
      Buffer_Width      : Natural := 0;
      Buffer_Height     : Natural := 0;
      Frame_Count       : Natural := 0;
      Frame_Rate        : Float := 0.0;
      Duration_S        : Float := 0.0;
      Current_Frame     : Natural := 0;
      Elapsed_S         : Float := 0.0;
      Playing           : Boolean := True;
      Looping           : Boolean := True;
      Playback_Speed    : Float := 1.0;
      Min_Ready_Frames  : Natural := 8;
      Requested_Backend : RLottie_Backend_Kind := Primitive_Backend;
      Active_Backend    : RLottie_Backend_Kind := Texture_Backend;
      Frame_Image       : Image_Access := null;
      Frame_Surfaces    : Surface_Array_Access := null;
      State             : Preload_State_Access := null;
      Worker            : Preload_Task_Access := null;
   end record;

end Adi.RLottie;
