--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Unchecked_Conversion;

package body Adi_GL is

   use type System.Address;

   --  SDL already links into this program and knows which GL library the
   --  current context came from, so it is the portable way to reach an
   --  entry point the platform's import library does not export.
   function SDL_GL_GetProcAddress
     (Proc : Interfaces.C.Strings.chars_ptr) return System.Address
     with Import, Convention => C,
          External_Name => "SDL_GL_GetProcAddress";

   Any_Missing : Boolean := True;

   function Resolve (Name : String) return System.Address is
      use Interfaces.C.Strings;
      C_Name : chars_ptr := New_String (Name);
      Addr   : constant System.Address := SDL_GL_GetProcAddress (C_Name);
   begin
      Free (C_Name);
      if Addr = System.Null_Address then
         Any_Missing := True;
      end if;
      return Addr;
   end Resolve;

   generic
      type Fn is private;
   function Entry_Point (Name : String) return Fn;

   function Entry_Point (Name : String) return Fn is
      function To_Fn is new Ada.Unchecked_Conversion (System.Address, Fn);
   begin
      return To_Fn (Resolve (Name));
   end Entry_Point;

   ------------
   -- Loaded --
   ------------

   function Loaded return Boolean is (not Any_Missing);

   ----------
   -- Load --
   ----------

   procedure Load is
      function Gen_Names   is new Entry_Point (Gen_Names_Fn);
      function Bind_Target is new Entry_Point (Bind_Target_Fn);
      function Object      is new Entry_Point (Object_Fn);
      function Fb_Texture  is new Entry_Point (Framebuffer_Texture_Fn);
      function Buf_Data    is new Entry_Point (Buffer_Data_Fn);
      function Mk_Shader   is new Entry_Point (Create_Shader_Fn);
      function Mk_Program  is new Entry_Point (Create_Program_Fn);
      function Src         is new Entry_Point (Shader_Source_Fn);
      function Object_Iv   is new Entry_Point (Get_Object_Iv_Fn);
      function Info_Log    is new Entry_Point (Get_Info_Log_Fn);
      function Attach      is new Entry_Point (Attach_Shader_Fn);
      function Bind_Attrib is new Entry_Point (Bind_Attrib_Fn);
      function Attrib_Ptr  is new Entry_Point (Vertex_Attrib_Pointer_Fn);
   begin
      Any_Missing := False;

      glGenFramebuffers      := Gen_Names ("glGenFramebuffers");
      glDeleteFramebuffers   := Gen_Names ("glDeleteFramebuffers");
      glBindFramebuffer      := Bind_Target ("glBindFramebuffer");
      glFramebufferTexture2D := Fb_Texture ("glFramebufferTexture2D");

      glGenVertexArrays    := Gen_Names ("glGenVertexArrays");
      glDeleteVertexArrays := Gen_Names ("glDeleteVertexArrays");
      glBindVertexArray    := Object ("glBindVertexArray");

      glGenBuffers    := Gen_Names ("glGenBuffers");
      glDeleteBuffers := Gen_Names ("glDeleteBuffers");
      glBindBuffer    := Bind_Target ("glBindBuffer");
      glBufferData    := Buf_Data ("glBufferData");

      glCreateShader     := Mk_Shader ("glCreateShader");
      glShaderSource     := Src ("glShaderSource");
      glCompileShader    := Object ("glCompileShader");
      glGetShaderiv      := Object_Iv ("glGetShaderiv");
      glGetShaderInfoLog := Info_Log ("glGetShaderInfoLog");
      glDeleteShader     := Object ("glDeleteShader");

      glCreateProgram      := Mk_Program ("glCreateProgram");
      glAttachShader       := Attach ("glAttachShader");
      glLinkProgram        := Object ("glLinkProgram");
      glGetProgramiv       := Object_Iv ("glGetProgramiv");
      glBindAttribLocation := Bind_Attrib ("glBindAttribLocation");
      glUseProgram         := Object ("glUseProgram");

      glVertexAttribPointer      := Attrib_Ptr ("glVertexAttribPointer");
      glEnableVertexAttribArray  := Object ("glEnableVertexAttribArray");
      glDisableVertexAttribArray := Object ("glDisableVertexAttribArray");
   end Load;

end Adi_GL;
