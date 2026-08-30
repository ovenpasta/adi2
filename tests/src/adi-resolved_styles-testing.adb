--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Resolved_Styles.Testing is

   procedure Set_Entry_Cap (Entries : Positive) is
   begin
      Adi.Resolved_Styles.Entry_Cap := Entries;
   end Set_Entry_Cap;

   function Entry_Cap return Positive is
     (Adi.Resolved_Styles.Entry_Cap);

   Cap_At_Elaboration : constant Positive := Adi.Resolved_Styles.Entry_Cap;

   function Default_Entry_Cap return Positive is (Cap_At_Elaboration);

end Adi.Resolved_Styles.Testing;
