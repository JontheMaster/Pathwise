// Zugang des Dashboards — und die Grenzen, die es sich selbst setzt.
//
// Das Dashboard schreibt in die Datenbank. Dafuer reicht der publishable key
// der App nicht: der darf nur zaehlen, den Spiegel lesen und eine Rueckmeldung
// einsenden. Das Dashboard braucht den geheimen Schluessel, und der hebelt
// jede RLS-Regel aus.
//
// Daraus folgt alles Weitere:
//
//   Der Schluessel steht nirgends im Repo. Er wird beim Starten uebergeben und
//   landet nur im Speicher des Rechners, auf dem gestartet wurde.
//
//   Das Dashboard laeuft als Desktop-Programm, nicht im Browser. Supabase weist
//   geheime Schluessel (sb_secret_...) mit 401 ab, sobald die Anfrage aus
//   einem Browser kommt — erkannt am User-Agent. Im Browser endet deshalb jede
//   Abfrage mit "Invalid API key", auch mit dem richtigen Schluessel.
//
//   Laeuft es doch im Web, dann nur auf localhost. Ein Web-Build mit
//   einbackenem Schluessel duerfte nirgends hochgeladen werden — die Pruefung
//   unten macht daraus keinen Unfall, sondern einen Abbruch mit Ansage.
//
//   Es wird nicht dauerhaft betrieben. Es laeuft, solange es gestartet ist.
//
// Aufruf (unter Windows -d windows):
//   flutter run -d macos -t lib/admin/main.dart \
//     --dart-define=SUPABASE_SECRET_KEY=sb_secret_...
import 'package:flutter/foundation.dart';

import '../data/supabase_config.dart';

abstract final class AdminConfig {
  /// Dieselbe Projekt-URL wie die App.
  static const url = SupabaseConfig.url;

  /// Der geheime Schluessel. Ohne ihn startet das Dashboard nicht.
  ///
  /// Bewusst ohne Vorgabewert: ein versehentlich eingebackener Schluessel waere
  /// genau der Fehler, den diese Datei verhindern soll.
  static const secretKey = String.fromEnvironment('SUPABASE_SECRET_KEY');

  static bool get schluesselDa => secretKey.isNotEmpty;

  /// Nur auf dem eigenen Rechner. [host] ist im Web `Uri.base.host`.
  static bool istLokal(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1' || host == '';

  /// Einer der neuen geheimen Schluessel, die Supabase im Browser abweist.
  /// Der alte service_role-Schluessel (ein JWT, "eyJ...") ist davon nicht
  /// betroffen.
  static bool istGeheimerSchluessel(String schluessel) =>
      schluessel.startsWith('sb_secret_');

  /// Was schiefsteht, oder null wenn alles passt.
  ///
  /// [imBrowser] und [schluessel] sind nur fuer Tests ueberschreibbar.
  static AdminHindernis? hindernis(
    String host, {
    bool imBrowser = kIsWeb,
    String schluessel = secretKey,
  }) {
    if (!istLokal(host)) return AdminHindernis.nichtLokal;
    if (schluessel.isEmpty) return AdminHindernis.ohneSchluessel;
    if (imBrowser && istGeheimerSchluessel(schluessel)) {
      return AdminHindernis.imBrowser;
    }
    if (url.isEmpty) return AdminHindernis.ohneProjekt;
    return null;
  }

  /// Das Geraet fuer den Startbefehl: das System, auf dem gerade gearbeitet
  /// wird. Im Web meldet Flutter hier das System des Browsers.
  static String get desktopGeraet => switch (defaultTargetPlatform) {
        TargetPlatform.windows => 'windows',
        TargetPlatform.linux => 'linux',
        _ => 'macos',
      };
}

enum AdminHindernis {
  ohneSchluessel,
  imBrowser,
  nichtLokal,
  ohneProjekt;

  String get titel => switch (this) {
        ohneSchluessel => 'Kein Schlüssel übergeben',
        imBrowser => 'Im Browser geht der Schlüssel nicht',
        nichtLokal => 'Das Dashboard läuft nur lokal',
        ohneProjekt => 'Keine Projekt-URL',
      };

  String get text => switch (this) {
        ohneSchluessel =>
          'Das Dashboard schreibt in die Datenbank und braucht dafür den '
              'geheimen Schlüssel des Supabase-Projekts. Er wird beim Starten '
              'übergeben und steht bewusst nirgends im Code.',
        imBrowser =>
          'Supabase weist geheime Schlüssel ab, sobald eine Anfrage aus einem '
              'Browser kommt — jede Abfrage endete hier mit „Invalid API key", '
              'auch mit dem richtigen Schlüssel. Starte die Verwaltung deshalb '
              'als Programm auf deinem Rechner. Der Schlüssel bleibt dabei '
              'genauso lokal.',
        nichtLokal =>
          'Diese Seite wurde nicht von localhost geladen. Ein Web-Build mit '
              'eingebackenem Schlüssel gehört auf keinen Server — wer die '
              'Seite erreicht, könnte alles ändern und alles löschen. Starte '
              'das Dashboard stattdessen auf deinem Rechner.',
        ohneProjekt =>
          'Es ist keine Supabase-URL gesetzt. Ohne sie gibt es nichts zu '
              'bearbeiten.',
      };

  /// Der Befehl, der es richtig macht — oder null, wenn es keinen gibt.
  String? get befehl => switch (this) {
        ohneSchluessel || imBrowser || ohneProjekt =>
          'flutter run -d ${AdminConfig.desktopGeraet} -t lib/admin/main.dart \\\n'
              '  --dart-define=SUPABASE_SECRET_KEY=sb_secret_...',
        nichtLokal => null,
      };
}
