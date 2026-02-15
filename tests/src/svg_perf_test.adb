pragma Ada_2022;

with Ada.Calendar; use Ada.Calendar;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with Adi.SVG;

procedure Svg_Perf_Test is
   use type Adi.SVG.Document_Access;
   use type Adi.SVG.Pixel_Buffer_Access;

   procedure Free_Pixels is
     new Ada.Unchecked_Deallocation (Adi.SVG.Pixel_Buffer, Adi.SVG.Pixel_Buffer_Access);
   procedure Free_Document is
     new Ada.Unchecked_Deallocation (Adi.SVG.Document'Class, Adi.SVG.Document_Access);

   function Trimmed (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   function Ms_Image (Value : Long_Float) return String is
   begin
      return Trimmed (Long_Float'Image (Value));
   end Ms_Image;

   function Iterations_For (Size : Positive) return Positive is
   begin
      if Size <= 128 then
         return 24;
      elsif Size <= 256 then
         return 14;
      elsif Size <= 512 then
         return 8;
      else
         return 4;
      end if;
   end Iterations_For;

   procedure Benchmark_Asset
     (Path  : String;
      Label : String)
   is
      Sizes : constant array (Positive range 1 .. 5) of Positive := (64, 128, 256, 512, 1024);
      Doc   : Adi.SVG.Document_Access := Adi.SVG.Load_From_File (Path);
      Px    : Adi.SVG.Pixel_Buffer_Access := null;
   begin
      if Doc = null or else not Adi.SVG.Is_Valid (Doc.all) then
         raise Program_Error with "failed to load SVG for perf test: " & Path;
      end if;

      for Size of Sizes loop
         declare
            Warmups : constant Positive := 2;
            N       : constant Positive := Iterations_For (Size);
            Cold_MS : Long_Float := 0.0;
            Min_MS  : Long_Float := Long_Float'Last;
            Max_MS  : Long_Float := 0.0;
            Sum_MS  : Long_Float := 0.0;
         begin
            declare
               T0 : constant Time := Clock;
               T1 : Time;
            begin
               Px := Adi.SVG.Render_ARGB32 (Doc.all, Size, Size);
               T1 := Clock;

               if Px = null then
                  raise Program_Error with "cold render failed for " & Label;
               end if;

               Cold_MS := Long_Float (T1 - T0) * 1000.0;
               Free_Pixels (Px);
            end;

            for I in 1 .. Warmups loop
               Px := Adi.SVG.Render_ARGB32 (Doc.all, Size, Size);
               if Px = null then
                  raise Program_Error with "warmup render failed for " & Label;
               end if;
               Free_Pixels (Px);
            end loop;

            for I in 1 .. N loop
               declare
                  T0 : constant Ada.Calendar.Time := Ada.Calendar.Clock;
                  T1 : Ada.Calendar.Time;
                  MS : Long_Float;
               begin
                  Px := Adi.SVG.Render_ARGB32 (Doc.all, Size, Size);
                  T1 := Ada.Calendar.Clock;

                  if Px = null then
                     raise Program_Error with "measured render failed for " & Label;
                  end if;

                  MS := Long_Float (T1 - T0) * 1000.0;
                  Sum_MS := Sum_MS + MS;
                  if MS < Min_MS then
                     Min_MS := MS;
                  end if;
                  if MS > Max_MS then
                     Max_MS := MS;
                  end if;

                  Free_Pixels (Px);
               end;
            end loop;

            Put_Line
              ("PERF backend=" & Adi.SVG.Backend_Name
               & " asset=" & Label
               & " size=" & Trimmed (Positive'Image (Size))
               & " iters=" & Trimmed (Positive'Image (N))
               & " cold_ms=" & Ms_Image (Cold_MS)
               & " avg_ms=" & Ms_Image (Sum_MS / Long_Float (N))
               & " min_ms=" & Ms_Image (Min_MS)
               & " max_ms=" & Ms_Image (Max_MS));
         end;
      end loop;

      Adi.SVG.Destroy (Doc.all);
      Free_Document (Doc);
   end Benchmark_Asset;

begin
   Put_Line ("SVG performance test backend=" & Adi.SVG.Backend_Name);
   Put_Line ("");

   Benchmark_Asset ("tests/assets/tiger.svg", "tiger");
   Benchmark_Asset ("tests/assets/camera.svg", "camera");
end Svg_Perf_Test;
