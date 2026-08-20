--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Clock;

with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Animated_Image is

   function Create return Animated_Image_Widget_Access is
      Result : constant Animated_Image_Widget_Access := new Animated_Image_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   function Create
     (Animation : Animation_Handle) return Animated_Image_Widget_Access
   is
      Result : constant Animated_Image_Widget_Access := Create;
   begin
      Result.Animation := Animation;
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle return Animated_Image_Handle is
   begin
      return (Id => Get_Handle (Create.all).Id);
   end Create_Handle;

   function Create_Handle
     (Animation : Animation_Handle) return Animated_Image_Handle is
   begin
      return (Id => Get_Handle (Create (Animation).all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : Animated_Image_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Animated_Image
     (H : Widget_Handle) return Animated_Image_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Animated_Image_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Animated_Image_Handle;
   end Try_As_Animated_Image;

   function Is_Valid (H : Animated_Image_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Animated_Image_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles
     (H : Animated_Image_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------------
   -- Handle methods --
   --------------------

   procedure Set_Animation
     (H : Animated_Image_Handle; Animation : Animation_Handle)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Animation (Animated_Image_Widget (Ptr.all), Animation);
      end if;
   end Set_Animation;

   function Get_Animation
     (H : Animated_Image_Handle) return Animation_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Animation (Animated_Image_Widget (Ptr.all));
      end if;
      return Null_Animation_Handle;
   end Get_Animation;

   procedure Start (H : Animated_Image_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Start (Animated_Image_Widget (Ptr.all));
      end if;
   end Start;

   procedure Stop (H : Animated_Image_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Stop (Animated_Image_Widget (Ptr.all));
      end if;
   end Stop;

   procedure Reset (H : Animated_Image_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Reset (Animated_Image_Widget (Ptr.all));
      end if;
   end Reset;

   procedure Set_Looping
     (H : Animated_Image_Handle; Value : Boolean := True)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Looping (Animated_Image_Widget (Ptr.all), Value);
      end if;
   end Set_Looping;

   function Is_Looping (H : Animated_Image_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Looping (Animated_Image_Widget (Ptr.all));
      end if;
      return False;
   end Is_Looping;

   function Is_Playing (H : Animated_Image_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Playing (Animated_Image_Widget (Ptr.all));
      end if;
      return False;
   end Is_Playing;

   procedure Set_Animation
     (W         : in out Animated_Image_Widget;
      Animation : Animation_Handle)
   is
   begin
      W.Animation := Animation;
      Mark_Dirty (W);
   end Set_Animation;

   function Get_Animation
     (W : Animated_Image_Widget) return Animation_Handle
   is
   begin
      return W.Animation;
   end Get_Animation;

   procedure Start (W : in out Animated_Image_Widget) is
   begin
      if not Is_Valid (W.Animation) then
         return;
      end if;

      Start (W.Animation);
      Mark_Dirty (W);
   end Start;

   procedure Stop (W : in out Animated_Image_Widget) is
   begin
      if not Is_Valid (W.Animation) then
         return;
      end if;

      Stop (W.Animation);
      Mark_Dirty (W);
   end Stop;

   procedure Reset (W : in out Animated_Image_Widget) is
   begin
      if not Is_Valid (W.Animation) then
         return;
      end if;

      Reset (W.Animation);
      Mark_Dirty (W);
   end Reset;

   procedure Set_Looping
     (W     : in out Animated_Image_Widget;
      Value : Boolean := True)
   is
   begin
      if not Is_Valid (W.Animation) then
         return;
      end if;

      Set_Looping (W.Animation, Value);
   end Set_Looping;

   function Is_Looping (W : Animated_Image_Widget) return Boolean is
   begin
      if not Is_Valid (W.Animation) then
         return False;
      end if;

      return Is_Looping (W.Animation);
   end Is_Looping;

   function Is_Playing (W : Animated_Image_Widget) return Boolean is
   begin
      if not Is_Valid (W.Animation) then
         return False;
      end if;

      return Is_Playing (W.Animation);
   end Is_Playing;

   overriding function Measure_Content (W : Animated_Image_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Result     : Size_2D := (0.0, 0.0);
   begin
      if Is_Valid (W.Animation) then
         Get_Size (W.Animation, Result.Width, Result.Height);
      end if;

      return Outer_Size (Result, Main_Style);
   end Measure_Content;

   overriding procedure Build_Items (W : in out Animated_Image_Widget) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Content    : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Current    : Image_Handle := Adi.Image.Null_Image_Handle;
   begin
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Add_Item (W, Make_Image (Icon_Part, Content, Adi.Image.Null_Image_Handle, 1));
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;
      W.Items.Reference (Image_Idx).Geometry := Content;

      if Is_Valid (W.Animation) then
         Current := Get_Current_Image (W.Animation);
      end if;

      W.Items.Reference (Image_Idx).Image_Source := Current;

      --  Recorded here and nowhere else: what the widget has shown is
      --  what reached the render item, not what a tick happened to see.
      W.Shown_Image := Current;
   end Build_Items;

   overriding procedure Layout (W : in out Animated_Image_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Layout;

   overriding procedure On_Tick (W : in out Animated_Image_Widget; DT : Duration) is
      Changed : Boolean;
   begin
      Tick_Scroll_Animations (W, DT);

      if Is_Valid (W.Animation) then
         --  Sampled rather than stepped: several widgets may show one
         --  animation, and each stepping it would run the playhead at a
         --  multiple of its speed.
         Changed := Advance_At (W.Animation, Adi.Clock.Now);

         --  Two questions, and neither answers the other. The step
         --  reports that the animation changed; and at most one viewer
         --  of a shared animation is the one that made it, while every
         --  viewer of it has the new frame to draw.
         if Changed
           or else Get_Current_Image (W.Animation) /= W.Shown_Image
         then
            Mark_Dirty (W);
         end if;
      end if;
   end On_Tick;

end Adi.Widget.Animated_Image;
