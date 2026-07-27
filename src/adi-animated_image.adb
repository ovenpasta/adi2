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
     (Raw_Anim : IMG_Animation_Access;
      Label    : String) return Animated_Image_Access;

   function Load_From_File (Path : String) return Animated_Image_Access
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
         return null;
      end if;

      return Build_From_Raw (Raw_Anim, Path);
   end Load_From_File;

   function Build_From_Raw
     (Raw_Anim : IMG_Animation_Access;
      Label    : String) return Animated_Image_Access
   is
      Result      : Animated_Image_Access := null;
      Frame_Count : Natural;
      Delay_Base  : System.Address := System.Null_Address;
   begin
      Frame_Count :=
        (if Raw_Anim.count > 0 then Natural (Raw_Anim.count) else 0);
      if Frame_Count = 0 then
         IMG_FreeAnimation (Raw_Anim);
         Adi.Log.Error ("Animated image has no frames: " & Label);
         return null;
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

            Dup := SDL_Surface_Ptr (SDL_DuplicateSurface (Surface));
            if Dup = null then
               goto Next_Frame;
            end if;

            Img := Create_From_Surface (Dup);
            if Img = null then
               SDL_DestroySurface (Dup);
               goto Next_Frame;
            end if;

            if Delay_Base /= System.Null_Address then
               Frame_Delay := Read_Delay_At (Delay_Base, I);
            end if;

            Result.Frames.Append
              (Frame_Info'(Image => Img, Delay_MS => Frame_Delay));

            <<Next_Frame>>
            null;
         end;
      end loop;

      IMG_FreeAnimation (Raw_Anim);

      if Result.Frames.Is_Empty then
         Adi.Log.Error
           ("Failed to create any animation frame surfaces: " & Label);
         Free_Animated (Result);
         return null;
      end if;

      if Result.Width <= 0.0 or else Result.Height <= 0.0 then
         Get_Size (Result.Frames.First_Element.Image.all,
                   Result.Width, Result.Height);
      end if;

      Result.Current_Frame := 1;
      Result.Elapsed_MS := 0.0;
      Result.Playing := True;
      Result.Looping := True;
      return Result;
   end Build_From_Raw;

   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count)
      return Animated_Image_Access
   is
      Stream   : SDL_IOStream_Ptr;
      Raw_Anim : IMG_Animation_Access;
   begin
      if Data = System.Null_Address or else Length = 0 then
         return null;
      end if;

      Stream := SDL_IOFromConstMem (Data, size_t (Length));
      if Stream = null then
         Adi.Log.Error ("Failed to create IO stream for animated image");
         return null;
      end if;

      Raw_Anim := IMG_LoadAnimation_IO (Stream, True);
      if Raw_Anim = null then
         Adi.Log.Error ("Failed to load animated image from memory");
         return null;
      end if;

      return Build_From_Raw (Raw_Anim, "(memory)");
   end Load_From_Memory;

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
      if Anim.Frames.Is_Empty then
         Anim.Current_Frame := 0;
      else
         Anim.Current_Frame := 1;
      end if;
      Anim.Elapsed_MS := 0.0;
   end Reset;

   function Advance
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
   end Advance;

   procedure Destroy (Anim : in out Animated_Image) is
   begin
      if not Anim.Frames.Is_Empty then
         for F of Anim.Frames loop
            if F.Image /= null then
               declare
                  Img : Image_Access := F.Image;
               begin
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

end Adi.Animated_Image;
