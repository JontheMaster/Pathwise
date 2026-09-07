// S2 — Szenario-Einstieg, DESIGN.md 7/S2.
//
// Der Screen ist bewusst kurz: er soll ohne Scrollen auf ein 390 x 844-Display
// passen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/szenario_modelle.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_card.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_label.dart';
import '../design/components/pw_situation_text.dart';
import '../design/pathwise_routes.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../state/durchlauf_state.dart';
import 'overlays.dart';
import 'punkt_screen.dart';
import 'pw_scaffold.dart';

class EinstiegScreen extends ConsumerWidget {
  const EinstiegScreen({super.key, required this.szenarioId});

  final String szenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(durchlaufProvider);
    final sz = s.inhalt.szenarien.firstWhere((x) => x.id == szenarioId);
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PwScaffold(
      titel: sz.titel,
      // Der Zurueck-Weg fuehrt zur Uebersicht, nicht einen Schritt: der
      // Durchlauf ist jederzeit unterbrechbar (DESIGN.md 6).
      onZurueck: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onEinstellungen: () => einstellungenOeffnen(context),
      onSzenarioOeffnen: (ziel) => szenarioOeffnen(context, ref, ziel),
      aktionen: [
        PwButton(
          label: 'Szenario beginnen',
          variante: PwButtonVariante.accent,
          ikonDanach: PwIcons.arrowRight,
          vollBreite: true,
          onPressed: () {
            ref.read(durchlaufProvider.notifier).begonnen(sz);
            Navigator.of(context).push(
              pwRoute(
                PunktScreen(szenarioId: sz.id, startPunkt: 0),
                PwTransition.vor,
              ),
            );
          },
        ),
      ],
      inhalt: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PwLabel(sz.themenfeld),
            const SizedBox(height: PwSpace.s4),
            Text(sz.titel, style: t.displaySmall),
          ],
        ),
        PwSituationText(text: sz.ausgangssituation, rahmen: sz.rahmen),
        PwCard(
          ton: PwCardTon.tint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const PwLabel('Vorgeschichte'),
              const SizedBox(height: PwSpace.s4),
              Text(
                sz.vorgeschichte,
                style: t.bodyLarge?.copyWith(color: c.textOnTint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ein Szenario oeffnen: noch nicht begonnen fuehrt zum Einstieg, begonnen
/// direkt zum zuletzt offenen Entscheidungspunkt (DESIGN.md 6).
void szenarioOeffnen(BuildContext context, WidgetRef ref, PwSzenario sz) {
  final s = ref.read(durchlaufProvider);
  final begonnen = s.fortschritt.begonnen.contains(sz.id);

  final ziel = begonnen
      ? PunktScreen(szenarioId: sz.id, startPunkt: s.letzterPunkt(sz))
      : EinstiegScreen(szenarioId: sz.id);

  final navigator = Navigator.of(context);
  navigator.popUntil((r) => r.isFirst);
  navigator.push(pwRoute(ziel, PwTransition.oeffnen));
}
