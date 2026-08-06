pragma Ada_2022;

with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.App;
with Adi.Image;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.SVG;
with Adi.Widget;         use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Image;
with Adi.Widget.Label;
with Adi.Window;         use Adi.Window;

with Svg_Example_Styles;  use Svg_Example_Styles;

procedure Svg_Example is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Adi.Image.Image_Access;

   Tiger_Path : constant String := "examples/assets/tiger.svg";

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("SVG Example", Adi.Window.Extent (Px (494.0), Px (439.0)));

      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;

      Header : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("SVG Rendering");
      Subtitle : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Resize the window: the document is rasterised again at the "
           & "new size, not scaled from a bitmap.");

      Panel : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Panel_Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("tiger.svg");

      Stage : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Artwork : constant Adi.Widget.Image.Image_Handle :=
        Adi.Widget.Image.Create_Handle;
      Caption : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle (Tiger_Path);

      Status : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("");

      Tiger : constant Adi.Image.Image_Access :=
        Adi.Image.Load_From_File (Tiger_Path);
   begin
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Header, Header_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Subtitle, Subtitle_Class_Part_Styles);

      Adi.Widget.Box.Set_Part_Styles (Panel, Panel_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles
        (Panel_Title, Panel_Title_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Stage, Stage_Class_Part_Styles);
      Adi.Widget.Image.Set_Part_Styles (Artwork, Artwork_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Caption, Caption_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Status, Status_Class_Part_Styles);

      if Tiger /= null then
         Adi.Widget.Image.Set_Image (Artwork, Tiger);
         Adi.Widget.Label.Set_Text
           (Status, "Loaded " & Tiger_Path
            & "  --  backend: " & Adi.SVG.Backend_Name);
      else
         Adi.Widget.Label.Set_Text
           (Status, "Could not load " & Tiger_Path
            & "  --  run from the project root.");
      end if;

      Add_Child (+Header, +Title);
      Add_Child (+Header, +Subtitle);
      Add_Child (+Root, +Header);

      Add_Child (+Stage, Adi.Widget.Image.To_Widget_Handle (Artwork));
      Add_Child (+Stage, +Caption);
      Add_Child (+Panel, +Panel_Title);
      Add_Child (+Panel, +Stage);
      Add_Child (+Root, +Panel);

      Add_Child (+Root, +Status);

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Svg_Example;
