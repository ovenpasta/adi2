with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;

package Adi.Widget.Part_Styles is

   ---------------------------------------------------------------------------
   --  Part Style Builder - Fluent API for configuring widget part styles
   ---------------------------------------------------------------------------

   type Part_Style_Builder is tagged private;

   --  Create a new builder
   function Create return Part_Style_Builder;

   --  Configure a specific part with a Widget_Style
   function With_Part (B : Part_Style_Builder;
                       P : Part_Kind;
                       S : Widget_Style) return Part_Style_Builder;

   --  Configure a specific part using a Style_Builder (finalizes it)
   function With_Part (B : Part_Style_Builder;
                       P : Part_Kind;
                       S : Style_Builder'Class) return Part_Style_Builder;

   --  Shorthand methods for common parts
   function With_Main (B : Part_Style_Builder;
                       S : Widget_Style) return Part_Style_Builder;
   function With_Main (B : Part_Style_Builder;
                       S : Style_Builder'Class) return Part_Style_Builder;

   function With_Label (B : Part_Style_Builder;
                        S : Widget_Style) return Part_Style_Builder;
   function With_Label (B : Part_Style_Builder;
                        S : Style_Builder'Class) return Part_Style_Builder;

   function With_Icon (B : Part_Style_Builder;
                       S : Widget_Style) return Part_Style_Builder;
   function With_Icon (B : Part_Style_Builder;
                       S : Style_Builder'Class) return Part_Style_Builder;

   function With_Indicator (B : Part_Style_Builder;
                            S : Widget_Style) return Part_Style_Builder;
   function With_Indicator (B : Part_Style_Builder;
                            S : Style_Builder'Class) return Part_Style_Builder;

   function With_Knob (B : Part_Style_Builder;
                       S : Widget_Style) return Part_Style_Builder;
   function With_Knob (B : Part_Style_Builder;
                       S : Style_Builder'Class) return Part_Style_Builder;

   function With_Scroll (B : Part_Style_Builder;
                         S : Widget_Style) return Part_Style_Builder;
   function With_Scroll (B : Part_Style_Builder;
                         S : Style_Builder'Class) return Part_Style_Builder;

   function With_Cursor (B : Part_Style_Builder;
                         S : Widget_Style) return Part_Style_Builder;
   function With_Cursor (B : Part_Style_Builder;
                         S : Style_Builder'Class) return Part_Style_Builder;

   function With_Selected (B : Part_Style_Builder;
                           S : Widget_Style) return Part_Style_Builder;
   function With_Selected (B : Part_Style_Builder;
                           S : Style_Builder'Class) return Part_Style_Builder;

   --  Disable a part (won't be rendered)
   function Disable_Part (B : Part_Style_Builder;
                          P : Part_Kind) return Part_Style_Builder;

   --  Enable a part
   function Enable_Part (B : Part_Style_Builder;
                         P : Part_Kind) return Part_Style_Builder;

   --  Build the final Part_Style_Array
   function Build (B : Part_Style_Builder) return Part_Style_Array;

   --  Apply directly to a widget
   procedure Apply_To (B : Part_Style_Builder; W : in out Widget'Class);

   ---------------------------------------------------------------------------
   --  Predefined Part Style Templates
   --  These define which parts are enabled for common widget types
   ---------------------------------------------------------------------------

   --  Standard button styling (main panel + label + optional icon)
   function Button_Template return Part_Style_Builder;

   --  Checkbox styling (main + indicator + label)
   function Checkbox_Template return Part_Style_Builder;

   --  Scrollbar styling (scroll track + knob)
   function Scrollbar_Template return Part_Style_Builder;

   --  Text input styling (main + cursor + label)
   function Input_Template return Part_Style_Builder;

   --  List/menu item styling (main + selected + items + scroll)
   function List_Template return Part_Style_Builder;

   --  Slider styling (main + knob + indicator)
   function Slider_Template return Part_Style_Builder;

private

   type Part_Style_Builder is tagged record
      Styles       : Part_Style_Array := Empty_Part_Styles;
   end record;

end Adi.Widget.Part_Styles;
