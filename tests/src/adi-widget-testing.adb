--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Testing is

   function Interned_Styles return Natural is (Interned_Style_Count);

   function Memo_Entries return Natural is (Resolved_Memo_Entries);

   function Resolved_Cache_Hash
     (Part_Handle, Main_Handle : Natural;
      Widget_State_Bits, Part_State_Bits,
      Main_Part_State_Bits     : Interfaces.Unsigned_16;
      Font_Gen                 : Interfaces.Unsigned_32)
      return Ada.Containers.Hash_Type
   is (Adi.Widget.Resolved_Cache_Hash
         (Style_Handle (Part_Handle), Style_Handle (Main_Handle),
          Widget_State_Bits, Part_State_Bits, Main_Part_State_Bits,
          Adi.Font.Font_Generation (Font_Gen)));

end Adi.Widget.Testing;
