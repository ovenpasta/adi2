--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Widget.Texture_View.Testing is

   --  Make the next upload fail, once. SDL refuses no well-formed
   --  upload, so injecting one is the only way to reach what a refusal
   --  leaves behind: a frame still pending, and a reason for it.
   procedure Fail_Next_Upload;

end Adi.Widget.Texture_View.Testing;
