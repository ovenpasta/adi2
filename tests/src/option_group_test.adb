pragma Ada_2022;

with Test_Support; use Test_Support;
with Adi.Widget;   use Adi.Widget;
with Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget.Button.Options.Testing;

--  An option group hands every button it owns a pointer back to itself,
--  so the group has to outlive those buttons or unlink them on the way
--  out. The cases below are the ways the two lifetimes can cross.
procedure Option_Group_Test is

   use Adi.Widget.Button;

   type Choice is (Alpha, Beta, Gamma);
   package Choices is new Adi.Widget.Button.Options (Choice);
   use Choices;
   package Choices_Testing is new Choices.Testing;
   use Choices_Testing;

   procedure Test_Finalize_Unlinks is
      A : constant Button_Handle := Create_Handle ("A");
      B : constant Button_Handle := Create_Handle ("B");
   begin
      Section ("Finalizing a group unlinks its buttons");

      declare
         G : Option_Group;
      begin
         Set_Button (G, Alpha, A);
         Set_Button (G, Beta,  B);
         Assert (Is_Linked (A) and then Is_Linked (B),
                 "both buttons are linked while the group lives");
      end;

      Assert (not Is_Linked (A) and then not Is_Linked (B),
              "both buttons are unlinked when the group goes");
   end Test_Finalize_Unlinks;

   procedure Test_Replacing_An_Option_Unlinks is
      First  : constant Button_Handle := Create_Handle ("first");
      Second : constant Button_Handle := Create_Handle ("second");
      G      : Option_Group;
   begin
      Section ("Replacing an option unlinks the button that held it");

      Set_Button (G, Alpha, First);
      Assert (Is_Linked (First), "the first button is linked");

      Set_Button (G, Alpha, Second);
      Assert (not Is_Linked (First),
              "the replaced button is unlinked");
      Assert (Is_Linked (Second), "the new button is linked");
   end Test_Replacing_An_Option_Unlinks;

   procedure Test_Move_Between_Groups is
      B  : constant Button_Handle := Create_Handle ("moving");
      G1 : Option_Group;
      G2 : Option_Group;
   begin
      Section ("Moving a button between groups");

      Set_Button (G1, Alpha, B);
      Set_Button (G2, Beta, B);

      Assert (Is_Linked (B), "the button is linked to its new group");

      --  Asserted on the recorded membership, not on behaviour: every
      --  operation checks the button's link, so a retained entry would
      --  be invisible from the outside.
      Assert (Choices_Testing.Recorded (G1, Alpha) = Null_Button_Handle,
              "the old group dropped the membership");
      Assert (Choices_Testing.Recorded (G2, Beta) = B,
              "the new group recorded it");

      Set_Button (G1, Gamma, Create_Handle ("other"));
      Set_Selected (G1, Gamma);
      Assert (Get_Selected (G1) = Gamma, "the old group still works");
      Assert (Is_Linked (B),
              "the old group did not touch the moved button's link");
   end Test_Move_Between_Groups;

   procedure Test_Old_Group_Finalize_Keeps_New_Link is
      B : constant Button_Handle := Create_Handle ("moving");
   begin
      Section ("Finalizing the old group leaves the newer link alone");

      declare
         G2 : Option_Group;
      begin
         declare
            G1 : Option_Group;
         begin
            Set_Button (G1, Alpha, B);
            Set_Button (G2, Beta,  B);
         end;   --  G1 finalizes here, after the button has moved on

         Assert (Is_Linked (B),
                 "the button keeps the link to the group it moved to");
      end;

      Assert (not Is_Linked (B),
              "and loses it when that group goes too");
   end Test_Old_Group_Finalize_Keeps_New_Link;

   --  The case conditional unlinking exists for: a group holding an
   --  entry for a button whose link names someone else. Set_Button
   --  creates it on every move, between publishing the new link and
   --  Forget_Button reaching the old group, and leaves it for good if
   --  that call propagates an exception.
   procedure Test_Unlink_Is_Conditional is
      B : constant Button_Handle := Create_Handle ("relinked");
   begin
      Section ("A group only unlinks a button that still points at it");

      declare
         G : Option_Group;
      begin
         Set_Button (G, Alpha, B);

         Rebind_Elsewhere (B);
         Assert (Links_Elsewhere (B), "the button now points elsewhere");
      end;   --  G finalizes while still holding B in its array

      Assert (Links_Elsewhere (B),
              "finalizing the group it left did not sever the new link");
   end Test_Unlink_Is_Conditional;

   --  A group must not drive a button that no longer points at it. The
   --  link, not merely the handle resolving, is what says the button is
   --  still ours -- Set_Button leaves exactly this state in the group a
   --  button moves away from, until Forget_Button reaches it.
   procedure Test_Group_Does_Not_Drive_Foreign_Button is
      B    : constant Button_Handle := Create_Handle ("taken");
      Keep : constant Button_Handle := Create_Handle ("kept");
      Was  : Boolean;
   begin
      Section ("A group leaves a rebound button alone");

      declare
         G : Option_Group;
      begin
         Set_Button (G, Alpha, B);
         Set_Button (G, Beta,  Keep);

         --  B's link moves on while G still records it.
         Rebind_Elsewhere (B);

         Was := Is_Toggled (B);

         --  Selecting Alpha would toggle B on, and selecting away would
         --  toggle it off, if the group still considered it a member.
         Set_Selected (G, Alpha);
         Assert (Is_Toggled (B) = Was,
                 "Set_Selected does not toggle a rebound button on");

         Set_Selected (G, Beta);
         Assert (Is_Toggled (B) = Was,
                 "and does not toggle it off either");

         --  Nor through a click routed to the group.
         Click (G, B);
         Assert (Get_Selected (G) = Beta,
                 "a click on a rebound button does not move the group");
      end;
   end Test_Group_Does_Not_Drive_Foreign_Button;

   procedure Test_Button_Destroyed_First is
      A : Button_Handle := Create_Handle ("doomed");
      G : Option_Group;
      W : Widget_Handle;
   begin
      Section ("A button destroyed before its group");

      Set_Button (G, Alpha, A);
      Set_Button (G, Beta, Create_Handle ("survivor"));

      W := +A;
      Destroy (W);
      Pump_Widget_Store;
      Assert (not Is_Valid (A), "the button is gone");

      --  Every path through the group has to tolerate this.
      Set_Selected (G, Alpha);
      Assert (Get_Selected (G) = Alpha,
              "selecting a destroyed button's option does not raise");
      Set_Selected (G, Beta);
      Assert (Get_Selected (G) = Beta, "and the group keeps working");
      A := Null_Button_Handle;
   end Test_Button_Destroyed_First;

   procedure Test_Click_Selects is
      A : constant Button_Handle := Create_Handle ("A");
      B : constant Button_Handle := Create_Handle ("B");
      G : Option_Group;
      Seen : Choice := Choice'Last;

      procedure On_Changed (Value : Choice) is
      begin
         Seen := Value;
      end On_Changed;
   begin
      Section ("Clicking still drives the group");

      Set_Button (G, Alpha, A);
      Set_Button (G, Beta,  B);
      Connect_Changed (G, On_Changed'Unrestricted_Access);

      Assert (Get_Selected (G) = Alpha, "the first button set the option");

      Click (G, B);
      Assert (Get_Selected (G) = Beta, "clicking B selects Beta");
      Assert (Seen = Beta, "and the change is reported");
   end Test_Click_Selects;

begin
   Start_Suite ("Option Group Tests");

   Test_Finalize_Unlinks;
   Test_Replacing_An_Option_Unlinks;
   Test_Move_Between_Groups;
   Test_Old_Group_Finalize_Keeps_New_Link;
   Test_Unlink_Is_Conditional;
   Test_Group_Does_Not_Drive_Foreign_Button;
   Test_Button_Destroyed_First;
   Test_Click_Selects;

   Test_Support.Finish;
end Option_Group_Test;
