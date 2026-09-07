// Lokale Persistenz — DESIGN.md 8: Wahlen, begonnene Szenarien, Erststart und
// Theme-Wunsch bleiben auf dem Geraet. Kein Konto, keine Cloud-Sicherung, kein
// Analytics. Im Web landet das in localStorage.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class Fortschritt {
  const Fortschritt({
    this.wahlen = const {},
    this.begonnen = const {},
    this.gezaehlt = const {},
    this.gefeiert = const {},
    this.erststartGesehen = false,
    this.themeMode = ThemeMode.dark,
    this.bewegungReduziert = false,
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

  /// Bewegung in der App abschalten, unabhaengig von der Systemeinstellung.
  /// Wer die Systemeinstellung schon gesetzt hat, braucht das nicht — die
  /// gilt weiterhin (DESIGN.md 5).
  final bool bewegungReduziert;

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
    bool? bewegungReduziert,
  }) =>
      Fortschritt(
        wahlen: wahlen ?? this.wahlen,
        begonnen: begonnen ?? this.begonnen,
        gezaehlt: gezaehlt ?? this.gezaehlt,
        gefeiert: gefeiert ?? this.gefeiert,
        erststartGesehen: erststartGesehen ?? this.erststartGesehen,
        themeMode: themeMode ?? this.themeMode,
        bewegungReduziert: bewegungReduziert ?? this.bewegungReduziert,
      );
}

class FortschrittSpeicher {
  const FortschrittSpeicher();

  static const _kWahlen = 'pw_wahlen';
  static const _kBegonnen = 'pw_begonnen';
  static const _kGezaehlt = 'pw_gezaehlt';
  static const _kGefeiert = 'pw_gefeiert';
  static const _kErststart = 'pw_erststart_gesehen';
  static const _kTheme = 'pw_theme_mode';
  static const _kBewegung = 'pw_bewegung_reduziert';

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
      bewegungReduziert: p.getBool(_kBewegung) ?? false,
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
    await p.setBool(_kBewegung, f.bewegungReduziert);
  }
}
