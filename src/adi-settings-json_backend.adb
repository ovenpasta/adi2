--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.OS_Lib;

with Adi.JSON;
with Adi.OS;

package body Adi.Settings.JSON_Backend is

   ---------------------------------------------------------------------------
   --  JSON -> Setting_Value Conversion
   ---------------------------------------------------------------------------

   function Convert (JV : Adi.JSON.Types.JSON_Value) return Setting_Value is
      use Adi.JSON.Types;
   begin
      case JV.Kind is
         when Null_Kind =>
            return Null_Value;

         when String_Kind =>
            return To_Value (String'(JV.Value));

         when Integer_Kind =>
            return To_Value (Long_Integer'(JV.Value));

         when Float_Kind =>
            return To_Value (Long_Float'(JV.Value));

         when Boolean_Kind =>
            return To_Value (Boolean'(JV.Value));

         when Array_Kind =>
            declare
               Result : Setting_Value := Empty_List;
            begin
               for I in 1 .. JV.Length loop
                  declare
                     Elem : constant Setting_Value :=
                       Convert (JV.Get (I));
                  begin
                     Append (Result, Elem);
                  end;
               end loop;
               return Result;
            end;

         when Object_Kind =>
            declare
               Result : Setting_Value := Empty_Map;
            begin
               for Key_JV of JV loop
                  declare
                     K : constant String := String'(Key_JV.Value);
                     V : constant Setting_Value := Convert (JV.Get (K));
                  begin
                     Insert (Result, K, V);
                  end;
               end loop;
               return Result;
            end;
      end case;
   end Convert;

   ---------------------------------------------------------------------------
   --  Setting_Value -> JSON Serialization (uses public API only)
   ---------------------------------------------------------------------------

   procedure Write_Setting
     (W : in out Adi.JSON.JSON_Writer;
      V : Setting_Value)
   is
   begin
      case Kind (V) is
         when Null_Kind =>
            W.Write_Null;

         when String_Kind =>
            W.Write_Value (As_String (V));

         when Integer_Kind =>
            W.Write_Value (As_Integer (V));

         when Float_Kind =>
            W.Write_Value (As_Float (V));

         when Boolean_Kind =>
            W.Write_Value (As_Boolean (V));

         when List_Kind =>
            W.Start_Array;
            for I in 1 .. Length (V) loop
               Write_Setting (W, Element (V, I));
            end loop;
            W.End_Array;

         when Map_Kind =>
            W.Start_Object;
            declare
               K_List : constant Key_Array := Keys (V);
            begin
               for K of K_List loop
                  W.Key (To_String (K));
                  Write_Setting (W, Get (V, To_String (K)));
               end loop;
            end;
            W.End_Object;
      end case;
   end Write_Setting;

   ---------------------------------------------------------------------------
   --  File I/O Helpers
   ---------------------------------------------------------------------------

   function Read_File (Path : String) return String is
      use Ada.Streams.Stream_IO;
      use Ada.Streams;
      Size : constant Natural :=
        Natural (Ada.Directories.Size (Path));
      F    : File_Type;
   begin
      if Size = 0 then return ""; end if;

      Open (F, In_File, Path);
      declare
         Buf  : Stream_Element_Array (1 .. Stream_Element_Offset (Size));
         Last : Stream_Element_Offset;
      begin
         Read (Stream (F).all, Buf, Last);
         Close (F);
         declare
            Result : String (1 .. Natural (Last));
         begin
            for I in 1 .. Last loop
               Result (Natural (I)) := Character'Val (Buf (I));
            end loop;
            return Result;
         end;
      end;
   exception
      when others =>
         if Is_Open (F) then Close (F); end if;
         return "";
   end Read_File;

   procedure Write_File (Path : String; Content : String) is
      use Ada.Text_IO;
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      Put (F, Content);
      Close (F);
   exception
      when others =>
         if Is_Open (F) then Close (F); end if;
   end Write_File;

   procedure Atomic_Write (Path : String; Content : String) is
      Tmp     : constant String := Path & ".tmp";
      Success : Boolean;
   begin
      Write_File (Tmp, Content);
      GNAT.OS_Lib.Rename_File (Tmp, Path, Success);
      if not Success then
         Write_File (Path, Content);
         begin
            Ada.Directories.Delete_File (Tmp);
         exception
            when others => null;
         end;
      end if;
   end Atomic_Write;

   ---------------------------------------------------------------------------
   --  Backend Implementation
   ---------------------------------------------------------------------------

   overriding function Load
     (B : JSON_Settings_Backend; Path : String) return Setting_Value
   is
      pragma Unreferenced (B);
      use Adi.OS;
      Info : constant Path_Info := Get_Path_Info (Path);
   begin
      if Info.Kind /= File then
         return Null_Value;
      end if;

      declare
         Content : constant String := Read_File (Path);
      begin
         if Content'Length = 0 then
            return Null_Value;
         end if;

         declare
            use Adi.JSON;
            P    : Parsers.Parser := Parsers.Create (Content);
            Root : constant Types.JSON_Value := P.Parse;
         begin
            return Convert (Root);
         end;
      exception
         when others =>
            return Null_Value;
      end;
   end Load;

   overriding procedure Save
     (B    : JSON_Settings_Backend;
      Path : String;
      Data : Setting_Value)
   is
      pragma Unreferenced (B);
      W : Adi.JSON.JSON_Writer := Adi.JSON.Create (Pretty => True);
   begin
      Write_Setting (W, Data);
      Atomic_Write (Path, W.To_String & ASCII.LF);
   end Save;

   ---------------------------------------------------------------------------
   --  Convenience Constructor
   ---------------------------------------------------------------------------

   procedure Create_With_JSON_Backend
     (Store : in out Settings_Store;
      Org   : String;
      App   : String)
   is
      B : constant Backend_Access := new JSON_Settings_Backend;
   begin
      Store.Initialize (Org, App, B);
      Store.Owns_Backend := True;
   end Create_With_JSON_Backend;

end Adi.Settings.JSON_Backend;
