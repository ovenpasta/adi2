--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.Core;              use Adi.Core;
with Adi.Widget_Styles;     use Adi.Widget_Styles;
with Adi.CSS_Styles;        use Adi.CSS_Styles;
with Adi.Animation;         use Adi.Animation;
with Adi.Font;
with Adi.SDL.TTF;
with Adi.SDL.TTF.TextEngine;
with Adi.SDL.Events;
with Adi.Signal;
with Adi.Render;            use Adi.Render;
with Adi.Image;             use Adi.Image;
with Ada.Containers;
with Ada.Finalization;
with Adi.Handle_Store;

package Adi.Widget is
   pragma Elaborate_Body;

   ---------------------------------------------------------------------------
   --  Forward Declarations and Access Types
   ---------------------------------------------------------------------------

   type Widget is abstract tagged limited private;

   ---------------------------------------------------------------------------
   --  Handle Store (generational IDs, deferred destroy, borrow pinning)
   --  Widget_Handle is opaque; internal code uses Widget_Stores (private).
   ---------------------------------------------------------------------------

   type Widget_Handle is private;
   Null_Handle : constant Widget_Handle;

   function Is_Valid    (H : Widget_Handle) return Boolean;

   --  A key for keying maps on handles. Does not resolve the handle, so
   --  it stays usable once the widget is gone.
   function Hash (H : Widget_Handle) return Ada.Containers.Hash_Type;
   procedure Destroy    (H : in out Widget_Handle);
   function Get_Handle  (W : Widget'Class) return Widget_Handle;

   --  Drain deferred widget destroys (call once per frame from App.Run)
   procedure Pump_Widget_Store;

   --  Fired after a widget's scroll offset changes, carrying the widget
   --  that scrolled. Overlays anchored to a widget's geometry — combo
   --  dropdowns — need this because scrolling only marks rendering
   --  dirty, so layout, where such overlays are placed, does not re-run
   --  and the overlay is left behind.
   --
   --  A signal rather than a single hook: more than one subsystem may
   --  care, and knowing which widget scrolled lets each ignore the ones
   --  that cannot affect it instead of re-examining everything.
   --
   --  Fires for every widget. The scrolled widget is passed as a
   --  pointer, not a handle, because parent links are pointers too: the
   --  library's own Add_Child/Set_Parent on Widget'Class allow
   --  unregistered widgets in the tree, and those have no handle to
   --  report or walk through.
   --
   --  This is the one callback in the public API that carries a widget
   --  as a pointer. Scrolled is borrowed for the length of the call
   --  only: widgets need not be heap-allocated, so an observer that
   --  stores the pointer can end up with a dangling one. Take a
   --  Widget_Handle instead if the widget is registered and something
   --  has to outlive the callback.
   type Scroll_Observer is access procedure
     (Scrolled : not null access Widget'Class);
   package Scroll_Signals is new Adi.Signal (Scroll_Observer, null);

   procedure Connect_Scroll_Changed (CB : Scroll_Observer);
   function Connect_Scroll_Changed
     (CB : Scroll_Observer) return Scroll_Signals.Connection_Id;
   procedure Disconnect_Scroll_Changed
     (Id : Scroll_Signals.Connection_Id);

   ---------------------------------------------------------------------------
   --  Common Widget_Handle base overloads
   --  No-op on stale handles; Boolean returns False, Natural returns 0.
   ---------------------------------------------------------------------------

   procedure Set_Visible  (H : Widget_Handle; Value : Boolean);
   function  Is_Visible   (H : Widget_Handle) return Boolean;
   procedure Set_Disabled (H : Widget_Handle; Value : Boolean := True);
   function  Is_Disabled  (H : Widget_Handle) return Boolean;
   procedure Set_Focusable (H : Widget_Handle; Value : Boolean);
   procedure Set_Label    (H : Widget_Handle; Label : String);
   function  Get_Label    (H : Widget_Handle) return String;
   procedure Mark_Dirty   (H : Widget_Handle);

   ---------------------------------------------------------------------------
   --  Scoped Borrow  (Implicit_Dereference)
   --
   --  Pin a widget for the lifetime of the returned Ref.  While the Ref is
   --  alive, Request_Destroy is deferred so the pointer stays valid.
   --  Raises Constraint_Error when H is Null_Handle or stale.
   ---------------------------------------------------------------------------

   type Widget_Ref (Ptr : access Widget'Class) is
     limited new Ada.Finalization.Limited_Controlled with private
     with Implicit_Dereference => Ptr;

   function Borrow (H : Widget_Handle) return Widget_Ref;

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
      Label_Part,       --  Auxiliary/display label region
      Text_Part,        --  Text content in editable/selectable inputs
      Icon_Part,        --  Icon/image area
      Any_Part,         --  Matches any part (for generic rules)
      Custom_Part);     --  User-defined parts


   ---------------------------------------------------------------------------
   --  Widget Flags
   ---------------------------------------------------------------------------

   type Widget_Flag is (Clickable, Focusable, Scrollable, Draggable, Visible);
   type Widget_Flags is array (Widget_Flag) of Boolean;

   Default_Flags : constant Widget_Flags := [Visible => True, others => False];

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
      Image_Source   : Image_Handle := Null_Image_Handle;
      Is_Background  : Boolean := False;

      --  Text rendering cache (only used by Text_Item)
      Cached_TTF_Text    : Adi.SDL.TTF.TextEngine.TTF_Text_Access := null;
      Cached_Text_String : Unbounded_String := Null_Unbounded_String;
      Cached_Font        : Adi.SDL.TTF.TTF_Font_Access := null;
      Cached_Font_Attrs  : Adi.Font.Font_Attributes :=
        Adi.Font.Default_Font_Attributes;
      --  Line-skip the cached TTF_Text was laid out with.  -1.0 sentinel
      --  forces a relayout on the first render.
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

   Empty_Part_Styles : constant Part_Style_Array := [others => <>];

   ---------------------------------------------------------------------------
   --  Unique Widget Identifier
   ---------------------------------------------------------------------------

   function Get_Id (H : Widget_Handle) return Natural;

   ---------------------------------------------------------------------------
   --  Widget State Management
   ---------------------------------------------------------------------------

   procedure Set_State (H : Widget_Handle; S : Widget_State; Active : Boolean);
   function  Has_State (H : Widget_Handle; S : Widget_State) return Boolean;
   function  Get_States (H : Widget_Handle) return Widget_States;
   procedure Set_Hovered (H : Widget_Handle; Value : Boolean := True);
   procedure Set_Pressed (H : Widget_Handle; Value : Boolean := True);
   procedure Set_Focused (H : Widget_Handle; Value : Boolean := True);
   procedure Set_Selected (H : Widget_Handle; Value : Boolean := True);

   ---------------------------------------------------------------------------
   --  Part Style Management
   ---------------------------------------------------------------------------

   procedure Set_Part_Style (H : Widget_Handle;
                             P : Part_Kind;
                             S : Widget_Style);
   procedure Set_Part_Styles (H : Widget_Handle;
                              Styles : Part_Style_Array);
   procedure Set_Part_Styles (W : in out Widget'Class;
                              Styles : Part_Style_Array);

   function Get_Part_Style (H : Widget_Handle;
                            P : Part_Kind) return Widget_Style;

   function Get_Part_Style_Rules (H : Widget_Handle;
                                  P : Part_Kind) return Style_Rules;

   function Get_Resolved_Part_Style (H : Widget_Handle;
                                     P : Part_Kind) return Resolved_Style;

   procedure Set_Part_State (H : Widget_Handle;
                             P : Part_Kind;
                             S : Widget_State;
                             Active : Boolean);

   ---------------------------------------------------------------------------
   --  Item Management (Widget'Class — used by widget implementations)
   ---------------------------------------------------------------------------

   procedure Add_Item (W : in out Widget'Class; I : Item);
   procedure Clear_Items (W : in out Widget'Class);
   procedure Update_Item (W : in out Widget'Class;
                          Index : Positive;
                          I : Item);
   function  Item_Count (H : Widget_Handle) return Natural;
   function  Item_Count (W : Widget'Class) return Natural;
   function  Get_Item (W : Widget'Class; Index : Positive) return Item;
   function  Get_Item (H : Widget_Handle; Index : Positive) return Item;

   --  Apply current part styles to all items (recomputes Computed_Style)
   procedure Apply_Styles_To_Items (W : in out Widget'Class);

   --  Get items filtered by part
   function Get_Items_For_Part (W : Widget'Class;
                                P : Part_Kind) return Items_List.Vector;
   function Get_Items_For_Part (H : Widget_Handle;
                                P : Part_Kind) return Items_List.Vector;
   function Get_Part_At (W : Widget'Class;
                         X, Y : Pixel_Type) return Part_Kind;
   function Get_Part_At (H : Widget_Handle;
                         X, Y : Pixel_Type) return Part_Kind;

   ---------------------------------------------------------------------------
   --  Hierarchy Management
   ---------------------------------------------------------------------------

   procedure Add_Child (Parent : Widget_Handle; Child : Widget_Handle);
   procedure Remove_Child (Parent : Widget_Handle; Child : Widget_Handle);
   procedure Set_Parent (W : Widget_Handle; P : Widget_Handle);
   function  Get_Parent_Handle (H : Widget_Handle) return Widget_Handle;
   function  Child_Count (H : Widget_Handle) return Natural;
   function  Get_Child_Handle (H : Widget_Handle; Index : Positive)
      return Widget_Handle;

   ---------------------------------------------------------------------------
   --  Geometry and Layout
   ---------------------------------------------------------------------------

   procedure Set_Geometry (H : Widget_Handle; G : Rectangle);
   function  Get_Geometry (H : Widget_Handle) return Rectangle;

   --  The area the layout calculated, which does not account for
   --  scrolling. Use it for Layout, Build_Items and input.
   function  Get_Geometry (W : Widget'Class) return Rectangle;

   ---------------------------------------------------------------------------
   --  Shared Vertical Scrolling (overflow-y)
   ---------------------------------------------------------------------------

   procedure Set_Scroll_Offset_Y (W : in out Widget'Class; Offset : Pixel_Type);
   procedure Set_Scroll_Offset_Y (H : Widget_Handle; Offset : Pixel_Type);
   function  Get_Scroll_Offset_Y (W : Widget'Class) return Pixel_Type;
   function  Get_Scroll_Offset_Y (H : Widget_Handle) return Pixel_Type;
   procedure Scroll_By_Y (W : in out Widget'Class; Delta_Y : Pixel_Type);
   function  Get_Scroll_Content_Height (H : Widget_Handle) return Pixel_Type;
   function  Get_Scroll_Max_Offset_Y (W : Widget'Class) return Pixel_Type;
   function  Get_Scroll_Max_Offset_Y (H : Widget_Handle) return Pixel_Type;

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
   function Handle_Scroll_Mouse_Down
     (H      : Widget_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button) return Boolean;
   procedure Handle_Scroll_Mouse_Move
     (H    : Widget_Handle;
      X, Y : Pixel_Type);
   procedure Handle_Scroll_Mouse_Up
     (H      : Widget_Handle;
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

   procedure Set_Flag (H : Widget_Handle; F : Widget_Flag; Value : Boolean);
   function  Has_Flag (H : Widget_Handle; F : Widget_Flag) return Boolean;

   ---------------------------------------------------------------------------
   --  Context Menu Routing
   ---------------------------------------------------------------------------

   type Context_Menu_Callback is access procedure
     (W    : Widget_Handle;
      X, Y : Pixel_Type);

   package Context_Menu_Signals is new Adi.Signal
     (Context_Menu_Callback, null);

   procedure Connect_Context_Menu
     (W : in out Widget'Class; CB : Context_Menu_Callback);
   procedure Connect_Context_Menu
     (H : Widget_Handle; CB : Context_Menu_Callback);
   function Connect_Context_Menu
     (W : in out Widget'Class; CB : Context_Menu_Callback)
      return Context_Menu_Signals.Connection_Id;
   procedure Disconnect_Context_Menu
     (W : in out Widget'Class; Id : Context_Menu_Signals.Connection_Id);
   function Has_Context_Menu (W : Widget'Class) return Boolean;
   function Has_Context_Menu (H : Widget_Handle) return Boolean;
   function Show_Context_Menu
     (W    : in out Widget'Class;
      X, Y : Pixel_Type) return Boolean;
   function Bubble_Context_Menu
     (Start : Widget_Handle;
      X, Y  : Pixel_Type) return Boolean;

   ---------------------------------------------------------------------------
   --  Dirty/Update Tracking
   ---------------------------------------------------------------------------

   procedure Mark_Dirty (W : in out Widget'Class);
   procedure Mark_Render_Dirty (W : in out Widget'Class);
   procedure Mark_Render_Dirty (H : Widget_Handle);
   procedure Mark_Clean (W : in out Widget'Class);

   --  Library-finalization escape hatch.  Adi.Window.Finalize sets this
   --  before walking its widget tree to skip dispatching On_Destroy /
   --  Clear_Items on widgets whose tagged-type scope has already been
   --  finalized — the vtable is gone by then and a dispatching call
   --  faults below the level where GNAT's signal-to-exception mapping
   --  is still active, so an exception handler cannot catch it.
   procedure Begin_Library_Finalization;
   procedure End_Library_Finalization;
   function  Is_Dirty (W : Widget'Class) return Boolean;
   function  Is_Dirty (H : Widget_Handle) return Boolean;
   function  Is_Layout_Dirty (W : Widget'Class) return Boolean;
   function  Is_Layout_Dirty (H : Widget_Handle) return Boolean;

   ---------------------------------------------------------------------------
   --  Abstract Methods - Must be implemented by derived widgets
   ---------------------------------------------------------------------------

   --  Render items to the scene graph/renderer
   procedure Build_Items (W : in out Widget) is abstract;
   procedure Build_Items (H : Widget_Handle);

   ---------------------------------------------------------------------------
   --  Concrete Rendering - Generic for all widgets
   ---------------------------------------------------------------------------

   --  Render all items of this widget using SDL renderer
   procedure Render_Items (W : in out Widget'Class; Ctx : in out Render_Context);

   --  An override replaces the items entirely; call Render_Items first
   --  to keep the CSS background and border under what it draws. Area is
   --  where to draw, with scrolling applied. The clip is already set.
   --  Leave the renderer as you found it -- widgets drawn afterwards
   --  inherit a render target left set.
   procedure Render_Content (W    : in out Widget;
                             Ctx  : in out Render_Context;
                             Area : Rectangle);

   --  Render this widget and all children recursively
   procedure Render_Tree (W : in out Widget'Class; Ctx : in out Render_Context);
   procedure Render_Tree (H : Widget_Handle; Ctx : in out Render_Context);

   --  Full update and render cycle
   procedure Update_And_Render (W : in out Widget'Class; Ctx : in out Render_Context);

   --  Handle layout calculation
   procedure Layout (W : in out Widget) is abstract;
   procedure Layout (H : Widget_Handle);

   --  Total scrollable content height for overflow-y. Default returns the
   --  cached W.Scroll_Content_H that Update_Shared_Scroll_Layout populates
   --  from child geometries; widgets that scroll over a virtual document
   --  (no child per row) override this to report the document size without
   --  materialising the children.
   function Get_Scroll_Content_Height (W : Widget) return Pixel_Type;

   --  Called when the widget is clicked (mouse-up within bounds of clickable widget)
   --  Default does nothing; override in derived widgets (e.g., Button).
   procedure On_Click (W : in out Widget) is null;
   procedure On_Click (H : Widget_Handle);

   --  Called for mouse interaction routed by the window.
   procedure On_Mouse_Down
     (W      : in out Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   procedure On_Mouse_Down
     (H      : Widget_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   procedure On_Mouse_Move
     (W    : in out Widget;
      X, Y : Pixel_Type);
   procedure On_Mouse_Move
     (H    : Widget_Handle;
      X, Y : Pixel_Type);
   procedure On_Mouse_Up
     (W      : in out Widget;
      X, Y   : Pixel_Type;
      Button : Mouse_Button);
   procedure On_Mouse_Up
     (H      : Widget_Handle;
      X, Y   : Pixel_Type;
      Button : Mouse_Button);
   procedure On_Mouse_Wheel
     (W              : in out Widget;
      Delta_X, Delta_Y : Pixel_Type);
   procedure On_Mouse_Wheel
     (H                : Widget_Handle;
      Delta_X, Delta_Y : Pixel_Type);

   --  Called for key down events when this widget has focus.
   procedure On_Key_Down
     (W        : in out Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean) is null;
   procedure On_Key_Down
     (H        : Widget_Handle;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

   --  Called for key up events when this widget has focus.
   procedure On_Key_Up
     (W        : in out Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean) is null;
   procedure On_Key_Up
     (H        : Widget_Handle;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean);

   --  Called for text input events when this widget has focus.
   procedure On_Text_Input (W : in out Widget; Text : String) is null;
   procedure On_Text_Input (H : Widget_Handle; Text : String);

   --  Called when this widget gains/loses keyboard focus.
   procedure On_Focus_Gained (W : in out Widget) is null;
   procedure On_Focus_Gained (H : Widget_Handle);
   procedure On_Focus_Lost (W : in out Widget) is null;
   procedure On_Focus_Lost (H : Widget_Handle);

   --  Called just before a widget is destroyed (Request_Destroy).
   --  Override to clean up external references (e.g. global binding tables).
   --  Children are still intact when this is called.
   procedure On_Destroy (W : in out Widget) is null;

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

   --  Called from Set_Scroll_Offset_Y after a real change to Scroll_Offset_Y
   --  (no-op writes do not fire). Old_Offset is the value before the write,
   --  New_Offset is the post-clamp value the widget actually holds. Virtualised
   --  widgets override this to refill / recycle their item pool when the
   --  visible window moves, instead of polling from On_Tick.
   procedure On_Scroll_Changed
     (W          : in out Widget;
      Old_Offset : Pixel_Type;
      New_Offset : Pixel_Type) is null;

   ---------------------------------------------------------------------------
   --  Update/Render Cycle
   ---------------------------------------------------------------------------

   --  Full update: rebuild items if dirty, apply styles, prepare for render
   procedure Update (W : in out Widget'Class);
   procedure Update (H : Widget_Handle);


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
                        Source : Image_Handle;
                        Z_Order : Natural := 0;
                        Is_Background : Boolean := False) return Item;

    ---------------------------------------------------------------------------
   --  Content Measurement
   ---------------------------------------------------------------------------

   function Measure_Content(W : Widget) return Size_2D;
   function Measure_Content(H : Widget_Handle) return Size_2D;
   function Get_Min_Size(W : Widget) return Size_2D;
   function Get_Min_Size(H : Widget_Handle) return Size_2D;
   function Get_Preferred_Size(W : Widget'Class) return Size_2D;
   function Get_Preferred_Size(H : Widget_Handle) return Size_2D;

   --  True when this overflow value makes a box scroll its content
   --  rather than grow to fit it.
   function Overflow_Is_Scrollable (V : Overflow_Value) return Boolean;

   --  Min-content size: the smallest this widget's content can be
   --  squeezed into. Advisory — the parent applies the flex rules to it.
   --  Contrast Get_Min_Size, which is the minimum the widget demands.
   --  Default zero; see docs/layout_minimums.md.
   function Get_Content_Min_Size (W : Widget) return Size_2D;
   function Get_Content_Min_Size (H : Widget_Handle) return Size_2D;

   --  The width text is actually wrapped at, given the room available.
   --
   --  Words are never broken, so a column narrower than the widest word
   --  buys no extra lines -- the text overflows instead. Every path that
   --  wraps or measures wrapped text goes through this, so measurement,
   --  layout and rendering agree on where the lines fall.
   --
   --  It is an approximation of CSS overflow-wrap: normal, not that rule
   --  itself: flooring the whole column at the widest word also lets
   --  shorter words share a line wider than the box really is. Exact
   --  behaviour needs whitespace-aware line breaking, and real
   --  overflow-wrap / word-break support to opt out of it.
   function Effective_Wrap_Width
     (Attrs     : Adi.Font.Font_Attributes;
      Content   : String;
      Available : Pixel_Type) return Pixel_Type;

   --  Content size when the widget is laid out at Assigned_Width as its
   --  own outer width -- the width-aware counterpart of Measure_Content,
   --  and like it, CSS width/height are not applied here. Override this
   --  in a widget whose height depends on its width; the default ignores
   --  the width and returns Measure_Content, which is right for every
   --  widget whose height does not.
   --
   --  It must not change observable layout state: no geometry, no
   --  committed sizes, nothing a later pass would read as fact. Internal
   --  memoisation is fine -- callers ask this speculatively, and an
   --  answer must not commit the widget to it.
   function Measure_Content_At_Width
     (W : Widget; Assigned_Width : Pixel_Type) return Size_2D;

   --  Preferred outer size at that width, with CSS sizing applied on top
   --  the way Get_Preferred_Size applies it to Measure_Content: a
   --  declared height wins over whatever the content measured. The width
   --  comes back as given -- the caller resolved it and will render at
   --  it, so resolving the widget's own width again would apply a
   --  percentage twice. Not dispatching: the widget-specific part is the
   --  primitive above.
   function Measure_At_Width
     (W : Widget'Class; Assigned_Width : Pixel_Type) return Size_2D;
   function Measure_At_Width
     (H : Widget_Handle; Assigned_Width : Pixel_Type) return Size_2D;

   --  How small a child can actually be made, per axis: its content
   --  minimum capped by a definite size it declares — CSS's specified
   --  size suggestion — and then floored by the minimum it demands.
   --  Percentages resolve against a container that is itself still being
   --  measured, so they are not definite here and do not cap.
   --  Containers aggregate this rather than the raw content minimum.
   function Effective_Min_Size (W : Widget'Class) return Size_2D;
   function Effective_Min_Size (H : Widget_Handle) return Size_2D;

   --  Content minimum when the widget is laid out at Assigned_Width as
   --  its own outer width -- the width-aware counterpart of
   --  Get_Content_Min_Size. Override this in a widget whose block-axis
   --  minimum depends on the width it is given; the default ignores the
   --  width and returns Get_Content_Min_Size.
   --
   --  Same contract as Measure_Content_At_Width, and one rule beyond it:
   --  the answer must not come from geometry. The caller is deciding a
   --  width, so the width the widget happens to carry from the previous
   --  layout would make the minimum one pass late.
   function Get_Content_Min_Size_At_Width
     (W : Widget; Assigned_Width : Pixel_Type) return Size_2D;

   --  Where a box shadow lands, resolved once: the renderer draws this
   --  rectangle and culling asks whether it is worth drawing, so the
   --  two must not compute it separately.
   type Shadow_Geometry is record
      Blur     : Natural := 0;
      Spread   : Pixel_Type := 0.0;
      Offset_X : Pixel_Type := 0.0;
      Offset_Y : Pixel_Type := 0.0;
      Dst      : Rectangle := (0.0, 0.0, 0.0, 0.0);
   end record;

   function Resolve_Shadow_Geometry
     (Style : Adi.CSS_Styles.Resolved_Style;
      Geom  : Rectangle) return Shadow_Geometry;

   --  How far an outline reaches outside the border box. Raw amounts,
   --  because that is what the renderer draws: putting them through
   --  Length_To_Px here would make culling disagree with painting
   --  wherever a scale is not 1.
   function Outline_Expansion
     (Style : Adi.CSS_Styles.Resolved_Style) return Pixel_Type;

   --  The rectangle an item can paint into, which is not its geometry:
   --  a shadow is drawn at its own offset expanded by spread plus three
   --  blur radii, and an outline sits outside the border box. Anything
   --  deciding what is worth drawing has to agree with what drawing
   --  actually covers, so both come through here.
   function Item_Paint_Bounds
     (Style : Adi.CSS_Styles.Resolved_Style;
      Geom  : Rectangle) return Rectangle;

   type Pixel_Array is array (Positive range <>) of Pixel_Type;

   --  What one child of a flex row gets: the width it is laid out at,
   --  and which line it lands on. A wrapping row is as deep as the sum
   --  of its lines, so a caller measuring one needs both.
   type Flex_Row_Item is record
      Width : Pixel_Type := 0.0;
      Line  : Positive := 1;
   end record;
   type Flex_Row_Items is array (Positive range <>) of Flex_Row_Item;

   --  The widths the in-flow children of a flex row are laid out at,
   --  in child order, given the row's content width.
   --
   --  This runs the real main-axis distribution rather than guessing at
   --  it, and stops there: cross sizing would stretch the children and
   --  contaminate an answer that was only asked how wide they are. It is
   --  a query and leaves no geometry behind.
   --
   --  Empty unless W is a flex row with in-flow children. A wrapping row
   --  is broken into lines first and each line flexes on its own, so a
   --  caller measuring one can also tell which line an item landed on.
   function Flex_Row_Child_Widths
     (W : Widget'Class; Content_Width : Pixel_Type) return Flex_Row_Items;

   --  The main-axis size a flex item is laid out from before it grows or
   --  shrinks. A definite flex-basis is exactly that basis -- including
   --  zero, which is a demand for nothing -- and otherwise the item's own
   --  content size at the width it is being given.
   --
   --  Aggregation and the flex algorithm both resolve the base through
   --  here, so a container cannot reserve room on one rule while the
   --  layout places on another. Pass Unknown_Assigned_Width when no width
   --  has been decided yet; the base then comes from the unconstrained
   --  preferred size.
   Unknown_Assigned_Width : constant Pixel_Type := -1.0;

   function Resolved_Flex_Base
     (Child          : Widget'Class;
      Direction      : Flex_Direction_Value;
      Assigned_Width : Pixel_Type;
      Container_Main : Pixel_Type) return Pixel_Type;

   --  Effective_Min_Size at that width. Not dispatching: the
   --  widget-specific part is the primitive above.
   function Effective_Min_Size_At_Width
     (W : Widget'Class; Assigned_Width : Pixel_Type) return Size_2D;
   function Effective_Min_Size_At_Width
     (H : Widget_Handle; Assigned_Width : Pixel_Type) return Size_2D;

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
   procedure Rebuild_All_Items (H : Widget_Handle);
   procedure Layout_Tree (W : in out Widget'Class);
   procedure Layout_Tree (H : Widget_Handle);

   ---------------------------------------------------------------------------
   --  Animation
   ---------------------------------------------------------------------------

   --  Advance all active transitions by DT seconds, recursing to children
   procedure Tick_Animations (W : in out Widget'Class; DT : Duration);
   procedure Tick_Animations (H : Widget_Handle; DT : Duration);

   ---------------------------------------------------------------------------
   --  Per-frame performance counters (debug stats overlay)
   ---------------------------------------------------------------------------

   procedure Reset_Perf_Counters;
   function Get_Perf_Style_Resolves return Natural;
   function Get_Perf_Style_Hits return Natural;
   function Get_Perf_Layout_Calls return Natural;
   function Get_Perf_Layout_Skips return Natural;
   function Get_Perf_Pref_Calls return Natural;
   function Get_Perf_Pref_Hits return Natural;

   ---------------------------------------------------------------------------
   --  Layout helper for containers: lay out a child and mark its epoch
   --  so Layout_Tree will not re-lay-out it.
   ---------------------------------------------------------------------------

   procedure Layout_Child (Child : in out Widget'Class);

private

   --  Widgets are reached through Widget_Handle.  The pointer type, the
   --  resolver and the registrar are here so the library's own child
   --  packages can build widgets; defining one outside the library goes
   --  through Adi.Widget.Extension.
   type Widget_Access is access all Widget'Class;

   --  Null for a null handle and for a stale one.  Prefer Borrow, which
   --  pins.
   function Resolve_Handle (H : Widget_Handle) return Widget_Access;

   --  Register a freshly allocated widget in the global store.
   --  Called from each widget's Create function.
   procedure Register_Widget (Obj : not null Widget_Access);

   ---------------------------------------------------------------------------
   --  Private Package Instantiations
   ---------------------------------------------------------------------------

   package Widget_List is new
     Ada.Containers.Doubly_Linked_Lists (Widget_Access);

   --  True for widgets that scroll their own content without being
   --  scroll containers — a text input slides its line sideways as you
   --  type, so what moved out of view must not be drawn beside the
   --  field. It is the equivalent of a browser's user-agent
   --  `overflow: hidden` on an input: dispatching, so a derived widget
   --  such as a value input inherits it, and private, so a stylesheet
   --  cannot switch it off. It clips only the parts the widget scrolls.
   function Clips_Own_Content (W : Widget) return Boolean;

   --  Kept private so no consumer can drop another subsystem's
   --  subscription with Disconnect_All.
   Scroll_Changed : Scroll_Signals.Signal;

   ---------------------------------------------------------------------------
   --  Widget Record
   ---------------------------------------------------------------------------

   --  Interned style handles (0 = Empty_Widget_Style)
   type Style_Handle is new Natural;
   type Part_Style_Handle_Array is array (Part_Kind) of Style_Handle;
   type Part_Enabled_Array is array (Part_Kind) of Boolean;

   --  Animation state per part
   type Part_Transition_Array is array (Part_Kind) of Part_Transition;
   type Part_Resolved_Array is array (Part_Kind) of Resolved_Style;
   type Part_Initialized_Array is array (Part_Kind) of Boolean;
   type Part_State_Array is array (Part_Kind) of Widget_States;

   function Allocate_Widget_Id return Natural;

   type Widget is abstract tagged limited record
      --  Unique identifier (monotonically increasing, assigned at creation)
      Widget_Id : Natural := Allocate_Widget_Id;

      --  Handle store slot (set by Register, used by Get_Handle).
      --  Stored as raw Naturals because Widget_Stores is instantiated
      --  after the full type declaration (Ada elaboration order).
      Store_Index : Natural := 0;
      Store_Gen   : Natural := 0;

      --  Hierarchy
      Parent   : access Widget'Class := null;
      Children : Widget_List.List;

      --  Geometry
      Geometry : Rectangle := (0.0, 0.0, 0.0, 0.0);

      --  State
      States      : Widget_States := No_States;
      Part_States : Part_State_Array := [others => No_States];
      Dirty       : Boolean := True;
      Layout_Dirty : Boolean := True;
      Style_Version        : Natural := 0;
      Last_Applied_Version : Natural := 0;
      Flags       : Widget_Flags := Default_Flags;

      --  Styling - each part references an interned style
      Part_Style_Handles : Part_Style_Handle_Array := [others => 0];
      Part_Style_Enabled : Part_Enabled_Array := [others => True];

      --  Renderable items (built by derived widgets)
      Items : Items_List.Vector;

      --  Resolved style cache (auto-invalidated by key mismatch).
      --  Keyed on (Style_Version, effective states via Get_States,
      --  Part_States(P)) so inherited :disabled is handled correctly.
      Cached_Resolved      : Part_Resolved_Array;
      Cached_Resolved_Init : Part_Initialized_Array := [others => False];
      Cached_Style_Version : Natural := 0;
      Cached_Eff_States    : Widget_States := No_States;
      --  The font environment those cached styles were resolved against.
      Cached_Font_Gen      : Adi.Font.Font_Generation := 0;
      Cached_Part_States   : Part_State_Array := [others => No_States];

      --  Layout epoch for duplicate-call elimination (Phase 2)
      Last_Layout_Epoch : Natural := 0;

      --  Content version: bumped by Mark_Dirty (text changes, child
      --  add/remove, etc.).  Propagates to parents since Mark_Dirty
      --  recurses upward.  Used by the pref-size cache to detect
      --  content mutations that don't affect Style_Version.
      Content_Version : Natural := 0;

      --  Preferred size cache (pass-scoped + mutation-keyed).
      --  Keyed on (epoch, Style_Version, Content_Version, effective
      --  states, geometry, Last_Layout_Epoch).  Epoch = Natural'Last initially so that
      --  the cache never false-hits before the first Layout_Tree call.
      Cached_Pref_Size       : Size_2D := (0.0, 0.0);
      Cached_Pref_Epoch      : Natural := Natural'Last;
      Cached_Pref_Version    : Natural := 0;
      Cached_Pref_Content    : Natural := 0;
      Cached_Pref_States     : Widget_States := No_States;
      Cached_Pref_Geom_W     : Pixel_Type := 0.0;
      Cached_Pref_Geom_H     : Pixel_Type := 0.0;
      Cached_Pref_Layout_Epoch : Natural := 0;

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
      Context_Menu_Sig    : Context_Menu_Signals.Signal;

      --  Floating label overlay (any widget can have a label)
      Label_Text      : Unbounded_String := Null_Unbounded_String;
      Label_Item_Base : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   --  Handle Store instantiation (must come after Widget's full definition)
   ---------------------------------------------------------------------------

   package Widget_Stores is new Adi.Handle_Store (Widget, Widget_Access);

   type Widget_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;

   Null_Handle : constant Widget_Handle := (Id => Widget_Stores.Null_Id);

   --  How the window layer is told a widget is going away.  Installed
   --  through Adi.Widget.Window_Bridge, which is the only unit that may
   --  set it, and read by Destroy.  Here rather than in the visible part
   --  because it is not public API, and not in the body because a child
   --  has to reach it -- Adi.Widget is Elaborate_Body, so its body
   --  cannot with its own child.
   type Destroy_Notice_Proc is access procedure (H : Widget_Handle);
   Destroy_Notice_Slot : Destroy_Notice_Proc := null;

   type Widget_Ref (Ptr : access Widget'Class) is
     limited new Ada.Finalization.Limited_Controlled with record
       Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
     end record;
   overriding procedure Finalize (R : in out Widget_Ref);

   --  Widget'Class versions — used internally by handle wrappers
   --  and visible to child packages (List_Box, Stack, Dialog, etc.).
   procedure Set_Label (W : in out Widget'Class; Label : String);
   function  Get_Label (W : Widget'Class) return String;
   function  Get_Id (W : Widget'Class) return Natural;

   procedure Set_State (W : in out Widget'Class; S : Widget_State; Active : Boolean);
   function  Has_State (W : Widget'Class; S : Widget_State) return Boolean;
   function  Get_States (W : Widget'Class) return Widget_States;
   procedure Set_Part_State (W : in out Widget'Class;
                             P : Part_Kind;
                             S : Widget_State;
                             Active : Boolean);
   function  Get_Part_States (W : Widget'Class; P : Part_Kind)
      return Widget_States;
   procedure Clear_States (W : in out Widget'Class);
   procedure Clear_Part_States (W : in out Widget'Class);
   procedure Set_Hovered  (W : in out Widget'Class; Value : Boolean := True);
   procedure Set_Pressed  (W : in out Widget'Class; Value : Boolean := True);
   procedure Set_Focused  (W : in out Widget'Class; Value : Boolean := True);
   procedure Set_Disabled (W : in out Widget'Class; Value : Boolean := True);
   function  Is_Disabled  (W : Widget'Class) return Boolean;
   procedure Set_Selected (W : in out Widget'Class; Value : Boolean := True);

   procedure Set_Part_Style (W : in out Widget'Class;
                             P : Part_Kind;
                             S : Widget_Style);
   function  Get_Part_Style (W : Widget'Class;
                             P : Part_Kind) return Widget_Style;
   function  Get_Part_Style_Rules (W : Widget'Class;
                                   P : Part_Kind) return Style_Rules;
   function  Get_Resolved_Part_Style (W : Widget'Class;
                                      P : Part_Kind) return Resolved_Style;

   procedure Set_Geometry (W : in out Widget'Class; G : Rectangle);
   function  Get_Content_Box (W : Widget'Class) return Rectangle;

   procedure Set_Flag (W : in out Widget'Class; F : Widget_Flag; Value : Boolean);
   function  Has_Flag (W : Widget'Class; F : Widget_Flag) return Boolean;

   procedure Add_Child    (W : in out Widget'Class; C : Widget_Handle);
   procedure Add_Child    (W : in out Widget'Class; C : access Widget'Class);
   procedure Remove_Child (W : in out Widget'Class; C : access Widget'Class);
   procedure Set_Parent   (W : in out Widget'Class; P : access Widget'Class);
   function  Get_Parent   (W : Widget'Class) return access Widget'Class;
   function  Get_Parent_Handle (W : Widget'Class) return Widget_Handle;
   function  Child_Count  (W : Widget'Class) return Natural;
   function  Get_Child    (W : Widget'Class; Index : Positive)
      return Widget_Access;
   function  Get_Child_Handle (W : Widget'Class; Index : Positive)
      return Widget_Handle;

   --  Color conversion helpers (CSS Color_Value to SDL RGBA)
   procedure CSS_Color_To_SDL
      (C : Color_Value;
       R, G, B, A : out Adi.SDL.Uint8);

   --  Position layout helpers (shared by flex and grid layout paths)
   procedure Position_Absolute_Child
     (Child       : in out Widget'Class;
      Child_Style : Resolved_Style;
      Container   : Rectangle);

   procedure Apply_Relative_Offset
     (Child     : in out Widget'Class;
      Container : Rectangle);

end Adi.Widget;
