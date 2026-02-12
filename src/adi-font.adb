with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Adi.Build_Target;
with Adi.SDL;
with Adi.SDL.TTF;           use Adi.SDL.TTF;
with Interfaces.C;          use Interfaces.C;
with Interfaces.C.Strings;  use Interfaces.C.Strings;

package body Adi.Font is
   Debug_Font_Loading : constant Boolean := False;

   procedure Log (Msg : String) is
   begin
      if Debug_Font_Loading then
         Ada.Text_IO.Put_Line ("[Adi.Font] " & Msg);
      end if;
   end Log;

   package Path_Vector is new Ada.Containers.Vectors (Positive, Unbounded_String);
   package Nat_Vector  is new Ada.Containers.Vectors (Positive, Natural);

   Family_Registry    : Path_Vector.Vector;
   Family_Generation  : Nat_Vector.Vector;

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

   type Weight_Style_Key is record
      Weight : Font_Weight_Value;
      Style  : Font_Style_Value;
   end record;

   function "<" (L, R : Weight_Style_Key) return Boolean is
   begin
      if L.Weight /= R.Weight then
         return Font_Weight_Value'Pos (L.Weight) < Font_Weight_Value'Pos (R.Weight);
      end if;
      return Font_Style_Value'Pos (L.Style) < Font_Style_Value'Pos (R.Style);
   end "<";

   type Fallback_Variant_Result is record
      Path           : Unbounded_String;
      Weight_Matched : Boolean := False;
      Style_Matched  : Boolean := False;
   end record;

   package Fallback_Variant_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Weight_Style_Key,
      Element_Type => Fallback_Variant_Result);

   Fallback_Variant_Cache : Fallback_Variant_Maps.Map;

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

   Fallback_Path  : Unbounded_String := Null_Unbounded_String;
   Fallback_Found : Boolean := False;

   type Search_Path_Array is array (Positive range <>) of access constant String;

   Posix_Fallback_Search_Paths : constant Search_Path_Array (1 .. 3) :=
     (new String'("/usr/share/fonts/TTF/DejaVuSans.ttf"),
      new String'("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
      new String'("/usr/share/fonts/noto/NotoSans-Regular.ttf"));

   Windows_Fallback_Search_Paths : constant Search_Path_Array (1 .. 3) :=
     (new String'("C:\Windows\Fonts\segoeui.ttf"),
      new String'("C:\Windows\Fonts\arial.ttf"),
      new String'("C:\Windows\Fonts\tahoma.ttf"));

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

   function Ends_With (S, Suffix : String) return Boolean is
   begin
      return Suffix'Length <= S'Length
        and then S (S'Last - Suffix'Length + 1 .. S'Last) = Suffix;
   end Ends_With;

   function Last_Slash (S : String) return Natural is
   begin
      for I in reverse S'Range loop
         if S (I) = '/' then
            return Natural (I);
         end if;
      end loop;
      return 0;
   end Last_Slash;

   function Last_Dot_After (S : String; Pos : Natural) return Natural is
   begin
      for I in reverse S'Range loop
         if Natural (I) <= Pos then
            return 0;
         elsif S (I) = '.' then
            return Natural (I);
         end if;
      end loop;
      return 0;
   end Last_Dot_After;

   function Dir_Of (Path : String) return String is
      Slash : constant Natural := Last_Slash (Path);
   begin
      if Slash = 0 then
         return ".";
      end if;
      return Path (Path'First .. Integer (Slash - 1));
   end Dir_Of;

   function Name_Of (Path : String) return String is
      Slash : constant Natural := Last_Slash (Path);
   begin
      if Slash = 0 then
         return Path;
      end if;
      return Path (Integer (Slash + 1) .. Path'Last);
   end Name_Of;

   function Stem_Of (Name : String) return String is
      Dot : constant Natural := Last_Dot_After (Name, 0);
   begin
      if Dot = 0 then
         return Name;
      end if;
      return Name (Name'First .. Integer (Dot - 1));
   end Stem_Of;

   function Ext_Of (Name : String) return String is
      Dot : constant Natural := Last_Dot_After (Name, 0);
   begin
      if Dot = 0 then
         return "";
      end if;
      return Name (Integer (Dot) .. Name'Last);
   end Ext_Of;

   function Variant_Base_Stem (Stem : String) return String is
   begin
      if Ends_With (Stem, "-Regular") then
         return Stem (Stem'First .. Stem'Last - 8);
      elsif Ends_With (Stem, "-Book") then
         return Stem (Stem'First .. Stem'Last - 5);
      elsif Ends_With (Stem, "-Roman") then
         return Stem (Stem'First .. Stem'Last - 6);
      else
         return Stem;
      end if;
   end Variant_Base_Stem;

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

   function Build_Variant_Path (Base_Path, Suffix : String) return String is
      Dir       : constant String := Dir_Of (Base_Path);
      Name      : constant String := Name_Of (Base_Path);
      Stem      : constant String := Stem_Of (Name);
      Ext       : constant String := Ext_Of (Name);
      Base_Stem : constant String := Variant_Base_Stem (Stem);
   begin
      if Suffix'Length = 0 then
         return Base_Path;
      end if;
      return Dir & "/" & Base_Stem & Suffix & Ext;
   end Build_Variant_Path;

   procedure Find_Fallback is
      C_Path : chars_ptr;
      F      : TTF_Font_Access;
      procedure Try_Paths (Paths : Search_Path_Array) is
      begin
         for P of Paths loop
            C_Path := New_String (P.all);
            F := TTF_OpenFont (C_Path, Default_Font_Size_Px);
            Free (C_Path);
            if F /= null then
               TTF_CloseFont (F);
               Fallback_Path := To_Unbounded_String (P.all);
               Fallback_Found := True;
               Fallback_Variant_Cache.Clear;
               Log ("fallback base selected: " & P.all);
               return;
            end if;
         end loop;
      end Try_Paths;
   begin
      if Fallback_Found then
         return;
      end if;

      if Adi.Build_Target.Is_Windows then
         Try_Paths (Windows_Fallback_Search_Paths);
      else
         Try_Paths (Posix_Fallback_Search_Paths);
      end if;

      Log ("ERROR: No fallback font found");
      Fallback_Found := True;
      Fallback_Variant_Cache.Clear;
   end Find_Fallback;

   function Resolve_Fallback_Variant (Weight : Font_Weight_Value;
                                      Style  : Font_Style_Value)
      return Fallback_Variant_Result
   is
      Key    : constant Weight_Style_Key := (Weight => Weight, Style => Style);
      Cursor : constant Fallback_Variant_Maps.Cursor :=
        Fallback_Variant_Cache.Find (Key);
      Base_Path : constant String := To_String (Fallback_Path);
      Result : Fallback_Variant_Result :=
        (Path => Fallback_Path, Weight_Matched => False, Style_Matched => False);
      Found : Boolean := False;

      procedure Try_Candidate (Suffix : String;
                               Weight_OK : Boolean;
                               Style_OK  : Boolean) is
         Candidate : constant String := Build_Variant_Path (Base_Path, Suffix);
      begin
         if Found then
            return;
         end if;
         if Is_Usable_Font_File (Candidate) then
            Result := (Path => To_Unbounded_String (Candidate),
                       Weight_Matched => Weight_OK,
                       Style_Matched  => Style_OK);
            Found := True;
         end if;
      end Try_Candidate;

      procedure Try_Weight_Normal (Italic : Boolean) is
      begin
         if Italic then
            Try_Candidate ("-Italic", False, True);
            Try_Candidate ("-Oblique", False, True);
            Try_Candidate ("-RegularItalic", True, True);
            Try_Candidate ("-RegularOblique", True, True);
            Try_Candidate ("-BookItalic", True, True);
            Try_Candidate ("-BookOblique", True, True);
         else
            Try_Candidate ("-Regular", True, True);
            Try_Candidate ("-Book", True, True);
            Try_Candidate ("-Roman", True, True);
         end if;
      end Try_Weight_Normal;

      procedure Try_Weight_With_Style (Base_Suffix : String) is
      begin
         if Style = Style_Normal then
            Try_Candidate (Base_Suffix, True, True);
         else
            Try_Candidate (Base_Suffix & "Italic", True, True);
            Try_Candidate (Base_Suffix & "Oblique", True, True);
            Try_Candidate (Base_Suffix & "-Italic", True, True);
            Try_Candidate (Base_Suffix & "-Oblique", True, True);
         end if;
      end Try_Weight_With_Style;
   begin
      if Fallback_Variant_Maps.Has_Element (Cursor) then
         Log ("fallback variant cache hit for "
              & Weight'Image & "/" & Style'Image
              & " -> " & To_String (Fallback_Variant_Maps.Element (Cursor).Path));
         return Fallback_Variant_Maps.Element (Cursor);
      end if;

      if Style = Style_Normal and then Weight = Weight_Normal then
         Result := (Path => Fallback_Path, Weight_Matched => True, Style_Matched => True);
         Fallback_Variant_Cache.Insert (Key, Result);
         return Result;
      end if;

      case Weight is
         when Weight_Thin =>
            Try_Weight_With_Style ("-Thin");
         when Weight_Extra_Light | Weight_Light =>
            Try_Weight_With_Style ("-ExtraLight");
            Try_Weight_With_Style ("-UltraLight");
            Try_Weight_With_Style ("-Light");
         when Weight_Normal =>
            Try_Weight_Normal (Style /= Style_Normal);
         when Weight_Medium =>
            Try_Weight_With_Style ("-Medium");
         when Weight_Semi_Bold =>
            Try_Weight_With_Style ("-SemiBold");
            Try_Weight_With_Style ("-DemiBold");
         when Weight_Bold =>
            Try_Weight_With_Style ("-Bold");
         when Weight_Extra_Bold =>
            Try_Weight_With_Style ("-ExtraBold");
            Try_Weight_With_Style ("-UltraBold");
         when Weight_Black =>
            Try_Weight_With_Style ("-Black");
            Try_Weight_With_Style ("-Heavy");
      end case;

      if not Found and then Style /= Style_Normal then
         Try_Candidate ("-Italic", False, True);
         Try_Candidate ("-Oblique", False, True);
      end if;

      if not Found and then Weight = Weight_Normal and then Style = Style_Normal then
         Result := (Path => Fallback_Path, Weight_Matched => True, Style_Matched => True);
      elsif not Found then
         Result := (Path => Fallback_Path, Weight_Matched => False, Style_Matched => (Style = Style_Normal));
      end if;

      Fallback_Variant_Cache.Insert (Key, Result);
      Log ("fallback variant resolved for "
           & Weight'Image & "/" & Style'Image
           & " -> " & To_String (Result.Path)
           & " (weight_match=" & Boolean'Image (Result.Weight_Matched)
           & ", style_match=" & Boolean'Image (Result.Style_Matched) & ")");
      return Result;
   end Resolve_Fallback_Variant;

   function Get_Path (Handle : Font_Handle) return String is
      H : constant Font_Handle := Canonical_Handle (Handle);
   begin
      if H /= Null_Font then
         return To_String (Family_Registry.Element (Positive (H)));
      end if;

      Find_Fallback;
      return To_String (Fallback_Path);
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

   function Quantize_Size (Size : Float) return Natural is
      Q : constant Integer := Integer (Float'Rounding (Size * 64.0));
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
      Path  : Unbounded_String;
      Flags : TTF_FontStyleFlags := TTF_STYLE_NORMAL;
   end record;

   function Resolve_Request (Attrs : Font_Attributes)
      return Resolved_Request
   is
      H                  : constant Font_Handle := Canonical_Handle (Attrs.Family);
      Result             : Resolved_Request := (Path => To_Unbounded_String (Get_Path (H)),
                                                Flags => TTF_STYLE_NORMAL);
      Variant_Cursor     : Variant_Maps.Cursor;
      Weight_Matched     : Boolean := False;
      Style_Matched      : Boolean := False;
   begin
      if H /= Null_Font then
         Variant_Cursor := Variant_Registry.Find ((Handle => H,
                                                   Weight => Attrs.Weight,
                                                   Style  => Attrs.Style));
         if Variant_Maps.Has_Element (Variant_Cursor) then
            Result.Path := Variant_Maps.Element (Variant_Cursor);
            Weight_Matched := True;
            Style_Matched := True;
         elsif Attrs.Style = Style_Oblique then
            Variant_Cursor := Variant_Registry.Find ((Handle => H,
                                                      Weight => Attrs.Weight,
                                                      Style  => Style_Italic));
            if Variant_Maps.Has_Element (Variant_Cursor) then
               Result.Path := Variant_Maps.Element (Variant_Cursor);
               Weight_Matched := True;
               Style_Matched := True;
            end if;
         end if;
      else
         declare
            Fallback : constant Fallback_Variant_Result :=
              Resolve_Fallback_Variant (Weight => Attrs.Weight,
                                        Style  => Attrs.Style);
         begin
            Result.Path := Fallback.Path;
            Weight_Matched := Fallback.Weight_Matched;
            Style_Matched := Fallback.Style_Matched;
         end;
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

   function Load (Path : String) return Font_Handle is
   begin
      Family_Registry.Append (To_Unbounded_String (Path));
      Family_Generation.Append (0);
      Log ("load family: handle="
           & Font_Handle'Image (Font_Handle (Family_Registry.Last_Index))
           & ", path=" & Path);
      return Font_Handle (Family_Registry.Last_Index);
   end Load;

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
         F : constant TTF_Font_Access := Open_Sized (To_String (Request.Path),
                                                     Key.Attrs.Size,
                                                     Request.Flags);
      begin
         Log ("cache miss -> resolve: family=" & Font_Handle'Image (Key.Attrs.Family)
              & ", size=" & Float'Image (Key.Attrs.Size)
              & ", size_q=" & Natural'Image (Key.Size_Q)
              & ", weight=" & Key.Attrs.Weight'Image
              & ", style=" & Key.Attrs.Style'Image
              & ", deco=" & Key.Attrs.Decoration'Image
              & ", resolved_path=" & To_String (Request.Path)
              & ", flags=" & TTF_FontStyleFlags'Image (Request.Flags));
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

   function Measure_Text_Wrapped (Attrs      : Font_Attributes;
                                  Content    : String;
                                  Wrap_Width : Pixel_Type) return Size_2D
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
      Ignore := TTF_GetStringSizeWrapped (F, C_Text,
                                          size_t (Content'Length),
                                          int (Wrap_Width),
                                          W'Access, H'Access);
      Free (C_Text);

      return (Pixel_Type (W), Pixel_Type (H));
   end Measure_Text_Wrapped;

end Adi.Font;
