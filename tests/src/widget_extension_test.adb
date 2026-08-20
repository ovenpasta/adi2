pragma Ada_2022;

with Test_Support; use Test_Support;
with Adi.Core;     use Adi.Core;
with Adi.Widget;   use Adi.Widget;
with Adi.Widget.Box;
with Test_Extension_Widgets; use Test_Extension_Widgets;

procedure Widget_Extension_Test is

   use Probes;

   procedure Test_New_Widget is
      H : constant Probes.Handle := Probes.New_Widget;
      W : Widget_Handle;
   begin
      Section ("New_Widget");

      Assert (Probes.Is_Valid (H), "New_Widget returns a valid handle");
      Assert (Adi.Widget.Is_Valid (+H), "the widened handle is valid too");
      Assert (Adi.Widget.Is_Visible (+H),
              "New_Widget sets Visible, as the library's own widgets do");

      W := +H;
      Destroy (W);
      Pump_Widget_Store;
      Assert (not Probes.Is_Valid (H),
              "Destroy through the widened handle stales the typed one");
   end Test_New_Widget;

   procedure Test_Try_As is
      P   : constant Probes.Handle := Probes.New_Widget;
      Box : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      W   : Widget_Handle;
   begin
      Section ("Try_As");

      Assert (Probes.Is_Valid (Probes.Try_As (+P)),
              "Try_As recovers the typed handle from a widened one");
      Assert (not Probes.Is_Valid (Probes.Try_As (Adi.Widget.Null_Handle)),
              "Try_As of Null_Handle is Null_Handle");
      Assert (not Probes.Is_Valid
                (Probes.Try_As (Adi.Widget.Box.To_Widget_Handle (Box))),
              "Try_As of another widget type is Null_Handle");

      W := +P;
      Destroy (W);
      W := Adi.Widget.Box.To_Widget_Handle (Box);
      Destroy (W);
      Pump_Widget_Store;
   end Test_Try_As;

   --  Try_As answers about a handle rather than dereferencing it, so a
   --  stale one is Null_Handle.  Borrow, which must produce a usable
   --  pointer, is the operation that raises instead.
   procedure Test_Try_As_Stale is
      P : constant Probes.Handle := Probes.New_Widget;
      W : Widget_Handle := +P;
   begin
      Section ("Try_As of a stale handle");

      Destroy (W);
      Pump_Widget_Store;
      Assert (not Probes.Is_Valid (P), "the widget is gone");

      declare
         Recovered : Probes.Handle := Probes.Null_Handle;
      begin
         Recovered := Probes.Try_As (Probes.To_Widget_Handle (P));
         Assert (not Probes.Is_Valid (Recovered),
                 "Try_As of a stale handle is Null_Handle");
      exception
         when Program_Error =>
            Assert (False,
                    "Try_As of a stale handle raised Program_Error");
      end;
   end Test_Try_As_Stale;

   procedure Test_Borrow_Mutates is
      H : constant Probes.Handle := Probes.New_Widget;
      W : Widget_Handle;
   begin
      Section ("Borrow reaches the concrete type");

      declare
         R : constant Probes.Ref := Probes.Borrow (H);
      begin
         Assert (R.Ptr /= null, "Borrow yields a non-null Ptr");
         Assert (R.Marker = 0, "a fresh widget is default-initialised");
         R.Marker := 42;
      end;

      declare
         R : constant Probes.Ref := Probes.Borrow (H);
      begin
         Assert (R.Marker = 42, "the mutation survives the borrow");
      end;

      W := +H;
      Destroy (W);
      Pump_Widget_Store;
   end Test_Borrow_Mutates;

   --  The property the store provides: a Destroy issued while a borrow is
   --  alive is recorded, not performed, and the widget stays usable until
   --  the last Ref finalizes.
   procedure Test_Destroy_Deferred_While_Borrowed is
      H : constant Probes.Handle := Probes.New_Widget;
      W : Widget_Handle := +H;      --  a copy of the base handle
   begin
      Section ("Destroy is deferred while borrowed");

      declare
         R : constant Probes.Ref := Probes.Borrow (H);
      begin
         R.Marker := 7;

         Destroy (W);
         Assert (Probes.Is_Valid (H),
                 "the widget outlives a Destroy taken while borrowed");
         Assert (R.Marker = 7,
                 "and its storage is still readable through the Ref");

         R.Marker := 8;
         Assert (R.Marker = 8, "and still writable");

         Pump_Widget_Store;
         Assert (Probes.Is_Valid (H),
                 "Pump does not collect a pinned widget");
      end;

      Assert (not Probes.Is_Valid (H),
              "the deferred destroy runs when the Ref finalizes");
   end Test_Destroy_Deferred_While_Borrowed;

   procedure Test_Nested_Borrows is
      H : constant Probes.Handle := Probes.New_Widget;
      W : Widget_Handle := +H;
   begin
      Section ("Nested borrows");

      declare
         Outer : constant Probes.Ref := Probes.Borrow (H);
      begin
         declare
            Inner : constant Probes.Ref := Probes.Borrow (H);
         begin
            Inner.Marker := 3;
            Destroy (W);
         end;

         Assert (Probes.Is_Valid (H),
                 "the outer borrow still holds the widget");
         Assert (Outer.Marker = 3, "both refs see the same widget");
      end;

      Assert (not Probes.Is_Valid (H),
              "the widget goes when the last borrow ends");
   end Test_Nested_Borrows;

   procedure Test_Borrow_Rejects is
      H : constant Probes.Handle := Probes.New_Widget;
      W : Widget_Handle := +H;
      Raised : Boolean;
   begin
      Section ("Borrow rejects handles it cannot honour");

      Raised := False;
      begin
         declare
            R : constant Probes.Ref := Probes.Borrow (Probes.Null_Handle);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Assert (Raised, "Borrow (Null_Handle) raises Constraint_Error");

      --  Nothing else holds the widget, so if the rejected call had
      --  pinned, this Destroy would be deferred and never complete.
      Destroy (W);
      Pump_Widget_Store;
      Assert (not Probes.Is_Valid (H),
              "a rejected borrow leaves the pin count alone");

      --  The store is strict, so a stale non-null id is an error rather
      --  than a silent null, matching Adi.Widget.Borrow.
      Raised := False;
      begin
         declare
            R : constant Probes.Ref := Probes.Borrow (H);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Program_Error => Raised := True;
      end;
      Assert (Raised, "Borrow of a stale handle raises Program_Error");
   end Test_Borrow_Rejects;

   procedure Test_Private_Component is
      G : constant Gauge_Handle := Create_Gauge;
      W : Widget_Handle;
   begin
      Section ("A private extension component through Borrow");

      Assert (Test_Extension_Widgets.Is_Valid (G),
              "Create_Gauge returns a valid handle");
      Assert (Get_Reading (G) = 0.0, "Reading defaults to 0.0");

      Set_Reading (G, 0.5);
      Assert (Get_Reading (G) = 0.5,
              "Set_Reading writes the private component");

      W := +G;
      Adi.Widget.Set_Geometry (W, (0.0, 0.0, 40.0, 10.0));
      Assert (Adi.Widget.Get_Geometry (W).Width = 40.0,
              "the widened handle drives the inherited Box behaviour");

      Destroy (W);
      Pump_Widget_Store;
      Assert (not Test_Extension_Widgets.Is_Valid (G),
              "Destroy stales the gauge handle");
   end Test_Private_Component;

begin
   Start_Suite ("Widget Extension Tests");

   Test_New_Widget;
   Test_Try_As;
   Test_Try_As_Stale;
   Test_Borrow_Mutates;
   Test_Destroy_Deferred_While_Borrowed;
   Test_Nested_Borrows;
   Test_Borrow_Rejects;
   Test_Private_Component;

   Test_Support.Finish;
end Widget_Extension_Test;
