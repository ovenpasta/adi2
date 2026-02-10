with Ada.Characters.Latin_1;
with Adi.CSS_Styles;          use Adi.CSS_Styles;
with Adi.Font;
with Adi.Layout_Util;         use Adi.Layout_Util;
with Adi.SDL.Events;          use Adi.SDL.Events;
with Adi.SDL.TTF;             use Adi.SDL.TTF;
with Adi.Text_Buffer;         use Adi.Text_Buffer;
with Interfaces.C;            use Interfaces.C;
with Interfaces.C.Strings;    use Interfaces.C.Strings;

package body Adi.Widget.Text_Input is

   Drag_Threshold_Px : constant Pixel_Type := 4.0;

   function Is_Mod_Active (Mods : SDL_Keymod; Mask : SDL_Keymod) return Boolean is
   begin
      return (Mods and Mask) /= 0;
   end Is_Mod_Active;

   function Is_UTF8_Continuation_Byte (C : Character) return Boolean is
      V : constant Natural := Character'Pos (C);
   begin
      return V in 16#80# .. 16#BF#;
   end Is_UTF8_Continuation_Byte;

   function Normalize_Column (Line : String; Col : Natural) return Natural;

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

   procedure Select_Word_At_Caret (W : in out Text_Input_Widget) is
      Line : constant String := Get_Line (W.Buffer, 1);
      Cur  : constant Position := Get_Caret (W.Buffer);
      C    : Natural := Normalize_Column (Line, Cur.Column);
      S    : Natural;
      E    : Natural;
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
      while S > 0 and then Is_Word_Char_At (Line, Prev_Column (Line, S)) = Want_Word loop
         S := Prev_Column (Line, S);
      end loop;

      E := Next_Column (Line, C);
      while E < Line'Length and then Is_Word_Char_At (Line, E) = Want_Word loop
         E := Next_Column (Line, E);
      end loop;

      Set_Caret (W.Buffer, (Line => 1, Column => S));
      Set_Caret (W.Buffer, (Line => 1, Column => E), Extend_Selection => True);
   end Select_Word_At_Caret;

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

   function Prefix_Width_For_Column
     (Label_Style : Resolved_Style;
      Line        : String;
      Col         : Natural) return Pixel_Type
   is
      use Interfaces.C;
      Safe_Col : constant Natural := Normalize_Column (Line, Col);
      Prefix   : constant String :=
        (if Safe_Col = 0 then ""
         else Line (1 .. Integer (Safe_Col)));
      Font_Attrs : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Float (Label_Style.Font_Size.Amount),
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      Font     : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      C_Text   : chars_ptr;
      W, H     : aliased int;
      Ok       : Adi.SDL.C_bool;
   begin
      if Prefix'Length = 0 or else Font = null then
         return 0.0;
      end if;

      C_Text := New_String (Prefix);
      Ok := TTF_GetStringSize
        (Font, C_Text, size_t (Prefix'Length), W'Access, H'Access);
      Free (C_Text);

      if not Boolean (Ok) then
         return 0.0;
      end if;
      return Pixel_Type (W);
   end Prefix_Width_For_Column;

   function Column_At_X
     (W : Text_Input_Widget;
      X : Pixel_Type) return Natural
   is
      use Interfaces.C;
      Main_Style  : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Label_Part);
      Content     : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Line        : constant String := Get_Line (W.Buffer, 1);
      Line_Len    : constant Natural := Line'Length;
      Font_Attrs  : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Float (Label_Style.Font_Size.Amount),
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      Font        : constant TTF_Font_Access := Adi.Font.Get_TTF_Font (Font_Attrs);
      Max_Width   : constant int := int
        (Integer
           (Pixel_Type'Max (0.0, X - Content.X + W.Horizontal_Scroll)));
      C_Text      : chars_ptr;
      Measured_W  : aliased int := 0;
      Measured_L  : aliased size_t := 0;
      Ok          : Adi.SDL.C_bool;
   begin
      if Line_Len = 0 or else Font = null then
         return 0;
      end if;

      C_Text := New_String (Line);
      Ok := TTF_MeasureString
        (Font            => Font,
         Text            => C_Text,
         Length          => size_t (Line_Len),
         Max_Width       => Max_Width,
         Measured_Width  => Measured_W'Access,
         Measured_Length => Measured_L'Access);
      Free (C_Text);

      if not Boolean (Ok) then
         return 0;
      end if;

      return Normalize_Column (Line, Natural (Measured_L));
   end Column_At_X;

   procedure Set_Caret_From_X
     (W                : in out Text_Input_Widget;
      X                : Pixel_Type;
      Extend_Selection : Boolean)
   is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Content    : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Line : constant String := Get_Line (W.Buffer, 1);
      Col  : Natural;
   begin
      if X < Content.X then
         Col := 0;
      else
         Col := Normalize_Column (Line, Column_At_X (W, X));
      end if;

      Set_Caret
        (B                => W.Buffer,
         P                => (Line => 1, Column => Col),
         Extend_Selection => Extend_Selection);
   end Set_Caret_From_X;

   procedure Fire_Changed (W : in out Text_Input_Widget) is
      Self : constant Text_Input_Widget_Access := W'Unchecked_Access;
   begin
      Mark_Dirty (W);
      if W.On_Changed /= null then
         W.On_Changed (Self, Get_Text (W));
      end if;
   end Fire_Changed;

   function Create (Text : String := "") return Text_Input_Widget_Access is
      Result : constant Text_Input_Widget_Access := new Text_Input_Widget;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);

      if Text'Length > 0 then
         Set_Text (Result.all, Text);
      else
         Clear (Result.Buffer);
      end if;
      return Result;
   end Create;

   procedure Set_Text (W : in out Text_Input_Widget; Text : String) is
   begin
      Set_Text (W.Buffer, Text);
      Mark_Dirty (W);
   end Set_Text;

   function Get_Text (W : Text_Input_Widget) return String is
   begin
      return Get_Text (W.Buffer);
   end Get_Text;

   procedure Set_On_Changed (W : in out Text_Input_Widget;
                             CB : Change_Callback) is
   begin
      W.On_Changed := CB;
   end Set_On_Changed;

   overriding function Measure_Content (W : Text_Input_Widget) return Size_2D is
      Main_Style  : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Label_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Label_Part);
      Sample      : constant String := (if Get_Text (W)'Length = 0 then "M" else Get_Text (W));
      Font_Attrs  : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Label_Style.Font_Size.Amount,
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      Text_Size   : constant Size_2D :=
        Adi.Font.Measure_Text (Attrs => Font_Attrs, Content => Sample);
      Pad    : constant Edge_Pixels := Get_Padding_Px (Main_Style);
      Border : constant Edge_Pixels := Get_Border_Width_Px (Main_Style);
   begin
      return (Width  => Pixel_Type'Max (120.0, Text_Size.Width + Pad.Left + Pad.Right + Border.Left + Border.Right),
              Height => Pixel_Type'Max (28.0, Text_Size.Height + Pad.Top + Pad.Bottom + Border.Top + Border.Bottom));
   end Measure_Content;

   overriding procedure Layout (W : in out Text_Input_Widget) is
   begin
      null;
   end Layout;

   overriding procedure Build_Items (W : in out Text_Input_Widget) is
      Main_Style   : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Label_Style  : constant Resolved_Style := Get_Resolved_Part_Style (W, Label_Part);
      Content      : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Full_Text    : constant String := Get_Text (W.Buffer);
      First_Line   : constant String := Get_Line (W.Buffer, 1);
      Caret        : constant Position := Get_Caret (W.Buffer);
      Sel_Start    : Position;
      Sel_Stop     : Position;
      Has_Sel      : Boolean;
      Font_Attrs   : constant Adi.Font.Font_Attributes :=
        Adi.Font.Make_Attributes
          (Family     => Label_Style.Font_Family,
           Size       => Label_Style.Font_Size.Amount,
           Weight     => Label_Style.Font_Weight,
           Style      => Label_Style.Font_Style,
           Decoration => Label_Style.Text_Decoration);
      Text_Size    : constant Size_2D :=
        Adi.Font.Measure_Text (Attrs => Font_Attrs, Content => First_Line);
      Caret_Col    : constant Natural := Normalize_Column (First_Line, Caret.Column);
      Prefix_W     : constant Pixel_Type :=
        Prefix_Width_For_Column (Label_Style, First_Line, Caret_Col);
      Scroll_X     : Pixel_Type := Pixel_Type'Max (0.0, W.Horizontal_Scroll);
      Max_Scroll   : constant Pixel_Type :=
        Pixel_Type'Max (0.0, Text_Size.Width - Content.Width);
      Caret_Right  : constant Pixel_Type := Prefix_W + 1.0;
      Text_Y       : constant Pixel_Type := Content.Y + (Content.Height - Text_Size.Height) / 2.0;
      Cursor_H     : constant Pixel_Type := Pixel_Type'Min (Content.Height, Text_Size.Height);
      Cursor_Y     : constant Pixel_Type := Content.Y + (Content.Height - Cursor_H) / 2.0;
      Cursor_X     : Pixel_Type;
   begin
      if Content.Width <= 0.0 then
         Scroll_X := 0.0;
      elsif Prefix_W < Scroll_X then
         Scroll_X := Prefix_W;
      elsif Caret_Right > Scroll_X + Content.Width then
         Scroll_X := Caret_Right - Content.Width;
      end if;
      Scroll_X := Pixel_Type'Min (Pixel_Type'Max (0.0, Scroll_X), Max_Scroll);
      W.Horizontal_Scroll := Scroll_X;
      Cursor_X := Content.X + Prefix_W - Scroll_X;

      Get_Selection_Range (W.Buffer, Sel_Start, Sel_Stop, Has_Sel);

      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Add_Item (W, Make_Panel (Selected_Part, (0.0, 0.0, 0.0, 0.0), 1));
         Add_Item (W, Make_Text (Label_Part, Content, "", 2));
         W.Items.Reference (Text_Idx).Wrap_Text := False;
         Add_Item (W, Make_Panel (Cursor_Part, (0.0, 0.0, 0.0, 0.0), 3));
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;

      declare
         Sel_It : Item renames W.Items.Reference (Selection_Idx).Element.all;
      begin
         if Has_Sel and then Sel_Start.Line = 1 and then Sel_Stop.Line = 1 then
            declare
               Start_Col : constant Natural :=
                 Normalize_Column (First_Line, Sel_Start.Column);
               Stop_Col  : constant Natural :=
                 Normalize_Column (First_Line, Sel_Stop.Column);
               Start_X : constant Pixel_Type :=
                 Content.X + Prefix_Width_For_Column (Label_Style, First_Line, Start_Col) - Scroll_X;
               Stop_X  : constant Pixel_Type :=
                 Content.X + Prefix_Width_For_Column (Label_Style, First_Line, Stop_Col) - Scroll_X;
               Sel_Left  : constant Pixel_Type :=
                 Pixel_Type'Max (Content.X, Start_X);
               Sel_Right : constant Pixel_Type :=
                 Pixel_Type'Min (Content.X + Content.Width, Stop_X);
            begin
               Sel_It.Geometry := (X      => Sel_Left,
                                   Y      => Text_Y,
                                   Width  => Pixel_Type'Max (0.0, Sel_Right - Sel_Left),
                                   Height => Text_Size.Height);
            end;
         else
            Sel_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         end if;
      end;

      declare
         Text_It : Item renames W.Items.Reference (Text_Idx).Element.all;
      begin
         Text_It.Text_Content := To_Unbounded_String
           ((if Full_Text'Length = 0 then "" else First_Line));
         Text_It.Geometry := (X      => Content.X,
                              Y      => Text_Y,
                              Width  => Content.Width,
                              Height => Text_Size.Height);
         Text_It.Text_Offset_X := -Scroll_X;
      end;

      declare
         Cursor_It : Item renames W.Items.Reference (Cursor_Idx).Element.all;
      begin
         if Has_State (W, State_Focused) then
            Cursor_It.Geometry := (X      => Cursor_X,
                                   Y      => Cursor_Y,
                                   Width  => 1.0,
                                   Height => Cursor_H);
         else
            Cursor_It.Geometry := (0.0, 0.0, 0.0, 0.0);
         end if;
      end;
   end Build_Items;

   overriding procedure On_Key_Down
     (W        : in out Text_Input_Widget;
      Scancode : SDL_Scancode;
      Key_Mod  : SDL_Keymod;
      Repeat   : Boolean)
   is
      pragma Unreferenced (Repeat);
      Shift : constant Boolean := Is_Mod_Active (Key_Mod, SDL_KMOD_SHIFT);
      Ctrl  : constant Boolean := Is_Mod_Active (Key_Mod, SDL_KMOD_CTRL);
   begin
      if Ctrl and then Scancode = SDL_SCANCODE_A then
         Select_All (W.Buffer);
         Mark_Dirty (W);
         return;
      end if;

      case Scancode is
         when SDL_SCANCODE_BACKSPACE =>
            Delete_Backward (W.Buffer);
            Fire_Changed (W);

         when SDL_SCANCODE_DELETE =>
            Delete_Forward (W.Buffer);
            Fire_Changed (W);

         when SDL_SCANCODE_LEFT =>
            Move_Left (W.Buffer, Extend_Selection => Shift);
            Mark_Dirty (W);

         when SDL_SCANCODE_RIGHT =>
            Move_Right (W.Buffer, Extend_Selection => Shift);
            Mark_Dirty (W);

         when SDL_SCANCODE_HOME =>
            Move_Home (W.Buffer, Extend_Selection => Shift);
            Mark_Dirty (W);

         when SDL_SCANCODE_END =>
            Move_End (W.Buffer, Extend_Selection => Shift);
            Mark_Dirty (W);

         when others =>
            null;
      end case;
   end On_Key_Down;

   overriding procedure On_Text_Input (W : in out Text_Input_Widget; Text : String) is
   begin
      if Text'Length = 0 then
         return;
      end if;

      if (for some C of Text => C = Ada.Characters.Latin_1.LF) then
         return;  -- single-line widget
      end if;

      Insert_Text (W.Buffer, Text);
      Fire_Changed (W);
   end On_Text_Input;

   overriding procedure On_Focus_Gained (W : in out Text_Input_Widget) is
   begin
      Mark_Dirty (W);
   end On_Focus_Gained;

   overriding procedure On_Focus_Lost (W : in out Text_Input_Widget) is
   begin
      W.Drag_Selecting := False;
      W.Pending_Word_Select := False;
      Mark_Dirty (W);
   end On_Focus_Lost;

   overriding procedure On_Mouse_Down
     (W      : in out Text_Input_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button;
      Clicks : Natural := 1)
   is
      pragma Unreferenced (Y);
   begin
      if Button /= Left_Button then
         return;
      end if;

      W.Press_X := X;
      W.Press_Y := Y;
      Set_Caret_From_X (W, X, Extend_Selection => False);
      if Clicks >= 3 then
         Select_All (W.Buffer);
         W.Pending_Word_Select := False;
         W.Drag_Selecting := False;
      elsif Clicks = 2 then
         W.Pending_Word_Select := True;
         W.Drag_Selecting := False;
      else
         W.Pending_Word_Select := False;
         W.Drag_Selecting := True;
      end if;
      Mark_Dirty (W);
   end On_Mouse_Down;

   overriding procedure On_Mouse_Move
     (W    : in out Text_Input_Widget;
      X, Y : Pixel_Type)
   is
      pragma Unreferenced (Y);
   begin
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

      Set_Caret_From_X (W, X, Extend_Selection => True);
      Mark_Dirty (W);
   end On_Mouse_Move;

   overriding procedure On_Mouse_Up
     (W      : in out Text_Input_Widget;
      X, Y   : Pixel_Type;
      Button : Adi.Core.Mouse_Button)
   is
      pragma Unreferenced (Y);
   begin
      if Button /= Left_Button then
         return;
      end if;

      if W.Pending_Word_Select then
         Select_Word_At_Caret (W);
         W.Pending_Word_Select := False;
         W.Drag_Selecting := False;
         Mark_Dirty (W);
         return;
      end if;

      if W.Drag_Selecting then
         Set_Caret_From_X (W, X, Extend_Selection => True);
      end if;
      W.Drag_Selecting := False;
      Mark_Dirty (W);
   end On_Mouse_Up;

end Adi.Widget.Text_Input;
