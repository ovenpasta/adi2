pragma Ada_2022;

with Ada.Unchecked_Deallocation;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Log;

package body Adi.Assets is

   ---------------------------------------------------------------------------
   --  Internal types
   ---------------------------------------------------------------------------

   type Search_Entry is record
      Dir    : Unbounded_String;
      Scheme : Unbounded_String;  --  "" = default (plain paths)
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Search_Entry);

   package String_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Unbounded_String);

   package Image_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Image_Access);

   package Anim_Image_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Animated_Image_Access);

   procedure Free_Animated is new Ada.Unchecked_Deallocation
     (Object => Adi.Animated_Image.Animated_Image'Class,
      Name   => Animated_Image_Access);

   ---------------------------------------------------------------------------
   --  Module-level state
   ---------------------------------------------------------------------------

   Entries     : Entry_Vectors.Vector;
   Strings     : String_Maps.Map;
   Images      : Image_Maps.Map;
   Anim_Images : Anim_Image_Maps.Map;

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
         end loop;
         return "";
      end;
   end Resolve;

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
   --  Add_Path
   ---------------------------------------------------------------------------

   procedure Add_Path (Path : String; Scheme : String := "") is
   begin
      Entries.Append
        (Search_Entry'(Dir    => To_Unbounded_String (Path),
                       Scheme => To_Unbounded_String (Scheme)));
   end Add_Path;

   ---------------------------------------------------------------------------
   --  Remove_Path
   ---------------------------------------------------------------------------

   procedure Remove_Path (Path : String; Scheme : String := "") is
      Target_Dir    : constant Unbounded_String := To_Unbounded_String (Path);
      Target_Scheme : constant Unbounded_String := To_Unbounded_String (Scheme);
   begin
      for I in 1 .. Natural (Entries.Length) loop
         if Entries (I).Dir = Target_Dir
           and then Entries (I).Scheme = Target_Scheme
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
      if Pos /= No_Element then
         return To_String (Element (Pos));
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

   function Get_Image (Path : String) return Image_Access is
      use Image_Maps;
      Pos : constant Cursor := Images.Find (Path);
   begin
      if Pos /= No_Element then
         return Element (Pos);
      end if;

      declare
         FP  : constant String := Resolve (Path);
         Img : Image_Access := null;
      begin
         if FP = "" then
            Adi.Log.Warning ("Assets: file not found: " & Path);
         else
            Img := Adi.Image.Load_From_File (FP);
            if Img = null then
               Adi.Log.Warning ("Assets: failed to load image: " & FP);
            end if;
         end if;

         Images.Insert (Path, Img);
         return Img;
      end;
   end Get_Image;

   ---------------------------------------------------------------------------
   --  Get_Animated_Image
   ---------------------------------------------------------------------------

   function Get_Animated_Image (Path : String) return Animated_Image_Access is
      use Anim_Image_Maps;
      Pos : constant Cursor := Anim_Images.Find (Path);
   begin
      if Pos /= No_Element then
         return Element (Pos);
      end if;

      declare
         FP   : constant String := Resolve (Path);
         Anim : Animated_Image_Access := null;
      begin
         if FP = "" then
            Adi.Log.Warning ("Assets: file not found: " & Path);
         else
            Anim := Adi.Animated_Image.Load_From_File (FP);
            if Anim = null then
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
   begin
      for Pos in Images.Iterate loop
         declare
            Img : Image_Access := Image_Maps.Element (Pos);
         begin
            Adi.Image.Free (Img);
         end;
      end loop;
      Images.Clear;
   end Free_All_Images;

   procedure Free_All_Anim_Images is
   begin
      for Pos in Anim_Images.Iterate loop
         declare
            Anim : Animated_Image_Access := Anim_Image_Maps.Element (Pos);
         begin
            if Anim /= null then
               Adi.Animated_Image.Destroy (Anim.all);
               Free_Animated (Anim);
            end if;
         end;
      end loop;
      Anim_Images.Clear;
   end Free_All_Anim_Images;

   procedure Clear_Cache is
   begin
      Strings.Clear;
      Free_All_Images;
      Free_All_Anim_Images;
   end Clear_Cache;

   procedure Clear_String_Cache is
   begin
      Strings.Clear;
   end Clear_String_Cache;

   procedure Clear_Image_Cache is
   begin
      Free_All_Images;
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
         declare
            Img : Image_Access := Images.Element (Path);
         begin
            Adi.Image.Free (Img);
         end;
         Images.Delete (Path);
      end if;
      if Anim_Images.Contains (Path) then
         declare
            Anim : Animated_Image_Access := Anim_Images.Element (Path);
         begin
            if Anim /= null then
               Adi.Animated_Image.Destroy (Anim.all);
               Free_Animated (Anim);
            end if;
         end;
         Anim_Images.Delete (Path);
      end if;
   end Invalidate;

end Adi.Assets;
