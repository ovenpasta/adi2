pragma Ada_2022;

package body Test_Extension_Widgets is

   function Create_Gauge return Gauge_Handle
   is (Ref => Gauges.New_Widget);

   function Is_Valid (H : Gauge_Handle) return Boolean
   is (Gauges.Is_Valid (H.Ref));

   function "+" (H : Gauge_Handle) return Widget_Handle
   is (Gauges."+" (H.Ref));

   procedure Set_Reading (H : Gauge_Handle; Value : Float) is
      R : constant Gauges.Ref := Gauges.Borrow (H.Ref);
   begin
      R.Reading := Value;
   end Set_Reading;

   function Get_Reading (H : Gauge_Handle) return Float is
      R : constant Gauges.Ref := Gauges.Borrow (H.Ref);
   begin
      return R.Reading;
   end Get_Reading;

end Test_Extension_Widgets;
