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
//   Das Dashboard laeuft nur auf localhost. Ein Web-Build mit einbackenem
//   Schluessel duerfte nirgends hochgeladen werden — die Pruefung unten macht
//   daraus keinen Unfall, sondern einen Abbruch mit Ansage.
//
//   Es wird nicht dauerhaft betrieben. Es laeuft, solange es gestartet ist.
//
// Aufruf:
//   flutter run -d chrome -t lib/admin/main.dart \
//     --dart-define=SUPABASE_SECRET_KEY=sb_secret_...
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

  /// Was schiefsteht, oder null wenn alles passt.
  static AdminHindernis? hindernis(String host) {
    if (!istLokal(host)) return AdminHindernis.nichtLokal;
    if (!schluesselDa) return AdminHindernis.ohneSchluessel;
    if (url.isEmpty) return AdminHindernis.ohneProjekt;
    return null;
  }
}

enum AdminHindernis {
  ohneSchluessel,
  nichtLokal,
  ohneProjekt;

  String get titel => switch (this) {
        ohneSchluessel => 'Kein Schlüssel übergeben',
        nichtLokal => 'Das Dashboard läuft nur lokal',
        ohneProjekt => 'Keine Projekt-URL',
      };

  String get text => switch (this) {
        ohneSchluessel =>
          'Das Dashboard schreibt in die Datenbank und braucht dafür den '
              'geheimen Schlüssel des Supabase-Projekts. Er wird beim Starten '
              'übergeben und steht bewusst nirgends im Code.',
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
        ohneSchluessel || ohneProjekt =>
          'flutter run -d chrome -t lib/admin/main.dart \\\n'
              '  --dart-define=SUPABASE_SECRET_KEY=sb_secret_...',
        nichtLokal => null,
      };
}
