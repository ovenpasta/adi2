--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Ada.Containers.Indefinite_Holders;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.Handle_Store;
with Adi.Signal;
with Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with Adi.Window;

package Adi.Widget.Context_Menu is

   type Context_Menu is abstract tagged limited private;
   type Context_Menu_Access is access all Context_Menu'Class;

   ---------------------------------------------------------------------------
   --  Handle Store (generational IDs, deferred destroy, borrow pinning)
   ---------------------------------------------------------------------------

   type Menu_Handle is private;
   Null_Menu_Handle : constant Menu_Handle;

   function Is_Valid    (H : Menu_Handle) return Boolean;
   procedure Destroy    (H : in out Menu_Handle);
   function Get_Handle  (M : Context_Menu) return Menu_Handle;

   --  Drain deferred menu destroys (call once per frame from App.Run)
   procedure Pump_Menu_Store;

   ---------------------------------------------------------------------------

   type Item_Selected_Callback is access procedure
     (Menu  : Menu_Handle;
      Index : Positive;
      Text  : String);

   package Item_Selected_Signals is new Adi.Signal
     (Item_Selected_Callback, null);

   function Create return Context_Menu_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle return Menu_Handle;
   function Resolve_Menu_Handle (H : Menu_Handle) return Context_Menu_Access
     with Obsolescent => "Bridge only; prefer Menu_Handle APIs";

   procedure Attach_Window
     (Menu : in out Context_Menu;
      Host : Adi.Window.Window_Access)
     with Obsolescent => "Use Attach_Window with Window_Handle";
   procedure Attach_Window
     (Menu : in out Context_Menu;
      Host : Adi.Window.Window_Handle);
   procedure Attach_Window
     (Menu : Menu_Handle;
      Host : Adi.Window.Window_Access)
     with Obsolescent => "Use Attach_Window (Menu : Menu_Handle; Host : Window_Handle)";
   procedure Attach_Window
     (Menu : Menu_Handle;
      Host : Adi.Window.Window_Handle);

   procedure Add_Item
     (Menu : in out Context_Menu;
      Text : String);
   procedure Add_Item
     (Menu : Menu_Handle;
      Text : String);
   procedure Clear_Items (Menu : in out Context_Menu);
   procedure Clear_Items (Menu : Menu_Handle);
   function Item_Count (Menu : Context_Menu) return Natural;

   procedure Set_Item_Disabled
     (Menu     : in out Context_Menu;
      Index    : Positive;
      Disabled : Boolean);
   procedure Set_Item_Disabled
     (Menu     : Menu_Handle;
      Index    : Positive;
      Disabled : Boolean);
   function Is_Item_Disabled
     (Menu  : Context_Menu;
      Index : Positive) return Boolean;
   function Is_Item_Disabled
     (Menu  : Menu_Handle;
      Index : Positive) return Boolean;

   procedure Connect_Item_Selected
     (Menu : in out Context_Menu; CB : Item_Selected_Callback);
   function Connect_Item_Selected
     (Menu : in out Context_Menu; CB : Item_Selected_Callback)
      return Item_Selected_Signals.Connection_Id;
   procedure Disconnect_Item_Selected
     (Menu : in out Context_Menu;
      Id   : Item_Selected_Signals.Connection_Id);
   procedure Connect_Item_Selected
     (Menu : Menu_Handle; CB : Item_Selected_Callback);
   function Connect_Item_Selected
     (Menu : Menu_Handle; CB : Item_Selected_Callback)
      return Item_Selected_Signals.Connection_Id;
   procedure Disconnect_Item_Selected
     (Menu : Menu_Handle;
      Id   : Item_Selected_Signals.Connection_Id);

   procedure Set_Menu_Part_Styles
     (Menu   : in out Context_Menu;
      Styles : Adi.Widget.Part_Style_Array);
   procedure Set_Menu_Part_Styles
     (Menu   : Menu_Handle;
      Styles : Adi.Widget.Part_Style_Array);
   procedure Set_Item_Part_Styles
     (Menu   : in out Context_Menu;
      Styles : Adi.Widget.Part_Style_Array);
   procedure Set_Item_Part_Styles
     (Menu   : Menu_Handle;
      Styles : Adi.Widget.Part_Style_Array);

   --  Package-level defaults — apply to all context menus that don't have
   --  per-instance styles set via Set_Menu_Part_Styles / Set_Item_Part_Styles.
   procedure Set_Default_Menu_Styles (Styles : Adi.Widget.Part_Style_Array);
   procedure Set_Default_Item_Styles (Styles : Adi.Widget.Part_Style_Array);
   function Has_Default_Menu_Styles return Boolean;
   function Has_Default_Item_Styles return Boolean;

   procedure Show_At
     (Menu      : in out Context_Menu;
      X, Y      : Pixel_Type;
      Min_Width : Pixel_Type := 140.0);
   procedure Show_At
     (Menu      : Menu_Handle;
      X, Y      : Pixel_Type;
      Min_Width : Pixel_Type := 140.0);
   procedure Hide (Menu : in out Context_Menu);
   procedure Hide (Menu : Menu_Handle);
   function Is_Shown (Menu : Context_Menu) return Boolean;
   function Is_Shown (Menu : Menu_Handle) return Boolean;

private
   package String_Vectors is new Ada.Containers.Vectors
     (Positive, Ada.Strings.Unbounded.Unbounded_String);

   package Bool_Vectors is new Ada.Containers.Vectors (Positive, Boolean);

   package Part_Style_Holders is new Ada.Containers.Indefinite_Holders
     (Adi.Widget.Part_Style_Array);

   package Popup_Lists is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget);

   type Context_Menu is tagged limited record
      Host_Window : Adi.Window.Window_Access := null;
      Popup       : Popup_Lists.List_Box_Handle := Popup_Lists.Null_List_Box_Handle;
      Items       : String_Vectors.Vector;
      Disabled    : Bool_Vectors.Vector;
      Row_Styles  : Part_Style_Holders.Holder;
      Open        : Boolean := False;
      Item_Selected : Item_Selected_Signals.Signal;

      --  Handle store slot (raw Naturals; Menu_Stores after full type)
      Store_Index : Natural := 0;
      Store_Gen   : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   --  Menu Handle Store instantiation (after Context_Menu full definition)
   ---------------------------------------------------------------------------

   package Menu_Stores is new Adi.Handle_Store
     (Context_Menu, Context_Menu_Access);

   type Menu_Handle is record
      Id : Menu_Stores.Object_Id := Menu_Stores.Null_Id;
   end record;

   Null_Menu_Handle : constant Menu_Handle := (Id => Menu_Stores.Null_Id);

end Adi.Widget.Context_Menu;
