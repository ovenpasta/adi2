pragma Ada_2022;

with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Tags;
with Ada.Text_IO;
with GNAT.OS_Lib;

with Adi.Core;                   use Adi.Core;
with Adi.CSS_Styles;             use Adi.CSS_Styles;
with Adi.JSON;
with Adi.Screenshot;
with Adi.SDL.Events;             use Adi.SDL.Events;
with Adi.SDL.Render;             use Adi.SDL.Render;
with Adi.Widget;                 use Adi.Widget;
with Adi.Widget.Introspection;   use Adi.Widget.Introspection;
with Adi.Widget.Label;
with Adi.Widget.Text_Input;
with Adi.Widget.Text_Editor;
with Adi.Widget_Styles;          use Adi.Widget_Styles;

package body Adi.MCP is

   Active     : Boolean := False;
   MCP_Dir    : Unbounded_String;
   MCP_Window : access Adi.Window.Window'Class := null;

   --  Connection IDs for signal-based disconnect in Finalize
   Frame_Conn       : Adi.Window.Frame_Signals.Connection_Id :=
     Adi.Window.Frame_Signals.No_Connection;
   Post_Render_Conn : Adi.Window.Post_Render_Signals.Connection_Id :=
     Adi.Window.Post_Render_Signals.No_Connection;

   --  Deferred screenshot: queued by the frame callback, executed by the
   --  post-render callback (which has a valid renderer with fresh content).
   Pending_Screenshot    : Boolean := False;
   Pending_Screenshot_Id : Unbounded_String;

   ---------------------------------------------------------------------------
   --  JSON Helpers
   ---------------------------------------------------------------------------

   function Escape_JSON_String (S : String) return String is
      Result : Unbounded_String;
   begin
      for C of S loop
         case C is
            when '"'    => Append (Result, "\""");
            when '\'    => Append (Result, "\\");
            when ASCII.BS  => Append (Result, "\b");
            when ASCII.HT  => Append (Result, "\t");
            when ASCII.LF  => Append (Result, "\n");
            when ASCII.FF  => Append (Result, "\f");
            when ASCII.CR  => Append (Result, "\r");
            when others =>
               if Character'Pos (C) < 32 or else Character'Pos (C) >= 128 then
                  declare
                     Hex : constant String := "0123456789abcdef";
                     Hi  : constant Natural := Character'Pos (C) / 16;
                     Lo  : constant Natural := Character'Pos (C) mod 16;
                  begin
                     Append (Result, "\u00");
                     Append (Result, Hex (Hex'First + Hi));
                     Append (Result, Hex (Hex'First + Lo));
                  end;
               else
                  Append (Result, C);
               end if;
         end case;
      end loop;
      return To_String (Result);
   end Escape_JSON_String;

   --  JSON key-value pair builders (append to Unbounded_String)
   procedure JKV_String
     (Buf : in out Unbounded_String;
      Key : String;
      Val : String;
      First : Boolean := False) is
   begin
      if not First then Append (Buf, ","); end if;
      Append (Buf, """" & Key & """:""" & Escape_JSON_String (Val) & """");
   end JKV_String;

   procedure JKV_Int
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Integer;
      First : Boolean := False) is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Integer'Image (Val), Ada.Strings.Left);
   begin
      if not First then Append (Buf, ","); end if;
      Append (Buf, """" & Key & """:" & Img);
   end JKV_Int;

   procedure JKV_Float
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Float;
      First : Boolean := False) is
      Img : constant String := Ada.Strings.Fixed.Trim
        (Float'Image (Val), Ada.Strings.Left);
   begin
      if not First then Append (Buf, ","); end if;
      Append (Buf, """" & Key & """:" & Img);
   end JKV_Float;

   procedure JKV_Bool
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Boolean;
      First : Boolean := False) is
   begin
      if not First then Append (Buf, ","); end if;
      if Val then
         Append (Buf, """" & Key & """:true");
      else
         Append (Buf, """" & Key & """:false");
      end if;
   end JKV_Bool;

   procedure JKV_Duration
     (Buf : in out Unbounded_String;
      Key : String;
      Val : Duration;
      First : Boolean := False) is
      Ms : constant Float := Float (Val) * 1000.0;
   begin
      JKV_Float (Buf, Key, Ms, First);
   end JKV_Duration;

   ---------------------------------------------------------------------------
   --  File Helpers
   ---------------------------------------------------------------------------

   function Read_File (Path : String) return String is
      use Ada.Text_IO;
      F      : File_Type;
      Result : Unbounded_String;
      Line   : String (1 .. 4096);
      Last   : Natural;
   begin
      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         Get_Line (F, Line, Last);
         if Length (Result) > 0 then
            Append (Result, ASCII.LF);
         end if;
         Append (Result, Line (1 .. Last));
      end loop;
      Close (F);
      return To_String (Result);
   exception
      when others =>
         if Is_Open (F) then Close (F); end if;
         return "";
   end Read_File;

   procedure Write_File (Path : String; Content : String) is
      use Ada.Text_IO;
      F : File_Type;
   begin
      Create (F, Out_File, Path);
      Put (F, Content);
      Close (F);
   exception
      when others =>
         if Is_Open (F) then Close (F); end if;
   end Write_File;

   procedure Atomic_Write (Path : String; Content : String) is
      Tmp     : constant String := Path & ".tmp";
      Success : Boolean;
   begin
      Write_File (Tmp, Content);
      GNAT.OS_Lib.Rename_File (Tmp, Path, Success);
      if not Success then
         Write_File (Path, Content);
         Ada.Directories.Delete_File (Tmp);
      end if;
   end Atomic_Write;

   ---------------------------------------------------------------------------
   --  Command Parsing (uses json-ada)
   ---------------------------------------------------------------------------

   function JSON_Get_String
     (JSON_Text : String; Key : String) return String
   is
      use Adi.JSON;
      P    : Parsers.Parser := Parsers.Create (JSON_Text);
      Root : constant Types.JSON_Value := P.Parse;
   begin
      if Root.Contains (Key) then
         return Root.Get (Key).Value;
      else
         return "";
      end if;
   exception
      when others => return "";
   end JSON_Get_String;

   function JSON_Get_Int
     (JSON_Text : String; Key : String; Default : Integer := 0) return Integer
   is
      use Adi.JSON;
      P    : Parsers.Parser := Parsers.Create (JSON_Text);
      Root : constant Types.JSON_Value := P.Parse;
   begin
      if Root.Contains (Key) then
         return Integer (Long_Integer'(Root.Get (Key).Value));
      end if;
      return Default;
   exception
      when others => return Default;
   end JSON_Get_Int;

   function JSON_Get_Bool
     (JSON_Text : String; Key : String; Default : Boolean := False)
      return Boolean
   is
      use Adi.JSON;
      P    : Parsers.Parser := Parsers.Create (JSON_Text);
      Root : constant Types.JSON_Value := P.Parse;
   begin
      if Root.Contains (Key) then
         return Boolean'(Root.Get (Key).Value);
      end if;
      return Default;
   exception
      when others => return Default;
   end JSON_Get_Bool;

   ---------------------------------------------------------------------------
   --  Error Response Helper
   ---------------------------------------------------------------------------

   function Error_Response (Req_Id : String; Msg : String) return String is
      Buf : Unbounded_String;
   begin
      Append (Buf, "{");
      JKV_String (Buf, "status", "error", First => True);
      JKV_String (Buf, "req_id", Req_Id);
      JKV_String (Buf, "error", Msg);
      Append (Buf, "}");
      return To_String (Buf);
   end Error_Response;

   ---------------------------------------------------------------------------
   --  Widget Resolution (by ID or path, scanning root + overlays)
   ---------------------------------------------------------------------------

   function Resolve_Widget
     (JSON   : String;
      Result_Path : out Unbounded_String) return Widget_Access
   is
      Id       : constant Integer := JSON_Get_Int (JSON, "id");
      Path_Str : constant String := JSON_Get_String (JSON, "path");
      Root     : constant Widget_Access :=
        Adi.Window.Get_Root (MCP_Window.all);
   begin
      Result_Path := Null_Unbounded_String;

      if Id > 0 then
         --  Search by ID: root first, then overlays
         if Root /= null then
            declare
               W : constant Widget_Access := Find_By_Id (Root, Id);
            begin
               if W /= null then
                  Result_Path := To_Unbounded_String (Find_Path (Root, W));
                  return W;
               end if;
            end;
         end if;
         for I in 1 .. Adi.Window.Overlay_Count (MCP_Window.all) loop
            declare
               OV : constant Widget_Access :=
                 Adi.Window.Get_Overlay (MCP_Window.all, I);
               W  : constant Widget_Access := Find_By_Id (OV, Id);
            begin
               if W /= null then
                  Result_Path := To_Unbounded_String
                    ("overlay" & Ada.Strings.Fixed.Trim
                       (Positive'Image (I), Ada.Strings.Left) &
                     ":" & Find_Path (OV, W));
                  return W;
               end if;
            end;
         end loop;
         return null;

      elsif Path_Str'Length > 0 then
         --  Search by path: root first, then overlays.
         --  Overlay paths use "overlayN:subpath" syntax (e.g. "overlay1:1.2").
         declare
            use Ada.Strings.Fixed;
            Colon : constant Natural := Index (Path_Str, ":");
         begin
            if Colon > 0
              and then Path_Str'Length >= 8
              and then Path_Str (Path_Str'First .. Path_Str'First + 6)
                         = "overlay"
            then
               --  Overlay path: "overlayN:subpath"
               declare
                  OV_Idx_Str : constant String :=
                    Path_Str (Path_Str'First + 7 .. Colon - 1);
                  OV_Idx     : constant Positive :=
                    Positive'Value (OV_Idx_Str);
                  Sub_Path   : constant String :=
                    Path_Str (Colon + 1 .. Path_Str'Last);
                  OV_Count   : constant Natural :=
                    Adi.Window.Overlay_Count (MCP_Window.all);
               begin
                  if OV_Idx <= OV_Count then
                     declare
                        OV : constant Widget_Access :=
                          Adi.Window.Get_Overlay (MCP_Window.all, OV_Idx);
                        W  : constant Widget_Access :=
                          Find_By_Path (OV, Sub_Path);
                     begin
                        if W /= null then
                           Result_Path := To_Unbounded_String (Path_Str);
                           return W;
                        end if;
                     end;
                  end if;
               end;
               return null;
            end if;
         exception
            when Constraint_Error => null;
         end;

         --  Plain root path
         if Root /= null then
            declare
               W : constant Widget_Access := Find_By_Path (Root, Path_Str);
            begin
               if W /= null then
                  Result_Path := To_Unbounded_String (Path_Str);
                  return W;
               end if;
            end;
         end if;

         --  Fallback: try each overlay with the plain path
         for I in 1 .. Adi.Window.Overlay_Count (MCP_Window.all) loop
            declare
               OV : constant Widget_Access :=
                 Adi.Window.Get_Overlay (MCP_Window.all, I);
               W  : constant Widget_Access := Find_By_Path (OV, Path_Str);
            begin
               if W /= null then
                  Result_Path := To_Unbounded_String
                    ("overlay" & Ada.Strings.Fixed.Trim
                       (Positive'Image (I), Ada.Strings.Left) &
                     ":" & Path_Str);
                  return W;
               end if;
            end;
         end loop;
         return null;

      else
         --  No id or path: return root
         if Root /= null then
            Result_Path := To_Unbounded_String ("");
         end if;
         return Root;
      end if;
   end Resolve_Widget;

   ---------------------------------------------------------------------------
   --  Widget Tree Serialization
   ---------------------------------------------------------------------------

   procedure Serialize_Widget_Tree
     (W    : Widget_Access;
      Path : String;
      Buf  : in out Unbounded_String)
   is
      use Adi.Widget.Introspection;
      Info : constant Widget_Info := Get_Info (W, Path);
      Txt  : constant String := To_String (Info.Text);
   begin
      Append (Buf, "{");
      JKV_String (Buf, "type", To_String (Info.Tag_Name), First => True);
      JKV_Int (Buf, "id", Info.Id);
      JKV_String (Buf, "path", Path);
      JKV_Float (Buf, "x", Float (Info.Geometry.X));
      JKV_Float (Buf, "y", Float (Info.Geometry.Y));
      JKV_Float (Buf, "w", Float (Info.Geometry.Width));
      JKV_Float (Buf, "h", Float (Info.Geometry.Height));

      --  Text (truncated to 200 chars in tree view)
      if Txt'Length > 0 then
         if Txt'Length <= 200 then
            JKV_String (Buf, "text", Txt);
         else
            JKV_String (Buf, "text", Txt (Txt'First .. Txt'First + 199));
         end if;
      end if;

      --  States
      declare
         S_Buf  : Unbounded_String;
         First_S : Boolean := True;
      begin
         Append (S_Buf, "[");
         for St in Widget_State loop
            if Info.States (St) then
               if not First_S then Append (S_Buf, ","); end if;
               Append (S_Buf, """" &
                 Ada.Characters.Handling.To_Lower
                   (Widget_State'Image (St)) & """");
               First_S := False;
            end if;
         end loop;
         Append (S_Buf, "]");
         Append (Buf, ",""states"":" & To_String (S_Buf));
      end;

      JKV_Bool (Buf, "visible", Info.Flags (Visible));
      JKV_Bool (Buf, "clickable", Info.Flags (Clickable));
      JKV_Bool (Buf, "focusable", Info.Flags (Focusable));

      JKV_Int (Buf, "child_count", Info.Child_Count);
      JKV_Int (Buf, "items_count", Info.Items_Count);

      --  Children
      if Info.Child_Count > 0 then
         Append (Buf, ",""children"":[");
         for I in 1 .. Info.Child_Count loop
            if I > 1 then Append (Buf, ","); end if;
            declare
               Child_Path : constant String :=
                 (if Path'Length = 0
                  then Ada.Strings.Fixed.Trim
                    (Positive'Image (I), Ada.Strings.Left)
                  else Path & "." & Ada.Strings.Fixed.Trim
                    (Positive'Image (I), Ada.Strings.Left));
               C : constant Widget_Access := Get_Child (W.all, I);
            begin
               Serialize_Widget_Tree (C, Child_Path, Buf);
            end;
         end loop;
         Append (Buf, "]");
      end if;

      Append (Buf, "}");
   end Serialize_Widget_Tree;

   ---------------------------------------------------------------------------
   --  Widget Info Serialization
   ---------------------------------------------------------------------------

   procedure Serialize_Widget_Info
     (W    : Widget_Access;
      Path : String;
      Buf  : in out Unbounded_String)
   is
      Info : constant Widget_Info := Get_Info (W, Path);
   begin
      Append (Buf, "{");
      JKV_String (Buf, "type", To_String (Info.Tag_Name), First => True);
      JKV_Int (Buf, "id", Info.Id);
      JKV_String (Buf, "path", Path);
      JKV_String (Buf, "text", To_String (Info.Text));
      JKV_Float (Buf, "x", Float (Info.Geometry.X));
      JKV_Float (Buf, "y", Float (Info.Geometry.Y));
      JKV_Float (Buf, "w", Float (Info.Geometry.Width));
      JKV_Float (Buf, "h", Float (Info.Geometry.Height));
      JKV_Int (Buf, "child_count", Info.Child_Count);
      JKV_Int (Buf, "items_count", Info.Items_Count);

      --  States
      for St in Widget_State loop
         JKV_Bool (Buf, "state_" &
           Ada.Characters.Handling.To_Lower (Widget_State'Image (St)),
           Info.States (St));
      end loop;

      --  Flags
      for Fl in Widget_Flag loop
         JKV_Bool (Buf, "flag_" &
           Ada.Characters.Handling.To_Lower (Widget_Flag'Image (Fl)),
           Info.Flags (Fl));
      end loop;

      Append (Buf, "}");
   end Serialize_Widget_Info;

   ---------------------------------------------------------------------------
   --  Match Serialization
   ---------------------------------------------------------------------------

   procedure Serialize_Match
     (M     : Widget_Match;
      Buf   : in out Unbounded_String;
      First : Boolean := False)
   is
   begin
      if not First then Append (Buf, ","); end if;
      Append (Buf, "{");
      JKV_Int (Buf, "id", M.Id, First => True);
      JKV_String (Buf, "path", To_String (M.Path));
      JKV_String (Buf, "type", To_String (M.Tag_Name));
      JKV_String (Buf, "text", To_String (M.Text));
      Append (Buf, "}");
   end Serialize_Match;

   procedure Serialize_Matches
     (Matches : Match_Vectors.Vector;
      Buf     : in out Unbounded_String)
   is
      First_M : Boolean := True;
   begin
      Append (Buf, "[");
      for M of Matches loop
         Serialize_Match (M, Buf, First => First_M);
         First_M := False;
      end loop;
      Append (Buf, "]");
   end Serialize_Matches;

   ---------------------------------------------------------------------------
   --  CSS Value Serialization
   ---------------------------------------------------------------------------

   function Serialize_Color (C : Color_Value) return String is
   begin
      case C.Kind is
         when Named =>
            return Ada.Characters.Handling.To_Lower
              (Named_Color'Image (C.Name));
         when RGB =>
            return "rgb(" &
              Ada.Strings.Fixed.Trim (Natural'Image (C.R), Ada.Strings.Left) &
              "," &
              Ada.Strings.Fixed.Trim (Natural'Image (C.G), Ada.Strings.Left) &
              "," &
              Ada.Strings.Fixed.Trim (Natural'Image (C.B), Ada.Strings.Left) &
              ")";
         when RGBA =>
            return "rgba(" &
              Ada.Strings.Fixed.Trim
                (Natural'Image (C.RA), Ada.Strings.Left) & "," &
              Ada.Strings.Fixed.Trim
                (Natural'Image (C.GA), Ada.Strings.Left) & "," &
              Ada.Strings.Fixed.Trim
                (Natural'Image (C.BA), Ada.Strings.Left) & "," &
              Ada.Strings.Fixed.Trim
                (Float'Image (C.Alpha), Ada.Strings.Left) & ")";
      end case;
   end Serialize_Color;

   function Serialize_Length (L : Length_Value) return String is
      Amt : constant String := Ada.Strings.Fixed.Trim
        (Float'Image (L.Amount), Ada.Strings.Left);
   begin
      case L.Unit is
         when Px      => return Amt & "px";
         when Dip     => return Amt & "dip";
         when Em      => return Amt & "em";
         when Root_Em => return Amt & "rem";
         when Pct     => return Amt & "%";
         when Vw      => return Amt & "vw";
         when Vh      => return Amt & "vh";
      end case;
   end Serialize_Length;

   function Serialize_Size (S : Size_Value) return String is
   begin
      case S.Kind is
         when Fixed       => return Serialize_Length (S.Size);
         when Auto        => return "auto";
         when Min_Content => return "min-content";
         when Max_Content => return "max-content";
         when Fit_Content => return "fit-content";
      end case;
   end Serialize_Size;

   procedure Serialize_CSS_Values
     (W    : not null Widget_Access;
      Part : Part_Kind;
      Buf  : in out Unbounded_String)
   is
      use Ada.Characters.Handling;
      S : constant Resolved_Style := Get_Resolved_Part_Style (W.all, Part);
   begin
      Append (Buf, "{");

      --  Colors
      JKV_String (Buf, "color", Serialize_Color (S.Color), First => True);
      JKV_String (Buf, "background_color",
                  Serialize_Color (S.Background_Color));

      --  Border width (4 edges)
      case S.Border_Width.Kind is
         when Gap_Uniform =>
            JKV_String (Buf, "border_width",
                        Serialize_Length (S.Border_Width.All_Edges));
         when Per_Edge =>
            JKV_String (Buf, "border_width_top",
                        Serialize_Length (S.Border_Width.Edges (Top)));
            JKV_String (Buf, "border_width_right",
                        Serialize_Length (S.Border_Width.Edges (Right)));
            JKV_String (Buf, "border_width_bottom",
                        Serialize_Length (S.Border_Width.Edges (Bottom)));
            JKV_String (Buf, "border_width_left",
                        Serialize_Length (S.Border_Width.Edges (Left)));
      end case;

      --  Border color (4 edges)
      case S.Border_Color.Kind is
         when Gap_Uniform =>
            JKV_String (Buf, "border_color",
                        Serialize_Color (S.Border_Color.All_Edges));
         when Per_Edge =>
            JKV_String (Buf, "border_color_top",
                        Serialize_Color (S.Border_Color.Edges (Top)));
            JKV_String (Buf, "border_color_right",
                        Serialize_Color (S.Border_Color.Edges (Right)));
            JKV_String (Buf, "border_color_bottom",
                        Serialize_Color (S.Border_Color.Edges (Bottom)));
            JKV_String (Buf, "border_color_left",
                        Serialize_Color (S.Border_Color.Edges (Left)));
      end case;

      --  Border radius (4 corners)
      case S.Border_Radius.Kind is
         when Gap_Uniform =>
            JKV_String (Buf, "border_radius",
                        Serialize_Length (S.Border_Radius.All_Corners));
         when Per_Corner =>
            JKV_String (Buf, "border_radius_tl",
                        Serialize_Length
                          (S.Border_Radius.Corners (Top_Left)));
            JKV_String (Buf, "border_radius_tr",
                        Serialize_Length
                          (S.Border_Radius.Corners (Top_Right)));
            JKV_String (Buf, "border_radius_br",
                        Serialize_Length
                          (S.Border_Radius.Corners (Bottom_Right)));
            JKV_String (Buf, "border_radius_bl",
                        Serialize_Length
                          (S.Border_Radius.Corners (Bottom_Left)));
      end case;

      --  Padding (4 sides)
      case S.Padding.Kind is
         when Gap_Uniform =>
            JKV_String (Buf, "padding",
                        Serialize_Length (S.Padding.All_Sides));
         when Axis =>
            JKV_String (Buf, "padding_vertical",
                        Serialize_Length (S.Padding.Vertical));
            JKV_String (Buf, "padding_horizontal",
                        Serialize_Length (S.Padding.Horizontal));
         when Per_Side =>
            JKV_String (Buf, "padding_top",
                        Serialize_Length (S.Padding.Sides (Top)));
            JKV_String (Buf, "padding_right",
                        Serialize_Length (S.Padding.Sides (Right)));
            JKV_String (Buf, "padding_bottom",
                        Serialize_Length (S.Padding.Sides (Bottom)));
            JKV_String (Buf, "padding_left",
                        Serialize_Length (S.Padding.Sides (Left)));
      end case;

      --  Margin (4 sides)
      case S.Margin.Kind is
         when Gap_Uniform =>
            JKV_String (Buf, "margin",
                        Serialize_Length (S.Margin.All_Sides));
         when Axis =>
            JKV_String (Buf, "margin_vertical",
                        Serialize_Length (S.Margin.Vertical));
            JKV_String (Buf, "margin_horizontal",
                        Serialize_Length (S.Margin.Horizontal));
         when Per_Side =>
            JKV_String (Buf, "margin_top",
                        Serialize_Length (S.Margin.Sides (Top)));
            JKV_String (Buf, "margin_right",
                        Serialize_Length (S.Margin.Sides (Right)));
            JKV_String (Buf, "margin_bottom",
                        Serialize_Length (S.Margin.Sides (Bottom)));
            JKV_String (Buf, "margin_left",
                        Serialize_Length (S.Margin.Sides (Left)));
      end case;

      --  Sizing
      JKV_String (Buf, "width", Serialize_Size (S.Width));
      JKV_String (Buf, "height", Serialize_Size (S.Height));
      JKV_String (Buf, "min_width", Serialize_Size (S.Min_Width));
      JKV_String (Buf, "max_width", Serialize_Size (S.Max_Width));
      JKV_String (Buf, "min_height", Serialize_Size (S.Min_Height));
      JKV_String (Buf, "max_height", Serialize_Size (S.Max_Height));

      --  Typography
      JKV_String (Buf, "font_size", Serialize_Length (S.Font_Size));
      JKV_String (Buf, "font_weight", To_Lower
        (Font_Weight_Value'Image (S.Font_Weight)));
      JKV_String (Buf, "font_style", To_Lower
        (Font_Style_Value'Image (S.Font_Style)));
      JKV_String (Buf, "text_align", To_Lower
        (Text_Align_Value'Image (S.Text_Align)));
      JKV_String (Buf, "vertical_align", To_Lower
        (Vertical_Align_Value'Image (S.Vertical_Align)));

      --  Layout
      JKV_String (Buf, "display", To_Lower
        (Display_Value'Image (S.Display)));
      JKV_String (Buf, "position", To_Lower
        (Position_Value'Image (S.Position)));
      JKV_String (Buf, "overflow_x", To_Lower
        (Overflow_Value'Image (S.Overflow_X)));
      JKV_String (Buf, "overflow_y", To_Lower
        (Overflow_Value'Image (S.Overflow_Y)));
      JKV_String (Buf, "visibility", To_Lower
        (Visibility_Value'Image (S.Visibility)));

      --  Flex
      JKV_String (Buf, "flex_direction", To_Lower
        (Flex_Direction_Value'Image (S.Flex_Direction)));
      JKV_String (Buf, "flex_wrap", To_Lower
        (Flex_Wrap_Value'Image (S.Flex_Wrap)));
      JKV_String (Buf, "justify_content", To_Lower
        (Justify_Content_Value'Image (S.Justify_Content)));
      JKV_String (Buf, "align_items", To_Lower
        (Align_Items_Value'Image (S.Align_Items)));

      --  Gap
      case S.Gap.Kind is
         when Gap_Uniform =>
            JKV_String (Buf, "gap", Serialize_Length (S.Gap.All_Gap));
         when Gap_Separate =>
            JKV_String (Buf, "row_gap", Serialize_Length (S.Gap.Row_Gap));
            JKV_String (Buf, "column_gap",
                        Serialize_Length (S.Gap.Column_Gap));
      end case;

      --  Visual
      JKV_Float (Buf, "opacity", Float (S.Opacity));
      JKV_String (Buf, "cursor", To_Lower
        (Cursor_Value'Image (S.Cursor)));

      Append (Buf, "}");
   end Serialize_CSS_Values;

   ---------------------------------------------------------------------------
   --  Part Name Resolution
   ---------------------------------------------------------------------------

   function Resolve_Part (Name : String) return Part_Kind is
      use Ada.Characters.Handling;
      LN : constant String := To_Lower (Name);
   begin
      if LN = "main" then return Main_Part;
      elsif LN = "label" then return Label_Part;
      elsif LN = "icon" then return Icon_Part;
      elsif LN = "text" then return Text_Part;
      elsif LN = "cursor" then return Cursor_Part;
      elsif LN = "selected" then return Selected_Part;
      elsif LN = "indicator" then return Indicator_Part;
      elsif LN = "scroll" then return Scroll_Part;
      elsif LN = "knob" then return Knob_Part;
      elsif LN = "items" then return Items_Part;
      else return Main_Part;
      end if;
   end Resolve_Part;

   ---------------------------------------------------------------------------
   --  send_keys: Key Token Parsing
   ---------------------------------------------------------------------------

   type Key_Token_Kind is (Char_Token, Named_Token);

   procedure Parse_And_Send_Keys
     (Win  : not null access Adi.Window.Window'Class;
      Keys : String)
   is
      I : Positive := Keys'First;
   begin
      while I <= Keys'Last loop
         if Keys (I) = '{' then
            --  Named key: find closing '}'
            declare
               Close : Natural := 0;
            begin
               for J in I + 1 .. Keys'Last loop
                  if Keys (J) = '}' then
                     Close := J;
                     exit;
                  end if;
               end loop;

               if Close = 0 then
                  --  Malformed: treat rest as literal
                  Adi.Window.On_Text_Input (Win.all, Keys (I .. I));
                  I := I + 1;
               else
                  declare
                     use Ada.Characters.Handling;
                     Name : constant String :=
                       To_Lower (Keys (I + 1 .. Close - 1));
                     SC   : SDL_Scancode := 0;
                  begin
                     if Name = "return" or else Name = "enter" then
                        SC := SDL_SCANCODE_RETURN;
                     elsif Name = "escape" or else Name = "esc" then
                        SC := SDL_SCANCODE_ESCAPE;
                     elsif Name = "backspace" then
                        SC := SDL_SCANCODE_BACKSPACE;
                     elsif Name = "tab" then
                        SC := SDL_SCANCODE_TAB;
                     elsif Name = "space" then
                        SC := SDL_SCANCODE_SPACE;
                     elsif Name = "delete" or else Name = "del" then
                        SC := SDL_SCANCODE_DELETE;
                     elsif Name = "home" then
                        SC := SDL_SCANCODE_HOME;
                     elsif Name = "end" then
                        SC := SDL_SCANCODE_END;
                     elsif Name = "pageup" then
                        SC := SDL_SCANCODE_PAGEUP;
                     elsif Name = "pagedown" then
                        SC := SDL_SCANCODE_PAGEDOWN;
                     elsif Name = "right" then
                        SC := SDL_SCANCODE_RIGHT;
                     elsif Name = "left" then
                        SC := SDL_SCANCODE_LEFT;
                     elsif Name = "down" then
                        SC := SDL_SCANCODE_DOWN;
                     elsif Name = "up" then
                        SC := SDL_SCANCODE_UP;
                     end if;

                     if SC /= 0 then
                        Adi.Window.On_Key_Down
                          (Win.all, SC, Key_Mod => 0, Repeat => False);
                        Adi.Window.On_Key_Up
                          (Win.all, SC, Key_Mod => 0, Repeat => False);
                     end if;
                  end;
                  I := Close + 1;
               end if;
            end;
         else
            --  Regular character: send as text input
            Adi.Window.On_Text_Input (Win.all, Keys (I .. I));
            I := I + 1;
         end if;
      end loop;
   end Parse_And_Send_Keys;

   ---------------------------------------------------------------------------
   --  Command Execution
   ---------------------------------------------------------------------------

   function Execute_Command
     (Cmd      : String;
      Req_Id   : String) return String
   is
   begin
      if Cmd = "widget_tree" then
         declare
            Root : constant Widget_Access :=
              Adi.Window.Get_Root (MCP_Window.all);
            Buf  : Unbounded_String;
         begin
            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            if Root /= null then
               Append (Buf, ",""tree"":");
               Serialize_Widget_Tree (Root, "", Buf);
            else
               Append (Buf, ",""tree"":null");
            end if;

            --  Overlays
            declare
               OC : constant Natural :=
                 Adi.Window.Overlay_Count (MCP_Window.all);
            begin
               if OC > 0 then
                  Append (Buf, ",""overlays"":[");
                  for I in 1 .. OC loop
                     if I > 1 then Append (Buf, ","); end if;
                     declare
                        OV : constant Widget_Access :=
                          Adi.Window.Get_Overlay (MCP_Window.all, I);
                     begin
                        Serialize_Widget_Tree
                          (OV,
                           "overlay" & Ada.Strings.Fixed.Trim
                             (Positive'Image (I), Ada.Strings.Left),
                           Buf);
                     end;
                  end loop;
                  Append (Buf, "]");
               end if;
            end;

            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "perf_stats" then
         declare
            Stats : constant Adi.Window.Frame_Stats :=
              Adi.Window.Get_Frame_Stats (MCP_Window.all);
            Buf   : Unbounded_String;
         begin
            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "frame_no", Stats.Frame_No);
            JKV_Int (Buf, "render_us", Stats.Render_Us);
            JKV_Int (Buf, "update_us", Stats.Update_Us);
            JKV_Int (Buf, "layout_us", Stats.Layout_Us);
            JKV_Int (Buf, "draw_us", Stats.Draw_Us);
            JKV_Int (Buf, "present_us", Stats.Present_Us);
            JKV_Duration (Buf, "last_dt_ms", Stats.Last_DT);
            JKV_Int (Buf, "layout_count", Stats.Layout_Count);
            if Stats.Last_DT > 0.0 then
               JKV_Float (Buf, "fps",
                 Float'Min (9999.0, 1.0 / Float (Stats.Last_DT)));
            else
               JKV_Float (Buf, "fps", 0.0);
            end if;
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "get_focus" then
         declare
            Focused : constant Widget_Access :=
              Adi.Window.Get_Focus (MCP_Window.all);
            Root    : constant Widget_Access :=
              Adi.Window.Get_Root (MCP_Window.all);
            Buf     : Unbounded_String;
         begin
            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            if Focused /= null and then Root /= null then
               declare
                  Path : constant String := Find_Path (Root, Focused);
               begin
                  Append (Buf, ",""widget"":");
                  Serialize_Widget_Info (Focused, Path, Buf);
               end;
            else
               Append (Buf, ",""widget"":null");
            end if;
            Append (Buf, "}");
            return To_String (Buf);
         end;

      else
         return Error_Response (Req_Id, "unknown command: " & Cmd);
      end if;
   end Execute_Command;

   --  Extended version that receives full JSON for commands with parameters
   function Execute_Command_Full
     (JSON     : String;
      Cmd      : String;
      Req_Id   : String) return String
   is
   begin
      if Cmd = "widget_info" then
         declare
            Resolved_Path : Unbounded_String;
            Target        : constant Widget_Access :=
              Resolve_Widget (JSON, Resolved_Path);
            Buf           : Unbounded_String;
         begin
            if Target = null then
               return Error_Response (Req_Id, "widget not found");
            end if;

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            Append (Buf, ",""widget"":");
            Serialize_Widget_Info
              (Target, To_String (Resolved_Path), Buf);
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "find_by_text" then
         declare
            Query : constant String := JSON_Get_String (JSON, "query");
            Exact : constant Boolean := JSON_Get_Bool (JSON, "exact");
            Root  : constant Widget_Access :=
              Adi.Window.Get_Root (MCP_Window.all);
            Results : Match_Vectors.Vector;
            Buf     : Unbounded_String;
         begin
            if Query'Length = 0 then
               return Error_Response (Req_Id, "missing query parameter");
            end if;

            if Root /= null then
               Results := Find_By_Text (Root, Query, Exact);
            end if;

            --  Search overlays too
            for I in 1 .. Adi.Window.Overlay_Count (MCP_Window.all) loop
               declare
                  OV      : constant Widget_Access :=
                    Adi.Window.Get_Overlay (MCP_Window.all, I);
                  OV_Hits : constant Match_Vectors.Vector :=
                    Find_By_Text (OV, Query, Exact);
               begin
                  for M of OV_Hits loop
                     Results.Append (M);
                  end loop;
               end;
            end loop;

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "count", Integer (Results.Length));
            Append (Buf, ",""matches"":");
            Serialize_Matches (Results, Buf);
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "find_by_type" then
         declare
            Type_Name : constant String :=
              JSON_Get_String (JSON, "type_name");
            Root    : constant Widget_Access :=
              Adi.Window.Get_Root (MCP_Window.all);
            Results : Match_Vectors.Vector;
            Buf     : Unbounded_String;
         begin
            if Type_Name'Length = 0 then
               return Error_Response (Req_Id, "missing type_name parameter");
            end if;

            if Root /= null then
               Results := Find_By_Type (Root, Type_Name);
            end if;

            for I in 1 .. Adi.Window.Overlay_Count (MCP_Window.all) loop
               declare
                  OV      : constant Widget_Access :=
                    Adi.Window.Get_Overlay (MCP_Window.all, I);
                  OV_Hits : constant Match_Vectors.Vector :=
                    Find_By_Type (OV, Type_Name);
               begin
                  for M of OV_Hits loop
                     Results.Append (M);
                  end loop;
               end;
            end loop;

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "count", Integer (Results.Length));
            Append (Buf, ",""matches"":");
            Serialize_Matches (Results, Buf);
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "click_widget" then
         declare
            Id_Val        : constant Integer := JSON_Get_Int (JSON, "id");
            Path_Val      : constant String := JSON_Get_String (JSON, "path");
            Resolved_Path : Unbounded_String;
            Target        : Widget_Access;
            Buf           : Unbounded_String;
         begin
            if Id_Val = 0 and then Path_Val'Length = 0 then
               return Error_Response
                 (Req_Id, "click_widget requires id or path");
            end if;

            Target := Resolve_Widget (JSON, Resolved_Path);
            if Target = null then
               return Error_Response (Req_Id, "widget not found");
            end if;

            declare
               Geom : constant Rectangle := Get_Geometry (Target.all);
               CX   : constant Pixel_Type :=
                 Geom.X + Geom.Width / 2.0;
               CY   : constant Pixel_Type :=
                 Geom.Y + Geom.Height / 2.0;
            begin
               Adi.Window.On_Mouse_Down
                 (MCP_Window.all, CX, CY, Left_Button, 1);
               Adi.Window.On_Mouse_Up
                 (MCP_Window.all, CX, CY, Left_Button);
            end;

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "id", Get_Id (Target.all));
            JKV_String (Buf, "path", To_String (Resolved_Path));
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "send_keys" then
         declare
            Keys : constant String := JSON_Get_String (JSON, "keys");
            Buf  : Unbounded_String;
         begin
            if Keys'Length = 0 then
               return Error_Response (Req_Id, "missing keys parameter");
            end if;

            Parse_And_Send_Keys (MCP_Window, Keys);

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "set_text" then
         declare
            Resolved_Path : Unbounded_String;
            Target        : constant Widget_Access :=
              Resolve_Widget (JSON, Resolved_Path);
            Text          : constant String := JSON_Get_String (JSON, "text");
            Buf           : Unbounded_String;
         begin
            if Target = null then
               return Error_Response (Req_Id, "widget not found");
            end if;

            if Target.all in Label.Label_Widget'Class then
               Label.Set_Text
                 (Label.Label_Widget'Class (Target.all), Text);
            elsif Target.all in Text_Input.Text_Input_Widget'Class then
               Text_Input.Set_Text
                 (Text_Input.Text_Input_Widget'Class (Target.all), Text);
            elsif Target.all in Text_Editor.Text_Editor_Widget'Class then
               Text_Editor.Set_Text
                 (Text_Editor.Text_Editor_Widget'Class (Target.all), Text);
            else
               return Error_Response
                 (Req_Id, "widget does not support set_text");
            end if;

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "id", Get_Id (Target.all));
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "set_focus" then
         declare
            Resolved_Path : Unbounded_String;
            Target        : constant Widget_Access :=
              Resolve_Widget (JSON, Resolved_Path);
            Buf           : Unbounded_String;
         begin
            if Target = null then
               return Error_Response (Req_Id, "widget not found");
            end if;

            Adi.Window.Set_Focus (MCP_Window.all, Target);

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "id", Get_Id (Target.all));
            Append (Buf, "}");
            return To_String (Buf);
         end;

      elsif Cmd = "css_values" then
         declare
            Resolved_Path : Unbounded_String;
            Target        : constant Widget_Access :=
              Resolve_Widget (JSON, Resolved_Path);
            Part_Str      : constant String :=
              JSON_Get_String (JSON, "part");
            Part          : Part_Kind;
            Buf           : Unbounded_String;
         begin
            if Target = null then
               return Error_Response (Req_Id, "widget not found");
            end if;

            Part := Resolve_Part
              (if Part_Str'Length > 0 then Part_Str else "main");

            Append (Buf, "{");
            JKV_String (Buf, "status", "ok", First => True);
            JKV_String (Buf, "req_id", Req_Id);
            JKV_Int (Buf, "id", Get_Id (Target.all));
            JKV_String (Buf, "part",
              Ada.Characters.Handling.To_Lower
                (Part_Kind'Image (Part)));
            Append (Buf, ",""values"":");
            Serialize_CSS_Values (Target, Part, Buf);
            Append (Buf, "}");
            return To_String (Buf);
         end;

      else
         return Execute_Command (Cmd, Req_Id);
      end if;
   end Execute_Command_Full;

   ---------------------------------------------------------------------------
   --  Polling & Callbacks
   ---------------------------------------------------------------------------

   procedure Post_Render_Handler
     (Win      : not null access Adi.Window.Window'Class;
      Renderer : SDL_Renderer_Ptr)
   is
      pragma Unreferenced (Win);
   begin
      if not Pending_Screenshot then return; end if;

      declare
         Req_Id : constant String := To_String (Pending_Screenshot_Id);
         Dir    : constant String := To_String (MCP_Dir);
         Path   : constant String :=
           Dir & "/screenshot_" & Req_Id & ".png";
         Buf    : Unbounded_String;
         Resp_Path : constant String :=
           Dir & "/resp_" & Req_Id & ".json";
      begin
         Pending_Screenshot := False;
         Adi.Screenshot.Capture (Renderer, Path);
         Append (Buf, "{");
         JKV_String (Buf, "status", "ok", First => True);
         JKV_String (Buf, "req_id", Req_Id);
         JKV_String (Buf, "path", Path);
         Append (Buf, "}");
         Atomic_Write (Resp_Path, To_String (Buf));
      exception
         when others =>
            Pending_Screenshot := False;
            declare
               Err_Buf : Unbounded_String;
            begin
               Append (Err_Buf, "{");
               JKV_String (Err_Buf, "status", "error", First => True);
               JKV_String (Err_Buf, "req_id", Req_Id);
               JKV_String (Err_Buf, "error", "screenshot capture failed");
               Append (Err_Buf, "}");
               Atomic_Write (Resp_Path, To_String (Err_Buf));
            end;
      end;
   exception
      when others => null;
   end Post_Render_Handler;

   procedure Frame_Handler
     (Win : not null access Adi.Window.Window'Class)
   is
      use Ada.Directories;
      Dir  : constant String := To_String (MCP_Dir);
      Srch : Search_Type;
      Ent  : Directory_Entry_Type;
   begin
      Start_Search (Srch, Dir, "cmd_*.json",
                    [Ordinary_File => True, others => False]);
      if More_Entries (Srch) then
         Get_Next_Entry (Srch, Ent);
         End_Search (Srch);

         declare
            Cmd_Path  : constant String := Full_Name (Ent);
            Cmd_Name  : constant String := Simple_Name (Ent);
            JSON      : constant String := Read_File (Cmd_Path);
            Cmd       : constant String := JSON_Get_String (JSON, "command");
            Req_Id_J  : constant String := JSON_Get_String (JSON, "req_id");

            function Req_Id_From_Filename return String is
               Prefix : constant String := "cmd_";
               Suffix : constant String := ".json";
            begin
               if Cmd_Name'Length > Prefix'Length + Suffix'Length
                 and then Cmd_Name (Cmd_Name'First ..
                   Cmd_Name'First + Prefix'Length - 1) = Prefix
                 and then Cmd_Name (Cmd_Name'Last - Suffix'Length + 1 ..
                   Cmd_Name'Last) = Suffix
               then
                  return Cmd_Name (Cmd_Name'First + Prefix'Length ..
                    Cmd_Name'Last - Suffix'Length);
               end if;
               return "";
            end Req_Id_From_Filename;

            Req_Id : constant String :=
              (if Req_Id_J'Length > 0 then Req_Id_J
               else Req_Id_From_Filename);
         begin
            if Exists (Cmd_Path) then
               Delete_File (Cmd_Path);
            end if;

            if Req_Id'Length = 0 then
               return;
            end if;

            if Cmd'Length = 0 then
               declare
                  Resp_Path : constant String :=
                    Dir & "/resp_" & Req_Id & ".json";
               begin
                  Atomic_Write (Resp_Path,
                    Error_Response (Req_Id, "missing command field"));
               end;
               return;
            end if;

            if Cmd = "screenshot" then
               Pending_Screenshot := True;
               Pending_Screenshot_Id := To_Unbounded_String (Req_Id);
               Adi.Window.Request_Redraw (Win.all);
            else
               declare
                  Response  : constant String :=
                    Execute_Command_Full (JSON, Cmd, Req_Id);
                  Resp_Path : constant String :=
                    Dir & "/resp_" & Req_Id & ".json";
               begin
                  Atomic_Write (Resp_Path, Response);
               end;
            end if;
         end;
      else
         End_Search (Srch);
      end if;
   exception
      when others => null;
   end Frame_Handler;

   ---------------------------------------------------------------------------
   --  Public API
   ---------------------------------------------------------------------------

   function Is_Process_Alive (Pid : Integer) return Boolean is
      function C_Kill (P : Integer; Sig : Integer) return Integer
        with Import, Convention => C, External_Name => "kill";
   begin
      return C_Kill (Pid, 0) = 0;
   end Is_Process_Alive;

   procedure Remove_Directory_Recursive (Path : String) is
      use Ada.Directories;
      Srch : Search_Type;
      Ent  : Directory_Entry_Type;
   begin
      if not Exists (Path) then return; end if;
      Start_Search (Srch, Path, "",
                    [Ordinary_File => True, others => False]);
      while More_Entries (Srch) loop
         Get_Next_Entry (Srch, Ent);
         Delete_File (Full_Name (Ent));
      end loop;
      End_Search (Srch);
      Delete_Directory (Path);
   exception
      when others => null;
   end Remove_Directory_Recursive;

   procedure Cleanup_Stale_Dirs (Parent : String) is
      use Ada.Directories;
      Srch : Search_Type;
      Ent  : Directory_Entry_Type;
   begin
      if not Exists (Parent) then return; end if;
      Start_Search (Srch, Parent, "",
                    [Directory => True, others => False]);
      while More_Entries (Srch) loop
         Get_Next_Entry (Srch, Ent);
         declare
            Name : constant String := Simple_Name (Ent);
         begin
            if Name /= "." and then Name /= ".." then
               declare
                  Dir_Pid : constant Integer := Integer'Value (Name);
               begin
                  if not Is_Process_Alive (Dir_Pid) then
                     Remove_Directory_Recursive (Full_Name (Ent));
                  end if;
               exception
                  when Constraint_Error => null;
               end;
            end if;
         end;
      end loop;
      End_Search (Srch);
   exception
      when others => null;
   end Cleanup_Stale_Dirs;

   procedure Initialize
     (Win      : not null access Adi.Window.Window'Class;
      Base_Dir : String := "/tmp/adi_mcp")
   is
      use GNAT.OS_Lib;
      Pid_Str : constant String := Ada.Strings.Fixed.Trim
        (Integer'Image (Pid_To_Integer (Current_Process_Id)),
         Ada.Strings.Left);
      Parent  : constant String := Ada.Directories.Full_Name (Base_Dir);
      Dir     : constant String := Parent & "/" & Pid_Str;
   begin
      if Active then return; end if;

      if not Ada.Directories.Exists (Parent) then
         Ada.Directories.Create_Directory (Parent);
      end if;

      Cleanup_Stale_Dirs (Parent);

      if not Ada.Directories.Exists (Dir) then
         Ada.Directories.Create_Directory (Dir);
      end if;

      MCP_Dir := To_Unbounded_String (Dir);
      MCP_Window := Win;
      Active := True;

      Write_File (Dir & "/ready", Pid_Str);

      Frame_Conn := Adi.Window.Connect_Frame
        (Win.all, Frame_Handler'Access);
      Post_Render_Conn := Adi.Window.Connect_Post_Render
        (Win.all, Post_Render_Handler'Access);
   end Initialize;

   procedure Finalize is
      use Ada.Directories;
      Dir : constant String := To_String (MCP_Dir);
   begin
      if not Active then return; end if;

      if MCP_Window /= null then
         Adi.Window.Disconnect_Frame (MCP_Window.all, Frame_Conn);
         Adi.Window.Disconnect_Post_Render (MCP_Window.all, Post_Render_Conn);
         Frame_Conn := Adi.Window.Frame_Signals.No_Connection;
         Post_Render_Conn := Adi.Window.Post_Render_Signals.No_Connection;
      end if;

      if Exists (Dir) then
         declare
            Srch : Search_Type;
            Ent  : Directory_Entry_Type;
         begin
            Start_Search (Srch, Dir, "",
                          [Ordinary_File => True, others => False]);
            while More_Entries (Srch) loop
               Get_Next_Entry (Srch, Ent);
               Delete_File (Full_Name (Ent));
            end loop;
            End_Search (Srch);
         exception
            when others => null;
         end;
         begin
            Delete_Directory (Dir);
         exception
            when others => null;
         end;
      end if;

      Active := False;
      MCP_Window := null;
   end Finalize;

   function Is_Active return Boolean is
   begin
      return Active;
   end Is_Active;

end Adi.MCP;
