pragma Ada_2022;

with Ada.Directories;
with Ada.Streams.Stream_IO;
with Adi.Log;
with Adi.SDL.Render;            use Adi.SDL.Render;

package body Adi.Assets is

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
   --  If Path is a scheme URI (e.g. "app://file.svg"), only directories
   --  registered with that scheme are searched.  Plain paths search
   --  only default (empty scheme) directories.
   --  Returns the full path of the first match, or "" if not found.
   ---------------------------------------------------------------------------

   function Resolve (Store : Asset_Store; Path : String) return String is
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

         for E of Store.Entries loop
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
   --  Create
   ---------------------------------------------------------------------------

   function Create
     (Win : not null access Adi.Window.Window) return Asset_Store is
   begin
      return (Win => Win, others => <>);
   end Create;

   ---------------------------------------------------------------------------
   --  Add_Path
   ---------------------------------------------------------------------------

   procedure Add_Path
     (Store  : in out Asset_Store;
      Path   : String;
      Scheme : String := "") is
   begin
      Store.Entries.Append
        (Search_Entry'(Dir    => To_Unbounded_String (Path),
                       Scheme => To_Unbounded_String (Scheme)));
   end Add_Path;

   ---------------------------------------------------------------------------
   --  Get_String
   ---------------------------------------------------------------------------

   function Get_String
     (Store : in out Asset_Store;
      Path  : String) return String
   is
      use String_Maps;
      Pos : constant Cursor := Store.Strings.Find (Path);
   begin
      if Pos /= No_Element then
         return To_String (Element (Pos));
      end if;

      declare
         FP : constant String := Resolve (Store, Path);
      begin
         if FP = "" then
            Adi.Log.Warning ("Assets: file not found: " & Path);
            Store.Strings.Insert (Path, Null_Unbounded_String);
            return "";
         end if;

         declare
            Content : constant String := Read_File (FP);
         begin
            Store.Strings.Insert (Path, To_Unbounded_String (Content));
            return Content;
         end;
      end;
   end Get_String;

   ---------------------------------------------------------------------------
   --  Get_Image
   ---------------------------------------------------------------------------

   function Get_Image
     (Store : in out Asset_Store;
      Path  : String) return Image_Access
   is
      use Image_Maps;
      Pos : constant Cursor := Store.Images.Find (Path);
   begin
      if Pos /= No_Element then
         return Element (Pos);
      end if;

      declare
         FP       : constant String := Resolve (Store, Path);
         Renderer : constant SDL_Renderer_Ptr :=
           Adi.Window.Get_Renderer (Store.Win.all);
         Img      : Image_Access := null;
      begin
         if Renderer = null then
            Adi.Log.Warning ("Assets: no renderer available");
         elsif FP = "" then
            Adi.Log.Warning ("Assets: file not found: " & Path);
         else
            Img := Adi.Image.Load_From_File (Renderer, FP);
            if Img = null then
               Adi.Log.Warning ("Assets: failed to load image: " & FP);
            end if;
         end if;

         Store.Images.Insert (Path, Img);
         return Img;
      end;
   end Get_Image;

end Adi.Assets;
