pragma Ada_2022;

package body Test_Mouse_Probe is

   --  A view of the widget behind H as a probe, or null when H is stale
   --  or designates some other widget type.
   function Probe_Of (H : Widget_Handle) return Widget_Access is
      A : constant Widget_Access := Resolve_Handle (H);
   begin
      if A = null or else A.all not in Probe_Widget'Class then
         return null;
      end if;
      return A;
   end Probe_Of;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle return Widget_Handle is
      Ptr : constant Widget_Access := new Probe_Widget;
      H   : constant Widget_Handle := Adopt_Widget (Ptr);
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

   function Down_Count (H : Widget_Handle) return Natural is
      A : constant Widget_Access := Probe_Of (H);
   begin
      return (if A = null then 0 else Probe_Widget (A.all).Downs);
   end Down_Count;

   function Move_Count (H : Widget_Handle) return Natural is
      A : constant Widget_Access := Probe_Of (H);
   begin
      return (if A = null then 0 else Probe_Widget (A.all).Moves);
   end Move_Count;

   function Up_Count (H : Widget_Handle) return Natural is
      A : constant Widget_Access := Probe_Of (H);
   begin
      return (if A = null then 0 else Probe_Widget (A.all).Ups);
   end Up_Count;

   function Last_Down (H : Widget_Handle) return Point is
      A : constant Widget_Access := Probe_Of (H);
   begin
      return (if A = null then (0.0, 0.0) else Probe_Widget (A.all).Down_At);
   end Last_Down;

   function Last_Move (H : Widget_Handle) return Point is
      A : constant Widget_Access := Probe_Of (H);
   begin
      return (if A = null then (0.0, 0.0) else Probe_Widget (A.all).Move_At);
   end Last_Move;

   function Last_Up (H : Widget_Handle) return Point is
      A : constant Widget_Access := Probe_Of (H);
   begin
      return (if A = null then (0.0, 0.0) else Probe_Widget (A.all).Up_At);
   end Last_Up;

   procedure Reset (H : Widget_Handle) is
      A : constant Widget_Access := Probe_Of (H);
   begin
      if A = null then
         return;
      end if;

      declare
         P : Probe_Widget renames Probe_Widget (A.all);
      begin
         P.Downs := 0;
         P.Moves := 0;
         P.Ups := 0;
         P.Down_At := (0.0, 0.0);
         P.Move_At := (0.0, 0.0);
         P.Up_At := (0.0, 0.0);
      end;
   end Reset;

end Test_Mouse_Probe;
