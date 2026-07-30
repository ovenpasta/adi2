pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Text_IO; use Ada.Text_IO;

with Adi.Core;    use Adi.Core;
with Adi.Widget;  use Adi.Widget;
with Test_Support;

procedure Scroll_Primitives_Test is

   Virtual_Height : constant Pixel_Type := 1_000_000.0;

   type Offset_Pair is record
      Old_Offset : Pixel_Type;
      New_Offset : Pixel_Type;
   end record;
   package Pair_Vectors is new Ada.Containers.Vectors (Positive, Offset_Pair);
   Recorded : Pair_Vectors.Vector;

   --  Subclass overriding Get_Scroll_Content_Height. No children; the
   --  inherited Update_Shared_Scroll_Layout would set Scroll_Content_H to 0,
   --  but Get_Scroll_Content_Height now dispatches and returns the virtual
   --  total instead.
   type Virtual_Widget is new Adi.Widget.Widget with null record;
   overriding procedure Build_Items (W : in out Virtual_Widget) is null;
   overriding procedure Layout (W : in out Virtual_Widget) is null;
   overriding function Get_Scroll_Content_Height
     (W : Virtual_Widget) return Pixel_Type;

   --  Subclass overriding both Get_Scroll_Content_Height (so Set_Scroll_Offset_Y
   --  has room to apply non-zero offsets without being clamped) and
   --  On_Scroll_Changed (records every (Old, New) pair).
   type Tracking_Widget is new Adi.Widget.Widget with null record;
   overriding procedure Build_Items (W : in out Tracking_Widget) is null;
   overriding procedure Layout (W : in out Tracking_Widget) is null;
   overriding function Get_Scroll_Content_Height
     (W : Tracking_Widget) return Pixel_Type;
   overriding procedure On_Scroll_Changed
     (W          : in out Tracking_Widget;
      Old_Offset : Pixel_Type;
      New_Offset : Pixel_Type);

   --  Bodies -------------------------------------------------------------

   overriding function Get_Scroll_Content_Height
     (W : Virtual_Widget) return Pixel_Type
   is
      pragma Unreferenced (W);
   begin
      return Virtual_Height;
   end Get_Scroll_Content_Height;

   overriding function Get_Scroll_Content_Height
     (W : Tracking_Widget) return Pixel_Type
   is
      pragma Unreferenced (W);
   begin
      return Virtual_Height;
   end Get_Scroll_Content_Height;

   overriding procedure On_Scroll_Changed
     (W          : in out Tracking_Widget;
      Old_Offset : Pixel_Type;
      New_Offset : Pixel_Type)
   is
      pragma Unreferenced (W);
   begin
      Recorded.Append (Offset_Pair'(Old_Offset, New_Offset));
   end On_Scroll_Changed;

   --  Tests --------------------------------------------------------------

   procedure Test_Virtual_Content_Height is
      W : aliased Virtual_Widget;
   begin
      Test_Support.Section ("Virtual content height");
      Test_Support.Assert (Get_Scroll_Content_Height (W) = Virtual_Height,
              "primitive dispatches to subclass override");
      Test_Support.Assert (Get_Scroll_Max_Offset_Y (W) = Virtual_Height,
              "max offset reflects virtual height "
              & "(viewport height defaults to 0)");
   end Test_Virtual_Content_Height;

   procedure Test_On_Scroll_Changed_Fires is
      W : aliased Tracking_Widget;
   begin
      Test_Support.Section ("On_Scroll_Changed fires once per real change");
      Recorded.Clear;

      Set_Scroll_Offset_Y (W, 10.0);
      Test_Support.Assert (Natural (Recorded.Length) = 1
              and then Recorded (1).Old_Offset = 0.0
              and then Recorded (1).New_Offset = 10.0,
              "first write fires (0 -> 10)");

      Set_Scroll_Offset_Y (W, 10.0);  --  same value, no-op
      Test_Support.Assert (Natural (Recorded.Length) = 1,
              "no-op write does not fire");

      Scroll_By_Y (W, 5.0);
      Test_Support.Assert (Natural (Recorded.Length) = 2
              and then Recorded (2).Old_Offset = 10.0
              and then Recorded (2).New_Offset = 15.0,
              "Scroll_By_Y funnels through Set_Scroll_Offset_Y (10 -> 15)");

      Set_Scroll_Offset_Y (W, 0.0);
      Test_Support.Assert (Natural (Recorded.Length) = 3
              and then Recorded (3).Old_Offset = 15.0
              and then Recorded (3).New_Offset = 0.0,
              "write back to 0 fires (15 -> 0)");
   end Test_On_Scroll_Changed_Fires;

   procedure Test_Offset_Clamps_To_Max is
      W : aliased Tracking_Widget;
   begin
      Test_Support.Section ("Scroll offset clamps to Max_Offset");
      Recorded.Clear;
      Set_Scroll_Offset_Y (W, Virtual_Height * 2.0);
      Test_Support.Assert (Get_Scroll_Offset_Y (W) = Virtual_Height,
              "offset clamps to max (= virtual height with viewport 0)");
      Test_Support.Assert (Natural (Recorded.Length) = 1
              and then Recorded (1).New_Offset = Virtual_Height,
              "On_Scroll_Changed sees the post-clamp value, not the raw write");
   end Test_Offset_Clamps_To_Max;

   --  Scroll_Changed identifies the widget that scrolled. Nothing puts a
   --  widget in the handle store on its own — these test subclasses are
   --  never registered, yet they scroll through the public API — so the
   --  event carries a pointer. Reporting a handle instead raised in
   --  strict mode, and suppressing the event for such widgets left
   --  anything anchored to them, a combo dropdown in particular,
   --  stranded where it was.
   Observed : access Adi.Widget.Widget'Class := null;
   Observed_Count : Natural := 0;

   procedure Note_Scroll
     (Scrolled : not null access Adi.Widget.Widget'Class) is
   begin
      Observed := Scrolled;
      Observed_Count := Observed_Count + 1;
   end Note_Scroll;

   procedure Test_Scroll_Changed_Reports_The_Widget is
      W  : aliased Tracking_Widget;
      Id : constant Scroll_Signals.Connection_Id :=
        Connect_Scroll_Changed (Note_Scroll'Unrestricted_Access);
      Expect : constant access Adi.Widget.Widget'Class :=
        Adi.Widget.Widget'Class (W)'Unchecked_Access;
   begin
      Test_Support.Section ("Scroll_Changed reports the widget that scrolled");
      Observed := null;
      Observed_Count := 0;

      Set_Scroll_Offset_Y (W, 25.0);
      Test_Support.Assert (Observed_Count = 1,
              "an unregistered widget still notifies observers");
      Test_Support.Assert (Observed = Expect,
              "the observer is told which widget scrolled");

      Set_Scroll_Offset_Y (W, 25.0);  --  no-op
      Test_Support.Assert (Observed_Count = 1,
              "a write that changes nothing does not notify");

      Disconnect_Scroll_Changed (Id);
      Set_Scroll_Offset_Y (W, 40.0);
      Test_Support.Assert (Observed_Count = 1,
              "a disconnected observer stops hearing about scrolling");

      --  The pointer is borrowed for the call only, and W is about to go
      --  out of scope: drop it rather than leave a dangling one behind.
      Observed := null;
   end Test_Scroll_Changed_Reports_The_Widget;

begin
   Test_Support.Start_Suite ("Scroll Primitives Test");
   New_Line;
   Test_Virtual_Content_Height;
   New_Line;
   Test_On_Scroll_Changed_Fires;
   New_Line;
   Test_Offset_Clamps_To_Max;
   New_Line;
   Test_Scroll_Changed_Reports_The_Widget;
   New_Line;
   Test_Support.Finish;
end Scroll_Primitives_Test;
