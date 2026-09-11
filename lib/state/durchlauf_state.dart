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
import '../data/szenario_repository.dart';
import '../data/verein_modelle.dart';
import '../data/verein_repository.dart';

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

  // Die Vereinsangaben kommen aus der Datenbank, sobald ein Code eingetragen
  // ist. Ohne Code bleibt die App vollstaendig bedienbar (DESIGN.md 8), zeigt
  // aber *keine* Ansprechpersonen:
  //
  // Im Buendel liegen die Angaben des Pilotvereins. Sie als Vorgabe
  // anzuzeigen hiesse, jemandem aus einem anderen Verein eine fremde
  // Kinderschutz-Adresse zu nennen — jemand koennte einen Verdacht dorthin
  // schreiben. Lieber keine Ansprechperson als die falsche.
  //
  // Die externen Stellen sind davon ausgenommen: Hilfetelefon und Nummer
  // gegen Kummer gelten bundesweit und sind ohne Verein richtig.
  PwVerein? get verein => fortschritt.verein;
  String? get vereinId => fortschritt.verein?.id;
  String? get vereinName => fortschritt.verein?.name;
  List<PwPerson> get personen => fortschritt.verein?.personen ?? const [];
  List<PwBeratung> get beratung =>
      fortschritt.verein?.beratung ?? inhalt.beratung;

  /// Beim Erststart wird einmal nach dem Vereinscode gefragt — ueberspringbar.
  bool get vereinFragen =>
      fortschritt.verein == null && !fortschritt.vereinGefragt;

  DurchlaufState copyWith({
    PwInhalt? inhalt,
    Fortschritt? fortschritt,
    String? themenfeldFilter,
  }) =>
      DurchlaufState(
        inhalt: inhalt ?? this.inhalt,
        fortschritt: fortschritt ?? this.fortschritt,
        themenfeldFilter: themenfeldFilter ?? this.themenfeldFilter,
      );
}

class DurchlaufNotifier extends Notifier<DurchlaufState> {
  DurchlaufNotifier(
    this._start,
    this._speicher,
    this._spiegel, [
    this._szenarien = const SzenarioRepository(),
  ]);

  final DurchlaufState _start;
  final FortschrittSpeicher _speicher;
  final SpiegelRepository _spiegel;
  final SzenarioRepository _szenarien;

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

  /// Traegt einen nachgeschlagenen Verein ein.
  void vereinSetzen(PwVerein v) {
    _setzen(state.fortschritt.copyWith(verein: v, vereinGefragt: true));
  }

  /// Entfernt die Vereinszuordnung. Der Fortschritt bleibt; nur die Angaben
  /// und der Spiegel fallen auf ihre Vorgabe zurueck.
  void vereinEntfernen() {
    _setzen(state.fortschritt.copyWith(vereinEntfernen: true));
  }

  /// Merkt, dass beim Erststart gefragt wurde — auch wenn uebersprungen.
  void vereinsfrageErledigt() {
    if (state.fortschritt.vereinGefragt) return;
    _setzen(state.fortschritt.copyWith(vereinGefragt: true));
  }

  /// Holt die Angaben zum eingetragenen Code neu. Laeuft im Hintergrund beim
  /// Start; scheitert es, bleiben die zwischengespeicherten stehen.
  Future<void> vereinAuffrischen() async {
    final code = state.fortschritt.verein?.code;
    if (code == null) return;

    final antwort = await const VereinRepository().nachschlagen(code);
    switch (antwort.ergebnis) {
      case PwCodeErgebnis.gefunden:
        _setzen(state.fortschritt.copyWith(verein: antwort.verein));
      case PwCodeErgebnis.nichtErreichbar:
        break; // Zwischenspeicher behalten
      case PwCodeErgebnis.unbekannt:
        // Der Verein wurde abgeschaltet oder der Code geaendert. Die Angaben
        // stehen zu lassen waere schlechter, als auf das Buendel
        // zurueckzufallen — sie koennten veraltete Ansprechpersonen zeigen.
        _setzen(state.fortschritt.copyWith(vereinEntfernen: true));
    }
  }

