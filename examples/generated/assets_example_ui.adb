--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Assets;
with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Image; use Adi.Widget.Image;
with Adi.Widget.Label; use Adi.Widget.Label;
with Assets_Example_Styles;

package body Assets_Example_UI is

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
      Result := Merge_Metadata (Result, Assets_Example_Styles.Root_Metadata);
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
        Adi.Window.Create_Window_Handle ("Assets Example", Adi.Window.Extent (Px (686.0), Px (713.0)));
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("SVG Sprites (?id=)");
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_1 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("home");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_2 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("star");
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_3 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("heart");
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_4 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("settings");
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_5 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("search");
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_6 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("bell");
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Raster Crop (?x=;y=;w=;h=)");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_7 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Top-Left");
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_8 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Top-Right");
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_9 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Bottom-Left");
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_10 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Bottom-Right");
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Scale Modes (?render=)");
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_11 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("linear");
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_12 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("nearest");
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Image_13 : constant Adi.Widget.Image.Image_Handle := Adi.Widget.Image.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("pixelated");
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Labels with Icons (icon= attribute)");
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Home");
      Label_19 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Search");
      Label_20 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Settings");
      Label_21 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Alerts");
   begin
      --  Configure properties
      Adi.Widget.Image.Set_Image (Image_1, Adi.Assets.Get_Image ("icons.svg?id=home"));
      Adi.Widget.Image.Set_Image (Image_2, Adi.Assets.Get_Image ("icons.svg?id=star"));
      Adi.Widget.Image.Set_Image (Image_3, Adi.Assets.Get_Image ("icons.svg?id=heart"));
      Adi.Widget.Image.Set_Image (Image_4, Adi.Assets.Get_Image ("icons.svg?id=settings"));
      Adi.Widget.Image.Set_Image (Image_5, Adi.Assets.Get_Image ("icons.svg?id=search"));
      Adi.Widget.Image.Set_Image (Image_6, Adi.Assets.Get_Image ("icons.svg?id=bell"));
      Adi.Widget.Image.Set_Image (Image_7, Adi.Assets.Get_Image ("happycat.png?x=0;y=0;w=64;h=52"));
      Adi.Widget.Image.Set_Image (Image_8, Adi.Assets.Get_Image ("happycat.png?x=64;y=0;w=64;h=52"));
      Adi.Widget.Image.Set_Image (Image_9, Adi.Assets.Get_Image ("happycat.png?x=0;y=52;w=64;h=53"));
      Adi.Widget.Image.Set_Image (Image_10, Adi.Assets.Get_Image ("happycat.png?x=64;y=52;w=64;h=53"));
      Adi.Widget.Image.Set_Image (Image_11, Adi.Assets.Get_Image ("happycat.png?render=linear"));
      Adi.Widget.Image.Set_Image (Image_12, Adi.Assets.Get_Image ("happycat.png?render=nearest"));
      Adi.Widget.Image.Set_Image (Image_13, Adi.Assets.Get_Image ("happycat.png?render=pixelated"));
      Adi.Widget.Label.Set_Icon (Label_18, Adi.Assets.Get_Image ("icons.svg?id=home"));
      Adi.Widget.Label.Set_Icon (Label_19, Adi.Assets.Get_Image ("icons.svg?id=search"));
      Adi.Widget.Label.Set_Icon (Label_20, Adi.Assets.Get_Image ("icons.svg?id=settings"));
      Adi.Widget.Label.Set_Icon (Label_21, Adi.Assets.Get_Image ("icons.svg?id=bell"));

      --  Install the stylesheets as one batch: precompiled
      --  styles as static fallback, then dynamic CSS and the mode
      declare
         Update : Adi.CSS_Source.Update_Scope (Source'Access);
         pragma Unreferenced (Update);
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Static_Entries (Source);
         Assets_Example_Styles.Register_Selectors (Source);
         Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

         Adi.CSS_Source.Clear_Dynamic_Entries (Source);
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/assets_example.css", Loaded);
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
         W          => +Label_1,
         Tag_Name   => "label",
         Class_Name => "section-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_2,
         Tag_Name   => "box",
         Class_Name => "sprite-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_1,
         Tag_Name   => "image",
         Class_Name => "sprite-icon tint-blue");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_2,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_2,
         Tag_Name   => "image",
         Class_Name => "sprite-icon tint-amber");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_3,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_3,
         Tag_Name   => "image",
         Class_Name => "sprite-icon tint-red");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_4,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_4,
         Tag_Name   => "image",
         Class_Name => "sprite-icon tint-purple");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_5,
         Tag_Name   => "image",
         Class_Name => "sprite-icon tint-green");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_6,
         Tag_Name   => "image",
         Class_Name => "sprite-icon tint-cyan");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_7,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_8,
         Tag_Name   => "label",
         Class_Name => "section-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "crop-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_7,
         Tag_Name   => "image",
         Class_Name => "crop-img");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_8,
         Tag_Name   => "image",
         Class_Name => "crop-img");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_9,
         Tag_Name   => "image",
         Class_Name => "crop-img");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_10,
         Tag_Name   => "image",
         Class_Name => "crop-img");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "section-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "scale-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_11,
         Tag_Name   => "image",
         Class_Name => "scale-img");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_14,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_12,
         Tag_Name   => "image",
         Class_Name => "scale-img");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_15,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_17,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Image_13,
         Tag_Name   => "image",
         Class_Name => "scale-img");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_17,
         Tag_Name   => "label",
         Class_Name => "section-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_18,
         Tag_Name   => "box",
         Class_Name => "nav-bar");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_18,
         Tag_Name   => "label",
         Class_Name => "nav-item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_19,
         Tag_Name   => "label",
         Class_Name => "nav-item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_20,
         Tag_Name   => "label",
         Class_Name => "nav-item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_21,
         Tag_Name   => "label",
         Class_Name => "nav-item");

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_3, +Image_1);
      Adi.Widget.Add_Child (+Box_3, +Label_2);
      Adi.Widget.Add_Child (+Box_4, +Image_2);
      Adi.Widget.Add_Child (+Box_4, +Label_3);
      Adi.Widget.Add_Child (+Box_5, +Image_3);
      Adi.Widget.Add_Child (+Box_5, +Label_4);
      Adi.Widget.Add_Child (+Box_6, +Image_4);
      Adi.Widget.Add_Child (+Box_6, +Label_5);
      Adi.Widget.Add_Child (+Box_7, +Image_5);
      Adi.Widget.Add_Child (+Box_7, +Label_6);
      Adi.Widget.Add_Child (+Box_8, +Image_6);
      Adi.Widget.Add_Child (+Box_8, +Label_7);
      Adi.Widget.Add_Child (+Box_2, +Box_3);
      Adi.Widget.Add_Child (+Box_2, +Box_4);
      Adi.Widget.Add_Child (+Box_2, +Box_5);
      Adi.Widget.Add_Child (+Box_2, +Box_6);
      Adi.Widget.Add_Child (+Box_2, +Box_7);
      Adi.Widget.Add_Child (+Box_2, +Box_8);
      Adi.Widget.Add_Child (+Box_10, +Image_7);
      Adi.Widget.Add_Child (+Box_10, +Label_9);
      Adi.Widget.Add_Child (+Box_11, +Image_8);
      Adi.Widget.Add_Child (+Box_11, +Label_10);
      Adi.Widget.Add_Child (+Box_12, +Image_9);
      Adi.Widget.Add_Child (+Box_12, +Label_11);
      Adi.Widget.Add_Child (+Box_13, +Image_10);
      Adi.Widget.Add_Child (+Box_13, +Label_12);
      Adi.Widget.Add_Child (+Box_9, +Box_10);
      Adi.Widget.Add_Child (+Box_9, +Box_11);
      Adi.Widget.Add_Child (+Box_9, +Box_12);
      Adi.Widget.Add_Child (+Box_9, +Box_13);
      Adi.Widget.Add_Child (+Box_15, +Image_11);
      Adi.Widget.Add_Child (+Box_15, +Label_14);
      Adi.Widget.Add_Child (+Box_16, +Image_12);
      Adi.Widget.Add_Child (+Box_16, +Label_15);
      Adi.Widget.Add_Child (+Box_17, +Image_13);
      Adi.Widget.Add_Child (+Box_17, +Label_16);
      Adi.Widget.Add_Child (+Box_14, +Box_15);
      Adi.Widget.Add_Child (+Box_14, +Box_16);
      Adi.Widget.Add_Child (+Box_14, +Box_17);
      Adi.Widget.Add_Child (+Box_18, +Label_18);
      Adi.Widget.Add_Child (+Box_18, +Label_19);
      Adi.Widget.Add_Child (+Box_18, +Label_20);
      Adi.Widget.Add_Child (+Box_18, +Label_21);
      Adi.Widget.Add_Child (+Box_1, +Label_1);
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_1, +Label_8);
      Adi.Widget.Add_Child (+Box_1, +Box_9);
      Adi.Widget.Add_Child (+Box_1, +Label_13);
      Adi.Widget.Add_Child (+Box_1, +Box_14);
      Adi.Widget.Add_Child (+Box_1, +Label_17);
      Adi.Widget.Add_Child (+Box_1, +Box_18);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Box_1);
      return W;
   end Build;

   end Instance;

end Assets_Example_UI;
