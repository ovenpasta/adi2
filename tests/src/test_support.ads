pragma Ada_2022;

with Adi.Image;

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

   --  Keep an image for the rest of the program and hand back a view of
   --  it. A test draws through views, and something has to own; where
   --  what is under test is the owning itself, hold the owner instead.
   function Keep (O : Adi.Image.Image_Owner) return Adi.Image.Image_Handle;

end Test_Support;
