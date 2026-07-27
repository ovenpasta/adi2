pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Core; use Adi.Core;
with Adi.Text_Buffer; use Adi.Text_Buffer;
with Adi.Text_Layout; use Adi.Text_Layout;
with Test_Support;

procedure Text_Layout_Test is

   procedure Test_Wrap_Enabled_Flags is
      S : Resolved_Style := (others => <>);
   begin
      Put_Line ("Test: Wrap_Enabled flags");
      Test_Support.Assert (Wrap_Enabled (S), "default resolved style enables wrap");

      S.White_Space := WS_Nowrap;
      Test_Support.Assert (not Wrap_Enabled (S), "white-space nowrap disables wrap");

      S := (others => <>);
      S.Text_Wrap_Mode := TWM_Nowrap;
      Test_Support.Assert (not Wrap_Enabled (S), "text-wrap-mode nowrap disables wrap");
      New_Line;
   end Test_Wrap_Enabled_Flags;

   procedure Test_Nowrap_Row_Mapping is
      B : Text_Buffer;
      L : Text_Layout;
      S : Resolved_Style := (others => <>);
      R : Visual_Row;
   begin
      Put_Line ("Test: nowrap row mapping");
      Set_Text (B, "one" & ASCII.LF & "" & ASCII.LF & "two");
      S.White_Space := WS_Nowrap;
      S.Text_Wrap_Mode := TWM_Nowrap;
      Rebuild (L, B, S, 120.0);

      Test_Support.Assert (Row_Count (L) = 3, "three logical lines map to three visual rows");

      R := Row_At (L, 1);
      Test_Support.Assert (R.Buffer_Line = 1 and then R.Start_Column = 0 and then R.End_Column = 3,
              "row 1 range");
      Test_Support.Assert (Row_Text (L, B, R) = "one", "row 1 text");

      R := Row_At (L, 2);
      Test_Support.Assert (R.Buffer_Line = 2 and then R.Start_Column = 0 and then R.End_Column = 0,
              "empty line keeps one empty row");
      Test_Support.Assert (Row_Text (L, B, R) = "", "row 2 text empty");

      R := Row_At (L, 3);
      Test_Support.Assert (R.Buffer_Line = 3 and then R.Start_Column = 0 and then R.End_Column = 3,
              "row 3 range");
      Test_Support.Assert (Row_Text (L, B, R) = "two", "row 3 text");
      New_Line;
   end Test_Nowrap_Row_Mapping;

   procedure Test_Position_Mapping_By_Row is
      B : Text_Buffer;
      L : Text_Layout;
      S : Resolved_Style := (others => <>);
      P : Position;
   begin
      Put_Line ("Test: row/position mapping");
      Set_Text (B, "alpha" & ASCII.LF & "" & ASCII.LF & "omega");
      S.White_Space := WS_Nowrap;
      S.Text_Wrap_Mode := TWM_Nowrap;
      Rebuild (L, B, S, 100.0);

      Test_Support.Assert (Row_Index_For_Position (L, B, (Line => 1, Column => 0)) = 1,
              "line 1 start maps to row 1");
      Test_Support.Assert (Row_Index_For_Position (L, B, (Line => 1, Column => 5)) = 1,
              "line 1 end maps to row 1");
      Test_Support.Assert (Row_Index_For_Position (L, B, (Line => 3, Column => 2)) = 3,
              "line 3 maps to row 3");

      P :=
        Position_At_Point
          (L               => L,
           B               => B,
           Label_Style     => S,
           Content_X       => 10.0,
           X               => 10.0,
           Y               => 0.0,
           Scroll_Offset_Y => 0.0,
           Line_Skip       => 10.0);
      Test_Support.Assert (P.Line = 1, "point in first visual row maps to line 1");

      P :=
        Position_At_Point
          (L               => L,
           B               => B,
           Label_Style     => S,
           Content_X       => 10.0,
           X               => 10.0,
           Y               => 20.0,
           Scroll_Offset_Y => 0.0,
           Line_Skip       => 10.0);
      Test_Support.Assert (P.Line = 3, "point in third visual row maps to line 3");

      P :=
        Position_At_Point
          (L               => L,
           B               => B,
           Label_Style     => S,
           Content_X       => 10.0,
           X               => 10.0,
           Y               => 0.0,
           Scroll_Offset_Y => 10.0,
           Line_Skip       => 10.0);
      Test_Support.Assert (P.Line = 2, "scroll offset shifts row mapping");
      New_Line;
   end Test_Position_Mapping_By_Row;

   procedure Test_X_Offset_Start_Zero is
      B : Text_Buffer;
      L : Text_Layout;
      S : Resolved_Style := (others => <>);
   begin
      Put_Line ("Test: x offset baseline");
      Set_Text (B, "xyz");
      S.White_Space := WS_Nowrap;
      S.Text_Wrap_Mode := TWM_Nowrap;
      Rebuild (L, B, S, 120.0);

      Test_Support.Assert
        (X_Offset_For_Column
           (L           => L,
            B           => B,
            Label_Style => S,
            Row_Index   => 1,
            Column      => 0) = 0.0,
         "column 0 x-offset is zero");
      New_Line;
   end Test_X_Offset_Start_Zero;

begin
   Test_Support.Start_Suite ("Text layout test");
   Put_Line ("");

   Test_Wrap_Enabled_Flags;
   Test_Nowrap_Row_Mapping;
   Test_Position_Mapping_By_Row;
   Test_X_Offset_Start_Zero;

   Test_Support.Finish;
end Text_Layout_Test;
