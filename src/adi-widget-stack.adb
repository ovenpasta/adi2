with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Layout_Util; use Adi.Layout_Util;

package body Adi.Widget.Stack is

   ---------------------------------------------------------------------------
   --  Construction
   ---------------------------------------------------------------------------

   function Create return Stack_Widget_Access is
      Result : constant Stack_Widget_Access := new Stack_Widget;
   begin
      Result.Flags := [Visible => True, others => False];
      return Result;
   end Create;

   ---------------------------------------------------------------------------
   --  Page Management
   ---------------------------------------------------------------------------

   procedure Add_Page (W : in out Stack_Widget; Id : Page_Id; Page : access Widget'Class) is
      PA : constant Widget_Access := Widget_Access (Page);
   begin
      Add_Child (W, Page);
      W.Pages (Id) := PA;

      if not W.Has_Active then
         W.Active := Id;
         W.Has_Active := True;
         Set_Flag (Page.all, Visible, True);
      else
         Set_Flag (Page.all, Visible, False);
      end if;
   end Add_Page;

   procedure Set_Active (W : in out Stack_Widget; Id : Page_Id) is
      Old_Page : Widget_Access;
      New_Page : constant Widget_Access := W.Pages (Id);
   begin
      if New_Page = null then
         return;
      end if;

      if Id = W.Active and then W.Has_Active then
         return;
      end if;

      --  Hide current active page
      if W.Has_Active then
         Old_Page := W.Pages (W.Active);
         if Old_Page /= null then
            Set_Flag (Old_Page.all, Visible, False);
         end if;
      end if;

      --  Show new active page
      W.Active := Id;
      W.Has_Active := True;
      Set_Flag (New_Page.all, Visible, True);
      Mark_Dirty (W);

      if W.On_Changed /= null then
         W.On_Changed (Id);
      end if;
   end Set_Active;

   function Get_Active (W : Stack_Widget) return Page_Id is
   begin
      return W.Active;
   end Get_Active;

   function Get_Active_Widget (W : Stack_Widget) return Widget_Access is
   begin
      if W.Has_Active then
         return W.Pages (W.Active);
      end if;
      return null;
   end Get_Active_Widget;

   function Get_Page (W : Stack_Widget; Id : Page_Id) return Widget_Access is
   begin
      return W.Pages (Id);
   end Get_Page;

   procedure Set_On_Changed (W  : in out Stack_Widget;
                              CB : Page_Changed_Callback) is
   begin
      W.On_Changed := CB;
   end Set_On_Changed;

   ---------------------------------------------------------------------------
   --  Build_Items
   ---------------------------------------------------------------------------

   overriding procedure Build_Items (W : in out Stack_Widget) is
   begin
      if Item_Count (W) = 0 then
         Add_Item (W, Make_Panel (Main_Part, W.Geometry, 0));
      end if;

      W.Items.Reference (Panel_Idx).Geometry := W.Geometry;
   end Build_Items;

   ---------------------------------------------------------------------------
   --  Layout - All children get the full content area
   ---------------------------------------------------------------------------

   overriding procedure Layout (W : in out Stack_Widget) is
      Style   : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Pad     : constant Edge_Pixels := Get_Padding_Px (Style);
      Border  : constant Edge_Pixels := Get_Border_Width_Px (Style);

      Content_X : constant Pixel_Type :=
         W.Geometry.X + Pad.Left + Border.Left;
      Content_Y : constant Pixel_Type :=
         W.Geometry.Y + Pad.Top + Border.Top;
      Content_W : constant Pixel_Type :=
         W.Geometry.Width - Pad.Left - Pad.Right - Border.Left - Border.Right;
      Content_H : constant Pixel_Type :=
         W.Geometry.Height - Pad.Top - Pad.Bottom - Border.Top - Border.Bottom;

      Child_Geom : constant Rectangle :=
         (X => Content_X, Y => Content_Y,
          Width => Content_W, Height => Content_H);
   begin
      for I in 1 .. Child_Count (W) loop
         Set_Geometry (Get_Child (W, I).all, Child_Geom);
         Layout (Get_Child (W, I).all);
      end loop;
   end Layout;

end Adi.Widget.Stack;
