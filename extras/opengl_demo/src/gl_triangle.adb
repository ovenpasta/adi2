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
with Adi.SDL;
with Adi.SDL.Render;
with Adi.Widget;
with Adi.Widget.Html_View;
with Adi.Widget.Texture_View;
with Adi.Window;

with Adi_GL;

with GL_Demo_UI;

--  A triangle drawn by OpenGL into a texture Adi never touches, shown as
--  a widget and driven by ordinary Adi controls.
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

   Tex_W : constant := 1024;
   Tex_H : constant := 1024;

   Tex  : aliased GLuint := 0;
   FBO  : aliased GLuint := 0;
   VAO  : aliased GLuint := 0;
   VBO  : aliased GLuint := 0;
   Prog : GLuint := 0;

   Ready : Boolean := False;
   Angle : Float := 0.0;

   --  Read whole rather than bundled: the demo is meant to be edited
   --  while it runs.
   function Read_Asset (Name : String) return String is
      use Ada.Streams.Stream_IO;

      function Locate return String is
        (if Ada.Directories.Exists ("demo/assets/" & Name)
         then "demo/assets/" & Name
         else "assets/" & Name);

      Path : constant String := Locate;
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
            raise Program_Error with To_Ada (Log);
         end;
      end if;
      return Id;
   end Make_Shader;

   --  Written by the controls, read by the GL callback.
   Speed    : Float   := 0.6;
   Scale    : Float   := 0.72;
   Spinning : Boolean := True;

   ------------------
   -- GL rendering --
   ------------------
   procedure Draw_GL (Win : Adi.Window.Window_Handle) is
      Sc : constant GLfloat := GLfloat (Scale);

      Saved_Clear    : GLfloat_Array (0 .. 3) := [others => 0.0];
      Saved_Viewport : GLint_Array (0 .. 3)   := [others => 0];
      Saved_Program  : aliased GLint := 0;
      Saved_FBO      : aliased GLint := 0;
      Saved_Texture  : aliased GLint := 0;
      Saved_VAO      : aliased GLint := 0;
      Unused         : Adi.SDL.C_bool;

      --  Scissor above all: SDL leaves it enabled with a rect in window
      --  coordinates, which would clip drawing into a texture that has
      --  no relation to the window at all.
      Toggles : constant array (Positive range <>) of GLenum :=
        [GL_SCISSOR_TEST, GL_DEPTH_TEST, GL_CULL_FACE, GL_BLEND];
      Was_On  : array (Toggles'Range) of GLboolean := [others => GL_FALSE];
   begin
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

      if not Ready then
         --  Resolves the post-1.1 entry points against the live context.
         Adi_GL.Load;
         if not Adi_GL.Loaded then
            raise Program_Error with "OpenGL entry point unavailable";
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
            if Status = 0 then
               raise Program_Error with "shader program did not link";
            end if;

            glDeleteShader (VS);
            glDeleteShader (FS);
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

      glBindFramebuffer (GL_FRAMEBUFFER, FBO);
      glViewport (0, 0, Tex_W, Tex_H);

      for I in Toggles'Range loop
         Was_On (I) := glIsEnabled (Toggles (I));
         glDisable (Toggles (I));
      end loop;

      glClearColor (0.99, 0.99, 1.0, 1.0);
      glClear (GL_COLOR_BUFFER_BIT);

      declare
         S1 : constant GLfloat := GLfloat (Sin (Angle));
         C1 : constant GLfloat := GLfloat (Cos (Angle));
         --  x, y, r, g, b per vertex.
         Verts : constant GLfloat_Array :=
           [C1 * Sc,  S1 * Sc,  0.93, 0.29, 0.36,
            -S1 * Sc, C1 * Sc,  0.20, 0.72, 0.47,
            -C1 * Sc, -S1 * Sc, 0.23, 0.51, 0.96];
         Unit   : constant GLsizei := GLfloat'Size / System.Storage_Unit;
         Stride : constant GLsizei := 5 * Unit;
      begin
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

         glDrawArrays (GL_TRIANGLES, 0, 3);

         glDisableVertexAttribArray (0);
         glDisableVertexAttribArray (1);
         glBindBuffer (GL_ARRAY_BUFFER, 0);
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

      --  Flush on the way out as well as in. The call drops SDL's cached
      --  state, and the state worth dropping is what this callback just
      --  changed -- doing it only on entry invalidates a cache that was
      --  still accurate and leaves the dirtied one in place.
      Unused := Adi.SDL.Render.SDL_FlushRenderer
        (Adi.Window.Get_Renderer (Win));
   end Draw_GL;

   --------------
   -- Controls --
   --------------
   procedure On_Speed (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Speed := Value;
      GL_Demo_UI.Float_Value.Set_Value (UI.Speed_Value, Value);
   end On_Speed;

   procedure On_Speed_Value (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Speed := Value;
      GL_Demo_UI.Float_Slider.Set_Value (UI.Speed_Slider, Value);
   end On_Speed_Value;

   procedure On_Scale (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Scale := Value;
      GL_Demo_UI.Float_Value.Set_Value (UI.Scale_Value, Value);
   end On_Scale;

   procedure On_Scale_Value (W : Adi.Widget.Widget_Handle; Value : Float) is
      pragma Unreferenced (W);
   begin
      Scale := Value;
      GL_Demo_UI.Float_Slider.Set_Value (UI.Scale_Slider, Value);
   end On_Scale_Value;

   procedure On_Spin (W : Adi.Widget.Widget_Handle; Active : Boolean) is
      pragma Unreferenced (W);
   begin
      Spinning := Active;
   end On_Spin;

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
   UI.On_Spin        := On_Spin'Unrestricted_Access;

   W := UI.Build;

   Adi.Widget.Html_View.Set_HTML (UI.Explain, Read_Asset ("explain.html"));
   Adi.Window.Connect_Frame (W, Draw_GL'Unrestricted_Access);

   Adi.MCP.Initialize (W);
   A.Add_Window (W);
   A.Run;
   Adi.MCP.Finalize;
end GL_Triangle;
