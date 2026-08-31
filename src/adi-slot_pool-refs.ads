--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

--  The pool's payload in place, for a caller that would otherwise copy
--  a large one whole to read one component or to change one. The pool
--  itself answers by value and holds no access value; a caller that
--  wants an accessor instantiates this beside it and takes on the
--  lifetime rule that comes with one.
generic
package Adi.Slot_Pool.Refs is

   type Const_Access is access constant Payload;
   type Var_Access is access all Payload;

   --  The payload of a live slot, and null for a slot the pool no
   --  longer holds -- the caller supplies whatever an absent slot
   --  should read as. The address stands for the life of the
   --  partition, and the value under it belongs to whoever holds the
   --  slot now: never hold the result past the statement that
   --  dereferences it, and never across a call that may Release or
   --  Acquire.
   function Ref (S : Slot) return Const_Access;
   function Mutable (S : Slot) return Var_Access;

private

   function Ref (S : Slot) return Const_Access is
     (if Live (S) then Entries (S.Ordinal).Item'Access else null);

   function Mutable (S : Slot) return Var_Access is
     (if Live (S) then Entries (S.Ordinal).Item'Access else null);

end Adi.Slot_Pool.Refs;
