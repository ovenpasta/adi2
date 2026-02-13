with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.Widget_Styles;     use Adi.Widget_Styles;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Animation;         use Adi.Animation;
with Adi.Font;
with Adi.Layout_Util;       use Adi.Layout_Util;
with Adi.SDL.Render;        use Adi.SDL.Render;
with Adi.SDL.TTF;
with Adi.SDL.TTF.TextEngine;
with Adi.SDL.Events;
with Adi.Render;            use Adi.Render;
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

      --  Optional explicit per-item style. When enabled, this style is used
      --  directly and part-based style resolution/animation does not override
      --  the item's computed style.
      Has_Style_Override : Boolean := False;
      Style_Override     : Resolved_Style := Resolve (Empty_Style);

      --  Text_Item fields (unused by other kinds)
      Text_Content   : Unbounded_String := Null_Unbounded_String;
      Wrap_Text      : Boolean := True;
      Text_Offset_X  : Pixel_Type := 0.0;
      Text_Offset_Y  : Pixel_Type := 0.0;

      --  Image_Item fields (unused by other kinds)
      Image_Source   : Image_Access := null;
      Is_Background  : Boolean := False;

      --  Text rendering cache (only used by Text_Item)
      Cached_TTF_Text    : Adi.SDL.TTF.TextEngine.TTF_Text_Access := null;
      Cached_Text_String : Unbounded_String := Null_Unbounded_String;
      Cached_Font        : Adi.SDL.TTF.TTF_Font_Access := null;
      Cached_Font_Attrs  : Adi.Font.Font_Attributes :=
        Adi.Font.Default_Font_Attributes;
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
   procedure Set_Part_State (W : in out Widget'Class;
                             P : Part_Kind;
                             S : Widget_State;
                             Active : Boolean);
   function Get_Part_States (W : Widget'Class; P : Part_Kind) return Widget_States;
   procedure Clear_States (W : in out Widget'Class);
   procedure Clear_Part_States (W : in out Widget'Class);

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
   function Get_Part_At (W : Widget'Class;
                         X, Y : Pixel_Type) return Part_Kind;

   ---------------------------------------------------------------------------
   --  Hierarchy Management
   ---------------------------------------------------------------------------

   procedure Add_Child (W : in out Widget'Class; C : access Widget'Class);
   procedure Remove_Child (W : in out Widget'Class; C : access Widget'Class);
   procedure Set_Parent (W : in out Widget'Class; P : access Widget'Class);
   function  Get_Parent (W : Widget'Class) return access Widget'Class;
   function  Child_Count (W : Widget'Class) return Natural;
   function Get_Child (W : Widget'Class; Index : Positive) return Widget_Access;

   ---------------------------------------------------------------------------
   --  Geometry and Layout
   ---------------------------------------------------------------------------

   procedure Set_Geometry (W : in out Widget'Class; G : Rectangle);
   function  Get_Geometry (W : Widget'Class) return Rectangle;
   function  Get_Content_Box (W : Widget'Class) return Rectangle;

   ---------------------------------------------------------------------------
   --  Shared Vertical Scrolling (overflow-y)
   ---------------------------------------------------------------------------

   procedure Set_Scroll_Offset_Y (W : in out Widget'Class; Offset : Pixel_Type);
   function  Get_Scroll_Offset_Y (W : Widget'Class) return Pixel_Type;
   procedure Scroll_By_Y (W : in out Widget'Class; Delta_Y : Pixel_Type);
   function  Get_Scroll_Content_Height (W : Widget'Class) return Pixel_Type;
   function  Get_Scroll_Max_Offset_Y (W : Widget'Class) return Pixel_Type;

   --  Reusable input hooks for widgets that override mouse handlers but still
   --  want the shared scrollbar behavior.
   function Handle_Scroll_Mouse_Down
     (W      : in out Widget'Class;
      X, Y   : Pixel_Type;
      Button : Mouse_Button) return Boolean;
   procedure Handle_Scroll_Mouse_Move
     (W    : in out Widget'Class;
      X, Y : Pixel_Type);
   procedure Handle_Scroll_Mouse_Up
     (W      : in out Widget'Class;
      Button : Mouse_Button);
   procedure Handle_Scroll_Mouse_Wheel
     (W                : in out Widget'Class;
      Delta_X, Delta_Y : Pixel_Type);
   procedure Tick_Scroll_Animations (W : in out Widget'Class; DT : Duration);
   procedure Update_Scrollbar_Geometry (W : in out Widget'Class);
   --  Controls inertial/momentum continuation after wheel/drag input.
   --  When disabled, scrolling remains immediate and deterministic.
   procedure Set_Scroll_Inertia_Enabled (Enabled : Boolean := True);
   function Get_Scroll_Inertia_Enabled return Boolean;
   --  Draws widget/item debug overlays (margin/padding/content outlines).
   --  Disabled by default and intended for interactive diagnostics only.
   procedure Set_Debug_Layout_Overlay_Enabled (Enabled : Boolean := True);
   function Get_Debug_Layout_Overlay_Enabled return Boolean;

   ---------------------------------------------------------------------------
   --  Flags
   ---------------------------------------------------------------------------

   procedure Set_Flag (W : in out Widget'Class; F : Widget_Flag; Value : Boolean);
   function  Has_Flag (W : Widget'Class; F : Widget_Flag) return Boolean;

   ---------------------------------------------------------------------------
   --  Context Menu Routing
   ---------------------------------------------------------------------------

   type Context_Menu_Callback is access procedure
     (W    : Widget_Access;
      X, Y : Pixel_Type);

   procedure Set_On_Context_Menu
     (W  : in out Widget'Class;
      CB : Context_Menu_Callback);
   function Has_Context_Menu (W : Widget'Class) return Boolean;
   function Show_Context_Menu
     (W    : in out Widget'Class;
      X, Y : Pixel_Type) return Boolean;
   function Bubble_Context_Menu
     (Start : Widget_Access;
      X, Y  : Pixel_Type) return Boolean;

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
   procedure Render_Items (W : in out Widget'Class; Ctx : in out Render_Context);

   --  Render this widget and all children recursively
   procedure Render_Tree (W : in out Widget'Class; Ctx : in out Render_Context);

   --  Full update and render cycle
   procedure Update_And_Render (W : in out Widget'Class; Ctx : in out Render_Context);

   --  Handle layout calculation
   procedure Layout (W : in out Widget) is abstract;

   --  Called when the widget is clicked (mouse-up within bounds of clickable widget)
   --  Default does nothing; override in derived widgets (e.g., Button).
   procedure On_Click (W : in out Widget) is null;

   --  Called for mouse interaction routed by the window.
   procedure On_Mouse_Down
     (W      : in out Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   procedure On_Mouse_Move
     (W    : in out Widget;
      X, Y : Pixel_Type);
   procedure On_Mouse_Up
     (W      : in out Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button);
   procedure On_Mouse_Wheel
     (W              : in out Widget;
      Delta_X, Delta_Y : Pixel_Type);

   --  Called for key down events when this widget has focus.
   procedure On_Key_Down
     (W        : in out Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean) is null;

   --  Called for key up events when this widget has focus.
   procedure On_Key_Up
     (W        : in out Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean) is null;

   --  Called for text input events when this widget has focus.
   procedure On_Text_Input (W : in out Widget; Text : String) is null;

   --  Called when this widget gains/loses keyboard focus.
   procedure On_Focus_Gained (W : in out Widget) is null;
   procedure On_Focus_Lost (W : in out Widget) is null;

   ---------------------------------------------------------------------------
   --  Optional Overridable Methods
   ---------------------------------------------------------------------------

   --  Called when state changes (default: marks dirty and reapplies styles)
   procedure On_State_Changed (W : in out Widget'Class;
                               S : Widget_State;
                               Active : Boolean);

   --  Called when geometry changes (default: marks dirty)
   procedure On_Geometry_Changed (W : in out Widget'Class);

   --  Per-frame callback (default: no-op). DT is in seconds.
   procedure On_Tick (W : in out Widget; DT : Duration);

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
                        Z_Order : Natural := 0;
                        Is_Background : Boolean := False) return Item;

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

   ---------------------------------------------------------------------------
   --  Animation
   ---------------------------------------------------------------------------

   --  Advance all active transitions by DT seconds, recursing to children
   procedure Tick_Animations (W : in out Widget'Class; DT : Duration);
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

   --  Animation state per part
   type Part_Transition_Array is array (Part_Kind) of Part_Transition;
   type Part_Resolved_Array is array (Part_Kind) of Resolved_Style;
   type Part_Initialized_Array is array (Part_Kind) of Boolean;
   type Part_State_Array is array (Part_Kind) of Widget_States;

   type Widget is abstract tagged limited record
      --  Hierarchy
      Parent   : access Widget'Class := null;
      Children : Widget_List.List;

      --  Geometry
      Geometry : Rectangle := (0.0, 0.0, 0.0, 0.0);

      --  State
      States      : Widget_States := No_States;
      Part_States : Part_State_Array := [others => No_States];
      Dirty       : Boolean := True;
      Flags       : Widget_Flags := Default_Flags;

      --  Styling - each part has its own Widget_Style
      Part_Styles : Part_Style_Array := Empty_Part_Styles;

      --  Renderable items (built by derived widgets)
      Items : Items_List.Vector;

      --  Cached images for rendering
      Images : Image_List.List;

      --  Animation state
      Transitions       : Part_Transition_Array := [others => No_Part_Transition];
      Last_Target       : Part_Resolved_Array;
      Last_Target_Init  : Part_Initialized_Array := [others => False];
      Has_Any_Animation : Boolean := False;

      --  Shared vertical scrolling state for overflow:auto/scroll
      Scroll_Offset_Y     : Pixel_Type := 0.0;
      Scroll_Content_H    : Pixel_Type := 0.0;
      Scroll_Viewport_H   : Pixel_Type := 0.0;
      Scroll_Track_Geom   : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Scroll_Knob_Geom    : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Scroll_Show_Bar     : Boolean := False;
      Scroll_Dragging     : Boolean := False;
      Scroll_Drag_Offset  : Pixel_Type := 0.0;
      Scroll_Velocity_Y   : Pixel_Type := 0.0;
      On_Context_Menu     : Context_Menu_Callback := null;
   end record;

   --  Color conversion helpers (CSS Color_Value to SDL RGBA)
   procedure CSS_Color_To_SDL
      (C : Color_Value;
       R, G, B, A : out Adi.SDL.Uint8);

end Adi.Widget;
