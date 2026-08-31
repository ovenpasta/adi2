--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles; use Adi.CSS_Styles;
private with Adi.Slot_Pool;

--  One store for the resolved styles the runtime holds. Interning is
--  canonical, so equal values share a handle and a handle comparison is
--  a value comparison. A widget, an item and a transition each name a
--  value by handle rather than carrying one.
package Adi.Resolved_Styles is

   type Resolved_Handle is private;

   --  What a style with nothing set resolves to. Every holder starts here.
   Default_Handle : constant Resolved_Handle;

   function Intern (S : Resolved_Style) return Resolved_Handle;

   --  The stored value. A handle the store no longer holds -- one taken
   --  before an eviction, or one into a released scratch slot -- reads as
   --  the default style, which Is_Held distinguishes.
   function Value (H : Resolved_Handle) return Resolved_Style;

   type Const_Style_Access is access constant Resolved_Style;

   --  The stored value in place, for a reader that would otherwise copy
   --  the whole record to reach one component. The address stays good
   --  for the life of the process; the value under it stands until the
   --  event that hands its cell on, and which event that is follows the
   --  handle. A store handle stands until the next Collect. A handle
   --  into a scratch slot stands until that slot is released or handed
   --  out again, which Collect never does and Acquire_Scratch and
   --  Release_Scratch both do -- reached from Adi.Animation's Start,
   --  Cancel and Advance, and from Destroy_Subtree. Never hold the
   --  result past the statement that dereferences it, and never across
   --  a call that may reach any of them.
   function Ref (H : Resolved_Handle) return not null Const_Style_Access;

   function Is_Held (H : Resolved_Handle) return Boolean;

   ---------------------------------------------------------------------------
   --  Layout inputs
   ---------------------------------------------------------------------------

   --  The layout-affecting properties of a stored value, projected onto
   --  the defaults and interned on their own. Equal layout handles are
   --  equal layout inputs, exactly.
   function Layout_Of (H : Resolved_Handle) return Resolved_Handle;

   function Layout_Affecting_Diff (A, B : Resolved_Handle) return Boolean is
     (Layout_Of (A) /= Layout_Of (B));

   --  The projection itself, for a test that pins it against
   --  Adi.CSS_Styles.Layout_Affecting_Diff.
   function Layout_Projection (S : Resolved_Style) return Resolved_Style;

   ---------------------------------------------------------------------------
   --  Lifetime
   ---------------------------------------------------------------------------

   --  Clears the store when it has passed its cap, and raises
   --  Generation. This is the one place a handle stops naming its value,
   --  so a caller that drives it once per frame -- Adi.Widget.Update
   --  does -- gives every handle minted in a frame the whole of that
   --  frame. Interning never clears on its own: a clear taken inside it
   --  would strand the handles the frame had already handed out.
   procedure Collect;

   --  Rises at a Collect that cleared. A holder that keeps a handle
   --  across frames keeps this beside it and resolves again on a
   --  difference.
   function Generation return Natural;

   --  Entries the store holds, and the storage elements the blocks
   --  behind them occupy. A clear takes the count to zero and keeps the
   --  blocks for the entries that follow. The count passes the cap by
   --  what one frame interns past it, since Collect is what acts on it.
   function Entry_Count return Natural;
   function Entry_Bytes return Natural;

   --  Entries past which the next Collect clears the store. The count is
   --  read against this, as texture residency is read against the
   --  texture budget.
   function Entry_Cap return Natural;

   ---------------------------------------------------------------------------
   --  Animation scratch
   ---------------------------------------------------------------------------

   --  A transition mints an interpolated style every frame. Those live
   --  in a fixed pool rather than in the store, which holds only values
   --  the cascade produced. A slot carries two cells: where the
   --  transition starts from, and where it stands this frame.
   Scratch_Slots : constant := 64;

   type Scratch_Slot is private;
   No_Scratch : constant Scratch_Slot;

   --  No_Scratch when every slot is taken; the caller then assigns the
   --  target directly, as a part with a zero duration does.
   function Acquire_Scratch return Scratch_Slot;
   procedure Release_Scratch (S : in out Scratch_Slot);
   function Held_Scratch return Natural;

   function From_Cell (S : Scratch_Slot) return Resolved_Handle;
   function Current_Cell (S : Scratch_Slot) return Resolved_Handle;

   --  Writes through a scratch handle. A store handle is canonical, so a
   --  write through one is dropped.
   procedure Write (H : Resolved_Handle; S : Resolved_Style);

private

   type Resolved_Handle is record
      Index : Natural := 0;
      Gen   : Natural := 0;
   end record;

   Default_Handle : constant Resolved_Handle := (Index => 0, Gen => 0);

   type Scratch_Cells is array (1 .. 2) of aliased Resolved_Style;

   --  Never `use Scratch_Pool`. The body's Held is the store's entry
   --  count and the pool's Held is its occupancy; a use clause hides one
   --  behind the other under RM 8.3, and -gnatwa says nothing. Reach the
   --  pool through Scratch_Pool.<name>, or through the operations
   --  Scratch_Slot inherits below.
   --
   --  Local_Restrictions => (No_Secondary_Stack, No_Heap_Allocations) is
   --  accepted on an instantiation and rejected here, charged against
   --  Scratch_Cells' default-initialization procedure at Slot_Entry.Item
   --  rather than against any pool code: a payload whose components
   --  carry no defaults passes both, and tests/src/slot_pool_test.adb
   --  instantiates under both.
   package Scratch_Pool is new Adi.Slot_Pool
     (Payload => Scratch_Cells, Capacity => Scratch_Slots);

   --  The pool's own slot serial is what a handle into a slot carries
   --  in Resolved_Handle.Gen, where a handle into the store carries the
   --  store's generation there.
   type Scratch_Slot is new Scratch_Pool.Slot;

   No_Scratch : constant Scratch_Slot := Scratch_Slot (Scratch_Pool.No_Slot);

   --  A test lowers this to reach the clear without interning its way
   --  to the ceiling.
   Cap_Entries : Natural := 16_384;

end Adi.Resolved_Styles;
