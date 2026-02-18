pragma Ada_2022;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;

package body Adi.Widget.Value_Input is

   function Conv_Image (V : Value_Type) return String is
      --  Find shortest fixed-point representation that round-trips.
      --  Try Aft 1..6 and pick the first where Value_Type'Value = V.
      package FIO is new Ada.Text_IO.Float_IO (Value_Type);
      Buf : String (1 .. 64);

      function Format (Aft : Natural) return String is
         Last : Natural;
         Dot  : Natural := 0;
      begin
         FIO.Put (Buf, V, Aft => Aft, Exp => 0);
         declare
            S : constant String := Trim (Buf, Both);
         begin
            --  Find decimal point
            for I in S'Range loop
               if S (I) = '.' then
                  Dot := I;
                  exit;
               end if;
            end loop;
            if Dot = 0 then
               return S;
            end if;
            --  Strip trailing zeros, keep at least one after dot
            Last := S'Last;
            while Last > Dot + 1 and then S (Last) = '0' loop
               Last := Last - 1;
            end loop;
            return S (S'First .. Last);
         end;
      end Format;
   begin
      --  Try increasing precision, return first that round-trips
      for Aft in 1 .. 5 loop
         declare
            S : constant String := Format (Aft);
         begin
            if Value_Type'Value (S) = V then
               return S;
            end if;
         exception
            when others => null;
         end;
      end loop;
      --  Fallback: 6 digits
      return Format (6);
   end Conv_Image;

end Adi.Widget.Value_Input;
