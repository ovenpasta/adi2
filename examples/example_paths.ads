--  Copyright (C) 2026 Aldo Nicolas Bruno
--  SPDX-License-Identifier: Apache-2.0

package Example_Paths is
   --  Change to the examples directory, found from the executable location,
   --  so assets/ and css/ resolve independently of the launch directory.
   --  Warn and keep the current directory if the assets cannot be found.
   procedure Initialize;
end Example_Paths;
