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

   function View (H : Html_View_Handle) return access constant Html_View is
      Ptr : constant Widget_Access := Resolve_Handle (To_Widget_Handle (H));
   begin
      return (if Ptr = null then null else Html_View (Ptr.all)'Access);
   end View;

   function Document_Item_Count (H : Html_View_Handle) return Natural is
     (if View (H) = null then 0
      else Natural (View (H).Layout_Cache.Items.Length));

   function Document_Item (H : Html_View_Handle; I : Positive) return Item is
     (View (H).Layout_Cache.Items.Element (I));

   function Document_Link_Count (H : Html_View_Handle) return Natural is
     (if View (H) = null then 0
      else Natural (View (H).Layout_Cache.Links.Length));

   function Document_Link_Geometry
     (H : Html_View_Handle; I : Positive) return Rectangle is
     (View (H).Layout_Cache.Links.Element (I).Geometry);

   function Document_Link_Href (H : Html_View_Handle; I : Positive) return String is
     (To_String (View (H).Layout_Cache.Links.Element (I).Href));

end Adi.Widget.Html_View.Testing;
