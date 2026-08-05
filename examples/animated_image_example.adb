pragma Ada_2022;

with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;                 use Adi.Window;
with Adi.Widget;                 use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Button;
with Adi.Widget.Animated_Widget;
with Adi.Animated_Image;         use Adi.Animated_Image;
with Animated_Image_Example_Styles; use Animated_Image_Example_Styles;

procedure Animated_Image_Example is
   A : Adi.App.App;

   use type Adi.Widget.Box.Box_Handle;
   use type Adi.Widget.Label.Label_Handle;
   use type Adi.Widget.Button.Button_Handle;
   use type Adi.Widget.Animated_Widget.Animated_Widget_Handle;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Handle :=
        Create_Window_Handle ("Animated Image Example", (920.0, 680.0));

      Root : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Header : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Title : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Animated Image (SDL_image)");
      Subtitle : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle
          ("Animhorse.gif from Wikimedia Commons with live playback controls");
      Viewer_Frame : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Viewer : constant Adi.Widget.Animated_Widget.Animated_Widget_Handle :=
        Adi.Widget.Animated_Widget.Create_Handle;
      Controls : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Status : constant Adi.Widget.Label.Label_Handle :=
        Adi.Widget.Label.Create_Handle ("Loading animation...");

      Btn_Start : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Start");
      Btn_Stop  : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Stop");
      Btn_Reset : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Reset");
      Btn_Loop  : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle ("Loop: ON");

      Animation : Animated_Image_Access := null;

      procedure On_Start (W : Widget_Handle) is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Start (Viewer);
         Adi.Widget.Label.Set_Text (Status, "Playing");
      end On_Start;

      procedure On_Stop (W : Widget_Handle) is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Stop (Viewer);
         Adi.Widget.Label.Set_Text (Status, "Stopped");
      end On_Stop;

      procedure On_Reset (W : Widget_Handle) is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Reset (Viewer);
         Adi.Widget.Label.Set_Text (Status, "Reset to first frame");
      end On_Reset;

      procedure On_Loop_Toggled
        (W      : Widget_Handle;
         Active : Boolean)
      is
         pragma Unreferenced (W);
      begin
         Adi.Widget.Animated_Widget.Set_Looping (Viewer, Active);
         if Active then
            Adi.Widget.Button.Set_Text (Btn_Loop, "Loop: ON");
            Adi.Widget.Label.Set_Text (Status, "Loop enabled");
         else
            Adi.Widget.Button.Set_Text (Btn_Loop, "Loop: OFF");
            Adi.Widget.Label.Set_Text (Status, "Loop disabled");
         end if;
      end On_Loop_Toggled;

   begin
      Adi.Widget.Box.Set_Part_Styles (Root, Root_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Header, Header_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Title, Title_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Subtitle, Subtitle_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles
        (Viewer_Frame, Viewer_Frame_Class_Part_Styles);
      Adi.Widget.Animated_Widget.Set_Part_Styles
        (Viewer, Viewer_Class_Part_Styles);
      Adi.Widget.Box.Set_Part_Styles (Controls, Controls_Class_Part_Styles);
      Adi.Widget.Label.Set_Part_Styles (Status, Status_Class_Part_Styles);

      Adi.Widget.Button.Set_Part_Styles
        (Btn_Start, Action_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Stop, Action_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Reset, Action_Button_Class_Part_Styles);
      Adi.Widget.Button.Set_Part_Styles
        (Btn_Loop, Loop_Button_Class_Part_Styles);

      Adi.Widget.Button.Set_Toggleable (Btn_Loop, True);
      Adi.Widget.Button.Set_Toggled (Btn_Loop, True);

      Adi.Widget.Button.Connect_Clicked
        (Btn_Start, On_Start'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked
        (Btn_Stop, On_Stop'Unrestricted_Access);
      Adi.Widget.Button.Connect_Clicked
        (Btn_Reset, On_Reset'Unrestricted_Access);
      Adi.Widget.Button.Connect_Toggled
        (Btn_Loop, On_Loop_Toggled'Unrestricted_Access);

      Add_Child (+Root, +Header);
      Add_Child (+Header, +Title);
      Add_Child (+Header, +Subtitle);

      Add_Child (+Root, +Viewer_Frame);
      Add_Child (+Viewer_Frame, +Viewer);

      Add_Child (+Root, +Controls);
      Add_Child (+Controls, +Btn_Start);
      Add_Child (+Controls, +Btn_Stop);
      Add_Child (+Controls, +Btn_Reset);
      Add_Child (+Controls, +Btn_Loop);

      Add_Child (+Root, +Status);

      Animation :=
        Adi.Animated_Image.Load_From_File ("examples/assets/animhorse.gif");
      if Animation = null then
         Adi.Widget.Label.Set_Text (Status, "Failed to load animhorse.gif");
      else
         Adi.Widget.Animated_Widget.Set_Animation (Viewer, Animation);
         Adi.Widget.Animated_Widget.Set_Looping (Viewer, True);
         Adi.Widget.Label.Set_Text
           (Status,
            "Loaded Animhorse.gif (" &
            Get_Frame_Count (Animation.all)'Image & " frames)");
      end if;

      Adi.Window.Set_Root (W, Widget_Handle'(+Root));
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
      A.Run;
      Adi.MCP.Finalize;
   end;
end Animated_Image_Example;
