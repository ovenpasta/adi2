--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Parser;
with Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Flat_Values_Styles;
with Test_Support; use Test_Support;

procedure Style_Flat_Values_Test is

   use type Opt_Bg_Image.Optional;
   use type Opt_Font.Optional;
   use type Opt_List_Style_Type.Optional;
   use type Opt_List_Style_Image.Optional;

   --  The shape adi-widget.adb gives Prepared_Style_Entry, mirrored so
   --  the interned entry appears in the size table beside the types it
   --  is built from. It is declared in a body, out of reach of a with.
   type Ordered_Rule_Index_Array is
     array (Positive range 1 .. Max_Style_Rules) of Positive;

   type Prepared_Style_Entry is record
      Style         : Widget_Style := Empty_Widget_Style;
      Ordered_Rules : Ordered_Rule_Index_Array := [others => 1];
      Ordered_Count : Natural := 0;
   end record;

   ---------------------------------------------------------------------
   --  Finalization
   ---------------------------------------------------------------------

   --  GNAT answers 'Finalization_Size with the size of the hidden data
   --  it reserves to run an object's finalization, and with zero for a
   --  type that needs none. It is the direct reading of "this type is
   --  controlled or holds something that is", which the language offers
   --  no attribute for.

   procedure Test_Finalization is
   begin
      Section ("style values need no finalization");

      Assert (Font_Family_Value'Finalization_Size = 0,
              "Font_Family_Value is flat");
      Assert (Background_Image_Value'Finalization_Size = 0,
              "Background_Image_Value is flat");
      Assert (List_Style_Type_Value'Finalization_Size = 0,
              "List_Style_Type_Value is flat");
      Assert (List_Style_Image_Value'Finalization_Size = 0,
              "List_Style_Image_Value is flat");

      Assert (Style_Rules'Finalization_Size = 0,
              "Style_Rules is flat");
      Assert (Resolved_Style'Finalization_Size = 0,
              "Resolved_Style is flat");
      Assert (State_Rule'Finalization_Size = 0,
              "State_Rule is flat");
      Assert (Widget_Style'Finalization_Size = 0,
              "Widget_Style is flat");
      Assert (Part_Style'Finalization_Size = 0,
              "Part_Style is flat");
      Assert (Part_Style_Array'Finalization_Size = 0,
              "Part_Style_Array is flat");
      Assert (Prepared_Style_Entry'Finalization_Size = 0,
              "Prepared_Style_Entry is flat");
      Assert (Adi.CSS_Parser.Stylesheet_Metadata'Finalization_Size = 0,
              "Stylesheet_Metadata is flat");
   end Test_Finalization;

   ---------------------------------------------------------------------
   --  Sizes
   ---------------------------------------------------------------------

   procedure Report_Sizes is
      procedure Row (Name : String; Object_Bits, Max_SE : Natural) is
         Bytes : constant String := Natural'Image (Object_Bits / 8);
         Pad   : constant String := [1 .. 28 - Name'Length => ' '];
      begin
         Put_Line ("      " & Name & Pad & Bytes & Natural'Image (Max_SE));
      end Row;
   begin
      Section ("size chain, bytes: 'Object_Size/8 and 'Max_Size_In_SE");

      Row ("Background_Image_Value",
           Background_Image_Value'Object_Size,
           Background_Image_Value'Max_Size_In_Storage_Elements);
      Row ("Font_Family_Value",
           Font_Family_Value'Object_Size,
           Font_Family_Value'Max_Size_In_Storage_Elements);
      Row ("List_Style_Type_Value",
           List_Style_Type_Value'Object_Size,
           List_Style_Type_Value'Max_Size_In_Storage_Elements);
      Row ("List_Style_Image_Value",
           List_Style_Image_Value'Object_Size,
           List_Style_Image_Value'Max_Size_In_Storage_Elements);
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
      Row ("Stylesheet_Metadata",
           Adi.CSS_Parser.Stylesheet_Metadata'Object_Size,
           Adi.CSS_Parser.Stylesheet_Metadata'Max_Size_In_Storage_Elements);
      Row ("Prepared_Style_Entry",
           Prepared_Style_Entry'Object_Size,
           Prepared_Style_Entry'Max_Size_In_Storage_Elements);
      Row ("Resolved_Style",
           Resolved_Style'Object_Size,
           Resolved_Style'Max_Size_In_Storage_Elements);
   end Report_Sizes;

   ---------------------------------------------------------------------
   --  Text bounds
   ---------------------------------------------------------------------

   --  Text a style value carries is held to a maximum length. The
   --  figure itself is Adi.CSS_Styles.Max_CSS_Text_Length; the two
   --  lengths here bracket it, so the checks say what a caller gets on
   --  either side of the limit without pinning the limit.
   Quote : constant Character := '"';
   Ordinary : constant String (1 .. 60) := [others => 'a'];
   Over_Long : constant String (1 .. 8192) := [others => 'b'];

   procedure Test_Text_Bounds is
   begin
      Section ("text a style value carries");

      Assert (Background_Image_URL (Ordinary).Kind = Url_Image,
              "an ordinary path names an image");
      Assert (List_Image (Ordinary).Kind = List_Image_URL,
              "an ordinary path names a list marker image");

      Assert (Background_Image_URL (Ordinary)
                = Background_Image_URL (Ordinary),
              "one path gives one background-image value");
      Assert (Background_Image_URL (Ordinary)
                /= Background_Image_URL (Ordinary & "x"),
              "two paths give two background-image values");
      Assert (List_String ("-> ") = List_String ("-> "),
              "one marker string gives one list-style-type value");
      Assert (List_String ("-> ") /= List_String ("* "),
              "two marker strings give two list-style-type values");

      Assert (Background_Image_URL (Over_Long).Kind = No_Image,
              "a path past the limit names no image");
      Assert (List_Image (Over_Long).Kind = List_Image_None,
              "a path past the limit names no list marker image");
      Assert (List_String (Over_Long) = List_String (""),
              "a marker string past the limit reads as the empty one");
      Assert (Set_Font_Family (Over_Long) = Set_Font_Family (""),
              "a family list past the limit reads as the empty one");

      Assert (Background_Image_URL ("").Kind = No_Image,
              "an empty path names no image");
      Assert (List_Image ("").Kind = List_Image_None,
              "an empty path names no list marker image");
   end Test_Text_Bounds;

   --  The runtime parser holds the same limit as tools/css_to_ada.py,
   --  so a declaration naming more text than a style value carries is
   --  dropped rather than reaching one pipeline and not the other.
   procedure Test_Parser_Drops_Over_Long is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;
      CSS   : constant String :=
        ".over { background-image: url(" & Over_Long & ");"
        & " list-style-image: url(" & Over_Long & ");"
        & " list-style-type: " & Quote & Over_Long & Quote & ";"
        & " font-family: " & Over_Long & "; }" & ASCII.LF
        & ".fits { background-image: url(" & Ordinary & ");"
        & " list-style-image: url(" & Ordinary & ");"
        & " list-style-type: " & Quote & Ordinary & Quote & ";"
        & " font-family: " & Ordinary & "; }" & ASCII.LF;

      function Base (Class : String) return Style_Rules is
        (Adi.CSS_Parser.Styles_For_Class (Sheet, Class)
           (Main_Part).Style.Base);
   begin
      Section ("the parser drops text past the limit");

      Adi.CSS_Parser.Load_String (Sheet, CSS, OK);
      Assert (OK, "the probe stylesheet should parse");
      if not OK then
         return;
      end if;

      Assert (not Opt_Bg_Image.Is_Specified (Base ("over").Background_Image),
              "an over-long background-image url leaves the property unset");
      Assert (not Opt_List_Style_Image.Is_Specified
                (Base ("over").List_Style_Image),
              "an over-long list-style-image url leaves the property unset");
      Assert (not Opt_List_Style_Type.Is_Specified
                (Base ("over").List_Style_Type),
              "an over-long list-style-type marker leaves the property unset");
      Assert (not Opt_Font.Is_Specified (Base ("over").Font_Family),
              "an over-long font-family list leaves the property unset");

      Assert (Opt_Bg_Image.Is_Specified (Base ("fits").Background_Image),
              "a background-image url within the limit is kept");
      Assert (Opt_List_Style_Image.Is_Specified
                (Base ("fits").List_Style_Image),
              "a list-style-image url within the limit is kept");
      Assert (Opt_List_Style_Type.Is_Specified (Base ("fits").List_Style_Type),
              "a list-style-type marker within the limit is kept");
      Assert (Opt_Font.Is_Specified (Base ("fits").Font_Family),
              "a font-family list within the limit is kept");
   end Test_Parser_Drops_Over_Long;

   ---------------------------------------------------------------------
   --  Both pipelines
   ---------------------------------------------------------------------

   --  tools/css_to_ada.py encodes tests/css/flat_values.css at build
   --  time into tests/generated/flat_values_styles.ads; Adi.CSS_Parser
   --  reads the same file here. Each of the four properties is compared
   --  as the Style_Rules component both produce, so an encoding one
   --  pipeline adopts and the other does not is a failure.
   Corpus_Path : constant String := "tests/css/flat_values.css";

   procedure Test_Pipeline_Agreement is
      Sheet : Adi.CSS_Parser.Stylesheet;
      OK    : Boolean := False;

      function Parsed_Base (Class : String) return Style_Rules is
         Styles : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, Class);
      begin
         return Styles (Main_Part).Style.Base;
      end Parsed_Base;

      function Parsed_Hover (Class : String) return Style_Rules is
         Styles : constant Part_Style_Array :=
           Adi.CSS_Parser.Styles_For_Class (Sheet, Class);
         WS     : constant Widget_Style := Styles (Main_Part).Style;
      begin
         for I in 1 .. WS.Rule_Count loop
            if Matches (WS.Rules (I).Selector,
                        Single_State (State_Hovered))
            then
               return WS.Rules (I).Style;
            end if;
         end loop;
         return Empty_Style;
      end Parsed_Hover;

      procedure Compare (Label : String; G, P : Style_Rules) is
      begin
         Assert (G.Background_Image = P.Background_Image,
                 Label & ": background-image agrees between the pipelines");
         Assert (G.Font_Family = P.Font_Family,
                 Label & ": font-family agrees between the pipelines");
         Assert (G.List_Style_Type = P.List_Style_Type,
                 Label & ": list-style-type agrees between the pipelines");
         Assert (G.List_Style_Image = P.List_Style_Image,
                 Label & ": list-style-image agrees between the pipelines");
      end Compare;

      --  Agreement alone would pass with both pipelines wrong the same
      --  way, so the values are spelled out against the parsed side.
      procedure Expect_Parsed is
         Bg   : constant Style_Rules := Parsed_Base ("flat-bg");
         Grad : constant Style_Rules := Parsed_Base ("flat-grad");
         Lst  : constant Style_Rules := Parsed_Base ("flat-list");
         Hov  : constant Style_Rules := Parsed_Hover ("flat-list");
      begin
         Assert (Opt_Bg_Image.Resolve (Bg.Background_Image).Kind = Url_Image,
                 "a url() background-image parses as a URL image");
         Assert (Opt_Font.Resolve (Bg.Font_Family).Kind = By_Name,
                 "a font-family list parses as a name");
         Assert (Opt_Bg_Image.Resolve (Grad.Background_Image).Kind
                   = Linear_Gradient_Image,
                 "a linear-gradient() background-image parses as a gradient");
         Assert (Opt_List_Style_Type.Resolve (Lst.List_Style_Type).Kind
                   = List_Style_Custom_String,
                 "a quoted list-style-type parses as a custom string");
         Assert (Opt_List_Style_Image.Resolve (Lst.List_Style_Image).Kind
                   = List_Image_URL,
                 "a url() list-style-image parses as a URL image");
         Assert (Opt_List_Style_Type.Resolve (Hov.List_Style_Type).Kind
                   = List_Style_Square,
                 "the hover rule names a square marker");
         Assert (Opt_List_Style_Image.Resolve (Hov.List_Style_Image).Kind
                   = List_Image_None,
                 "the hover rule clears the marker image");
      end Expect_Parsed;

   begin
      Section ("generated and parsed pipelines agree");

      Adi.CSS_Parser.Load_File (Sheet, Corpus_Path, OK);
      Assert (OK, "corpus file should be readable from the repository root");
      if not OK then
         return;
      end if;

      Compare ("flat-bg",
               Flat_Values_Styles.Flat_Bg_Class_Base_Style,
               Parsed_Base ("flat-bg"));
      Compare ("flat-grad",
               Flat_Values_Styles.Flat_Grad_Class_Base_Style,
               Parsed_Base ("flat-grad"));
      Compare ("flat-list",
               Flat_Values_Styles.Flat_List_Class_Base_Style,
               Parsed_Base ("flat-list"));
      Compare ("flat-list:hover",
               Flat_Values_Styles.Flat_List_Class_Widget_Hovered_Style,
               Parsed_Hover ("flat-list"));

      Expect_Parsed;
   end Test_Pipeline_Agreement;

   ---------------------------------------------------------------------
   --  Through a source, both modes
   ---------------------------------------------------------------------

   procedure Test_Resolved_Through_Source is
      Generated : Adi.CSS_Source.Style_Source;
      Parsed    : Adi.CSS_Source.Style_Source;
      Gen_W     : constant Box_Handle := Create_Handle;
      Par_W     : constant Box_Handle := Create_Handle;
      OK        : Boolean := False;
   begin
      Section ("a bound widget resolves alike from either pipeline");

      Flat_Values_Styles.Register_Selectors (Generated);
      Adi.CSS_Source.Set_Mode (Generated, Adi.CSS_Source.Static_Mode, OK);
      Assert (OK, "generated stylesheet should install");

      Adi.CSS_Source.Add_Dynamic_File (Parsed, Corpus_Path, OK);
      Assert (OK, "corpus file should load into a dynamic source");
      Adi.CSS_Source.Set_Mode (Parsed, Adi.CSS_Source.Dynamic_Mode, OK);
      Assert (OK, "parsed stylesheet should install");

      Adi.CSS_Source.Bind_Class (Generated, "flat-list", +Gen_W);
      Adi.CSS_Source.Bind_Class (Parsed, "flat-list", +Par_W);

      declare
         G : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Gen_W, Main_Part);
         P : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Main_Part);
      begin
         Assert (G.List_Style_Type = P.List_Style_Type,
                 "base: the resolved marker string agrees");
         Assert (G.List_Style_Image = P.List_Style_Image,
                 "base: the resolved marker image agrees");
      end;

      Set_Hovered (+Gen_W);
      Set_Hovered (+Par_W);

      declare
         G : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Gen_W, Main_Part);
         P : constant Resolved_Style :=
           Get_Resolved_Part_Style (+Par_W, Main_Part);
      begin
         Assert (G.List_Style_Type = P.List_Style_Type,
                 "hover: the resolved marker string agrees");
         Assert (G.List_Style_Image = P.List_Style_Image,
                 "hover: the resolved marker image agrees");
         Assert (G.List_Style_Type.Kind = List_Style_Square,
                 "hover: the marker resolves to a square");
      end;
   end Test_Resolved_Through_Source;

begin
   Start_Suite ("Style flat values test");

   Test_Finalization;
   Report_Sizes;
   Test_Text_Bounds;
   Test_Parser_Drops_Over_Long;
   Test_Pipeline_Agreement;
   Test_Resolved_Through_Source;

   Finish;
end Style_Flat_Values_Test;
