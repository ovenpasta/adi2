--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.SDL.TTF;
with Adi.SDL.Render;
with Interfaces.C.Strings;
with System;

package Adi.SDL.TTF.TextEngine is

   ----------------------------------------------------------------------------
   -- Draw Commands
   ----------------------------------------------------------------------------

   type TTF_DrawCommand is (
      TTF_DRAW_COMMAND_NOOP,
      TTF_DRAW_COMMAND_FILL,
      TTF_DRAW_COMMAND_COPY
   ) with Convention => C;

   ----------------------------------------------------------------------------
   -- Draw Operations
   ----------------------------------------------------------------------------

   type SDL_Rect is record
      x : int;
      y : int;
      w : int;
      h : int;
   end record with Convention => C_Pass_By_Copy;

   type TTF_FillOperation is record
      cmd  : aliased TTF_DrawCommand;
      rect : aliased SDL_Rect;
   end record with Convention => C_Pass_By_Copy;

   type TTF_CopyOperation is record
      cmd         : aliased TTF_DrawCommand;
      text_offset : aliased int;
      glyph_font  : TTF_Font_Access;
      glyph_index : aliased Uint32;
      src         : aliased SDL_Rect;
      dst         : aliased SDL_Rect;
      reserved    : System.Address;
   end record with Convention => C_Pass_By_Copy;

   type TTF_DrawOperation (discr : unsigned := 0) is record
      case discr is
         when 0 =>
            cmd  : aliased TTF_DrawCommand;
         when 1 =>
            fill : aliased TTF_FillOperation;
         when others =>
            copy : aliased TTF_CopyOperation;
      end case;
   end record with Convention => C_Pass_By_Copy, Unchecked_Union => True;

   ----------------------------------------------------------------------------
   -- Text Layout and Data
   ----------------------------------------------------------------------------

   type TTF_TextLayout is limited null record;
   type TTF_TextLayout_Access is access all TTF_TextLayout;

   type TTF_SubString is record
      offset      : aliased int;
      length      : aliased int;
      line_index  : aliased int;
      cluster_index : aliased int;
      rect        : aliased SDL_Rect;
   end record with Convention => C_Pass_By_Copy;

   type TTF_SubString_Access is access all TTF_SubString;
   type TTF_DrawOperation_Access is access all TTF_DrawOperation;

   type TTF_Text is limited null record;
   type TTF_Text_Access is access all TTF_Text;

   type TTF_TextEngine;
   type TTF_TextEngine_Access is access all TTF_TextEngine;

   type TTF_TextData is record
      font                : TTF_Font_Access;
      color               : aliased SDL_FColor;
      needs_layout_update : aliased C_bool;
      layout              : TTF_TextLayout_Access;
      x                   : aliased int;
      y                   : aliased int;
      w                   : aliased int;
      h                   : aliased int;
      num_ops             : aliased int;
      ops                 : TTF_DrawOperation_Access;
      num_clusters        : aliased int;
      clusters            : TTF_SubString_Access;
      props               : aliased Uint32;  -- SDL_PropertiesID
      needs_engine_update : aliased C_bool;
      engine              : TTF_TextEngine_Access;
      engine_text         : System.Address;
   end record with Convention => C_Pass_By_Copy;

   ----------------------------------------------------------------------------
   -- Text Engine Callbacks
   ----------------------------------------------------------------------------

   type CreateText_Callback is access function
      (userdata : System.Address;
       text     : TTF_Text_Access) return C_bool
      with Convention => C;

   type DestroyText_Callback is access procedure
      (userdata : System.Address;
       text     : TTF_Text_Access)
      with Convention => C;

   type TTF_TextEngine is record
      version     : aliased Uint32;
      userdata    : System.Address;
      CreateText  : CreateText_Callback;
      DestroyText : DestroyText_Callback;
   end record with Convention => C_Pass_By_Copy;

   ----------------------------------------------------------------------------
   -- Text Engine Creation and Management
   ----------------------------------------------------------------------------

   function TTF_CreateRendererTextEngine
      (renderer : Adi.SDL.Render.SDL_Renderer_Ptr) return TTF_TextEngine_Access
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_CreateRendererTextEngine";

   procedure TTF_DestroyRendererTextEngine
      (engine : TTF_TextEngine_Access)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_DestroyRendererTextEngine";

   ----------------------------------------------------------------------------
   -- Text Object Creation and Management
   ----------------------------------------------------------------------------

   function TTF_CreateText
      (engine : TTF_TextEngine_Access;
       font   : TTF_Font_Access;
       text   : Interfaces.C.Strings.chars_ptr;
       length : Interfaces.C.size_t) return TTF_Text_Access
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_CreateText";

   procedure TTF_DestroyText
      (text : TTF_Text_Access)
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_DestroyText";

   ----------------------------------------------------------------------------
   -- Text Configuration
   ----------------------------------------------------------------------------

   function TTF_SetTextFont
      (text : TTF_Text_Access;
       font : TTF_Font_Access) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetTextFont";

   function TTF_SetTextColor
      (text : TTF_Text_Access;
       r    : Uint8;
       g    : Uint8;
       b    : Uint8;
       a    : Uint8) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetTextColor";

   function TTF_SetTextColorFloat
      (text : TTF_Text_Access;
       r    : C_float;
       g    : C_float;
       b    : C_float;
       a    : C_float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetTextColorFloat";

   function TTF_SetTextString
      (text   : TTF_Text_Access;
       string : Interfaces.C.Strings.chars_ptr;
       length : Interfaces.C.size_t) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetTextString";

   function TTF_SetTextPosition
      (text : TTF_Text_Access;
       x    : int;
       y    : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetTextPosition";

   function TTF_SetTextWrapWidth
      (text       : TTF_Text_Access;
       wrap_width : int) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_SetTextWrapWidth";

   ----------------------------------------------------------------------------
   -- Text Rendering
   ----------------------------------------------------------------------------

   function TTF_DrawRendererText
      (text : TTF_Text_Access;
       x    : C_float;
       y    : C_float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "TTF_DrawRendererText";

end Adi.SDL.TTF.TextEngine;
