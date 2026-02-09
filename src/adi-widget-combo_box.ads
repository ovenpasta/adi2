with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.SDL.Events;
with Adi.Widget;            use Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with Adi.Window;

package Adi.Widget.Combo_Box is

   type Combo_Box_Widget is new Widget with private;
   type Combo_Box_Widget_Access is access all Combo_Box_Widget'Class;

   type Selection_Changed_Callback is access procedure
     (W     : Combo_Box_Widget_Access;
      Index : Natural;
      Text  : String);

   function Create return Combo_Box_Widget_Access;

   procedure Attach_Window
     (W    : in out Combo_Box_Widget;
      Host : Adi.Window.Window_Access);

   procedure Add_Item (W : in out Combo_Box_Widget; Text : String);
   procedure Clear_Items (W : in out Combo_Box_Widget);
   function Option_Count (W : Combo_Box_Widget) return Natural;

   procedure Set_Selected_Index (W : in out Combo_Box_Widget; Index : Natural);
   function Get_Selected_Index (W : Combo_Box_Widget) return Natural;
   function Get_Selected_Text (W : Combo_Box_Widget) return String;

   procedure Set_On_Selection_Changed
     (W  : in out Combo_Box_Widget;
      CB : Selection_Changed_Callback);

   procedure Set_Dropdown_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array);
   procedure Set_Option_Row_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array);

   procedure Open_Dropdown (W : in out Combo_Box_Widget);
   procedure Close_Dropdown (W : in out Combo_Box_Widget);
   procedure Toggle_Dropdown (W : in out Combo_Box_Widget);
   function Is_Open (W : Combo_Box_Widget) return Boolean;

   overriding procedure Build_Items (W : in out Combo_Box_Widget);
   overriding procedure Layout (W : in out Combo_Box_Widget);
   overriding procedure On_Mouse_Down
     (W      : in out Combo_Box_Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Key_Down
     (W        : in out Combo_Box_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);
   overriding procedure On_Focus_Lost (W : in out Combo_Box_Widget);

private
   package String_Vectors is new Ada.Containers.Vectors
     (Positive, Ada.Strings.Unbounded.Unbounded_String);

   package Popup_Lists is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget,
      Adi.Widget.Label.Label_Widget_Access);

   Panel_Idx     : constant Positive := 1;
   Label_Idx     : constant Positive := 2;
   Indicator_Idx : constant Positive := 3;

   type Combo_Box_Widget is new Widget with record
      Host_Window : Adi.Window.Window_Access := null;
      Popup       : Popup_Lists.List_Box_Widget_Access := null;
      Options     : String_Vectors.Vector;
      Option_Row_Styles     : Part_Style_Array := Empty_Part_Styles;
      Has_Option_Row_Styles : Boolean := False;
      Selected    : Natural := 0;
      Open        : Boolean := False;
      On_Changed  : Selection_Changed_Callback := null;
   end record;

end Adi.Widget.Combo_Box;
