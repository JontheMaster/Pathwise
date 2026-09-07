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
    this.erststartGesehen = false,
    this.themeMode = ThemeMode.dark,
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

  final bool erststartGesehen;

  /// Dunkel ist der Standard der App, nicht `system` (DESIGN.md 3).
  final ThemeMode themeMode;

  static String schluessel(String szenarioId, int punkt) => '$szenarioId:$punkt';

  String? wahl(String szenarioId, int punkt) =>
      wahlen[schluessel(szenarioId, punkt)];

  Fortschritt copyWith({
    Map<String, String>? wahlen,
    Set<String>? begonnen,
    Set<String>? gezaehlt,
    bool? erststartGesehen,
    ThemeMode? themeMode,
  }) =>
      Fortschritt(
        wahlen: wahlen ?? this.wahlen,
        begonnen: begonnen ?? this.begonnen,
        gezaehlt: gezaehlt ?? this.gezaehlt,
        erststartGesehen: erststartGesehen ?? this.erststartGesehen,
        themeMode: themeMode ?? this.themeMode,
      );
}

class FortschrittSpeicher {
  const FortschrittSpeicher();

  static const _kWahlen = 'pw_wahlen';
  static const _kBegonnen = 'pw_begonnen';
  static const _kGezaehlt = 'pw_gezaehlt';
  static const _kErststart = 'pw_erststart_gesehen';
  static const _kTheme = 'pw_theme_mode';

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
      erststartGesehen: p.getBool(_kErststart) ?? false,
      themeMode: switch (p.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
    );
  }

  Future<void> sichern(Fortschritt f) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kWahlen, jsonEncode(f.wahlen));
    await p.setStringList(_kBegonnen, f.begonnen.toList());
    await p.setStringList(_kGezaehlt, f.gezaehlt.toList());
    await p.setBool(_kErststart, f.erststartGesehen);
    await p.setString(_kTheme, f.themeMode.name);
  }
}
