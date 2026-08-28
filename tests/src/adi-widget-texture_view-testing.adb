--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Texture_View.Testing is

   procedure Fail_Next_Upload is
   begin
      Texture_View.Fail_Next_Upload := True;
   end Fail_Next_Upload;

end Adi.Widget.Texture_View.Testing;
