--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.Assets; use Adi.Assets;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Image; use Adi.Widget.Image;
with Adi.Widget.Label; use Adi.Widget.Label;
with Adi.Window; use Adi.Window;
with Assets_Example_Styles; use Assets_Example_Styles;

package body Assets_Example_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;

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
   begin
      Adi.CSS_Source.Clear_Dynamic_Entries (Source);
      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);
      if Success then
         Adi.CSS_Source.Reload_Dynamic (Source, Success);
      end if;
   end Set_CSS_File;

   function Build
      return Adi.Window.Window_Access is
      W : constant Adi.Window.Window_Access :=
        Adi.Window.Create_Window ("Assets Example", (1000.0, 700.0));
      Box_1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_1 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("SVG Sprites (?id=)");
      Box_2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_3 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_1 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_2 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("home");
      Box_4 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_2 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_3 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("star");
      Box_5 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_3 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_4 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("heart");
      Box_6 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_4 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_5 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("settings");
      Box_7 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_5 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_6 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("search");
      Box_8 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_6 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_7 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("bell");
      Label_8 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Raster Crop (?x=;y=;w=;h=)");
      Box_9 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_10 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_7 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_9 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Top-Left");
      Box_11 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_8 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_10 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Top-Right");
      Box_12 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_9 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_11 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Bottom-Left");
      Box_13 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_10 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_12 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Bottom-Right");
      Label_13 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Scale Modes (?render=)");
      Box_14 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Box_15 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_11 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_14 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("linear");
      Box_16 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_12 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_15 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("nearest");
      Box_17 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Image_13 : constant Adi.Widget.Image.Image_Widget_Access := Adi.Widget.Image.Create;
      Label_16 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("pixelated");
      Label_17 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Labels with Icons (icon= attribute)");
      Box_18 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Label_18 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Home");
      Label_19 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Search");
      Label_20 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Settings");
      Label_21 : constant Adi.Widget.Label.Label_Widget_Access := Adi.Widget.Label.Create ("Alerts");
   begin
      --  Configure properties
      Image_1.Set_Image (Adi.Assets.Get_Image ("icons.svg?id=home"));
      Image_2.Set_Image (Adi.Assets.Get_Image ("icons.svg?id=star"));
      Image_3.Set_Image (Adi.Assets.Get_Image ("icons.svg?id=heart"));
      Image_4.Set_Image (Adi.Assets.Get_Image ("icons.svg?id=settings"));
      Image_5.Set_Image (Adi.Assets.Get_Image ("icons.svg?id=search"));
      Image_6.Set_Image (Adi.Assets.Get_Image ("icons.svg?id=bell"));
      Image_7.Set_Image (Adi.Assets.Get_Image ("happycat.png?x=0;y=0;w=64;h=52"));
      Image_8.Set_Image (Adi.Assets.Get_Image ("happycat.png?x=64;y=0;w=64;h=52"));
      Image_9.Set_Image (Adi.Assets.Get_Image ("happycat.png?x=0;y=52;w=64;h=53"));
      Image_10.Set_Image (Adi.Assets.Get_Image ("happycat.png?x=64;y=52;w=64;h=53"));
      Image_11.Set_Image (Adi.Assets.Get_Image ("happycat.png?render=linear"));
      Image_12.Set_Image (Adi.Assets.Get_Image ("happycat.png?render=nearest"));
      Image_13.Set_Image (Adi.Assets.Get_Image ("happycat.png?render=pixelated"));
      Label_18.Set_Icon (Adi.Assets.Get_Image ("icons.svg?id=home"));
      Label_19.Set_Icon (Adi.Assets.Get_Image ("icons.svg?id=search"));
      Label_20.Set_Icon (Adi.Assets.Get_Image ("icons.svg?id=settings"));
      Label_21.Set_Icon (Adi.Assets.Get_Image ("icons.svg?id=bell"));

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("root", Root_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("section-title", Section_Title_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("sprite-grid", Sprite_Grid_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card", Card_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("sprite-icon", Sprite_Icon_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-blue", Tint_Blue_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("card-label", Card_Label_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-amber", Tint_Amber_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-red", Tint_Red_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-purple", Tint_Purple_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-green", Tint_Green_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("tint-cyan", Tint_Cyan_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("crop-grid", Crop_Grid_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("crop-img", Crop_Img_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("scale-grid", Scale_Grid_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("scale-img", Scale_Img_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("nav-bar", Nav_Bar_Class_Part_Styles));
      Adi.CSS_Source.Add_Static_Entry (Source, Adi.CSS_Source.Class_Entry ("nav-item", Nav_Item_Class_Part_Styles));

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

      --  Bind every widget that has a CSS class
      Adi.CSS_Source.Bind_Class (Source, "root", Box_1);
      Adi.CSS_Source.Bind_Class (Source, "section-title", Label_1);
      Adi.CSS_Source.Bind_Class (Source, "sprite-grid", Box_2);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_3);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-blue", Image_1);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_2);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_4);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-amber", Image_2);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_3);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_5);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-red", Image_3);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_4);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_6);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-purple", Image_4);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_5);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_7);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-green", Image_5);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_6);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_8);
      Adi.CSS_Source.Bind_Class (Source, "sprite-icon tint-cyan", Image_6);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_7);
      Adi.CSS_Source.Bind_Class (Source, "section-title", Label_8);
      Adi.CSS_Source.Bind_Class (Source, "crop-grid", Box_9);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_10);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", Image_7);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_9);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_11);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", Image_8);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_10);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_12);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", Image_9);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_11);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_13);
      Adi.CSS_Source.Bind_Class (Source, "crop-img", Image_10);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_12);
      Adi.CSS_Source.Bind_Class (Source, "section-title", Label_13);
      Adi.CSS_Source.Bind_Class (Source, "scale-grid", Box_14);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_15);
      Adi.CSS_Source.Bind_Class (Source, "scale-img", Image_11);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_14);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_16);
      Adi.CSS_Source.Bind_Class (Source, "scale-img", Image_12);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_15);
      Adi.CSS_Source.Bind_Class (Source, "card", Box_17);
      Adi.CSS_Source.Bind_Class (Source, "scale-img", Image_13);
      Adi.CSS_Source.Bind_Class (Source, "card-label", Label_16);
      Adi.CSS_Source.Bind_Class (Source, "section-title", Label_17);
      Adi.CSS_Source.Bind_Class (Source, "nav-bar", Box_18);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", Label_18);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", Label_19);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", Label_20);
      Adi.CSS_Source.Bind_Class (Source, "nav-item", Label_21);

      --  Build hierarchy
      Box_3.Add_Child (Image_1);
      Box_3.Add_Child (Label_2);
      Box_4.Add_Child (Image_2);
      Box_4.Add_Child (Label_3);
      Box_5.Add_Child (Image_3);
      Box_5.Add_Child (Label_4);
      Box_6.Add_Child (Image_4);
      Box_6.Add_Child (Label_5);
      Box_7.Add_Child (Image_5);
      Box_7.Add_Child (Label_6);
      Box_8.Add_Child (Image_6);
      Box_8.Add_Child (Label_7);
      Box_2.Add_Child (Box_3);
      Box_2.Add_Child (Box_4);
      Box_2.Add_Child (Box_5);
      Box_2.Add_Child (Box_6);
      Box_2.Add_Child (Box_7);
      Box_2.Add_Child (Box_8);
      Box_10.Add_Child (Image_7);
      Box_10.Add_Child (Label_9);
      Box_11.Add_Child (Image_8);
      Box_11.Add_Child (Label_10);
      Box_12.Add_Child (Image_9);
      Box_12.Add_Child (Label_11);
      Box_13.Add_Child (Image_10);
      Box_13.Add_Child (Label_12);
      Box_9.Add_Child (Box_10);
      Box_9.Add_Child (Box_11);
      Box_9.Add_Child (Box_12);
      Box_9.Add_Child (Box_13);
      Box_15.Add_Child (Image_11);
      Box_15.Add_Child (Label_14);
      Box_16.Add_Child (Image_12);
      Box_16.Add_Child (Label_15);
      Box_17.Add_Child (Image_13);
      Box_17.Add_Child (Label_16);
      Box_14.Add_Child (Box_15);
      Box_14.Add_Child (Box_16);
      Box_14.Add_Child (Box_17);
      Box_18.Add_Child (Label_18);
      Box_18.Add_Child (Label_19);
      Box_18.Add_Child (Label_20);
      Box_18.Add_Child (Label_21);
      Box_1.Add_Child (Label_1);
      Box_1.Add_Child (Box_2);
      Box_1.Add_Child (Label_8);
      Box_1.Add_Child (Box_9);
      Box_1.Add_Child (Label_13);
      Box_1.Add_Child (Box_14);
      Box_1.Add_Child (Label_17);
      Box_1.Add_Child (Box_18);

      --  Auto-wire CSS live reload
      Adi.Window.Set_On_Tick (W.all, Tick_Styles_CB'Unrestricted_Access);

      W.Set_Root (Box_1);
      return W;
   end Build;

   end Instance;

end Assets_Example_UI;
