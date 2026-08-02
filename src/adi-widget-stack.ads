--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.Signal;

generic
   type Page_Id is (<>);
package Adi.Widget.Stack is

   ---------------------------------------------------------------------------
   --  Stack Widget - Container showing one child at a time
   --
   --  Generic over a discrete Page_Id type (typically an enum).
   --  Each page is keyed by its Page_Id, so Add_Page / Set_Active use
   --  meaningful names instead of fragile integer indices.
   --
   --  When combined with Button.Options instantiated over the same enum,
   --  the On_Changed callback maps directly to Set_Active.
   --
   --  Items:
   --    - Panel_Item (Main_Part) - Background panel
   ---------------------------------------------------------------------------

   type Stack_Widget is new Widget with private;
   type Stack_Widget_Access is access all Stack_Widget'Class;

   --  Typed handle
   type Stack_Handle is private;
   Null_Stack_Handle : constant Stack_Handle;

   --  Construction
   function Create_Handle return Stack_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Stack_Handle) return Widget_Handle;
   function Try_As_Stack (H : Widget_Handle) return Stack_Handle;
   function Is_Valid (H : Stack_Handle) return Boolean;
   function "+" (H : Stack_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : Stack_Handle; Styles : Part_Style_Array);

   --  Active page management (widget methods)
   procedure Set_Active (W : in out Stack_Widget; Id : Page_Id);
   function  Get_Active (W : Stack_Widget) return Page_Id;
   function  Get_Active_Widget_Handle (W : Stack_Widget) return Widget_Handle;
   function  Get_Page_Handle (W : Stack_Widget; Id : Page_Id) return Widget_Handle;

   --  Callback when active page changes
   type Page_Changed_Callback is access procedure (Id : Page_Id);

   package Page_Changed_Signals is new Adi.Signal
     (Page_Changed_Callback, null);

   procedure Connect_Changed
     (W : in out Stack_Widget; CB : Page_Changed_Callback);
   function Connect_Changed
     (W : in out Stack_Widget; CB : Page_Changed_Callback)
      return Page_Changed_Signals.Connection_Id;
   procedure Disconnect_Changed
     (W : in out Stack_Widget; Id : Page_Changed_Signals.Connection_Id);

   --  Handle methods
   procedure Add_Page (H : Stack_Handle; Id : Page_Id; Page : Widget_Handle);
   procedure Set_Active (H : Stack_Handle; Id : Page_Id);
   function  Get_Active (H : Stack_Handle) return Page_Id;
   function  Get_Active_Widget_Handle (H : Stack_Handle) return Widget_Handle;
   function  Get_Page_Handle (H : Stack_Handle; Id : Page_Id)
      return Widget_Handle;
   procedure Connect_Changed
     (H : Stack_Handle; CB : Page_Changed_Callback);
   function  Connect_Changed
     (H : Stack_Handle; CB : Page_Changed_Callback)
      return Page_Changed_Signals.Connection_Id;
   procedure Disconnect_Changed
     (H : Stack_Handle; Id : Page_Changed_Signals.Connection_Id);

   --  Implement abstract methods
   overriding function Measure_Content (W : Stack_Widget) return Size_2D;
   overriding function Measure_Content_At_Width
     (W : Stack_Widget; Assigned_Width : Pixel_Type) return Size_2D;
   overriding function Get_Min_Size (W : Stack_Widget) return Size_2D;
   overriding function Get_Content_Min_Size
     (W : Stack_Widget) return Size_2D;
   overriding procedure Build_Items (W : in out Stack_Widget);
   overriding procedure Layout (W : in out Stack_Widget);

private

   Panel_Idx : constant Positive := 1;

   type Page_Array is array (Page_Id) of Widget_Access;

   type Stack_Widget is new Widget with record
      Pages      : Page_Array := [others => null];
      Active     : Page_Id := Page_Id'First;
      Has_Active : Boolean := False;
      Changed : Page_Changed_Signals.Signal;
   end record;

   type Stack_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Stack_Handle : constant Stack_Handle :=
     (Id => Widget_Stores.Null_Id);

end Adi.Widget.Stack;
