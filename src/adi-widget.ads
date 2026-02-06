with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.Widget_Styles;     use Adi.Widget_Styles;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.Render;        use Adi.SDL.Render;
with Adi.SDL.TTF.TextEngine;
with Adi.Image;             use Adi.Image;

package Adi.Widget is
   pragma Elaborate_Body;

   ---------------------------------------------------------------------------
   --  Forward Declarations and Access Types
   ---------------------------------------------------------------------------

   type Widget is abstract tagged limited private;
   type Widget_Access is access all Widget'Class;

   ---------------------------------------------------------------------------
   --  Part Kinds - Logical regions of a widget that can be styled
   ---------------------------------------------------------------------------

   type Part_Kind is
     (Main_Part,        --  Primary widget area (background, border)
      Indicator_Part,   --  Checkbox check, radio dot, toggle indicator
      Scroll_Part,      --  Scrollbar track
      Knob_Part,        --  Scrollbar thumb, slider handle
      Selected_Part,    --  Selected item highlight
      Items_Part,       --  Container for list/menu items
      Cursor_Part,      --  Text cursor in input fields
      Label_Part,       --  Text label area
      Icon_Part,        --  Icon/image area
      Any_Part,         --  Matches any part (for generic rules)
      Custom_Part);     --  User-defined parts


   ---------------------------------------------------------------------------
   --  Widget Flags
   ---------------------------------------------------------------------------

   type Widget_Flag is (Clickable, Focusable, Scrollable, Draggable, Visible);
   type Widget_Flags is array (Widget_Flag) of Boolean;

   Default_Flags : constant Widget_Flags := (Visible => True, others => False);

   ---------------------------------------------------------------------------
   --  Item Types - Renderable primitives that compose a widget
   --  Each item references a Part and will be styled via the part's style
   ---------------------------------------------------------------------------

   type Item_Kind is (Panel_Item, Text_Item, Image_Item);


   type Item is record
      Kind           : Item_Kind := Panel_Item;
      Geometry       : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Part           : Part_Kind := Main_Part;
      Z_Order        : Natural := 0;

      --  Computed style (resolved from part style + widget states)
      Computed_Style : Resolved_Style;

      --  Text_Item fields (unused by other kinds)
      Text_Content   : Unbounded_String := Null_Unbounded_String;

      --  Image_Item fields (unused by other kinds)
      Image_Source   : Image_Access := null;

      --  Text rendering cache (only used by Text_Item)
      Cached_TTF_Text    : Adi.SDL.TTF.TextEngine.TTF_Text_Access := null;
      Cached_Text_String : Unbounded_String := Null_Unbounded_String;
   end record;

   package Items_List is new
     Ada.Containers.Vectors (Positive, Item);

   ---------------------------------------------------------------------------
   --  Layout Items - Items that can participate in flex layout
   ---------------------------------------------------------------------------

   --  Flex properties for a layout item
   type Flex_Item_Properties is record
      Grow       : Float := 0.0;   -- flex-grow (default 0 = don't grow)
      Shrink     : Float := 1.0;   -- flex-shrink (default 1 = can shrink)
      Basis      : Float := 0.0;   -- flex-basis in pixels (default auto = 0)
      Align_Self : Align_Self_Value := Auto;  -- Override container alignment
   end record;

   --  A layout item represents a logical element that will be positioned
   --  by the flex layout algorithm and then rendered as an Item
   type Layout_Item is record
      Part        : Part_Kind := Main_Part;

      --  Size constraints
      Min_Width   : Float := 0.0;
      Min_Height  : Float := 0.0;
      Max_Width   : Float := Float'Last;
      Max_Height  : Float := Float'Last;

      --  Preferred/content size (intrinsic size)
      Content_Width  : Float := 0.0;
      Content_Height : Float := 0.0;

      --  Flex properties
      Flex        : Flex_Item_Properties;

      --  Calculated geometry (output of layout algorithm)
      Geometry    : Rectangle := (0.0, 0.0, 0.0, 0.0);

      --  User data to identify this item when creating renderable Items
      Index       : Natural := 0;  -- Can be used to identify which item this is
   end record;

   package Layout_Item_List is new
     Ada.Containers.Vectors (Positive, Layout_Item);

   ---------------------------------------------------------------------------
   --  Part Style Record - Associates a Widget_Style with each part
   ---------------------------------------------------------------------------

   type Part_Style is record
      Style   : Widget_Style := Empty_Widget_Style;
      Enabled : Boolean := True;
   end record;

   type Part_Style_Array is array (Part_Kind) of Part_Style;

   Empty_Part_Styles : constant Part_Style_Array := (others => <>);

   ---------------------------------------------------------------------------
   --  Widget State Management
   ---------------------------------------------------------------------------

   procedure Set_State (W : in out Widget'Class; S : Widget_State; Active : Boolean);
   function  Has_State (W : Widget'Class; S : Widget_State) return Boolean;
   function  Get_States (W : Widget'Class) return Widget_States;
   procedure Clear_States (W : in out Widget'Class);

   --  Convenience state setters
   procedure Set_Hovered (W : in out Widget'Class; Value : Boolean := True);
   procedure Set_Pressed (W : in out Widget'Class; Value : Boolean := True);
   procedure Set_Focused (W : in out Widget'Class; Value : Boolean := True);
   procedure Set_Disabled (W : in out Widget'Class; Value : Boolean := True);
   procedure Set_Selected (W : in out Widget'Class; Value : Boolean := True);

   ---------------------------------------------------------------------------
   --  Part Style Management
   ---------------------------------------------------------------------------

   procedure Set_Part_Style (W : in out Widget'Class;
                             P : Part_Kind;
                             S : Widget_Style);

   procedure Set_Part_Styles (W : in out Widget'Class;
                              Styles : Part_Style_Array);

   function Get_Part_Style (W : Widget'Class;
                            P : Part_Kind) return Widget_Style;

   --  Get the Style_Rules for a part (before resolution)
   function Get_Part_Style_Rules (W : Widget'Class;
                                  P : Part_Kind) return Style_Rules;

   --  Get computed/resolved style for a part given current widget states
   function Get_Resolved_Part_Style (W : Widget'Class;
                                     P : Part_Kind) return Resolved_Style;

   ---------------------------------------------------------------------------
   --  Item Management
   ---------------------------------------------------------------------------

   procedure Add_Item (W : in out Widget'Class; I : Item);
   procedure Clear_Items (W : in out Widget'Class);
   procedure Update_Item (W : in out Widget'Class;
                          Index : Positive;
                          I : Item);
   function  Item_Count (W : Widget'Class) return Natural;
   function  Get_Item (W : Widget'Class; Index : Positive) return Item;

   --  Apply current part styles to all items (recomputes Computed_Style)
   procedure Apply_Styles_To_Items (W : in out Widget'Class);

   --  Get items filtered by part
   function Get_Items_For_Part (W : Widget'Class;
                                P : Part_Kind) return Items_List.Vector;

   ---------------------------------------------------------------------------
   --  Hierarchy Management
   ---------------------------------------------------------------------------

   procedure Add_Child (W : in out Widget'Class; C : Widget_Access);
   procedure Remove_Child (W : in out Widget'Class; C : Widget_Access);
   procedure Set_Parent (W : in out Widget'Class; P : access Widget'Class);
   function  Get_Parent (W : Widget'Class) return access Widget'Class;
   function  Child_Count (W : Widget'Class) return Natural;
   function Get_Child (W : Widget'Class; Index : Positive) return Widget_Access;

   ---------------------------------------------------------------------------
   --  Geometry and Layout
   ---------------------------------------------------------------------------

   procedure Set_Geometry (W : in out Widget'Class; G : Rectangle);
   function  Get_Geometry (W : Widget'Class) return Rectangle;

   ---------------------------------------------------------------------------
   --  Flags
   ---------------------------------------------------------------------------

   procedure Set_Flag (W : in out Widget'Class; F : Widget_Flag; Value : Boolean);
   function  Has_Flag (W : Widget'Class; F : Widget_Flag) return Boolean;

   ---------------------------------------------------------------------------
   --  Dirty/Update Tracking
   ---------------------------------------------------------------------------

   procedure Mark_Dirty (W : in out Widget'Class);
   procedure Mark_Clean (W : in out Widget'Class);
   function  Is_Dirty (W : Widget'Class) return Boolean;

   ---------------------------------------------------------------------------
   --  Abstract Methods - Must be implemented by derived widgets
   ---------------------------------------------------------------------------

   --  Render items to the scene graph/renderer
   procedure Build_Items (W : in out Widget) is abstract;

   ---------------------------------------------------------------------------
   --  Concrete Rendering - Generic for all widgets
   ---------------------------------------------------------------------------

   --  Render all items of this widget using SDL renderer
   procedure Render_Items (W : in out Widget'Class; Renderer : SDL_Renderer_Ptr);

   --  Render this widget and all children recursively
   procedure Render_Tree (W : in out Widget'Class; Renderer : SDL_Renderer_Ptr);

   --  Full update and render cycle
   procedure Update_And_Render (W : in out Widget'Class; Renderer : SDL_Renderer_Ptr);

   --  Handle layout calculation
   procedure Layout (W : in out Widget) is abstract;

   ---------------------------------------------------------------------------
   --  Optional Overridable Methods
   ---------------------------------------------------------------------------

   --  Called when state changes (default: marks dirty and reapplies styles)
   procedure On_State_Changed (W : in out Widget'Class;
                               S : Widget_State;
                               Active : Boolean);

   --  Called when geometry changes (default: marks dirty)
   procedure On_Geometry_Changed (W : in out Widget'Class);

   ---------------------------------------------------------------------------
   --  Update/Render Cycle
   ---------------------------------------------------------------------------

   --  Full update: rebuild items if dirty, apply styles, prepare for render
   procedure Update (W : in out Widget'Class);


   ---------------------------------------------------------------------------
   --  Item Creation Helpers
   ---------------------------------------------------------------------------

   function Make_Panel (Part : Part_Kind;
                        Geometry : Rectangle;
                        Z_Order : Natural := 0) return Item;

   function Make_Text (Part : Part_Kind;
                       Geometry : Rectangle;
                       Content : String;
                       Z_Order : Natural := 0) return Item;

   function Make_Image (Part : Part_Kind;
                        Geometry : Rectangle;
                        Source : Image_Access;
                        Z_Order : Natural := 0) return Item;

    ---------------------------------------------------------------------------
   --  Content Measurement
   ---------------------------------------------------------------------------

   function Measure_Content(W : Widget) return Size_2D;
   function Get_Min_Size(W : Widget'Class) return Size_2D;
   function Get_Preferred_Size(W : Widget'Class) return Size_2D;

   ---------------------------------------------------------------------------
   --  Flex Layout
   ---------------------------------------------------------------------------

   procedure Perform_Flex_Layout(W : in out Widget'Class);

   --  Item-based flex layout: positions a list of Layout_Items based on
   --  flex properties. This allows widgets to use flex layout for their
   --  internal items (not just child widgets).
   procedure Perform_Item_Flex_Layout
      (Container_Geom  : Rectangle;
       Container_Style : Resolved_Style;
       Items           : in out Layout_Item_List.Vector);

   --  Check if widget uses flex display
   function Is_Flex_Container(W : Widget'Class) return Boolean;
   procedure Rebuild_All_Items (W : in out Widget'Class);
   procedure Layout_Tree (W : in out Widget'Class);
private

   ---------------------------------------------------------------------------
   --  Private Package Instantiations
   ---------------------------------------------------------------------------

   package Widget_List is new
     Ada.Containers.Doubly_Linked_Lists (Widget_Access);

   package Image_List is new
     Ada.Containers.Doubly_Linked_Lists (Image_Access);

   ---------------------------------------------------------------------------
   --  Widget Record
   ---------------------------------------------------------------------------

   type Widget is abstract tagged limited record
      --  Hierarchy
      Parent   : access Widget'Class := null;
      Children : Widget_List.List;

      --  Geometry
      Geometry : Rectangle := (0.0, 0.0, 100.0, 100.0);

      --  State
      States : Widget_States := No_States;
      Dirty  : Boolean := True;
      Flags  : Widget_Flags := Default_Flags;

      --  Styling - each part has its own Widget_Style
      Part_Styles : Part_Style_Array := Empty_Part_Styles;

      --  Renderable items (built by derived widgets)
      Items : Items_List.Vector;

      --  Cached images for rendering
      Images : Image_List.List;
   end record;

   --  Color conversion helpers (CSS Color_Value to SDL RGBA)
   procedure CSS_Color_To_SDL
      (C : Color_Value;
       R, G, B, A : out Adi.SDL.Uint8);

end Adi.Widget;
