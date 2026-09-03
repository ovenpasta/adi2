pragma Ada_2022;

with Ada.Text_IO;       use Ada.Text_IO;
with Test_Support;      use Test_Support;

with Adi.Core;          use Adi.Core;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Label;  use type Adi.Widget.Label.Label_Handle;

--  What a tick costs a tree, and what it still has to do for one.
procedure Idle_Tick_Test is

   Fanout : constant := 8;
   Depth  : constant := 3;
   --  Root plus 8 + 64 + 512 below it.
   Tree_Size : constant := 1 + 8 + 64 + 512;

   Tick : constant Duration := 0.016;

   ------------------------------------------------------------------
   --  A panel with room to scroll
   ------------------------------------------------------------------

   Panel_W    : constant Pixel_Type := 200.0;
   Panel_H    : constant Pixel_Type := 200.0;
   Content_H  : constant Pixel_Type := 4_000.0;
   Max_Offset : constant Pixel_Type := Content_H - Panel_H;

   Knob_Idle_Bg    : constant Color_Value := RGB (120, 120, 120);
   Knob_Pressed_Bg : constant Color_Value := RGB (240, 30, 30);

   Scrolling_Panel : constant Widget_Style :=
     Style_Of .Display (Flex) .Flex_Direction (Adi.CSS_Styles.Column)
              .Overflow_Y (Overflow_Scroll) .Build;
   Knob : constant Widget_Style :=
     Style_Of .Width (Size (Px (12.0))) .Background (Knob_Idle_Bg)
              .On (When_Part_State (State_Pressed))
              .Background (Knob_Pressed_Bg) .Build;

   --  The knob being held is a state of the knob part, so what says it
   --  is held is the style that state selects.
   function Knob_Held (H : Widget_Handle) return Boolean is
     (Get_Resolved_Part_Style (H, Knob_Part).Background_Color
        = Knob_Pressed_Bg);

   function Open_Panel (Content_Height : Pixel_Type := Content_H)
      return Widget_Handle
   is
      Panel   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Content : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Sized   : constant Widget_Style :=
        Style_Of .Height (Size (Px (Float (Content_Height))))
                 .Min_Height (Size (Px (Float (Content_Height)))) .Build;
   begin
      Set_Part_Style (Panel, Main_Part, Scrolling_Panel);
      Set_Part_Style (Panel, Knob_Part, Knob);
      Set_Part_Style (Content, Main_Part, Sized);
      Add_Child (Panel, Content);
      Set_Geometry (Panel, (0.0, 0.0, Panel_W, Panel_H));
      Layout_Tree (Panel);
      return Panel;
   end Open_Panel;

   --  One wheel notch down, which is over the launch threshold.
   procedure Flick (H : Widget_Handle) is
      R : constant Widget_Ref := Borrow (H);
   begin
      Handle_Scroll_Mouse_Wheel (R.Ptr.all, 0.0, -1.0);
   end Flick;

   ------------------------------------------------------------------
   procedure Test_Quiet_Tree_Costs_Nothing is
      Root     : Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Count    : Natural;
      Resolves : Natural;

      procedure Populate (Parent : Widget_Handle; Level : Natural) is
      begin
         if Level = 0 then
            return;
         end if;
         for I in 1 .. Fanout loop
            declare
               Child : constant Widget_Handle :=
                 (if Level = 1
                  then +Adi.Widget.Label.Create_Handle ("leaf")
                  else +Adi.Widget.Box.Create_Handle);
            begin
               Add_Child (Parent, Child);
               Populate (Child, Level - 1);
            end;
         end loop;
      end Populate;

      function Count_Tree (H : Widget_Handle) return Natural is
         Total : Natural := 1;
      begin
         for I in 1 .. Child_Count (H) loop
            Total := Total + Count_Tree (Get_Child_Handle (H, I));
         end loop;
         return Total;
      end Count_Tree;
   begin
      Section ("A tick over a quiet tree");
      Populate (Root, Depth);
      Count := Count_Tree (Root);
      Assert (Count = Tree_Size,
              "the tree holds" & Natural'Image (Tree_Size) & " widgets, holds"
              & Natural'Image (Count));

      --  One tick first, so what a tick costs is read on its own rather
      --  than together with what a first look at a widget costs.
      Tick_Animations (Root, Tick);
      Reset_Perf_Counters;
      Tick_Animations (Root, Tick);
      Resolves := Get_Perf_Style_Resolves;

      Put_Line ("   " & Natural'Image (Count) & " widgets,"
                & Natural'Image (Resolves) & " style resolves per tick");
      Assert (Resolves = 0,
              "a tick over a tree with nothing to animate resolves no"
              & " styles, resolved" & Natural'Image (Resolves));
      Destroy (Root);
   end Test_Quiet_Tree_Costs_Nothing;

   ------------------------------------------------------------------
   procedure Test_Flick_Still_Carries is
      Panel : Widget_Handle := Open_Panel;
      Before, After : Pixel_Type;
   begin
      Section ("A tick over a panel that is moving");
      Assert (Get_Scroll_Max_Offset_Y (Panel) = Max_Offset,
              "the panel scrolls" & Pixel_Type'Image (Max_Offset) & " px, it"
              & " scrolls" & Pixel_Type'Image (Get_Scroll_Max_Offset_Y (Panel)));
      Assert (not Knob_Held (Panel), "an untouched knob paints idle");

      Flick (Panel);
      Before := Get_Scroll_Offset_Y (Panel);
      Tick_Animations (Panel, Tick);
      After := Get_Scroll_Offset_Y (Panel);

      Assert (After > Before,
              "inertia carries the offset on, moved"
              & Pixel_Type'Image (After - Before));
      Assert (Knob_Held (Panel), "a fast scroll holds the knob");
      Destroy (Panel);
   end Test_Flick_Still_Carries;

   ------------------------------------------------------------------
   procedure Test_Coming_To_Rest_Releases is
      Panel    : Widget_Handle := Open_Panel;
      Resting  : Pixel_Type;
      Resolves : Natural;
   begin
      Section ("A tick that brings a panel to rest");
      Flick (Panel);
      Tick_Animations (Panel, Tick);
      Assert (Knob_Held (Panel), "the knob is held while it moves");

      --  Enough ticks for friction to take it under the threshold.
      for I in 1 .. 200 loop
         Tick_Animations (Panel, Tick);
      end loop;
      Resting := Get_Scroll_Offset_Y (Panel);

      Assert (not Knob_Held (Panel), "the knob releases once it stops");

      Reset_Perf_Counters;
      Tick_Animations (Panel, Tick);
      Resolves := Get_Perf_Style_Resolves;
      Assert (Resolves = 0,
              "the tick after it rests costs nothing, cost"
              & Natural'Image (Resolves));
      Assert (Get_Scroll_Offset_Y (Panel) = Resting,
              "and leaves the offset where friction left it");
      Destroy (Panel);
   end Test_Coming_To_Rest_Releases;

   ------------------------------------------------------------------
   --  A knob let go of stays pressed until a tick releases it, which is
   --  the case a quiet path has to keep letting through: nothing is
   --  dragging and nothing is moving, and there is still work to do.
   procedure Test_Released_Knob_Is_Let_Go is
      Panel   : Widget_Handle := Open_Panel;
      Bar_X   : constant Pixel_Type := Panel_W - 6.0;
      Grab_Y  : constant Pixel_Type := 4.0;
      Grabbed : Boolean;
      Was_Inertial : constant Boolean := Get_Scroll_Inertia_Enabled;
   begin
      Section ("A knob let go of");
      --  Inertia off, so letting go leaves nothing moving.
      Set_Scroll_Inertia_Enabled (False);

      Assert (Get_Part_At (Panel, Bar_X, Grab_Y) = Knob_Part,
              "the knob is where the test aims for it, it is "
              & Part_Kind'Image (Get_Part_At (Panel, Bar_X, Grab_Y)));

      Grabbed := Handle_Scroll_Mouse_Down (Panel, Bar_X, Grab_Y, Left_Button);
      Assert (Grabbed, "the knob takes the press");
      Handle_Scroll_Mouse_Move (Panel, Bar_X, Grab_Y + 40.0);
      Tick_Animations (Panel, Tick);
      Assert (Knob_Held (Panel), "a dragged knob is held");

      Handle_Scroll_Mouse_Up (Panel, Left_Button);
      Assert (Knob_Held (Panel),
              "letting go of the button leaves the knob held");

      Tick_Animations (Panel, Tick);
      Assert (not Knob_Held (Panel), "the next tick lets the knob go");

      Set_Scroll_Inertia_Enabled (Was_Inertial);
      Destroy (Panel);
   end Test_Released_Knob_Is_Let_Go;

   ------------------------------------------------------------------
   --  A drag whose last step is a fraction of a pixel ends carrying a
   --  speed slower than the one a tick spends. That speed has to come
   --  to rest, or the panel pays for a tick for the rest of the run.
   procedure Test_A_Slow_Drag_Comes_To_Rest is
      --  Just past the viewport, so the knob nearly fills the track.
      Panel   : Widget_Handle := Open_Panel (Panel_H + 20.0);
      Bar_X   : constant Pixel_Type := Panel_W - 6.0;
      Grabbed : Boolean;
      Resolves : Natural;
   begin
      Section ("A slow drag");
      Assert (Get_Part_At (Panel, Bar_X, 4.0) = Knob_Part,
              "the knob is where the test aims for it, it is "
              & Part_Kind'Image (Get_Part_At (Panel, Bar_X, 4.0)));

      Grabbed := Handle_Scroll_Mouse_Down (Panel, Bar_X, 4.0, Left_Button);
      Assert (Grabbed, "the knob takes the press");
      --  A tenth of a pixel: window coordinates are scaled by the
      --  display's DIP factor, so a pointer step arrives fractional.
      Handle_Scroll_Mouse_Move (Panel, Bar_X, 4.1);
      Handle_Scroll_Mouse_Up (Panel, Left_Button);

      --  One tick to let the knob go, then a tick that should find
      --  nothing left to do.
      Tick_Animations (Panel, Tick);
      Assert (not Knob_Held (Panel), "the knob is let go");

      Reset_Perf_Counters;
      Tick_Animations (Panel, Tick);
      Resolves := Get_Perf_Style_Resolves;
      Assert (Resolves = 0,
              "and the panel rests, costing" & Natural'Image (Resolves));
      Destroy (Panel);
   end Test_A_Slow_Drag_Comes_To_Rest;

begin
   Start_Suite ("Idle tick");
   Test_Quiet_Tree_Costs_Nothing;
   Test_Flick_Still_Carries;
   Test_Coming_To_Rest_Releases;
   Test_Released_Knob_Is_Let_Go;
   Test_A_Slow_Drag_Comes_To_Rest;
   Finish;
end Idle_Tick_Test;
