--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Animated_Image;  use Adi.Animated_Image;
with Adi.Clock;

package Adi.Widget.Animated_Widget is

   type Animated_Widget is new Widget with private;
   type Animated_Widget_Access is access all Animated_Widget'Class;

   --  Typed handle
   type Animated_Widget_Handle is private;
   Null_Animated_Widget_Handle : constant Animated_Widget_Handle;

   --  Construction
   function Create return Animated_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create
     (Animation : Animation_Handle) return Animated_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle return Animated_Widget_Handle;
   function Create_Handle
     (Animation : Animation_Handle) return Animated_Widget_Handle;

   --  Handle bridge
   function To_Widget_Handle
     (H : Animated_Widget_Handle) return Widget_Handle;
   function Try_As_Animated_Widget
     (H : Widget_Handle) return Animated_Widget_Handle;
   function Is_Valid (H : Animated_Widget_Handle) return Boolean;
   function "+" (H : Animated_Widget_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Animated_Widget_Handle; Styles : Part_Style_Array);

   procedure Set_Animation
     (W         : in out Animated_Widget;
      Animation : Animation_Handle);
   function Get_Image_Animation
     (W : Animated_Widget) return Animation_Handle;

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

   --  Handle methods
   procedure Set_Animation
     (H : Animated_Widget_Handle; Animation : Animation_Handle);
   function Get_Image_Animation
     (H : Animated_Widget_Handle) return Animation_Handle;
   procedure Start (H : Animated_Widget_Handle);
   procedure Stop (H : Animated_Widget_Handle);
   procedure Reset (H : Animated_Widget_Handle);
   procedure Set_Looping
     (H : Animated_Widget_Handle; Value : Boolean := True);
   procedure Set_Playback_Speed
     (H : Animated_Widget_Handle; Multiplier : Float := 1.0);
   function Is_Looping (H : Animated_Widget_Handle) return Boolean;
   function Is_Playing (H : Animated_Widget_Handle) return Boolean;
   procedure Set_Max_Size
     (H          : Animated_Widget_Handle;
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
     (B : Animation_Backend) return Image_Handle is abstract;

   --  Tell the backend the physical pixel extent it will be drawn at.
   --  Called every time the widget builds its items, so it must be cheap
   --  and idempotent for an unchanged extent. A backend whose frames do
   --  not depend on size ignores it, which is why this is not abstract.
   procedure Prepare
     (B            : in out Animation_Backend;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) is null;
   --  Two descriptions of the same instant. A backend that owns its
   --  playhead outright steps by DT; one whose animation may be shared
   --  between widgets samples Sample instead, so that two viewers ticking
   --  the same frame do not step the timeline twice.
   function Advance
     (B      : in out Animation_Backend;
      DT     : Duration;
      Sample : Adi.Clock.Time) return Boolean is abstract;
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
      As_Image : Animation_Handle := Null_Animation_Handle);

   type Animated_Widget is new Widget with record
      Image_Animation : Animation_Handle := Null_Animation_Handle;
      Backend         : Animation_Backend_Access := null;
      Max_Width       : Pixel_Type := 0.0;
      Max_Height      : Pixel_Type := 0.0;
      --  The image this widget last put in its render item. A shared
      --  animation is stepped by whichever viewer ticks first, so the
      --  return of that step tells a viewer nothing about whether it has
      --  something new to show; comparing against what it drew does.
      Shown_Image     : Image_Handle := Adi.Image.Null_Image_Handle;
   end record;

   type Animated_Widget_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Animated_Widget_Handle : constant Animated_Widget_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.Animated_Widget;
