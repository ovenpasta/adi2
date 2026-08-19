pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Adi.Core; use Adi.Core;
with Adi.SVG_Sprites;
with Adi.Image;
with Test_Support; use Test_Support;

procedure SVG_Sprites_Test is
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
      Own   : Image_Owner;
      Img   : Image_Handle;
      W, H  : Adi.Core.Pixel_Type;
   begin
      Put_Line ("Test: Get_Image");

      Sheet := Load_From_String (Sample_SVG);
      Assert (Sheet /= null, "sheet loaded");

      Own := Sheet.Get_Image ("icon-a");
      Img := Adi.Image.To_Handle (Own);
      Assert (Img /= Adi.Image.Null_Image_Handle, "icon-a image is not null");
      Assert (Adi.Image.Is_Valid (Img), "icon-a image is valid");
      Adi.Image.Get_Size (Img, W, H);
      Assert (W = 320.0, "icon-a width = 320, got" & W'Image);
      Assert (H = 512.0, "icon-a height = 512, got" & H'Image);

      Own := Sheet.Get_Image ("icon-b");
      Img := Adi.Image.To_Handle (Own);
      Assert (Img /= Adi.Image.Null_Image_Handle, "icon-b image is not null");
      Adi.Image.Get_Size (Img, W, H);
      Assert (W = 256.0, "icon-b width = 256, got" & W'Image);

      Own := Sheet.Get_Image ("icon-c");
      Img := Adi.Image.To_Handle (Own);
      Assert (Img /= Adi.Image.Null_Image_Handle, "icon-c image is not null (multi-path symbol)");

      Own := Sheet.Get_Image ("nonexistent");
      Img := Adi.Image.To_Handle (Own);
      Assert (Img = Adi.Image.Null_Image_Handle, "nonexistent returns null");

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
   Test_Support.Start_Suite ("SVG Sprites Test Suite");

   Test_Load_From_String;
   Test_Get_Image;
   Test_Empty_Source;

   Test_Support.Finish;
end SVG_Sprites_Test;
