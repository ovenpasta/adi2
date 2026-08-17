pragma Ada_2022;

with Ada.Directories;
with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.RLottie;               use Adi.RLottie;
with Adi.Window;                use Adi.Window;
with Adi.Widget;                use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Label;
with Adi.Widget.Animated_Widget;
with Adi.Widget.Animated_Widget.RLottie;
with RLottie_Example_Styles;    use RLottie_Example_Styles;

--  Eight emoji, each its own animation, each drawn at a fixed 72x72.
--  That is the size rlottie is meant for: a frame set costs what it is
--  displayed at, so pinning the extent is what keeps eight concurrent
--  animations affordable.

procedure RLottie_Example is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Animated_Widget.Animated_Widget_Handle;

   type Emoji_Kind is
     (Party_Popper, Grinning_Face, Red_Heart, Rocket,
      Fire, Thumbs_Up, Tears_Of_Joy, Star);

   function Asset (E : Emoji_Kind) return String is
     (case E is
         when Party_Popper  => "noto_party_popper.json",
         when Grinning_Face => "noto_grinning_face.json",
         when Red_Heart     => "noto_red_heart.json",
         when Rocket        => "noto_rocket.json",
         when Fire          => "noto_fire.json",
         when Thumbs_Up     => "noto_thumbs_up.json",
         when Tears_Of_Joy  => "noto_tears_of_joy.json",
         when Star          => "noto_star.json");

   function Caption (E : Emoji_Kind) return String is
     (case E is
         when Party_Popper  => "PARTY",
         when Grinning_Face => "GRIN",
         when Red_Heart     => "HEART",
         when Rocket        => "ROCKET",
         when Fire          => "FIRE",
         when Thumbs_Up     => "THUMBS",
         when Tears_Of_Joy  => "JOY",
         when Star          => "STAR");

   --  Examples are run from the repository root, from their own directory
   --  and from a build tree, so the asset is looked for in each.
   function Resolve_Asset (File : String) return String is
   begin
      if Ada.Directories.Exists ("examples/assets/" & File) then
         return "examples/assets/" & File;
      elsif Ada.Directories.Exists ("assets/" & File) then
         return "assets/" & File;
      elsif Ada.Directories.Exists ("../examples/assets/" & File) then
         return "../examples/assets/" & File;
      else
         return "examples/assets/" & File;
      end if;
   end Resolve_Asset;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle
          ("RLottie Example", Adi.Window.Extent (Px (620.0), Px (540.0)));

      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Header : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Animated Emoji");
      Subtitle : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Eight Lottie animations at 72x72, one animation object each");
      Deck : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Grid : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Transport : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Status : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Loading...");

      Btn_Play : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("PLAY >");
      Btn_Pause : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("PAUSE ||");
      Btn_Reset : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("RESET <<");
      Btn_Speed : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("SPEED 1.0x");

      Cells : constant array (Emoji_Kind) of Adi.Widget.Box.Box_Handle :=
        [for E in Emoji_Kind => Adi.Widget.Box.Create_Handle];
      Viewers : constant array (Emoji_Kind) of
        Adi.Widget.Animated_Widget.Animated_Widget_Handle :=
          [for E in Emoji_Kind =>
             Adi.Widget.Animated_Widget.Create_Handle];
      Captions : constant array (Emoji_Kind) of
        Adi.Widget.Label.Label_Handle :=
          [for E in Emoji_Kind =>
             Adi.Widget.Label.Create_Handle (Caption (E))];

      Anims : array (Emoji_Kind) of RLottie_Animation_Access :=
        [others => null];

      Speeds : constant array (Positive range 1 .. 3) of Float :=
        [0.5, 1.0, 2.0];
      Speed_Idx : Positive := 2;

      procedure On_Play (Src : Widget_Handle) is
         pragma Unreferenced (Src);
      begin
         for E in Emoji_Kind loop
            Adi.Widget.Animated_Widget.Start (Viewers (E));
         end loop;
         Adi.Widget.Label.Set_Text (Status, "PLAYING");
      end On_Play;

      procedure On_Pause (Src : Widget_Handle) is
         pragma Unreferenced (Src);
      begin
         for E in Emoji_Kind loop
            Adi.Widget.Animated_Widget.Stop (Viewers (E));
         end loop;
         Adi.Widget.Label.Set_Text (Status, "PAUSED");
      end On_Pause;

      procedure On_Reset (Src : Widget_Handle) is
         pragma Unreferenced (Src);
      begin
         for E in Emoji_Kind loop
            Adi.Widget.Animated_Widget.Reset (Viewers (E));
         end loop;
         Adi.Widget.Label.Set_Text (Status, "RESET TO FRAME 1");
      end On_Reset;

      procedure On_Speed (Src : Widget_Handle) is
         pragma Unreferenced (Src);
      begin
         Speed_Idx := (if Speed_Idx = Speeds'Last then Speeds'First
                       else Speed_Idx + 1);
         for E in Emoji_Kind loop
            Adi.Widget.Animated_Widget.Set_Playback_Speed
              (Viewers (E), Speeds (Speed_Idx));
         end loop;
         declare
            Label : constant String :=
              (case Speed_Idx is
                  when 1 => "SPEED 0.5x",
                  when 2 => "SPEED 1.0x",
                  when others => "SPEED 2.0x");
         begin
            Adi.Widget.Button.Set_Text (Btn_Speed, Label);
            Adi.Widget.Label.Set_Text (Status, Label);
         end;
      end On_Speed;

      Loaded : Natural := 0;
      Frames : Natural := 0;

   begin
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Header, Header_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Subtitle, Subtitle_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Deck, Deck_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Grid, Grid_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Transport, Transport_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Status, Status_Class_Part_Styles);

      Adi.Widget.Button.Set_Part_Styles
        (Btn_Play, Play_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Pause, Pause_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Reset, Reset_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Speed, Speed_Button_Class_Part_Styles);

      Adi.Widget.Button.Connect_Clicked
        (Btn_Play, On_Play'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked
        (Btn_Pause, On_Pause'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked
        (Btn_Reset, On_Reset'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked
        (Btn_Speed, On_Speed'Unrestricted_Access);

      Add_Child (+Root, +Header);
      Add_Child (+Header, +Title);
      Add_Child (+Header, +Subtitle);

      Add_Child (+Root, +Deck);
      Add_Child (+Deck, +Grid);

      for E in Emoji_Kind loop
         Adi.Widget.Box.Set_Part_Styles (Cells (E), Cell_Class_Part_Styles);
         Adi.Widget.Animated_Widget.Set_Part_Styles
           (Viewers (E), Emoji_Class_Part_Styles);
         Adi.Widget.Label.Set_Part_Styles
           (Captions (E), Caption_Class_Part_Styles);

         --  Belt and braces with the stylesheet: the measured size is what
         --  decides the rasterised extent, and a cell that grew would
         --  raster every frame larger for nothing.
         Adi.Widget.Animated_Widget.Set_Max_Size
           (Viewers (E), Max_Width => 72.0, Max_Height => 72.0);
         Adi.Widget.Animated_Widget.Set_Looping (Viewers (E), True);

         Add_Child (+Grid, +Cells (E));
         Add_Child (+Cells (E), +Viewers (E));
         Add_Child (+Cells (E), +Captions (E));

         Anims (E) := Adi.RLottie.Load_From_File
                        (Path => Resolve_Asset (Asset (E)));
         if Anims (E) /= null then
            Adi.Widget.Animated_Widget.RLottie.Set_Animation
              (Viewers (E), Anims (E));
            Adi.Widget.Animated_Widget.Set_Looping (Viewers (E), True);
            Loaded := Loaded + 1;
            Frames := Frames + Get_Frame_Count (Anims (E).all);
         else
            Adi.Widget.Label.Set_Text (Captions (E), "MISSING");
         end if;
      end loop;

      Add_Child (+Deck, +Transport);
      Add_Child (+Transport, +Btn_Play);
      Add_Child (+Transport, +Btn_Pause);
      Add_Child (+Transport, +Btn_Reset);
      Add_Child (+Transport, +Btn_Speed);

      Add_Child (+Root, +Status);

      if Loaded = 0 then
         Adi.Widget.Label.Set_Text
           (Status, "FAILED TO LOAD examples/assets/noto_*.json");
      else
         Adi.Widget.Label.Set_Text
           (Status,
            "READY " & Loaded'Image & " ANIMATIONS," & Frames'Image
            & " FRAMES");
      end if;

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;

      for E in Emoji_Kind loop
         if Anims (E) /= null then
            Destroy (Anims (E).all);
         end if;
      end loop;
   end;
end RLottie_Example;
