--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Interfaces.C;
with Interfaces.C.Strings;
with Adi.Log;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;
with Adi.SDL.Surface;     use Adi.SDL.Surface;

package body Adi.RLottie is

   use type Interfaces.C.size_t;
   use type System.Address;

   type RL_Animation is limited null record;
   type RL_Animation_Ptr is access all RL_Animation;

   procedure Lottie_Init
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_init";

   procedure Animation_Destroy
     (Animation : RL_Animation_Ptr)
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_animation_destroy";

   function Animation_From_File
     (Path : Interfaces.C.Strings.chars_ptr) return RL_Animation_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_animation_from_file";

   procedure Animation_Get_Size
     (Animation : RL_Animation_Ptr;
      Width     : access Interfaces.C.size_t;
      Height    : access Interfaces.C.size_t)
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_animation_get_size";

   function Animation_Get_Duration
     (Animation : RL_Animation_Ptr) return Interfaces.C.double
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_animation_get_duration";

   function Animation_Get_Total_Frame
     (Animation : RL_Animation_Ptr) return Interfaces.C.size_t
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_animation_get_totalframe";

   function Animation_Get_Frame_Rate
     (Animation : RL_Animation_Ptr) return Interfaces.C.double
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_animation_get_framerate";

   procedure Animation_Render
     (Animation      : RL_Animation_Ptr;
      Frame_Num      : Interfaces.C.size_t;
      Buffer         : access Interfaces.Unsigned_32;
      Width          : Interfaces.C.size_t;
      Height         : Interfaces.C.size_t;
      Bytes_Per_Line : Interfaces.C.size_t)
      with Import        => True,
           Convention    => C,
           External_Name => "lottie_animation_render";

   function To_Ptr is new Ada.Unchecked_Conversion
     (Source => System.Address,
      Target => RL_Animation_Ptr);

   function To_Address is new Ada.Unchecked_Conversion
     (Source => RL_Animation_Ptr,
      Target => System.Address);

   type U32_Ptr is access all Interfaces.Unsigned_32;
   function To_U32_Ptr is new Ada.Unchecked_Conversion
     (Source => System.Address,
      Target => U32_Ptr);

   Initialized : Boolean := False;

   procedure Ensure_Initialized is
   begin
      if not Initialized then
         Lottie_Init;
         Initialized := True;
      end if;
   end Ensure_Initialized;


   procedure Free_RLottie is new Ada.Unchecked_Deallocation
     (Object => RLottie_Animation'Class,
      Name   => RLottie_Animation_Access);

   procedure Free_Images is new Ada.Unchecked_Deallocation
     (Object => Image_Array,
      Name   => Image_Array_Access);

   procedure Free_Set is new Ada.Unchecked_Deallocation
     (Object => Frame_Set,
      Name   => Frame_Set_Access);

   function Resolve_Target_Frame
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Natural;

   function Resolve_Target_Frame
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Natural
   is
      T : Float;
      F : Natural;
   begin
      if Anim.Frame_Count = 0 then
         return 0;
      end if;

      if not Anim.Playing then
         return Anim.Current_Frame;
      end if;

      Anim.Elapsed_S := Anim.Elapsed_S + Float (DT) * Anim.Playback_Speed;

      if Anim.Duration_S <= 0.0 then
         return Anim.Current_Frame;
      end if;

      if Anim.Looping then
         while Anim.Elapsed_S >= Anim.Duration_S loop
            Anim.Elapsed_S := Anim.Elapsed_S - Anim.Duration_S;
         end loop;
      elsif Anim.Elapsed_S >= Anim.Duration_S then
         Anim.Elapsed_S := Anim.Duration_S;
         Anim.Playing := False;
      end if;

      T := Anim.Elapsed_S * Anim.Frame_Rate;
      F := 1 + Natural (Integer (Float'Floor (T)));
      if F < 1 then
         F := 1;
      elsif F > Anim.Frame_Count then
         F := Anim.Frame_Count;
      end if;
      return F;
   end Resolve_Target_Frame;

   --  Rasterise one frame of one set, once. A slot already filled is the
   --  common case: a looping animation pays for each frame the first time
   --  playback reaches it and never again.
   function Rasterise_Into
     (Anim  : in out RLottie_Animation;
      Set   : Frame_Set_Access;
      Frame : Positive) return Boolean
   is
      Surf : SDL_Surface_Ptr;
      Buf  : U32_Ptr;
      Img  : Image_Access;
   begin
      if Set = null
        or else Set.Images = null
        or else Frame > Set.Images'Last
      then
         return False;
      end if;

      if Set.Images (Frame) /= null then
         return True;
      end if;

      if Anim.Fail_Next_Raster then
         Anim.Fail_Next_Raster := False;
         return False;
      end if;

      Surf :=
        SDL_Surface_Ptr
          (SDL_CreateSurface
             (width  => Interfaces.C.int (Set.Width),
              height => Interfaces.C.int (Set.Height),
              format => SDL_PIXELFORMAT_ARGB8888));
      if Surf = null then
         return False;
      end if;

      --  Wrapping a surface nothing was drawn into would retain a blank
      --  frame for ever and count it as rasterised.
      if Surf.pixels = System.Null_Address then
         SDL_DestroySurface (Surf);
         return False;
      end if;

      Buf := To_U32_Ptr (Surf.pixels);
      if Buf = null then
         SDL_DestroySurface (Surf);
         return False;
      end if;

      Animation_Render
        (Animation      => To_Ptr (Anim.Handle),
         Frame_Num      => Interfaces.C.size_t (Frame - 1),
         Buffer         => Buf,
         Width          => Interfaces.C.size_t (Set.Width),
         Height         => Interfaces.C.size_t (Set.Height),
         Bytes_Per_Line => Interfaces.C.size_t (Surf.pitch));

      --  Every frame of this extent joins that extent's group, so
      --  replacing the extent takes its textures out of every renderer
      --  rather than leaving them for eviction.
      Img := Create_From_Surface (Surf, Group => Set.Group'Unchecked_Access);
      if Img = null then
         SDL_DestroySurface (Surf);
         return False;
      end if;

      Set.Images (Frame) := Img;
      Anim.Rasterisations := Anim.Rasterisations + 1;
      return True;
   end Rasterise_Into;

   function Ensure_Frame_Image
     (Anim  : in out RLottie_Animation;
      Frame : Positive) return Boolean
   is (Rasterise_Into (Anim, Anim.Active, Frame));

   function Load_From_File
     (Path : String) return RLottie_Animation_Access
   is
      use Interfaces.C.Strings;

      C_Path   : chars_ptr;
      Handle   : RL_Animation_Ptr;
      W        : aliased Interfaces.C.size_t := 0;
      H        : aliased Interfaces.C.size_t := 0;
      Count    : Interfaces.C.size_t;
      FPS      : Interfaces.C.double;
      Dur      : Interfaces.C.double;
      Result   : RLottie_Animation_Access := null;
   begin
      Ensure_Initialized;

      C_Path := New_String (Path);
      Handle := Animation_From_File (C_Path);
      Free (C_Path);

      if Handle = null then
         Adi.Log.Error ("Failed to load rlottie animation: " & Path);
         return null;
      end if;

      Animation_Get_Size (Handle, W'Access, H'Access);
      if W = 0 or else H = 0 then
         Animation_Destroy (Handle);
         Adi.Log.Error ("rlottie animation reports invalid size: " & Path);
         return null;
      end if;

      Count := Animation_Get_Total_Frame (Handle);
      FPS := Animation_Get_Frame_Rate (Handle);
      Dur := Animation_Get_Duration (Handle);

      if Count = 0 then
         Animation_Destroy (Handle);
         Adi.Log.Error ("rlottie animation has zero frames: " & Path);
         return null;
      end if;

      Result := new RLottie_Animation;
      Result.Handle := To_Address (Handle);
      Result.Width := Pixel_Type (Float (W));
      Result.Height := Pixel_Type (Float (H));
      Result.Frame_Count := Natural (Count);
      Result.Frame_Rate := Float (FPS);
      Result.Duration_S := Float (Dur);

      --  Nothing is rasterised here. The file's viewport is what the
      --  animation was authored at, not what it will be drawn at, and
      --  the caller knows the latter.
      return Result;
   end Load_From_File;

   ---------------------------------------------------------------------------
   -- Prepare
   ---------------------------------------------------------------------------

   --  Free a set outright. Only for one no widget can have seen: a
   --  replacement that failed before it was published.
   procedure Destroy_Set (Set : in out Frame_Set_Access) is
   begin
      if Set = null then
         return;
      end if;

      Adi.Texture_Cache.Release (Set.Group);

      if Set.Images /= null then
         for I in Set.Images'Range loop
            if Set.Images (I) /= null then
               Adi.Image.Free (Set.Images (I));
            end if;
         end loop;
         Free_Images (Set.Images);
      end if;

      Free_Set (Set);
      Set := null;
   end Destroy_Set;

   --  Retire a set that was drawn from. Its textures go from every
   --  renderer and its pixels go, but the Image records stay: a widget in
   --  a window that has not ticked since the replacement still holds a
   --  plain Image_Access to one of them, and drawing through it must find
   --  an empty image rather than freed storage. The shells are freed in
   --  Destroy, where widgets are already required to have detached.
   procedure Retire_Set
     (Anim : in out RLottie_Animation;
      Set  : in out Frame_Set_Access) is
   begin
      if Set = null then
         return;
      end if;

      Adi.Texture_Cache.Release (Set.Group);

      if Set.Images /= null then
         for I in Set.Images'Range loop
            if Set.Images (I) /= null then
               Adi.Image.Destroy (Set.Images (I).all);
            end if;
         end loop;
      end if;

      Set.Next_Retired := Anim.Retired;
      Anim.Retired := Set;
      Anim.Retired_Count := Anim.Retired_Count + 1;
      Set := null;
   end Retire_Set;

   --  Put a set for the settled extent in place. Whether the current
   --  frame is rasterised first is the whole difference between the two
   --  cases: the first set has nothing to preserve and nothing has asked
   --  it for a frame, while a replacement is taking over from something
   --  already on screen and must not blank it.
   function Install_Extent (Anim : in out RLottie_Animation) return Boolean is
      Replacing : constant Boolean := Anim.Active /= null;
      First     : constant Positive :=
        (if Anim.Current_Frame in 1 .. Anim.Frame_Count
         then Anim.Current_Frame else 1);
      Fresh : Frame_Set_Access;
      Old   : Frame_Set_Access;
   begin
      if Anim.Frame_Count = 0 then
         return False;
      end if;

      Fresh := new Frame_Set'
        (Images       => new Image_Array'(1 .. Anim.Frame_Count => null),
         Width        => Anim.Pending_W,
         Height       => Anim.Pending_H,
         Frame_Count  => Anim.Frame_Count,
         Group        => <>,
         Next_Retired => null);

      --  Nothing has drawn from it yet, so failing here costs nothing:
      --  the old set stays in place and stays drawable.
      if Replacing and then not Rasterise_Into (Anim, Fresh, First) then
         Destroy_Set (Fresh);
         return False;
      end if;

      Old := Anim.Active;
      Anim.Active := Fresh;

      --  A resize changes how the animation is presented, not where it
      --  has got to, so the playhead and the elapsed time both stand.
      if Replacing then
         Anim.Current_Frame := First;
      end if;

      Retire_Set (Anim, Old);
      return True;
   end Install_Extent;

   --  How long an extent must stand still before it is worth rasterising
   --  at. A resize passes through every intermediate size; rebuilding at
   --  each would throw away the frames of every one of them.
   Settle_Time : constant Duration := 0.150;

   procedure Service_Pending (Anim : in out RLottie_Animation) is
      use type Adi.Clock.Time;
   begin
      if not Anim.Pending_Live then
         return;
      end if;

      --  Already at the wanted extent.
      if Anim.Active /= null
        and then Anim.Active.Width = Anim.Pending_W
        and then Anim.Active.Height = Anim.Pending_H
      then
         Anim.Pending_Live := False;
         return;
      end if;

      --  The first extent is wanted immediately: there is nothing to draw
      --  until it exists, so waiting for it to settle would leave the
      --  animation blank for no benefit.
      if Anim.Active = null
        or else Adi.Clock.To_Duration (Adi.Clock.Now - Anim.Pending_Since)
                  >= Settle_Time
      then
         if Install_Extent (Anim) then
            Anim.Pending_Live := False;
         else
            --  Asked for again rather than dropped, but not before the
            --  settle interval: retrying an allocation that just failed
            --  on every tick helps nothing.
            Anim.Pending_Since := Adi.Clock.Now;
         end if;
      end if;
   end Service_Pending;

   procedure Prepare
     (Anim         : in out RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) is
   begin
      if Anim.Handle = System.Null_Address or else Anim.Frame_Count = 0 then
         return;
      end if;

      --  Already rasterising at this extent.
      if Anim.Active /= null
        and then Anim.Active.Width = Pixel_Width
        and then Anim.Active.Height = Pixel_Height
      then
         Anim.Pending_Live := False;
         return;
      end if;

      --  Asking again for the same extent leaves the clock alone, so a
      --  steady request settles rather than restarting on every frame.
      if not Anim.Pending_Live
        or else Anim.Pending_W /= Pixel_Width
        or else Anim.Pending_H /= Pixel_Height
      then
         Anim.Pending_W := Pixel_Width;
         Anim.Pending_H := Pixel_Height;
         Anim.Pending_Since := Adi.Clock.Now;
         Anim.Pending_Live := True;
      end if;

      Service_Pending (Anim);
   end Prepare;

   --  A set that can be drawn from, not one that is being built: an
   --  empty allocation is not something to show.
   --  Drawable, not merely sized. A set holds no frames until playback
   --  reaches them, so an accepted extent is not on its own something to
   --  draw.
   function Is_Prepared (Anim : RLottie_Animation) return Boolean is
     (Anim.Active /= null
      and then Anim.Current_Frame in 1 .. Anim.Active.Images'Last
      and then Anim.Active.Images (Anim.Current_Frame) /= null);

   procedure Prepared_Extent
     (Anim   : RLottie_Animation;
      Width  : out Natural;
      Height : out Natural) is
   begin
      if Anim.Active = null then
         Width := 0;
         Height := 0;
      else
         Width := Anim.Active.Width;
         Height := Anim.Active.Height;
      end if;
   end Prepared_Extent;

   function Estimated_Surface_Bytes
     (Anim         : RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer
   is (Long_Long_Integer (Anim.Frame_Count)
       * Long_Long_Integer (Pixel_Width)
       * Long_Long_Integer (Pixel_Height)
       * 4);

   function Estimated_Max_Texture_Bytes
     (Anim         : RLottie_Animation;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer
   is (Estimated_Surface_Bytes (Anim, Pixel_Width, Pixel_Height));

   --  The model is loaded and has frames to draw. Whether any have been
   --  rasterised is Is_Prepared's question: measurement needs the former
   --  and drawing needs the latter.
   function Is_Valid (Anim : RLottie_Animation) return Boolean is
   begin
      return Anim.Handle /= System.Null_Address
        and then Anim.Frame_Count > 0;
   end Is_Valid;

   procedure Get_Size
     (Anim   : RLottie_Animation;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
   begin
      Width := Anim.Width;
      Height := Anim.Height;
   end Get_Size;

   function Get_Frame_Count (Anim : RLottie_Animation) return Natural is
   begin
      return Anim.Frame_Count;
   end Get_Frame_Count;

   function Get_Frame_Rate (Anim : RLottie_Animation) return Float is
   begin
      return Anim.Frame_Rate;
   end Get_Frame_Rate;

   function Get_Duration (Anim : RLottie_Animation) return Duration is
   begin
      return Duration (Anim.Duration_S);
   end Get_Duration;

   function Get_Current_Frame_Index (Anim : RLottie_Animation) return Natural is
   begin
      return Anim.Current_Frame;
   end Get_Current_Frame_Index;

   function Get_Current_Image (Anim : RLottie_Animation) return Image_Access is
   begin
      if Anim.Active = null
        or else Anim.Current_Frame = 0
        or else Anim.Current_Frame > Anim.Active.Images'Last
      then
         return null;
      end if;
      return Anim.Active.Images (Anim.Current_Frame);
   end Get_Current_Image;

   procedure Start (Anim : in out RLottie_Animation) is
   begin
      if Anim.Frame_Count > 0 then
         --  Resuming re-anchors, so the pause is not charged as elapsed.
         Anim.Anchored := False;
         Anim.Playing := True;
      end if;
   end Start;

   procedure Stop (Anim : in out RLottie_Animation) is
   begin
      Anim.Playing := False;
   end Stop;

   function Is_Playing (Anim : RLottie_Animation) return Boolean is
   begin
      return Anim.Playing and then Anim.Frame_Count > 0;
   end Is_Playing;

   procedure Set_Looping (Anim : in out RLottie_Animation; Value : Boolean := True) is
   begin
      Anim.Looping := Value;
   end Set_Looping;

   function Is_Looping (Anim : RLottie_Animation) return Boolean is
   begin
      return Anim.Looping;
   end Is_Looping;

   procedure Set_Playback_Speed
     (Anim       : in out RLottie_Animation;
      Multiplier : Float := 1.0)
   is
   begin
      Anim.Playback_Speed := Float'Max (0.01, Multiplier);
   end Set_Playback_Speed;

   function Get_Playback_Speed (Anim : RLottie_Animation) return Float is
   begin
      return Anim.Playback_Speed;
   end Get_Playback_Speed;

   procedure Reset (Anim : in out RLottie_Animation) is
   begin
      Anim.Elapsed_S := 0.0;
      Anim.Current_Frame := 0;
      Anim.Anchored := False;

      if Anim.Active /= null then
         if Ensure_Frame_Image (Anim, 1) then
            Anim.Current_Frame := 1;
         end if;
      end if;
   end Reset;

   --  The stepping itself. Both ways in share it; what differs is what
   --  they do to the sampled anchor.
   function Advance_By
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Boolean
   is
      Target : Natural;
   begin
      if not Is_Valid (Anim) then
         return False;
      end if;

      if Anim.Active = null then
         return False;
      end if;

      Target := Resolve_Target_Frame (Anim, DT);
      if Target = 0 or else Target = Anim.Current_Frame then
         return False;
      end if;

      if Target > Anim.Frame_Count then
         return False;
      end if;

      if not Ensure_Frame_Image (Anim, Target) then
         return False;
      end if;

      Anim.Current_Frame := Target;
      return True;
   end Advance_By;

   function Advance
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Boolean is
   begin
      if not Is_Valid (Anim) then
         return False;
      end if;

      --  Preparation is not playback: a settled extent has to be taken up
      --  whether or not the playhead is moving, so this runs before any
      --  of the returns below it.
      Service_Pending (Anim);

      --  Stepping by hand moves the timeline without the sampled clock
      --  knowing, so the next sample must anchor rather than charge for
      --  the step it has just been given and the time since.
      Anim.Anchored := False;
      return Advance_By (Anim, DT);
   end Advance;

   function Advance_At
     (Anim   : in out RLottie_Animation;
      Sample : Adi.Clock.Time) return Boolean
   is
      use type Adi.Clock.Time;
      Step : Duration;
   begin
      if not Is_Valid (Anim) then
         return False;
      end if;

      --  Preparation is not playback: a settled extent has to be taken up
      --  whether or not the playhead is moving, so this runs before the
      --  anchor, stale-sample and paused returns below.
      Service_Pending (Anim);

      --  Nothing to charge the animation for: the first sample, or the
      --  first after the timeline moved some other way.
      if not Anim.Anchored then
         Anim.Last_Sample := Sample;
         Anim.Anchored := True;

         --  Anchoring is not the same as showing nothing. Stepping by
         --  zero moves the timeline nowhere but still settles which frame
         --  is visible, so a freshly prepared animation shows its first
         --  rather than staying blank until a second sample arrives. When
         --  one is already visible it reports no movement, which is what
         --  keeps a re-anchor after Start or Reset from looking like one.
         return Advance_By (Anim, 0.0);
      end if;

      Step := Adi.Clock.To_Duration (Sample - Anim.Last_Sample);

      --  A repeat of the same instant advances nothing, which is what
      --  makes several viewers per step harmless. One that has gone
      --  backwards is ignored outright: moving the anchor to it would
      --  make the next honest sample pay for the gap twice.
      if Step <= 0.0 then
         return False;
      end if;

      Anim.Last_Sample := Sample;

      --  Paused time is not owed; the anchor has already moved above, so
      --  resuming does not deliver the whole pause at once.
      if not Anim.Playing then
         return False;
      end if;

      return Advance_By (Anim, Step);
   end Advance_At;

   procedure Destroy (Anim : in out RLottie_Animation) is
      Next : Frame_Set_Access;
   begin
      --  Every texture made from any extent goes at once, in whichever
      --  renderers hold them. This runs on the render thread, which is
      --  where the caches live.
      Destroy_Set (Anim.Active);

      --  The shells kept across replacements. Widgets are required to
      --  have detached by here, so the records can finally go.
      while Anim.Retired /= null loop
         Next := Anim.Retired.Next_Retired;
         Anim.Retired.Next_Retired := null;
         Destroy_Set (Anim.Retired);
         Anim.Retired := Next;
      end loop;
      Anim.Retired_Count := 0;

      --  Only now: nothing is rendering from it any more.
      if Anim.Handle /= System.Null_Address then
         Animation_Destroy (To_Ptr (Anim.Handle));
         Anim.Handle := System.Null_Address;
      end if;

      Anim.Frame_Count := 0;
      Anim.Current_Frame := 0;
      Anim.Pending_Live := False;
   end Destroy;

end Adi.RLottie;
