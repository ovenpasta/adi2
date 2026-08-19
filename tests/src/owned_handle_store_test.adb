pragma Ada_2022;

with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Vectors;
with Adi.Owned_Handle_Store;
with Test_Support; use Test_Support;

--  The strong/weak split on its own, with an object that only counts
--  what happens to it. Ada's controlled operations run at points the
--  source does not name -- a copy on return, an Adjust after an
--  assignment, a Finalize when a vector shifts its elements -- so what
--  is exercised here is those points rather than the arithmetic.

procedure Owned_Handle_Store_Test is

   Reclaims  : Natural := 0;
   Wipe_Nope : Boolean := False;

   Wipe_Failed : exception;

   type Thing is tagged limited record
      Value : Integer := 0;
   end record;

   type Thing_Access is access all Thing'Class;

   procedure Wipe (T : in out Thing'Class);

   procedure Wipe (T : in out Thing'Class) is
   begin
      if Wipe_Nope then
         Wipe_Nope := False;
         raise Wipe_Failed;
      end if;
      Reclaims := Reclaims + 1;
      T.Value := 0;
   end Wipe;

   package Things is new Adi.Owned_Handle_Store (Thing, Thing_Access, Wipe);
   use Things;

   package Owner_Vectors is new Ada.Containers.Vectors (Positive, Owner);
   package Owner_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (String, Owner);

   function Make (V : Integer) return Owner
   is (Register (new Thing'(Value => V)));

   --  Owner is controlled and so passed by reference: handing the same
   --  object as both parameters makes the assignment inside a real
   --  self-assignment, which the compiler cannot recognise and drop the
   --  way it drops a literal "A := A".
   procedure Assign (Target : in out Owner; Source : Owner);

   procedure Assign (Target : in out Owner; Source : Owner) is
   begin
      Target := Source;
   end Assign;

begin
   Start_Suite ("Owned handle store test");

   ---------------------------------------------------------------------
   Section ("one owner, and the view that does not own");
   declare
      Before : constant Natural := Reclaims;
      Seen   : Handle;
   begin
      declare
         O : Owner := Make (7);
      begin
         Seen := View (O);
         Assert (Is_Owned (O), "the owner holds it");
         Assert (Is_Valid (Seen), "and the view finds it");
         Assert (Resolve (Seen).Value = 7, "naming the same object");

         --  Copying a view neither keeps the object nor costs anything.
         declare
            Copy : constant Handle := Seen;
         begin
            Assert (Is_Valid (Copy), "a copied view names it too");
         end;
         Assert (Reclaims = Before,
                 "and dropping that copy reclaims nothing: a view has no"
                 & " share to give up");
      end;

      Assert (Reclaims = Before + 1,
              "leaving the scope of the last owner reclaims the object");
      Assert (not Is_Valid (Seen),
              "and every view of it goes stale in that moment, rather"
              & " than keeping it alive for whoever still points at it");
      Assert (Resolve (Seen) = null, "so resolving one finds nothing");
   end;

   ---------------------------------------------------------------------
   Section ("a second owner keeps it, and only the last one ends it");
   declare
      Before : constant Natural := Reclaims;
      Seen   : Handle;
   begin
      declare
         First : Owner := Make (3);
      begin
         Seen := View (First);
         declare
            --  Assignment, so Adjust runs on the copy.
            Second : Owner := First;
         begin
            Assert (Is_Owned (Second), "the copy owns it too");
            Release (First);
            Assert (Reclaims = Before,
                    "Releasing one of two reclaims nothing: the object"
                    & " is still owned");
            Assert (not Is_Owned (First), "though that owner is spent");
            Assert (Is_Valid (Seen), "and views still find it");
         end;

         Assert (Reclaims = Before + 1,
                 "the second going out of scope was the last share");
         Assert (not Is_Valid (Seen), "so the views went stale");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("releasing twice, and owning nothing");
   declare
      Before : constant Natural := Reclaims;
      O      : Owner := Make (1);
      Empty  : Owner;
   begin
      Release (O);
      Assert (Reclaims = Before + 1, "the first release reclaimed it");
      Release (O);
      Assert (Reclaims = Before + 1,
              "and the second is no work: an owner that gave up its"
              & " share has none to give up twice");

      Assert (not Is_Owned (Empty), "a default owner holds nothing");
      Release (Empty);
      Assert (Resolve (Empty) = null, "and releasing it is no work");
      Assert (View (Empty) = Null_Handle, "its view names nothing");
   end;

   ---------------------------------------------------------------------
   Section ("assigning over an owner ends what it held");
   declare
      Before : constant Natural := Reclaims;
      A      : Owner := Make (10);
      B      : constant Owner := Make (20);
      Old    : constant Handle := View (A);
   begin
      A := B;
      Assert (Reclaims = Before + 1,
              "the object A held loses its only owner and goes");
      Assert (not Is_Valid (Old), "so views of it are stale");
      Assert (Resolve (A).Value = 20, "and A now holds B's object");
   end;

   ---------------------------------------------------------------------
   Section ("assigning an owner to itself changes nothing");
   declare
      Before : constant Natural := Reclaims;
      A      : Owner := Make (5);
      Seen   : constant Handle := View (A);
   begin
      Assign (A, A);
      Assert (Reclaims = Before,
              "Self-assignment reclaims nothing. Assignment adjusts an"
              & " anonymous copy before finalising the target (RM"
              & " 7.6(17)), and the whole operation may be skipped when"
              & " the two are the same object (RM 7.6(19)) -- so this"
              & " records what a caller may rely on, not which of the"
              & " two happened");
      Assert (Is_Owned (A), "the owner still holds it");
      Assert (Is_Valid (Seen) and then Resolve (Seen).Value = 5,
              "and it is unchanged");
   end;

   ---------------------------------------------------------------------
   Section ("owners in containers are released, not merely removed");
   declare
      Before : constant Natural := Reclaims;
      Views  : array (1 .. 3) of Handle;
      M      : Owner_Maps.Map;
      V      : Owner_Vectors.Vector;

      procedure Give_Up (Key : String; O : in out Owner);
      procedure Give_Up_Elem (O : in out Owner);

      procedure Give_Up (Key : String; O : in out Owner) is
         pragma Unreferenced (Key);
      begin
         Release (O);
      end Give_Up;

      procedure Give_Up_Elem (O : in out Owner) is
      begin
         Release (O);
      end Give_Up_Elem;
   begin
      for I in 1 .. 3 loop
         declare
            O : constant Owner := Make (I * 100);
         begin
            M.Insert ("k" & I'Image, O);
            V.Append (O);
            Views (I) := View (O);
         end;
      end loop;

      Assert (Reclaims = Before,
              "Inserting copies the owner in, so the one that went out"
              & " of scope was not the last");
      Assert ((for all H of Views => Is_Valid (H)),
              "and every object is still there");

      --  Two containers hold each object, so ending one means releasing
      --  through both. When a container finalises a value it drops is
      --  its own affair -- the standard does not say, and GNAT's map and
      --  vector do not agree -- so nothing here waits to find out.
      M.Update_Element (M.Find ("k 1"), Give_Up'Access);
      M.Delete ("k 1");
      Assert (Reclaims = Before,
              "one of the two shares given up reclaims nothing");
      Assert (Is_Valid (Views (1)), "the object is still owned");

      declare
         Held : Owner := V.Element (1);
      begin
         Release (Held);
      end;
      Assert (Reclaims = Before,
              "and releasing a copy taken out of the vector gives up"
              & " that copy's share, not the vector's");
      Assert (Is_Valid (Views (1)), "so the object is still there");

      V.Update_Element (1, Give_Up_Elem'Access);
      Assert (Reclaims = Before + 1,
              "Releasing the vector's own element was the last share:"
              & " ending an object at a chosen moment means releasing"
              & " every owner of it, rather than removing them and"
              & " trusting the container to finalise when it likes");
      Assert (not Is_Valid (Views (1)), "so its views are stale");
      Assert (Is_Valid (Views (2)), "and the others are untouched");
   end;

   ---------------------------------------------------------------------
   Section ("a Reclaim that fails still ends the object");
   declare
      Before : constant Natural := Reclaims;
      O      : Owner := Make (1);
      Seen   : constant Handle := View (O);
      Raised : Boolean := False;
   begin
      Wipe_Nope := True;
      begin
         Release (O);
      exception
         when Wipe_Failed =>
            Raised := True;
      end;

      Assert (Raised, "the failure reaches whoever released");
      Assert (Reclaims = Before, "and nothing was emptied");
      Assert (not Is_Valid (Seen),
              "The slot is retired anyway: the owner that would have"
              & " tried again is already spent, and leaving it live"
              & " would strand a half-emptied object every view still"
              & " resolves to");
      Assert (not Is_Owned (O), "the owner holds nothing either");

      declare
         Next : constant Owner := Make (2);
      begin
         Assert (Is_Owned (Next) and then Resolve (Next).Value = 2,
                 "and the store is still usable afterwards");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("a slot reused later does not revive a stale view");
   declare
      Stale : Handle;
   begin
      declare
         O : constant Owner := Make (1);
      begin
         Stale := View (O);
      end;

      declare
         Next : constant Owner := Make (2);
      begin
         Assert (Is_Owned (Next), "the next object registers");
         Assert (View (Next) /= Stale,
                 "and does not compare equal to the stale view, even"
                 & " taking the slot it left");
         Assert (not Is_Valid (Stale), "which stays stale");
      end;
   end;

   Finish;
end Owned_Handle_Store_Test;
