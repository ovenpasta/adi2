package body Adi.CSS_Styles is

   -------------------------------------------------
   -- Merge: Combine two Style_Rules (Override wins for set values)
   -------------------------------------------------

   function Merge (Base, Override : Style_Rules) return Style_Rules is
   begin
      return (
         -- Colors
         Color            => Opt_Text_Color.Merge (Base.Color, Override.Color),
         Background_Color => Opt_Bg_Color.Merge (Base.Background_Color, Override.Background_Color),
         Background_Image => Opt_Bg_Image.Merge (Base.Background_Image, Override.Background_Image),

         -- Border
         Border_Radius    => Opt_Radius.Merge (Base.Border_Radius, Override.Border_Radius),
         Border_Width     => Opt_Border_Width.Merge (Base.Border_Width, Override.Border_Width),
         Border_Color     => Opt_Border_Color.Merge (Base.Border_Color, Override.Border_Color),
         Border_Style     => Opt_Border_Style.Merge (Base.Border_Style, Override.Border_Style),

         -- Spacing
         Padding          => Opt_Box.Merge (Base.Padding, Override.Padding),
         Margin           => Opt_Box.Merge (Base.Margin, Override.Margin),

         -- Sizing
         Width            => Opt_Size.Merge (Base.Width, Override.Width),
         Height           => Opt_Size.Merge (Base.Height, Override.Height),
         Min_Width        => Opt_Size.Merge (Base.Min_Width, Override.Min_Width),
         Max_Width        => Opt_Size.Merge (Base.Max_Width, Override.Max_Width),
         Min_Height       => Opt_Size.Merge (Base.Min_Height, Override.Min_Height),
         Max_Height       => Opt_Size.Merge (Base.Max_Height, Override.Max_Height),

         -- Typography
         Font_Size        => Opt_Font_Size.Merge (Base.Font_Size, Override.Font_Size),
         Font_Family      => Opt_Font.Merge (Base.Font_Family, Override.Font_Family),
         Font_Weight      => Opt_Font_Weight.Merge (Base.Font_Weight, Override.Font_Weight),
         Font_Style       => Opt_Font_Style.Merge (Base.Font_Style, Override.Font_Style),
         Text_Decoration  => Opt_Text_Decoration.Merge (Base.Text_Decoration, Override.Text_Decoration),
         White_Space      => Opt_White_Space.Merge (Base.White_Space, Override.White_Space),
         Text_Overflow    => Opt_Text_Overflow.Merge (Base.Text_Overflow, Override.Text_Overflow),
         Text_Wrap_Mode   => Opt_Text_Wrap_Mode.Merge (Base.Text_Wrap_Mode, Override.Text_Wrap_Mode),
         Line_Height      => Opt_Line_Height.Merge (Base.Line_Height, Override.Line_Height),

         Text_Align       => Opt_Text_Align.Merge (Base.Text_Align, Override.Text_Align),
         Vertical_Align   => Opt_Vertical_Align.Merge (Base.Vertical_Align, Override.Vertical_Align),

         -- Layout
         Display          => Opt_Display.Merge (Base.Display, Override.Display),
         Position         => Opt_Position.Merge (Base.Position, Override.Position),
         Overflow         => Opt_Overflow.Merge (Base.Overflow, Override.Overflow),
         Visibility       => Opt_Visibility.Merge (Base.Visibility, Override.Visibility),

         -- Visual
         Opacity          => Opt_Opacity.Merge (Base.Opacity, Override.Opacity),
         Cursor           => Opt_Cursor.Merge (Base.Cursor, Override.Cursor),

         -- Object/Image
         Object_Fit       => Opt_Object_Fit.Merge (Base.Object_Fit, Override.Object_Fit),
         Object_Position  => Opt_Object_Pos.Merge (Base.Object_Position, Override.Object_Position),

         -- Flexbox Container
         Flex_Direction   => Opt_Flex_Dir.Merge (Base.Flex_Direction, Override.Flex_Direction),
         Flex_Wrap        => Opt_Flex_Wrap.Merge (Base.Flex_Wrap, Override.Flex_Wrap),
         Justify_Content  => Opt_Justify.Merge (Base.Justify_Content, Override.Justify_Content),
         Align_Items      => Opt_Align_Items.Merge (Base.Align_Items, Override.Align_Items),
         Align_Content    => Opt_Align_Content.Merge (Base.Align_Content, Override.Align_Content),
         Gap              => Opt_Gap.Merge (Base.Gap, Override.Gap),

         -- Flexbox Item
         Align_Self       => Opt_Align_Self.Merge (Base.Align_Self, Override.Align_Self),
         Flex_Grow        => Opt_Flex_Grow.Merge (Base.Flex_Grow, Override.Flex_Grow),
         Flex_Shrink      => Opt_Flex_Shrink.Merge (Base.Flex_Shrink, Override.Flex_Shrink),
         Flex_Basis       => Opt_Flex_Basis.Merge (Base.Flex_Basis, Override.Flex_Basis),
         Order            => Opt_Order.Merge (Base.Order, Override.Order)
      );
   end Merge;

   -------------------------------------------------
   -- Resolve: Convert Style_Rules to Resolved_Style
   -------------------------------------------------

   function Resolve (S : Style_Rules) return Resolved_Style is
   begin
      return (
         -- Colors
         Color            => Opt_Text_Color.Resolve (S.Color),
         Background_Color => Opt_Bg_Color.Resolve (S.Background_Color),
         Background_Image => Opt_Bg_Image.Resolve (S.Background_Image),

         -- Border
         Border_Radius    => Opt_Radius.Resolve (S.Border_Radius),
         Border_Width     => Opt_Border_Width.Resolve (S.Border_Width),
         Border_Color     => Opt_Border_Color.Resolve (S.Border_Color),
         Border_Style     => Opt_Border_Style.Resolve (S.Border_Style),

         -- Spacing
         Padding          => Opt_Box.Resolve (S.Padding),
         Margin           => Opt_Box.Resolve (S.Margin),

         -- Sizing
         Width            => Opt_Size.Resolve (S.Width),
         Height           => Opt_Size.Resolve (S.Height),
         Min_Width        => Opt_Size.Resolve (S.Min_Width),
         Max_Width        => Opt_Size.Resolve (S.Max_Width),
         Min_Height       => Opt_Size.Resolve (S.Min_Height),
         Max_Height       => Opt_Size.Resolve (S.Max_Height),

         -- Typography
         Font_Size        => Opt_Font_Size.Resolve (S.Font_Size),
         Font_Family      => Opt_Font.Resolve (S.Font_Family),
         Font_Weight      => Opt_Font_Weight.Resolve (S.Font_Weight),
         Font_Style       => Opt_Font_Style.Resolve (S.Font_Style),
         Text_Decoration  => Opt_Text_Decoration.Resolve (S.Text_Decoration),
         White_Space      => Opt_White_Space.Resolve (S.White_Space),
         Text_Overflow    => Opt_Text_Overflow.Resolve (S.Text_Overflow),
         Text_Wrap_Mode   => Opt_Text_Wrap_Mode.Resolve (S.Text_Wrap_Mode),
         Line_Height      => Opt_Line_Height.Resolve (S.Line_Height),

         Text_Align       => Opt_Text_Align.Resolve (S.Text_Align),
         Vertical_Align   => Opt_Vertical_Align.Resolve (S.Vertical_Align),

         -- Layout
         Display          => Opt_Display.Resolve (S.Display),
         Position         => Opt_Position.Resolve (S.Position),
         Overflow         => Opt_Overflow.Resolve (S.Overflow),
         Visibility       => Opt_Visibility.Resolve (S.Visibility),

         -- Visual
         Opacity          => Opt_Opacity.Resolve (S.Opacity),
         Cursor           => Opt_Cursor.Resolve (S.Cursor),

         -- Object/Image
         Object_Fit       => Opt_Object_Fit.Resolve (S.Object_Fit),
         Object_Position  => Opt_Object_Pos.Resolve (S.Object_Position),

         -- Flexbox Container
         Flex_Direction   => Opt_Flex_Dir.Resolve (S.Flex_Direction),
         Flex_Wrap        => Opt_Flex_Wrap.Resolve (S.Flex_Wrap),
         Justify_Content  => Opt_Justify.Resolve (S.Justify_Content),
         Align_Items      => Opt_Align_Items.Resolve (S.Align_Items),
         Align_Content    => Opt_Align_Content.Resolve (S.Align_Content),
         Gap              => Opt_Gap.Resolve (S.Gap),

         -- Flexbox Item
         Align_Self       => Opt_Align_Self.Resolve (S.Align_Self),
         Flex_Grow        => Opt_Flex_Grow.Resolve (S.Flex_Grow),
         Flex_Shrink      => Opt_Flex_Shrink.Resolve (S.Flex_Shrink),
         Flex_Basis       => Opt_Flex_Basis.Resolve (S.Flex_Basis),
         Order            => Opt_Order.Resolve (S.Order)
      );
   end Resolve;

end Adi.CSS_Styles;