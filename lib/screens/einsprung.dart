// Haelt Widget und Erinnerung auf dem Stand der App — und oeffnet das
// Szenario, wenn jemand auf eines von beiden tippt.
//
// Sitzt einmal um die ganze App (main.dart) und beobachtet den Zustand, statt
// dass jede Stelle, die ihn aendert, einzeln Bescheid sagen muesste: wer ein
// Szenario beginnt, eine Antwort aendert oder "Nochmal" drueckt, veraendert
// damit auch, was das Widget zeigt.
//
// Nichts hiervon blockiert. Klappt ein Abgleich nicht, laeuft die App weiter
// wie ohne Widget (DESIGN.md 8).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/einsprung_bruecke.dart';
import '../data/vorschlag.dart';
import '../state/durchlauf_state.dart';
import 'einstieg_screen.dart';

/// Der Navigator der App. Ein Tipp aufs Widget kommt von ausserhalb jedes
/// Screens an und braucht trotzdem einen Weg hinein.
final pwNavigatorKey = GlobalKey<NavigatorState>();

class PwEinsprung extends ConsumerStatefulWidget {
  const PwEinsprung({super.key, required this.child, this.jetzt = DateTime.now});

  final Widget child;

  /// Die Uhr fuer den Erinnerungsplan — in Tests austauschbar.
  final DateTime Function() jetzt;

  @override
  ConsumerState<PwEinsprung> createState() => _PwEinsprungState();
}

class _PwEinsprungState extends ConsumerState<PwEinsprung> {
  StreamSubscription<String>? _abo;
  AppLifecycleListener? _lebenszyklus;

  /// Was zuletzt hinuebergegangen ist. Unveraendertes wird nicht erneut
  /// geschickt — jeder Aufruf laedt das Widget neu.
  String? _zuletztWidget;
  String? _zuletztPlan;

  EinsprungBruecke get _bruecke => ref.read(einsprungBrueckeProvider);

  @override
  void initState() {
    super.initState();
    final bruecke = _bruecke;
    if (!bruecke.verfuegbar) return;

    _abo = bruecke.ziele.listen(_oeffnen);
    ref.listenManual(durchlaufProvider, (_, _) => _abgleichen());
    // Zurueck aus dem Hintergrund: der Plan rueckt einen Tag weiter, und das
    // Widget bekommt denselben Stand noch einmal, falls es ihn verloren hat.
    _lebenszyklus =
        AppLifecycleListener(onResume: () => _abgleichen(erzwingen: true));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _abgleichen(erzwingen: true);
      try {
        final ziel = await bruecke.startZiel();
        if (ziel != null) _oeffnen(ziel);
      } catch (e) {
        debugPrint('Einsprung beim Start: $e');
      }
    });
  }

  @override
  void dispose() {
    _abo?.cancel();
    _lebenszyklus?.dispose();
    super.dispose();
  }

  Future<void> _abgleichen({bool erzwingen = false}) async {
    if (!mounted) return;
    final bruecke = _bruecke;
    final s = ref.read(durchlaufProvider);

    try {
      final daten = widgetDaten(s);
      final text = jsonEncode(daten);
      if (erzwingen || text != _zuletztWidget) {
        _zuletztWidget = text;
        await bruecke.widgetAktualisieren(daten);
      }

      if (s.fortschritt.erinnerung) {
        final plan = erinnerungsplan(s, widget.jetzt());
        final schluessel = jsonEncode([for (final e in plan) e.zuKanal()]);
        if (erzwingen || schluessel != _zuletztPlan) {
          _zuletztPlan = schluessel;
          await bruecke.erinnerungenPlanen(plan);
        }
      } else if (erzwingen || _zuletztPlan != '') {
        _zuletztPlan = '';
        await bruecke.erinnerungenLoeschen();
      }
    } catch (e) {
      debugPrint('Einsprung-Abgleich: $e');
    }
  }

  /// Oeffnet das Szenario hinter [adresse] — genau wie ein Tipp auf seine
  /// Karte in der Uebersicht: begonnen heisst zurueck an den offenen Punkt.
  void _oeffnen(String adresse) {
    final navigator = pwNavigatorKey.currentState;
    if (navigator == null || !mounted) return;

    final id = szenarioAusAdresse(adresse);
    final sz = id == null
        ? null
        : ref
            .read(durchlaufProvider)
            .inhalt
            .szenarien
            .where((x) => x.id == id)
            .firstOrNull;

    // Unbekannt oder inzwischen zurueckgezogen: dann die Uebersicht.
    if (sz == null) {
      navigator.popUntil((r) => r.isFirst);
      return;
    }
    szenarioOeffnenMit(navigator, ref, sz);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
