// Die Angaben eines Vereins, wie sie die Datenbank liefert.
//
// Bis hierher lagen sie im App-Buendel: eine geaenderte Telefonnummer hiess
// neue APK fuer alle. Jetzt pflegt sie eine Person zentral.
//
// Ein Geraet erfaehrt seinen Verein ueber einen kurzen Code. Der ist kein
// Login und kein Geheimnis — er ordnet zu, mehr nicht.
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'szenario_modelle.dart';

@immutable
class PwVerein {
  const PwVerein({
    required this.id,
    required this.code,
    required this.name,
    required this.personen,
    required this.beratung,
  });

  final String id;
  final String code;
  final String name;
  final List<PwPerson> personen;
  final List<PwBeratung> beratung;

  factory PwVerein.ausJson(Map<String, dynamic> j) => PwVerein(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        personen: ((j['personen'] as List?) ?? const [])
            .map((p) => PwPerson.ausJson(p as Map<String, dynamic>))
            .toList(growable: false),
        beratung: ((j['beratung'] as List?) ?? const [])
            .map((b) => PwBeratung.ausJson(b as Map<String, dynamic>))
            .toList(growable: false),
      );

  /// Fuer den lokalen Zwischenspeicher: dieselbe Form, die die Datenbank
  /// liefert, damit Lesen und Schreiben denselben Weg gehen.
  Map<String, dynamic> zuJson() => {
        'id': id,
        'code': code,
        'name': name,
        'personen': [
          for (final p in personen)
            {
              'name': p.name,
              'rolle': p.rolle,
              'kontakt': p.kontakt,
              'kontaktart': p.perTelefon ? 'telefon' : 'mail',
            },
        ],
        'beratung': [
          for (final b in beratung)
            {'titel': b.titel, 'zusatz': b.zusatz, 'nummer': b.nummer},
        ],
      };

  String zuText() => jsonEncode(zuJson());

  static PwVerein? ausText(String? roh) {
    if (roh == null || roh.isEmpty) return null;
    try {
      return PwVerein.ausJson(jsonDecode(roh) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
