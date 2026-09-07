// Zustand der App — DESIGN.md 8.
//
// Inhalte und Fortschritt werden vor runApp geladen und hier hineingereicht.
// So gibt es keinen Ladezustand auf der Uebersicht, fuer den es auch keinen
// Entwurf gibt (DESIGN.md 11, Punkt 4).
//
// Aufklappzustaende (Einordnung, "Situation nachlesen", Spiegel-Block) leben
// bewusst im jeweiligen Screen: der Prototyp setzt sie bei jeder Navigation
// zurueck, und lokal gehalten passiert das von selbst.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fortschritt_speicher.dart';
import '../data/spiegel_repository.dart';
import '../data/szenario_modelle.dart';

/// Status einer Szenariokarte auf der Uebersicht (PathwiseApp.dc.html Z. 817).
enum SzenarioStatus {
  offen('Noch nicht bearbeitet'),
  angefangen('Angefangen'),
  abgeschlossen('Abgeschlossen');

  const SzenarioStatus(this.label);
  final String label;
}

@immutable
class DurchlaufState {
  const DurchlaufState({
    required this.inhalt,
    required this.fortschritt,
    this.themenfeldFilter = 'Alle',
  });

  final PwInhalt inhalt;
  final Fortschritt fortschritt;
  final String themenfeldFilter;

  List<PwSzenario> get sichtbareSzenarien => themenfeldFilter == 'Alle'
      ? inhalt.szenarien
      : inhalt.szenarien
          .where((s) => s.themenfeld == themenfeldFilter)
          .toList(growable: false);

  SzenarioStatus status(PwSzenario s) {
    if (!fortschritt.begonnen.contains(s.id)) return SzenarioStatus.offen;
    final letzter = s.punkte.length - 1;
    return fortschritt.wahl(s.id, letzter) != null
        ? SzenarioStatus.abgeschlossen
        : SzenarioStatus.angefangen;
  }

  /// Der zuletzt offene Entscheidungspunkt eines Szenarios
  /// (PathwiseApp.dc.html, letzterPunkt()).
  int letzterPunkt(PwSzenario s) {
    for (var p = s.punkte.length - 1; p >= 0; p--) {
      if (fortschritt.wahl(s.id, p) != null) {
        return (p + 1).clamp(0, s.punkte.length - 1);
      }
    }
    return 0;
  }

  /// Das erste begonnene, noch nicht abgeschlossene Szenario — Grundlage der
  /// "Weiter machen"-Karte.
  PwSzenario? get laufendes {
    for (final s in inhalt.szenarien) {
      if (fortschritt.begonnen.contains(s.id) &&
          status(s) != SzenarioStatus.abgeschlossen) {
        return s;
      }
    }
    return null;
  }

  bool get erststartAn => fortschritt.begonnen.isEmpty;

  DurchlaufState copyWith({Fortschritt? fortschritt, String? themenfeldFilter}) =>
      DurchlaufState(
        inhalt: inhalt,
        fortschritt: fortschritt ?? this.fortschritt,
        themenfeldFilter: themenfeldFilter ?? this.themenfeldFilter,
      );
}

class DurchlaufNotifier extends Notifier<DurchlaufState> {
  DurchlaufNotifier(this._start, this._speicher, this._spiegel);

  final DurchlaufState _start;
  final FortschrittSpeicher _speicher;
  final SpiegelRepository _spiegel;

  @override
  DurchlaufState build() => _start;

  void _setzen(Fortschritt f) {
    state = state.copyWith(fortschritt: f);
    _speicher.sichern(f);
  }

  void filterSetzen(String themenfeld) {
    state = state.copyWith(themenfeldFilter: themenfeld);
  }

  /// Merkt, dass die einmalige Abschluss-Geste fuer dieses Szenario gelaufen
  /// ist — sie erscheint danach nie wieder, auch nicht nach "Nochmal".
  void gefeiert(PwSzenario s) {
    if (state.fortschritt.gefeiert.contains(s.id)) return;
    _setzen(state.fortschritt
        .copyWith(gefeiert: {...state.fortschritt.gefeiert, s.id}));
  }

