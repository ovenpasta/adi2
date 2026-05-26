pragma Ada_2022;
with Adi.App;
with Adi.Layout_Util;
with Adi.Log;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Button;
with Adi.Widget_Styles; use Adi.Widget_Styles;
with Adi.CSS_Styles;    use Adi.CSS_Styles;

use type Adi.Widget.Box.Box_Handle;
use type Adi.Widget.Label.Label_Handle;
use type Adi.Widget.Button.Button_Handle;

--  Same UI as hello_example, written by hand without the XML/CSS pipeline.
--  Demonstrates that the declarative path is convenience, not a requirement:
--  widgets are built with handle constructors and styles are plain Ada
--  aggregates wired through Set_Part_Style.

procedure Hello_Raw_Example is
   A : Adi.App.App;
   W : Window_Handle;

   function Style return Style_Builder renames Adi.Widget_Styles.Create;

   --  Equivalent of the .root rule from hello_example.css
   Root_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Direction   => Set (Column),
      Background_Color => Set_Bg (RGB (24, 26, 32)),
      Padding          => Set (CSS_Box (Px (24.0))),
      Gap              => Set (Gap (Px (16.0))),
      others           => <>);

   --  Equivalent of .welcome::label
   Welcome_Label_Style : constant Style_Rules :=
     (Color     => Set (RGB (220, 225, 240)),
      Font_Size => Set_Font (Px (18.0)),
      others    => <>);

   --  Equivalent of .primary base + :hover
   Primary_Base : constant Style_Rules :=
     (Display          => Set (Inline_Flex),
      Justify_Content  => Set (Justify_Content_Value'(Center)),
      Align_Items      => Set (Align_Items_Value'(Center)),
      Background_Color => Set_Bg (RGB (37, 99, 235)),
      Border_Radius    => Set (Radius (Px (8.0))),
      Padding          => Set (CSS_Box (Px (10.0), Px (16.0))),
      Cursor           => Set (Cursor_Pointer),
      Transition       => Set ((Duration   => 0.15,
                                Easing     => Ease_Out,
                                Properties => Props (Prop_Background_Color))),
      others           => <>);

   Primary_Hover : constant Style_Rules :=
     (Background_Color => Set_Bg (RGB (29, 78, 216)),
      others           => <>);

   --  Equivalent of .primary::label
   Primary_Label_Style : constant Style_Rules :=
     (Color       => Set (RGB (255, 255, 255)),
      Font_Size   => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),  --  font-weight: 500
      others      => <>);

   procedure On_Hello_Click (Btn : Widget_Handle) is
      pragma Unreferenced (Btn);
   begin
      Adi.Log.Info ("Hello from Adi (raw)!");
   end On_Hello_Click;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   W := Create_Window_Handle ("Hello, Adi (raw)", (320.0, 180.0));

   declare
      Root : constant Adi.Widget.Box.Box_Handle    := Adi.Widget.Box.Create_Handle;
      Lbl  : constant Adi.Widget.Label.Label_Handle :=
               Adi.Widget.Label.Create_Handle ("Welcome to Adi");
      Btn  : constant Adi.Widget.Button.Button_Handle :=
               Adi.Widget.Button.Create_Handle ("Click me");
   begin
      --  Wire styles part-by-part. Bare-class CSS targets Main_Part;
      --  ::label targets the Label_Part subpart.
      Set_Part_Style (Widget_Handle'(+Root), Main_Part,
                      Style.Base (Root_Style).Build);

      Set_Part_Style (Widget_Handle'(+Lbl), Label_Part,
                      Style.Base (Welcome_Label_Style).Build);

      Set_Part_Style (Widget_Handle'(+Btn), Main_Part,
                      Style.Base (Primary_Base)
                           .On_Hover (Primary_Hover)
                           .Build);
      Set_Part_Style (Widget_Handle'(+Btn), Label_Part,
                      Style.Base (Primary_Label_Style).Build);

      Adi.Widget.Button.Connect_Clicked (Btn, On_Hello_Click'Unrestricted_Access);

      Add_Child (Widget_Handle'(+Root), Widget_Handle'(+Lbl));
      Add_Child (Widget_Handle'(+Root), Widget_Handle'(+Btn));

      Set_Root (W, Widget_Handle'(+Root));
   end;

   A.Add_Window (W);
   A.Run;
end Hello_Raw_Example;
