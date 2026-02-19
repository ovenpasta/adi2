with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Build_Target;
with Adi.Log;
with Adi.SDL;
with Adi.SDL.TTF;           use Adi.SDL.TTF;
with Interfaces.C;          use Interfaces.C;
with Interfaces.C.Strings;  use Interfaces.C.Strings;

package body Adi.Font is
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

   type Source_Profile_Kind is
     (Profile_Generic, Profile_Windows_Segoe, Profile_Windows_Arial);

   type Fallback_Source is record
      Profile        : Source_Profile_Kind := Profile_Generic;
      Path_Id        : Positive;
      Name_Id        : Positive;
      Extension_Id   : Positive;
      Regular_Suffix : access constant String;
   end record;

   type Fallback_Source_Array is array (Positive range <>) of Fallback_Source;

   Fallback_Paths : constant array (Positive range 1 .. 5) of access constant String :=
     (1 => new String'("/usr/share/fonts/TTF"),
      2 => new String'("/usr/share/fonts/truetype/dejavu"),
      3 => new String'("/usr/share/fonts/noto"),
      4 => new String'("C:\Windows\Fonts"),
      5 => new String'("C:\WINNT\Fonts"));

   Fallback_Font_Names : constant array (Positive range 1 .. 4) of access constant String :=
     (1 => new String'("DejaVuSans"),
      2 => new String'("NotoSans"),
      3 => new String'("segoeui"),
      4 => new String'("arial"));

   Fallback_Extensions : constant array (Positive range 1 .. 1) of access constant String :=
     (1 => new String'(".ttf"));

   Posix_Fallback_Sources : constant Fallback_Source_Array (1 .. 5) :=
     ((Profile => Profile_Generic, Path_Id => 1, Name_Id => 1, Extension_Id => 1, Regular_Suffix => new String'("-Regular")),
      (Profile => Profile_Generic, Path_Id => 1, Name_Id => 1, Extension_Id => 1, Regular_Suffix => new String'("")),
      (Profile => Profile_Generic, Path_Id => 2, Name_Id => 1, Extension_Id => 1, Regular_Suffix => new String'("-Regular")),
      (Profile => Profile_Generic, Path_Id => 2, Name_Id => 1, Extension_Id => 1, Regular_Suffix => new String'("")),
      (Profile => Profile_Generic, Path_Id => 3, Name_Id => 2, Extension_Id => 1, Regular_Suffix => new String'("-Regular")));

   Windows_Fallback_Sources : constant Fallback_Source_Array (1 .. 4) :=
     ((Profile => Profile_Windows_Segoe, Path_Id => 4, Name_Id => 3, Extension_Id => 1, Regular_Suffix => new String'("")),
      (Profile => Profile_Windows_Segoe, Path_Id => 5, Name_Id => 3, Extension_Id => 1, Regular_Suffix => new String'("")),
      (Profile => Profile_Windows_Arial, Path_Id => 4, Name_Id => 4, Extension_Id => 1, Regular_Suffix => new String'("")),
      (Profile => Profile_Windows_Arial, Path_Id => 5, Name_Id => 4, Extension_Id => 1, Regular_Suffix => new String'("")));

   Selected_Fallback_Source : Fallback_Source := Posix_Fallback_Sources (1);

   type Suffix_Rule is record
      Profile        : Source_Profile_Kind;
      Weight         : Font_Weight_Value;
      Style          : Font_Style_Value;
      Suffix         : access constant String;
      Weight_Matched : Boolean;
      Style_Matched  : Boolean;
   end record;

   type Suffix_Rule_Array is array (Positive range <>) of Suffix_Rule;

   Fallback_Suffix_Rules : constant Suffix_Rule_Array :=
     (
      -- Generic normal style
      (Profile_Generic, Weight_Thin,        Style_Normal, new String'("-Thin"),      True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Normal, new String'("-ExtraLight"), True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Normal, new String'("-UltraLight"), True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Normal, new String'("-Light"),      True, True),
      (Profile_Generic, Weight_Light,       Style_Normal, new String'("-ExtraLight"), True, True),
      (Profile_Generic, Weight_Light,       Style_Normal, new String'("-UltraLight"), True, True),
      (Profile_Generic, Weight_Light,       Style_Normal, new String'("-Light"),      True, True),
      (Profile_Generic, Weight_Medium,      Style_Normal, new String'("-Medium"),     True, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Normal, new String'("-SemiBold"),   True, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Normal, new String'("-DemiBold"),   True, True),
      (Profile_Generic, Weight_Bold,        Style_Normal, new String'("-Bold"),       True, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Normal, new String'("-ExtraBold"),  True, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Normal, new String'("-UltraBold"),  True, True),
      (Profile_Generic, Weight_Black,       Style_Normal, new String'("-Black"),      True, True),
      (Profile_Generic, Weight_Black,       Style_Normal, new String'("-Heavy"),      True, True),

      -- Generic normal-weight italic/oblique forms
      (Profile_Generic, Weight_Normal, Style_Italic, new String'("-Italic"),          False, True),
      (Profile_Generic, Weight_Normal, Style_Italic, new String'("-Oblique"),         False, True),
      (Profile_Generic, Weight_Normal, Style_Italic, new String'("-RegularItalic"),    True, True),
      (Profile_Generic, Weight_Normal, Style_Italic, new String'("-RegularOblique"),   True, True),
      (Profile_Generic, Weight_Normal, Style_Italic, new String'("-BookItalic"),       True, True),
      (Profile_Generic, Weight_Normal, Style_Italic, new String'("-BookOblique"),      True, True),

      -- Generic weighted italic/oblique forms
      (Profile_Generic, Weight_Thin,        Style_Italic, new String'("-ThinItalic"),       True, True),
      (Profile_Generic, Weight_Thin,        Style_Italic, new String'("-ThinOblique"),      True, True),
      (Profile_Generic, Weight_Thin,        Style_Italic, new String'("-Thin-Italic"),      True, True),
      (Profile_Generic, Weight_Thin,        Style_Italic, new String'("-Thin-Oblique"),     True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-ExtraLightItalic"), True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-ExtraLightOblique"), True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-UltraLightItalic"), True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-UltraLightOblique"), True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-LightItalic"),      True, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-LightOblique"),     True, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-ExtraLightItalic"), True, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-ExtraLightOblique"), True, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-UltraLightItalic"), True, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-UltraLightOblique"), True, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-LightItalic"),      True, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-LightOblique"),     True, True),
      (Profile_Generic, Weight_Medium,      Style_Italic, new String'("-MediumItalic"),     True, True),
      (Profile_Generic, Weight_Medium,      Style_Italic, new String'("-MediumOblique"),    True, True),
      (Profile_Generic, Weight_Medium,      Style_Italic, new String'("-Medium-Italic"),    True, True),
      (Profile_Generic, Weight_Medium,      Style_Italic, new String'("-Medium-Oblique"),   True, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Italic, new String'("-SemiBoldItalic"),   True, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Italic, new String'("-SemiBoldOblique"),  True, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Italic, new String'("-DemiBoldItalic"),   True, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Italic, new String'("-DemiBoldOblique"),  True, True),
      (Profile_Generic, Weight_Bold,        Style_Italic, new String'("-BoldItalic"),       True, True),
      (Profile_Generic, Weight_Bold,        Style_Italic, new String'("-BoldOblique"),      True, True),
      (Profile_Generic, Weight_Bold,        Style_Italic, new String'("-Bold-Italic"),      True, True),
      (Profile_Generic, Weight_Bold,        Style_Italic, new String'("-Bold-Oblique"),     True, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Italic, new String'("-ExtraBoldItalic"),  True, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Italic, new String'("-ExtraBoldOblique"), True, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Italic, new String'("-UltraBoldItalic"),  True, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Italic, new String'("-UltraBoldOblique"), True, True),
      (Profile_Generic, Weight_Black,       Style_Italic, new String'("-BlackItalic"),      True, True),
      (Profile_Generic, Weight_Black,       Style_Italic, new String'("-BlackOblique"),     True, True),
      (Profile_Generic, Weight_Black,       Style_Italic, new String'("-HeavyItalic"),      True, True),
      (Profile_Generic, Weight_Black,       Style_Italic, new String'("-HeavyOblique"),     True, True),

      -- Generic style fallback (all weights)
      (Profile_Generic, Weight_Thin,        Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Thin,        Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Extra_Light, Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Light,       Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Normal,      Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Normal,      Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Medium,      Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Medium,      Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Semi_Bold,   Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Bold,        Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Bold,        Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Extra_Bold,  Style_Italic, new String'("-Oblique"), False, True),
      (Profile_Generic, Weight_Black,       Style_Italic, new String'("-Italic"), False, True),
      (Profile_Generic, Weight_Black,       Style_Italic, new String'("-Oblique"), False, True),

      -- Windows Segoe rules
      (Profile_Windows_Segoe, Weight_Thin,        Style_Normal, new String'("l"),  True, True),
      (Profile_Windows_Segoe, Weight_Thin,        Style_Normal, new String'("sl"), True, True),
      (Profile_Windows_Segoe, Weight_Thin,        Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Segoe, Weight_Extra_Light, Style_Normal, new String'("l"),  True, True),
      (Profile_Windows_Segoe, Weight_Extra_Light, Style_Normal, new String'("sl"), True, True),
      (Profile_Windows_Segoe, Weight_Extra_Light, Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Segoe, Weight_Light,       Style_Normal, new String'("l"),  True, True),
      (Profile_Windows_Segoe, Weight_Light,       Style_Normal, new String'("sl"), True, True),
      (Profile_Windows_Segoe, Weight_Light,       Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Segoe, Weight_Thin,        Style_Italic, new String'("l"),  True, False),
      (Profile_Windows_Segoe, Weight_Thin,        Style_Italic, new String'("sl"), True, False),
      (Profile_Windows_Segoe, Weight_Thin,        Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Segoe, Weight_Thin,        Style_Italic, new String'(""),   False, False),
      (Profile_Windows_Segoe, Weight_Extra_Light, Style_Italic, new String'("l"),  True, False),
      (Profile_Windows_Segoe, Weight_Extra_Light, Style_Italic, new String'("sl"), True, False),
      (Profile_Windows_Segoe, Weight_Extra_Light, Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Segoe, Weight_Extra_Light, Style_Italic, new String'(""),   False, False),
      (Profile_Windows_Segoe, Weight_Light,       Style_Italic, new String'("l"),  True, False),
      (Profile_Windows_Segoe, Weight_Light,       Style_Italic, new String'("sl"), True, False),
      (Profile_Windows_Segoe, Weight_Light,       Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Segoe, Weight_Light,       Style_Italic, new String'(""),   False, False),
      (Profile_Windows_Segoe, Weight_Medium,      Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Segoe, Weight_Medium,      Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Segoe, Weight_Normal,      Style_Normal, new String'(""),   True, True),
      (Profile_Windows_Segoe, Weight_Normal,      Style_Italic, new String'("i"),  True, True),
      (Profile_Windows_Segoe, Weight_Black,       Style_Normal, new String'("b"),  True, True),
      (Profile_Windows_Segoe, Weight_Black,       Style_Italic, new String'("z"),  False, True),
      (Profile_Windows_Segoe, Weight_Black,       Style_Italic, new String'("b"),  True, False),
      (Profile_Windows_Segoe, Weight_Semi_Bold,   Style_Normal, new String'("b"),  True, True),
      (Profile_Windows_Segoe, Weight_Semi_Bold,   Style_Italic, new String'("z"),  True, True),
      (Profile_Windows_Segoe, Weight_Semi_Bold,   Style_Italic, new String'("b"),  True, False),
      (Profile_Windows_Segoe, Weight_Bold,        Style_Normal, new String'("b"),  True, True),
      (Profile_Windows_Segoe, Weight_Bold,        Style_Italic, new String'("z"),  True, True),
      (Profile_Windows_Segoe, Weight_Bold,        Style_Italic, new String'("b"),  True, False),
      (Profile_Windows_Segoe, Weight_Extra_Bold,  Style_Normal, new String'("b"),  True, True),
      (Profile_Windows_Segoe, Weight_Extra_Bold,  Style_Italic, new String'("z"),  True, True),
      (Profile_Windows_Segoe, Weight_Extra_Bold,  Style_Italic, new String'("b"),  True, False),

      -- Windows Arial rules
      (Profile_Windows_Arial, Weight_Thin,        Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Arial, Weight_Extra_Light, Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Arial, Weight_Light,       Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Arial, Weight_Thin,        Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Arial, Weight_Extra_Light, Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Arial, Weight_Light,       Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Arial, Weight_Medium,      Style_Normal, new String'(""),   False, True),
      (Profile_Windows_Arial, Weight_Medium,      Style_Italic, new String'("i"),  False, True),
      (Profile_Windows_Arial, Weight_Normal,      Style_Normal, new String'(""),   True, True),
      (Profile_Windows_Arial, Weight_Normal,      Style_Italic, new String'("i"),  True, True),
      (Profile_Windows_Arial, Weight_Black,       Style_Normal, new String'("bd"), True, True),
      (Profile_Windows_Arial, Weight_Black,       Style_Italic, new String'("bi"), False, True),
      (Profile_Windows_Arial, Weight_Black,       Style_Italic, new String'("bd"), True, False),
      (Profile_Windows_Arial, Weight_Semi_Bold,   Style_Normal, new String'("bd"), True, True),
      (Profile_Windows_Arial, Weight_Semi_Bold,   Style_Italic, new String'("bi"), True, True),
      (Profile_Windows_Arial, Weight_Semi_Bold,   Style_Italic, new String'("bd"), True, False),
      (Profile_Windows_Arial, Weight_Bold,        Style_Normal, new String'("bd"), True, True),
      (Profile_Windows_Arial, Weight_Bold,        Style_Italic, new String'("bi"), True, True),
      (Profile_Windows_Arial, Weight_Bold,        Style_Italic, new String'("bd"), True, False),
      (Profile_Windows_Arial, Weight_Extra_Bold,  Style_Normal, new String'("bd"), True, True),
      (Profile_Windows_Arial, Weight_Extra_Bold,  Style_Italic, new String'("bi"), True, True),
      (Profile_Windows_Arial, Weight_Extra_Bold,  Style_Italic, new String'("bd"), True, False)
     );

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

   function Build_Font_Path (Source : Fallback_Source;
                             Suffix : String) return String
   is
      Path : constant String := Fallback_Paths (Source.Path_Id).all;
      Sep  : constant String := Path_Separator (Path);
   begin
      return Path
        & Sep
        & Fallback_Font_Names (Source.Name_Id).all
        & Suffix
        & Fallback_Extensions (Source.Extension_Id).all;
   end Build_Font_Path;

   function Build_Regular_Font_Path (Source : Fallback_Source) return String is
   begin
      return Build_Font_Path (Source, Source.Regular_Suffix.all);
   end Build_Regular_Font_Path;

   procedure Find_Fallback is
      procedure Try_Sources (Sources : Fallback_Source_Array) is
      begin
         for Source of Sources loop
            declare
               Candidate : constant String := Build_Regular_Font_Path (Source);
            begin
               if Is_Usable_Font_File (Candidate) then
                  Fallback_Path := To_Unbounded_String (Candidate);
                  Selected_Fallback_Source := Source;
                  Fallback_Found := True;
                  Fallback_Variant_Cache.Clear;
                  Log ("fallback base selected: " & Candidate);
                  return;
               end if;
            end;
         end loop;
      end Try_Sources;
   begin
      if Fallback_Found then
         return;
      end if;

      if Adi.Build_Target.Is_Windows then
         Try_Sources (Windows_Fallback_Sources);
      else
         Try_Sources (Posix_Fallback_Sources);
      end if;

      if Fallback_Found then
         return;
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
      Source : constant Fallback_Source := Selected_Fallback_Source;
      Result : Fallback_Variant_Result :=
        (Path => Fallback_Path, Weight_Matched => False, Style_Matched => False);
      Found : Boolean := False;
      Requested_Style : constant Font_Style_Value :=
        (if Style = Style_Normal then Style_Normal else Style_Italic);

      procedure Try_Candidate (Suffix    : String;
                               Weight_OK : Boolean;
                               Style_OK  : Boolean) is
         Candidate : constant String := Build_Font_Path (Source, Suffix);
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

      procedure Apply_Suffix_Rules is
      begin
         for Rule of Fallback_Suffix_Rules loop
            if Rule.Profile = Source.Profile
              and then Rule.Weight = Weight
              and then Rule.Style = Requested_Style
            then
               Try_Candidate (Suffix    => Rule.Suffix.all,
                              Weight_OK => Rule.Weight_Matched,
                              Style_OK  => Rule.Style_Matched);
            end if;
         end loop;
      end Apply_Suffix_Rules;
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

      Apply_Suffix_Rules;

      if not Found then
         Try_Candidate (Suffix    => Source.Regular_Suffix.all,
                        Weight_OK => False,
                        Style_OK  => (Style = Style_Normal));
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

end Adi.Font;
