--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Directories;
with Ada.Numerics.Elementary_Functions;
with Ada.Streams.Stream_IO;
with Interfaces;
with Interfaces.C.Strings;
with System;

with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.OS;
with Adi.SDL;
with Adi.SDL.Render;
with Adi.Widget;
with Adi.Widget.Html_View;
with Adi.Widget.Texture_View;
with Adi.Window;

with Adi_GL;

with GL_Demo_UI;

--  A tetrahedron drawn by OpenGL into a texture Adi never touches, shown
--  as a widget and driven by ordinary Adi controls.
--
--  The layout is XML, the styling is CSS, and the GL work happens in a
--  per-frame callback outside the widget tree. The controls only write
--  variables the callback reads on its next pass: nothing in the GUI
--  reaches into GL, and nothing in GL reaches into the GUI.
procedure GL_Triangle is

   package UI is new GL_Demo_UI.Instance;

   ---------------------------------------------------------------------
   --  OpenGL through Adi_GL
   ---------------------------------------------------------------------

   use Adi_GL;

   function Sin (X : Float) return Float
     renames Ada.Numerics.Elementary_Functions.Sin;
   function Cos (X : Float) return Float
     renames Ada.Numerics.Elementary_Functions.Cos;
   function Sqrt (X : Float) return Float
     renames Ada.Numerics.Elementary_Functions.Sqrt;

   type Vec3 is record
      X, Y, Z : Float;
   end record;

   --  A regular tetrahedron: four alternate corners of a cube, pulled
   --  onto the unit sphere.
   Third_Root : constant Float := 0.577_350_27;

   Corners : constant array (0 .. 3) of Vec3 :=
     [(Third_Root, Third_Root, Third_Root),
      (Third_Root, -Third_Root, -Third_Root),
      (-Third_Root, Third_Root, -Third_Root),
      (-Third_Root, -Third_Root, Third_Root)];

   type Face is array (0 .. 2) of Natural;

   --  Wound counter-clockwise seen from outside, which is what back-face
   --  culling reads.
   Faces : constant array (0 .. 3) of Face :=
     [[0, 1, 2], [0, 2, 3], [0, 3, 1], [1, 3, 2]];

   --  Full value, so the corner colours match the spectrum on the slider
   --  that picks them.
   function From_Hue (Degrees : Float) return Vec3 is
      Saturation : constant Float := 0.82;

      Turns : constant Float := Degrees / 360.0;
      Sixth : constant Float :=
        (Turns - Float'Floor (Turns)) * 6.0;
      Band  : constant Integer := Integer (Float'Floor (Sixth));
      Along : constant Float := Sixth - Float (Band);

      Low  : constant Float := 1.0 - Saturation;
      Down : constant Float := 1.0 - Saturation * Along;
      Up   : constant Float := 1.0 - Saturation * (1.0 - Along);
   begin
      case Band is
         when 0      => return (1.0, Up, Low);
         when 1      => return (Down, 1.0, Low);
         when 2      => return (Low, 1.0, Up);
         when 3      => return (Low, Down, 1.0);
         when 4      => return (Up, Low, 1.0);
         when others => return (1.0, Low, Down);
      end case;
   end From_Hue;

   Tex_W : constant := 1024;
   Tex_H : constant := 1024;

   Tex  : aliased GLuint := 0;
   FBO  : aliased GLuint := 0;
   VAO  : aliased GLuint := 0;
   VBO  : aliased GLuint := 0;
   Prog : GLuint := 0;

   Ready    : Boolean := False;
   Finished : Boolean := False;
   Angle    : Float := 0.0;
   Orbit    : Float := 0.0;

   --  Read at startup rather than bundled, so the file can be edited
   --  between runs without rebuilding. Base_Path is where the binary
   --  is, and bin/ sits beside assets/, so the working directory the
   --  user happened to run from does not come into it.
   function Read_Asset (Name : String) return String is
      use Ada.Streams.Stream_IO;

      Path : constant String := Adi.OS.Base_Path & "../assets/" & Name;
      F    : File_Type;
   begin
      if not Ada.Directories.Exists (Path) then
         return "<p>Missing " & Path & "</p>";
      end if;

      Open (F, In_File, Path);
      declare
         Size   : constant Natural :=
           Natural (Ada.Directories.Size (Path));
         Buffer : String (1 .. Size);
      begin
         String'Read (Stream (F), Buffer);
         Close (F);
         return Buffer;
      exception
         when others =>
            if Is_Open (F) then
               Close (F);
            end if;
            return "<p>Could not read " & Path & "</p>";
      end;
   end Read_Asset;

   --  A shader that will not compile draws nothing and says nothing, so
   --  the log is worth reading here.
   function Make_Shader (Kind : GLenum; Source : String) return GLuint is
      use Interfaces.C;
      use Interfaces.C.Strings;

      Id     : constant GLuint := glCreateShader (Kind);
      Text   : aliased chars_ptr := New_String (Source);
      Status : aliased GLint := 0;
   begin
      glShaderSource (Id, 1, Text'Access, null);
      Free (Text);
      glCompileShader (Id);
      glGetShaderiv (Id, GL_COMPILE_STATUS, Status'Access);

      if Status = 0 then
         declare
            Log : char_array (0 .. 1023) := [others => nul];
            Len : aliased GLsizei := 0;
         begin
            glGetShaderInfoLog
              (Id, GLsizei (Log'Length), Len'Access, Log (0)'Access);
            glDeleteShader (Id);
            raise Program_Error with To_Ada (Log);
         end;
      end if;
      return Id;
   end Make_Shader;

   --  Written by the controls, read by the GL callback.
   Speed    : Float   := 0.6;
   Scale    : Float   := 0.72;
   Hue      : Float   := 200.0;
   Spinning : Boolean := True;
   Orbiting : Boolean := False;

   ------------------
   -- GL rendering --
   ------------------
   procedure Draw_GL (Win : Adi.Window.Window_Handle) is
      Saved_Clear    : GLfloat_Array (0 .. 3) := [others => 0.0];
      Saved_Viewport : GLint_Array (0 .. 3)   := [others => 0];
      Saved_Program  : aliased GLint := 0;
      Saved_FBO      : aliased GLint := 0;
      Saved_Texture  : aliased GLint := 0;
      Saved_VAO      : aliased GLint := 0;
      Saved_Cull     : aliased GLint := GLint (GL_BACK);
      Saved_Winding  : aliased GLint := GLint (GL_CCW);
      Saved_Buffer   : aliased GLint := 0;
      Unused         : Adi.SDL.C_bool;

      --  Scissor above all: SDL leaves it enabled with a rect in window
      --  coordinates, which would clip drawing into a texture that has
      --  no relation to the window at all.
      Toggles : constant array (Positive range <>) of GLenum :=
        [GL_SCISSOR_TEST, GL_DEPTH_TEST, GL_CULL_FACE, GL_BLEND];
      Was_On  : array (Toggles'Range) of GLboolean := [others => GL_FALSE];
   begin
      if Finished then
         return;
      end if;

      --  Required before calling into GL alongside SDL_Renderer: drains
      --  the queued batch and drops SDL's cached state, so SDL rebuilds
      --  what it needs instead of trusting what it last set.
      Unused := Adi.SDL.Render.SDL_FlushRenderer
        (Adi.Window.Get_Renderer (Win));

      --  SDL_FlushRenderer protects SDL's own cached state; the rest is
      --  raw GL. Everything this callback goes on to change is read back
      --  from the driver here and put back on the way out.
      glGetFloatv (GL_COLOR_CLEAR_VALUE, Saved_Clear (0)'Access);
      glGetIntegerv (GL_VIEWPORT, Saved_Viewport (0)'Access);
      glGetIntegerv (GL_CURRENT_PROGRAM, Saved_Program'Access);
      glGetIntegerv (GL_FRAMEBUFFER_BINDING, Saved_FBO'Access);
      glGetIntegerv (GL_TEXTURE_BINDING_2D, Saved_Texture'Access);
      glGetIntegerv (GL_VERTEX_ARRAY_BINDING, Saved_VAO'Access);
      glGetIntegerv (GL_CULL_FACE_MODE, Saved_Cull'Access);
      glGetIntegerv (GL_FRONT_FACE, Saved_Winding'Access);
      glGetIntegerv (GL_ARRAY_BUFFER_BINDING, Saved_Buffer'Access);

      if not Ready then
         --  Resolves the post-1.1 entry points against the live context.
         Adi_GL.Load;
         if not Adi_GL.Loaded then
            raise Program_Error with
              "OpenGL entry point unavailable: "
              & Adi_GL.Missing_Entry_Point;
         end if;

         glGenTextures (1, Tex'Access);
         glBindTexture (GL_TEXTURE_2D, Tex);
         glTexImage2D
           (GL_TEXTURE_2D, 0, GLint (GL_RGBA), Tex_W, Tex_H, 0,
            GL_RGBA, GL_UNSIGNED_BYTE, System.Null_Address);
         glTexParameteri
           (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GLint (GL_LINEAR));
         glTexParameteri
           (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GLint (GL_LINEAR));

         glGenFramebuffers (1, FBO'Access);
         glBindFramebuffer (GL_FRAMEBUFFER, FBO);
         glFramebufferTexture2D
           (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, Tex, 0);

         --  Own program, own vertex array, own buffer: nothing here is
         --  state SDL reads, which is the whole point of not using the
         --  fixed-function pipeline in a context SDL believes it owns.
         declare
            use Interfaces.C.Strings;

            VS : constant GLuint := Make_Shader
              (GL_VERTEX_SHADER,
               "#version 120" & ASCII.LF
               & "attribute vec2 aPos;" & ASCII.LF
               & "attribute vec3 aCol;" & ASCII.LF
               & "varying vec3 vCol;" & ASCII.LF
               & "void main(){vCol=aCol;gl_Position=vec4(aPos,0.0,1.0);}");
            FS : constant GLuint := Make_Shader
              (GL_FRAGMENT_SHADER,
               "#version 120" & ASCII.LF
               & "varying vec3 vCol;" & ASCII.LF
               & "void main(){gl_FragColor=vec4(vCol,1.0);}");

            A_Pos  : chars_ptr := New_String ("aPos");
            A_Col  : chars_ptr := New_String ("aCol");
            Status : aliased GLint := 0;
         begin
            Prog := glCreateProgram.all;
            glAttachShader (Prog, VS);
            glAttachShader (Prog, FS);
            glBindAttribLocation (Prog, 0, A_Pos);
            glBindAttribLocation (Prog, 1, A_Col);
            glLinkProgram (Prog);

            Free (A_Pos);
            Free (A_Col);

            glGetProgramiv (Prog, GL_LINK_STATUS, Status'Access);

            glDeleteShader (VS);
            glDeleteShader (FS);

            if Status = 0 then
               glDeleteProgram (Prog);
               Prog := 0;
               raise Program_Error with "shader program did not link";
            end if;
         end;

         glGenVertexArrays (1, VAO'Access);
         glGenBuffers (1, VBO'Access);

         Ready := True;
         Adi.Widget.Texture_View.Set_Texture
              (UI.View,
               Backend => Adi.Widget.Texture_View.OpenGL,
               Name    => Interfaces.Unsigned_64 (Tex),
               Width   => Tex_W,
               Height  => Tex_H);
      end if;

      if Spinning then
         Angle := Angle + Speed * 0.03;
      end if;

      if Orbiting then
         Orbit := Orbit + Speed * 0.012;
      end if;

      glBindFramebuffer (GL_FRAMEBUFFER, FBO);
      glViewport (0, 0, Tex_W, Tex_H);

      for I in Toggles'Range loop
         Was_On (I) := glIsEnabled (Toggles (I));
         glDisable (Toggles (I));
      end loop;

      --  A tetrahedron is convex, so dropping the faces that turn away
      --  leaves exactly the ones in front: no visible face can hide
      --  another. That is what lets this draw solid into a framebuffer
      --  carrying nothing but colour.
      glFrontFace (GL_CCW);
      glCullFace (GL_BACK);
      glEnable (GL_CULL_FACE);

      glClearColor (0.99, 0.99, 1.0, 1.0);
      glClear (GL_COLOR_BUFFER_BIT);

      declare
         --  Spin about the upright axis, under a fixed tilt so the
         --  solid is seen from a little above rather than edge on.
         Tilt : constant Float := 0.42;
         Spin_C : constant Float := Cos (Angle);
         Spin_S : constant Float := Sin (Angle);
         Tilt_C : constant Float := Cos (Tilt);
         Tilt_S : constant Float := Sin (Tilt);

         --  Far enough that the near corner grows by about a fifth.
         Eye : constant Float := 3.2;

         --  Unit length, so the dot product below is the cosine.
         Light : constant Vec3 := (0.33, 0.53, 0.78);

         --  Carried around the view as a whole, after the projection, so
         --  it moves the solid without turning it or changing its size.
         Drift_X : constant Float :=
           (if Orbiting then 0.42 * Cos (Orbit) else 0.0);
         Drift_Y : constant Float :=
           (if Orbiting then 0.28 * Sin (Orbit) else 0.0);

         function Turned (V : Vec3) return Vec3 is
            X1 : constant Float := V.X * Spin_C - V.Z * Spin_S;
            Z1 : constant Float := V.X * Spin_S + V.Z * Spin_C;
         begin
            return (X       => X1,
                    Y       => V.Y * Tilt_C - Z1 * Tilt_S,
                    Z       => V.Y * Tilt_S + Z1 * Tilt_C);
         end Turned;

         Placed : array (Corners'Range) of Vec3;

         --  x, y, r, g, b per vertex, three vertices to a face. The
         --  faces do not share vertices: each carries its own shade,
         --  which is what makes the solid read as facets rather than a
         --  smear.
         Verts : GLfloat_Array (0 .. 5 * 3 * Faces'Length - 1) :=
           [others => 0.0];
         At_Vertex : Natural := Verts'First;

         Unit   : constant GLsizei := GLfloat'Size / System.Storage_Unit;
         Stride : constant GLsizei := 5 * Unit;
      begin
         for I in Corners'Range loop
            Placed (I) := Turned (Corners (I));
         end loop;

         for F of Faces loop
            declare
               A : constant Vec3 := Placed (F (0));
               B : constant Vec3 := Placed (F (1));
               C : constant Vec3 := Placed (F (2));

               U : constant Vec3 :=
                 (B.X - A.X, B.Y - A.Y, B.Z - A.Z);
               V : constant Vec3 :=
                 (C.X - A.X, C.Y - A.Y, C.Z - A.Z);

               Normal : constant Vec3 :=
                 (U.Y * V.Z - U.Z * V.Y,
                  U.Z * V.X - U.X * V.Z,
                  U.X * V.Y - U.Y * V.X);
               Length : constant Float :=
                 Sqrt (Normal.X * Normal.X
                       + Normal.Y * Normal.Y
                       + Normal.Z * Normal.Z);
               Facing : constant Float :=
                 (if Length = 0.0 then 0.0
                  else (Normal.X * Light.X
                        + Normal.Y * Light.Y
                        + Normal.Z * Light.Z) / Length);

               --  Never to black: an unlit face still shows its
               --  corners' colours, only dimmer.
               Shade : constant Float :=
                 0.45 + 0.55 * Float'Max (0.0, Facing);
            begin
               for K in F'Range loop
                  declare
                     P : constant Vec3 := Placed (F (K));

                     --  The near corner is drawn larger than the far
                     --  one, which is the whole of the perspective
                     --  here.
                     Near : constant Float :=
                       Scale * 0.82 * Eye / (Eye - P.Z);

                     --  A quarter turn of hue per corner, all four
                     --  carried round together by the control.
                     Tint : constant Vec3 :=
                       From_Hue (Hue + 90.0 * Float (F (K)));
                  begin
                     Verts (At_Vertex)     :=
                       GLfloat (P.X * Near + Drift_X);
                     Verts (At_Vertex + 1) :=
                       GLfloat (P.Y * Near + Drift_Y);
                     Verts (At_Vertex + 2) := GLfloat (Tint.X * Shade);
                     Verts (At_Vertex + 3) := GLfloat (Tint.Y * Shade);
                     Verts (At_Vertex + 4) := GLfloat (Tint.Z * Shade);
                     At_Vertex := At_Vertex + 5;
                  end;
               end loop;
            end;
         end loop;

         glUseProgram (Prog);
         glBindVertexArray (VAO);
         glBindBuffer (GL_ARRAY_BUFFER, VBO);
         glBufferData
           (GL_ARRAY_BUFFER, GLsizeiptr (Verts'Length * Unit),
            Verts (Verts'First)'Address, GL_STREAM_DRAW);

         glEnableVertexAttribArray (0);
         glVertexAttribPointer (0, 2, GL_FLOAT, GL_FALSE, Stride, 0);
         glEnableVertexAttribArray (1);
         glVertexAttribPointer
           (1, 3, GL_FLOAT, GL_FALSE, Stride, GLoffset (2 * Unit));

         glDrawArrays (GL_TRIANGLES, 0, 3 * Faces'Length);

         glDisableVertexAttribArray (0);
         glDisableVertexAttribArray (1);
         glBindBuffer (GL_ARRAY_BUFFER, GLuint (Saved_Buffer));
      end;

      for I in Toggles'Range loop
         if Was_On (I) = GL_FALSE then
            glDisable (Toggles (I));
         else
            glEnable (Toggles (I));
         end if;
      end loop;

      glFinish;

      Adi.Widget.Texture_View.Invalidate (UI.View);

      glBindVertexArray (GLuint (Saved_VAO));
      glUseProgram (GLuint (Saved_Program));
      glBindTexture (GL_TEXTURE_2D, GLuint (Saved_Texture));
      glBindFramebuffer (GL_FRAMEBUFFER, GLuint (Saved_FBO));
      glViewport
        (Saved_Viewport (0), Saved_Viewport (1),
         Saved_Viewport (2), Saved_Viewport (3));
      glClearColor
        (Saved_Clear (0), Saved_Clear (1), Saved_Clear (2), Saved_Clear (3));
      glCullFace (GLenum (Saved_Cull));
      glFrontFace (GLenum (Saved_Winding));

      --  Flush on the way out as well as in. The call drops SDL's cached
      --  state, and the state worth dropping is what this callback just
      --  changed -- doing it only on entry invalidates a cache that was
      --  still accurate and leaves the dirtied one in place.
      Unused := Adi.SDL.Render.SDL_FlushRenderer
        (Adi.Window.Get_Renderer (Win));
   end Draw_GL;

   --  The objects belong to the context SDL made, and Run destroys the
   --  window -- and with it that context -- as it returns. A close
   --  request is the last moment they can be released, so they go here
   --  rather than after the loop.
   procedure On_Close
     (Win   : Adi.Window.Window_Handle;
      Allow : in out Boolean)
   is
      pragma Unreferenced (Win);
   begin
      Allow := True;

      if not Ready then
         return;
      end if;

      --  Before the names go: the view holds one and blits it.
      Adi.Widget.Texture_View.Clear_Texture (UI.View);

      glDeleteBuffers (1, VBO'Access);
      glDeleteVertexArrays (1, VAO'Access);
      glDeleteFramebuffers (1, FBO'Access);
      glDeleteTextures (1, Tex'Access);

      if Prog /= 0 then
         glDeleteProgram (Prog);
         Prog := 0;
      end if;

      Ready    := False;
      Finished := True;
   end On_Close;

   --------------
   -- Controls --
   --------------

   --  A value input prints the shortest text that reads back as the
   --  number it holds, so a value straight off a dragged slider prints
   --  every digit it has. Three decimals is finer than any of these
   --  controls needs, and a value rounded to three prints as three.
   function Rounded (V : Float) return Float is
     (Float'Rounding (V * 1000.0) / 1000.0);

   procedure On_Speed (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
      V : constant Float := Rounded (Value);
   begin
      Speed := V;
      GL_Demo_UI.Float_Value.Set_Value (UI.Speed_Value, V);
   end On_Speed;

   procedure On_Speed_Value (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
      V : constant Float := Rounded (Value);
   begin
      Speed := V;
      GL_Demo_UI.Float_Slider.Set_Value (UI.Speed_Slider, V);
   end On_Speed_Value;

   procedure On_Scale (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
      V : constant Float := Rounded (Value);
   begin
      Scale := V;
      GL_Demo_UI.Float_Value.Set_Value (UI.Scale_Value, V);
   end On_Scale;

   procedure On_Scale_Value (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
      V : constant Float := Rounded (Value);
   begin
      Scale := V;
      GL_Demo_UI.Float_Slider.Set_Value (UI.Scale_Slider, V);
   end On_Scale_Value;

   procedure On_Hue (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
      V : constant Float := Rounded (Value);
   begin
      Hue := V;
      GL_Demo_UI.Float_Value.Set_Value (UI.Hue_Value, V);
   end On_Hue;

   procedure On_Hue_Value (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
      V : constant Float := Rounded (Value);
   begin
      Hue := V;
      GL_Demo_UI.Float_Slider.Set_Value (UI.Hue_Slider, V);
   end On_Hue_Value;

   procedure On_Spin (W : Adi.Widget.Widget_Handle; Active : Boolean) is
      pragma Unreferenced (W);
   begin
      Spinning := Active;
   end On_Spin;

   procedure On_Orbit (W : Adi.Widget.Widget_Handle; Active : Boolean) is
      pragma Unreferenced (W);
   begin
      Orbiting := Active;
   end On_Orbit;

   A : Adi.App.App;
   W : Adi.Window.Window_Handle;

begin
   --  Before the window: SDL reads the driver when it builds the
   --  renderer, and a GL texture cannot be handed to a D3D or Metal one.
   Adi.Window.Prefer_Render_Driver ("opengl");

   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   UI.On_Speed       := On_Speed'Unrestricted_Access;
   UI.On_Speed_Value := On_Speed_Value'Unrestricted_Access;
   UI.On_Scale       := On_Scale'Unrestricted_Access;
   UI.On_Scale_Value := On_Scale_Value'Unrestricted_Access;
   UI.On_Hue         := On_Hue'Unrestricted_Access;
   UI.On_Hue_Value   := On_Hue_Value'Unrestricted_Access;
   UI.On_Spin        := On_Spin'Unrestricted_Access;
   UI.On_Orbit       := On_Orbit'Unrestricted_Access;

   W := UI.Build;

   Adi.Widget.Html_View.Set_HTML (UI.Explain, Read_Asset ("explain.html"));
   Adi.Window.Connect_Frame (W, Draw_GL'Unrestricted_Access);
   Adi.Window.Connect_Close_Request (W, On_Close'Unrestricted_Access);

   Adi.MCP.Initialize (W);
   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end GL_Triangle;
