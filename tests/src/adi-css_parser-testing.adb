--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package body Adi.CSS_Parser.Testing is

   function Selector_Entry_Bytes return Natural is
     (Adi.CSS_Parser.Selector_Entry_Bytes);

   function Live_Sheets return Natural is
     (Adi.CSS_Parser.Live_Impl_Count);

   function Bindings_Held (Sheet : Stylesheet) return Natural is
     (Adi.CSS_Parser.Binding_Count (Sheet));

   function Effective_Held (Sheet : Stylesheet) return Natural is
     (Adi.CSS_Parser.Effective_Count (Sheet));

end Adi.CSS_Parser.Testing;
