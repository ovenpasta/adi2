--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Gradient_Example_Styles;

package body Gradient_Example_UI is

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
      Result := Merge_Metadata (Result, Gradient_Example_Styles.Root_Metadata);
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
        Adi.Window.Create_Window_Handle ("Gradient Showcase", Adi.Window.Extent (Px (658.0), Px (617.0)));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Linear Gradient Showcase");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_19 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_20 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_21 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_22 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_23 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_24 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_25 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_26 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_27 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_28 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;

      --  Configure properties
      Adi.Widget.Set_Label (+Box_2, "to bottom");
      Adi.Widget.Set_Label (+Box_3, "to right");
      Adi.Widget.Set_Label (+Box_4, "default angle");
      Adi.Widget.Set_Label (+Box_6, "to top");
      Adi.Widget.Set_Label (+Box_7, "to left");
      Adi.Widget.Set_Label (+Box_8, "to bottom right");
      Adi.Widget.Set_Label (+Box_10, "to top right");
      Adi.Widget.Set_Label (+Box_11, "to bottom left");
      Adi.Widget.Set_Label (+Box_12, "to top left");
      Adi.Widget.Set_Label (+Box_14, "45deg");
      Adi.Widget.Set_Label (+Box_15, "135deg");
      Adi.Widget.Set_Label (+Box_16, "0.25turn");
      Adi.Widget.Set_Label (+Box_18, "1.5708rad");
      Adi.Widget.Set_Label (+Box_19, "150grad");
      Adi.Widget.Set_Label (+Box_20, "alpha over bg-color");
      Adi.Widget.Set_Label (+Box_22, "3 stops, auto (flat)");
      Adi.Widget.Set_Label (+Box_23, "0/30/100% stops");
      Adi.Widget.Set_Label (+Box_24, "20/80% edge bands");
      Adi.Widget.Set_Label (+Box_26, "16 stops (flat)");
      Adi.Widget.Set_Label (+Box_27, "pill radius 50px");
      Adi.Widget.Set_Label (+Box_28, "4px border");

      --  Set labels
      Adi.Widget.Set_Label (+Box_2, "to bottom");
      Adi.Widget.Set_Label (+Box_3, "to right");
      Adi.Widget.Set_Label (+Box_4, "default angle");
      Adi.Widget.Set_Label (+Box_6, "to top");
      Adi.Widget.Set_Label (+Box_7, "to left");
      Adi.Widget.Set_Label (+Box_8, "to bottom right");
      Adi.Widget.Set_Label (+Box_10, "to top right");
      Adi.Widget.Set_Label (+Box_11, "to bottom left");
      Adi.Widget.Set_Label (+Box_12, "to top left");
      Adi.Widget.Set_Label (+Box_14, "45deg");
      Adi.Widget.Set_Label (+Box_15, "135deg");
      Adi.Widget.Set_Label (+Box_16, "0.25turn");
      Adi.Widget.Set_Label (+Box_18, "1.5708rad");
      Adi.Widget.Set_Label (+Box_19, "150grad");
      Adi.Widget.Set_Label (+Box_20, "alpha over bg-color");
      Adi.Widget.Set_Label (+Box_22, "3 stops, auto (flat)");
      Adi.Widget.Set_Label (+Box_23, "0/30/100% stops");
      Adi.Widget.Set_Label (+Box_24, "20/80% edge bands");
      Adi.Widget.Set_Label (+Box_26, "16 stops (flat)");
      Adi.Widget.Set_Label (+Box_27, "pill radius 50px");
      Adi.Widget.Set_Label (+Box_28, "4px border");

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Gradient_Example_Styles.Register_Selectors (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Dynamic_Entries (Source);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/gradient_example.css", Loaded);
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
         Class_Name => "row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_2,
         Tag_Name   => "box",
         Class_Name => "grad-v grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "grad-h grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "grad-default grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "grad-up grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "grad-left grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "grad-diag grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "grad-diag-tr grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "grad-diag-bl grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "grad-diag-rev grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "grad-45 grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "grad-135 grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "grad-turn grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_17,
         Tag_Name   => "box",
         Class_Name => "row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_18,
         Tag_Name   => "box",
         Class_Name => "grad-rad grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_19,
         Tag_Name   => "box",
         Class_Name => "grad-grad grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_20,
         Tag_Name   => "box",
         Class_Name => "grad-alpha grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_21,
         Tag_Name   => "box",
         Class_Name => "row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_22,
         Tag_Name   => "box",
         Class_Name => "grad-3stop grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_23,
         Tag_Name   => "box",
         Class_Name => "grad-pos grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_24,
         Tag_Name   => "box",
         Class_Name => "grad-edge grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_25,
         Tag_Name   => "box",
         Class_Name => "row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_26,
         Tag_Name   => "box",
         Class_Name => "grad-16stop grad-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_27,
         Tag_Name   => "box",
         Class_Name => "grad-card grad-pill");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_28,
         Tag_Name   => "box",
         Class_Name => "grad-border grad-card");

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_1, +Box_3);
      Adi.Widget.Add_Child (+Box_1, +Box_4);
      Adi.Widget.Add_Child (+Box_5, +Box_6);
      Adi.Widget.Add_Child (+Box_5, +Box_7);
      Adi.Widget.Add_Child (+Box_5, +Box_8);
      Adi.Widget.Add_Child (+Box_9, +Box_10);
      Adi.Widget.Add_Child (+Box_9, +Box_11);
      Adi.Widget.Add_Child (+Box_9, +Box_12);
      Adi.Widget.Add_Child (+Box_13, +Box_14);
      Adi.Widget.Add_Child (+Box_13, +Box_15);
      Adi.Widget.Add_Child (+Box_13, +Box_16);
      Adi.Widget.Add_Child (+Box_17, +Box_18);
      Adi.Widget.Add_Child (+Box_17, +Box_19);
      Adi.Widget.Add_Child (+Box_17, +Box_20);
      Adi.Widget.Add_Child (+Box_21, +Box_22);
      Adi.Widget.Add_Child (+Box_21, +Box_23);
      Adi.Widget.Add_Child (+Box_21, +Box_24);
      Adi.Widget.Add_Child (+Box_25, +Box_26);
      Adi.Widget.Add_Child (+Box_25, +Box_27);
      Adi.Widget.Add_Child (+Box_25, +Box_28);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Box_5);
      Adi.Widget.Add_Child (+Root, +Box_9);
      Adi.Widget.Add_Child (+Root, +Box_13);
      Adi.Widget.Add_Child (+Root, +Box_17);
      Adi.Widget.Add_Child (+Root, +Box_21);
      Adi.Widget.Add_Child (+Root, +Box_25);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Gradient_Example_UI;
