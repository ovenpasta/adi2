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

   overriding procedure Build_Items (W : in out Reentrant) is
   begin
      Adi.Widget.Button.Build_Items (Adi.Widget.Button.Button_Widget (W));
      if W.Click_From_Build then
         W.Click_From_Build := False;
         Adi.Widget.Button.On_Click
           (Adi.Widget.Button.Button_Widget (W));
      end if;
   end Build_Items;

   overriding function Get_Min_Size (W : Reentrant) return Adi.Core.Size_2D is
      --  Get_Min_Size is a function and firing a signal marks the widget
      --  dirty, so the emit needs a variable view of it.
      Self : constant access Reentrant := W'Unrestricted_Access;
   begin
      if Self.Click_From_Min_Size then
         Self.Click_From_Min_Size := False;
         Adi.Widget.Button.On_Click
           (Adi.Widget.Button.Button_Widget (Self.all));
      end if;
      return Adi.Widget.Button.Get_Min_Size
        (Adi.Widget.Button.Button_Widget (W));
   end Get_Min_Size;

   overriding function Measure_Content
     (W : Reentrant) return Adi.Core.Size_2D
   is
      Self : constant access Reentrant := W'Unrestricted_Access;
   begin
      if Self.Click_From_Measure then
         Self.Click_From_Measure := False;
         Adi.Widget.Button.On_Click
           (Adi.Widget.Button.Button_Widget (Self.all));
      end if;
      return Adi.Widget.Button.Measure_Content
        (Adi.Widget.Button.Button_Widget (W));
   end Measure_Content;

   procedure Click_On_Next_Build (H : Reentrants.Handle) is
      R : constant Reentrants.Ref := Reentrants.Borrow (H);
   begin
      R.Click_From_Build := True;
   end Click_On_Next_Build;

   procedure Click_On_Next_Min_Size (H : Reentrants.Handle) is
      R : constant Reentrants.Ref := Reentrants.Borrow (H);
   begin
      R.Click_From_Min_Size := True;
   end Click_On_Next_Min_Size;

   procedure Click_On_Next_Measure (H : Reentrants.Handle) is
      R : constant Reentrants.Ref := Reentrants.Borrow (H);
   begin
      R.Click_From_Measure := True;
   end Click_On_Next_Measure;

end Test_Extension_Widgets;
