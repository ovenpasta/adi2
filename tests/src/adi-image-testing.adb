--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Image.Testing is

   function Handle_Is_Registered (H : Image_Handle) return Boolean
   is (Image_Stores.Is_Valid (H.Ref));

end Adi.Image.Testing;
