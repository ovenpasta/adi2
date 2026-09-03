pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Text_IO; use Ada.Text_IO;

with Adi.Core;          use Adi.Core;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
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
   --  event carries a pointer. Reporting a handle instead means calling
   --  Get_Handle, which raises on an unregistered widget, and suppressing
   --  the event for such widgets left anything anchored to them, a combo
   --  dropdown in particular, stranded where it was.
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

   -----------------------------------------------------------------
   --  What a widget scrolls is what its stylesheet says now. A sheet
   --  that stops scrolling it has to stop it scrolling.
   -----------------------------------------------------------------
   procedure Test_Overflow_Governs_Scrolling is
      Panel_W   : constant Pixel_Type := 200.0;
      Panel_H   : constant Pixel_Type := 200.0;
      Content_H : constant Pixel_Type := 4_000.0;

      Scrolls : constant Widget_Style :=
        Style_Of .Display (Flex) .Flex_Direction (Adi.CSS_Styles.Column)
                 .Overflow_Y (Overflow_Scroll) .Build;
      Clips : constant Widget_Style :=
        Style_Of .Display (Flex) .Flex_Direction (Adi.CSS_Styles.Column)
                 .Overflow_Y (Overflow_Hidden) .Build;
      Tall : constant Widget_Style :=
        Style_Of .Height (Size (Px (Float (Content_H))))
                 .Min_Height (Size (Px (Float (Content_H)))) .Build;

      Panel   : Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Content : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
   begin
      Test_Support.Section ("Overflow governs scrolling");
      Set_Part_Style (Content, Main_Part, Tall);
      Add_Child (Panel, Content);
      Set_Geometry (Panel, (0.0, 0.0, Panel_W, Panel_H));

      Set_Part_Style (Panel, Main_Part, Scrolls);
      Layout_Tree (Panel);
      Test_Support.Assert (Is_Scroll_Enabled (Panel),
              "overflow-y: scroll scrolls the panel");
      Test_Support.Assert (not Has_Flag (Panel, Scrollable),
              "and leaves the flag to whoever set it");
      Set_Scroll_Offset_Y (Panel, 500.0);
      Test_Support.Assert (Get_Scroll_Offset_Y (Panel) = 500.0,
              "so the panel takes an offset, it is"
              & Pixel_Type'Image (Get_Scroll_Offset_Y (Panel)));

      Set_Part_Style (Panel, Main_Part, Clips);
      Layout_Tree (Panel);
      Test_Support.Assert (not Is_Scroll_Enabled (Panel),
              "overflow-y: hidden stops the panel scrolling");
      Test_Support.Assert
        (Get_Part_At (Panel, Panel_W - 6.0, 4.0) = Main_Part,
         "and takes its scrollbar away, the right edge is "
         & Part_Kind'Image (Get_Part_At (Panel, Panel_W - 6.0, 4.0)));
      declare
         Held : constant Pixel_Type := Get_Scroll_Offset_Y (Panel);
         R    : constant Widget_Ref := Borrow (Panel);
      begin
         Handle_Scroll_Mouse_Wheel (R.Ptr.all, 0.0, -3.0);
         Test_Support.Assert (Get_Scroll_Offset_Y (Panel) = Held,
                 "and a wheel over it moves nothing, it moved"
                 & Pixel_Type'Image (Get_Scroll_Offset_Y (Panel) - Held));
      end;

      --  Back again, so what the sheet says is read every time rather
      --  than once.
      Set_Part_Style (Panel, Main_Part, Scrolls);
      Layout_Tree (Panel);
      Test_Support.Assert (Is_Scroll_Enabled (Panel),
              "and scrolling comes back when the sheet asks for it");
      Destroy (Panel);
   end Test_Overflow_Governs_Scrolling;

   -----------------------------------------------------------------
   --  A scroll container reports its floor and shows its content a
   --  piece at a time; one that stops scrolling sizes to the whole of
   --  it again.
   -----------------------------------------------------------------
   procedure Test_Sizing_Follows_Overflow is
      Content_H : constant Pixel_Type := 4_000.0;

      Scrolls : constant Widget_Style :=
        Style_Of .Display (Flex) .Flex_Direction (Adi.CSS_Styles.Column)
                 .Overflow_Y (Overflow_Scroll) .Build;
      Shows : constant Widget_Style :=
        Style_Of .Display (Flex) .Flex_Direction (Adi.CSS_Styles.Column)
                 .Overflow_Y (Overflow_Visible) .Build;
      Tall : constant Widget_Style :=
        Style_Of .Height (Size (Px (Float (Content_H))))
                 .Min_Height (Size (Px (Float (Content_H)))) .Build;

      Panel   : Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Content : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Scrolling_Pref, Showing_Pref : Pixel_Type;
   begin
      Test_Support.Section ("Sizing follows overflow");
      Set_Part_Style (Content, Main_Part, Tall);
      Add_Child (Panel, Content);
      Set_Geometry (Panel, (0.0, 0.0, 200.0, 200.0));

      Set_Part_Style (Panel, Main_Part, Scrolls);
      Layout_Tree (Panel);
      Scrolling_Pref := Get_Preferred_Size (Panel).Height;
      Test_Support.Assert (Scrolling_Pref < Content_H,
              "a scrolling panel asks for its floor, it asks for"
              & Pixel_Type'Image (Scrolling_Pref));

      Set_Part_Style (Panel, Main_Part, Shows);
      Layout_Tree (Panel);
      Showing_Pref := Get_Preferred_Size (Panel).Height;
      Test_Support.Assert (Showing_Pref >= Content_H,
              "and asks for the whole of its content once it shows it,"
              & " it asks for" & Pixel_Type'Image (Showing_Pref));
      Destroy (Panel);
   end Test_Sizing_Follows_Overflow;

   -----------------------------------------------------------------
   --  The flag is the other way in, and layout leaves it alone.
   -----------------------------------------------------------------
   procedure Test_Flag_Scrolls_Without_A_Sheet is
      Panel   : Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Content : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Tall : constant Widget_Style :=
        Style_Of .Height (Size (Px (4_000.0)))
                 .Min_Height (Size (Px (4_000.0))) .Build;
   begin
      Test_Support.Section ("The Scrollable flag");
      Set_Part_Style (Content, Main_Part, Tall);
      Add_Child (Panel, Content);
      Set_Geometry (Panel, (0.0, 0.0, 200.0, 200.0));
      Layout_Tree (Panel);
      Test_Support.Assert (not Is_Scroll_Enabled (Panel),
              "a panel with neither flag nor overflow does not scroll");

      Set_Flag (Panel, Scrollable, True);
      Layout_Tree (Panel);
      Test_Support.Assert (Is_Scroll_Enabled (Panel),
              "the flag scrolls it with no stylesheet involved");

      Set_Flag (Panel, Scrollable, False);
      Layout_Tree (Panel);
      Test_Support.Assert (not Is_Scroll_Enabled (Panel),
              "and taking the flag back stops it");
      Destroy (Panel);
   end Test_Flag_Scrolls_Without_A_Sheet;

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
   Test_Overflow_Governs_Scrolling;
   New_Line;
   Test_Sizing_Follows_Overflow;
   New_Line;
   Test_Flag_Scrolls_Without_A_Sheet;
   New_Line;
   Test_Support.Finish;
end Scroll_Primitives_Test;
