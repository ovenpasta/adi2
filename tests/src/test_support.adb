pragma Ada_2022;

with Ada.Containers.Vectors;
with Adi.Image; use type Adi.Image.Image_Owner;

with Ada.Command_Line;
with Ada.Text_IO;

package body Test_Support is

   --  Owners live here until the program ends. Nothing releases them:
   --  the images are wanted for as long as the test runs.
   package Owner_Vectors is new Ada.Containers.Vectors
     (Positive, Adi.Image.Image_Owner);

   Kept : Owner_Vectors.Vector;


   Passed : Natural := 0;
   Failed : Natural := 0;

   -----------------
   -- Start_Suite --
   -----------------

   procedure Start_Suite (Name : String) is
   begin
      Ada.Text_IO.Put_Line ("=== " & Name & " ===");
   end Start_Suite;

   -------------
   -- Section --
   -------------

   procedure Section (Name : String) is
   begin
      Ada.Text_IO.Put_Line ("-- " & Name & " --");
   end Section;

   ------------
   -- Assert --
   ------------

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Passed := Passed + 1;
      else
         Failed := Failed + 1;
         Ada.Text_IO.Put_Line ("[FAIL] " & Message);
      end if;
   end Assert;

   ------------
   -- Finish --
   ------------

   procedure Finish is
   begin
      Ada.Text_IO.Put_Line
        ("Results:" & Passed'Image & " passed," & Failed'Image & " failed");
      if Failed > 0 then
         Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      else
         Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
      end if;
   end Finish;

   --------------
   -- Failures --
   --------------

   function Failures return Natural is (Failed);

   function Keep (O : Adi.Image.Image_Owner) return Adi.Image.Image_Handle is
   begin
      Kept.Append (O);
      return Adi.Image.To_Handle (O);
   end Keep;

end Test_Support;
