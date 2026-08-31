--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Widget_Styles;

package body Adi.Widget.Testing is

   function Interned_Styles return Natural is
     (Adi.Widget_Styles.Interned_Styles);

   function Interned_Style_Bytes return Natural is
     (Adi.Widget_Styles.Interned_Style_Bytes);

   function Memo_Entries return Natural is (Resolved_Memo_Entries);

   function Widget_Bytes return Natural is
     (Widget'Max_Size_In_Storage_Elements);

   function Item_Bytes return Natural is
     (Item'Max_Size_In_Storage_Elements);

   function Part_Transition_Bytes return Natural is
     (Part_Transition'Max_Size_In_Storage_Elements);

   function Cached_Resolved_Bytes return Natural is
     (Part_Resolved_Array'Max_Size_In_Storage_Elements);

   function Transitions_Bytes return Natural is
     (Part_Transition_Array'Max_Size_In_Storage_Elements);

   function Resolved_Cache_Hash
     (Part_Handle, Main_Handle : Natural;
      Widget_State_Bits, Part_State_Bits,
      Main_Part_State_Bits     : Interfaces.Unsigned_16;
      Font_Gen                 : Interfaces.Unsigned_32;
      Assigned                 : Adi.Widget_Properties.Property_Assignment
        := Adi.Widget_Properties.Empty_Assignment)
      return Ada.Containers.Hash_Type
   is (Adi.Widget.Resolved_Cache_Hash
         (Part_Handle, Main_Handle,
          Widget_State_Bits, Part_State_Bits, Main_Part_State_Bits,
          Adi.Font.Font_Generation (Font_Gen), Assigned));

end Adi.Widget.Testing;
