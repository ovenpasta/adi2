--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Instrumentation the tests need and applications do not. The group
--  protocol is private to Adi.Widget.Button, so reaching it at all is
--  what this package is for.
generic
package Adi.Widget.Button.Options.Testing is

   --  The button a group has recorded against an option, whether or not
   --  that button still points back at the group. Every operation asks
   --  the button's link rather than this array, so behaviour alone
   --  cannot tell a dropped membership from a retained one.
   function Recorded
     (G : Option_Group; O : Option_Type) return Button_Handle;

   --  Route a click to the group the way Button.On_Click does.
   procedure Click (G : in out Option_Group; B : Button_Handle);

   --  True while the button points at any group.
   function Is_Linked (B : Button_Handle) return Boolean;

   --  Rebind the button to a group that is not the one holding it. Only
   --  the library can do this, and Set_Button does it whenever a button
   --  moves between groups; here it stands for the window in which one
   --  group still records a button another group has taken.
   procedure Rebind_Elsewhere (B : Button_Handle);
   function Links_Elsewhere (B : Button_Handle) return Boolean;

end Adi.Widget.Button.Options.Testing;
