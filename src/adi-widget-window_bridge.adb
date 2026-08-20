--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Window_Bridge is

   procedure Install_Destroy_Notice (Notice : not null Destroy_Notice) is
   begin
      if Adi.Widget.Destroy_Notice_Slot /= null then
         raise Program_Error with
           "Widget.Window_Bridge: a destroy notice is already installed";
      end if;

      Adi.Widget.Destroy_Notice_Slot :=
        Adi.Widget.Destroy_Notice_Proc (Notice);
   end Install_Destroy_Notice;

end Adi.Widget.Window_Bridge;
