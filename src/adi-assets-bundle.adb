pragma Ada_2022;

with Ada.Containers.Indefinite_Ordered_Maps;

package body Adi.Assets.Bundle is

   package Bundle_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Asset_Data);

   Registry : Bundle_Maps.Map;

   procedure Register
     (Path   : String;
      Addr   : System.Address;
      Length : System.Storage_Elements.Storage_Count)
   is
      D : constant Asset_Data := (Addr => Addr, Length => Length);
   begin
      if Registry.Contains (Path) then
         Registry.Replace (Path, D);
      else
         Registry.Insert (Path, D);
      end if;
   end Register;

   function Lookup (Path : String) return Asset_Data is
      use Bundle_Maps;
      Pos : constant Cursor := Registry.Find (Path);
   begin
      if Pos /= No_Element then
         return Element (Pos);
      end if;
      return Null_Asset;
   end Lookup;

   procedure Clear is
   begin
      Registry.Clear;
   end Clear;

end Adi.Assets.Bundle;
