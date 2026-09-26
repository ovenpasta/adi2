--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.OS.Testing is

   procedure Post_Dialog_Result
     (Callback : Dialog_Callback;
      Files    : String_Array) renames Adi.OS.Post_Dialog_Result;

   function Claim_Dialog return Boolean renames Adi.OS.Claim_Dialog;

end Adi.OS.Testing;
