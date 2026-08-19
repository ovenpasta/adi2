--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with System;
with System.Storage_Elements;
with Adi.Core;       use Adi.Core;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.SDL.TTF;    use Adi.SDL.TTF;

package Adi.Font is

   Default_Font_Size_Px : constant Float := Default_Font_Size.Amount;

   --  SDL aligns wrapped lines three ways, and only per font.
   type Wrap_Alignment is (Wrap_Left, Wrap_Center, Wrap_Right);

   --  A font's full identity, layout state included. Line skip and wrap
   --  alignment are font-level state in SDL: setting either re-lays every
   --  TTF_Text built from that font. Carrying them here makes each
   --  combination its own cached instance, set once when it is opened and
   --  never mutated, so widgets that share a family and size but differ in
   --  line-height or alignment cannot disturb each other.
   type Font_Attributes is record
      Family     : Font_Handle := Default_Font;
      Size       : Float := Default_Font_Size_Px;
      Weight     : Font_Weight_Value := Default_Font_Weight;
      Style      : Font_Style_Value := Default_Font_Style;
      Decoration : Text_Decoration_Value := Default_Text_Decoration;
      --  The exact integer handed to TTF_SetFontLineSkip, or 0 to leave
      --  the font's own spacing alone. Storing what is applied rather
      --  than a rounded-off pixel value keeps identity and applied state
      --  from ever disagreeing.
      Line_Skip  : Natural := 0;
      Wrap_Align : Wrap_Alignment := Wrap_Left;
   end record;

   function "=" (L, R : Font_Attributes) return Boolean;

   Default_Font_Attributes : constant Font_Attributes :=
     (Family     => Default_Font,
      Size       => Default_Font_Size_Px,
      Weight     => Default_Font_Weight,
      Style      => Default_Font_Style,
      Decoration => Default_Text_Decoration,
      Line_Skip  => 0,
      Wrap_Align => Wrap_Left);

   function Quantize_Size (Size : Float) return Natural;

   function Make_Attributes (Family     : Font_Handle;
                             Size       : Float;
                             Weight     : Font_Weight_Value;
                             Style      : Font_Style_Value;
                             Decoration : Text_Decoration_Value;
                             Line_Skip  : Natural := 0;
                             Wrap_Align : Wrap_Alignment := Wrap_Left)
      return Font_Attributes;

   --  The wrap alignment an attribute set should carry. SDL aligns lines
   --  within the wrap width, so text that does not wrap has no box to be
   --  aligned in and always asks for Wrap_Left; Label positions that case
   --  itself. `justify` is not implemented and reads as left; `end` reads
   --  as right, there being no RTL support.
   function Wrap_Alignment_For
     (Align : Text_Align_Value;
      Wraps : Boolean) return Wrap_Alignment;

   --  The line skip an attribute set should carry for a CSS line-height:
   --  0 when the font's own spacing is wanted (`normal`), otherwise the
   --  integer SDL will be given. Needs no font, so the cache key can be
   --  built before one is opened.
   function Line_Skip_Override
     (Line_Height  : Line_Height_Value;
      Font_Size_Px : Pixel_Type) return Natural;

   ---------------------------------------------------------------------------
   --  Font loading — registers a font family file, returns a handle.
   --  Sized TTF_Font instances are created on demand and cached internally.
   --
   --  Load(Path) opens the font temporarily to auto-detect family name,
   --  weight, and style from TTF metadata.  If a font with the same family
   --  name was already loaded, the new file is registered as a variant of
   --  the existing handle (same handle is returned).
   --
   --  Load(Path, Name) uses the provided Name instead of the auto-detected
   --  family name for registry lookup/insertion.
   ---------------------------------------------------------------------------

   function Load (Path : String) return Font_Handle;
   function Load (Path : String; Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  Memory-based font loading — register a font from in-memory data.
   --
   --  Data must point to a static-lifetime buffer (e.g. a library-level
   --  Storage_Array constant) because TTF_OpenFontIO reads glyphs on demand.
   --  The buffer must outlive all sized font instances derived from this handle.
   --
   --  If Name is empty, the family name is auto-detected from TTF metadata.
   ---------------------------------------------------------------------------

   function Load_From_Memory
     (Data   : System.Address;
      Length : System.Storage_Elements.Storage_Count;
      Name   : String := "") return Font_Handle;
   procedure Register_Variant (Base   : Font_Handle;
                               Weight : Font_Weight_Value;
                               Style  : Font_Style_Value;
                               Path   : String);

   ---------------------------------------------------------------------------
   --  Name registry — register / look up fonts by family name.
   --
   --  Register_Name  — create a case-insensitive alias for an existing handle.
   --  Lookup         — return the handle for a registered name, or Null_Font.
   ---------------------------------------------------------------------------

   procedure Register_Name (Name : String; Handle : Font_Handle);
   function Lookup (Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  System font search.
   --
   --  Find searches system font directories recursively for a font whose TTF
   --  family name matches Name (case-insensitive).  If found, all weight/style
   --  variants are loaded and the family handle is returned.
   --
   --  Checks the name registry first; already-loaded fonts are returned
   --  immediately without scanning.  Names that were previously searched and
   --  not found are cached, so repeated misses are cheap.
   --
   --  System directories searched:
   --    Linux:   /usr/share/fonts, /usr/local/share/fonts,
   --             /usr/share/fonts/truetype
   --    macOS:   /System/Library/Fonts (incl. Supplemental/),
   --             /Library/Fonts, $HOME/Library/Fonts
   --    Windows: C:\Windows\Fonts, C:\WINNT\Fonts
   ---------------------------------------------------------------------------

   function Find (Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  CSS font-family resolution mode.
   --
   --  By default, CSS font-family only resolves names registered via Load,
   --  Find, or Register_Name.  Calling Enable_System_Font_Search switches
   --  the resolver to use Find, so unregistered names trigger a system font
   --  search on first use.
   --
   --  The generic families -- sans-serif, serif and monospace -- resolve in
   --  either mode. They are names CSS defines rather than names of anything
   --  installed, so an application that has not opened lookup to arbitrary
   --  families still gets a monospace face from "monospace". Each is tried
   --  against a per-platform list of candidates and answered by the first
   --  one present; a name registered for the generic itself wins over that.
   --  Resolution happens on first use and is kept, so nothing is scanned
   --  for a generic the program never asks about.
   ---------------------------------------------------------------------------

   procedure Enable_System_Font_Search;

   ---------------------------------------------------------------------------
   --  Asset-relative loading — resolve via Adi.Assets then Load.
   ---------------------------------------------------------------------------

   function Load_Asset (Asset_Path : String) return Font_Handle;
   function Load_Asset (Asset_Path : String; Name : String) return Font_Handle;

   ---------------------------------------------------------------------------
   --  Default font — set the font used when a widget has no font-family.
   --  Overrides the automatic system font fallback (DejaVu Sans, etc.).
   ---------------------------------------------------------------------------

   procedure Set_Default_Font (Handle : Font_Handle);

   --  Advances whenever anything that changes text metrics changes: a
   --  variant registered, a family's faces replaced, a different default
   --  font chosen. Family, size and the scales can all stay put across
   --  such a change, so a cache keyed on those alone would not notice
   --  it. Compare this alongside them.
   --
   --  Modular, so it wraps instead of raising: only equality matters,
   --  and two keys can only alias after exactly 2**32 changes between
   --  storing one and comparing it.
   --
   --  It makes the next resolution correct; it does not repaint what is
   --  already on screen. Nothing here can mark a widget dirty -- widgets
   --  depend on fonts, not the other way round -- so a font registered
   --  while a window is up reaches it when something else invalidates
   --  that widget, or when the caller asks for a rebuild, the way CSS
   --  live reload does.
   type Font_Generation is mod 2 ** 32;
   function Environment_Generation return Font_Generation;

   ---------------------------------------------------------------------------
   --  Font access — returns a TTF_Font opened at the given point size.
   --  Each (Handle, Size) pair is cached: first call opens the font,
   --  subsequent calls return the cached instance.
   --  When Handle is Null_Font, returns a fallback system font.
   ---------------------------------------------------------------------------

   function Get_TTF_Font (Handle : Font_Handle;
                          Size   : Float) return TTF_Font_Access;

   function Get_TTF_Font (Handle     : Font_Handle;
                          Size       : Float;
                          Weight     : Font_Weight_Value;
                          Style      : Font_Style_Value;
                          Decoration : Text_Decoration_Value)
      return TTF_Font_Access;

   function Get_TTF_Font (Attrs : Font_Attributes) return TTF_Font_Access;

   ---------------------------------------------------------------------------
   --  Text measurement
   ---------------------------------------------------------------------------

   function Measure_Text (Handle    : Font_Handle;
                          Content   : String;
                          Font_Size : Float) return Size_2D;

   function Measure_Text (Handle     : Font_Handle;
                          Content    : String;
                          Font_Size  : Float;
                          Weight     : Font_Weight_Value;
                          Style      : Font_Style_Value;
                          Decoration : Text_Decoration_Value) return Size_2D;

   function Measure_Text (Attrs   : Font_Attributes;
                          Content : String) return Size_2D;

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type) return Size_2D;

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type;
                                  Weight     : Font_Weight_Value;
                                  Style      : Font_Style_Value;
                                  Decoration : Text_Decoration_Value)
      return Size_2D;

   --  Wrapped height follows Attrs.Line_Skip, so the caller resolves the
   --  CSS line-height into the attributes it asks with. Taking it as a
   --  separate argument here would let it contradict the identity the
   --  rest of Font_Attributes now carries.
   function Measure_Text_Wrapped (Attrs      : Font_Attributes;
                                  Content    : String;
                                  Wrap_Width : Pixel_Type) return Size_2D;

   --  Return the width of the longest word in Content.
   --  Words are separated by spaces, tabs, and newlines.
   --  This gives the minimum intrinsic width for wrappable text.
   function Measure_Min_Text_Width (Attrs   : Font_Attributes;
                                    Content : String) return Pixel_Type;

   ---------------------------------------------------------------------------
   --  Line spacing
   ---------------------------------------------------------------------------

   --  Font's intrinsic line skip in pixels, captured on first acquisition
   --  before any TTF_SetFontLineSkip override may have mutated it.  Cached
   --  per Font pointer.
   function Natural_Line_Skip_Px (Font : TTF_Font_Access) return Pixel_Type;

   --  Resolve a CSS line-height into an absolute pixel line-skip:
   --    LH_Normal -> Natural_Line_Skip_Px (Font)
   --    LH_Number -> Font_Size_Px * Multiplier
   --    LH_Length -> length resolved against the font size, percentages
   --                 included
   --  Applying this to a font is Get_TTF_Font's job, through the Line_Skip
   --  field of Font_Attributes; nothing else may set it on a shared font.
   function Resolve_Line_Skip_Px
     (Line_Height  : Line_Height_Value;
      Font_Size_Px : Pixel_Type;
      Font         : TTF_Font_Access) return Pixel_Type;

end Adi.Font;
