// Zugang zum Supabase-Projekt "Pathwise App".
//
// Der publishable key ist dafuer gemacht, im Client zu stehen — er gibt fuer
// sich genommen keine Rechte. Was moeglich ist, entscheidet allein RLS
// (siehe supabase/migrations/0001_pathwise.sql): zaehlen, den Spiegel lesen,
// eine Rueckmeldung einsenden. Mehr nicht.
//
// Beide Werte lassen sich beim Bauen ueberschreiben:
//   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
//
// Sind sie leer, laeuft die App vollstaendig ohne Backend: der
// Einschaetzungsspiegel zeigt dann seinen Empty-State (DESIGN.md 4.10) und die
// Rueckmeldung meldet einen Fehler. Nichts davon blockiert (DESIGN.md 8).
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ggxeegseqqacwsupeaus.supabase.co',
  );

  static const key = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_2kKh3E6s3y7qCg7IEfLe7Q_0J0MRJvk',
  );

  static bool get vorhanden => url.isNotEmpty && key.isNotEmpty;
}
