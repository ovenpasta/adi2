--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Animated_Widget.RLottie is

   type RLottie_Backend is new Animation_Backend with record
      Animation : Adi.RLottie.Animation_Handle := Adi.RLottie.Null_Animation_Handle;
   end record;

   overriding procedure Get_Size
     (B      : RLottie_Backend;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);
   overriding function Get_Current_Image
     (B : RLottie_Backend) return Image_Handle;
   overriding procedure Prepare
     (B            : in out RLottie_Backend;
      Pixel_Width  : Positive;
      Pixel_Height : Positive);
   overriding function Advance
     (B      : in out RLottie_Backend;
      DT     : Duration;
      Sample : Adi.Clock.Time) return Boolean;
   overriding procedure Start (B : in out RLottie_Backend);
   overriding procedure Stop (B : in out RLottie_Backend);
   overriding procedure Reset (B : in out RLottie_Backend);
   overriding procedure Set_Looping
     (B     : in out RLottie_Backend;
      Value : Boolean);
   overriding procedure Set_Playback_Speed
     (B          : in out RLottie_Backend;
      Multiplier : Float);
   overriding function Is_Looping (B : RLottie_Backend) return Boolean;
   overriding function Is_Playing (B : RLottie_Backend) return Boolean;

   function Create
     (Animation : Adi.RLottie.Animation_Handle) return Animated_Widget_Access
   is
      Result : constant Animated_Widget_Access := new Animated_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (Result));
      Set_Animation (Result.all, Animation);
      return Result;
   end Create;

   procedure Set_Animation
     (W         : in out Animated_Widget'Class;
      Animation : Adi.RLottie.Animation_Handle)
   is
      B : Animation_Backend_Access := null;
   begin
      if Is_Valid (Animation) then
         B := new RLottie_Backend'(Animation => Animation);
      end if;
      --  No image animation: this widget is backed by a Lottie.
      Set_Backend (W, B, Adi.Animated_Image.Null_Animation_Handle);
   end Set_Animation;

   procedure Set_Animation
     (H         : Animated_Widget_Handle;
      Animation : Adi.RLottie.Animation_Handle)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Animated_Widget'Class then
         Set_Animation (Animated_Widget'Class (Ptr.all), Animation);
      end if;
   end Set_Animation;

   function Get_Animation
     (W : Animated_Widget) return Adi.RLottie.Animation_Handle
   is
   begin
      if W.Backend = null then
         return Adi.RLottie.Null_Animation_Handle;
      end if;

      if W.Backend.all in RLottie_Backend'Class then
         return RLottie_Backend (W.Backend.all).Animation;
      end if;

      return Adi.RLottie.Null_Animation_Handle;
   end Get_Animation;

   function Get_Animation
     (H : Animated_Widget_Handle) return Adi.RLottie.Animation_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Animated_Widget'Class then
         return Get_Animation (Animated_Widget (Ptr.all));
      end if;
      return Adi.RLottie.Null_Animation_Handle;
   end Get_Animation;

   overriding procedure Get_Size
     (B      : RLottie_Backend;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
   begin
      if not Is_Valid (B.Animation) then
         Width := 0.0;
         Height := 0.0;
         return;
      end if;
      Adi.RLottie.Get_Size (B.Animation, Width, Height);
   end Get_Size;

   overriding procedure Prepare
     (B            : in out RLottie_Backend;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) is
   begin
      if Is_Valid (B.Animation) then
         Adi.RLottie.Prepare (B.Animation, Pixel_Width, Pixel_Height);
      end if;
   end Prepare;

   overriding function Get_Current_Image
     (B : RLottie_Backend) return Image_Handle
   is
   begin
      if not Is_Valid (B.Animation) then
         return Adi.Image.Null_Image_Handle;
      end if;
      return Adi.RLottie.Get_Current_Image (B.Animation);
   end Get_Current_Image;

   overriding function Advance
     (B      : in out RLottie_Backend;
      DT     : Duration;
      Sample : Adi.Clock.Time) return Boolean
   is
      pragma Unreferenced (DT);
   begin
      if not Is_Valid (B.Animation) then
         return False;
      end if;

      --  One animation can back several widgets. Stepping by DT would run
      --  its playhead at a multiple of its speed, one step per viewer.
      return Adi.RLottie.Advance_At (B.Animation, Sample);
   end Advance;

   overriding procedure Start (B : in out RLottie_Backend) is
   begin
      if Is_Valid (B.Animation) then
         Adi.RLottie.Start (B.Animation);
      end if;
   end Start;

   overriding procedure Stop (B : in out RLottie_Backend) is
   begin
      if Is_Valid (B.Animation) then
         Adi.RLottie.Stop (B.Animation);
      end if;
   end Stop;

   overriding procedure Reset (B : in out RLottie_Backend) is
   begin
      if Is_Valid (B.Animation) then
         Adi.RLottie.Reset (B.Animation);
      end if;
   end Reset;

   overriding procedure Set_Looping
     (B     : in out RLottie_Backend;
      Value : Boolean)
   is
   begin
      if Is_Valid (B.Animation) then
         Adi.RLottie.Set_Looping (B.Animation, Value);
      end if;
   end Set_Looping;

   overriding procedure Set_Playback_Speed
     (B          : in out RLottie_Backend;
      Multiplier : Float)
   is
   begin
      if Is_Valid (B.Animation) then
         Adi.RLottie.Set_Playback_Speed (B.Animation, Multiplier);
      end if;
   end Set_Playback_Speed;

   overriding function Is_Looping (B : RLottie_Backend) return Boolean is
   begin
      if not Is_Valid (B.Animation) then
         return False;
      end if;
      return Adi.RLottie.Is_Looping (B.Animation);
   end Is_Looping;

   overriding function Is_Playing (B : RLottie_Backend) return Boolean is
   begin
      if not Is_Valid (B.Animation) then
         return False;
      end if;
      return Adi.RLottie.Is_Playing (B.Animation);
   end Is_Playing;

end Adi.Widget.Animated_Widget.RLottie;
