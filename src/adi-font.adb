with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Adi.SDL;
with Interfaces.C;          use Interfaces.C;
with Interfaces.C.Strings;  use Interfaces.C.Strings;

package body Adi.Font is

   ---------------------------------------------------------------------------
   --  Family registry — maps Font_Handle to file path
   ---------------------------------------------------------------------------

   package Path_Vector is new Ada.Containers.Vectors (Positive, Unbounded_String);

   Family_Registry : Path_Vector.Vector;

   ---------------------------------------------------------------------------
   --  Sized font cache — maps (Handle, Size) to a TTF_Font instance
   ---------------------------------------------------------------------------

   type Sized_Font_Key is record
      Handle : Font_Handle;
      Size   : Float;
   end record;

   function "<" (L, R : Sized_Font_Key) return Boolean is
   begin
      if L.Handle /= R.Handle then
         return L.Handle < R.Handle;
      end if;
      return L.Size < R.Size;
   end "<";

   package Sized_Font_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Sized_Font_Key,
      Element_Type => TTF_Font_Access);

   Sized_Cache : Sized_Font_Maps.Map;

   ---------------------------------------------------------------------------
   --  Fallback font — found once from well-known system paths
   ---------------------------------------------------------------------------

   Fallback_Path  : Unbounded_String := Null_Unbounded_String;
   Fallback_Found : Boolean := False;

   Fallback_Search_Paths : constant array (1 .. 3) of access constant String :=
     (new String'("/usr/share/fonts/TTF/DejaVuSans.ttf"),
      new String'("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
      new String'("/usr/share/fonts/noto/NotoSans-Regular.ttf"));

   procedure Find_Fallback is
      C_Path : chars_ptr;
      F      : TTF_Font_Access;
   begin
      if Fallback_Found then
         return;
      end if;

      for P of Fallback_Search_Paths loop
         C_Path := New_String (P.all);
         F := TTF_OpenFont (C_Path, 16.0);
         Free (C_Path);
         if F /= null then
            TTF_CloseFont (F);
            Fallback_Path := To_Unbounded_String (P.all);
            Fallback_Found := True;
            return;
         end if;
      end loop;

      Ada.Text_IO.Put_Line ("ERROR: No fallback font found");
      Fallback_Found := True;  --  Don't search again
   end Find_Fallback;

   ---------------------------------------------------------------------------
   --  Internal: get file path for a handle
   ---------------------------------------------------------------------------

   function Get_Path (Handle : Font_Handle) return String is
   begin
      if Handle /= Null_Font
        and then Positive (Handle) <= Positive (Family_Registry.Length)
      then
         return To_String (Family_Registry.Element (Positive (Handle)));
      end if;

      Find_Fallback;
      return To_String (Fallback_Path);
   end Get_Path;

   ---------------------------------------------------------------------------
   --  Internal: open a TTF_Font from path at size
   ---------------------------------------------------------------------------

   function Open_Sized (Path : String; Size : Float) return TTF_Font_Access is
      C_Path : chars_ptr;
      F      : TTF_Font_Access;
   begin
      if Path'Length = 0 then
         return null;
      end if;

      C_Path := New_String (Path);
      F := TTF_OpenFont (C_Path, Size);
      Free (C_Path);

      if F = null then
         declare
            Err : constant chars_ptr := Adi.SDL.SDL_GetError;
         begin
            Ada.Text_IO.Put_Line ("ERROR: Failed to open font " & Path
                                  & " at size" & Float'Image (Size)
                                  & " - " & Value (Err));
         end;
      end if;

      return F;
   end Open_Sized;

   ----------
   -- Load --
   ----------

   function Load (Path : String) return Font_Handle is
   begin
      Family_Registry.Append (To_Unbounded_String (Path));
      return Font_Handle (Family_Registry.Last_Index);
   end Load;

   ------------------
   -- Get_TTF_Font --
   ------------------

   function Get_TTF_Font (Handle : Font_Handle;
                          Size   : Float) return TTF_Font_Access
   is
      Key    : constant Sized_Font_Key := (Handle, Size);
      Cursor : constant Sized_Font_Maps.Cursor := Sized_Cache.Find (Key);
   begin
      if Sized_Font_Maps.Has_Element (Cursor) then
         return Sized_Font_Maps.Element (Cursor);
      end if;

      --  Not cached — open a new instance at the requested size
      declare
         Path : constant String := Get_Path (Handle);
         F    : constant TTF_Font_Access := Open_Sized (Path, Size);
      begin
         if F /= null then
            Sized_Cache.Insert (Key, F);
         end if;
         return F;
      end;
   end Get_TTF_Font;

   ------------------
   -- Measure_Text --
   ------------------

   function Measure_Text (Handle    : Font_Handle;
                          Content   : String;
                          Font_Size : Float) return Size_2D
   is
      F      : constant TTF_Font_Access := Get_TTF_Font (Handle, Font_Size);
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

   --------------------------
   -- Measure_Text_Wrapped --
   --------------------------

   function Measure_Text_Wrapped (Handle     : Font_Handle;
                                  Content    : String;
                                  Font_Size  : Float;
                                  Wrap_Width : Pixel_Type) return Size_2D
   is
      F      : constant TTF_Font_Access := Get_TTF_Font (Handle, Font_Size);
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
