with Ada.Calendar;
with Adi.Core; use Adi.Core;

package Adi.Event is

   type Event_Kind is (Mouse_Move);
   --, Mouse_Enter, Mouse_Down, Mouse_Up, Mouse_Click,
   --   Key_Press, Key_Release);

   type Event (Kind : Event_Kind) is record
      Timestamp : Ada.Calendar.Time;
      case Kind is
         when Mouse_Move =>
            Mouse_Pos   : Point;
            Mouse_Speed : Point;
      end case;
   end record;

end Adi.Event;
