pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.SVG_Sprites;
with Adi.Image;

procedure SVG_Sprites_Test is
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

   Sample_SVG : constant String :=
     "<?xml version=""1.0"" encoding=""UTF-8""?>" &
     "<svg xmlns=""http://www.w3.org/2000/svg"" style=""display: none;"">" &
     "  <symbol id=""icon-a"" viewBox=""0 0 320 512"">" &
     "    <path d=""M160 32C71 32 0 103 0 192V320C0 408 71 480 160 480Z""></path>" &
     "  </symbol>" &
     "  <symbol id=""icon-b"" viewBox=""0 0 256 512"">" &
     "    <path d=""M256 464C256 472 248 480 240 480H16Z""></path>" &
     "  </symbol>" &
     "  <symbol id=""icon-c"" viewBox=""0 0 640 512"">" &
     "    <path d=""M320 0L640 512H0Z""></path>" &
     "    <path d=""M320 128L480 384H160Z""></path>" &
     "  </symbol>" &
     "</svg>";

   procedure Test_Load_From_String is
      use Adi.SVG_Sprites;
      Sheet : Sprite_Sheet_Access;
   begin
      Put_Line ("Test: Load_From_String");

      Sheet := Load_From_String (Sample_SVG);
      Assert (Sheet /= null, "sheet is not null");
      Assert (Sheet.Symbol_Count = 3, "found 3 symbols, got" & Sheet.Symbol_Count'Image);
      Assert (Sheet.Has_Symbol ("icon-a"), "has icon-a");
      Assert (Sheet.Has_Symbol ("icon-b"), "has icon-b");
      Assert (Sheet.Has_Symbol ("icon-c"), "has icon-c");
      Assert (not Sheet.Has_Symbol ("icon-d"), "does not have icon-d");

      Sheet.Destroy;
   end Test_Load_From_String;

   procedure Test_Get_Image is
      use Adi.SVG_Sprites;
      use Adi.Image;
      Sheet : Sprite_Sheet_Access;
      Img   : Image_Access;
      W, H  : Adi.Core.Pixel_Type;
   begin
      Put_Line ("Test: Get_Image");

      Sheet := Load_From_String (Sample_SVG);
      Assert (Sheet /= null, "sheet loaded");

      Img := Sheet.Get_Image ("icon-a");
      Assert (Img /= null, "icon-a image is not null");
      Assert (Img.Is_Valid, "icon-a image is valid");
      Img.Get_Size (W, H);
      Assert (W = 320.0, "icon-a width = 320, got" & W'Image);
      Assert (H = 512.0, "icon-a height = 512, got" & H'Image);

      Img := Sheet.Get_Image ("icon-b");
      Assert (Img /= null, "icon-b image is not null");
      Img.Get_Size (W, H);
      Assert (W = 256.0, "icon-b width = 256, got" & W'Image);

      Img := Sheet.Get_Image ("icon-c");
      Assert (Img /= null, "icon-c image is not null (multi-path symbol)");

      Img := Sheet.Get_Image ("nonexistent");
      Assert (Img = null, "nonexistent returns null");

      Sheet.Destroy;
   end Test_Get_Image;

   procedure Test_Empty_Source is
      use Adi.SVG_Sprites;
      Sheet : Sprite_Sheet_Access;
   begin
      Put_Line ("Test: Edge cases");

      Sheet := Load_From_String ("");
      Assert (Sheet = null, "empty string returns null");

      Sheet := Load_From_String ("<svg></svg>");
      Assert (Sheet /= null, "svg with no symbols returns non-null sheet");
      Assert (Sheet.Symbol_Count = 0, "no symbols found");
      Sheet.Destroy;
   end Test_Empty_Source;

begin
   Put_Line ("========================================");
   Put_Line ("   SVG Sprites Test Suite");
   Put_Line ("========================================");

   Test_Load_From_String;
   Test_Get_Image;
   Test_Empty_Source;

   Put_Line ("Total:" & Test_Count'Image
             & "  Passed:" & Pass_Count'Image
             & "  Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Put_Line ("FAILED");
   else
      Put_Line ("All tests PASSED!");
   end if;
end SVG_Sprites_Test;
