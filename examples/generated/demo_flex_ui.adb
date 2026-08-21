--  Auto-generated from XML
--  Do not edit manually

pragma Ada_2022;

with Adi.CSS_Parser;
with Adi.CSS_Source; use Adi.CSS_Source;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Widget; use Adi.Widget;
with Adi.Widget.Box; use Adi.Widget.Box;
with Adi.Widget.Label; use Adi.Widget.Label;
with Demo_Flex_Styles;

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

      --  Install the stylesheets as one batch: precompiled
      --  styles as static fallback, then dynamic CSS and the mode
      declare
         Update : Adi.CSS_Source.Update_Scope (Source'Access);
         pragma Unreferenced (Update);
         Loaded, Mode_OK : Boolean;
      begin
         Adi.CSS_Source.Clear_Static_Entries (Source);
         Demo_Flex_Styles.Register_Selectors (Source);
         Adi.CSS_Source.Set_Static_Metadata (Source, Static_Root_Metadata);

         Adi.CSS_Source.Clear_Dynamic_Entries (Source);
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
      --  Bind every widget under the selectors naming it
      Adi.CSS_Source.Bind_Root_Metadata (Source, +Root);
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Root,
         Tag_Name   => "box",
         Class_Name => "root",
         Id_Name    => "Root");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_1,
         Tag_Name   => "label",
         Class_Name => "title");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_1,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_2,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_3,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_2,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_3,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_4,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_4,
         Tag_Name   => "box",
         Class_Name => "demo tall dir-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_5,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_6,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_7,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_5,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_8,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_6,
         Tag_Name   => "box",
         Class_Name => "demo tall dir-row-rev");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_9,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_10,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_11,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_7,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_12,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_8,
         Tag_Name   => "box",
         Class_Name => "demo tall dir-col");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_13,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_14,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_9,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_15,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_10,
         Tag_Name   => "box",
         Class_Name => "demo tall dir-col-rev");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_16,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_17,
         Tag_Name   => "label",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_11,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_18,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_19,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_12,
         Tag_Name   => "box",
         Class_Name => "demo short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_13,
         Tag_Name   => "box",
         Class_Name => "item bar grow-1");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_14,
         Tag_Name   => "box",
         Class_Name => "item bar grow-2");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_15,
         Tag_Name   => "box",
         Class_Name => "item bar grow-1");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_16,
         Tag_Name   => "box",
         Class_Name => "item bar grow-0");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_17,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_20,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_21,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_18,
         Tag_Name   => "box",
         Class_Name => "demo short w320");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_19,
         Tag_Name   => "box",
         Class_Name => "item bar shrink-yes");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_20,
         Tag_Name   => "box",
         Class_Name => "item bar shrink-no");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_21,
         Tag_Name   => "box",
         Class_Name => "item bar shrink-yes");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_22,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_22,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_23,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_23,
         Tag_Name   => "box",
         Class_Name => "demo short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_24,
         Tag_Name   => "box",
         Class_Name => "item bar basis-40");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_25,
         Tag_Name   => "box",
         Class_Name => "item bar basis-120");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_26,
         Tag_Name   => "box",
         Class_Name => "item bar basis-200");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_27,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_24,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_25,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_28,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_29,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_26,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_30,
         Tag_Name   => "box",
         Class_Name => "demo short just-start");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_31,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_32,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_33,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_34,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_27,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_35,
         Tag_Name   => "box",
         Class_Name => "demo short just-center");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_36,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_37,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_38,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_39,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_28,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_40,
         Tag_Name   => "box",
         Class_Name => "demo short just-end");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_41,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_42,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_43,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_44,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_45,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_29,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_46,
         Tag_Name   => "box",
         Class_Name => "demo short just-between");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_47,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_48,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_49,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_50,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_30,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_51,
         Tag_Name   => "box",
         Class_Name => "demo short just-around");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_52,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_53,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_54,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_55,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_31,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_56,
         Tag_Name   => "box",
         Class_Name => "demo short just-evenly");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_57,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_58,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_59,
         Tag_Name   => "box",
         Class_Name => "item");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_60,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_32,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_33,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_61,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_62,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_34,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_63,
         Tag_Name   => "box",
         Class_Name => "demo tall align-start");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_64,
         Tag_Name   => "box",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_65,
         Tag_Name   => "box",
         Class_Name => "item h40");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_66,
         Tag_Name   => "box",
         Class_Name => "item h-auto");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_67,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_35,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_68,
         Tag_Name   => "box",
         Class_Name => "demo tall align-center");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_69,
         Tag_Name   => "box",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_70,
         Tag_Name   => "box",
         Class_Name => "item h40");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_71,
         Tag_Name   => "box",
         Class_Name => "item h-auto");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_72,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_36,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_73,
         Tag_Name   => "box",
         Class_Name => "demo tall align-end");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_74,
         Tag_Name   => "box",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_75,
         Tag_Name   => "box",
         Class_Name => "item h40");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_76,
         Tag_Name   => "box",
         Class_Name => "item h-auto");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_77,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_37,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_78,
         Tag_Name   => "box",
         Class_Name => "demo tall align-stretch");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_79,
         Tag_Name   => "box",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_80,
         Tag_Name   => "box",
         Class_Name => "item h40");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_81,
         Tag_Name   => "box",
         Class_Name => "item h-auto");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_82,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_38,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_39,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_83,
         Tag_Name   => "box",
         Class_Name => "demo short w480");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_84,
         Tag_Name   => "box",
         Class_Name => "item bar pinned");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_85,
         Tag_Name   => "box",
         Class_Name => "item bar elastic");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_86,
         Tag_Name   => "box",
         Class_Name => "item bar pinned");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_87,
         Tag_Name   => "box",
         Class_Name => "item bar elastic");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_88,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_40,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_41,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_89,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_90,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_42,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_91,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 nowrap align-start-items");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_43,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_44,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_45,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_46,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_92,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_47,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_93,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-start align-start-items");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_48,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_49,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_50,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_51,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_94,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_52,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_95,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap-reverse ac-start align-start-items");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_53,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_54,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_55,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_56,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_96,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_57,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_58,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_97,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_98,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_59,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_99,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-start");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_60,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_61,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_62,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_63,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_100,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_64,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_101,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-center");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_65,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_66,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_67,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_68,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_102,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_69,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_103,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-end");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_70,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_71,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_72,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_73,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_104,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_74,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_105,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-between");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_75,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_76,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_77,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_78,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_106,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_79,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_107,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-around");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_80,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_81,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_82,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_83,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_108,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_84,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_109,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-stretch");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_85,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_86,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_87,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_88,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_110,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_89,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_90,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_111,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_112,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_91,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_113,
         Tag_Name   => "box",
         Class_Name => "demo tall align-start");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_92,
         Tag_Name   => "label",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_93,
         Tag_Name   => "label",
         Class_Name => "item h20 self-center");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_94,
         Tag_Name   => "label",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_114,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_95,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_115,
         Tag_Name   => "box",
         Class_Name => "demo tall align-start");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_96,
         Tag_Name   => "label",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_97,
         Tag_Name   => "label",
         Class_Name => "item h20 self-end");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_98,
         Tag_Name   => "label",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_116,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_99,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_117,
         Tag_Name   => "box",
         Class_Name => "demo tall align-start");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_100,
         Tag_Name   => "label",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_101,
         Tag_Name   => "label",
         Class_Name => "item self-stretch");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_102,
         Tag_Name   => "label",
         Class_Name => "item h20");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_118,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_103,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_104,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_119,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_120,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_105,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_121,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-start gap-row");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_106,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_107,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_108,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_109,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_122,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_110,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_123,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-start gap-column");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_111,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_112,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_113,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_114,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_124,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_115,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_125,
         Tag_Name   => "box",
         Class_Name => "demo h120 w170 wrap ac-start gap-both");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_116,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_117,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_118,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_119,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_126,
         Tag_Name   => "box",
         Class_Name => "section");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_120,
         Tag_Name   => "label",
         Class_Name => "caption");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_121,
         Tag_Name   => "label",
         Class_Name => "note");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_127,
         Tag_Name   => "box",
         Class_Name => "cases");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_128,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_122,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_129,
         Tag_Name   => "box",
         Class_Name => "demo h150 w110 wrap ac-start align-start");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_123,
         Tag_Name   => "label",
         Class_Name => "item tile tile-deep");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_124,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_125,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_126,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_130,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_127,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_131,
         Tag_Name   => "box",
         Class_Name => "demo h150 w110 wrap ac-start align-center");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_128,
         Tag_Name   => "label",
         Class_Name => "item tile tile-deep");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_129,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_130,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_131,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_132,
         Tag_Name   => "box",
         Class_Name => "case");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_132,
         Tag_Name   => "label",
         Class_Name => "case-label");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Box_133,
         Tag_Name   => "box",
         Class_Name => "demo h150 w110 wrap ac-start align-end");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_133,
         Tag_Name   => "label",
         Class_Name => "item tile tile-deep");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_134,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_135,
         Tag_Name   => "label",
         Class_Name => "item tile");
      Adi.CSS_Source.Bind_Selector_Set
        (Source     => Source,
         W          => +Label_136,
         Tag_Name   => "label",
         Class_Name => "item tile tile-short");

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
