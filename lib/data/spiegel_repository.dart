// Einschaetzungsspiegel — der einzige regelmaessige Netzaufruf der App
// (DESIGN.md 8). Je Entscheidungspunkt und Handlungsoption ein Zaehlwert,
// ohne Geraetekennung, ohne Sitzungs-ID, ohne Zeitstempel.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Unterhalb dieser Zahl an Einschaetzungen zeigt ein Punkt den
/// "zu wenige"-Block statt der Balken (DESIGN.md 4.10). Die Schwelle legt
/// DESIGN.md nicht fest; fuenf ist die Annahme dieser Umsetzung.
const int kSpiegelSchwelle = 5;

/// Zaehlwerte eines Szenarios: punktIndex -> optionId -> Anzahl.
typedef Zaehlwerte = Map<int, Map<String, int>>;

enum SpiegelStatus {
  laedt,
  da,
  fehler,
  ohneBackend,

  /// Kein Verein eingetragen. Der Spiegel zeigt die Zahlen des eigenen
  /// Teams — ohne Verein gibt es dieses Team nicht.
  ohneVerein,
}

@immutable
class SpiegelDaten {
  const SpiegelDaten({required this.status, this.werte = const {}});

  final SpiegelStatus status;
  final Zaehlwerte werte;

  static const laedt = SpiegelDaten(status: SpiegelStatus.laedt);
  static const ohneVerein = SpiegelDaten(status: SpiegelStatus.ohneVerein);
  static const fehler = SpiegelDaten(status: SpiegelStatus.fehler);
  static const ohneBackend = SpiegelDaten(status: SpiegelStatus.ohneBackend);

  int gesamt(int punkt) =>
      (werte[punkt]?.values.fold<int>(0, (a, b) => a + b)) ?? 0;

  /// Anteile in Prozent, auf 100 aufgerundet verteilt (groesster Rest zuerst),
  /// damit die Summe im Balkendiagramm stimmt.
  Map<String, int> anteile(int punkt, List<String> optionIds) {
    final roh = werte[punkt] ?? const {};
    final summe = optionIds.fold<int>(0, (a, id) => a + (roh[id] ?? 0));
    if (summe == 0) return {for (final id in optionIds) id: 0};

    final exakt = {
      for (final id in optionIds) id: (roh[id] ?? 0) * 100 / summe,
    };
    final ergebnis = {for (final e in exakt.entries) e.key: e.value.floor()};
    var rest = 100 - ergebnis.values.fold<int>(0, (a, b) => a + b);

    final nachRest = optionIds.toList()
      ..sort((a, b) =>
          (exakt[b]! - exakt[b]!.floor()).compareTo(exakt[a]! - exakt[a]!.floor()));
    for (var i = 0; rest > 0 && i < nachRest.length; i++, rest--) {
      ergebnis[nachRest[i]] = ergebnis[nachRest[i]]! + 1;
    }
    return ergebnis;
  }
}

class SpiegelRepository {
  const SpiegelRepository();

  /// Null, solange kein Backend eingerichtet oder erreichbar ist. main.dart
  /// faengt einen gescheiterten Supabase.initialize ab und laeuft weiter —
  /// dann wirft der Zugriff auf die Instanz, und genau das faengt dieser
  /// Getter: Netzfehler duerfen nie blockieren (DESIGN.md 8).
  SupabaseClient? get _client {
    if (!SupabaseConfig.vorhanden) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Beim Waehlen. Fehler werden geschluckt — ein nicht gezaehlter Wert darf
  /// den Durchlauf nie stoeren (DESIGN.md 8).
  Future<void> zaehlen({
    required String? vereinId,
    required String szenarioId,
    required int punktIndex,
    required String optionId,
  }) async {
    final c = _client;
    // Ohne Verein wird nicht gezaehlt: die Zahl gehoert zu einem Team.
    if (c == null || vereinId == null) return;
    try {
      await c.rpc('zaehlwert_erhoehen', params: {
        'p_verein': vereinId,
        'p_szenario': szenarioId,
        'p_punkt': punktIndex,
        'p_option': optionId,
      });
    } catch (e) {
      debugPrint('Zaehlwert nicht uebermittelt: $e');
    }
  }

  /// Beim Oeffnen der Auswertung.
  Future<SpiegelDaten> laden(String szenarioId, {String? vereinId}) async {
    if (vereinId == null) return SpiegelDaten.ohneVerein;
    final c = _client;
    if (c == null) return SpiegelDaten.ohneBackend;
    try {
      final zeilen = await c.rpc(
        'spiegel',
        params: {'p_verein': vereinId, 'p_szenario': szenarioId},
      );
      final werte = <int, Map<String, int>>{};
      for (final z in (zeilen as List).cast<Map<String, dynamic>>()) {
        final punkt = (z['punkt_index'] as num).toInt();
        final option = z['option_id'] as String;
        final anzahl = (z['anzahl'] as num).toInt();
        (werte[punkt] ??= <String, int>{})[option] = anzahl;
      }
      return SpiegelDaten(status: SpiegelStatus.da, werte: werte);
    } catch (e) {
      debugPrint('Spiegel nicht abrufbar: $e');
      return SpiegelDaten.fehler;
    }
  }
}
