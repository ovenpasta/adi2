--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Strings.Unbounded;
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

   --  Pix is an Adi extension, not CSS: one renderer pixel, always.
   --  It ignores the DIP and UI scales and the px -> dip mapping, which
   --  is what makes it the unit for a guaranteed hairline. Font sizes in
   --  pix still take the accessibility text scale.
   --  Appended so the existing positions keep their values.
   type CSS_Unit is (Px, Dip, Em, Root_Em, Pct, Vw, Vh, Pix);

   type Length_Value is record
      Amount : Float := 0.0;
      Unit   : CSS_Unit := Px;
   end record;

   function Px (V : Float) return Length_Value is ((Amount => V, Unit => Px));
   function Px (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Px));
   function Pix (V : Float) return Length_Value is ((Amount => V, Unit => Pix));
   function Pix (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Pix));
   function Dip (V : Float) return Length_Value is ((Amount => V, Unit => Dip));
   function Dip (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Dip));
   function Em (V : Float) return Length_Value is ((Amount => V, Unit => Em));
   function Em (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Em));
   function Root_Em (V : Float) return Length_Value is ((Amount => V, Unit => Root_Em));
   function Root_Em (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Root_Em));
   function Pct (V : Float) return Length_Value is ((Amount => V, Unit => Pct));
   function Pct (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Pct));
   function Vw (V : Float) return Length_Value is ((Amount => V, Unit => Vw));
   function Vw (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Vw));
   function Vh (V : Float) return Length_Value is ((Amount => V, Unit => Vh));
   function Vh (V : Integer) return Length_Value is ((Amount => Float (V), Unit => Vh));

   Zero_Length : constant Length_Value := (Amount => 0.0, Unit => Px);

   -------------------------------------------------
   -- Colors
   -------------------------------------------------

   type Named_Color is (
      Black,
      White,
      Red,
      Green,
      Blue,
      Yellow,
      Orange,
      Purple,
      Gray,
      Light_Gray,
      Dark_Gray,
      Silver,
      Maroon,
      Fuchsia,
      Lime,
      Olive,
      Navy,
      Teal,
      Aqua,
      Alice_Blue,
      Antique_White,
      Aqua_Marine,
      Azure,
      Beige,
      Bisque,
      Blanched_Almond,
      Blue_Violet,
      Brown,
      Burly_Wood,
      Cadet_Blue,
      Chartreuse,
      Chocolate,
      Coral,
      Cornflower_Blue,
      Corn_Silk,
      Crimson,
      Cyan,
      Dark_Blue,
      Dark_Cyan,
      Dark_Goldenrod,
      Dark_Green,
      Dark_Khaki,
      Dark_Magenta,
      Dark_Olive_Green,
      Dark_Orange,
      Dark_Orchid,
      Dark_Red,
      Dark_Salmon,
      Dark_Sea_Green,
      Dark_Slate_Blue,
      Dark_Slate_Gray,
      Dark_Slate_Grey,
      Dark_Turquoise,
      Dark_Violet,
      Deep_Pink,
      Deep_Sky_Blue,
      Dim_Gray,
      Dim_Grey,
      Dodger_Blue,
      Fire_Brick,
      Floral_White,
      Forest_Green,
      Gainsboro,
      Ghost_White,
      Gold,
      Goldenrod,
      Green_Yellow,
      Honey_Dew,
      Hot_Pink,
      Indian_Red,
      Indigo,
      Ivory,
      Khaki,
      Lavender,
      Lavender_Blush,
      Lawn_Green,
      Lemon_Chiffon,
      Light_Blue,
      Light_Coral,
      Light_Cyan,
      Light_Goldenrod_Yellow,
      Light_Green,
      Light_Pink,
      Light_Salmon,
      Light_Sea_Green,
      Light_Sky_Blue,
      Light_Slate_Gray,
      Light_Slate_Grey,
      Light_Steel_Blue,
      Light_Yellow,
      Lime_Green,
      Linen,
      Magenta,
      Medium_Aqua_Marine,
      Medium_Blue,
      Medium_Orchid,
      Medium_Purple,
      Medium_Sea_Green,
      Medium_Slate_Blue,
      Medium_Spring_Green,
      Medium_Turquoise,
      Medium_Violet_Red,
      Midnight_Blue,
      Mint_Cream,
      Misty_Rose,
      Moccasin,
      Navajo_White,
      Old_Lace,
      Olive_Drab,
      Orange_Red,
      Orchid,
      Pale_Goldenrod,
      Pale_Green,
      Pale_Turquoise,
      Pale_Violet_Red,
      Papaya_Whip,
      Peach_Puff,
      Peru,
      Pink,
      Plum,
      Powder_Blue,
      Rosy_Brown,
      Royal_Blue,
      Saddle_Brown,
      Salmon,
      Sandy_Brown,
      Sea_Green,
      Sea_Shell,
      Sienna,
      Sky_Blue,
      Slate_Blue,
      Slate_Gray,
      Slate_Grey,
      Snow,
      Spring_Green,
      Steel_Blue,
      Tan,
      Thistle,
      Tomato,
      Turquoise,
      Violet,
      Wheat,
      White_Smoke,
      Yellow_Green,
      Transparent,
      Inherit,
      Current_Color
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
   -- Linear Gradient
   -------------------------------------------------

   Max_Gradient_Stops : constant := 16;

   type Gradient_Stop is record
      Color    : Color_Value := C (Black);
      Position : Float       := 0.0;  -- 0.0–1.0; only valid when Has_Pos = True
      Has_Pos  : Boolean     := False;
   end record;

   type Gradient_Stop_Array is array (1 .. Max_Gradient_Stops) of Gradient_Stop;

   type Linear_Gradient_Value is record
      Angle      : Float := 180.0;  -- CSS degrees: 0=to top, 90=to right, 180=to bottom
      Stop_Count : Natural range 0 .. Max_Gradient_Stops := 0;
      Stops      : Gradient_Stop_Array;
   end record;

   --  Heap-allocated reference to a gradient value.  Stored by pointer in
   --  Background_Image_Value so that Style_Rules / Widget_Style stay thin
   --  even when many state-rule slots are present.
   type Linear_Gradient_Ref is access Linear_Gradient_Value;

   function Gradient_Stop_At
     (Color : Color_Value; Position : Float) return Gradient_Stop is
       ((Color => Color, Position => Position, Has_Pos => True));

   function Gradient_Stop_Auto (Color : Color_Value) return Gradient_Stop is
      ((Color => Color, Position => 0.0, Has_Pos => False));

   -------------------------------------------------
   -- Background Image
   -------------------------------------------------

   type Background_Image_Kind is
     (No_Image, Picture_Image, Url_Image, Linear_Gradient_Image);

   type Background_Image_Value (Kind : Background_Image_Kind := No_Image) is record
      case Kind is
         when No_Image => null;
         when Picture_Image =>
            Image : Adi.Image.Image_Handle :=
                      Adi.Image.Null_Image_Handle;
         when Url_Image =>
            URI : Ada.Strings.Unbounded.Unbounded_String;
         when Linear_Gradient_Image =>
            Gradient : Linear_Gradient_Ref := null;
      end case;
   end record;

   function No_Background_Image return Background_Image_Value is
      ((Kind => No_Image));

   function Background_Image (Img : Adi.Image.Image_Handle) return Background_Image_Value is
      ((Kind => Picture_Image, Image => Img));

   function Background_Image_URL (URI : String) return Background_Image_Value is
      ((Kind => Url_Image,
        URI  => Ada.Strings.Unbounded.To_Unbounded_String (URI)));

   function Linear_Gradient
     (Angle : Float; Stops : Gradient_Stop_Array; Count : Natural)
      return Background_Image_Value;

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
   -- Outline (uniform, not per-edge)
   -------------------------------------------------

   type Outline_Style_Kind is (Outline_None, Outline_Solid, Outline_Dashed, Outline_Dotted);

   Default_Outline_Width  : constant Length_Value := Zero_Length;
   Default_Outline_Color  : constant Color_Value := C (Current_Color);
   Default_Outline_Style  : constant Outline_Style_Kind := Outline_None;
   Default_Outline_Offset : constant Length_Value := Zero_Length;

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
   -- Inset (top/right/bottom/left) — auto = "not set"
   -------------------------------------------------

   type Inset_Kind is (Fixed, Auto);

   type Inset_Value (Kind : Inset_Kind := Auto) is record
      case Kind is
         when Fixed => Length : Length_Value := Zero_Length;
         when Auto  => null;
      end case;
   end record;

   function Inset (L : Length_Value) return Inset_Value is
      ((Kind => Fixed, Length => L));

   Auto_Inset    : constant Inset_Value := (Kind => Auto);
   Default_Inset : constant Inset_Value := Auto_Inset;

-------------------------------------------------
-- Font Properties
-------------------------------------------------

--  Font family (reference to loaded font resource)
type Font_Handle is new Natural;
Null_Font    : constant Font_Handle := 0;
Default_Font : constant Font_Handle := Null_Font;

--  Font family value for CSS cascade: either a resolved handle or a name
--  string that gets resolved at Resolve() time via Font_Name_Resolver.
type Font_Family_Kind is (By_Handle, By_Name);

type Font_Family_Value (Kind : Font_Family_Kind := By_Handle) is record
   case Kind is
      when By_Handle => Handle : Font_Handle := Default_Font;
      when By_Name   => Name   : Ada.Strings.Unbounded.Unbounded_String;
   end case;
end record;

Default_Font_Family : constant Font_Family_Value :=
  (Kind => By_Handle, Handle => Default_Font);

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

--  List style (CSS list-style-*)
type List_Style_Type_Kind is (
   List_Style_None,
   List_Style_Disc,
   List_Style_Circle,
   List_Style_Square,
   List_Style_Decimal,
   List_Style_Custom_String
);

type List_Style_Type_Value
  (Kind : List_Style_Type_Kind := List_Style_Disc) is record
   case Kind is
      when List_Style_Custom_String =>
         Marker : Ada.Strings.Unbounded.Unbounded_String :=
           Ada.Strings.Unbounded.Null_Unbounded_String;
      when others =>
         null;
   end case;
end record;

function List_String (Text : String) return List_Style_Type_Value is
  ((Kind   => List_Style_Custom_String,
    Marker => Ada.Strings.Unbounded.To_Unbounded_String (Text)));

Default_List_Style_Type : constant List_Style_Type_Value :=
  (Kind => List_Style_Disc);

type List_Style_Image_Kind is (
   List_Image_None,
   List_Image_URL
);

type List_Style_Image_Value
  (Kind : List_Style_Image_Kind := List_Image_None) is record
   case Kind is
      when List_Image_URL =>
         URI : Ada.Strings.Unbounded.Unbounded_String :=
           Ada.Strings.Unbounded.Null_Unbounded_String;
      when others =>
         null;
   end case;
end record;

function List_Image (URI : String) return List_Style_Image_Value is
  ((Kind => List_Image_URL,
    URI  => Ada.Strings.Unbounded.To_Unbounded_String (URI)));

No_List_Image : constant List_Style_Image_Value := (Kind => List_Image_None);

type List_Style_Position_Value is (
   List_Outside,
   List_Inside
);

Default_List_Style_Position : constant List_Style_Position_Value := List_Outside;

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
   -- Transition
   -------------------------------------------------

   type Easing_Kind is (Linear, Ease_In, Ease_Out, Ease_In_Out);

   --  Animatable properties that can be individually targeted
   type Animatable_Property is (
      Prop_Color,
      Prop_Background_Color,
      Prop_Border_Color,
      Prop_Border_Width,
      Prop_Border_Radius,
      Prop_Padding,
      Prop_Margin,
      Prop_Opacity,
      Prop_Box_Shadow,
      Prop_Font_Size);

   type Property_Set is array (Animatable_Property) of Boolean;

   All_Properties : constant Property_Set := [others => True];
   No_Properties  : constant Property_Set := [others => False];

   --  Helpers to build property sets
   function Props (P : Animatable_Property) return Property_Set is
      ([for I in Animatable_Property => I = P]);
   function "+" (L, R : Property_Set) return Property_Set is
      ([for P in Animatable_Property => L (P) or R (P)]);
   function "+" (L : Property_Set; R : Animatable_Property) return Property_Set is
      ([L with delta R => True]);

   type Transition_Spec is record
      Duration   : Float := 0.0;          --  Duration in seconds
      Easing     : Easing_Kind := Linear;
      Properties : Property_Set := All_Properties;  --  Which properties to animate
   end record;

   No_Transition : constant Transition_Spec := (0.0, Linear, All_Properties);
   Default_Transition : constant Transition_Spec := No_Transition;

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

   --  Gap_Separate records which axes the style actually named. Both
   --  longhands write this one field, so the cascade has to tell an axis
   --  that was set to zero from one that was never mentioned — otherwise
   --  a rule saying only `row-gap` would wipe an inherited column gap.
   type Gap_Value (Kind : Gap_Kind := Gap_Uniform) is record
      case Kind is
         when Gap_Uniform  => All_Gap : Length_Value := Zero_Length;
         when Gap_Separate =>
            Row_Gap, Column_Gap : Length_Value := Zero_Length;
            Has_Row, Has_Column : Boolean := True;
      end case;
   end record;

   function Gap (All_L : Length_Value) return Gap_Value is
      ((Kind => Gap_Uniform, All_Gap => All_L));
   function Gap (Row_G, Column_G : Length_Value) return Gap_Value is
      ((Kind => Gap_Separate, Row_Gap => Row_G, Column_Gap => Column_G,
        Has_Row => True, Has_Column => True));

   --  One axis only, as `row-gap` / `column-gap` express it.
   function Gap_Row (L : Length_Value) return Gap_Value is
      ((Kind => Gap_Separate, Row_Gap => L, Column_Gap => Zero_Length,
        Has_Row => True, Has_Column => False));
   function Gap_Column (L : Length_Value) return Gap_Value is
      ((Kind => Gap_Separate, Row_Gap => Zero_Length, Column_Gap => L,
        Has_Row => False, Has_Column => True));

   --  Axis-wise override: each axis Override names wins, the other keeps
   --  what Base had. Used both within a rule and across the cascade.
   function Overlay (Base, Override : Gap_Value) return Gap_Value;

   Default_Gap : constant Gap_Value := Gap (Zero_Length);

   -- Order
   type Order_Value is new Integer;
   Default_Order : constant Order_Value := 0;

   -- Grid container/item properties
   type Grid_Columns_Value is new Natural;
   type Grid_Rows_Value is new Natural;
   type Grid_Column_Value is new Natural;
   type Grid_Row_Value is new Natural;
   type Grid_Column_Span_Value is new Natural range 1 .. Natural'Last;
   type Grid_Row_Span_Value is new Natural range 1 .. Natural'Last;

   Default_Grid_Columns : constant Grid_Columns_Value := 1;
   Default_Grid_Rows : constant Grid_Rows_Value := 0;  -- 0 => auto
   Default_Grid_Column : constant Grid_Column_Value := 0; -- 0 => auto
   Default_Grid_Row : constant Grid_Row_Value := 0;       -- 0 => auto
   Default_Grid_Column_Span : constant Grid_Column_Span_Value := 1;
   Default_Grid_Row_Span : constant Grid_Row_Span_Value := 1;

   -- Per-column track sizing for grid-template-columns
   type Grid_Track_Kind is (Track_Auto, Track_Fr, Track_Px, Track_Pix);

   type Grid_Track_Spec is record
      Kind  : Grid_Track_Kind := Track_Fr;
      --  fr units, or for Track_Px/Track_Pix the unresolved CSS number;
      --  unused for
      --  Track_Auto. A Track_Px value is not a pixel count: resolve it
      --  through Length_To_Px (Px (Value)) so it takes the px -> dip
      --  mapping every other length takes. Track_Pix resolves through
      --  Pix and stays at renderer pixels.
      Value : Float           := 1.0;
   end record;

   Max_Grid_Tracks : constant := 16;

   type Grid_Track_Array is array (1 .. Max_Grid_Tracks) of Grid_Track_Spec;

   type Grid_Track_List is record
      Count  : Natural         := 0;  -- 0 = not set; layout falls back to equal distribution
      Tracks : Grid_Track_Array := [others => (Kind => Track_Fr, Value => 1.0)];
   end record;

   Default_Grid_Track_List : constant Grid_Track_List := (others => <>);

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
   package Opt_Size          is new Optional_Values (Size_Value, Default_Size);
   package Opt_Font_Size     is new Optional_Values (Length_Value, Default_Font_Size);
   package Opt_Display       is new Optional_Values (Display_Value, Default_Display);
   package Opt_Position      is new Optional_Values (Position_Value, Default_Position);
   package Opt_Top    is new Optional_Values (Inset_Value, Default_Inset);
   package Opt_Right  is new Optional_Values (Inset_Value, Default_Inset);
   package Opt_Bottom is new Optional_Values (Inset_Value, Default_Inset);
   package Opt_Left   is new Optional_Values (Inset_Value, Default_Inset);
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
   package Opt_Grid_Cols     is new Optional_Values (Grid_Columns_Value, Default_Grid_Columns);
   package Opt_Grid_Rows     is new Optional_Values (Grid_Rows_Value, Default_Grid_Rows);
   package Opt_Grid_Column   is new Optional_Values (Grid_Column_Value, Default_Grid_Column);
   package Opt_Grid_Row      is new Optional_Values (Grid_Row_Value, Default_Grid_Row);
   package Opt_Grid_Col_Span is new Optional_Values (Grid_Column_Span_Value, Default_Grid_Column_Span);
   package Opt_Grid_Row_Span is new Optional_Values (Grid_Row_Span_Value, Default_Grid_Row_Span);

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

     package Opt_Font_Family     is new Optional_Values (Font_Family_Value, Default_Font_Family);
     package Opt_Font renames Opt_Font_Family;
     package Opt_Font_Weight     is new Optional_Values (Font_Weight_Value, Default_Font_Weight);
     package Opt_Font_Style      is new Optional_Values (Font_Style_Value, Default_Font_Style);
     package Opt_Text_Decoration is new Optional_Values (Text_Decoration_Value, Default_Text_Decoration);
     package Opt_List_Style_Type is new Optional_Values (List_Style_Type_Value, Default_List_Style_Type);
     package Opt_List_Style_Image is new Optional_Values (List_Style_Image_Value, No_List_Image);
     package Opt_List_Style_Position is new Optional_Values (List_Style_Position_Value, Default_List_Style_Position);
     package Opt_White_Space     is new Optional_Values (White_Space_Value, Default_White_Space);
     package Opt_Text_Overflow   is new Optional_Values (Text_Overflow_Value, Default_Text_Overflow);
     package Opt_Line_Height     is new Optional_Values (Line_Height_Value, Default_Line_Height);
     package Opt_Text_Wrap_Mode  is new Optional_Values (Text_Wrap_Mode_Value, Default_Text_Wrap_Mode);
    package Opt_Transition      is new Optional_Values (Transition_Spec, Default_Transition);

   package Opt_Outline_Width  is new Optional_Values (Length_Value, Default_Outline_Width);
   package Opt_Outline_Color  is new Optional_Values (Color_Value, Default_Outline_Color);
   package Opt_Outline_Style  is new Optional_Values (Outline_Style_Kind, Default_Outline_Style);
   package Opt_Outline_Offset is new Optional_Values (Length_Value, Default_Outline_Offset);

   -------------------------------------------------
   -- Per-side rule values
   -------------------------------------------------

   --  In CSS the four sides of a box-model group are four independent
   --  properties, so each side carries its own optional and the cascade
   --  merges them one by one: `padding-top` in a later rule leaves the
   --  other three sides to whatever an earlier rule set. Only the rules
   --  are split this way; Resolved_Style still holds one concrete value
   --  per group.

   package Opt_Length     is new Optional_Values (Length_Value, Zero_Length);
   package Opt_Edge_Color is new Optional_Values (Color_Value, Default_Border_Color);
   package Opt_Edge_Style is new Optional_Values (Border_Style_Kind, None_Style);

   type Opt_Edge_Lengths   is array (Edge)   of Opt_Length.Optional;
   type Opt_Edge_Colors    is array (Edge)   of Opt_Edge_Color.Optional;
   type Opt_Edge_Styles    is array (Edge)   of Opt_Edge_Style.Optional;
   type Opt_Corner_Lengths is array (Corner) of Opt_Length.Optional;

   Unset_Edge_Lengths   : constant Opt_Edge_Lengths   := [others => Opt_Length.Unset];
   Unset_Edge_Colors    : constant Opt_Edge_Colors    := [others => Opt_Edge_Color.Unset];
   Unset_Edge_Styles    : constant Opt_Edge_Styles    := [others => Opt_Edge_Style.Unset];
   Unset_Corner_Lengths : constant Opt_Corner_Lengths := [others => Opt_Length.Unset];

   function Merge (Base, Override : Opt_Edge_Lengths) return Opt_Edge_Lengths is
     ([for E in Edge => Opt_Length.Merge (Base (E), Override (E))]);
   function Merge (Base, Override : Opt_Edge_Colors) return Opt_Edge_Colors is
     ([for E in Edge => Opt_Edge_Color.Merge (Base (E), Override (E))]);
   function Merge (Base, Override : Opt_Edge_Styles) return Opt_Edge_Styles is
     ([for E in Edge => Opt_Edge_Style.Merge (Base (E), Override (E))]);
   function Merge (Base, Override : Opt_Corner_Lengths) return Opt_Corner_Lengths is
     ([for C in Corner => Opt_Length.Merge (Base (C), Override (C))]);

   --  Concrete group values for rendering and layout.
   function To_Box           (O : Opt_Edge_Lengths)   return CSS_Box_Value;
   function To_Border_Width  (O : Opt_Edge_Lengths)   return Border_Width_Value;
   function To_Border_Color  (O : Opt_Edge_Colors)    return Border_Color_Value;
   function To_Border_Style  (O : Opt_Edge_Styles)    return Border_Style_Value;
   function To_Border_Radius (O : Opt_Corner_Lengths) return Border_Radius_Value;

   -------------------------------------------------
   -- Style Rules Record
   -------------------------------------------------

   type Style_Rules is record
      -- Colors
      Color            : Opt_Text_Color.Optional   := Opt_Text_Color.Unset;
      Background_Color : Opt_Bg_Color.Optional     := Opt_Bg_Color.Unset;
      Background_Image : Opt_Bg_Image.Optional     := Opt_Bg_Image.Unset;

      -- Border
      Border_Radius    : Opt_Corner_Lengths        := Unset_Corner_Lengths;
      Border_Width     : Opt_Edge_Lengths          := Unset_Edge_Lengths;
      Border_Color     : Opt_Edge_Colors           := Unset_Edge_Colors;
      Border_Style     : Opt_Edge_Styles           := Unset_Edge_Styles;

      -- Outline
      Outline_Width    : Opt_Outline_Width.Optional  := Opt_Outline_Width.Unset;
      Outline_Color    : Opt_Outline_Color.Optional  := Opt_Outline_Color.Unset;
      Outline_Style    : Opt_Outline_Style.Optional  := Opt_Outline_Style.Unset;
      Outline_Offset   : Opt_Outline_Offset.Optional := Opt_Outline_Offset.Unset;

      -- Spacing
      Padding          : Opt_Edge_Lengths          := Unset_Edge_Lengths;
      Margin           : Opt_Edge_Lengths          := Unset_Edge_Lengths;

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
      List_Style_Type  : Opt_List_Style_Type.Optional := Opt_List_Style_Type.Unset;
      List_Style_Image : Opt_List_Style_Image.Optional := Opt_List_Style_Image.Unset;
      List_Style_Position : Opt_List_Style_Position.Optional := Opt_List_Style_Position.Unset;
      White_Space      : Opt_White_Space.Optional     := Opt_White_Space.Unset;
      Text_Overflow    : Opt_Text_Overflow.Optional   := Opt_Text_Overflow.Unset;
      Text_Wrap_Mode   : Opt_Text_Wrap_Mode.Optional  := Opt_Text_Wrap_Mode.Unset;
      Line_Height      : Opt_Line_Height.Optional     := Opt_Line_Height.Unset;

      -- Layout
      Display          : Opt_Display.Optional      := Opt_Display.Unset;
      Position         : Opt_Position.Optional     := Opt_Position.Unset;
      Top              : Opt_Top.Optional          := Opt_Top.Unset;
      Right            : Opt_Right.Optional        := Opt_Right.Unset;
      Bottom           : Opt_Bottom.Optional       := Opt_Bottom.Unset;
      Left             : Opt_Left.Optional         := Opt_Left.Unset;
      Overflow_X       : Opt_Overflow.Optional     := Opt_Overflow.Unset;
      Overflow_Y       : Opt_Overflow.Optional     := Opt_Overflow.Unset;
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
      Grid_Columns     : Opt_Grid_Cols.Optional    := Opt_Grid_Cols.Unset;
      Grid_Rows        : Opt_Grid_Rows.Optional    := Opt_Grid_Rows.Unset;
      Grid_Column_Tracks : Grid_Track_List         := Default_Grid_Track_List;

      -- Flexbox Item
      Align_Self       : Opt_Align_Self.Optional   := Opt_Align_Self.Unset;
      Flex_Grow        : Opt_Flex_Grow.Optional    := Opt_Flex_Grow.Unset;
      Flex_Shrink      : Opt_Flex_Shrink.Optional  := Opt_Flex_Shrink.Unset;
      Flex_Basis       : Opt_Flex_Basis.Optional   := Opt_Flex_Basis.Unset;
      Order            : Opt_Order.Optional        := Opt_Order.Unset;
      Grid_Column      : Opt_Grid_Column.Optional  := Opt_Grid_Column.Unset;
      Grid_Row         : Opt_Grid_Row.Optional     := Opt_Grid_Row.Unset;
      Grid_Column_Span : Opt_Grid_Col_Span.Optional := Opt_Grid_Col_Span.Unset;
      Grid_Row_Span    : Opt_Grid_Row_Span.Optional := Opt_Grid_Row_Span.Unset;

      -- Animation
      Transition       : Opt_Transition.Optional   := Opt_Transition.Unset;

   end record;

   Empty_Style : constant Style_Rules := (others => <>);

   function Merge (Base, Override : Style_Rules) return Style_Rules;

   -------------------------------------------------
   --  CSS property enumeration and inheritance
   -------------------------------------------------

   type CSS_Property is (
      --  Colors
      Prop_Color, Prop_Background_Color, Prop_Background_Image,
      --  Border
      Prop_Border_Radius, Prop_Border_Width, Prop_Border_Color, Prop_Border_Style,
      --  Outline
      Prop_Outline_Width, Prop_Outline_Color, Prop_Outline_Style, Prop_Outline_Offset,
      --  Spacing
      Prop_Padding, Prop_Margin,
      --  Sizing
      Prop_Width, Prop_Height,
      Prop_Min_Width, Prop_Max_Width, Prop_Min_Height, Prop_Max_Height,
      --  Typography
      Prop_Font_Family, Prop_Font_Size, Prop_Font_Weight, Prop_Font_Style,
      Prop_Text_Align, Prop_Vertical_Align, Prop_Text_Decoration,
      Prop_List_Style_Type, Prop_List_Style_Image, Prop_List_Style_Position,
      Prop_White_Space, Prop_Text_Overflow, Prop_Text_Wrap_Mode, Prop_Line_Height,
      --  Layout
      --  Prop_Overflow is shorthand metadata only (expands to both axes).
      Prop_Display, Prop_Position, Prop_Overflow, Prop_Overflow_X, Prop_Overflow_Y, Prop_Visibility,
      --  Visual
      Prop_Opacity, Prop_Cursor, Prop_Box_Shadow,
      --  Object/Image
      Prop_Object_Fit, Prop_Object_Position,
      --  Flexbox Container
      Prop_Flex_Direction, Prop_Flex_Wrap, Prop_Justify_Content,
      Prop_Align_Items, Prop_Align_Content, Prop_Gap,
      Prop_Grid_Columns, Prop_Grid_Rows,
      --  Flexbox Item
      Prop_Align_Self, Prop_Flex_Grow, Prop_Flex_Shrink, Prop_Flex_Basis,
      Prop_Order, Prop_Grid_Column, Prop_Grid_Row,
      Prop_Grid_Column_Span, Prop_Grid_Row_Span,
      --  Animation
      Prop_Transition);

   type CSS_Property_Set is array (CSS_Property) of Boolean;

   --  Properties that inherit from Main_Part to sub-parts (matching CSS spec).
   --  Text/typography and cursor inherit; box-model/layout properties do not.
   Inheritable_Properties : constant CSS_Property_Set :=
     [Prop_Color           | Prop_Font_Family    | Prop_Font_Size       |
      Prop_Font_Weight     | Prop_Font_Style     | Prop_Text_Align      |
      Prop_Vertical_Align  | Prop_Text_Decoration |
      Prop_Text_Overflow   | Prop_Text_Wrap_Mode | Prop_Line_Height     |
      Prop_White_Space     | Prop_Cursor         |
      Prop_List_Style_Type | Prop_List_Style_Image |
      Prop_List_Style_Position => True,
      others => False];

   --  Inherit inheritable CSS properties from Parent into Child.
   --  For each property in Inheritable_Properties: if Child's field is
   --  Undefined, use Parent's field. Non-inheritable properties pass through.
   function Inherit_From (Parent, Child : Style_Rules) return Style_Rules;

   -------------------------------------------------
   -- Resolved style for rendering
   -------------------------------------------------

   type Resolved_Style is record
      -- Colors
      Color            : Color_Value := Default_Color;
      Background_Color : Color_Value := Default_Background;
      Background_Image : Background_Image_Value := Default_Background_Image;

      -- Border
      Border_Radius    : Border_Radius_Value := Default_Radius;
      Border_Width     : Border_Width_Value := Default_Border_Width;
      Border_Color     : Border_Color_Value := Default_Border_Color_Val;
      Border_Style     : Border_Style_Value := Default_Border_Style;

      -- Outline
      Outline_Width    : Length_Value := Default_Outline_Width;
      Outline_Color    : Color_Value := Default_Outline_Color;
      Outline_Style    : Outline_Style_Kind := Default_Outline_Style;
      Outline_Offset   : Length_Value := Default_Outline_Offset;

      -- Spacing
      Padding          : CSS_Box_Value := Default_CSS_Box;
      Margin           : CSS_Box_Value := Default_CSS_Box;

      -- Sizing
      Width            : Size_Value := Default_Size;
      Height           : Size_Value := Default_Size;
      Min_Width        : Size_Value := Default_Size;
      Max_Width        : Size_Value := Default_Size;
      Min_Height       : Size_Value := Default_Size;
      Max_Height       : Size_Value := Default_Size;

      -- Typography
      Font_Family      : Font_Handle := Default_Font;
      Font_Size        : Length_Value := Default_Font_Size;
      Font_Weight      : Font_Weight_Value := Default_Font_Weight;
      Font_Style       : Font_Style_Value := Default_Font_Style;
      Text_Align       : Text_Align_Value := Default_Text_Align;
      Vertical_Align   : Vertical_Align_Value := Default_Vertical_Align;
      Text_Decoration  : Text_Decoration_Value := Default_Text_Decoration;
      List_Style_Type  : List_Style_Type_Value := Default_List_Style_Type;
      List_Style_Image : List_Style_Image_Value := No_List_Image;
      List_Style_Position : List_Style_Position_Value := Default_List_Style_Position;
      White_Space      : White_Space_Value := Default_White_Space;
      Text_Overflow    : Text_Overflow_Value := Default_Text_Overflow;
      Text_Wrap_Mode   : Text_Wrap_Mode_Value := Default_Text_Wrap_Mode;
      Line_Height      : Line_Height_Value := Default_Line_Height;

      -- Layout (stored per-axis; `overflow` shorthand expands to both)
      Display          : Display_Value := Default_Display;
      Position         : Position_Value := Default_Position;
      Top              : Inset_Value := Default_Inset;
      Right            : Inset_Value := Default_Inset;
      Bottom           : Inset_Value := Default_Inset;
      Left             : Inset_Value := Default_Inset;
      Overflow_X       : Overflow_Value := Default_Overflow;
      Overflow_Y       : Overflow_Value := Default_Overflow;
      Visibility       : Visibility_Value := Default_Visibility;

      -- Visual
      Opacity          : Opacity_Value := Default_Opacity;
      Cursor           : Cursor_Value := Default_Cursor;
      Box_Shadow       : Box_Shadow_Value := Default_Box_Shadow;

      -- Object/Image
      Object_Fit       : Object_Fit_Value := Default_Object_Fit;
      Object_Position  : Object_Position_Value := Default_Object_Position;

      -- Flexbox Container
      Flex_Direction   : Flex_Direction_Value := Default_Flex_Direction;
      Flex_Wrap        : Flex_Wrap_Value := Default_Flex_Wrap;
      Justify_Content  : Justify_Content_Value := Default_Justify_Content;
      Align_Items      : Align_Items_Value := Default_Align_Items;
      Align_Content    : Align_Content_Value := Default_Align_Content;
      Gap              : Gap_Value := Default_Gap;
      Grid_Columns       : Grid_Columns_Value  := Default_Grid_Columns;
      Grid_Rows          : Grid_Rows_Value    := Default_Grid_Rows;
      Grid_Column_Tracks : Grid_Track_List    := Default_Grid_Track_List;

      -- Flexbox Item
      Align_Self       : Align_Self_Value := Default_Align_Self;
      Flex_Grow        : Flex_Grow_Value := Default_Flex_Grow;
      Flex_Shrink      : Flex_Shrink_Value := Default_Flex_Shrink;
      Flex_Basis       : Flex_Basis_Value := Default_Flex_Basis;
      Order            : Order_Value := Default_Order;
      Grid_Column      : Grid_Column_Value := Default_Grid_Column;
      Grid_Row         : Grid_Row_Value := Default_Grid_Row;
      Grid_Column_Span : Grid_Column_Span_Value := Default_Grid_Column_Span;
      Grid_Row_Span    : Grid_Row_Span_Value := Default_Grid_Row_Span;

      -- Animation
      Transition       : Transition_Spec := Default_Transition;

   end record;

   function Resolve (S : Style_Rules) return Resolved_Style;

   -------------------------------------------------
   -- Font name resolution callback
   -------------------------------------------------

   type Font_Name_Resolver is access function (Name : String) return Font_Handle;
   procedure Set_Font_Name_Resolver (Resolver : Font_Name_Resolver);

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

   -- Per-side values.  A whole-group value names every side at once; the
   -- element forms name one and leave the rest to the cascade.
   function Set (V : Length_Value) return Opt_Length.Optional
     renames Opt_Length.Val;
   function Set_Edge_Color (V : Color_Value) return Opt_Edge_Color.Optional
     renames Opt_Edge_Color.Val;
   function Set_Edge_Style (V : Border_Style_Kind) return Opt_Edge_Style.Optional
     renames Opt_Edge_Style.Val;

   -- Border
   function Set (V : Border_Radius_Value) return Opt_Corner_Lengths;
   function Set (V : Border_Width_Value) return Opt_Edge_Lengths;
   function Set (V : Border_Color_Value) return Opt_Edge_Colors;
   function Set (V : Border_Style_Value) return Opt_Edge_Styles;
   No_Radius       : constant Opt_Corner_Lengths := [others => Opt_Length.Cleared];
   No_Border_Width : constant Opt_Edge_Lengths   := [others => Opt_Length.Cleared];
   No_Border_Color : constant Opt_Edge_Colors    := [others => Opt_Edge_Color.Cleared];
   No_Border_Style : constant Opt_Edge_Styles    := [others => Opt_Edge_Style.Cleared];

   -- Outline
   function Set_Outline_Width (V : Length_Value) return Opt_Outline_Width.Optional renames Opt_Outline_Width.Val;
   function Set_Outline_Color (V : Color_Value) return Opt_Outline_Color.Optional renames Opt_Outline_Color.Val;
   function Set (V : Outline_Style_Kind) return Opt_Outline_Style.Optional renames Opt_Outline_Style.Val;
   function Set_Outline_Offset (V : Length_Value) return Opt_Outline_Offset.Optional renames Opt_Outline_Offset.Val;

   -- CSS_Box
   function Set (V : CSS_Box_Value) return Opt_Edge_Lengths;
   No_Box : constant Opt_Edge_Lengths := [others => Opt_Length.Cleared];

   -- Size
   function Set (V : Size_Value) return Opt_Size.Optional renames Opt_Size.Val;
   function Set_Font (V : Length_Value) return Opt_Font_Size.Optional renames Opt_Font_Size.Val;
   No_Size      : constant Opt_Size.Optional      := Opt_Size.Cleared;
   No_Font_Size : constant Opt_Font_Size.Optional := Opt_Font_Size.Cleared;
     function Set (V : Font_Handle) return Opt_Font.Optional is
       (Opt_Font.Val ((Kind => By_Handle, Handle => V)));
     function Set_Font_Family (Name : String) return Opt_Font.Optional is
       (Opt_Font.Val ((Kind => By_Name,
                        Name => Ada.Strings.Unbounded.To_Unbounded_String (Name))));
     function Set (V : Font_Weight_Value) return Opt_Font_Weight.Optional renames Opt_Font_Weight.Val;
     function Set (V : Font_Style_Value) return Opt_Font_Style.Optional renames Opt_Font_Style.Val;
     function Set (V : Text_Decoration_Value) return Opt_Text_Decoration.Optional renames Opt_Text_Decoration.Val;
     function Set (V : List_Style_Type_Value) return Opt_List_Style_Type.Optional renames Opt_List_Style_Type.Val;
     function Set (V : List_Style_Image_Value) return Opt_List_Style_Image.Optional renames Opt_List_Style_Image.Val;
     function Set (V : List_Style_Position_Value) return Opt_List_Style_Position.Optional renames Opt_List_Style_Position.Val;
     function Set (V : White_Space_Value) return Opt_White_Space.Optional renames Opt_White_Space.Val;
     function Set (V : Text_Overflow_Value) return Opt_Text_Overflow.Optional renames Opt_Text_Overflow.Val;
     function Set (V : Text_Wrap_Mode_Value) return Opt_Text_Wrap_Mode.Optional renames Opt_Text_Wrap_Mode.Val;
     function Set (V : Line_Height_Value) return Opt_Line_Height.Optional renames Opt_Line_Height.Val;

   -- Layout
   function Set (V : Display_Value) return Opt_Display.Optional renames Opt_Display.Val;
   function Set (V : Position_Value) return Opt_Position.Optional renames Opt_Position.Val;
   function Set_Top    (V : Inset_Value) return Opt_Top.Optional    renames Opt_Top.Val;
   function Set_Right  (V : Inset_Value) return Opt_Right.Optional  renames Opt_Right.Val;
   function Set_Bottom (V : Inset_Value) return Opt_Bottom.Optional renames Opt_Bottom.Val;
   function Set_Left   (V : Inset_Value) return Opt_Left.Optional   renames Opt_Left.Val;
   --  Convenience helper for axis assignments.
   --  Style_Rules/Resolved_Style do not store a standalone `Overflow` field.
   function Set (V : Overflow_Value) return Opt_Overflow.Optional renames Opt_Overflow.Val;
   function Set_Overflow_X (V : Overflow_Value) return Opt_Overflow.Optional renames Opt_Overflow.Val;
   function Set_Overflow_Y (V : Overflow_Value) return Opt_Overflow.Optional renames Opt_Overflow.Val;
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
   function Set (V : Grid_Columns_Value) return Opt_Grid_Cols.Optional renames Opt_Grid_Cols.Val;
   function Set (V : Grid_Rows_Value) return Opt_Grid_Rows.Optional renames Opt_Grid_Rows.Val;
   function Set (V : Grid_Column_Value) return Opt_Grid_Column.Optional renames Opt_Grid_Column.Val;
   function Set (V : Grid_Row_Value) return Opt_Grid_Row.Optional renames Opt_Grid_Row.Val;
   function Set (V : Grid_Column_Span_Value) return Opt_Grid_Col_Span.Optional renames Opt_Grid_Col_Span.Val;
   function Set (V : Grid_Row_Span_Value) return Opt_Grid_Row_Span.Optional renames Opt_Grid_Row_Span.Val;

   -- Animation
   function Set (V : Transition_Spec) return Opt_Transition.Optional renames Opt_Transition.Val;

   -------------------------------------------------
   -- Color Normalization Helper
   -------------------------------------------------

   function Parse_Named_Color
     (Name  : String;
      Value : out Named_Color) return Boolean;

   procedure Normalize_Color (C : Color_Value;
                              R, G, B : out Natural;
                              A : out Float);

end Adi.CSS_Styles;
