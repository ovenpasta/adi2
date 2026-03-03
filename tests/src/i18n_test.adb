pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.I18N; use Adi.I18N;
with Adi.Log;

procedure I18N_Test is

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Assert (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Passed := Passed + 1;
      else
         Failed := Failed + 1;
         Adi.Log.Error ("FAIL: " & Msg);
      end if;
   end Assert;

begin

   ---------------------------------------------------------------------------
   --  Empty catalog passthrough
   ---------------------------------------------------------------------------

   Clear;
   Set_Language ("en");
   Assert (T ("Hello") = "Hello",
           "empty catalog returns msgid");

   ---------------------------------------------------------------------------
   --  Simple translation
   ---------------------------------------------------------------------------

   Clear;
   Register ("fr", "Welcome", "Bienvenue");
   Register ("fr", "Cancel", "Annuler");
   Set_Language ("fr");
   Assert (T ("Welcome") = "Bienvenue",
           "simple translation fr/Welcome");
   Assert (T ("Cancel") = "Annuler",
           "simple translation fr/Cancel");
   Assert (T ("Unknown") = "Unknown",
           "missing key returns msgid");

   ---------------------------------------------------------------------------
   --  Non-reactive model: Set_Language after T() does not change old results
   ---------------------------------------------------------------------------

   Clear;
   Register ("fr", "Welcome", "Bienvenue");
   Register ("de", "Welcome", "Willkommen");
   Set_Language ("fr");

   declare
      Snap : constant String := T ("Welcome");
   begin
      Assert (Snap = "Bienvenue",
              "snapshot is Bienvenue before language change");
      Set_Language ("de");
      --  Snap is a plain String, not a live binding — must remain unchanged
      Assert (Snap = "Bienvenue",
              "snapshot still Bienvenue after Set_Language(de)");
      Assert (T ("Welcome") = "Willkommen",
              "new T() call returns Willkommen");
   end;

   ---------------------------------------------------------------------------
   --  Locale canonicalization
   ---------------------------------------------------------------------------

   Clear;
   Register ("pt_BR", "Hello", "Olá");
   Set_Language ("pt_BR");
   Assert (T ("Hello") = "Olá", "exact pt_BR");

   Set_Language ("pt-BR");
   Assert (T ("Hello") = "Olá", "pt-BR normalized to pt_br");

   Set_Language ("PT-br");
   Assert (T ("Hello") = "Olá", "PT-br case insensitive");

   Set_Language ("pt_br");
   Assert (T ("Hello") = "Olá", "pt_br lowercase");

   Set_Language ("PT_BR");
   Assert (T ("Hello") = "Olá", "PT_BR uppercase");

   --  Register with different case
   Clear;
   Register ("de-AT", "Hello", "Grüß Gott");
   Set_Language ("de_at");
   Assert (T ("Hello") = "Grüß Gott", "de_at lookup");

   Set_Language ("DE-AT");
   Assert (T ("Hello") = "Grüß Gott", "DE-AT lookup");

   ---------------------------------------------------------------------------
   --  Locale fallback chain
   ---------------------------------------------------------------------------

   Clear;
   Register ("pt_BR", "Specific", "Específico BR");
   Register ("pt", "Specific", "Específico");
   Register ("pt", "General", "Geral");
   Register ("pt_BR", "Both", "Ambos BR");
   Register ("pt", "Both", "Ambos");

   Set_Language ("pt_BR");
   Assert (T ("Specific") = "Específico BR",
           "pt_BR gets pt_BR-specific value");
   Assert (T ("General") = "Geral",
           "pt_BR falls back to pt for General");
   Assert (T ("Both") = "Ambos BR",
           "pt_BR prefers pt_BR over pt");
   Assert (T ("Missing") = "Missing",
           "pt_BR returns msgid for missing key");

   --  Fallback does not cross languages
   Clear;
   Register ("fr", "Hello", "Bonjour");
   Set_Language ("fr_CA");
   Assert (T ("Hello") = "Bonjour",
           "fr_CA falls back to fr");
   Set_Language ("de");
   Assert (T ("Hello") = "Hello",
           "de does not fall back to fr");

   ---------------------------------------------------------------------------
   --  Context disambiguation
   ---------------------------------------------------------------------------

   Clear;
   Register ("fr", "Open", "Ouvrir", Context => "menu");
   Register ("fr", "Open", "Ouvert", Context => "adjective");
   Set_Language ("fr");

   Assert (Translate ("menu", "Open") = "Ouvrir",
           "context menu => Ouvrir");
   Assert (Translate ("adjective", "Open") = "Ouvert",
           "context adjective => Ouvert");
   Assert (T ("Open") = "Open",
           "no context => passthrough (not matched)");

   ---------------------------------------------------------------------------
   --  Plural formula evaluation
   ---------------------------------------------------------------------------

   Clear;
   Register_Plural_Formula ("fr", 2, "n > 1");
   Register_Plural ("fr", "file",
     [0 => To_Unbounded_String ("fichier"),
      1 => To_Unbounded_String ("fichiers")]);
   Set_Language ("fr");

   --  French: 0 is singular, 1 is singular, 2+ is plural
   Assert (Tn ("file", "files", 0) = "fichier",
           "fr plural n=0 => singular");
   Assert (Tn ("file", "files", 1) = "fichier",
           "fr plural n=1 => singular");
   Assert (Tn ("file", "files", 5) = "fichiers",
           "fr plural n=5 => plural");

   --  English default formula fallback (no registered forms)
   Set_Language ("en");
   Assert (Tn ("file", "files", 1) = "file",
           "en plural n=1 => msgid singular");
   Assert (Tn ("file", "files", 5) = "files",
           "en plural n=5 => msgid_plural");

   ---------------------------------------------------------------------------
   --  Contextual plural fallback returns plain msgid, not composite key
   ---------------------------------------------------------------------------

   Clear;
   Set_Language ("en");
   --  No translations registered — fallback should return plain msgid
   Assert (Translate_Plural ("ctx", "item", "items", 1) = "item",
           "contextual plural fallback n=1 => plain msgid");
   Assert (Translate_Plural ("ctx", "item", "items", 5) = "items",
           "contextual plural fallback n=5 => msgid_plural");

   ---------------------------------------------------------------------------
   --  Explicit-language simple translation
   ---------------------------------------------------------------------------

   Clear;
   Register ("fr", "Hello", "Bonjour");
   Register ("de", "Hello", "Hallo");
   Set_Language ("en");

   Assert (Translate_Language ("fr", "Hello") = "Bonjour",
           "explicit fr => Bonjour");
   Assert (Translate_Language ("de", "Hello") = "Hallo",
           "explicit de => Hallo");
   Assert (Translate_Language ("es", "Hello") = "Hello",
           "explicit es missing => passthrough");

   ---------------------------------------------------------------------------
   --  Explicit-language does not affect global state
   ---------------------------------------------------------------------------

   Clear;
   Register ("fr", "Hello", "Bonjour");
   Register ("de", "Hello", "Hallo");
   Set_Language ("fr");

   Assert (Translate_Language ("de", "Hello") = "Hallo",
           "explicit de while global is fr");
   Assert (T ("Hello") = "Bonjour",
           "global T still resolves fr after explicit de call");
   Assert (Get_Language = "fr",
           "Get_Language still fr after explicit de call");

   ---------------------------------------------------------------------------
   --  Explicit-language with context
   ---------------------------------------------------------------------------

   Clear;
   Register ("fr", "Open", "Ouvrir", Context => "menu");
   Register ("fr", "Open", "Ouvert", Context => "adjective");
   Register ("de", "Open", "Öffnen", Context => "menu");

   Assert (Translate_Language ("fr", "menu", "Open") = "Ouvrir",
           "explicit fr context menu => Ouvrir");
   Assert (Translate_Language ("fr", "adjective", "Open") = "Ouvert",
           "explicit fr context adjective => Ouvert");
   Assert (Translate_Language ("de", "menu", "Open") = "Öffnen",
           "explicit de context menu => Öffnen");
   Assert (Translate_Language ("de", "adjective", "Open") = "Open",
           "explicit de context adjective missing => passthrough");

   ---------------------------------------------------------------------------
   --  Explicit-language fallback (region to base)
   ---------------------------------------------------------------------------

   Clear;
   Register ("pt", "General", "Geral");
   Register ("pt_BR", "Specific", "Específico BR");

   Assert (Translate_Language ("pt_BR", "General") = "Geral",
           "explicit pt_BR falls back to pt");
   Assert (Translate_Language ("pt_BR", "Specific") = "Específico BR",
           "explicit pt_BR exact match");
   Assert (Translate_Language ("pt", "Specific") = "Specific",
           "explicit pt has no pt_BR entry => passthrough");

   ---------------------------------------------------------------------------
   --  Explicit-language plural
   ---------------------------------------------------------------------------

   Clear;
   Register_Plural_Formula ("fr", 2, "n > 1");
   Register_Plural ("fr", "file",
     [0 => To_Unbounded_String ("fichier"),
      1 => To_Unbounded_String ("fichiers")]);

   Assert (Translate_Plural_Language ("fr", "file", "files", 1) = "fichier",
           "explicit fr plural n=1 => singular");
   Assert (Translate_Plural_Language ("fr", "file", "files", 5) = "fichiers",
           "explicit fr plural n=5 => plural");
   Assert (Translate_Plural_Language ("en", "file", "files", 1) = "file",
           "explicit en plural fallback n=1 => msgid");
   Assert (Translate_Plural_Language ("en", "file", "files", 5) = "files",
           "explicit en plural fallback n=5 => msgid_plural");

   ---------------------------------------------------------------------------
   --  Explicit-language contextual plural fallback returns plain msgid
   ---------------------------------------------------------------------------

   Clear;
   Assert (Translate_Plural_Language ("en", "ctx", "item", "items", 1) =
           "item",
           "explicit contextual plural fallback n=1 => plain msgid");
   Assert (Translate_Plural_Language ("en", "ctx", "item", "items", 5) =
           "items",
           "explicit contextual plural fallback n=5 => msgid_plural");

   ---------------------------------------------------------------------------
   --  Summary
   ---------------------------------------------------------------------------

   Adi.Log.Info ("I18N_Test:" & Passed'Image & " passed," &
                 Failed'Image & " failed");

   if Failed > 0 then
      raise Constraint_Error with "I18N_Test:" & Failed'Image & " tests failed";
   end if;

end I18N_Test;
