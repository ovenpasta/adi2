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
   type Dialog_Widget_Access is access all Dialog_Widget'Class;

   function Create return Dialog_Widget_Access;

   procedure Attach_Window
     (W    : in out Dialog_Widget;
      Host : Adi.Window.Window_Access);

   --  Content
   procedure Set_Title   (W : in out Dialog_Widget; Text : String);
   procedure Set_Message (W : in out Dialog_Widget; Text : String);

   --  Custom content: replaces the message label with an arbitrary widget.
   --  Pass null to restore the built-in message label.
   procedure Set_Content
     (W       : in out Dialog_Widget;
      Content : access Widget'Class);

   --  Icon (sets icon on the message label)
   procedure Set_Icon (W : in out Dialog_Widget; Icon : Image_Access);

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
   function Get_Button
     (W : Dialog_Widget; Index : Positive)
      return Adi.Widget.Button.Button_Widget_Access;

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

   --  Result callback: Button_Index=0 means dismissed (backdrop/escape)
   type Dialog_Result_Callback is access procedure
     (Dlg          : Dialog_Widget_Access;
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

private

   package Part_Style_Holders is new Ada.Containers.Indefinite_Holders
     (Part_Style_Array);

   type Button_Info is record
      Text   : Ada.Strings.Unbounded.Unbounded_String;
      Widget : Adi.Widget.Widget_Access := null;
   end record;

   package Button_Vectors is new Ada.Containers.Vectors (Positive, Button_Info);

   Panel_Idx : constant Positive := 1;

   type Dialog_Widget is new Widget with record
      Host_Window   : Adi.Window.Window_Access := null;
      Content_Panel : Adi.Widget.Box.Box_Widget_Access := null;
      Title_Label   : Adi.Widget.Label.Label_Widget_Access := null;
      Message_Label : Adi.Widget.Label.Label_Widget_Access := null;
      Custom_Content : Widget_Access := null;
      Button_Row    : Adi.Widget.Box.Box_Widget_Access := null;
      Buttons       : Button_Vectors.Vector;
      Shown         : Boolean := False;
      Dismiss_On_Backdrop_Flag : Boolean := True;
      Dismiss_On_Escape_Flag   : Boolean := True;
      Result : Result_Signals.Signal;
      Button_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Button_Styles : Boolean := False;
      Default_Button_Index : Natural := 0;
      Primary_Button_Styles : Part_Style_Array := Empty_Part_Styles;
      Has_Primary_Button_Styles : Boolean := False;
   end record;

end Adi.Widget.Dialog;
