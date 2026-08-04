pragma Ada_2022;

with Adi.Core;   use Adi.Core;
with Adi.Widget; use Adi.Widget;

--  A widget that records the coordinates the window hands to its mouse
--  primitives, so a test can check the coordinate space they arrive in.
--
--  Library level rather than nested in the test procedure: Adopt_Widget
--  takes a Widget_Access, and an access type declared inside a procedure
--  cannot be converted to one declared at library level.
package Test_Mouse_Probe is

   type Probe_Widget is new Widget with private;

   --  Allocate a probe, register it, and mark it clickable so the window
   --  routes presses to it. The widget store owns the allocation: do not
   --  free the object.
   function Create_Handle return Widget_Handle;

   --  Coordinates passed to the most recent call of each primitive, and
   --  how many times each has been called. Zero and the origin for a
   --  handle that is not a probe.
   function Down_Count (H : Widget_Handle) return Natural;
   function Move_Count (H : Widget_Handle) return Natural;
   function Up_Count   (H : Widget_Handle) return Natural;

   function Last_Down (H : Widget_Handle) return Point;
   function Last_Move (H : Widget_Handle) return Point;
   function Last_Up   (H : Widget_Handle) return Point;

   procedure Reset (H : Widget_Handle);

private

   type Probe_Widget is new Widget with record
      Downs   : Natural := 0;
      Moves   : Natural := 0;
      Ups     : Natural := 0;
      Down_At : Point := (0.0, 0.0);
      Move_At : Point := (0.0, 0.0);
      Up_At   : Point := (0.0, 0.0);
   end record;

   overriding procedure Build_Items (W : in out Probe_Widget) is null;
   overriding procedure Layout (W : in out Probe_Widget) is null;

   overriding procedure On_Mouse_Down
     (W      : in out Probe_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);

   overriding procedure On_Mouse_Move
     (W    : in out Probe_Widget;
      X, Y : Pixel_Type);

   overriding procedure On_Mouse_Up
     (W      : in out Probe_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button);

end Test_Mouse_Probe;
