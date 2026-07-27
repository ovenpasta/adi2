pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;

package body Test_Support is

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

end Test_Support;
