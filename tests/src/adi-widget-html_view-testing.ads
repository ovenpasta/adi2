--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not.
package Adi.Widget.Html_View.Testing is

   --  How many times the document has been laid out. Scrolling, moving
   --  the widget and rebuilding it unchanged all leave this alone; a
   --  change to anything a layout depends on advances it by one. It is
   --  the only thing that separates a cache that hits from one that
   --  re-lays the document every frame, since both render alike.
   type Layout_Pass_Counter is mod 2 ** 32;

   function Layout_Pass_Count (H : Html_View_Handle) return Layout_Pass_Counter;

end Adi.Widget.Html_View.Testing;
