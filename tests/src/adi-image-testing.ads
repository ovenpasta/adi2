--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Test-only view of the image store.
package Adi.Image.Testing is

   --  Whether the store still holds a live slot for this handle, asked
   --  of the store rather than of the image. Is_Valid answers False for
   --  an emptied image as readily as for a released one, so a test that
   --  used it to check that an image had been ended would pass without
   --  anything having ended.
   function Handle_Is_Registered (H : Image_Handle) return Boolean;

end Adi.Image.Testing;
