--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Parser;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.Widget.Testing;
with Test_Support; use Test_Support;

procedure Style_Sparse_Test is

   ---------------------------------------------------------------------
   --  State bits
   ---------------------------------------------------------------------

   procedure Test_State_Sets_Are_Bits is
      Bits_Needed : constant Natural := Widget_State'Pos (Widget_State'Last) + 1;
   begin
      Section ("a state set is one bit per state");

      Assert (Widget_States'Object_Size <= 16,
              "Widget_States holds" & Natural'Image (Bits_Needed)
              & " states in two bytes or fewer");
      Assert (State_Selector'Object_Size <= 64,
              "State_Selector holds four state sets in eight bytes or fewer");
   end Test_State_Sets_Are_Bits;

   procedure Test_State_Sets_Behave is
      H : constant State_Selector := When_State (State_Hovered);
      P : constant State_Selector := When_Part_State (State_Pressed);
      N : constant State_Selector := When_Not (State_Disabled);
      Hovered : constant Widget_States := Single_State (State_Hovered);
      Pressed : constant Widget_States := Single_State (State_Pressed);
   begin
      Section ("state sets read by index as they did");

      Assert (Hovered (State_Hovered), "a single state names itself");
      Assert (not Hovered (State_Pressed), "and names nothing else");
      Assert (No_States = Widget_States'[others => False],
              "the empty set equals an all-False aggregate");
      Assert (All_States = Widget_States'[others => True],
              "the full set equals an all-True aggregate");
      Assert (Hovered /= Pressed, "two single states differ");

      Assert (Matches (H, Hovered), "a required state matches when active");
      Assert (not Matches (H, No_States),
              "a required state fails when inactive");
      Assert (Matches (N, No_States), "an excluded state matches when absent");
      Assert (not Matches (N, Single_State (State_Disabled)),
              "an excluded state fails when present");
      Assert (Matches (P, No_States, Pressed),
              "a part state matches on the part axis");
      Assert (not Matches (P, Pressed, No_States),
              "a part state ignores the widget axis");

      Assert (Specificity (Any_State) = 0, "any-state scores nothing");
      Assert (Specificity (H) = 1, "one condition scores one");
      Assert (Specificity (H and N) = 2, "two conditions score two");

      Assert (Matches (H and When_State (State_Focused),
                       Widget_States'[State_Hovered | State_Focused => True,
                                      others => False]),
              "a combined selector needs both states");
   end Test_State_Sets_Behave;

   ---------------------------------------------------------------------
   --  Visibility
   ---------------------------------------------------------------------

   procedure Test_Visibility_Reaches_A_Part is
      W  : constant Box_Handle := Create_Handle;
      WS : constant Widget_Style :=
        From (Style_Rules'(Visibility => Set (Visibility_Hidden),
                           others     => <>)).Build;
   begin
      Section ("visibility inherits from a widget to its parts");

      Set_Part_Style (+W, Main_Part, WS);

      Assert (Get_Resolved_Part_Style (+W, Main_Part).Visibility
                = Visibility_Hidden,
              "the main part carries the declared visibility");
      Assert (Get_Resolved_Part_Style (+W, Label_Part).Visibility
                = Visibility_Hidden,
              "a sub-part inherits it through the part cascade");
      Assert (Inheritable_Properties (Prop_Visibility),
              "and the inheritance table says so");
   end Test_Visibility_Reaches_A_Part;

   ---------------------------------------------------------------------
   --  Rules sized to the sheet
   ---------------------------------------------------------------------

   procedure Test_Store_Sizes_To_The_Rules is

      --  Distinct bases, so each interns as its own entry.
      function Base_Rules (Tag : Natural) return Style_Rules is
        (Style_Rules'(Flex_Grow => Set (Flex_Grow_Value (Tag)),
                      others    => <>));

      function Style_With (Tag, Rules : Natural) return Widget_Style is
         Result : Widget_Style :=
           From (Base_Rules (Tag)).Build;
         States : constant array (1 .. 5) of Widget_State :=
           [State_Hovered, State_Pressed, State_Focused,
            State_Disabled, State_Selected];
      begin
         for I in 1 .. Rules loop
            Add_Rule
              (Result,
               (Selector => When_State (States (((I - 1) mod 5) + 1)),
                Style    => Style_Rules'(Order => Set (Order_Value (I)),
                                         others => <>),
                Priority => I));
         end loop;
         return Result;
      end Style_With;

      function Cost_Of (S : Widget_Style) return Natural is
         Before : constant Natural := Adi.Widget.Testing.Interned_Style_Bytes;
         W      : constant Box_Handle := Create_Handle;
      begin
         Set_Part_Style (+W, Main_Part, S);
         return Adi.Widget.Testing.Interned_Style_Bytes - Before;
      end Cost_Of;

      Bare  : constant Natural := Cost_Of (Style_With (1, 0));
      One   : constant Natural := Cost_Of (Style_With (2, 1));
      Eight : constant Natural := Cost_Of (Style_With (3, 8));
      Full  : constant Natural := Cost_Of (Style_With (4, Max_Style_Rules));
   begin
      Section ("an interned entry costs the rules it carries");

      Put_Line ("      entry bytes: 0 rules" & Natural'Image (Bare)
                & ", 1" & Natural'Image (One)
                & ", 8" & Natural'Image (Eight)
                & "," & Natural'Image (Max_Style_Rules)
                & Natural'Image (Full));

      Assert (Bare > 0, "interning a style costs storage");
      Assert (One > Bare, "a style naming one rule costs more than none");
      Assert (Eight > One, "eight rules cost more than one");
      Assert (Full > Eight, "a full rule set costs more than eight");

      Assert (Bare * 4 < Full,
              "a rule-free style costs a fraction of a full one");

      Assert (Eight - One >= 6 * (One - Bare),
              "each further rule adds its own storage");
   end Test_Store_Sizes_To_The_Rules;

   ---------------------------------------------------------------------
   --  Declaration names
   ---------------------------------------------------------------------

   --  Every declaration name Apply_Property recognises, as the
   --  oracle the name lookup has to answer for.
   type Name_List is array (Positive range <>) of access constant String;

   N_align_content : aliased constant String := "align-content";
   N_align_items : aliased constant String := "align-items";
   N_align_self : aliased constant String := "align-self";
   N_background : aliased constant String := "background";
   N_background_color : aliased constant String := "background-color";
   N_background_image : aliased constant String := "background-image";
   N_border : aliased constant String := "border";
   N_border_bottom : aliased constant String := "border-bottom";
   N_border_bottom_color : aliased constant String := "border-bottom-color";
   N_border_bottom_left_radius : aliased constant String := "border-bottom-left-radius";
   N_border_bottom_right_radius : aliased constant String := "border-bottom-right-radius";
   N_border_bottom_style : aliased constant String := "border-bottom-style";
   N_border_bottom_width : aliased constant String := "border-bottom-width";
   N_border_color : aliased constant String := "border-color";
   N_border_left : aliased constant String := "border-left";
   N_border_left_color : aliased constant String := "border-left-color";
   N_border_left_style : aliased constant String := "border-left-style";
   N_border_left_width : aliased constant String := "border-left-width";
   N_border_radius : aliased constant String := "border-radius";
   N_border_right : aliased constant String := "border-right";
   N_border_right_color : aliased constant String := "border-right-color";
   N_border_right_style : aliased constant String := "border-right-style";
   N_border_right_width : aliased constant String := "border-right-width";
   N_border_style : aliased constant String := "border-style";
   N_border_top : aliased constant String := "border-top";
   N_border_top_color : aliased constant String := "border-top-color";
   N_border_top_left_radius : aliased constant String := "border-top-left-radius";
   N_border_top_right_radius : aliased constant String := "border-top-right-radius";
   N_border_top_style : aliased constant String := "border-top-style";
   N_border_top_width : aliased constant String := "border-top-width";
   N_border_width : aliased constant String := "border-width";
   N_bottom : aliased constant String := "bottom";
   N_box_shadow : aliased constant String := "box-shadow";
   N_color : aliased constant String := "color";
   N_column_gap : aliased constant String := "column-gap";
   N_cursor : aliased constant String := "cursor";
   N_display : aliased constant String := "display";
   N_flex_basis : aliased constant String := "flex-basis";
   N_flex_direction : aliased constant String := "flex-direction";
   N_flex_grow : aliased constant String := "flex-grow";
   N_flex_shrink : aliased constant String := "flex-shrink";
   N_flex_wrap : aliased constant String := "flex-wrap";
   N_font_family : aliased constant String := "font-family";
   N_font_size : aliased constant String := "font-size";
   N_font_style : aliased constant String := "font-style";
   N_font_weight : aliased constant String := "font-weight";
   N_gap : aliased constant String := "gap";
   N_grid_column : aliased constant String := "grid-column";
   N_grid_row : aliased constant String := "grid-row";
   N_grid_template_columns : aliased constant String := "grid-template-columns";
   N_grid_template_rows : aliased constant String := "grid-template-rows";
   N_height : aliased constant String := "height";
   N_justify_content : aliased constant String := "justify-content";
   N_left : aliased constant String := "left";
   N_line_height : aliased constant String := "line-height";
   N_list_style : aliased constant String := "list-style";
   N_list_style_image : aliased constant String := "list-style-image";
   N_list_style_position : aliased constant String := "list-style-position";
   N_list_style_type : aliased constant String := "list-style-type";
   N_margin : aliased constant String := "margin";
   N_margin_bottom : aliased constant String := "margin-bottom";
   N_margin_left : aliased constant String := "margin-left";
   N_margin_right : aliased constant String := "margin-right";
   N_margin_top : aliased constant String := "margin-top";
   N_max_height : aliased constant String := "max-height";
   N_max_width : aliased constant String := "max-width";
   N_min_height : aliased constant String := "min-height";
   N_min_width : aliased constant String := "min-width";
   N_object_fit : aliased constant String := "object-fit";
   N_object_position : aliased constant String := "object-position";
   N_opacity : aliased constant String := "opacity";
   N_order : aliased constant String := "order";
   N_outline : aliased constant String := "outline";
   N_outline_color : aliased constant String := "outline-color";
   N_outline_offset : aliased constant String := "outline-offset";
   N_outline_style : aliased constant String := "outline-style";
   N_outline_width : aliased constant String := "outline-width";
   N_overflow : aliased constant String := "overflow";
   N_overflow_x : aliased constant String := "overflow-x";
   N_overflow_y : aliased constant String := "overflow-y";
   N_padding : aliased constant String := "padding";
   N_padding_bottom : aliased constant String := "padding-bottom";
   N_padding_left : aliased constant String := "padding-left";
   N_padding_right : aliased constant String := "padding-right";
   N_padding_top : aliased constant String := "padding-top";
   N_position : aliased constant String := "position";
   N_right : aliased constant String := "right";
   N_row_gap : aliased constant String := "row-gap";
   N_text_align : aliased constant String := "text-align";
   N_text_decoration : aliased constant String := "text-decoration";
   N_text_overflow : aliased constant String := "text-overflow";
   N_text_wrap_mode : aliased constant String := "text-wrap-mode";
   N_top : aliased constant String := "top";
   N_transition : aliased constant String := "transition";
   N_vertical_align : aliased constant String := "vertical-align";
   N_visibility : aliased constant String := "visibility";
   N_white_space : aliased constant String := "white-space";
   N_width : aliased constant String := "width";

   Declaration_Names : constant Name_List :=
     [
      N_align_content'Access,
      N_align_items'Access,
      N_align_self'Access,
      N_background'Access,
      N_background_color'Access,
      N_background_image'Access,
      N_border'Access,
      N_border_bottom'Access,
      N_border_bottom_color'Access,
      N_border_bottom_left_radius'Access,
      N_border_bottom_right_radius'Access,
      N_border_bottom_style'Access,
      N_border_bottom_width'Access,
      N_border_color'Access,
      N_border_left'Access,
      N_border_left_color'Access,
      N_border_left_style'Access,
      N_border_left_width'Access,
      N_border_radius'Access,
      N_border_right'Access,
      N_border_right_color'Access,
      N_border_right_style'Access,
      N_border_right_width'Access,
      N_border_style'Access,
      N_border_top'Access,
      N_border_top_color'Access,
      N_border_top_left_radius'Access,
      N_border_top_right_radius'Access,
      N_border_top_style'Access,
      N_border_top_width'Access,
      N_border_width'Access,
      N_bottom'Access,
      N_box_shadow'Access,
      N_color'Access,
      N_column_gap'Access,
      N_cursor'Access,
      N_display'Access,
      N_flex_basis'Access,
      N_flex_direction'Access,
      N_flex_grow'Access,
      N_flex_shrink'Access,
      N_flex_wrap'Access,
      N_font_family'Access,
      N_font_size'Access,
      N_font_style'Access,
      N_font_weight'Access,
      N_gap'Access,
      N_grid_column'Access,
      N_grid_row'Access,
      N_grid_template_columns'Access,
      N_grid_template_rows'Access,
      N_height'Access,
      N_justify_content'Access,
      N_left'Access,
      N_line_height'Access,
      N_list_style'Access,
      N_list_style_image'Access,
      N_list_style_position'Access,
      N_list_style_type'Access,
      N_margin'Access,
      N_margin_bottom'Access,
      N_margin_left'Access,
      N_margin_right'Access,
      N_margin_top'Access,
      N_max_height'Access,
      N_max_width'Access,
      N_min_height'Access,
      N_min_width'Access,
      N_object_fit'Access,
      N_object_position'Access,
      N_opacity'Access,
      N_order'Access,
      N_outline'Access,
      N_outline_color'Access,
      N_outline_offset'Access,
      N_outline_style'Access,
      N_outline_width'Access,
      N_overflow'Access,
      N_overflow_x'Access,
      N_overflow_y'Access,
      N_padding'Access,
      N_padding_bottom'Access,
      N_padding_left'Access,
      N_padding_right'Access,
      N_padding_top'Access,
      N_position'Access,
      N_right'Access,
      N_row_gap'Access,
      N_text_align'Access,
      N_text_decoration'Access,
      N_text_overflow'Access,
      N_text_wrap_mode'Access,
      N_top'Access,
      N_transition'Access,
      N_vertical_align'Access,
      N_visibility'Access,
      N_white_space'Access,
      N_width'Access
     ];

   C01 : aliased constant String := "4px";
   C02 : aliased constant String := "rgb(1, 2, 3)";
   C03 : aliased constant String := "auto";
   C04 : aliased constant String := "none";
   C05 : aliased constant String := "solid";
   C06 : aliased constant String := "1";
   C07 : aliased constant String := "1.5";
   C08 : aliased constant String := "center";
   C09 : aliased constant String := "row";
   C10 : aliased constant String := "wrap";
   C11 : aliased constant String := "hidden";
   C12 : aliased constant String := "visible";
   C13 : aliased constant String := "block";
   C14 : aliased constant String := "absolute";
   C15 : aliased constant String := "url(a.png)";
   C16 : aliased constant String := """x""";
   C17 : aliased constant String := "bold";
   C18 : aliased constant String := "italic";
   C19 : aliased constant String := "underline";
   C20 : aliased constant String := "nowrap";
   C21 : aliased constant String := "normal";
   C22 : aliased constant String := "ellipsis";
   C23 : aliased constant String := "pointer";
   C24 : aliased constant String := "contain";
   C25 : aliased constant String := "flex-start";
   C26 : aliased constant String := "space-between";
   C27 : aliased constant String := "1px solid rgb(1, 2, 3)";
   C28 : aliased constant String := "inside";
   C29 : aliased constant String := "disc";
   C30 : aliased constant String := "0.2s";
   C31 : aliased constant String := "middle";

   Candidates : constant Name_List :=
     [C01'Access, C02'Access, C03'Access, C04'Access, C05'Access,
      C06'Access, C07'Access, C08'Access, C09'Access, C10'Access,
      C11'Access, C12'Access, C13'Access, C14'Access, C15'Access,
      C16'Access, C17'Access, C18'Access, C19'Access, C20'Access,
      C21'Access, C22'Access, C23'Access, C24'Access, C25'Access,
      C26'Access, C27'Access, C28'Access, C29'Access, C30'Access,
      C31'Access];

   procedure Test_Every_Name_Routes is
      Landed : Natural := 0;
      Named  : Natural := 0;

      Empty : constant CSS_Property_Set := [others => False];

      function Reached (Name, Value : String) return CSS_Property_Set is
         Sheet : Adi.CSS_Parser.Stylesheet;
         OK    : Boolean := False;
      begin
         Adi.CSS_Parser.Load_String
           (Sheet, ".probe { " & Name & ": " & Value & "; }", OK);
         if not OK then
            return Empty;
         end if;
         return Set_Properties
           (Adi.CSS_Parser.Styles_For_Class (Sheet, "probe")
              (Main_Part).Style.Base);
      end Reached;

      function Lands (Name, Value : String) return Boolean is
        (Reached (Name, Value) /= Empty);

      --  "border-left-color" spelled the way CSS_Property'Image answers,
      --  which pins a name to its own literal rather than to any literal.
      function Literal_Image (Name : String) return String is
         R : String (1 .. Name'Length) := Name;
      begin
         for I in R'Range loop
            R (I) :=
              (if R (I) = '-' then '_'
               else Ada.Characters.Handling.To_Upper (R (I)));
         end loop;
         return "PROP_" & R;
      end Literal_Image;

      --  The literal a longhand name owns. A shorthand spreads across
      --  several and answers with the empty set, as does Prop_Overflow,
      --  which is shorthand metadata carried by the two axes.
      function Own_Property (Name : String) return CSS_Property_Set is
         Want : constant String := Literal_Image (Name);
         R    : CSS_Property_Set := Empty;
      begin
         for P in CSS_Property loop
            if CSS_Property'Image (P) = Want and then P /= Prop_Overflow then
               R (P) := True;
            end if;
         end loop;
         return R;
      end Own_Property;

   begin
      Section ("every declaration name reaches its branch");

      for N of Declaration_Names loop
         declare
            Own : constant CSS_Property_Set := Own_Property (N.all);
            Hit : Boolean := False;
         begin
            for C of Candidates loop
               declare
                  Got : constant CSS_Property_Set := Reached (N.all, C.all);
               begin
                  if Got /= Empty then
                     Hit := True;

                     --  A name that owns a literal sets that one, so a
                     --  table row reaching its neighbour's branch shows
                     --  here rather than passing as some property set.
                     if Own /= Empty then
                        Named := Named + 1;
                        Assert ((for some P in CSS_Property =>
                                   Own (P) and then Got (P)),
                                "'" & N.all & "' sets its own property");
                     end if;
                     exit;
                  end if;
               end;
            end loop;

            Assert (Hit, "'" & N.all & "' sets a property");
            if Hit then
               Landed := Landed + 1;
            end if;
         end;
      end loop;

      Assert (Named >= 60,
              "most declaration names are pinned to their own literal");

      Assert (Landed = Declaration_Names'Length,
              "every recognised name routes to a branch");

      Assert (not Lands ("not-a-property", "4px"),
              "an unrecognised name sets nothing");
      Assert (not Lands ("colo", "red"), "a truncated name sets nothing");
      Assert (not Lands ("colorr", "red"), "an extended name sets nothing");
   end Test_Every_Name_Routes;

   ---------------------------------------------------------------------
   --  Sizes
   ---------------------------------------------------------------------

   procedure Report_Sizes is
      procedure Row (Name : String; Object_Bits, Max_SE : Natural) is
         Pad : constant String := [1 .. 26 - Name'Length => ' '];
      begin
         Put_Line ("      " & Name & Pad & Natural'Image (Object_Bits / 8)
                   & Natural'Image (Max_SE));
      end Row;
   begin
      Section ("size chain, bytes: 'Object_Size/8 and 'Max_Size_In_SE");

      Row ("Widget_States",
           Widget_States'Object_Size,
           Widget_States'Max_Size_In_Storage_Elements);
      Row ("State_Selector",
           State_Selector'Object_Size,
           State_Selector'Max_Size_In_Storage_Elements);
      Row ("Style_Rules",
           Style_Rules'Object_Size,
           Style_Rules'Max_Size_In_Storage_Elements);
      Row ("State_Rule",
           State_Rule'Object_Size,
           State_Rule'Max_Size_In_Storage_Elements);
      Row ("Widget_Style",
           Widget_Style'Object_Size,
           Widget_Style'Max_Size_In_Storage_Elements);
      Row ("Part_Style_Array",
           Part_Style_Array'Object_Size,
           Part_Style_Array'Max_Size_In_Storage_Elements);
      Assert (Adi.CSS_Parser.Stylesheet_Metadata'Object_Size / 8 < 1024,
              "Stylesheet_Metadata holds its root styles by handle");

      Row ("Stylesheet_Metadata",
           Adi.CSS_Parser.Stylesheet_Metadata'Object_Size,
           Adi.CSS_Parser.Stylesheet_Metadata'Max_Size_In_Storage_Elements);
   end Report_Sizes;

begin
   Start_Suite ("Style sparse storage test");

   Test_State_Sets_Are_Bits;
   Test_State_Sets_Behave;
   Test_Visibility_Reaches_A_Part;
   Test_Store_Sizes_To_The_Rules;
   Test_Every_Name_Routes;
   Report_Sizes;

   Finish;
end Style_Sparse_Test;
