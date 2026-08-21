--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Finalization;

--  Defining a widget type outside the Adi library.
--
--  Derive from Widget or from any widget the library provides, override
--  the primitives the type needs, and instantiate this package for it:
--
--     type Gauge is new Adi.Widget.Box.Box_Widget with record
--        Reading : Float := 0.0;
--     end record;
--     overriding procedure Build_Items (W : in out Gauge);
--
--     package Gauges is new Adi.Widget.Extension (Gauge);
--
--     G : constant Gauges.Handle := Gauges.New_Widget;
--
--  Handle behaves as every typed widget handle does: "+" widens it to a
--  Widget_Handle, Adi.Widget.Destroy stales every copy, and copying one
--  does not keep the widget alive.  Components declared by Custom_Widget
--  are reached through a scoped borrow:
--
--     declare
--        R : Gauges.Ref := Gauges.Borrow (G);
--     begin
--        R.Reading := 0.5;
--     end;
--
--  Allocation and registration happen inside the library, so an
--  application names no access type and holds no raw pointer.
--
--  Custom_Widget must be declared at library level, because the widget
--  store outlives nested masters: it holds the widget until Destroy, and
--  dispatches through its tag while doing so.  A type declared inside a
--  subprogram would leave the store holding entries whose dispatch table
--  is gone.  New_Widget allocates through Widget_Access, so a nested
--  actual is rejected by the accessibility check rather than registered.
generic
   type Custom_Widget is new Widget with private;
package Adi.Widget.Extension is

   type Handle is private;
   Null_Handle : constant Handle;

   --  Allocate a default-initialised Custom_Widget and register it in
   --  the widget store, which owns it from here on.  Visible is set, as
   --  it is for the library's own widgets.  The allocation is released
   --  if registration fails.
   function New_Widget return Handle;

   function Is_Valid (H : Handle) return Boolean;
   function To_Widget_Handle (H : Handle) return Widget_Handle;
   function "+" (H : Handle) return Widget_Handle;

   --  Recover the typed handle, as Try_As_Box and its siblings do.
   --  Null_Handle when H is null, stale, or designates a widget outside
   --  Custom_Widget'Class.
   function Try_As (H : Widget_Handle) return Handle;

   ---------------------------------------------------------------------------
   --  Scoped borrow
   --
   --  Pin the widget for the lifetime of the returned Ref, as
   --  Adi.Widget.Borrow does, and view it as Custom_Widget'Class so the
   --  type's own components are reachable.  A Destroy while a Ref is
   --  alive is deferred until the last one finalizes.
   ---------------------------------------------------------------------------

   type Ref (Ptr : access Custom_Widget'Class) is
     limited new Ada.Finalization.Limited_Controlled with private
     with Implicit_Dereference => Ptr;

   --  Raises Constraint_Error when H is Null_Handle, when it is stale,
   --  and when it designates a widget that is not a Custom_Widget,
   --  matching Adi.Widget.Borrow.  The pin count is unchanged on every
   --  one of those paths.
   function Borrow (H : Handle) return Ref;

private

   type Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;

   Null_Handle : constant Handle := (Id => Widget_Stores.Null_Id);

   type Ref (Ptr : access Custom_Widget'Class) is
     limited new Ada.Finalization.Limited_Controlled with record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;

   overriding procedure Finalize (R : in out Ref);

end Adi.Widget.Extension;
