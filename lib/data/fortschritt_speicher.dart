// Lokale Persistenz — DESIGN.md 8: Wahlen, begonnene Szenarien, Erststart und
// Theme-Wunsch bleiben auf dem Geraet. Kein Konto, keine Cloud-Sicherung, kein
// Analytics. Im Web landet das in localStorage.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'verein_modelle.dart';

/// Wie viel Bewegung die App zeigt.
///
/// Eine Achse mit drei Stufen statt mehrerer Schalter: mehr Bewegung heisst
/// immer auch alles darunter.
enum PwBewegung {
  /// Alles sofort im Endzustand, keine Animation.
  reduziert('reduziert'),

  /// Die Bewegungen aus DESIGN.md 5 — die Vorgabe.
  normal('normal'),

  /// Zusaetzlich die Gesten, die nichts erklaeren, sondern schmuecken.
  /// Bewusst abschaltbar und bewusst nicht die Vorgabe: DESIGN.md 1 schliesst
  /// Feier- und Belohnungsanimationen aus.
  verspielt('verspielt');

  const PwBewegung(this.schluessel);
  final String schluessel;

  static PwBewegung vonSchluessel(String? s) => values.firstWhere(
        (e) => e.schluessel == s,
        orElse: () => PwBewegung.normal,
      );

  bool get istReduziert => this == PwBewegung.reduziert;
  bool get zeigtExtras => this == PwBewegung.verspielt;
}

@immutable
class Fortschritt {
  const Fortschritt({
    this.wahlen = const {},
    this.begonnen = const {},
    this.gezaehlt = const {},
    this.gefeiert = const {},
    this.erststartGesehen = false,
    this.themeMode = ThemeMode.dark,
    this.bewegung = PwBewegung.normal,
    this.verein,
    this.vereinGefragt = false,
    this.fassungen = const {},
    this.erinnerung = false,
  });

  /// "szenarioId:punktIndex" -> "a" | "b" | "c"
  final Map<String, String> wahlen;
  final Set<String> begonnen;

  /// Entscheidungspunkte, deren Zaehlwert bereits gesendet wurde.
  ///
  /// Der Einschaetzungsspiegel soll zeigen, wie sich Trainerinnen und Trainer
  /// entschieden haben — nicht, wie oft jemand seine Antwort geaendert oder ein
  /// Szenario wiederholt hat. Gezaehlt wird deshalb nur die erste Entscheidung
  /// je Entscheidungspunkt und Geraet. Ueberliegt bewusst "Antwort ändern" und
  /// "Nochmal".
  final Set<String> gezaehlt;

  /// Szenarien, deren einmalige Abschluss-Geste schon gelaufen ist.
  final Set<String> gefeiert;

  final bool erststartGesehen;

  /// Dunkel ist der Standard der App, nicht `system` (DESIGN.md 3).
  final ThemeMode themeMode;

  /// Wie viel Bewegung die App zeigt. Die Systemeinstellung "Bewegung
  /// reduzieren" gilt unabhaengig davon weiter (DESIGN.md 5).
  final PwBewegung bewegung;

  /// Der zugeordnete Verein, zuletzt abgerufen. Liegt lokal, damit die
  /// Angaben auch ohne Netz stehen.
  final PwVerein? verein;

  /// Ob beim Erststart schon nach dem Vereinscode gefragt wurde. Wer
  /// „Später" gewaehlt hat, soll nicht bei jedem Start neu gefragt werden.
  final bool vereinGefragt;

  /// szenarioId -> Fassung, in der dieses Geraet das Szenario angefangen hat.
  ///
  /// Wird ein Szenario ueberarbeitet, waehrend jemand mittendrin steckt,
  /// wechselte sonst zwischen zwei Entscheidungspunkten die Leitfrage. Der
  /// angeheftete Wert bleibt, bis "Nochmal" gedrueckt wird — auch nach dem
  /// Abschluss, damit die Auswertung zu den getroffenen Entscheidungen passt.
  final Map<String, int> fassungen;

  /// Ob Pathwise sich einmal am Tag meldet. Aus ist die Vorgabe: die App
  /// draengt sich nicht auf, wer es moechte, schaltet es ein.
  final bool erinnerung;

  static String schluessel(String szenarioId, int punkt) => '$szenarioId:$punkt';

  String? wahl(String szenarioId, int punkt) =>
      wahlen[schluessel(szenarioId, punkt)];

