with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

package body Adi.SVG.Ada_Cache is

   procedure Free_Cache is new Ada.Unchecked_Deallocation (Cache, Cache_Access);
   procedure Free_Pixel_Buffer is
     new Ada.Unchecked_Deallocation (Pixel_Buffer, Pixel_Buffer_Access);

   function Clone_Buffer (Src : Pixel_Buffer_Access) return Pixel_Buffer_Access is
   begin
      if Src = null then
         return null;
      end if;

      declare
         Dst : constant Pixel_Buffer_Access := new Pixel_Buffer (Src'Range);
      begin
         for I in Src'Range loop
            Dst (I) := Src (I);
         end loop;
         return Dst;
      end;
   end Clone_Buffer;

   function Create return Cache_Access is
   begin
      return new Cache;
   end Create;

   procedure Destroy (Obj : in out Cache_Access) is
   begin
      if Obj /= null then
         for I in 1 .. Natural (Obj.Renders.Length) loop
            declare
               E : Render_Entry := Obj.Renders.Element (Positive (I));
            begin
               if E.Pixels /= null then
                  Free_Pixel_Buffer (E.Pixels);
               end if;
            end;
         end loop;

         Free_Cache (Obj);
      end if;
   end Destroy;

   function Quantize (V : Float) return Integer is
      Scale : constant Float := 1024.0;
   begin
      if V >= 0.0 then
         return Integer (Float'Floor (V * Scale + 0.5));
      else
         return Integer (Float'Ceiling (V * Scale - 0.5));
      end if;
   end Quantize;

   function Key_For (M : Adi.SVG.Parser.Matrix) return Matrix_Key is
   begin
      return
        (A => Quantize (M.A),
         B => Quantize (M.B),
         C => Quantize (M.C),
         D => Quantize (M.D),
         E => Quantize (M.E),
         F => Quantize (M.F));
   end Key_For;

   function Same_Key (L, R : Matrix_Key) return Boolean is
     (L.A = R.A
      and then L.B = R.B
      and then L.C = R.C
      and then L.D = R.D
      and then L.E = R.E
      and then L.F = R.F);

   function Find_Path_Entry
     (Obj      : Cache;
      Path_Pos : Natural;
      D        : String) return Natural
   is
   begin
      for I in 1 .. Natural (Obj.Paths.Length) loop
         declare
            E : constant Path_Entry := Obj.Paths.Element (Positive (I));
         begin
            if E.Pos = Path_Pos and then US.To_String (E.D_Text) = D then
               return I;
            end if;
         end;
      end loop;
      return 0;
   end Find_Path_Entry;

   function Find_Path_Contours
     (Obj      : in out Cache;
      Path_Pos : Natural;
      D        : String;
      M        : Adi.SVG.Parser.Matrix;
      Contours : out Adi.SVG.Parser.Contour_Vectors.Vector) return Boolean
   is
      Entry_Idx : constant Natural := Find_Path_Entry (Obj, Path_Pos, D);
      K         : constant Matrix_Key := Key_For (M);
   begin
      Contours.Clear;

      if Entry_Idx = 0 then
         return False;
      end if;

      declare
         E : constant Path_Entry := Obj.Paths.Element (Positive (Entry_Idx));
      begin
         for J in 1 .. Natural (E.Variants.Length) loop
            declare
               V : constant Path_Variant := E.Variants.Element (Positive (J));
            begin
               if Same_Key (V.Key, K) then
                  Contours := V.Contours;
                  return True;
               end if;
            end;
         end loop;
      end;

      return False;
   end Find_Path_Contours;

   procedure Store_Path_Contours
     (Obj      : in out Cache;
      Path_Pos : Natural;
      D        : String;
      M        : Adi.SVG.Parser.Matrix;
      Contours : Adi.SVG.Parser.Contour_Vectors.Vector)
   is
      Entry_Idx : constant Natural := Find_Path_Entry (Obj, Path_Pos, D);
      K         : constant Matrix_Key := Key_For (M);
   begin
      if Entry_Idx = 0 then
         declare
            E : Path_Entry;
         begin
            E.Pos := Path_Pos;
            E.D_Text := US.To_Unbounded_String (D);
            E.Variants.Append (Path_Variant'(Key => K, Contours => Contours));
            Obj.Paths.Append (E);
         end;
      else
         declare
            E : Path_Entry := Obj.Paths.Element (Positive (Entry_Idx));
         begin
            for J in 1 .. Natural (E.Variants.Length) loop
               if Same_Key (E.Variants.Element (Positive (J)).Key, K) then
                  return;
               end if;
            end loop;

            E.Variants.Append (Path_Variant'(Key => K, Contours => Contours));
            Obj.Paths.Replace_Element (Positive (Entry_Idx), E);
         end;
      end if;
   end Store_Path_Contours;

   function Find_Render_Buffer
     (Obj      : in out Cache;
      Width    : Positive;
      Height   : Positive;
      AA_Scale : Positive;
      Pixels   : out Pixel_Buffer_Access) return Boolean
   is
   begin
      Pixels := null;

      for I in 1 .. Natural (Obj.Renders.Length) loop
         declare
            E : constant Render_Entry := Obj.Renders.Element (Positive (I));
         begin
            if E.Width = Width
              and then E.Height = Height
              and then E.AA_Scale = AA_Scale
              and then E.Pixels /= null
            then
               Pixels := Clone_Buffer (E.Pixels);
               return Pixels /= null;
            end if;
         end;
      end loop;

      return False;
   end Find_Render_Buffer;

   procedure Store_Render_Buffer
     (Obj      : in out Cache;
      Width    : Positive;
      Height   : Positive;
      AA_Scale : Positive;
      Pixels   : Pixel_Buffer_Access)
   is
      Copy : constant Pixel_Buffer_Access := Clone_Buffer (Pixels);
   begin
      if Copy = null then
         return;
      end if;

      for I in 1 .. Natural (Obj.Renders.Length) loop
         declare
            E : Render_Entry := Obj.Renders.Element (Positive (I));
         begin
            if E.Width = Width
              and then E.Height = Height
              and then E.AA_Scale = AA_Scale
            then
               if E.Pixels /= null then
                  Free_Pixel_Buffer (E.Pixels);
               end if;

               E.Pixels := Copy;
               Obj.Renders.Replace_Element (Positive (I), E);
               return;
            end if;
         end;
      end loop;

      Obj.Renders.Append
        (Render_Entry'
           (Width    => Width,
            Height   => Height,
            AA_Scale => AA_Scale,
            Pixels   => Copy));
   end Store_Render_Buffer;

end Adi.SVG.Ada_Cache;
