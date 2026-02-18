pragma Ada_2022;

with Adi.SDL.Events; use Adi.SDL.Events;

package body Adi.Widget.Value_Input_Impl is

   ---------------------------------------------------------------------------
   --  Internal helpers
   ---------------------------------------------------------------------------

   function Clamp (V, Lo, Hi : Value_Type) return Value_Type is
   begin
      if V < Lo then
         return Lo;
      elsif Hi < V then
         return Hi;
      else
         return V;
      end if;
   end Clamp;

   function Is_Numeric_Char (C : Character) return Boolean is
   begin
      return C in '0' .. '9'
        or else C = '-'
        or else C = '+'
        or else (Allow_Decimal and then (C = '.' or else C = 'e' or else C = 'E'));
   end Is_Numeric_Char;

   procedure Update_Text_From_Value (W : in out Value_Input_Widget) is
   begin
      W.Updating_Text := True;
      Set_Text (W, Image (W.Num_Value));
      W.Updating_Text := False;
   end Update_Text_From_Value;

   procedure Fire_Value_Changed (W : in out Value_Input_Widget) is
      Self : constant Value_Input_Widget_Access := W'Unchecked_Access;
   begin
      if W.On_Val_Changed /= null then
         W.On_Val_Changed (Self, W.Num_Value);
      end if;
   end Fire_Value_Changed;

   procedure Apply_Step
     (W          : in out Value_Input_Widget;
      Up         : Boolean;
      Multiplier : Float := 1.0)
   is
      Step_F  : constant Float := To_Float (W.Step);
      Range_F : constant Float := To_Float (W.Max_Value - W.Min_Value);
      Inc     : Value_Type;
      Old_Val : constant Value_Type := W.Num_Value;
      New_Val : Value_Type;
   begin
      if Step_F > 0.0 then
         Inc := From_Float (Step_F * Multiplier);
      elsif Range_F > 0.0 then
         Inc := From_Float (Range_F / 100.0 * Multiplier);
      else
         return;
      end if;

      if Up then
         New_Val := Clamp (W.Num_Value + Inc, W.Min_Value, W.Max_Value);
      else
         New_Val := Clamp (W.Num_Value - Inc, W.Min_Value, W.Max_Value);
      end if;

      if To_Float (New_Val) /= To_Float (Old_Val) then
         W.Num_Value := New_Val;
         Update_Text_From_Value (W);
         Mark_Dirty (W);
         Fire_Value_Changed (W);
      end if;
   end Apply_Step;

   ---------------------------------------------------------------------------
   --  Public API
   ---------------------------------------------------------------------------

   function Create
     (Min   : Value_Type;
      Max   : Value_Type;
      Value : Value_Type) return Value_Input_Widget_Access
   is
      Result : constant Value_Input_Widget_Access := new Value_Input_Widget;
   begin
      Set_Flag (Result.all, Visible, True);
      Set_Flag (Result.all, Clickable, True);
      Set_Flag (Result.all, Focusable, True);
      Result.Min_Value := Min;
      Result.Max_Value := Max;
      Result.Num_Value := Clamp (Value, Min, Max);
      Result.Updating_Text := True;
      Set_Text (Result.all, Image (Result.Num_Value));
      Result.Updating_Text := False;
      return Result;
   end Create;

   procedure Set_Value (W : in out Value_Input_Widget; V : Value_Type) is
      Clamped : constant Value_Type := Clamp (V, W.Min_Value, W.Max_Value);
   begin
      W.Num_Value := Clamped;
      Update_Text_From_Value (W);
      Mark_Dirty (W);
   end Set_Value;

   function Get_Value (W : Value_Input_Widget) return Value_Type is
   begin
      return W.Num_Value;
   end Get_Value;

   procedure Set_Range (W : in out Value_Input_Widget;
                         Min, Max : Value_Type) is
   begin
      W.Min_Value := Min;
      W.Max_Value := Max;
      W.Num_Value := Clamp (W.Num_Value, Min, Max);
      Update_Text_From_Value (W);
      Mark_Dirty (W);
   end Set_Range;

   function Get_Min (W : Value_Input_Widget) return Value_Type is
   begin
      return W.Min_Value;
   end Get_Min;

   function Get_Max (W : Value_Input_Widget) return Value_Type is
   begin
      return W.Max_Value;
   end Get_Max;

   procedure Set_Step (W : in out Value_Input_Widget; S : Value_Type) is
   begin
      W.Step := S;
   end Set_Step;

   function Get_Step (W : Value_Input_Widget) return Value_Type is
   begin
      return W.Step;
   end Get_Step;

   procedure Set_On_Value_Changed (W  : in out Value_Input_Widget;
                                    CB : Value_Changed_Callback) is
   begin
      W.On_Val_Changed := CB;
   end Set_On_Value_Changed;

   ---------------------------------------------------------------------------
   --  Overrides
   ---------------------------------------------------------------------------

   overriding procedure On_Text_Input
     (W : in out Value_Input_Widget; Text : String)
   is
      Filtered : String (Text'Range);
      Len      : Natural := 0;
   begin
      --  Filter: only pass numeric characters to the parent
      for C of Text loop
         if Is_Numeric_Char (C) then
            Len := Len + 1;
            Filtered (Filtered'First + Len - 1) := C;
         end if;
      end loop;

      if Len > 0 then
         Text_Input_Widget (W).On_Text_Input
           (Filtered (Filtered'First .. Filtered'First + Len - 1));
      end if;
   end On_Text_Input;

   overriding procedure On_Key_Down
     (W        : in out Value_Input_Widget;
      Scancode : Adi.SDL.Events.SDL_Scancode;
      Key_Mod  : Adi.SDL.Events.SDL_Keymod;
      Repeat   : Boolean)
   is
   begin
      case Scancode is
         when SDL_SCANCODE_UP =>
            Apply_Step (W, Up => True);
            return;

         when SDL_SCANCODE_DOWN =>
            Apply_Step (W, Up => False);
            return;

         when SDL_SCANCODE_PAGEUP =>
            Apply_Step (W, Up => True, Multiplier => 10.0);
            return;

         when SDL_SCANCODE_PAGEDOWN =>
            Apply_Step (W, Up => False, Multiplier => 10.0);
            return;

         when SDL_SCANCODE_RETURN =>
            --  Commit on Enter: parse, clamp, reformat
            declare
               Text : constant String := Get_Text (W);
            begin
               W.Num_Value := Clamp (Parse (Text), W.Min_Value, W.Max_Value);
               Update_Text_From_Value (W);
               Mark_Dirty (W);
               Fire_Value_Changed (W);
            exception
               when others =>
                  Update_Text_From_Value (W);
                  Mark_Dirty (W);
            end;
            return;

         when others =>
            null;
      end case;

      --  Forward everything else to Text_Input
      Text_Input_Widget (W).On_Key_Down (Scancode, Key_Mod, Repeat);
   end On_Key_Down;

   overriding procedure On_Focus_Lost (W : in out Value_Input_Widget) is
   begin
      --  Parse current text, clamp, and reformat
      declare
         Text : constant String := Get_Text (W);
      begin
         W.Num_Value := Clamp (Parse (Text), W.Min_Value, W.Max_Value);
      exception
         when others =>
            null;  -- Keep current value on parse failure
      end;

      Update_Text_From_Value (W);
      Fire_Value_Changed (W);

      --  Call parent On_Focus_Lost
      Text_Input_Widget (W).On_Focus_Lost;
   end On_Focus_Lost;

   overriding procedure On_Mouse_Wheel
     (W                : in out Value_Input_Widget;
      Delta_X, Delta_Y : Pixel_Type)
   is
      pragma Unreferenced (Delta_X);
   begin
      if Delta_Y > 0.0 then
         Apply_Step (W, Up => True);
      elsif Delta_Y < 0.0 then
         Apply_Step (W, Up => False);
      end if;
   end On_Mouse_Wheel;

end Adi.Widget.Value_Input_Impl;
