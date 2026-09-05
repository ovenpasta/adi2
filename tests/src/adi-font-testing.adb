--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Font.Testing is

   function Sized_Fonts_Held return Natural is
     (Adi.Font.Faces_Held);

   function Resident (Font : TTF_Font_Access) return Boolean is
     (Adi.Font.Face_Resident (Font));

   function Pins (Font : TTF_Font_Access) return Natural is
     (Adi.Font.Face_Pins (Font));

   function Last_Used (Font : TTF_Font_Access) return Natural is
     (Adi.Font.Face_Last_Used (Font));

   function Line_Skip_Cached (Font : TTF_Font_Access) return Boolean is
     (Adi.Font.Has_Natural_Skip (Font));

end Adi.Font.Testing;
