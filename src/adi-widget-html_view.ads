with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Vectors;
with Adi.Core;              use Adi.Core;
with Adi.CSS_Parser;
with Adi.Image;
with Adi.Widget;            use Adi.Widget;
with Adi.Window;

package Adi.Widget.Html_View is

   type Html_View is new Widget with private;
   type Html_View_Access is access all Html_View'Class;

   type Link_Click_Callback is access procedure
     (Self : access Html_View;
      Href : String);

   type Asset_Load_Callback is access function
     (Self : access Html_View;
      URI  : String) return Adi.Image.Image_Access;

   type Resource_Load_Callback is access function
     (Self : access Html_View;
      URI  : String) return String;

   function Create return Html_View_Access;

   procedure Attach_Window
     (Self : in out Html_View;
      Host : Adi.Window.Window_Access);

   procedure Set_HTML
     (Self   : in out Html_View;
      Source : String);
   function Get_HTML (Self : Html_View) return String;
   procedure Clear (Self : in out Html_View);

   procedure Set_On_Link_Click
     (Self     : in out Html_View;
      Callback : Link_Click_Callback);

   procedure Set_On_Load_Asset
     (Self     : in out Html_View;
      Callback : Asset_Load_Callback);

   procedure Set_On_Load_Resource
     (Self     : in out Html_View;
      Callback : Resource_Load_Callback);

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
   type Token_Kind is (Text_Token, Break_Token, Hr_Token, Image_Token);
   type Text_Style_Kind is
     (Normal_Text,
      Heading_1_Text,
      Heading_2_Text,
      Code_Text,
      Bold_Text,
      Italic_Text,
      Bold_Italic_Text);

   type Token (Kind : Token_Kind := Text_Token) is record
      Link_Href : Unbounded_String := Null_Unbounded_String;
      case Kind is
         when Text_Token =>
            Text : Unbounded_String := Null_Unbounded_String;
            Style_Kind : Text_Style_Kind := Normal_Text;
         when Image_Token =>
            Src : Unbounded_String := Null_Unbounded_String;
            Alt : Unbounded_String := Null_Unbounded_String;
         when others =>
            null;
      end case;
   end record;

   package Token_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Token);

   type Link_Fragment is record
      Geometry : Rectangle := (0.0, 0.0, 0.0, 0.0);
      Href     : Unbounded_String := Null_Unbounded_String;
   end record;

   package Link_Fragment_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Link_Fragment);

   type Cached_Image is record
      Src : Unbounded_String := Null_Unbounded_String;
      Img : Adi.Image.Image_Access := null;
   end record;

   package Cached_Image_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cached_Image);

   type Html_View is new Widget with record
      Source          : Unbounded_String := Null_Unbounded_String;
      Tokens          : Token_Vectors.Vector;
      Links           : Link_Fragment_Vectors.Vector;
      Image_Cache     : Cached_Image_Vectors.Vector;
      Host            : Adi.Window.Window_Access := null;
      On_Link_Click   : Link_Click_Callback := null;
      On_Load_Asset   : Asset_Load_Callback := null;
      On_Load_Resource : Resource_Load_Callback := null;
      CSS_Sheet       : Adi.CSS_Parser.Stylesheet;
      Hovered_Href    : Unbounded_String := Null_Unbounded_String;
      Pressed_Href    : Unbounded_String := Null_Unbounded_String;
      Pressed_Is_Link : Boolean := False;
   end record;

end Adi.Widget.Html_View;
