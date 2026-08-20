--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Framework-internal: how Adi.Window learns that a widget is being
--  destroyed, without Adi.Widget naming Adi.Window.  Applications have
--  no reason to name this package; it is visible only because Ada gives
--  no narrower way to let one library unit reach another.
--
--  Adi.Widget's spec cannot mention Adi.Window, since Adi.Window withs
--  Adi.Widget.  A child of Adi.Widget can name both, and reaches the
--  slot in its parent's private part.
--
--  The installed notice runs from Destroy while the handle still
--  resolves and the widget is still in its host window's tree, because
--  that membership is how the host is found.  It returns before the
--  widget is detached from its parent and before the subtree is
--  destroyed, so it must not retain anything it is passed.
package Adi.Widget.Window_Bridge is

   type Destroy_Notice is access procedure (H : Widget_Handle);

   --  Installed once, by Adi.Window at elaboration.
   --  Raises Program_Error when a notice is already installed.
   procedure Install_Destroy_Notice (Notice : not null Destroy_Notice);

end Adi.Widget.Window_Bridge;
