pragma Ada_2022;

with Adi.App;
with Adi.Assets;
with Adi.Window; use Adi.Window;
with Assets_Example_UI;

procedure Assets_Example is
   A : Adi.App.App;
   package UI is new Assets_Example_UI.Instance;
   W : Window_Access;
begin
   A.Init;
   Adi.Assets.Add_Path ("examples/assets");
   W := UI.Build;
   A.Add_Window (W);
   A.Run;
end Assets_Example;
