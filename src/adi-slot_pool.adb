--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Slot_Pool is

   function Live (S : Slot) return Boolean is
     (S.Ordinal in Slot_Index
      and then Entries (S.Ordinal).In_Use
      and then Entries (S.Ordinal).Serial = S.Serial);

   function Acquire return Slot is
   begin
      for I in Entries'Range loop
         if not Entries (I).In_Use then
            Entries (I).In_Use := True;
            Entries (I).Serial := Entries (I).Serial + 1;
            Taken := Taken + 1;
            return (Ordinal => I, Serial => Entries (I).Serial);
         end if;
      end loop;
      return No_Slot;
   end Acquire;

   procedure Release (S : in out Slot) is
   begin
      if Live (S) then
         Entries (S.Ordinal).In_Use := False;
         Taken := Taken - 1;
      end if;
      S := No_Slot;
   end Release;

   function Held return Slot_Count is (Taken);

   function Get (S : Slot) return Payload is
   begin
      if not Live (S) then
         raise Constraint_Error with "the pool no longer holds this slot";
      end if;
      return Entries (S.Ordinal).Item;
   end Get;

   procedure Set (S : Slot; P : Payload) is
   begin
      if not Live (S) then
         raise Constraint_Error with "the pool no longer holds this slot";
      end if;
      Entries (S.Ordinal).Item := P;
   end Set;

   function Ordinal (S : Slot) return Slot_Count is (S.Ordinal);

   function Serial (S : Slot) return Natural is (S.Serial);

   function Named (Ordinal : Natural; Serial : Natural) return Slot is
     (if Ordinal in Slot_Index
      then (Ordinal => Ordinal, Serial => Serial)
      else No_Slot);

end Adi.Slot_Pool;
