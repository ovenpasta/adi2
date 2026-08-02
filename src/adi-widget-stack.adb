--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

pragma Ada_2022;

with Adi.CSS_Styles;  use Adi.CSS_Styles;
with Adi.Layout_Util; use Adi.Layout_Util;
with Adi.Log;

package body Adi.Widget.Stack is

   function Child_Participates (Child : Widget_Access) return Boolean is
   begin
      return Child /= null
        and then Has_Flag (Child.all, Visible)
        and then Get_Resolved_Part_Style (Child.all, Main_Part).Display /= Display_None;
   end Child_Participates;

   ---------------------------------------------------------------------------
   --  Construction
   ---------------------------------------------------------------------------

   function Create_Handle return Stack_Handle is
      Result : constant Stack_Widget_Access := new Stack_Widget;
      P      : constant access Widget'Class := Result.all'Unchecked_Access;
   begin
      Result.Flags := [Visible => True, others => False];
      Register_Widget (Widget_Access (P));
      return (Id => Get_Handle (Result.all).Id);
   end Create_Handle;

   ----------------------
   -- Handle bridge --
   ----------------------

   function To_Widget_Handle (H : Stack_Handle) return Widget_Handle is
   begin
      return (Id => H.Id);
   end To_Widget_Handle;

   function Try_As_Stack (H : Widget_Handle) return Stack_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null and then Ptr.all in Stack_Widget'Class then
         return (Id => H.Id);
      end if;
      return Null_Stack_Handle;
   end Try_As_Stack;

   function Is_Valid (H : Stack_Handle) return Boolean is
   begin
      return Widget_Stores.Is_Valid (H.Id);
   end Is_Valid;

   function "+" (H : Stack_Handle) return Widget_Handle is
   begin
      return To_Widget_Handle (H);
   end "+";

   procedure Set_Part_Styles (H : Stack_Handle; Styles : Part_Style_Array) is
   begin
      Adi.Widget.Set_Part_Styles (To_Widget_Handle (H), Styles);
   end Set_Part_Styles;

   ---------------------------------------------------------------------------
   --  Page Management
   ---------------------------------------------------------------------------

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

      declare
         procedure Call (CB : Page_Changed_Callback) is begin CB (Id); end Call;
         procedure Emit is new Page_Changed_Signals.For_Each (Call);
      begin
         Emit (W.Changed);
      end;
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

   function Get_Active_Widget_Handle (W : Stack_Widget) return Widget_Handle is
      Page : constant Widget_Access := Get_Active_Widget (W);
   begin
      if Page = null then
         return Null_Handle;
      end if;
      return Get_Handle (Page.all);
   end Get_Active_Widget_Handle;

   function Get_Page (W : Stack_Widget; Id : Page_Id) return Widget_Access is
   begin
      return W.Pages (Id);
   end Get_Page;

   function Get_Page_Handle
     (W  : Stack_Widget;
      Id : Page_Id) return Widget_Handle
   is
      Page : constant Widget_Access := Get_Page (W, Id);
   begin
      if Page = null then
         return Null_Handle;
      end if;
      return Get_Handle (Page.all);
   end Get_Page_Handle;

   procedure Connect_Changed (W  : in out Stack_Widget;
                              CB : Page_Changed_Callback) is
   begin
      W.Changed.Connect (CB);
   end Connect_Changed;

   function Connect_Changed (W  : in out Stack_Widget;
                             CB : Page_Changed_Callback)
      return Page_Changed_Signals.Connection_Id is
   begin
      return W.Changed.Connect (CB);
   end Connect_Changed;

   procedure Disconnect_Changed
     (W : in out Stack_Widget; Id : Page_Changed_Signals.Connection_Id) is
   begin
      W.Changed.Disconnect (Id);
   end Disconnect_Changed;

   ---------------------------------------------------------------------------
   --  Measurement
   ---------------------------------------------------------------------------

   overriding function Measure_Content (W : Stack_Widget) return Size_2D is
      Style : constant Resolved_Style := Get_Resolved_Part_Style (W, Main_Part);
      Result : Size_2D := (0.0, 0.0);
   begin
      for Child of W.Children loop
         if Child_Participates (Child) then
            declare
               Pref : constant Size_2D := Get_Preferred_Size (Child.all);
            begin
               Result.Width := Pixel_Type'Max (Result.Width, Pref.Width);
               Result.Height := Pixel_Type'Max (Result.Height, Pref.Height);
            end;
         end if;
      end loop;

      return Outer_Size (Result, Style);
   end Measure_Content;

   --  Minimum over the participating pages, taken as a max on both
   --  axes because pages overlap rather than stack. Child_Participates
   --  excludes hidden pages, so in practice this measures the active
   --  page, not the tallest registered one. Content_Min selects each
   --  page's content floor instead of what it demands.
   Stack_Scrolling_Warned : Boolean := False;

   procedure Warn_Unsupported_Stack_Scrolling is
   begin
      if Stack_Scrolling_Warned then
         return;
      end if;
      Stack_Scrolling_Warned := True;
      Adi.Log.Warning
        ("Adi.Widget.Stack: overflow scroll/auto on a stack is not "
         & "supported and leaves content unclickable. Put the overflow "
         & "on the page instead, which also gives each page its own "
         & "scroll offset. overflow:hidden on a stack is fine.");
   end Warn_Unsupported_Stack_Scrolling;

   function Aggregate_Page_Minimums
     (W : Stack_Widget; Content_Min : Boolean) return Size_2D
   is
      Style  : constant Resolved_Style :=
        Get_Resolved_Part_Style (W, Main_Part);
      Result : Size_2D := (0.0, 0.0);
   begin
      for Child of W.Children loop
         if Child_Participates (Child) then
            declare
               --  Same cap-and-floor rule Box applies to its children.
               Min : constant Size_2D :=
                 (if Content_Min then Effective_Min_Size (Child.all)
                  else Get_Min_Size (Child.all));
            begin
               Result.Width := Pixel_Type'Max (Result.Width, Min.Width);
               Result.Height := Pixel_Type'Max (Result.Height, Min.Height);
            end;
         end if;
      end loop;

      --  Like Box: an axis the stack clips in absorbs its pages'
      --  minimum rather than propagating it upward.
      --  Only clipping is sound here; Layout diagnoses the scrolling
      --  case, which it sees on every frame.
      --
      if Style.Overflow_Y /= Overflow_Visible then
         Result.Height := 0.0;
      end if;
      if Style.Overflow_X /= Overflow_Visible then
         Result.Width := 0.0;
      end if;

      return Outer_Size (Result, Style);
   end Aggregate_Page_Minimums;

   overriding function Get_Min_Size (W : Stack_Widget) return Size_2D is
      CSS_Min : constant Size_2D := Get_Min_Size (Widget (W));
      Result  : constant Size_2D :=
        Aggregate_Page_Minimums (W, Content_Min => False);
   begin
      return
        (Width  => Pixel_Type'Max (CSS_Min.Width, Result.Width),
         Height => Pixel_Type'Max (CSS_Min.Height, Result.Height));
   end Get_Min_Size;

   overriding function Get_Content_Min_Size (W : Stack_Widget) return Size_2D
   is
   begin
      return Aggregate_Page_Minimums (W, Content_Min => True);
   end Get_Content_Min_Size;

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
      --  Scrolling a Stack directly is not supported: every page gets the
      --  stack's content box, so a page taller than the viewport keeps
      --  content that is drawn and scrolled yet sits outside the page's
      --  own geometry, where hit testing will not reach it. Put the
      --  overflow on the page instead — it then owns the viewport, and
      --  each page keeps its own scroll offset.
      if Overflow_Is_Scrollable (Style.Overflow_Y)
        or else Overflow_Is_Scrollable (Style.Overflow_X)
      then
         Warn_Unsupported_Stack_Scrolling;
      end if;

      --  Each page gets the stack's content box. A page that needs to
      --  scroll declares its own overflow and becomes its own viewport,
      --  which keeps a separate offset per page.
      for I in 1 .. Child_Count (W) loop
         declare
            Child_H : constant Widget_Handle := Get_Child_Handle (W, I);
            Child   : constant Widget_Access := Widget_Stores.Get (Child_H.Id);
         begin
            if Child /= null
              and then Has_Flag (Child.all, Visible)
              and then Get_Resolved_Part_Style (Child.all, Main_Part).Display /= Display_None
            then
               Set_Geometry (Child.all, Child_Geom);
               Layout_Child (Child.all);
            end if;
         end;
      end loop;
   end Layout;

   ---------------------------------------------------------------------------
   --  Handle methods
   ---------------------------------------------------------------------------

   procedure Add_Page (H : Stack_Handle; Id : Page_Id; Page : Widget_Handle) is
      Ptr      : constant Widget_Access := Widget_Stores.Get (H.Id);
      Page_Ptr : constant Widget_Access := Widget_Stores.Get (Page.Id);
   begin
      if Ptr /= null and then Page_Ptr /= null then
         declare
            SW : Stack_Widget renames Stack_Widget (Ptr.all);
         begin
            Add_Child (SW, Page);
            SW.Pages (Id) := Page_Ptr;

            if not SW.Has_Active then
               SW.Active := Id;
               SW.Has_Active := True;
               Set_Flag (Page_Ptr.all, Visible, True);
            else
               Set_Flag (Page_Ptr.all, Visible, False);
            end if;
         end;
      end if;
   end Add_Page;

   procedure Set_Active (H : Stack_Handle; Id : Page_Id) is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Set_Active (Stack_Widget (Ptr.all), Id);
      end if;
   end Set_Active;

   function Get_Active (H : Stack_Handle) return Page_Id is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Active (Stack_Widget (Ptr.all));
      end if;
      return Page_Id'First;
   end Get_Active;

   function Get_Active_Widget_Handle (H : Stack_Handle) return Widget_Handle is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Active_Widget_Handle (Stack_Widget (Ptr.all));
      end if;
      return Null_Handle;
   end Get_Active_Widget_Handle;

   function Get_Page_Handle
     (H  : Stack_Handle;
      Id : Page_Id) return Widget_Handle
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Get_Page_Handle (Stack_Widget (Ptr.all), Id);
      end if;
      return Null_Handle;
   end Get_Page_Handle;

   procedure Connect_Changed
     (H : Stack_Handle; CB : Page_Changed_Callback)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Connect_Changed (Stack_Widget (Ptr.all), CB);
      end if;
   end Connect_Changed;

   function Connect_Changed
     (H : Stack_Handle; CB : Page_Changed_Callback)
      return Page_Changed_Signals.Connection_Id
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         return Connect_Changed (Stack_Widget (Ptr.all), CB);
      end if;
      return Page_Changed_Signals.No_Connection;
   end Connect_Changed;

   procedure Disconnect_Changed
     (H : Stack_Handle; Id : Page_Changed_Signals.Connection_Id)
   is
      Ptr : constant Widget_Access := Widget_Stores.Get (H.Id);
   begin
      if Ptr /= null then
         Disconnect_Changed (Stack_Widget (Ptr.all), Id);
      end if;
   end Disconnect_Changed;

end Adi.Widget.Stack;
