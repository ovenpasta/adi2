pragma Ada_2022;

with Adi.App;
with Adi.Assets;
with Adi.Font;
with Adi.Window; use Adi.Window;
with Assets_Example_UI;
with Assets_Example_Bundle;

procedure Assets_Example is
   A : Adi.App.App;
   package UI is new Assets_Example_UI.Instance;
   W : Window_Handle;
begin
   A.Init;
   Assets_Example_Bundle.Register_All;
   Adi.Assets.Set_Mode (Adi.Assets.Bundle_Mode);

   --  Load bundled font and set as app default (replaces system fallback)
   Adi.Font.Set_Default_Font
     (Adi.Font.Load_Asset ("OpenSans-Regular.ttf"));

   W := UI.Build;
   A.Add_Window (W);
   A.Run;
end Assets_Example;
