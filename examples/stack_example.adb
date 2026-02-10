pragma Ada_2022;
with Adi.App;
with Adi.Window;        use Adi.Window;
with Adi.Widget;        use Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Label;
with Adi.Widget.Button; use Adi.Widget.Button;
with Adi.Widget.Button.Options;
with Adi.Widget.Stack;
with Stack_Example_Styles; use Stack_Example_Styles;

procedure Stack_Example is
   A : Adi.App.App;

   type Tab is (Red, Green, Blue);
   package My_Stack is new Adi.Widget.Stack (Tab);
   package Tab_Options is new Adi.Widget.Button.Options (Tab);

   Pages : My_Stack.Stack_Widget_Access;

   procedure On_Tab (Value : Tab) is
   begin
      Pages.Set_Active (Value);
   end On_Tab;

begin
   A.Init;
   A.Set_Target_FPS (60);

   declare
      W : constant Window_Access := Create_Window ("Stack Example", (600.0, 450.0));

      Root    : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Tab_Bar : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Btn_Red   : constant Button_Widget_Access := Create ("Red");
      Btn_Green : constant Button_Widget_Access := Create ("Green");
      Btn_Blue  : constant Button_Widget_Access := Create ("Blue");
      Tab_Group : aliased Tab_Options.Option_Group;

      --  Pages
      Page1 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title1 : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Red Page");
      Desc1  : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("This is the first page with a warm red background.");

      Page2 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title2 : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Green Page");
      Desc2  : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("This is the second page with a natural green background.");

      Page3 : constant Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title3 : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Blue Page");
      Desc3  : constant Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("This is the third page with a deep blue background.");
   begin
      Pages := My_Stack.Create;

      --  Tab group — shared enum makes the On_Changed callback type-safe
      Tab_Group.Set_Button (Red, Btn_Red);
      Tab_Group.Set_Button (Green, Btn_Green);
      Tab_Group.Set_Button (Blue, Btn_Blue);
      Tab_Group.Set_On_Changed (On_Tab'Unrestricted_Access);

      --  Apply styles
      Set_Part_Styles (Root.all, Root_Part_Styles);
      Set_Part_Styles (Tab_Bar.all, Tab_Bar_Part_Styles);

      Set_Part_Styles (Btn_Red.all, Tab_Left_Part_Styles);
      Set_Part_Styles (Btn_Green.all, Tab_Center_Part_Styles);
      Set_Part_Styles (Btn_Blue.all, Tab_Right_Part_Styles);

      Set_Part_Styles (Pages.all, Stack_Part_Styles);

      Set_Part_Styles (Page1.all, Page_Red_Part_Styles);
      Set_Part_Styles (Page2.all, Page_Green_Part_Styles);
      Set_Part_Styles (Page3.all, Page_Blue_Part_Styles);

      Set_Part_Styles (Title1.all, Page_Title_Part_Styles);
      Set_Part_Styles (Title2.all, Page_Title_Part_Styles);
      Set_Part_Styles (Title3.all, Page_Title_Part_Styles);

      Set_Part_Styles (Desc1.all, Page_Desc_Part_Styles);
      Set_Part_Styles (Desc2.all, Page_Desc_Part_Styles);
      Set_Part_Styles (Desc3.all, Page_Desc_Part_Styles);

      --  Build page content
      Page1.Add_Child (Title1);
      Page1.Add_Child (Desc1);

      Page2.Add_Child (Title2);
      Page2.Add_Child (Desc2);

      Page3.Add_Child (Title3);
      Page3.Add_Child (Desc3);

      --  Add pages to stack by enum key
      Pages.Add_Page (Red,   Page1);
      Pages.Add_Page (Green, Page2);
      Pages.Add_Page (Blue,  Page3);

      --  Build tab bar
      Tab_Bar.Add_Child (Btn_Red);
      Tab_Bar.Add_Child (Btn_Green);
      Tab_Bar.Add_Child (Btn_Blue);

      --  Assemble hierarchy
      Root.Add_Child (Tab_Bar);
      Root.Add_Child (Pages);

      W.Set_Root (Root);
      A.Add_Window (W);
      A.Run;
   end;
end Stack_Example;
