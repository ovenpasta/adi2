--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.Widget.Html_View.Testing is

   function Layout_Pass_Count (H : Html_View_Handle) return Layout_Pass_Counter
   is
      Ptr : constant Widget_Access := Resolve_Handle (To_Widget_Handle (H));
   begin
      if Ptr = null then
         return 0;
      end if;
      return Layout_Pass_Counter (Html_View (Ptr.all).Layout_Passes);
   end Layout_Pass_Count;

end Adi.Widget.Html_View.Testing;