  void themeSetzen(ThemeMode m) {
    _setzen(state.fortschritt.copyWith(themeMode: m));
  }

  void bewegungSetzen(PwBewegung b) {
    _setzen(state.fortschritt.copyWith(bewegung: b));
  }

  /// Die taegliche Erinnerung ein- oder ausschalten. Die Erlaubnis des
  /// Systems holt die Einstellungsseite vorher ein; geplant wird in
  /// screens/einsprung.dart, sobald sich der Zustand hier aendert.
  void erinnerungSetzen(bool an) {
    if (state.fortschritt.erinnerung == an) return;
    _setzen(state.fortschritt.copyWith(erinnerung: an));
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
    _setzen(state.fortschritt.copyWith(
      begonnen: {...state.fortschritt.begonnen, s.id},
      // Die Fassung anheften: ab hier gilt sie fuer dieses Geraet, bis
      // "Nochmal" gedrueckt wird.
      fassungen: s.ausDatenbank
          ? {...state.fortschritt.fassungen, s.id: s.fassung}
          : state.fortschritt.fassungen,
    ));
  }

  /// Holt die Szenarien aus der Datenbank und tauscht sie gegen die aus dem
  /// Buendel. Laeuft beim Start nebenher; scheitert es, bleibt das Buendel.
  ///
  /// Angefangene Szenarien behalten ihre angeheftete Fassung — auch wenn
  /// inzwischen eine neuere veroeffentlicht wurde.
  Future<void> szenarienAuffrischen() async {
    final aktuell = await _szenarien.ausDatenbank();
    if (aktuell == null) return;

    final angeheftet = state.fortschritt.fassungen;
    final fertig = <PwSzenario>[];
    for (final sz in aktuell) {
      final wunsch = angeheftet[sz.id];
      if (wunsch == null || wunsch == sz.fassung) {
        fertig.add(sz);
        continue;
      }
      // Ueberarbeitet, waehrend jemand mittendrin steckt: die alte Fassung
      // holen. Ist sie nicht mehr abrufbar, gilt die aktuelle — besser ein
      // veraenderter Text als ein verschwundenes Szenario.
      fertig.add(await _szenarien.fassung(sz.id, wunsch) ?? sz);
    }

    state = state.copyWith(inhalt: state.inhalt.mitSzenarien(fertig));
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
      _spiegel.zaehlen(
        vereinId: state.vereinId,
        szenarioId: s.id,
        signatur: s.signatur,
        punktIndex: punkt,
        optionId: optionId,
      );
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
  ///
  /// Die angeheftete Fassung faellt dabei weg. Der laufende Wiederholungs-
  /// durchlauf spielt noch die geladene Fassung zu Ende — mitten im Szenario
  /// den Text auszutauschen waere genau das, was das Anheften verhindern soll.
  /// Beim naechsten Start greift dann die aktuelle Fassung, und [begonnen]
  /// heftet sie neu an.
  void nochmal(PwSzenario s) {
    final wahlen = {...state.fortschritt.wahlen};
    for (var p = 0; p < s.punkte.length; p++) {
      wahlen.remove(Fortschritt.schluessel(s.id, p));
    }
    final fassungen = {...state.fortschritt.fassungen}..remove(s.id);
    _setzen(state.fortschritt.copyWith(wahlen: wahlen, fassungen: fassungen));
  }
}

/// Wird in main() ueberschrieben, sobald Inhalt und Fortschritt geladen sind.
final durchlaufProvider =
    NotifierProvider<DurchlaufNotifier, DurchlaufState>(() {
  throw UnimplementedError('durchlaufProvider muss in main() gesetzt werden.');
});

final spiegelRepositoryProvider =
    Provider<SpiegelRepository>((_) => const SpiegelRepository());
