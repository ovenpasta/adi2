--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Indefinite_Holders;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Window;

package Adi.Widget.Dialog is

   type Dialog_Widget is new Widget with private;

   --  Typed handle
   type Dialog_Handle is private;
   Null_Dialog_Handle : constant Dialog_Handle;

   --  Construction
   function Create_Handle return Dialog_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Dialog_Handle) return Widget_Handle;
   function Try_As_Dialog (H : Widget_Handle) return Dialog_Handle;
   function Is_Valid (H : Dialog_Handle) return Boolean;
   function "+" (H : Dialog_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Dialog_Handle; Styles : Part_Style_Array);

   --  Content
   procedure Set_Title   (W : in out Dialog_Widget; Text : String);
   procedure Set_Message (W : in out Dialog_Widget; Text : String);

   --  Custom content: replaces the message label with an arbitrary widget.
   --  Pass null to restore the built-in message label.
   procedure Set_Content
     (W       : in out Dialog_Widget;
      Content : access Widget'Class);

   --  Icon (sets icon on the message label)
   procedure Set_Icon (W : in out Dialog_Widget; Icon : Image_Handle);

   --  Button management (returns 1-based index)
   function  Add_Button    (W : in out Dialog_Widget; Text : String) return Positive;
   procedure Add_Button    (W : in out Dialog_Widget; Text : String);
   procedure Clear_Buttons (W : in out Dialog_Widget);

   --  Default (primary) button: visually distinct, receives focus on Show.
   --  Pass 0 to clear the default button.
   --  Out-of-range nonzero indices are stored and will take effect once
   --  a button exists at that index.
   procedure Set_Default_Button (W : in out Dialog_Widget; Index : Natural);

   --  Access individual buttons for per-button styling.
   --  Returns null if Index is out of range.
   function Get_Button_Handle
     (W : Dialog_Widget; Index : Positive)
      return Adi.Widget.Button.Button_Handle;

   --  Convenience presets
   procedure Set_OK_Button     (W : in out Dialog_Widget);
   procedure Set_OK_Cancel     (W : in out Dialog_Widget);
   procedure Set_Yes_No        (W : in out Dialog_Widget);
   procedure Set_Yes_No_Cancel (W : in out Dialog_Widget);

   --  Show/Hide
   procedure Show (W : in out Dialog_Widget);
   procedure Hide (W : in out Dialog_Widget);
   function  Is_Shown (W : Dialog_Widget) return Boolean;

   --  Dismiss policies
   procedure Set_Dismiss_On_Backdrop
     (W : in out Dialog_Widget; Value : Boolean := True);
   procedure Set_Dismiss_On_Escape
     (W : in out Dialog_Widget; Value : Boolean := True);

   --  Auto-close on button click (default True).
   --  When False the result callback fires but the dialog stays visible;
   --  the application must call Hide explicitly.
   procedure Set_Auto_Close
     (W : in out Dialog_Widget; Value : Boolean := True);

   --  Result callback: Button_Index=0 means dismissed (backdrop/escape)
   type Dialog_Result_Callback is access procedure
     (W            : Widget_Handle;
      Button_Index : Natural;
      Button_Text  : String);

   package Result_Signals is new Adi.Signal (Dialog_Result_Callback, null);

   procedure Connect_Result
     (W : in out Dialog_Widget; CB : Dialog_Result_Callback);
   function Connect_Result
     (W : in out Dialog_Widget; CB : Dialog_Result_Callback)
      return Result_Signals.Connection_Id;
   procedure Disconnect_Result
     (W : in out Dialog_Widget; Id : Result_Signals.Connection_Id);

   --  Style injection for sub-widgets
   procedure Set_Panel_Style
     (W : in out Dialog_Widget; S : Part_Style_Array);
   procedure Set_Title_Style
     (W : in out Dialog_Widget; S : Part_Style_Array);
   procedure Set_Message_Style
     (W : in out Dialog_Widget; S : Part_Style_Array);
   procedure Set_Button_Row_Style
     (W : in out Dialog_Widget; S : Part_Style_Array);
   procedure Set_Button_Style
     (W : in out Dialog_Widget; S : Part_Style_Array);
   --  Primary style used for the current default button.
   --  Falls back to package-level primary style, then normal button style.
   procedure Set_Primary_Button_Style
     (W : in out Dialog_Widget; S : Part_Style_Array);
   procedure Set_Content_Style
     (W : in out Dialog_Widget; S : Part_Style_Array);

   --  Handle methods
   procedure Attach_Window
     (H : Dialog_Handle; Host : Adi.Window.Window_Handle);
   procedure Set_Title   (H : Dialog_Handle; Text : String);
   procedure Set_Message (H : Dialog_Handle; Text : String);
   procedure Set_Content (H : Dialog_Handle; Content : Widget_Handle);
   procedure Set_Icon    (H : Dialog_Handle; Icon : Image_Handle);
   function  Add_Button  (H : Dialog_Handle; Text : String) return Positive;
   procedure Add_Button  (H : Dialog_Handle; Text : String);
   procedure Clear_Buttons (H : Dialog_Handle);
   procedure Set_Default_Button (H : Dialog_Handle; Index : Natural);
   function  Get_Button_Handle
     (H : Dialog_Handle; Index : Positive)
      return Adi.Widget.Button.Button_Handle;
   function Get_Content_Panel_Handle
     (H : Dialog_Handle) return Adi.Widget.Box.Box_Handle;
   function Get_Title_Handle
     (H : Dialog_Handle) return Adi.Widget.Label.Label_Handle;
   function Get_Message_Handle
     (H : Dialog_Handle) return Adi.Widget.Label.Label_Handle;
   function Get_Button_Row_Handle
     (H : Dialog_Handle) return Adi.Widget.Box.Box_Handle;
   procedure Set_OK_Button     (H : Dialog_Handle);
   procedure Set_OK_Cancel     (H : Dialog_Handle);
   procedure Set_Yes_No        (H : Dialog_Handle);
   procedure Set_Yes_No_Cancel (H : Dialog_Handle);
   procedure Show    (H : Dialog_Handle);
   procedure Hide    (H : Dialog_Handle);
   function  Is_Shown (H : Dialog_Handle) return Boolean;
   procedure Set_Dismiss_On_Backdrop
     (H : Dialog_Handle; Value : Boolean := True);
   procedure Set_Dismiss_On_Escape
     (H : Dialog_Handle; Value : Boolean := True);
   procedure Set_Auto_Close
     (H : Dialog_Handle; Value : Boolean := True);
   procedure Connect_Result
     (H : Dialog_Handle; CB : Dialog_Result_Callback);
   function  Connect_Result
     (H : Dialog_Handle; CB : Dialog_Result_Callback)
      return Result_Signals.Connection_Id;
   procedure Disconnect_Result
     (H : Dialog_Handle; Id : Result_Signals.Connection_Id);
   procedure Set_Panel_Style
     (H : Dialog_Handle; S : Part_Style_Array);
   procedure Set_Title_Style
     (H : Dialog_Handle; S : Part_Style_Array);
   procedure Set_Message_Style
     (H : Dialog_Handle; S : Part_Style_Array);
   procedure Set_Button_Row_Style
     (H : Dialog_Handle; S : Part_Style_Array);
   procedure Set_Button_Style
     (H : Dialog_Handle; S : Part_Style_Array);
   procedure Set_Primary_Button_Style
     (H : Dialog_Handle; S : Part_Style_Array);
   procedure Set_Content_Style
     (H : Dialog_Handle; S : Part_Style_Array);

   --  Package-level defaults — apply to all dialogs that don't have
   --  per-instance styles set.
   procedure Set_Default_Panel_Style      (S : Part_Style_Array);
   procedure Set_Default_Title_Style      (S : Part_Style_Array);
   procedure Set_Default_Message_Style    (S : Part_Style_Array);
   procedure Set_Default_Button_Row_Style (S : Part_Style_Array);
   procedure Set_Default_Button_Style         (S : Part_Style_Array);
   --  Package-level primary style used for each dialog's default button.
   --  Falls back to that dialog's normal button style when unset.
   procedure Set_Default_Primary_Button_Style (S : Part_Style_Array);
   procedure Set_Default_Content_Style        (S : Part_Style_Array);

   --  Abstract method implementations
   overriding procedure Build_Items (W : in out Dialog_Widget);
   overriding procedure Layout (W : in out Dialog_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out Dialog_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Key_Down
     (W        : in out Dialog_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);
   overriding procedure On_Destroy (W : in out Dialog_Widget);

private

   package Part_Style_Holders is new Ada.Containers.Indefinite_Holders
     (Part_Style_Array);

   type Button_Info is record
      Text   : Ada.Strings.Unbounded.Unbounded_String;
      Widget : Widget_Handle := Null_Handle;
   end record;

   package Button_Vectors is new Ada.Containers.Vectors (Positive, Button_Info);

   Panel_Idx : constant Positive := 1;

   type Dialog_Widget is new Widget with record
      Host_Window    : Adi.Window.Window_Handle := Adi.Window.Null_Window_Handle;
      Content_Panel  : Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Null_Box_Handle;
      Title_Label    : Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Null_Label_Handle;
      Message_Label  : Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Null_Label_Handle;
      Custom_Content : Widget_Handle := Null_Handle;
      Button_Row     : Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Null_Box_Handle;
      Buttons       : Button_Vectors.Vector;
      Shown         : Boolean := False;
      Dismiss_On_Backdrop_Flag : Boolean := True;
      Dismiss_On_Escape_Flag   : Boolean := True;
      Auto_Close_Flag          : Boolean := True;
      Result : Result_Signals.Signal;
      Button_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Button_Styles : Boolean := False;
      Default_Button_Index : Natural := 0;
      Primary_Button_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Primary_Button_Styles : Boolean := False;
   end record;

   type Dialog_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Dialog_Handle : constant Dialog_Handle :=
     (Id => Widget_Stores.Null_Id);

   type Dialog_Widget_Access is access all Dialog_Widget'Class;

end Adi.Widget.Dialog;
