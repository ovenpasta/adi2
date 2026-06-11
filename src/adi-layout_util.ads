with Adi.Core;       use Adi.Core;
with Adi.CSS_Styles; use Adi.CSS_Styles;

package Adi.Layout_Util is

   Default_Root_Font_Size_Px : constant Pixel_Type :=
     Pixel_Type (Default_Font_Size.Amount);

   --  Active DIP scale used by Length_To_Px for Dip units.
   --  Window code updates this based on SDL window display scale.
   procedure Set_Active_DIP_Scale (Scale : Pixel_Type);
   function Get_Active_DIP_Scale return Pixel_Type;

   --  Active user UI scale applied on top of the OS DIP scale for logical
   --  layout units such as dp/dip.
   procedure Set_Active_UI_Scale (Scale : Pixel_Type);
   function Get_Active_UI_Scale return Pixel_Type;

   --  Active user text scale applied when a length is used as a font size.
   procedure Set_Active_Text_Scale (Scale : Pixel_Type);
   function Get_Active_Text_Scale return Pixel_Type;

   --  Active root font size used by Length_To_Px for Root_Em units when
   --  explicit root font size is not provided at call sites.
   procedure Set_Active_Root_Font_Size (Size : Pixel_Type);
   function Get_Active_Root_Font_Size return Pixel_Type;

   --  Active viewport size used by Length_To_Px for vw/vh units when
   --  explicit viewport dimensions are not provided at call sites.
   procedure Set_Active_Viewport_Size
     (Width  : Pixel_Type;
      Height : Pixel_Type);
   function Get_Active_Viewport_Width return Pixel_Type;
   function Get_Active_Viewport_Height return Pixel_Type;

   procedure Set_Px_Maps_To_Dip (Enabled : Boolean);
   function  Get_Px_Maps_To_Dip return Boolean;

   --  Build a Length_Value that, when passed through Length_To_Px, yields
   --  exactly P pixels regardless of the Px_Maps_To_Dip toggle and current
   --  DIP / UI scales. Use this when a widget has already resolved a length
   --  to its final pixel value and needs to store that value in a
   --  Length_Value field (e.g. Style_Override.Font_Size) that will be
   --  re-resolved later by the rendering pipeline.
   function Pixels_As_Length (P : Pixel_Type) return CSS_Styles.Length_Value;


   -------------------------------------------------
   -- Alignment Types
   -------------------------------------------------

   type H_Alignment is (H_Left, H_Center, H_Right, H_Stretch);
   type V_Alignment is (V_Top, V_Middle, V_Bottom, V_Stretch);

   -------------------------------------------------
   -- Edge/Box Pixel Extraction
   -------------------------------------------------

   type Edge_Pixels is record
      Top, Right, Bottom, Left : Pixel_Type;
   end record;

   Zero_Edges : constant Edge_Pixels := (0.0, 0.0, 0.0, 0.0);

   --  Extract padding as pixels (converts Length to Pixel_Type)
   function Get_Padding_Px (Style : Resolved_Style) return Edge_Pixels;
   function Get_Margin_Px (Style : Resolved_Style) return Edge_Pixels;
   function Get_Border_Width_Px (Style : Resolved_Style) return Edge_Pixels;

   --  Helper to convert CSS_Box_Value to Edge_Pixels
   function Box_To_Pixels (B : CSS_Box_Value) return Edge_Pixels;
   function Border_To_Pixels (B : Border_Width_Value) return Edge_Pixels;

   -------------------------------------------------
   -- Content Box Calculation
   -------------------------------------------------

   --  Get inner content area after subtracting padding and border
   function Content_Box (Outer : Rectangle;
                         Style : Resolved_Style) return Rectangle;

   --  Get inner area after subtracting only padding
   function Padding_Box (Outer : Rectangle;
                         Style : Resolved_Style) return Rectangle;

   --  Compute outer size from content size by adding padding + border
   function Outer_Size (Content : Size_2D;
                        Style   : Resolved_Style) return Size_2D;

   --  Shrink rectangle by edge amounts
   function Shrink (R : Rectangle; Edges : Edge_Pixels) return Rectangle;

   --  Expand rectangle by edge amounts
   function Expand (R : Rectangle; Edges : Edge_Pixels) return Rectangle;

   -------------------------------------------------
   -- Rectangle Alignment
   -------------------------------------------------

   --  Align a sized item within a container
   function Align_In (Container : Rectangle;
                      Item_Size : Size_2D;
                      H : H_Alignment := H_Left;
                      V : V_Alignment := V_Top) return Rectangle;

   --  Clamp preferred size between min/max and center within container.
   function Clamp_And_Center
     (Container : Rectangle;
      Preferred : Size_2D;
      Min_Size  : Size_2D;
      Max_Size  : Size_2D) return Rectangle;

   --  Align using CSS text-align value
   function Align_H_From_CSS (Align : Text_Align_Value) return H_Alignment;

   --  Align using CSS vertical-align value
   function Align_V_From_CSS (Align : Vertical_Align_Value) return V_Alignment;

   -------------------------------------------------
   -- Icon + Text Layout
   -------------------------------------------------

   type Icon_Position is (Icon_Left, Icon_Right, Icon_Top, Icon_Bottom, Icon_Only);

   type Icon_Text_Rects is record
      Icon_Rect : Rectangle;
      Text_Rect : Rectangle;
      Has_Icon  : Boolean;
      Has_Text  : Boolean;
   end record;

   function Layout_Icon_Text (
      Container   : Rectangle;
      Icon_Size   : Size_2D;
      Has_Icon    : Boolean;
      Has_Text    : Boolean;
      Position    : Icon_Position := Icon_Left;
      Gap         : Pixel_Type := 8.0;
      Icon_V_Align : V_Alignment := V_Middle) return Icon_Text_Rects;

   -------------------------------------------------
   -- Stack/Flow Layout
   -------------------------------------------------

   type Stack_Direction is (Dir_Horizontal, Dir_Vertical);

   --  Calculate position for item N in a stack
   function Stack_Position (
      Container   : Rectangle;
      Item_Index  : Natural;        --  0-based
      Item_Count  : Positive;
      Item_Size   : Size_2D;
      Direction   : Stack_Direction;
      Gap         : Pixel_Type := 0.0;
      Main_Align  : H_Alignment := H_Left;   --  Along main axis
      Cross_Align : V_Alignment := V_Top) return Rectangle;

   --  Get total size needed for stacked items
   function Stack_Total_Size (
      Item_Count : Positive;
      Item_Size  : Size_2D;
      Direction  : Stack_Direction;
      Gap        : Pixel_Type := 0.0) return Size_2D;

   -------------------------------------------------
   -- Flex-like Distribution
   -------------------------------------------------

   type Flex_Item_Info is record
      Min_Size   : Pixel_Type := 0.0;
      Max_Size   : Pixel_Type := Pixel_Type'Last;
      Flex_Grow  : Float := 0.0;
      Flex_Shrink : Float := 1.0;
   end record;

   type Flex_Item_Array is array (Positive range <>) of Flex_Item_Info;
   type Pixel_Array is array (Positive range <>) of Pixel_Type;

   --  Distribute space among flex items
   function Distribute_Flex (
      Available   : Pixel_Type;
      Items       : Flex_Item_Array;
      Gap         : Pixel_Type := 0.0) return Pixel_Array;

   -------------------------------------------------
   -- Utility
   -------------------------------------------------

   --  Convert Length to pixels (simplified - assumes Px or does basic conversion)
   function Length_To_Px (L : CSS_Styles.Length_Value;
                           Container_Size : Pixel_Type := 0.0;
                           Font_Size : Pixel_Type := Default_Root_Font_Size_Px;
                           Root_Font_Size : Pixel_Type := 0.0;
                           Viewport_Width : Pixel_Type := 0.0;
                           Viewport_Height : Pixel_Type := 0.0)
       return Pixel_Type;

   --  Convert a font-related length to pixels, applying the active text scale.
   function Font_Length_To_Px
     (L : CSS_Styles.Length_Value;
      Container_Size : Pixel_Type := 0.0;
      Font_Size : Pixel_Type := Default_Root_Font_Size_Px;
      Root_Font_Size : Pixel_Type := 0.0;
      Viewport_Width : Pixel_Type := 0.0;
      Viewport_Height : Pixel_Type := 0.0)
      return Pixel_Type;

   --  Convert Inset_Value to pixels; Auto yields 0.0
   function Inset_To_Px (V : CSS_Styles.Inset_Value;
                          Container_Size : Pixel_Type := 0.0)
       return Pixel_Type;

   --  Get size from Size_Value
   function Size_To_Px (S : Size_Value;
                         Container_Size : Pixel_Type := 0.0;
                         Font_Size : Pixel_Type := Default_Root_Font_Size_Px;
                         Root_Font_Size : Pixel_Type := 0.0;
                         Viewport_Width : Pixel_Type := 0.0;
                         Viewport_Height : Pixel_Type := 0.0)
       return Pixel_Type;

   --  Resolve Border_Radius_Value to per-corner pixel values, properly
   --  routing each corner Length_Value through Length_To_Px so px ↔ dp
   --  mapping and DIP scaling are honoured.  The plain
   --  Adi.CSS_Styles.Get_Border_Radius_Px returns raw .Amount values and
   --  bypasses unit handling — use this instead for any geometry-aware
   --  rendering or layout calculation.
   function Resolve_Border_Radius_Px
     (R : CSS_Styles.Border_Radius_Value;
      Container_Width  : Pixel_Type := 0.0;
      Container_Height : Pixel_Type := 0.0;
      Font_Size        : Pixel_Type := Default_Root_Font_Size_Px;
      Root_Font_Size   : Pixel_Type := 0.0;
      Viewport_Width   : Pixel_Type := 0.0;
      Viewport_Height  : Pixel_Type := 0.0)
      return CSS_Styles.Corner_Pixels;

