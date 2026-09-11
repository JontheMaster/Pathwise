// Was Pathwise ausserhalb der App vorschlaegt: im Widget auf dem Homescreen
// und in der taeglichen Erinnerung.
//
// Beides folgt der "Weiter machen"-Karte der Uebersicht: steckt jemand mitten
// in einem Szenario, geht es dort weiter. Sonst steht ein Szenario da, das
// noch offen ist — und nicht den ganzen Tag dasselbe.
//
// DESIGN.md 1 gilt hier genauso: keine Serie, kein Zaehler, keine Frist, kein
// Ausrufezeichen. Wer einen Tag auslaesst, verpasst nichts und hoert davon
// auch nichts.
import 'package:flutter/foundation.dart';

import '../state/durchlauf_state.dart';
import 'szenario_modelle.dart';

/// Um diese Uhrzeit kommt die Erinnerung. Abends, weil die App meist abends
/// benutzt wird (DESIGN.md 3).
const int kErinnerungStunde = 18;

/// So viele Tage im Voraus wird geplant. Jedes Oeffnen der App schiebt das
/// Fenster weiter — wer sie zwei Wochen nicht oeffnet, hoert danach nichts
/// mehr von ihr. Das ist Absicht.
const int kErinnerungTage = 14;

/// Die Adresse, ueber die Widget und Erinnerung ein Szenario oeffnen.
Uri szenarioAdresse(String id) =>
    Uri(scheme: 'pathwise', host: 'szenario', path: '/$id');

/// Die Szenario-Kennung aus einer Adresse — oder null, wenn die Adresse nur
/// die App oeffnen soll.
String? szenarioAusAdresse(String roh) {
  final uri = Uri.tryParse(roh);
  if (uri == null || uri.scheme != 'pathwise' || uri.host != 'szenario') {
    return null;
  }
  final teile = uri.pathSegments.where((t) => t.isNotEmpty);
  return teile.isEmpty ? null : teile.first;
}

/// Was zur Wahl steht, wenn nichts unterbrochen ist: die noch nicht
/// abgeschlossenen Szenarien. Sind alle durch, wieder alle — ein zweiter
/// Durchlauf ist vorgesehen ("Nochmal").
List<PwSzenario> vorschlagsliste(DurchlaufState s) {
  final offen = s.inhalt.szenarien
      .where((sz) => s.status(sz) != SzenarioStatus.abgeschlossen)
      .toList(growable: false);
  return offen.isEmpty ? s.inhalt.szenarien : offen;
}

Map<String, Object?> _eintrag(PwSzenario sz) => {
      'id': sz.id,
      'titel': sz.titel,
      'themenfeld': sz.themenfeld,
      'kurz': sz.kurz,
      'vorgeschichte': sz.vorgeschichte,
      'punkte': sz.punkte.length,
    };

/// Was das Widget braucht, als JSON-faehige Map.
///
/// Welches Szenario gerade dran ist, entscheidet das Widget selbst: es
/// wechselt alle paar Stunden, auch wenn die App die ganze Zeit zu bleibt.
/// Deshalb geht die ganze Liste hinueber, nicht ein einzelnes Szenario.
Map<String, Object?> widgetDaten(DurchlaufState s) {
  final laufend = s.laufendes;
  return {
    'version': 1,
    'theme': s.fortschritt.themeMode.name,
    'laufend': laufend == null
        ? null
        : {..._eintrag(laufend), 'punkt': s.letzterPunkt(laufend) + 1},
    'vorschlaege': [for (final sz in vorschlagsliste(s)) _eintrag(sz)],
  };
}

/// Eine geplante Erinnerung.
@immutable
class PwErinnerung {
  const PwErinnerung({
    required this.id,
    required this.zeitpunkt,
    required this.titel,
    required this.untertitel,
    required this.text,
    required this.ziel,
  });

  /// Eindeutig je Tag. Eine neue Planung ersetzt die alte vollstaendig.
  final String id;
  final DateTime zeitpunkt;
  final String titel;
  final String untertitel;
  final String text;

  /// Die Adresse, die beim Tippen geoeffnet wird.
  final String ziel;

  Map<String, Object?> zuKanal() => {
        'id': id,
        'jahr': zeitpunkt.year,
        'monat': zeitpunkt.month,
        'tag': zeitpunkt.day,
        'stunde': zeitpunkt.hour,
        'minute': zeitpunkt.minute,
        'titel': titel,
        'untertitel': untertitel,
        'text': text,
        'ziel': ziel,
      };
}

String _datum(DateTime d) => '${d.year}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

int _tageSeitEpoche(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1970)).inDays;

/// Die Erinnerungen der naechsten [kErinnerungTage] Tage, jeweils um
/// [kErinnerungStunde] Uhr. Ist es heute schon spaeter, beginnt der Plan
/// morgen.
List<PwErinnerung> erinnerungsplan(DurchlaufState s, DateTime jetzt) {
  final liste = vorschlagsliste(s);
  if (liste.isEmpty) return const [];
  final laufend = s.laufendes;

  var erster = DateTime(jetzt.year, jetzt.month, jetzt.day, kErinnerungStunde);
  if (!erster.isAfter(jetzt)) {
    erster =
        DateTime(jetzt.year, jetzt.month, jetzt.day + 1, kErinnerungStunde);
  }

  return [
    for (var i = 0; i < kErinnerungTage; i++)
      _erinnerung(
        s,
        // Ueber den Tag gezaehlt, nicht ueber 24 Stunden: so bleibt es auch
        // an den Tagen der Zeitumstellung bei 18 Uhr.
        DateTime(erster.year, erster.month, erster.day + i, kErinnerungStunde),
        laufend,
        liste,
      ),
  ];
}

PwErinnerung _erinnerung(
  DurchlaufState s,
  DateTime zeit,
  PwSzenario? laufend,
  List<PwSzenario> liste,
) {
  final id = 'pw-erinnerung-${_datum(zeit)}';

  if (laufend != null) {
    return PwErinnerung(
      id: id,
      zeitpunkt: zeit,
      titel: 'Weiter machen',
      untertitel: laufend.titel,
      text: 'Du warst bei Entscheidungspunkt '
          '${s.letzterPunkt(laufend) + 1} von ${laufend.punkte.length}. '
          'Es geht genau dort weiter.',
      ziel: szenarioAdresse(laufend.id).toString(),
    );
  }

  // Jeden Tag das naechste: aufeinanderfolgende Tage schlagen verschiedene
  // Szenarien vor, sobald mehr als eines offen ist.
  final sz = liste[_tageSeitEpoche(zeit) % liste.length];
  return PwErinnerung(
    id: id,
    zeitpunkt: zeit,
    titel: sz.titel,
    untertitel: sz.themenfeld,
    text: sz.kurz,
    ziel: szenarioAdresse(sz.id).toString(),
  );
}
