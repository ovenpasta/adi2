pragma Ada_2022;

with Adi.Core;
with Adi.Image;

package Adi.CSS_Styles is

   generic
      type Value_Type is private;
      Default : Value_Type;
   package Optional_Values is
      type State_Kind is (Undefined, None, Set);

      type Optional (State : State_Kind := Undefined) is record
         case State is
            when Undefined | None => null;
            when Set => Value : Value_Type;
         end case;
      end record;

      function Unset return Optional is ((State => Undefined));
      function Cleared return Optional is ((State => None));
      function Val (V : Value_Type) return Optional is ((State => Set, Value => V));

      function Merge (Base, Override : Optional) return Optional is
         (if Override.State = Undefined then Base else Override);

      function Resolve (O : Optional) return Value_Type is
         (case O.State is
            when Undefined | None => Default,
            when Set => O.Value);

      function Is_Set (O : Optional) return Boolean is (O.State = Set);
      function Is_None (O : Optional) return Boolean is (O.State = None);
      function Get_Default return Value_Type is (Default);
   end Optional_Values;

   -------------------------------------------------
   -- Units
   -------------------------------------------------

   type CSS_Unit is (Px, Dip, Em, Root_Em, Pct);

   type Length_Value is record
      Amount : Float := 0.0;
      Unit   : CSS_Unit := Px;
   end record;

   function Px (V : Float) return Length_Value is ((Amount => V, Unit => Px));
   function Px (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Px));
   function Dip (V : Float) return Length_Value is ((Amount => V, Unit => Dip));
   function Dip (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Dip));
   function Em (V : Float) return Length_Value is ((Amount => V, Unit => Em));
   function Em (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Em));
   function Root_Em (V : Float) return Length_Value is ((Amount => V, Unit => Root_Em));
   function Root_Em (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Root_Em));
   function Pct (V : Float) return Length_Value is ((Amount => V, Unit => Pct));
   function Pct (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Pct));

   Zero_Length : constant Length_Value := (Amount => 0.0, Unit => Px);

   -------------------------------------------------
   -- Colors
   -------------------------------------------------

   type Named_Color is (
      Black, White, Red, Green, Blue, Yellow, Orange, Purple,
      Gray, Light_Gray, Dark_Gray, Transparent, Inherit, Current_Color
   );

   type Color_Kind is (Named, RGB, RGBA);

   type Color_Value (Kind : Color_Kind := Named) is record
      case Kind is
         when Named => Name : Named_Color := Black;
         when RGB   => R, G, B : Natural := 0;
         when RGBA  => RA, GA, BA : Natural := 0; Alpha : Float := 1.0;
      end case;
   end record;

   function C (Name : Named_Color) return Color_Value is
      ((Kind => Named, Name => Name));
   function RGB (R, G, B : Natural) return Color_Value is
      ((Kind => RGB, R => R, G => G, B => B));
   function RGBA (R, G, B : Natural; A : Float) return Color_Value is
      ((Kind => RGBA, RA => R, GA => G, BA => B, Alpha => A));

   Default_Color      : constant Color_Value := C (Inherit);
   Default_Background : constant Color_Value := C (Transparent);
   Default_Border_Color : constant Color_Value := C (Current_Color);

   -------------------------------------------------
   -- Background Image
   -------------------------------------------------

   type Background_Image_Kind is (No_Image, Picture_Image, Url_Image);

   type Background_Image_Value (Kind : Background_Image_Kind := No_Image) is record
      case Kind is
         when No_Image => null;
         when Picture_Image =>
            Image : Adi.Image.Image_Access := null;
         when Url_Image =>
            --  For future URL-based loading
            null;
      end case;
   end record;

   function No_Background_Image return Background_Image_Value is
      ((Kind => No_Image));

   function Background_Image (Img : Adi.Image.Image_Access) return Background_Image_Value is
      ((Kind => Picture_Image, Image => Img));

   Default_Background_Image : constant Background_Image_Value := (Kind => No_Image);

   -------------------------------------------------
   -- Border Radius
   -------------------------------------------------

   type Corner is (Top_Left, Top_Right, Bottom_Right, Bottom_Left);
   type Corner_Radii is array (Corner) of Length_Value;
   type Radius_Kind is (Gap_Uniform, Per_Corner);

   type Border_Radius_Value (Kind : Radius_Kind := Gap_Uniform) is record
      case Kind is
         when Gap_Uniform    => All_Corners : Length_Value := Zero_Length;
         when Per_Corner => Corners : Corner_Radii := [others => Zero_Length];
      end case;
   end record;

   function Radius (All_L : Length_Value) return Border_Radius_Value is
      ((Kind => Gap_Uniform, All_Corners => All_L));
   function Radius (TL, TR, BR, BL : Length_Value) return Border_Radius_Value is
      ((Kind => Per_Corner, Corners => [TL, TR, BR, BL]));
   function Radius (TL_BR, TR_BL : Length_Value) return Border_Radius_Value is
      ((Kind => Per_Corner, Corners => [TL_BR, TR_BL, TL_BR, TR_BL]));

   Default_Radius : constant Border_Radius_Value := Radius (Zero_Length);

   type Corner_Pixels is record
      Top_Left, Top_Right, Bottom_Right, Bottom_Left : Float;
   end record;

   Zero_Corners : constant Corner_Pixels := (0.0, 0.0, 0.0, 0.0);

   function Get_Border_Radius_Px (R : Border_Radius_Value) return Corner_Pixels;

   -------------------------------------------------
   -- Border Style
   -------------------------------------------------

   type Border_Style_Kind is (
      None_Style, Hidden, Dotted, Dashed, Solid, Double,
      Groove, Ridge, Inset, Outset
   );

   type Edge is (Top, Right, Bottom, Left);
   type Edge_Lengths is array (Edge) of Length_Value;
   type Edge_Colors is array (Edge) of Color_Value;
   type Edge_Styles is array (Edge) of Border_Style_Kind;

   -- Border Width
   type Border_Width_Kind is (Gap_Uniform, Per_Edge);

   type Border_Width_Value (Kind : Border_Width_Kind := Gap_Uniform) is record
      case Kind is
         when Gap_Uniform  => All_Edges : Length_Value := Zero_Length;
         when Per_Edge => Edges : Edge_Lengths := [others => Zero_Length];
      end case;
   end record;

   function Border_Width (All_L : Length_Value) return Border_Width_Value is
      ((Kind => Gap_Uniform, All_Edges => All_L));
   function Border_Width (Vertical, Horizontal : Length_Value) return Border_Width_Value is
      ((Kind => Per_Edge, Edges => [Top => Vertical, Bottom => Vertical,
                                    Left => Horizontal, Right => Horizontal]));
   function Border_Width (Top, Right, Bottom, Left : Length_Value) return Border_Width_Value is
      ((Kind => Per_Edge, Edges => [Top, Right, Bottom, Left]));

   Default_Border_Width : constant Border_Width_Value := Border_Width (Zero_Length);

   -- Border Color
   type Border_Color_Kind is (Gap_Uniform, Per_Edge);

   type Border_Color_Value (Kind : Border_Color_Kind := Gap_Uniform) is record
      case Kind is
         when Gap_Uniform  => All_Edges : Color_Value := Default_Border_Color;
         when Per_Edge => Edges : Edge_Colors := [others => Default_Border_Color];
      end case;
   end record;

   function Border_Color (All_C : Color_Value) return Border_Color_Value is
      ((Kind => Gap_Uniform, All_Edges => All_C));
   function Border_Color (Top, Right, Bottom, Left : Color_Value) return Border_Color_Value is
      ((Kind => Per_Edge, Edges => [Top, Right, Bottom, Left]));

   Default_Border_Color_Val : constant Border_Color_Value := Border_Color (Default_Border_Color);

   -- Border Style
   type Border_Style_Value_Kind is (Gap_Uniform, Per_Edge);

   type Border_Style_Value (Kind : Border_Style_Value_Kind := Gap_Uniform) is record
      case Kind is
         when Gap_Uniform  => All_Edges : Border_Style_Kind := None_Style;
         when Per_Edge => Edges : Edge_Styles := [others => None_Style];
      end case;
   end record;

   function Border_Style (All_S : Border_Style_Kind) return Border_Style_Value is
      ((Kind => Gap_Uniform, All_Edges => All_S));
   function Border_Style (Top, Right, Bottom, Left : Border_Style_Kind) return Border_Style_Value is
      ((Kind => Per_Edge, Edges => [Top, Right, Bottom, Left]));

   Default_Border_Style : constant Border_Style_Value := Border_Style (None_Style);

   -------------------------------------------------
   -- CSS_Box (padding/margin)
   -------------------------------------------------

   type CSS_Box_Sides is array (Edge) of Length_Value;
   type CSS_Box_Kind is (Gap_Uniform, Axis, Per_Side);

   type CSS_Box_Value (Kind : CSS_Box_Kind := Gap_Uniform) is record
      case Kind is
         when Gap_Uniform  => All_Sides : Length_Value := Zero_Length;
         when Axis     => Vertical, Horizontal : Length_Value := Zero_Length;
         when Per_Side => Sides : CSS_Box_Sides := [others => Zero_Length];
      end case;
   end record;

   function CSS_Box (All_L : Length_Value) return CSS_Box_Value is
      ((Kind => Gap_Uniform, All_Sides => All_L));
   function CSS_Box (Vertical, Horizontal : Length_Value) return CSS_Box_Value is
      ((Kind => Axis, Vertical => Vertical, Horizontal => Horizontal));
   function CSS_Box (Top, Right, Bottom, Left : Length_Value) return CSS_Box_Value is
      ((Kind => Per_Side, Sides => [Top, Right, Bottom, Left]));

   Default_CSS_Box : constant CSS_Box_Value := CSS_Box (Zero_Length);

   -------------------------------------------------
   -- Size (width/height/font-size)
   -------------------------------------------------

   type Size_Kind is (Fixed, Auto, Min_Content, Max_Content, Fit_Content);

   type Size_Value (Kind : Size_Kind := Auto) is record
      case Kind is
         when Fixed => Size : Length_Value := Zero_Length;
         when Auto | Min_Content | Max_Content | Fit_Content => null;
      end case;
   end record;

   function Size (L : Length_Value) return Size_Value is
      ((Kind => Fixed, Size => L));

   Auto_Size    : constant Size_Value := (Kind => Auto);
   Min_Content_Size  : constant Size_Value := (Kind => Min_Content);
   Max_Content_Size  : constant Size_Value := (Kind => Max_Content);
   Fit_Content_Size  : constant Size_Value := (Kind => Fit_Content);

   Default_Size      : constant Size_Value := Auto_Size;
   Default_Font_Size : constant Length_Value := Px (16);

