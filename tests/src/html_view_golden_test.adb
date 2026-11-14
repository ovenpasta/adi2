pragma Ada_2022;

with Ada.Command_Line;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Adi.Core;  use Adi.Core;
with Adi.CSS_Styles;
with Adi.Font;
with Adi.Image;
with Adi.SDL;
with Adi.SDL.TTF;
with Adi.Widget;
with Adi.Widget.Html_View;
with Html_View_Dump;
with Test_Support;

--  Lays out every tests/html/layout/*.html in each of Passes, under
--  tests/html/layout/default.css and the vendored Open Sans, and holds
--  the result against tests/goldens/html/<name>.txt.
--
--  `tests/bin/html_view_golden_test --update` rewrites the goldens.
procedure Html_View_Golden_Test is

   package HV renames Adi.Widget.Html_View;
   use type Adi.CSS_Styles.Font_Handle;
   use type HV.Html_View_Handle;

   Case_Dir   : constant String := "tests/html/layout";
   Golden_Dir : constant String := "tests/goldens/html";
   Stylesheet : constant String := Case_Dir & "/default.css";
   Font_Dir   : constant String := "vendor/open-sans/static";

   --  A view width and content scale. Twice the scale in twice the width
   --  lays out at about twice the size, so a length that misses the
   --  scale, or takes it twice, stands out.
   type Pass is record
      Width : Pixel_Type;
      Scale : Pixel_Type;
   end record;

   Passes : constant array (Positive range <>) of Pass :=
     [(640.0, 1.0), (320.0, 1.0), (1280.0, 2.0)];

   --  Tall enough at scale 1 that no case is culled by the viewport band;
   --  a pass's view is this times its scale.
   View_H : constant Pixel_Type := 2000.0;

   Update : constant Boolean :=
     Ada.Command_Line.Argument_Count >= 1
     and then Ada.Command_Line.Argument (1) = "--update";

   Cat : Adi.Image.Image_Owner := Adi.Image.Null_Image_Owner;

   function Load_Asset (Self : HV.Html_View_Handle; URI : String)
     return Adi.Image.Image_Handle
   is
      pragma Unreferenced (Self);
   begin
      return (if URI = "cat.svg" then Adi.Image.To_Handle (Cat)
              else Adi.Image.Null_Image_Handle);
   end Load_Asset;

   function Read_File (Path : String) return String is
      use Ada.Streams.Stream_IO;
      F : File_Type;
   begin
      Open (F, In_File, Path);
      declare
         S : String (1 .. Natural (Size (F)));
      begin
         String'Read (Stream (F), S);
         Close (F);
         return S;
      end;
   end Read_File;

   procedure Write_File (Path : String; Content : String) is
      use Ada.Streams.Stream_IO;
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      String'Write (Stream (F), Content);
      Close (F);
   end Write_File;

   function Width_Image (W : Pixel_Type) return String is
     (Ada.Strings.Fixed.Trim (Integer'Image (Integer (W)), Ada.Strings.Both));

   function Lay_Out (HTML : String; Name : String) return String is
      Out_S : Unbounded_String;
   begin
      for P of Passes loop
         declare
            View : constant HV.Html_View_Handle := HV.Create_Handle;
            W    : constant Pixel_Type := P.Width;
            H    : constant Pixel_Type := View_H * P.Scale;
         begin
            HV.Set_Content_Scale (View, P.Scale);
            HV.Set_Default_Stylesheet (View, Stylesheet);
            HV.Set_On_Load_Asset (View, Load_Asset'Unrestricted_Access);
            HV.Connect_Link_Click (View, Html_View_Dump.Record_Link'Access);
            HV.Set_HTML (View, HTML);
            Adi.Widget.Set_Geometry
              (+View, (X => 0.0, Y => 0.0, Width => W, Height => H));
            Adi.Widget.Build_Items (+View);

            Test_Support.Assert
              (Adi.Widget.Get_Preferred_Size (+View).Height <= H,
               Name & " fits the " & Width_Image (H) & " px view at width "
               & Width_Image (W));

            Append (Out_S,
                    "== width " & Width_Image (W)
                    & (if P.Scale = 1.0 then ""
                       else " scale " & Width_Image (P.Scale))
                    & ASCII.LF);
            Append (Out_S, Html_View_Dump.Snapshot (View));
            declare
               Handle : Adi.Widget.Widget_Handle := +View;
            begin
               Adi.Widget.Destroy (Handle);
            end;
         end;
      end loop;
      return To_String (Out_S);
   end Lay_Out;

   --  The first lines that differ, numbered.
   procedure Report_Difference (Expected, Actual : String) is
      E_First : Positive := Expected'First;
      A_First : Positive := Actual'First;
      Line    : Positive := 1;
      Shown   : Natural := 0;

      function Next_Line (S : String; First : in out Positive) return String is
         Last : Natural := Ada.Strings.Fixed.Index (S (First .. S'Last), "" & ASCII.LF);
         Start : constant Positive := First;
      begin
         if First > S'Last then
            return "<end>";
         end if;
         if Last = 0 then
            Last := S'Last + 1;
         end if;
         First := Last + 1;
         return S (Start .. Last - 1);
      end Next_Line;
   begin
      while (E_First <= Expected'Last or else A_First <= Actual'Last)
        and then Shown < 12
      loop
         declare
            E : constant String := Next_Line (Expected, E_First);
            A : constant String := Next_Line (Actual, A_First);
         begin
            if E /= A then
               Ada.Text_IO.Put_Line ("  line" & Line'Image & ":");
               Ada.Text_IO.Put_Line ("    - " & E);
               Ada.Text_IO.Put_Line ("    + " & A);
               Shown := Shown + 1;
            end if;
         end;
         Line := Line + 1;
      end loop;
   end Report_Difference;

   procedure Check_Case (Name : String) is
      Golden : constant String := Golden_Dir & "/" & Name & ".txt";
      Actual : constant String :=
        Lay_Out (Read_File (Case_Dir & "/" & Name & ".html"), Name);
   begin
      if Update then
         Write_File (Golden, Actual);
         Ada.Text_IO.Put_Line ("updated " & Golden);
         return;
      end if;

      if not Ada.Directories.Exists (Golden) then
         Test_Support.Assert
           (False, Name & ": no golden; run with --update to record one");
         return;
      end if;

      declare
         Expected : constant String := Read_File (Golden);
      begin
         if Expected /= Actual then
            Ada.Text_IO.Put_Line ("DIFF " & Name);
            Report_Difference (Expected, Actual);
         end if;
         Test_Support.Assert (Expected = Actual, Name & " matches its golden");
      end;
   end Check_Case;

   package Name_Vectors is new Ada.Containers.Vectors
     (Positive, Unbounded_String);
   package Name_Sorting is new Name_Vectors.Generic_Sorting;

   --  Base names of the files in Dir matching Pattern, sorted.
   function Names_In (Dir, Pattern : String) return Name_Vectors.Vector is
      use Ada.Directories;
      Found : Name_Vectors.Vector;
      S     : Search_Type;
      E     : Directory_Entry_Type;
   begin
      if Exists (Dir) then
         Start_Search (S, Dir, Pattern, [Ordinary_File => True, others => False]);
         while More_Entries (S) loop
            Get_Next_Entry (S, E);
            Found.Append (To_Unbounded_String (Base_Name (Simple_Name (E))));
         end loop;
         End_Search (S);
      end if;
      Name_Sorting.Sort (Found);
      return Found;
   end Names_In;

   Regular : Adi.CSS_Styles.Font_Handle := Adi.CSS_Styles.Null_Font;

   --  Faces of one family merge into the first one's handle; a face
   --  that did not would leave its weight to the system fonts.
   procedure Load_Face (Face : String) is
      H : constant Adi.CSS_Styles.Font_Handle :=
        Adi.Font.Load (Font_Dir & "/OpenSans-" & Face & ".ttf");
   begin
      if Regular = Adi.CSS_Styles.Null_Font then
         Regular := H;
      end if;
      Test_Support.Assert
        (H /= Adi.CSS_Styles.Null_Font and then H = Regular,
         "Open Sans " & Face & " loads into the Regular family");
   end Load_Face;

begin
   Test_Support.Start_Suite ("html_view_golden_test");

   if not Ada.Directories.Exists (Case_Dir) then
      Test_Support.Assert (False, Case_Dir & " exists; run from the repository root");
      Test_Support.Finish;
      return;
   end if;

   if not Boolean (Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO))
     or else not Boolean (Adi.SDL.TTF.TTF_Init)
   then
      Test_Support.Assert (False, "SDL and SDL_ttf initialise");
      Test_Support.Finish;
      return;
   end if;

   Load_Face ("Regular");
   Load_Face ("Italic");
   Load_Face ("SemiBold");
   Load_Face ("SemiBoldItalic");
   Load_Face ("Bold");
   Load_Face ("BoldItalic");
   Adi.Font.Set_Default_Font (Regular);

   Cat := Adi.Image.Load_From_File ("tests/assets/cat.svg");

   if Update and then not Ada.Directories.Exists (Golden_Dir) then
      Ada.Directories.Create_Path (Golden_Dir);
   end if;

   declare
      Cases : constant Name_Vectors.Vector := Names_In (Case_Dir, "*.html");
   begin
      for Name of Cases loop
         Check_Case (To_String (Name));
      end loop;

      for Golden of Names_In (Golden_Dir, "*.txt") loop
         Test_Support.Assert
           (Cases.Contains (Golden),
            Golden_Dir & "/" & To_String (Golden) & ".txt has a case");
      end loop;
   end;

   Test_Support.Finish;
end Html_View_Golden_Test;
