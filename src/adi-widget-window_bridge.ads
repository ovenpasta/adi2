--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  Framework-internal: how the layers above Adi.Widget learn that a
--  widget is being destroyed, without Adi.Widget naming them.  Adi.Window
--  drops its references to it; Adi.CSS_Source and Adi.CSS_Parser prune
--  its bindings.  Applications have no reason to name this package; it is
--  visible only because Ada gives no narrower way to let one library unit
--  reach another.
--
--  Adi.Widget's spec cannot mention Adi.Window, since Adi.Window withs
--  Adi.Widget.  A child of Adi.Widget can name both, and reaches the
--  slot in its parent's private part.
--
--  For the widget Destroy was called on, the notice runs while the
--  handle still resolves and the widget is still in its host window's
--  tree, because that membership is how the host is found.  It returns
--  before the widget is detached from its parent and before the subtree
--  is destroyed, so it must not retain anything it is passed.
--
--  Every widget under that one is notified too, as the subtree is walked
--  and after it has been detached -- so a descendant's notice can no
--  longer reach the window through the tree, and a subscriber that needs
--  the window must do its work from the first call.
package Adi.Widget.Window_Bridge is

   type Destroy_Notice is access procedure (H : Widget_Handle);

   --  Installed at elaboration, once per subscriber. Installing the
   --  same notice again does nothing.
   procedure Install_Destroy_Notice (Notice : not null Destroy_Notice);

end Adi.Widget.Window_Bridge;
