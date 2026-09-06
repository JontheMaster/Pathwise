// Pathwise — Einstieg der App.
//
// Inhalt, Fortschritt und Supabase werden vor runApp aufgeloest, damit die
// Uebersicht sofort steht: fuer einen Ladezustand gibt es keinen Entwurf
// (DESIGN.md 11, Punkt 4).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/fortschritt_speicher.dart';
import 'data/spiegel_repository.dart';
import 'data/supabase_config.dart';
import 'data/szenario_repository.dart';
import 'design/pathwise_theme.dart';
import 'screens/uebersicht_screen.dart';
import 'state/durchlauf_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.vorhanden) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.key,
      );
    } catch (e) {
      // Ohne Backend laeuft die App weiter; der Spiegel zeigt dann seinen
      // Empty-State (DESIGN.md 4.10). Netzfehler blockieren nie.
      debugPrint('Supabase nicht erreichbar: $e');
    }
  }

  const speicher = FortschrittSpeicher();
  final inhalt = await const SzenarioRepository().laden();
  final fortschritt = await speicher.laden();

  runApp(
    ProviderScope(
      overrides: [
        durchlaufProvider.overrideWith(
          () => DurchlaufNotifier(
            DurchlaufState(inhalt: inhalt, fortschritt: fortschritt),
            speicher,
            const SpiegelRepository(),
          ),
        ),
      ],
      child: const PathwiseApp(),
    ),
  );
}

class PathwiseApp extends ConsumerWidget {
  const PathwiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modus =
        ref.watch(durchlaufProvider.select((s) => s.fortschritt.themeMode));

    return MaterialApp(
      title: 'Pathwise',
      debugShowCheckedModeBanner: false,
      theme: pwTheme(dark: false),
      darkTheme: pwTheme(dark: true),
      // Dunkel ist der Standard der App, nicht `system` (DESIGN.md 3).
      themeMode: modus,
      home: const UebersichtScreen(),
    );
  }
}
