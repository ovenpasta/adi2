pragma Wide_Character_Encoding (Brackets);
pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Adi.I18N; use Adi.I18N;

package body I18N_Example_Translations is

   procedure Register_All is
   begin
      Register ("de", "Material Demo", "Material-Demo");
      Register ("de", "Home", "Startseite");
      Register ("de", "Forms", "Formulare");
      Register ("de", "Settings", "Einstellungen");
      Register ("de", "Controls", "Steuerungen");
      Register ("de", "Welcome", "Willkommen");
      Register ("de", "A Material Design 3 demo built with Adi.", "Eine Material Design 3 Demo, erstellt mit Adi.");
      Register ("de", "Get Started", "Loslegen");
      Register ("de", "Form Controls", "Formularsteuerungen");
      Register ("de", "Name", "Name");
      Register ("de", "Country", "Land");
      Register ("de", "United States", "Vereinigte Staaten");
      Register ("de", "United Kingdom", "Vereinigtes Königreich");
      Register ("de", "Germany", "Deutschland");
      Register ("de", "France", "Frankreich");
      Register ("de", "Japan", "Japan");
      Register ("de", "Submit", "Absenden");
      Register ("de", "Cancel", "Abbrechen");
      Register ("de", "Enabled vs Disabled", "Aktiviert vs Deaktiviert");

      Register_Plural_Formula ("fr", 2, "n > 1");

      Register ("fr", "Material Demo", "Démo Material");
      Register ("fr", "Home", "Accueil");
      Register ("fr", "Forms", "Formulaires");
      Register ("fr", "Settings", "Paramètres");
      Register ("fr", "Controls", "Contrôles");
      Register ("fr", "Welcome", "Bienvenue");
      Register ("fr", "A Material Design 3 demo built with Adi.", "Une démo Material Design 3 construite avec Adi.");
      Register ("fr", "Get Started", "Commencer");
      Register ("fr", "Form Controls", "Contrôles de formulaire");
      Register ("fr", "Name", "Nom");
      Register ("fr", "Country", "Pays");
      Register ("fr", "United States", "États-Unis");
      Register ("fr", "United Kingdom", "Royaume-Uni");
      Register ("fr", "Germany", "Allemagne");
      Register ("fr", "France", "France");
      Register ("fr", "Japan", "Japon");
      Register ("fr", "Submit", "Envoyer");
      Register ("fr", "Cancel", "Annuler");
      Register ("fr", "Enabled vs Disabled", "Activé vs Désactivé");
   end Register_All;

end I18N_Example_Translations;
