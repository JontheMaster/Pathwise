// Szenarien — aus der Datenbank, mit dem App-Buendel als Rueckfallebene
// (DESIGN.md 8, letzter Punkt).
//
// Das Buendel bleibt vollstaendig im Programm. Es traegt die App, solange kein
// Netz da ist, und es traegt sie beim Start: die Uebersicht steht sofort, weil
// fuer einen Ladezustand kein Entwurf existiert (DESIGN.md 11, Punkt 4). Der
// Abruf aus der Datenbank laeuft danach nebenher und tauscht die Szenarien aus.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'szenario_modelle.dart';

class SzenarioRepository {
  const SzenarioRepository();

  static const pfad = 'assets/szenarien.json';

  SupabaseClient? get _client {
    if (!SupabaseConfig.vorhanden) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Aus dem Buendel. Schlaegt nie fehl.
  Future<PwInhalt> laden() async {
    final roh = await rootBundle.loadString(pfad);
    return PwInhalt.ausJson(jsonDecode(roh) as Map<String, dynamic>);
  }

  /// Alle veroeffentlichten Szenarien in ihrer aktuellen Fassung.
  ///
  /// Null heisst "nicht abrufbar" — dann bleibt stehen, was schon da ist.
  /// Eine leere Liste waere etwas anderes und wird deshalb nicht als Erfolg
  /// gewertet: eine App ganz ohne Szenarien hat keinen Entwurf.
  Future<List<PwSzenario>?> ausDatenbank() async {
    final c = _client;
    if (c == null) return null;
    try {
      final antwort = await c.rpc('szenarien_aktuell');
      final liste = (antwort as List)
          .cast<Map<String, dynamic>>()
          .map(PwSzenario.ausJson)
          .toList(growable: false);
      return liste.isEmpty ? null : liste;
    } catch (e) {
      debugPrint('Szenarien nicht abrufbar: $e');
      return null;
    }
  }

  /// Eine bestimmte Fassung — fuer einen angefangenen Durchlauf, dessen
  /// Szenario inzwischen ueberarbeitet wurde.
  Future<PwSzenario?> fassung(String id, int fassung) async {
    final c = _client;
    if (c == null || fassung <= 0) return null;
    try {
      final antwort = await c.rpc(
        'szenario_fassung',
        params: {'p_id': id, 'p_fassung': fassung},
      );
      if (antwort == null) return null;
      return PwSzenario.ausJson(antwort as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Fassung $fassung von $id nicht abrufbar: $e');
      return null;
    }
  }
}
