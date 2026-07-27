pragma Ada_2022;

package Test_Support is

   --  Print the suite header line.
   procedure Start_Suite (Name : String);

   --  Print a section marker ("-- Name --").
   procedure Section (Name : String);

   --  Count and report one check. Failures print "[FAIL] Message";
   --  passes count silently (matching the majority of existing tests).
   procedure Assert (Condition : Boolean; Message : String);

   --  Print the summary line and set a failing process exit status
   --  when any Assert failed. Call as the last statement of a test.
   procedure Finish;

   function Failures return Natural;

end Test_Support;
