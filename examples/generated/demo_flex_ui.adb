--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Demo_Flex_Styles; use Demo_Flex_Styles;

package body Demo_Flex_UI is

   package body Instance is
   Source : aliased Adi.CSS_Source.Style_Source;

   function Merge_Metadata
     (Base, Override : Adi.CSS_Parser.Stylesheet_Metadata)
      return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := Base;
   begin
      if Override.Has_Root_Style then
         if Result.Has_Root_Style then
            Result.Root_Styles :=
              Merge_Part_Styles (Result.Root_Styles, Override.Root_Styles);
         else
            Result.Root_Styles := Override.Root_Styles;
            Result.Has_Root_Style := True;
         end if;
      end if;
      if Override.Has_Root_Font_Size then
         Result.Has_Root_Font_Size := True;
         Result.Root_Font_Size := Override.Root_Font_Size;
      end if;
      return Result;
   end Merge_Metadata;

   function Static_Root_Metadata return Adi.CSS_Parser.Stylesheet_Metadata is
      Result : Adi.CSS_Parser.Stylesheet_Metadata := (others => <>);
   begin
      Result := Merge_Metadata (Result, Demo_Flex_Styles.Root_Metadata);
      return Result;
   end Static_Root_Metadata;

   procedure Tick_Styles (Reloaded : out Boolean;
                          Success  : out Boolean) is
   begin
      Reloaded := False;
      Success := True;
      declare
         Local_Reloaded : Boolean := False;
         Local_Success  : Boolean := True;
      begin
         Adi.CSS_Source.Tick (Source, Local_Reloaded, Local_Success);
         Reloaded := Reloaded or Local_Reloaded;
         Success := Success and Local_Success;
      end;
   end Tick_Styles;

   procedure Tick_Styles_CB (DT : Duration) is
      pragma Unreferenced (DT);
      Reloaded, Success : Boolean;
   begin
      Tick_Styles (Reloaded, Success);
   end Tick_Styles_CB;

   procedure Set_CSS_File (Path : String; Success : out Boolean) is
      Mode_OK : Boolean;
   begin
      Adi.CSS_Source.Clear_Dynamic_Entries (Source);
      Adi.CSS_Source.Add_Dynamic_File (Source, Path, Success);
      if Success then
         Adi.CSS_Source.Set_Mode
           (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         Adi.CSS_Source.Set_Auto_Reload (Source, True);
         Success := Mode_OK;
      end if;
   end Set_CSS_File;

   procedure Register_Root_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("root", Root_Class_Part_Styles));
   end Register_Root_Styles;

   procedure Register_Title_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("title", Title_Class_Part_Styles));
   end Register_Title_Styles;

   procedure Register_Section_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("section", Section_Class_Part_Styles));
   end Register_Section_Styles;

   procedure Register_Caption_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("caption", Caption_Class_Part_Styles));
   end Register_Caption_Styles;

   procedure Register_Note_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("note", Note_Class_Part_Styles));
   end Register_Note_Styles;

   procedure Register_Cases_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("cases", Cases_Class_Part_Styles));
   end Register_Cases_Styles;

   procedure Register_Case_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("case", Case_Class_Part_Styles));
   end Register_Case_Styles;

   procedure Register_Case_Label_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("case-label", Case_Label_Class_Part_Styles));
   end Register_Case_Label_Styles;

   procedure Register_Demo_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("demo", Demo_Class_Part_Styles));
   end Register_Demo_Styles;

   procedure Register_Tall_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tall", Tall_Class_Part_Styles));
   end Register_Tall_Styles;

   procedure Register_Dir_Row_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("dir-row", Dir_Row_Class_Part_Styles));
   end Register_Dir_Row_Styles;

   procedure Register_Item_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("item", Item_Class_Part_Styles));
   end Register_Item_Styles;

   procedure Register_Dir_Row_Rev_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("dir-row-rev", Dir_Row_Rev_Class_Part_Styles));
   end Register_Dir_Row_Rev_Styles;

   procedure Register_Dir_Col_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("dir-col", Dir_Col_Class_Part_Styles));
   end Register_Dir_Col_Styles;

   procedure Register_Dir_Col_Rev_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("dir-col-rev", Dir_Col_Rev_Class_Part_Styles));
   end Register_Dir_Col_Rev_Styles;

   procedure Register_Short_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("short", Short_Class_Part_Styles));
   end Register_Short_Styles;

   procedure Register_Bar_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("bar", Bar_Class_Part_Styles));
   end Register_Bar_Styles;

   procedure Register_Grow_1_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grow-1", Grow_1_Class_Part_Styles));
   end Register_Grow_1_Styles;

   procedure Register_Grow_2_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grow-2", Grow_2_Class_Part_Styles));
   end Register_Grow_2_Styles;

   procedure Register_Grow_0_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("grow-0", Grow_0_Class_Part_Styles));
   end Register_Grow_0_Styles;

   procedure Register_W320_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("w320", W320_Class_Part_Styles));
   end Register_W320_Styles;

   procedure Register_Shrink_Yes_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("shrink-yes", Shrink_Yes_Class_Part_Styles));
   end Register_Shrink_Yes_Styles;

   procedure Register_Shrink_No_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("shrink-no", Shrink_No_Class_Part_Styles));
   end Register_Shrink_No_Styles;

   procedure Register_Basis_40_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("basis-40", Basis_40_Class_Part_Styles));
   end Register_Basis_40_Styles;

   procedure Register_Basis_120_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("basis-120", Basis_120_Class_Part_Styles));
   end Register_Basis_120_Styles;

   procedure Register_Basis_200_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("basis-200", Basis_200_Class_Part_Styles));
   end Register_Basis_200_Styles;

   procedure Register_Just_Start_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("just-start", Just_Start_Class_Part_Styles));
   end Register_Just_Start_Styles;

   procedure Register_Just_Center_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("just-center", Just_Center_Class_Part_Styles));
   end Register_Just_Center_Styles;

   procedure Register_Just_End_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("just-end", Just_End_Class_Part_Styles));
   end Register_Just_End_Styles;

   procedure Register_Just_Between_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("just-between", Just_Between_Class_Part_Styles));
   end Register_Just_Between_Styles;

   procedure Register_Just_Around_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("just-around", Just_Around_Class_Part_Styles));
   end Register_Just_Around_Styles;

   procedure Register_Just_Evenly_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("just-evenly", Just_Evenly_Class_Part_Styles));
   end Register_Just_Evenly_Styles;

   procedure Register_Align_Start_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("align-start", Align_Start_Class_Part_Styles));
   end Register_Align_Start_Styles;

   procedure Register_H20_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("h20", H20_Class_Part_Styles));
   end Register_H20_Styles;

   procedure Register_H40_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("h40", H40_Class_Part_Styles));
   end Register_H40_Styles;

   procedure Register_H_Auto_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("h-auto", H_Auto_Class_Part_Styles));
   end Register_H_Auto_Styles;

   procedure Register_Align_Center_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("align-center", Align_Center_Class_Part_Styles));
   end Register_Align_Center_Styles;

   procedure Register_Align_End_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("align-end", Align_End_Class_Part_Styles));
   end Register_Align_End_Styles;

   procedure Register_Align_Stretch_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("align-stretch", Align_Stretch_Class_Part_Styles));
   end Register_Align_Stretch_Styles;

   procedure Register_W480_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("w480", W480_Class_Part_Styles));
   end Register_W480_Styles;

   procedure Register_Pinned_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("pinned", Pinned_Class_Part_Styles));
   end Register_Pinned_Styles;

   procedure Register_Elastic_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("elastic", Elastic_Class_Part_Styles));
   end Register_Elastic_Styles;

   procedure Register_H120_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("h120", H120_Class_Part_Styles));
   end Register_H120_Styles;

   procedure Register_W170_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("w170", W170_Class_Part_Styles));
   end Register_W170_Styles;

   procedure Register_Nowrap_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("nowrap", Nowrap_Class_Part_Styles));
   end Register_Nowrap_Styles;

   procedure Register_Align_Start_Items_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("align-start-items", Align_Start_Items_Class_Part_Styles));
   end Register_Align_Start_Items_Styles;

   procedure Register_Tile_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tile", Tile_Class_Part_Styles));
   end Register_Tile_Styles;

   procedure Register_Tile_Short_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tile-short", Tile_Short_Class_Part_Styles));
   end Register_Tile_Short_Styles;

   procedure Register_Wrap_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("wrap", Wrap_Class_Part_Styles));
   end Register_Wrap_Styles;

   procedure Register_Ac_Start_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("ac-start", Ac_Start_Class_Part_Styles));
   end Register_Ac_Start_Styles;

   procedure Register_Wrap_Reverse_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("wrap-reverse", Wrap_Reverse_Class_Part_Styles));
   end Register_Wrap_Reverse_Styles;

   procedure Register_Ac_Center_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("ac-center", Ac_Center_Class_Part_Styles));
   end Register_Ac_Center_Styles;

   procedure Register_Ac_End_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("ac-end", Ac_End_Class_Part_Styles));
   end Register_Ac_End_Styles;

   procedure Register_Ac_Between_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("ac-between", Ac_Between_Class_Part_Styles));
   end Register_Ac_Between_Styles;

   procedure Register_Ac_Around_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("ac-around", Ac_Around_Class_Part_Styles));
   end Register_Ac_Around_Styles;

   procedure Register_Ac_Stretch_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("ac-stretch", Ac_Stretch_Class_Part_Styles));
   end Register_Ac_Stretch_Styles;

   procedure Register_Self_Center_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("self-center", Self_Center_Class_Part_Styles));
   end Register_Self_Center_Styles;

   procedure Register_Self_End_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("self-end", Self_End_Class_Part_Styles));
   end Register_Self_End_Styles;

   procedure Register_Self_Stretch_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("self-stretch", Self_Stretch_Class_Part_Styles));
   end Register_Self_Stretch_Styles;

   procedure Register_Gap_Row_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("gap-row", Gap_Row_Class_Part_Styles));
   end Register_Gap_Row_Styles;

   procedure Register_Gap_Column_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("gap-column", Gap_Column_Class_Part_Styles));
   end Register_Gap_Column_Styles;

   procedure Register_Gap_Both_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("gap-both", Gap_Both_Class_Part_Styles));
   end Register_Gap_Both_Styles;

   procedure Register_H150_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("h150", H150_Class_Part_Styles));
   end Register_H150_Styles;

   procedure Register_W110_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("w110", W110_Class_Part_Styles));
   end Register_W110_Styles;

   procedure Register_Tile_Deep_Styles
     (S : in out Style_Source) is
   begin
      Add_Static_Entry
        (S, Class_Entry ("tile-deep", Tile_Deep_Class_Part_Styles));
   end Register_Tile_Deep_Styles;

   function Build
      return Adi.Window.Window_Handle is
      W : constant Adi.Window.Window_Handle :=
        Adi.Window.Create_Window_Handle ("Flex Layout Reference", Adi.Window.Extent (Px (617.0), Px (617.0)));
      Label_1 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Flex Layout Reference");
      Box_1 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_2 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-direction");
      Label_3 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Which way the main axis runs, and from which end it starts.");
      Box_2 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_3 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_4 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("row");
      Box_4 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_5 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_6 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_7 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Box_5 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_8 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("row-reverse");
      Box_6 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_9 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_10 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_11 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Box_7 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_12 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("column");
      Box_8 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_13 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_14 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Box_9 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_15 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("column-reverse");
      Box_10 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_16 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_17 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Box_11 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_18 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-grow");
      Label_19 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Free space is shared by grow factor: 1, 2, 1. The last item has grow 0 and keeps its 70px.");
      Box_12 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_13 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_14 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_15 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_16 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_17 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_20 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-shrink");
      Label_21 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Three 160px items in a 320px row. The red one has shrink 0 and keeps its width; the overflow comes off the other two.");
      Box_18 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_19 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_20 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_21 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_22 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_22 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-basis");
      Label_23 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Starting sizes of 40, 120 and 200px. Equal grow factors add the same amount to each, so the differences survive.");
      Box_23 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_24 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_25 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_26 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_27 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_24 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("justify-content");
      Label_25 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Where leftover main-axis space goes.");
      Box_28 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_29 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_26 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-start");
      Box_30 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_31 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_32 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_33 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_34 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_27 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("center");
      Box_35 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_36 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_37 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_38 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_39 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_28 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-end");
      Box_40 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_41 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_42 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_43 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_44 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_45 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_29 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("space-between");
      Box_46 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_47 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_48 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_49 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_50 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_30 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("space-around");
      Box_51 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_52 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_53 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_54 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_55 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_31 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("space-evenly");
      Box_56 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_57 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_58 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_59 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_60 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_32 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("align-items");
      Label_33 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Cross-axis placement. The third item has no height of its own, so only stretch gives it one.");
      Box_61 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_62 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_34 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-start");
      Box_63 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_64 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_65 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_66 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_67 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_35 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("center");
      Box_68 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_69 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_70 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_71 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_72 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_36 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-end");
      Box_73 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_74 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_75 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_76 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_77 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_37 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("stretch");
      Box_78 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_79 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_80 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_81 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_82 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_38 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("min-size freeze and redistribution");
      Label_39 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("620px of flex-basis in a 480px row. The two red items are already at their min-width and can give up nothing, so the green ones absorb the whole overflow and the row still ends flush with its border. Sharing the overflow by basis alone would leave the red items' share unabsorbed and the row would spill past the right edge.");
      Box_83 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_84 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_85 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_86 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_87 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_88 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_40 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-wrap");
      Label_41 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Four 40px tiles in a 170px row, aligned to the start of their line. nowrap keeps one line and lets it run past the border; wrap breaks where the next tile stops fitting; wrap-reverse builds the lines from the bottom up and takes the start of each line with it, so the short tile drops instead of rising.");
      Box_89 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_90 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_42 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("nowrap");
      Box_91 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_43 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_44 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_45 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_46 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_92 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_47 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("wrap");
      Box_93 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_48 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_49 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_50 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_51 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_94 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_52 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("wrap-reverse");
      Box_95 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_53 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_54 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_55 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_56 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_96 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_57 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("align-content");
      Label_58 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Where the lines sit once they are formed. Each row wraps into two lines and has cross-axis space left over; stretch is the only value that grows the lines themselves to take it up.");
      Box_97 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_98 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_59 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-start");
      Box_99 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_60 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_61 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_62 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_63 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_100 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_64 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("center");
      Box_101 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_65 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_66 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_67 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_68 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_102 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_69 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-end");
      Box_103 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_70 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_71 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_72 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_73 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_104 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_74 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("space-between");
      Box_105 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_75 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_76 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_77 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_78 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_106 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_79 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("space-around");
      Box_107 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_80 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_81 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_82 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_83 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_108 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_84 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("stretch");
      Box_109 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_85 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_86 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_87 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_88 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_110 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_89 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("align-self");
      Label_90 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("One item stepping out of the row's align-items: flex-start. Item 2 takes its own value; the others stay where the container put them.");
      Box_111 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_112 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_91 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("center");
      Box_113 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_92 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_93 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_94 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Box_114 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_95 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-end");
      Box_115 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_96 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_97 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_98 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Box_116 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_99 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("stretch");
      Box_117 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_100 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_101 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_102 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Box_118 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_103 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("row-gap and column-gap");
      Label_104 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("The two axes are separate. In a wrapping row, column-gap sits between items on a line and row-gap sits between the lines; gap names both at once, rows first.");
      Box_119 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_120 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_105 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("row-gap: 24px");
      Box_121 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_106 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_107 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_108 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_109 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_122 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_110 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("column-gap: 24px");
      Box_123 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_111 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_112 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_113 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_114 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_124 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_115 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("gap: 24px 6px");
      Box_125 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_116 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_117 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_118 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_119 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_126 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_120 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("align-items across lines");
      Label_121 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("Each line is as deep as its own deepest item, and alignment happens inside that line rather than across the whole box. The first line is 46px deep and the second 34px, so the shallow item on each lands at a different offset under the same value.");
      Box_127 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Box_128 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_122 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-start");
      Box_129 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_123 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_124 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_125 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_126 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_130 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_127 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("center");
      Box_131 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_128 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_129 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_130 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_131 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
      Box_132 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_132 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("flex-end");
      Box_133 : constant Adi.Widget.Box.Box_Handle := Adi.Widget.Box.Create_Handle;
      Label_133 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("1");
      Label_134 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("2");
      Label_135 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("3");
      Label_136 : constant Adi.Widget.Label.Label_Handle := Adi.Widget.Label.Create_Handle ("4");
   begin
      --  Create widgets
      Root := Adi.Widget.Box.Create_Handle;

      --  Register precompiled styles as static fallback
      Adi.CSS_Source.Clear_Static_Entries (Source);
      Register_Root_Styles (Source);
      Register_Title_Styles (Source);
      Register_Section_Styles (Source);
      Register_Caption_Styles (Source);
      Register_Note_Styles (Source);
      Register_Cases_Styles (Source);
      Register_Case_Styles (Source);
      Register_Case_Label_Styles (Source);
      Register_Demo_Styles (Source);
      Register_Tall_Styles (Source);
      Register_Dir_Row_Styles (Source);
      Register_Item_Styles (Source);
      Register_Dir_Row_Rev_Styles (Source);
      Register_Dir_Col_Styles (Source);
      Register_Dir_Col_Rev_Styles (Source);
      Register_Short_Styles (Source);
      Register_Bar_Styles (Source);
      Register_Grow_1_Styles (Source);
      Register_Grow_2_Styles (Source);
      Register_Grow_0_Styles (Source);
      Register_W320_Styles (Source);
      Register_Shrink_Yes_Styles (Source);
      Register_Shrink_No_Styles (Source);
      Register_Basis_40_Styles (Source);
      Register_Basis_120_Styles (Source);
      Register_Basis_200_Styles (Source);
      Register_Just_Start_Styles (Source);
      Register_Just_Center_Styles (Source);
      Register_Just_End_Styles (Source);
      Register_Just_Between_Styles (Source);
      Register_Just_Around_Styles (Source);
      Register_Just_Evenly_Styles (Source);
      Register_Align_Start_Styles (Source);
      Register_H20_Styles (Source);
      Register_H40_Styles (Source);
      Register_H_Auto_Styles (Source);
      Register_Align_Center_Styles (Source);
      Register_Align_End_Styles (Source);
      Register_Align_Stretch_Styles (Source);
      Register_W480_Styles (Source);
      Register_Pinned_Styles (Source);
      Register_Elastic_Styles (Source);
      Register_H120_Styles (Source);
      Register_W170_Styles (Source);
      Register_Nowrap_Styles (Source);
      Register_Align_Start_Items_Styles (Source);
      Register_Tile_Styles (Source);
      Register_Tile_Short_Styles (Source);
      Register_Wrap_Styles (Source);
      Register_Ac_Start_Styles (Source);
      Register_Wrap_Reverse_Styles (Source);
      Register_Ac_Center_Styles (Source);
      Register_Ac_End_Styles (Source);
      Register_Ac_Between_Styles (Source);
      Register_Ac_Around_Styles (Source);
      Register_Ac_Stretch_Styles (Source);
      Register_Self_Center_Styles (Source);
      Register_Self_End_Styles (Source);
      Register_Self_Stretch_Styles (Source);
      Register_Gap_Row_Styles (Source);
      Register_Gap_Column_Styles (Source);
      Register_Gap_Both_Styles (Source);
      Register_H150_Styles (Source);
      Register_W110_Styles (Source);
      Register_Tile_Deep_Styles (Source);
      Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

      --  Load dynamic CSS and choose mode
      declare
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Add_Dynamic_File
           (Source, "examples/css/demo_flex.css", Loaded);
         if Loaded then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Dynamic_Mode, Mode_OK);
         else
            Mode_OK := False;
         end if;
         if not Mode_OK then
            Adi.CSS_Source.Set_Mode
              (Source, Adi.CSS_Source.Static_Mode, Mode_OK);
         end if;
      end;

      Adi.CSS_Source.Attach_Window (Source, W);
      --  Bind every widget that has a CSS class
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Root);
      Adi.CSS_Source.Bind_Class (Source, "root", +Root);
      Adi.CSS_Source.Bind_Class (Source, "title", +Label_1);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_1);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_2);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_3);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_2);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_3);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_4);
      Adi.CSS_Source.Bind_Class (Source, "demo tall dir-row", +Box_4);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_5);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_6);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_7);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_5);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_8);
      Adi.CSS_Source.Bind_Class (Source, "demo tall dir-row-rev", +Box_6);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_9);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_10);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_11);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_7);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_12);
      Adi.CSS_Source.Bind_Class (Source, "demo tall dir-col", +Box_8);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_13);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_14);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_9);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_15);
      Adi.CSS_Source.Bind_Class (Source, "demo tall dir-col-rev", +Box_10);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_16);
      Adi.CSS_Source.Bind_Class (Source, "item", +Label_17);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_11);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_18);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_19);
      Adi.CSS_Source.Bind_Class (Source, "demo short", +Box_12);
      Adi.CSS_Source.Bind_Class (Source, "item bar grow-1", +Box_13);
      Adi.CSS_Source.Bind_Class (Source, "item bar grow-2", +Box_14);
      Adi.CSS_Source.Bind_Class (Source, "item bar grow-1", +Box_15);
      Adi.CSS_Source.Bind_Class (Source, "item bar grow-0", +Box_16);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_17);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_20);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_21);
      Adi.CSS_Source.Bind_Class (Source, "demo short w320", +Box_18);
      Adi.CSS_Source.Bind_Class (Source, "item bar shrink-yes", +Box_19);
      Adi.CSS_Source.Bind_Class (Source, "item bar shrink-no", +Box_20);
      Adi.CSS_Source.Bind_Class (Source, "item bar shrink-yes", +Box_21);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_22);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_22);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_23);
      Adi.CSS_Source.Bind_Class (Source, "demo short", +Box_23);
      Adi.CSS_Source.Bind_Class (Source, "item bar basis-40", +Box_24);
      Adi.CSS_Source.Bind_Class (Source, "item bar basis-120", +Box_25);
      Adi.CSS_Source.Bind_Class (Source, "item bar basis-200", +Box_26);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_27);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_24);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_25);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_28);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_29);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_26);
      Adi.CSS_Source.Bind_Class (Source, "demo short just-start", +Box_30);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_31);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_32);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_33);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_34);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_27);
      Adi.CSS_Source.Bind_Class (Source, "demo short just-center", +Box_35);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_36);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_37);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_38);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_39);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_28);
      Adi.CSS_Source.Bind_Class (Source, "demo short just-end", +Box_40);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_41);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_42);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_43);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_44);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_45);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_29);
      Adi.CSS_Source.Bind_Class (Source, "demo short just-between", +Box_46);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_47);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_48);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_49);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_50);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_30);
      Adi.CSS_Source.Bind_Class (Source, "demo short just-around", +Box_51);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_52);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_53);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_54);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_55);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_31);
      Adi.CSS_Source.Bind_Class (Source, "demo short just-evenly", +Box_56);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_57);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_58);
      Adi.CSS_Source.Bind_Class (Source, "item", +Box_59);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_60);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_32);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_33);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_61);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_62);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_34);
      Adi.CSS_Source.Bind_Class (Source, "demo tall align-start", +Box_63);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Box_64);
      Adi.CSS_Source.Bind_Class (Source, "item h40", +Box_65);
      Adi.CSS_Source.Bind_Class (Source, "item h-auto", +Box_66);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_67);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_35);
      Adi.CSS_Source.Bind_Class (Source, "demo tall align-center", +Box_68);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Box_69);
      Adi.CSS_Source.Bind_Class (Source, "item h40", +Box_70);
      Adi.CSS_Source.Bind_Class (Source, "item h-auto", +Box_71);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_72);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_36);
      Adi.CSS_Source.Bind_Class (Source, "demo tall align-end", +Box_73);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Box_74);
      Adi.CSS_Source.Bind_Class (Source, "item h40", +Box_75);
      Adi.CSS_Source.Bind_Class (Source, "item h-auto", +Box_76);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_77);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_37);
      Adi.CSS_Source.Bind_Class (Source, "demo tall align-stretch", +Box_78);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Box_79);
      Adi.CSS_Source.Bind_Class (Source, "item h40", +Box_80);
      Adi.CSS_Source.Bind_Class (Source, "item h-auto", +Box_81);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_82);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_38);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_39);
      Adi.CSS_Source.Bind_Class (Source, "demo short w480", +Box_83);
      Adi.CSS_Source.Bind_Class (Source, "item bar pinned", +Box_84);
      Adi.CSS_Source.Bind_Class (Source, "item bar elastic", +Box_85);
      Adi.CSS_Source.Bind_Class (Source, "item bar pinned", +Box_86);
      Adi.CSS_Source.Bind_Class (Source, "item bar elastic", +Box_87);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_88);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_40);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_41);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_89);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_90);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_42);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 nowrap align-start-items", +Box_91);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_43);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_44);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_45);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_46);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_92);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_47);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-start align-start-items", +Box_93);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_48);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_49);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_50);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_51);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_94);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_52);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap-reverse ac-start align-start-items", +Box_95);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_53);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_54);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_55);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_56);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_96);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_57);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_58);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_97);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_98);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_59);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-start", +Box_99);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_60);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_61);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_62);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_63);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_100);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_64);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-center", +Box_101);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_65);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_66);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_67);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_68);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_102);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_69);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-end", +Box_103);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_70);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_71);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_72);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_73);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_104);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_74);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-between", +Box_105);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_75);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_76);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_77);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_78);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_106);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_79);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-around", +Box_107);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_80);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_81);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_82);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_83);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_108);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_84);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-stretch", +Box_109);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_85);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_86);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_87);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_88);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_110);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_89);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_90);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_111);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_112);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_91);
      Adi.CSS_Source.Bind_Class (Source, "demo tall align-start", +Box_113);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Label_92);
      Adi.CSS_Source.Bind_Class (Source, "item h20 self-center", +Label_93);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Label_94);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_114);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_95);
      Adi.CSS_Source.Bind_Class (Source, "demo tall align-start", +Box_115);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Label_96);
      Adi.CSS_Source.Bind_Class (Source, "item h20 self-end", +Label_97);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Label_98);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_116);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_99);
      Adi.CSS_Source.Bind_Class (Source, "demo tall align-start", +Box_117);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Label_100);
      Adi.CSS_Source.Bind_Class (Source, "item self-stretch", +Label_101);
      Adi.CSS_Source.Bind_Class (Source, "item h20", +Label_102);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_118);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_103);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_104);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_119);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_120);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_105);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-start gap-row", +Box_121);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_106);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_107);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_108);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_109);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_122);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_110);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-start gap-column", +Box_123);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_111);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_112);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_113);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_114);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_124);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_115);
      Adi.CSS_Source.Bind_Class (Source, "demo h120 w170 wrap ac-start gap-both", +Box_125);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_116);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_117);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_118);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_119);
      Adi.CSS_Source.Bind_Class (Source, "section", +Box_126);
      Adi.CSS_Source.Bind_Class (Source, "caption", +Label_120);
      Adi.CSS_Source.Bind_Class (Source, "note", +Label_121);
      Adi.CSS_Source.Bind_Class (Source, "cases", +Box_127);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_128);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_122);
      Adi.CSS_Source.Bind_Class (Source, "demo h150 w110 wrap ac-start align-start", +Box_129);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-deep", +Label_123);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_124);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_125);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_126);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_130);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_127);
      Adi.CSS_Source.Bind_Class (Source, "demo h150 w110 wrap ac-start align-center", +Box_131);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-deep", +Label_128);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_129);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_130);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_131);
      Adi.CSS_Source.Bind_Class (Source, "case", +Box_132);
      Adi.CSS_Source.Bind_Class (Source, "case-label", +Label_132);
      Adi.CSS_Source.Bind_Class (Source, "demo h150 w110 wrap ac-start align-end", +Box_133);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-deep", +Label_133);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_134);
      Adi.CSS_Source.Bind_Class (Source, "item tile", +Label_135);
      Adi.CSS_Source.Bind_Class (Source, "item tile tile-short", +Label_136);

      --  Build hierarchy
      Adi.Widget.Add_Child (+Box_4, +Label_5);
      Adi.Widget.Add_Child (+Box_4, +Label_6);
      Adi.Widget.Add_Child (+Box_4, +Label_7);
      Adi.Widget.Add_Child (+Box_3, +Label_4);
      Adi.Widget.Add_Child (+Box_3, +Box_4);
      Adi.Widget.Add_Child (+Box_6, +Label_9);
      Adi.Widget.Add_Child (+Box_6, +Label_10);
      Adi.Widget.Add_Child (+Box_6, +Label_11);
      Adi.Widget.Add_Child (+Box_5, +Label_8);
      Adi.Widget.Add_Child (+Box_5, +Box_6);
      Adi.Widget.Add_Child (+Box_8, +Label_13);
      Adi.Widget.Add_Child (+Box_8, +Label_14);
      Adi.Widget.Add_Child (+Box_7, +Label_12);
      Adi.Widget.Add_Child (+Box_7, +Box_8);
      Adi.Widget.Add_Child (+Box_10, +Label_16);
      Adi.Widget.Add_Child (+Box_10, +Label_17);
      Adi.Widget.Add_Child (+Box_9, +Label_15);
      Adi.Widget.Add_Child (+Box_9, +Box_10);
      Adi.Widget.Add_Child (+Box_2, +Box_3);
      Adi.Widget.Add_Child (+Box_2, +Box_5);
      Adi.Widget.Add_Child (+Box_2, +Box_7);
      Adi.Widget.Add_Child (+Box_2, +Box_9);
      Adi.Widget.Add_Child (+Box_1, +Label_2);
      Adi.Widget.Add_Child (+Box_1, +Label_3);
      Adi.Widget.Add_Child (+Box_1, +Box_2);
      Adi.Widget.Add_Child (+Box_12, +Box_13);
      Adi.Widget.Add_Child (+Box_12, +Box_14);
      Adi.Widget.Add_Child (+Box_12, +Box_15);
      Adi.Widget.Add_Child (+Box_12, +Box_16);
      Adi.Widget.Add_Child (+Box_11, +Label_18);
      Adi.Widget.Add_Child (+Box_11, +Label_19);
      Adi.Widget.Add_Child (+Box_11, +Box_12);
      Adi.Widget.Add_Child (+Box_18, +Box_19);
      Adi.Widget.Add_Child (+Box_18, +Box_20);
      Adi.Widget.Add_Child (+Box_18, +Box_21);
      Adi.Widget.Add_Child (+Box_17, +Label_20);
      Adi.Widget.Add_Child (+Box_17, +Label_21);
      Adi.Widget.Add_Child (+Box_17, +Box_18);
      Adi.Widget.Add_Child (+Box_23, +Box_24);
      Adi.Widget.Add_Child (+Box_23, +Box_25);
      Adi.Widget.Add_Child (+Box_23, +Box_26);
      Adi.Widget.Add_Child (+Box_22, +Label_22);
      Adi.Widget.Add_Child (+Box_22, +Label_23);
      Adi.Widget.Add_Child (+Box_22, +Box_23);
      Adi.Widget.Add_Child (+Box_30, +Box_31);
      Adi.Widget.Add_Child (+Box_30, +Box_32);
      Adi.Widget.Add_Child (+Box_30, +Box_33);
      Adi.Widget.Add_Child (+Box_29, +Label_26);
      Adi.Widget.Add_Child (+Box_29, +Box_30);
      Adi.Widget.Add_Child (+Box_35, +Box_36);
      Adi.Widget.Add_Child (+Box_35, +Box_37);
      Adi.Widget.Add_Child (+Box_35, +Box_38);
      Adi.Widget.Add_Child (+Box_34, +Label_27);
      Adi.Widget.Add_Child (+Box_34, +Box_35);
      Adi.Widget.Add_Child (+Box_40, +Box_41);
      Adi.Widget.Add_Child (+Box_40, +Box_42);
      Adi.Widget.Add_Child (+Box_40, +Box_43);
      Adi.Widget.Add_Child (+Box_39, +Label_28);
      Adi.Widget.Add_Child (+Box_39, +Box_40);
      Adi.Widget.Add_Child (+Box_28, +Box_29);
      Adi.Widget.Add_Child (+Box_28, +Box_34);
      Adi.Widget.Add_Child (+Box_28, +Box_39);
      Adi.Widget.Add_Child (+Box_46, +Box_47);
      Adi.Widget.Add_Child (+Box_46, +Box_48);
      Adi.Widget.Add_Child (+Box_46, +Box_49);
      Adi.Widget.Add_Child (+Box_45, +Label_29);
      Adi.Widget.Add_Child (+Box_45, +Box_46);
      Adi.Widget.Add_Child (+Box_51, +Box_52);
      Adi.Widget.Add_Child (+Box_51, +Box_53);
      Adi.Widget.Add_Child (+Box_51, +Box_54);
      Adi.Widget.Add_Child (+Box_50, +Label_30);
      Adi.Widget.Add_Child (+Box_50, +Box_51);
      Adi.Widget.Add_Child (+Box_56, +Box_57);
      Adi.Widget.Add_Child (+Box_56, +Box_58);
      Adi.Widget.Add_Child (+Box_56, +Box_59);
      Adi.Widget.Add_Child (+Box_55, +Label_31);
      Adi.Widget.Add_Child (+Box_55, +Box_56);
      Adi.Widget.Add_Child (+Box_44, +Box_45);
      Adi.Widget.Add_Child (+Box_44, +Box_50);
      Adi.Widget.Add_Child (+Box_44, +Box_55);
      Adi.Widget.Add_Child (+Box_27, +Label_24);
      Adi.Widget.Add_Child (+Box_27, +Label_25);
      Adi.Widget.Add_Child (+Box_27, +Box_28);
      Adi.Widget.Add_Child (+Box_27, +Box_44);
      Adi.Widget.Add_Child (+Box_63, +Box_64);
      Adi.Widget.Add_Child (+Box_63, +Box_65);
      Adi.Widget.Add_Child (+Box_63, +Box_66);
      Adi.Widget.Add_Child (+Box_62, +Label_34);
      Adi.Widget.Add_Child (+Box_62, +Box_63);
      Adi.Widget.Add_Child (+Box_68, +Box_69);
      Adi.Widget.Add_Child (+Box_68, +Box_70);
      Adi.Widget.Add_Child (+Box_68, +Box_71);
      Adi.Widget.Add_Child (+Box_67, +Label_35);
      Adi.Widget.Add_Child (+Box_67, +Box_68);
      Adi.Widget.Add_Child (+Box_73, +Box_74);
      Adi.Widget.Add_Child (+Box_73, +Box_75);
      Adi.Widget.Add_Child (+Box_73, +Box_76);
      Adi.Widget.Add_Child (+Box_72, +Label_36);
      Adi.Widget.Add_Child (+Box_72, +Box_73);
      Adi.Widget.Add_Child (+Box_78, +Box_79);
      Adi.Widget.Add_Child (+Box_78, +Box_80);
      Adi.Widget.Add_Child (+Box_78, +Box_81);
      Adi.Widget.Add_Child (+Box_77, +Label_37);
      Adi.Widget.Add_Child (+Box_77, +Box_78);
      Adi.Widget.Add_Child (+Box_61, +Box_62);
      Adi.Widget.Add_Child (+Box_61, +Box_67);
      Adi.Widget.Add_Child (+Box_61, +Box_72);
      Adi.Widget.Add_Child (+Box_61, +Box_77);
      Adi.Widget.Add_Child (+Box_60, +Label_32);
      Adi.Widget.Add_Child (+Box_60, +Label_33);
      Adi.Widget.Add_Child (+Box_60, +Box_61);
      Adi.Widget.Add_Child (+Box_83, +Box_84);
      Adi.Widget.Add_Child (+Box_83, +Box_85);
      Adi.Widget.Add_Child (+Box_83, +Box_86);
      Adi.Widget.Add_Child (+Box_83, +Box_87);
      Adi.Widget.Add_Child (+Box_82, +Label_38);
      Adi.Widget.Add_Child (+Box_82, +Label_39);
      Adi.Widget.Add_Child (+Box_82, +Box_83);
      Adi.Widget.Add_Child (+Box_91, +Label_43);
      Adi.Widget.Add_Child (+Box_91, +Label_44);
      Adi.Widget.Add_Child (+Box_91, +Label_45);
      Adi.Widget.Add_Child (+Box_91, +Label_46);
      Adi.Widget.Add_Child (+Box_90, +Label_42);
      Adi.Widget.Add_Child (+Box_90, +Box_91);
      Adi.Widget.Add_Child (+Box_93, +Label_48);
      Adi.Widget.Add_Child (+Box_93, +Label_49);
      Adi.Widget.Add_Child (+Box_93, +Label_50);
      Adi.Widget.Add_Child (+Box_93, +Label_51);
      Adi.Widget.Add_Child (+Box_92, +Label_47);
      Adi.Widget.Add_Child (+Box_92, +Box_93);
      Adi.Widget.Add_Child (+Box_95, +Label_53);
      Adi.Widget.Add_Child (+Box_95, +Label_54);
      Adi.Widget.Add_Child (+Box_95, +Label_55);
      Adi.Widget.Add_Child (+Box_95, +Label_56);
      Adi.Widget.Add_Child (+Box_94, +Label_52);
      Adi.Widget.Add_Child (+Box_94, +Box_95);
      Adi.Widget.Add_Child (+Box_89, +Box_90);
      Adi.Widget.Add_Child (+Box_89, +Box_92);
      Adi.Widget.Add_Child (+Box_89, +Box_94);
      Adi.Widget.Add_Child (+Box_88, +Label_40);
      Adi.Widget.Add_Child (+Box_88, +Label_41);
      Adi.Widget.Add_Child (+Box_88, +Box_89);
      Adi.Widget.Add_Child (+Box_99, +Label_60);
      Adi.Widget.Add_Child (+Box_99, +Label_61);
      Adi.Widget.Add_Child (+Box_99, +Label_62);
      Adi.Widget.Add_Child (+Box_99, +Label_63);
      Adi.Widget.Add_Child (+Box_98, +Label_59);
      Adi.Widget.Add_Child (+Box_98, +Box_99);
      Adi.Widget.Add_Child (+Box_101, +Label_65);
      Adi.Widget.Add_Child (+Box_101, +Label_66);
      Adi.Widget.Add_Child (+Box_101, +Label_67);
      Adi.Widget.Add_Child (+Box_101, +Label_68);
      Adi.Widget.Add_Child (+Box_100, +Label_64);
      Adi.Widget.Add_Child (+Box_100, +Box_101);
      Adi.Widget.Add_Child (+Box_103, +Label_70);
      Adi.Widget.Add_Child (+Box_103, +Label_71);
      Adi.Widget.Add_Child (+Box_103, +Label_72);
      Adi.Widget.Add_Child (+Box_103, +Label_73);
      Adi.Widget.Add_Child (+Box_102, +Label_69);
      Adi.Widget.Add_Child (+Box_102, +Box_103);
      Adi.Widget.Add_Child (+Box_105, +Label_75);
      Adi.Widget.Add_Child (+Box_105, +Label_76);
      Adi.Widget.Add_Child (+Box_105, +Label_77);
      Adi.Widget.Add_Child (+Box_105, +Label_78);
      Adi.Widget.Add_Child (+Box_104, +Label_74);
      Adi.Widget.Add_Child (+Box_104, +Box_105);
      Adi.Widget.Add_Child (+Box_107, +Label_80);
      Adi.Widget.Add_Child (+Box_107, +Label_81);
      Adi.Widget.Add_Child (+Box_107, +Label_82);
      Adi.Widget.Add_Child (+Box_107, +Label_83);
      Adi.Widget.Add_Child (+Box_106, +Label_79);
      Adi.Widget.Add_Child (+Box_106, +Box_107);
      Adi.Widget.Add_Child (+Box_109, +Label_85);
      Adi.Widget.Add_Child (+Box_109, +Label_86);
      Adi.Widget.Add_Child (+Box_109, +Label_87);
      Adi.Widget.Add_Child (+Box_109, +Label_88);
      Adi.Widget.Add_Child (+Box_108, +Label_84);
      Adi.Widget.Add_Child (+Box_108, +Box_109);
      Adi.Widget.Add_Child (+Box_97, +Box_98);
      Adi.Widget.Add_Child (+Box_97, +Box_100);
      Adi.Widget.Add_Child (+Box_97, +Box_102);
      Adi.Widget.Add_Child (+Box_97, +Box_104);
      Adi.Widget.Add_Child (+Box_97, +Box_106);
      Adi.Widget.Add_Child (+Box_97, +Box_108);
      Adi.Widget.Add_Child (+Box_96, +Label_57);
      Adi.Widget.Add_Child (+Box_96, +Label_58);
      Adi.Widget.Add_Child (+Box_96, +Box_97);
      Adi.Widget.Add_Child (+Box_113, +Label_92);
      Adi.Widget.Add_Child (+Box_113, +Label_93);
      Adi.Widget.Add_Child (+Box_113, +Label_94);
      Adi.Widget.Add_Child (+Box_112, +Label_91);
      Adi.Widget.Add_Child (+Box_112, +Box_113);
      Adi.Widget.Add_Child (+Box_115, +Label_96);
      Adi.Widget.Add_Child (+Box_115, +Label_97);
      Adi.Widget.Add_Child (+Box_115, +Label_98);
      Adi.Widget.Add_Child (+Box_114, +Label_95);
      Adi.Widget.Add_Child (+Box_114, +Box_115);
      Adi.Widget.Add_Child (+Box_117, +Label_100);
      Adi.Widget.Add_Child (+Box_117, +Label_101);
      Adi.Widget.Add_Child (+Box_117, +Label_102);
      Adi.Widget.Add_Child (+Box_116, +Label_99);
      Adi.Widget.Add_Child (+Box_116, +Box_117);
      Adi.Widget.Add_Child (+Box_111, +Box_112);
      Adi.Widget.Add_Child (+Box_111, +Box_114);
      Adi.Widget.Add_Child (+Box_111, +Box_116);
      Adi.Widget.Add_Child (+Box_110, +Label_89);
      Adi.Widget.Add_Child (+Box_110, +Label_90);
      Adi.Widget.Add_Child (+Box_110, +Box_111);
      Adi.Widget.Add_Child (+Box_121, +Label_106);
      Adi.Widget.Add_Child (+Box_121, +Label_107);
      Adi.Widget.Add_Child (+Box_121, +Label_108);
      Adi.Widget.Add_Child (+Box_121, +Label_109);
      Adi.Widget.Add_Child (+Box_120, +Label_105);
      Adi.Widget.Add_Child (+Box_120, +Box_121);
      Adi.Widget.Add_Child (+Box_123, +Label_111);
      Adi.Widget.Add_Child (+Box_123, +Label_112);
      Adi.Widget.Add_Child (+Box_123, +Label_113);
      Adi.Widget.Add_Child (+Box_123, +Label_114);
      Adi.Widget.Add_Child (+Box_122, +Label_110);
      Adi.Widget.Add_Child (+Box_122, +Box_123);
      Adi.Widget.Add_Child (+Box_125, +Label_116);
      Adi.Widget.Add_Child (+Box_125, +Label_117);
      Adi.Widget.Add_Child (+Box_125, +Label_118);
      Adi.Widget.Add_Child (+Box_125, +Label_119);
      Adi.Widget.Add_Child (+Box_124, +Label_115);
      Adi.Widget.Add_Child (+Box_124, +Box_125);
      Adi.Widget.Add_Child (+Box_119, +Box_120);
      Adi.Widget.Add_Child (+Box_119, +Box_122);
      Adi.Widget.Add_Child (+Box_119, +Box_124);
      Adi.Widget.Add_Child (+Box_118, +Label_103);
      Adi.Widget.Add_Child (+Box_118, +Label_104);
      Adi.Widget.Add_Child (+Box_118, +Box_119);
      Adi.Widget.Add_Child (+Box_129, +Label_123);
      Adi.Widget.Add_Child (+Box_129, +Label_124);
      Adi.Widget.Add_Child (+Box_129, +Label_125);
      Adi.Widget.Add_Child (+Box_129, +Label_126);
      Adi.Widget.Add_Child (+Box_128, +Label_122);
      Adi.Widget.Add_Child (+Box_128, +Box_129);
      Adi.Widget.Add_Child (+Box_131, +Label_128);
      Adi.Widget.Add_Child (+Box_131, +Label_129);
      Adi.Widget.Add_Child (+Box_131, +Label_130);
      Adi.Widget.Add_Child (+Box_131, +Label_131);
      Adi.Widget.Add_Child (+Box_130, +Label_127);
      Adi.Widget.Add_Child (+Box_130, +Box_131);
      Adi.Widget.Add_Child (+Box_133, +Label_133);
      Adi.Widget.Add_Child (+Box_133, +Label_134);
      Adi.Widget.Add_Child (+Box_133, +Label_135);
      Adi.Widget.Add_Child (+Box_133, +Label_136);
      Adi.Widget.Add_Child (+Box_132, +Label_132);
      Adi.Widget.Add_Child (+Box_132, +Box_133);
      Adi.Widget.Add_Child (+Box_127, +Box_128);
      Adi.Widget.Add_Child (+Box_127, +Box_130);
      Adi.Widget.Add_Child (+Box_127, +Box_132);
      Adi.Widget.Add_Child (+Box_126, +Label_120);
      Adi.Widget.Add_Child (+Box_126, +Label_121);
      Adi.Widget.Add_Child (+Box_126, +Box_127);
      Adi.Widget.Add_Child (+Root, +Label_1);
      Adi.Widget.Add_Child (+Root, +Box_1);
      Adi.Widget.Add_Child (+Root, +Box_11);
      Adi.Widget.Add_Child (+Root, +Box_17);
      Adi.Widget.Add_Child (+Root, +Box_22);
      Adi.Widget.Add_Child (+Root, +Box_27);
      Adi.Widget.Add_Child (+Root, +Box_60);
      Adi.Widget.Add_Child (+Root, +Box_82);
      Adi.Widget.Add_Child (+Root, +Box_88);
      Adi.Widget.Add_Child (+Root, +Box_96);
      Adi.Widget.Add_Child (+Root, +Box_110);
      Adi.Widget.Add_Child (+Root, +Box_118);
      Adi.Widget.Add_Child (+Root, +Box_126);

      --  Auto-wire CSS live reload
      Adi.Window.Connect_Tick (W, Tick_Styles_CB'Unrestricted_Access);

      Adi.Window.Set_Root (W, +Root);
      return W;
   end Build;

   end Instance;

end Demo_Flex_UI;
