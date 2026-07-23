--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

with Adi.Core;
with Adi.CSS_Styles;
with Adi.Font;
with Adi.Text_Buffer;
with Ada.Containers.Vectors;

package Adi.Text_Layout is

   type Visual_Row is record
      Buffer_Line  : Positive := 1;
      Start_Column : Natural := 0;
      End_Column   : Natural := 0;
   end record;

   type Text_Layout is tagged private;

   function Wrap_Enabled
     (Label_Style : Adi.CSS_Styles.Resolved_Style) return Boolean;

   procedure Rebuild
     (L              : in out Text_Layout;
      B              : Adi.Text_Buffer.Text_Buffer;
      Label_Style    : Adi.CSS_Styles.Resolved_Style;
      Viewport_Width : Adi.Core.Pixel_Type);

   function Row_Count (L : Text_Layout) return Natural;
   function Row_At (L : Text_Layout; Index : Positive) return Visual_Row;

   function Row_Index_For_Position
     (L : Text_Layout;
      B : Adi.Text_Buffer.Text_Buffer;
      P : Adi.Text_Buffer.Position) return Positive;

   function Position_At_Point
     (L               : Text_Layout;
      B               : Adi.Text_Buffer.Text_Buffer;
      Label_Style     : Adi.CSS_Styles.Resolved_Style;
      Content_X       : Adi.Core.Pixel_Type;
      X, Y            : Adi.Core.Pixel_Type;
      Scroll_Offset_Y : Adi.Core.Pixel_Type;
      Line_Skip       : Adi.Core.Pixel_Type) return Adi.Text_Buffer.Position;

   function Position_At_Row_X
     (L           : Text_Layout;
      B           : Adi.Text_Buffer.Text_Buffer;
      Label_Style : Adi.CSS_Styles.Resolved_Style;
      Row_Index   : Positive;
      X_From_Row  : Adi.Core.Pixel_Type) return Adi.Text_Buffer.Position;

   function X_Offset_For_Column
     (L           : Text_Layout;
      B           : Adi.Text_Buffer.Text_Buffer;
      Label_Style : Adi.CSS_Styles.Resolved_Style;
      Row_Index   : Positive;
      Column      : Natural) return Adi.Core.Pixel_Type;

   function Row_Text
     (L        : Text_Layout;
      B        : Adi.Text_Buffer.Text_Buffer;
      Row      : Visual_Row) return String;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Visual_Row);

   type Text_Layout is tagged record
      Rows           : Row_Vectors.Vector;
      Cached_Version : Natural := Natural'Last;
      Cached_Width   : Adi.Core.Pixel_Type := Adi.Core.Pixel_Type'First;
      Cached_Font    : Adi.Font.Font_Attributes;
      Cached_Wrap    : Boolean := True;
   end record;

end Adi.Text_Layout;
