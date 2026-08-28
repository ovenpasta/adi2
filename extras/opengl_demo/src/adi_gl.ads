--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Interfaces.C.Strings;
with System;

--  The slice of OpenGL this demo needs, bound by hand.
--
--  Entry points arrive two ways. OpenGL 1.0/1.1 is exported by
--  opengl32.dll on Windows and by libGL elsewhere, so it is imported
--  directly. Nothing later is exported by opengl32.dll, so importing it
--  the same way would fail to link there; those entry points are
--  access-to-subprogram variables that Load fills in from SDL.
package Adi_GL is

   --  Derived rather than subtypes, so that a client with a use clause
   --  on this package also gets the arithmetic on them.
   type GLenum     is new Interfaces.C.unsigned;
   type GLbitfield is new Interfaces.C.unsigned;
   type GLuint     is new Interfaces.C.unsigned;
   type GLint      is new Interfaces.C.int;
   type GLfloat    is new Interfaces.C.C_float;
   type GLboolean  is new Interfaces.C.unsigned_char;
   type GLsizeiptr is new Interfaces.C.ptrdiff_t;

   subtype GLsizei is GLint;

   --  Left as the C character type: glGetShaderInfoLog writes into an
   --  Interfaces.C.char_array.
   subtype GLchar is Interfaces.C.char;

   --  glVertexAttribPointer's last argument is typed as a pointer but
   --  read as a byte offset into the bound buffer.
   subtype GLoffset is GLsizeiptr;

   --  Aliased components: the glGet* entry points write through a
   --  pointer to the first one.
   type GLint_Array   is array (Natural range <>) of aliased GLint;
   type GLfloat_Array is array (Natural range <>) of aliased GLfloat;

   GL_FALSE : constant GLboolean := 0;
   GL_TRUE  : constant GLboolean := 1;

   GL_TRIANGLES         : constant GLenum := 16#0004#;
   GL_BACK              : constant GLenum := 16#0405#;
   GL_CW                : constant GLenum := 16#0900#;
   GL_CCW               : constant GLenum := 16#0901#;
   GL_CULL_FACE         : constant GLenum := 16#0B44#;
   GL_CULL_FACE_MODE    : constant GLenum := 16#0B45#;
   GL_FRONT_FACE        : constant GLenum := 16#0B46#;
   GL_DEPTH_TEST        : constant GLenum := 16#0B71#;
   GL_VIEWPORT          : constant GLenum := 16#0BA2#;
   GL_BLEND             : constant GLenum := 16#0BE2#;
   GL_SCISSOR_TEST      : constant GLenum := 16#0C11#;
   GL_COLOR_CLEAR_VALUE : constant GLenum := 16#0C22#;
   GL_TEXTURE_2D        : constant GLenum := 16#0DE1#;
   GL_UNSIGNED_BYTE     : constant GLenum := 16#1401#;
   GL_FLOAT             : constant GLenum := 16#1406#;
   GL_RGBA              : constant GLenum := 16#1908#;
   GL_LINEAR            : constant GLenum := 16#2601#;

   GL_TEXTURE_MAG_FILTER : constant GLenum := 16#2800#;
   GL_TEXTURE_MIN_FILTER : constant GLenum := 16#2801#;
   GL_TEXTURE_BINDING_2D : constant GLenum := 16#8069#;

   GL_VERTEX_ARRAY_BINDING : constant GLenum := 16#85B5#;
   GL_ARRAY_BUFFER         : constant GLenum := 16#8892#;
   GL_ARRAY_BUFFER_BINDING : constant GLenum := 16#8894#;
   GL_STREAM_DRAW          : constant GLenum := 16#88E0#;
   GL_FRAGMENT_SHADER      : constant GLenum := 16#8B30#;
   GL_VERTEX_SHADER        : constant GLenum := 16#8B31#;
   GL_COMPILE_STATUS       : constant GLenum := 16#8B81#;
   GL_LINK_STATUS          : constant GLenum := 16#8B82#;
   GL_CURRENT_PROGRAM      : constant GLenum := 16#8B8D#;
   GL_FRAMEBUFFER_BINDING  : constant GLenum := 16#8CA6#;
   GL_COLOR_ATTACHMENT0    : constant GLenum := 16#8CE0#;
   GL_FRAMEBUFFER          : constant GLenum := 16#8D40#;

   GL_COLOR_BUFFER_BIT : constant GLbitfield := 16#0000_4000#;

   ---------------------------------------------------------------------
   --  OpenGL 1.0/1.1
   ---------------------------------------------------------------------

   procedure glGenTextures (N : GLsizei; Names : access GLuint)
     with Import, Convention => C, External_Name => "glGenTextures";

   procedure glDeleteTextures (N : GLsizei; Names : access GLuint)
     with Import, Convention => C, External_Name => "glDeleteTextures";

   procedure glBindTexture (Target : GLenum; Texture : GLuint)
     with Import, Convention => C, External_Name => "glBindTexture";

   procedure glTexImage2D
     (Target          : GLenum;
      Level           : GLint;
      Internal_Format : GLint;
      Width, Height   : GLsizei;
      Border          : GLint;
      Format          : GLenum;
      Data_Type       : GLenum;
      Data            : System.Address)
     with Import, Convention => C, External_Name => "glTexImage2D";

   procedure glTexParameteri
     (Target : GLenum; Pname : GLenum; Param : GLint)
     with Import, Convention => C, External_Name => "glTexParameteri";

   procedure glViewport (X, Y : GLint; Width, Height : GLsizei)
     with Import, Convention => C, External_Name => "glViewport";

   procedure glCullFace (Mode : GLenum)
     with Import, Convention => C, External_Name => "glCullFace";

   procedure glFrontFace (Mode : GLenum)
     with Import, Convention => C, External_Name => "glFrontFace";

   procedure glClearColor (Red, Green, Blue, Alpha : GLfloat)
     with Import, Convention => C, External_Name => "glClearColor";

   procedure glClear (Mask : GLbitfield)
     with Import, Convention => C, External_Name => "glClear";

   procedure glDrawArrays (Mode : GLenum; First : GLint; Count : GLsizei)
     with Import, Convention => C, External_Name => "glDrawArrays";

   procedure glGetIntegerv (Pname : GLenum; Data : access GLint)
     with Import, Convention => C, External_Name => "glGetIntegerv";

   procedure glGetFloatv (Pname : GLenum; Data : access GLfloat)
     with Import, Convention => C, External_Name => "glGetFloatv";

   function glIsEnabled (Cap : GLenum) return GLboolean
     with Import, Convention => C, External_Name => "glIsEnabled";

   procedure glEnable (Cap : GLenum)
     with Import, Convention => C, External_Name => "glEnable";

   procedure glDisable (Cap : GLenum)
     with Import, Convention => C, External_Name => "glDisable";

   procedure glFinish
     with Import, Convention => C, External_Name => "glFinish";

   ---------------------------------------------------------------------
   --  Loaded at run time
   ---------------------------------------------------------------------

   type Gen_Names_Fn is access procedure (N : GLsizei; Names : access GLuint)
     with Convention => C;

   type Bind_Target_Fn is access procedure (Target : GLenum; Name : GLuint)
     with Convention => C;

   type Object_Fn is access procedure (Name : GLuint)
     with Convention => C;

   type Framebuffer_Texture_Fn is access procedure
     (Target     : GLenum;
      Attachment : GLenum;
      Tex_Target : GLenum;
      Texture    : GLuint;
      Level      : GLint)
     with Convention => C;

   type Buffer_Data_Fn is access procedure
     (Target : GLenum;
      Size   : GLsizeiptr;
      Data   : System.Address;
      Usage  : GLenum)
     with Convention => C;

   type Create_Shader_Fn is access function
     (Shader_Type : GLenum) return GLuint
     with Convention => C;

   type Create_Program_Fn is access function return GLuint
     with Convention => C;

   type Shader_Source_Fn is access procedure
     (Shader  : GLuint;
      Count   : GLsizei;
      Strings : access Interfaces.C.Strings.chars_ptr;
      Lengths : access GLint)
     with Convention => C;

   type Get_Object_Iv_Fn is access procedure
     (Name : GLuint; Pname : GLenum; Params : access GLint)
     with Convention => C;

   type Get_Info_Log_Fn is access procedure
     (Name     : GLuint;
      Max_Size : GLsizei;
      Length   : access GLsizei;
      Log      : access GLchar)
     with Convention => C;

   type Attach_Shader_Fn is access procedure (Program, Shader : GLuint)
     with Convention => C;

   type Bind_Attrib_Fn is access procedure
     (Program : GLuint;
      Index   : GLuint;
      Name    : Interfaces.C.Strings.chars_ptr)
     with Convention => C;

   type Vertex_Attrib_Pointer_Fn is access procedure
     (Index      : GLuint;
      Size       : GLint;
      Data_Type  : GLenum;
      Normalized : GLboolean;
      Stride     : GLsizei;
      Offset     : GLoffset)
     with Convention => C;

   glGenFramebuffers      : Gen_Names_Fn;
   glDeleteFramebuffers   : Gen_Names_Fn;
   glBindFramebuffer      : Bind_Target_Fn;
   glFramebufferTexture2D : Framebuffer_Texture_Fn;

   glGenVertexArrays    : Gen_Names_Fn;
   glDeleteVertexArrays : Gen_Names_Fn;
   glBindVertexArray    : Object_Fn;

   glGenBuffers    : Gen_Names_Fn;
   glDeleteBuffers : Gen_Names_Fn;
   glBindBuffer    : Bind_Target_Fn;
   glBufferData    : Buffer_Data_Fn;

   glCreateShader     : Create_Shader_Fn;
   glShaderSource     : Shader_Source_Fn;
   glCompileShader    : Object_Fn;
   glGetShaderiv      : Get_Object_Iv_Fn;
   glGetShaderInfoLog : Get_Info_Log_Fn;
   glDeleteShader     : Object_Fn;

   glCreateProgram      : Create_Program_Fn;
   glAttachShader       : Attach_Shader_Fn;
   glLinkProgram        : Object_Fn;
   glGetProgramiv       : Get_Object_Iv_Fn;
   glBindAttribLocation : Bind_Attrib_Fn;
   glUseProgram         : Object_Fn;
   glDeleteProgram      : Object_Fn;

   glVertexAttribPointer      : Vertex_Attrib_Pointer_Fn;
   glEnableVertexAttribArray  : Object_Fn;
   glDisableVertexAttribArray : Object_Fn;

   --  Call with a GL context current. On Windows the resolved addresses
   --  belong to that context, so a renderer recreated later leaves them
   --  stale and Load has to run again.
   procedure Load;

   --  False until Load has resolved every entry point above.
   function Loaded return Boolean;

   --  The first entry point Load could not resolve, for the message a
   --  caller gives when Loaded is False. Empty once everything resolved.
   function Missing_Entry_Point return String;

end Adi_GL;
