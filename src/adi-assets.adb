--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Deallocation;
with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C;    use Interfaces.C;
with Adi.Log;
with Adi.SDL;         use Adi.SDL;
with Adi.SDL.Surface; use Adi.SDL.Surface;
with Adi.SVG_Sprites; use Adi.SVG_Sprites;
with Adi.Assets.Bundle;

package body Adi.Assets is

   use type System.Address;

   ---------------------------------------------------------------------------
   --  Internal types
   ---------------------------------------------------------------------------

   type Search_Entry is record
      Dir     : Unbounded_String;
      Scheme  : Unbounded_String;  --  "" = default (plain paths)
      Flatten : Boolean := False;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Search_Entry);

   package String_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Unbounded_String);

   package Image_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Image_Owner);

   package Anim_Image_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Animation_Handle);

   package Sprite_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Adi.SVG_Sprites.Sprite_Sheet_Access,
      "="          => Adi.SVG_Sprites."=");

   procedure Free_Sprite is new Ada.Unchecked_Deallocation
     (Object => Adi.SVG_Sprites.Sprite_Sheet'Class,
      Name   => Adi.SVG_Sprites.Sprite_Sheet_Access);

   ---------------------------------------------------------------------------
   --  Module-level state
   ---------------------------------------------------------------------------

   Entries     : Entry_Vectors.Vector;
   Strings     : String_Maps.Map;
   Images      : Image_Maps.Map;
   Anim_Images : Anim_Image_Maps.Map;
   Sprites     : Sprite_Maps.Map;

   Current_Mode     : Asset_Mode := File_Mode;
   Any_Asset_Loaded : Boolean := False;

   ---------------------------------------------------------------------------
   --  Mode and bundle API
   ---------------------------------------------------------------------------

   procedure Set_Mode (Mode : Asset_Mode) is
   begin
      if Any_Asset_Loaded then
         raise Program_Error with
           "Adi.Assets.Set_Mode called after assets were already loaded";
      end if;
      Current_Mode := Mode;
   end Set_Mode;

   function Get_Mode return Asset_Mode is
   begin
      return Current_Mode;
   end Get_Mode;

   procedure Mark_Asset_Loaded is
   begin
      Any_Asset_Loaded := True;
   end Mark_Asset_Loaded;

   procedure Register
     (Path   : String;
      Addr   : System.Address;
      Length : System.Storage_Elements.Storage_Count) is
   begin
      Adi.Assets.Bundle.Register (Path, Addr, Length);
   end Register;

   function Bundle_Lookup (Path : String) return Asset_Data is
   begin
      return Adi.Assets.Bundle.Lookup (Path);
   end Bundle_Lookup;

   function Memory_To_String
     (BD : Asset_Data) return String
   is
      use System.Storage_Elements;
      Len : constant Natural := Natural (BD.Length);
      subtype Data_Array is Storage_Array (1 .. BD.Length);
      Raw : Data_Array;
      for Raw'Address use BD.Addr;
      pragma Import (Ada, Raw);
      Result : String (1 .. Len);
   begin
      for I in 1 .. Len loop
         Result (I) := Character'Val (Raw (Storage_Offset (I)));
      end loop;
      return Result;
   end Memory_To_String;

   ---------------------------------------------------------------------------
   --  Sanitize — return a safe relative path.  Strips leading slashes
   --  and backslashes, normalizes backslashes to forward slashes, and
   --  rejects ".." segments that would escape the search directory.
   --  Returns "" if the path is unsafe or empty.
   ---------------------------------------------------------------------------

   function Sanitize (Path : String) return String is
      Start : Natural := Path'First;
   begin
      while Start <= Path'Last
        and then (Path (Start) = '/' or Path (Start) = '\')
      loop
         Start := Start + 1;
      end loop;

      if Start > Path'Last then
         return "";
      end if;

      declare
         Result : String (1 .. Path'Last - Start + 1);
      begin
         for I in Start .. Path'Last loop
            if Path (I) = '\' then
               Result (I - Start + 1) := '/';
            else
               Result (I - Start + 1) := Path (I);
            end if;
         end loop;

         --  Reject ".." segments
         if Result = ".." then
            return "";
         end if;

         if Result'Length >= 3
           and then Result (1 .. 3) = "../"
         then
            return "";
         end if;

         if Result'Length >= 3
           and then Result (Result'Last - 2 .. Result'Last) = "/.."
         then
            return "";
         end if;

         for I in Result'First .. Result'Last - 3 loop
            if Result (I .. I + 3) = "/../" then
               return "";
            end if;
         end loop;

         return Result;
      end;
   end Sanitize;

   ---------------------------------------------------------------------------
   --  Parse_Scheme — split "scheme://relative" into (scheme, relative).
   --  If no "://" is found, returns ("", Path) for default resolution.
   ---------------------------------------------------------------------------

   procedure Parse_Scheme
     (Path   : String;
      Scheme : out Unbounded_String;
      Rel    : out Unbounded_String)
   is
   begin
      for I in Path'First .. Path'Last - 2 loop
         if Path (I .. I + 2) = "://" then
            --  Reject malformed URIs with empty scheme (e.g. "://foo")
            if I = Path'First then
               Scheme := Null_Unbounded_String;
               Rel    := Null_Unbounded_String;
               return;
            end if;
            Scheme := To_Unbounded_String (Path (Path'First .. I - 1));
            if I + 3 <= Path'Last then
               Rel := To_Unbounded_String (Path (I + 3 .. Path'Last));
            else
               Rel := Null_Unbounded_String;
            end if;
            return;
         end if;
      end loop;

      Scheme := Null_Unbounded_String;
      Rel    := To_Unbounded_String (Path);
   end Parse_Scheme;

   ---------------------------------------------------------------------------
   --  Find_In_Subtree — depth-first search for a file by Simple_Name.
   --  Returns the full path of the first ordinary file whose Simple_Name
   --  matches Name, or "" if none found.
   ---------------------------------------------------------------------------

   function Find_In_Subtree (Dir : String; Name : String) return String is
      use Ada.Directories;
      Search  : Search_Type;
      Dir_Ent : Directory_Entry_Type;
   begin
      Start_Search
        (Search,
         Directory => Dir,
         Pattern   => "",
         Filter    => [Directory     => True,
                       Ordinary_File => True,
                       others        => False]);

      while More_Entries (Search) loop
         Get_Next_Entry (Search, Dir_Ent);

         declare
            SN : constant String := Simple_Name (Dir_Ent);
         begin
            if Kind (Dir_Ent) = Ordinary_File then
               if SN = Name then
                  End_Search (Search);
                  return Full_Name (Dir_Ent);
               end if;
            elsif Kind (Dir_Ent) = Directory
              and then SN /= "." and then SN /= ".."
            then
               declare
                  Result : constant String :=
                    Find_In_Subtree (Full_Name (Dir_Ent), Name);
               begin
                  if Result /= "" then
                     End_Search (Search);
                     return Result;
                  end if;
               end;
            end if;
         end;
      end loop;

      End_Search (Search);
      return "";
   end Find_In_Subtree;

   ---------------------------------------------------------------------------
   --  Resolve — search directories in insertion order for Path.
   ---------------------------------------------------------------------------

   function Resolve (Path : String) return String is
      use type Ada.Directories.File_Kind;
      Scheme : Unbounded_String;
      Rel    : Unbounded_String;
   begin
      Parse_Scheme (Path, Scheme, Rel);

      declare
         Safe : constant String := Sanitize (To_String (Rel));
      begin
         if Safe = "" then
            Adi.Log.Warning ("Assets: rejected unsafe path: " & Path);
            return "";
         end if;

         for E of Entries loop
            if E.Scheme = Scheme then
               if E.Flatten then
                  --  Flattened: look up by basename only.
                  declare
                     Filename : constant String :=
                       Ada.Directories.Simple_Name (Safe);
                     Dir_Str  : constant String := To_String (E.Dir);
                     FP       : constant String :=
                       Dir_Str & "/" & Filename;
                  begin
                     if Ada.Directories.Exists (FP)
                       and then Ada.Directories.Kind (FP)
                                  = Ada.Directories.Ordinary_File
                     then
                        return FP;
                     end if;

                     declare
                        Found : constant String :=
                          Find_In_Subtree (Dir_Str, Filename);
                     begin
                        if Found /= "" then
                           return Found;
                        end if;
                     end;
                  end;
               else
                  declare
                     FP : constant String :=
                       To_String (E.Dir) & "/" & Safe;
                  begin
                     if Ada.Directories.Exists (FP)
                       and then Ada.Directories.Kind (FP)
                                  = Ada.Directories.Ordinary_File
                     then
                        return FP;
                     end if;
                  end;
               end if;
            end if;
         end loop;
         return "";
      end;
   end Resolve;

   ---------------------------------------------------------------------------
   --  Resolve_Path
   ---------------------------------------------------------------------------

   function Resolve_Path (Path : String) return String is
   begin
      if Current_Mode = Bundle_Mode then
         return "";
      end if;
      return Resolve (Path);
   end Resolve_Path;

   ---------------------------------------------------------------------------
   --  Read_File — read entire file contents into a String.
   ---------------------------------------------------------------------------

   function Read_File (Path : String) return String is
      use Ada.Directories;
      File_Size : constant Natural := Natural (Size (Path));
   begin
      if File_Size = 0 then
         return "";
      end if;
      declare
         subtype Content_String is String (1 .. File_Size);
         F : Ada.Streams.Stream_IO.File_Type;
         S : Ada.Streams.Stream_IO.Stream_Access;
         Result : Content_String;
      begin
         Ada.Streams.Stream_IO.Open (F, Ada.Streams.Stream_IO.In_File, Path);
         S := Ada.Streams.Stream_IO.Stream (F);
         Content_String'Read (S, Result);
         Ada.Streams.Stream_IO.Close (F);
         return Result;
      end;
   end Read_File;

   ---------------------------------------------------------------------------
   --  Split_Query — split "base?key=val&key=val" into base path and params.
   --  If no '?' is found, Query_Start is set past Path'Last.
   ---------------------------------------------------------------------------

   procedure Split_Query
     (Path        : String;
      Base_Last   : out Natural;
      Query_Start : out Natural)
   is
   begin
      for I in Path'Range loop
         if Path (I) = '?' then
            Base_Last   := I - 1;
            Query_Start := I + 1;
            return;
         end if;
      end loop;
      Base_Last   := Path'Last;
      Query_Start := Path'Last + 1;
   end Split_Query;

   ---------------------------------------------------------------------------
   --  Get_Param — extract the value for a key from "key=val&key=val" query.
   --  Returns "" if not found.
   ---------------------------------------------------------------------------

   function Get_Param (Query : String; Key : String) return String is
      I   : Natural := Query'First;
      Sep : Natural;
      Amp : Natural;
   begin
      while I <= Query'Last loop
         --  Find end of this pair (next '&' / ';' or end of string)
         Amp := Query'Last + 1;
         for J in I .. Query'Last loop
            if Query (J) = '&' or else Query (J) = ';' then
               Amp := J;
               exit;
            end if;
         end loop;

         --  Find '=' separator within this pair
         Sep := Amp;  --  default: no value
         for J in I .. Amp - 1 loop
            if Query (J) = '=' then
               Sep := J;
               exit;
            end if;
         end loop;

         if Query (I .. Sep - 1) = Key and then Sep < Amp then
            return Query (Sep + 1 .. Amp - 1);
         end if;

         I := Amp + 1;
      end loop;
      return "";
   end Get_Param;

   ---------------------------------------------------------------------------
   --  Has_Param — check if a key exists in the query string.
   ---------------------------------------------------------------------------

   function Has_Param (Query : String; Key : String) return Boolean is
      I   : Natural := Query'First;
      Sep : Natural;
      Amp : Natural;
   begin
      while I <= Query'Last loop
         Amp := Query'Last + 1;
         for J in I .. Query'Last loop
            if Query (J) = '&' or else Query (J) = ';' then
               Amp := J;
               exit;
            end if;
         end loop;

         Sep := Amp;
         for J in I .. Amp - 1 loop
            if Query (J) = '=' then
               Sep := J;
               exit;
            end if;
         end loop;

         if Query (I .. Sep - 1) = Key then
            return True;
         end if;

         I := Amp + 1;
      end loop;
      return False;
   end Has_Param;

   ---------------------------------------------------------------------------
   --  Parse_Natural — parse a non-negative integer from a string.
   --  Returns -1 on failure.
   ---------------------------------------------------------------------------

   function Parse_Natural (S : String) return Integer is
      Max    : constant := 1_000_000;
      Result : Integer := 0;
   begin
      if S'Length = 0 then
         return -1;
      end if;
      for C of S loop
         if C not in '0' .. '9' then
            return -1;
         end if;
         Result := Result * 10 + (Character'Pos (C) - Character'Pos ('0'));
         if Result > Max then
            return -1;
         end if;
      end loop;
      return Result;
   end Parse_Natural;

   ---------------------------------------------------------------------------
   --  Ends_With_SVG — case-insensitive check for .svg extension.
   ---------------------------------------------------------------------------

   function Ends_With_SVG (Path : String) return Boolean is
      use Ada.Characters.Handling;
   begin
      return Path'Length >= 4
        and then To_Lower (Path (Path'Last - 3 .. Path'Last)) = ".svg";
   end Ends_With_SVG;

   ---------------------------------------------------------------------------
   --  Crop_Surface — blit a rectangle from Source into a new surface.
   --  Clamps to source bounds.  Returns null on failure.
   ---------------------------------------------------------------------------

   function Crop_Surface
     (Source : SDL_Surface_Ptr;
      X, Y   : Natural;
      W, H   : Positive) return SDL_Surface_Ptr
   is
      Src_W : constant Natural := Natural (Source.w);
      Src_H : constant Natural := Natural (Source.h);
      --  Clamp to source bounds
      CX : constant Natural := Natural'Min (X, Src_W);
      CY : constant Natural := Natural'Min (Y, Src_H);
      CW : constant Positive :=
        Positive'Max (1, Natural'Min (W, Src_W - CX));
      CH : constant Positive :=
        Positive'Max (1, Natural'Min (H, Src_H - CY));
      Src_Rect : aliased SDL_Rect :=
        (x => int (CX), y => int (CY), w => int (CW), h => int (CH));
      Dst_Rect : aliased SDL_Rect :=
        (x => 0, y => 0, w => int (CW), h => int (CH));
      Dst : SDL_Surface_Ptr;
      OK  : Adi.SDL.C_bool;
   begin
      Dst := SDL_CreateSurface (int (CW), int (CH), Source.format);
      if Dst = null then
         return null;
      end if;
      OK := SDL_BlitSurface (Source, Src_Rect'Access, Dst, Dst_Rect'Access);
      if not OK then
         SDL_DestroySurface (Dst);
         return null;
      end if;
      return Dst;
   end Crop_Surface;

   ---------------------------------------------------------------------------
   --  Load_SVG_Sprite — load/cache sprite sheet, extract symbol as Image.
   ---------------------------------------------------------------------------

   function Load_SVG_Sprite
     (Base_Path : String;
      Id        : String) return Image_Owner
   is
      use Sprite_Maps;
      Sheet : Adi.SVG_Sprites.Sprite_Sheet_Access;
      Img   : Image_Owner;
   begin
      if Current_Mode = Bundle_Mode then
         --  In Bundle_Mode, use Base_Path directly as sprite cache key
         declare
            Pos : constant Cursor := Sprites.Find (Base_Path);
         begin
            if Pos /= No_Element then
               Sheet := Element (Pos);
            else
               declare
                  BD : constant Asset_Data := Bundle_Lookup (Base_Path);
               begin
                  if BD.Addr = System.Null_Address then
                     Adi.Log.Warning
                       ("Assets: SVG sprite bundle not found: " & Base_Path);
                     Sprites.Insert (Base_Path, null);
                     return Null_Image_Owner;
                  end if;
                  Sheet := Adi.SVG_Sprites.Load_From_String
                    (Memory_To_String (BD));
                  if Sheet = null then
                     Adi.Log.Warning
                       ("Assets: failed to parse SVG sprite from bundle: "
                        & Base_Path);
                     Sprites.Insert (Base_Path, null);
                     return Null_Image_Owner;
                  end if;
                  Sprites.Insert (Base_Path, Sheet);
               end;
            end if;
         end;
      else
         declare
            FP : constant String := Resolve (Base_Path);
            Pos : Cursor;
         begin
            if FP = "" then
               Adi.Log.Warning
                 ("Assets: SVG sprite file not found: " & Base_Path);
               return Null_Image_Owner;
            end if;

            Pos := Sprites.Find (FP);
            if Pos /= No_Element then
               Sheet := Element (Pos);
            else
               Sheet := Adi.SVG_Sprites.Load (FP);
               if Sheet = null then
                  Adi.Log.Warning
                    ("Assets: failed to load SVG sprite sheet: " & FP);
                  Sprites.Insert (FP, null);
                  return Null_Image_Owner;
               end if;
               Sprites.Insert (FP, Sheet);
            end if;
         end;
      end if;

      if Sheet = null then
         return Null_Image_Owner;
      end if;

      Img := Sheet.Get_Image (Id, Tintable => True);
      if not Adi.Image.Is_Owned (Img) then
         Adi.Log.Warning
           ("Assets: SVG sprite symbol not found: " & Id
            & " in " & Base_Path);
      end if;
      return Img;
   end Load_SVG_Sprite;

   ---------------------------------------------------------------------------
   --  Load_Raster_Crop — load source image, crop rectangle, return Image.
   ---------------------------------------------------------------------------

   function Load_Raster_Crop
     (Base_Path : String;
      X, Y      : Natural;
      W, H      : Positive) return Image_Owner
   is
      Source : Image_Handle;
      Surf   : SDL_Surface_Ptr;
      Crop   : SDL_Surface_Ptr;
   begin
      --  Load the source image (may already be cached under the base path)
      Source := Get_Image (Base_Path);
      if not Adi.Image.Is_Valid (Source) then
         return Null_Image_Owner;
      end if;

      Surf := Adi.Image.Get_Surface (Source);
      if Surf = null then
         Adi.Log.Warning
           ("Assets: cannot crop non-raster image: " & Base_Path);
         return Null_Image_Owner;
      end if;

      Crop := Crop_Surface (Surf, X, Y, W, H);
      if Crop = null then
         Adi.Log.Warning ("Assets: surface crop failed: " & Base_Path);
         return Null_Image_Owner;
      end if;

      --  The crop is this subprogram's until the image adopts it, and
      --  it does that only once it owns one.
      begin
         return Adi.Image.Create_From_Surface (Crop);
      exception
         when others =>
            SDL_DestroySurface (Crop);
            raise;
      end;
   end Load_Raster_Crop;

   ---------------------------------------------------------------------------
   --  Free_All_Sprites — destroy and deallocate all cached sprite sheets.
   ---------------------------------------------------------------------------

   procedure Free_All_Sprites is
   begin
      for Pos in Sprites.Iterate loop
         declare
            Sheet : Adi.SVG_Sprites.Sprite_Sheet_Access :=
              Sprite_Maps.Element (Pos);
         begin
            if Sheet /= null then
               Adi.SVG_Sprites.Destroy (Sheet.all);
               Free_Sprite (Sheet);
            end if;
         end;
      end loop;
      Sprites.Clear;
   end Free_All_Sprites;

   ---------------------------------------------------------------------------
   --  Invalidate_Derived — remove all image cache entries whose key starts
   --  with Base & "?" (derived sprite/crop keys).
   ---------------------------------------------------------------------------

   --  A container finalises what it drops when it likes, so an entry is
   --  released through the map before it is removed rather than by
   --  removing it.
   procedure Release_Entry (M : in out Image_Maps.Map; Key : String);

   procedure Release_Entry (M : in out Image_Maps.Map; Key : String) is
      procedure Give_Up (K : String; O : in out Image_Owner);

      procedure Give_Up (K : String; O : in out Image_Owner) is
         pragma Unreferenced (K);
      begin
         Adi.Image.Release (O);
      end Give_Up;

      Pos : constant Image_Maps.Cursor := M.Find (Key);
   begin
      if Image_Maps.Has_Element (Pos) then
         M.Update_Element (Pos, Give_Up'Access);
      end if;
   end Release_Entry;

   procedure Invalidate_Derived (Base : String) is
      package UB_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Unbounded_String);
      Prefix : constant String := Base & "?";
      Keys   : UB_Vectors.Vector;
   begin
      for Pos in Images.Iterate loop
         declare
            K : constant String := Image_Maps.Key (Pos);
         begin
            if K'Length >= Prefix'Length
              and then K (K'First .. K'First + Prefix'Length - 1) = Prefix
            then
               Keys.Append (To_Unbounded_String (K));
            end if;
         end;
      end loop;
      for K of Keys loop
         declare
            S : constant String := To_String (K);
         begin
            Release_Entry (Images, S);
            Images.Delete (S);
         end;
      end loop;
   end Invalidate_Derived;

   ---------------------------------------------------------------------------
   --  Add_Path
   ---------------------------------------------------------------------------

   procedure Add_Path
     (Path : String; Scheme : String := ""; Flatten : Boolean := False) is
   begin
      Entries.Append
        (Search_Entry'(Dir     => To_Unbounded_String (Path),
                       Scheme  => To_Unbounded_String (Scheme),
                       Flatten => Flatten));
   end Add_Path;

   ---------------------------------------------------------------------------
   --  Remove_Path
   ---------------------------------------------------------------------------

   procedure Remove_Path
     (Path : String; Scheme : String := ""; Flatten : Boolean := False) is
      Target_Dir    : constant Unbounded_String := To_Unbounded_String (Path);
      Target_Scheme : constant Unbounded_String := To_Unbounded_String (Scheme);
   begin
      for I in 1 .. Natural (Entries.Length) loop
         if Entries (I).Dir = Target_Dir
           and then Entries (I).Scheme = Target_Scheme
           and then Entries (I).Flatten = Flatten
         then
            Entries.Delete (I);
            return;
         end if;
      end loop;
   end Remove_Path;

   ---------------------------------------------------------------------------
   --  Clear_Paths
   ---------------------------------------------------------------------------

   procedure Clear_Paths is
   begin
      Entries.Clear;
   end Clear_Paths;

   ---------------------------------------------------------------------------
   --  Get_String
   ---------------------------------------------------------------------------

   function Get_String (Path : String) return String is
      use String_Maps;
      Pos : constant Cursor := Strings.Find (Path);
   begin
      Any_Asset_Loaded := True;

      if Pos /= No_Element then
         return To_String (Element (Pos));
      end if;

      if Current_Mode = Bundle_Mode then
         declare
            BD : constant Asset_Data := Bundle_Lookup (Path);
         begin
            if BD.Addr /= System.Null_Address then
               declare
                  Content : constant String := Memory_To_String (BD);
               begin
                  Strings.Insert (Path, To_Unbounded_String (Content));
                  return Content;
               end;
            end if;
            Adi.Log.Warning ("Assets: bundle entry not found: " & Path);
            Strings.Insert (Path, Null_Unbounded_String);
            return "";
         end;
      end if;

      declare
         FP : constant String := Resolve (Path);
      begin
         if FP = "" then
            Adi.Log.Warning ("Assets: file not found: " & Path);
            Strings.Insert (Path, Null_Unbounded_String);
            return "";
         end if;

         declare
            Content : constant String := Read_File (FP);
         begin
            Strings.Insert (Path, To_Unbounded_String (Content));
            return Content;
         end;
      end;
   end Get_String;

   ---------------------------------------------------------------------------
   --  Get_Image
   ---------------------------------------------------------------------------

   --  Load without consulting or filling the cache. Callers that mean
   --  to cache the result insert the owner themselves.
   function Load_Fresh (Path : String) return Image_Owner is
   begin
      if Current_Mode = Bundle_Mode then
         declare
            BD : constant Asset_Data := Bundle_Lookup (Path);
         begin
            if BD.Addr = System.Null_Address then
               Adi.Log.Warning
                 ("Assets: bundle entry not found or failed: " & Path);
               return Null_Image_Owner;
            end if;

            if Ends_With_SVG (Path) then
               return Adi.Image.Load_SVG_From_String (Memory_To_String (BD));
            end if;
            return Adi.Image.Load_From_Memory (BD.Addr, BD.Length);
         end;
      end if;

      declare
         FP : constant String := Resolve (Path);
      begin
         if FP = "" then
            Adi.Log.Warning ("Assets: file not found: " & Path);
            return Null_Image_Owner;
         end if;

         return Loaded : constant Image_Owner :=
           Adi.Image.Load_From_File (FP)
         do
            if not Adi.Image.Is_Owned (Loaded) then
               Adi.Log.Warning ("Assets: failed to load image: " & FP);
            end if;
         end return;
      end;
   end Load_Fresh;

   function Get_Image (Path : String) return Image_Handle is
      use Image_Maps;
      Pos : constant Cursor := Images.Find (Path);
   begin
      Any_Asset_Loaded := True;

      if Pos /= No_Element then
         return Adi.Image.To_Handle (Element (Pos));
      end if;

      --  Check for query parameters (sprite/crop syntax)
      declare
         Base_Last   : Natural;
         Query_Start : Natural;
      begin
         Split_Query (Path, Base_Last, Query_Start);

         if Query_Start <= Path'Last then
            --  Has query string — sprite or crop mode
            if Base_Last < Path'First then
               Adi.Log.Warning ("Assets: missing base path: " & Path);
               Images.Insert (Path, Null_Image_Owner);
               return Null_Image_Handle;
            end if;
            declare
               Base  : constant String :=
                 Path (Path'First .. Base_Last);
               Query : constant String :=
                 Path (Query_Start .. Path'Last);
               Img          : Image_Owner;
               Has_Content  : Boolean := False;
            begin
               if Has_Param (Query, "id") then
                  --  SVG sprite mode: base.svg?id=symbol-name
                  Has_Content := True;
                  if not Ends_With_SVG (Base) then
                     Adi.Log.Warning
                       ("Assets: 'id' param requires .svg file: " & Path);
                  else
                     Img := Load_SVG_Sprite
                       (Base, Get_Param (Query, "id"));
                  end if;
               elsif Has_Param (Query, "x")
                 and then Has_Param (Query, "y")
                 and then Has_Param (Query, "w")
                 and then Has_Param (Query, "h")
               then
                  --  Raster crop mode: image.png?x=0&y=0&w=32&h=32
                  Has_Content := True;
                  declare
                     PX : constant Integer :=
                       Parse_Natural (Get_Param (Query, "x"));
                     PY : constant Integer :=
                       Parse_Natural (Get_Param (Query, "y"));
                     PW : constant Integer :=
                       Parse_Natural (Get_Param (Query, "w"));
                     PH : constant Integer :=
                       Parse_Natural (Get_Param (Query, "h"));
                  begin
                     if PX < 0 or PY < 0 or PW <= 0 or PH <= 0 then
                        Adi.Log.Warning
                          ("Assets: invalid crop params: " & Path);
                     else
                        Img := Load_Raster_Crop (Base, PX, PY, PW, PH);
                     end if;
                  end;
               end if;

               --  ?render= can combine with sprite/crop or stand alone
               if Has_Param (Query, "render") then
                  if not Has_Content then
                     --  Standalone render param — clone the base image so
                     --  setting its scale mode doesn't mutate the cached
                     --  original (which other queries may share).
                     declare
                        Base_Img : constant Image_Handle := Get_Image (Base);
                        Surf     : SDL_Surface_Ptr;
                        Copy     : SDL_Surface_Ptr;
                     begin
                        if not Adi.Image.Is_Valid (Base_Img) then
                           Images.Insert (Path, Img);
                           return Null_Image_Handle;
                        end if;
                        Surf := Adi.Image.Get_Surface (Base_Img);
                        if Surf /= null then
                           --  Named, so that a failure has something to
                           --  destroy: the duplicate is this branch's
                           --  until the image adopts it.
                           Copy := SDL_Surface_Ptr
                             (SDL_DuplicateSurface (Surf));
                           begin
                              Img := Adi.Image.Create_From_Surface (Copy);
                           exception
                              when others =>
                                 SDL_DestroySurface (Copy);
                                 raise;
                           end;
                        else
                           --  SVG, which has no surface to duplicate, so
                           --  it is loaded again. Naming the base image
                           --  under this key too would give the two keys
                           --  one image: setting the scale mode here
                           --  would change the base, and invalidating
                           --  either key would end both.
                           Img := Load_Fresh (Base);
                        end if;
                        Has_Content := True;
                     end;
                  end if;
                  if Adi.Image.Is_Owned (Img) then
                     declare
                        R : constant String :=
                          Get_Param (Query, "render");
                     begin
                        if R = "pixelated" or R = "pixelart" then
                           Adi.Image.Set_Scale_Mode
                             (Adi.Image.To_Handle (Img),
                              Adi.Image.Scale_Pixelart);
                        elsif R = "nearest" then
                           Adi.Image.Set_Scale_Mode
                             (Adi.Image.To_Handle (Img),
                              Adi.Image.Scale_Nearest);
                        elsif R = "linear" or R = "smooth" then
                           Adi.Image.Set_Scale_Mode
                             (Adi.Image.To_Handle (Img),
                              Adi.Image.Scale_Linear);
                        else
                           Adi.Log.Warning
                             ("Assets: unknown render mode: " & R);
                        end if;
                     end;
                  end if;
               elsif not Has_Content then
                  Adi.Log.Warning
                    ("Assets: unrecognized query params: " & Path);
               end if;

               Images.Insert (Path, Img);
               return Adi.Image.To_Handle (Img);
            end;
         end if;
      end;

      --  Normal path — no query string
      declare
         Img : constant Image_Owner := Load_Fresh (Path);
      begin
         Images.Insert (Path, Img);
         return Adi.Image.To_Handle (Img);
      end;
   end Get_Image;

   ---------------------------------------------------------------------------
   --  Get_Animated_Image
   ---------------------------------------------------------------------------

   function Get_Animated_Image
     (Path : String) return Animation_Handle is
      use Anim_Image_Maps;
      Pos : constant Cursor := Anim_Images.Find (Path);
   begin
      Any_Asset_Loaded := True;

      if Pos /= No_Element then
         return Element (Pos);
      end if;

      if Current_Mode = Bundle_Mode then
         declare
            BD   : constant Asset_Data := Bundle_Lookup (Path);
            Anim : Animation_Handle := Null_Animation_Handle;
         begin
            if BD.Addr /= System.Null_Address then
               Anim := Adi.Animated_Image.Load_From_Memory
                 (BD.Addr, BD.Length);
            end if;
            if not Is_Valid (Anim) then
               Adi.Log.Warning
                 ("Assets: bundle entry not found or failed: " & Path);
            end if;
            Anim_Images.Insert (Path, Anim);
            return Anim;
         end;
      end if;

      declare
         FP   : constant String := Resolve (Path);
         Anim : Animation_Handle := Null_Animation_Handle;
      begin
         if FP = "" then
            Adi.Log.Warning ("Assets: file not found: " & Path);
         else
            Anim := Adi.Animated_Image.Load_From_File (FP);
            if not Is_Valid (Anim) then
               Adi.Log.Warning
                 ("Assets: failed to load animated image: " & FP);
            end if;
         end if;

         Anim_Images.Insert (Path, Anim);
         return Anim;
      end;
   end Get_Animated_Image;

   ---------------------------------------------------------------------------
   --  Cache Management
   ---------------------------------------------------------------------------

   procedure Free_All_Images is
      procedure Give_Up (K : String; O : in out Image_Owner);

      procedure Give_Up (K : String; O : in out Image_Owner) is
         pragma Unreferenced (K);
      begin
         Adi.Image.Release (O);
      end Give_Up;
   begin
      --  Released one by one before the map is emptied: clearing a
      --  container finalises what it held whenever it likes, and the
      --  images have to go now.
      for Pos in Images.Iterate loop
         Images.Update_Element (Pos, Give_Up'Access);
      end loop;
      Images.Clear;
   end Free_All_Images;

   procedure Free_All_Anim_Images is
   begin
      for Pos in Anim_Images.Iterate loop
         declare
            Anim : Animation_Handle := Anim_Image_Maps.Element (Pos);
         begin
            --  Destroy reclaims the record and retires the slot, so
            --  every handle handed out for this path goes stale.
            Adi.Animated_Image.Destroy (Anim);
         end;
      end loop;
      Anim_Images.Clear;
   end Free_All_Anim_Images;

   procedure Clear_Cache is
   begin
      Strings.Clear;
      Free_All_Images;
      Free_All_Anim_Images;
      Free_All_Sprites;
   end Clear_Cache;

   procedure Clear_String_Cache is
   begin
      Strings.Clear;
   end Clear_String_Cache;

   procedure Clear_Image_Cache is
   begin
      Free_All_Images;
      Free_All_Sprites;
   end Clear_Image_Cache;

   procedure Clear_Animated_Image_Cache is
   begin
      Free_All_Anim_Images;
   end Clear_Animated_Image_Cache;

   procedure Invalidate (Path : String) is
   begin
      if Strings.Contains (Path) then
         Strings.Delete (Path);
      end if;
      if Images.Contains (Path) then
         Release_Entry (Images, Path);
         Images.Delete (Path);
      end if;
      if Anim_Images.Contains (Path) then
         declare
            Anim : Animation_Handle := Anim_Images.Element (Path);
         begin
            --  Destroy reclaims the record and retires the slot, so
            --  every handle handed out for this path goes stale.
            Adi.Animated_Image.Destroy (Anim);
         end;
         Anim_Images.Delete (Path);
      end if;

      --  Also invalidate derived sprite/crop entries and sprite sheet cache.
      Invalidate_Derived (Path);

      --  In Bundle_Mode the sprite key is the original path, not resolved path.
      if Current_Mode = Bundle_Mode then
         if Sprites.Contains (Path) then
            declare
               Sheet : Adi.SVG_Sprites.Sprite_Sheet_Access :=
                 Sprites.Element (Path);
            begin
               if Sheet /= null then
                  Adi.SVG_Sprites.Destroy (Sheet.all);
                  Free_Sprite (Sheet);
               end if;
            end;
            Sprites.Delete (Path);
         end if;
      else
         declare
            FP : constant String := Resolve (Path);
         begin
            if FP /= "" and then Sprites.Contains (FP) then
               declare
                  Sheet : Adi.SVG_Sprites.Sprite_Sheet_Access :=
                    Sprites.Element (FP);
               begin
                  if Sheet /= null then
                     Adi.SVG_Sprites.Destroy (Sheet.all);
                     Free_Sprite (Sheet);
                  end if;
               end;
               Sprites.Delete (FP);
            end if;
         end;
      end if;
   end Invalidate;

end Adi.Assets;
