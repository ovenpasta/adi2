--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Environment_Variables;
with Ada.Exceptions;          use Ada.Exceptions;
with Ada.Text_IO;             use Ada.Text_IO;
with Interfaces.C;            use Interfaces.C;
with Adi.Core;                use Adi.Core;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.SDL;                 use Adi.SDL;
with Adi.SDL.Render;          use Adi.SDL.Render;
with Adi.SDL.Surface;         use Adi.SDL.Surface;
with Adi.SDL.TTF;
with Adi.Widget;              use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Text_Input;
with Adi.Widget.Value_Input;
with Adi.Widget_Styles;       use Adi.Widget_Styles;
with Adi.Window;
with Test_Support;            use Test_Support;

--  What `overflow: visible` means for text.
--
--  Text that does not fit its own box is drawn outside it, exactly as
--  CSS says (https://www.w3.org/TR/css-overflow/#valdef-overflow-visible),
--  and an ancestor that says `overflow: hidden` clips it. These tests
--  read the rendered pixels rather than geometry, because the failure
--  they guard against was a renderer-side clip that layout knew nothing
--  about.
procedure Text_Overflow_Test is

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;

   Win_W : constant := 400;
   Win_H : constant := 200;

   --  The clipping box: narrow enough that the label's text cannot fit.
   Box_W : constant := 110.0;
   Box_H : constant := 60.0;

   --  Wide, unwrappable, and bright against the black background.
   Sample : constant String := "MMMMMMMMMMMMMMMMMMMMMMMMMMMM";

   procedure Ensure_SDL_Initialized (Ready : out Boolean) is
      Ok : Adi.SDL.C_bool;
   begin
      Ada.Environment_Variables.Set ("SDL_VIDEODRIVER", "dummy");
      Ok := SDL_Init (SDL_INIT_VIDEO or SDL_INIT_EVENTS);
      Ready := Boolean (Ok);
      Assert (Ready, "SDL_Init(video|events) should succeed");
      if Ready then
         Ok := Adi.SDL.TTF.TTF_Init;
         Ready := Boolean (Ok);
         Assert (Ready, "TTF_Init should succeed");
      end if;
   end Ensure_SDL_Initialized;

   --  SDL invalidates the back buffer at present, so the frame is read
   --  from the post-render callback, which runs just before it.
   Captured : SDL_Surface_Ptr := null;

   procedure Capture_Frame
     (Win      : Adi.Window.Window_Handle;
      Renderer : SDL_Renderer_Ptr)
   is
      pragma Unreferenced (Win);
   begin
      if Captured /= null then
         SDL_DestroySurface (Captured);
      end if;
      Captured := SDL_RenderReadPixels (Renderer, Rect => null);
   end Capture_Frame;

   procedure Release_Capture is
   begin
      if Captured /= null then
         SDL_DestroySurface (Captured);
         Captured := null;
      end if;
   end Release_Capture;

   --  Count pixels that are not the black background inside a rectangle
   --  of the captured frame.
   function Ink_Count (X0, Y0, X1, Y1 : Integer) return Natural is
      Surf  : constant SDL_Surface_Ptr := Captured;
      R, G, B, A : aliased Uint8;
      Count : Natural := 0;
   begin
      if Surf = null then
         Assert (False, "the post-render callback should have captured a frame");
         return 0;
      end if;

      for Y in Y0 .. Y1 loop
         for X in X0 .. X1 loop
            if X >= 0 and then Y >= 0
              and then X < Integer (Surf.w) and then Y < Integer (Surf.h)
              and then Boolean
                         (SDL_ReadSurfacePixel
                            (Surf, int (X), int (Y),
                             R'Access, G'Access, B'Access, A'Access))
            then
               --  Anything lit up: text is white, the box is dark blue.
               if Natural (R) + Natural (G) + Natural (B) > 120 then
                  Count := Count + 1;
               end if;
            end if;
         end loop;
      end loop;

      return Count;
   end Ink_Count;

   --  root(black) > clip(Box_W x Box_H, given overflow) > label(Sample)
   function Build_Scene
     (Clip_Overflow : Overflow_Value) return Adi.Window.Window_Handle
   is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle
          ("Text Overflow", (Pixel_Type (Win_W), Pixel_Type (Win_H)));
      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Clip : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Text : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle (Sample);

      Root_Rules : constant Style_Rules :=
        (Display          => Set (Flex),
         Flex_Direction   => Set (Adi.CSS_Styles.Column),
         Background_Color => Set_Bg (RGB (0, 0, 0)),
         others           => <>);
      Clip_Rules : constant Style_Rules :=
        (Display          => Set (Flex),
         Flex_Direction   => Set (Adi.CSS_Styles.Column),
         Width            => Set (Size (Px (Box_W))),
         Height           => Set (Size (Px (Box_H))),
         Overflow_X       => Set_Overflow_X (Clip_Overflow),
         Overflow_Y       => Set_Overflow_Y (Clip_Overflow),
         Background_Color => Set_Bg (RGB (0, 0, 40)),
         others           => <>);
      Text_Rules : constant Style_Rules :=
        (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>);
      Label_Rules : constant Style_Rules :=
        (Color          => Set (RGB (255, 255, 255)),
         Font_Size      => Set_Font (Px (20.0)),
         Text_Wrap_Mode => Set (TWM_Nowrap),
         others         => <>);
   begin
      Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
      Set_Part_Style (+Clip, Main_Part, From (Clip_Rules).Build);
      Set_Part_Style (+Text, Main_Part, From (Text_Rules).Build);
      Set_Part_Style (+Text, Label_Part, From (Label_Rules).Build);

      Add_Child (+Clip, +Text);
      Add_Child (+Root, +Clip);

      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.Window.Connect_Post_Render (W, Capture_Frame'Unrestricted_Access);
      Adi.Window.Render (W);
      return W;
   end Build_Scene;

   procedure Test_Visible_Text_Escapes_Its_Box is
      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Inside, Beyond : Natural;
   begin
      Section ("overflow: visible draws text outside its box");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Build_Scene (Overflow_Visible);
      Inside := Ink_Count (0, 0, Integer (Box_W) - 1, Integer (Box_H) - 1);
      Beyond := Ink_Count (Integer (Box_W) + 2, 0, Win_W - 1,
                           Integer (Box_H) - 1);

      Put_Line ("    ink inside=" & Inside'Image
                & " beyond the box=" & Beyond'Image);

      Assert (Inside > 0, "the text renders at all");
      Assert (Beyond > 0,
              "text too wide for its box keeps rendering past the edge");

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Visible_Text_Escapes_Its_Box;

   procedure Test_Hidden_Ancestor_Still_Clips is
      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Inside, Beyond : Natural;
   begin
      Section ("overflow: hidden clips the same text");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Build_Scene (Overflow_Hidden);
      Inside := Ink_Count (0, 0, Integer (Box_W) - 1, Integer (Box_H) - 1);
      Beyond := Ink_Count (Integer (Box_W) + 2, 0, Win_W - 1,
                           Integer (Box_H) - 1);

      Put_Line ("    ink inside=" & Inside'Image
                & " beyond the box=" & Beyond'Image);

      Assert (Inside > 0, "the clipped text still renders inside the box");
      Assert (Beyond = 0, "nothing is drawn past a hidden box's edge");

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Hidden_Ancestor_Still_Clips;

   --  Wrapped text is measured in lines rather than columns, so the
   --  vertical case exercises a different path than the nowrap one.
   procedure Test_Wrapped_Text_Overflows_Downward is
      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Root  : Adi.Widget.Box.Box_Handle;
      Clip  : Adi.Widget.Box.Box_Handle;
      Text  : Adi.Widget.Label.Label_Handle;
      Below : Natural;

      Paragraph : constant String :=
        "This paragraph is deliberately long so that it wraps into far "
        & "more lines than the short box can hold, which means the last "
        & "lines have to be drawn below the box itself.";
   begin
      Section ("wrapped text overflows below a visible box");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle
             ("Wrapped Overflow", (Pixel_Type (Win_W), Pixel_Type (Win_H)));
      Root := Adi.Widget.Box.Create_Handle;
      Clip := Adi.Widget.Box.Create_Handle;
      Text := Adi.Widget.Label.Create_Handle (Paragraph);

      declare
         Root_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Background_Color => Set_Bg (RGB (0, 0, 0)),
            others           => <>);
         Clip_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Width            => Set (Size (Px (200.0))),
            Height           => Set (Size (Px (40.0))),
            Background_Color => Set_Bg (RGB (0, 0, 40)),
            others           => <>);
         Label_Rules : constant Style_Rules :=
           (Color          => Set (RGB (255, 255, 255)),
            Font_Size      => Set_Font (Px (14.0)),
            Text_Wrap_Mode => Set (TWM_Wrap),
            others         => <>);
      begin
         Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
         Set_Part_Style (+Clip, Main_Part, From (Clip_Rules).Build);
         Set_Part_Style (+Text, Label_Part, From (Label_Rules).Build);
      end;

      Add_Child (+Clip, +Text);
      Add_Child (+Root, +Clip);
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.Window.Connect_Post_Render (W, Capture_Frame'Unrestricted_Access);
      Adi.Window.Render (W);

      Below := Ink_Count (0, 45, 250, Win_H - 1);
      Put_Line ("    ink below the box=" & Below'Image);
      Assert (Below > 0,
              "wrapped lines that do not fit are drawn below the box");

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Wrapped_Text_Overflows_Downward;

   --  A value input derives from the text input, so it must inherit the
   --  clipping capability rather than depend on a flag its own
   --  constructor never sets: a long number would otherwise be drawn
   --  beside the field.
   procedure Test_Value_Input_Clips_Its_Number is
      package Float_Value_Input is new Adi.Widget.Value_Input (Float);

      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Root  : Adi.Widget.Box.Box_Handle;
      Field : Float_Value_Input.Value_Input_Handle;
      Inside, Beyond : Natural;

      Field_W : constant := 90.0;
   begin
      Section ("a value input clips its own scrolled number");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle
             ("Value Overflow", (Pixel_Type (Win_W), Pixel_Type (Win_H)));
      Root := Adi.Widget.Box.Create_Handle;
      Field := Float_Value_Input.Create_Handle
                 (Min => -1.0e9, Max => 1.0e9, Value => 0.0);

      declare
         --  Room to the left of the field: the line scrolls to keep its
         --  tail visible, so anything that escapes does so leftwards.
         Root_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Align_Items      => Set (Adi.CSS_Styles.Flex_End),
            Background_Color => Set_Bg (RGB (0, 0, 0)),
            others           => <>);
         Field_Rules : constant Style_Rules :=
           (Width            => Set (Size (Px (Field_W))),
            Height           => Set (Size (Px (40.0))),
            Background_Color => Set_Bg (RGB (0, 0, 40)),
            others           => <>);
         Text_Rules : constant Style_Rules :=
           (Color          => Set (RGB (255, 255, 255)),
            Font_Size      => Set_Font (Px (20.0)),
            Text_Wrap_Mode => Set (TWM_Nowrap),
            others         => <>);
      begin
         Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
         Set_Part_Style (Float_Value_Input.To_Widget_Handle (Field),
                         Main_Part, From (Field_Rules).Build);
         Set_Part_Style (Float_Value_Input.To_Widget_Handle (Field),
                         Text_Part, From (Text_Rules).Build);
         Set_Part_Style (Float_Value_Input.To_Widget_Handle (Field),
                         Label_Part, From (Text_Rules).Build);
      end;

      --  Far wider than the field, so the line has to scroll.
      Float_Value_Input.Set_Value (Field, -123456789.0);

      Add_Child (+Root, Float_Value_Input.To_Widget_Handle (Field));
      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.Window.Connect_Post_Render
        (W,
         Capture_Frame'Unrestricted_Access);
      Adi.Window.Render (W);

      --  The field is flush with the right edge, so its box starts here.
      declare
         Field_X : constant Integer := Win_W - Integer (Field_W);
      begin
         Inside := Ink_Count (Field_X, 0, Win_W - 1, 39);
         Beyond := Ink_Count (0, 0, Field_X - 2, 39);
      end;
      Put_Line ("    ink inside=" & Inside'Image
                & " left of the field=" & Beyond'Image);

      --  Without this the test would also pass if the number stopped
      --  rendering altogether.
      Assert (Inside > 0, "the number renders inside the field");
      Assert (Beyond = 0, "a value input does not draw its number outside "
              & "the field");

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Value_Input_Clips_Its_Number;

   --  A text input inside a scrolled page still shows its text. The
   --  input clips its own line, and that clip is a rectangle in window
   --  space: taking it from the widget's stored geometry while the items
   --  are drawn shifted by the scroll offset put the two in different
   --  places, and the text vanished as soon as the page moved.
   procedure Test_Scrolled_Input_Still_Renders is
      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Root  : Adi.Widget.Box.Box_Handle;
      Page  : Adi.Widget.Box.Box_Handle;
      Spacer : Adi.Widget.Box.Box_Handle;
      Field : Adi.Widget.Text_Input.Text_Input_Handle;

      Scroll_By : constant Pixel_Type := 90.0;
      Before, After : Natural;
   begin
      Section ("a scrolled text input keeps rendering its text");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle
             ("Scrolled Input", (Pixel_Type (Win_W), Pixel_Type (Win_H)));
      Root   := Adi.Widget.Box.Create_Handle;
      Page   := Adi.Widget.Box.Create_Handle;
      Spacer := Adi.Widget.Box.Create_Handle;
      Field  := Adi.Widget.Text_Input.Create_Handle ("WWWWWWWW");

      declare
         Root_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Background_Color => Set_Bg (RGB (0, 0, 0)),
            others           => <>);
         Page_Rules : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
            Height         => Set (Size (Px (150.0))),
            others         => <>);
         Spacer_Rules : constant Style_Rules :=
           (Height     => Set (Size (Px (200.0))),
            Min_Height => Set (Size (Px (200.0))),
            others     => <>);
         Field_Rules : constant Style_Rules :=
           (Height           => Set (Size (Px (40.0))),
            Min_Height       => Set (Size (Px (40.0))),
            Background_Color => Set_Bg (RGB (0, 0, 40)),
            others           => <>);
         Text_Rules : constant Style_Rules :=
           (Color     => Set (RGB (255, 255, 255)),
            Font_Size => Set_Font (Px (20.0)),
            others    => <>);
      begin
         Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
         Set_Part_Style (+Page, Main_Part, From (Page_Rules).Build);
         Set_Part_Style (+Spacer, Main_Part, From (Spacer_Rules).Build);
         Set_Part_Style
           (Adi.Widget.Text_Input.To_Widget_Handle (Field), Main_Part,
            From (Field_Rules).Build);
         Set_Part_Style
           (Adi.Widget.Text_Input.To_Widget_Handle (Field), Text_Part,
            From (Text_Rules).Build);
      end;

      Add_Child (+Page, +Spacer);
      Add_Child (+Page, Adi.Widget.Text_Input.To_Widget_Handle (Field));
      Add_Child (+Root, +Page);

      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.Window.Connect_Post_Render
        (W,
         Capture_Frame'Unrestricted_Access);
      Adi.Window.Render (W);

      --  The spacer is taller than the viewport, so the field starts out
      --  below the fold: nothing of it is on screen yet.
      Before := Ink_Count (0, 0, Win_W - 1, 149);
      Assert (Before = 0, "the field is below the fold to begin with");

      Set_Scroll_Offset_Y (+Page, Scroll_By);
      Adi.Window.Render (W);
      Assert (abs (Get_Scroll_Offset_Y (+Page) - Scroll_By) < 0.5,
              "the page really scrolled");

      --  Scrolled by 90, the field has come into view.
      After := Ink_Count (0, 0, Win_W - 1, 149);

      Put_Line ("    ink before scrolling=" & Before'Image
                & " after=" & After'Image);

      Assert (After > 0, "the field still renders its text once scrolled");

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Scrolled_Input_Still_Renders;

   --  A clipped container scrolled into view clips in the right place.
   --  The subtree clip is a window-space rectangle built from stored
   --  geometry, while the descendants inside it are drawn shifted by the
   --  page's scroll: the two must move together, or the box crops its
   --  own children -- or hides them entirely -- once the page moves.
   procedure Test_Scrolled_Clipping_Box_Keeps_Its_Children is
      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Root, Page, Spacer, Clip_Box, Trailer : Adi.Widget.Box.Box_Handle;
      Text  : Adi.Widget.Label.Label_Handle;

      --  Content is 414 tall in a 150 viewport; this brings the box up
      --  to roughly y=50, well clear of both viewport edges.
      Scroll_By : constant Pixel_Type := 150.0;
      Inside, Above, Below : Natural;
   begin
      Section ("a clipped box scrolled into view keeps clipping in place");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle
             ("Scrolled Clip", (Pixel_Type (Win_W), Pixel_Type (Win_H)));
      Root     := Adi.Widget.Box.Create_Handle;
      Page     := Adi.Widget.Box.Create_Handle;
      Spacer   := Adi.Widget.Box.Create_Handle;
      Clip_Box := Adi.Widget.Box.Create_Handle;
      Trailer  := Adi.Widget.Box.Create_Handle;
      Text     := Adi.Widget.Label.Create_Handle ("MMMM");

      declare
         Root_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Background_Color => Set_Bg (RGB (0, 0, 0)),
            others           => <>);
         Page_Rules : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
            Height         => Set (Size (Px (150.0))),
            others         => <>);
         Spacer_Rules : constant Style_Rules :=
           (Height     => Set (Size (Px (200.0))),
            Min_Height => Set (Size (Px (200.0))),
            others     => <>);
         --  Half the label's height, so the bottom of the text is cut.
         Box_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Height           => Set (Size (Px (14.0))),
            Min_Height       => Set (Size (Px (14.0))),
            Overflow_Y       => Set_Overflow_Y (Overflow_Hidden),
            Background_Color => Set_Bg (RGB (0, 0, 40)),
            others           => <>);
         Text_Rules : constant Style_Rules :=
           (Color          => Set (RGB (255, 255, 255)),
            Font_Size      => Set_Font (Px (28.0)),
            Text_Wrap_Mode => Set (TWM_Nowrap),
            others         => <>);
      begin
         Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
         Set_Part_Style (+Page, Main_Part, From (Page_Rules).Build);
         Set_Part_Style (+Spacer, Main_Part, From (Spacer_Rules).Build);
         Set_Part_Style (+Clip_Box, Main_Part, From (Box_Rules).Build);
         Set_Part_Style (+Trailer, Main_Part, From (Spacer_Rules).Build);
         Set_Part_Style (+Text, Label_Part, From (Text_Rules).Build);
      end;

      Add_Child (+Clip_Box, +Text);
      Add_Child (+Page, +Spacer);
      Add_Child (+Page, +Clip_Box);
      --  Trailing content, so the box can be scrolled to the middle of
      --  the viewport rather than sitting at its bottom edge -- there the
      --  page's own clip would hide anything escaping downwards and the
      --  test would pass without the box clipping at all.
      Add_Child (+Page, +Trailer);
      Add_Child (+Root, +Page);

      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.Window.Connect_Post_Render
        (W,
         Capture_Frame'Unrestricted_Access);
      Adi.Window.Render (W);

      Set_Scroll_Offset_Y (+Page, Scroll_By);
      Adi.Window.Render (W);
      Assert (abs (Get_Scroll_Offset_Y (+Page) - Scroll_By) < 0.5,
              "the page really scrolled");

      declare
         Box_G : constant Rectangle := Get_Geometry (+Clip_Box);
         --  Where the box is drawn: stored position, less the scroll.
         Top    : constant Integer := Integer (Box_G.Y - Scroll_By);
         Bottom : constant Integer := Top + Integer (Box_G.Height);
      begin
         --  With the trailer below it, the box is well inside the
         --  viewport: anything escaping it would be visible rather than
         --  cut off by the page.
         Assert (Bottom < 140,
                 "the box sits inside the viewport, not at its edge");

         Inside := Ink_Count (0, Top, Win_W - 1, Bottom - 1);
         Above  := Ink_Count (0, 0, Win_W - 1, Top - 2);
         Below  := Ink_Count (0, Bottom + 1, Win_W - 1, 149);

         Put_Line ("    box at" & Top'Image & " .." & Bottom'Image
                   & "  ink inside=" & Inside'Image
                   & " above=" & Above'Image
                   & " below=" & Below'Image);

         Assert (Inside > 0,
                 "the clipped box still shows its child once scrolled");
         Assert (Above = 0,
                 "nothing of it is drawn above the box");
         Assert (Below = 0,
                 "and nothing escapes below it either");
      end;

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Scrolled_Clipping_Box_Keeps_Its_Children;

   --  A scrollable widget inside another scrolled container moves with
   --  it, and so must its scrollbar: the track and knob are stored in
   --  layout coordinates and drawn directly, so without the same shift
   --  the bar stays behind while the widget it belongs to slides away.
   procedure Test_Nested_Scrollbar_Moves_With_Its_Widget is
      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Root, Page, Spacer, Inner, Tall : Adi.Widget.Box.Box_Handle;

      Scroll_By : constant Pixel_Type := 60.0;
      --  A colour nothing else in the scene uses.

      --  Count only the scrollbar's own colour.
      function Bar_Ink (Y0, Y1 : Integer) return Natural is
         Surf : constant SDL_Surface_Ptr := Captured;
         R, G, B, A : aliased Uint8;
         Count : Natural := 0;
      begin
         if Surf = null then
            return 0;
         end if;
         for Y in Y0 .. Y1 loop
            for X in 0 .. Win_W - 1 loop
               if Y >= 0 and then Y < Integer (Surf.h)
                 and then Boolean
                            (SDL_ReadSurfacePixel
                               (Surf, int (X), int (Y),
                                R'Access, G'Access, B'Access, A'Access))
                 and then Natural (R) > 200
                 and then Natural (G) < 60
                 and then Natural (B) < 60
               then
                  Count := Count + 1;
               end if;
            end loop;
         end loop;
         return Count;
      end Bar_Ink;

      Before, After_At_Old, After_At_New : Natural;
   begin
      Section ("a nested scrollbar moves with the widget it belongs to");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle
             ("Nested Scrollbar", (Pixel_Type (Win_W), Pixel_Type (Win_H)));
      Root   := Adi.Widget.Box.Create_Handle;
      Page   := Adi.Widget.Box.Create_Handle;
      Spacer := Adi.Widget.Box.Create_Handle;
      Inner  := Adi.Widget.Box.Create_Handle;
      Tall   := Adi.Widget.Box.Create_Handle;

      declare
         Root_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Background_Color => Set_Bg (RGB (0, 0, 0)),
            others           => <>);
         Page_Rules : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
            Height         => Set (Size (Px (150.0))),
            others         => <>);
         Spacer_Rules : constant Style_Rules :=
           (Height     => Set (Size (Px (160.0))),
            Min_Height => Set (Size (Px (160.0))),
            others     => <>);
         Inner_Rules : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            Overflow_Y     => Set_Overflow_Y (Overflow_Auto),
            Height         => Set (Size (Px (80.0))),
            Min_Height     => Set (Size (Px (80.0))),
            others         => <>);
         Tall_Rules : constant Style_Rules :=
           (Height     => Set (Size (Px (400.0))),
            Min_Height => Set (Size (Px (400.0))),
            others     => <>);
         Bar_Rules : constant Style_Rules :=
           (Background_Color => Set_Bg (RGB (255, 0, 0)), others => <>);
      begin
         Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
         Set_Part_Style (+Page, Main_Part, From (Page_Rules).Build);
         Set_Part_Style (+Spacer, Main_Part, From (Spacer_Rules).Build);
         Set_Part_Style (+Inner, Main_Part, From (Inner_Rules).Build);
         Set_Part_Style (+Inner, Scroll_Part, From (Bar_Rules).Build);
         Set_Part_Style (+Inner, Knob_Part, From (Bar_Rules).Build);
         Set_Part_Style (+Tall, Main_Part, From (Tall_Rules).Build);
      end;

      Add_Child (+Inner, +Tall);
      Add_Child (+Page, +Spacer);
      Add_Child (+Page, +Inner);
      Add_Child (+Root, +Page);

      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.Window.Connect_Post_Render
        (W,
         Capture_Frame'Unrestricted_Access);
      Adi.Window.Render (W);

      declare
         Inner_G : constant Rectangle := Get_Geometry (+Inner);
         Old_Top : constant Integer := Integer (Inner_G.Y);
         New_Top : constant Integer := Integer (Inner_G.Y - Scroll_By);
      begin
         --  The inner box starts below the fold, so nothing of it shows
         --  until the outer page scrolls it into view.
         Before := Bar_Ink (0, Win_H - 1);
         Assert (Before = 0, "the nested box starts out of view");

         Set_Scroll_Offset_Y (+Page, Scroll_By);
         Adi.Window.Render (W);
         Assert (abs (Get_Scroll_Offset_Y (+Page) - Scroll_By) < 0.5,
                 "the outer page really scrolled");

         After_At_New :=
           Bar_Ink (New_Top, New_Top + Integer (Inner_G.Height) - 1);
         After_At_Old :=
           Bar_Ink (New_Top + Integer (Inner_G.Height) + 2,
                    Old_Top + Integer (Inner_G.Height) - 1);

         Put_Line ("    bar ink: before=" & Before'Image
                   & " after at the new position=" & After_At_New'Image
                   & " left behind=" & After_At_Old'Image);

         Assert (After_At_New > 0,
                 "the scrollbar follows its widget up the page");
         Assert (After_At_Old = 0,
                 "and nothing of it is left at the old position");
      end;

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Nested_Scrollbar_Moves_With_Its_Widget;

   --  Words are not broken. Given a box narrower than a single word, the
   --  renderer draws that word past the edge instead of chopping it into
   --  stacked fragments -- which is what layout reserved room for, since
   --  measurement applies the same floor. Read from pixels: the geometry
   --  comes from the same measurement code, so it cannot testify about
   --  what the renderer did.
   procedure Test_Renderer_Does_Not_Break_Words is
      Ready : Boolean;
      W     : Adi.Window.Window_Handle;
      Root, Narrow : Adi.Widget.Box.Box_Handle;
      Text  : Adi.Widget.Label.Label_Handle;

      --  One word, far wider than the box it is given.
      Word : constant String := "MMMMMMMMMMMM";
      Box_W_Px : constant := 40;
      Line_H   : constant := 34;

      Inside, Beside, Below : Natural;
   begin
      Section ("the renderer overflows a long word instead of breaking it");
      Ensure_SDL_Initialized (Ready);
      if not Ready then
         return;
      end if;

      W := Adi.Window.Create_Window_Handle
             ("Word Break", (Pixel_Type (Win_W), Pixel_Type (Win_H)));
      Root   := Adi.Widget.Box.Create_Handle;
      Narrow := Adi.Widget.Box.Create_Handle;
      Text   := Adi.Widget.Label.Create_Handle (Word);

      declare
         Root_Rules : constant Style_Rules :=
           (Display          => Set (Flex),
            Flex_Direction   => Set (Adi.CSS_Styles.Column),
            Background_Color => Set_Bg (RGB (0, 0, 0)),
            others           => <>);
         --  A cross-axis child of a column: no automatic minimum, so it
         --  really does get a width narrower than the word.
         Narrow_Rules : constant Style_Rules :=
           (Display        => Set (Flex),
            Flex_Direction => Set (Adi.CSS_Styles.Column),
            Width          => Set (Size (Px (Box_W_Px))),
            others         => <>);
         Text_Rules : constant Style_Rules :=
           (Color          => Set (RGB (255, 255, 255)),
            Font_Size      => Set_Font (Px (24.0)),
            Text_Wrap_Mode => Set (TWM_Wrap),
            others         => <>);
      begin
         Set_Part_Style (+Root, Main_Part, From (Root_Rules).Build);
         Set_Part_Style (+Narrow, Main_Part, From (Narrow_Rules).Build);
         Set_Part_Style (+Text, Label_Part, From (Text_Rules).Build);
      end;

      Add_Child (+Narrow, +Text);
      Add_Child (+Root, +Narrow);

      Adi.Window.Set_Enforce_Layout_Min_Size (W, False);
      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.Window.Connect_Post_Render
        (W,
         Capture_Frame'Unrestricted_Access);
      Adi.Window.Render (W);

      Inside := Ink_Count (0, 0, Box_W_Px - 1, Line_H);
      Beside := Ink_Count (Box_W_Px + 2, 0, Win_W - 1, Line_H);
      Below  := Ink_Count (0, Line_H + 6, Win_W - 1, Win_H - 1);

      Put_Line ("    ink inside=" & Inside'Image
                & " beside=" & Beside'Image
                & " below the first line=" & Below'Image);

      Assert (Inside > 0, "the word renders");
      Assert (Beside > 0,
              "it runs past the box rather than being chopped to fit");
      Assert (Below = 0,
              "and it is not stacked into further lines below");

      Release_Capture;
      Adi.Window.Destroy (W);
   exception
      when E : others =>
         Assert (False, "Unexpected exception: " & Exception_Name (E));
   end Test_Renderer_Does_Not_Break_Words;

begin
   Start_Suite ("Text Overflow Test");
   New_Line;
   Test_Visible_Text_Escapes_Its_Box;
   New_Line;
   Test_Hidden_Ancestor_Still_Clips;
   New_Line;
   Test_Wrapped_Text_Overflows_Downward;
   New_Line;
   Test_Value_Input_Clips_Its_Number;
   New_Line;
   Test_Scrolled_Input_Still_Renders;
   New_Line;
   Test_Scrolled_Clipping_Box_Keeps_Its_Children;
   New_Line;
   Test_Nested_Scrollbar_Moves_With_Its_Widget;
   New_Line;
   Test_Renderer_Does_Not_Break_Words;
   New_Line;
   Finish;
end Text_Overflow_Test;
