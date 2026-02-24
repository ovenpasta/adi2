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

   --  Construction
   function Create return Stack_Widget_Access;

   --  Add a page keyed by its Id. First page added becomes active.
   procedure Add_Page (W : in out Stack_Widget; Id : Page_Id; Page : access Widget'Class);

   --  Active page management
   procedure Set_Active (W : in out Stack_Widget; Id : Page_Id);
   function  Get_Active (W : Stack_Widget) return Page_Id;
   function  Get_Active_Widget (W : Stack_Widget) return Widget_Access;

   --  Get page widget by Id. Returns null if the page was never added.
   function  Get_Page (W : Stack_Widget; Id : Page_Id) return Widget_Access;

   --  Callback when active page changes
   type Page_Changed_Callback is access procedure (Id : Page_Id);
   procedure Set_On_Changed (W  : in out Stack_Widget;
                              CB : Page_Changed_Callback);

   --  Implement abstract methods
   overriding function Measure_Content (W : Stack_Widget) return Size_2D;
   overriding function Get_Min_Size (W : Stack_Widget) return Size_2D;
   overriding procedure Build_Items (W : in out Stack_Widget);
   overriding procedure Layout (W : in out Stack_Widget);

private

   Panel_Idx : constant Positive := 1;

   type Page_Array is array (Page_Id) of Widget_Access;

   type Stack_Widget is new Widget with record
      Pages      : Page_Array := [others => null];
      Active     : Page_Id := Page_Id'First;
      Has_Active : Boolean := False;
      On_Changed : Page_Changed_Callback := null;
   end record;

end Adi.Widget.Stack;