-------------------------------------------------
-- Font Properties
-------------------------------------------------

--  Font family (reference to loaded font resource)
type Font_Handle is new Natural;
Null_Font    : constant Font_Handle := 0;
Default_Font : constant Font_Handle := Null_Font;

--  Font weight (CSS font-weight)
type Font_Weight_Value is (
   Weight_Thin,       -- 100
   Weight_Extra_Light,-- 200
   Weight_Light,      -- 300
   Weight_Normal,     -- 400
   Weight_Medium,     -- 500
   Weight_Semi_Bold,  -- 600
   Weight_Bold,       -- 700
   Weight_Extra_Bold, -- 800
   Weight_Black       -- 900
);
Default_Font_Weight : constant Font_Weight_Value := Weight_Normal;

--  Font style (CSS font-style)
type Font_Style_Value is (Style_Normal, Style_Italic, Style_Oblique);
Default_Font_Style : constant Font_Style_Value := Style_Normal;

--  Text decoration (CSS text-decoration)
type Text_Decoration_Value is (
   Decoration_None,
   Decoration_Underline,
   Decoration_Overline,
   Decoration_Line_Through
);
Default_Text_Decoration : constant Text_Decoration_Value := Decoration_None;

--  White space handling (CSS white-space)
type White_Space_Value is (
   WS_Normal,
   WS_Nowrap,
   WS_Pre,
   WS_Pre_Wrap,
   WS_Pre_Line
);
Default_White_Space : constant White_Space_Value := WS_Normal;

