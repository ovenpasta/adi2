pragma Ada_2022;

package Adi.Widget.Button.Switch is

   ---------------------------------------------------------------------------
   --  Switch Widget
   --
   --  Derives from Button_Widget to reuse click/toggle callbacks and keyboard
   --  activation semantics, but renders as a track + knob switch.
   ---------------------------------------------------------------------------

   type Switch_Widget is new Adi.Widget.Button.Button_Widget with private;
   type Switch_Widget_Access is access all Switch_Widget'Class;

   function Create (Checked : Boolean := False) return Switch_Widget_Access;

   procedure Set_Checked (W : in out Switch_Widget; Value : Boolean);
   function  Is_Checked (W : Switch_Widget) return Boolean;

   overriding procedure Build_Items (W : in out Switch_Widget);
   overriding procedure Layout (W : in out Switch_Widget);
   overriding function Measure_Content (W : Switch_Widget) return Size_2D;

private

   type Switch_Widget is new Adi.Widget.Button.Button_Widget with null record;

end Adi.Widget.Button.Switch;
