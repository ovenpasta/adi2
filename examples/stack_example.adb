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
      W : Window_Access := Create_Window ("Stack Example", (600.0, 450.0));

      Root    : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Tab_Bar : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;

      Btn_Red   : Button_Widget_Access := Create ("Red");
      Btn_Green : Button_Widget_Access := Create ("Green");
      Btn_Blue  : Button_Widget_Access := Create ("Blue");
      Tab_Group : aliased Tab_Options.Option_Group;

      --  Pages
      Page1 : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title1 : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Red Page");
      Desc1  : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("This is the first page with a warm red background.");

      Page2 : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title2 : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Green Page");
      Desc2  : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("This is the second page with a natural green background.");

      Page3 : Adi.Widget.Box.Box_Widget_Access := Adi.Widget.Box.Create;
      Title3 : Adi.Widget.Label.Label_Widget_Access :=
         Adi.Widget.Label.Create ("Blue Page");
      Desc3  : Adi.Widget.Label.Label_Widget_Access :=
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
      Add_Child (Page1.all, Widget_Access (Title1));
      Add_Child (Page1.all, Widget_Access (Desc1));

      Add_Child (Page2.all, Widget_Access (Title2));
      Add_Child (Page2.all, Widget_Access (Desc2));

      Add_Child (Page3.all, Widget_Access (Title3));
      Add_Child (Page3.all, Widget_Access (Desc3));

      --  Add pages to stack by enum key
      Pages.Add_Page (Red,   Widget_Access (Page1));
      Pages.Add_Page (Green, Widget_Access (Page2));
      Pages.Add_Page (Blue,  Widget_Access (Page3));

      --  Build tab bar
      Add_Child (Tab_Bar.all, Widget_Access (Btn_Red));
      Add_Child (Tab_Bar.all, Widget_Access (Btn_Green));
      Add_Child (Tab_Bar.all, Widget_Access (Btn_Blue));

      --  Assemble hierarchy
      Add_Child (Root.all, Widget_Access (Tab_Bar));
      declare
         P : constant access Widget'Class := Pages.all'Unchecked_Access;
      begin
         Add_Child (Root.all, Widget_Access (P));
      end;

      W.Set_Root (Widget_Access (Root));
      A.Add_Window (W);
      A.Run;
   end;
end Stack_Example;
