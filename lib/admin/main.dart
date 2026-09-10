// Pathwise — Verwaltung. Ein eigener Einstieg, nicht Teil der App.
//
// Die App und dieses Dashboard teilen sich Projekt und Gestaltung, aber nicht
// den Einstiegspunkt: was hier steht, landet nie in einem App-Build. Der
// Compiler faengt bei lib/main.dart an und kommt hier nie vorbei.
//
// Starten:
//   flutter run -d chrome -t lib/admin/main.dart \
//     --dart-define=SUPABASE_SECRET_KEY=sb_secret_...
//
// Der Schluessel steht nirgends im Repo (siehe admin_config.dart). Ohne ihn
// zeigt das Dashboard eine Sperrseite mit genau diesem Befehl.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_app.dart';
import 'admin_config.dart';
import 'admin_repository.dart';
import 'admin_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uri.base ist im Web die Adresse des Tabs. Auf anderen Plattformen ist der
  // Host leer — dort gibt es keinen Server, von dem etwas geladen wurde, und
  // die Pruefung greift ins Leere. Deshalb gilt der leere Host als lokal.
  final hindernis = AdminConfig.hindernis(Uri.base.host);
  if (hindernis != null) {
    runApp(AdminApp(hindernis: hindernis));
    return;
  }

  try {
    await Supabase.initialize(
      url: AdminConfig.url,
      // Der Name des Parameters sagt "publishable", die Bibliothek setzt den
      // Wert aber schlicht als apikey-Kopfzeile — hier geht der geheime
      // Schluessel hinein. Er geht an RLS vorbei; genau deshalb laeuft das
      // hier nur lokal und nur, solange es gestartet ist.
      publishableKey: AdminConfig.secretKey,
    );
  } catch (e) {
    debugPrint('Supabase nicht erreichbar: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(
          SupabaseAdminRepository(Supabase.instance.client),
        ),
      ],
      child: const AdminApp(),
    ),
  );
}
