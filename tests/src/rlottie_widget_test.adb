pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Text_IO;                        use Ada.Text_IO;
with Adi.Core;                           use Adi.Core;
with Adi.RLottie;                        use Adi.RLottie;
with Adi.RLottie.Testing;                use Adi.RLottie.Testing;
with Adi.SDL;
with Adi.Widget;                         use Adi.Widget;
with Adi.Widget.Animated_Widget;
with Adi.Widget.Animated_Widget.RLottie;
with Adi.Widget.Box;
with Adi.Widget.RLottie;
with Adi.Widget_Styles;              use Adi.Widget_Styles;
with Adi.CSS_Styles;                 use Adi.CSS_Styles;
with Adi.Window;
with Test_Support;                       use Test_Support;

--  Two widgets draw rlottie animations, and each has to tell the
--  animation what pixel extent it will be drawn at. Nothing in the
--  frames shows whether it did: an animation never told rasterises
--  nothing and simply draws blank, which no assertion about the picture
--  distinguishes from a widget that is merely empty. These look at what
--  the widget asked the animation for.

procedure RLottie_Widget_Test is

   Fixture : constant String := "tests/assets/tiny_anim.json";

   --  Every wait is bounded: a state machine that never settles must
   --  fail the suite rather than hang it.
   Deadline : constant := 400;   --  × 5 ms

   procedure Settle (Anim : in out RLottie_Animation'Class) is
   begin
      for I in 1 .. Deadline loop
         Service (Anim);
         exit when not Build_In_Flight (Anim);
         delay 0.005;
      end loop;
   end Settle;

   --  Waits for the Nth build to be installed. The plain Pump below
   --  cannot serve here: during the debounce the old generation is still
   --  prepared and no worker has started yet, so "prepared and idle" is
   --  true of a state that has not begun the work being waited for.
   procedure Pump_Until_Build
     (W     : Adi.Window.Window_Handle;
      Anim  : in out RLottie_Animation'Class;
      Count : Positive)
   is
   begin
      for I in 1 .. Deadline loop
         Adi.Window.Render (W);
         Service (Anim);
         exit when Build_Count (Anim) >= Count
                   and then not Build_In_Flight (Anim);
         delay 0.005;
      end loop;
   end Pump_Until_Build;

   --  Renders until the widget has had a chance to build its items and
   --  the animation has finished preparing.
   procedure Pump
     (W    : Adi.Window.Window_Handle;
      Anim : access RLottie_Animation'Class)
   is
   begin
      for I in 1 .. Deadline loop
         Adi.Window.Render (W);
         if Anim /= null then
            Service (Anim.all);
            exit when Is_Prepared (Anim.all)
                      and then not Build_In_Flight (Anim.all);
         end if;
         delay 0.005;
      end loop;
   end Pump;

   ---------------------------------------------------------------------------

   --  The direct widget. Its Build_Items is a different call site from
   --  the animated widget's, so it needs its own animation and its own
   --  assertion: one covering both would pass with either broken.
   procedure Test_RLottie_Widget_Prepares is
      W    : Adi.Window.Window_Handle;
      Box  : Adi.Widget.RLottie.RLottie_Handle;
      Anim : RLottie_Animation_Access;
   begin
      Section ("Adi.Widget.RLottie asks at its own extent");

      Anim := Load_From_File (Fixture);
      Assert (Anim /= null, "the fixture loads");
      if Anim = null then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("RLottie Widget", (200.0, 200.0));
      Box := Adi.Widget.RLottie.Create_Handle (Anim);
      Adi.Widget.RLottie.Set_Max_Size (Box, 64.0, 48.0);
      Adi.Window.Set_Root (W, Adi.Widget.RLottie.To_Widget_Handle (Box));

      Pump (W, Anim);

      Assert (Build_Count (Anim.all) = 1,
              "Rendering should prepare the animation exactly once:"
              & " never is a blank widget, twice is a wasted frame set");
      Assert (Is_Prepared (Anim.all), "and leave it drawable");

      declare
         PW, PH : Natural;
      begin
         Prepared_Extent (Anim.all, PW, PH);
         Assert (PW > 0 and then PH > 0,
                 "at a real extent");
         --  The widget is the root of a 200 by 200 window and stretches
         --  to it, so that is the extent it draws at and the extent its
         --  frames must be rasterised at -- not the file's own 8 by 8,
         --  and not the measurement bound, which constrains only how
         --  large the widget asks to be when something else decides.
         Assert (PW = 200 and then PH = 200,
                 "at exactly the extent the widget occupies");
      end;

      Adi.Window.Destroy (W);
      Destroy (Anim.all);
   end Test_RLottie_Widget_Prepares;

   ---------------------------------------------------------------------------

   procedure Test_Animated_Widget_Prepares is
      W    : Adi.Window.Window_Handle;
      Box  : Adi.Widget.Animated_Widget.Animated_Widget_Handle;
      Anim : RLottie_Animation_Access;
   begin
      Section ("Adi.Widget.Animated_Widget asks through its backend");

      Anim := Load_From_File (Fixture);
      Assert (Anim /= null, "the fixture loads");
      if Anim = null then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("Animated Widget", (200.0, 200.0));
      Box := Adi.Widget.Animated_Widget.Create_Handle;
      Adi.Widget.Animated_Widget.RLottie.Set_Animation (Box, Anim);
      Adi.Widget.Animated_Widget.Set_Max_Size (Box, 64.0, 48.0);
      Adi.Window.Set_Root
        (W, Adi.Widget.Animated_Widget.To_Widget_Handle (Box));

      Pump (W, Anim);

      Assert (Build_Count (Anim.all) = 1,
              "The backend path should prepare exactly once too: it is a"
              & " separate call site and fails separately");
      Assert (Is_Prepared (Anim.all), "and leave it drawable");

      declare
         PW, PH : Natural;
      begin
         Prepared_Extent (Anim.all, PW, PH);
         Assert (PW > 0 and then PH > 0, "at a real extent");
         Assert (PW = 200 and then PH = 200,
                 "at exactly the extent the widget occupies");
      end;

      Adi.Window.Destroy (W);
      Destroy (Anim.all);
   end Test_Animated_Widget_Prepares;

   ---------------------------------------------------------------------------

   --  Scale is process-global here, so it is restored whatever happens:
   --  a test that raised while it was changed would leave every later
   --  test measuring in the wrong units.
   procedure Test_Scale_Change_Reprepares is
      W     : Adi.Window.Window_Handle;
      Box   : Adi.Widget.RLottie.RLottie_Handle;
      Root  : Adi.Widget.Box.Box_Handle;
      Anim  : RLottie_Animation_Access;
      Was_W : Natural := 0;
      Was_H : Natural := 0;

      procedure Body_Of_Test is
      begin
         Pump (W, Anim);
         Assert (Build_Count (Anim.all) = 1, "one build at the first scale");
         Prepared_Extent (Anim.all, Was_W, Was_H);
         Assert (Was_W = 200 and then Was_H = 30,
                 "thirty dip is thirty pixels at unit scale, stretched"
                 & " across the block");

         --  Same logical geometry, twice the pixels behind it.
         Adi.Window.Set_UI_Scale (W, 2.0);
         Adi.Window.Render (W);

         Assert (Is_Prepared (Anim.all),
                 "The old generation stays drawable across a scale"
                 & " change, rather than blanking while it re-rasterises");
         declare
            PW, PH : Natural;
         begin
            Prepared_Extent (Anim.all, PW, PH);
            Assert (PW = Was_W and then PH = Was_H,
                    "and it is still the old one being drawn while the"
                    & " replacement is pending");
         end;

         Pump_Until_Build (W, Anim.all, 2);

         Assert (Build_Count (Anim.all) = 2,
                 "exactly one replacement build follows the scale change");
         Assert (not Build_In_Flight (Anim.all), "and it has finished");

         declare
            PW, PH : Natural;
         begin
            Prepared_Extent (Anim.all, PW, PH);
            Assert (PH = 60,
                    "thirty dip is sixty pixels at double scale, so the"
                    & " frames are rasterised at the size actually drawn");
            Assert (PW = 200,
                    "while the stretched axis is unchanged, being fixed"
                    & " by the block rather than by a dip length");
         end;
      end Body_Of_Test;

   begin
      Section ("a scale change re-prepares at the new physical size");

      Anim := Load_From_File (Fixture);
      Assert (Anim /= null, "the fixture loads");
      if Anim = null then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle ("RLottie Scale", (200.0, 200.0));
      Box := Adi.Widget.RLottie.Create_Handle (Anim);

      --  Sized in dip rather than stretched to the window: a root widget
      --  filling a window of fixed pixels occupies the same pixels at any
      --  scale, so it could not show a scale change either way.
      declare
         Rules : Style_Rules;
      begin
         Rules.Width := Set (Size (Dip (40.0)));
         Rules.Height := Set (Size (Dip (30.0)));
         Set_Part_Style (Adi.Widget.RLottie.To_Widget_Handle (Box),
                         Main_Part, From (Rules).Build);
      end;

      Root := Adi.Widget.Box.Create_Handle;
      Adi.Widget.Box.Add_Child
        (Root, Adi.Widget.RLottie.To_Widget_Handle (Box));
      Adi.Window.Set_Root (W, Adi.Widget.Box.To_Widget_Handle (Root));

      begin
         Body_Of_Test;
      exception
         when E : others =>
            Assert (False,
                    "the scale test should not raise: "
                    & Ada.Exceptions.Exception_Name (E));
      end;

      --  Restored whether the body succeeded, failed or raised.
      Adi.Window.Set_UI_Scale (W, 1.0);
      Adi.Window.Destroy (W);
      Destroy (Anim.all);
   end Test_Scale_Change_Reprepares;

begin
   Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
   Start_Suite ("RLottie widget test");

   if not Boolean (Adi.SDL.SDL_Init (Adi.SDL.SDL_INIT_VIDEO)) then
      Assert (False, "SDL_Init(video) should succeed");
      Finish;
      return;
   end if;

   Test_RLottie_Widget_Prepares;
   Test_Animated_Widget_Prepares;
   Test_Scale_Change_Reprepares;

   Finish;
end RLottie_Widget_Test;
