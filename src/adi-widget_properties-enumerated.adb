--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;

package body Adi.Widget_Properties.Enumerated is

   package Char renames Ada.Characters.Handling;

   function Ordinal_Of (V : Values) return Natural is
     (Values'Pos (V) - Values'Pos (Values'First));

   function At_Ordinal (Ordinal : Natural) return Values is
     (Values'Val (Values'Pos (Values'First) + Ordinal));

   function Id return Property is (Registered);

   function Value (V : Values) return Property_Value is
     (Value_At (Registered, Ordinal_Of (V)));

   function CSS_Name (V : Values) return String is
      Raw : constant String := Values'Image (V);
   begin
      return Result : String (Raw'Range) do
         for I in Raw'Range loop
            Result (I) :=
              (if Raw (I) = '_' then '-' else Char.To_Lower (Raw (I)));
         end loop;
      end return;
   end CSS_Name;

   --  What the registry calls when a dynamic stylesheet spells a value.
   --  Nothing but the enumeration knows its literals, so the lookup
   --  lives here and the registry holds no value names of its own.
   function Resolve_Ordinal (Name : String) return Integer is
   begin
      for V in Values loop
         if CSS_Name (V) = Name then
            return Ordinal_Of (V);
         end if;
      end loop;
      return -1;
   end Resolve_Ordinal;

   function Name_At_Ordinal (Ordinal : Natural) return String is
     (if Ordinal < Value_Count (Registered) then CSS_Name (At_Ordinal (Ordinal))
      else "");

   procedure Set (H : Adi.Widget.Widget_Handle; V : Values) is
   begin
      Adi.Widget.Set_Property (H, Value (V));
   end Set;

   procedure Clear (H : Adi.Widget.Widget_Handle) is
   begin
      Adi.Widget.Clear_Property (H, Registered);
   end Clear;

   function Is_Set (H : Adi.Widget.Widget_Handle) return Boolean is
     (Adi.Widget.Has_Property (H, Registered));

   function Get (H : Adi.Widget.Widget_Handle; Default : Values) return Values
   is
      Held : constant Property_Value :=
        Adi.Widget.Get_Property (H, Registered);
   begin
      if Held = No_Value then
         return Default;
      end if;
      return At_Ordinal (Natural (Held.Ordinal));
   end Get;

end Adi.Widget_Properties.Enumerated;
