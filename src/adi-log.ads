--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package Adi.Log is

   procedure Write (Msg : String);
   procedure Debug (Msg : String);
   procedure Info (Msg : String);
   procedure Warning (Msg : String);
   procedure Error (Msg : String);

end Adi.Log;
