--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Parser;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Test_Support; use Test_Support;

--  The composer against the aggregate it replaces. Interning is
--  canonical, so a style written either way answers one handle and the
--  two paths agree exactly rather than equivalently -- the shape
--  tests/src/side_longhand_test.adb uses for the two CSS pipelines.
procedure Style_Composer_Test is

   Blue   : constant Color_Value := RGB (37, 99, 235);
   Deep   : constant Color_Value := RGB (29, 78, 216);
   Danger : constant Color_Value := RGB (200, 30, 30);

   Pad    : constant CSS_Box_Value := CSS_Box (Px (12.0), Px (24.0));
   Round  : constant Border_Radius_Value := Radius (Px (6.0));
   Drop   : constant Box_Shadow_Value :=
     Shadow (Px (0.0), Px (2.0), Px (4.0), Px (0.0), RGBA (0, 0, 0, 0.3));

   --  The values that carry interned text or a shared gradient, built
   --  once so that the chain and the aggregate name the same one.
   Wallpaper   : constant Background_Image_Value :=
     Background_Image_URL ("images/paper.png");
   Sweep       : constant Background_Image_Value :=
     Linear_Gradient
       (90.0,
        [1 => Gradient_Stop_At (Blue, 0.0),
         2 => Gradient_Stop_At (Deep, 1.0),
         others => Gradient_Stop_Auto (C (Black))],
        2);
   Loaded_Font   : constant Font_Handle := Font_Handle (7);
   Square_Marker : constant List_Style_Type_Value :=
     (Kind => List_Style_Square);
   Dash_Marker   : constant List_Style_Type_Value := List_String ("-- ");
   Bullet        : constant List_Style_Image_Value :=
     List_Image ("images/bullet.png");

   ---------------------------------------------------------------------
   --  Widths
   ---------------------------------------------------------------------

   procedure Test_Widths is
   begin
      Section ("what a chain step costs");

      Assert (Slot_Bytes = 8,
              "a chain step is eight bytes, not" & Slot_Bytes'Image);
      Assert (Composer_Bytes = 24,
              "a composer is twenty-four bytes, not" & Composer_Bytes'Image);

      Put_Line
        ("      slot" & Slot_Bytes'Image
         & " B, composer" & Composer_Bytes'Image
         & " B, an eight-property rule" & Natural'Image (8 * Slot_Bytes)
         & " B against a Style_Rules at"
         & Natural'Image (Style_Rules'Max_Size_In_Storage_Elements) & " B");
   end Test_Widths;

   ---------------------------------------------------------------------
   --  Value references
   ---------------------------------------------------------------------

   procedure Test_Value_Refs is
      Wide  : constant Color_Value := RGBA (9, 9, 9, 0.5);
      Before : Natural;
      First, Second : Value_Ref;
   begin
      Section ("a value narrow enough reaches no store");

      Assert (not Is_Stored (Intern (C (Red))),
              "a named colour sits in the reference");
      Assert (Color_Of (Intern (C (Red))) = C (Red),
              "and reads back as itself");

      Assert (not Is_Stored (Intern (RGB (12, 34, 56))),
              "a channel triple in eight bits each sits in the reference");
      Assert (Color_Of (Intern (RGB (12, 34, 56))) = RGB (12, 34, 56),
              "and reads back as itself");

      Assert (Is_Stored (Intern (RGB (300, 0, 0))),
              "a channel past 255 reaches the store");
      Assert (Color_Of (Intern (RGB (300, 0, 0))) = RGB (300, 0, 0),
              "and reads back exact");

      Assert (Is_Stored (Intern (Wide)), "an alpha reaches the store");
      Assert (Color_Of (Intern (Wide)) = Wide, "and reads back exact");

      Assert (not Is_Stored (Intern (Px (12.0))),
              "a whole length sits in the reference");
      Assert (Length_Of (Intern (Px (12.0))) = Px (12.0),
              "and reads back as itself");
      Assert (not Is_Stored (Intern (Em (2.0))),
              "the unit rides beside the magnitude");
      Assert (Length_Of (Intern (Em (2.0))) = Em (2.0),
              "and reads back as itself");

      Assert (Is_Stored (Intern (Px (12.5))),
              "a fractional length reaches the store");
      Assert (Length_Of (Intern (Px (12.5))) = Px (12.5),
              "and reads back exact");
      Assert (Is_Stored (Intern (Px (-4.0))),
              "a negative length reaches the store");
      Assert (Length_Of (Intern (Px (-4.0))) = Px (-4.0),
              "and reads back exact");

      Assert (not Is_Stored (Intern (Flex)),
              "an enumeration is its own reference");
      Assert (Display_Of (Intern (Flex)) = Flex, "and reads back as itself");

      Assert (Is_Stored (Intern (Pad)), "a side box reaches the store");
      Assert (Box_Of (Intern (Pad)) = Pad, "and reads back exact");
      Assert (Is_Stored (Intern (Drop)), "a shadow reaches the store");
      Assert (Box_Shadow_Of (Intern (Drop)) = Drop, "and reads back exact");
      Assert (Is_Stored (Intern (Border_Color (C (Red)))),
              "a border colour reaches the store");
      Assert (Border_Color_Of (Intern (Border_Color (C (Red))))
                = Border_Color (C (Red)),
              "and reads back exact");

      Assert (not Is_Stored (Intern (Grid_Columns_Value (3))),
              "a grid count is its own reference");
      Assert (Grid_Columns_Of (Intern (Grid_Columns_Value (3)))
                = Grid_Columns_Value (3),
              "and reads back as itself");
      Assert (not Is_Stored (Intern (Order_Value (5))),
              "an order at or above zero sits in the reference");
      Assert (Order_Of (Intern (Order_Value (5))) = Order_Value (5),
              "and reads back as itself");
      Assert (Is_Stored (Intern (Order_Value (-2))),
              "an order below zero reaches the store");
      Assert (Order_Of (Intern (Order_Value (-2))) = Order_Value (-2),
              "and reads back exact");

      Section ("a value carrying interned text reaches a store");

      Assert (Is_Stored (Intern (Wallpaper)),
              "a URL background reaches the store");
      Assert (Background_Image_Of (Intern (Wallpaper)) = Wallpaper,
              "and reads back exact, text id and all");
      Assert (Is_Stored (Intern (Sweep)),
              "a gradient background reaches the store");
      Assert (Background_Image_Of (Intern (Sweep)) = Sweep,
              "and reads back as the one shared gradient it names");
      Assert (Intern (Sweep)
                = Intern (Linear_Gradient
                            (90.0,
                             [1 => Gradient_Stop_At (Blue, 0.0),
                              2 => Gradient_Stop_At (Deep, 1.0),
                              others => Gradient_Stop_Auto (C (Black))],
                             2)),
              "so an equal gradient built again answers one reference");
      Assert (Font_Family_Of
                (Intern (Font_Family_Value'(Kind => By_Name,
                                            Name => Intern_Text ("Inter"))))
                = Font_Family_Value'(Kind => By_Name,
                                     Name => Intern_Text ("Inter")),
              "a font family named in text reads back exact");
      Assert (List_Style_Type_Of (Intern (Dash_Marker)) = Dash_Marker,
              "a custom list marker reads back exact");
      Assert (List_Style_Image_Of (Intern (Bullet)) = Bullet,
              "and so does a list image");

      Section ("equal values share one entry");

      Before := Interned_Values;
      First := Intern (RGBA (9, 9, 9, 0.25));
      Assert (Interned_Values = Before + 1, "a fresh value takes an entry");
      Second := Intern (RGBA (9, 9, 9, 0.25));
      Assert (First = Second, "an equal value answers the same reference");
      Assert (Interned_Values = Before + 1, "and takes no second entry");
      Assert (Interned_Value_Bytes >= 4 * Interned_Values,
              "and the stores report the storage their entries occupy");
   end Test_Value_Refs;

   ---------------------------------------------------------------------
   --  The two authoring paths
   ---------------------------------------------------------------------

   procedure Test_One_Property is
      By_Aggregate : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue), others => <>)).Build;
      By_Chain : constant Widget_Style := Style_Of.Background (Blue).Build;
   begin
      Section ("one property, either way");

      Assert (By_Aggregate = By_Chain,
              "a chain of one property interns to the aggregate's handle");
   end Test_One_Property;

   procedure Test_Several_Properties is
      By_Aggregate : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue),
               Padding          => Set (Pad),
               Border_Radius    => Set (Round),
               Border_Color     => Set (Border_Color (C (Red))),
               Box_Shadow       => Set (Drop),
               Display          => Set (Flex),
               Font_Size        => Set_Font (Px (14.0)),
               Flex_Grow        => Set (Flex_Grow_Value (1.0)),
               Cursor           => Set (Cursor_Pointer),
               Gap              => Set (Gap (Px (8.0))),
               others           => <>)).Build;

      By_Chain : constant Widget_Style :=
        Style_Of
          .Background (Blue)
          .Padding (Pad)
          .Radius (Round)
          .Border_Color (Border_Color (C (Red)))
          .Box_Shadow (Drop)
          .Display (Flex)
          .Font_Size (Px (14.0))
          .Flex_Grow (1.0)
          .Cursor_Style (Cursor_Pointer)
          .Gap (Gap (Px (8.0)))
        .Build;
   begin
      Section ("every value shape, either way");

      Assert (By_Aggregate = By_Chain,
              "a chain over ten properties interns to the aggregate's "
              & "handle");
   end Test_Several_Properties;

   procedure Test_Several_Rules is
      By_Aggregate : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue),
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             others           => <>))
          .On (Sel_Focused, (Border_Color => Set (Border_Color (C (White))),
                             others       => <>))
          .Build;

      By_Chain : constant Widget_Style :=
        Style_Of
          .Background (Blue)
          .Padding (Pad)
        .On_Hover
          .Background (Deep)
        .On_Focus
          .Border_Color (Border_Color (C (White)))
        .Build;
   begin
      Section ("a base and two state rules, either way");

      Assert (By_Aggregate = By_Chain,
              "a chain over three rules interns to the aggregate's handle");
   end Test_Several_Rules;

   procedure Test_Rule_Reuse is
      By_Aggregate : constant Widget_Style :=
        From (Empty_Style)
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             Color            => Set (C (White)),
                             others           => <>))
          .Build;

      By_Chain : constant Widget_Style :=
        Style_Of
        .On_Hover
          .Background (Deep)
        .On_Hover
          .Text_Color (C (White))
        .Build;
      --  Past Max_Style_Rules moves, a chain that took a fresh rule per
      --  move would run out and fold the rest onto whichever rule it
      --  was left standing on.
      Alternating : Composer := Style_Of;
   begin
      Section ("a selector named twice is one rule");

      Assert (By_Aggregate = By_Chain,
              ".On_Hover twice fills one rule rather than adding a second");

      for Unused_Pass in 1 .. Max_Style_Rules loop
         Alternating := Alternating.On_Hover.Background (Deep);
         Alternating := Alternating.On_Focus.Text_Color (C (White));
      end loop;
      Alternating := Alternating.On_Hover.Background (Deep);

      Assert (Alternating.Build
                = From (Empty_Style)
                    .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                                       others           => <>))
                    .On (Sel_Focused, (Color  => Set (C (White)),
                                       others => <>))
                    .Build,
              "moving between two selectors many times keeps two rules");
   end Test_Rule_Reuse;

   procedure Test_Empty_Chain is
      By_Builder : constant Widget_Style := Create.Build;
      By_Chain   : constant Widget_Style := Style_Of.Build;
   begin
      Section ("a chain that names nothing");

      Assert (By_Chain = By_Builder,
              "an empty chain interns to what an empty builder does");
      Assert (By_Chain = Empty_Widget_Style,
              "which is the empty style");
   end Test_Empty_Chain;

   ---------------------------------------------------------------------
   --  Every setter, one at a time
   ---------------------------------------------------------------------

   --  A setter that named the wrong field would compile and pass every
   --  test above, so each one gets an assertion of its own: the chain
   --  naming one property against the aggregate naming that field.
   --  Every CSS_Property has a setter here, the overflow shorthand
   --  included, and Test_Residue below drives the same set through
   --  Apply_Property and Clear_Property.
   procedure Same (Chain : Widget_Style; Agg : Style_Rules; Prop : String) is
   begin
      Assert (Chain = From (Agg).Build,
              "the " & Prop & " setter names the " & Prop & " field");
   end Same;

   procedure Test_Every_Setter is
      L  : constant Length_Value := Px (7.0);
      Sz : constant Size_Value := Size (Px (120.0));
   begin
      Section ("each setter against the field it names");

      Same (Style_Of.Text_Color (C (Red)).Build,
            (Color => Set (C (Red)), others => <>), "color");
      Same (Style_Of.Background (Blue).Build,
            (Background_Color => Set_Bg (Blue), others => <>),
            "background-color");
      Same (Style_Of.Radius (Round).Build,
            (Border_Radius => Set (Round), others => <>), "border-radius");
      Same (Style_Of.Border_Width (Border_Width (L)).Build,
            (Border_Width => Set (Border_Width (L)), others => <>),
            "border-width");
      Same (Style_Of.Border_Color (Border_Color (C (Lime))).Build,
            (Border_Color => Set (Border_Color (C (Lime))), others => <>),
            "border-color");
      Same (Style_Of.Border_Style (Border_Style (Dashed)).Build,
            (Border_Style => Set (Border_Style (Dashed)), others => <>),
            "border-style");
      Same (Style_Of.Outline_Width (L).Build,
            (Outline_Width => Set_Outline_Width (L), others => <>),
            "outline-width");
      Same (Style_Of.Outline_Color (C (Teal)).Build,
            (Outline_Color => Set_Outline_Color (C (Teal)), others => <>),
            "outline-color");
      Same (Style_Of.Outline_Offset (L).Build,
            (Outline_Offset => Set_Outline_Offset (L), others => <>),
            "outline-offset");
      Same (Style_Of.Padding (Pad).Build,
            (Padding => Set (Pad), others => <>), "padding");
      Same (Style_Of.Margin (Pad).Build,
            (Margin => Set_Margin (Pad), others => <>), "margin");
      Same (Style_Of.Width (Sz).Build,
            (Width => Set (Sz), others => <>), "width");
      Same (Style_Of.Height (Sz).Build,
            (Height => Set (Sz), others => <>), "height");
      Same (Style_Of.Min_Width (Sz).Build,
            (Min_Width => Set (Sz), others => <>), "min-width");
      Same (Style_Of.Max_Width (Sz).Build,
            (Max_Width => Set (Sz), others => <>), "max-width");
      Same (Style_Of.Min_Height (Sz).Build,
            (Min_Height => Set (Sz), others => <>), "min-height");
      Same (Style_Of.Max_Height (Sz).Build,
            (Max_Height => Set (Sz), others => <>), "max-height");
      Same (Style_Of.Font_Size (L).Build,
            (Font_Size => Set_Font (L), others => <>), "font-size");
      Same (Style_Of.Font_Weight (Weight_Bold).Build,
            (Font_Weight => Set (Weight_Bold), others => <>), "font-weight");
      Same (Style_Of.Text_Align (Text_Center).Build,
            (Text_Align => Set (Text_Center), others => <>), "text-align");
      Same (Style_Of.Text_Wrap_Mode (TWM_Nowrap).Build,
            (Text_Wrap_Mode => Set (TWM_Nowrap), others => <>),
            "text-wrap-mode");
      Same (Style_Of.Display (Flex).Build,
            (Display => Set (Flex), others => <>), "display");
      Same (Style_Of.Overflow_X (Overflow_Scroll).Build,
            (Overflow_X => Set (Overflow_Scroll), others => <>), "overflow-x");
      Same (Style_Of.Overflow_Y (Overflow_Scroll).Build,
            (Overflow_Y => Set (Overflow_Scroll), others => <>), "overflow-y");
      Same (Style_Of.Overflow (Overflow_Scroll).Build,
            (Overflow_X => Set (Overflow_Scroll),
             Overflow_Y => Set (Overflow_Scroll), others => <>), "overflow");
      Same (Style_Of.Opacity (0.5).Build,
            (Opacity => Set (Opacity_Value (0.5)), others => <>), "opacity");
      Same (Style_Of.Cursor_Style (Cursor_Pointer).Build,
            (Cursor => Set (Cursor_Pointer), others => <>), "cursor");
      Same (Style_Of.Box_Shadow (Drop).Build,
            (Box_Shadow => Set (Drop), others => <>), "box-shadow");
      Same (Style_Of.Flex_Direction (Column).Build,
            (Flex_Direction => Set (Column), others => <>), "flex-direction");
      Same (Style_Of.Justify_Content (Space_Between).Build,
            (Justify_Content => Set (Space_Between), others => <>),
            "justify-content");
      Same (Style_Of.Align_Items (Baseline).Build,
            (Align_Items => Set (Baseline), others => <>), "align-items");
      Same (Style_Of.Gap (Gap (Px (8.0))).Build,
            (Gap => Set (Gap (Px (8.0))), others => <>), "gap");
      Same (Style_Of.Flex_Grow (2.0).Build,
            (Flex_Grow => Set (Flex_Grow_Value (2.0)), others => <>),
            "flex-grow");
      Same (Style_Of.Flex_Shrink (3.0).Build,
            (Flex_Shrink => Set (Flex_Shrink_Value (3.0)), others => <>),
            "flex-shrink");
      Same (Style_Of.Transition ((0.2, Ease_Out, All_Properties)).Build,
            (Transition => Set ((0.2, Ease_Out, All_Properties)),
             others => <>),
            "transition");

      Same (Style_Of.Background_Image (Wallpaper).Build,
            (Background_Image => Set_Bg_Image (Wallpaper), others => <>),
            "background-image");
      Same (Style_Of.Background_Image (Sweep).Build,
            (Background_Image => Set_Bg_Image (Sweep), others => <>),
            "background-image as a gradient");
      Same (Style_Of.Outline_Style (Outline_Dotted).Build,
            (Outline_Style => Set (Outline_Dotted), others => <>),
            "outline-style");
      Same (Style_Of.Font_Family (Loaded_Font).Build,
            (Font_Family => Set (Loaded_Font), others => <>),
            "font-family as a handle");
      Same (Style_Of.Font_Family ("Inter").Build,
            (Font_Family => Set_Font_Family ("Inter"), others => <>),
            "font-family as a name");
      Same (Style_Of.Font_Style (Style_Italic).Build,
            (Font_Style => Set (Style_Italic), others => <>), "font-style");
      Same (Style_Of.Vertical_Align (VA_Middle).Build,
            (Vertical_Align => Set (VA_Middle), others => <>),
            "vertical-align");
      Same (Style_Of.Text_Decoration (Decoration_Underline).Build,
            (Text_Decoration => Set (Decoration_Underline), others => <>),
            "text-decoration");
      Same (Style_Of.List_Style_Type (Square_Marker).Build,
            (List_Style_Type => Set (Square_Marker), others => <>),
            "list-style-type");
      Same (Style_Of.List_Style_Type (Dash_Marker).Build,
            (List_Style_Type => Set (Dash_Marker), others => <>),
            "list-style-type as a custom string");
      Same (Style_Of.List_Style_Image (Bullet).Build,
            (List_Style_Image => Set (Bullet), others => <>),
            "list-style-image");
      Same (Style_Of.List_Style_Position (List_Inside).Build,
            (List_Style_Position => Set (List_Inside), others => <>),
            "list-style-position");
      Same (Style_Of.White_Space (WS_Pre).Build,
            (White_Space => Set (WS_Pre), others => <>), "white-space");
      Same (Style_Of.Text_Overflow (Overflow_Ellipsis).Build,
            (Text_Overflow => Set (Overflow_Ellipsis), others => <>),
            "text-overflow");
      Same (Style_Of.Line_Height (Line_Height (1.5)).Build,
            (Line_Height => Set (Line_Height (1.5)), others => <>),
            "line-height");
      Same (Style_Of.Position_Mode (Absolute).Build,
            (Position => Set (Absolute), others => <>), "position");
      Same (Style_Of.Top (Inset (L)).Build,
            (Top => Set_Top (Inset (L)), others => <>), "top");
      Same (Style_Of.Right (Inset (L)).Build,
            (Right => Set_Right (Inset (L)), others => <>), "right");
      Same (Style_Of.Bottom (Auto_Inset).Build,
            (Bottom => Set_Bottom (Auto_Inset), others => <>), "bottom");
      Same (Style_Of.Left (Inset (L)).Build,
            (Left => Set_Left (Inset (L)), others => <>), "left");
      Same (Style_Of.Visibility (Visibility_Hidden).Build,
            (Visibility => Set (Visibility_Hidden), others => <>),
            "visibility");
      Same (Style_Of.Object_Fit (Fit_Cover).Build,
            (Object_Fit => Set (Fit_Cover), others => <>), "object-fit");
      Same (Style_Of.Object_Position (Object_Position (Pos_Left, Pos_Top))
              .Build,
            (Object_Position => Set (Object_Position (Pos_Left, Pos_Top)),
             others => <>),
            "object-position");
      Same (Style_Of.Flex_Wrap (Wrap).Build,
            (Flex_Wrap => Set (Flex_Wrap_Value'(Wrap)), others => <>),
            "flex-wrap");
      Same (Style_Of.Align_Content (Space_Between).Build,
            (Align_Content => Set (Align_Content_Value'(Space_Between)),
             others => <>),
            "align-content");
      Same (Style_Of.Align_Self (Center).Build,
            (Align_Self => Set (Align_Self_Value'(Center)), others => <>),
            "align-self");
      Same (Style_Of.Flex_Basis (Basis (Px (120.0))).Build,
            (Flex_Basis => Set (Basis (Px (120.0))), others => <>),
            "flex-basis");
      Same (Style_Of.Order (3).Build,
            (Order => Set (Order_Value (3)), others => <>), "order");
      Same (Style_Of.Order (-2).Build,
            (Order => Set (Order_Value (-2)), others => <>),
            "order below zero");
      Same (Style_Of.Grid_Columns (3).Build,
            (Grid_Columns => Set (Grid_Columns_Value (3)), others => <>),
            "grid-template-columns");
      Same (Style_Of.Grid_Rows (2).Build,
            (Grid_Rows => Set (Grid_Rows_Value (2)), others => <>),
            "grid-template-rows");
      Same (Style_Of.Grid_Column (2).Build,
            (Grid_Column => Set (Grid_Column_Value (2)), others => <>),
            "grid-column");
      Same (Style_Of.Grid_Row (4).Build,
            (Grid_Row => Set (Grid_Row_Value (4)), others => <>), "grid-row");
      Same (Style_Of.Grid_Column_Span (3).Build,
            (Grid_Column_Span => Set (Grid_Column_Span_Value (3)),
             others => <>),
            "grid-column span");
      Same (Style_Of.Grid_Row_Span (2).Build,
            (Grid_Row_Span => Set (Grid_Row_Span_Value (2)), others => <>),
            "grid-row span");
   end Test_Every_Setter;

   ---------------------------------------------------------------------
   --  Every clear, one at a time
   ---------------------------------------------------------------------

   --  Clear_Property's branches are label-swappable in a way the type
   --  system cannot see: every Opt_* is a distinct instantiation, so
   --  `when Prop_Top => S.Bottom := Opt_Bottom.Cleared` compiles. The
   --  aggregate side here names the field of Style_Rules directly, so a
   --  branch clearing its neighbour shows.
   procedure Same_Clear (P : CSS_Property; Agg : Style_Rules; Prop : String)
   is
   begin
      Assert (Style_Of.Clear (P).Build = From (Agg).Build,
              "clearing " & Prop & " names the " & Prop & " field");
   end Same_Clear;

   procedure Test_Every_Clear is
   begin
      Section ("each clear against the field it names");

      Same_Clear (Prop_Color,
                  (Color => Opt_Text_Color.Cleared, others => <>),
                  "color");
      Same_Clear (Prop_Background_Color,
                  (Background_Color => No_Bg_Color, others => <>),
                  "background-color");
      Same_Clear (Prop_Background_Image,
                  (Background_Image => No_Bg_Image, others => <>),
                  "background-image");
      Same_Clear (Prop_Border_Radius,
                  (Border_Radius => No_Radius, others => <>),
                  "border-radius");
      Same_Clear (Prop_Border_Width,
                  (Border_Width => No_Border_Width, others => <>),
                  "border-width");
      Same_Clear (Prop_Border_Color,
                  (Border_Color => No_Border_Color, others => <>),
                  "border-color");
      Same_Clear (Prop_Border_Style,
                  (Border_Style => No_Border_Style, others => <>),
                  "border-style");
      Same_Clear (Prop_Outline_Width,
                  (Outline_Width => Opt_Outline_Width.Cleared, others => <>),
                  "outline-width");
      Same_Clear (Prop_Outline_Color,
                  (Outline_Color => Opt_Outline_Color.Cleared, others => <>),
                  "outline-color");
      Same_Clear (Prop_Outline_Style,
                  (Outline_Style => Opt_Outline_Style.Cleared, others => <>),
                  "outline-style");
      Same_Clear (Prop_Outline_Offset,
                  (Outline_Offset => Opt_Outline_Offset.Cleared, others => <>),
                  "outline-offset");
      Same_Clear (Prop_Padding, (Padding => No_Box, others => <>), "padding");
      Same_Clear (Prop_Margin, (Margin => No_Margin, others => <>), "margin");
      Same_Clear (Prop_Width,
                  (Width => Opt_Size.Cleared, others => <>),
                  "width");
      Same_Clear (Prop_Height,
                  (Height => Opt_Size.Cleared, others => <>),
                  "height");
      Same_Clear (Prop_Min_Width,
                  (Min_Width => Opt_Size.Cleared, others => <>),
                  "min-width");
      Same_Clear (Prop_Max_Width,
                  (Max_Width => Opt_Size.Cleared, others => <>),
                  "max-width");
      Same_Clear (Prop_Min_Height,
                  (Min_Height => Opt_Size.Cleared, others => <>),
                  "min-height");
      Same_Clear (Prop_Max_Height,
                  (Max_Height => Opt_Size.Cleared, others => <>),
                  "max-height");
      Same_Clear (Prop_Font_Family,
                  (Font_Family => Opt_Font.Cleared, others => <>),
                  "font-family");
      Same_Clear (Prop_Font_Size,
                  (Font_Size => Opt_Font_Size.Cleared, others => <>),
                  "font-size");
      Same_Clear (Prop_Font_Weight,
                  (Font_Weight => Opt_Font_Weight.Cleared, others => <>),
                  "font-weight");
      Same_Clear (Prop_Font_Style,
                  (Font_Style => Opt_Font_Style.Cleared, others => <>),
                  "font-style");
      Same_Clear (Prop_Text_Align,
                  (Text_Align => Opt_Text_Align.Cleared, others => <>),
                  "text-align");
      Same_Clear (Prop_Vertical_Align,
                  (Vertical_Align => Opt_Vertical_Align.Cleared, others => <>),
                  "vertical-align");
      Same_Clear (Prop_Text_Decoration,
                  (Text_Decoration => Opt_Text_Decoration.Cleared,
                   others => <>),
                  "text-decoration");
      Same_Clear (Prop_List_Style_Type,
                  (List_Style_Type => Opt_List_Style_Type.Cleared,
                   others => <>),
                  "list-style-type");
      Same_Clear (Prop_List_Style_Image,
                  (List_Style_Image => Opt_List_Style_Image.Cleared,
                   others => <>),
                  "list-style-image");
      Same_Clear (Prop_List_Style_Position,
                  (List_Style_Position => Opt_List_Style_Position.Cleared,
                   others => <>),
                  "list-style-position");
      Same_Clear (Prop_White_Space,
                  (White_Space => Opt_White_Space.Cleared, others => <>),
                  "white-space");
      Same_Clear (Prop_Text_Overflow,
                  (Text_Overflow => Opt_Text_Overflow.Cleared, others => <>),
                  "text-overflow");
      Same_Clear (Prop_Text_Wrap_Mode,
                  (Text_Wrap_Mode => Opt_Text_Wrap_Mode.Cleared, others => <>),
                  "text-wrap-mode");
      Same_Clear (Prop_Line_Height,
                  (Line_Height => Opt_Line_Height.Cleared, others => <>),
                  "line-height");
      Same_Clear (Prop_Display,
                  (Display => Opt_Display.Cleared, others => <>),
                  "display");
      Same_Clear (Prop_Position,
                  (Position => Opt_Position.Cleared, others => <>),
                  "position");
      Same_Clear (Prop_Overflow_X,
                  (Overflow_X => Opt_Overflow.Cleared, others => <>),
                  "overflow-x");
      Same_Clear (Prop_Overflow_Y,
                  (Overflow_Y => Opt_Overflow.Cleared, others => <>),
                  "overflow-y");
      Same_Clear (Prop_Overflow,
                  (Overflow_X => Opt_Overflow.Cleared,
                   Overflow_Y => Opt_Overflow.Cleared, others => <>),
                  "overflow");
      Same_Clear (Prop_Visibility,
                  (Visibility => Opt_Visibility.Cleared, others => <>),
                  "visibility");
      Same_Clear (Prop_Top, (Top => Opt_Top.Cleared, others => <>), "top");
      Same_Clear (Prop_Right,
                  (Right => Opt_Right.Cleared, others => <>),
                  "right");
      Same_Clear (Prop_Bottom,
                  (Bottom => Opt_Bottom.Cleared, others => <>),
                  "bottom");
      Same_Clear (Prop_Left, (Left => Opt_Left.Cleared, others => <>), "left");
      Same_Clear (Prop_Opacity,
                  (Opacity => Opt_Opacity.Cleared, others => <>),
                  "opacity");
      Same_Clear (Prop_Cursor,
                  (Cursor => Opt_Cursor.Cleared, others => <>),
                  "cursor");
      Same_Clear (Prop_Box_Shadow,
                  (Box_Shadow => Opt_Box_Shadow.Cleared, others => <>),
                  "box-shadow");
      Same_Clear (Prop_Object_Fit,
                  (Object_Fit => Opt_Object_Fit.Cleared, others => <>),
                  "object-fit");
      Same_Clear (Prop_Object_Position,
                  (Object_Position => Opt_Object_Pos.Cleared, others => <>),
                  "object-position");
      Same_Clear (Prop_Flex_Direction,
                  (Flex_Direction => Opt_Flex_Dir.Cleared, others => <>),
                  "flex-direction");
      Same_Clear (Prop_Flex_Wrap,
                  (Flex_Wrap => Opt_Flex_Wrap.Cleared, others => <>),
                  "flex-wrap");
      Same_Clear (Prop_Justify_Content,
                  (Justify_Content => Opt_Justify.Cleared, others => <>),
                  "justify-content");
      Same_Clear (Prop_Align_Items,
                  (Align_Items => Opt_Align_Items.Cleared, others => <>),
                  "align-items");
      Same_Clear (Prop_Align_Content,
                  (Align_Content => Opt_Align_Content.Cleared, others => <>),
                  "align-content");
      Same_Clear (Prop_Gap, (Gap => Opt_Gap.Cleared, others => <>), "gap");
      Same_Clear (Prop_Grid_Columns,
                  (Grid_Columns => Opt_Grid_Cols.Cleared, others => <>),
                  "grid-columns");
      Same_Clear (Prop_Grid_Rows,
                  (Grid_Rows => Opt_Grid_Rows.Cleared, others => <>),
                  "grid-rows");
      Same_Clear (Prop_Align_Self,
                  (Align_Self => Opt_Align_Self.Cleared, others => <>),
                  "align-self");
      Same_Clear (Prop_Flex_Grow,
                  (Flex_Grow => Opt_Flex_Grow.Cleared, others => <>),
                  "flex-grow");
      Same_Clear (Prop_Flex_Shrink,
                  (Flex_Shrink => Opt_Flex_Shrink.Cleared, others => <>),
                  "flex-shrink");
      Same_Clear (Prop_Flex_Basis,
                  (Flex_Basis => Opt_Flex_Basis.Cleared, others => <>),
                  "flex-basis");
      Same_Clear (Prop_Order,
                  (Order => Opt_Order.Cleared, others => <>),
                  "order");
      Same_Clear (Prop_Grid_Column,
                  (Grid_Column => Opt_Grid_Column.Cleared, others => <>),
                  "grid-column");
      Same_Clear (Prop_Grid_Row,
                  (Grid_Row => Opt_Grid_Row.Cleared, others => <>),
                  "grid-row");
      Same_Clear (Prop_Grid_Column_Span,
                  (Grid_Column_Span => Opt_Grid_Col_Span.Cleared,
                   others => <>),
                  "grid-column span");
      Same_Clear (Prop_Grid_Row_Span,
                  (Grid_Row_Span => Opt_Grid_Row_Span.Cleared, others => <>),
                  "grid-row span");
      Same_Clear (Prop_Transition,
                  (Transition => Opt_Transition.Cleared, others => <>),
                  "transition");
   end Test_Every_Clear;

   ---------------------------------------------------------------------
   --  The overflow shorthand
   ---------------------------------------------------------------------

   --  Prop_Overflow owns no field, so the setter names the two axes it
   --  stands for -- what Adi.CSS_Parser does for the same declaration.
   procedure Test_Overflow_Shorthand is
      Both : constant Widget_Style :=
        Style_Of.Overflow (Overflow_Hidden).Build;
      Axes : constant Widget_Style :=
        Style_Of.Overflow_X (Overflow_Hidden)
                .Overflow_Y (Overflow_Hidden).Build;

      Seeded : constant Widget_Style :=
        From ((Overflow_X => Set (Overflow_Scroll),
               Overflow_Y => Set (Overflow_Scroll),
               others     => <>)).Build;
      Wiped  : constant Widget_Style :=
        Style_Of (Seeded).Clear (Prop_Overflow).Build;

      Nearly : constant Natural := Max_Chain_Slots - 1;
      Before : Natural;
      Chain  : Composer;
   begin
      Section ("the shorthand that stands for two axes");

      Assert (Both = Axes,
              "one step naming the shorthand moves both axes");
      Assert (Both = From ((Overflow_X => Set (Overflow_Hidden),
                            Overflow_Y => Set (Overflow_Hidden),
                            others     => <>)).Build,
              "and interns to the aggregate naming both");

      Assert (Wiped = From ((Overflow_X => Opt_Overflow.Cleared,
                             Overflow_Y => Opt_Overflow.Cleared,
                             others     => <>)).Build,
              "clearing the shorthand clears both axes");

      --  One slot, so a buffer either carries the whole shorthand or
      --  drops the whole of it -- there is no state between.
      Before := Dropped_Chain_Slots;
      Chain := Style_Of;
      for I in 1 .. Nearly loop
         Chain := Chain.Flex_Grow (Flex_Grow_Value (Float (I)));
      end loop;

      Assert (Chain.Overflow (Overflow_Hidden).Build
                = From ((Flex_Grow  => Set (Flex_Grow_Value (Float (Nearly))),
                         Overflow_X => Set (Overflow_Hidden),
                         Overflow_Y => Set (Overflow_Hidden),
                         others     => <>)).Build,
              "the last free slot carries the shorthand whole");
      Assert (Dropped_Chain_Slots = Before, "and drops nothing");

      Before := Dropped_Chain_Slots;
      Chain := Style_Of;
      for I in 1 .. Max_Chain_Slots loop
         Chain := Chain.Flex_Grow (Flex_Grow_Value (Float (I)));
      end loop;

      Assert (Chain.Overflow (Overflow_Hidden).Build
                = From ((Flex_Grow =>
                           Set (Flex_Grow_Value (Float (Max_Chain_Slots))),
                         others    => <>)).Build,
              "a full buffer drops it whole, never one axis of it");
      Assert (Dropped_Chain_Slots = Before + 1,
              "counted as the one step it is");
      Assert (Open_Chains = 0, "every chain here returned its buffer");
   end Test_Overflow_Shorthand;

   ---------------------------------------------------------------------
   --  The gap axes
   ---------------------------------------------------------------------

   --  What a chain answers for the main part with no state active.
   function Base_Of (S : Widget_Style) return Style_Rules is
     (Rules_Of (Definition (S).Base));

   procedure Test_Gap_Axes is
      Both : constant Widget_Style :=
        Style_Of.Gap (Gap_Row (Px (4.0))).Gap (Gap_Column (Px (8.0))).Build;
      Then_Uniform : constant Widget_Style :=
        Style_Of.Gap (Gap_Row (Px (4.0))).Gap (Gap (Px (8.0))).Build;

      G : constant Gap_Value := Opt_Gap.Resolve (Base_Of (Both).Gap);
      U : constant Gap_Value := Opt_Gap.Resolve (Base_Of (Then_Uniform).Gap);
   begin
      Section ("one field, two axes");

      Assert (G.Kind = Gap_Separate, "two longhands leave the axes apart");
      if G.Kind = Gap_Separate then
         Assert (G.Row_Gap = Px (4.0) and then G.Has_Row,
                 "the row gap named first survives the column gap");
         Assert (G.Column_Gap = Px (8.0) and then G.Has_Column,
                 "and the column gap is the one named second");
      end if;

      Assert (U.Kind = Gap_Uniform and then U.All_Gap = Px (8.0),
              "a value naming both axes replaces one naming a single axis");
   end Test_Gap_Axes;

   ---------------------------------------------------------------------
   --  Text at the limit a style carries
   ---------------------------------------------------------------------

   --  Adi.CSS_Parser drops a declaration whose text passes
   --  Max_CSS_Text_Length, leaving the property unset so the cascade
   --  shows through. The chain and the aggregate answer the same, which
   --  is what the four text-carrying properties are checked for here at
   --  the exact boundary.
   procedure Test_Text_Limit is
      Fits : constant String (1 .. Max_CSS_Text_Length) := [others => 'a'];
      Over : constant String (1 .. Max_CSS_Text_Length + 1) := [others => 'a'];

      Half : constant Opt_Opacity.Optional := Set (Opacity_Value (0.5));

      --  A second declaration, so the rule block stands whether or not
      --  the text one survives.
      Only_Opacity : constant Style_Rules := (Opacity => Half, others => <>);

      function Sheet_Rules (Decl : String) return Style_Rules is
         Source : constant String :=
           ".x { opacity: 0.5; " & Decl & " }" & ASCII.LF;
         Sheet  : Adi.CSS_Parser.Rule_Sheet;
         Loaded : Boolean;
      begin
         Adi.CSS_Parser.Load_Rules (Sheet, Source, Loaded);
         Assert (Loaded, "the sheet parses");
         return Adi.CSS_Parser.Base_Rules
                  (Sheet, Adi.CSS_Parser.Class_Selector, "x");
      end Sheet_Rules;

      procedure Three_Ways (Chain : Widget_Style;
                            Agg   : Style_Rules;
                            Decl  : String;
                            What  : String) is
      begin
         Assert (Chain = From (Agg).Build,
                 What & ": the chain and the aggregate agree");
         Assert (Intern_Rules (Sheet_Rules (Decl)) = Intern_Rules (Agg),
                 What & ": and a parsed sheet agrees with both");
      end Three_Ways;
   begin
      Section ("text at and past what a style value carries");

      Three_Ways
        (Style_Of.Opacity (0.5).Font_Family (Fits).Build,
         (Opacity => Half, Font_Family => Set_Font_Family (Fits),
          others => <>),
         "font-family: " & Fits & ";",
         "font-family at the limit");
      Three_Ways
        (Style_Of.Opacity (0.5).Font_Family (Over).Build,
         Only_Opacity,
         "font-family: " & Over & ";",
         "font-family past the limit");

      Three_Ways
        (Style_Of.Opacity (0.5).Background_Image (Fits).Build,
         (Opacity => Half, Background_Image => Set_Bg_Image (Fits),
          others => <>),
         "background-image: url(""" & Fits & """);",
         "background-image at the limit");
      Three_Ways
        (Style_Of.Opacity (0.5).Background_Image (Over).Build,
         Only_Opacity,
         "background-image: url(""" & Over & """);",
         "background-image past the limit");

      Three_Ways
        (Style_Of.Opacity (0.5).List_Style_Image (Fits).Build,
         (Opacity => Half, List_Style_Image => Set_List_Image (Fits),
          others => <>),
         "list-style-image: url(""" & Fits & """);",
         "list-style-image at the limit");
      Three_Ways
        (Style_Of.Opacity (0.5).List_Style_Image (Over).Build,
         Only_Opacity,
         "list-style-image: url(""" & Over & """);",
         "list-style-image past the limit");

      Three_Ways
        (Style_Of.Opacity (0.5).List_Style_Type (Fits).Build,
         (Opacity => Half, List_Style_Type => Set_List_Type (Fits),
          others => <>),
         "list-style-type: """ & Fits & """;",
         "list-style-type at the limit");
      Three_Ways
        (Style_Of.Opacity (0.5).List_Style_Type (Over).Build,
         Only_Opacity,
         "list-style-type: """ & Over & """;",
         "list-style-type past the limit");

      Assert (Style_Of.Background_Image ("").Build = Empty_Widget_Style,
              "an empty URL names nothing, as an empty url() does");
   end Test_Text_Limit;

   ---------------------------------------------------------------------
   --  Against the runtime parser
   ---------------------------------------------------------------------

   --  The standing rule in this repository: the two pipelines resolve
   --  the same CSS the same way. Here one side is a chain and the other
   --  is Adi.CSS_Parser reading the declarations the chain names.
   procedure Test_Agrees_With_Parser is
      Source : constant String :=
        ".c {" & ASCII.LF
        & "  color: #ffffff;" & ASCII.LF
        & "  background-color: #2563eb;" & ASCII.LF
        & "  font-size: 14px;" & ASCII.LF
        & "  display: flex;" & ASCII.LF
        & "  flex-grow: 1;" & ASCII.LF
        & "  row-gap: 4px;" & ASCII.LF
        & "  column-gap: 8px;" & ASCII.LF
        & "}" & ASCII.LF;

      Sheet   : Adi.CSS_Parser.Rule_Sheet;
      Loaded  : Boolean;

      By_Chain : constant Widget_Style :=
        Style_Of
          .Text_Color (RGB (255, 255, 255))
          .Background (RGB (37, 99, 235))
          .Font_Size (Px (14.0))
          .Display (Flex)
          .Flex_Grow (1.0)
          .Gap (Gap_Row (Px (4.0)))
          .Gap (Gap_Column (Px (8.0)))
        .Build;
   begin
      Section ("a chain against the sheet it spells");

      Adi.CSS_Parser.Load_Rules (Sheet, Source, Loaded);
      Assert (Loaded, "the sheet parses");

      Assert (Intern_Rules
                (Adi.CSS_Parser.Base_Rules
                   (Sheet, Adi.CSS_Parser.Class_Selector, "c"))
              = Definition (By_Chain).Base,
              "the parser and the chain fold the same declarations to "
              & "one interned rule set");
   end Test_Agrees_With_Parser;

   --  The same claim over the properties the composer reaches through a
   --  store rather than through a reference, and over the two the
   --  parser expands: `overflow` to its axes and `grid-column` to a
   --  line and a span.
   procedure Test_Agrees_With_Parser_Widely is
      Source : constant String :=
        ".w {" & ASCII.LF
        & "  position: absolute;" & ASCII.LF
        & "  top: 4px;" & ASCII.LF
        & "  left: auto;" & ASCII.LF
        & "  visibility: hidden;" & ASCII.LF
        & "  overflow: hidden;" & ASCII.LF
        & "  font-family: Inter;" & ASCII.LF
        & "  font-style: italic;" & ASCII.LF
        & "  line-height: 1.5;" & ASCII.LF
        & "  white-space: pre;" & ASCII.LF
        & "  text-decoration: underline;" & ASCII.LF
        & "  vertical-align: middle;" & ASCII.LF
        & "  text-overflow: ellipsis;" & ASCII.LF
        & "  outline-style: dotted;" & ASCII.LF
        & "  list-style-type: square;" & ASCII.LF
        & "  list-style-image: url(""images/bullet.png"");" & ASCII.LF
        & "  list-style-position: inside;" & ASCII.LF
        & "  background-image: url(""images/paper.png"");" & ASCII.LF
        & "  object-fit: cover;" & ASCII.LF
        & "  flex-wrap: wrap;" & ASCII.LF
        & "  align-self: center;" & ASCII.LF
        & "  align-content: space-between;" & ASCII.LF
        & "  flex-basis: 120px;" & ASCII.LF
        & "  order: -2;" & ASCII.LF
        & "  grid-template-rows: 40px 40px;" & ASCII.LF
        & "  grid-column: 2 / span 3;" & ASCII.LF
        & "}" & ASCII.LF;

      Sheet  : Adi.CSS_Parser.Rule_Sheet;
      Loaded : Boolean;

      By_Chain : constant Widget_Style :=
        Style_Of
          .Position_Mode (Absolute)
          .Top (Inset (Px (4.0)))
          .Left (Auto_Inset)
          .Visibility (Visibility_Hidden)
          .Overflow (Overflow_Hidden)
          .Font_Family ("Inter")
          .Font_Style (Style_Italic)
          .Line_Height (Line_Height (1.5))
          .White_Space (WS_Pre)
          .Text_Decoration (Decoration_Underline)
          .Vertical_Align (VA_Middle)
          .Text_Overflow (Overflow_Ellipsis)
          .Outline_Style (Outline_Dotted)
          .List_Style_Type (Square_Marker)
          .List_Style_Image (Bullet)
          .List_Style_Position (List_Inside)
          .Background_Image (Wallpaper)
          .Object_Fit (Fit_Cover)
          .Flex_Wrap (Wrap)
          .Align_Self (Center)
          .Align_Content (Space_Between)
          .Flex_Basis (Basis (Px (120.0)))
          .Order (-2)
          .Grid_Rows (2)
          .Grid_Column (2)
          .Grid_Column_Span (3)
        .Build;
   begin
      Section ("a chain against the wider sheet it spells");

      Adi.CSS_Parser.Load_Rules (Sheet, Source, Loaded);
      Assert (Loaded, "the sheet parses");

      Assert (Intern_Rules
                (Adi.CSS_Parser.Base_Rules
                   (Sheet, Adi.CSS_Parser.Class_Selector, "w"))
              = Definition (By_Chain).Base,
              "the parser and the chain fold the same twenty-six "
              & "declarations to one interned rule set");
   end Test_Agrees_With_Parser_Widely;

   ---------------------------------------------------------------------
   --  Deriving
   ---------------------------------------------------------------------

   Primary : constant Widget_Style :=
     Style_Of
       .Background (Blue)
       .Padding (Pad)
     .On_Hover
       .Background (Deep)
     .Build;

   procedure Test_Derived is
      Derived : constant Widget_Style :=
        Style_Of (Primary).Background (Danger).Build;

      Expected : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Danger),
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             others           => <>))
          .Build;
   begin
      Section ("a chain that opens on an existing style");

      Assert (Derived = Expected,
              "the base's other properties stand, the named one changes, "
              & "and the state rule comes through");
      Assert (Derived /= Primary, "and the derived style is a second one");
   end Test_Derived;

   procedure Test_Derived_State_Rule is
      Derived : constant Widget_Style :=
        Style_Of (Primary).On_Hover.Text_Color (C (White)).Build;

      Expected : constant Widget_Style :=
        From ((Background_Color => Set_Bg (Blue),
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             Color            => Set (C (White)),
                             others           => <>))
          .Build;
   begin
      Section ("a derived chain reaching a rule the base already carries");

      Assert (Derived = Expected,
              "the hover rule takes the override rather than a rule of "
              & "its own");
   end Test_Derived_State_Rule;

   procedure Test_Clear is
      Cleared : constant Widget_Style :=
        Style_Of (Primary).Clear (Prop_Background_Color).Build;

      Expected : constant Widget_Style :=
        From ((Background_Color => No_Bg_Color,
               Padding          => Set (Pad),
               others           => <>))
          .On (Sel_Hovered, (Background_Color => Set_Bg (Deep),
                             others           => <>))
          .Build;
   begin
      Section ("clearing a property the base set");

      Assert (Cleared = Expected,
              ".Clear interns to the aggregate that names the property "
              & "cleared");
      Assert (Cleared /= Style_Of (Primary).Build,
              "and a cleared property is not an unset one");
   end Test_Clear;

   ---------------------------------------------------------------------
   --  What a repeat build costs
   ---------------------------------------------------------------------

   procedure Test_Repeat_Build_Interns_Nothing is
      Values : constant Natural := Interned_Values;
      Rules  : constant Natural := Interned_Rule_Sets;
      Styles : constant Natural := Interned_Styles;

      Again : constant Widget_Style :=
        Style_Of
          .Background (Blue)
          .Padding (Pad)
        .On_Hover
          .Background (Deep)
        .Build;
   begin
      Section ("a chain built a second time");

      Assert (Again = Primary, "answers the handle the first build did");
      Assert (Interned_Values = Values, "and interns no further value");
      Assert (Interned_Rule_Sets = Rules, "no further rule set");
      Assert (Interned_Styles = Styles, "and no further style");
   end Test_Repeat_Build_Interns_Nothing;

   ---------------------------------------------------------------------
   --  Degrading
   ---------------------------------------------------------------------

   procedure Test_Is_Live is
      Open_One : Composer := Style_Of;
      Built    : constant Composer := Style_Of;
      Unused   : Widget_Style;
   begin
      Section ("whether a chain still holds its buffer");

      Assert (Is_Live (Open_One), "a chain the pool granted holds one");

      Unused := Built.Background (Blue).Build;
      Assert (not Is_Live (Built), ".Build returns it");
      Assert (Unused /= Empty_Widget_Style, "and builds what it named");

      Open_One.Discard;
      Assert (not Is_Live (Open_One), ".Discard returns it too");
      Assert (Open_Chains = 0, "and the pool is empty again");
   end Test_Is_Live;

   procedure Test_Reclaim_Is_Visible is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Extra  : Composer;
      Before : constant Natural := Reclaimed_Chains;
      Answer : Widget_Style;
   begin
      Section ("a chain can see that its buffer was taken back");

      Held (1) := Style_Of (Primary);
      for I in 2 .. Held'Last loop
         Held (I) := Style_Of;
      end loop;
      Assert (Is_Live (Held (1)), "the oldest chain holds a buffer");

      Extra := Style_Of;
      Assert (Reclaimed_Chains = Before + 1, "opening on a full pool reclaims");
      Assert (not Is_Live (Held (1)),
              "and the chain it took the buffer from can see it is gone");
      Assert (Is_Live (Extra), "while the chain that took it holds one");

      --  The answer is plausible rather than wrong, which is why the
      --  predicate above and the report at .Build both exist.
      Answer := Held (1).Background (Danger).Build;
      Assert (Answer = Primary,
              "its .Build answers the style it opened on");

      Extra.Discard;
      for I in 2 .. Held'Last loop
         Held (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and every buffer comes back");
   end Test_Reclaim_Is_Visible;

   --  Discarding a chain whose buffer was already taken back must leave
   --  the ledger entry of whoever holds that buffer now alone. If it
   --  did not, the new holder would stop being orderable and would
   --  never be chosen as the oldest.
   procedure Test_Discard_After_Reclaim_Leaves_The_Ledger is
      First  : array (1 .. Max_Open_Chains) of Composer;
      Fresh  : array (1 .. Max_Open_Chains - 1) of Composer;
      Taker  : Composer;
      Last   : Composer;
   begin
      Section ("discarding a chain whose buffer moved on");

      for I in First'Range loop
         First (I) := Style_Of;
      end loop;

      Taker := Style_Of;
      Assert (not Is_Live (First (1)), "the oldest lost its buffer");

      --  The discard that must not touch Taker's ledger entry.
      First (1).Discard;
      for I in 2 .. First'Last loop
         First (I).Discard;
      end loop;
      Assert (Open_Chains = 1, "only the taker is left holding one");

      --  Taker is now the oldest of a full pool, so it is what the next
      --  chain must take back.
      for I in Fresh'Range loop
         Fresh (I) := Style_Of;
      end loop;
      Assert (Open_Chains = Max_Open_Chains, "the pool is full again");

      Last := Style_Of;
      Assert (not Is_Live (Taker),
              "the taker is still orderable, and is the oldest");
      for I in Fresh'Range loop
         Assert (Is_Live (Fresh (I)), "and no younger buffer was taken");
      end loop;

      Last.Discard;
      Taker.Discard;
      for I in Fresh'Range loop
         Fresh (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and every buffer comes back");
   end Test_Discard_After_Reclaim_Leaves_The_Ledger;

   procedure Test_Cascading_Reclaims is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Before : constant Natural := Reclaimed_Chains;
      Rounds : constant := 5;
   begin
      Section ("reclaiming again and again");

      for I in Held'Range loop
         Held (I) := Style_Of;
      end loop;

      --  Each of these finds the pool full, takes the oldest buffer and
      --  keeps it, so the pool stays exactly full throughout and the
      --  count rises by exactly one a time.
      for Round in 1 .. Rounds loop
         declare
            Taker : Composer := Style_Of;
         begin
            Assert (Reclaimed_Chains = Before + Round,
                    "each reclaim is counted once");
            Assert (Open_Chains = Max_Open_Chains,
                    "and the pool stays exactly full");
            Assert (Is_Live (Taker), "the taker holds the buffer");
            Taker.Discard;
            Assert (Open_Chains = Max_Open_Chains - 1,
                    "discarding it frees exactly one");
            Held (Round) := Style_Of;
         end;
      end loop;

      for I in Held'Range loop
         Held (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and nothing is left held");
   end Test_Cascading_Reclaims;

   procedure Test_Clock_Survives_Churn is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Before : constant Natural := Reclaimed_Chains;
      Unused : Widget_Style;
   begin
      Section ("ordering after the pool has emptied many times");

      --  Every one of these empties the pool, which is what resets the
      --  clock that orders the held buffers.
      for I in 1 .. 200 loop
         Unused := Style_Of.Flex_Grow (Flex_Grow_Value (Float (I mod 8)))
                     .Build;
      end loop;
      Assert (Open_Chains = 0, "the churn leaves nothing held");
      Assert (Reclaimed_Chains = Before,
              "and never had to reclaim, the pool never being full");

      --  The oldest is still the oldest after all that.
      for I in Held'Range loop
         Held (I) := Style_Of;
      end loop;
      declare
         Taker : Composer := Style_Of;
      begin
         Assert (not Is_Live (Held (1)),
                 "the buffer taken back is the one held longest");
         for I in 2 .. Held'Last loop
            Assert (Is_Live (Held (I)), "and no other is disturbed");
         end loop;
         Taker.Discard;
      end;

      for I in Held'Range loop
         Held (I).Discard;
      end loop;
      Assert (Open_Chains = 0, "and every buffer comes back");
      Assert (Unused /= Empty_Widget_Style, "the churn built real styles");
   end Test_Clock_Survives_Churn;

   procedure Test_Full_Pool_Reclaims is
      Held   : array (1 .. Max_Open_Chains) of Composer;
      Extra  : Composer;
      Before : constant Natural := Reclaimed_Chains;
   begin
      Section ("a pool with every chain buffer held");

      Assert (Open_Chains = 0, "the pool starts with nothing open");

      --  The first is the oldest, and opens on a style, so what it
      --  answers once reclaimed says what a reclaim costs a caller.
      Held (1) := Style_Of (Primary);
      for I in 2 .. Held'Last loop
         Held (I) := Style_Of;
      end loop;
      Assert (Open_Chains = Max_Open_Chains, "every buffer is held");

      Extra := Style_Of;
      Assert (Reclaimed_Chains = Before + 1,
              "a chain opening on a full pool takes the oldest buffer back");
      Assert (Open_Chains = Max_Open_Chains,
              "and holds that one rather than adding a ninth");

      Assert (Held (1).Background (Danger).Build = Primary,
              "the reclaimed chain answers the style it opened on, with "
              & "the override it named not applied");

      Assert (Extra.Background (Blue).Build
                = From ((Background_Color => Set_Bg (Blue),
                         others           => <>)).Build,
              "and the chain that took the buffer builds normally");

      for I in 2 .. Held'Last loop
         Held (I).Discard;
      end loop;
      Held (1).Discard;
      Assert (Open_Chains = 0,
              "discarding returns every buffer, and discarding a "
              & "reclaimed chain takes none from its new holder");
   end Test_Full_Pool_Reclaims;

   procedure Test_Full_Buffer is
      Before : constant Natural := Dropped_Chain_Slots;
      Full   : Composer := Style_Of;
      Built  : Widget_Style;

      Expected : constant Widget_Style :=
        From ((Flex_Grow => Set (Flex_Grow_Value (Float (Max_Chain_Slots))),
               others    => <>)).Build;
   begin
      Section ("a chain longer than its buffer");

      for I in 1 .. Max_Chain_Slots loop
         Full := Full.Flex_Grow (Flex_Grow_Value (Float (I)));
      end loop;
      Assert (Dropped_Chain_Slots = Before,
              "a chain filling the buffer exactly drops nothing");

      Full := Full.Background (Blue);
      Assert (Dropped_Chain_Slots = Before + 1,
              "the step past the buffer is dropped and counted");

      Full := Full.Text_Color (C (White));
      Assert (Dropped_Chain_Slots = Before + 2,
              "and so is the next");

      Built := Full.Build;
      Assert (Built = Expected,
              "what fits is what the style carries, and the chain builds "
              & "rather than raising");
      Assert (Open_Chains = 0, "and the buffer comes back");
   end Test_Full_Buffer;

   ---------------------------------------------------------------------
   --  What stays outside the composed set, and what being inside means
   ---------------------------------------------------------------------

   --  A value of the right type for each property, so the loop below
   --  can drive Apply_Property over the whole enumeration. The case has
   --  no `others`, so a CSS_Property added past this stops the test
   --  compiling until it is sampled.
   function Sample_Ref (P : CSS_Property) return Value_Ref is
     (case P is
        when Prop_Color | Prop_Background_Color | Prop_Outline_Color =>
          Intern (C (Red)),
        when Prop_Outline_Width | Prop_Outline_Offset | Prop_Font_Size =>
          Intern (Px (7.0)),
        when Prop_Width | Prop_Height | Prop_Min_Width | Prop_Max_Width
           | Prop_Min_Height | Prop_Max_Height =>
          Intern (Size (Px (120.0))),
        when Prop_Padding | Prop_Margin        => Intern (Pad),
        when Prop_Border_Radius                => Intern (Round),
        when Prop_Border_Width  => Intern (Border_Width (Px (1.0))),
        when Prop_Border_Color  => Intern (Border_Color (C (Lime))),
        when Prop_Border_Style  => Intern (Border_Style (Dashed)),
        when Prop_Gap           => Intern (Gap (Px (8.0))),
        when Prop_Box_Shadow    => Intern (Drop),
        when Prop_Transition    =>
          Intern (Transition_Spec'(0.2, Ease_Out, All_Properties)),
        when Prop_Opacity       => Intern (Opacity_Value (0.5)),
        when Prop_Flex_Grow     => Intern (Flex_Grow_Value (2.0)),
        when Prop_Flex_Shrink   => Intern (Flex_Shrink_Value (3.0)),
        when Prop_Display       => Intern (Flex),
        when Prop_Overflow_X | Prop_Overflow_Y => Intern (Overflow_Scroll),
        when Prop_Cursor        => Intern (Cursor_Pointer),
        when Prop_Text_Align    => Intern (Text_Center),
        when Prop_Text_Wrap_Mode => Intern (TWM_Nowrap),
        when Prop_Font_Weight   => Intern (Weight_Bold),
        when Prop_Flex_Direction  => Intern (Flex_Direction_Value'(Column)),
        when Prop_Justify_Content =>
          Intern (Justify_Content_Value'(Space_Between)),
        when Prop_Align_Items   => Intern (Align_Items_Value'(Baseline)),
        when Prop_Align_Self    => Intern (Align_Self_Value'(Center)),
        when Prop_Align_Content =>
          Intern (Align_Content_Value'(Space_Between)),
        when Prop_Flex_Wrap     => Intern (Flex_Wrap_Value'(Wrap)),
        when Prop_Position      => Intern (Position_Value'(Absolute)),
        when Prop_Visibility    => Intern (Visibility_Hidden),
        when Prop_Outline_Style => Intern (Outline_Dotted),
        when Prop_Font_Style    => Intern (Style_Italic),
        when Prop_Vertical_Align  => Intern (VA_Middle),
        when Prop_Text_Decoration => Intern (Decoration_Underline),
        when Prop_List_Style_Position => Intern (List_Inside),
        when Prop_White_Space   => Intern (WS_Pre),
        when Prop_Text_Overflow => Intern (Overflow_Ellipsis),
        when Prop_Object_Fit    => Intern (Fit_Cover),
        when Prop_Object_Position =>
          Intern (Object_Position (Pos_Left, Pos_Top)),
        when Prop_Line_Height   => Intern (Line_Height (1.5)),
        when Prop_Flex_Basis    => Intern (Basis (Px (120.0))),
        when Prop_Top | Prop_Right | Prop_Bottom | Prop_Left =>
          Intern (Inset (Px (4.0))),
        when Prop_Background_Image => Intern (Wallpaper),
        when Prop_Font_Family =>
          Intern (Font_Family_Value'(Kind => By_Handle,
                                     Handle => Loaded_Font)),
        when Prop_List_Style_Type  => Intern (Square_Marker),
        when Prop_List_Style_Image => Intern (Bullet),
        when Prop_Order            => Intern (Order_Value (3)),
        when Prop_Grid_Columns     => Intern (Grid_Columns_Value (3)),
        when Prop_Grid_Rows        => Intern (Grid_Rows_Value (2)),
        when Prop_Grid_Column      => Intern (Grid_Column_Value (2)),
        when Prop_Grid_Row         => Intern (Grid_Row_Value (4)),
        when Prop_Grid_Column_Span => Intern (Grid_Column_Span_Value (3)),
        when Prop_Grid_Row_Span    => Intern (Grid_Row_Span_Value (2)),
        when Prop_Overflow         => Intern (Overflow_Hidden));

   --  The fields a property names. Every property names itself, and
   --  the shorthand names its two axes -- which is what makes it
   --  composable without a field of its own.
   function Names_Of (P : CSS_Property) return CSS_Property_Set is
     (if P = Prop_Overflow
      then [for Q in CSS_Property =>
              Q in Prop_Overflow_X | Prop_Overflow_Y]
      else [for Q in CSS_Property => Q = P]);

   --  Membership alone would be satisfied by a branch that did nothing,
   --  since the set is `others => True`, so each property is driven
   --  through both procedures: applying a value of its own type must
   --  name its fields, clearing must name them, and the two must
   --  differ. That is what makes the default safe rather than merely
   --  convenient.
   --
   --  The residue is Grid_Column_Tracks alone, which no chain can name
   --  because it has no CSS_Property literal: giving it one is the
   --  descriptor table's business.
   procedure Test_Residue is
      Composable : Natural := 0;
      Applied, Wiped : Style_Rules;
   begin
      Section ("what being in the composed set means");

      for P in CSS_Property loop
         Assert (Composable_Properties (P),
                 CSS_Property'Image (P) & " composes");
         Composable := Composable + 1;

         Applied := Empty_Style;
         Apply_Property (Applied, P, Sample_Ref (P));
         Assert (Applied /= Empty_Style
                   and then (for all Q in CSS_Property =>
                               (if Names_Of (P) (Q)
                                then Set_Properties (Applied) (Q))),
                 "Apply_Property writes the fields "
                 & CSS_Property'Image (P) & " names");

         Wiped := Empty_Style;
         Clear_Property (Wiped, P);
         Assert (Wiped /= Empty_Style
                   and then (for all Q in CSS_Property =>
                               (if Names_Of (P) (Q)
                                then Set_Properties (Wiped) (Q))),
                 "Clear_Property names the same fields for "
                 & CSS_Property'Image (P));

         Assert (Applied /= Wiped,
                 "and set is not cleared for " & CSS_Property'Image (P));
      end loop;

      Assert (Composable = 66,
              "all sixty-six properties compose, not"
              & Composable'Image);

      Assert (Rules_Of (Definition (Style_Of.Grid_Columns (3).Build).Base)
                .Grid_Column_Tracks.Count = 0,
              "and the track list stays outside, having no property to be "
              & "named by");
   end Test_Residue;

   procedure Test_Chain_Leaves_No_Buffer is
   begin
      Section ("what the suite leaves behind");

      Assert (Open_Chains = 0,
              "every chain built or discarded above returned its buffer");
   end Test_Chain_Leaves_No_Buffer;

begin
   Start_Suite ("Style Composer Test");

   Test_Widths;
   Test_Value_Refs;
   Test_One_Property;
   Test_Several_Properties;
   Test_Several_Rules;
   Test_Every_Setter;
   Test_Every_Clear;
   Test_Gap_Axes;
   Test_Overflow_Shorthand;
   Test_Text_Limit;
   Test_Agrees_With_Parser;
   Test_Agrees_With_Parser_Widely;
   Test_Rule_Reuse;
   Test_Empty_Chain;
   Test_Derived;
   Test_Derived_State_Rule;
   Test_Clear;
   Test_Repeat_Build_Interns_Nothing;
   Test_Is_Live;
   Test_Full_Pool_Reclaims;
   Test_Reclaim_Is_Visible;
   Test_Discard_After_Reclaim_Leaves_The_Ledger;
   Test_Cascading_Reclaims;
   Test_Clock_Survives_Churn;
   Test_Full_Buffer;
   Test_Residue;
   Test_Chain_Leaves_No_Buffer;

   Finish;
end Style_Composer_Test;