  void erststartGesehen() {
    if (state.fortschritt.erststartGesehen) return;
    _setzen(state.fortschritt.copyWith(erststartGesehen: true));
  }

  void themeSetzen(ThemeMode m) {
    _setzen(state.fortschritt.copyWith(themeMode: m));
  }

  void bewegungSetzen(bool reduziert) {
    _setzen(state.fortschritt.copyWith(bewegungReduziert: reduziert));
  }

  /// Loescht alles, was auf dem Geraet liegt: Entscheidungen, Fortschritt und
  /// die Einstellungen. Danach steht die App wie beim ersten Oeffnen da.
  Future<void> allesLoeschen() async {
    await _speicher.allesLoeschen();
    state = state.copyWith(
      fortschritt: const Fortschritt(),
      themenfeldFilter: 'Alle',
    );
  }

  void begonnen(PwSzenario s) {
    if (state.fortschritt.begonnen.contains(s.id)) return;
    _setzen(state.fortschritt
        .copyWith(begonnen: {...state.fortschritt.begonnen, s.id}));
  }

  /// Eine Option waehlen. Der Zaehlwert geht nebenher ins Netz; scheitert das,
  /// merkt der Durchlauf nichts davon (DESIGN.md 8).
  ///
  /// Gezaehlt wird nur die *erste* Entscheidung je Entscheidungspunkt: sonst
  /// wuerde der Spiegel messen, wie oft jemand seine Antwort aendert oder ein
  /// Szenario wiederholt, statt wie sich das Trainerteam entscheidet.
  void waehlen(PwSzenario s, int punkt, String optionId) {
    final schluessel = Fortschritt.schluessel(s.id, punkt);
    final wahlen = {...state.fortschritt.wahlen}..[schluessel] = optionId;
    final erstmals = !state.fortschritt.gezaehlt.contains(schluessel);

    _setzen(state.fortschritt.copyWith(
      wahlen: wahlen,
      begonnen: {...state.fortschritt.begonnen, s.id},
      gezaehlt: erstmals
          ? {...state.fortschritt.gezaehlt, schluessel}
          : state.fortschritt.gezaehlt,
    ));

    if (erstmals) {
      _spiegel.zaehlen(szenarioId: s.id, punktIndex: punkt, optionId: optionId);
    }
  }

  /// "Antwort ändern" — loescht nur die Wahl an diesem Punkt. Der bereits
  /// gesendete Zaehlwert bleibt stehen; er traegt keinen Bezug zu diesem Geraet.
  void wahlLoeschen(PwSzenario s, int punkt) {
    final wahlen = {...state.fortschritt.wahlen}
      ..remove(Fortschritt.schluessel(s.id, punkt));
    _setzen(state.fortschritt.copyWith(wahlen: wahlen));
  }

  /// "Nochmal" — loescht nur die Wahlen dieses Szenarios (DESIGN.md 8).
  /// `gezaehlt` bleibt absichtlich stehen: der Wiederholungsdurchlauf soll den
  /// Spiegel nicht ein zweites Mal hochzaehlen.
  void nochmal(PwSzenario s) {
    final wahlen = {...state.fortschritt.wahlen};
    for (var p = 0; p < s.punkte.length; p++) {
      wahlen.remove(Fortschritt.schluessel(s.id, p));
    }
    _setzen(state.fortschritt.copyWith(wahlen: wahlen));
  }
}

/// Wird in main() ueberschrieben, sobald Inhalt und Fortschritt geladen sind.
final durchlaufProvider =
    NotifierProvider<DurchlaufNotifier, DurchlaufState>(() {
  throw UnimplementedError('durchlaufProvider muss in main() gesetzt werden.');
});

final spiegelRepositoryProvider =
    Provider<SpiegelRepository>((_) => const SpiegelRepository());
