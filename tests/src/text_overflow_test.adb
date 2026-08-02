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
     (Win      : not null access Adi.Window.Window'Class;
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
      Adi.Window.Connect_Post_Render
        (Adi.Window.Resolve_Window_Handle (W).all, Capture_Frame'Unrestricted_Access);
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
      Adi.Window.Connect_Post_Render
        (Adi.Window.Resolve_Window_Handle (W).all, Capture_Frame'Unrestricted_Access);
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
        (Adi.Window.Resolve_Window_Handle (W).all,
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
   Finish;
end Text_Overflow_Test;
