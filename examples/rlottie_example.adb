pragma Ada_2022;

with Ada.Directories;
with Adi.App;
with Adi.RLottie;               use Adi.RLottie;
with Adi.Window;                use Adi.Window;
with Adi.Widget;                use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Widget.Animated_Widget;
with Adi.Widget.Animated_Widget.RLottie;
with RLottie_Example_Styles;    use RLottie_Example_Styles;

procedure RLottie_Example is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Animated_Widget.Animated_Widget_Handle;

   function Resolve_Lottie_Path return String is
   begin
      if Ada.Directories.Exists ("examples/assets/lottie_sample.json") then
         return "examples/assets/lottie_sample.json";
      elsif Ada.Directories.Exists ("assets/lottie_sample.json") then
         return "assets/lottie_sample.json";
      elsif Ada.Directories.Exists ("../examples/assets/lottie_sample.json") then
         return "../examples/assets/lottie_sample.json";
      else
         return "examples/assets/lottie_sample.json";
      end if;
   end Resolve_Lottie_Path;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("RLottie Example", (920.0, 680.0));

      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Header : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("RLottie Deck");
      Subtitle : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Main-thread render path with transport controls");
      Deck : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Viewer_Shell : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Viewer : constant Adi.Widget.Animated_Widget.Animated_Widget_Handle :=
        Adi.Widget.Animated_Widget.Create_Handle;
      Transport : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Status : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Loading assets/lottie_sample.json...");

      Btn_Play : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("PLAY >");
      Btn_Stop : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("STOP []");
      Btn_Rew  : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("REW <<");
      Btn_Loop : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("LOOP: ON");

      Anim : RLottie_Animation_Access := null;

      procedure On_Play (W : Widget_Handle) is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Start (Viewer);
         Adi.Widget.Label.Set_Text (Status, "PLAY");
      end On_Play;

      procedure On_Stop (W : Widget_Handle) is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Stop (Viewer);
         Adi.Widget.Label.Set_Text (Status, "STOP");
      end On_Stop;

      procedure On_Rew (W : Widget_Handle) is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Reset (Viewer);
         Adi.Widget.Label.Set_Text (Status, "REWIND TO FRAME 1");
      end On_Rew;

      procedure On_Loop_Toggled
        (W      : Widget_Handle;
         Active : Boolean)
      is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Set_Looping (Viewer, Active);
         if Active then
            Adi.Widget.Button.Set_Text (Btn_Loop, "LOOP: ON");
            Adi.Widget.Label.Set_Text (Status, "LOOP ENABLED");
         else
            Adi.Widget.Button.Set_Text (Btn_Loop, "LOOP: OFF");
            Adi.Widget.Label.Set_Text (Status, "LOOP DISABLED");
         end if;
      end On_Loop_Toggled;

   begin
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Header, Header_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Subtitle, Subtitle_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Deck, Deck_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles
        (Viewer_Shell, Viewer_Shell_Class_Part_Styles);
      Adi.Widget.Animated_Widget.Set_Part_Styles
        (Viewer, Viewer_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Transport, Transport_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Status, Status_Class_Part_Styles);

      Adi.Widget.Button.Set_Part_Styles
        (Btn_Play, Play_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Stop, Stop_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Rew, Rew_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Loop, Loop_Button_Class_Part_Styles);

      Adi.Widget.Button.Set_Toggleable (Btn_Loop, True);
      Adi.Widget.Button.Set_Toggled (Btn_Loop, True);
      Adi.Widget.Animated_Widget.Set_Looping (Viewer, True);
      Adi.Widget.Animated_Widget.Set_Max_Size
        (Viewer, Max_Width => 500.0, Max_Height => 280.0);

      Adi.Widget.Button.Connect_Clicked
        (Btn_Play, On_Play'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked
        (Btn_Stop, On_Stop'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked
        (Btn_Rew, On_Rew'Unrestricted_Access);
      Adi.Widget.Button.Connect_Toggled
        (Btn_Loop, On_Loop_Toggled'Unrestricted_Access);

      Add_Child (+Root, +Header);
      Add_Child (+Header, +Title);
      Add_Child (+Header, +Subtitle);

      Add_Child (+Root, +Deck);
      Add_Child (+Deck, +Viewer_Shell);
      Add_Child (+Viewer_Shell, +Viewer);
      Add_Child (+Deck, +Transport);
      Add_Child (+Transport, +Btn_Rew);
      Add_Child (+Transport, +Btn_Play);
      Add_Child (+Transport, +Btn_Stop);
      Add_Child (+Transport, +Btn_Loop);

      Add_Child (+Root, +Status);

      Anim := Adi.RLottie.Load_From_File (Path => Resolve_Lottie_Path);
      if Anim = null then
         Adi.Widget.Label.Set_Text
           (Status, "FAILED TO LOAD examples/assets/lottie_sample.json");
      else
         Adi.Widget.Animated_Widget.RLottie.Set_Animation
           (Viewer, Anim);
         Adi.Widget.Animated_Widget.Set_Looping
           (Viewer, Adi.Widget.Button.Is_Toggled (Btn_Loop));
         Adi.Widget.Label.Set_Text
           (Status,
            "READY  FRAMES:" &
            Natural'Image (Get_Frame_Count (Anim.all)));
      end if;

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      A.Add_Window (W);
      A.Run;

      if Anim /= null then
         Destroy (Anim.all);
      end if;
   end;
end RLottie_Example;
