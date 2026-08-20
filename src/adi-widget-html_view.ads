--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Ada.Containers.Vectors;
with Adi.CSS_Parser;
with Adi.CSS_Styles;
with Adi.Font;
with Adi.Image;
with Adi.Signal;

package Adi.Widget.Html_View is

   type Html_View is new Widget with private;

   --  Typed handle
   type Html_View_Handle is private;
   Null_Html_View_Handle : constant Html_View_Handle;

   type Link_Click_Callback is access procedure
     (Self : Html_View_Handle;
      Href : String);

   package Link_Click_Signals is new Adi.Signal (Link_Click_Callback, null);

   --  Answer with a view of an image the callback keeps an owner for.
   --  The view returns a handle, which keeps nothing: loading into a
   --  local owner and returning its handle yields one that is already
   --  stale by the time the view draws.
   --
   --  The view caches what it is given, and asks again for an entry
   --  whose image has since been released -- so an owner may be let go
   --  and the image reloaded on the next request.
   type Asset_Load_Callback is access function
     (Self : Html_View_Handle;
      URI  : String) return Adi.Image.Image_Handle;

   type Resource_Load_Callback is access function
     (Self : Html_View_Handle;
      URI  : String) return String;

   --  Construction
   function Create_Handle return Html_View_Handle;

   --  Handle bridge
   function To_Widget_Handle (H : Html_View_Handle) return Widget_Handle;
   function Try_As_Html_View (H : Widget_Handle) return Html_View_Handle;
   function Is_Valid (H : Html_View_Handle) return Boolean;
   function "+" (H : Html_View_Handle) return Widget_Handle;
   procedure Set_Part_Styles
     (H : Html_View_Handle; Styles : Part_Style_Array);

   --  Widget methods
   procedure Set_HTML
     (Self   : in out Html_View;
      Source : String);
   function Get_HTML (Self : Html_View) return String;
   procedure Clear (Self : in out Html_View);

   procedure Set_Content_Scale
     (Self  : in out Html_View;
      Scale : Pixel_Type);
   function Get_Content_Scale (Self : Html_View) return Pixel_Type;

   procedure Connect_Link_Click
     (Self : in out Html_View; CB : Link_Click_Callback);
   function Connect_Link_Click
     (Self : in out Html_View; CB : Link_Click_Callback)
      return Link_Click_Signals.Connection_Id;
   procedure Disconnect_Link_Click
     (Self : in out Html_View; Id : Link_Click_Signals.Connection_Id);

   procedure Set_On_Load_Asset
     (Self     : in out Html_View;
      Callback : Asset_Load_Callback);

   procedure Set_On_Load_Resource
     (Self     : in out Html_View;
      Callback : Resource_Load_Callback);

   procedure Set_Default_Stylesheet
     (Self : in out Html_View;
      Path : String);
   procedure Set_Default_Stylesheet_String
     (Self : in out Html_View;
      CSS  : String);
   function Get_Default_Stylesheet (Self : Html_View) return String;

   --  Handle methods
   procedure Set_HTML (H : Html_View_Handle; Source : String);
   function  Get_HTML (H : Html_View_Handle) return String;
   procedure Clear (H : Html_View_Handle);
   procedure Set_Content_Scale (H : Html_View_Handle; Scale : Pixel_Type);
   function  Get_Content_Scale (H : Html_View_Handle) return Pixel_Type;
   procedure Connect_Link_Click
     (H : Html_View_Handle; CB : Link_Click_Callback);
   function  Connect_Link_Click
     (H : Html_View_Handle; CB : Link_Click_Callback)
      return Link_Click_Signals.Connection_Id;
   procedure Disconnect_Link_Click
     (H : Html_View_Handle; Id : Link_Click_Signals.Connection_Id);
   procedure Set_On_Load_Asset
     (H : Html_View_Handle; Callback : Asset_Load_Callback);
   procedure Set_On_Load_Resource
     (H : Html_View_Handle; Callback : Resource_Load_Callback);
   procedure Set_Default_Stylesheet
     (H : Html_View_Handle; Path : String);
   procedure Set_Default_Stylesheet_String
     (H : Html_View_Handle; CSS : String);
   function  Get_Default_Stylesheet (H : Html_View_Handle) return String;

   overriding procedure Build_Items (Self : in out Html_View);
   overriding procedure Layout (Self : in out Html_View);
   overriding function Measure_Content (Self : Html_View) return Size_2D;

   overriding procedure On_Mouse_Down
     (Self   : in out Html_View;
      X, Y   : Pixel_Type;
      Button : Mouse_Button;
      Clicks : Natural := 1);
   overriding procedure On_Mouse_Move
     (Self : in out Html_View;
      X, Y : Pixel_Type);
   overriding procedure On_Mouse_Up
     (Self   : in out Html_View;
      X, Y   : Pixel_Type;
      Button : Mouse_Button);

