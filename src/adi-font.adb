with Ada.Characters.Handling;
with Ada.Containers.Hashed_Maps;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with Adi.Assets;
with Adi.Build_Target;
with Adi.Layout_Util;
with Adi.Log;
with Adi.SDL;
with Adi.SDL.IO;            use Adi.SDL.IO;
with Adi.SDL.TTF;           use Adi.SDL.TTF;
with Interfaces.C;          use Interfaces.C;
with Interfaces.C.Strings;  use Interfaces.C.Strings;

package body Adi.Font is
   use type System.Address;
   use type Adi.Assets.Asset_Mode;

   Debug_Font_Loading : constant Boolean := False;

   procedure Log (Msg : String) is
   begin
      if Debug_Font_Loading then
         Adi.Log.Debug ("[Adi.Font] " & Msg);
      end if;
   end Log;

   package Path_Vector is new Ada.Containers.Vectors (Positive, Unbounded_String);
   package Nat_Vector  is new Ada.Containers.Vectors (Positive, Natural);

   Family_Registry    : Path_Vector.Vector;
   Family_Generation  : Nat_Vector.Vector;

   --  Name → Font_Handle registry (keys lowercased)
   package Name_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Font_Handle);

   Name_Registry : Name_Maps.Map;

   --  Negative cache: lowercased names that were searched and not found.
   --  Prevents repeated filesystem scans for the same missing name.
   package Name_Sets is new Ada.Containers.Indefinite_Ordered_Sets (String);
   Name_Miss_Cache : Name_Sets.Set;

   -------------------------------------------------
   --  TTF metadata helpers
   -------------------------------------------------

   function TTF_Weight_To_Ada (W : int) return Font_Weight_Value is
   begin
      if W <= 150 then return Weight_Thin;
      elsif W <= 250 then return Weight_Extra_Light;
      elsif W <= 350 then return Weight_Light;
      elsif W <= 450 then return Weight_Normal;
      elsif W <= 550 then return Weight_Medium;
      elsif W <= 650 then return Weight_Semi_Bold;
      elsif W <= 750 then return Weight_Bold;
      elsif W <= 850 then return Weight_Extra_Bold;
      else return Weight_Black;
      end if;
   end TTF_Weight_To_Ada;

   function Contains_Substring (Haystack, Needle : String) return Boolean is
   begin
      if Needle'Length > Haystack'Length then
         return False;
      end if;
      for I in Haystack'First .. Haystack'Last - Needle'Length + 1 loop
         if Haystack (I .. I + Needle'Length - 1) = Needle then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Substring;

   function TTF_Style_Name_To_Ada (Style_Name : String) return Font_Style_Value is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Style_Name);
   begin
      if Contains_Substring (Lower, "italic") then
         return Style_Italic;
      elsif Contains_Substring (Lower, "oblique") then
         return Style_Oblique;
      else
         return Style_Normal;
      end if;
   end TTF_Style_Name_To_Ada;

   type Variant_Key is record
      Handle : Font_Handle;
      Weight : Font_Weight_Value;
      Style  : Font_Style_Value;
   end record;

   function "<" (L, R : Variant_Key) return Boolean is
   begin
      if L.Handle /= R.Handle then
         return L.Handle < R.Handle;
      end if;
      if L.Weight /= R.Weight then
         return Font_Weight_Value'Pos (L.Weight) < Font_Weight_Value'Pos (R.Weight);
      end if;
      return Font_Style_Value'Pos (L.Style) < Font_Style_Value'Pos (R.Style);
   end "<";

   package Variant_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Variant_Key,
      Element_Type => Unbounded_String);

   Variant_Registry : Variant_Maps.Map;

   --  Memory-based font variants: same key as Variant_Maps but stores
   --  a pointer to the in-memory font data rather than a file path.
   type Memory_Font_Entry is record
      Addr   : System.Address := System.Null_Address;
      Length : Storage_Count := 0;
   end record;

   package Memory_Font_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Variant_Key,
      Element_Type => Memory_Font_Entry);

   Memory_Variants : Memory_Font_Maps.Map;

   type Sized_Font_Key is record
      Attrs      : Font_Attributes;
      Size_Q     : Natural;
      Generation : Natural;
   end record;

   function "<" (L, R : Sized_Font_Key) return Boolean is
   begin
      if L.Attrs.Family /= R.Attrs.Family then
         return L.Attrs.Family < R.Attrs.Family;
      end if;
      if L.Size_Q /= R.Size_Q then
         return L.Size_Q < R.Size_Q;
      end if;
      if L.Attrs.Weight /= R.Attrs.Weight then
         return Font_Weight_Value'Pos (L.Attrs.Weight) < Font_Weight_Value'Pos (R.Attrs.Weight);
      end if;
      if L.Attrs.Style /= R.Attrs.Style then
         return Font_Style_Value'Pos (L.Attrs.Style) < Font_Style_Value'Pos (R.Attrs.Style);
      end if;
      if L.Attrs.Decoration /= R.Attrs.Decoration then
         return Text_Decoration_Value'Pos (L.Attrs.Decoration) < Text_Decoration_Value'Pos (R.Attrs.Decoration);
      end if;
      return L.Generation < R.Generation;
   end "<";

   package Sized_Font_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Sized_Font_Key,
      Element_Type => TTF_Font_Access);

   Sized_Cache : Sized_Font_Maps.Map;

   --  Per-font natural line-skip cache.  SDL3_ttf reports the original font
   --  metrics via TTF_GetFontLineSkip, but any prior TTF_SetFontLineSkip call
   --  overwrites it.  We snapshot the value the first time a font is queried
   --  and serve subsequent queries from this cache so callers can always
   --  recover the "use the font's default" pixel value.
   function Hash_Font (F : TTF_Font_Access) return Ada.Containers.Hash_Type is
     (if F = null then 0
      else Ada.Containers.Hash_Type
             (System.Storage_Elements.To_Integer (F.all'Address)
                mod 2**32));

   package Font_Skip_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => TTF_Font_Access,
      Element_Type    => Pixel_Type,
      Hash            => Hash_Font,
      Equivalent_Keys => "=");

   Natural_Skip_Cache : Font_Skip_Maps.Map;

   Default_Fallback_Handle : Font_Handle := Null_Font;
   Fallback_Found : Boolean := False;

   Linux_Fallback_Paths : constant array (Positive range 1 .. 3) of access constant String :=
     (1 => new String'("/usr/share/fonts"),
      2 => new String'("/usr/local/share/fonts"),
      3 => new String'("/usr/share/fonts/truetype"));

   --  macOS bundles UI fonts (Helvetica, Menlo, …) under /System/Library/Fonts,
   --  bundled-but-not-system fonts (Arial, Courier New, Georgia, …) under its
   --  Supplemental/ subdirectory (covered by Scan_Dir's recursion), admin-
   --  installed fonts under /Library/Fonts, and per-user fonts under
   --  $HOME/Library/Fonts (resolved at runtime in Search_System_Font).
   macOS_Fallback_Paths : constant array (Positive range 1 .. 2) of access constant String :=
     (1 => new String'("/System/Library/Fonts"),
      2 => new String'("/Library/Fonts"));

   Windows_Fallback_Paths : constant array (Positive range 1 .. 2) of access constant String :=
     (1 => new String'("C:\Windows\Fonts"),
      2 => new String'("C:\WINNT\Fonts"));

   type Fallback_Font_Entry is record
      File_Prefix : access constant String;
      Family_Name : access constant String;  --  lowercased expected TTF family name
   end record;

   Linux_Fallback_Fonts : constant array (Positive range 1 .. 2) of Fallback_Font_Entry :=
     (1 => (File_Prefix => new String'("DejaVuSans"),
            Family_Name => new String'("dejavu sans")),
      2 => (File_Prefix => new String'("NotoSans"),
            Family_Name => new String'("noto sans")));

   --  macOS UI fonts. Helvetica and HelveticaNeue ship on every install;
   --  Arial is in /System/Library/Fonts/Supplemental on consumer macOS.
   --  (SFNS.ttf reports its family as "System Font", not stable enough to
   --  match against.)
   macOS_Fallback_Fonts : constant array (Positive range 1 .. 3) of Fallback_Font_Entry :=
     (1 => (File_Prefix => new String'("Helvetica"),
            Family_Name => new String'("helvetica")),
      2 => (File_Prefix => new String'("HelveticaNeue"),
            Family_Name => new String'("helvetica neue")),
      3 => (File_Prefix => new String'("Arial"),
            Family_Name => new String'("arial")));

   Windows_Fallback_Fonts : constant array (Positive range 1 .. 2) of Fallback_Font_Entry :=
     (1 => (File_Prefix => new String'("segoeui"),
            Family_Name => new String'("segoe ui")),
      2 => (File_Prefix => new String'("arial"),
            Family_Name => new String'("arial")));

   function Is_Valid_Handle (Handle : Font_Handle) return Boolean is
   begin
      return Handle /= Null_Font
        and then Positive (Handle) <= Positive (Family_Registry.Length);
   end Is_Valid_Handle;

   function Canonical_Handle (Handle : Font_Handle) return Font_Handle is
   begin
      if Is_Valid_Handle (Handle) then
         return Handle;
      end if;
      return Null_Font;
   end Canonical_Handle;

   function Path_Separator (Path : String) return String is
   begin
      for C of Path loop
         if C = '\' then
            return "\";
         end if;
      end loop;
      return "/";
   end Path_Separator;

   function Is_Usable_Font_File (Path : String) return Boolean is
      C_Path : chars_ptr;
      F      : TTF_Font_Access;
   begin
      if Path'Length = 0 then
         return False;
      end if;

      C_Path := New_String (Path);
      F := TTF_OpenFont (C_Path, Default_Font_Size_Px);
      Free (C_Path);

      if F /= null then
         TTF_CloseFont (F);
         return True;
      end if;
      return False;
   end Is_Usable_Font_File;

   function Load_Internal (Path : String; Override_Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  System font scanning — shared infrastructure for Find and Find_Fallback
   ---------------------------------------------------------------------------

   function Has_Font_Extension (Name : String) return Boolean is
      Len : constant Natural := Name'Length;
   begin
      if Len < 4 then
         return False;
      end if;
      declare
         Ext : constant String :=
           Ada.Characters.Handling.To_Lower (Name (Name'Last - 3 .. Name'Last));
      begin
         return Ext = ".ttf" or else Ext = ".otf" or else Ext = ".ttc";
      end;
   end Has_Font_Extension;

   function Starts_With_Prefix (Name, Prefix : String) return Boolean is
      Lower_Name   : constant String := Ada.Characters.Handling.To_Lower (Name);
      Lower_Prefix : constant String := Ada.Characters.Handling.To_Lower (Prefix);
   begin
      if Prefix'Length = 0 then
         return True;  --  empty prefix matches everything
      end if;
      if Lower_Name'Length < Lower_Prefix'Length then
         return False;
      end if;
      return Lower_Name (Lower_Name'First .. Lower_Name'First + Lower_Prefix'Length - 1)
        = Lower_Prefix;
   end Starts_With_Prefix;

   --  Derive a filename prefix from a family name by removing spaces.
   --  E.g. "Noto Sans" -> "NotoSans", "DejaVu Sans" -> "DejaVuSans"
   function Derive_File_Prefix (Family_Name : String) return String is
      Result : String (1 .. Family_Name'Length);
      Len    : Natural := 0;
   begin
      for C of Family_Name loop
         if C /= ' ' then
            Len := Len + 1;
            Result (Len) := C;
         end if;
      end loop;
      return Result (1 .. Len);
   end Derive_File_Prefix;

   type Scan_Candidate is record
      Path   : Unbounded_String;
      Score  : Natural := 0;
   end record;
   type Scan_Candidate_Array is array (1 .. 64) of Scan_Candidate;

   type Scan_State is record
      Candidates : Scan_Candidate_Array;
      Count      : Natural := 0;
   end record;

   procedure Scan_Dir
     (State       : in out Scan_State;
      Dir         : String;
      Name_Prefix : String;
      Family_Name : String)
   is
      use Ada.Directories;
      Search  : Search_Type;
      Dir_Ent : Directory_Entry_Type;
      Sep     : constant String := Path_Separator (Dir);
   begin
      if not Exists (Dir) then
         return;
      end if;

      --  Scan files in this directory
      Start_Search
        (Search,
         Directory => Dir,
         Pattern   => "",
         Filter    => (Ordinary_File => True, others => False));

      while More_Entries (Search) loop
         Get_Next_Entry (Search, Dir_Ent);
         declare
            SN : constant String := Simple_Name (Dir_Ent);
         begin
            if Has_Font_Extension (SN)
              and then Starts_With_Prefix (SN, Name_Prefix)
              and then State.Count < State.Candidates'Last
            then
               --  Peek at metadata and verify family name matches
               declare
                  FP     : constant String := Dir & Sep & SN;
                  C_Path : chars_ptr := New_String (FP);
                  F      : TTF_Font_Access;
               begin
                  F := TTF_OpenFont (C_Path, Default_Font_Size_Px);
                  Free (C_Path);

                  if F /= null then
                     declare
                        Fam_Ptr : constant chars_ptr :=
                          TTF_GetFontFamilyName (F);
                        Fam_Lower : constant String :=
                          (if Fam_Ptr /= Null_Ptr
                           then Ada.Characters.Handling.To_Lower
                                  (Value (Fam_Ptr))
                           else "");
                     begin
                        if Fam_Lower = Family_Name then
                           declare
                              W : constant int := TTF_GetFontWeight (F);
                              Style_Ptr : constant chars_ptr :=
                                TTF_GetFontStyleName (F);
                              St : constant Font_Style_Value :=
                                (if Style_Ptr /= Null_Ptr
                                 then TTF_Style_Name_To_Ada (Value (Style_Ptr))
                                 else Style_Normal);
                              Wd : constant Natural :=
                                Natural (abs (W - 400));
                              Sp : constant Natural :=
                                (if St /= Style_Normal then 1000 else 0);
                           begin
                              State.Count := State.Count + 1;
                              State.Candidates (State.Count) :=
                                (Path  => To_Unbounded_String (FP),
                                 Score => Wd + Sp);
                           end;
                        end if;
                        TTF_CloseFont (F);
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;

      End_Search (Search);

      --  Recurse into subdirectories
      declare
         Sub_Search  : Search_Type;
         Sub_Dir_Ent : Directory_Entry_Type;
      begin
         Start_Search
           (Sub_Search,
            Directory => Dir,
            Pattern   => "",
            Filter    => (Ada.Directories.Directory => True, others => False));

         while More_Entries (Sub_Search) loop
            Get_Next_Entry (Sub_Search, Sub_Dir_Ent);
            declare
               Sub_Name : constant String := Simple_Name (Sub_Dir_Ent);
            begin
               if Sub_Name /= "." and then Sub_Name /= ".." then
                  Scan_Dir (State, Dir & Sep & Sub_Name, Name_Prefix, Family_Name);
                  if State.Count >= State.Candidates'Last then
                     End_Search (Sub_Search);
                     return;
                  end if;
               end if;
            end;
         end loop;

         End_Search (Sub_Search);
      end;
   end Scan_Dir;

   --  Sort candidates by score and load them all.  Returns the handle
   --  of the base (most-regular) face, or Null_Font if nothing matched.
   function Load_Scanned (State : in out Scan_State) return Font_Handle is
   begin
      if State.Count = 0 then
         return Null_Font;
      end if;

      --  Sort by score (simple selection sort, small N)
      for I in 1 .. State.Count - 1 loop
         declare
            Min_J : Natural := I;
         begin
            for J in I + 1 .. State.Count loop
               if State.Candidates (J).Score < State.Candidates (Min_J).Score then
                  Min_J := J;
               end if;
            end loop;
            if Min_J /= I then
               declare
                  Tmp : constant Scan_Candidate := State.Candidates (I);
               begin
                  State.Candidates (I) := State.Candidates (Min_J);
                  State.Candidates (Min_J) := Tmp;
               end;
            end if;
         end;
      end loop;

      --  Load lowest-score (most regular) first as base
      declare
         H : constant Font_Handle :=
           Load_Internal (To_String (State.Candidates (1).Path), "");
      begin
         if H /= Null_Font then
            Log ("system font loaded: " & To_String (State.Candidates (1).Path));

            --  Load remaining as variants (auto-merge by family name)
            for I in 2 .. State.Count loop
               declare
                  Ignore : Font_Handle;
               begin
                  Ignore := Load_Internal (To_String (State.Candidates (I).Path), "");
               end;
            end loop;
         end if;
         return H;
      end;
   end Load_Scanned;

   --  Search system font directories for a font family.
   --  File_Prefix is used as a filename filter to avoid opening every font
   --  file; Family_Name (lowercased) is the authoritative TTF metadata match.
   --  Returns the loaded handle or Null_Font.
   function Search_System_Font
     (Family_Name : String;
      File_Prefix : String) return Font_Handle
   is
      State : Scan_State;
   begin
      case Adi.Build_Target.Platform is
         when Adi.Build_Target.Windows =>
            for Dir of Windows_Fallback_Paths loop
               Scan_Dir (State, Dir.all, File_Prefix, Family_Name);
            end loop;
         when Adi.Build_Target.macOS =>
            for Dir of macOS_Fallback_Paths loop
               Scan_Dir (State, Dir.all, File_Prefix, Family_Name);
            end loop;
            declare
               Home : constant String :=
                 Ada.Environment_Variables.Value ("HOME", "");
            begin
               if Home'Length > 0 then
                  Scan_Dir (State, Home & "/Library/Fonts",
                            File_Prefix, Family_Name);
               end if;
            end;
         when Adi.Build_Target.Linux =>
            for Dir of Linux_Fallback_Paths loop
               Scan_Dir (State, Dir.all, File_Prefix, Family_Name);
            end loop;
      end case;
      return Load_Scanned (State);
   end Search_System_Font;

   ---------------------------------------------------------------------------
   --  Find_Fallback — locate a default system font
   ---------------------------------------------------------------------------

   procedure Find_Fallback is
   begin
      if Fallback_Found then
         return;
      end if;

      case Adi.Build_Target.Platform is
         when Adi.Build_Target.Windows =>
            for FE of Windows_Fallback_Fonts loop
               declare
                  H : constant Font_Handle :=
                    Search_System_Font (FE.Family_Name.all, FE.File_Prefix.all);
               begin
                  if H /= Null_Font then
                     Default_Fallback_Handle := H;
                     Fallback_Found := True;
                     return;
                  end if;
               end;
            end loop;
         when Adi.Build_Target.macOS =>
            for FE of macOS_Fallback_Fonts loop
               declare
                  H : constant Font_Handle :=
                    Search_System_Font (FE.Family_Name.all, FE.File_Prefix.all);
               begin
                  if H /= Null_Font then
                     Default_Fallback_Handle := H;
                     Fallback_Found := True;
                     return;
                  end if;
               end;
            end loop;
         when Adi.Build_Target.Linux =>
            for FE of Linux_Fallback_Fonts loop
               declare
                  H : constant Font_Handle :=
                    Search_System_Font (FE.Family_Name.all, FE.File_Prefix.all);
               begin
                  if H /= Null_Font then
                     Default_Fallback_Handle := H;
                     Fallback_Found := True;
                     return;
                  end if;
               end;
            end loop;
      end case;

      Log ("ERROR: No fallback font found");
      Fallback_Found := True;
   end Find_Fallback;

   function Get_Path (Handle : Font_Handle) return String is
      H : constant Font_Handle := Canonical_Handle (Handle);
   begin
      if H /= Null_Font then
         return To_String (Family_Registry.Element (Positive (H)));
      end if;

      Find_Fallback;
      if Default_Fallback_Handle /= Null_Font then
         return To_String (Family_Registry.Element (Positive (Default_Fallback_Handle)));
      end if;
      return "";
   end Get_Path;

   function Get_Generation (Handle : Font_Handle) return Natural is
      H : constant Font_Handle := Canonical_Handle (Handle);
   begin
      if H = Null_Font then
         return 0;
      end if;
      return Family_Generation.Element (Positive (H));
   end Get_Generation;

   procedure Bump_Generation (Handle : Font_Handle) is
      H     : constant Font_Handle := Canonical_Handle (Handle);
      Index : Positive;
      Value : Natural;
   begin
      if H = Null_Font then
         return;
      end if;

      Index := Positive (H);
      Value := Family_Generation.Element (Index);
      Family_Generation.Replace_Element (Index, Value + 1);
   end Bump_Generation;

   --  Quantization step used to key the sized-font cache.
   --
   --  FreeType internally uses 1/64-px precision but we don't need that
   --  for caching — two sizes a fraction of a pixel apart look
   --  indistinguishable.  We round to 1/2 px, which collapses adjacent
   --  scale values to a single TTF_Font.  Critical for live UI-scale
   --  sliders: at 1/64 step the cache grew unbounded under continuous
   --  drag and every new TTF_Font kept an SDL_IO handle open, eventually
   --  exhausting the process FD table.
   Size_Quantum : constant := 2.0;  --  steps per pixel (1/2 px grain)

   function Quantize_Size (Size : Float) return Natural is
      Q : constant Integer := Integer (Float'Rounding (Size * Size_Quantum));
   begin
      if Q < 1 then
         return 1;
      end if;
      return Natural (Q);
   end Quantize_Size;

   function "=" (L, R : Font_Attributes) return Boolean is
   begin
      return L.Family = R.Family
        and then Quantize_Size (L.Size) = Quantize_Size (R.Size)
        and then L.Weight = R.Weight
        and then L.Style = R.Style
        and then L.Decoration = R.Decoration;
   end "=";

   function Make_Attributes (Family     : Font_Handle;
                             Size       : Float;
                             Weight     : Font_Weight_Value;
                             Style      : Font_Style_Value;
                             Decoration : Text_Decoration_Value)
      return Font_Attributes
   is
      Actual_Size : constant Float :=
        (if Size > 0.0 then Size else Default_Font_Size_Px);
   begin
      return (Family     => Canonical_Handle (Family),
              Size       => Actual_Size,
              Weight     => Weight,
              Style      => Style,
              Decoration => Decoration);
   end Make_Attributes;

   function Decoration_To_Flags (Decoration : Text_Decoration_Value)
      return TTF_FontStyleFlags
   is
      Flags : TTF_FontStyleFlags := TTF_STYLE_NORMAL;
   begin
      case Decoration is
         when Decoration_Underline =>
            Flags := Flags or TTF_STYLE_UNDERLINE;
         when Decoration_Line_Through =>
            Flags := Flags or TTF_STYLE_STRIKETHROUGH;
         when others =>
            null;
      end case;
      return Flags;
   end Decoration_To_Flags;

   function Needs_Bold (Weight : Font_Weight_Value) return Boolean is
   begin
      return Weight in Weight_Semi_Bold | Weight_Bold | Weight_Extra_Bold | Weight_Black;
   end Needs_Bold;

   function Needs_Italic (Style : Font_Style_Value) return Boolean is
   begin
      return Style /= Style_Normal;
   end Needs_Italic;

   type Resolved_Request is record
      Path     : Unbounded_String;
      Flags    : TTF_FontStyleFlags := TTF_STYLE_NORMAL;
      From_Mem : Boolean := False;
      Mem_Addr : System.Address := System.Null_Address;
      Mem_Len  : Storage_Count := 0;
   end record;

   function Resolve_Request (Attrs : Font_Attributes)
      return Resolved_Request
   is
      H                  : constant Font_Handle := Canonical_Handle (Attrs.Family);
      Result             : Resolved_Request :=
        (Path     => To_Unbounded_String (Get_Path (H)),
         Flags    => TTF_STYLE_NORMAL,
         From_Mem => False,
         Mem_Addr => System.Null_Address,
         Mem_Len  => 0);
      Variant_Cursor     : Variant_Maps.Cursor;
      Mem_Cursor         : Memory_Font_Maps.Cursor;
      Weight_Matched     : Boolean := False;
      Style_Matched      : Boolean := False;
   begin
      if H /= Null_Font then
         --  Check memory variants first
         Mem_Cursor := Memory_Variants.Find ((Handle => H,
                                              Weight => Attrs.Weight,
                                              Style  => Attrs.Style));
         if Memory_Font_Maps.Has_Element (Mem_Cursor) then
            declare
               ME : constant Memory_Font_Entry :=
                 Memory_Font_Maps.Element (Mem_Cursor);
            begin
               Result.From_Mem := True;
               Result.Mem_Addr := ME.Addr;
               Result.Mem_Len  := ME.Length;
            end;
            Weight_Matched := True;
            Style_Matched := True;
         elsif Attrs.Style = Style_Oblique then
            Mem_Cursor := Memory_Variants.Find ((Handle => H,
                                                 Weight => Attrs.Weight,
                                                 Style  => Style_Italic));
            if Memory_Font_Maps.Has_Element (Mem_Cursor) then
               declare
                  ME : constant Memory_Font_Entry :=
                    Memory_Font_Maps.Element (Mem_Cursor);
               begin
                  Result.From_Mem := True;
                  Result.Mem_Addr := ME.Addr;
                  Result.Mem_Len  := ME.Length;
               end;
               Weight_Matched := True;
               Style_Matched := True;
            end if;
         end if;

         --  If no memory variant, try filesystem variants
         if not Weight_Matched then
            Variant_Cursor := Variant_Registry.Find ((Handle => H,
                                                      Weight => Attrs.Weight,
                                                      Style  => Attrs.Style));
            if Variant_Maps.Has_Element (Variant_Cursor) then
               Result.Path := Variant_Maps.Element (Variant_Cursor);
               Weight_Matched := True;
               Style_Matched := True;
            elsif Attrs.Style = Style_Oblique then
               Variant_Cursor := Variant_Registry.Find
                 ((Handle => H,
                   Weight => Attrs.Weight,
                   Style  => Style_Italic));
               if Variant_Maps.Has_Element (Variant_Cursor) then
                  Result.Path := Variant_Maps.Element (Variant_Cursor);
                  Weight_Matched := True;
                  Style_Matched := True;
               end if;
            end if;
         end if;

         --  If still no match, try the primary memory variant for this handle
         --  (first registered memory entry) for synthetic fallback
         if not Weight_Matched and then not Memory_Variants.Is_Empty then
            for Pos in Memory_Variants.Iterate loop
               declare
                  K  : constant Variant_Key := Memory_Font_Maps.Key (Pos);
                  ME : constant Memory_Font_Entry :=
                    Memory_Font_Maps.Element (Pos);
               begin
                  if K.Handle = H then
                     Result.From_Mem := True;
                     Result.Mem_Addr := ME.Addr;
                     Result.Mem_Len  := ME.Length;
                     exit;
                  end if;
               end;
            end loop;
         end if;
      else
         --  Null handle: use default fallback
         Find_Fallback;
         if Default_Fallback_Handle /= Null_Font then
            --  Try memory variants first (for Set_Default_Font with
            --  a memory-loaded handle)
            Mem_Cursor := Memory_Variants.Find
              ((Handle => Default_Fallback_Handle,
                Weight => Attrs.Weight,
                Style  => Attrs.Style));
            if Memory_Font_Maps.Has_Element (Mem_Cursor) then
               declare
                  ME : constant Memory_Font_Entry :=
                    Memory_Font_Maps.Element (Mem_Cursor);
               begin
                  Result.From_Mem := True;
                  Result.Mem_Addr := ME.Addr;
                  Result.Mem_Len  := ME.Length;
               end;
               Weight_Matched := True;
               Style_Matched := True;
            end if;

            --  Try filesystem variants
            if not Weight_Matched then
               Variant_Cursor := Variant_Registry.Find
                 ((Handle => Default_Fallback_Handle,
                   Weight => Attrs.Weight,
                   Style  => Attrs.Style));
               if Variant_Maps.Has_Element (Variant_Cursor) then
                  Result.Path := Variant_Maps.Element (Variant_Cursor);
                  Weight_Matched := True;
                  Style_Matched := True;
               elsif Attrs.Style = Style_Oblique then
                  Variant_Cursor := Variant_Registry.Find
                    ((Handle => Default_Fallback_Handle,
                      Weight => Attrs.Weight,
                      Style  => Style_Italic));
                  if Variant_Maps.Has_Element (Variant_Cursor) then
                     Result.Path := Variant_Maps.Element (Variant_Cursor);
                     Weight_Matched := True;
                     Style_Matched := True;
                  end if;
               end if;
            end if;

            --  Last resort: any memory variant for this handle (synthetic)
            if not Weight_Matched and then not Memory_Variants.Is_Empty then
               for Pos in Memory_Variants.Iterate loop
                  declare
                     K  : constant Variant_Key :=
                       Memory_Font_Maps.Key (Pos);
                     ME : constant Memory_Font_Entry :=
                       Memory_Font_Maps.Element (Pos);
                  begin
                     if K.Handle = Default_Fallback_Handle then
                        Result.From_Mem := True;
                        Result.Mem_Addr := ME.Addr;
                        Result.Mem_Len  := ME.Length;
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end if;
      end if;

      if Needs_Bold (Attrs.Weight) and then not Weight_Matched then
         Result.Flags := Result.Flags or TTF_STYLE_BOLD;
      end if;

      if Needs_Italic (Attrs.Style) and then not Style_Matched then
         Result.Flags := Result.Flags or TTF_STYLE_ITALIC;
      end if;

      Result.Flags := Result.Flags or Decoration_To_Flags (Attrs.Decoration);
      return Result;
   end Resolve_Request;

   function Open_Sized_From_Memory
     (Addr  : System.Address;
      Len   : Storage_Count;
      Size  : Float;
      Flags : TTF_FontStyleFlags) return TTF_Font_Access
   is
      Stream : SDL_IOStream_Ptr;
      F      : TTF_Font_Access;
   begin
      if Addr = System.Null_Address or else Len = 0 then
         return null;
      end if;

      Stream := SDL_IOFromConstMem (Addr, Interfaces.C.size_t (Len));
      if Stream = null then
         Log ("ERROR: Failed to create IO stream for memory font");
         return null;
      end if;

      F := TTF_OpenFontIO (Stream, True, Size);
      if F /= null then
         TTF_SetFontHinting (F, TTF_HINTING_LIGHT_SUBPIXEL);
         TTF_SetFontStyle (F, Flags);
         Log ("open sized memory font: size=" & Float'Image (Size)
              & ", flags=" & TTF_FontStyleFlags'Image (Flags));
      else
         declare
            Err : constant chars_ptr := Adi.SDL.SDL_GetError;
         begin
            Log ("ERROR: Failed to open memory font at size"
                 & Float'Image (Size) & " - " & Value (Err));
         end;
      end if;

      return F;
   end Open_Sized_From_Memory;

   function Open_Sized (Path  : String;
                        Size  : Float;
                        Flags : TTF_FontStyleFlags) return TTF_Font_Access
   is
      C_Path : chars_ptr;
      F      : TTF_Font_Access;
   begin
      if Path'Length = 0 then
         return null;
      end if;

      C_Path := New_String (Path);
      F := TTF_OpenFont (C_Path, Size);
      Free (C_Path);

      if F /= null then
         TTF_SetFontHinting (F, TTF_HINTING_LIGHT_SUBPIXEL);
         TTF_SetFontStyle (F, Flags);
      end if;

      if F = null then
         declare
            Err : constant chars_ptr := Adi.SDL.SDL_GetError;
         begin
            Log ("ERROR: Failed to open font " & Path
                                  & " at size" & Float'Image (Size)
                                  & " - " & Value (Err));
         end;
      end if;

      if F /= null then
         Log ("open sized font: path=" & Path
              & ", size=" & Float'Image (Size)
              & ", flags=" & TTF_FontStyleFlags'Image (Flags));
      end if;

      return F;
   end Open_Sized;

   function Load_Internal (Path : String; Override_Name : String) return Font_Handle is
      C_Path     : chars_ptr;
      F          : TTF_Font_Access;
      Family_Str : Unbounded_String;
      Det_Weight : Font_Weight_Value := Weight_Normal;
      Det_Style  : Font_Style_Value  := Style_Normal;
   begin
      --  Open font temporarily to read metadata
      C_Path := New_String (Path);
      F := TTF_OpenFont (C_Path, Default_Font_Size_Px);
      Free (C_Path);

      if F = null then
         declare
            Err : constant chars_ptr := Adi.SDL.SDL_GetError;
         begin
            Log ("ERROR: Failed to open font for metadata: " & Path
                 & " - " & Value (Err));
         end;
         return Null_Font;
      end if;

      --  Read metadata
      if Override_Name'Length > 0 then
         Family_Str := To_Unbounded_String (Override_Name);
      else
         declare
            Name_Ptr : constant chars_ptr := TTF_GetFontFamilyName (F);
         begin
            if Name_Ptr /= Null_Ptr then
               Family_Str := To_Unbounded_String (Value (Name_Ptr));
            else
               Family_Str := To_Unbounded_String ("Unknown");
            end if;
         end;
      end if;

      Det_Weight := TTF_Weight_To_Ada (TTF_GetFontWeight (F));

      declare
         Style_Ptr : constant chars_ptr := TTF_GetFontStyleName (F);
      begin
         if Style_Ptr /= Null_Ptr then
            Det_Style := TTF_Style_Name_To_Ada (Value (Style_Ptr));
         end if;
      end;

      TTF_CloseFont (F);

      --  Check if family already registered
      declare
         Key : constant String :=
           Ada.Characters.Handling.To_Lower (To_String (Family_Str));
         Existing : constant Font_Handle := Lookup (Key);
      begin
         if Existing /= Null_Font then
            --  Add as variant of existing family
            Register_Variant (Existing, Det_Weight, Det_Style, Path);
            Log ("load variant: handle=" & Font_Handle'Image (Existing)
                 & ", family=" & To_String (Family_Str)
                 & ", weight=" & Det_Weight'Image
                 & ", style=" & Det_Style'Image
                 & ", path=" & Path);
            return Existing;
         end if;

         --  New family
         Family_Registry.Append (To_Unbounded_String (Path));
         Family_Generation.Append (0);

         declare
            H : constant Font_Handle :=
              Font_Handle (Family_Registry.Last_Index);
         begin
            Register_Name (To_String (Family_Str), H);
            Register_Variant (H, Det_Weight, Det_Style, Path);
            Log ("load family: handle=" & Font_Handle'Image (H)
                 & ", family=" & To_String (Family_Str)
                 & ", weight=" & Det_Weight'Image
                 & ", style=" & Det_Style'Image
                 & ", path=" & Path);
            return H;
         end;
      end;
   end Load_Internal;

   function Load (Path : String) return Font_Handle is
   begin
      return Load_Internal (Path, "");
   end Load;

   function Load (Path : String; Name : String) return Font_Handle is
   begin
      return Load_Internal (Path, Name);
   end Load;

   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count;
      Name   : String := "") return Font_Handle
   is
      Stream     : SDL_IOStream_Ptr;
      F          : TTF_Font_Access;
      Family_Str : Unbounded_String;
      Det_Weight : Font_Weight_Value := Weight_Normal;
      Det_Style  : Font_Style_Value  := Style_Normal;
   begin
      if Data = System.Null_Address or else Length = 0 then
         return Null_Font;
      end if;

      --  Open font temporarily to read metadata
      Stream := SDL_IOFromConstMem (Data, Interfaces.C.size_t (Length));
      if Stream = null then
         Log ("ERROR: Failed to create IO stream for memory font metadata");
         return Null_Font;
      end if;

      F := TTF_OpenFontIO (Stream, True, Default_Font_Size_Px);
      if F = null then
         declare
            Err : constant chars_ptr := Adi.SDL.SDL_GetError;
         begin
            Log ("ERROR: Failed to open memory font for metadata - "
                 & Value (Err));
         end;
         return Null_Font;
      end if;

      --  Read metadata
      if Name'Length > 0 then
         Family_Str := To_Unbounded_String (Name);
      else
         declare
            Name_Ptr : constant chars_ptr := TTF_GetFontFamilyName (F);
         begin
            if Name_Ptr /= Null_Ptr then
               Family_Str := To_Unbounded_String (Value (Name_Ptr));
            else
               Family_Str := To_Unbounded_String ("Unknown");
            end if;
         end;
      end if;

      Det_Weight := TTF_Weight_To_Ada (TTF_GetFontWeight (F));

      declare
         Style_Ptr : constant chars_ptr := TTF_GetFontStyleName (F);
      begin
         if Style_Ptr /= Null_Ptr then
            Det_Style := TTF_Style_Name_To_Ada (Value (Style_Ptr));
         end if;
      end;

      TTF_CloseFont (F);

      --  Check if family already registered
      declare
         Key : constant String :=
           Ada.Characters.Handling.To_Lower (To_String (Family_Str));
         Existing : constant Font_Handle := Lookup (Key);
         H        : Font_Handle;
      begin
         if Existing /= Null_Font then
            H := Existing;
         else
            --  New family — register with a placeholder path
            Family_Registry.Append
              (To_Unbounded_String ("(memory:" & To_String (Family_Str) & ")"));
            Family_Generation.Append (0);
            H := Font_Handle (Family_Registry.Last_Index);
            Register_Name (To_String (Family_Str), H);
         end if;

         --  Register in memory variants map
         declare
            VK : constant Variant_Key :=
              (Handle => H, Weight => Det_Weight, Style => Det_Style);
         begin
            if Memory_Variants.Contains (VK) then
               Memory_Variants.Replace (VK, (Addr => Data, Length => Length));
            else
               Memory_Variants.Insert (VK, (Addr => Data, Length => Length));
            end if;
         end;

         Bump_Generation (H);
         Log ("load memory font: handle=" & Font_Handle'Image (H)
              & ", family=" & To_String (Family_Str)
              & ", weight=" & Det_Weight'Image
              & ", style=" & Det_Style'Image);
         return H;
      end;
   end Load_From_Memory;

   procedure Register_Variant (Base   : Font_Handle;
                               Weight : Font_Weight_Value;
                               Style  : Font_Style_Value;
                               Path   : String)
   is
      H   : constant Font_Handle := Canonical_Handle (Base);
      Key : constant Variant_Key := (Handle => H, Weight => Weight, Style => Style);
   begin
      if H = Null_Font or else Path'Length = 0 then
         return;
      end if;

      if Variant_Registry.Contains (Key) then
         Variant_Registry.Replace (Key, To_Unbounded_String (Path));
      else
         Variant_Registry.Insert (Key, To_Unbounded_String (Path));
      end if;

      Log ("register variant: handle=" & Font_Handle'Image (H)
           & ", weight=" & Weight'Image
           & ", style=" & Style'Image
           & ", path=" & Path);

      Bump_Generation (H);
   end Register_Variant;

   procedure Register_Name (Name : String; Handle : Font_Handle) is
      Key : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      if Name_Registry.Contains (Key) then
         Name_Registry.Replace (Key, Handle);
      else
         Name_Registry.Insert (Key, Handle);
      end if;
      Log ("register name: """ & Name & """ -> handle=" & Font_Handle'Image (Handle));
   end Register_Name;

   function Lookup (Name : String) return Font_Handle is
      Key    : constant String := Ada.Characters.Handling.To_Lower (Name);
      Cursor : constant Name_Maps.Cursor := Name_Registry.Find (Key);
   begin
      if Name_Maps.Has_Element (Cursor) then
         return Name_Maps.Element (Cursor);
      end if;
      return Null_Font;
   end Lookup;

   function Find (Name : String) return Font_Handle is
      Key : constant String := Ada.Characters.Handling.To_Lower (Name);
      H   : Font_Handle;
   begin
      --  Check if already loaded/registered
      H := Lookup (Key);
      if H /= Null_Font then
         return H;
      end if;

      --  Check negative cache to avoid repeated expensive scans
      if Name_Miss_Cache.Contains (Key) then
         return Null_Font;
      end if;

      --  Search system font directories
      H := Search_System_Font (Key, Derive_File_Prefix (Name));
      if H /= Null_Font then
         Log ("find: resolved """ & Name & """ from system fonts");
      else
         Log ("find: """ & Name & """ not found in system fonts");
         Name_Miss_Cache.Include (Key);
      end if;
      return H;
   end Find;

   function Load_Asset (Asset_Path : String) return Font_Handle is
   begin
      Adi.Assets.Mark_Asset_Loaded;
      if Adi.Assets.Get_Mode = Adi.Assets.Bundle_Mode then
         declare
            BD : constant Adi.Assets.Asset_Data :=
              Adi.Assets.Bundle_Lookup (Asset_Path);
         begin
            if BD.Addr /= System.Null_Address then
               return Load_From_Memory (BD.Addr, BD.Length);
            end if;
            Log ("ERROR: Load_Asset bundle not found: " & Asset_Path);
            return Null_Font;
         end;
      end if;

      declare
         Resolved : constant String := Adi.Assets.Resolve_Path (Asset_Path);
      begin
         if Resolved = "" then
            Log ("ERROR: Load_Asset could not resolve: " & Asset_Path);
            return Null_Font;
         end if;
         return Load (Resolved);
      end;
   end Load_Asset;

   function Load_Asset (Asset_Path : String; Name : String) return Font_Handle is
   begin
      Adi.Assets.Mark_Asset_Loaded;
      if Adi.Assets.Get_Mode = Adi.Assets.Bundle_Mode then
         declare
            BD : constant Adi.Assets.Asset_Data :=
              Adi.Assets.Bundle_Lookup (Asset_Path);
         begin
            if BD.Addr /= System.Null_Address then
               return Load_From_Memory (BD.Addr, BD.Length, Name);
            end if;
            Log ("ERROR: Load_Asset bundle not found: " & Asset_Path);
            return Null_Font;
         end;
      end if;

      declare
         Resolved : constant String := Adi.Assets.Resolve_Path (Asset_Path);
      begin
         if Resolved = "" then
            Log ("ERROR: Load_Asset could not resolve: " & Asset_Path);
            return Null_Font;
         end if;
         return Load (Resolved, Name);
      end;
   end Load_Asset;

   function Get_TTF_Font (Handle : Font_Handle;
                          Size   : Float) return TTF_Font_Access is
   begin
      return Get_TTF_Font
        (Make_Attributes (Family     => Handle,
                          Size       => Size,
                          Weight     => Default_Font_Weight,
                          Style      => Default_Font_Style,
                          Decoration => Default_Text_Decoration));
   end Get_TTF_Font;

   function Get_TTF_Font (Handle     : Font_Handle;
                          Size       : Float;
                          Weight     : Font_Weight_Value;
                          Style      : Font_Style_Value;
                          Decoration : Text_Decoration_Value)
      return TTF_Font_Access
   is
   begin
      return Get_TTF_Font
        (Make_Attributes (Family     => Handle,
                          Size       => Size,
                          Weight     => Weight,
                          Style      => Style,
                          Decoration => Decoration));
   end Get_TTF_Font;

   function Get_TTF_Font (Attrs : Font_Attributes) return TTF_Font_Access
   is
      Norm   : constant Font_Attributes := Make_Attributes
        (Family     => Attrs.Family,
         Size       => Attrs.Size,
         Weight     => Attrs.Weight,
         Style      => Attrs.Style,
         Decoration => Attrs.Decoration);
      H      : constant Font_Handle := Canonical_Handle (Norm.Family);
      Key    : constant Sized_Font_Key :=
        (Attrs      => (Family     => H,
                        Size       => Norm.Size,
                        Weight     => Norm.Weight,
                        Style      => Norm.Style,
                        Decoration => Norm.Decoration),
         Size_Q     => Quantize_Size (Norm.Size),
         Generation => Get_Generation (H));
      Cursor : constant Sized_Font_Maps.Cursor := Sized_Cache.Find (Key);
   begin
      if Sized_Font_Maps.Has_Element (Cursor) then
         Log ("cache hit: family=" & Font_Handle'Image (Key.Attrs.Family)
              & ", size_q=" & Natural'Image (Key.Size_Q)
              & ", weight=" & Key.Attrs.Weight'Image
              & ", style=" & Key.Attrs.Style'Image
              & ", deco=" & Key.Attrs.Decoration'Image
              & ", gen=" & Natural'Image (Key.Generation));
         return Sized_Font_Maps.Element (Cursor);
      end if;

      declare
         Request : constant Resolved_Request := Resolve_Request (Key.Attrs);
         F : TTF_Font_Access;
      begin
         if Request.From_Mem then
            F := Open_Sized_From_Memory (Request.Mem_Addr, Request.Mem_Len,
                                         Key.Attrs.Size, Request.Flags);
            Log ("cache miss -> resolve (memory): family="
                 & Font_Handle'Image (Key.Attrs.Family)
                 & ", size=" & Float'Image (Key.Attrs.Size)
                 & ", flags=" & TTF_FontStyleFlags'Image (Request.Flags));
         else
            F := Open_Sized (To_String (Request.Path),
                             Key.Attrs.Size, Request.Flags);
            Log ("cache miss -> resolve: family="
                 & Font_Handle'Image (Key.Attrs.Family)
                 & ", size=" & Float'Image (Key.Attrs.Size)
                 & ", size_q=" & Natural'Image (Key.Size_Q)
                 & ", weight=" & Key.Attrs.Weight'Image
                 & ", style=" & Key.Attrs.Style'Image
                 & ", deco=" & Key.Attrs.Decoration'Image
                 & ", resolved_path=" & To_String (Request.Path)
                 & ", flags=" & TTF_FontStyleFlags'Image (Request.Flags));
         end if;
         if F /= null then
            Sized_Cache.Insert (Key, F);
         end if;
         return F;
      end;
   end Get_TTF_Font;

   function Measure_Text (Handle    : Font_Handle;
                          Content   : String;
                          Font_Size : Float) return Size_2D is
   begin
      return Measure_Text
        (Attrs   => Make_Attributes (Family     => Handle,
                                     Size       => Font_Size,
                                     Weight     => Default_Font_Weight,
                                     Style      => Default_Font_Style,
                                     Decoration => Default_Text_Decoration),
         Content => Content);
   end Measure_Text;

   function Measure_Text (Handle     : Font_Handle;
                          Content    : String;
                          Font_Size  : Float;
                          Weight     : Font_Weight_Value;
                          Style      : Font_Style_Value;
                          Decoration : Text_Decoration_Value) return Size_2D
   is
   begin
      return Measure_Text
        (Attrs   => Make_Attributes (Family     => Handle,
                                     Size       => Font_Size,
                                     Weight     => Weight,
                                     Style      => Style,
                                     Decoration => Decoration),
         Content => Content);
   end Measure_Text;

   function Measure_Text (Attrs   : Font_Attributes;
                          Content : String) return Size_2D
   is
      F      : constant TTF_Font_Access := Get_TTF_Font (Attrs);
      C_Text : chars_ptr;
      W, H   : aliased int;
      Ignore : Adi.SDL.C_bool;
   begin
      if F = null or else Content'Length = 0 then
         return (0.0, 0.0);
      end if;

      C_Text := New_String (Content);
      Ignore := TTF_GetStringSize (F, C_Text,
                                   size_t (Content'Length),
                                   W'Access, H'Access);
      Free (C_Text);

      return (Pixel_Type (W), Pixel_Type (H));
   end Measure_Text;

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type) return Size_2D is
   begin
      return Measure_Text_Wrapped
        (Attrs      => Make_Attributes (Family     => Handle,
                                        Size       => Font_Size,
                                        Weight     => Default_Font_Weight,
                                        Style      => Default_Font_Style,
                                        Decoration => Default_Text_Decoration),
         Content    => Content,
         Wrap_Width => Wrap_Width);
   end Measure_Text_Wrapped;

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type;
                                  Weight     : Font_Weight_Value;
                                  Style      : Font_Style_Value;
                                  Decoration : Text_Decoration_Value)
      return Size_2D
   is
   begin
      return Measure_Text_Wrapped
        (Attrs      => Make_Attributes (Family     => Handle,
                                        Size       => Font_Size,
                                        Weight     => Weight,
                                        Style      => Style,
                                        Decoration => Decoration),
         Content    => Content,
         Wrap_Width => Wrap_Width);
   end Measure_Text_Wrapped;

   function Measure_Text_Wrapped (Attrs       : Font_Attributes;
                                  Content     : String;
                                  Wrap_Width  : Pixel_Type;
                                  Line_Height : Line_Height_Value :=
                                                  Normal_Line_Height)
      return Size_2D
   is
      F      : constant TTF_Font_Access := Get_TTF_Font (Attrs);
      C_Text : chars_ptr;
      W, H   : aliased int;
      Ignore : Adi.SDL.C_bool;
   begin
      if F = null or else Content'Length = 0 then
         return (0.0, 0.0);
      end if;

      --  Push CSS line-height onto the shared TTF font before measuring;
      --  TTF_GetStringSizeWrapped uses the font's current line skip when
      --  computing the multi-line height.
      TTF_SetFontLineSkip
        (F,
         int (Resolve_Line_Skip_Px
                (Line_Height  => Line_Height,
                 Font_Size_Px => Pixel_Type (Attrs.Size),
                 Font         => F)));

      C_Text := New_String (Content);
      Ignore := TTF_GetStringSizeWrapped (F, C_Text,
                                          size_t (Content'Length),
                                          int (Wrap_Width),
                                          W'Access, H'Access);
      Free (C_Text);

      return (Pixel_Type (W), Pixel_Type (H));
   end Measure_Text_Wrapped;

   function Measure_Min_Text_Width (Attrs   : Font_Attributes;
                                    Content : String) return Pixel_Type
   is
      function Is_Break (C : Character) return Boolean is
        (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

      Max_W      : Pixel_Type := 0.0;
      Word_Start : Integer := Content'First;
      I          : Integer := Content'First;
   begin
      if Content'Length = 0 then
         return 0.0;
      end if;

      while I <= Content'Last loop
         if Is_Break (Content (I)) then
            if I > Word_Start then
               declare
                  W : constant Size_2D :=
                    Measure_Text (Attrs, Content (Word_Start .. I - 1));
               begin
                  if W.Width > Max_W then
                     Max_W := W.Width;
                  end if;
               end;
            end if;
            Word_Start := I + 1;
         end if;
         I := I + 1;
      end loop;

      --  Last word (no trailing break)
      if Word_Start <= Content'Last then
         declare
            W : constant Size_2D :=
              Measure_Text (Attrs, Content (Word_Start .. Content'Last));
         begin
            if W.Width > Max_W then
               Max_W := W.Width;
            end if;
         end;
      end if;

      return Max_W;
   end Measure_Min_Text_Width;

   ---------------------------------------------------------------------------
   --  Line spacing
   ---------------------------------------------------------------------------

   function Natural_Line_Skip_Px (Font : TTF_Font_Access) return Pixel_Type is
      Cur : Font_Skip_Maps.Cursor;
   begin
      if Font = null then
         return 0.0;
      end if;
      Cur := Natural_Skip_Cache.Find (Font);
      if Font_Skip_Maps.Has_Element (Cur) then
         return Font_Skip_Maps.Element (Cur);
      end if;
      declare
         Skip : constant Pixel_Type := Pixel_Type (TTF_GetFontLineSkip (Font));
      begin
         Natural_Skip_Cache.Insert (Font, Skip);
         return Skip;
      end;
   end Natural_Line_Skip_Px;

   function Resolve_Line_Skip_Px
     (Line_Height  : Line_Height_Value;
      Font_Size_Px : Pixel_Type;
      Font         : TTF_Font_Access) return Pixel_Type
   is
      Natural_Skip : constant Pixel_Type :=
        (if Font = null then Font_Size_Px else Natural_Line_Skip_Px (Font));
   begin
      case Line_Height.Kind is
         when LH_Normal =>
            return Pixel_Type'Max (1.0, Natural_Skip);
         when LH_Number =>
            return Pixel_Type'Max
              (1.0, Font_Size_Px * Pixel_Type (Line_Height.Multiplier));
         when LH_Length =>
            return Pixel_Type'Max
              (1.0,
               Adi.Layout_Util.Length_To_Px
                 (Line_Height.Height,
                  Container_Size => Natural_Skip,
                  Font_Size      => Font_Size_Px));
      end case;
   end Resolve_Line_Skip_Px;

   procedure Set_Default_Font (Handle : Font_Handle) is
   begin
      Default_Fallback_Handle := Handle;
      Fallback_Found := Handle /= Null_Font;
   end Set_Default_Font;

   procedure Enable_System_Font_Search is
   begin
      Adi.CSS_Styles.Set_Font_Name_Resolver (Find'Access);
   end Enable_System_Font_Search;

begin
   Adi.CSS_Styles.Set_Font_Name_Resolver (Lookup'Access);
end Adi.Font;
