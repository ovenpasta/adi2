--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Adi.Image;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with Adi.Window;

package Adi.Widget.Combo_Box is

   type Combo_Box_Widget is new Widget with private;

   --  Typed handle
   type Combo_Box_Handle is private;
   Null_Combo_Box_Handle : constant Combo_Box_Handle;

   --  Construction
   function Create_Handle return Combo_Box_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Combo_Box_Handle) return Widget_Handle;
   function Try_As_Combo_Box (H : Widget_Handle) return Combo_Box_Handle;
   function Is_Valid (H : Combo_Box_Handle) return Boolean;
   function "+" (H : Combo_Box_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Combo_Box_Handle; Styles : Part_Style_Array);

   --  Base type for per-item user data.  Derive to attach arbitrary state.
   --  The combo box stores a borrowed reference; the caller owns the object.
   type Item_Data is tagged null record;
   type Item_Data_Access is access all Item_Data'Class;

   procedure Add_Item (W    : in out Combo_Box_Widget;
                       Text : String;
                       Icon : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
                       Data : Item_Data_Access       := null);
   procedure Clear_Items (W : in out Combo_Box_Widget);
   function Option_Count (W : Combo_Box_Widget) return Natural;

   procedure Set_Selected_Index (W : in out Combo_Box_Widget; Index : Natural);
   function Get_Selected_Index (W : Combo_Box_Widget) return Natural;
   function Get_Selected_Text (W : Combo_Box_Widget) return String;
   function Get_Selected_Data (W : Combo_Box_Widget) return Item_Data_Access;

   function Get_Item_Data (W     : Combo_Box_Widget;
                           Index : Positive) return Item_Data_Access;
   function Get_Item_Icon (W     : Combo_Box_Widget;
                           Index : Positive) return Adi.Image.Image_Handle;

   type Selection_Changed_Callback is access procedure
     (W : Widget_Handle; Index : Natural; Text : String);

   package Selection_Changed_Signals is new Adi.Signal
     (Selection_Changed_Callback, null);

   procedure Connect_Selection_Changed
     (W : in out Combo_Box_Widget; CB : Selection_Changed_Callback);
   function Connect_Selection_Changed
     (W : in out Combo_Box_Widget; CB : Selection_Changed_Callback)
      return Selection_Changed_Signals.Connection_Id;
   procedure Disconnect_Selection_Changed
     (W : in out Combo_Box_Widget;
      Id : Selection_Changed_Signals.Connection_Id);

   procedure Set_Dropdown_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array);
   procedure Set_Option_Row_Part_Styles
     (W      : in out Combo_Box_Widget;
      Styles : Part_Style_Array);

   --  Package-level defaults — apply to all combo boxes that don't have
   --  per-instance styles set via Set_Dropdown/Option_Row_Part_Styles.
   procedure Set_Default_Dropdown_Styles (Styles : Part_Style_Array);
   procedure Set_Default_Option_Row_Styles (Styles : Part_Style_Array);

   procedure Set_Arrow_Image
     (W    : in out Combo_Box_Widget;
      Down : Adi.Image.Image_Handle;
      Up   : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle);

   procedure Set_Default_Arrow_Image
     (Down : Adi.Image.Image_Handle;
      Up   : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle);

   procedure Open_Dropdown (W : in out Combo_Box_Widget);
   procedure Close_Dropdown (W : in out Combo_Box_Widget);
   procedure Toggle_Dropdown (W : in out Combo_Box_Widget);
   function Is_Open (W : Combo_Box_Widget) return Boolean;

   --  Handle methods
   procedure Add_Item (H    : Combo_Box_Handle;
                       Text : String;
                       Icon : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
                       Data : Item_Data_Access       := null);
   procedure Clear_Items (H : Combo_Box_Handle);
   function Option_Count (H : Combo_Box_Handle) return Natural;
   procedure Set_Selected_Index (H : Combo_Box_Handle; Index : Natural);
   function Get_Selected_Index (H : Combo_Box_Handle) return Natural;
   function Get_Selected_Text (H : Combo_Box_Handle) return String;
   function Get_Selected_Data (H : Combo_Box_Handle) return Item_Data_Access;
   function Get_Item_Data (H     : Combo_Box_Handle;
                           Index : Positive) return Item_Data_Access;
   function Get_Item_Icon (H     : Combo_Box_Handle;
                           Index : Positive) return Adi.Image.Image_Handle;
   procedure Connect_Selection_Changed
     (H : Combo_Box_Handle; CB : Selection_Changed_Callback);
   function Connect_Selection_Changed
     (H : Combo_Box_Handle; CB : Selection_Changed_Callback)
      return Selection_Changed_Signals.Connection_Id;
   procedure Disconnect_Selection_Changed
     (H  : Combo_Box_Handle;
      Id : Selection_Changed_Signals.Connection_Id);
   procedure Set_Dropdown_Part_Styles
     (H : Combo_Box_Handle; Styles : Part_Style_Array);
   procedure Set_Option_Row_Part_Styles
     (H : Combo_Box_Handle; Styles : Part_Style_Array);
   procedure Set_Arrow_Image
     (H    : Combo_Box_Handle;
      Down : Adi.Image.Image_Handle;
      Up   : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle);
   procedure Open_Dropdown (H : Combo_Box_Handle);
   procedure Close_Dropdown (H : Combo_Box_Handle);
   procedure Toggle_Dropdown (H : Combo_Box_Handle);
   function Is_Open (H : Combo_Box_Handle) return Boolean;

   overriding procedure Build_Items (W : in out Combo_Box_Widget);
   overriding function Get_Content_Min_Size
     (W : Combo_Box_Widget) return Size_2D;
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
   overriding procedure On_Destroy (W : in out Combo_Box_Widget);

