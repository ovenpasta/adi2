--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Interfaces.C;         use Interfaces.C;
with Interfaces.C.Strings;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with Adi.Log;
with Adi.SDL;         use Adi.SDL;
with Adi.SDL.IO;      use Adi.SDL.IO;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SDL.Image;   use Adi.SDL.Image;

package body Adi.Animated_Image is
   use type System.Address;

   procedure Free_Animated is new Ada.Unchecked_Deallocation
     (Object => Animated_Image'Class,
      Name   => Animated_Image_Access);


   type Surface_Ptr_Ref is access all SDL_Surface_Ptr;
   function To_Surface_Ptr_Ref is new Ada.Unchecked_Conversion
     (System.Address, Surface_Ptr_Ref);

   type Int_Ref is access all int;
   function To_Int_Ref is new Ada.Unchecked_Conversion
     (System.Address, Int_Ref);

   Surface_Ptr_Bytes : constant Storage_Offset :=
     Storage_Offset (SDL_Surface_Ptr'Size / System.Storage_Unit);
   Int_Bytes : constant Storage_Offset :=
     Storage_Offset (int'Size / System.Storage_Unit);

   function Read_Surface_At
     (Base  : System.Address;
      Index : Natural) return SDL_Surface_Ptr;

   function Read_Delay_At
     (Base  : System.Address;
      Index : Natural) return Natural;

   function Read_Surface_At
     (Base  : System.Address;
      Index : Natural) return SDL_Surface_Ptr
   is
      Ptr_Addr : constant System.Address :=
        Base + Storage_Offset (Index) * Surface_Ptr_Bytes;
      Ptr_Ref  : constant Surface_Ptr_Ref := To_Surface_Ptr_Ref (Ptr_Addr);
   begin
      if Ptr_Ref = null then
         return null;
      end if;

      return Ptr_Ref.all;
   end Read_Surface_At;

   function Read_Delay_At
     (Base  : System.Address;
      Index : Natural) return Natural
   is
      Delay_Addr : constant System.Address :=
        Base + Storage_Offset (Index) * Int_Bytes;
      Delay_Ref  : constant Int_Ref := To_Int_Ref (Delay_Addr);
      Delay_MS   : int;
   begin
      if Delay_Ref = null then
         return 100;
      end if;

      Delay_MS := Delay_Ref.all;
      if Delay_MS <= 0 then
         return 100;
      else
         return Natural (Delay_MS);
      end if;
   end Read_Delay_At;

   function Build_From_Raw
     (Raw_Anim : in out IMG_Animation_Access;
      Label    : String) return Animation_Handle;

   function Advance_By
     (Anim : in out Animated_Image;
      DT   : Duration) return Boolean;

   function Load_From_File (Path : String) return Animation_Handle
   is
      use Interfaces.C.Strings;

      C_Path   : chars_ptr;
      Raw_Anim : IMG_Animation_Access;
   begin
      C_Path := New_String (Path);
      Raw_Anim := IMG_LoadAnimation (C_Path);
      Free (C_Path);

      if Raw_Anim = null then
         Adi.Log.Error ("Failed to load animated image: " & Path);
         return Null_Animation_Handle;
      end if;

      return Build_From_Raw (Raw_Anim, Path);
   end Load_From_File;

   function Build_From_Raw
     (Raw_Anim : in out IMG_Animation_Access;
      Label    : String) return Animation_Handle
   is
      Result      : Animated_Image_Access := null;
      Frame_Count : Natural;
      Delay_Base  : System.Address := System.Null_Address;

      --  Nulls as it frees, so a later failure cannot free it twice.
      procedure Discard_Raw is
      begin
         if Raw_Anim /= null then
            IMG_FreeAnimation (Raw_Anim);
            Raw_Anim := null;
         end if;
      end Discard_Raw;

      --  Whatever frames were built go with the record, textures and all.
      procedure Reclaim (A : in out Animated_Image_Access) is
      begin
         if A /= null then
            Destroy (A.all);
            Free_Animated (A);
         end if;
      end Reclaim;
   begin
      Frame_Count :=
        (if Raw_Anim.count > 0 then Natural (Raw_Anim.count) else 0);
      if Frame_Count = 0 then
         Discard_Raw;
         Adi.Log.Error ("Animated image has no frames: " & Label);
         return Null_Animation_Handle;
      end if;

      Result := new Animated_Image;
      Result.Width := Pixel_Type (Raw_Anim.w);
      Result.Height := Pixel_Type (Raw_Anim.h);

      if Raw_Anim.delays /= null then
         Delay_Base := Raw_Anim.delays.all'Address;
      end if;

      for I in 0 .. Frame_Count - 1 loop
         declare
            Surface : constant SDL_Surface_Ptr :=
              Read_Surface_At (Raw_Anim.frames, I);
            Dup         : SDL_Surface_Ptr;
            Frame_Delay : Natural := 100;
            Img         : Image_Access;
         begin
            if Surface = null then
               goto Next_Frame;
            end if;

            --  Read before the duplication, so nothing is owned yet
            --  when it runs.
            if Delay_Base /= System.Null_Address then
               Frame_Delay := Read_Delay_At (Delay_Base, I);
            end if;

            Dup := SDL_Surface_Ptr (SDL_DuplicateSurface (Surface));
            if Dup = null then
               goto Next_Frame;
            end if;

            --  From here the surface, and then the image, belong to this
            --  iteration until the vector takes them. A failure in
            --  between would otherwise strand whichever exists: the
            --  surface is not yet an image, and the image is not yet
            --  anywhere Reclaim looks.
            begin
               Img := Create_From_Surface
                 (Dup, Group => Result.Group'Unchecked_Access);

               if Img = null then
                  SDL_DestroySurface (Dup);
                  Dup := null;
                  goto Next_Frame;
               end if;

               --  The image owns the surface now.
               Dup := null;

               Result.Frames.Append
                 (Frame_Info'(Image => Img, Delay_MS => Frame_Delay));

               --  And the vector owns the image.
               Img := null;
            exception
               when others =>
                  if Img /= null then
                     Adi.Image.Free (Img);
                  elsif Dup /= null then
                     SDL_DestroySurface (Dup);
                  end if;
                  raise;
            end;

            <<Next_Frame>>
            null;
         end;
      end loop;

      Discard_Raw;

      if Result.Frames.Is_Empty then
         Adi.Log.Error
           ("Failed to create any animation frame surfaces: " & Label);
         Reclaim (Result);
         return Null_Animation_Handle;
      end if;

      if Result.Width <= 0.0 or else Result.Height <= 0.0 then
         Get_Size (Result.Frames.First_Element.Image.all,
                   Result.Width, Result.Height);
      end if;

      Result.Current_Frame := 1;
      Result.Elapsed_MS := 0.0;
      Result.Playing := True;
      Result.Looping := True;
      return (Id => Animation_Stores.Register (Result));

   exception
      --  The decoder's animation is the C library's and nothing else
      --  will reclaim it; the frames built so far are this package's.
      --  Both go, and then it propagates: a file that will not decode is
      --  answered with a null handle above, so anything reaching here is
      --  exhaustion or a defect.
      when others =>
         Reclaim (Result);
         Discard_Raw;
         raise;
   end Build_From_Raw;

   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count)
      return Animation_Handle
   is
      Stream   : SDL_IOStream_Ptr;
      Raw_Anim : IMG_Animation_Access;
   begin
      if Data = System.Null_Address or else Length = 0 then
         return Null_Animation_Handle;
      end if;

      Stream := SDL_IOFromConstMem (Data, size_t (Length));
      if Stream = null then
         Adi.Log.Error ("Failed to create IO stream for animated image");
         return Null_Animation_Handle;
      end if;

      Raw_Anim := IMG_LoadAnimation_IO (Stream, True);
      if Raw_Anim = null then
         Adi.Log.Error ("Failed to load animated image from memory");
         return Null_Animation_Handle;
      end if;

      return Build_From_Raw (Raw_Anim, "(memory)");
   end Load_From_Memory;

   function Advance
     (Anim : in out Animated_Image; DT : Duration) return Boolean is
   begin
      --  Stepping by hand moves the timeline without the sampled clock
      --  knowing, so the next sample must anchor rather than charge for
      --  the step just given and the time since.
      Adi.Playback_Clock.Reanchor (Anim.Clock);
      return Advance_By (Anim, DT);
   end Advance;

   function Advance_At
     (Anim   : in out Animated_Image;
      Sample : Adi.Clock.Time) return Boolean
   is
      Tick : Adi.Playback_Clock.Sample_Result;
   begin
      Tick := Adi.Playback_Clock.Sample (Anim.Clock, Sample);

      case Tick.Kind is
         when Adi.Playback_Clock.Ignored =>
            return False;

         when Adi.Playback_Clock.Anchored =>
            --  Nothing to charge, and a frame is already showing: the
            --  first is selected at load rather than on first advance.
            return False;

         when Adi.Playback_Clock.Elapsed =>
            --  Sampled before this, so a pause is consumed as it passes
            --  rather than delivered in one leap on resume.
            if not Anim.Playing then
               return False;
            end if;
            return Advance_By (Anim, Tick.Span);
      end case;
   end Advance_At;

   function Is_Valid (Anim : Animated_Image) return Boolean is
   begin
      return not Anim.Frames.Is_Empty;
   end Is_Valid;

   procedure Get_Size
     (Anim   : Animated_Image;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
   begin
      Width := Anim.Width;
      Height := Anim.Height;
   end Get_Size;

   function Get_Frame_Count (Anim : Animated_Image) return Natural is
   begin
      return Natural (Anim.Frames.Length);
   end Get_Frame_Count;

   function Get_Current_Frame_Index (Anim : Animated_Image) return Natural is
   begin
      if Anim.Frames.Is_Empty then
         return 0;
      end if;

      return Anim.Current_Frame;
   end Get_Current_Frame_Index;

   function Get_Current_Image (Anim : Animated_Image) return Image_Access is
   begin
      if Anim.Frames.Is_Empty then
         return null;
      end if;

      if Anim.Current_Frame = 0
        or else Anim.Current_Frame > Natural (Anim.Frames.Length)
      then
         return null;
      end if;

      return Anim.Frames.Element (Positive (Anim.Current_Frame)).Image;
   end Get_Current_Image;

   procedure Start (Anim : in out Animated_Image) is
   begin
      --  Resuming re-anchors, so the pause is not charged as elapsed.
      Adi.Playback_Clock.Reanchor (Anim.Clock);
      if not Anim.Frames.Is_Empty then
         Anim.Playing := True;
      end if;
   end Start;

   procedure Stop (Anim : in out Animated_Image) is
   begin
      Anim.Playing := False;
   end Stop;

   function Is_Playing (Anim : Animated_Image) return Boolean is
   begin
      return Anim.Playing and then not Anim.Frames.Is_Empty;
   end Is_Playing;

   procedure Set_Looping (Anim : in out Animated_Image; Value : Boolean := True) is
   begin
      Anim.Looping := Value;
   end Set_Looping;

   function Is_Looping (Anim : Animated_Image) return Boolean is
   begin
      return Anim.Looping;
   end Is_Looping;

   procedure Reset (Anim : in out Animated_Image) is
   begin
      Adi.Playback_Clock.Reanchor (Anim.Clock);
      if Anim.Frames.Is_Empty then
         Anim.Current_Frame := 0;
      else
         Anim.Current_Frame := 1;
      end if;
      Anim.Elapsed_MS := 0.0;
   end Reset;

   --  The stepping itself. Both ways in share it; what differs is what
   --  they do to the sampled anchor.
   function Advance_By
     (Anim : in out Animated_Image;
      DT   : Duration) return Boolean
   is
      Changed : Boolean := False;
      Last    : constant Natural := Natural (Anim.Frames.Length);
      Frame_Delay : Natural;
   begin
      if Last = 0 or else not Anim.Playing then
         return False;
      end if;

      if Anim.Current_Frame = 0 or else Anim.Current_Frame > Last then
         Anim.Current_Frame := 1;
         Anim.Elapsed_MS := 0.0;
      end if;

      Anim.Elapsed_MS := Anim.Elapsed_MS + Float (DT) * 1_000.0;

      loop
         Frame_Delay :=
           Anim.Frames.Element (Positive (Anim.Current_Frame)).Delay_MS;
         exit when Anim.Elapsed_MS < Float (Frame_Delay);

         Anim.Elapsed_MS := Anim.Elapsed_MS - Float (Frame_Delay);

         if Anim.Current_Frame = Last then
            if Anim.Looping then
               Anim.Current_Frame := 1;
               Changed := True;
            else
               Anim.Playing := False;
               Anim.Elapsed_MS := 0.0;
               exit;
            end if;
         else
            Anim.Current_Frame := Anim.Current_Frame + 1;
            Changed := True;
         end if;
      end loop;

      return Changed;
   end Advance_By;

   procedure Destroy (Anim : in out Animated_Image) is
   begin
      --  Before the frames, and explicitly: the textures made from them
      --  live in renderers, and releasing the group is what takes them
      --  out of each one. Finalisation would do it eventually, but only
      --  after these images were already gone.
      Adi.Texture_Cache.Release (Anim.Group);

      if not Anim.Frames.Is_Empty then
         for F of Anim.Frames loop
            if F.Image /= null then
               declare
                  Img : Image_Access := F.Image;
               begin
                  --  Cleared before the free, so a teardown interrupted
                  --  part way can be run again without freeing twice.
                  F.Image := null;
                  Adi.Image.Free (Img);
               end;
            end if;
         end loop;
         Anim.Frames.Clear;
      end if;

      Anim.Width := 0.0;
      Anim.Height := 0.0;
      Anim.Current_Frame := 0;
      Anim.Elapsed_MS := 0.0;
      Anim.Playing := False;
   end Destroy;

   ---------------------------------------------------------------------------
   --  Handles
   ---------------------------------------------------------------------------

   --  Checked rather than fetched: the store is strict by default and
   --  raises on a stale id, while a stale handle here is an ordinary
   --  thing to be told about.
   function Resolve (H : Animation_Handle) return Animated_Image_Access
   is (if Animation_Stores.Is_Valid (H.Id)
       then Animation_Stores.Get (H.Id)
       else null);

   function Is_Valid (H : Animation_Handle) return Boolean is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return A /= null and then Is_Valid (A.all);
   end Is_Valid;

   procedure Get_Size
     (H      : Animation_Handle;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      if A = null then
         Width := 0.0;
         Height := 0.0;
         return;
      end if;
      Get_Size (A.all, Width, Height);
   end Get_Size;

   function Get_Frame_Count (H : Animation_Handle) return Natural is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return (if A = null then 0 else Get_Frame_Count (A.all));
   end Get_Frame_Count;

   function Get_Current_Frame_Index
     (H : Animation_Handle) return Natural
   is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return (if A = null then 0 else Get_Current_Frame_Index (A.all));
   end Get_Current_Frame_Index;

   function Get_Current_Image
     (H : Animation_Handle) return Image_Access
   is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return (if A = null then null else Get_Current_Image (A.all));
   end Get_Current_Image;

   procedure Start (H : Animation_Handle) is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      if A /= null then
         Start (A.all);
      end if;
   end Start;

   procedure Stop (H : Animation_Handle) is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      if A /= null then
         Stop (A.all);
      end if;
   end Stop;

   function Is_Playing (H : Animation_Handle) return Boolean is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return A /= null and then Is_Playing (A.all);
   end Is_Playing;

   procedure Set_Looping
     (H : Animation_Handle; Value : Boolean := True)
   is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      if A /= null then
         Set_Looping (A.all, Value);
      end if;
   end Set_Looping;

   function Is_Looping (H : Animation_Handle) return Boolean is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return A /= null and then Is_Looping (A.all);
   end Is_Looping;

   procedure Reset (H : Animation_Handle) is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      if A /= null then
         Reset (A.all);
      end if;
   end Reset;

   function Advance
     (H : Animation_Handle; DT : Duration) return Boolean
   is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return A /= null and then Advance (A.all, DT);
   end Advance;

   function Advance_At
     (H      : Animation_Handle;
      Sample : Adi.Clock.Time) return Boolean
   is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      return A /= null and then Advance_At (A.all, Sample);
   end Advance_At;

   procedure Destroy (H : in out Animation_Handle) is
      A : constant Animated_Image_Access := Resolve (H);
   begin
      if A /= null then
         Destroy (A.all);
         Animation_Stores.Request_Destroy (H.Id);
      end if;
      H := Null_Animation_Handle;
   end Destroy;

end Adi.Animated_Image;
