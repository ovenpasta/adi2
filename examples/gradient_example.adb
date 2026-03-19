pragma Ada_2022;
with Adi.App;
with Adi.Window;          use Adi.Window;
with Gradient_Example_UI;

procedure Gradient_Example is
   A  : Adi.App.App;
   package UI is new Gradient_Example_UI.Instance;
   W  : Window_Handle;
begin
   A.Init;
   A.Set_Target_FPS (60);
   W := UI.Build;
   A.Add_Window (W);
   A.Run;
end Gradient_Example;
