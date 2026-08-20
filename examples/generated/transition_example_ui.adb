--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Label; use Adi.Widget.Label;
with Transition_Example_Styles;

package body Transition_Example_UI is

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
      Result := Merge_Metadata (Result, Transition_Example_Styles.Root_Metadata);
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
        Adi.Window.Create_Window_Handle ("Transition Examples", Adi.Window.Extent (Px (617.0), Px (480.0)));
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("EASING CURVES");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_1 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Linear");
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Constant speed");
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_2 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Ease In");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Slow start");
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_3 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Ease Out");
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Fast start");
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_4 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Ease In Out");
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Smooth both");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("INDIVIDUAL PROPERTIES");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_5 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Background");
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Prop_Background_Color");
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_6 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Border Color");
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Prop_Border_Color");
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_7 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Radius");
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Prop_Border_Radius");
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_8 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Shadow");
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Prop_Box_Shadow");
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_9 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Opacity");
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Prop_Opacity");
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("COMBINED & DURATION");
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_10 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Multi-Property");
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("bg + border + shadow");
      Box_19 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_11 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Everything");
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("no list: every property");
      Box_20 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_12 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Fast (50ms)");
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("50ms linear");
      Box_21 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Button_13 : constant Adi.Widget.Button.Button_Handle := Adi.Widget.Button.Create_Handle ("Slow (800ms)");
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("800ms ease-in-out");
   begin
      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Transition_Example_Styles.Register_Selectors (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Dynamic_Entries (Source);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/transition_example.css", Loaded);
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
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Box_1);
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_1,
         Tag_Name   => "box",
         Class_Name => "root");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_2,
         Tag_Name   => "box",
         Class_Name => "content");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_1,
         Tag_Name   => "label",
         Class_Name => "title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "section-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_1,
         Tag_Name   => "button",
         Class_Name => "demo-base t-linear");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_2,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_2,
         Tag_Name   => "button",
         Class_Name => "demo-base t-ease-in");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_3,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_3,
         Tag_Name   => "button",
         Class_Name => "demo-base t-ease-out");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_4,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_4,
         Tag_Name   => "button",
         Class_Name => "demo-base t-ease-io");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "section-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_5,
         Tag_Name   => "button",
         Class_Name => "demo-base t-bg");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_7,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_6,
         Tag_Name   => "button",
         Class_Name => "demo-base t-border");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_8,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_7,
         Tag_Name   => "button",
         Class_Name => "demo-base t-radius");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_8,
         Tag_Name   => "button",
         Class_Name => "demo-base t-shadow");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_9,
         Tag_Name   => "button",
         Class_Name => "demo-base t-opacity");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_17,
         Tag_Name   => "box",
         Class_Name => "section-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_18,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_10,
         Tag_Name   => "button",
         Class_Name => "demo-base t-multi");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_19,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_11,
         Tag_Name   => "button",
         Class_Name => "demo-base t-everything");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_14,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_20,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_12,
         Tag_Name   => "button",
         Class_Name => "demo-base t-fast");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_15,
         Tag_Name   => "label",
         Class_Name => "desc");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_21,
         Tag_Name   => "box",
         Class_Name => "col-style");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Button_13,
         Tag_Name   => "button",
         Class_Name => "demo-base t-slow");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "desc");

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_5, +Button_1);
      Adi.Widget.Add_Child (+Box_5, +Label_2);
      Adi.Widget.Add_Child (+Box_6, +Button_2);
      Adi.Widget.Add_Child (+Box_6, +Label_3);
      Adi.Widget.Add_Child (+Box_7, +Button_3);
      Adi.Widget.Add_Child (+Box_7, +Label_4);
      Adi.Widget.Add_Child (+Box_8, +Button_4);
      Adi.Widget.Add_Child (+Box_8, +Label_5);
      Adi.Widget.Add_Child (+Box_4, +Box_5);
      Adi.Widget.Add_Child (+Box_4, +Box_6);
      Adi.Widget.Add_Child (+Box_4, +Box_7);
      Adi.Widget.Add_Child (+Box_4, +Box_8);
      Adi.Widget.Add_Child (+Box_3, +Label_1);
      Adi.Widget.Add_Child (+Box_3, +Box_4);
      Adi.Widget.Add_Child (+Box_11, +Button_5);
      Adi.Widget.Add_Child (+Box_11, +Label_7);
      Adi.Widget.Add_Child (+Box_12, +Button_6);
      Adi.Widget.Add_Child (+Box_12, +Label_8);
      Adi.Widget.Add_Child (+Box_13, +Button_7);
      Adi.Widget.Add_Child (+Box_13, +Label_9);
      Adi.Widget.Add_Child (+Box_14, +Button_8);
      Adi.Widget.Add_Child (+Box_14, +Label_10);
      Adi.Widget.Add_Child (+Box_15, +Button_9);
      Adi.Widget.Add_Child (+Box_15, +Label_11);
      Adi.Widget.Add_Child (+Box_10, +Box_11);
      Adi.Widget.Add_Child (+Box_10, +Box_12);
      Adi.Widget.Add_Child (+Box_10, +Box_13);
      Adi.Widget.Add_Child (+Box_10, +Box_14);
      Adi.Widget.Add_Child (+Box_10, +Box_15);
      Adi.Widget.Add_Child (+Box_9, +Label_6);
      Adi.Widget.Add_Child (+Box_9, +Box_10);
      Adi.Widget.Add_Child (+Box_18, +Button_10);
      Adi.Widget.Add_Child (+Box_18, +Label_13);
      Adi.Widget.Add_Child (+Box_19, +Button_11);
      Adi.Widget.Add_Child (+Box_19, +Label_14);
      Adi.Widget.Add_Child (+Box_20, +Button_12);
      Adi.Widget.Add_Child (+Box_20, +Label_15);
      Adi.Widget.Add_Child (+Box_21, +Button_13);
      Adi.Widget.Add_Child (+Box_21, +Label_16);
      Adi.Widget.Add_Child (+Box_17, +Box_18);
      Adi.Widget.Add_Child (+Box_17, +Box_19);
      Adi.Widget.Add_Child (+Box_17, +Box_20);
      Adi.Widget.Add_Child (+Box_17, +Box_21);
      Adi.Widget.Add_Child (+Box_16, +Label_12);
      Adi.Widget.Add_Child (+Box_16, +Box_17);
      Adi.Widget.Add_Child (+Box_2, +Box_3);
      Adi.Widget.Add_Child (+Box_2, +Box_9);
      Adi.Widget.Add_Child (+Box_2, +Box_16);
      Adi.Widget.Add_Child (+Box_1, +Box_2);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Box_1);
      return W;
   end Build;

   end Instance;

end Transition_Example_UI;
