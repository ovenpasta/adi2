--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Clock;
with Adi.Animated_Image;  use Adi.Animated_Image;

package Adi.Widget.Animated_Image is

   type Animated_Image_Widget is new Widget with private;
   type Animated_Image_Widget_Access is access all Animated_Image_Widget'Class;

   --  Typed handle
   type Animated_Image_Handle is private;
   Null_Animated_Image_Handle : constant Animated_Image_Handle;

   --  Construction
   function Create return Animated_Image_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create
     (Animation : Animation_Handle) return Animated_Image_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle return Animated_Image_Handle;
   function Create_Handle
     (Animation : Animation_Handle) return Animated_Image_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Animated_Image_Handle) return Widget_Handle;
   function Try_As_Animated_Image
     (H : Widget_Handle) return Animated_Image_Handle;
   function Is_Valid (H : Animated_Image_Handle) return Boolean;
   function "+" (H : Animated_Image_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Animated_Image_Handle; Styles : Part_Style_Array);

   procedure Set_Animation
     (W         : in out Animated_Image_Widget;
      Animation : Animation_Handle);
   function Get_Animation
     (W : Animated_Image_Widget) return Animation_Handle;

   procedure Start (W : in out Animated_Image_Widget);
   procedure Stop (W : in out Animated_Image_Widget);
   procedure Reset (W : in out Animated_Image_Widget);

   procedure Set_Looping
     (W     : in out Animated_Image_Widget;
      Value : Boolean := True);
   function Is_Looping (W : Animated_Image_Widget) return Boolean;
   function Is_Playing (W : Animated_Image_Widget) return Boolean;

   --  Handle methods
   procedure Set_Animation
     (H : Animated_Image_Handle; Animation : Animation_Handle);
   function Get_Animation
     (H : Animated_Image_Handle) return Animation_Handle;
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
      Animation : Animation_Handle := Null_Animation_Handle;
      --  The image this widget last put in its render item. A shared
      --  animation is stepped by whichever viewer ticks first, so the
      --  return of that step tells a viewer nothing about whether it has
      --  something new to show; comparing against what it drew does.
      Shown_Image : Image_Handle := Adi.Image.Null_Image_Handle;
   end record;

   type Animated_Image_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Animated_Image_Handle : constant Animated_Image_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.Animated_Image;
