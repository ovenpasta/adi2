--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Interfaces.C;            use Interfaces.C;
with Interfaces.C.Strings;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
with System;
package Adi.SDL is

    subtype Uint8 is Unsigned_8;
    subtype Uint16 is Unsigned_16;
    subtype Uint32 is Unsigned_32;
    subtype Uint64 is Unsigned_64;
    subtype Sint16 is Signed_16;
    subtype Sint32 is Signed_32;
    subtype C_bool is Interfaces.C.C_bool;

    type SDL_Rect is record
        x : aliased int;  -- /usr/include/SDL3/SDL_rect.h:85
        y : aliased int;  -- /usr/include/SDL3/SDL_rect.h:85
        w : aliased int;  -- /usr/include/SDL3/SDL_rect.h:86
        h : aliased int;  -- /usr/include/SDL3/SDL_rect.h:86
    end record with
       Convention => C_Pass_By_Copy;  -- /usr/include/SDL3/SDL_rect.h:83

    type SDL_FRect is record
        x : aliased Float;  -- /usr/include/SDL3/SDL_rect.h:108
        y : aliased Float;  -- /usr/include/SDL3/SDL_rect.h:109
        w : aliased Float;  -- /usr/include/SDL3/SDL_rect.h:110
        h : aliased Float;  -- /usr/include/SDL3/SDL_rect.h:111
    end record with
       Convention => C_Pass_By_Copy;  -- /usr/include/SDL3/SDL_rect.h:106

    type SDL_FPoint is record
        x : aliased Float;
        y : aliased Float;
    end record with
       Convention => C_Pass_By_Copy;

    type SDL_FColor is record
        r : aliased Float;
        g : aliased Float;
        b : aliased Float;
        a : aliased Float;
    end record with
       Convention => C_Pass_By_Copy;

    type SDL_InitFlags is new Interfaces.Unsigned_32;
    SDL_INIT_AUDIO    : constant SDL_InitFlags :=
       16#0000_0010#;  --  /usr/include/SDL3/SDL_init.h:80
    SDL_INIT_VIDEO    : constant SDL_InitFlags :=
       16#0000_0020#;  --  /usr/include/SDL3/SDL_init.h:81
    SDL_INIT_JOYSTICK : constant SDL_InitFlags :=
       16#0000_0200#;  --  /usr/include/SDL3/SDL_init.h:82
    SDL_INIT_HAPTIC   : constant SDL_InitFlags :=
       16#0000_1000#;  --  /usr/include/SDL3/SDL_init.h:83
    SDL_INIT_GAMEPAD  : constant SDL_InitFlags :=
       16#0000_2000#;  --  /usr/include/SDL3/SDL_init.h:84
    SDL_INIT_EVENTS   : constant SDL_InitFlags :=
       16#0000_4000#;  --  /usr/include/SDL3/SDL_init.h:85
    SDL_INIT_SENSOR   : constant SDL_InitFlags :=
       16#0000_8000#;  --  /usr/include/SDL3/SDL_init.h:86
    SDL_INIT_CAMERA   : constant SDL_InitFlags :=
       16#0001_0000#;  --  /usr/include/SDL3/SDL_init.h:87

    function SDL_Init
       (flags : SDL_InitFlags)
        return C_bool  -- /usr/include/SDL3/SDL_init.h:236
    with
       Import => True, Convention => C, External_Name => "SDL_Init";

    ---------------------------------------------------------------------------
    --  SDL Error Handling
    ---------------------------------------------------------------------------

    --  Get the last SDL error message
    function SDL_GetError return Interfaces.C.Strings.chars_ptr
    with Import => True,
         Convention => C,
         External_Name => "SDL_GetError";

    --  Clear the last SDL error
    function SDL_ClearError return C_bool
    with Import => True,
         Convention => C,
         External_Name => "SDL_ClearError";

    ---------------------------------------------------------------------------
    --  SDL Clipboard
    ---------------------------------------------------------------------------

    function SDL_SetClipboardText
      (Text : Interfaces.C.Strings.chars_ptr) return C_bool
    with Import        => True,
         Convention    => C,
         External_Name => "SDL_SetClipboardText";

    function SDL_GetClipboardText return Interfaces.C.Strings.chars_ptr
    with Import        => True,
         Convention    => C,
         External_Name => "SDL_GetClipboardText";

    function SDL_HasClipboardText return C_bool
    with Import        => True,
         Convention    => C,
         External_Name => "SDL_HasClipboardText";

    procedure SDL_free (Mem : Interfaces.C.Strings.chars_ptr)
    with Import        => True,
         Convention    => C,
         External_Name => "SDL_free";

    procedure SDL_free (Mem : System.Address)
    with Import        => True,
         Convention    => C,
         External_Name => "SDL_free";

    ---------------------------------------------------------------------------
    --  SDL Helper Utilities
    ---------------------------------------------------------------------------

    --  Assert helper for SDL functions that return C_bool
    --  Uses pragma Assert to check the result and provide meaningful error messages
    procedure SDL_Assert (Result : C_bool; Func_Name : String);

end Adi.SDL;
