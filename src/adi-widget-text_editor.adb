with Ada.Characters.Latin_1;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.Font;
with Adi.Layout_Util;         use Adi.Layout_Util;
with Adi.SDL;
with Adi.SDL.Events;          use Adi.SDL.Events;
with Adi.SDL.TTF;             use Adi.SDL.TTF;
with Adi.Text_Layout;         use Adi.Text_Layout;
with Adi.Text_Buffer;         use Adi.Text_Buffer;
with Adi.Widget.Context_Menu;
with Adi.Widget.Text_Context_Menu;
with Adi.Window;

package body Adi.Widget.Text_Editor is

   Drag_Threshold_Px : constant Pixel_Type := 4.0;

   use type Adi.Widget.Context_Menu.Context_Menu_Access;

   type Menu_Binding is record
      Menu  : Adi.Widget.Context_Menu.Context_Menu_Access := null;
      Owner : Text_Editor_Widget_Access := null;
   end record;

   package Menu_Binding_Vectors is new Ada.Containers.Vectors
     (Positive, Menu_Binding);
   package Positive_Vectors is new Ada.Containers.Vectors (Positive, Positive);

   Menu_Bindings : Menu_Binding_Vectors.Vector;

   function Find_Owner_By_Menu
     (Menu : Adi.Widget.Context_Menu.Context_Menu_Access)
      return Text_Editor_Widget_Access
   is
   begin
      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Menu = Menu then
            return Menu_Bindings.Element (I).Owner;
         end if;
      end loop;
      return null;
   end Find_Owner_By_Menu;

   procedure Register_Menu_Binding
     (Menu  : Adi.Widget.Context_Menu.Context_Menu_Access;
      Owner : Text_Editor_Widget_Access)
   is
   begin
      if Menu = null then
         return;
      end if;

      for I in 1 .. Natural (Menu_Bindings.Length) loop
         if Menu_Bindings.Element (I).Menu = Menu then
            Menu_Bindings.Replace_Element (I, (Menu => Menu, Owner => Owner));
            return;
         end if;
      end loop;

      Menu_Bindings.Append
        (New_Item => Menu_Binding'(Menu => Menu, Owner => Owner));
   end Register_Menu_Binding;

   function Is_Mod_Active (Mods : SDL_Keymod; Mask : SDL_Keymod) return Boolean
   is
   begin
      return (Mods and Mask) /= 0;
   end Is_Mod_Active;

   function Is_UTF8_Continuation_Byte (C : Character) return Boolean is
      V : constant Natural := Character'Pos (C);
   begin
      return V in 16#80# .. 16#BF#;
   end Is_UTF8_Continuation_Byte;

   function Normalize_Column (Line : String; Col : Natural) return Natural is
      C : Natural := Natural'Min (Col, Line'Length);
   begin
      while C > 0
        and then Integer (C) < Line'Length
        and then Is_UTF8_Continuation_Byte (Line (Integer (C + 1)))
      loop
         C := C - 1;
      end loop;
      return C;
   end Normalize_Column;

   function Prev_Column (Line : String; Col : Natural) return Natural is
      C : Natural := Normalize_Column (Line, Col);
   begin
      if C = 0 then
         return 0;
      end if;
      C := C - 1;
      while C > 0
        and then Is_UTF8_Continuation_Byte (Line (Integer (C + 1)))
      loop
         C := C - 1;
      end loop;
      return C;
   end Prev_Column;

   function Next_Column (Line : String; Col : Natural) return Natural is
      C : Natural := Normalize_Column (Line, Col);
   begin
      if C >= Line'Length then
         return Line'Length;
      end if;
      C := C + 1;
      while C < Line'Length
        and then Is_UTF8_Continuation_Byte (Line (Integer (C + 1)))
      loop
         C := C + 1;
      end loop;
      return C;
   end Next_Column;

   function Is_Word_Char_At (Line : String; Col : Natural) return Boolean is
      B : Natural;
      C : Character;
   begin
      if Col >= Line'Length then
         return False;
      end if;

      B := Character'Pos (Line (Integer (Col + 1)));
      if B >= 16#80# then
         return True;
      end if;

      C := Line (Integer (Col + 1));
      return (C in 'a' .. 'z')
        or else (C in 'A' .. 'Z')
        or else (C in '0' .. '9')
        or else C = '_';
   end Is_Word_Char_At;

   procedure Ensure_Caret_Visible
     (W         : in out Text_Editor_Widget;
      Caret_Row : Positive;
      Content   : Rectangle) is
      Caret_Top  : Pixel_Type;
      Caret_Bot  : Pixel_Type;
      Offset     : Pixel_Type := Get_Scroll_Offset_Y (W);
      Max_Offset : Pixel_Type;
   begin
      if W.Line_Skip <= 0.0 or else Content.Height <= 0.0 then
         return;
      end if;

      Caret_Top := Pixel_Type (Caret_Row - 1) * W.Line_Skip;
      Caret_Bot := Caret_Top + W.Line_Skip;

      if Caret_Top < Offset then
         Offset := Caret_Top;
      elsif Caret_Bot > Offset + Content.Height then
         Offset := Caret_Bot - Content.Height;
      end if;

      Max_Offset := Pixel_Type'Max
        (0.0, W.Scroll_Content_H - W.Scroll_Viewport_H);
      Offset := Pixel_Type'Max (0.0, Pixel_Type'Min (Offset, Max_Offset));
      Set_Scroll_Offset_Y (W, Offset);
   end Ensure_Caret_Visible;

   procedure Refresh_Layout
     (W           : in out Text_Editor_Widget;
      Label_Style : Resolved_Style;
      Content     : Rectangle) is
   begin
      Rebuild (W.Layout, W.Buffer, Label_Style, Content.Width);
   end Refresh_Layout;

   procedure Move_Caret_By_Visual_Rows
     (W                : in out Text_Editor_Widget;
      Label_Style      : Resolved_Style;
      Content          : Rectangle;
      Delta_Rows       : Integer;
      Extend_Selection : Boolean)
   is
      Caret       : constant Position := Get_Caret (W.Buffer);
      Current_Row : Positive;
      Target_Row  : Positive;
      Row_Count_V : Natural;
      New_Pos     : Position;
   begin
      Refresh_Layout (W, Label_Style, Content);
      Row_Count_V := Row_Count (W.Layout);
      if Row_Count_V = 0 then
         return;
      end if;

      Current_Row := Row_Index_For_Position (W.Layout, W.Buffer, Caret);

      if not W.Has_Preferred_X then
         W.Preferred_Caret_X :=
           X_Offset_For_Column
             (W.Layout, W.Buffer, Label_Style, Current_Row, Caret.Column);
         W.Has_Preferred_X := True;
      end if;

      declare
         Target_I : Integer := Integer (Current_Row) + Delta_Rows;
      begin
         Target_I := Integer'Max (1, Integer'Min (Target_I, Integer (Row_Count_V)));
         Target_Row := Positive (Target_I);
      end;

      New_Pos :=
        Position_At_Row_X
          (W.Layout, W.Buffer, Label_Style, Target_Row, W.Preferred_Caret_X);
      Set_Caret (W.Buffer, New_Pos, Extend_Selection => Extend_Selection);
      Mark_Dirty (W);
   end Move_Caret_By_Visual_Rows;

   procedure Selection_Columns_For_Row
     (Row       : Visual_Row;
      Sel_Start : Position;
      Sel_Stop  : Position;
      Has_Sel   : Boolean;
      Show      : out Boolean;
      Start_Col : out Natural;
      End_Col   : out Natural)
   is
   begin
      Show := False;
      Start_Col := Row.Start_Column;
      End_Col := Row.Start_Column;

      if not Has_Sel then
         return;
      end if;

      if Row.Buffer_Line < Sel_Start.Line or else Row.Buffer_Line > Sel_Stop.Line then
         return;
      end if;

      if Row.Buffer_Line = Sel_Start.Line then
         Start_Col := Natural'Max (Row.Start_Column, Sel_Start.Column);
      end if;

      if Row.Buffer_Line = Sel_Stop.Line then
         End_Col := Natural'Min (Row.End_Column, Sel_Stop.Column);
      else
         End_Col := Row.End_Column;
      end if;

      if End_Col > Start_Col then
         Show := True;
      end if;
   end Selection_Columns_For_Row;

   procedure Select_Word_At_Caret (W : in out Text_Editor_Widget) is
      Caret : constant Position := Get_Caret (W.Buffer);
      Line  : constant String := Get_Line (W.Buffer, Caret.Line);
      C     : Natural := Normalize_Column (Line, Caret.Column);
      S     : Natural;
      E     : Natural;
      Want_Word : Boolean;
   begin
      if Line'Length = 0 then
         return;
      end if;

      if C = Line'Length and then C > 0 then
         C := Prev_Column (Line, C);
      end if;

      Want_Word := Is_Word_Char_At (Line, C);
      S := C;
      while S > 0
        and then Is_Word_Char_At (Line, Prev_Column (Line, S)) = Want_Word
      loop
         S := Prev_Column (Line, S);
      end loop;

      E := Next_Column (Line, C);
      while E < Line'Length
        and then Is_Word_Char_At (Line, E) = Want_Word
      loop
         E := Next_Column (Line, E);
      end loop;

      Set_Caret (W.Buffer, (Line => Caret.Line, Column => S));
      Set_Caret (W.Buffer, (Line => Caret.Line, Column => E),
                 Extend_Selection => True);
   end Select_Word_At_Caret;

   procedure Fire_Changed (W : in out Text_Editor_Widget'Class) is
      Self : constant Text_Editor_Widget_Access := W'Unchecked_Access;
   begin
      Mark_Dirty (W);
      if W.On_Changed /= null then
         W.On_Changed (Self, Get_Text (W));
      end if;
   end Fire_Changed;

   procedure On_Menu_Command_Applied
     (Menu         : Adi.Widget.Context_Menu.Context_Menu_Access;
      Command      : Adi.Widget.Text_Context_Menu.Text_Menu_Command;
      Changed_Text : Boolean)
   is
      pragma Unreferenced (Command);
      Owner : constant Text_Editor_Widget_Access := Find_Owner_By_Menu (Menu);
   begin
      if Owner = null then
         return;
      end if;

      if Changed_Text then
         Fire_Changed (Owner.all);
      else
         Mark_Dirty (Owner.all);
      end if;
   end On_Menu_Command_Applied;

   procedure Apply_Context_Menu_Styles (W : in out Text_Editor_Widget) is
   begin
      if W.Context_Menu = null then
         return;
      end if;

      if W.Has_Context_Menu_Styles then
         Adi.Widget.Context_Menu.Set_Menu_Part_Styles
           (W.Context_Menu.all, W.Context_Menu_Styles);
      end if;
      if W.Has_Context_Item_Styles then
         Adi.Widget.Context_Menu.Set_Item_Part_Styles
           (W.Context_Menu.all, W.Context_Item_Styles);
      end if;
   end Apply_Context_Menu_Styles;

   ---------------------------------------------------------------------------
   --  Public API
   ---------------------------------------------------------------------------

   function Create (Text : String := "") return Text_Editor_Widget_Access is
      Result : constant Text_Editor_Widget_Access := new Text_Editor_Widget;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);
      Set_Flag (Result.all, Scrollable, True);

      if Text'Length > 0 then
         Set_Text (Result.all, Text);
      else
         Clear (Result.Buffer);
      end if;
      return Result;
   end Create;

   procedure Attach_Window
     (W    : in out Text_Editor_Widget;
      Host : Adi.Window.Window_Access)
   is
      Self : constant Text_Editor_Widget_Access := W'Unchecked_Access;
   begin
      if W.Context_Menu = null then
         W.Context_Menu := Adi.Widget.Text_Context_Menu.Create_Default
           (Buffer      => W.Buffer'Unchecked_Access,
            Host        => Host,
            Single_Line => False,
            On_Applied  => On_Menu_Command_Applied'Access);
         Register_Menu_Binding (W.Context_Menu, Self);
         Adi.Widget.Text_Context_Menu.Bind_Widget_Request (W, W.Context_Menu);
      else
         Adi.Widget.Context_Menu.Attach_Window (W.Context_Menu.all, Host);
      end if;

      Apply_Context_Menu_Styles (W);
   end Attach_Window;

   procedure Set_Text (W : in out Text_Editor_Widget; Text : String) is
   begin
      Adi.Text_Buffer.Set_Text (W.Buffer, Text);
      W.Has_Preferred_X := False;
      Mark_Dirty (W);
   end Set_Text;

   function Get_Text (W : Text_Editor_Widget) return String is
   begin
      return Adi.Text_Buffer.Get_Text (W.Buffer);
   end Get_Text;

   procedure Set_Context_Menu_Part_Styles
     (W      : in out Text_Editor_Widget;
      Styles : Part_Style_Array)
   is
   begin
      W.Context_Menu_Styles := Styles;
      W.Has_Context_Menu_Styles := True;
      Apply_Context_Menu_Styles (W);
   end Set_Context_Menu_Part_Styles;

   procedure Set_Context_Menu_Item_Part_Styles
     (W      : in out Text_Editor_Widget;
      Styles : Part_Style_Array)
   is
   begin
      W.Context_Item_Styles := Styles;
      W.Has_Context_Item_Styles := True;
      Apply_Context_Menu_Styles (W);
   end Set_Context_Menu_Item_Part_Styles;

   procedure Set_On_Changed (W : in out Text_Editor_Widget;
                             CB : Change_Callback) is
   begin
      W.On_Changed := CB;
   end Set_On_Changed;

   ---------------------------------------------------------------------------
   --  Build_Items
   ---------------------------------------------------------------------------

   overriding procedure Build_Items (W : in out Text_Editor_Widget) is
      Main_Style   : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Label_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Label_Part);
      Content      : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Caret        : constant Position := Get_Caret (W.Buffer);

      Font_Attrs   : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Label_Style.Font_Size.Amount,
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      Font         : constant TTF_Font_Access :=
        Adi.Font.Get_TTF_Font (Font_Attrs);
      LS           : Pixel_Type;
      Sel_Start    : Position;
      Sel_Stop     : Position;
      Has_Sel      : Boolean;
      Vis_Sel      : Natural := 0;
      Visible_Rows : Positive_Vectors.Vector;
      Cursor_X     : Pixel_Type;
      Cursor_Y     : Pixel_Type;
      Total_Rows   : Natural;
      Caret_Row    : Positive;
      Row_It       : Visual_Row;
      Desired_Row_Items : Natural;
   begin
      --  Compute line skip
      if Font /= null then
         LS := Pixel_Type (TTF_GetFontLineSkip (Font));
      else
         LS := Pixel_Type (Label_Style.Font_Size.Amount);
      end if;
      if LS < 1.0 then
         LS := Pixel_Type (Label_Style.Font_Size.Amount);
      end if;
      W.Line_Skip := LS;

      Refresh_Layout (W, Label_Style, Content);
      Total_Rows := Row_Count (W.Layout);
      if Total_Rows = 0 then
         Total_Rows := 1;
      end if;

      --  Total content height and scroll metrics
      W.Scroll_Content_H := Pixel_Type'Max (Pixel_Type (Total_Rows) * LS, Content.Height);
      W.Scroll_Viewport_H := Content.Height;

      --  Only snap scroll to caret when the caret actually moved (keyboard
      --  navigation, typing), not on every rebuild (which would fight mouse
      --  wheel / scrollbar scrolling).
      if Caret /= W.Last_Caret then
         W.Last_Caret := Caret;
         Caret_Row := Row_Index_For_Position (W.Layout, W.Buffer, Caret);
         Ensure_Caret_Visible (W, Caret_Row, Content);
      end if;

      --  Selection info
      Get_Selection_Range (W.Buffer, Sel_Start, Sel_Stop, Has_Sel);

      for I in 1 .. Row_Count (W.Layout) loop
         declare
            Top : constant Pixel_Type :=
              Pixel_Type (I - 1) * LS - Get_Scroll_Offset_Y (W);
            Bot : constant Pixel_Type := Top + LS;
            Show_Sel  : Boolean;
            Sel_From  : Natural;
            Sel_To    : Natural;
         begin
            if Bot > 0.0 and then Top < Content.Height then
               Visible_Rows.Append (I);
               Selection_Columns_For_Row
                 (Row       => Row_At (W.Layout, I),
                  Sel_Start => Sel_Start,
                  Sel_Stop  => Sel_Stop,
                  Has_Sel   => Has_Sel,
                  Show      => Show_Sel,
                  Start_Col => Sel_From,
                  End_Col   => Sel_To);
               if Show_Sel then
                  Vis_Sel := Vis_Sel + 1;
               end if;
            end if;
         end;
      end loop;
      Desired_Row_Items := Natural (Visible_Rows.Length);

      --  Resize items vector if needed
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         for I in 1 .. Vis_Sel loop
            Add_Item (W, Make_Panel (Selected_Part, (0.0, 0.0, 0.0, 0.0), 1));
         end loop;
         for I in 1 .. Desired_Row_Items loop
            Add_Item (W, Make_Text (Label_Part, Content, "", 2));
            W.Items.Reference (1 + Vis_Sel + I).Wrap_Text := False;
         end loop;
         Add_Item (W, Make_Panel (Cursor_Part, (0.0, 0.0, 0.0, 0.0), 3));
         W.Sel_Item_Count := Vis_Sel;
         W.Row_Item_Count := Desired_Row_Items;
         W.First_Row_Item_Idx := 2 + Vis_Sel;
         W.Cursor_Item_Idx := W.First_Row_Item_Idx + Desired_Row_Items;
      elsif Vis_Sel /= W.Sel_Item_Count or else Desired_Row_Items /= W.Row_Item_Count then
         Clear_Items (W);
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         for I in 1 .. Vis_Sel loop
            Add_Item (W, Make_Panel (Selected_Part, (0.0, 0.0, 0.0, 0.0), 1));
         end loop;
         for I in 1 .. Desired_Row_Items loop
            Add_Item (W, Make_Text (Label_Part, Content, "", 2));
            W.Items.Reference (1 + Vis_Sel + I).Wrap_Text := False;
         end loop;
         Add_Item (W, Make_Panel (Cursor_Part, (0.0, 0.0, 0.0, 0.0), 3));
         W.Sel_Item_Count := Vis_Sel;
         W.Row_Item_Count := Desired_Row_Items;
         W.First_Row_Item_Idx := 2 + Vis_Sel;
         W.Cursor_Item_Idx := W.First_Row_Item_Idx + Desired_Row_Items;
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

      if Has_Sel and then Vis_Sel > 0 then
         declare
            Sel_Idx : Natural := 0;
         begin
            for I in 1 .. Desired_Row_Items loop
               declare
                  R_Idx     : constant Positive := Visible_Rows.Element (I);
                  R         : constant Visual_Row := Row_At (W.Layout, R_Idx);
                  Row_Top   : constant Pixel_Type :=
                    Pixel_Type (R_Idx - 1) * LS - Get_Scroll_Offset_Y (W);
                  Show_Sel  : Boolean;
                  Sel_From  : Natural;
                  Sel_To    : Natural;
                  SX        : Pixel_Type;
                  EX        : Pixel_Type;
                  Line_Text : constant String := Get_Line (W.Buffer, R.Buffer_Line);
               begin
                  Selection_Columns_For_Row
                    (Row       => R,
                     Sel_Start => Sel_Start,
                     Sel_Stop  => Sel_Stop,
                     Has_Sel   => Has_Sel,
                     Show      => Show_Sel,
                     Start_Col => Sel_From,
                     End_Col   => Sel_To);

                  if Show_Sel then
                     Sel_Idx := Sel_Idx + 1;

                     SX := Content.X + X_Offset_For_Column
                       (W.Layout, W.Buffer, Label_Style, R_Idx, Sel_From);
                     EX := Content.X + X_Offset_For_Column
                       (W.Layout, W.Buffer, Label_Style, R_Idx, Sel_To);

                     if R.Buffer_Line < Sel_Stop.Line
                       and then Sel_To = R.End_Column
                       and then R.End_Column = Line_Text'Length
                     then
                        EX := EX + LS * 0.3;
                     end if;

                     SX := Pixel_Type'Max (Content.X, SX);
                     EX := Pixel_Type'Min (Content.X + Content.Width, EX);

                     declare
                        S_It : Item renames
                          W.Items.Reference (1 + Sel_Idx).Element.all;
                     begin
                        S_It.Geometry :=
                          (X      => SX,
                           Y      => Content.Y + Row_Top,
                           Width  => Pixel_Type'Max (0.0, EX - SX),
                           Height => LS);
                     end;
                  end if;
               end;
            end loop;
         end;
      end if;

      for I in 1 .. Desired_Row_Items loop
         declare
            R_Idx  : constant Positive := Visible_Rows.Element (I);
            Top    : constant Pixel_Type :=
              Pixel_Type (R_Idx - 1) * LS - Get_Scroll_Offset_Y (W);
            Text_It : Item renames
              W.Items.Reference (W.First_Row_Item_Idx + I - 1).Element.all;
         begin
            Row_It := Row_At (W.Layout, R_Idx);
            Text_It.Text_Content := To_Unbounded_String (Row_Text (W.Layout, W.Buffer, Row_It));
            Text_It.Geometry :=
              (X      => Content.X,
               Y      => Content.Y + Top,
               Width  => Content.Width,
               Height => LS);
            Text_It.Text_Offset_Y := 0.0;
            Text_It.Wrap_Text := False;
         end;
      end loop;

      Caret_Row := Row_Index_For_Position (W.Layout, W.Buffer, Caret);
      Cursor_X := Content.X + X_Offset_For_Column
        (W.Layout, W.Buffer, Label_Style, Caret_Row, Caret.Column);
      Cursor_Y := Content.Y + Pixel_Type (Caret_Row - 1) * LS - Get_Scroll_Offset_Y (W);

      declare
         Cur_It : Item renames
           W.Items.Reference (W.Cursor_Item_Idx).Element.all;
      begin
         if Has_State (W, State_Focused)
           and then Cursor_Y + LS > Content.Y
           and then Cursor_Y < Content.Y + Content.Height
         then
            Cur_It.Geometry :=
              (X      => Cursor_X,
               Y      => Cursor_Y,
               Width  => 1.0,
               Height => LS);
         else
            Cur_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         end if;
      end;

      Update_Scrollbar_Geometry (W);
   end Build_Items;

   overriding procedure Layout (W : in out Text_Editor_Widget) is
   begin
      null;
   end Layout;

   overriding function Measure_Content
     (W : Text_Editor_Widget) return Size_2D
   is
      Main_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Pad         : constant Edge_Pixels := Get_Padding_Px (Main_Style);
      Border      : constant Edge_Pixels := Get_Border_Width_Px (Main_Style);
   begin
      --  Scrollable widget: return a modest preferred viewport size rather
      --  than the full text content height, so flex layout can shrink it.
      return
        (Width  => 200.0 + Pad.Left + Pad.Right + Border.Left + Border.Right,
         Height => 100.0 + Pad.Top + Pad.Bottom + Border.Top + Border.Bottom);
   end Measure_Content;

   ---------------------------------------------------------------------------
   --  Keyboard handling
   ---------------------------------------------------------------------------

   overriding procedure On_Key_Down
     (W        : in out Text_Editor_Widget;
      Scancode : SDL_Scancode;
      Key_Mod  : SDL_Keymod;
      Repeat   : Boolean)
   is
      pragma Unreferenced (Repeat);
      Shift : constant Boolean := Is_Mod_Active (Key_Mod, SDL_KMOD_SHIFT);
      Ctrl  : constant Boolean := Is_Mod_Active (Key_Mod, SDL_KMOD_CTRL);
      Lines_Per_Page : Positive;
   begin
      if Ctrl
        and then (Scancode = SDL_SCANCODE_Y
                  or else (Shift and then Scancode = SDL_SCANCODE_Z))
      then
         if Redo (W.Buffer) then
            W.Has_Preferred_X := False;
            Fire_Changed (W);
         end if;
         return;
      end if;

      if Ctrl and then Scancode = SDL_SCANCODE_Z then
         if Undo (W.Buffer) then
            W.Has_Preferred_X := False;
            Fire_Changed (W);
         end if;
         return;
      end if;

      --  Ctrl+A: Select All
      if Ctrl and then Scancode = SDL_SCANCODE_A then
         Select_All (W.Buffer);
         W.Has_Preferred_X := False;
         Mark_Dirty (W);
         return;
      end if;

      --  Ctrl+C: Copy
      if Ctrl and then Scancode = SDL_SCANCODE_C then
         if Copy_Selection_To_Clipboard (W.Buffer) then
            null;
         end if;
         return;
      end if;

      --  Ctrl+X: Cut
      if Ctrl and then Scancode = SDL_SCANCODE_X then
         if Cut_Selection_To_Clipboard (W.Buffer) then
            W.Has_Preferred_X := False;
            Fire_Changed (W);
         end if;
         return;
      end if;

      --  Ctrl+V: Paste
      if Ctrl and then Scancode = SDL_SCANCODE_V then
         if Paste_From_Clipboard (W.Buffer) then
            W.Has_Preferred_X := False;
            Fire_Changed (W);
         end if;
         return;
      end if;

      case Scancode is
         when SDL_SCANCODE_BACKSPACE =>
            Delete_Backward (W.Buffer);
            W.Has_Preferred_X := False;
            Fire_Changed (W);

         when SDL_SCANCODE_DELETE =>
            Delete_Forward (W.Buffer);
            W.Has_Preferred_X := False;
            Fire_Changed (W);

         when SDL_SCANCODE_RETURN =>
            Insert_Text (W.Buffer, [1 => Ada.Characters.Latin_1.LF]);
            W.Has_Preferred_X := False;
            Fire_Changed (W);

         when SDL_SCANCODE_TAB =>
            Insert_Text (W.Buffer, "   ");
            W.Has_Preferred_X := False;
            Fire_Changed (W);

         when SDL_SCANCODE_LEFT =>
            W.Has_Preferred_X := False;
            Move_Left (W.Buffer, Extend_Selection => Shift);
            Mark_Dirty (W);

         when SDL_SCANCODE_RIGHT =>
            W.Has_Preferred_X := False;
            Move_Right (W.Buffer, Extend_Selection => Shift);
            Mark_Dirty (W);

         when SDL_SCANCODE_UP =>
            declare
               Main_Style  : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Main_Part);
               Label_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Label_Part);
               Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);
            begin
               if Wrap_Enabled (Label_Style) then
                  Move_Caret_By_Visual_Rows
                    (W                => W,
                     Label_Style      => Label_Style,
                     Content          => Content,
                     Delta_Rows       => -1,
                     Extend_Selection => Shift);
               else
                  W.Has_Preferred_X := False;
                  Move_Up (W.Buffer, Extend_Selection => Shift);
                  Mark_Dirty (W);
               end if;
            end;

         when SDL_SCANCODE_DOWN =>
            declare
               Main_Style  : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Main_Part);
               Label_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Label_Part);
               Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);
            begin
               if Wrap_Enabled (Label_Style) then
                  Move_Caret_By_Visual_Rows
                    (W                => W,
                     Label_Style      => Label_Style,
                     Content          => Content,
                     Delta_Rows       => 1,
                     Extend_Selection => Shift);
               else
                  W.Has_Preferred_X := False;
                  Move_Down (W.Buffer, Extend_Selection => Shift);
                  Mark_Dirty (W);
               end if;
            end;

         when SDL_SCANCODE_HOME =>
            W.Has_Preferred_X := False;
            if Ctrl then
               Move_To_Start (W.Buffer, Extend_Selection => Shift);
            else
               Move_Home (W.Buffer, Extend_Selection => Shift);
            end if;
            Mark_Dirty (W);

         when SDL_SCANCODE_END =>
            W.Has_Preferred_X := False;
            if Ctrl then
               Move_To_End (W.Buffer, Extend_Selection => Shift);
            else
               Move_End (W.Buffer, Extend_Selection => Shift);
            end if;
            Mark_Dirty (W);

         when SDL_SCANCODE_PAGEUP =>
            if W.Line_Skip > 0.0 then
               Lines_Per_Page := Positive'Max
                 (1, Positive (Float'Floor
                   (Float (W.Scroll_Viewport_H / W.Line_Skip))));
            else
               Lines_Per_Page := 10;
            end if;
            declare
               Main_Style  : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Main_Part);
               Label_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Label_Part);
               Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);
            begin
               if Wrap_Enabled (Label_Style) then
                  Move_Caret_By_Visual_Rows
                    (W                => W,
                     Label_Style      => Label_Style,
                     Content          => Content,
                     Delta_Rows       => -Integer (Lines_Per_Page),
                     Extend_Selection => Shift);
               else
                  W.Has_Preferred_X := False;
                  Move_Page_Up (W.Buffer, Lines_Per_Page,
                                Extend_Selection => Shift);
                  Mark_Dirty (W);
               end if;
            end;

         when SDL_SCANCODE_PAGEDOWN =>
            if W.Line_Skip > 0.0 then
               Lines_Per_Page := Positive'Max
                 (1, Positive (Float'Floor
                   (Float (W.Scroll_Viewport_H / W.Line_Skip))));
            else
               Lines_Per_Page := 10;
            end if;
            declare
               Main_Style  : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Main_Part);
               Label_Style : constant Resolved_Style :=
                 Get_Resolved_Part_Style (W, Label_Part);
               Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);
            begin
               if Wrap_Enabled (Label_Style) then
                  Move_Caret_By_Visual_Rows
                    (W                => W,
                     Label_Style      => Label_Style,
                     Content          => Content,
                     Delta_Rows       => Integer (Lines_Per_Page),
                     Extend_Selection => Shift);
               else
                  W.Has_Preferred_X := False;
                  Move_Page_Down (W.Buffer, Lines_Per_Page,
                                  Extend_Selection => Shift);
                  Mark_Dirty (W);
               end if;
            end;

         when others =>
            null;
      end case;
   end On_Key_Down;

   overriding procedure On_Text_Input
     (W : in out Text_Editor_Widget; Text : String)
   is
   begin
      if Text'Length = 0 then
         return;
      end if;

      Insert_Text (W.Buffer, Text);
      W.Has_Preferred_X := False;
      Fire_Changed (W);
   end On_Text_Input;

   overriding procedure On_Focus_Gained (W : in out Text_Editor_Widget) is
   begin
      Mark_Dirty (W);
   end On_Focus_Gained;

   overriding procedure On_Focus_Lost (W : in out Text_Editor_Widget) is
   begin
      W.Drag_Selecting := False;
      W.Pending_Word_Select := False;
      W.Has_Preferred_X := False;
      Mark_Dirty (W);
   end On_Focus_Lost;

   ---------------------------------------------------------------------------
   --  Mouse handling
   ---------------------------------------------------------------------------

   overriding procedure On_Mouse_Down
     (W      : in out Text_Editor_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button;
      Clicks : Natural := 1)
   is
      Main_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Label_Part);
      Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      P           : Position;
   begin
      if Button /= Left_Button then
         return;
      end if;

      --  Try scrollbar first
      if Handle_Scroll_Mouse_Down (W, X, Y, Button) then
         return;
      end if;

      W.Press_X := X;
      W.Press_Y := Y;
      W.Has_Preferred_X := False;

      Refresh_Layout (W, Label_Style, Content);
      P :=
        Position_At_Point
          (L               => W.Layout,
           B               => W.Buffer,
           Label_Style     => Label_Style,
           Content_X       => Content.X,
           X               => X,
           Y               => Y - Content.Y,
           Scroll_Offset_Y => Get_Scroll_Offset_Y (W),
           Line_Skip       => W.Line_Skip);

      if Clicks >= 3 then
         declare
            LT : constant String := Get_Line (W.Buffer, P.Line);
         begin
            Set_Caret (W.Buffer, (Line => P.Line, Column => 0));
            Set_Caret (W.Buffer, (Line => P.Line, Column => LT'Length),
                       Extend_Selection => True);
         end;
         W.Pending_Word_Select := False;
         W.Drag_Selecting := False;
      elsif Clicks = 2 then
         Set_Caret (W.Buffer, P);
         W.Pending_Word_Select := True;
         W.Drag_Selecting := False;
      else
         Set_Caret (W.Buffer, P);
         W.Pending_Word_Select := False;
         W.Drag_Selecting := True;
      end if;
      Mark_Dirty (W);
   end On_Mouse_Down;

   overriding procedure On_Mouse_Move
     (W    : in out Text_Editor_Widget;
      X, Y : Pixel_Type)
   is
      Main_Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Label_Part);
      Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);
   begin
      Handle_Scroll_Mouse_Move (W, X, Y);

      if W.Pending_Word_Select then
         if abs (X - W.Press_X) > Drag_Threshold_Px
           or else abs (Y - W.Press_Y) > Drag_Threshold_Px
         then
            W.Pending_Word_Select := False;
            W.Drag_Selecting := True;
         else
            return;
         end if;
      end if;

      if not W.Drag_Selecting then
         return;
      end if;

      Refresh_Layout (W, Label_Style, Content);
      Set_Caret
        (W.Buffer,
         Position_At_Point
           (L               => W.Layout,
            B               => W.Buffer,
            Label_Style     => Label_Style,
            Content_X       => Content.X,
            X               => X,
            Y               => Y - Content.Y,
            Scroll_Offset_Y => Get_Scroll_Offset_Y (W),
            Line_Skip       => W.Line_Skip),
         Extend_Selection => True);
      Mark_Dirty (W);
   end On_Mouse_Move;

   overriding procedure On_Mouse_Up
     (W      : in out Text_Editor_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button)
   is
      pragma Unreferenced (X);
   begin
      Handle_Scroll_Mouse_Up (W, Button);

      if Button /= Left_Button then
         return;
      end if;

      if W.Pending_Word_Select then
         Select_Word_At_Caret (W);
         W.Has_Preferred_X := False;
         W.Pending_Word_Select := False;
         W.Drag_Selecting := False;
         Mark_Dirty (W);
         return;
      end if;

      W.Drag_Selecting := False;
      Mark_Dirty (W);
   end On_Mouse_Up;

   overriding procedure On_Mouse_Wheel
     (W                : in out Text_Editor_Widget;
      Delta_X, Delta_Y : Pixel_Type)
   is
   begin
      Handle_Scroll_Mouse_Wheel (W, Delta_X, Delta_Y);
   end On_Mouse_Wheel;

   overriding procedure On_Tick
     (W  : in out Text_Editor_Widget;
      DT : Duration)
   is
   begin
      Tick_Scroll_Animations (W, DT);
   end On_Tick;

end Adi.Widget.Text_Editor;
