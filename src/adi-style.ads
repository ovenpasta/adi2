with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Indefinite_Holders;

with Adi.Core; use Adi.Core;

package Adi.Style is

   type Dip_Type is new Integer;
   type Percent_Type is new Float;
   type Fr_Type is new Float;

   type Property_Kind is
     (
     --  Box Model
      Prop_X,
      Prop_Y,
      Prop_Width,
      Prop_Height,
      Prop_Min_Width,
      Prop_Min_Height,
      Prop_Max_Width,
      Prop_Max_Height,
      Prop_Margin,
      Prop_Padding,

      --  Background
      Prop_Background,
      Prop_Background_Image,

      --  Border
      Prop_Border_Width,
      Prop_Border_Color,
      Prop_Border_Radius,
      Prop_Border_Style,

      --  Effects
      Prop_Shadow,
      Prop_Opacity,

      --  Typography
      Prop_Font_Family,
      Prop_Font_Size,
      Prop_Font_Weight,
      Prop_Font_Style,
      Prop_Text_Color,
      Prop_Text_Align,
      Prop_Vertical_Align,
      Prop_Line_Height,

      --  Flexbox Layout
      Prop_Display,
      Prop_Flex_Direction,
      Prop_Flex_Wrap,
      Prop_Justify_Content,
      Prop_Align_Items,
      Prop_Align_Content,
      Prop_Gap,
      Prop_Row_Gap,
      Prop_Column_Gap,
      Prop_Flex_Grow,
      Prop_Flex_Shrink,
      Prop_Flex_Basis,
      Prop_Align_Self,

      --  Grid Layout
      Prop_Grid_Columns,
      Prop_Grid_Rows,
      Prop_Grid_Column,
      Prop_Grid_Row,
      Prop_Grid_Column_Span,
      Prop_Grid_Row_Span,

      --  Visual
      Prop_Visibility,
      Prop_Overflow,
      Prop_Cursor,

      --  Animation / Transition
      Prop_Transition_Duration,
      Prop_Transition_Easing);

   type Keyword is
     (Kw_Undefined,
      Kw_Hidden,
      Kw_Visible,
      Kw_Auto,
      Kw_None,
      Kw_Scroll,
      Kw_Clip,
      Kw_Inherit,
      Kw_Flex,
      Kw_Block,
      Kw_Grid,
      Kw_Bold,
      Kw_Normal,
      Kw_Row,
      Kw_Column,
      Kw_RowReverse,
      Kw_ColumnReverse,
      Kw_ColumnGap,
      Kw_RowGap,
      Kw_Start,
      Kw_End,
      Kw_SpaceAround,
      Kw_SpaceBetween,
      Kw_SpaceEvenly,
      Kw_Stretch,
      Kw_Center);

   type Display_Type is
     (Display_Block, Display_Flex, Display_Grid, Display_None);

   type Flex_Wrap is (Wrap_No_Wrap, Wrap_Wrap, Wrap_Wrap_Reverse);

   type Justify_Content is
     (Justify_Start,
      Justify_End,
      Justify_Center,
      Justify_Space_Between,
      Justify_Space_Around,
      Justify_Space_Evenly);

   type Align_Items is
     (Items_Start, Items_End, Items_Center, Items_Stretch, Items_Baseline);

   type Align_Content is
     (Content_Start,
      Content_End,
      Content_Center,
      Content_Stretch,
      Content_Space_Between,
      Content_Space_Around);

   type Align_Self is
     (Self_Auto,
      Self_Start,
      Self_End,
      Self_Center,
      Self_Stretch,
      Self_Baseline);

   ---------------------------------------------------------------------------
   --  Dimension Value (pixels, percentage, auto, or fr for grid)
   ---------------------------------------------------------------------------

   type Dimension_Kind is (Dim_Pixels, Dim_Dip, Dim_Percent, Dim_Auto, Dim_Fr);

   type Dimension_Value (Kind : Dimension_Kind := Dim_Auto) is record
      case Kind is
         when Dim_Pixels =>
            Pixels : Pixel_Type := 0.0;

         when Dim_Dip =>
            Dips : Dip_Type := 0;

         when Dim_Percent =>
            Percent : Percent_Type := 0.0;

         when Dim_Fr =>
            Fr : Fr_Type := 1.0;

         when Dim_Auto =>
            null;
      end case;
   end record;

   Auto : constant Dimension_Value := (Kind => Dim_Auto);

   function Px (Value : Pixel_Type) return Dimension_Value
   is (Kind => Dim_Pixels, Pixels => Value);

   function Pct (Value : Percent_Type) return Dimension_Value
   is (Kind => Dim_Percent, Percent => Value);

   function Dip (Value : Dip_Type) return Dimension_Value
   is (Kind => Dim_Dip, Dips => Value);

   function Fr (Value : Fr_Type := 1.0) return Dimension_Value
   is (Kind => Dim_Fr, Fr => Value);

   type Property_Value;
   type Property_Value_Access is access Property_Value;
   type Property_Value_Kind is
     (Null_Value,
      Int_Value,
      String_Value,
      Float_Value,
      Array_Value,
      Keyword_Value,
      Keyword_Array_Value,
      Function_Value,
      Color_Value);
      
   package Property_Value_List is new
     Ada.Containers.Vectors (Positive, Property_Value_Access);
   package Keyword_List is new Ada.Containers.Vectors (Positive, Keyword);

   --  Predefined colors
   Transparent : constant Color := (0.0, 0.0, 0.0, 0.0);
   Black       : constant Color := (0.0, 0.0, 0.0, 1.0);
   White       : constant Color := (1.0, 1.0, 1.0, 1.0);
   Red         : constant Color := (1.0, 0.0, 0.0, 1.0);
   Green       : constant Color := (0.0, 0.8, 0.0, 1.0);
   Blue        : constant Color := (0.0, 0.0, 1.0, 1.0);
   Yellow      : constant Color := (1.0, 1.0, 0.0, 1.0);
   Cyan        : constant Color := (0.0, 1.0, 1.0, 1.0);
   Magenta     : constant Color := (1.0, 0.0, 1.0, 1.0);
   Gray        : constant Color := (0.5, 0.5, 0.5, 1.0);
   Light_Gray  : constant Color := (0.75, 0.75, 0.75, 1.0);
   Dark_Gray   : constant Color := (0.25, 0.25, 0.25, 1.0);

   --  Text alignment
   type H_Alignment is (Align_Left, Align_Center, Align_Right);
   type V_Alignment is (Align_Top, Align_Middle, Align_Bottom);

   --  Font properties
   type Font_Weight is
     (Weight_Thin,
      Weight_Light,
      Weight_Normal,
      Weight_Medium,
      Weight_Semi_Bold,
      Weight_Bold,
      Weight_Extra_Bold,
      Weight_Black);

   type Font_Style is (Style_Normal, Style_Italic, Style_Oblique);

   --  Layout direction
   type Direction is (Dir_Horizontal, Dir_Vertical);

   --  Overflow handling
   type Overflow is (Overflow_Visible, Overflow_Hidden, Overflow_Scroll);

   --  Cursor types
   type Cursor is
     (Cursor_Default,
      Cursor_Pointer,
      Cursor_Text,
      Cursor_Move,
      Cursor_Resize_NS,
      Cursor_Resize_EW,
      Cursor_Not_Allowed,
      Cursor_Wait);

   --  Border styles
   type Border_Style is
     (Border_None, Border_Solid, Border_Dashed, Border_Dotted);

   type Property_Value (Kind : Property_Value_Kind) is record
      case Kind is
         when Int_Value =>
            Value_Int : Integer;

         when Null_Value =>
            null;

         when String_Value =>
            Value_String : Unbounded_String;

         when Float_Value =>
            Value_Float : Float;

         when Array_Value =>
            Values : Property_Value_List.Vector;

         when Keyword_Value =>
            Value_Keyword : Keyword;

         when Keyword_Array_Value =>
            Value_Keywords : Keyword_List.Vector;

         when Function_Value =>
            null;

         when Color_Value =>
            Value_Color : Color;
      end case;
   end record;

   --  Widget states
   type Widget_State is
     (State_Normal,
      State_Hovered,
      State_Pressed,
      State_Focused,
      State_Disabled,
      State_Selected);

   type Widget_States is array (Widget_State) of Boolean;

   No_States : constant Widget_States := (others => False);

   function Hash_Property
     (Key : Property_Kind) return Ada.Containers.Hash_Type;
   package Widget_Styles is new
     Ada.Containers.Indefinite_Hashed_Maps
       (Property_Kind,
        Property_Value,
        Hash            => Hash_Property,
        Equivalent_Keys => "=");

   type Style_Rule is record
      style : Widget_Styles.Map;
      state : Widget_States;
   end record;

   package Style_Rule_List is new
     Ada.Containers.Doubly_Linked_Lists (Style_Rule);

   type Style is record
      properties : Widget_Styles.Map;
   end record;

   function Has_Property (S : Style; id : Property_Kind) return Boolean;

   function Get_Property (S : Style; id : Property_Kind) return Property_Value;

   type Property_Value_Kind_Array is array (Property_Value_Kind) of Boolean;

   package Property_Value_Holder is new
     Ada.Containers.Indefinite_Holders (Property_Value);

   type Property_Spec is record
      Default_Value : Property_Value_Holder.Holder;
      Layout        : Boolean;
      Inherit       : Boolean;
      Draw          : Boolean;
      Check         :
        access function
          (id : Property_Kind; p : Property_Value) return Boolean;
      kinds         : Property_Value_Kind_Array;
   end record;

   Property_Specs_Array : array (Property_Kind) of Property_Spec;

   procedure Initialize_Specs;
end Adi.Style;