private
   --  Internal eager host binding. Public callers rely on lazy host
   --  resolution when opening the dropdown.
   procedure Attach_Window
     (W    : in out Combo_Box_Widget;
      Host : Adi.Window.Window_Access);

   type Combo_Item is record
      Text : Ada.Strings.Unbounded.Unbounded_String :=
               Ada.Strings.Unbounded.Null_Unbounded_String;
      Icon : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
      Data : Item_Data_Access       := null;
   end record;

   package Combo_Item_Vectors is new Ada.Containers.Vectors
     (Positive, Combo_Item);

   package Popup_Lists is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget);

   Panel_Idx     : constant Positive := 1;
   Label_Idx     : constant Positive := 2;
   Indicator_Idx : constant Positive := 3;
   Icon_Idx      : constant Positive := 4;

   type Combo_Box_Widget is new Widget with record
      Host_Window : Adi.Window.Window_Access := null;
      Popup       : Popup_Lists.List_Box_Handle := Popup_Lists.Null_List_Box_Handle;
      Options     : Combo_Item_Vectors.Vector;
      Option_Row_Styles     : Part_Style_Array := Empty_Part_Styles;
      Has_Option_Row_Styles : Boolean := False;
      Selected    : Natural := 0;
      Open        : Boolean := False;
      Changed : Selection_Changed_Signals.Signal;
      Layout_Items : Layout_Item_List.Vector;
      Arrow_Down_Img : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
      Arrow_Up_Img   : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
      --  Hold images only when this widget drew its own chevrons for
      --  want of any supplied to it. Arrows given by the application, or
      --  set as the package default, belong to whoever set them.
      Own_Arrow_Down : Adi.Image.Image_Owner := Adi.Image.Null_Image_Owner;
      Own_Arrow_Up   : Adi.Image.Image_Owner := Adi.Image.Null_Image_Owner;
   end record;

   type Combo_Box_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Combo_Box_Handle : constant Combo_Box_Handle :=
     (Id => Widget_Stores.Null_Id);

   type Combo_Box_Widget_Access is access all Combo_Box_Widget'Class;

end Adi.Widget.Combo_Box;
