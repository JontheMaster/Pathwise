// Die Bruecke zu iOS fuer alles, was ausserhalb der App passiert: das Widget
// auf dem Homescreen, die taegliche Erinnerung und der Weg zurueck in die App,
// wenn jemand auf eines von beiden tippt.
//
// Bewusst ohne Plugin. Die Gegenseite steht in ios/Runner/PathwiseBruecke.swift
// und im Widget-Target ios/PathwiseWidget/. Auf allen anderen Plattformen gibt
// es beides nicht, und die App nimmt [KeineEinsprungBruecke] — so bleiben
// Android-, Web- und Desktop-Builds unberuehrt.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vorschlag.dart';

/// Ob das System Mitteilungen von Pathwise zulaesst.
enum PwErlaubnis { erlaubt, abgelehnt, offen }

abstract class EinsprungBruecke {
  const EinsprungBruecke();

  /// Ob es Widget und Erinnerung auf dieser Plattform gibt.
  bool get verfuegbar;

  /// Die Adresse, ueber die die App gestartet wurde — einmal, danach null.
  Future<String?> startZiel();

  /// Adressen, die ankommen, waehrend die App schon laeuft.
  Stream<String> get ziele;

  Future<void> widgetAktualisieren(Map<String, Object?> daten);

  Future<PwErlaubnis> erlaubnis();

  /// Fragt das System. Beim ersten Mal erscheint dessen Dialog, danach
  /// antwortet es ohne Rueckfrage.
  Future<bool> erlaubnisAnfragen();

  /// Ersetzt alle geplanten Erinnerungen durch [plan].
  Future<void> erinnerungenPlanen(List<PwErinnerung> plan);

  Future<void> erinnerungenLoeschen();

  /// Die Kennungen der geplanten Erinnerungen — zum Nachpruefen.
  Future<List<String>> geplanteErinnerungen();

  /// Oeffnet die Mitteilungs-Einstellungen des Systems fuer Pathwise.
  Future<void> systemEinstellungenOeffnen();
}

/// Ueberall, wo es kein Widget und keine Erinnerung gibt.
class KeineEinsprungBruecke extends EinsprungBruecke {
  const KeineEinsprungBruecke();

  @override
  bool get verfuegbar => false;
  @override
  Future<String?> startZiel() async => null;
  @override
  Stream<String> get ziele => const Stream.empty();
  @override
  Future<void> widgetAktualisieren(Map<String, Object?> daten) async {}
  @override
  Future<PwErlaubnis> erlaubnis() async => PwErlaubnis.abgelehnt;
  @override
  Future<bool> erlaubnisAnfragen() async => false;
  @override
  Future<void> erinnerungenPlanen(List<PwErinnerung> plan) async {}
  @override
  Future<void> erinnerungenLoeschen() async {}
  @override
  Future<List<String>> geplanteErinnerungen() async => const [];
  @override
  Future<void> systemEinstellungenOeffnen() async {}
}

class IosEinsprungBruecke extends EinsprungBruecke {
  IosEinsprungBruecke() {
    _kanal.setMethodCallHandler((aufruf) async {
      if (aufruf.method == 'ziel' && aufruf.arguments is String) {
        _ziele.add(aufruf.arguments as String);
      }
      return null;
    });
  }

  static const _kanal = MethodChannel('pathwise/einsprung');
  final _ziele = StreamController<String>.broadcast();

  @override
  bool get verfuegbar => true;

  @override
  Future<String?> startZiel() => _kanal.invokeMethod<String>('startZiel');

  @override
  Stream<String> get ziele => _ziele.stream;

  @override
  Future<void> widgetAktualisieren(Map<String, Object?> daten) =>
      _kanal.invokeMethod('widgetDaten', jsonEncode(daten));

  @override
  Future<PwErlaubnis> erlaubnis() async =>
      switch (await _kanal.invokeMethod<String>('erlaubnis')) {
        'erlaubt' => PwErlaubnis.erlaubt,
        'abgelehnt' => PwErlaubnis.abgelehnt,
        _ => PwErlaubnis.offen,
      };

  @override
  Future<bool> erlaubnisAnfragen() async =>
      await _kanal.invokeMethod<bool>('erlaubnisAnfragen') ?? false;

  @override
  Future<void> erinnerungenPlanen(List<PwErinnerung> plan) => _kanal
      .invokeMethod('erinnerungenPlanen', [for (final e in plan) e.zuKanal()]);

  @override
  Future<void> erinnerungenLoeschen() =>
      _kanal.invokeMethod('erinnerungenLoeschen');

  @override
  Future<List<String>> geplanteErinnerungen() async =>
      await _kanal.invokeListMethod<String>('geplant') ?? const [];

  @override
  Future<void> systemEinstellungenOeffnen() =>
      _kanal.invokeMethod('systemEinstellungen');
}

final einsprungBrueckeProvider = Provider<EinsprungBruecke>(
  (_) => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? IosEinsprungBruecke()
      : const KeineEinsprungBruecke(),
);
