--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Demo_Block_Styles;

package body Demo_Block_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;

   function Merge_Metadata
     (Base, Override : Adi.CSS_Parser.Stylesheet_Metadata)
      return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := Base;
   begin
      if Override.Has_Root_Style then
         if Result.Has_Root_Style then
            Result.Root_Styles :=
              Merge_Part_Styles (Result.Root_Styles, Override.Root_Styles);
         else
            Result.Root_Styles := Override.Root_Styles;
            Result.Has_Root_Style := True;
         end if;
      end if;
      if Override.Has_Root_Font_Size then
         Result.Has_Root_Font_Size := True;
         Result.Root_Font_Size := Override.Root_Font_Size;
      end if;
      return Result;
   end Merge_Metadata;

   function Static_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := (others => <>);
   begin
      Result := Merge_Metadata (Result, Demo_Block_Styles.Root_Metadata);
      return Result;
   end Static_Root_Metadata;

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Reloaded := False;
      Success := True;
      declare
         Local_Reloaded : Boolean := False;
         Local_Success  : Boolean := True;
      begin
         Adi.CSS_Source.Tick (Source, Local_Reloaded, Local_Success);
         Reloaded := Reloaded or Local_Reloaded;
         Success := Success and Local_Success;
      end;
   end Tick_Styles;

   procedure Tick_Styles_CB (DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded, Success : Boolean;
   begin
      Tick_Styles (Reloaded, Success);
   end Tick_Styles_CB;

   procedure Set_CSS_File (Path : String; Success : out Boolean) is
      Mode_OK : Boolean;
   begin
      Adi.CSS_Source.Clear_Dynamic_Entries (Source);
      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);
      if Success then
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         Adi.CSS_Source.Set_Auto_Reload (Source, True);
         Success := Mode_OK;
      end if;
   end Set_CSS_File;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Block Layout Reference", Adi.Window.Extent (Px (617.0), Px (617.0)));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Block Layout Reference");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("What a box does by default");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Block is what a box does when nothing asks otherwise: children stack down the content area in order, each spanning it for want of a width of its own. No rule on this box declares display.");
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A declared width is honoured");
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A child is laid out at the width it declares, in pixels or as a fraction of the container's content area. Declaring none spans that area instead, and max-width caps whichever of the two applies. What is left over stays to the right: block centring is margin: auto, which Adi has no value for.");
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("The last three are the two edges of the box. A margin sits outside the width, so it comes off an automatic one and only moves a declared one along. Padding sits inside it, so both of the bottom pair are the same box with the text starting further in.");
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("no width");
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("width: 120px");
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("width: 45%");
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("max-width: 160px");
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("margin-left: 48px");
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("same margin, width: 280px");
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("same width, padding-left: 48px");
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A declared height is honoured");
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("The height a child declares is taken the same way its width is. A child that declares none gets its content's height, which for a box with nothing in it is the next section.");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("height: 20px");
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("height: 34px");
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("height: 48px");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_19 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A child with nothing in it takes no height");
      Label_20 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("The right-hand box carries two extra children between its bars, each with height: auto and nothing inside. An empty child measures nothing and is never stretched to fill, so the two boxes are indistinguishable.");
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_21 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("two bars");
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_22 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("two bars, two empty children");
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_19 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_20 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_21 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_22 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_23 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A percentage height");
      Label_24 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A percentage resolves against the container's content box, not against whatever height the child came in with, so it holds on every pass. These three take all of it, half of it and a quarter of it.");
      Box_23 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_24 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_25 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("height: 100%");
      Box_25 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_26 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_27 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_26 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("height: 50%");
      Box_28 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_29 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_30 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_27 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("height: 25%");
      Box_31 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_32 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_33 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_28 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Block and flex");
      Label_29 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("The same three children, once under a box that declares nothing and once under display: flex. Both give each child the width it asks for; block stacks them down the content area while flex ranges them along a row and divides what is left over. demo_flex is the reference for what flex does from there.");
      Box_34 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_35 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_30 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("no display");
      Box_36 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_37 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_38 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_39 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_40 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_31 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("display: flex");
      Box_41 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_42 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_43 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_44 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;

      --  Install the stylesheets as one batch: precompiled
      --  styles as static fallback, then dynamic CSS and the mode
      declare
         Update : Adi.CSS_Source.Update_Scope (Source'Access);
         pragma Unreferenced (Update);
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Static_Entries (Source);
         Demo_Block_Styles.Register_Selectors (Source);
         Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

         Adi.CSS_Source.Clear_Dynamic_Entries (Source);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/demo_block.css", Loaded);
         if Loaded then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         else
            Mode_OK := False;
         end if;
         if not Mode_OK then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
         end if;
      end;

      Adi.CSS_Source.Attach_Window (Source, W);
      --  Bind every widget under the selectors naming it
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Root);
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Root,
         Tag_Name   => "box",
         Class_Name => "root",
         Id_Name    => "Root");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_1,
         Tag_Name   => "label",
         Class_Name => "title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_1,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_2,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_3,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_2,
         Tag_Name   => "box",
         Class_Name => "demo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_4,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "demo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_7,
         Tag_Name   => "label",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_8,
         Tag_Name   => "label",
         Class_Name => "bar w120");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "bar w45");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "bar wcap");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "bar indent");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "bar w280 indent");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "bar w280 inset");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_14,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_15,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "demo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "bar h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_17,
         Tag_Name   => "label",
         Class_Name => "bar h34");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_18,
         Tag_Name   => "label",
         Class_Name => "bar h48");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_19,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_20,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_21,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "demo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_22,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_17,
         Tag_Name   => "box",
         Class_Name => "demo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_18,
         Tag_Name   => "box",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_19,
         Tag_Name   => "box",
         Class_Name => "ghost");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_20,
         Tag_Name   => "box",
         Class_Name => "ghost");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_21,
         Tag_Name   => "box",
         Class_Name => "bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_22,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_23,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_24,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_23,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_24,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_25,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_25,
         Tag_Name   => "box",
         Class_Name => "demo frame");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_26,
         Tag_Name   => "box",
         Class_Name => "bar fill");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_27,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_26,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_28,
         Tag_Name   => "box",
         Class_Name => "demo frame");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_29,
         Tag_Name   => "box",
         Class_Name => "bar half");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_30,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_27,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_31,
         Tag_Name   => "box",
         Class_Name => "demo frame");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_32,
         Tag_Name   => "box",
         Class_Name => "bar quarter");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_33,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_28,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_29,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_34,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_35,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_30,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_36,
         Tag_Name   => "box",
         Class_Name => "demo");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_37,
         Tag_Name   => "box",
         Class_Name => "chip chip-1");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_38,
         Tag_Name   => "box",
         Class_Name => "chip chip-2");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_39,
         Tag_Name   => "box",
         Class_Name => "chip chip-3");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_40,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_31,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_41,
         Tag_Name   => "box",
         Class_Name => "demo flex-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_42,
         Tag_Name   => "box",
         Class_Name => "chip chip-1");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_43,
         Tag_Name   => "box",
         Class_Name => "chip chip-2");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_44,
         Tag_Name   => "box",
         Class_Name => "chip chip-3");

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_2, +Box_3);
      Adi.Widget.Add_Child (+Box_2, +Box_4);
      Adi.Widget.Add_Child (+Box_2, +Box_5);
      Adi.Widget.Add_Child (+Box_1, +Label_2);
      Adi.Widget.Add_Child (+Box_1, +Label_3);
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_7, +Label_7);
      Adi.Widget.Add_Child (+Box_7, +Label_8);
      Adi.Widget.Add_Child (+Box_7, +Label_9);
      Adi.Widget.Add_Child (+Box_7, +Label_10);
      Adi.Widget.Add_Child (+Box_7, +Label_11);
      Adi.Widget.Add_Child (+Box_7, +Label_12);
      Adi.Widget.Add_Child (+Box_7, +Label_13);
      Adi.Widget.Add_Child (+Box_6, +Label_4);
      Adi.Widget.Add_Child (+Box_6, +Label_5);
      Adi.Widget.Add_Child (+Box_6, +Label_6);
      Adi.Widget.Add_Child (+Box_6, +Box_7);
      Adi.Widget.Add_Child (+Box_9, +Label_16);
      Adi.Widget.Add_Child (+Box_9, +Label_17);
      Adi.Widget.Add_Child (+Box_9, +Label_18);
      Adi.Widget.Add_Child (+Box_8, +Label_14);
      Adi.Widget.Add_Child (+Box_8, +Label_15);
      Adi.Widget.Add_Child (+Box_8, +Box_9);
      Adi.Widget.Add_Child (+Box_13, +Box_14);
      Adi.Widget.Add_Child (+Box_13, +Box_15);
      Adi.Widget.Add_Child (+Box_12, +Label_21);
      Adi.Widget.Add_Child (+Box_12, +Box_13);
      Adi.Widget.Add_Child (+Box_17, +Box_18);
      Adi.Widget.Add_Child (+Box_17, +Box_19);
      Adi.Widget.Add_Child (+Box_17, +Box_20);
      Adi.Widget.Add_Child (+Box_17, +Box_21);
      Adi.Widget.Add_Child (+Box_16, +Label_22);
      Adi.Widget.Add_Child (+Box_16, +Box_17);
      Adi.Widget.Add_Child (+Box_11, +Box_12);
      Adi.Widget.Add_Child (+Box_11, +Box_16);
      Adi.Widget.Add_Child (+Box_10, +Label_19);
      Adi.Widget.Add_Child (+Box_10, +Label_20);
      Adi.Widget.Add_Child (+Box_10, +Box_11);
      Adi.Widget.Add_Child (+Box_25, +Box_26);
      Adi.Widget.Add_Child (+Box_24, +Label_25);
      Adi.Widget.Add_Child (+Box_24, +Box_25);
      Adi.Widget.Add_Child (+Box_28, +Box_29);
      Adi.Widget.Add_Child (+Box_27, +Label_26);
      Adi.Widget.Add_Child (+Box_27, +Box_28);
      Adi.Widget.Add_Child (+Box_31, +Box_32);
      Adi.Widget.Add_Child (+Box_30, +Label_27);
      Adi.Widget.Add_Child (+Box_30, +Box_31);
      Adi.Widget.Add_Child (+Box_23, +Box_24);
      Adi.Widget.Add_Child (+Box_23, +Box_27);
      Adi.Widget.Add_Child (+Box_23, +Box_30);
      Adi.Widget.Add_Child (+Box_22, +Label_23);
      Adi.Widget.Add_Child (+Box_22, +Label_24);
      Adi.Widget.Add_Child (+Box_22, +Box_23);
      Adi.Widget.Add_Child (+Box_36, +Box_37);
      Adi.Widget.Add_Child (+Box_36, +Box_38);
      Adi.Widget.Add_Child (+Box_36, +Box_39);
      Adi.Widget.Add_Child (+Box_35, +Label_30);
      Adi.Widget.Add_Child (+Box_35, +Box_36);
      Adi.Widget.Add_Child (+Box_41, +Box_42);
      Adi.Widget.Add_Child (+Box_41, +Box_43);
      Adi.Widget.Add_Child (+Box_41, +Box_44);
      Adi.Widget.Add_Child (+Box_40, +Label_31);
      Adi.Widget.Add_Child (+Box_40, +Box_41);
      Adi.Widget.Add_Child (+Box_34, +Box_35);
      Adi.Widget.Add_Child (+Box_34, +Box_40);
      Adi.Widget.Add_Child (+Box_33, +Label_28);
      Adi.Widget.Add_Child (+Box_33, +Label_29);
      Adi.Widget.Add_Child (+Box_33, +Box_34);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Box_6);
      Adi.Widget.Add_Child (+Root, +Box_8);
      Adi.Widget.Add_Child (+Root, +Box_10);
      Adi.Widget.Add_Child (+Root, +Box_22);
      Adi.Widget.Add_Child (+Root, +Box_33);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Demo_Block_UI;
