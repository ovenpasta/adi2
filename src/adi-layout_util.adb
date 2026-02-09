package body Adi.Layout_Util is

   -------------------------------------------------
   -- Length Conversion
   -------------------------------------------------

   function Length_To_Px (L : Length_Value;
                          Container_Size : Pixel_Type := 0.0;
                          Font_Size : Pixel_Type := 16.0) return Pixel_Type is
   begin
      case L.Unit is
         when Px =>
            return Pixel_Type (L.Amount);
         when Dip =>
            --  Assume 1 DIP = 1 Px for now (should use display density)
            return Pixel_Type (L.Amount);
         when Em =>
            return Pixel_Type (L.Amount * Float (Font_Size));
         when Root_Em =>
            --  Assume root font size = 16
            return Pixel_Type (L.Amount * 16.0);
         when Pct =>
            return Pixel_Type (L.Amount / 100.0 * Float (Container_Size));
      end case;
      return 0.0;
   end Length_To_Px;

   function Size_To_Px (S : Size_Value;
                        Container_Size : Pixel_Type := 0.0;
                        Font_Size : Pixel_Type := 16.0) return Pixel_Type is
   begin
      case S.Kind is
         when Fixed =>
            return Length_To_Px (S.Size, Container_Size, Font_Size);
         when Auto | Min_Content | Max_Content | Fit_Content =>
            --  These need more context; return 0 as placeholder
            return 0.0;
      end case;
   end Size_To_Px;

   -------------------------------------------------
   -- CSS_Box to Pixels
   -------------------------------------------------

   function Box_To_Pixels (B : CSS_Box_Value) return Edge_Pixels is
   begin
      case B.Kind is
         when Gap_Uniform =>
            declare
               V : constant Pixel_Type := Length_To_Px (B.All_Sides);
            begin
               return (V, V, V, V);
            end;
         when Axis =>
            declare
               Vert : constant Pixel_Type := Length_To_Px (B.Vertical);
               Horiz : constant Pixel_Type := Length_To_Px (B.Horizontal);
            begin
               return (Top => Vert, Bottom => Vert,
                       Left => Horiz, Right => Horiz);
            end;
         when Per_Side =>
            return (Top    => Length_To_Px (B.Sides (Top)),
                    Right  => Length_To_Px (B.Sides (Right)),
                    Bottom => Length_To_Px (B.Sides (Bottom)),
                    Left   => Length_To_Px (B.Sides (Left)));
      end case;
   end Box_To_Pixels;

   function Border_To_Pixels (B : Border_Width_Value) return Edge_Pixels is
   begin
      case B.Kind is
         when Gap_Uniform =>
            declare
               V : constant Pixel_Type := Length_To_Px (B.All_Edges);
            begin
               return (V, V, V, V);
            end;
         when Per_Edge =>
            return (Top    => Length_To_Px (B.Edges (Top)),
                    Right  => Length_To_Px (B.Edges (Right)),
                    Bottom => Length_To_Px (B.Edges (Bottom)),
                    Left   => Length_To_Px (B.Edges (Left)));
      end case;
   end Border_To_Pixels;

   function Get_Padding_Px (Style : Resolved_Style) return Edge_Pixels is
   begin
      return Box_To_Pixels (Style.Padding);
   end Get_Padding_Px;

   function Get_Margin_Px (Style : Resolved_Style) return Edge_Pixels is
   begin
      return Box_To_Pixels (Style.Margin);
   end Get_Margin_Px;

   function Get_Border_Width_Px (Style : Resolved_Style) return Edge_Pixels is
   begin
      return Border_To_Pixels (Style.Border_Width);
   end Get_Border_Width_Px;

   -------------------------------------------------
   -- Rectangle Operations
   -------------------------------------------------

   function Shrink (R : Rectangle; Edges : Edge_Pixels) return Rectangle is
   begin
      return (X => R.X + Edges.Left,
              Y => R.Y + Edges.Top,
              Width => R.Width - Edges.Left - Edges.Right,
              Height => R.Height - Edges.Top - Edges.Bottom);
   end Shrink;

   function Expand (R : Rectangle; Edges : Edge_Pixels) return Rectangle is
   begin
      return (X => R.X - Edges.Left,
              Y => R.Y - Edges.Top,
              Width => R.Width + Edges.Left + Edges.Right,
              Height => R.Height + Edges.Top + Edges.Bottom);
   end Expand;

   function Content_Box (Outer : Rectangle;
                         Style : Resolved_Style) return Rectangle is
      Padding : constant Edge_Pixels := Get_Padding_Px (Style);
      Border  : constant Edge_Pixels := Get_Border_Width_Px (Style);
      Total   : constant Edge_Pixels := (
         Top    => Padding.Top + Border.Top,
         Right  => Padding.Right + Border.Right,
         Bottom => Padding.Bottom + Border.Bottom,
         Left   => Padding.Left + Border.Left);
   begin
      return Shrink (Outer, Total);
   end Content_Box;

   function Padding_Box (Outer : Rectangle;
                         Style : Resolved_Style) return Rectangle is
   begin
      return Shrink (Outer, Get_Padding_Px (Style));
   end Padding_Box;

   -------------------------------------------------
   -- Alignment
   -------------------------------------------------

   function Align_In (Container : Rectangle;
                      Item_Size : Size_2D;
                      H : H_Alignment := H_Left;
                      V : V_Alignment := V_Top) return Rectangle is
      Result_X, Result_Y : Pixel_Type;
      Result_W, Result_H : Pixel_Type;
   begin
      --  Horizontal
      case H is
         when H_Left =>
            Result_X := Container.X;
            Result_W := Item_Size.Width;
         when H_Center =>
            Result_X := Container.X + (Container.Width - Item_Size.Width) / 2.0;
            Result_W := Item_Size.Width;
         when H_Right =>
            Result_X := Container.X + Container.Width - Item_Size.Width;
            Result_W := Item_Size.Width;
         when H_Stretch =>
            Result_X := Container.X;
            Result_W := Container.Width;
      end case;

      --  Vertical
      case V is
         when V_Top =>
            Result_Y := Container.Y;
            Result_H := Item_Size.Height;
         when V_Middle =>
            Result_Y := Container.Y + (Container.Height - Item_Size.Height) / 2.0;
            Result_H := Item_Size.Height;
         when V_Bottom =>
            Result_Y := Container.Y + Container.Height - Item_Size.Height;
            Result_H := Item_Size.Height;
         when V_Stretch =>
            Result_Y := Container.Y;
            Result_H := Container.Height;
      end case;

      return (Result_X, Result_Y, Result_W, Result_H);
   end Align_In;

   function Align_H_From_CSS (Align : Text_Align_Value) return H_Alignment is
   begin
      case Align is
         when Text_Left | Text_Start => return H_Left;
         when Text_Center            => return H_Center;
         when Text_Right | Text_End  => return H_Right;
         when Text_Justify           => return H_Stretch;
      end case;
   end Align_H_From_CSS;

   function Align_V_From_CSS (Align : Vertical_Align_Value) return V_Alignment is
   begin
      case Align is
         when VA_Top | VA_Text_Top       => return V_Top;
         when VA_Middle                  => return V_Middle;
         when VA_Bottom | VA_Text_Bottom => return V_Bottom;
         when VA_Baseline                => return V_Top;  -- Simplified
      end case;
   end Align_V_From_CSS;

   -------------------------------------------------
   -- Icon + Text Layout
   -------------------------------------------------

   function Layout_Icon_Text (
      Container    : Rectangle;
      Icon_Size    : Size_2D;
      Has_Icon     : Boolean;
      Has_Text     : Boolean;
      Position     : Icon_Position := Icon_Left;
      Gap          : Pixel_Type := 8.0;
      Icon_V_Align : V_Alignment := V_Middle) return Icon_Text_Rects is

      Result : Icon_Text_Rects;
      Actual_Gap : Pixel_Type;
   begin
      Result.Has_Icon := Has_Icon;
      Result.Has_Text := Has_Text and Position /= Icon_Only;

      --  No gap if only one element
      if not Has_Icon or not Has_Text or Position = Icon_Only then
         Actual_Gap := 0.0;
      else
         Actual_Gap := Gap;
      end if;

      if not Has_Icon then
         --  Text only
         Result.Text_Rect := Container;
         Result.Icon_Rect := (0.0, 0.0, 0.0, 0.0);
         return Result;
      end if;

      if Position = Icon_Only or not Has_Text then
         --  Icon only, centered
         Result.Icon_Rect := Align_In (Container, Icon_Size, H_Center, V_Middle);
         Result.Text_Rect := (0.0, 0.0, 0.0, 0.0);
         Result.Has_Text := False;
         return Result;
      end if;

      --  Both icon and text
      case Position is
         when Icon_Left =>
            Result.Icon_Rect := Align_In (
               (Container.X, Container.Y, Icon_Size.Width, Container.Height),
               Icon_Size, H_Left, Icon_V_Align);
            Result.Text_Rect := (
               X => Container.X + Icon_Size.Width + Actual_Gap,
               Y => Container.Y,
               Width => Container.Width - Icon_Size.Width - Actual_Gap,
               Height => Container.Height);

         when Icon_Right =>
            Result.Text_Rect := (
               X => Container.X,
               Y => Container.Y,
               Width => Container.Width - Icon_Size.Width - Actual_Gap,
               Height => Container.Height);
            Result.Icon_Rect := Align_In (
               (Container.X + Container.Width - Icon_Size.Width, Container.Y,
                Icon_Size.Width, Container.Height),
               Icon_Size, H_Right, Icon_V_Align);

         when Icon_Top =>
            Result.Icon_Rect := Align_In (
               (Container.X, Container.Y, Container.Width, Icon_Size.Height),
               Icon_Size, H_Center, V_Top);
            Result.Text_Rect := (
               X => Container.X,
               Y => Container.Y + Icon_Size.Height + Actual_Gap,
               Width => Container.Width,
               Height => Container.Height - Icon_Size.Height - Actual_Gap);

         when Icon_Bottom =>
            Result.Text_Rect := (
               X => Container.X,
               Y => Container.Y,
               Width => Container.Width,
               Height => Container.Height - Icon_Size.Height - Actual_Gap);
            Result.Icon_Rect := Align_In (
               (Container.X, Container.Y + Container.Height - Icon_Size.Height,
                Container.Width, Icon_Size.Height),
               Icon_Size, H_Center, V_Bottom);

         when Icon_Only =>
            null;  -- Handled above
      end case;

      return Result;
   end Layout_Icon_Text;

   -------------------------------------------------
   -- Stack Layout
   -------------------------------------------------

   function Stack_Position (
      Container   : Rectangle;
      Item_Index  : Natural;
      Item_Count  : Positive;
      Item_Size   : Size_2D;
      Direction   : Stack_Direction;
      Gap         : Pixel_Type := 0.0;
      Main_Align  : H_Alignment := H_Left;
      Cross_Align : V_Alignment := V_Top) return Rectangle is

      Total      : constant Size_2D := Stack_Total_Size (Item_Count, Item_Size, Direction, Gap);
      Start_X    : Pixel_Type;
      Start_Y    : Pixel_Type;
      Item_X     : Pixel_Type;
      Item_Y     : Pixel_Type;
   begin
      --  Calculate starting position based on main axis alignment
      case Direction is
         when Dir_Horizontal =>
            case Main_Align is
               when H_Left | H_Stretch => Start_X := Container.X;
               when H_Center => Start_X := Container.X + (Container.Width - Total.Width) / 2.0;
               when H_Right => Start_X := Container.X + Container.Width - Total.Width;
            end case;
            Item_X := Start_X + Pixel_Type (Item_Index) * (Item_Size.Width + Gap);

            case Cross_Align is
               when V_Top | V_Stretch => Item_Y := Container.Y;
               when V_Middle => Item_Y := Container.Y + (Container.Height - Item_Size.Height) / 2.0;
               when V_Bottom => Item_Y := Container.Y + Container.Height - Item_Size.Height;
            end case;

         when Dir_Vertical =>
            case Cross_Align is
               when V_Top | V_Stretch => Start_Y := Container.Y;
               when V_Middle => Start_Y := Container.Y + (Container.Height - Total.Height) / 2.0;
               when V_Bottom => Start_Y := Container.Y + Container.Height - Total.Height;
            end case;
            Item_Y := Start_Y + Pixel_Type (Item_Index) * (Item_Size.Height + Gap);

            case Main_Align is
               when H_Left | H_Stretch => Item_X := Container.X;
               when H_Center => Item_X := Container.X + (Container.Width - Item_Size.Width) / 2.0;
               when H_Right => Item_X := Container.X + Container.Width - Item_Size.Width;
            end case;
      end case;

      return (Item_X, Item_Y, Item_Size.Width, Item_Size.Height);
   end Stack_Position;

   function Stack_Total_Size (
      Item_Count : Positive;
      Item_Size  : Size_2D;
      Direction  : Stack_Direction;
      Gap        : Pixel_Type := 0.0) return Size_2D is

      Total_Gap : constant Pixel_Type := Gap * Pixel_Type (Item_Count - 1);
   begin
      case Direction is
         when Dir_Horizontal =>
            return (Width => Item_Size.Width * Pixel_Type (Item_Count) + Total_Gap,
                    Height => Item_Size.Height);
         when Dir_Vertical =>
            return (Width => Item_Size.Width,
                    Height => Item_Size.Height * Pixel_Type (Item_Count) + Total_Gap);
      end case;
   end Stack_Total_Size;

   -------------------------------------------------
   -- Flex Distribution
   -------------------------------------------------

   function Distribute_Flex (
      Available : Pixel_Type;
      Items     : Flex_Item_Array;
      Gap       : Pixel_Type := 0.0) return Pixel_Array is

      Result      : Pixel_Array (Items'Range);
      Total_Gaps  : constant Pixel_Type := Gap * Pixel_Type (Items'Length - 1);
      Space       : Pixel_Type := Available - Total_Gaps;
      Total_Grow  : Float := 0.0;
      Total_Min   : Pixel_Type := 0.0;
   begin
      --  Calculate totals
      for I in Items'Range loop
         Total_Grow := Total_Grow + Items (I).Flex_Grow;
         Total_Min := Total_Min + Items (I).Min_Size;
      end loop;

      --  Simple distribution (doesn't handle shrink yet)
      if Total_Grow > 0.0 then
         declare
            Remaining : Pixel_Type := Space - Total_Min;
         begin
            for I in Items'Range loop
               if Items (I).Flex_Grow > 0.0 then
                  declare
                     Extra : constant Pixel_Type := Pixel_Type (
                        Float (Remaining) * Items (I).Flex_Grow / Total_Grow);
                  begin
                     Result (I) := Items (I).Min_Size + Extra;
                  end;
               else
                  Result (I) := Items (I).Min_Size;
               end if;
            end loop;
         end;
      else
         --  No flex grow, use min sizes
         for I in Items'Range loop
            Result (I) := Items (I).Min_Size;
         end loop;
      end if;

      return Result;
   end Distribute_Flex;


-------------------------------------------------
   -- Gap Extraction
   -------------------------------------------------

   function Get_Row_Gap(G : Gap_Value) return Pixel_Type is
   begin
      case G.Kind is
         when Gap_Uniform =>
            return Length_To_Px(G.All_Gap);
         when Gap_Separate =>
            return Length_To_Px(G.Row_Gap);
      end case;
   end Get_Row_Gap;

   function Get_Column_Gap(G : Gap_Value) return Pixel_Type is
   begin
      case G.Kind is
         when Gap_Uniform =>
            return Length_To_Px(G.All_Gap);
         when Gap_Separate =>
            return Length_To_Px(G.Column_Gap);
      end case;
   end Get_Column_Gap;

   function Is_Row_Direction(Dir : Flex_Direction_Value) return Boolean is
   begin
      return Dir = Row or Dir = Row_Reverse;
   end Is_Row_Direction;

   function Is_Reversed(Dir : Flex_Direction_Value) return Boolean is
   begin
      return Dir = Row_Reverse or Dir = Column_Reverse;
   end Is_Reversed;

   function Get_Main_Gap(G : Gap_Value; Dir : Flex_Direction_Value) return Pixel_Type is
   begin
      if Is_Row_Direction(Dir) then
         return Get_Column_Gap(G);  -- Column gap is between items in a row
      else
         return Get_Row_Gap(G);     -- Row gap is between items in a column
      end if;
   end Get_Main_Gap;

   function Get_Cross_Gap(G : Gap_Value; Dir : Flex_Direction_Value) return Pixel_Type is
   begin
      if Is_Row_Direction(Dir) then
         return Get_Row_Gap(G);     -- Row gap is between lines
      else
         return Get_Column_Gap(G);  -- Column gap is between lines
      end if;
   end Get_Cross_Gap;

   function Get_Main_Size(S : Size_2D; Dir : Flex_Direction_Value) return Pixel_Type is
   begin
      if Is_Row_Direction(Dir) then
         return S.Width;
      else
         return S.Height;
      end if;
   end Get_Main_Size;

   function Get_Cross_Size(S : Size_2D; Dir : Flex_Direction_Value) return Pixel_Type is
   begin
      if Is_Row_Direction(Dir) then
         return S.Height;
      else
         return S.Width;
      end if;
   end Get_Cross_Size;

   function Make_Size(Main, Cross : Pixel_Type; Dir : Flex_Direction_Value) return Size_2D is
   begin
      if Is_Row_Direction(Dir) then
         return (Width => Main, Height => Cross);
      else
         return (Width => Cross, Height => Main);
      end if;
   end Make_Size;

   -------------------------------------------------
   -- Flex Layout Algorithm
   -------------------------------------------------

   procedure Compute_Flex_Layout(
      Context   : Flex_Layout_Context;
      Children  : in out Flex_Child_Info_Array)
   is
      Container_Main  : constant Pixel_Type := Get_Main_Size(
         (Context.Container.Width, Context.Container.Height), Context.Direction);
      Container_Cross : constant Pixel_Type := Get_Cross_Size(
         (Context.Container.Width, Context.Container.Height), Context.Direction);

      Main_Gap : constant Pixel_Type := Context.Row_Gap;  -- Gap between items on main axis

      --  For simplicity, we implement single-line (no wrap) first
      --  Then extend to wrapping

      Total_Flex_Basis : Pixel_Type := 0.0;
      Total_Grow       : Float := 0.0;
      Total_Shrink     : Float := 0.0;
      Num_Children     : constant Natural := Children'Length;
      Total_Gaps       : Pixel_Type := 0.0;

      Available_Space  : Pixel_Type;
      Free_Space       : Pixel_Type;

      --  Current position along main axis
      Current_Pos      : Pixel_Type := 0.0;

      --  For space distribution
      Space_Per_Item   : Pixel_Type := 0.0;
      Initial_Space    : Pixel_Type := 0.0;
   begin
      if Num_Children = 0 then
         return;
      end if;

      --  Calculate total gaps
      if Num_Children > 1 then
         Total_Gaps := Main_Gap * Pixel_Type(Num_Children - 1);
      end if;

      --  Step 1: Calculate flex basis and totals
      for I in Children'Range loop
         declare
            Child : Flex_Child_Info renames Children(I);
            Basis : Pixel_Type;
         begin
            --  Determine flex basis
            Basis := Child.Flex_Basis;
            if Basis = 0.0 then
               --  Auto basis: use content size
               Basis := Child.Content_Main;
            end if;

            --  Clamp to min/max
            Basis := Pixel_Type'Max(Child.Min_Main,
                     Pixel_Type'Min(Child.Max_Main, Basis));

            Child.Computed_Main := Basis;
            Total_Flex_Basis := Total_Flex_Basis + Basis;
            Total_Grow := Total_Grow + Child.Flex_Grow;
            Total_Shrink := Total_Shrink + Child.Flex_Shrink * Float(Basis);
         end;
      end loop;

      --  Step 2: Calculate free space
      Available_Space := Container_Main - Total_Gaps;
      Free_Space := Available_Space - Total_Flex_Basis;

      --  Step 3: Distribute free space (grow or shrink)
      if Free_Space > 0.0 and Total_Grow > 0.0 then
         --  Grow items
         for I in Children'Range loop
            declare
               Child : Flex_Child_Info renames Children(I);
               Growth : Pixel_Type;
            begin
               if Child.Flex_Grow > 0.0 then
                  Growth := Pixel_Type(Float(Free_Space) * Child.Flex_Grow / Total_Grow);
                  Child.Computed_Main := Child.Computed_Main + Growth;
                  --  Clamp to max
                  Child.Computed_Main := Pixel_Type'Min(Child.Max_Main, Child.Computed_Main);
               end if;
            end;
         end loop;
      elsif Free_Space < 0.0 and Total_Shrink > 0.0 then
         --  Shrink items
         declare
            Shrink_Space : constant Pixel_Type := -Free_Space;
         begin
            for I in Children'Range loop
               declare
                  Child : Flex_Child_Info renames Children(I);
                  Shrink_Factor : Float;
                  Shrinkage : Pixel_Type;
               begin
                  if Child.Flex_Shrink > 0.0 then
                     Shrink_Factor := Child.Flex_Shrink * Float(Child.Computed_Main) / Total_Shrink;
                     Shrinkage := Pixel_Type(Float(Shrink_Space) * Shrink_Factor);
                     Child.Computed_Main := Child.Computed_Main - Shrinkage;
                     --  Clamp to min
                     Child.Computed_Main := Pixel_Type'Max(Child.Min_Main, Child.Computed_Main);
                  end if;
               end;
            end loop;
         end;
      end if;

      --  Step 4: Calculate actual used space after grow/shrink
      declare
         Actual_Used : Pixel_Type := 0.0;
      begin
         for I in Children'Range loop
            Actual_Used := Actual_Used + Children(I).Computed_Main;
         end loop;
         Free_Space := Available_Space - Actual_Used;
      end;

      --  Step 5: Position items based on justify-content
      --  When content overflows (Free_Space < 0), keep spacing non-negative
      --  so items overflow instead of collapsing/overlapping.
      case Context.Justify_Content is
         when Flex_Start =>
            Current_Pos := 0.0;
            Space_Per_Item := 0.0;
            Initial_Space := 0.0;

         when Flex_End =>
            Current_Pos := Pixel_Type'Max (0.0, Free_Space);
            Space_Per_Item := 0.0;
            Initial_Space := Current_Pos;

         when Center =>
            Current_Pos := Pixel_Type'Max (0.0, Free_Space) / 2.0;
            Space_Per_Item := 0.0;
            Initial_Space := Current_Pos;

         when Space_Between =>
            Current_Pos := 0.0;
            Initial_Space := 0.0;
            if Num_Children > 1 then
               Space_Per_Item := Pixel_Type'Max (0.0, Free_Space)
                 / Pixel_Type (Num_Children - 1);
            else
               Space_Per_Item := 0.0;
            end if;

         when Space_Around =>
            if Num_Children > 0 then
               Space_Per_Item := Pixel_Type'Max (0.0, Free_Space)
                 / Pixel_Type (Num_Children);
               Initial_Space := Space_Per_Item / 2.0;
               Current_Pos := Initial_Space;
            end if;

         when Space_Evenly =>
            if Num_Children > 0 then
               Space_Per_Item := Pixel_Type'Max (0.0, Free_Space)
                 / Pixel_Type (Num_Children + 1);
               Initial_Space := Space_Per_Item;
               Current_Pos := Space_Per_Item;
            end if;
      end case;

      --  Handle reversed direction
      if Is_Reversed(Context.Direction) then
         Current_Pos := Container_Main - Current_Pos;
      end if;

      --  Step 6: Assign positions and cross sizes
      for I in Children'Range loop
         declare
            Child : Flex_Child_Info renames Children(I);
            Cross_Start : Pixel_Type := 0.0;
            Effective_Align : Align_Items_Value;
         begin
            --  Main axis position
            if Is_Reversed(Context.Direction) then
               Current_Pos := Current_Pos - Child.Computed_Main;
               Child.Computed_Pos_Main := Current_Pos;
               if I < Children'Last then
                  Current_Pos := Current_Pos - Main_Gap - Space_Per_Item;
               end if;
            else
               Child.Computed_Pos_Main := Current_Pos;
               Current_Pos := Current_Pos + Child.Computed_Main + Main_Gap;
               if Context.Justify_Content in Space_Between | Space_Around | Space_Evenly then
                  Current_Pos := Current_Pos + Space_Per_Item;
               end if;
            end if;

            --  Cross axis sizing and alignment
            --  Determine effective alignment
            if Child.Align_Self = Auto then
               Effective_Align := Context.Align_Items;
            else
               --  Map Align_Self to Align_Items
               case Child.Align_Self is
                  when Auto => Effective_Align := Context.Align_Items;
                  when Adi.CSS_Styles.Flex_Start => Effective_Align := Adi.CSS_Styles.Flex_Start;
                  when Adi.CSS_Styles.Flex_End => Effective_Align := Adi.CSS_Styles.Flex_End;
                  when Adi.CSS_Styles.Center => Effective_Align := Adi.CSS_Styles.Center;
                  when Adi.CSS_Styles.Baseline => Effective_Align := Adi.CSS_Styles.Baseline;
                  when Adi.CSS_Styles.Stretch => Effective_Align := Adi.CSS_Styles.Stretch;
               end case;
            end if;

            case Effective_Align is
               when Adi.CSS_Styles.Flex_Start =>
                  Child.Computed_Cross := Child.Content_Cross;
                  Child.Computed_Cross := Pixel_Type'Max(Child.Min_Cross,
                     Pixel_Type'Min(Child.Max_Cross, Child.Computed_Cross));
                  Cross_Start := 0.0;

               when Adi.CSS_Styles.Flex_End =>
                  Child.Computed_Cross := Child.Content_Cross;
                  Child.Computed_Cross := Pixel_Type'Max(Child.Min_Cross,
                     Pixel_Type'Min(Child.Max_Cross, Child.Computed_Cross));
                  Cross_Start := Container_Cross - Child.Computed_Cross;

               when Adi.CSS_Styles.Center =>
                  Child.Computed_Cross := Child.Content_Cross;
                  Child.Computed_Cross := Pixel_Type'Max(Child.Min_Cross,
                     Pixel_Type'Min(Child.Max_Cross, Child.Computed_Cross));
                  Cross_Start := (Container_Cross - Child.Computed_Cross) / 2.0;

               when Adi.CSS_Styles.Stretch =>
                  Child.Computed_Cross := Container_Cross;
                  Child.Computed_Cross := Pixel_Type'Max(Child.Min_Cross,
                     Pixel_Type'Min(Child.Max_Cross, Child.Computed_Cross));
                  Cross_Start := 0.0;

               when Adi.CSS_Styles.Baseline =>
                  --  Simplified: treat as flex-start
                  Child.Computed_Cross := Child.Content_Cross;
                  Child.Computed_Cross := Pixel_Type'Max(Child.Min_Cross,
                     Pixel_Type'Min(Child.Max_Cross, Child.Computed_Cross));
                  Cross_Start := 0.0;
            end case;

            Child.Computed_Pos_Cross := Cross_Start;
         end;
      end loop;
   end Compute_Flex_Layout;

   -------------------------------------------------
   -- Convert Flex Results to Rectangles
   -------------------------------------------------

   function Flex_To_Rectangles(
      Context  : Flex_Layout_Context;
      Children : Flex_Child_Info_Array) return Rectangle_Array
   is
      Result : Rectangle_Array(Children'Range);
   begin
      for I in Children'Range loop
         declare
            Child : Flex_Child_Info renames Children(I);
            X, Y, W, H : Pixel_Type;
         begin
            if Is_Row_Direction(Context.Direction) then
               X := Context.Container.X + Child.Computed_Pos_Main;
               Y := Context.Container.Y + Child.Computed_Pos_Cross;
               W := Child.Computed_Main;
               H := Child.Computed_Cross;
            else
               X := Context.Container.X + Child.Computed_Pos_Cross;
               Y := Context.Container.Y + Child.Computed_Pos_Main;
               W := Child.Computed_Cross;
               H := Child.Computed_Main;
            end if;

            Result(I) := (X => X, Y => Y, Width => W, Height => H);
         end;
      end loop;

      return Result;
   end Flex_To_Rectangles;

end Adi.Layout_Util;
