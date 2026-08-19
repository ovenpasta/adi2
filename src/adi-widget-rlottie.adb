--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Clock;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.RLottie is

   function Create return RLottie_Widget_Access is
      Result : constant RLottie_Widget_Access := new RLottie_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   function Create
     (Animation : Animation_Handle) return RLottie_Widget_Access
   is
      Result : constant RLottie_Widget_Access := Create;
   begin
      Set_Animation (Result.all, Animation);
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle return RLottie_Handle is
   begin
      return (Id => Get_Handle (Create.all).Id);
   end Create_Handle;

   function Create_Handle
     (Animation : Animation_Handle) return RLottie_Handle is
   begin
      return (Id => Get_Handle (Create (Animation).all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : RLottie_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_RLottie (H : Widget_Handle) return RLottie_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in RLottie_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_RLottie_Handle;
   end Try_As_RLottie;

   function Is_Valid (H : RLottie_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : RLottie_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles (H : RLottie_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------------
   -- Handle methods --
   --------------------

   procedure Set_Animation
     (H : RLottie_Handle; Animation : Animation_Handle)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Animation (RLottie_Widget (Ptr.all), Animation);
      end if;
   end Set_Animation;

   function Get_Animation
     (H : RLottie_Handle) return Animation_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Animation (RLottie_Widget (Ptr.all));
      end if;
      return Null_Animation_Handle;
   end Get_Animation;

   procedure Start (H : RLottie_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Start (RLottie_Widget (Ptr.all));
      end if;
   end Start;

   procedure Stop (H : RLottie_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Stop (RLottie_Widget (Ptr.all));
      end if;
   end Stop;

   procedure Reset (H : RLottie_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Reset (RLottie_Widget (Ptr.all));
      end if;
   end Reset;

   procedure Set_Looping (H : RLottie_Handle; Value : Boolean := True) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Looping (RLottie_Widget (Ptr.all), Value);
      end if;
   end Set_Looping;

   procedure Set_Playback_Speed
     (H : RLottie_Handle; Multiplier : Float := 1.0)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Playback_Speed (RLottie_Widget (Ptr.all), Multiplier);
      end if;
   end Set_Playback_Speed;

   function Is_Playing (H : RLottie_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Playing (RLottie_Widget (Ptr.all));
      end if;
      return False;
   end Is_Playing;

   function Is_Looping (H : RLottie_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Looping (RLottie_Widget (Ptr.all));
      end if;
      return False;
   end Is_Looping;

   procedure Set_Max_Size
     (H          : RLottie_Handle;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Max_Size (RLottie_Widget (Ptr.all), Max_Width, Max_Height);
      end if;
   end Set_Max_Size;

   procedure Set_Animation
     (W         : in out RLottie_Widget;
      Animation : Animation_Handle)
   is
   begin
      W.Animation := Animation;
      if Is_Valid (W.Animation) then
         Set_Looping (W.Animation, W.Desired_Looping);
         Set_Playback_Speed (W.Animation, W.Desired_Playback_Speed);
      end if;
      Mark_Dirty (W);
   end Set_Animation;

   function Get_Animation
     (W : RLottie_Widget) return Animation_Handle
   is
   begin
      return W.Animation;
   end Get_Animation;

   procedure Start (W : in out RLottie_Widget) is
   begin
      if Is_Valid (W.Animation) then
         Start (W.Animation);
         Mark_Dirty (W);
      end if;
   end Start;

   procedure Stop (W : in out RLottie_Widget) is
   begin
      if Is_Valid (W.Animation) then
         Stop (W.Animation);
         Mark_Dirty (W);
      end if;
   end Stop;

   procedure Reset (W : in out RLottie_Widget) is
   begin
      if Is_Valid (W.Animation) then
         Reset (W.Animation);
         Mark_Dirty (W);
      end if;
   end Reset;

   procedure Set_Looping (W : in out RLottie_Widget; Value : Boolean := True) is
   begin
      W.Desired_Looping := Value;
      if Is_Valid (W.Animation) then
         Set_Looping (W.Animation, Value);
      end if;
   end Set_Looping;

   procedure Set_Playback_Speed
     (W          : in out RLottie_Widget;
      Multiplier : Float := 1.0)
   is
   begin
      W.Desired_Playback_Speed := Float'Max (0.01, Multiplier);
      if Is_Valid (W.Animation) then
         Set_Playback_Speed (W.Animation, W.Desired_Playback_Speed);
      end if;
   end Set_Playback_Speed;

   function Is_Playing (W : RLottie_Widget) return Boolean is
   begin
      if not Is_Valid (W.Animation) then
         return False;
      end if;
      return Is_Playing (W.Animation);
   end Is_Playing;

   function Is_Looping (W : RLottie_Widget) return Boolean is
   begin
      if not Is_Valid (W.Animation) then
         return W.Desired_Looping;
      end if;
      return Is_Looping (W.Animation);
   end Is_Looping;

   procedure Set_Max_Size
     (W          : in out RLottie_Widget;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type)
   is
   begin
      W.Max_Width := Pixel_Type'Max (0.0, Max_Width);
      W.Max_Height := Pixel_Type'Max (0.0, Max_Height);
      Mark_Dirty (W);
   end Set_Max_Size;

   overriding function Measure_Content (W : RLottie_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Result     : Size_2D := (0.0, 0.0);
      Scale      : Pixel_Type := 1.0;
   begin
      if Is_Valid (W.Animation) then
         Get_Size (W.Animation, Result.Width, Result.Height);
      end if;

      if Result.Width > 0.0 and then Result.Height > 0.0 then
         if W.Max_Width > 0.0 and then Result.Width > W.Max_Width then
            Scale := Pixel_Type'Min (Scale, W.Max_Width / Result.Width);
         end if;
         if W.Max_Height > 0.0 and then Result.Height > W.Max_Height then
            Scale := Pixel_Type'Min (Scale, W.Max_Height / Result.Height);
         end if;
         Result.Width := Result.Width * Scale;
         Result.Height := Result.Height * Scale;
      end if;

      return Outer_Size (Result, Main_Style);
   end Measure_Content;

   overriding procedure Build_Items (W : in out RLottie_Widget) is
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

      --  The first point at which the animation's real extent is known.
      --  Rasterising at the file's own viewport instead would size the
      --  frame set by how the artwork was authored rather than by how it
      --  is shown, which for an icon-sized emoji is the whole difference
      --  between kilobytes and hundreds of megabytes.
      if Is_Valid (W.Animation)
        and then Content.Width > 0.0
        and then Content.Height > 0.0
      then
         declare
            PW : constant Positive :=
              Positive (Pixel_Type'Max (1.0, Pixel_Type'Ceiling
                          (Content.Width)));
            PH : constant Positive :=
              Positive (Pixel_Type'Max (1.0, Pixel_Type'Ceiling
                          (Content.Height)));
         begin
            --  Idempotent, so this costs a comparison on every frame but
            --  the ones where the extent actually changed.
            Prepare (W.Animation, PW, PH);
         end;
      end if;

      if Is_Valid (W.Animation) then
         Current := Get_Current_Image (W.Animation);
      end if;

      W.Items.Reference (Image_Idx).Image_Source := Current;

      --  Recorded here and nowhere else: what the widget has shown is
      --  what reached the render item, not what a tick happened to see.
      W.Shown_Image := Current;
   end Build_Items;

   overriding procedure Layout (W : in out RLottie_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Layout;

   overriding procedure On_Tick (W : in out RLottie_Widget; DT : Duration) is
      Changed : Boolean;
   begin
      Tick_Scroll_Animations (W, DT);

      if Is_Valid (W.Animation) then
         --  Sampled rather than stepped: several widgets may show one
         --  animation, and each stepping it would run the playhead at a
         --  multiple of its speed.
         Changed := Advance_At (W.Animation, Adi.Clock.Now);

         --  Two questions, and neither answers the other. The step
         --  reports that the animation changed, which it can do without
         --  handing out a different image; and at most one viewer of a
         --  shared animation is the one that made the step, while every
         --  viewer of it has the new frame to draw.
         if Changed
           or else Get_Current_Image (W.Animation) /= W.Shown_Image
         then
            Mark_Dirty (W);
         end if;
      end if;
   end On_Tick;

end Adi.Widget.RLottie;
