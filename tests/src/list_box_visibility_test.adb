pragma Ada_2022;

with Adi.Core;           use Adi.Core;
with Adi.CSS_Styles;     use Adi.CSS_Styles;
with Adi.SDL.Events;     use Adi.SDL.Events;
with Adi.Widget;         use Adi.Widget;
with Adi.Widget.Label;
with Adi.Widget.List_Box;
with Adi.Widget_Styles;  use Adi.Widget_Styles;
with Test_Support;       use Test_Support;

procedure List_Box_Visibility_Test is

   package Label_List is new Adi.Widget.List_Box
     (Adi.Widget.Label.Label_Widget);
   use Label_List;

   Eps : constant Pixel_Type := 0.01;

   --  Each row carries an explicit height, so the list's geometry does not
   --  depend on font metrics.
   Row_H   : constant Pixel_Type := 20.0;
   Row_Gap : constant Pixel_Type := 4.0;
   Step    : constant Pixel_Type := Row_H + Row_Gap;

   --  What Append_Row seeds Row_Heights with, before any layout measures.
   Default_Row_H : constant Pixel_Type := 24.0;
   Default_Step  : constant Pixel_Type := Default_Row_H + Row_Gap;

   No_Mods : constant SDL_Keymod := 0;

   Last_Clicked : Natural := 0;

   procedure Note_Click
     (W : Widget_Handle; Index : Positive; Clicks : Natural)
   is
      pragma Unreferenced (W, Clicks);
   begin
      Last_Clicked := Index;
   end Note_Click;

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Message : String) is
   begin
      Assert (abs (Actual - Expected) <= Eps,
              Message & " (got" & Actual'Image
              & ", expected" & Expected'Image & ")");
   end Assert_Close;

   procedure Append_Sized_Row (H : List_Box_Handle; Text : String) is
      Row : constant Widget_Handle :=
        Adi.Widget.Label."+" (Adi.Widget.Label.Create_Handle (Text));
      Rules : constant Style_Rules :=
        (Height => Set (Size (Px (Float (Row_H)))), others => <>);
   begin
      Set_Part_Style (Row, Main_Part, From (Rules).Build);
      Append_Row (H, Row);
   end Append_Sized_Row;

   function New_List
     (Count : Natural; Cols : Natural := 1) return List_Box_Handle
   is
      H : constant List_Box_Handle := Create_Handle;
      Rules : constant Style_Rules :=
        (Gap          => Set (Gap (Px (Float (Row_Gap)))),
         Grid_Columns => Set (Grid_Columns_Value (Cols)),
         others       => <>);
   begin
      Set_Part_Style (+H, Main_Part, From (Rules).Build);
      for I in 1 .. Count loop
         Append_Sized_Row (H, "Row" & I'Image);
      end loop;
      return H;
   end New_List;

   procedure Hide (H : List_Box_Handle; Index : Positive) is
   begin
      Set_Visible (Get_Row_Handle (H, Index), False);
   end Hide;

   procedure Show (H : List_Box_Handle; Index : Positive) is
   begin
      Set_Visible (Get_Row_Handle (H, Index), True);
   end Show;

   function Row_Y (H : List_Box_Handle; Index : Positive) return Pixel_Type is
     (Get_Geometry (Get_Row_Handle (H, Index)).Y);

   --  Reports which row a click at (X, Y) reached, 0 for none. The click
   --  signal fires with the index Row_Index_At answered, which is the only
   --  public window onto it.
   function Click_At
     (H : List_Box_Handle; X, Y : Pixel_Type) return Natural is
   begin
      Last_Clicked := 0;
      On_Mouse_Down (+H, X, Y, Left_Button, 1);
      return Last_Clicked;
   end Click_At;

   ---------------------------------------------------------------------------
   --  A hidden row takes no height and leaves no gap behind it.
   ---------------------------------------------------------------------------

   procedure Test_Visible_Rows_Close_Up is
      H : constant List_Box_Handle := New_List (6);
   begin
      Section ("visible rows sit at consecutive offsets");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Layout_Tree (+H);

      Assert_Close (Row_Y (H, 4), 3.0 * Step,
                    "with every row shown, row 4 sits three steps down");

      Hide (H, 3);
      Layout_Tree (+H);

      Assert_Close (Row_Y (H, 1), 0.0, "row 1 sits at the content origin");
      Assert_Close (Row_Y (H, 2), Step, "row 2 sits one step down");
      Assert_Close (Row_Y (H, 4), 2.0 * Step,
                    "row 4 takes the place row 3 vacated");
      Assert_Close (Row_Y (H, 5), 3.0 * Step, "row 5 follows row 4");
      Assert_Close (Row_Y (H, 6), 4.0 * Step, "row 6 follows row 5");

      Assert_Close (Row_Y (H, 4) - Row_Y (H, 2), Step,
                    "the rows either side of the hidden one are one gap apart");

      Assert_Close (Get_Geometry (Get_Row_Handle (H, 4)).Height, Row_H,
                    "a visible row keeps its own height");
   end Test_Visible_Rows_Close_Up;

   ---------------------------------------------------------------------------
   --  Get_Scroll_Content_Height counts the participating rows and their gaps.
   ---------------------------------------------------------------------------

   procedure Test_Content_Height_Closes_Up is
      H : constant List_Box_Handle := New_List (6);
   begin
      Section ("content height counts only participating rows");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 50.0));
      Layout_Tree (+H);

      Assert_Close (Get_Content_Height (H), 6.0 * Row_H + 5.0 * Row_Gap,
                    "six rows and five gaps");

      Hide (H, 3);
      Layout_Tree (+H);

      Assert_Close (Get_Content_Height (H), 5.0 * Row_H + 4.0 * Row_Gap,
                    "five rows and four gaps once one row is hidden");

      Hide (H, 4);
      Layout_Tree (+H);

      Assert_Close (Get_Content_Height (H), 4.0 * Row_H + 3.0 * Row_Gap,
                    "two adjacent hidden rows cost two rows and two gaps");

      Show (H, 3);
      Show (H, 4);
      Layout_Tree (+H);

      Assert_Close (Get_Content_Height (H), 6.0 * Row_H + 5.0 * Row_Gap,
                    "showing the rows again restores the full height");
   end Test_Content_Height_Closes_Up;

   ---------------------------------------------------------------------------
   --  Row_Index_At answers only participating indices, in a single column.
   ---------------------------------------------------------------------------

   procedure Test_Hit_Test_Vertical is
      H : constant List_Box_Handle := New_List (6);
      Seen : array (1 .. 6) of Boolean := [others => False];
      Y    : Pixel_Type := 0.0;
      Hit  : Natural;
   begin
      Section ("hit testing skips a hidden row, single column");

      Connect_Item_Clicked (H, Note_Click'Unrestricted_Access);
      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Hide (H, 3);
      Layout_Tree (+H);

      while Y <= 300.0 loop
         Hit := Click_At (H, 5.0, Y);
         Assert (Hit /= 3, "no point in the list reaches the hidden row 3");
         if Hit in Seen'Range then
            Seen (Hit) := True;
         end if;
         Y := Y + 0.5;
      end loop;

      for I in Seen'Range loop
         if I = 3 then
            Assert (not Seen (I), "the hidden row is never hit");
         else
            Assert (Seen (I), "row" & I'Image & " is reachable by click");
         end if;
      end loop;

      Assert (Click_At (H, 5.0, Row_Y (H, 4) + 1.0) = 4,
              "a click just inside row 4 reaches row 4");
   end Test_Hit_Test_Vertical;

   ---------------------------------------------------------------------------
   --  The content-box origin belongs to the first row that is actually
   --  there, not to a hidden row whose cell rectangle collapsed onto it.
   ---------------------------------------------------------------------------

   procedure Test_Hit_Test_Origin is
      Vertical : constant List_Box_Handle := New_List (6);
      Grid     : constant List_Box_Handle := New_List (9, Cols => 3);
   begin
      Section ("the content origin never lands on a hidden row");

      Connect_Item_Clicked (Vertical, Note_Click'Unrestricted_Access);
      Set_Geometry (+Vertical, (0.0, 0.0, 100.0, 300.0));
      Hide (Vertical, 1);
      Layout_Tree (+Vertical);

      Assert (Click_At (Vertical, 5.0, 0.0) = 2,
              "single column: the origin reaches row 2, not the hidden row 1");

      Connect_Item_Clicked (Grid, Note_Click'Unrestricted_Access);
      Set_Geometry (+Grid, (0.0, 0.0, 300.0, 300.0));
      Hide (Grid, 1);
      Layout_Tree (+Grid);

      Assert (Click_At (Grid, 0.0, 0.0) = 2,
              "grid: the origin reaches cell 2, not the hidden cell 1");
   end Test_Hit_Test_Origin;

   ---------------------------------------------------------------------------
   --  Row_Index_At answers only participating indices in a grid, and the
   --  grid closes up over the hidden cell.
   ---------------------------------------------------------------------------

   procedure Test_Hit_Test_Grid is
      H : constant List_Box_Handle := New_List (9, Cols => 3);
      Seen : array (1 .. 9) of Boolean := [others => False];
      X, Y : Pixel_Type;
      Hit  : Natural;
      Cell : Rectangle;
   begin
      Section ("hit testing skips a hidden cell, three columns");

      Connect_Item_Clicked (H, Note_Click'Unrestricted_Access);
      Set_Geometry (+H, (0.0, 0.0, 300.0, 300.0));
      Hide (H, 5);
      Layout_Tree (+H);

      Assert_Close (Row_Y (H, 6), Row_Y (H, 4),
                    "cell 6 moves up into the row cell 5 vacated");
      Assert (Get_Geometry (Get_Row_Handle (H, 6)).X
              > Get_Geometry (Get_Row_Handle (H, 4)).X,
              "cell 6 takes the column after cell 4");

      Y := 0.0;
      while Y <= 300.0 loop
         X := 0.0;
         while X <= 300.0 loop
            Hit := Click_At (H, X, Y);
            Assert (Hit /= 5, "no point in the grid reaches the hidden cell 5");
            if Hit in Seen'Range then
               Seen (Hit) := True;
            end if;
            X := X + 5.0;
         end loop;
         Y := Y + 5.0;
      end loop;

      for I in Seen'Range loop
         if I = 5 then
            Assert (not Seen (I), "the hidden cell is never hit");
         else
            Assert (Seen (I), "cell" & I'Image & " is reachable by click");
         end if;
      end loop;

      for I in 1 .. 9 loop
         if I /= 5 then
            Cell := Get_Geometry (Get_Row_Handle (H, I));
            Assert (Click_At (H, Cell.X + Cell.Width / 2.0,
                              Cell.Y + Cell.Height / 2.0) = I,
                    "a click at cell" & I'Image & "'s centre reaches it");
         end if;
      end loop;
   end Test_Hit_Test_Grid;

   ---------------------------------------------------------------------------
   --  Row indices address rows: hiding one renumbers nothing.
   ---------------------------------------------------------------------------

   procedure Test_Indices_Are_Stable is
      H : constant List_Box_Handle := New_List (6);
      Before : array (1 .. 6) of Widget_Handle;
   begin
      Section ("row identity survives hiding");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Layout_Tree (+H);

      for I in Before'Range loop
         Before (I) := Get_Row_Handle (H, I);
      end loop;

      Hide (H, 3);
      Layout_Tree (+H);

      Assert (Row_Count (H) = 6, "Row_Count still counts every row");
      for I in Before'Range loop
         Assert (Get_Row_Handle (H, I) = Before (I),
                 "Get_Row_Handle" & I'Image & " answers the same row");
      end loop;
   end Test_Indices_Are_Stable;

   ---------------------------------------------------------------------------
   --  Ensure_Row_Visible scrolls to the row's own top, through the cached
   --  cell rectangles.
   ---------------------------------------------------------------------------

   procedure Test_Ensure_Visible_Cell_Rects is
      H : constant List_Box_Handle := New_List (8);
   begin
      Section ("Ensure_Row_Visible over cached cell rectangles");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 50.0));
      Hide (H, 3);
      Layout_Tree (+H);

      Assert_Close (Get_Content_Height (H), 7.0 * Row_H + 6.0 * Row_Gap,
                    "seven rows and six gaps");

      Set_Scroll_Offset (H, Get_Scroll_Max_Offset_Y (+H));
      Assert (Get_Scroll_Offset (H) > 2.0 * Step,
              "the fixture scrolls past row 4 before the check");

      Ensure_Row_Visible (H, 4);
      Assert_Close (Get_Scroll_Offset (H), 2.0 * Step,
                    "row 4's top counts the two rows that precede it");

      Ensure_Row_Visible (H, 1);
      Assert_Close (Get_Scroll_Offset (H), 0.0,
                    "row 1's top is the content origin");
   end Test_Ensure_Visible_Cell_Rects;

   ---------------------------------------------------------------------------
   --  Ensure_Row_Visible over the height cursor, reached when the row set
   --  has no cell rectangles yet. Clear_Rows drops them and leaves the
   --  scroll extent of the previous population, so there is room to scroll.
   ---------------------------------------------------------------------------

   procedure Test_Ensure_Visible_Height_Cursor is
      H : constant List_Box_Handle := New_List (20);
      Viewport : constant Pixel_Type := 50.0;
      --  Row 6 follows four participating rows, and its bottom edge has to
      --  come into a viewport that starts at the top of the list.
      Expected : constant Pixel_Type :=
        4.0 * Default_Step + Default_Row_H - Viewport;
   begin
      Section ("Ensure_Row_Visible over the height cursor");

      Set_Geometry (+H, (0.0, 0.0, 100.0, Viewport));
      Layout_Tree (+H);

      Clear_Rows (H);
      for I in 1 .. 8 loop
         Append_Sized_Row (H, "Row" & I'Image);
      end loop;
      Hide (H, 3);

      Assert (Get_Scroll_Max_Offset_Y (+H) > Expected + Default_Step,
              "the fixture still has room to scroll");

      Ensure_Row_Visible (H, 6);
      Assert_Close (Get_Scroll_Offset (H), Expected,
                    "row 6 sits four steps down, not five");
   end Test_Ensure_Visible_Height_Cursor;

   ---------------------------------------------------------------------------
   --  Keyboard movement steps over hidden rows.
   ---------------------------------------------------------------------------

   procedure Test_Keyboard_Steps_Over_Hidden is
      H : constant List_Box_Handle := New_List (6);
   begin
      Section ("arrow movement skips a hidden row");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Hide (H, 3);
      Layout_Tree (+H);

      Set_Current_Row (H, 2);
      On_Key_Down (+H, SDL_SCANCODE_DOWN, No_Mods, False);
      Assert (Get_Current_Row (H) = 4,
              "down from row 2 reaches row 4 (got"
              & Get_Current_Row (H)'Image & ")");
      Assert (Is_Row_Selected (H, 4), "row 4 is selected after the move");

      On_Key_Down (+H, SDL_SCANCODE_UP, No_Mods, False);
      Assert (Get_Current_Row (H) = 2,
              "up from row 4 reaches row 2 (got"
              & Get_Current_Row (H)'Image & ")");
   end Test_Keyboard_Steps_Over_Hidden;

   procedure Test_Keyboard_Steps_Over_Run is
      H : constant List_Box_Handle := New_List (7);
   begin
      Section ("arrow movement skips a run of hidden rows");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Hide (H, 3);
      Hide (H, 4);
      Hide (H, 5);
      Layout_Tree (+H);

      Set_Current_Row (H, 2);
      On_Key_Down (+H, SDL_SCANCODE_DOWN, No_Mods, False);
      Assert (Get_Current_Row (H) = 6,
              "down from row 2 clears all three hidden rows (got"
              & Get_Current_Row (H)'Image & ")");

      On_Key_Down (+H, SDL_SCANCODE_UP, No_Mods, False);
      Assert (Get_Current_Row (H) = 2,
              "up from row 6 clears all three hidden rows (got"
              & Get_Current_Row (H)'Image & ")");
   end Test_Keyboard_Steps_Over_Run;

   procedure Test_Home_And_End is
      H : constant List_Box_Handle := New_List (6);
   begin
      Section ("Home and End reach the first and last participating rows");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Hide (H, 1);
      Hide (H, 6);
      Layout_Tree (+H);

      Set_Current_Row (H, 4);
      On_Key_Down (+H, SDL_SCANCODE_HOME, No_Mods, False);
      Assert (Get_Current_Row (H) = 2,
              "Home reaches row 2 (got" & Get_Current_Row (H)'Image & ")");

      On_Key_Down (+H, SDL_SCANCODE_END, No_Mods, False);
      Assert (Get_Current_Row (H) = 5,
              "End reaches row 5 (got" & Get_Current_Row (H)'Image & ")");
   end Test_Home_And_End;

   --  Append_Row seeds Current_Row with 1, and hiding a row never moves it,
   --  so the cursor can start on a hidden row -- including one at the end it
   --  is about to be asked to walk towards.
   procedure Test_Cursor_On_Hidden_Row is
      Top    : constant List_Box_Handle := New_List (6);
      Bottom : constant List_Box_Handle := New_List (6);
      Middle : constant List_Box_Handle := New_List (6);
   begin
      Section ("a cursor resting on a hidden row still moves");

      Set_Geometry (+Top, (0.0, 0.0, 100.0, 300.0));
      Hide (Top, 1);
      Layout_Tree (+Top);

      Assert (Get_Current_Row (Top) = 1,
              "the cursor starts on the hidden first row (got"
              & Get_Current_Row (Top)'Image & ")");
      On_Key_Down (+Top, SDL_SCANCODE_HOME, No_Mods, False);
      Assert (Get_Current_Row (Top) = 2,
              "Home off the hidden first row reaches row 2 (got"
              & Get_Current_Row (Top)'Image & ")");

      Set_Geometry (+Top, (0.0, 0.0, 100.0, 300.0));
      Set_Current_Row (Top, 1);
      On_Key_Down (+Top, SDL_SCANCODE_UP, No_Mods, False);
      Assert (Get_Current_Row (Top) = 2,
              "up off the hidden first row reaches row 2 (got"
              & Get_Current_Row (Top)'Image & ")");

      Set_Geometry (+Bottom, (0.0, 0.0, 100.0, 300.0));
      Hide (Bottom, 6);
      Layout_Tree (+Bottom);

      Set_Current_Row (Bottom, 6);
      On_Key_Down (+Bottom, SDL_SCANCODE_END, No_Mods, False);
      Assert (Get_Current_Row (Bottom) = 5,
              "End off the hidden last row reaches row 5 (got"
              & Get_Current_Row (Bottom)'Image & ")");

      Set_Current_Row (Bottom, 6);
      On_Key_Down (+Bottom, SDL_SCANCODE_DOWN, No_Mods, False);
      Assert (Get_Current_Row (Bottom) = 5,
              "down off the hidden last row reaches row 5 (got"
              & Get_Current_Row (Bottom)'Image & ")");

      --  Nothing participates below the cursor, so down settles on the
      --  nearest participating row above it rather than staying hidden.
      Set_Geometry (+Middle, (0.0, 0.0, 100.0, 300.0));
      Hide (Middle, 4);
      Hide (Middle, 5);
      Hide (Middle, 6);
      Layout_Tree (+Middle);

      Set_Current_Row (Middle, 5);
      On_Key_Down (+Middle, SDL_SCANCODE_DOWN, No_Mods, False);
      Assert (Get_Current_Row (Middle) = 3,
              "down from a hidden row with nothing below reaches row 3 (got"
              & Get_Current_Row (Middle)'Image & ")");

      Set_Current_Row (Middle, 5);
      On_Key_Down (+Middle, SDL_SCANCODE_UP, No_Mods, False);
      Assert (Get_Current_Row (Middle) = 3,
              "up from a hidden row reaches row 3 (got"
              & Get_Current_Row (Middle)'Image & ")");
   end Test_Cursor_On_Hidden_Row;

   ---------------------------------------------------------------------------
   --  Selection is orthogonal to participation.
   ---------------------------------------------------------------------------

   procedure Test_Selection_Survives_Hiding is
      H : constant List_Box_Handle := New_List (6);
   begin
      Section ("selection survives a row being hidden and shown");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Set_Selection_Mode (H, Multi_Selection);
      Layout_Tree (+H);

      Toggle_Row_Selected (H, 3);
      Toggle_Row_Selected (H, 5);
      Assert (Get_Selected_Count (H) = 2, "two rows selected to begin with");

      Hide (H, 3);
      Layout_Tree (+H);
      Assert (Is_Row_Selected (H, 3), "the hidden row stays selected");
      Assert (Get_Selected_Count (H) = 2,
              "the selected count counts the hidden row");

      Show (H, 3);
      Layout_Tree (+H);
      Assert (Is_Row_Selected (H, 3), "the row comes back selected");
      Assert_Close (Row_Y (H, 3), 2.0 * Step,
                    "the row comes back in its own place");
   end Test_Selection_Survives_Hiding;

   ---------------------------------------------------------------------------
   --  Degenerate cases.
   ---------------------------------------------------------------------------

   procedure Test_All_Rows_Hidden is
      H : constant List_Box_Handle := New_List (4);
      Y : Pixel_Type := 0.0;
   begin
      Section ("every row hidden");

      Connect_Item_Clicked (H, Note_Click'Unrestricted_Access);
      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      for I in 1 .. 4 loop
         Hide (H, I);
      end loop;
      Layout_Tree (+H);

      while Y <= 300.0 loop
         Assert (Click_At (H, 5.0, Y) = 0, "no click reaches any row");
         Y := Y + 1.0;
      end loop;

      Set_Current_Row (H, 2);
      On_Key_Down (+H, SDL_SCANCODE_DOWN, No_Mods, False);
      Assert (Get_Current_Row (H) = 2,
              "a list with nothing to move to leaves the current row alone");

      Assert (Row_Count (H) = 4, "the rows are still there");
   end Test_All_Rows_Hidden;

   procedure Test_First_Row_Hidden is
      H : constant List_Box_Handle := New_List (5);
   begin
      Section ("first row hidden");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 50.0));
      Hide (H, 1);
      Layout_Tree (+H);

      Assert_Close (Row_Y (H, 2), 0.0,
                    "row 2 sits at the content origin");
      Assert_Close (Row_Y (H, 5), 3.0 * Step, "row 5 follows three rows");
      Assert_Close (Get_Content_Height (H), 4.0 * Row_H + 3.0 * Row_Gap,
                    "four rows and three gaps");
   end Test_First_Row_Hidden;

   procedure Test_Last_Row_Hidden is
      H : constant List_Box_Handle := New_List (5);
   begin
      Section ("last row hidden");

      Connect_Item_Clicked (H, Note_Click'Unrestricted_Access);
      Set_Geometry (+H, (0.0, 0.0, 100.0, 50.0));
      Hide (H, 5);
      Layout_Tree (+H);

      Assert_Close (Row_Y (H, 4), 3.0 * Step, "row 4 keeps its place");
      Assert_Close (Get_Content_Height (H), 4.0 * Row_H + 3.0 * Row_Gap,
                    "the trailing gap goes with the row");

      Set_Geometry (+H, (0.0, 0.0, 100.0, 300.0));
      Layout_Tree (+H);

      Assert (Click_At (H, 5.0, 3.0 * Step + Row_H / 2.0) = 4,
              "row 4 still answers a click");
      Assert (Click_At (H, 5.0, 4.0 * Step + Row_H / 2.0) = 0,
              "the band the hidden last row would have taken reaches no row");
   end Test_Last_Row_Hidden;

begin
   Start_Suite ("List Box Row Visibility Test");

   Test_Visible_Rows_Close_Up;
   Test_Content_Height_Closes_Up;
   Test_Hit_Test_Vertical;
   Test_Hit_Test_Origin;
   Test_Hit_Test_Grid;
   Test_Indices_Are_Stable;
   Test_Ensure_Visible_Cell_Rects;
   Test_Ensure_Visible_Height_Cursor;
   Test_Keyboard_Steps_Over_Hidden;
   Test_Keyboard_Steps_Over_Run;
   Test_Home_And_End;
   Test_Cursor_On_Hidden_Row;
   Test_Selection_Survives_Hiding;
   Test_All_Rows_Hidden;
   Test_First_Row_Hidden;
   Test_Last_Row_Hidden;

   Finish;
end List_Box_Visibility_Test;
