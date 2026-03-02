pragma Ada_2022;

with Adi.App;
with Adi.Window;                 use Adi.Window;
with Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Button;          use Adi.Widget.Button;
with Adi.Widget.Animated_Widget;
with Adi.Animated_Image;         use Adi.Animated_Image;
with Animated_Image_Example_Styles; use Animated_Image_Example_Styles;

procedure Animated_Image_Example is
   A : Adi.App.App;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access :=
        Create_Window ("Animated Image Example", (920.0, 680.0));

      Root : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Header : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Title : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Animated Image (SDL_image)");
      Subtitle : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create
          ("Animhorse.gif from Wikimedia Commons with live playback controls");
      Viewer_Frame : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Viewer : constant Adi.Widget.Animated_Widget.Animated_Widget_Access :=
        Adi.Widget.Animated_Widget.Create;
      Controls : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Status : constant Adi.Widget.Label.Label_Widget_Access :=
        Adi.Widget.Label.Create ("Loading animation...");

      Btn_Start : constant Button_Widget_Access := Create ("Start");
      Btn_Stop  : constant Button_Widget_Access := Create ("Stop");
      Btn_Reset : constant Button_Widget_Access := Create ("Reset");
      Btn_Loop  : constant Button_Widget_Access := Create ("Loop: ON");

      Animation : Animated_Image_Access := null;

      procedure On_Start (Btn : Button_Widget_Access) is
         pragma Unreferenced (Btn);
      begin
         Viewer.Start;
         Status.Set_Text ("Playing");
      end On_Start;

      procedure On_Stop (Btn : Button_Widget_Access) is
         pragma Unreferenced (Btn);
      begin
         Viewer.Stop;
         Status.Set_Text ("Stopped");
      end On_Stop;

      procedure On_Reset (Btn : Button_Widget_Access) is
         pragma Unreferenced (Btn);
      begin
         Viewer.Reset;
         Status.Set_Text ("Reset to first frame");
      end On_Reset;

      procedure On_Loop_Toggled
        (Btn    : Button_Widget_Access;
         Active : Boolean)
      is
         pragma Unreferenced (Btn);
      begin
         Viewer.Set_Looping (Active);
         if Active then
            Btn_Loop.Set_Text ("Loop: ON");
            Status.Set_Text ("Loop enabled");
         else
            Btn_Loop.Set_Text ("Loop: OFF");
            Status.Set_Text ("Loop disabled");
         end if;
      end On_Loop_Toggled;

   begin
      Adi.Widget.Set_Part_Styles (Root.all, Root_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Header.all, Header_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Title.all, Title_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Subtitle.all, Subtitle_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Viewer_Frame.all, Viewer_Frame_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Viewer.all, Viewer_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Controls.all, Controls_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Status.all, Status_Class_Part_Styles);

      Adi.Widget.Set_Part_Styles (Btn_Start.all, Action_Button_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Stop.all, Action_Button_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Reset.all, Action_Button_Class_Part_Styles);
      Adi.Widget.Set_Part_Styles (Btn_Loop.all, Loop_Button_Class_Part_Styles);

      Btn_Loop.Set_Toggleable (True);
      Btn_Loop.Set_Toggled (True);

      Btn_Start.Connect_Clicked (On_Start'Unrestricted_Access);
      Btn_Stop.Connect_Clicked (On_Stop'Unrestricted_Access);
      Btn_Reset.Connect_Clicked (On_Reset'Unrestricted_Access);
      Btn_Loop.Connect_Toggled (On_Loop_Toggled'Unrestricted_Access);

      Root.Add_Child (Header);
      Header.Add_Child (Title);
      Header.Add_Child (Subtitle);

      Root.Add_Child (Viewer_Frame);
      Viewer_Frame.Add_Child (Viewer);

      Root.Add_Child (Controls);
      Controls.Add_Child (Btn_Start);
      Controls.Add_Child (Btn_Stop);
      Controls.Add_Child (Btn_Reset);
      Controls.Add_Child (Btn_Loop);

      Root.Add_Child (Status);

      Animation :=
        Adi.Animated_Image.Load_From_File ("examples/assets/animhorse.gif");
      if Animation = null then
         Status.Set_Text ("Failed to load animhorse.gif");
      else
         Viewer.Set_Animation (Animation);
         Viewer.Set_Looping (True);
         Status.Set_Text
           ("Loaded Animhorse.gif (" &
            Get_Frame_Count (Animation.all)'Image & " frames)");
      end if;

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Animated_Image_Example;
