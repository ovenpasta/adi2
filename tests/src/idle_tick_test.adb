pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Text_IO;       use Ada.Text_IO;
with Test_Support;      use Test_Support;
with Test_Extension_Widgets;

with Adi.Animated_Image;
with Adi.Core;          use Adi.Core;
with Adi.Resolved_Styles;
with Adi.RLottie;
with Adi.SDL;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;
with Adi.Widget.Animated_Image;
with Adi.Widget.Animated_Widget;
with Adi.Widget.Box;    use type Adi.Widget.Box.Box_Handle;
with Adi.Widget.Label;  use type Adi.Widget.Label.Label_Handle;
with Adi.Widget.List_Box;
with Adi.Widget.RLottie;
with Adi.Widget.Text_Editor;

--  What a tick costs a tree, and what it still has to do for one.
procedure Idle_Tick_Test is

   Fanout : constant := 8;
   Depth  : constant := 3;
   --  Root plus 8 + 64 + 512 below it.
   Tree_Size : constant := 1 + 8 + 64 + 512;

   Tick : constant Duration := 0.016;

   --  What a tick may reach in a tree where nothing wants one: the root
   --  it is handed, and no further.
   Quiet_Visits : constant := 1;

   --  Boxes above the widget a test buries, so what a tick reaches is
   --  countable: one visit when it stops at the top, and one per link
   --  plus the widget when it reaches the bottom.
   Chain_Links  : constant := 3;
   Chain_Visits : constant := Chain_Links + 1;

   --  Frames a transition of Fade_Seconds needs, with room to spare.
   Fade_Seconds : constant := 0.5;
   Fade_Frames  : constant := 100;

   Gif    : constant String := "demos/assets/animhorse.gif";
   Lottie : constant String := "tests/assets/tiny_anim.json";

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

   --  A knob the sheet says nothing about for the state it is put in,
   --  so putting it in one marks nothing dirty.
   Plain_Knob : constant Widget_Style :=
     Style_Of .Width (Size (Px (12.0))) .Background (Knob_Idle_Bg) .Build;

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

   package Label_List is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget);

   --  One wheel notch down, which is over the launch threshold.
   procedure Flick (H : Widget_Handle) is
      R : constant Widget_Ref := Borrow (H);
   begin
      Handle_Scroll_Mouse_Wheel (R.Ptr.all, 0.0, -1.0);
   end Flick;

   ------------------------------------------------------------------
   --  A widget at the bottom of a chain of boxes that want nothing, so
   --  the only reason a tick has to go past the top is the widget.
   ------------------------------------------------------------------

   function Bury (Leaf : Widget_Handle) return Widget_Handle is
      Root : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Node : Widget_Handle := Root;
   begin
      for I in 2 .. Chain_Links loop
         declare
            Link : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
         begin
            Add_Child (Node, Link);
            Node := Link;
         end;
      end loop;
      Add_Child (Node, Leaf);
      return Root;
   end Bury;

   --  The bottom of the leftmost branch.
   function Leaf_Of (Root : Widget_Handle) return Widget_Handle is
      Node : Widget_Handle := Root;
   begin
      while Child_Count (Node) > 0 loop
         Node := Get_Child_Handle (Node, 1);
      end loop;
      return Node;
   end Leaf_Of;

   --  The tick after a tick, so what is counted is what the tree wants
   --  next rather than what the tick before it left behind.
   function Steady_Visits (Root : Widget_Handle) return Natural is
   begin
      Tick_Animations (Root, Tick);
      Reset_Perf_Counters;
      Tick_Animations (Root, Tick);
      return Get_Perf_Tick_Visits;
   end Steady_Visits;

   --  What the next tick alone reaches, which is what a change just
   --  made has left behind.
   function Next_Visits (Root : Widget_Handle) return Natural is
   begin
      Reset_Perf_Counters;
      Tick_Animations (Root, Tick);
      return Get_Perf_Tick_Visits;
   end Next_Visits;

   procedure Assert_Quiet (Root : Widget_Handle; What : String) is
      Visits : constant Natural := Steady_Visits (Root);
   begin
      Assert (Visits = Quiet_Visits,
              "a tick over " & What & " stops at the widget it is handed,"
              & " reached" & Natural'Image (Visits));
   end Assert_Quiet;

   procedure Assert_Reaches_Buried (Root : Widget_Handle; What : String) is
      Visits : constant Natural := Steady_Visits (Root);
   begin
      Assert (Visits >= Chain_Visits,
              "a tick reaches " & What & " under three quiet boxes,"
              & " reached" & Natural'Image (Visits) & " of"
              & Natural'Image (Chain_Visits));
   end Assert_Reaches_Buried;

   ------------------------------------------------------------------
   procedure Test_Quiet_Tree_Costs_Nothing is
      Root     : Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Count    : Natural;
      Resolves : Natural;
      Visits   : Natural;

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
      Visits   := Get_Perf_Tick_Visits;

      Put_Line ("   " & Natural'Image (Count) & " widgets,"
                & Natural'Image (Resolves) & " style resolves,"
                & Natural'Image (Visits) & " visits per tick");
      Assert (Resolves = 0,
              "a tick over a tree with nothing to animate resolves no"
              & " styles, resolved" & Natural'Image (Resolves));
      Assert (Visits <= Quiet_Visits,
              "a tick over a tree with nothing to animate reaches at most"
              & Natural'Image (Quiet_Visits) & " widgets, reached"
              & Natural'Image (Visits));

      --  A pointer crossing a part of a widget the sheet says nothing
      --  about, which over a largely unstyled tree is most crossings.
      Set_Part_State (Leaf_Of (Root), Main_Part, State_Hovered, True);
      Visits := Next_Visits (Root);
      Put_Line ("   " & Natural'Image (Visits)
                & " visits on the tick after a pointer crossing");
      Assert (Visits <= Quiet_Visits,
              "a crossing the sheet paints nothing for leaves the tick"
              & " where it was, it reached" & Natural'Image (Visits));
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


   ------------------------------------------------------------------
   --  A transition is the one thing a widget starts with nothing else
   --  about it moving, and so the one a tick that stops short freezes
   --  without anything else looking wrong.
   procedure Test_A_Buried_Transition_Runs is
      Calm   : constant Color_Value := RGB (0, 0, 0);
      Roused : constant Color_Value := RGB (200, 200, 200);
      Fading : constant Widget_Style :=
        Style_Of .Background (Calm)
                 .Transition ((Duration   => Fade_Seconds,
                               Easing     => Linear,
                               Properties => All_Properties))
                 .On (When_State (State_Hovered)) .Background (Roused)
                 .Build;

      Leaf   : constant Widget_Handle := +Adi.Widget.Box.Create_Handle;
      Root   : Widget_Handle := Bury (Leaf);
      Midway : Natural;

      --  The red channel of what the leaf paints now, which during a
      --  transition is the interpolation rather than either end.
      function Painted return Natural is
         Items   : constant Items_List.Vector :=
           Get_Items_For_Part (Leaf, Main_Part);
         R, G, B : Natural;
         A       : Float;
      begin
         Normalize_Color
           (Adi.Resolved_Styles.Value
              (Items.First_Element.Computed_Style).Background_Color,
            R, G, B, A);
         return R;
      end Painted;
   begin
      Section ("A transition under a quiet subtree");
      Set_Part_Style (Leaf, Main_Part, Fading);
      Set_Geometry (Root, (0.0, 0.0, 100.0, 100.0));
      Layout_Tree (Root);
      Update (Root);
      Assert_Quiet (Root, "a chain with nothing in flight");

      Set_Hovered (Leaf);
      Update (Root);
      Assert_Reaches_Buried (Root, "a transition");

      for I in 1 .. 10 loop
         Tick_Animations (Root, Tick);
      end loop;
      Midway := Painted;
      Assert (Midway > 0 and then Midway < 200,
              "and carries the colour between the two, standing at"
              & Natural'Image (Midway));

      for I in 1 .. Fade_Frames loop
         Tick_Animations (Root, Tick);
      end loop;
      Assert (Painted = 200,
              "the transition arrives, standing at" & Natural'Image (Painted));
      Assert_Quiet (Root, "a chain whose transition has arrived");
      Destroy (Root);
   end Test_A_Buried_Transition_Runs;

   ------------------------------------------------------------------
   procedure Test_A_Buried_Animated_Image_Ticks is
      use Adi.Animated_Image;
      package W_Image renames Adi.Widget.Animated_Image;

      Anim : Animation_Handle := Load_From_File (Gif);
      Img  : constant W_Image.Animated_Image_Handle := W_Image.Create_Handle;
      Leaf : constant Widget_Handle := W_Image."+" (Img);
      Root : Widget_Handle := Bury (Leaf);
   begin
      Section ("An animated image under a quiet subtree");
      Assert (Is_Valid (Anim), "the fixture loads");

      --  Quiet first, so setting the animation is what puts the widget
      --  back on the tick's path.
      Assert_Quiet (Root, "an animated image holding nothing");
      W_Image.Set_Animation (Img, Anim);
      --  Built, so the widget has shown the frame the animation is on
      --  and a tick that finds it unchanged has nothing to report.  What
      --  keeps it on the tick's path is what it asks for.
      Set_Geometry (Root, (0.0, 0.0, 100.0, 100.0));
      Layout_Tree (Root);
      Update (Root);
      Assert_Reaches_Buried (Root, "an animated image");

      W_Image.Set_Animation (Img, Null_Animation_Handle);
      Assert_Quiet (Root, "an animated image with nothing to sample");

      Destroy (Root);
      Destroy (Anim);
   end Test_A_Buried_Animated_Image_Ticks;

   ------------------------------------------------------------------
   procedure Test_A_Buried_RLottie_Ticks is
      use Adi.RLottie;
      package W_Lottie renames Adi.Widget.RLottie;

      Anim : Animation_Handle := Load_From_File (Lottie);
      Lot  : constant W_Lottie.RLottie_Handle := W_Lottie.Create_Handle;
      Leaf : constant Widget_Handle := W_Lottie."+" (Lot);
      Root : Widget_Handle := Bury (Leaf);
   begin
      Section ("An rlottie animation under a quiet subtree");
      Assert (Is_Valid (Anim), "the fixture loads");

      --  Quiet first, so setting the animation is what puts the widget
      --  back on the tick's path.
      Assert_Quiet (Root, "an rlottie widget holding nothing");
      W_Lottie.Set_Animation (Lot, Anim);
      --  Built, so the widget has shown the frame the animation is on
      --  and a tick that finds it unchanged has nothing to report.  What
      --  keeps it on the tick's path is what it asks for.
      Set_Geometry (Root, (0.0, 0.0, 100.0, 100.0));
      Layout_Tree (Root);
      Update (Root);
      Assert_Reaches_Buried (Root, "an rlottie widget");

      --  A stopped animation reports no change and hands out the frame
      --  the widget already shows, so nothing about it is dirty and the
      --  only thing keeping it reachable is what it asks for.  It is
      --  asked while it holds an animation, not while it plays one:
      --  starting again is the application's to do at any time.
      W_Lottie.Stop (Lot);
      Update (Root);
      Assert_Reaches_Buried (Root, "an rlottie widget that is stopped");

      W_Lottie.Set_Animation (Lot, Null_Animation_Handle);
      Assert_Quiet (Root, "an rlottie widget with nothing to sample");

      Destroy (Root);
      Destroy (Anim);
   end Test_A_Buried_RLottie_Ticks;

   ------------------------------------------------------------------
   procedure Test_A_Buried_Animated_Widget_Ticks is
      use Adi.Animated_Image;
      package W_Anim renames Adi.Widget.Animated_Widget;

      Anim : Animation_Handle := Load_From_File (Gif);
      Vw   : constant W_Anim.Animated_Widget_Handle := W_Anim.Create_Handle;
      Leaf : constant Widget_Handle := W_Anim."+" (Vw);
      Root : Widget_Handle := Bury (Leaf);
   begin
      Section ("An animated widget under a quiet subtree");
      Assert (Is_Valid (Anim), "the fixture loads");

      --  Quiet first, so setting the animation is what puts the widget
      --  back on the tick's path.
      Assert_Quiet (Root, "an animated widget holding nothing");
      W_Anim.Set_Animation (Vw, Anim);
      --  Built, so the widget has shown the frame the animation is on
      --  and a tick that finds it unchanged has nothing to report.  What
      --  keeps it on the tick's path is what it asks for.
      Set_Geometry (Root, (0.0, 0.0, 100.0, 100.0));
      Layout_Tree (Root);
      Update (Root);
      Assert_Reaches_Buried (Root, "an animated widget");

      W_Anim.Set_Animation (Vw, Null_Animation_Handle);
      Assert_Quiet (Root, "an animated widget with no backend");

      Destroy (Root);
      Destroy (Anim);
   end Test_A_Buried_Animated_Widget_Ticks;

   ------------------------------------------------------------------
   procedure Test_A_Buried_List_Box_Carries_Inertia is
      Rows    : constant := 20;
      Row_H   : constant Pixel_Type := 20.0;
      Sized   : constant Widget_Style :=
        Style_Of .Height (Size (Px (Float (Row_H)))) .Build;

      List : constant Label_List.List_Box_Handle := Label_List.Create_Handle;
      Leaf : constant Widget_Handle := Label_List."+" (List);
      Root : Widget_Handle;
      Before, After : Pixel_Type;
   begin
      Section ("A list box under a quiet subtree");
      for I in 1 .. Rows loop
         declare
            Row : constant Widget_Handle :=
              +Adi.Widget.Label.Create_Handle ("row" & Integer'Image (I));
         begin
            Set_Part_Style (Row, Main_Part, Sized);
            Label_List.Append_Row (List, Row);
         end;
      end loop;
      Set_Flag (Leaf, Scrollable, True);
      Set_Geometry (Leaf, (0.0, 0.0, 100.0, 50.0));
      Layout_Tree (Leaf);
      Assert (Get_Scroll_Max_Offset_Y (Leaf) > 0.0,
              "the list has room to scroll, it has"
              & Pixel_Type'Image (Get_Scroll_Max_Offset_Y (Leaf)));

      Root := Bury (Leaf);
      Assert_Quiet (Root, "a list box at rest");

      Flick (Leaf);
      Before := Get_Scroll_Offset_Y (Leaf);
      Assert_Reaches_Buried (Root, "a list box under inertia");
      After := Get_Scroll_Offset_Y (Leaf);
      Assert (After > Before,
              "and its inertia carries the offset on, moved"
              & Pixel_Type'Image (After - Before));
      Destroy (Root);
   end Test_A_Buried_List_Box_Carries_Inertia;

   ------------------------------------------------------------------
   --  A text editor overrides On_Tick to scroll and for nothing else --
   --  it has no blinking cursor -- so what its tick carries is inertia.
   procedure Test_A_Buried_Text_Editor_Carries_Inertia is
      package Editor renames Adi.Widget.Text_Editor;

      --  Far more text than one wheel notch spends, so the notch lands
      --  in the middle of the travel and leaves inertia to carry.
      function Many_Lines return String is
         Line : constant String := "a line of text" & ASCII.LF;
         Text : String (1 .. 200 * Line'Length);
      begin
         for I in 0 .. 199 loop
            Text (I * Line'Length + 1 .. (I + 1) * Line'Length) := Line;
         end loop;
         return Text;
      end Many_Lines;

      Ed   : constant Editor.Text_Editor_Handle :=
        Editor.Create_Handle (Many_Lines);
      Leaf : constant Widget_Handle := Editor."+" (Ed);
      Root : Widget_Handle;
      Before, After : Pixel_Type;
   begin
      Section ("A text editor under a quiet subtree");
      Set_Flag (Leaf, Scrollable, True);
      Set_Geometry (Leaf, (0.0, 0.0, 200.0, 40.0));
      Layout_Tree (Leaf);
      --  A text editor measures its text into scroll metrics while it
      --  builds its items, so laying it out alone leaves it flat.
      Update (Leaf);
      Assert (Get_Scroll_Max_Offset_Y (Leaf) > 0.0,
              "the text has room to scroll, it has"
              & Pixel_Type'Image (Get_Scroll_Max_Offset_Y (Leaf)));

      --  Building put the caret in view and the caret is at the end of
      --  the text, so the travel starts spent and a notch down would
      --  have nowhere to carry to.
      Set_Scroll_Offset_Y (Leaf, 0.0);

      Root := Bury (Leaf);
      Assert_Quiet (Root, "a text editor at rest");

      Flick (Leaf);
      Before := Get_Scroll_Offset_Y (Leaf);
      Assert_Reaches_Buried (Root, "a text editor under inertia");
      After := Get_Scroll_Offset_Y (Leaf);
      Assert (After > Before,
              "and its inertia carries the offset on, moved"
              & Pixel_Type'Image (After - Before));
      Destroy (Root);
   end Test_A_Buried_Text_Editor_Carries_Inertia;

   ------------------------------------------------------------------
   procedure Test_A_Destroyed_Widget_Stops_Being_Ticked is
      use Adi.Animated_Image;
      package W_Image renames Adi.Widget.Animated_Image;

      Anim : Animation_Handle := Load_From_File (Gif);
      Img  : constant W_Image.Animated_Image_Handle := W_Image.Create_Handle;
      Leaf : Widget_Handle := W_Image."+" (Img);
      Root : Widget_Handle := Bury (Leaf);
   begin
      Section ("A widget destroyed while it was asking for ticks");
      Assert (Is_Valid (Anim), "the fixture loads");
      W_Image.Set_Animation (Img, Anim);
      Assert_Reaches_Buried (Root, "an animated image");

      Destroy (Leaf);
      Assert (not Is_Valid (Leaf), "the handle is stale");
      Assert_Quiet (Root, "a chain the animated image has left");

      Destroy (Root);
      Destroy (Anim);
   end Test_A_Destroyed_Widget_Stops_Being_Ticked;

   ------------------------------------------------------------------
   --  What such a type wants of a tick is written outside the library,
   --  so nothing inside it can conclude the type wants none.
   procedure Test_An_Extension_Type_Still_Ticks is
      use Test_Extension_Widgets;

      Custom : constant Tickers.Handle := Tickers.New_Widget;
      Leaf   : constant Widget_Handle := Tickers."+" (Custom);
      Root   : Widget_Handle := Bury (Leaf);
      Rounds : constant := 20;
      Before : Natural;
   begin
      Section ("A widget type the library never saw");
      Assert_Reaches_Buried (Root, "a type registered through Extension");

      Before := Ticks (Custom);
      for I in 1 .. Rounds loop
         Tick_Animations (Root, Tick);
      end loop;
      Assert (Ticks (Custom) = Before + Rounds,
              "its On_Tick runs once per tick, over" & Natural'Image (Rounds)
              & " it ran" & Natural'Image (Ticks (Custom) - Before));
      Destroy (Root);
   end Test_An_Extension_Type_Still_Ticks;


   ------------------------------------------------------------------
   --  A scroll part put into State_Pressed is the one part state a tick
   --  has to undo, and a sheet with no rule for it marks nothing dirty
   --  on the way in.
   procedure Test_An_Unpainted_Knob_Press_Is_Undone is
      Panel   : constant Widget_Handle := Open_Panel;
      Root    : Widget_Handle;
      Reached : Natural;
   begin
      Section ("A knob press the sheet paints nothing for");
      Set_Part_Style (Panel, Knob_Part, Plain_Knob);
      Layout_Tree (Panel);
      Root := Bury (Panel);
      Assert_Quiet (Root, "a panel at rest under a plain knob");

      Set_Part_State (Panel, Knob_Part, State_Pressed, True);
      Assert (Get_Resolved_Part_Style (Panel, Knob_Part).Background_Color
                = Knob_Idle_Bg,
              "the sheet paints nothing different for the state, so"
              & " nothing about the panel is dirty");

      Reached := Next_Visits (Root);
      Assert (Reached >= Chain_Visits,
              "the next tick reaches the panel under three quiet boxes,"
              & " it reached" & Natural'Image (Reached));

      --  Only a tick puts the part down again, so a tree gone quiet is
      --  what says it did.
      Assert_Quiet (Root, "a panel whose knob the tick has put down");
      Destroy (Root);
   end Test_An_Unpainted_Knob_Press_Is_Undone;


   ------------------------------------------------------------------
   --  A tick that fails part-way unwinds through every frame above it,
   --  each of which lowered its own flag on the way in.  A fault is a
   --  thing to see again next frame, not a thing that takes the subtree
   --  off the tick for good.
   procedure Test_A_Failed_Tick_Is_Tried_Again is
      use Test_Extension_Widgets;

      Custom : constant Tickers.Handle := Tickers.New_Widget;
      Leaf   : constant Widget_Handle := Tickers."+" (Custom);
      Root   : Widget_Handle := Bury (Leaf);
      Threw  : Boolean := False;
      Before : Natural;
   begin
      Section ("A tick that raises part-way");
      Assert_Reaches_Buried (Root, "a type registered through Extension");
      Before := Ticks (Custom);

      Raise_On_Next_Tick (Custom);
      begin
         Tick_Animations (Root, Tick);
      exception
         when Program_Error =>
            Threw := True;
      end;
      Assert (Threw, "the tick carries the fault out");
      Assert (Ticks (Custom) = Before,
              "and the widget counted nothing for it");

      Assert (Next_Visits (Root) >= Chain_Visits,
              "the tick after it reaches the widget again, it reached"
              & Natural'Image (Next_Visits (Root)));
      Assert (Ticks (Custom) > Before,
              "and the widget counts again, having counted"
              & Natural'Image (Ticks (Custom) - Before));
      Destroy (Root);
   end Test_A_Failed_Tick_Is_Tried_Again;

begin
   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   Start_Suite ("Idle tick");

   if not Boolean (Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO)) then
      Assert (False, "SDL_Init(video) should succeed");
      Finish;
      return;
   end if;

   Test_Quiet_Tree_Costs_Nothing;
   Test_Flick_Still_Carries;
   Test_Coming_To_Rest_Releases;
   Test_Released_Knob_Is_Let_Go;
   Test_A_Slow_Drag_Comes_To_Rest;
   Test_An_Unpainted_Knob_Press_Is_Undone;
   Test_A_Buried_Transition_Runs;
   Test_A_Buried_Animated_Image_Ticks;
   Test_A_Buried_RLottie_Ticks;
   Test_A_Buried_Animated_Widget_Ticks;
   Test_A_Buried_List_Box_Carries_Inertia;
   Test_A_Buried_Text_Editor_Carries_Inertia;
   Test_A_Destroyed_Widget_Stops_Being_Ticked;
   Test_An_Extension_Type_Still_Ticks;
   Test_A_Failed_Tick_Is_Tried_Again;
   Finish;
end Idle_Tick_Test;
