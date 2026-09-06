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
    this.erststartGesehen = false,
    this.themeMode = ThemeMode.dark,
  });

  /// "szenarioId:punktIndex" -> "a" | "b" | "c"
  final Map<String, String> wahlen;
  final Set<String> begonnen;
  final bool erststartGesehen;

  /// Dunkel ist der Standard der App, nicht `system` (DESIGN.md 3).
  final ThemeMode themeMode;

  static String schluessel(String szenarioId, int punkt) => '$szenarioId:$punkt';

  String? wahl(String szenarioId, int punkt) =>
      wahlen[schluessel(szenarioId, punkt)];

  Fortschritt copyWith({
    Map<String, String>? wahlen,
    Set<String>? begonnen,
    bool? erststartGesehen,
    ThemeMode? themeMode,
  }) =>
      Fortschritt(
        wahlen: wahlen ?? this.wahlen,
        begonnen: begonnen ?? this.begonnen,
        erststartGesehen: erststartGesehen ?? this.erststartGesehen,
        themeMode: themeMode ?? this.themeMode,
      );
}

class FortschrittSpeicher {
  const FortschrittSpeicher();

  static const _kWahlen = 'pw_wahlen';
  static const _kBegonnen = 'pw_begonnen';
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
    await p.setBool(_kErststart, f.erststartGesehen);
    await p.setString(_kTheme, f.themeMode.name);
  }
}
