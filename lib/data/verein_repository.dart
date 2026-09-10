// Holt die Vereinsangaben zu einem Code.
//
// Der Abruf laeuft ueber eine Funktion, nicht ueber die Tabellen: ohne Code
// laesst sich weder eine Vereinsliste noch eine Sammlung von Kontaktdaten
// abziehen (siehe supabase/migrations/0002_vereine.sql).
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'verein_modelle.dart';

/// Was beim Nachschlagen eines Codes herauskommt.
enum PwCodeErgebnis {
  gefunden,

  /// Den Code gibt es nicht — oder der Verein ist nicht mehr aktiv.
  unbekannt,

  /// Kein Netz, kein Backend. Kein Grund, einen Code zu verwerfen.
  nichtErreichbar,
}

@immutable
class PwVereinAntwort {
  const PwVereinAntwort(this.ergebnis, [this.verein]);

  final PwCodeErgebnis ergebnis;
  final PwVerein? verein;
}

class VereinRepository {
  const VereinRepository();

  SupabaseClient? get _client {
    if (!SupabaseConfig.vorhanden) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Schlaegt [code] nach. Gross- und Kleinschreibung sowie Leerzeichen am
  /// Rand spielen keine Rolle — das erledigt die Datenbank.
  Future<PwVereinAntwort> nachschlagen(String code) async {
    final sauber = code.trim();
    if (sauber.isEmpty) {
      return const PwVereinAntwort(PwCodeErgebnis.unbekannt);
    }

    final c = _client;
    if (c == null) {
      return const PwVereinAntwort(PwCodeErgebnis.nichtErreichbar);
    }

    try {
      final antwort = await c.rpc('vereinsangaben', params: {'p_code': sauber});
      if (antwort == null) {
        return const PwVereinAntwort(PwCodeErgebnis.unbekannt);
      }
      return PwVereinAntwort(
        PwCodeErgebnis.gefunden,
        PwVerein.ausJson(antwort as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('Vereinsangaben nicht abrufbar: $e');
      return const PwVereinAntwort(PwCodeErgebnis.nichtErreichbar);
    }
  }
}
