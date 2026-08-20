--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Grid_Example_Styles;

package body Grid_Example_UI is

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
      Result := Merge_Metadata (Result, Grid_Example_Styles.Root_Metadata);
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
        Adi.Window.Create_Window_Handle ("Grid Layout Reference", Adi.Window.Extent (Px (617.0), Px (617.0)));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Grid Layout Reference");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("grid-template-columns");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Track sizes across the row. repeat(N, size) expands to N tracks of that size.");
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("repeat(3, 1fr)");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("120px 1fr");
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("120px");
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1fr");
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("auto 1fr");
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("auto");
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1fr");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1fr 2fr 1fr");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("mixed track kinds");
      Label_19 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("120px 2fr 0.5fr auto. The px track is fixed, auto takes its content, and what is left is split between the two fr tracks by factor.");
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_20 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("120px");
      Label_21 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2fr");
      Label_22 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("0.5fr");
      Label_23 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("auto");
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_24 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("grid-column and grid-row");
      Label_25 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Four columns, three rows. Items take a start line, a span, or both.");
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_26 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1 / span 2");
      Label_27 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("col 3, 1 / span 2");
      Label_28 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("col 4, row 1");
      Label_29 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("col 1, row 2");
      Label_30 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("col 2, row 2");
      Label_31 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("col 4, row 2");
      Label_32 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("col 1, row 3");
      Label_33 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2 / span 3");
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_34 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("row-gap and column-gap");
      Label_35 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("gap sets both axes; the longhands set one each and leave the other alone.");
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_36 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("gap: 14px");
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_37 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_38 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_39 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_40 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Label_41 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("5");
      Label_42 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("6");
      Box_19 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_43 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("row-gap 20px, col 2px");
      Box_20 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_44 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_45 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_46 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_47 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Label_48 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("5");
      Label_49 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("6");
      Box_21 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_50 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("row-gap 2px, col 20px");
      Box_22 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_51 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_52 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_53 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_54 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Label_55 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("5");
      Label_56 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("6");
      Box_23 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_57 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flexible tracks and their items' minimums");
      Label_58 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Three 1fr tracks in a 300px grid. A bare Nfr is minmax(auto, Nfr), so a track never shrinks below its item's minimum: the first two hold their tracks open and the third takes what is left.");
      Box_24 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_59 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("min 150px");
      Label_60 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("min 90px");
      Label_61 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("rest");
      Box_25 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_62 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("an item that clips does not hold its track open");
      Label_63 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("An item's automatic minimum is the room its content needs. An item that hides its overflow shows that content a piece at a time, so it asks for nothing and its 1fr track keeps its equal share. Same grid, same label, same width: only overflow differs.");
      Box_26 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_27 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_64 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("overflow: visible");
      Box_28 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_65 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("a wide label with no minimum");
      Label_66 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1fr");
      Box_29 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_67 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("overflow: hidden");
      Box_30 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_68 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("a wide label with no minimum");
      Label_69 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1fr");
      Box_31 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_70 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("a grid that scrolls");
      Label_71 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("overflow-y on the grid container itself: rows past the fixed height scroll instead of growing it.");
      Box_32 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_72 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_73 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_74 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_75 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Label_76 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("5");
      Label_77 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("6");
      Label_78 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("7");
      Label_79 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("8");
      Label_80 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("9");
      Label_81 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("10");
      Label_82 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("11");
      Label_83 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("12");
      Label_84 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("13");
      Label_85 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("14");
      Label_86 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("15");
      Label_87 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("16");
      Label_88 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("17");
      Label_89 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("18");
      Label_90 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("19");
      Label_91 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("20");
      Label_92 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("21");
      Label_93 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("22");
      Label_94 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("23");
      Label_95 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("24");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Grid_Example_Styles.Register_Selectors (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Dynamic_Entries (Source);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/grid_example.css", Loaded);
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
         Class_Name => "demo cols-3fr");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_7,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_8,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "demo cols-px-fr");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "cell warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "demo cols-auto");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_14,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "demo cols-weight");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_15,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_17,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_18,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_19,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "demo cols-mixed");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_20,
         Tag_Name   => "label",
         Class_Name => "cell warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_21,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_22,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_23,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_24,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_25,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "demo board");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_26,
         Tag_Name   => "label",
         Class_Name => "cell span-2col");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_27,
         Tag_Name   => "label",
         Class_Name => "cell rose span-2row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_28,
         Tag_Name   => "label",
         Class_Name => "cell at-4-1");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_29,
         Tag_Name   => "label",
         Class_Name => "cell alt at-1-2");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_30,
         Tag_Name   => "label",
         Class_Name => "cell alt at-2-2");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_31,
         Tag_Name   => "label",
         Class_Name => "cell at-4-2");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_32,
         Tag_Name   => "label",
         Class_Name => "cell at-1-3");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_33,
         Tag_Name   => "label",
         Class_Name => "cell warm span-3col");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_34,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_35,
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
         W          => +Label_36,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_18,
         Tag_Name   => "box",
         Class_Name => "demo gap-both");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_37,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_38,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_39,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_40,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_41,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_42,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_19,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_43,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_20,
         Tag_Name   => "box",
         Class_Name => "demo gap-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_44,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_45,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_46,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_47,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_48,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_49,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_21,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_50,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_22,
         Tag_Name   => "box",
         Class_Name => "demo gap-col");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_51,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_52,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_53,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_54,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_55,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_56,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_23,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_57,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_58,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_24,
         Tag_Name   => "box",
         Class_Name => "demo floor-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_59,
         Tag_Name   => "label",
         Class_Name => "cell red floor-wide");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_60,
         Tag_Name   => "label",
         Class_Name => "cell warm floor-medium");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_61,
         Tag_Name   => "label",
         Class_Name => "cell alt floor-rest");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_25,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_62,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_63,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_26,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_27,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_64,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_28,
         Tag_Name   => "box",
         Class_Name => "demo clip-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_65,
         Tag_Name   => "label",
         Class_Name => "cell red wide");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_66,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_29,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_67,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_30,
         Tag_Name   => "box",
         Class_Name => "demo clip-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_68,
         Tag_Name   => "label",
         Class_Name => "cell alt wide clipped");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_69,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_31,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_70,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_71,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_32,
         Tag_Name   => "box",
         Class_Name => "demo scroll-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_72,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_73,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_74,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_75,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_76,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_77,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_78,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_79,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_80,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_81,
         Tag_Name   => "label",
         Class_Name => "cell warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_82,
         Tag_Name   => "label",
         Class_Name => "cell warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_83,
         Tag_Name   => "label",
         Class_Name => "cell warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_84,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_85,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_86,
         Tag_Name   => "label",
         Class_Name => "cell");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_87,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_88,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_89,
         Tag_Name   => "label",
         Class_Name => "cell alt");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_90,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_91,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_92,
         Tag_Name   => "label",
         Class_Name => "cell rose");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_93,
         Tag_Name   => "label",
         Class_Name => "cell warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_94,
         Tag_Name   => "label",
         Class_Name => "cell warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_95,
         Tag_Name   => "label",
         Class_Name => "cell warm");

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_4, +Label_5);
      Adi.Widget.Add_Child (+Box_4, +Label_6);
      Adi.Widget.Add_Child (+Box_4, +Label_7);
      Adi.Widget.Add_Child (+Box_3, +Label_4);
      Adi.Widget.Add_Child (+Box_3, +Box_4);
      Adi.Widget.Add_Child (+Box_6, +Label_9);
      Adi.Widget.Add_Child (+Box_6, +Label_10);
      Adi.Widget.Add_Child (+Box_5, +Label_8);
      Adi.Widget.Add_Child (+Box_5, +Box_6);
      Adi.Widget.Add_Child (+Box_8, +Label_12);
      Adi.Widget.Add_Child (+Box_8, +Label_13);
      Adi.Widget.Add_Child (+Box_7, +Label_11);
      Adi.Widget.Add_Child (+Box_7, +Box_8);
      Adi.Widget.Add_Child (+Box_10, +Label_15);
      Adi.Widget.Add_Child (+Box_10, +Label_16);
      Adi.Widget.Add_Child (+Box_10, +Label_17);
      Adi.Widget.Add_Child (+Box_9, +Label_14);
      Adi.Widget.Add_Child (+Box_9, +Box_10);
      Adi.Widget.Add_Child (+Box_2, +Box_3);
      Adi.Widget.Add_Child (+Box_2, +Box_5);
      Adi.Widget.Add_Child (+Box_2, +Box_7);
      Adi.Widget.Add_Child (+Box_2, +Box_9);
      Adi.Widget.Add_Child (+Box_1, +Label_2);
      Adi.Widget.Add_Child (+Box_1, +Label_3);
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_12, +Label_20);
      Adi.Widget.Add_Child (+Box_12, +Label_21);
      Adi.Widget.Add_Child (+Box_12, +Label_22);
      Adi.Widget.Add_Child (+Box_12, +Label_23);
      Adi.Widget.Add_Child (+Box_11, +Label_18);
      Adi.Widget.Add_Child (+Box_11, +Label_19);
      Adi.Widget.Add_Child (+Box_11, +Box_12);
      Adi.Widget.Add_Child (+Box_14, +Label_26);
      Adi.Widget.Add_Child (+Box_14, +Label_27);
      Adi.Widget.Add_Child (+Box_14, +Label_28);
      Adi.Widget.Add_Child (+Box_14, +Label_29);
      Adi.Widget.Add_Child (+Box_14, +Label_30);
      Adi.Widget.Add_Child (+Box_14, +Label_31);
      Adi.Widget.Add_Child (+Box_14, +Label_32);
      Adi.Widget.Add_Child (+Box_14, +Label_33);
      Adi.Widget.Add_Child (+Box_13, +Label_24);
      Adi.Widget.Add_Child (+Box_13, +Label_25);
      Adi.Widget.Add_Child (+Box_13, +Box_14);
      Adi.Widget.Add_Child (+Box_18, +Label_37);
      Adi.Widget.Add_Child (+Box_18, +Label_38);
      Adi.Widget.Add_Child (+Box_18, +Label_39);
      Adi.Widget.Add_Child (+Box_18, +Label_40);
      Adi.Widget.Add_Child (+Box_18, +Label_41);
      Adi.Widget.Add_Child (+Box_18, +Label_42);
      Adi.Widget.Add_Child (+Box_17, +Label_36);
      Adi.Widget.Add_Child (+Box_17, +Box_18);
      Adi.Widget.Add_Child (+Box_20, +Label_44);
      Adi.Widget.Add_Child (+Box_20, +Label_45);
      Adi.Widget.Add_Child (+Box_20, +Label_46);
      Adi.Widget.Add_Child (+Box_20, +Label_47);
      Adi.Widget.Add_Child (+Box_20, +Label_48);
      Adi.Widget.Add_Child (+Box_20, +Label_49);
      Adi.Widget.Add_Child (+Box_19, +Label_43);
      Adi.Widget.Add_Child (+Box_19, +Box_20);
      Adi.Widget.Add_Child (+Box_22, +Label_51);
      Adi.Widget.Add_Child (+Box_22, +Label_52);
      Adi.Widget.Add_Child (+Box_22, +Label_53);
      Adi.Widget.Add_Child (+Box_22, +Label_54);
      Adi.Widget.Add_Child (+Box_22, +Label_55);
      Adi.Widget.Add_Child (+Box_22, +Label_56);
      Adi.Widget.Add_Child (+Box_21, +Label_50);
      Adi.Widget.Add_Child (+Box_21, +Box_22);
      Adi.Widget.Add_Child (+Box_16, +Box_17);
      Adi.Widget.Add_Child (+Box_16, +Box_19);
      Adi.Widget.Add_Child (+Box_16, +Box_21);
      Adi.Widget.Add_Child (+Box_15, +Label_34);
      Adi.Widget.Add_Child (+Box_15, +Label_35);
      Adi.Widget.Add_Child (+Box_15, +Box_16);
      Adi.Widget.Add_Child (+Box_24, +Label_59);
      Adi.Widget.Add_Child (+Box_24, +Label_60);
      Adi.Widget.Add_Child (+Box_24, +Label_61);
      Adi.Widget.Add_Child (+Box_23, +Label_57);
      Adi.Widget.Add_Child (+Box_23, +Label_58);
      Adi.Widget.Add_Child (+Box_23, +Box_24);
      Adi.Widget.Add_Child (+Box_28, +Label_65);
      Adi.Widget.Add_Child (+Box_28, +Label_66);
      Adi.Widget.Add_Child (+Box_27, +Label_64);
      Adi.Widget.Add_Child (+Box_27, +Box_28);
      Adi.Widget.Add_Child (+Box_30, +Label_68);
      Adi.Widget.Add_Child (+Box_30, +Label_69);
      Adi.Widget.Add_Child (+Box_29, +Label_67);
      Adi.Widget.Add_Child (+Box_29, +Box_30);
      Adi.Widget.Add_Child (+Box_26, +Box_27);
      Adi.Widget.Add_Child (+Box_26, +Box_29);
      Adi.Widget.Add_Child (+Box_25, +Label_62);
      Adi.Widget.Add_Child (+Box_25, +Label_63);
      Adi.Widget.Add_Child (+Box_25, +Box_26);
      Adi.Widget.Add_Child (+Box_32, +Label_72);
      Adi.Widget.Add_Child (+Box_32, +Label_73);
      Adi.Widget.Add_Child (+Box_32, +Label_74);
      Adi.Widget.Add_Child (+Box_32, +Label_75);
      Adi.Widget.Add_Child (+Box_32, +Label_76);
      Adi.Widget.Add_Child (+Box_32, +Label_77);
      Adi.Widget.Add_Child (+Box_32, +Label_78);
      Adi.Widget.Add_Child (+Box_32, +Label_79);
      Adi.Widget.Add_Child (+Box_32, +Label_80);
      Adi.Widget.Add_Child (+Box_32, +Label_81);
      Adi.Widget.Add_Child (+Box_32, +Label_82);
      Adi.Widget.Add_Child (+Box_32, +Label_83);
      Adi.Widget.Add_Child (+Box_32, +Label_84);
      Adi.Widget.Add_Child (+Box_32, +Label_85);
      Adi.Widget.Add_Child (+Box_32, +Label_86);
      Adi.Widget.Add_Child (+Box_32, +Label_87);
      Adi.Widget.Add_Child (+Box_32, +Label_88);
      Adi.Widget.Add_Child (+Box_32, +Label_89);
      Adi.Widget.Add_Child (+Box_32, +Label_90);
      Adi.Widget.Add_Child (+Box_32, +Label_91);
      Adi.Widget.Add_Child (+Box_32, +Label_92);
      Adi.Widget.Add_Child (+Box_32, +Label_93);
      Adi.Widget.Add_Child (+Box_32, +Label_94);
      Adi.Widget.Add_Child (+Box_32, +Label_95);
      Adi.Widget.Add_Child (+Box_31, +Label_70);
      Adi.Widget.Add_Child (+Box_31, +Label_71);
      Adi.Widget.Add_Child (+Box_31, +Box_32);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Box_11);
      Adi.Widget.Add_Child (+Root, +Box_13);
      Adi.Widget.Add_Child (+Root, +Box_15);
      Adi.Widget.Add_Child (+Root, +Box_23);
      Adi.Widget.Add_Child (+Root, +Box_25);
      Adi.Widget.Add_Child (+Root, +Box_31);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Grid_Example_UI;
