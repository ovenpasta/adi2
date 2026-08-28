--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Widget.Testing is

   --  Distinct styles the interning store holds. It only ever grows, so
   --  a test measures a step across an operation, not an absolute.
   function Interned_Styles return Natural;

end Adi.Widget.Testing;
