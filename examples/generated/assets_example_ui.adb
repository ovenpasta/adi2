--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Assets; use Adi.Assets;
with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Image; use Adi.Widget.Image;
with Adi.Widget.Label; use Adi.Widget.Label;
with Assets_Example_Styles; use Assets_Example_Styles;

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

   procedure Register_Root_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("root", Root_Class_Part_Styles));
   end Register_Root_Styles;

   procedure Register_Section_Title_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("section-title", Section_Title_Class_Part_Styles));
   end Register_Section_Title_Styles;

   procedure Register_Sprite_Grid_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("sprite-grid", Sprite_Grid_Class_Part_Styles));
   end Register_Sprite_Grid_Styles;

   procedure Register_Card_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card", Card_Class_Part_Styles));
   end Register_Card_Styles;

   procedure Register_Sprite_Icon_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("sprite-icon", Sprite_Icon_Class_Part_Styles));
   end Register_Sprite_Icon_Styles;

   procedure Register_Tint_Blue_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-blue", Tint_Blue_Class_Part_Styles));
   end Register_Tint_Blue_Styles;

   procedure Register_Card_Label_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("card-label", Card_Label_Class_Part_Styles));
   end Register_Card_Label_Styles;

   procedure Register_Tint_Amber_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-amber", Tint_Amber_Class_Part_Styles));
   end Register_Tint_Amber_Styles;

   procedure Register_Tint_Red_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-red", Tint_Red_Class_Part_Styles));
   end Register_Tint_Red_Styles;

   procedure Register_Tint_Purple_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-purple", Tint_Purple_Class_Part_Styles));
   end Register_Tint_Purple_Styles;

   procedure Register_Tint_Green_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-green", Tint_Green_Class_Part_Styles));
   end Register_Tint_Green_Styles;

   procedure Register_Tint_Cyan_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tint-cyan", Tint_Cyan_Class_Part_Styles));
   end Register_Tint_Cyan_Styles;

   procedure Register_Crop_Grid_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("crop-grid", Crop_Grid_Class_Part_Styles));
   end Register_Crop_Grid_Styles;

   procedure Register_Crop_Img_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("crop-img", Crop_Img_Class_Part_Styles));
   end Register_Crop_Img_Styles;

   procedure Register_Scale_Grid_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("scale-grid", Scale_Grid_Class_Part_Styles));
   end Register_Scale_Grid_Styles;

   procedure Register_Scale_Img_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("scale-img", Scale_Img_Class_Part_Styles));
   end Register_Scale_Img_Styles;

   procedure Register_Nav_Bar_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("nav-bar", Nav_Bar_Class_Part_Styles));
   end Register_Nav_Bar_Styles;

   procedure Register_Nav_Item_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("nav-item", Nav_Item_Class_Part_Styles));
   end Register_Nav_Item_Styles;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Assets Example", (1000.0, 700.0));
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

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Register_Root_Styles (Source);
      Register_Section_Title_Styles (Source);
      Register_Sprite_Grid_Styles (Source);
      Register_Card_Styles (Source);
      Register_Sprite_Icon_Styles (Source);
      Register_Tint_Blue_Styles (Source);
      Register_Card_Label_Styles (Source);
      Register_Tint_Amber_Styles (Source);
      Register_Tint_Red_Styles (Source);
      Register_Tint_Purple_Styles (Source);
      Register_Tint_Green_Styles (Source);
      Register_Tint_Cyan_Styles (Source);
      Register_Crop_Grid_Styles (Source);
      Register_Crop_Img_Styles (Source);
      Register_Scale_Grid_Styles (Source);
      Register_Scale_Img_Styles (Source);
      Register_Nav_Bar_Styles (Source);
      Register_Nav_Item_Styles (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
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
      --  Bind every widget that has a CSS class
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Box_1);
      Adi.CSS_Source.Bind_Class (Source, "root", +Box_1);
      Adi.CSS_Source.Bind_Class (Source, "section-title", +Label_1);
      Adi.CSS_Source.Bind_Class (Source, "sprite-grid", +Box_2);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_3);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-blue", +Image_1);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_2);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_4);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-amber", +Image_2);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_3);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_5);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-red", +Image_3);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_4);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_6);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-purple", +Image_4);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_5);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_7);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-green", +Image_5);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_6);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_8);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-cyan", +Image_6);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_7);
      Adi.CSS_Source.Bind_Class (Source, "section-title", +Label_8);
      Adi.CSS_Source.Bind_Class (Source, "crop-grid", +Box_9);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_10);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", +Image_7);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_9);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_11);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", +Image_8);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_10);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_12);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", +Image_9);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_11);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_13);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", +Image_10);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_12);
      Adi.CSS_Source.Bind_Class (Source, "section-title", +Label_13);
      Adi.CSS_Source.Bind_Class (Source, "scale-grid", +Box_14);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_15);
      Adi.CSS_Source.Bind_Class (Source, "scale-img", +Image_11);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_14);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_16);
      Adi.CSS_Source.Bind_Class (Source, "scale-img", +Image_12);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_15);
      Adi.CSS_Source.Bind_Class (Source, "card", +Box_17);
      Adi.CSS_Source.Bind_Class (Source, "scale-img", +Image_13);
      Adi.CSS_Source.Bind_Class (Source, "card-label", +Label_16);
      Adi.CSS_Source.Bind_Class (Source, "section-title", +Label_17);
      Adi.CSS_Source.Bind_Class (Source, "nav-bar", +Box_18);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", +Label_18);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", +Label_19);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", +Label_20);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", +Label_21);

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
