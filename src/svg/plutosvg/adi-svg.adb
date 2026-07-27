--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Interfaces;
with Interfaces.C;
with Interfaces.C.Strings;
with System;
with System.Address_To_Access_Conversions;
with System.Storage_Elements;

package body Adi.SVG is

   use type Interfaces.C.int;
   use type Interfaces.C.Strings.chars_ptr;
   use type Interfaces.Unsigned_32;
   use type System.Address;

   procedure Free_String is new Ada.Unchecked_Deallocation (String, String_Access);
   procedure Free_Pixel_Buffer is
     new Ada.Unchecked_Deallocation (Pixel_Buffer, Pixel_Buffer_Access);

   type Plutosvg_Document is limited null record;
   pragma Convention (C, Plutosvg_Document);
   type Plutosvg_Document_Ptr is access all Plutosvg_Document;

   type Plutovg_Surface is limited null record;
   pragma Convention (C, Plutovg_Surface);
   type Plutovg_Surface_Ptr is access all Plutovg_Surface;

   function To_Address is new Ada.Unchecked_Conversion
     (Source => Plutosvg_Document_Ptr,
      Target => System.Address);

   function To_Document_Ptr is new Ada.Unchecked_Conversion
     (Source => System.Address,
      Target => Plutosvg_Document_Ptr);

   function Document_Load_From_File
     (Filename : Interfaces.C.Strings.chars_ptr;
      Width    : Interfaces.C.C_float;
      Height   : Interfaces.C.C_float) return Plutosvg_Document_Ptr
      with Import,
           Convention    => C,
           External_Name => "plutosvg_document_load_from_file";

   function Document_Load_From_Data
     (Data         : System.Address;
      Length       : Interfaces.C.int;
      Width        : Interfaces.C.C_float;
      Height       : Interfaces.C.C_float;
      Destroy_Func : System.Address;
      Closure      : System.Address) return Plutosvg_Document_Ptr
      with Import,
           Convention    => C,
           External_Name => "plutosvg_document_load_from_data";

   function Document_Get_Width
     (Document : Plutosvg_Document_Ptr) return Interfaces.C.C_float
      with Import,
           Convention    => C,
           External_Name => "plutosvg_document_get_width";

   function Document_Get_Height
     (Document : Plutosvg_Document_Ptr) return Interfaces.C.C_float
      with Import,
           Convention    => C,
           External_Name => "plutosvg_document_get_height";

   function Document_Render_To_Surface
     (Document      : Plutosvg_Document_Ptr;
      Id            : Interfaces.C.Strings.chars_ptr;
      Width         : Interfaces.C.int;
      Height        : Interfaces.C.int;
      Current_Color : System.Address;
      Palette_Func  : System.Address;
      Closure       : System.Address) return Plutovg_Surface_Ptr
      with Import,
           Convention    => C,
           External_Name => "plutosvg_document_render_to_surface";

   procedure Document_Destroy (Document : Plutosvg_Document_Ptr)
      with Import,
           Convention    => C,
           External_Name => "plutosvg_document_destroy";

   function Surface_Get_Data
     (Surface : Plutovg_Surface_Ptr) return System.Address
      with Import,
           Convention    => C,
           External_Name => "plutovg_surface_get_data";

   function Surface_Get_Width
     (Surface : Plutovg_Surface_Ptr) return Interfaces.C.int
      with Import,
           Convention    => C,
           External_Name => "plutovg_surface_get_width";

   function Surface_Get_Height
     (Surface : Plutovg_Surface_Ptr) return Interfaces.C.int
      with Import,
           Convention    => C,
           External_Name => "plutovg_surface_get_height";

   function Surface_Get_Stride
     (Surface : Plutovg_Surface_Ptr) return Interfaces.C.int
      with Import,
           Convention    => C,
           External_Name => "plutovg_surface_get_stride";

   procedure Surface_Destroy (Surface : Plutovg_Surface_Ptr)
      with Import,
           Convention    => C,
           External_Name => "plutovg_surface_destroy";

   package U32_Conv is
     new System.Address_To_Access_Conversions (Interfaces.Unsigned_32);

   function Clamp_Byte (V : Integer) return Interfaces.Unsigned_32 is
      C : Integer := V;
   begin
      if C < 0 then
         C := 0;
      elsif C > 255 then
         C := 255;
      end if;
      return Interfaces.Unsigned_32 (C);
   end Clamp_Byte;

   function Pack_ARGB
     (A, R, G, B : Integer) return Uint32
   is
      AU : constant Interfaces.Unsigned_32 := Clamp_Byte (A);
      RU : constant Interfaces.Unsigned_32 := Clamp_Byte (R);
      GU : constant Interfaces.Unsigned_32 := Clamp_Byte (G);
      BU : constant Interfaces.Unsigned_32 := Clamp_Byte (B);
   begin
      return Uint32
        (Interfaces.Shift_Left (AU, 24)
         or Interfaces.Shift_Left (RU, 16)
         or Interfaces.Shift_Left (GU, 8)
         or BU);
   end Pack_ARGB;

   function Is_Valid (Doc : Document) return Boolean is
   begin
      return Doc.Valid and then Doc.Handle /= System.Null_Address;
   end Is_Valid;

   procedure Get_Size
     (Doc    : Document;
      Width  : out Pixel_Type;
      Height : out Pixel_Type)
   is
   begin
      Width := Doc.Width;
      Height := Doc.Height;
   end Get_Size;

   function Load_From_File (Path : String) return Document_Access is
      Doc    : Document_Access := new Document;
      C_Path : Interfaces.C.Strings.chars_ptr := Interfaces.C.Strings.Null_Ptr;
      Handle : Plutosvg_Document_Ptr;
   begin
      C_Path := Interfaces.C.Strings.New_String (Path);
      Handle :=
        Document_Load_From_File
          (Filename => C_Path,
           Width    => Interfaces.C.C_float (-1.0),
           Height   => Interfaces.C.C_float (-1.0));
      Interfaces.C.Strings.Free (C_Path);

      if Handle = null then
         return Doc;
      end if;

      Doc.Handle := To_Address (Handle);
      Doc.Width := Pixel_Type (Document_Get_Width (Handle));
      Doc.Height := Pixel_Type (Document_Get_Height (Handle));
      Doc.Valid := True;

      return Doc;
   exception
      when others =>
         if C_Path /= Interfaces.C.Strings.Null_Ptr then
            Interfaces.C.Strings.Free (C_Path);
         end if;
         return Doc;
   end Load_From_File;

   function Load_From_String (Source : String) return Document_Access is
      Doc    : Document_Access := new Document;
      Handle : Plutosvg_Document_Ptr := null;
   begin
      if Source'Length = 0 then
         return Doc;
      end if;

      Doc.Source := new String'(Source);
      Handle :=
        Document_Load_From_Data
          (Data         => Doc.Source (Doc.Source'First)'Address,
           Length       => Interfaces.C.int (Source'Length),
           Width        => Interfaces.C.C_float (-1.0),
           Height       => Interfaces.C.C_float (-1.0),
           Destroy_Func => System.Null_Address,
           Closure      => System.Null_Address);

      if Handle = null then
         Free_String (Doc.Source);
         return Doc;
      end if;

      Doc.Handle := To_Address (Handle);
      Doc.Width := Pixel_Type (Document_Get_Width (Handle));
      Doc.Height := Pixel_Type (Document_Get_Height (Handle));
      Doc.Valid := True;

      return Doc;
   exception
      when others =>
         if Handle /= null then
            Document_Destroy (Handle);
         end if;
         if Doc.Source /= null then
            Free_String (Doc.Source);
         end if;
         return Doc;
   end Load_From_String;

   function Render_ARGB32
     (Doc    : Document;
      Width  : Positive;
      Height : Positive) return Pixel_Buffer_Access
   is
      use System.Storage_Elements;

      Handle : constant Plutosvg_Document_Ptr := To_Document_Ptr (Doc.Handle);
      Surface : Plutovg_Surface_Ptr := null;
      Pixels  : Pixel_Buffer_Access := null;

      Data_Addr : System.Address;
      Surf_W    : Interfaces.C.int;
      Surf_H    : Interfaces.C.int;
      Stride    : Interfaces.C.int;
   begin
      if not Is_Valid (Doc) or else Handle = null then
         return null;
      end if;

      Surface :=
        Document_Render_To_Surface
          (Document      => Handle,
           Id            => Interfaces.C.Strings.Null_Ptr,
           Width         => Interfaces.C.int (Width),
           Height        => Interfaces.C.int (Height),
           Current_Color => System.Null_Address,
           Palette_Func  => System.Null_Address,
           Closure       => System.Null_Address);

      if Surface = null then
         return null;
      end if;

      Surf_W := Surface_Get_Width (Surface);
      Surf_H := Surface_Get_Height (Surface);
      Stride := Surface_Get_Stride (Surface);
      Data_Addr := Surface_Get_Data (Surface);

      if Surf_W <= 0 or else Surf_H <= 0 or else Stride <= 0 or else Data_Addr = System.Null_Address then
         Surface_Destroy (Surface);
         return null;
      end if;

      declare
         W_N      : constant Positive := Positive (Integer (Surf_W));
         H_N      : constant Positive := Positive (Integer (Surf_H));
         Stride_N : constant Natural := Natural (Stride);
      begin
         Pixels := new Pixel_Buffer (0 .. W_N * H_N - 1);

         for Y in 0 .. H_N - 1 loop
            declare
               Row_Addr : constant System.Address :=
                 Data_Addr + Storage_Offset (Y * Stride_N);
            begin
               for X in 0 .. W_N - 1 loop
                  declare
                     PM_Addr : constant System.Address :=
                       Row_Addr + Storage_Offset (X * 4);
                     PM : constant Interfaces.Unsigned_32 := U32_Conv.To_Pointer (PM_Addr).all;

                     A : constant Integer :=
                       Integer (Interfaces.Shift_Right (PM, 24) and 16#FF#);
                     R_PM : constant Integer :=
                       Integer (Interfaces.Shift_Right (PM, 16) and 16#FF#);
                     G_PM : constant Integer :=
                       Integer (Interfaces.Shift_Right (PM, 8) and 16#FF#);
                     B_PM : constant Integer := Integer (PM and 16#FF#);

                     R : Integer := 0;
                     G : Integer := 0;
                     B : Integer := 0;
                  begin
                     if A = 255 then
                        R := R_PM;
                        G := G_PM;
                        B := B_PM;
                     elsif A > 0 then
                        R := (R_PM * 255 + A / 2) / A;
                        G := (G_PM * 255 + A / 2) / A;
                        B := (B_PM * 255 + A / 2) / A;
                     end if;

                     Pixels (Y * W_N + X) := Pack_ARGB (A, R, G, B);
                  end;
               end loop;
            end;
         end loop;
      end;

      Surface_Destroy (Surface);
      return Pixels;
   exception
      when others =>
         if Surface /= null then
            Surface_Destroy (Surface);
         end if;
         if Pixels /= null then
            Free_Pixel_Buffer (Pixels);
         end if;
         return null;
   end Render_ARGB32;

   procedure Destroy (Doc : in out Document) is
      Handle : constant Plutosvg_Document_Ptr := To_Document_Ptr (Doc.Handle);
   begin
      if Handle /= null then
         Document_Destroy (Handle);
      end if;

      if Doc.Source /= null then
         Free_String (Doc.Source);
      end if;

      Doc.Handle := System.Null_Address;
      Doc.Valid := False;
      Doc.Width := 0.0;
      Doc.Height := 0.0;
   end Destroy;

   function Backend_Name return String is
   begin
      return "plutosvg";
   end Backend_Name;

end Adi.SVG;
