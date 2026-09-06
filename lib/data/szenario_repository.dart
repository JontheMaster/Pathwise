// Laedt die Szenariodaten aus dem Buendel — DESIGN.md 8, letzter Punkt.
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'szenario_modelle.dart';

class SzenarioRepository {
  const SzenarioRepository();

  static const pfad = 'assets/szenarien.json';

  Future<PwInhalt> laden() async {
    final roh = await rootBundle.loadString(pfad);
    return PwInhalt.ausJson(jsonDecode(roh) as Map<String, dynamic>);
  }
}
