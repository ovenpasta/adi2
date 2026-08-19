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
      Img  : Image_Owner;
   begin
      if Set = null
        or else Set.Images = null
        or else Frame > Set.Images'Last
      then
         return False;
      end if;

      if Adi.Image.Is_Owned (Set.Images (Frame)) then
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
      --  The surface is this subprogram's until the image adopts it,
      --  which it does only once it owns one.
      begin
         Img := Create_From_Surface (Surf, Group => Set.Group'Unchecked_Access);
      exception
         when others =>
            SDL_DestroySurface (Surf);
            raise;
      end;

      if not Adi.Image.Is_Owned (Img) then
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

   function Load_From_File (Path : String) return Animation_Handle is
      use Interfaces.C.Strings;

      C_Path   : chars_ptr;
      Handle   : RL_Animation_Ptr;
      W        : aliased Interfaces.C.size_t := 0;
      H        : aliased Interfaces.C.size_t := 0;
      Count    : Interfaces.C.size_t;
      FPS      : Interfaces.C.double;
      Dur      : Interfaces.C.double;
      Result   : RLottie_Animation_Access := null;

      --  Nulls as it frees. A branch that destroyed the model and then
      --  raised while building its log message would otherwise reach the
      --  handler with a pointer already freed.
      procedure Discard_Model is
      begin
         if Handle /= null then
            Animation_Destroy (Handle);
            Handle := null;
         end if;
      end Discard_Model;
   begin
      Ensure_Initialized;

      C_Path := New_String (Path);
      Handle := Animation_From_File (C_Path);
      Free (C_Path);

      if Handle = null then
         Adi.Log.Error ("Failed to load rlottie animation: " & Path);
         return Null_Animation_Handle;
      end if;

      Animation_Get_Size (Handle, W'Access, H'Access);
      if W = 0 or else H = 0 then
         Discard_Model;
         Adi.Log.Error ("rlottie animation reports invalid size: " & Path);
         return Null_Animation_Handle;
      end if;

      Count := Animation_Get_Total_Frame (Handle);
      FPS := Animation_Get_Frame_Rate (Handle);
      Dur := Animation_Get_Duration (Handle);

      if Count = 0 then
         Discard_Model;
         Adi.Log.Error ("rlottie animation has zero frames: " & Path);
         return Null_Animation_Handle;
      end if;

      if Fail_After_Model then
         Fail_After_Model := False;
         raise Storage_Error with "injected";
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
      return (Id => Animation_Stores.Register (Result));

   exception
      --  The model is the C library's, and nothing else will reclaim it.
      --  Whatever failed between creating it and handing it to a store
      --  slot -- an allocation, a conversion, the registration itself --
      --  it goes, along with the half-filled record if one exists.
      --
      --  Then it propagates. A file that will not parse is answered with
      --  a null handle above; anything reaching here is exhaustion or a
      --  defect, and swallowing those would report them as a bad file.
      when others =>
         if Result /= null then
            Result.Handle := System.Null_Address;
            Free_RLottie (Result);
         end if;
         Discard_Model;
         raise;
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
            Adi.Image.Release (Set.Images (I));
         end loop;
         Free_Images (Set.Images);
      end if;

      Free_Set (Set);
      Set := null;
   end Destroy_Set;

   --  Retire a set that was drawn from. Its textures go from every
   --  renderer and its images go with them. A widget in a window that has
   --  not ticked since the replacement still holds handles to those
   --  images; they are stale now, and drawing through one finds nothing
   --  rather than freed storage.
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
            Adi.Image.Release (Set.Images (I));
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
        (Images       => new Image_Array'(1 .. Anim.Frame_Count =>
                                            Null_Image_Owner),
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
      and then Adi.Image.Is_Owned
                 (Anim.Active.Images (Anim.Current_Frame)));

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

   function Get_Current_Image (Anim : RLottie_Animation) return Image_Handle is
   begin
      if Anim.Active = null
        or else Anim.Current_Frame = 0
        or else Anim.Current_Frame > Anim.Active.Images'Last
      then
         return Null_Image_Handle;
      end if;
      return Adi.Image.To_Handle (Anim.Active.Images (Anim.Current_Frame));
   end Get_Current_Image;

   procedure Start (Anim : in out RLottie_Animation) is
   begin
      if Anim.Frame_Count > 0 then
         --  Resuming re-anchors, so the pause is not charged as elapsed.
         Adi.Playback_Clock.Reanchor (Anim.Clock);
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
      Adi.Playback_Clock.Reanchor (Anim.Clock);

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
      Adi.Playback_Clock.Reanchor (Anim.Clock);
      return Advance_By (Anim, DT);
   end Advance;

   function Advance_At
     (Anim   : in out RLottie_Animation;
      Sample : Adi.Clock.Time) return Boolean
   is
      Tick : Adi.Playback_Clock.Sample_Result;
   begin
      if not Is_Valid (Anim) then
         return False;
      end if;

      --  Preparation is not playback: a settled extent has to be taken up
      --  whether or not the playhead is moving, so this runs before every
      --  return below it.
      Service_Pending (Anim);

      Tick := Adi.Playback_Clock.Sample (Anim.Clock, Sample);

      case Tick.Kind is
         when Adi.Playback_Clock.Ignored =>
            return False;

         when Adi.Playback_Clock.Anchored =>
            --  Anchoring is not the same as showing nothing. Stepping by
            --  zero moves the timeline nowhere but still settles which
            --  frame is visible, so a freshly prepared animation shows
            --  its first rather than staying blank until a second sample
            --  arrives. When one is already visible it reports no
            --  movement, which is what keeps a re-anchor after Start or
            --  Reset from looking like one.
            return Advance_By (Anim, 0.0);

         when Adi.Playback_Clock.Elapsed =>
            --  Sampled before this, so a pause is consumed as it passes
            --  rather than delivered in one leap on resume.
            if not Anim.Playing then
               return False;
            end if;
            return Advance_By (Anim, Tick.Span);
      end case;
   end Advance_At;

   procedure Destroy (Anim : in out RLottie_Animation) is
      Next : Frame_Set_Access;
   begin
      --  Every texture made from any extent goes at once, in whichever
      --  renderers hold them. This runs on the render thread, which is
      --  where the caches live.
      Destroy_Set (Anim.Active);

      --  The sets kept across replacements. Their frames are already
      --  released; what is left is the bookkeeping a resize is counted
      --  by.
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

   ---------------------------------------------------------------------------
   --  Handles
   ---------------------------------------------------------------------------

   --  Resolved for the duration of one synchronous call and no longer.
   --  Nothing here holds a borrow across a destroy, so the store never
   --  has a pinned slot to defer.
   --  Checked rather than fetched: the store is strict by default and
   --  raises on a stale id, while a stale handle here is an ordinary
   --  thing to be told about -- the animation it named has been
   --  destroyed, and the operation has nothing to do.
   function Resolve (H : Animation_Handle) return RLottie_Animation_Access
   is (if Animation_Stores.Is_Valid (H.Id)
       then Animation_Stores.Get (H.Id)
       else null);

   function Is_Valid (H : Animation_Handle) return Boolean is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return A /= null and then Is_Valid (A.all);
   end Is_Valid;

   procedure Get_Size
     (H      : Animation_Handle;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A = null then
         Width := 0.0;
         Height := 0.0;
         return;
      end if;
      Get_Size (A.all, Width, Height);
   end Get_Size;

   procedure Prepare
     (H            : Animation_Handle;
      Pixel_Width  : Positive;
      Pixel_Height : Positive)
   is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A /= null then
         Prepare (A.all, Pixel_Width, Pixel_Height);
      end if;
   end Prepare;

   function Is_Prepared (H : Animation_Handle) return Boolean is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return A /= null and then Is_Prepared (A.all);
   end Is_Prepared;

   procedure Prepared_Extent
     (H      : Animation_Handle;
      Width  : out Natural;
      Height : out Natural)
   is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A = null then
         Width := 0;
         Height := 0;
         return;
      end if;
      Prepared_Extent (A.all, Width, Height);
   end Prepared_Extent;

   function Estimated_Surface_Bytes
     (H            : Animation_Handle;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer
   is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then 0
              else Estimated_Surface_Bytes (A.all, Pixel_Width, Pixel_Height));
   end Estimated_Surface_Bytes;

   function Estimated_Max_Texture_Bytes
     (H            : Animation_Handle;
      Pixel_Width  : Positive;
      Pixel_Height : Positive) return Long_Long_Integer
   is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then 0
              else Estimated_Max_Texture_Bytes
                     (A.all, Pixel_Width, Pixel_Height));
   end Estimated_Max_Texture_Bytes;

   function Get_Frame_Count (H : Animation_Handle) return Natural is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then 0 else Get_Frame_Count (A.all));
   end Get_Frame_Count;

   function Get_Frame_Rate (H : Animation_Handle) return Float is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then 0.0 else Get_Frame_Rate (A.all));
   end Get_Frame_Rate;

   function Get_Duration (H : Animation_Handle) return Duration is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then 0.0 else Get_Duration (A.all));
   end Get_Duration;

   function Get_Current_Frame_Index (H : Animation_Handle) return Natural is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then 0 else Get_Current_Frame_Index (A.all));
   end Get_Current_Frame_Index;

   function Get_Current_Image (H : Animation_Handle) return Image_Handle is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then Null_Image_Handle
              else Get_Current_Image (A.all));
   end Get_Current_Image;

   procedure Start (H : Animation_Handle) is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A /= null then
         Start (A.all);
      end if;
   end Start;

   procedure Stop (H : Animation_Handle) is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A /= null then
         Stop (A.all);
      end if;
   end Stop;

   function Is_Playing (H : Animation_Handle) return Boolean is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return A /= null and then Is_Playing (A.all);
   end Is_Playing;

   procedure Set_Looping (H : Animation_Handle; Value : Boolean := True) is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A /= null then
         Set_Looping (A.all, Value);
      end if;
   end Set_Looping;

   function Is_Looping (H : Animation_Handle) return Boolean is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return A /= null and then Is_Looping (A.all);
   end Is_Looping;

   procedure Set_Playback_Speed
     (H          : Animation_Handle;
      Multiplier : Float := 1.0)
   is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A /= null then
         Set_Playback_Speed (A.all, Multiplier);
      end if;
   end Set_Playback_Speed;

   function Get_Playback_Speed (H : Animation_Handle) return Float is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return (if A = null then 1.0 else Get_Playback_Speed (A.all));
   end Get_Playback_Speed;

   procedure Reset (H : Animation_Handle) is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A /= null then
         Reset (A.all);
      end if;
   end Reset;

   function Advance (H : Animation_Handle; DT : Duration) return Boolean is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return A /= null and then Advance (A.all, DT);
   end Advance;

   function Advance_At
     (H      : Animation_Handle;
      Sample : Adi.Clock.Time) return Boolean
   is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      return A /= null and then Advance_At (A.all, Sample);
   end Advance_At;

   procedure Destroy (H : in out Animation_Handle) is
      A : constant RLottie_Animation_Access := Resolve (H);
   begin
      if A /= null then
         --  Torn down before the slot goes: the store has no hook that
         --  would do it, and nothing holds a pin to defer the free.
         Destroy (A.all);
         Animation_Stores.Request_Destroy (H.Id);
      end if;
      H := Null_Animation_Handle;
   end Destroy;

end Adi.RLottie;
