--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Deallocation;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Animated_Widget is

   type Image_Backend is new Animation_Backend with record
      Animation : Animated_Image_Access := null;
   end record;

   overriding procedure Get_Size
     (B      : Image_Backend;
      Width  : out Pixel_Type;
      Height : out Pixel_Type);
   overriding function Get_Current_Image
     (B : Image_Backend) return Image_Access;
   overriding function Advance
     (B  : in out Image_Backend;
      DT : Duration) return Boolean;
   overriding procedure Start (B : in out Image_Backend);
   overriding procedure Stop (B : in out Image_Backend);
   overriding procedure Reset (B : in out Image_Backend);
   overriding procedure Set_Looping
     (B     : in out Image_Backend;
      Value : Boolean);
   overriding procedure Set_Playback_Speed
     (B          : in out Image_Backend;
      Multiplier : Float);
   overriding function Is_Looping (B : Image_Backend) return Boolean;
   overriding function Is_Playing (B : Image_Backend) return Boolean;

   procedure Free_Backend is new Ada.Unchecked_Deallocation
     (Object => Animation_Backend'Class,
      Name   => Animation_Backend_Access);

   function Has_Backend (W : Animated_Widget) return Boolean is
   begin
      return W.Backend /= null;
   end Has_Backend;

   procedure Clear_Backend (W : in out Animated_Widget'Class) is
   begin
      if W.Backend /= null then
         declare
            Old : Animation_Backend_Access := W.Backend;
         begin
            W.Backend := null;
            Free_Backend (Old);
         end;
      end if;
      W.Image_Animation := null;
   end Clear_Backend;

   function Create return Animated_Widget_Access is
      Result : constant Animated_Widget_Access := new Animated_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   function Create
     (Animation : Animated_Image_Access) return Animated_Widget_Access
   is
      Result : constant Animated_Widget_Access := Create;
   begin
      Set_Animation (Result.all, Animation);
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle return Animated_Widget_Handle is
   begin
      return (Id => Get_Handle (Create.all).Id);
   end Create_Handle;

   function Create_Handle
     (Animation : Animated_Image_Access) return Animated_Widget_Handle is
   begin
      return (Id => Get_Handle (Create (Animation).all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle
     (H : Animated_Widget_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Animated_Widget
     (H : Widget_Handle) return Animated_Widget_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Animated_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Animated_Widget_Handle;
   end Try_As_Animated_Widget;

   function Is_Valid (H : Animated_Widget_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Animated_Widget_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles
     (H : Animated_Widget_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------------
   -- Handle methods --
   --------------------

   function Load_Image_From_File
     (H : Animated_Widget_Handle; Path : String) return Boolean
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Load_Image_From_File (Animated_Widget (Ptr.all), Path);
      end if;
      return False;
   end Load_Image_From_File;

   procedure Set_Animation
     (H : Animated_Widget_Handle; Animation : Animated_Image_Access)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Animation (Animated_Widget (Ptr.all), Animation);
      end if;
   end Set_Animation;

   function Get_Image_Animation
     (H : Animated_Widget_Handle) return Animated_Image_Access
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Image_Animation (Animated_Widget (Ptr.all));
      end if;
      return null;
   end Get_Image_Animation;

   procedure Start (H : Animated_Widget_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Start (Animated_Widget (Ptr.all));
      end if;
   end Start;

   procedure Stop (H : Animated_Widget_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Stop (Animated_Widget (Ptr.all));
      end if;
   end Stop;

   procedure Reset (H : Animated_Widget_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Reset (Animated_Widget (Ptr.all));
      end if;
   end Reset;

   procedure Set_Looping
     (H : Animated_Widget_Handle; Value : Boolean := True)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Looping (Animated_Widget (Ptr.all), Value);
      end if;
   end Set_Looping;

   procedure Set_Playback_Speed
     (H : Animated_Widget_Handle; Multiplier : Float := 1.0)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Playback_Speed (Animated_Widget (Ptr.all), Multiplier);
      end if;
   end Set_Playback_Speed;

   function Is_Looping (H : Animated_Widget_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Looping (Animated_Widget (Ptr.all));
      end if;
      return False;
   end Is_Looping;

   function Is_Playing (H : Animated_Widget_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Playing (Animated_Widget (Ptr.all));
      end if;
      return False;
   end Is_Playing;

   procedure Set_Max_Size
     (H          : Animated_Widget_Handle;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Max_Size (Animated_Widget (Ptr.all), Max_Width, Max_Height);
      end if;
   end Set_Max_Size;

   procedure Set_Backend
     (W        : in out Animated_Widget'Class;
      Backend  : Animation_Backend_Access;
      As_Image : Animated_Image_Access := null)
   is
   begin
      Clear_Backend (W);
      W.Image_Animation := As_Image;
      W.Backend := Backend;
      Mark_Dirty (W);
   end Set_Backend;

   function Load_Image_From_File
     (W    : in out Animated_Widget;
      Path : String) return Boolean
   is
      Loaded : constant Animated_Image_Access :=
        Adi.Animated_Image.Load_From_File (Path);
   begin
      if Loaded = null then
         return False;
      end if;

      Set_Animation (W, Loaded);
      return True;
   end Load_Image_From_File;

   procedure Set_Animation
     (W         : in out Animated_Widget;
      Animation : Animated_Image_Access)
   is
      B : Animation_Backend_Access := null;
   begin
      if Animation /= null then
         B := new Image_Backend'(Animation => Animation);
      end if;
      Set_Backend (W, B, Animation);
   end Set_Animation;

   function Get_Image_Animation
     (W : Animated_Widget) return Animated_Image_Access
   is
   begin
      return W.Image_Animation;
   end Get_Image_Animation;

   procedure Start (W : in out Animated_Widget) is
   begin
      if Has_Backend (W) then
         Start (W.Backend.all);
         Mark_Dirty (W);
      end if;
   end Start;

   procedure Stop (W : in out Animated_Widget) is
   begin
      if Has_Backend (W) then
         Stop (W.Backend.all);
         Mark_Dirty (W);
      end if;
   end Stop;

   procedure Reset (W : in out Animated_Widget) is
   begin
      if Has_Backend (W) then
         Reset (W.Backend.all);
         Mark_Dirty (W);
      end if;
   end Reset;

   procedure Set_Looping
     (W     : in out Animated_Widget;
      Value : Boolean := True)
   is
   begin
      if Has_Backend (W) then
         Set_Looping (W.Backend.all, Value);
      end if;
   end Set_Looping;

   procedure Set_Playback_Speed
     (W          : in out Animated_Widget;
      Multiplier : Float := 1.0)
   is
   begin
      if Has_Backend (W) then
         Set_Playback_Speed (W.Backend.all, Multiplier);
      end if;
   end Set_Playback_Speed;

   function Is_Looping (W : Animated_Widget) return Boolean is
   begin
      if Has_Backend (W) then
         return Is_Looping (W.Backend.all);
      end if;
      return False;
   end Is_Looping;

   function Is_Playing (W : Animated_Widget) return Boolean is
   begin
      if Has_Backend (W) then
         return Is_Playing (W.Backend.all);
      end if;
      return False;
   end Is_Playing;

   procedure Set_Max_Size
     (W          : in out Animated_Widget;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type)
   is
   begin
      W.Max_Width := Pixel_Type'Max (0.0, Max_Width);
      W.Max_Height := Pixel_Type'Max (0.0, Max_Height);
      Mark_Dirty (W);
   end Set_Max_Size;

   overriding function Measure_Content (W : Animated_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Result     : Size_2D := (0.0, 0.0);
      Scale      : Pixel_Type := 1.0;
   begin
      if Has_Backend (W) then
         Get_Size (W.Backend.all, Result.Width, Result.Height);
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

   overriding procedure Build_Items (W : in out Animated_Widget) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Content    : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Current    : Image_Access := null;
   begin
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Add_Item (W, Make_Image (Icon_Part, Content, null, 1));
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;
      W.Items.Reference (Image_Idx).Geometry := Content;

      if Has_Backend (W) then
         Current := Get_Current_Image (W.Backend.all);
      end if;

      W.Items.Reference (Image_Idx).Image_Source := Current;
   end Build_Items;

   overriding procedure Layout (W : in out Animated_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Layout;

   overriding procedure On_Tick (W : in out Animated_Widget; DT : Duration) is
      Changed : Boolean := False;
   begin
      Tick_Scroll_Animations (W, DT);

      if Has_Backend (W) then
         Changed := Advance (W.Backend.all, DT);
      end if;

      if Changed then
         Mark_Dirty (W);
      end if;
   end On_Tick;

   overriding procedure Get_Size
     (B      : Image_Backend;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
   begin
      if B.Animation = null or else not Is_Valid (B.Animation.all) then
         Width := 0.0;
         Height := 0.0;
         return;
      end if;
      Adi.Animated_Image.Get_Size (B.Animation.all, Width, Height);
   end Get_Size;

   overriding function Get_Current_Image
     (B : Image_Backend) return Image_Access
   is
   begin
      if B.Animation = null or else not Is_Valid (B.Animation.all) then
         return null;
      end if;
      return Adi.Animated_Image.Get_Current_Image (B.Animation.all);
   end Get_Current_Image;

   overriding function Advance
     (B  : in out Image_Backend;
      DT : Duration) return Boolean
   is
   begin
      if B.Animation = null then
         return False;
      end if;
      return Adi.Animated_Image.Advance (B.Animation.all, DT);
   end Advance;

   overriding procedure Start (B : in out Image_Backend) is
   begin
      if B.Animation /= null then
         Adi.Animated_Image.Start (B.Animation.all);
      end if;
   end Start;

   overriding procedure Stop (B : in out Image_Backend) is
   begin
      if B.Animation /= null then
         Adi.Animated_Image.Stop (B.Animation.all);
      end if;
   end Stop;

   overriding procedure Reset (B : in out Image_Backend) is
   begin
      if B.Animation /= null then
         Adi.Animated_Image.Reset (B.Animation.all);
      end if;
   end Reset;

   overriding procedure Set_Looping
     (B     : in out Image_Backend;
      Value : Boolean)
   is
   begin
      if B.Animation /= null then
         Adi.Animated_Image.Set_Looping (B.Animation.all, Value);
      end if;
   end Set_Looping;

   overriding procedure Set_Playback_Speed
     (B          : in out Image_Backend;
      Multiplier : Float)
   is
      pragma Unreferenced (B, Multiplier);
   begin
      null;
   end Set_Playback_Speed;

   overriding function Is_Looping (B : Image_Backend) return Boolean is
   begin
      if B.Animation = null then
         return False;
      end if;
      return Adi.Animated_Image.Is_Looping (B.Animation.all);
   end Is_Looping;

   overriding function Is_Playing (B : Image_Backend) return Boolean is
   begin
      if B.Animation = null then
         return False;
      end if;
      return Adi.Animated_Image.Is_Playing (B.Animation.all);
   end Is_Playing;

end Adi.Widget.Animated_Widget;
