--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.OS.Testing is

   --  What the dialog trampoline does with SDL's answer, called from
   --  whichever task a test chooses.
   procedure Post_Dialog_Result
     (Callback : Dialog_Callback;
      Files    : String_Array);

   --  What each Show_* asks before it opens a dialog.
   function Claim_Dialog return Boolean;

end Adi.OS.Testing;
