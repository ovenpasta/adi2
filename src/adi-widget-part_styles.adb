package body Adi.Widget.Part_Styles is

   ---------------------------------------------------------------------------
   --  Builder Creation
   ---------------------------------------------------------------------------

   function Create return Part_Style_Builder is
   begin
      return (Styles => Empty_Part_Styles);
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
   --  Build and Apply
   ---------------------------------------------------------------------------

   function Build (B : Part_Style_Builder) return Part_Style_Array is
   begin
      return B.Styles;
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

end Adi.Widget.Part_Styles;