private
   type Node_Kind is (Element_Node, Text_Node, Break_Node);

   type Element_Attributes is record
      Id_Attr    : Unbounded_String := Null_Unbounded_String;
      Class_Attr : Unbounded_String := Null_Unbounded_String;
      Style_Attr : Unbounded_String := Null_Unbounded_String;
      Href_Attr  : Unbounded_String := Null_Unbounded_String;
      Src_Attr   : Unbounded_String := Null_Unbounded_String;
      Alt_Attr   : Unbounded_String := Null_Unbounded_String;
      Value_Attr : Unbounded_String := Null_Unbounded_String;
      Svg_Source_Attr : Unbounded_String := Null_Unbounded_String;
   end record;

   package Node_Index_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Natural);

   type Node (Kind : Node_Kind := Text_Node) is record
      Parent : Natural := 0;
      case Kind is
         when Element_Node =>
            Tag_Name : Unbounded_String := Null_Unbounded_String;
            Attrs    : Element_Attributes;
            Children : Node_Index_Vectors.Vector;
         when Text_Node =>
            Text : Unbounded_String := Null_Unbounded_String;
         when Break_Node =>
            null;
      end case;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Node);

   type Link_Fragment is record
      Geometry : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Href     : Unbounded_String := Null_Unbounded_String;
   end record;

   package Link_Fragment_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Link_Fragment);

   --  Two kinds of image reach this cache. One the view built itself,
   --  from an inline <svg>, and must end; one it was handed by the asset
   --  callback or the asset cache, which belongs to whoever handed it
   --  over. Own holds an image only in the first case, and is what tells
   --  them apart when the cache is dropped.
   type Cached_Image is record
      Src : Unbounded_String := Null_Unbounded_String;
      Img : Adi.Image.Image_Handle := Adi.Image.Null_Image_Handle;
      Own : Adi.Image.Image_Owner := Adi.Image.Null_Image_Owner;
   end record;

   package Cached_Image_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cached_Image);

   type Inline_Style_Cache_Entry is record
      Inline_Text : Unbounded_String := Null_Unbounded_String;
      Rules       : Adi.CSS_Styles.Style_Rules := Adi.CSS_Styles.Empty_Style;
   end record;

   package Inline_Style_Cache_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Inline_Style_Cache_Entry);

   --  What one layout pass decided, before any of it reaches the
   --  widget. Item is the buffer: entries come from Make_* and so carry
   --  null renderer caches, and this vector is never rendered -- only
   --  copies emitted into Self.Items are.
   type Document_Layout is record
      Items      : Items_List.Vector;
      Links      : Link_Fragment_Vectors.Vector;
      Content_W  : Pixel_Type := 0.0;
      Content_H  : Pixel_Type := 0.0;
      Scroll_H   : Pixel_Type := 0.0;
      Viewport_H : Pixel_Type := 0.0;
      --  False when the widget had no visible area to lay out in.
      Sized      : Boolean := False;
   end record;

   --  Everything a layout depends on. Position and scroll are absent by
   --  construction: the layout is in document space and emission places
   --  it. The numeric scales are compared by value; the two generations
   --  cover changes that leave every value here standing.
   --  Wraps rather than raising, as the font counter does: only
   --  equality matters here.
   type Document_Generation is mod 2 ** 32;

   --  Counts document layout passes. Wraps rather than raising; only
   --  differences between two readings mean anything, and they are read
   --  through Adi.Widget.Html_View.Testing.
   type Pass_Count is mod 2 ** 32;

   type Cache_Key is record
      Valid       : Boolean := False;
      Doc_Gen     : Document_Generation := 0;
      Font_Gen    : Adi.Font.Font_Generation := 0;
      Content_W   : Pixel_Type := 0.0;
      Content_H   : Pixel_Type := 0.0;
      DIP_Scale   : Pixel_Type := 0.0;
      UI_Scale    : Pixel_Type := 0.0;
      Text_Scale  : Pixel_Type := 0.0;
      HTML_Scale  : Pixel_Type := 0.0;
      Px_To_Dip   : Boolean := False;
      Root_Font   : Adi.CSS_Styles.Length_Value :=
        Adi.CSS_Styles.Default_Font_Size;
      Main_Style  : Adi.CSS_Styles.Resolved_Style;
      Text_Style  : Adi.CSS_Styles.Resolved_Style;
   end record;

   type Html_View is new Widget with record
      Source          : Unbounded_String := Null_Unbounded_String;
      Nodes           : Node_Vectors.Vector;
      Links           : Link_Fragment_Vectors.Vector;
      Image_Cache     : Cached_Image_Vectors.Vector;
      Inline_Style_Cache : Inline_Style_Cache_Vectors.Vector;
      Link_Click      : Link_Click_Signals.Signal;
      On_Load_Asset   : Asset_Load_Callback := null;
      On_Load_Resource : Resource_Load_Callback := null;
      CSS_Sheet       : Adi.CSS_Parser.Stylesheet;
      Root_Font_Size  : Adi.CSS_Styles.Length_Value :=
        Adi.CSS_Styles.Default_Font_Size;
      Hovered_Href    : Unbounded_String := Null_Unbounded_String;
      Pressed_Href    : Unbounded_String := Null_Unbounded_String;
      Pressed_Is_Link : Boolean := False;
      Content_Scale   : Pixel_Type := 1.0;
      Default_CSS : Unbounded_String := Null_Unbounded_String;

      --  Cached size from the most recent Layout_And_Build pass.  Used
      --  by Measure_Content so the widget reports its real document
      --  height (and the width it was laid out at) instead of a
      --  constant stub.  Zero means "not measured yet" — first frame
      --  falls back to a small default so the parent flex has something
      --  to assign, after which Layout_And_Build fills these in and
      --  subsequent measures return the real values.
      Cached_Content_W : Pixel_Type := 0.0;
      Cached_Content_H : Pixel_Type := 0.0;

      --  Advances whenever the document itself changes: new source, new
      --  stylesheet, or a different asset loader, which drops the image
      --  cache without touching the source.
      Doc_Generation : Document_Generation := 0;

      Layout_Cache : Document_Layout;
      Layout_Key   : Cache_Key;

      Layout_Passes : Pass_Count := 0;
   end record;

   type Html_View_Handle is record
      Id : Widget_Stores.Object_Id := Widget_Stores.Null_Id;
   end record;
   Null_Html_View_Handle : constant Html_View_Handle :=
     (Id => Widget_Stores.Null_Id);

   type Html_View_Access is access all Html_View'Class;

end Adi.Widget.Html_View;
