// Zustand des Dashboards.
//
// Bewusst schlicht: vier Listen, die neu geladen werden, wenn sich etwas
// geaendert hat. Kein Zwischenspeicher, der stillschweigend veraltet — hier
// sitzt eine Person, die gerade etwas aendert, und die soll sehen, was
// wirklich in der Datenbank steht.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_modelle.dart';
import 'admin_repository.dart';

/// Fehler bleiben stehen, statt im Hintergrund wiederholt zu werden.
///
/// Riverpod versucht einen gescheiterten Provider von sich aus erneut. Fuer
/// eine wackelige Verbindung ist das richtig, hier nicht: der haeufigste
/// Fehler ist ein falscher Schluessel, und der wird nie von selbst richtig.
/// Ohne diese Zeile haengt das Dashboard auf "Wird geladen …" und schickt im
/// Hintergrund einen 401 nach dem anderen, statt zu sagen, was los ist.
Duration? _nichtWiederholen(int versuche, Object fehler) => null;

/// Wird in main() ueberschrieben, sobald Supabase steht.
final adminRepositoryProvider = Provider<AdminRepository>((_) {
  throw UnimplementedError('adminRepositoryProvider muss gesetzt werden.');
});

final szenarienProvider = FutureProvider<List<AdminSzenario>>(
  (ref) => ref.watch(adminRepositoryProvider).szenarien(),
  retry: _nichtWiederholen,
);

final vereineProvider = FutureProvider<List<AdminVerein>>(
  (ref) => ref.watch(adminRepositoryProvider).vereine(),
  retry: _nichtWiederholen,
);

final beratungBundesweitProvider = FutureProvider<List<AdminBeratung>>(
  (ref) => ref.watch(adminRepositoryProvider).beratungBundesweit(),
  retry: _nichtWiederholen,
);

final rueckmeldungenProvider = FutureProvider<List<AdminRueckmeldung>>(
  (ref) => ref.watch(adminRepositoryProvider).rueckmeldungen(),
  retry: _nichtWiederholen,
);

final zahlenProvider = FutureProvider<List<AdminZahl>>(
  (ref) => ref.watch(adminRepositoryProvider).zahlen(),
  retry: _nichtWiederholen,
);

/// Nach jeder Aenderung: alles neu holen, was davon beruehrt sein kann.
extension AdminAuffrischen on WidgetRef {
  void szenarienNeu() => invalidate(szenarienProvider);

  void vereineNeu() {
    invalidate(vereineProvider);
    invalidate(beratungBundesweitProvider);
  }

  void rueckmeldungenNeu() => invalidate(rueckmeldungenProvider);

  void zahlenNeu() => invalidate(zahlenProvider);
}
