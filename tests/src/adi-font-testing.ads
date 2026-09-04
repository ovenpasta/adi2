--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Font.Testing is

   --  Sized TTF_Font instances held, which a test reads to say what a
   --  call did rather than only what it returned.
   function Sized_Fonts_Held return Natural;

end Adi.Font.Testing;
