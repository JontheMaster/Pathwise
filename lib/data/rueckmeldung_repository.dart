// Rueckmeldungs-Sheet S8 — Freitext und freiwillige E-Mail.
//
// DESIGN.md 8 nennt den Zaehlwert als einzigen Netzaufruf; das Sheet verspricht
// aber "Jede Rueckmeldung wird gelesen und bearbeitet." Deshalb geht sie in eine
// reine Insert-Tabelle: einsenden ja, lesen nein (siehe Migration).
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

enum RueckmeldungArt {
  feedback('feedback'),
  szenario('szenario');

  const RueckmeldungArt(this.schluessel);
  final String schluessel;
}

class RueckmeldungRepository {
  const RueckmeldungRepository();

  /// Wirft, wenn das Senden scheitert — S8 zeigt den Fehler dann unter dem
  /// Textfeld und laesst die Eingaben stehen.
  Future<void> senden({
    required RueckmeldungArt art,
    required String text,
    String? email,
  }) async {
    if (!SupabaseConfig.vorhanden) {
      throw StateError('Kein Backend eingerichtet.');
    }
    final sauber = email?.trim();
    await Supabase.instance.client.from('rueckmeldungen').insert({
      'art': art.schluessel,
      'text': text.trim(),
      if (sauber != null && sauber.isNotEmpty) 'email': sauber,
    });
  }
}
