pragma Ada_2022;

with Ada.Text_IO;          use Ada.Text_IO;
with Adi.Core;             use Adi.Core;
with Adi.CSS_Styles;       use Adi.CSS_Styles;
with Adi.Image;            use Adi.Image;
with Adi.Widget;           use Adi.Widget;
with Adi.Widget_Styles;    use Adi.Widget_Styles;
with Adi.Widget.Image;     use Adi.Widget.Image;
with Adi.Widget.Box;
with Adi.Layout_Util;      use Adi.Layout_Util;

procedure Image_Widget_Test is
   Eps : constant Pixel_Type := 0.5;

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Assert;

   procedure Assert_Close
     (Actual, Expected : Pixel_Type; Msg : String) is
   begin
      Assert (abs (Actual - Expected) <= Eps,
              Msg & " actual=" & Actual'Image & " expected=" & Expected'Image);
   end Assert_Close;

   --  Helper to create a test image with specific intrinsic dimensions
   function Make_Test_Image
     (W, H : Pixel_Type) return Image_Access
   is
   begin
      return Load_SVG_Path
        (Path_Data => "M0 0 L" & Integer (W)'Image & " 0 L"
                      & Integer (W)'Image & " " & Integer (H)'Image
                      & " L0 " & Integer (H)'Image & " Z",
         Size      => (Width => W, Height => H),
         Fill      => (R => 128, G => 128, B => 128, A => 255));
   end Make_Test_Image;

   -----------------------------------------------
   --  Test: Create / Get / Set image
   -----------------------------------------------
   procedure Test_Create_Default is
      W : constant Image_Widget_Access := Create;
   begin
      Put_Line ("Test: Create with no image");
      Assert (Get_Image (W.all) = null,
              "Default image should be null");
   end Test_Create_Default;

   procedure Test_Create_With_Image is
      Img : constant Image_Access := Make_Test_Image (100.0, 80.0);
      W   : constant Image_Widget_Access := Create (Img);
   begin
      Put_Line ("Test: Create with image");
      Assert (Get_Image (W.all) = Img,
              "Get_Image should return the image passed to Create");
   end Test_Create_With_Image;

   procedure Test_Set_Image is
      W   : constant Image_Widget_Access := Create;
      Img : constant Image_Access := Make_Test_Image (64.0, 48.0);
   begin
      Put_Line ("Test: Set_Image replaces the image");
      Assert (Get_Image (W.all) = null, "Initially null");
      W.Set_Image (Img);
      Assert (Get_Image (W.all) = Img,
              "Get_Image should return the new image after Set_Image");
   end Test_Set_Image;

   procedure Test_Set_Image_To_Null is
      Img : constant Image_Access := Make_Test_Image (32.0, 32.0);
      W   : constant Image_Widget_Access := Create (Img);
   begin
      Put_Line ("Test: Set_Image to null clears the image");
      W.Set_Image (null);
      Assert (Get_Image (W.all) = null,
              "Get_Image should return null after Set_Image(null)");
   end Test_Set_Image_To_Null;

   -----------------------------------------------
   --  Test: Measure_Content with no CSS size
   -----------------------------------------------
   procedure Test_Measure_No_CSS_Size is
      Img : constant Image_Access := Make_Test_Image (200.0, 150.0);
      W   : constant Image_Widget_Access := Create (Img);
      S   : Size_2D;
   begin
      Put_Line ("Test: Measure_Content without CSS width/height returns (0,0)");
      S := Measure_Content (W.all);
      Assert_Close (S.Width, 0.0,
                    "Width should be 0 (scalable, no CSS override)");
      Assert_Close (S.Height, 0.0,
                    "Height should be 0 (scalable, no CSS override)");
   end Test_Measure_No_CSS_Size;

   procedure Test_Measure_Null_Image is
      W : constant Image_Widget_Access := Create;
      S : Size_2D;
   begin
      Put_Line ("Test: Measure_Content with null image returns (0,0)");
      S := Measure_Content (W.all);
      Assert_Close (S.Width, 0.0, "Width should be 0 for null image");
      Assert_Close (S.Height, 0.0, "Height should be 0 for null image");
   end Test_Measure_Null_Image;

   -----------------------------------------------
   --  Test: Measure_Content with explicit CSS width
   -----------------------------------------------
   procedure Test_Measure_CSS_Width_Only is
      Img : constant Image_Access := Make_Test_Image (200.0, 100.0);
      W   : constant Image_Widget_Access := Create (Img);
      Icon_Rules : constant Style_Rules := (
         Width  => Set (Size (Px (80.0))),
         others => <>
      );
      S : Size_2D;
   begin
      Put_Line ("Test: Measure_Content with CSS width preserves aspect ratio");
      Set_Part_Style (W.all, Icon_Part,
                      From (Icon_Rules).Build);
      S := Measure_Content (W.all);
      Assert_Close (S.Width, 80.0,
                    "Width should match CSS value");
      Assert_Close (S.Height, 40.0,
                    "Height should be aspect-ratio-derived (80 * 100/200 = 40)");
   end Test_Measure_CSS_Width_Only;

   -----------------------------------------------
   --  Test: Measure_Content with explicit CSS height
   -----------------------------------------------
   procedure Test_Measure_CSS_Height_Only is
      Img : constant Image_Access := Make_Test_Image (200.0, 100.0);
      W   : constant Image_Widget_Access := Create (Img);
      Icon_Rules : constant Style_Rules := (
         Height => Set (Size (Px (60.0))),
         others => <>
      );
      S : Size_2D;
   begin
      Put_Line ("Test: Measure_Content with CSS height preserves aspect ratio");
      Set_Part_Style (W.all, Icon_Part,
                      From (Icon_Rules).Build);
      S := Measure_Content (W.all);
      Assert_Close (S.Width, 120.0,
                    "Width should be aspect-ratio-derived (60 * 200/100 = 120)");
      Assert_Close (S.Height, 60.0,
                    "Height should match CSS value");
   end Test_Measure_CSS_Height_Only;

   -----------------------------------------------
   --  Test: Measure_Content with both CSS width and height
   -----------------------------------------------
   procedure Test_Measure_CSS_Both is
      Img : constant Image_Access := Make_Test_Image (200.0, 100.0);
      W   : constant Image_Widget_Access := Create (Img);
      Icon_Rules : constant Style_Rules := (
         Width  => Set (Size (Px (50.0))),
         Height => Set (Size (Px (70.0))),
         others => <>
      );
      S : Size_2D;
   begin
      Put_Line ("Test: Measure_Content with both CSS width and height");
      Set_Part_Style (W.all, Icon_Part,
                      From (Icon_Rules).Build);
      S := Measure_Content (W.all);
      Assert_Close (S.Width, 50.0,
                    "Width should match CSS value");
      Assert_Close (S.Height, 70.0,
                    "Height should match CSS value (no aspect ratio)");
   end Test_Measure_CSS_Both;

   -----------------------------------------------
   --  Test: Preferred size does not blow out grid
   -----------------------------------------------
   procedure Test_Grid_Not_Blown_Out is
      Img : constant Image_Access := Make_Test_Image (800.0, 600.0);
      W1  : constant Image_Widget_Access := Create (Img);
      W2  : constant Image_Widget_Access := Create (Img);
      Pref1 : Size_2D;
      Pref2 : Size_2D;

      Ctx : Grid_Layout_Context;
      Kids : Grid_Child_Info_Array (1 .. 2);
      Rects : Rectangle_Array (1 .. 2);
   begin
      Put_Line ("Test: Large image does not blow out grid columns");

      Pref1 := Get_Preferred_Size (W1.all);
      Pref2 := Get_Preferred_Size (W2.all);

      --  Preferred size should be (0,0) since no CSS width/height set
      Assert_Close (Pref1.Width, 0.0, "Preferred width should be 0");
      Assert_Close (Pref1.Height, 0.0, "Preferred height should be 0");

      --  Put two images in a 400px-wide, 2-column grid with preferred floor
      Ctx := (
         Container           => (0.0, 0.0, 400.0, 300.0),
         Columns             => 2,
         Explicit_Rows       => 1,
         Row_Gap             => 0.0,
         Column_Gap          => 0.0,
         Use_Preferred_Floor => True,
         others              => <>
      );
      Kids (1) := (Active => True,
                   Grid_Column => 1, Grid_Row => 1,
                   Grid_Column_Span => 1, Grid_Row_Span => 1,
                   Min_Width => 0.0, Min_Height => 0.0,
                   Pref_Width => Pref1.Width,
                   Pref_Height => Pref1.Height,
                   others => <>);
      Kids (2) := (Active => True,
                   Grid_Column => 2, Grid_Row => 1,
                   Grid_Column_Span => 1, Grid_Row_Span => 1,
                   Min_Width => 0.0, Min_Height => 0.0,
                   Pref_Width => Pref2.Width,
                   Pref_Height => Pref2.Height,
                   others => <>);

      Compute_Grid_Layout (Ctx, Kids);
      Rects := Grid_To_Rectangles (Kids);

      Assert_Close (Rects (1).Width, 200.0,
                    "First image column should be 200px (400/2)");
      Assert_Close (Rects (2).Width, 200.0,
                    "Second image column should be 200px (400/2)");
      Assert_Close (Rects (2).X, 200.0,
                    "Second column should start at 200px");
   end Test_Grid_Not_Blown_Out;

   -----------------------------------------------
   --  Test: Build_Items creates expected items
   -----------------------------------------------
   procedure Test_Build_Items is
      Img : constant Image_Access := Make_Test_Image (64.0, 64.0);
      W   : constant Image_Widget_Access := Create (Img);
   begin
      Put_Line ("Test: Build_Items creates panel and image items");
      Set_Geometry (W.all, (X => 0.0, Y => 0.0, Width => 100.0, Height => 100.0));
      Build_Items (W.all);
      Assert (Item_Count (W.all) = 2,
              "Should have exactly 2 items (panel + image)");
   end Test_Build_Items;

   procedure Test_Build_Items_Idempotent is
      Img : constant Image_Access := Make_Test_Image (64.0, 64.0);
      W   : constant Image_Widget_Access := Create (Img);
   begin
      Put_Line ("Test: Build_Items is idempotent (no extra items on second call)");
      Set_Geometry (W.all, (X => 0.0, Y => 0.0, Width => 100.0, Height => 100.0));
      Build_Items (W.all);
      Build_Items (W.all);
      Assert (Item_Count (W.all) = 2,
              "Should still have exactly 2 items after second Build_Items");
   end Test_Build_Items_Idempotent;

   procedure Test_Initial_Item_Count is
      W : constant Image_Widget_Access := Create;
   begin
      Put_Line ("Test: Fresh image widget has 0 items before first render");
      Assert (Item_Count (W.all) = 0,
              "Item_Count should be 0 for a freshly created widget");
   end Test_Initial_Item_Count;

   -----------------------------------------------
   --  Test: Image widget in a flex box
   -----------------------------------------------
   procedure Test_Image_In_Flex_Box is
      Img   : constant Image_Access := Make_Test_Image (500.0, 400.0);
      W_Img : constant Image_Widget_Access := Create (Img);
      Box   : constant Adi.Widget.Box.Box_Widget_Access :=
        Adi.Widget.Box.Create;
      Box_Rules : constant Style_Rules := (
         Width  => Set (Size (Px (200.0))),
         Height => Set (Size (Px (150.0))),
         others => <>
      );
   begin
      Put_Line ("Test: Image in flex box gets box dimensions, not intrinsic");
      Set_Part_Style (Box.all, Main_Part,
                      From (Box_Rules).Build);
      Add_Child (Box.all, W_Img);

      --  Verify the image's preferred size doesn't demand 500x400
      declare
         Pref : constant Size_2D := Get_Preferred_Size (W_Img.all);
      begin
         Assert_Close (Pref.Width, 0.0,
                       "Image preferred width should be 0 in flex context");
         Assert_Close (Pref.Height, 0.0,
                       "Image preferred height should be 0 in flex context");
      end;
   end Test_Image_In_Flex_Box;

begin
   Put_Line ("========================================");
   Put_Line ("   Image Widget Tests");
   Put_Line ("========================================");
   New_Line;

   Test_Create_Default;
   Test_Create_With_Image;
   Test_Set_Image;
   Test_Set_Image_To_Null;
   New_Line;

   Test_Measure_No_CSS_Size;
   Test_Measure_Null_Image;
   Test_Measure_CSS_Width_Only;
   Test_Measure_CSS_Height_Only;
   Test_Measure_CSS_Both;
   New_Line;

   Test_Grid_Not_Blown_Out;
   Test_Build_Items;
   Test_Build_Items_Idempotent;
   Test_Initial_Item_Count;
   Test_Image_In_Flex_Box;
   New_Line;

   Put_Line ("========================================");
   Put_Line ("   Test Summary");
   Put_Line ("========================================");
   Put_Line ("Total tests:" & Test_Count'Image);
   Put_Line ("Passed:     " & Pass_Count'Image);
   Put_Line ("Failed:     " & Fail_Count'Image);
   New_Line;

   if Fail_Count = 0 then
      Put_Line ("All tests PASSED!");
   else
      Put_Line ("Some tests FAILED!");
   end if;
   Put_Line ("========================================");
end Image_Widget_Test;
