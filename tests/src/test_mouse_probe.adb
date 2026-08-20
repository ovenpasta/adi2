pragma Ada_2022;

package body Test_Mouse_Probe is

   -------------------
   -- Create_Handle --
   -------------------

   use Probes;

   function Create_Handle return Widget_Handle is
      H : constant Widget_Handle := +Probes.New_Widget;
   begin
      Set_Flag (H, Clickable, True);
      return H;
   end Create_Handle;

   ----------------
   -- Primitives --
   ----------------

   overriding procedure On_Mouse_Down
     (W      : in out Probe_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (Button, Clicks);
   begin
      W.Downs := W.Downs + 1;
      W.Down_At := (X, Y);
   end On_Mouse_Down;

   overriding procedure On_Mouse_Move
     (W    : in out Probe_Widget;
      X, Y : Pixel_Type) is
   begin
      W.Moves := W.Moves + 1;
      W.Move_At := (X, Y);
   end On_Mouse_Move;

   overriding procedure On_Mouse_Up
     (W      : in out Probe_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button)
   is
      pragma Unreferenced (Button);
   begin
      W.Ups := W.Ups + 1;
      W.Up_At := (X, Y);
   end On_Mouse_Up;

   -------------
   -- Queries --
   -------------

   --  Each query resolves the handle first and answers with its
   --  documented default when H is stale or is not a probe; otherwise it
   --  reads through a borrow that ends with the call.

   function Down_Count (H : Widget_Handle) return Natural is
      P : constant Probes.Handle := Probes.Try_As (H);
   begin
      if not Probes.Is_Valid (P) then
         return 0;
      end if;
      return Probes.Borrow (P).Downs;
   end Down_Count;

   function Move_Count (H : Widget_Handle) return Natural is
      P : constant Probes.Handle := Probes.Try_As (H);
   begin
      if not Probes.Is_Valid (P) then
         return 0;
      end if;
      return Probes.Borrow (P).Moves;
   end Move_Count;

   function Up_Count (H : Widget_Handle) return Natural is
      P : constant Probes.Handle := Probes.Try_As (H);
   begin
      if not Probes.Is_Valid (P) then
         return 0;
      end if;
      return Probes.Borrow (P).Ups;
   end Up_Count;

   function Last_Down (H : Widget_Handle) return Point is
      P : constant Probes.Handle := Probes.Try_As (H);
   begin
      if not Probes.Is_Valid (P) then
         return (0.0, 0.0);
      end if;
      return Probes.Borrow (P).Down_At;
   end Last_Down;

   function Last_Move (H : Widget_Handle) return Point is
      P : constant Probes.Handle := Probes.Try_As (H);
   begin
      if not Probes.Is_Valid (P) then
         return (0.0, 0.0);
      end if;
      return Probes.Borrow (P).Move_At;
   end Last_Move;

   function Last_Up (H : Widget_Handle) return Point is
      P : constant Probes.Handle := Probes.Try_As (H);
   begin
      if not Probes.Is_Valid (P) then
         return (0.0, 0.0);
      end if;
      return Probes.Borrow (P).Up_At;
   end Last_Up;

   procedure Reset (H : Widget_Handle) is
      P : constant Probes.Handle := Probes.Try_As (H);
   begin
      if not Probes.Is_Valid (P) then
         return;
      end if;

      declare
         R : constant Probes.Ref := Probes.Borrow (P);
      begin
         R.Downs := 0;
         R.Moves := 0;
         R.Ups := 0;
         R.Down_At := (0.0, 0.0);
         R.Move_At := (0.0, 0.0);
         R.Up_At := (0.0, 0.0);
      end;
   end Reset;

end Test_Mouse_Probe;
