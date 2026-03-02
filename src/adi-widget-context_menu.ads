with Ada.Containers.Indefinite_Holders;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.Signal;
with Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with Adi.Window;

package Adi.Widget.Context_Menu is

   type Context_Menu is tagged limited private;
   type Context_Menu_Access is access all Context_Menu;

   type Item_Selected_Callback is access procedure
     (Menu  : Context_Menu_Access;
      Index : Positive;
      Text  : String);

   package Item_Selected_Signals is new Adi.Signal
     (Item_Selected_Callback, null);

   function Create return Context_Menu_Access;

   procedure Attach_Window
     (Menu : in out Context_Menu;
      Host : Adi.Window.Window_Access);

   procedure Add_Item
     (Menu : in out Context_Menu;
      Text : String);
   procedure Clear_Items (Menu : in out Context_Menu);
   function Item_Count (Menu : Context_Menu) return Natural;

   procedure Connect_Item_Selected
     (Menu : in out Context_Menu; CB : Item_Selected_Callback);
   function Connect_Item_Selected
     (Menu : in out Context_Menu; CB : Item_Selected_Callback)
      return Item_Selected_Signals.Connection_Id;
   procedure Disconnect_Item_Selected
     (Menu : in out Context_Menu;
      Id   : Item_Selected_Signals.Connection_Id);

   procedure Set_Menu_Part_Styles
     (Menu   : in out Context_Menu;
      Styles : Adi.Widget.Part_Style_Array);
   procedure Set_Item_Part_Styles
     (Menu   : in out Context_Menu;
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
   procedure Hide (Menu : in out Context_Menu);
   function Is_Shown (Menu : Context_Menu) return Boolean;

private
   package String_Vectors is new Ada.Containers.Vectors
     (Positive, Ada.Strings.Unbounded.Unbounded_String);

   package Part_Style_Holders is new Ada.Containers.Indefinite_Holders
     (Adi.Widget.Part_Style_Array);

   package Popup_Lists is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget,
      Adi.Widget.Label.Label_Widget_Access);

   type Context_Menu is tagged limited record
      Host_Window : Adi.Window.Window_Access := null;
      Popup       : Popup_Lists.List_Box_Widget_Access := null;
      Items       : String_Vectors.Vector;
      Row_Styles  : Part_Style_Holders.Holder;
      Open        : Boolean := False;
      Item_Selected : Item_Selected_Signals.Signal;
   end record;

end Adi.Widget.Context_Menu;
