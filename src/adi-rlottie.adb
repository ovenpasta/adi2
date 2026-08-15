--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Interfaces.C;
with Interfaces.C.Strings;
with Adi.Log;
with Adi.SDL.Pixelformat; use Adi.SDL.Pixelformat;

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

   protected body Preload_State is
      procedure Set_Ready_Count (Value : Natural) is
      begin
         Ready := Value;
      end Set_Ready_Count;

      function Ready_Count return Natural is
      begin
         return Ready;
      end Ready_Count;

      procedure Mark_Done is
      begin
         Completed := True;
      end Mark_Done;

      entry Wait_Done when Completed is
      begin
         null;
      end Wait_Done;

      function Done return Boolean is
      begin
         return Completed;
      end Done;

      procedure Signal_Stop is
      begin
         Stop_Flag := True;
      end Signal_Stop;

      function Stop_Requested return Boolean is
      begin
         return Stop_Flag;
      end Stop_Requested;
   end Preload_State;

   task body Preload_Task is
      Surf : SDL_Surface_Ptr;
      Buf  : U32_Ptr;
   begin
      --  Allocation belongs here rather than on the UI path: a frame set
      --  at a large extent is tens of megabytes, and the frame that asked
      --  for the resize should not wait for it.
      Set.Surfaces := new Surface_Array (1 .. Set.Frame_Count);
      for I in Set.Surfaces'Range loop
         Set.Surfaces (I) := null;
      end loop;

      Set.Images := new Image_Array (1 .. Set.Frame_Count);
      for I in Set.Images'Range loop
         Set.Images (I) := null;
      end loop;

      for I in 1 .. Set.Frame_Count loop
         exit when State.Stop_Requested;

         Surf :=
           SDL_Surface_Ptr
             (SDL_CreateSurface
                (width  => Interfaces.C.int (Set.Width),
                 height => Interfaces.C.int (Set.Height),
                 format => SDL_PIXELFORMAT_ARGB8888));
         if Surf = null then
            exit;
         end if;
         Set.Surfaces (I) := Surf;

         if Surf.pixels /= System.Null_Address then
            Buf := To_U32_Ptr (Surf.pixels);
            if Buf /= null then
               Animation_Render
                 (Animation      => To_Ptr (Animation.all),
                  Frame_Num      => Interfaces.C.size_t (I - 1),
                  Buffer         => Buf,
                  Width          => Interfaces.C.size_t (Set.Width),
                  Height         => Interfaces.C.size_t (Set.Height),
                  Bytes_Per_Line => Interfaces.C.size_t (Surf.pitch));
            end if;
         end if;

         State.Set_Ready_Count (I);
      end loop;

      State.Mark_Done;
   exception
      --  Whatever went wrong, teardown is waiting on this. A worker that
      --  died without saying so would block Destroy for ever.
      when others =>
         State.Mark_Done;
   end Preload_Task;

   procedure Free_RLottie is new Ada.Unchecked_Deallocation
     (Object => RLottie_Animation'Class,
      Name   => RLottie_Animation_Access);

   procedure Free_Surfaces is new Ada.Unchecked_Deallocation
     (Object => Surface_Array,
      Name   => Surface_Array_Access);

   procedure Free_Images is new Ada.Unchecked_Deallocation
     (Object => Image_Array,
      Name   => Image_Array_Access);

   procedure Free_State is new Ada.Unchecked_Deallocation
     (Object => Preload_State,
      Name   => Preload_State_Access);

   procedure Free_Set is new Ada.Unchecked_Deallocation
     (Object => Frame_Set,
      Name   => Frame_Set_Access);

   procedure Free_Worker is new Ada.Unchecked_Deallocation
     (Object => Preload_Task,
      Name   => Preload_Task_Access);

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

   --  Transfer ownership of a preloaded surface to an Image on first display.
   --  Only nulls the surface slot on successful image creation to avoid leaks.
   function Ensure_Frame_Image
     (Anim  : in out RLottie_Animation;
      Frame : Positive) return Boolean
   is
      Img : Image_Access;
   begin
      if Anim.Active = null
        or else Frame > Anim.Active.Images'Last
      then
         return False;
      end if;

      if Anim.Active.Images (Frame) /= null then
         return True;
      end if;

      if Anim.Active.Surfaces = null
        or else Frame > Anim.Active.Surfaces'Last
        or else Anim.Active.Surfaces (Frame) = null
      then
         return False;
      end if;

      Img := Create_From_Surface (Anim.Active.Surfaces (Frame));
      if Img = null then
         return False;
      end if;

      Anim.Active.Images (Frame) := Img;
      Anim.Active.Surfaces (Frame) := null;
      return True;
   end Ensure_Frame_Image;

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
      Width_N  : Natural;
      Height_N : Natural;
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
      Width_N := Natural (W);
      Height_N := Natural (H);

      if Count = 0 then
         Animation_Destroy (Handle);
         Adi.Log.Error ("rlottie animation has zero frames: " & Path);
         return null;
      end if;

      Result := new RLottie_Animation;
      Result.Handle := To_Address (Handle);
      Result.Width := Pixel_Type (Float (W));
      Result.Height := Pixel_Type (Float (H));
      Result.Buffer_Width := Width_N;
      Result.Buffer_Height := Height_N;
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

   --  Only ever called on a set no worker still holds.
   procedure Destroy_Set (Set : in out Frame_Set_Access) is
   begin
      if Set = null then
         return;
      end if;

      if Set.Images /= null then
         for I in Set.Images'Range loop
            if Set.Images (I) /= null then
               Adi.Image.Free (Set.Images (I));
            end if;
         end loop;
         Free_Images (Set.Images);
      end if;

      if Set.Surfaces /= null then
         for I in Set.Surfaces'Range loop
            if Set.Surfaces (I) /= null then
               SDL_DestroySurface (Set.Surfaces (I));
               Set.Surfaces (I) := null;
            end if;
         end loop;
         Free_Surfaces (Set.Surfaces);
      end if;

      Free_Set (Set);
      Set := null;
   end Destroy_Set;

   --  Take back a finished build: publish it if it is still wanted, drop
   --  it if it is not. Does nothing while the worker is still running, so
   --  the frame loop can call it every frame.
   procedure Reap_Build (Anim : in out RLottie_Animation) is
      Old : Frame_Set_Access;
   begin
      if Anim.Worker = null then
         return;
      end if;

      --  Terminated, not merely done: the task object cannot be reclaimed
      --  before the task has ended, and Done is raised inside the body.
      if not Anim.Worker.all'Terminated then
         return;
      end if;

      Free_Worker (Anim.Worker);
      Anim.Worker := null;
      if Anim.Build_State /= null then
         Free_State (Anim.Build_State);
      end if;

      if Anim.Build_Superseded
        or else Anim.Building = null
        or else Anim.Building.Generation /= Anim.Generation
      then
         Destroy_Set (Anim.Building);
      else
         --  The set that was drawable goes only once its replacement is
         --  in place, so nothing is ever left with no frames to draw.
         Old := Anim.Active;
         Anim.Active := Anim.Building;
         Anim.Building := null;
         Anim.Current_Frame := 0;
         Anim.Elapsed_S := 0.0;
         Destroy_Set (Old);
      end if;

      Anim.Build_Superseded := False;
   end Reap_Build;

   --  Begin a build at the pending extent. Never called while one is in
   --  flight, so exactly one worker exists at a time.
   procedure Start_Build (Anim : in out RLottie_Animation) is
   begin
      Anim.Generation := Anim.Generation + 1;
      Anim.Build_Count := Anim.Build_Count + 1;
      Anim.Build_Superseded := False;
      Anim.Building := new Frame_Set'
        (Surfaces    => null,
         Images      => null,
         Width       => Anim.Pending_W,
         Height      => Anim.Pending_H,
         Frame_Count => Anim.Frame_Count,
         Generation  => Anim.Generation);
      Anim.Build_State := new Preload_State;
      Anim.Worker := new Preload_Task
        (Animation => Anim.Handle'Unchecked_Access,
         Set       => Anim.Building,
         State     => Anim.Build_State);
   end Start_Build;

   --  How long an extent must stand still before it is worth rasterising
   --  at. A resize passes through every intermediate size; building at
   --  each would rebuild the set continuously and finish none of them.
   Settle_Time : constant Duration := 0.150;

   --  Run the pending extent forward. Called from the frame loop rather
   --  than from Prepare, because what decides a build is time passing
   --  without another request.
   procedure Service_Pending (Anim : in out RLottie_Animation) is
      use type Adi.Clock.Time;
   begin
      Reap_Build (Anim);

      if not Anim.Pending_Live then
         return;
      end if;

      --  Already drawable at the wanted extent.
      if Anim.Worker = null
        and then Anim.Active /= null
        and then Anim.Active.Width = Anim.Pending_W
        and then Anim.Active.Height = Anim.Pending_H
      then
         Anim.Pending_Live := False;
         return;
      end if;

      if Anim.Worker /= null then
         --  A build is in flight. If it is heading somewhere nobody wants
         --  any more, tell it to stop; the replacement starts when it has
         --  ended, so a rapid resize coalesces to its final extent rather
         --  than leaving a worker behind for every size it passed.
         if not Anim.Build_Superseded
           and then Anim.Building /= null
           and then (Anim.Building.Width /= Anim.Pending_W
                     or else Anim.Building.Height /= Anim.Pending_H)
         then
            Anim.Build_Superseded := True;
            if Anim.Build_State /= null then
               Anim.Build_State.Signal_Stop;
            end if;
         end if;
         return;
      end if;

      --  The first set is wanted immediately: there is nothing to draw
      --  until it exists, so waiting for the extent to settle would leave
      --  the animation blank for no benefit.
      if Anim.Active = null
        or else Adi.Clock.To_Duration (Adi.Clock.Now - Anim.Pending_Since)
                  >= Settle_Time
      then
         Start_Build (Anim);
         Anim.Pending_Live := False;
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

      --  Already drawable at this extent, with no build heading elsewhere.
      if Anim.Active /= null
        and then Anim.Active.Width = Pixel_Width
        and then Anim.Active.Height = Pixel_Height
        and then Anim.Worker = null
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
   function Is_Prepared (Anim : RLottie_Animation) return Boolean is
     (Anim.Active /= null);

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

   function Get_Preloaded_Frame_Count (Anim : RLottie_Animation) return Natural is
   begin
      --  Progress of the build in flight; a published set is complete by
      --  definition and reports its own frame count.
      if Anim.Build_State /= null then
         return Anim.Build_State.Ready_Count;
      elsif Anim.Active /= null then
         return Anim.Active.Frame_Count;
      end if;
      return 0;
   end Get_Preloaded_Frame_Count;

   function Is_Preload_Complete (Anim : RLottie_Animation) return Boolean is
   begin
      return Anim.Active /= null and then Anim.Worker = null;
   end Is_Preload_Complete;

   procedure Set_Preload_Threshold
     (Anim             : in out RLottie_Animation;
      Min_Ready_Frames : Natural)
   is
   begin
      Anim.Min_Ready_Frames := Min_Ready_Frames;
   end Set_Preload_Threshold;

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
      Ready : Natural := 0;
      Done  : Boolean := False;
   begin
      Anim.Elapsed_S := 0.0;
      Anim.Current_Frame := 0;

      --  A published set is complete, so the first frame is there if
      --  anything is.
      if Anim.Active /= null then
         if Ensure_Frame_Image (Anim, 1) then
            Anim.Current_Frame := 1;
         end if;
      end if;
   end Reset;

   function Advance
     (Anim : in out RLottie_Animation;
      DT   : Duration) return Boolean
   is
      Target : Natural;
      Ready  : Natural := 0;
      Done   : Boolean := False;
   begin
      if not Is_Valid (Anim) then
         return False;
      end if;

      --  The frame loop is where a settled extent turns into a build and
      --  a finished build turns into what is drawn.
      Service_Pending (Anim);

      if Anim.Active = null then
         return False;
      end if;

      --  Whatever is published is whole.
      Ready := Anim.Active.Frame_Count;
      Done := True;

      Target := Resolve_Target_Frame (Anim, DT);
      if Target = 0 or else Target = Anim.Current_Frame then
         return False;
      end if;

      if Target > Ready and then not Done then
         return False;
      end if;

      if Done and then Target > Anim.Frame_Count then
         return False;
      end if;

      if not Ensure_Frame_Image (Anim, Target) then
         return False;
      end if;

      Anim.Current_Frame := Target;
      return True;
   end Advance;

   procedure Destroy (Anim : in out RLottie_Animation) is
   begin
      --  A worker renders from the model and writes into its set, so both
      --  have to outlive it. Establishing that is what this waits for --
      --  at most the render already in progress, and event-driven rather
      --  than a sleep chosen in the hope it is long enough.
      if Anim.Worker /= null then
         if Anim.Build_State /= null then
            Anim.Build_State.Signal_Stop;
            Anim.Build_State.Wait_Done;
         end if;

         --  Done is raised inside the task body, so termination follows
         --  it rather than coinciding with it. Reclaiming the task object
         --  needs the latter, which by here is immediate.
         while not Anim.Worker.all'Terminated loop
            delay 0.0;
         end loop;

         Free_Worker (Anim.Worker);
         Anim.Worker := null;
      end if;

      if Anim.Build_State /= null then
         Free_State (Anim.Build_State);
      end if;

      Destroy_Set (Anim.Building);
      Destroy_Set (Anim.Active);

      --  Only now: nothing is rendering from it any more.
      if Anim.Handle /= System.Null_Address then
         Animation_Destroy (To_Ptr (Anim.Handle));
         Anim.Handle := System.Null_Address;
      end if;

      Anim.Frame_Count := 0;
      Anim.Current_Frame := 0;
      Anim.Pending_Live := False;
      Anim.Build_Superseded := False;
   end Destroy;

end Adi.RLottie;
