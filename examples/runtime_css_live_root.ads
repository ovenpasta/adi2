pragma Ada_2022;

with Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Extension;

--  The example's root widget: a box that ticks the style source each
--  frame and reports reloads through a label.
--
--  Library level rather than nested in the example procedure, because
--  the widget store owns what it registers and dispatches through its
--  tag while doing so.  Adi.Widget.Extension.New_Widget allocates
--  through Widget_Access, so a nested type would be rejected.  The style
--  source lives here for the same reason: the widget holds a pointer to
--  it for as long as it is registered.
package Runtime_Css_Live_Root is

   type Live_Root_Widget is new Adi.Widget.Box.Box_Widget with private;

   type Handle is private;

   --  Ticked by the root widget, bound to the widget tree by the example.
   Source : aliased Adi.CSS_Source.Style_Source;

   function Create_Handle return Handle;
   function "+" (H : Handle) return Widget_Handle;

   --  The label to tell about reloads and reload errors.
   procedure Set_Status_Label
     (H : Handle; Label : Adi.Widget.Label.Label_Handle);

private

   type Live_Root_Widget is new Adi.Widget.Box.Box_Widget with record
      Status_Label : Adi.Widget.Label.Label_Handle;
      Reload_Count : Natural := 0;
      Last_OK      : Boolean := True;
   end record;

   overriding procedure On_Tick (W : in out Live_Root_Widget; DT : Duration);

   package Impl is new Adi.Widget.Extension (Live_Root_Widget);

   type Handle is record
      Ref : Impl.Handle := Impl.Null_Handle;
   end record;

end Runtime_Css_Live_Root;
