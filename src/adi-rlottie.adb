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
      for I in 1 .. Frame_Count loop
         exit when State.Stop_Requested;

         Surf := Surfaces (I);
         if Surf /= null and then Surf.pixels /= System.Null_Address then
            Buf := To_U32_Ptr (Surf.pixels);
            if Buf /= null then
               Animation_Render
                 (Animation      => To_Ptr (Animation.all),
                  Frame_Num      => Interfaces.C.size_t (I - 1),
                  Buffer         => Buf,
                  Width          => Interfaces.C.size_t (Width),
                  Height         => Interfaces.C.size_t (Height),
                  Bytes_Per_Line => Interfaces.C.size_t (Surf.pitch));
            end if;
         end if;

         State.Set_Ready_Count (I);
      end loop;

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
      if Anim.Frame_Images = null
        or else Frame > Anim.Frame_Images'Last
      then
         return False;
      end if;

      if Anim.Frame_Images (Frame) /= null then
         return True;
      end if;

      if Anim.Frame_Surfaces = null
        or else Frame > Anim.Frame_Surfaces'Last
        or else Anim.Frame_Surfaces (Frame) = null
      then
         return False;
      end if;

      Img := Create_From_Surface (Anim.Frame_Surfaces (Frame));
      if Img = null then
         return False;
      end if;

      Anim.Frame_Images (Frame) := Img;
      Anim.Frame_Surfaces (Frame) := null;
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
      Surf     : SDL_Surface_Ptr;
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

      Result.Frame_Surfaces := new Surface_Array (1 .. Natural (Count));
      for I in Result.Frame_Surfaces'Range loop
         Surf :=
           SDL_Surface_Ptr
             (SDL_CreateSurface
                (width  => Interfaces.C.int (Width_N),
                 height => Interfaces.C.int (Height_N),
                 format => SDL_PIXELFORMAT_ARGB8888));
         if Surf = null then
            Adi.Log.Error ("Failed to allocate rlottie surface frame "
                           & Natural'Image (I));
            Destroy (Result.all);
            Free_RLottie (Result);
            return null;
         end if;
         Result.Frame_Surfaces (I) := Surf;
      end loop;

      Result.Frame_Images := new Image_Array (1 .. Natural (Count));
      for I in Result.Frame_Images'Range loop
         Result.Frame_Images (I) := null;
      end loop;

      Result.State := new Preload_State;
      Result.Worker := new Preload_Task
        (Animation   => Result.Handle'Unchecked_Access,
         Surfaces    => Result.Frame_Surfaces,
         Width       => Positive (Width_N),
         Height      => Positive (Height_N),
         Frame_Count => Positive (Natural (Count)),
         State       => Result.State);

      return Result;
   end Load_From_File;

   function Is_Valid (Anim : RLottie_Animation) return Boolean is
   begin
      return Anim.Handle /= System.Null_Address
        and then Anim.Frame_Images /= null;
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
      if Anim.State = null then
         return 0;
      end if;
      return Anim.State.Ready_Count;
   end Get_Preloaded_Frame_Count;

   function Is_Preload_Complete (Anim : RLottie_Animation) return Boolean is
   begin
      if Anim.State = null then
         return False;
      end if;
      return Anim.State.Done;
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
      if Anim.Frame_Images = null
        or else Anim.Current_Frame = 0
        or else Anim.Current_Frame > Anim.Frame_Images'Last
      then
         return null;
      end if;
      return Anim.Frame_Images (Anim.Current_Frame);
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

      if Anim.State /= null then
         Ready := Anim.State.Ready_Count;
         Done := Anim.State.Done;
      end if;

      if Ready >= 1 or else Done then
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

      if Anim.State /= null then
         Ready := Anim.State.Ready_Count;
         Done := Anim.State.Done;
      end if;

      if not Done and then Ready < Anim.Min_Ready_Frames then
         return False;
      end if;

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
      --  Stop worker first — it touches Frame_Surfaces
      if Anim.State /= null then
         Anim.State.Signal_Stop;
      end if;

      if Anim.Worker /= null then
         delay 0.01;
         declare
            W : Preload_Task_Access := Anim.Worker;
         begin
            Free_Worker (W);
            Anim.Worker := null;
         end;
      end if;

      if Anim.Handle /= System.Null_Address then
         Animation_Destroy (To_Ptr (Anim.Handle));
         Anim.Handle := System.Null_Address;
      end if;

      --  Free Images (which own their surfaces via Create_From_Surface)
      if Anim.Frame_Images /= null then
         for I in Anim.Frame_Images'Range loop
            if Anim.Frame_Images (I) /= null then
               Adi.Image.Free (Anim.Frame_Images (I));
            end if;
         end loop;
         declare
            Arr : Image_Array_Access := Anim.Frame_Images;
         begin
            Free_Images (Arr);
            Anim.Frame_Images := null;
         end;
      end if;

      --  Free remaining surfaces (for frames not yet converted to Images)
      if Anim.Frame_Surfaces /= null then
         for I in Anim.Frame_Surfaces'Range loop
            if Anim.Frame_Surfaces (I) /= null then
               SDL_DestroySurface (Anim.Frame_Surfaces (I));
               Anim.Frame_Surfaces (I) := null;
            end if;
         end loop;
         declare
            S : Surface_Array_Access := Anim.Frame_Surfaces;
         begin
            Free_Surfaces (S);
            Anim.Frame_Surfaces := null;
         end;
      end if;

      if Anim.State /= null then
         declare
            S : Preload_State_Access := Anim.State;
         begin
            Free_State (S);
            Anim.State := null;
         end;
      end if;

      Anim.Width := 0.0;
      Anim.Height := 0.0;
      Anim.Buffer_Width := 0;
      Anim.Buffer_Height := 0;
      Anim.Frame_Count := 0;
      Anim.Frame_Rate := 0.0;
      Anim.Duration_S := 0.0;
      Anim.Current_Frame := 0;
      Anim.Elapsed_S := 0.0;
      Anim.Playing := False;
   end Destroy;

end Adi.RLottie;
