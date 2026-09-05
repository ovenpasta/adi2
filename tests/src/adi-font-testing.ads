--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Font.Testing is

   --  Sized TTF_Font instances held, which a test reads to say what a
   --  call did rather than only what it returned.
   function Sized_Fonts_Held return Natural;

   --  Whether the cache still holds this face, how many holders it is
   --  pinned by, and the frame it was last handed out in.
   function Resident (Font : TTF_Font_Access) return Boolean;
   function Pins (Font : TTF_Font_Access) return Natural;
   function Last_Used (Font : TTF_Font_Access) return Natural;

   --  Whether the line-skip cache still answers for this pointer, which
   --  is what a closed face has to take with it.
   function Line_Skip_Cached (Font : TTF_Font_Access) return Boolean;

end Adi.Font.Testing;
