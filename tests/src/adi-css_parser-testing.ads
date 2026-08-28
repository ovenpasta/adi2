--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.CSS_Parser.Testing is

   --  What one parsed selector costs to hold. A sheet keeps one per
   --  selector it names, and every source that loads the same CSS keeps
   --  a sheet of its own.
   function Selector_Entry_Bytes return Natural;

end Adi.CSS_Parser.Testing;
