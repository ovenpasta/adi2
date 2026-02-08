package body Adi.Widget.Part_Styles is

   ---------------------------------------------------------------------------
   --  Builder Creation
   ---------------------------------------------------------------------------

   function Create return Part_Style_Builder is
   begin
      return (Styles        => Empty_Part_Styles,
              Configured    => [others => False],
              Default_Set   => False,
              Default_Style => Empty_Widget_Style);
   end Create;

   ---------------------------------------------------------------------------
   --  Part Configuration
   ---------------------------------------------------------------------------

   function With_Part (B : Part_Style_Builder;
                       P : Part_Kind;
                       S : Widget_Style) return Part_Style_Builder is
      Result : Part_Style_Builder := B;
   begin
      Result.Styles (P) := (Style => S, Enabled => True);
      Result.Configured (P) := True;
      return Result;
   end With_Part;

   function With_Part (B : Part_Style_Builder;
                       P : Part_Kind;
                       S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, P, Build (S));
   end With_Part;

   ---------------------------------------------------------------------------
   --  Shorthand Methods - Widget_Style variants
   ---------------------------------------------------------------------------

   function With_Main (B : Part_Style_Builder;
                       S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Main_Part, S);
   end With_Main;

   function With_Label (B : Part_Style_Builder;
                        S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Label_Part, S);
   end With_Label;

   function With_Icon (B : Part_Style_Builder;
                       S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Icon_Part, S);
   end With_Icon;

   function With_Indicator (B : Part_Style_Builder;
                            S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Indicator_Part, S);
   end With_Indicator;

   function With_Knob (B : Part_Style_Builder;
                       S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Knob_Part, S);
   end With_Knob;

   function With_Scroll (B : Part_Style_Builder;
                         S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Scroll_Part, S);
   end With_Scroll;

   function With_Cursor (B : Part_Style_Builder;
                         S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Cursor_Part, S);
   end With_Cursor;

   function With_Selected (B : Part_Style_Builder;
                           S : Widget_Style) return Part_Style_Builder is
   begin
      return With_Part (B, Selected_Part, S);
   end With_Selected;

   ---------------------------------------------------------------------------
   --  Shorthand Methods - Style_Builder variants
   ---------------------------------------------------------------------------

   function With_Main (B : Part_Style_Builder;
                       S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Main_Part, Build (S));
   end With_Main;

   function With_Label (B : Part_Style_Builder;
                        S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Label_Part, Build (S));
   end With_Label;

   function With_Icon (B : Part_Style_Builder;
                       S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Icon_Part, Build (S));
   end With_Icon;

   function With_Indicator (B : Part_Style_Builder;
                            S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Indicator_Part, Build (S));
   end With_Indicator;

   function With_Knob (B : Part_Style_Builder;
                       S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Knob_Part, Build (S));
   end With_Knob;

   function With_Scroll (B : Part_Style_Builder;
                         S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Scroll_Part, Build (S));
   end With_Scroll;

   function With_Cursor (B : Part_Style_Builder;
                         S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Cursor_Part, Build (S));
   end With_Cursor;

   function With_Selected (B : Part_Style_Builder;
                           S : Style_Builder'Class) return Part_Style_Builder is
   begin
      return With_Part (B, Selected_Part, Build (S));
   end With_Selected;

   ---------------------------------------------------------------------------
   --  Enable/Disable Parts
   ---------------------------------------------------------------------------

   function Disable_Part (B : Part_Style_Builder;
                          P : Part_Kind) return Part_Style_Builder is
      Result : Part_Style_Builder := B;
   begin
      Result.Styles (P).Enabled := False;
      return Result;
   end Disable_Part;

   function Enable_Part (B : Part_Style_Builder;
                         P : Part_Kind) return Part_Style_Builder is
      Result : Part_Style_Builder := B;
   begin
      Result.Styles (P).Enabled := True;
      return Result;
   end Enable_Part;

   ---------------------------------------------------------------------------
   --  Default Style
   ---------------------------------------------------------------------------

   function With_Default (B : Part_Style_Builder;
                          S : Widget_Style) return Part_Style_Builder is
      Result : Part_Style_Builder := B;
   begin
      Result.Default_Set := True;
      Result.Default_Style := S;
      return Result;
   end With_Default;

   ---------------------------------------------------------------------------
   --  Build and Apply
   ---------------------------------------------------------------------------

   function Build (B : Part_Style_Builder) return Part_Style_Array is
      Result : Part_Style_Array := B.Styles;
   begin
      --  Apply default style to unconfigured parts if set
      if B.Default_Set then
         for P in Part_Kind loop
            if not B.Configured (P) then
               Result (P) := (Style => B.Default_Style, Enabled => True);
            end if;
         end loop;
      end if;

      return Result;
   end Build;

   procedure Apply_To (B : Part_Style_Builder; W : in out Widget'Class) is
   begin
      Set_Part_Styles (W, Build (B));
   end Apply_To;

   ---------------------------------------------------------------------------
   --  Predefined Templates
   ---------------------------------------------------------------------------

   function Button_Template return Part_Style_Builder is
   begin
      return Create
        .Enable_Part (Main_Part)
        .Enable_Part (Label_Part)
        .Enable_Part (Icon_Part)
        .Disable_Part (Indicator_Part)
        .Disable_Part (Scroll_Part)
        .Disable_Part (Knob_Part)
        .Disable_Part (Selected_Part)
        .Disable_Part (Items_Part)
        .Disable_Part (Cursor_Part);
   end Button_Template;

   function Checkbox_Template return Part_Style_Builder is
   begin
      return Create
        .Enable_Part (Main_Part)
        .Enable_Part (Indicator_Part)
        .Enable_Part (Label_Part)
        .Disable_Part (Icon_Part)
        .Disable_Part (Scroll_Part)
        .Disable_Part (Knob_Part)
        .Disable_Part (Selected_Part)
        .Disable_Part (Items_Part)
        .Disable_Part (Cursor_Part);
   end Checkbox_Template;

   function Scrollbar_Template return Part_Style_Builder is
   begin
      return Create
        .Enable_Part (Main_Part)
        .Enable_Part (Scroll_Part)
        .Enable_Part (Knob_Part)
        .Disable_Part (Indicator_Part)
        .Disable_Part (Label_Part)
        .Disable_Part (Icon_Part)
        .Disable_Part (Selected_Part)
        .Disable_Part (Items_Part)
        .Disable_Part (Cursor_Part);
   end Scrollbar_Template;

   function Input_Template return Part_Style_Builder is
   begin
      return Create
        .Enable_Part (Main_Part)
        .Enable_Part (Label_Part)
        .Enable_Part (Cursor_Part)
        .Disable_Part (Indicator_Part)
        .Disable_Part (Icon_Part)
        .Disable_Part (Scroll_Part)
        .Disable_Part (Knob_Part)
        .Disable_Part (Selected_Part)
        .Disable_Part (Items_Part);
   end Input_Template;

   function List_Template return Part_Style_Builder is
   begin
      return Create
        .Enable_Part (Main_Part)
        .Enable_Part (Items_Part)
        .Enable_Part (Selected_Part)
        .Enable_Part (Scroll_Part)
        .Enable_Part (Knob_Part)
        .Disable_Part (Indicator_Part)
        .Disable_Part (Label_Part)
        .Disable_Part (Icon_Part)
        .Disable_Part (Cursor_Part);
   end List_Template;

   function Slider_Template return Part_Style_Builder is
   begin
      return Create
        .Enable_Part (Main_Part)
        .Enable_Part (Knob_Part)
        .Enable_Part (Indicator_Part)  --  For filled track portion
        .Disable_Part (Scroll_Part)
        .Disable_Part (Label_Part)
        .Disable_Part (Icon_Part)
        .Disable_Part (Selected_Part)
        .Disable_Part (Items_Part)
        .Disable_Part (Cursor_Part);
   end Slider_Template;

   ---------------------------------------------------------------------------
   --  Predefined Style Themes
   ---------------------------------------------------------------------------

   function Primary_Button_Style return Part_Style_Array is
      --  Blue button with white text, hover/press states
      Main_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Display          => Set (Inline_Flex),
             Justify_Content  => Set (Center),
             Align_Items      => Set (Adi.CSS_Styles.Center),
             Background_Color => Set_Bg (C (Blue)),
             Border_Width     => Set (Border_Width (Px (0))),
             Border_Radius    => Set (Radius (Px (6))),
             Padding          => Set (CSS_Box (Px (12), Px (24))),
             Cursor           => Set (Cursor_Pointer),
             others           => <>))
          .On_Hover ((
             Background_Color => Set_Bg (RGB (30, 64, 175)),  --  Darker blue
             others           => <>))
          .On_Press ((
             Background_Color => Set_Bg (RGB (29, 58, 145)),  --  Even darker
             others           => <>))
          .On_Disabled ((
             Background_Color => Set_Bg (C (Gray)),
             Cursor           => Set (Cursor_Not_Allowed),
             others           => <>))
          .Build;

      Label_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Color          => Set (C (White)),
             Font_Size      => Set_Font (Px (14)),
             Font_Weight    => Set (Weight_Medium),
             Text_Align     => Set (Text_Center),
             Text_Wrap_Mode => Set (TWM_Nowrap),
             others         => <>))
          .On_Disabled ((
             Color => Set (C (Light_Gray)),
             others => <>))
          .Build;

      Icon_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Color      => Set (C (White)),
             Object_Fit => Set (Fit_Contain),
             others     => <>))
          .On_Disabled ((
             Color   => Set (C (Light_Gray)),
             Opacity => Set (0.5),
             others  => <>))
          .Build;
   begin
      return Button_Template
        .With_Main (Main_Style)
        .With_Label (Label_Style)
        .With_Icon (Icon_Style)
        .Build;
   end Primary_Button_Style;

   function Secondary_Button_Style return Part_Style_Array is
      --  Outlined button with blue border
      Main_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Display          => Set (Inline_Flex),
             Justify_Content  => Set (Center),
             Align_Items      => Set (Adi.CSS_Styles.Center),
             Background_Color => Set_Bg (C (Transparent)),
             Border_Width     => Set (Border_Width (Px (2))),
             Border_Color     => Set (Border_Color (C (Blue))),
             Border_Style     => Set (Border_Style (Solid)),
             Border_Radius    => Set (Radius (Px (6))),
             Padding          => Set (CSS_Box (Px (10), Px (22))),
             Cursor           => Set (Cursor_Pointer),
             others           => <>))
          .On_Hover ((
             Background_Color => Set_Bg (RGBA (59, 130, 246, 0.1)),
             others           => <>))
          .On_Press ((
             Background_Color => Set_Bg (RGBA (59, 130, 246, 0.2)),
             others           => <>))
          .On_Disabled ((
             Border_Color => Set (Border_Color (C (Gray))),
             Cursor       => Set (Cursor_Not_Allowed),
             others       => <>))
          .Build;

      Label_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Color          => Set (C (Blue)),
             Font_Size      => Set_Font (Px (14)),
             Font_Weight    => Set (Weight_Medium),
             Text_Align     => Set (Text_Center),
             Text_Wrap_Mode => Set (TWM_Nowrap),
             others         => <>))
          .On_Hover ((
             Color => Set (C (White)),
             others => <>))
          .On_Disabled ((
             Color => Set (C (Gray)),
             others => <>))
          .Build;
   begin
      return Button_Template
        .With_Main (Main_Style)
        .With_Label (Label_Style)
        .Build;
   end Secondary_Button_Style;

   function Danger_Button_Style return Part_Style_Array is
      --  Red button for destructive actions
      Main_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Display          => Set (Inline_Flex),
             Justify_Content  => Set (Center),
             Align_Items      => Set (Adi.CSS_Styles.Center),
             Background_Color => Set_Bg (C (Red)),
             Border_Width     => Set (Border_Width (Px (0))),
             Border_Radius    => Set (Radius (Px (6))),
             Padding          => Set (CSS_Box (Px (12), Px (24))),
             Cursor           => Set (Cursor_Pointer),
             others           => <>))
          .On_Hover ((
             Background_Color => Set_Bg (RGB (185, 28, 28)),  --  Darker red
             others           => <>))
          .On_Press ((
             Background_Color => Set_Bg (RGB (153, 27, 27)),  --  Even darker
             others           => <>))
          .On_Disabled ((
             Background_Color => Set_Bg (C (Gray)),
             Cursor           => Set (Cursor_Not_Allowed),
             others           => <>))
          .Build;

      Label_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Color          => Set (C (White)),
             Font_Size      => Set_Font (Px (14)),
             Font_Weight    => Set (Weight_Medium),
             Text_Align     => Set (Text_Center),
             Text_Wrap_Mode => Set (TWM_Nowrap),
             others         => <>))
          .On_Disabled ((
             Color => Set (C (Light_Gray)),
             others => <>))
          .Build;
   begin
      return Button_Template
        .With_Main (Main_Style)
        .With_Label (Label_Style)
        .Build;
   end Danger_Button_Style;

   function Card_Style return Part_Style_Array is
      --  Basic card with shadow effect (border approximation)
      Main_Style : constant Widget_Style :=
        Adi.Widget_Styles.Create
          .Base ((
             Background_Color => Set_Bg (C (White)),
             Border_Width     => Set (Border_Width (Px (1))),
             Border_Color     => Set (Border_Color (C (Light_Gray))),
             Border_Style     => Set (Border_Style (Solid)),
             Border_Radius    => Set (Radius (Px (8))),
             Padding          => Set (CSS_Box (Px (16))),
             others           => <>))
          .On_Hover ((
             Border_Color => Set (Border_Color (C (Gray))),
             others       => <>))
          .Build;
   begin
      return Create
        .Enable_Part (Main_Part)
        .With_Main (Main_Style)
        .Build;
   end Card_Style;

end Adi.Widget.Part_Styles;