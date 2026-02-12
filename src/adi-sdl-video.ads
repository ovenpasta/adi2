with Adi.SDL.Surface; use Adi.SDL.Surface;
package Adi.SDL.Video is

   -- Use 64-bit modular type for bit flags
   type SDL_WindowFlags is new Interfaces.Unsigned_64;

   -- Individual flag constants
   SDL_WINDOW_FULLSCREEN          : constant SDL_WindowFlags :=
     16#0000000000000001#;
   SDL_WINDOW_OPENGL              : constant SDL_WindowFlags :=
     16#0000000000000002#;
   SDL_WINDOW_OCCLUDED            : constant SDL_WindowFlags :=
     16#0000000000000004#;
   SDL_WINDOW_HIDDEN              : constant SDL_WindowFlags :=
     16#0000000000000008#;
   SDL_WINDOW_BORDERLESS          : constant SDL_WindowFlags :=
     16#0000000000000010#;
   SDL_WINDOW_RESIZABLE           : constant SDL_WindowFlags :=
     16#0000000000000020#;
   SDL_WINDOW_MINIMIZED           : constant SDL_WindowFlags :=
     16#0000000000000040#;
   SDL_WINDOW_MAXIMIZED           : constant SDL_WindowFlags :=
     16#0000000000000080#;
   SDL_WINDOW_MOUSE_GRABBED       : constant SDL_WindowFlags :=
     16#0000000000000100#;
   SDL_WINDOW_INPUT_FOCUS         : constant SDL_WindowFlags :=
     16#0000000000000200#;
   SDL_WINDOW_MOUSE_FOCUS         : constant SDL_WindowFlags :=
     16#0000000000000400#;
   SDL_WINDOW_EXTERNAL            : constant SDL_WindowFlags :=
     16#0000000000000800#;
   SDL_WINDOW_MODAL               : constant SDL_WindowFlags :=
     16#0000000000001000#;
   SDL_WINDOW_HIGH_PIXEL_DENSITY  : constant SDL_WindowFlags :=
     16#0000000000002000#;
   SDL_WINDOW_MOUSE_CAPTURE       : constant SDL_WindowFlags :=
     16#0000000000004000#;
   SDL_WINDOW_MOUSE_RELATIVE_MODE : constant SDL_WindowFlags :=
     16#0000000000008000#;
   SDL_WINDOW_ALWAYS_ON_TOP       : constant SDL_WindowFlags :=
     16#0000000000010000#;
   SDL_WINDOW_UTILITY             : constant SDL_WindowFlags :=
     16#0000000000020000#;
   SDL_WINDOW_TOOLTIP             : constant SDL_WindowFlags :=
     16#0000000000040000#;
   SDL_WINDOW_POPUP_MENU          : constant SDL_WindowFlags :=
     16#0000000000080000#;
   SDL_WINDOW_KEYBOARD_GRABBED    : constant SDL_WindowFlags :=
     16#0000000000100000#;
   SDL_WINDOW_VULKAN              : constant SDL_WindowFlags :=
     16#0000000010000000#;
   SDL_WINDOW_METAL               : constant SDL_WindowFlags :=
     16#0000000020000000#;
   SDL_WINDOW_TRANSPARENT         : constant SDL_WindowFlags :=
     16#0000000040000000#;
   SDL_WINDOW_NOT_FOCUSABLE       : constant SDL_WindowFlags :=
     16#0000000080000000#;

   type SDL_Window is limited null record;   -- incomplete struct
   type SDL_Window_Ptr is access all SDL_Window;
	   
   function SDL_CreateWindow
     (title : Interfaces.C.Strings.chars_ptr;
      w     : int;
      h     : int;
      flags : SDL_WindowFlags)
      return access SDL_Window  -- /usr/include/SDL3/SDL_video.h:1129
   with Import => True, Convention => C, External_Name => "SDL_CreateWindow";
   
   
   function SDL_CreatePopupWindow
     (parent : access SDL_Window;
      offset_x : int;
      offset_y : int;
      w : int;
      h : int;
      flags : SDL_WindowFlags) return access SDL_Window  -- /usr/include/SDL3/SDL_video.h:1204
     with Import => True, 
          Convention => C, 
          External_Name => "SDL_CreatePopupWindow";

   function SDL_GetWindowSurface (window : access SDL_Window) return access SDL_Surface  -- /usr/include/SDL3/SDL_video.h:2310
   with Import => True, 
        Convention => C, 
        External_Name => "SDL_GetWindowSurface";
   
   function SDL_UpdateWindowSurface (window : access SDL_Window) return Extensions.bool  -- /usr/include/SDL3/SDL_video.h:2377
   with Import => True,
        Convention => C,
        External_Name => "SDL_UpdateWindowSurface";

   function SDL_GetWindowSize
      (window : SDL_Window_Ptr;
       w      : access int;
       h      : access int) return C_bool
   with Import => True,
        Convention => C,
        External_Name => "SDL_GetWindowSize";

   function SDL_GetWindowSizeInPixels
      (window : SDL_Window_Ptr;
       w      : access int;
       h      : access int) return C_bool
   with Import => True,
        Convention => C,
        External_Name => "SDL_GetWindowSizeInPixels";

   function SDL_GetWindowDisplayScale
      (window : SDL_Window_Ptr) return Float
   with Import => True,
        Convention => C,
        External_Name => "SDL_GetWindowDisplayScale";

   function SDL_SetWindowMinimumSize
      (window : SDL_Window_Ptr;
       min_w  : int;
       min_h  : int) return C_bool
   with Import => True,
        Convention => C,
        External_Name => "SDL_SetWindowMinimumSize";

   function SDL_StartTextInput (window : SDL_Window_Ptr) return C_bool
   with Import => True,
        Convention => C,
        External_Name => "SDL_StartTextInput";

   function SDL_StopTextInput (window : SDL_Window_Ptr) return C_bool
   with Import => True,
        Convention => C,
        External_Name => "SDL_StopTextInput";

   procedure SDL_DestroyWindow (window : SDL_Window_Ptr)
   with Import => True,
        Convention => C,
        External_Name => "SDL_DestroyWindow";

end Adi.SDL.Video;
