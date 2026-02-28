pragma Ada_2022;

with Ada.Directories;
with Ada.Streams.Stream_IO;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with Adi.App;
with Adi.Assets;
with Adi.Core;       use Adi.Core;
with Adi.CSS_Styles; use Adi.CSS_Styles;
with Adi.Font;       use Adi.Font;
with Adi.Image;      use Adi.Image;
with Adi.Log;
with Adi.SDL.TTF;    use Adi.SDL.TTF;

procedure Bundle_Test is
   use type System.Address;
   use type Adi.Assets.Asset_Mode;

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Passed := Passed + 1;
      else
         Failed := Failed + 1;
         Adi.Log.Error ("FAIL: " & Msg);
      end if;
   end Assert;

   ---------------------------------------------------------------------------
   --  Minimal 1x1 red PNG (69 bytes)
   ---------------------------------------------------------------------------

   Test_PNG : aliased constant Storage_Array :=
     (16#89#, 16#50#, 16#4E#, 16#47#, 16#0D#, 16#0A#, 16#1A#, 16#0A#,
      16#00#, 16#00#, 16#00#, 16#0D#, 16#49#, 16#48#, 16#44#, 16#52#,
      16#00#, 16#00#, 16#00#, 16#01#, 16#00#, 16#00#, 16#00#, 16#01#,
      16#08#, 16#02#, 16#00#, 16#00#, 16#00#, 16#90#, 16#77#, 16#53#,
      16#DE#, 16#00#, 16#00#, 16#00#, 16#0C#, 16#49#, 16#44#, 16#41#,
      16#54#, 16#78#, 16#9C#, 16#63#, 16#F8#, 16#CF#, 16#C0#, 16#00#,
      16#00#, 16#03#, 16#01#, 16#01#, 16#00#, 16#C9#, 16#FE#, 16#92#,
      16#EF#, 16#00#, 16#00#, 16#00#, 16#00#, 16#49#, 16#45#, 16#4E#,
      16#44#, 16#AE#, 16#42#, 16#60#, 16#82#);

   ---------------------------------------------------------------------------
   --  Minimal SVG with a symbol (for sprite testing)
   ---------------------------------------------------------------------------

   Test_SVG_Str : constant String :=
     "<svg xmlns=""http://www.w3.org/2000/svg"">" &
     "<symbol id=""home"" viewBox=""0 0 16 16"">" &
     "<rect width=""16"" height=""16"" fill=""white""/>" &
     "</symbol>" &
     "<symbol id=""star"" viewBox=""0 0 16 16"">" &
     "<circle cx=""8"" cy=""8"" r=""8"" fill=""white""/>" &
     "</symbol>" &
     "</svg>";

   Test_SVG : aliased constant Storage_Array
     (0 .. Storage_Offset (Test_SVG_Str'Length) - 1) :=
     [for I in 0 .. Storage_Offset (Test_SVG_Str'Length) - 1 =>
        Storage_Element (Character'Pos
          (Test_SVG_Str (Test_SVG_Str'First + Integer (I))))];

   ---------------------------------------------------------------------------
   --  Test text data
   ---------------------------------------------------------------------------

   Test_Text_Str : constant String := "Hello, bundle world!";

   Test_Text : aliased constant Storage_Array
     (0 .. Storage_Offset (Test_Text_Str'Length) - 1) :=
     [for I in 0 .. Storage_Offset (Test_Text_Str'Length) - 1 =>
        Storage_Element (Character'Pos
          (Test_Text_Str (Test_Text_Str'First + Integer (I))))];

   A : Adi.App.App;

begin
   A.Init;

   ---------------------------------------------------------------------------
   --  Mode tests
   ---------------------------------------------------------------------------

   Assert (Adi.Assets.Get_Mode = Adi.Assets.File_Mode,
           "default mode is File_Mode");

   Adi.Assets.Set_Mode (Adi.Assets.Bundle_Mode);
   Assert (Adi.Assets.Get_Mode = Adi.Assets.Bundle_Mode,
           "Set_Mode to Bundle_Mode");

   --  Reset to File_Mode for further tests (no assets loaded yet in the
   --  test because we haven't called Get_Image etc)
   Adi.Assets.Set_Mode (Adi.Assets.File_Mode);
   Assert (Adi.Assets.Get_Mode = Adi.Assets.File_Mode,
           "Set_Mode back to File_Mode");

   ---------------------------------------------------------------------------
   --  Register bundle entries
   ---------------------------------------------------------------------------

   Adi.Assets.Register
     ("test.png", Test_PNG'Address, Test_PNG'Length);
   Adi.Assets.Register
     ("icons.svg", Test_SVG'Address, Test_SVG'Length);
   Adi.Assets.Register
     ("greeting.txt", Test_Text'Address, Test_Text'Length);
   Adi.Assets.Register
     ("app://icons.svg", Test_SVG'Address, Test_SVG'Length);

   ---------------------------------------------------------------------------
   --  Bundle_Lookup tests (mode-independent)
   ---------------------------------------------------------------------------

   declare
      BD : Adi.Assets.Asset_Data;
   begin
      BD := Adi.Assets.Bundle_Lookup ("test.png");
      Assert (BD.Addr /= System.Null_Address,
              "Bundle_Lookup finds test.png");
      Assert (BD.Length = Test_PNG'Length,
              "Bundle_Lookup test.png has correct length");

      BD := Adi.Assets.Bundle_Lookup ("nonexistent.png");
      Assert (BD.Addr = System.Null_Address,
              "Bundle_Lookup returns Null_Asset for unknown key");

      --  Key format: exact match, no normalization
      BD := Adi.Assets.Bundle_Lookup ("./test.png");
      Assert (BD.Addr = System.Null_Address,
              "./test.png does NOT match test.png (distinct keys)");

      --  Scheme URI key
      BD := Adi.Assets.Bundle_Lookup ("app://icons.svg");
      Assert (BD.Addr /= System.Null_Address,
              "Bundle_Lookup finds app://icons.svg");
   end;

   ---------------------------------------------------------------------------
   --  Switch to Bundle_Mode and test asset loading
   ---------------------------------------------------------------------------

   Adi.Assets.Set_Mode (Adi.Assets.Bundle_Mode);

   --  Get_String test
   declare
      S : constant String := Adi.Assets.Get_String ("greeting.txt");
   begin
      Assert (S = "Hello, bundle world!",
              "Get_String returns correct content from bundle");
   end;

   --  Get_String unknown key
   declare
      S : constant String := Adi.Assets.Get_String ("missing.txt");
   begin
      Assert (S = "",
              "Get_String returns empty for unknown bundle key");
   end;

   --  Get_Image test (raster PNG)
   declare
      Img : constant Adi.Image.Image_Access :=
        Adi.Assets.Get_Image ("test.png");
   begin
      Assert (Img /= null, "Get_Image returns non-null for bundled PNG");
      if Img /= null then
         declare
            W, H : Adi.Core.Pixel_Type;
         begin
            Adi.Image.Get_Size (Img.all, W, H);
            Assert (W = 1.0, "bundled PNG width = 1");
            Assert (H = 1.0, "bundled PNG height = 1");
         end;
      end if;
   end;

   --  Get_Image unknown key
   declare
      Img : constant Adi.Image.Image_Access :=
        Adi.Assets.Get_Image ("nosuch.png");
   begin
      Assert (Img = null,
              "Get_Image returns null for unknown bundle key (no fallback)");
   end;

   --  SVG sprite test: icons.svg?id=home
   declare
      Img : constant Adi.Image.Image_Access :=
        Adi.Assets.Get_Image ("icons.svg?id=home");
   begin
      Assert (Img /= null,
              "Get_Image SVG sprite from bundle works");
   end;

   --  SVG sprite test: icons.svg?id=star
   declare
      Img : constant Adi.Image.Image_Access :=
        Adi.Assets.Get_Image ("icons.svg?id=star");
   begin
      Assert (Img /= null,
              "Get_Image SVG sprite 'star' from bundle works");
   end;

   --  SVG sprite unknown symbol
   declare
      Img : constant Adi.Image.Image_Access :=
        Adi.Assets.Get_Image ("icons.svg?id=nonexistent");
   begin
      Assert (Img = null,
              "Get_Image SVG sprite with unknown id returns null");
   end;

   --  Scheme URI sprite test: app://icons.svg?id=home
   declare
      Img : constant Adi.Image.Image_Access :=
        Adi.Assets.Get_Image ("app://icons.svg?id=home");
   begin
      Assert (Img /= null,
              "Get_Image scheme URI sprite from bundle works");
   end;

   --  Set_Mode after load should raise Program_Error
   declare
      Raised : Boolean := False;
   begin
      begin
         Adi.Assets.Set_Mode (Adi.Assets.File_Mode);
      exception
         when Program_Error =>
            Raised := True;
      end;
      Assert (Raised,
              "Set_Mode after asset load raises Program_Error");
   end;

   --  Clear_Cache test
   Adi.Assets.Clear_Cache;

   ---------------------------------------------------------------------------
   --  Font tests — Load_From_Memory using vendor font read at runtime
   ---------------------------------------------------------------------------

   declare
      Font_Path : constant String :=
        "vendor/open-sans/static/OpenSans-Regular.ttf";
      Font_Size : Natural;
   begin
      if Ada.Directories.Exists (Font_Path) then
         Font_Size :=
           Natural (Ada.Directories.Size (Font_Path));

         declare
            Font_Data : aliased Storage_Array (0 .. Storage_Offset (Font_Size) - 1);
            F         : Ada.Streams.Stream_IO.File_Type;
            S         : Ada.Streams.Stream_IO.Stream_Access;
         begin
            Ada.Streams.Stream_IO.Open
              (F, Ada.Streams.Stream_IO.In_File, Font_Path);
            S := Ada.Streams.Stream_IO.Stream (F);
            Storage_Array'Read (S, Font_Data);
            Ada.Streams.Stream_IO.Close (F);

            --  Load_From_Memory with auto-detected name
            declare
               H : constant Font_Handle :=
                 Adi.Font.Load_From_Memory
                   (Font_Data'Address, Font_Data'Length);
            begin
               Assert (H /= Null_Font,
                       "Load_From_Memory returns valid handle");

               if H /= Null_Font then
                  --  Get_TTF_Font at two sizes
                  declare
                     F16 : constant TTF_Font_Access :=
                       Adi.Font.Get_TTF_Font (H, 16.0);
                     F24 : constant TTF_Font_Access :=
                       Adi.Font.Get_TTF_Font (H, 24.0);
                  begin
                     Assert (F16 /= null,
                             "Get_TTF_Font 16px from memory font");
                     Assert (F24 /= null,
                             "Get_TTF_Font 24px from memory font");
                  end;
               end if;
            end;

            --  Load_From_Memory with explicit name override
            declare
               H2 : constant Font_Handle :=
                 Adi.Font.Load_From_Memory
                   (Font_Data'Address, Font_Data'Length,
                    Name => "TestCustomName");
            begin
               Assert (H2 /= Null_Font,
                       "Load_From_Memory with explicit Name works");
            end;

            --  Load_Asset in Bundle_Mode via registered font data
            Adi.Assets.Register
              ("test-font.ttf", Font_Data'Address, Font_Data'Length);

            declare
               H3 : constant Font_Handle :=
                 Adi.Font.Load_Asset ("test-font.ttf");
            begin
               Assert (H3 /= Null_Font,
                       "Load_Asset finds font from bundle");
            end;

            --  Load_Asset with unknown key
            declare
               H4 : constant Font_Handle :=
                 Adi.Font.Load_Asset ("nosuch-font.ttf");
            begin
               Assert (H4 = Null_Font,
                       "Load_Asset returns Null_Font for unknown key");
            end;
         end;
      else
         Adi.Log.Warning ("Skipping font tests: " & Font_Path & " not found");
      end if;
   end;

   --  Set_Mode after Load_Asset should also raise Program_Error
   --  (Load_Asset marks assets as loaded)
   declare
      Raised : Boolean := False;
   begin
      begin
         Adi.Assets.Set_Mode (Adi.Assets.File_Mode);
      exception
         when Program_Error =>
            Raised := True;
      end;
      Assert (Raised,
              "Set_Mode after Load_Asset raises Program_Error");
   end;

   ---------------------------------------------------------------------------
   --  Summary
   ---------------------------------------------------------------------------

   Adi.Log.Info ("Bundle test: " & Natural'Image (Passed) & " passed,"
                 & Natural'Image (Failed) & " failed");

   if Failed > 0 then
      raise Program_Error with "Bundle test failed";
   end if;
end Bundle_Test;
