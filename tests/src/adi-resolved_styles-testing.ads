--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Resolved_Styles.Testing is

   --  The cap the store clears at. Lowering it puts the eviction path
   --  within reach of a handful of distinct styles.
   procedure Set_Entry_Cap (Entries : Positive);

   --  What the cap is when nothing has moved it.
   function Default_Entry_Cap return Positive;

end Adi.Resolved_Styles.Testing;
