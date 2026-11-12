--  Auto-generated from XML
--  Do not edit manually

pragma Wide_Character_Encoding (Brackets);
pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Demo_Box_Styles;

package body Demo_Box_UI is

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
              Merge_Part_Styles
                (Result.Root_Styles, Override.Root_Styles);
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
      Result := Merge_Metadata (Result, Demo_Box_Styles.Root_Metadata);
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
      Adi.CSS_Source.Set_Dynamic_Sources
        (Source, [Adi.CSS_Source.CSS_File (Path)], Success);
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
        Adi.Window.Create_Window_Handle ("Box Painting Reference", Adi.Window.Extent (Px (617.0), Px (617.0)));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Box Painting Reference");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Border width, side by side");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A border sits inside the box's size, between its edge and its padding. Each side takes its own width, and a side of width 0 or style none paints nothing.");
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2px all round");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1px 4px 8px 2px");
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("border-left only");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("rounded, bottom none");
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Each edge its own colour");
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("border-top-color and its siblings paint one side each. A rounded corner changes from one side's colour to the next at its midpoint, the way a square corner changes on its diagonal.");
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("square corners");
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_19 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_20 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("rounded corners");
      Box_21 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_22 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_23 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("raised");
      Box_24 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_25 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_26 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("sunken");
      Box_27 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_28 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_29 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Corner radius");
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("border-radius takes one to four lengths, clockwise from the top left. Background, border, outline and shadow all follow the same curve.");
      Box_30 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_31 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("12px");
      Box_32 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_33 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_34 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("20px 4px");
      Box_35 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_36 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_37 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("12px 12px 0 0");
      Box_38 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_39 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_40 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_19 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("pill, thicker bottom");
      Box_41 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_42 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_43 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_20 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Outline");
      Label_21 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("An outline is drawn outside the border and takes no room: nothing around it moves. outline-offset opens a gap between the two.");
      Box_44 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_45 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_22 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2px solid");
      Box_46 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_47 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_48 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_23 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("offset 4px");
      Box_49 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_50 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_51 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_24 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("over a border, rounded");
      Box_52 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_53 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_54 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_25 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Box shadow");
      Label_26 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("box-shadow takes an offset, a blur, a spread and a colour. Like an outline it takes no room, so the stage pads round each box to show it whole.");
      Box_55 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_56 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_27 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("0 4px 10px");
      Box_57 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_58 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_59 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_28 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("6px 6px 0, no blur");
      Box_60 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_61 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_62 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_29 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("0 0 12px 2px, a glow");
      Box_63 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_64 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_65 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_30 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Background");
      Label_31 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("A gradient paints over background-color, so a translucent one shows the colour through. opacity fades the whole box, border and all.");
      Box_66 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_67 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_32 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("linear-gradient");
      Box_68 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_69 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_70 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_33 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("translucent gradient");
      Box_71 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_72 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_73 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_34 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("opacity: 0.5");
      Box_74 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_75 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
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
         Demo_Box_Styles.Register_Selectors (Source);
         Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

         Adi.CSS_Source.Set_Dynamic_Sources
           (Source,
            [Adi.CSS_Source.CSS_File ("css/demo_box.css")],
            Loaded);
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
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_4,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "swatch bw-uniform");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "swatch bw-sides");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "swatch bw-accent");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_7,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "swatch bw-open");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_8,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_17,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_18,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_19,
         Tag_Name   => "box",
         Class_Name => "swatch four-colours");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_20,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_21,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_22,
         Tag_Name   => "box",
         Class_Name => "swatch four-colours rounded");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_23,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_24,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_25,
         Tag_Name   => "box",
         Class_Name => "swatch raised");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_26,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_27,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_28,
         Tag_Name   => "box",
         Class_Name => "swatch sunken");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_29,
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
         W          => +Box_30,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_31,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_32,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_33,
         Tag_Name   => "box",
         Class_Name => "swatch filled r-12");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_34,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_17,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_35,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_36,
         Tag_Name   => "box",
         Class_Name => "swatch filled r-alternate");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_37,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_18,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_38,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_39,
         Tag_Name   => "box",
         Class_Name => "swatch filled r-top");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_40,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_19,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_41,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_42,
         Tag_Name   => "box",
         Class_Name => "swatch r-pill");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_43,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_20,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_21,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_44,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_45,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_22,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_46,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_47,
         Tag_Name   => "box",
         Class_Name => "swatch filled ol-plain");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_48,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_23,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_49,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_50,
         Tag_Name   => "box",
         Class_Name => "swatch filled ol-offset");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_51,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_24,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_52,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_53,
         Tag_Name   => "box",
         Class_Name => "swatch ol-rounded");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_54,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_25,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_26,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_55,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_56,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_27,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_57,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_58,
         Tag_Name   => "box",
         Class_Name => "swatch filled sh-drop");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_59,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_28,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_60,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_61,
         Tag_Name   => "box",
         Class_Name => "swatch filled sh-hard");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_62,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_29,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_63,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_64,
         Tag_Name   => "box",
         Class_Name => "swatch filled sh-glow");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_65,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_30,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_31,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_66,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_67,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_32,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_68,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_69,
         Tag_Name   => "box",
         Class_Name => "swatch bg-gradient");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_70,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_33,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_71,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_72,
         Tag_Name   => "box",
         Class_Name => "swatch bg-over-colour");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_73,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_34,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_74,
         Tag_Name   => "box",
         Class_Name => "stage");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_75,
         Tag_Name   => "box",
         Class_Name => "swatch raised bg-faded");

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_4, +Box_5);
      Adi.Widget.Add_Child (+Box_3, +Label_4);
      Adi.Widget.Add_Child (+Box_3, +Box_4);
      Adi.Widget.Add_Child (+Box_7, +Box_8);
      Adi.Widget.Add_Child (+Box_6, +Label_5);
      Adi.Widget.Add_Child (+Box_6, +Box_7);
      Adi.Widget.Add_Child (+Box_10, +Box_11);
      Adi.Widget.Add_Child (+Box_9, +Label_6);
      Adi.Widget.Add_Child (+Box_9, +Box_10);
      Adi.Widget.Add_Child (+Box_13, +Box_14);
      Adi.Widget.Add_Child (+Box_12, +Label_7);
      Adi.Widget.Add_Child (+Box_12, +Box_13);
      Adi.Widget.Add_Child (+Box_2, +Box_3);
      Adi.Widget.Add_Child (+Box_2, +Box_6);
      Adi.Widget.Add_Child (+Box_2, +Box_9);
      Adi.Widget.Add_Child (+Box_2, +Box_12);
      Adi.Widget.Add_Child (+Box_1, +Label_2);
      Adi.Widget.Add_Child (+Box_1, +Label_3);
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_18, +Box_19);
      Adi.Widget.Add_Child (+Box_17, +Label_10);
      Adi.Widget.Add_Child (+Box_17, +Box_18);
      Adi.Widget.Add_Child (+Box_21, +Box_22);
      Adi.Widget.Add_Child (+Box_20, +Label_11);
      Adi.Widget.Add_Child (+Box_20, +Box_21);
      Adi.Widget.Add_Child (+Box_24, +Box_25);
      Adi.Widget.Add_Child (+Box_23, +Label_12);
      Adi.Widget.Add_Child (+Box_23, +Box_24);
      Adi.Widget.Add_Child (+Box_27, +Box_28);
      Adi.Widget.Add_Child (+Box_26, +Label_13);
      Adi.Widget.Add_Child (+Box_26, +Box_27);
      Adi.Widget.Add_Child (+Box_16, +Box_17);
      Adi.Widget.Add_Child (+Box_16, +Box_20);
      Adi.Widget.Add_Child (+Box_16, +Box_23);
      Adi.Widget.Add_Child (+Box_16, +Box_26);
      Adi.Widget.Add_Child (+Box_15, +Label_8);
      Adi.Widget.Add_Child (+Box_15, +Label_9);
      Adi.Widget.Add_Child (+Box_15, +Box_16);
      Adi.Widget.Add_Child (+Box_32, +Box_33);
      Adi.Widget.Add_Child (+Box_31, +Label_16);
      Adi.Widget.Add_Child (+Box_31, +Box_32);
      Adi.Widget.Add_Child (+Box_35, +Box_36);
      Adi.Widget.Add_Child (+Box_34, +Label_17);
      Adi.Widget.Add_Child (+Box_34, +Box_35);
      Adi.Widget.Add_Child (+Box_38, +Box_39);
      Adi.Widget.Add_Child (+Box_37, +Label_18);
      Adi.Widget.Add_Child (+Box_37, +Box_38);
      Adi.Widget.Add_Child (+Box_41, +Box_42);
      Adi.Widget.Add_Child (+Box_40, +Label_19);
      Adi.Widget.Add_Child (+Box_40, +Box_41);
      Adi.Widget.Add_Child (+Box_30, +Box_31);
      Adi.Widget.Add_Child (+Box_30, +Box_34);
      Adi.Widget.Add_Child (+Box_30, +Box_37);
      Adi.Widget.Add_Child (+Box_30, +Box_40);
      Adi.Widget.Add_Child (+Box_29, +Label_14);
      Adi.Widget.Add_Child (+Box_29, +Label_15);
      Adi.Widget.Add_Child (+Box_29, +Box_30);
      Adi.Widget.Add_Child (+Box_46, +Box_47);
      Adi.Widget.Add_Child (+Box_45, +Label_22);
      Adi.Widget.Add_Child (+Box_45, +Box_46);
      Adi.Widget.Add_Child (+Box_49, +Box_50);
      Adi.Widget.Add_Child (+Box_48, +Label_23);
      Adi.Widget.Add_Child (+Box_48, +Box_49);
      Adi.Widget.Add_Child (+Box_52, +Box_53);
      Adi.Widget.Add_Child (+Box_51, +Label_24);
      Adi.Widget.Add_Child (+Box_51, +Box_52);
      Adi.Widget.Add_Child (+Box_44, +Box_45);
      Adi.Widget.Add_Child (+Box_44, +Box_48);
      Adi.Widget.Add_Child (+Box_44, +Box_51);
      Adi.Widget.Add_Child (+Box_43, +Label_20);
      Adi.Widget.Add_Child (+Box_43, +Label_21);
      Adi.Widget.Add_Child (+Box_43, +Box_44);
      Adi.Widget.Add_Child (+Box_57, +Box_58);
      Adi.Widget.Add_Child (+Box_56, +Label_27);
      Adi.Widget.Add_Child (+Box_56, +Box_57);
      Adi.Widget.Add_Child (+Box_60, +Box_61);
      Adi.Widget.Add_Child (+Box_59, +Label_28);
      Adi.Widget.Add_Child (+Box_59, +Box_60);
      Adi.Widget.Add_Child (+Box_63, +Box_64);
      Adi.Widget.Add_Child (+Box_62, +Label_29);
      Adi.Widget.Add_Child (+Box_62, +Box_63);
      Adi.Widget.Add_Child (+Box_55, +Box_56);
      Adi.Widget.Add_Child (+Box_55, +Box_59);
      Adi.Widget.Add_Child (+Box_55, +Box_62);
      Adi.Widget.Add_Child (+Box_54, +Label_25);
      Adi.Widget.Add_Child (+Box_54, +Label_26);
      Adi.Widget.Add_Child (+Box_54, +Box_55);
      Adi.Widget.Add_Child (+Box_68, +Box_69);
      Adi.Widget.Add_Child (+Box_67, +Label_32);
      Adi.Widget.Add_Child (+Box_67, +Box_68);
      Adi.Widget.Add_Child (+Box_71, +Box_72);
      Adi.Widget.Add_Child (+Box_70, +Label_33);
      Adi.Widget.Add_Child (+Box_70, +Box_71);
      Adi.Widget.Add_Child (+Box_74, +Box_75);
      Adi.Widget.Add_Child (+Box_73, +Label_34);
      Adi.Widget.Add_Child (+Box_73, +Box_74);
      Adi.Widget.Add_Child (+Box_66, +Box_67);
      Adi.Widget.Add_Child (+Box_66, +Box_70);
      Adi.Widget.Add_Child (+Box_66, +Box_73);
      Adi.Widget.Add_Child (+Box_65, +Label_30);
      Adi.Widget.Add_Child (+Box_65, +Label_31);
      Adi.Widget.Add_Child (+Box_65, +Box_66);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Box_15);
      Adi.Widget.Add_Child (+Root, +Box_29);
      Adi.Widget.Add_Child (+Root, +Box_43);
      Adi.Widget.Add_Child (+Root, +Box_54);
      Adi.Widget.Add_Child (+Root, +Box_65);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Demo_Box_UI;
