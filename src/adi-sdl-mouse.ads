--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Interfaces.C.Strings;
with Adi.SDL.Video;   use Adi.SDL.Video;
with Adi.SDL.Surface; use Adi.SDL.Surface;

package Adi.SDL.Mouse is

   ----------------------------------------------------------------------------
   -- Type Definitions
   ----------------------------------------------------------------------------

   subtype SDL_MouseID is Uint32;

   type SDL_Cursor is limited null record;
   type SDL_Cursor_Access is access all SDL_Cursor;

   subtype SDL_MouseButtonFlags is Uint32;

   ----------------------------------------------------------------------------
   -- Mouse Button Constants
   ----------------------------------------------------------------------------

   SDL_BUTTON_LEFT   : constant := 1;
   SDL_BUTTON_MIDDLE : constant := 2;
   SDL_BUTTON_RIGHT  : constant := 3;
   SDL_BUTTON_X1     : constant := 4;
   SDL_BUTTON_X2     : constant := 5;

   -- Button masks
   function SDL_BUTTON_MASK (X : Natural) return SDL_MouseButtonFlags is
      (SDL_MouseButtonFlags (2 ** (X - 1)));

   SDL_BUTTON_LMASK  : constant SDL_MouseButtonFlags := SDL_BUTTON_MASK (SDL_BUTTON_LEFT);
   SDL_BUTTON_MMASK  : constant SDL_MouseButtonFlags := SDL_BUTTON_MASK (SDL_BUTTON_MIDDLE);
   SDL_BUTTON_RMASK  : constant SDL_MouseButtonFlags := SDL_BUTTON_MASK (SDL_BUTTON_RIGHT);
   SDL_BUTTON_X1MASK : constant SDL_MouseButtonFlags := SDL_BUTTON_MASK (SDL_BUTTON_X1);
   SDL_BUTTON_X2MASK : constant SDL_MouseButtonFlags := SDL_BUTTON_MASK (SDL_BUTTON_X2);

   ----------------------------------------------------------------------------
   -- Enumerations
   ----------------------------------------------------------------------------

   type SDL_SystemCursor is (
      SDL_SYSTEM_CURSOR_DEFAULT,
      SDL_SYSTEM_CURSOR_TEXT,
      SDL_SYSTEM_CURSOR_WAIT,
      SDL_SYSTEM_CURSOR_CROSSHAIR,
      SDL_SYSTEM_CURSOR_PROGRESS,
      SDL_SYSTEM_CURSOR_NWSE_RESIZE,
      SDL_SYSTEM_CURSOR_NESW_RESIZE,
      SDL_SYSTEM_CURSOR_EW_RESIZE,
      SDL_SYSTEM_CURSOR_NS_RESIZE,
      SDL_SYSTEM_CURSOR_MOVE,
      SDL_SYSTEM_CURSOR_NOT_ALLOWED,
      SDL_SYSTEM_CURSOR_POINTER,
      SDL_SYSTEM_CURSOR_NW_RESIZE,
      SDL_SYSTEM_CURSOR_N_RESIZE,
      SDL_SYSTEM_CURSOR_NE_RESIZE,
      SDL_SYSTEM_CURSOR_E_RESIZE,
      SDL_SYSTEM_CURSOR_SE_RESIZE,
      SDL_SYSTEM_CURSOR_S_RESIZE,
      SDL_SYSTEM_CURSOR_SW_RESIZE,
      SDL_SYSTEM_CURSOR_W_RESIZE,
      SDL_SYSTEM_CURSOR_COUNT
   ) with Convention => C;

   type SDL_MouseWheelDirection is (
      SDL_MOUSEWHEEL_NORMAL,
      SDL_MOUSEWHEEL_FLIPPED
   ) with Convention => C;

   ----------------------------------------------------------------------------
   -- Mouse Detection and Enumeration
   ----------------------------------------------------------------------------

   function SDL_HasMouse return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_HasMouse";

   function SDL_GetMice (Count : access int) return access SDL_MouseID
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetMice";

   function SDL_GetMouseNameForID
      (Instance_ID : SDL_MouseID) return Interfaces.C.Strings.chars_ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetMouseNameForID";

   ----------------------------------------------------------------------------
   -- Mouse State Queries
   ----------------------------------------------------------------------------

   function SDL_GetMouseFocus return SDL_Window_Ptr
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetMouseFocus";

   function SDL_GetMouseState
      (X : access Float;
       Y : access Float) return SDL_MouseButtonFlags
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetMouseState";

   function SDL_GetGlobalMouseState
      (X : access Float;
       Y : access Float) return SDL_MouseButtonFlags
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetGlobalMouseState";

   function SDL_GetRelativeMouseState
      (X : access Float;
       Y : access Float) return SDL_MouseButtonFlags
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetRelativeMouseState";

   ----------------------------------------------------------------------------
   -- Mouse Warping
   ----------------------------------------------------------------------------

   procedure SDL_WarpMouseInWindow
      (Window : SDL_Window_Ptr;
       X      : Float;
       Y      : Float)
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_WarpMouseInWindow";

   function SDL_WarpMouseGlobal
      (X : Float;
       Y : Float) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_WarpMouseGlobal";

   ----------------------------------------------------------------------------
   -- Relative Mouse Mode
   ----------------------------------------------------------------------------

   function SDL_SetWindowRelativeMouseMode
      (Window  : SDL_Window_Ptr;
       Enabled : C_bool) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetWindowRelativeMouseMode";

   function SDL_GetWindowRelativeMouseMode
      (Window : SDL_Window_Ptr) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetWindowRelativeMouseMode";

   ----------------------------------------------------------------------------
   -- Mouse Capture
   ----------------------------------------------------------------------------

   function SDL_CaptureMouse (Enabled : C_bool) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CaptureMouse";

   ----------------------------------------------------------------------------
   -- Cursor Creation
   ----------------------------------------------------------------------------

   function SDL_CreateCursor
      (Data  : access Uint8;
       Mask  : access Uint8;
       W     : int;
       H     : int;
       Hot_X : int;
       Hot_Y : int) return SDL_Cursor_Access
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateCursor";

   function SDL_CreateColorCursor
      (Surface : access SDL_Surface;
       Hot_X   : int;
       Hot_Y   : int) return SDL_Cursor_Access
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateColorCursor";

   function SDL_CreateSystemCursor
      (ID : SDL_SystemCursor) return SDL_Cursor_Access
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CreateSystemCursor";

   ----------------------------------------------------------------------------
   -- Cursor Management
   ----------------------------------------------------------------------------

   function SDL_SetCursor (Cursor : SDL_Cursor_Access) return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_SetCursor";

   function SDL_GetCursor return SDL_Cursor_Access
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetCursor";

   function SDL_GetDefaultCursor return SDL_Cursor_Access
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_GetDefaultCursor";

   procedure SDL_DestroyCursor (Cursor : SDL_Cursor_Access)
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_DestroyCursor";

   ----------------------------------------------------------------------------
   -- Cursor Visibility
   ----------------------------------------------------------------------------

   function SDL_ShowCursor return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_ShowCursor";

   function SDL_HideCursor return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_HideCursor";

   function SDL_CursorVisible return C_bool
      with Import        => True,
           Convention    => C,
           External_Name => "SDL_CursorVisible";

end Adi.SDL.Mouse;
