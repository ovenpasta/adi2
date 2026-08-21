pragma Ada_2022;

with Adi.Core;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Extension;

--  Custom widget types for widget_extension_test and for the
--  destroy-under-dispatch tests in widget_handle_test.
--
--  Library level rather than nested in the test procedure: the widget
--  store owns what it registers and dispatches through its tag, so a
--  widget type declared inside a subprogram cannot be stored.
--  Adi.Widget.Extension.New_Widget allocates through Widget_Access and
--  the accessibility check enforces that.
package Test_Extension_Widgets is

   --  A reusable custom widget written the way an application would
   --  write one: the type and its component are private, and callers see
   --  only a typed handle whose operations borrow internally.
   type Gauge is new Adi.Widget.Box.Box_Widget with private;
   type Gauge_Handle is private;

   function Create_Gauge return Gauge_Handle;
   function Is_Valid (H : Gauge_Handle) return Boolean;
   function "+" (H : Gauge_Handle) return Widget_Handle;

   procedure Set_Reading (H : Gauge_Handle; Value : Float);
   function  Get_Reading (H : Gauge_Handle) return Float;

   --  A second custom widget whose component is visible, so the borrow
   --  and lifetime rules can be exercised from the test itself.
   type Probe is new Adi.Widget.Box.Box_Widget with record
      Marker : Natural := 0;
   end record;

   package Probes is new Adi.Widget.Extension (Probe);

   --  A widget that emits its own click signal from primitives the
   --  Widget_Handle wrappers dispatch through.  Adi.Widget.Update and
   --  Adi.Widget.Get_Min_Size reach no application callback inside the
   --  library; an application widget overriding Build_Items or
   --  Get_Min_Size is how a callback gets onto those two call paths, and
   --  a callback there may destroy the widget it is running under.
   type Reentrant is new Adi.Widget.Button.Button_Widget with record
      Click_From_Build    : Boolean := False;
      Click_From_Min_Size : Boolean := False;
      Click_From_Measure  : Boolean := False;
   end record;

   --  Each fires Clicked once and clears its own flag, so the emit does
   --  not re-enter the primitive that started it.
   overriding procedure Build_Items (W : in out Reentrant);
   overriding function Get_Min_Size (W : Reentrant) return Adi.Core.Size_2D;
   overriding function Measure_Content (W : Reentrant) return Adi.Core.Size_2D;

   package Reentrants is new Adi.Widget.Extension (Reentrant);

   procedure Click_On_Next_Build (H : Reentrants.Handle);
   procedure Click_On_Next_Min_Size (H : Reentrants.Handle);
   procedure Click_On_Next_Measure (H : Reentrants.Handle);

private

   type Gauge is new Adi.Widget.Box.Box_Widget with record
      Reading : Float := 0.0;
   end record;

   package Gauges is new Adi.Widget.Extension (Gauge);

   type Gauge_Handle is record
      Ref : Gauges.Handle := Gauges.Null_Handle;
   end record;

end Test_Extension_Widgets;