  Fortschritt copyWith({
    Map<String, String>? wahlen,
    Set<String>? begonnen,
    Set<String>? gezaehlt,
    Set<String>? gefeiert,
    bool? erststartGesehen,
    ThemeMode? themeMode,
    PwBewegung? bewegung,
    PwVerein? verein,
    bool vereinEntfernen = false,
    bool? vereinGefragt,
    Map<String, int>? fassungen,
    bool? erinnerung,
  }) =>
      Fortschritt(
        wahlen: wahlen ?? this.wahlen,
        begonnen: begonnen ?? this.begonnen,
        gezaehlt: gezaehlt ?? this.gezaehlt,
        gefeiert: gefeiert ?? this.gefeiert,
        erststartGesehen: erststartGesehen ?? this.erststartGesehen,
        themeMode: themeMode ?? this.themeMode,
        bewegung: bewegung ?? this.bewegung,
        verein: vereinEntfernen ? null : (verein ?? this.verein),
        vereinGefragt: vereinGefragt ?? this.vereinGefragt,
        fassungen: fassungen ?? this.fassungen,
        erinnerung: erinnerung ?? this.erinnerung,
      );
}

Map<String, int> _fassungenAusText(String? roh) {
  if (roh == null || roh.isEmpty) return const {};
  try {
    return (jsonDecode(roh) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
  } catch (_) {
    return const {};
  }
}

class FortschrittSpeicher {
  const FortschrittSpeicher();

  static const _kWahlen = 'pw_wahlen';
  static const _kBegonnen = 'pw_begonnen';
  static const _kGezaehlt = 'pw_gezaehlt';
  static const _kGefeiert = 'pw_gefeiert';
  static const _kErststart = 'pw_erststart_gesehen';
  static const _kTheme = 'pw_theme_mode';
  static const _kVerein = 'pw_verein';
  static const _kVereinGefragt = 'pw_verein_gefragt';
  static const _kFassungen = 'pw_fassungen';
  static const _kErinnerung = 'pw_erinnerung';
  static const _kBewegung = 'pw_bewegung';
  /// Vorgaenger: ein blosser Schalter. Wird beim Laden uebernommen.
  static const _kBewegungAlt = 'pw_bewegung_reduziert';

  Future<Fortschritt> laden() async {
    final p = await SharedPreferences.getInstance();
    final rohWahlen = p.getString(_kWahlen);
    return Fortschritt(
      wahlen: rohWahlen == null
          ? const {}
          : (jsonDecode(rohWahlen) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String)),
      begonnen: (p.getStringList(_kBegonnen) ?? const []).toSet(),
      gezaehlt: (p.getStringList(_kGezaehlt) ?? const []).toSet(),
      gefeiert: (p.getStringList(_kGefeiert) ?? const []).toSet(),
      erststartGesehen: p.getBool(_kErststart) ?? false,
      verein: PwVerein.ausText(p.getString(_kVerein)),
      fassungen: _fassungenAusText(p.getString(_kFassungen)),
      vereinGefragt: p.getBool(_kVereinGefragt) ?? false,
      erinnerung: p.getBool(_kErinnerung) ?? false,
      bewegung: p.containsKey(_kBewegung)
          ? PwBewegung.vonSchluessel(p.getString(_kBewegung))
          : (p.getBool(_kBewegungAlt) ?? false)
              ? PwBewegung.reduziert
              : PwBewegung.normal,
      themeMode: switch (p.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
    );
  }

  /// Loescht alles, was die App auf dem Geraet abgelegt hat. Danach steht
  /// die App wie beim ersten Oeffnen da.
  Future<void> allesLoeschen() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [
      _kWahlen,
      _kBegonnen,
      _kGezaehlt,
      _kGefeiert,
      _kErststart,
      _kTheme,
      _kBewegung,
      _kBewegungAlt,
      _kVerein,
      _kVereinGefragt,
      _kFassungen,
      _kErinnerung,
    ]) {
      await p.remove(k);
    }
  }

  Future<void> sichern(Fortschritt f) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kWahlen, jsonEncode(f.wahlen));
    await p.setStringList(_kBegonnen, f.begonnen.toList());
    await p.setStringList(_kGezaehlt, f.gezaehlt.toList());
    await p.setStringList(_kGefeiert, f.gefeiert.toList());
    await p.setBool(_kErststart, f.erststartGesehen);
    await p.setString(_kTheme, f.themeMode.name);
    await p.setString(_kBewegung, f.bewegung.schluessel);
    await p.setBool(_kVereinGefragt, f.vereinGefragt);
    await p.setString(_kFassungen, jsonEncode(f.fassungen));
    await p.setBool(_kErinnerung, f.erinnerung);
    if (f.verein == null) {
      await p.remove(_kVerein);
    } else {
      await p.setString(_kVerein, f.verein!.zuText());
    }
  }
}