-------------------------------------------------
   -- Flex Layout Types
   -------------------------------------------------

   type Flex_Layout_Context is record
      Container       : Rectangle;
      Direction       : Flex_Direction_Value;
      Wrap            : Flex_Wrap_Value;
      Justify_Content : Justify_Content_Value;
      Align_Items     : Align_Items_Value;
      Align_Content   : Align_Content_Value;
      Row_Gap         : Pixel_Type;
      Column_Gap      : Pixel_Type;
   end record;

   type Flex_Child_Info is record
      --  Input properties
      Flex_Grow    : Float := 0.0;
      Flex_Shrink  : Float := 1.0;
      Flex_Basis   : Pixel_Type := 0.0;  -- Resolved to pixels
      Align_Self   : Align_Self_Value := Auto;

      --  Size constraints
      Min_Main     : Pixel_Type := 0.0;
      Max_Main     : Pixel_Type := Pixel_Type'Last;
      Min_Cross    : Pixel_Type := 0.0;
      Max_Cross    : Pixel_Type := Pixel_Type'Last;

      --  Content/preferred sizes
      Content_Main  : Pixel_Type := 0.0;
      Content_Cross : Pixel_Type := 0.0;

      --  Margins
      Margin : Edge_Pixels := Zero_Edges;

      --  Output (computed by layout)
      Computed_Main  : Pixel_Type := 0.0;
      Computed_Cross : Pixel_Type := 0.0;
      Computed_Pos_Main  : Pixel_Type := 0.0;
      Computed_Pos_Cross : Pixel_Type := 0.0;
   end record;

   type Flex_Child_Info_Array is array (Positive range <>) of Flex_Child_Info;
   type Flex_Child_Info_Access is access all Flex_Child_Info_Array;

   type Rectangle_Array is array (Positive range <>) of Rectangle;
   type Rectangle_Array_Access is access all Rectangle_Array;

   -------------------------------------------------
   -- Flex Line (for wrapping)
   -------------------------------------------------

   type Flex_Line is record
      Start_Index  : Positive := 1;
      End_Index    : Positive := 1;
      Main_Size    : Pixel_Type := 0.0;
      Cross_Size   : Pixel_Type := 0.0;
      Total_Grow   : Float := 0.0;
      Total_Shrink : Float := 0.0;
   end record;

   type Flex_Line_Array is array (Positive range <>) of Flex_Line;

   -------------------------------------------------
   -- Flex Layout Functions
   -------------------------------------------------

   --  Main entry point for flex layout
   procedure Compute_Flex_Layout(
      Context   : Flex_Layout_Context;
      Children  : in out Flex_Child_Info_Array);

   --  Convert computed flex results to rectangles
   function Flex_To_Rectangles(
      Context  : Flex_Layout_Context;
      Children : Flex_Child_Info_Array) return Rectangle_Array;

   --  Gap extraction helpers
   function Get_Row_Gap(G : Gap_Value) return Pixel_Type;
   function Get_Column_Gap(G : Gap_Value) return Pixel_Type;
   function Get_Main_Gap(G : Gap_Value; Dir : Flex_Direction_Value) return Pixel_Type;
   function Get_Cross_Gap(G : Gap_Value; Dir : Flex_Direction_Value) return Pixel_Type;

   --  Axis helpers
   function Is_Row_Direction(Dir : Flex_Direction_Value) return Boolean;
   function Is_Reversed(Dir : Flex_Direction_Value) return Boolean;

   --  Size extraction from resolved style
   function Get_Main_Size(S : Size_2D; Dir : Flex_Direction_Value) return Pixel_Type;
   function Get_Cross_Size(S : Size_2D; Dir : Flex_Direction_Value) return Pixel_Type;
   function Make_Size(Main, Cross : Pixel_Type; Dir : Flex_Direction_Value) return Size_2D;

   -------------------------------------------------
   -- Grid Layout Types/Functions
   -------------------------------------------------

   type Grid_Layout_Context is record
      Container           : Rectangle;
      Columns             : Natural := 1;
      Explicit_Rows       : Natural := 0;  -- 0 => auto
      Row_Gap             : Pixel_Type := 0.0;
      Column_Gap          : Pixel_Type := 0.0;
      Use_Preferred_Floor : Boolean := False;
      Column_Tracks       : Grid_Track_List := Default_Grid_Track_List;
   end record;

   type Grid_Child_Info is record
      -- Input properties
      Active           : Boolean := True;
      Grid_Column      : Natural := 0; -- 0 => auto
      Grid_Row         : Natural := 0; -- 0 => auto
      Grid_Column_Span : Natural := 1;
      Grid_Row_Span    : Natural := 1;
      Min_Width        : Pixel_Type := 0.0;
      Min_Height       : Pixel_Type := 0.0;
      Pref_Width       : Pixel_Type := 0.0;
      Pref_Height      : Pixel_Type := 0.0;

      -- Output (computed by layout)
      Computed_X       : Pixel_Type := 0.0;
      Computed_Y       : Pixel_Type := 0.0;
      Computed_Width   : Pixel_Type := 0.0;
      Computed_Height  : Pixel_Type := 0.0;
   end record;

   type Grid_Child_Info_Array is array (Positive range <>) of Grid_Child_Info;

   -- Main entry point for grid layout
   procedure Compute_Grid_Layout(
      Context  : Grid_Layout_Context;
      Children : in out Grid_Child_Info_Array);

   -- Convert computed grid results to rectangles
   function Grid_To_Rectangles(
      Children : Grid_Child_Info_Array) return Rectangle_Array;
end Adi.Layout_Util;
