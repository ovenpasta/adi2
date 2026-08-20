--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0


pragma Ada_2022;

package Adi.SDL.Events is


   type SDL_EventType is new Uint32;
   type SDL_DisplayID is new Uint32;
   type SDL_WindowID is new Uint32;
   type SDL_KeyboardID is new Uint32;
   type SDL_MouseID is new Uint32;
   type SDL_JoystickID is new Uint32;
   type SDL_AudioDeviceID is new Uint32;
   type SDL_CameraID is new Uint32;
   type SDL_SensorID is new Uint32;
   type SDL_TouchID is new Uint64;
   type SDL_FingerID is new Uint64;
   type SDL_PenID is new Uint32;

   type SDL_Scancode is new Uint32;
   type SDL_Keycode is new Uint32;
   type SDL_Keymod is new Uint16;
   type SDL_MouseButtonFlags is new Uint32;
   type SDL_MouseWheelDirection is new Uint32;
   type SDL_PowerState is new Uint32;
   type SDL_PenInputFlags is new Uint32;
   type SDL_PenAxis is new Uint32;

   --  Common scancodes used by text editing widgets
   SDL_SCANCODE_A         : constant SDL_Scancode := 4;
   SDL_SCANCODE_C         : constant SDL_Scancode := 6;
   SDL_SCANCODE_V         : constant SDL_Scancode := 25;
   SDL_SCANCODE_X         : constant SDL_Scancode := 27;
   SDL_SCANCODE_Y         : constant SDL_Scancode := 28;
   SDL_SCANCODE_Z         : constant SDL_Scancode := 29;
   SDL_SCANCODE_RETURN    : constant SDL_Scancode := 40;
   SDL_SCANCODE_ESCAPE    : constant SDL_Scancode := 41;
   SDL_SCANCODE_SPACE     : constant SDL_Scancode := 44;
   SDL_SCANCODE_TAB       : constant SDL_Scancode := 43;
   SDL_SCANCODE_BACKSPACE : constant SDL_Scancode := 42;
   SDL_SCANCODE_DELETE    : constant SDL_Scancode := 76;
   SDL_SCANCODE_RIGHT     : constant SDL_Scancode := 79;
   SDL_SCANCODE_LEFT      : constant SDL_Scancode := 80;
   SDL_SCANCODE_DOWN      : constant SDL_Scancode := 81;
   SDL_SCANCODE_UP        : constant SDL_Scancode := 82;
   SDL_SCANCODE_HOME      : constant SDL_Scancode := 74;
   SDL_SCANCODE_PAGEUP    : constant SDL_Scancode := 75;
   SDL_SCANCODE_END       : constant SDL_Scancode := 77;
   SDL_SCANCODE_PAGEDOWN  : constant SDL_Scancode := 78;

   --  Keyboard modifier masks
   SDL_KMOD_SHIFT : constant SDL_Keymod := 16#0003#;
   SDL_KMOD_CTRL  : constant SDL_Keymod := 16#00C0#;

   SDL_EVENT_FIRST : constant SDL_EventType := 0;
   SDL_EVENT_QUIT : constant SDL_EventType := 256;
   SDL_EVENT_TERMINATING : constant SDL_EventType := 257;
   SDL_EVENT_LOW_MEMORY : constant SDL_EventType := 258;
   SDL_EVENT_WILL_ENTER_BACKGROUND : constant SDL_EventType := 259;
   SDL_EVENT_DID_ENTER_BACKGROUND : constant SDL_EventType := 260;
   SDL_EVENT_WILL_ENTER_FOREGROUND : constant SDL_EventType := 261;
   SDL_EVENT_DID_ENTER_FOREGROUND : constant SDL_EventType := 262;
   SDL_EVENT_LOCALE_CHANGED : constant SDL_EventType := 263;
   SDL_EVENT_SYSTEM_THEME_CHANGED : constant SDL_EventType := 264;
   SDL_EVENT_DISPLAY_ORIENTATION : constant SDL_EventType := 337;
   SDL_EVENT_DISPLAY_ADDED : constant SDL_EventType := 338;
   SDL_EVENT_DISPLAY_REMOVED : constant SDL_EventType := 339;
   SDL_EVENT_DISPLAY_MOVED : constant SDL_EventType := 340;
   SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED : constant SDL_EventType := 341;
   SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED : constant SDL_EventType := 342;
   SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED : constant SDL_EventType := 343;
   SDL_EVENT_DISPLAY_FIRST : constant SDL_EventType := 337;
   SDL_EVENT_DISPLAY_LAST : constant SDL_EventType := 343;
   SDL_EVENT_WINDOW_SHOWN : constant SDL_EventType := 514;
   SDL_EVENT_WINDOW_HIDDEN : constant SDL_EventType := 515;
   SDL_EVENT_WINDOW_EXPOSED : constant SDL_EventType := 516;
   SDL_EVENT_WINDOW_MOVED : constant SDL_EventType := 517;
   SDL_EVENT_WINDOW_RESIZED : constant SDL_EventType := 518;
   SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED : constant SDL_EventType := 519;
   SDL_EVENT_WINDOW_METAL_VIEW_RESIZED : constant SDL_EventType := 520;
   SDL_EVENT_WINDOW_MINIMIZED : constant SDL_EventType := 521;
   SDL_EVENT_WINDOW_MAXIMIZED : constant SDL_EventType := 522;
   SDL_EVENT_WINDOW_RESTORED : constant SDL_EventType := 523;
   SDL_EVENT_WINDOW_MOUSE_ENTER : constant SDL_EventType := 524;
   SDL_EVENT_WINDOW_MOUSE_LEAVE : constant SDL_EventType := 525;
   SDL_EVENT_WINDOW_FOCUS_GAINED : constant SDL_EventType := 526;
   SDL_EVENT_WINDOW_FOCUS_LOST : constant SDL_EventType := 527;
   SDL_EVENT_WINDOW_CLOSE_REQUESTED : constant SDL_EventType := 528;
   SDL_EVENT_WINDOW_HIT_TEST : constant SDL_EventType := 529;
   SDL_EVENT_WINDOW_ICCPROF_CHANGED : constant SDL_EventType := 530;
   SDL_EVENT_WINDOW_DISPLAY_CHANGED : constant SDL_EventType := 531;
   SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED : constant SDL_EventType := 532;
   SDL_EVENT_WINDOW_SAFE_AREA_CHANGED : constant SDL_EventType := 533;
   SDL_EVENT_WINDOW_OCCLUDED : constant SDL_EventType := 534;
   SDL_EVENT_WINDOW_ENTER_FULLSCREEN : constant SDL_EventType := 535;
   SDL_EVENT_WINDOW_LEAVE_FULLSCREEN : constant SDL_EventType := 536;
   SDL_EVENT_WINDOW_DESTROYED : constant SDL_EventType := 537;
   SDL_EVENT_WINDOW_HDR_STATE_CHANGED : constant SDL_EventType := 538;
   SDL_EVENT_WINDOW_FIRST : constant SDL_EventType := 514;
   SDL_EVENT_WINDOW_LAST : constant SDL_EventType := 538;
   SDL_EVENT_KEY_DOWN : constant SDL_EventType := 768;
   SDL_EVENT_KEY_UP : constant SDL_EventType := 769;
   SDL_EVENT_TEXT_EDITING : constant SDL_EventType := 770;
   SDL_EVENT_TEXT_INPUT : constant SDL_EventType := 771;
   SDL_EVENT_KEYMAP_CHANGED : constant SDL_EventType := 772;
   SDL_EVENT_KEYBOARD_ADDED : constant SDL_EventType := 773;
   SDL_EVENT_KEYBOARD_REMOVED : constant SDL_EventType := 774;
   SDL_EVENT_TEXT_EDITING_CANDIDATES : constant SDL_EventType := 775;
   SDL_EVENT_MOUSE_MOTION : constant SDL_EventType := 1024;
   SDL_EVENT_MOUSE_BUTTON_DOWN : constant SDL_EventType := 1025;
   SDL_EVENT_MOUSE_BUTTON_UP : constant SDL_EventType := 1026;
   SDL_EVENT_MOUSE_WHEEL : constant SDL_EventType := 1027;
   SDL_EVENT_MOUSE_ADDED : constant SDL_EventType := 1028;
   SDL_EVENT_MOUSE_REMOVED : constant SDL_EventType := 1029;
   SDL_EVENT_JOYSTICK_AXIS_MOTION : constant SDL_EventType := 1536;
   SDL_EVENT_JOYSTICK_BALL_MOTION : constant SDL_EventType := 1537;
   SDL_EVENT_JOYSTICK_HAT_MOTION : constant SDL_EventType := 1538;
   SDL_EVENT_JOYSTICK_BUTTON_DOWN : constant SDL_EventType := 1539;
   SDL_EVENT_JOYSTICK_BUTTON_UP : constant SDL_EventType := 1540;
   SDL_EVENT_JOYSTICK_ADDED : constant SDL_EventType := 1541;
   SDL_EVENT_JOYSTICK_REMOVED : constant SDL_EventType := 1542;
   SDL_EVENT_JOYSTICK_BATTERY_UPDATED : constant SDL_EventType := 1543;
   SDL_EVENT_JOYSTICK_UPDATE_COMPLETE : constant SDL_EventType := 1544;
   SDL_EVENT_GAMEPAD_AXIS_MOTION : constant SDL_EventType := 1616;
   SDL_EVENT_GAMEPAD_BUTTON_DOWN : constant SDL_EventType := 1617;
   SDL_EVENT_GAMEPAD_BUTTON_UP : constant SDL_EventType := 1618;
   SDL_EVENT_GAMEPAD_ADDED : constant SDL_EventType := 1619;
   SDL_EVENT_GAMEPAD_REMOVED : constant SDL_EventType := 1620;
   SDL_EVENT_GAMEPAD_REMAPPED : constant SDL_EventType := 1621;
   SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN : constant SDL_EventType := 1622;
   SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION : constant SDL_EventType := 1623;
   SDL_EVENT_GAMEPAD_TOUCHPAD_UP : constant SDL_EventType := 1624;
   SDL_EVENT_GAMEPAD_SENSOR_UPDATE : constant SDL_EventType := 1625;
   SDL_EVENT_GAMEPAD_UPDATE_COMPLETE : constant SDL_EventType := 1626;
   SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED : constant SDL_EventType := 1627;
   SDL_EVENT_FINGER_DOWN : constant SDL_EventType := 1792;
   SDL_EVENT_FINGER_UP : constant SDL_EventType := 1793;
   SDL_EVENT_FINGER_MOTION : constant SDL_EventType := 1794;
   SDL_EVENT_FINGER_CANCELED : constant SDL_EventType := 1795;
   SDL_EVENT_CLIPBOARD_UPDATE : constant SDL_EventType := 2304;
   SDL_EVENT_DROP_FILE : constant SDL_EventType := 4096;
   SDL_EVENT_DROP_TEXT : constant SDL_EventType := 4097;
   SDL_EVENT_DROP_BEGIN : constant SDL_EventType := 4098;
   SDL_EVENT_DROP_COMPLETE : constant SDL_EventType := 4099;
   SDL_EVENT_DROP_POSITION : constant SDL_EventType := 4100;
   SDL_EVENT_AUDIO_DEVICE_ADDED : constant SDL_EventType := 4352;
   SDL_EVENT_AUDIO_DEVICE_REMOVED : constant SDL_EventType := 4353;
   SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED : constant SDL_EventType := 4354;
   SDL_EVENT_SENSOR_UPDATE : constant SDL_EventType := 4608;
   SDL_EVENT_PEN_PROXIMITY_IN : constant SDL_EventType := 4864;
   SDL_EVENT_PEN_PROXIMITY_OUT : constant SDL_EventType := 4865;
   SDL_EVENT_PEN_DOWN : constant SDL_EventType := 4866;
   SDL_EVENT_PEN_UP : constant SDL_EventType := 4867;
   SDL_EVENT_PEN_BUTTON_DOWN : constant SDL_EventType := 4868;
   SDL_EVENT_PEN_BUTTON_UP : constant SDL_EventType := 4869;
   SDL_EVENT_PEN_MOTION : constant SDL_EventType := 4870;
   SDL_EVENT_PEN_AXIS : constant SDL_EventType := 4871;
   SDL_EVENT_CAMERA_DEVICE_ADDED : constant SDL_EventType := 5120;
   SDL_EVENT_CAMERA_DEVICE_REMOVED : constant SDL_EventType := 5121;
   SDL_EVENT_CAMERA_DEVICE_APPROVED : constant SDL_EventType := 5122;
   SDL_EVENT_CAMERA_DEVICE_DENIED : constant SDL_EventType := 5123;
   SDL_EVENT_RENDER_TARGETS_RESET : constant SDL_EventType := 8192;
   SDL_EVENT_RENDER_DEVICE_RESET : constant SDL_EventType := 8193;
   SDL_EVENT_RENDER_DEVICE_LOST : constant SDL_EventType := 8194;
   SDL_EVENT_PRIVATE0 : constant SDL_EventType := 16384;
   SDL_EVENT_PRIVATE1 : constant SDL_EventType := 16385;
   SDL_EVENT_PRIVATE2 : constant SDL_EventType := 16386;
   SDL_EVENT_PRIVATE3 : constant SDL_EventType := 16387;
   SDL_EVENT_POLL_SENTINEL : constant SDL_EventType := 32512;
   SDL_EVENT_USER : constant SDL_EventType := 32768;
   SDL_EVENT_LAST : constant SDL_EventType := 65535;
   SDL_EVENT_ENUM_PADDING : constant SDL_EventType := 2147483647;  -- /

   type SDL_CommonEvent is record
      Event_Type : Uint32;
      Reserved   : Uint32;
      Timestamp  : Uint64;
   end record with Convention => C;

   type SDL_DisplayEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Display_ID : SDL_DisplayID;
      Data1      : Sint32;
      Data2      : Sint32;
   end record with Convention => C;

   type SDL_WindowEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Data1      : Sint32;
      Data2      : Sint32;
   end record with Convention => C;

   type SDL_KeyboardDeviceEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_KeyboardID;
   end record with Convention => C;

   type SDL_KeyboardEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_KeyboardID;
      Scancode   : SDL_Scancode;
      Key        : SDL_Keycode;
      Key_Mod    : SDL_Keymod;
      Raw        : Uint16;
      Down       : C_bool;
      Is_Repeat  : C_bool;
   end record with Convention => C;

   type SDL_TextEditingEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Text       : Interfaces.C.Strings.chars_ptr;
      Start      : Sint32;
      Length     : Sint32;
   end record with Convention => C;

   type Chars_Ptr_Ptr is access all Interfaces.C.Strings.chars_ptr with Convention => C;

   type SDL_TextEditingCandidatesEvent is record
      Event_Type         : SDL_EventType;
      Reserved           : Uint32;
      Timestamp          : Uint64;
      Window_ID          : SDL_WindowID;
      Candidates         : Chars_Ptr_Ptr;
      Num_Candidates     : Sint32;
      Selected_Candidate : Sint32;
      Horizontal         : C_bool;
      Padding1           : Uint8;
      Padding2           : Uint8;
      Padding3           : Uint8;
   end record with Convention => C;

   type SDL_TextInputEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Text       : Interfaces.C.Strings.chars_ptr;
   end record with Convention => C;

   type SDL_MouseDeviceEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_MouseID;
   end record with Convention => C;

   type SDL_MouseMotionEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_MouseID;
      State      : SDL_MouseButtonFlags;
      X          : C_float;
      Y          : C_float;
      X_Rel      : C_float;
      Y_Rel      : C_float;
   end record with Convention => C;

   type SDL_MouseButtonEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_MouseID;
      Button     : Uint8;
      Down       : C_bool;
      Clicks     : Uint8;
      Padding    : Uint8;
      X          : C_float;
      Y          : C_float;
   end record with Convention => C;

   type SDL_MouseWheelEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_MouseID;
      X          : C_float;
      Y          : C_float;
      Direction  : SDL_MouseWheelDirection;
      Mouse_X    : C_float;
      Mouse_Y    : C_float;
      Integer_X  : Sint32;
      Integer_Y  : Sint32;
   end record with Convention => C;

   type SDL_JoyAxisEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      Axis       : Uint8;
      Padding1   : Uint8;
      Padding2   : Uint8;
      Padding3   : Uint8;
      Value      : Sint16;
      Padding4   : Uint16;
   end record with Convention => C;

   type SDL_JoyBallEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      Ball       : Uint8;
      Padding1   : Uint8;
      Padding2   : Uint8;
      Padding3   : Uint8;
      X_Rel      : Sint16;
      Y_Rel      : Sint16;
   end record with Convention => C;

   type SDL_JoyHatEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      Hat        : Uint8;
      Value      : Uint8;
      Padding1   : Uint8;
      Padding2   : Uint8;
   end record with Convention => C;

   type SDL_JoyButtonEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      Button     : Uint8;
      Down       : C_bool;
      Padding1   : Uint8;
      Padding2   : Uint8;
   end record with Convention => C;

   type SDL_JoyDeviceEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
   end record with Convention => C;

   type SDL_JoyBatteryEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      State      : SDL_PowerState;
      Percent    : int;
   end record with Convention => C;

   type SDL_GamepadAxisEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      Axis       : Uint8;
      Padding1   : Uint8;
      Padding2   : Uint8;
      Padding3   : Uint8;
      Value      : Sint16;
      Padding4   : Uint16;
   end record with Convention => C;

   type SDL_GamepadButtonEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      Button     : Uint8;
      Down       : C_bool;
      Padding1   : Uint8;
      Padding2   : Uint8;
   end record with Convention => C;

   type SDL_GamepadDeviceEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
   end record with Convention => C;

   type SDL_GamepadTouchpadEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_JoystickID;
      Touchpad   : Sint32;
      Finger     : Sint32;
      X          : C_float;
      Y          : C_float;
      Pressure   : C_float;
   end record with Convention => C;

   type Float_Array_3 is array (0 .. 2) of C_float with Convention => C;

   type SDL_GamepadSensorEvent is record
      Event_Type       : SDL_EventType;
      Reserved         : Uint32;
      Timestamp        : Uint64;
      Which            : SDL_JoystickID;
      Sensor           : Sint32;
      Data             : Float_Array_3;
      Sensor_Timestamp : Uint64;
   end record with Convention => C;

   type SDL_AudioDeviceEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_AudioDeviceID;
      Recording  : C_bool;
      Padding1   : Uint8;
      Padding2   : Uint8;
      Padding3   : Uint8;
   end record with Convention => C;

   type SDL_CameraDeviceEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Which      : SDL_CameraID;
   end record with Convention => C;

   type SDL_RenderEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
   end record with Convention => C;

   type SDL_TouchFingerEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Touch_ID   : SDL_TouchID;
      Finger_ID  : SDL_FingerID;
      X          : C_float;
      Y          : C_float;
      DX         : C_float;
      DY         : C_float;
      Pressure   : C_float;
      Window_ID  : SDL_WindowID;
   end record with Convention => C;

   type SDL_PenProximityEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_PenID;
   end record with Convention => C;

   type SDL_PenMotionEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_PenID;
      Pen_State  : SDL_PenInputFlags;
      X          : C_float;
      Y          : C_float;
   end record with Convention => C;

   type SDL_PenTouchEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_PenID;
      Pen_State  : SDL_PenInputFlags;
      X          : C_float;
      Y          : C_float;
      Eraser     : C_bool;
      Down       : C_bool;
   end record with Convention => C;

   type SDL_PenButtonEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_PenID;
      Pen_State  : SDL_PenInputFlags;
      X          : C_float;
      Y          : C_float;
      Button     : Uint8;
      Down       : C_bool;
   end record with Convention => C;

   type SDL_PenAxisEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Which      : SDL_PenID;
      Pen_State  : SDL_PenInputFlags;
      X          : C_float;
      Y          : C_float;
      Axis       : SDL_PenAxis;
      Value      : C_float;
   end record with Convention => C;

   type SDL_DropEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      X          : C_float;
      Y          : C_float;
      Source     : Interfaces.C.Strings.chars_ptr;
      Data       : Interfaces.C.Strings.chars_ptr;
   end record with Convention => C;

   type SDL_ClipboardEvent is record
      Event_Type     : SDL_EventType;
      Reserved       : Uint32;
      Timestamp      : Uint64;
      Owner          : C_bool;
      Num_Mime_Types : Sint32;
      Mime_Types     : Chars_Ptr_Ptr;
   end record with Convention => C;

   type Float_Array_6 is array (0 .. 5) of C_float with Convention => C;

   type SDL_SensorEvent is record
      Event_Type       : SDL_EventType;
      Reserved         : Uint32;
      Timestamp        : Uint64;
      Which            : SDL_SensorID;
      Data             : Float_Array_6;
      Sensor_Timestamp : Uint64;
   end record with Convention => C;

   type SDL_QuitEvent is record
      Event_Type : SDL_EventType;
      Reserved   : Uint32;
      Timestamp  : Uint64;
   end record with Convention => C;

   type SDL_UserEvent is record
      Event_Type : Uint32;
      Reserved   : Uint32;
      Timestamp  : Uint64;
      Window_ID  : SDL_WindowID;
      Code       : Sint32;
      Data1      : System.Address;
      Data2      : System.Address;
   end record with Convention => C;

   --  A union in C. Adi reads the tag and reinterprets the rest as the
   --  specific event, so the remaining storage is named rather than left
   --  implicit -- the record has to be the full union's size either way.
   type Event_Storage is array (1 .. 124) of Uint8;

   type SDL_Event is record
      Event_Type : SDL_EventType;
      Storage    : Event_Storage := [others => 0];
   end record with Convention => C, Size => 128 * 8;

   function SDL_GetModState return SDL_Keymod
   with Import => True,
        Convention => C,
        External_Name => "SDL_GetModState";

   function SDL_PollEvent (event : access SDL_Event) return C_bool  -- /usr/include/SDL3/SDL_events.h:1270
   with Import => True,
        Convention => C,
        External_Name => "SDL_PollEvent";

   function SDL_PushEvent (event : access SDL_Event) return C_bool  -- /usr/include/SDL3/SDL_events.h:1358
   with Import => True,
        Convention => C,
        External_Name => "SDL_PushEvent";

end Adi.SDL.Events;
