with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Animated_Image is

   function Create return Animated_Image_Widget_Access is
      Result : constant Animated_Image_Widget_Access := new Animated_Image_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      return Result;
   end Create;

   function Create
     (Animation : Animated_Image_Access) return Animated_Image_Widget_Access
   is
      Result : constant Animated_Image_Widget_Access := Create;
   begin
      Result.Animation := Animation;
      return Result;
   end Create;

   function Load_From_File
     (W    : in out Animated_Image_Widget;
      Path : String) return Boolean
   is
      Loaded : constant Animated_Image_Access :=
        Adi.Animated_Image.Load_From_File (Path);
   begin
      if Loaded = null then
         return False;
      end if;

      W.Animation := Loaded;
      Mark_Dirty (W);
      return True;
   end Load_From_File;

   procedure Set_Animation
     (W         : in out Animated_Image_Widget;
      Animation : Animated_Image_Access)
   is
   begin
      W.Animation := Animation;
      Mark_Dirty (W);
   end Set_Animation;

   function Get_Animation
     (W : Animated_Image_Widget) return Animated_Image_Access
   is
   begin
      return W.Animation;
   end Get_Animation;

   procedure Start (W : in out Animated_Image_Widget) is
   begin
      if W.Animation = null then
         return;
      end if;

      Start (W.Animation.all);
      Mark_Dirty (W);
   end Start;

   procedure Stop (W : in out Animated_Image_Widget) is
   begin
      if W.Animation = null then
         return;
      end if;

      Stop (W.Animation.all);
      Mark_Dirty (W);
   end Stop;

   procedure Reset (W : in out Animated_Image_Widget) is
   begin
      if W.Animation = null then
         return;
      end if;

      Reset (W.Animation.all);
      Mark_Dirty (W);
   end Reset;

   procedure Set_Looping
     (W     : in out Animated_Image_Widget;
      Value : Boolean := True)
   is
   begin
      if W.Animation = null then
         return;
      end if;

      Set_Looping (W.Animation.all, Value);
   end Set_Looping;

   function Is_Looping (W : Animated_Image_Widget) return Boolean is
   begin
      if W.Animation = null then
         return False;
      end if;

      return Is_Looping (W.Animation.all);
   end Is_Looping;

   function Is_Playing (W : Animated_Image_Widget) return Boolean is
   begin
      if W.Animation = null then
         return False;
      end if;

      return Is_Playing (W.Animation.all);
   end Is_Playing;

   overriding function Measure_Content (W : Animated_Image_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Result     : Size_2D := (0.0, 0.0);
   begin
      if W.Animation /= null and then Is_Valid (W.Animation.all) then
         Get_Size (W.Animation.all, Result.Width, Result.Height);
      end if;

      return Outer_Size (Result, Main_Style);
   end Measure_Content;

   overriding procedure Build_Items (W : in out Animated_Image_Widget) is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Content    : constant Rectangle := Content_Box (W.Geometry, Main_Style);
      Current    : Image_Access := null;
   begin
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
         Add_Item (W, Make_Image (Icon_Part, Content, null, 1));
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;
      W.Items.Reference (Image_Idx).Geometry := Content;

      if W.Animation /= null and then Is_Valid (W.Animation.all) then
         Current := Get_Current_Image (W.Animation.all);
      end if;

      W.Items.Reference (Image_Idx).Image_Source := Current;
   end Build_Items;

   overriding procedure Layout (W : in out Animated_Image_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Layout;

   overriding procedure On_Tick (W : in out Animated_Image_Widget; DT : Duration) is
      Frame_Changed : Boolean := False;
   begin
      Tick_Scroll_Animations (W, DT);

      if W.Animation /= null then
         Frame_Changed := Advance (W.Animation.all, DT);
         if Frame_Changed then
            Mark_Dirty (W);
         end if;
      end if;
   end On_Tick;

end Adi.Widget.Animated_Image;
