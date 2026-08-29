--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Window_Bridge is

   procedure Install_Destroy_Notice (Notice : not null Destroy_Notice) is
      P : constant Adi.Widget.Destroy_Notice_Proc :=
        Adi.Widget.Destroy_Notice_Proc (Notice);
   begin
      --  Installing the same notice twice would call it twice per
      --  widget, which a subscriber counting what it prunes would feel.
      for Installed of Adi.Widget.Destroy_Notices loop
         if Installed = P then
            return;
         end if;
      end loop;

      Adi.Widget.Destroy_Notices.Append (P);
   end Install_Destroy_Notice;

end Adi.Widget.Window_Bridge;
