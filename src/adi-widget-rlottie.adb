with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.RLottie is

   function Create return RLottie_Widget_Access is
      Result : constant RLottie_Widget_Access := new RLottie_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (Result));
      return Result;
   end Create;

   function Create
     (Animation : RLottie_Animation_Access) return RLottie_Widget_Access
   is
      Result : constant RLottie_Widget_Access := Create;
   begin
      Set_Animation (Result.all, Animation);
      return Result;
   end Create;

   -------------------
   -- Create_Handle --
   -------------------

   function Create_Handle return RLottie_Handle is
   begin
      return (Id => Get_Handle (Create.all).Id);
   end Create_Handle;

   function Create_Handle
     (Animation : RLottie_Animation_Access) return RLottie_Handle is
   begin
      return (Id => Get_Handle (Create (Animation).all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : RLottie_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_RLottie (H : Widget_Handle) return RLottie_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in RLottie_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_RLottie_Handle;
   end Try_As_RLottie;

   function Is_Valid (H : RLottie_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : RLottie_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles (H : RLottie_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   --------------------
   -- Handle methods --
   --------------------

   function Load_From_File
     (H : RLottie_Handle; Path : String) return Boolean
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Load_From_File (RLottie_Widget (Ptr.all), Path);
      end if;
      return False;
   end Load_From_File;

   procedure Set_Animation
     (H : RLottie_Handle; Animation : RLottie_Animation_Access)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Animation (RLottie_Widget (Ptr.all), Animation);
      end if;
   end Set_Animation;

   function Get_Animation
     (H : RLottie_Handle) return RLottie_Animation_Access
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Animation (RLottie_Widget (Ptr.all));
      end if;
      return null;
   end Get_Animation;

   procedure Start (H : RLottie_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Start (RLottie_Widget (Ptr.all));
      end if;
   end Start;

   procedure Stop (H : RLottie_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Stop (RLottie_Widget (Ptr.all));
      end if;
   end Stop;

   procedure Reset (H : RLottie_Handle) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Reset (RLottie_Widget (Ptr.all));
      end if;
   end Reset;

   procedure Set_Looping (H : RLottie_Handle; Value : Boolean := True) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Looping (RLottie_Widget (Ptr.all), Value);
      end if;
   end Set_Looping;

   procedure Set_Playback_Speed
     (H : RLottie_Handle; Multiplier : Float := 1.0)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Playback_Speed (RLottie_Widget (Ptr.all), Multiplier);
      end if;
   end Set_Playback_Speed;

   function Is_Playing (H : RLottie_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Playing (RLottie_Widget (Ptr.all));
      end if;
      return False;
   end Is_Playing;

   function Is_Looping (H : RLottie_Handle) return Boolean is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Is_Looping (RLottie_Widget (Ptr.all));
      end if;
      return False;
   end Is_Looping;

   procedure Set_Max_Size
     (H          : RLottie_Handle;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Max_Size (RLottie_Widget (Ptr.all), Max_Width, Max_Height);
      end if;
   end Set_Max_Size;

   function Load_From_File
     (W    : in out RLottie_Widget;
      Path : String) return Boolean
   is
      Loaded : constant RLottie_Animation_Access :=
        Adi.RLottie.Load_From_File (Path);
   begin
      if Loaded = null then
         return False;
      end if;

      Set_Animation (W, Loaded);
      return True;
   end Load_From_File;

   procedure Set_Animation
     (W         : in out RLottie_Widget;
      Animation : RLottie_Animation_Access)
   is
   begin
      W.Animation := Animation;
      if W.Animation /= null then
         Set_Looping (W.Animation.all, W.Desired_Looping);
         Set_Playback_Speed (W.Animation.all, W.Desired_Playback_Speed);
      end if;
      Mark_Dirty (W);
   end Set_Animation;

   function Get_Animation
     (W : RLottie_Widget) return RLottie_Animation_Access
   is
   begin
      return W.Animation;
   end Get_Animation;

   procedure Start (W : in out RLottie_Widget) is
   begin
      if W.Animation /= null then
         Start (W.Animation.all);
         Mark_Dirty (W);
      end if;
   end Start;

   procedure Stop (W : in out RLottie_Widget) is
   begin
      if W.Animation /= null then
         Stop (W.Animation.all);
         Mark_Dirty (W);
      end if;
   end Stop;

   procedure Reset (W : in out RLottie_Widget) is
   begin
      if W.Animation /= null then
         Reset (W.Animation.all);
         Mark_Dirty (W);
      end if;
   end Reset;

   procedure Set_Looping (W : in out RLottie_Widget; Value : Boolean := True) is
   begin
      W.Desired_Looping := Value;
      if W.Animation /= null then
         Set_Looping (W.Animation.all, Value);
      end if;
   end Set_Looping;

   procedure Set_Playback_Speed
     (W          : in out RLottie_Widget;
      Multiplier : Float := 1.0)
   is
   begin
      W.Desired_Playback_Speed := Float'Max (0.01, Multiplier);
      if W.Animation /= null then
         Set_Playback_Speed (W.Animation.all, W.Desired_Playback_Speed);
      end if;
   end Set_Playback_Speed;

   function Is_Playing (W : RLottie_Widget) return Boolean is
   begin
      if W.Animation = null then
         return False;
      end if;
      return Is_Playing (W.Animation.all);
   end Is_Playing;

   function Is_Looping (W : RLottie_Widget) return Boolean is
   begin
      if W.Animation = null then
         return W.Desired_Looping;
      end if;
      return Is_Looping (W.Animation.all);
   end Is_Looping;

   procedure Set_Max_Size
     (W          : in out RLottie_Widget;
      Max_Width  : Pixel_Type;
      Max_Height : Pixel_Type)
   is
   begin
      W.Max_Width := Pixel_Type'Max (0.0, Max_Width);
      W.Max_Height := Pixel_Type'Max (0.0, Max_Height);
      Mark_Dirty (W);
   end Set_Max_Size;

   overriding function Measure_Content (W : RLottie_Widget) return Size_2D is
      Main_Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Result     : Size_2D := (0.0, 0.0);
      Scale      : Pixel_Type := 1.0;
   begin
      if W.Animation /= null and then Is_Valid (W.Animation.all) then
         Get_Size (W.Animation.all, Result.Width, Result.Height);
      end if;

      if Result.Width > 0.0 and then Result.Height > 0.0 then
         if W.Max_Width > 0.0 and then Result.Width > W.Max_Width then
            Scale := Pixel_Type'Min (Scale, W.Max_Width / Result.Width);
         end if;
         if W.Max_Height > 0.0 and then Result.Height > W.Max_Height then
            Scale := Pixel_Type'Min (Scale, W.Max_Height / Result.Height);
         end if;
         Result.Width := Result.Width * Scale;
         Result.Height := Result.Height * Scale;
      end if;

      return Outer_Size (Result, Main_Style);
   end Measure_Content;

   overriding procedure Build_Items (W : in out RLottie_Widget) is
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

   overriding procedure Layout (W : in out RLottie_Widget) is
      pragma Unreferenced (W);
   begin
      null;
   end Layout;

   overriding procedure On_Tick (W : in out RLottie_Widget; DT : Duration) is
      Changed : Boolean := False;
   begin
      Tick_Scroll_Animations (W, DT);

      if W.Animation /= null then
         Changed := Advance (W.Animation.all, DT);
         if Changed then
            Mark_Dirty (W);
         end if;
      end if;
   end On_Tick;

end Adi.Widget.RLottie;
