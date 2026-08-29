--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Widget;

--  Instrumentation the tests need and applications do not: the shared
--  fold behind Adi.CSS_Source.Merge_Part_Styles and the stylesheet
--  parser, which is a private child and so unnameable from a test.
--  Reached from the body, which RM 10.1.2(8) allows a descendant of Adi.
package Adi.Style_Merge_Testing is

   function Merge (Base, Override : Adi.Widget.Part_Style_Array)
     return Adi.Widget.Part_Style_Array;

end Adi.Style_Merge_Testing;
