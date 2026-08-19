--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

package Adi.Widget.Label is

   ---------------------------------------------------------------------------
   --  Label Widget - Displays text with optional icon
   --
   --  Parts:
   --    - Main_Part  : Container (controls flex layout of icon+text)
   --    - Icon_Part  : Icon/image styling
   --    - Label_Part : Text styling
   --
   --  Layout:
   --    Uses Main_Part style for flex layout (flex-direction, align-items, gap)
   --    Icon and text are positioned using item-based flex layout
   ---------------------------------------------------------------------------

   type Label_Widget is new Widget with private;
   type Label_Widget_Access is access all Label_Widget'Class;

   --  Typed handle
   type Label_Handle is private;
   Null_Label_Handle : constant Label_Handle;

   --  Construction
   function Create (Text : String := "") return Label_Widget_Access
     with Obsolescent => "Use Create_Handle";
   function Create_Handle (Text : String := "") return Label_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Label_Handle) return Widget_Handle;
   function Try_As_Label (H : Widget_Handle) return Label_Handle;
   function Is_Valid (H : Label_Handle) return Boolean;

   --  Content management (widget methods)
   procedure Set_Text (W : in out Label_Widget; Text : String);
   function Get_Text (W : Label_Widget) return String;
   procedure Set_Icon (W : in out Label_Widget; Icon : Image_Handle);
   function Get_Icon (W : Label_Widget) return Image_Handle;

   --  Content management (typed handle methods)
   procedure Set_Text (H : Label_Handle; Text : String);
   function  Get_Text (H : Label_Handle) return String;
   procedure Set_Icon (H : Label_Handle; Icon : Image_Handle);
   function "+" (H : Label_Handle) return Widget_Handle;
   procedure Set_Part_Styles (H : Label_Handle; Styles : Part_Style_Array);

   --  Override abstract methods
   overriding procedure Build_Items (W : in out Label_Widget);
   overriding procedure Layout (W : in out Label_Widget);

   --  Override size calculation
   overriding function Measure_Content (W : Label_Widget) return Size_2D;
   overriding function Measure_Content_At_Width
     (W : Label_Widget; Assigned_Width : Pixel_Type) return Size_2D;
   overriding function Get_Content_Min_Size (W : Label_Widget) return Size_2D;
   overriding function Get_Content_Min_Size_At_Width
     (W : Label_Widget; Assigned_Width : Pixel_Type) return Size_2D;

private

   --  Fixed item indices for Label_Widget items vector
   Panel_Idx : constant Positive := 1;
   Text_Idx  : constant Positive := 2;
   Icon_Idx  : constant Positive := 3;

   type Label_Widget is new Widget with record
      Text : Unbounded_String := Null_Unbounded_String;
      Icon : Image_Handle := Null_Image_Handle;

      --  Layout items (positioned by flex layout, then rendered as Items)
      Layout_Items : Layout_Item_List.Vector;
   end record;

   type Label_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Label_Handle : constant Label_Handle := (Id => Widget_Stores.Null_Id);

end Adi.Widget.Label;
