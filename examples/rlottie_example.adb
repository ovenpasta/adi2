pragma Ada_2022;

with Ada.Directories;
with Adi.App;
with Adi.RLottie;               use Adi.RLottie;
with Adi.Window;                use Adi.Window;
with Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;         use Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Widget.Animated_Widget;
with Adi.Widget.Animated_Widget.RLottie;
with RLottie_Example_Styles;    use RLottie_Example_Styles;

procedure RLottie_Example is
   A : Adi.App.App;

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
      W : constant Window_Access :=
        Create_Window ("RLottie Example", (920.0, 680.0));

      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Header : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("RLottie Deck");
      Subtitle : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Main-thread render path with transport controls");
      Deck : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Viewer_Shell : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Viewer : constant Adi.Widget.Animated_Widget.Animated_Widget_Access :=
        Adi.Widget.Animated_Widget.Create;
      Transport : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Status : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Loading assets/lottie_sample.json...");

      Btn_Play : constant Button_Widget_Access := Create ("PLAY >");
      Btn_Stop : constant Button_Widget_Access := Create ("STOP []");
      Btn_Rew  : constant Button_Widget_Access := Create ("REW <<");
      Btn_Loop : constant Button_Widget_Access := Create ("LOOP: ON");

      Anim : RLottie_Animation_Access := null;

      procedure On_Play (Btn : Button_Widget_Access) is
         pragma Unreferenced (Btn);
      begin
         Viewer.Start;
         Status.Set_Text ("PLAY");
      end On_Play;

      procedure On_Stop (Btn : Button_Widget_Access) is
         pragma Unreferenced (Btn);
      begin
         Viewer.Stop;
         Status.Set_Text ("STOP");
      end On_Stop;

      procedure On_Rew (Btn : Button_Widget_Access) is
         pragma Unreferenced (Btn);
      begin
         Viewer.Reset;
         Status.Set_Text ("REWIND TO FRAME 1");
      end On_Rew;

      procedure On_Loop_Toggled
        (Btn    : Button_Widget_Access;
         Active : Boolean)
      is
         pragma Unreferenced (Btn);
      begin
         Viewer.Set_Looping (Active);
         if Active then
            Btn_Loop.Set_Text ("LOOP: ON");
            Status.Set_Text ("LOOP ENABLED");
         else
            Btn_Loop.Set_Text ("LOOP: OFF");
            Status.Set_Text ("LOOP DISABLED");
         end if;
      end On_Loop_Toggled;

   begin
      Adi.Widget.Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Header.all, Header_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Subtitle.all, Subtitle_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Deck.all, Deck_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Viewer_Shell.all, Viewer_Shell_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Viewer.all, Viewer_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Transport.all, Transport_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Status.all, Status_Class_Part_Styles);

      Adi.Widget.Set_Part_Styles (Btn_Play.all, Play_Button_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Stop.all, Stop_Button_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Rew.all, Rew_Button_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Loop.all, Loop_Button_Class_Part_Styles);

      Btn_Loop.Set_Toggleable (True);
      Btn_Loop.Set_Toggled (True);
      Viewer.Set_Looping (True);
      Viewer.Set_Max_Size (Max_Width => 500.0, Max_Height => 280.0);

      Btn_Play.Set_On_Clicked (On_Play'Unrestricted_Access);
      Btn_Stop.Set_On_Clicked (On_Stop'Unrestricted_Access);
      Btn_Rew.Set_On_Clicked (On_Rew'Unrestricted_Access);
      Btn_Loop.Set_On_Toggled (On_Loop_Toggled'Unrestricted_Access);

      Root.Add_Child (Header);
      Header.Add_Child (Title);
      Header.Add_Child (Subtitle);

      Root.Add_Child (Deck);
      Deck.Add_Child (Viewer_Shell);
      Viewer_Shell.Add_Child (Viewer);
      Deck.Add_Child (Transport);
      Transport.Add_Child (Btn_Rew);
      Transport.Add_Child (Btn_Play);
      Transport.Add_Child (Btn_Stop);
      Transport.Add_Child (Btn_Loop);

      Root.Add_Child (Status);

      Anim := Adi.RLottie.Load_From_File (Path => Resolve_Lottie_Path);
      if Anim = null then
         Status.Set_Text ("FAILED TO LOAD examples/assets/lottie_sample.json");
      else
         Adi.Widget.Animated_Widget.RLottie.Set_Animation (Viewer.all, Anim);
         Viewer.Set_Looping (Btn_Loop.Is_Toggled);
         Status.Set_Text
           ("READY  FRAMES:" &
            Natural'Image (Get_Frame_Count (Anim.all)));
      end if;

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;

      if Anim /= null then
         Destroy (Anim.all);
      end if;
   end;
end RLottie_Example;
