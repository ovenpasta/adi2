--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;
with Adi.Core;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Text_Buffer;
with Adi.Widget.Context_Menu;
with Adi.Window;

package Adi.Widget.Text_Input is

   type Text_Input_Widget is new Widget with private;

   --  Typed handle
   type Text_Input_Handle is private;
   Null_Text_Input_Handle : constant Text_Input_Handle;

   --  Construction
   function Create_Handle (Text : String := "";
                           Label : String := "") return Text_Input_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Text_Input_Handle) return Widget_Handle;
   function Try_As_Text_Input (H : Widget_Handle) return Text_Input_Handle;
   function Is_Valid (H : Text_Input_Handle) return Boolean;
   function "+" (H : Text_Input_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Text_Input_Handle; Styles : Part_Style_Array);

   --  Widget methods
   procedure Set_Text (W : in out Text_Input_Widget; Text : String);
   function Get_Text (W : Text_Input_Widget) return String;

   --  Minimum number of characters visible before scrolling kicks in.
   --  Determines the preferred width reported by Measure_Content.
   procedure Set_Min_Visible_Chars
     (W : in out Text_Input_Widget; Count : Positive);
   function  Get_Min_Visible_Chars
     (W : Text_Input_Widget) return Positive;

   procedure Set_Context_Menu_Part_Styles
     (W      : in out Text_Input_Widget;
      Styles : Part_Style_Array);
   procedure Set_Context_Menu_Item_Part_Styles
     (W      : in out Text_Input_Widget;
      Styles : Part_Style_Array);

   --  Password mode: when On, each codepoint of the buffer is rendered as
   --  Password_Character, and clipboard Cut/Copy (key shortcuts and
   --  context-menu items) are suppressed. The underlying buffer is not
   --  modified -- Get_Text still returns the real text. Paste is unaffected.
   procedure Set_Password_Mode
     (W : in out Text_Input_Widget; Value : Boolean := True);
   function  Is_Password_Mode (W : Text_Input_Widget) return Boolean;

   --  The mask drawn for each codepoint when Password_Mode is on. Char must
   --  hold exactly one UTF-8 codepoint; other inputs (empty, or two or more
   --  codepoints) are rejected silently and leave the mask unchanged.
   --  Default is U+2022 BULLET.
   procedure Set_Password_Character
     (W : in out Text_Input_Widget; Char : String);
   function  Get_Password_Character (W : Text_Input_Widget) return String;

   type Change_Callback is access procedure
     (W : Widget_Handle; Text : String);

   package Change_Signals is new Adi.Signal (Change_Callback, null);

   procedure Connect_Changed
     (W : in out Text_Input_Widget; CB : Change_Callback);
   function Connect_Changed
     (W : in out Text_Input_Widget; CB : Change_Callback)
      return Change_Signals.Connection_Id;
   procedure Disconnect_Changed
     (W : in out Text_Input_Widget; Id : Change_Signals.Connection_Id);

   --  Handle methods
   procedure Set_Text (H : Text_Input_Handle; Text : String);
   function  Get_Text (H : Text_Input_Handle) return String;
   procedure Set_Min_Visible_Chars
     (H : Text_Input_Handle; Count : Positive);
   function  Get_Min_Visible_Chars
     (H : Text_Input_Handle) return Positive;
   procedure Set_Context_Menu_Part_Styles
     (H : Text_Input_Handle; Styles : Part_Style_Array);
   procedure Set_Context_Menu_Item_Part_Styles
     (H : Text_Input_Handle; Styles : Part_Style_Array);
   procedure Set_Password_Mode
     (H : Text_Input_Handle; Value : Boolean := True);
   function  Is_Password_Mode (H : Text_Input_Handle) return Boolean;
   procedure Set_Password_Character
     (H : Text_Input_Handle; Char : String);
   function  Get_Password_Character (H : Text_Input_Handle) return String;
   procedure Connect_Changed
     (H : Text_Input_Handle; CB : Change_Callback);
   function  Connect_Changed
     (H : Text_Input_Handle; CB : Change_Callback)
      return Change_Signals.Connection_Id;
   procedure Disconnect_Changed
     (H : Text_Input_Handle; Id : Change_Signals.Connection_Id);

   overriding procedure Build_Items (W : in out Text_Input_Widget);
   overriding function Get_Content_Min_Size
     (W : Text_Input_Widget) return Size_2D;
   overriding procedure Layout (W : in out Text_Input_Widget);
   overriding function Measure_Content (W : Text_Input_Widget) return Size_2D;

   overriding procedure On_Key_Down
     (W        : in out Text_Input_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

   overriding procedure On_Text_Input (W : in out Text_Input_Widget; Text : String);
   overriding procedure On_Focus_Gained (W : in out Text_Input_Widget);
   overriding procedure On_Focus_Lost (W : in out Text_Input_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out Text_Input_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Mouse_Move
     (W    : in out Text_Input_Widget;
      X, Y : Pixel_Type);
   overriding procedure On_Mouse_Up
     (W      : in out Text_Input_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button);
   overriding procedure On_Destroy (W : in out Text_Input_Widget);

private
   --  Internal eager host binding. Public callers rely on lazy host
   --  resolution when the context menu is invoked.
   procedure Attach_Window
     (W    : in out Text_Input_Widget;
      Host : Adi.Window.Window_Access);

   Panel_Idx     : constant Positive := 1;
   Selection_Idx : constant Positive := 2;
   Text_Idx      : constant Positive := 3;
   Cursor_Idx    : constant Positive := 4;

   --  U+2022 BULLET, encoded once as UTF-8 so the record default can be
   --  a plain String literal rather than raw byte values.
   Default_Password_Char : constant String :=
     Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode
       (Wide_Wide_String'(1 => Wide_Wide_Character'Val (16#2022#)));

   type Text_Input_Widget is new Widget with record
      Buffer     : aliased Adi.Text_Buffer.Text_Buffer;
      Changed : Change_Signals.Signal;
      Min_Visible_Chars : Positive := 20;
      Drag_Selecting : Boolean := False;
      Pending_Word_Select : Boolean := False;
      Press_X : Pixel_Type := 0.0;
      Press_Y : Pixel_Type := 0.0;
      Horizontal_Scroll : Pixel_Type := 0.0;
      Context_Menu : Adi.Widget.Context_Menu.Menu_Handle :=
        Adi.Widget.Context_Menu.Null_Menu_Handle;
      Context_Menu_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Menu_Styles : Boolean := False;
      Context_Item_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Context_Item_Styles : Boolean := False;
      Password_Mode : Boolean := False;
      Password_Character : Unbounded_String :=
        To_Unbounded_String (Default_Password_Char);
   end record;

   --  The field scrolls its line sideways once the text outgrows it,
   --  so what scrolled out must not be drawn beside the field. Value
   --  inputs derive from this type and inherit it.
   overriding function Clips_Own_Content
     (W : Text_Input_Widget) return Boolean;

   type Text_Input_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Text_Input_Handle : constant Text_Input_Handle :=
     (Id => Widget_Stores.Null_Id);

   type Text_Input_Widget_Access is access all Text_Input_Widget'Class;

end Adi.Widget.Text_Input;
