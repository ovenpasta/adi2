--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0


pragma Ada_2022;

--  The root package references nothing itself, but its use clause is
--  inherited by every child: the SDL bindings and the widget stack rely
--  on the Interfaces.C.Extensions operators for the unsigned C types
--  (Uint8/Uint32 and friends) being directly visible.
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
pragma Warnings (Off, Interfaces.C.Extensions);

package Adi is

end Adi;
