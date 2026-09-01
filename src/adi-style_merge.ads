--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Widget;
with Adi.Widget_Styles;

--  Folding one set of styles onto another, shared by the two units that
--  apply a stylesheet to a widget: Adi.CSS_Source and Adi.CSS_Parser.
--  Private, because it has no callers outside them -- what an
--  application reaches is Adi.CSS_Source.Merge_Part_Styles.
private package Adi.Style_Merge is

   --  Fold Override onto Base. A state selector both name merges; one
   --  only Override names is added while the style has room for it, and
   --  reported through Adi.Log when it has not.
   function Merge (Base, Override : Adi.Widget_Styles.Widget_Style)
     return Adi.Widget_Styles.Widget_Style;

   --  The same, part by part. A part Override leaves disabled keeps
   --  whatever Base had for it.
   function Merge (Base, Override : Adi.Widget.Part_Style_Array)
     return Adi.Widget.Part_Style_Array;

   --  Styles as one widget takes them from a sheet: the sheet's :root
   --  block folded on when the widget is the one the sheet holds as its
   --  root, and Styles alone when it is not. Answering both cases is
   --  what lets one call grant the :root styles and withdraw them, so a
   --  root handover restyles the widget losing the role by the same
   --  route as the one taking it. Has_Root_Style and Root_Styles are
   --  the two fields a stylesheet's metadata carries for this; each
   --  caller reads them from the metadata its own mode puts in force.
   function Root_Merged_Styles
     (Has_Root_Style : Boolean;
      Root_Styles    : Adi.Widget.Part_Style_Array;
      Root_Target    : Adi.Widget.Widget_Handle;
      Target         : Adi.Widget.Widget_Handle;
      Styles         : Adi.Widget.Part_Style_Array)
     return Adi.Widget.Part_Style_Array;

end Adi.Style_Merge;
