--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers;
with Interfaces;

--  Instrumentation the tests need and applications do not.
package Adi.Widget.Testing is

   --  Distinct styles the interning store holds. It only ever grows, so
   --  a test measures a step across an operation, not an absolute.
   function Interned_Styles return Natural;

   --  Storage elements those entries occupy.
   function Interned_Style_Bytes return Natural;

   --  Entries the resolved-style memo holds. It is cleared wholesale at
   --  its cap, so this rises and falls.
   function Memo_Entries return Natural;

   --  Storage elements the per-widget records occupy, for the size
   --  chain a test reports.
   function Widget_Bytes return Natural;
   function Item_Bytes return Natural;
   function Part_Transition_Bytes return Natural;
   function Cached_Resolved_Bytes return Natural;
   function Transitions_Bytes return Natural;

   --  Key hash of the resolved-style memo, over the raw key fields: two
   --  interned style handles, three packed state words and the font
   --  generation.
   function Resolved_Cache_Hash
     (Part_Handle, Main_Handle : Natural;
      Widget_State_Bits, Part_State_Bits,
      Main_Part_State_Bits     : Interfaces.Unsigned_16;
      Font_Gen                 : Interfaces.Unsigned_32)
      return Ada.Containers.Hash_Type;

end Adi.Widget.Testing;
