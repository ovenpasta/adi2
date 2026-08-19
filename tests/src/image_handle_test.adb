pragma Ada_2022;

with Adi.Core;          use Adi.Core;
with Adi.Image;         use Adi.Image;
with Adi.Image.Testing;
with Adi.SDL.Surface;   use Adi.SDL.Surface;
with Test_Support;      use Test_Support;

--  Who owns an image and who merely looks at one. Loading yields an
--  owner; everything that draws takes a handle, which keeps nothing.

procedure Image_Handle_Test is

   Q : constant Character := '"';

   Fixture : constant String :=
     "<svg xmlns=" & Q & "http://www.w3.org/2000/svg" & Q
     & " width=" & Q & "20" & Q & " height=" & Q & "10" & Q & ">"
     & "<rect width=" & Q & "20" & Q & " height=" & Q & "10" & Q
     & " fill=" & Q & "#fff" & Q & "/></svg>";

   type Handle_Array is array (Positive range <>) of Image_Handle;

   function Make return Image_Owner is
     (Load_SVG_From_String (Fixture));

begin
   Start_Suite ("Image handle test");

   ---------------------------------------------------------------------
   Section ("an owner keeps the image; a handle only names it");
   declare
      Viewer : Image_Handle;
      W, H   : Pixel_Type;
   begin
      declare
         Owner : Image_Owner := Make;
      begin
         Assert (Is_Owned (Owner), "the fixture loads");
         Viewer := To_Handle (Owner);
         Assert (Is_Valid (Viewer), "and the view finds it");
         Get_Size (Viewer, W, H);
         Assert (W = 20.0 and then H = 10.0, "at its own size");

         declare
            Copy : constant Image_Handle := Viewer;
         begin
            Assert (Copy = Viewer, "a copied view names the same image");
         end;

         Release (Owner);
         Assert (not Is_Owned (Owner), "releasing spends the owner");
         Assert (not Adi.Image.Testing.Handle_Is_Registered (Viewer),
                 "The slot is retired, asked of the store rather than of"
                 & " the image: an emptied image answers Is_Valid False"
                 & " without anything having been retired");
         Assert (not Is_Valid (Viewer),
                 "and the view, which nobody nulled, reports nothing to"
                 & " draw rather than reaching freed storage");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("an owner going out of scope ends the image");
   declare
      Viewer : Image_Handle;
   begin
      declare
         Owner : constant Image_Owner := Make;
      begin
         Viewer := To_Handle (Owner);
         Assert (Is_Valid (Viewer), "drawable while owned");
      end;

      Assert (not Is_Valid (Viewer),
              "Leaving the owner's scope ends it: an image outlives its"
              & " owner nowhere, which is what makes the owner the thing"
              & " an application has to keep for as long as it draws");
   end;

   ---------------------------------------------------------------------
   Section ("a second owner keeps it, and only the last one ends it");
   declare
      Viewer : Image_Handle;
   begin
      declare
         First : Image_Owner := Make;
      begin
         Viewer := To_Handle (First);
         declare
            Second : constant Image_Owner := First;
            pragma Unreferenced (Second);
         begin
            Release (First);
            Assert (Is_Valid (Viewer),
                    "one of two owners letting go ends nothing");
         end;
         Assert (not Is_Valid (Viewer),
                 "and the second going was the last share");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("every operation has an answer for a handle naming nothing");
   declare
      Stale  : Image_Owner := Make;
      Seen   : constant Image_Handle := To_Handle (Stale);
      W, H   : Pixel_Type := 99.0;
   begin
      Release (Stale);

      declare
         Probes : constant Handle_Array (1 .. 2) :=
           [Seen, Null_Image_Handle];
      begin
         for Probe of Probes loop
            W := 99.0;
            H := 99.0;
            Assert (not Is_Valid (Probe), "nothing to draw");
            Assert (not Is_Tintable (Probe), "not tintable");
            Assert (Get_Surface (Probe) = null, "no surface");
            Assert (Get_Scale_Mode (Probe) = Scale_Linear,
                    "the default scale mode");
            Get_Size (Probe, W, H);
            Assert (W = 0.0 and then H = 0.0,
                    "no extent, out parameters included: leaving them"
                    & " untouched would hand layout whatever the caller"
                    & " had in them");

            --  Setters have nothing to set, and must not raise for it.
            Set_Tintable (Probe);
            Set_Scale_Mode (Probe, Scale_Nearest);
            Assert (Get_Scale_Mode (Probe) = Scale_Linear,
                    "and a setter on a handle naming nothing changes"
                    & " nothing rather than raising");
         end loop;
      end;

      --  Idempotent, and safe on an owner that never held anything.
      Release (Stale);
      declare
         Never : Image_Owner := Null_Image_Owner;
      begin
         Release (Never);
         Assert (not Is_Owned (Never), "releasing nothing is no work");
         Assert (To_Handle (Never) = Null_Image_Handle,
                 "and its view names nothing");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("a reused slot does not revive the handle that held it");
   declare
      Stale : Image_Handle;
   begin
      declare
         First : constant Image_Owner := Make;
      begin
         Stale := To_Handle (First);
      end;

      declare
         Second : constant Image_Owner := Make;
      begin
         Assert (Is_Owned (Second), "the replacement loads");
         Assert (To_Handle (Second) /= Stale,
                 "The new image does not compare equal to the old view:"
                 & " the generation moved on, which is what stops a"
                 & " handle outliving one image from naming its"
                 & " successor in the slot it left");
         Assert (not Is_Valid (Stale), "which stays stale");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("a failed load owns nothing");
   declare
      Owner : constant Image_Owner :=
        Load_SVG_From_String ("not an svg at all");
   begin
      Assert (not Is_Owned (Owner), "there was nothing to own");
      Assert (not Is_Valid (To_Handle (Owner)),
              "and its view has nothing to draw");
   end;

   ---------------------------------------------------------------------
   Section ("an empty image is owned, with nothing to draw");
   declare
      Owner : constant Image_Owner := Create_Empty;
      W, H  : Pixel_Type;
   begin
      Assert (Is_Owned (Owner), "Create_Empty yields an owner");
      Assert (Adi.Image.Testing.Handle_Is_Registered (To_Handle (Owner)),
              "the store holds it");
      Assert (not Is_Valid (To_Handle (Owner)),
              "but it has no picture, so nothing draws it");
      Get_Size (To_Handle (Owner), W, H);
      Assert (W = 0.0 and then H = 0.0, "and it measures zero");
   end;

   Finish;
end Image_Handle_Test;