--  Text overflow (CSS text-overflow)
type Text_Overflow_Value is (
   Overflow_Clip,
   Overflow_Ellipsis
);
Default_Text_Overflow : constant Text_Overflow_Value := Overflow_Clip;

--  Text wrap mode (CSS text-wrap-mode)
type Text_Wrap_Mode_Value is (
   TWM_Wrap,       --  text-wrap-mode: wrap (text wraps at soft wrap opportunities)
   TWM_Nowrap      --  text-wrap-mode: nowrap (text does not wrap)
);
Default_Text_Wrap_Mode : constant Text_Wrap_Mode_Value := TWM_Wrap;

--  Line height can be a number (multiplier) or length
type Line_Height_Kind is (LH_Normal, LH_Number, LH_Length);

type Line_Height_Value (Kind : Line_Height_Kind := LH_Normal) is record
   case Kind is
      when LH_Normal => null;
      when LH_Number => Multiplier : Float := 1.2;
      when LH_Length => Height : Length_Value := Zero_Length;
   end case;
end record;

function Line_Height (Mult : Float) return Line_Height_Value is
   ((Kind => LH_Number, Multiplier => Mult));
function Line_Height (L : Length_Value) return Line_Height_Value is
   ((Kind => LH_Length, Height => L));

Normal_Line_Height  : constant Line_Height_Value := (Kind => LH_Normal);
Default_Line_Height : constant Line_Height_Value := Normal_Line_Height;

   -------------------------------------------------
   -- Text Alignment (text-align)
   -------------------------------------------------

   type Text_Align_Value is (
      Text_Left,      --  text-align: left
      Text_Right,     --  text-align: right
      Text_Center,    --  text-align: center
      Text_Justify,   --  text-align: justify
      Text_Start,     --  text-align: start (locale-aware)
      Text_End        --  text-align: end (locale-aware)
   );

   Default_Text_Align : constant Text_Align_Value := Text_Start;

   -------------------------------------------------
   -- Vertical Alignment (vertical-align for inline)
   -------------------------------------------------

   type Vertical_Align_Value is (
      VA_Baseline,
      VA_Top,
      VA_Middle,
      VA_Bottom,
      VA_Text_Top,
      VA_Text_Bottom
   );

   Default_Vertical_Align : constant Vertical_Align_Value := VA_Baseline;

   -------------------------------------------------
   -- Object Fit (object-fit for images/video)
   -------------------------------------------------

   type Object_Fit_Value is (
      Fit_Fill,       --  object-fit: fill (stretch to fill, may distort)
      Fit_Contain,    --  object-fit: contain (scale to fit, preserve aspect)
      Fit_Cover,      --  object-fit: cover (scale to cover, may crop)
      Fit_None,       --  object-fit: none (no resizing)
      Fit_Scale_Down  --  object-fit: scale-down (like none or contain, whichever is smaller)
   );

   Default_Object_Fit : constant Object_Fit_Value := Fit_Fill;

   -------------------------------------------------
   -- Object Position (object-position for images)
   -------------------------------------------------

   type Object_Position_Keyword is (
      Pos_Left, Pos_Center, Pos_Right,
      Pos_Top, Pos_Bottom
   );

   type Object_Position_Kind is (Keyword_Pos, Length_Pos);

   type Object_Position_Value (Kind : Object_Position_Kind := Keyword_Pos) is record
      case Kind is
         when Keyword_Pos =>
            H_Keyword : Object_Position_Keyword := Pos_Center;
            V_Keyword : Object_Position_Keyword := Pos_Center;
         when Length_Pos =>
            X_Offset : Length_Value := Pct (50);
            Y_Offset : Length_Value := Pct (50);
      end case;
   end record;

   function Object_Position (H, V : Object_Position_Keyword) return Object_Position_Value is
      ((Kind => Keyword_Pos, H_Keyword => H, V_Keyword => V));
   function Object_Position (X, Y : Length_Value) return Object_Position_Value is
      ((Kind => Length_Pos, X_Offset => X, Y_Offset => Y));

   Default_Object_Position : constant Object_Position_Value :=
      (Kind => Keyword_Pos, H_Keyword => Pos_Center, V_Keyword => Pos_Center);

   -------------------------------------------------
   -- Opacity
   -------------------------------------------------
   use type Adi.Core.Normalized;
   subtype Opacity_Value is Adi.Core.Normalized;
   Opacity_Opaque : constant Opacity_Value := 1.0;
   Opacity_Transparent : constant Opacity_Value := 0.0;
   Default_Opacity : constant Opacity_Value := Opacity_Opaque;

   -------------------------------------------------
   -- Box Shadow
   -------------------------------------------------

   type Box_Shadow_Value is record
      Offset_X      : Length_Value := Zero_Length;
      Offset_Y      : Length_Value := Zero_Length;
      Blur_Radius   : Length_Value := Zero_Length;
      Spread_Radius : Length_Value := Zero_Length;
      Color         : Color_Value  := RGBA (0, 0, 0, 0.25);
   end record;

   No_Shadow : constant Box_Shadow_Value := (others => <>);
   Default_Box_Shadow : constant Box_Shadow_Value := No_Shadow;

   function Shadow (Offset_X, Offset_Y, Blur, Spread : Length_Value;
                    Color : Color_Value) return Box_Shadow_Value is
      ((Offset_X, Offset_Y, Blur, Spread, Color));

   function Shadow (Blur : Length_Value) return Box_Shadow_Value is
      ((Blur_Radius => Blur, others => <>));

   -------------------------------------------------
   -- Overflow
   -------------------------------------------------

   type Overflow_Value is (
      Overflow_Visible,  --  Content not clipped
      Overflow_Hidden,   --  Content clipped, no scrollbars
      Overflow_Scroll,   --  Always show scrollbars
      Overflow_Auto      --  Scrollbars when needed
   );

   Default_Overflow : constant Overflow_Value := Overflow_Visible;

   -------------------------------------------------
   -- Cursor
   -------------------------------------------------

   type Cursor_Value is (
      Cursor_Auto,
      Cursor_Default,
      Cursor_Pointer,
      Cursor_Text,
      Cursor_Move,
      Cursor_Not_Allowed,
      Cursor_Wait,
      Cursor_Crosshair,
      Cursor_Grab,
      Cursor_Grabbing,
      Cursor_Resize_NS,
      Cursor_Resize_EW,
      Cursor_Resize_NESW,
      Cursor_Resize_NWSE
   );

   Default_Cursor : constant Cursor_Value := Cursor_Auto;

   -------------------------------------------------
   -- Visibility
   -------------------------------------------------

   type Visibility_Value is (
      Visibility_Visible,
      Visibility_Hidden,
      Visibility_Collapse
   );

   Default_Visibility : constant Visibility_Value := Visibility_Visible;

   -------------------------------------------------
   -- Flexbox Layout
   -------------------------------------------------

   type Flex_Direction_Value is (Row, Row_Reverse, Column, Column_Reverse);
   type Flex_Wrap_Value is (No_Wrap, Wrap, Wrap_Reverse);

   type Justify_Content_Value is (
      Flex_Start, Flex_End, Center,
      Space_Between, Space_Around, Space_Evenly
   );

   type Align_Items_Value is (
      Flex_Start, Flex_End, Center, Baseline, Stretch
   );

   type Align_Self_Value is (
   --  Note: Align_Self_Value reuses the same values as Align_Items_Value
   --  but with an additional 'Auto' option
      Auto, Flex_Start, Flex_End, Center, Baseline, Stretch
   );

   type Align_Content_Value is (
      Flex_Start, Flex_End, Center,
      Space_Between, Space_Around, Stretch
   );

   Default_Flex_Direction  : constant Flex_Direction_Value := Row;
   Default_Flex_Wrap       : constant Flex_Wrap_Value := No_Wrap;
   Default_Justify_Content : constant Justify_Content_Value := Flex_Start;
   Default_Align_Items     : constant Align_Items_Value := Stretch;
   Default_Align_Self      : constant Align_Self_Value := Auto;
   Default_Align_Content   : constant Align_Content_Value := Stretch;

   -- Flex item properties
   type Flex_Grow_Value is new Float range 0.0 .. Float'Last;
   type Flex_Shrink_Value is new Float range 0.0 .. Float'Last;

   Default_Flex_Grow   : constant Flex_Grow_Value := 0.0;
   Default_Flex_Shrink : constant Flex_Shrink_Value := 1.0;

   -- Flex basis
   type Flex_Basis_Kind is (Auto, Content, Fixed);

   type Flex_Basis_Value (Kind : Flex_Basis_Kind := Auto) is record
      case Kind is
         when Auto | Content => null;
         when Fixed => Size : Length_Value := Zero_Length;
      end case;
   end record;

   function Basis (L : Length_Value) return Flex_Basis_Value is
      ((Kind => Fixed, Size => L));

   Auto_Basis    : constant Flex_Basis_Value := (Kind => Auto);
   Content_Basis : constant Flex_Basis_Value := (Kind => Content);

   Default_Flex_Basis : constant Flex_Basis_Value := Auto_Basis;

   -- Gap (row-gap, column-gap)
   type Gap_Kind is (Gap_Uniform, Gap_Separate);

   type Gap_Value (Kind : Gap_Kind := Gap_Uniform) is record
      case Kind is
         when Gap_Uniform  => All_Gap : Length_Value := Zero_Length;
         when Gap_Separate => Row_Gap, Column_Gap : Length_Value := Zero_Length;
      end case;
   end record;

   function Gap (All_L : Length_Value) return Gap_Value is
      ((Kind => Gap_Uniform, All_Gap => All_L));
   function Gap (Row_G, Column_G : Length_Value) return Gap_Value is
      ((Kind => Gap_Separate, Row_Gap => Row_G, Column_Gap => Column_G));

   Default_Gap : constant Gap_Value := Gap (Zero_Length);

   -- Order
   type Order_Value is new Integer;
   Default_Order : constant Order_Value := 0;

   -------------------------------------------------
   -- Display
   -------------------------------------------------

   type Display_Value is (
      Display_None, Block, Inline, Inline_Block,
      Flex, Inline_Flex, Grid, Inline_Grid
   );

   Default_Display : constant Display_Value := Block;

   -------------------------------------------------
   -- Position
   -------------------------------------------------

   type Position_Value is (Static, Relative, Absolute, Fixed, Sticky);

   Default_Position : constant Position_Value := Static;

   -------------------------------------------------
   -- Optional wrappers with defaults
   -------------------------------------------------

   package Opt_Text_Color    is new Optional_Values (Color_Value, Default_Color);
   package Opt_Bg_Color      is new Optional_Values (Color_Value, Default_Background);
   package Opt_Bg_Image      is new Optional_Values (Background_Image_Value, Default_Background_Image);
   package Opt_Radius        is new Optional_Values (Border_Radius_Value, Default_Radius);
   package Opt_Border_Width  is new Optional_Values (Border_Width_Value, Default_Border_Width);
   package Opt_Border_Color  is new Optional_Values (Border_Color_Value, Default_Border_Color_Val);
   package Opt_Border_Style  is new Optional_Values (Border_Style_Value, Default_Border_Style);
   package Opt_Box           is new Optional_Values (CSS_Box_Value, Default_CSS_Box);
   package Opt_Size          is new Optional_Values (Size_Value, Default_Size);
   package Opt_Font_Size     is new Optional_Values (Length_Value, Default_Font_Size);
   package Opt_Display       is new Optional_Values (Display_Value, Default_Display);
   package Opt_Position      is new Optional_Values (Position_Value, Default_Position);
   package Opt_Flex_Dir      is new Optional_Values (Flex_Direction_Value, Default_Flex_Direction);
   package Opt_Flex_Wrap     is new Optional_Values (Flex_Wrap_Value, Default_Flex_Wrap);
   package Opt_Justify       is new Optional_Values (Justify_Content_Value, Default_Justify_Content);
   package Opt_Align_Items   is new Optional_Values (Align_Items_Value, Default_Align_Items);
   package Opt_Align_Self    is new Optional_Values (Align_Self_Value, Default_Align_Self);
   package Opt_Align_Content is new Optional_Values (Align_Content_Value, Default_Align_Content);
   package Opt_Flex_Grow     is new Optional_Values (Flex_Grow_Value, Default_Flex_Grow);
   package Opt_Flex_Shrink   is new Optional_Values (Flex_Shrink_Value, Default_Flex_Shrink);
   package Opt_Flex_Basis    is new Optional_Values (Flex_Basis_Value, Default_Flex_Basis);
   package Opt_Gap           is new Optional_Values (Gap_Value, Default_Gap);
   package Opt_Order         is new Optional_Values (Order_Value, Default_Order);

   --  New optional wrappers
   package Opt_Text_Align    is new Optional_Values (Text_Align_Value, Default_Text_Align);
   package Opt_Vertical_Align is new Optional_Values (Vertical_Align_Value, Default_Vertical_Align);
   package Opt_Object_Fit    is new Optional_Values (Object_Fit_Value, Default_Object_Fit);
   package Opt_Object_Pos    is new Optional_Values (Object_Position_Value, Default_Object_Position);
   package Opt_Opacity       is new Optional_Values (Opacity_Value, Default_Opacity);
   package Opt_Overflow      is new Optional_Values (Overflow_Value, Default_Overflow);
   package Opt_Box_Shadow    is new Optional_Values (Box_Shadow_Value, Default_Box_Shadow);
   package Opt_Cursor        is new Optional_Values (Cursor_Value, Default_Cursor);
   package Opt_Visibility    is new Optional_Values (Visibility_Value, Default_Visibility);

    package Opt_Font            is new Optional_Values (Font_Handle, Default_Font);
    package Opt_Font_Weight     is new Optional_Values (Font_Weight_Value, Default_Font_Weight);
    package Opt_Font_Style      is new Optional_Values (Font_Style_Value, Default_Font_Style);
    package Opt_Text_Decoration is new Optional_Values (Text_Decoration_Value, Default_Text_Decoration);
    package Opt_White_Space     is new Optional_Values (White_Space_Value, Default_White_Space);
    package Opt_Text_Overflow   is new Optional_Values (Text_Overflow_Value, Default_Text_Overflow);
    package Opt_Line_Height     is new Optional_Values (Line_Height_Value, Default_Line_Height);
    package Opt_Text_Wrap_Mode  is new Optional_Values (Text_Wrap_Mode_Value, Default_Text_Wrap_Mode);
   -------------------------------------------------
   -- Style Rules Record
   -------------------------------------------------

   type Style_Rules is record
      -- Colors
      Color            : Opt_Text_Color.Optional   := Opt_Text_Color.Unset;
      Background_Color : Opt_Bg_Color.Optional     := Opt_Bg_Color.Unset;
      Background_Image : Opt_Bg_Image.Optional     := Opt_Bg_Image.Unset;

      -- Border
      Border_Radius    : Opt_Radius.Optional       := Opt_Radius.Unset;
      Border_Width     : Opt_Border_Width.Optional := Opt_Border_Width.Unset;
      Border_Color     : Opt_Border_Color.Optional := Opt_Border_Color.Unset;
      Border_Style     : Opt_Border_Style.Optional := Opt_Border_Style.Unset;

      -- Spacing
      Padding          : Opt_Box.Optional          := Opt_Box.Unset;
      Margin           : Opt_Box.Optional          := Opt_Box.Unset;

      -- Sizing
      Width            : Opt_Size.Optional         := Opt_Size.Unset;
      Height           : Opt_Size.Optional         := Opt_Size.Unset;
      Min_Width        : Opt_Size.Optional         := Opt_Size.Unset;
      Max_Width        : Opt_Size.Optional         := Opt_Size.Unset;
      Min_Height       : Opt_Size.Optional         := Opt_Size.Unset;
      Max_Height       : Opt_Size.Optional         := Opt_Size.Unset;

      -- Typography
      Font_Family      : Opt_Font.Optional            := Opt_Font.Unset;
      Font_Size        : Opt_Font_Size.Optional       := Opt_Font_Size.Unset;
      Font_Weight      : Opt_Font_Weight.Optional     := Opt_Font_Weight.Unset;
      Font_Style       : Opt_Font_Style.Optional      := Opt_Font_Style.Unset;
      Text_Align       : Opt_Text_Align.Optional      := Opt_Text_Align.Unset;
      Vertical_Align   : Opt_Vertical_Align.Optional  := Opt_Vertical_Align.Unset;
      Text_Decoration  : Opt_Text_Decoration.Optional := Opt_Text_Decoration.Unset;
      White_Space      : Opt_White_Space.Optional     := Opt_White_Space.Unset;
      Text_Overflow    : Opt_Text_Overflow.Optional   := Opt_Text_Overflow.Unset;
      Text_Wrap_Mode   : Opt_Text_Wrap_Mode.Optional  := Opt_Text_Wrap_Mode.Unset;
      Line_Height      : Opt_Line_Height.Optional     := Opt_Line_Height.Unset;

      -- Layout
      Display          : Opt_Display.Optional      := Opt_Display.Unset;
      Position         : Opt_Position.Optional     := Opt_Position.Unset;
      Overflow         : Opt_Overflow.Optional     := Opt_Overflow.Unset;
      Visibility       : Opt_Visibility.Optional   := Opt_Visibility.Unset;

      -- Visual
      Opacity          : Opt_Opacity.Optional      := Opt_Opacity.Unset;
      Cursor           : Opt_Cursor.Optional       := Opt_Cursor.Unset;
      Box_Shadow       : Opt_Box_Shadow.Optional   := Opt_Box_Shadow.Unset;

      -- Object/Image properties
      Object_Fit       : Opt_Object_Fit.Optional   := Opt_Object_Fit.Unset;
      Object_Position  : Opt_Object_Pos.Optional   := Opt_Object_Pos.Unset;

      -- Flexbox Container
      Flex_Direction   : Opt_Flex_Dir.Optional     := Opt_Flex_Dir.Unset;
      Flex_Wrap        : Opt_Flex_Wrap.Optional    := Opt_Flex_Wrap.Unset;
      Justify_Content  : Opt_Justify.Optional      := Opt_Justify.Unset;
      Align_Items      : Opt_Align_Items.Optional  := Opt_Align_Items.Unset;
      Align_Content    : Opt_Align_Content.Optional := Opt_Align_Content.Unset;
      Gap              : Opt_Gap.Optional          := Opt_Gap.Unset;

      -- Flexbox Item
      Align_Self       : Opt_Align_Self.Optional   := Opt_Align_Self.Unset;
      Flex_Grow        : Opt_Flex_Grow.Optional    := Opt_Flex_Grow.Unset;
      Flex_Shrink      : Opt_Flex_Shrink.Optional  := Opt_Flex_Shrink.Unset;
      Flex_Basis       : Opt_Flex_Basis.Optional   := Opt_Flex_Basis.Unset;
      Order            : Opt_Order.Optional        := Opt_Order.Unset;

   end record;

   Empty_Style : constant Style_Rules := (others => <>);

   function Merge (Base, Override : Style_Rules) return Style_Rules;

   -------------------------------------------------
   -- Resolved style for rendering
   -------------------------------------------------

   type Resolved_Style is record
      -- Colors
      Color            : Color_Value;
      Background_Color : Color_Value;
      Background_Image : Background_Image_Value;

      -- Border
      Border_Radius    : Border_Radius_Value;
      Border_Width     : Border_Width_Value;
      Border_Color     : Border_Color_Value;
      Border_Style     : Border_Style_Value;

      -- Spacing
      Padding          : CSS_Box_Value;
      Margin           : CSS_Box_Value;

      -- Sizing
      Width            : Size_Value;
      Height           : Size_Value;
      Min_Width        : Size_Value;
      Max_Width        : Size_Value;
      Min_Height       : Size_Value;
      Max_Height       : Size_Value;

      -- Typography
    Font_Family      : Font_Handle;
    Font_Size        : Length_Value;
    Font_Weight      : Font_Weight_Value;
    Font_Style       : Font_Style_Value;
    Text_Align       : Text_Align_Value;
    Vertical_Align   : Vertical_Align_Value;
    Text_Decoration  : Text_Decoration_Value;
    White_Space      : White_Space_Value;
    Text_Overflow    : Text_Overflow_Value;
    Text_Wrap_Mode   : Text_Wrap_Mode_Value;
    Line_Height      : Line_Height_Value;

      -- Layout
      Display          : Display_Value;
      Position         : Position_Value;
      Overflow         : Overflow_Value;
      Visibility       : Visibility_Value;

      -- Visual
      Opacity          : Opacity_Value;
      Cursor           : Cursor_Value;
      Box_Shadow       : Box_Shadow_Value;

      -- Object/Image
      Object_Fit       : Object_Fit_Value;
      Object_Position  : Object_Position_Value;

      -- Flexbox Container
      Flex_Direction   : Flex_Direction_Value;
      Flex_Wrap        : Flex_Wrap_Value;
      Justify_Content  : Justify_Content_Value;
      Align_Items      : Align_Items_Value;
      Align_Content    : Align_Content_Value;
      Gap              : Gap_Value;

      -- Flexbox Item
      Align_Self       : Align_Self_Value;
      Flex_Grow        : Flex_Grow_Value;
      Flex_Shrink      : Flex_Shrink_Value;
      Flex_Basis       : Flex_Basis_Value;
      Order            : Order_Value;

   end record;

   function Resolve (S : Style_Rules) return Resolved_Style;

   -------------------------------------------------
   -- Shorthand helpers
   -------------------------------------------------

   -- Colors
   function Set (V : Color_Value) return Opt_Text_Color.Optional renames Opt_Text_Color.Val;
   function Set_Bg (V : Color_Value) return Opt_Bg_Color.Optional renames Opt_Bg_Color.Val;
   function Set_Bg_Image (V : Background_Image_Value) return Opt_Bg_Image.Optional renames Opt_Bg_Image.Val;
   No_Text_Color : constant Opt_Text_Color.Optional := Opt_Text_Color.Cleared;
   No_Bg_Color   : constant Opt_Bg_Color.Optional   := Opt_Bg_Color.Cleared;
   No_Bg_Image   : constant Opt_Bg_Image.Optional   := Opt_Bg_Image.Cleared;

   -- Border
   function Set (V : Border_Radius_Value) return Opt_Radius.Optional renames Opt_Radius.Val;
   function Set (V : Border_Width_Value) return Opt_Border_Width.Optional renames Opt_Border_Width.Val;
   function Set (V : Border_Color_Value) return Opt_Border_Color.Optional renames Opt_Border_Color.Val;
   function Set (V : Border_Style_Value) return Opt_Border_Style.Optional renames Opt_Border_Style.Val;
   No_Radius       : constant Opt_Radius.Optional       := Opt_Radius.Cleared;
   No_Border_Width : constant Opt_Border_Width.Optional := Opt_Border_Width.Cleared;
   No_Border_Color : constant Opt_Border_Color.Optional := Opt_Border_Color.Cleared;
   No_Border_Style : constant Opt_Border_Style.Optional := Opt_Border_Style.Cleared;

   -- CSS_Box
   function Set (V : CSS_Box_Value) return Opt_Box.Optional renames Opt_Box.Val;
   No_Box : constant Opt_Box.Optional := Opt_Box.Cleared;

   -- Size
   function Set (V : Size_Value) return Opt_Size.Optional renames Opt_Size.Val;
   function Set_Font (V : Length_Value) return Opt_Font_Size.Optional renames Opt_Font_Size.Val;
   No_Size      : constant Opt_Size.Optional      := Opt_Size.Cleared;
   No_Font_Size : constant Opt_Font_Size.Optional := Opt_Font_Size.Cleared;
    function Set (V : Font_Handle) return Opt_Font.Optional renames Opt_Font.Val;
    function Set (V : Font_Weight_Value) return Opt_Font_Weight.Optional renames Opt_Font_Weight.Val;
    function Set (V : Font_Style_Value) return Opt_Font_Style.Optional renames Opt_Font_Style.Val;
    function Set (V : Text_Decoration_Value) return Opt_Text_Decoration.Optional renames Opt_Text_Decoration.Val;
    function Set (V : White_Space_Value) return Opt_White_Space.Optional renames Opt_White_Space.Val;
    function Set (V : Text_Overflow_Value) return Opt_Text_Overflow.Optional renames Opt_Text_Overflow.Val;
    function Set (V : Text_Wrap_Mode_Value) return Opt_Text_Wrap_Mode.Optional renames Opt_Text_Wrap_Mode.Val;
    function Set (V : Line_Height_Value) return Opt_Line_Height.Optional renames Opt_Line_Height.Val;

   -- Layout
   function Set (V : Display_Value) return Opt_Display.Optional renames Opt_Display.Val;
   function Set (V : Position_Value) return Opt_Position.Optional renames Opt_Position.Val;
   function Set (V : Overflow_Value) return Opt_Overflow.Optional renames Opt_Overflow.Val;
   function Set (V : Visibility_Value) return Opt_Visibility.Optional renames Opt_Visibility.Val;

   -- Visual
   function Set (V : Opacity_Value) return Opt_Opacity.Optional renames Opt_Opacity.Val;
   function Set (V : Cursor_Value) return Opt_Cursor.Optional renames Opt_Cursor.Val;
   function Set (V : Box_Shadow_Value) return Opt_Box_Shadow.Optional renames Opt_Box_Shadow.Val;

   -- Text
   function Set (V : Text_Align_Value) return Opt_Text_Align.Optional renames Opt_Text_Align.Val;
   function Set (V : Vertical_Align_Value) return Opt_Vertical_Align.Optional renames Opt_Vertical_Align.Val;

   -- Object/Image
   function Set (V : Object_Fit_Value) return Opt_Object_Fit.Optional renames Opt_Object_Fit.Val;
   function Set (V : Object_Position_Value) return Opt_Object_Pos.Optional renames Opt_Object_Pos.Val;

   -- Flexbox
   function Set (V : Flex_Direction_Value) return Opt_Flex_Dir.Optional renames Opt_Flex_Dir.Val;
   function Set (V : Flex_Wrap_Value) return Opt_Flex_Wrap.Optional renames Opt_Flex_Wrap.Val;
   function Set (V : Justify_Content_Value) return Opt_Justify.Optional renames Opt_Justify.Val;
   function Set (V : Align_Items_Value) return Opt_Align_Items.Optional renames Opt_Align_Items.Val;
   function Set (V : Align_Self_Value) return Opt_Align_Self.Optional renames Opt_Align_Self.Val;
   function Set (V : Align_Content_Value) return Opt_Align_Content.Optional renames Opt_Align_Content.Val;
   function Set (V : Flex_Grow_Value) return Opt_Flex_Grow.Optional renames Opt_Flex_Grow.Val;
   function Set (V : Flex_Shrink_Value) return Opt_Flex_Shrink.Optional renames Opt_Flex_Shrink.Val;
   function Set (V : Flex_Basis_Value) return Opt_Flex_Basis.Optional renames Opt_Flex_Basis.Val;
   function Set (V : Gap_Value) return Opt_Gap.Optional renames Opt_Gap.Val;
   function Set (V : Order_Value) return Opt_Order.Optional renames Opt_Order.Val;

   -------------------------------------------------
   -- Example declarations
   -------------------------------------------------

   -- Flex container
   Flex_Row_Center : constant Style_Rules := (
      Display         => Set (Flex),
      Flex_Direction  => Set (Row),
      Justify_Content => Set (Center),
      Align_Items     => Set (Center),
      Gap             => Set (Gap (Dip (16))),
      others          => <>
   );

   Flex_Column : constant Style_Rules := (
      Display        => Set (Flex),
      Flex_Direction => Set (Column),
      Gap            => Set (Gap (Dip (8), Dip (0))),
      others         => <>
   );

   -- Card with border
   Card_Style : constant Style_Rules := (
      Background_Color => Set_Bg (C (White)),
      Border_Width     => Set (Border_Width (Dip (1))),
      Border_Color     => Set (Border_Color (C (Light_Gray))),
      Border_Style     => Set (Border_Style (Solid)),
      Border_Radius    => Set (Radius (Dip (8))),
      Padding          => Set (CSS_Box (Dip (16))),
      others           => <>
   );

   -- Button
   Button_Style : constant Style_Rules := (
      Display          => Set (Inline_Flex),
      Justify_Content  => Set (Center),
      Align_Items      => Set (Center),
      Color            => Set (C (White)),
      Background_Color => Set_Bg (C (Blue)),
      Border_Width     => Set (Border_Width (Dip (2))),
      Border_Color     => Set (Border_Color (C (Blue))),
      Border_Style     => Set (Border_Style (Solid)),
      Border_Radius    => Set (Radius (Dip (6))),
      Padding          => Set (CSS_Box (Dip (12), Dip (24))),
      Font_Size        => Set_Font (Dip (14)),
      Cursor           => Set (Cursor_Pointer),
      others           => <>
   );

   -- Flex item that grows
   Flex_Grow_Item : constant Style_Rules := (
      Flex_Grow   => Set (1.0),
      Flex_Shrink => Set (0.0),
      Flex_Basis  => Set (Basis (Pct (0))),
      others      => <>
   );

   -- Image cover style
   Image_Cover : constant Style_Rules := (
      Object_Fit      => Set (Fit_Cover),
      Object_Position => Set (Object_Position (Pos_Center, Pos_Center)),
      Width           => Set (Size (Pct (100))),
      Height          => Set (Size (Pct (100))),
      others          => <>
   );

   -- Centered text
   Text_Centered : constant Style_Rules := (
      Text_Align     => Set (Text_Center),
      Vertical_Align => Set (VA_Middle),
      others         => <>
   );

end Adi.CSS_Styles;
