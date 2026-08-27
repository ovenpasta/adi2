--  Auto-generated from XML
--  Do not edit manually

pragma Wide_Character_Encoding (Brackets);
pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Image; use Adi.Widget.Image;
with Adi.Widget.Label; use Adi.Widget.Label;
with Image_Example_Styles;

package body Image_Example_UI is

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
      Result := Merge_Metadata (Result, Image_Example_Styles.Root_Metadata);
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
        Adi.Window.Create_Window_Handle ("Image Example", Adi.Window.Extent (Px (754.0), Px (620.0)));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Image Widget Showcase");
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Demonstrating SVG path, SVG file, PNG, and JPG formats with all object-fit modes");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Image Formats");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("SVG Path");
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("SVG (tiger.svg)");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("PNG (happycat.png)");
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("JPG (bg.jpg)");
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Object-Fit Modes (happycat.png)");
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("fill");
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("contain");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("cover");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("none");
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("scale-down");
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Tintable Icons (hover to change color)");
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Default → Blue");
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Amber → Yellow");
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Green → Light");
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Red → Light");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;
      Img_Svg_Path := Adi.Widget.Image.Create_Handle;
      Img_Svg := Adi.Widget.Image.Create_Handle;
      Img_Png := Adi.Widget.Image.Create_Handle;
      Img_Jpg := Adi.Widget.Image.Create_Handle;
      Fit_Fill := Adi.Widget.Image.Create_Handle;
      Fit_Contain := Adi.Widget.Image.Create_Handle;
      Fit_Cover := Adi.Widget.Image.Create_Handle;
      Fit_None := Adi.Widget.Image.Create_Handle;
      Fit_Scale_Down := Adi.Widget.Image.Create_Handle;
      Tint_Default := Adi.Widget.Image.Create_Handle;
      Tint_Warm := Adi.Widget.Image.Create_Handle;
      Tint_Success := Adi.Widget.Image.Create_Handle;
      Tint_Danger := Adi.Widget.Image.Create_Handle;

      --  Install the stylesheets as one batch: precompiled
      --  styles as static fallback, then dynamic CSS and the mode
      declare
         Update : Adi.CSS_Source.Update_Scope (Source'Access);
         pragma Unreferenced (Update);
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Static_Entries (Source);
         Image_Example_Styles.Register_Selectors (Source);
         Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

         Adi.CSS_Source.Set_Dynamic_Sources
           (Source,
            [Adi.CSS_Source.CSS_File ("examples/css/image_example.css")],
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
         W          => +Label_2,
         Tag_Name   => "label",
         Class_Name => "subtitle");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_3,
         Tag_Name   => "label",
         Class_Name => "section-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_1,
         Tag_Name   => "box",
         Class_Name => "format-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_2,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Img_Svg_Path,
         Tag_Name   => "image",
         Class_Name => "image",
         Id_Name    => "Img_Svg_Path");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_4,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Img_Svg,
         Tag_Name   => "image",
         Class_Name => "image",
         Id_Name    => "Img_Svg");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Img_Png,
         Tag_Name   => "image",
         Class_Name => "image",
         Id_Name    => "Img_Png");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Img_Jpg,
         Tag_Name   => "image",
         Class_Name => "image",
         Id_Name    => "Img_Jpg");
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
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "fit-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Fit_Fill,
         Tag_Name   => "image",
         Class_Name => "image fit-fill",
         Id_Name    => "Fit_Fill");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Fit_Contain,
         Tag_Name   => "image",
         Class_Name => "image fit-contain",
         Id_Name    => "Fit_Contain");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Fit_Cover,
         Tag_Name   => "image",
         Class_Name => "image fit-cover",
         Id_Name    => "Fit_Cover");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Fit_None,
         Tag_Name   => "image",
         Class_Name => "image fit-none",
         Id_Name    => "Fit_None");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Fit_Scale_Down,
         Tag_Name   => "image",
         Class_Name => "image fit-scale-down",
         Id_Name    => "Fit_Scale_Down");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_14,
         Tag_Name   => "label",
         Class_Name => "section-title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "tint-grid");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "tint-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Tint_Default,
         Tag_Name   => "image",
         Class_Name => "image tint-icon tint-default",
         Id_Name    => "Tint_Default");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_15,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "tint-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Tint_Warm,
         Tag_Name   => "image",
         Class_Name => "image tint-icon tint-warm",
         Id_Name    => "Tint_Warm");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "tint-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Tint_Success,
         Tag_Name   => "image",
         Class_Name => "image tint-icon tint-success",
         Id_Name    => "Tint_Success");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_17,
         Tag_Name   => "label",
         Class_Name => "card-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "tint-card");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Tint_Danger,
         Tag_Name   => "image",
         Class_Name => "image tint-icon tint-danger",
         Id_Name    => "Tint_Danger");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_18,
         Tag_Name   => "label",
         Class_Name => "card-label");

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_2, +Img_Svg_Path);
      Adi.Widget.Add_Child (+Box_2, +Label_4);
      Adi.Widget.Add_Child (+Box_3, +Img_Svg);
      Adi.Widget.Add_Child (+Box_3, +Label_5);
      Adi.Widget.Add_Child (+Box_4, +Img_Png);
      Adi.Widget.Add_Child (+Box_4, +Label_6);
      Adi.Widget.Add_Child (+Box_5, +Img_Jpg);
      Adi.Widget.Add_Child (+Box_5, +Label_7);
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_1, +Box_3);
      Adi.Widget.Add_Child (+Box_1, +Box_4);
      Adi.Widget.Add_Child (+Box_1, +Box_5);
      Adi.Widget.Add_Child (+Box_7, +Fit_Fill);
      Adi.Widget.Add_Child (+Box_7, +Label_9);
      Adi.Widget.Add_Child (+Box_8, +Fit_Contain);
      Adi.Widget.Add_Child (+Box_8, +Label_10);
      Adi.Widget.Add_Child (+Box_9, +Fit_Cover);
      Adi.Widget.Add_Child (+Box_9, +Label_11);
      Adi.Widget.Add_Child (+Box_10, +Fit_None);
      Adi.Widget.Add_Child (+Box_10, +Label_12);
      Adi.Widget.Add_Child (+Box_11, +Fit_Scale_Down);
      Adi.Widget.Add_Child (+Box_11, +Label_13);
      Adi.Widget.Add_Child (+Box_6, +Box_7);
      Adi.Widget.Add_Child (+Box_6, +Box_8);
      Adi.Widget.Add_Child (+Box_6, +Box_9);
      Adi.Widget.Add_Child (+Box_6, +Box_10);
      Adi.Widget.Add_Child (+Box_6, +Box_11);
      Adi.Widget.Add_Child (+Box_13, +Tint_Default);
      Adi.Widget.Add_Child (+Box_13, +Label_15);
      Adi.Widget.Add_Child (+Box_14, +Tint_Warm);
      Adi.Widget.Add_Child (+Box_14, +Label_16);
      Adi.Widget.Add_Child (+Box_15, +Tint_Success);
      Adi.Widget.Add_Child (+Box_15, +Label_17);
      Adi.Widget.Add_Child (+Box_16, +Tint_Danger);
      Adi.Widget.Add_Child (+Box_16, +Label_18);
      Adi.Widget.Add_Child (+Box_12, +Box_13);
      Adi.Widget.Add_Child (+Box_12, +Box_14);
      Adi.Widget.Add_Child (+Box_12, +Box_15);
      Adi.Widget.Add_Child (+Box_12, +Box_16);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Label_2);
      Adi.Widget.Add_Child (+Root, +Label_3);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Label_8);
      Adi.Widget.Add_Child (+Root, +Box_6);
      Adi.Widget.Add_Child (+Root, +Label_14);
      Adi.Widget.Add_Child (+Root, +Box_12);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Image_Example_UI;
