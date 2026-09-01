--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Widget_Styles.Testing is

   --  Rules that did not fit: what Try_Add_Rule dropped and what a
   --  composer chain dropped. It only ever grows, so a test measures a
   --  step across an operation, not an absolute.
   function Dropped_Rules return Natural;

end Adi.Widget_Styles.Testing;
