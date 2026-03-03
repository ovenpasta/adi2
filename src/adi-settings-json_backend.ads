pragma Ada_2022;

package Adi.Settings.JSON_Backend is

   type JSON_Settings_Backend is new Settings_Backend with null record;

   overriding function Load
     (B : JSON_Settings_Backend; Path : String) return Setting_Value;

   overriding procedure Save
     (B    : JSON_Settings_Backend;
      Path : String;
      Data : Setting_Value);

   --  Convenience: create a store with the default JSON backend.
   --  The backend is allocated internally and owned by the store.
   procedure Create_With_JSON_Backend
     (Store : in out Settings_Store;
      Org   : String;
      App   : String);

end Adi.Settings.JSON_Backend;
