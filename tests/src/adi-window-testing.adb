--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Window.Testing is

   procedure At_Frame_Close (Callback : Frame_Close_Callback) is
   begin
      Adi.Window.Frame_Closed := Frame_Close_Hook (Callback);
   end At_Frame_Close;

end Adi.Window.Testing;
