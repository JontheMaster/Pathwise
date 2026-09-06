// S5 — Vereinsangaben, DESIGN.md 7/S5.
//
// Der Screen zeigt die Daten nur an. Woher sie kommen und wie der Verein sie
// aendert, ist nicht designt (DESIGN.md 11, Punkt 3).
// Hier steht als einzigem Screen keine HelpBar: die Beratungsangebote stehen
// schon im Inhalt.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/components/pw_button.dart';
import '../design/components/pw_card.dart';
import '../design/components/pw_contact_list.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_label.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../state/durchlauf_state.dart';
import 'overlays.dart';
import 'pw_scaffold.dart';

class VereinScreen extends ConsumerWidget {
  const VereinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(durchlaufProvider);
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PwScaffold(
      titel: 'Vereinsangaben',
      onZurueck: () => Navigator.of(context).maybePop(),
      helpBar: false,
      aktionen: [
        PwButton(
          label: 'Zurück zur Übersicht',
          ikon: PwIcons.chevronLeft,
          vollBreite: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      inhalt: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.inhalt.verein,
              style: t.displaySmall?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: PwSpace.s4),
            Text(
              'Die Angaben pflegt der Verein. Sie stehen in jedem Szenario am '
              'Ende und jederzeit über die Beratungsleiste.',
              style: t.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ],
        ),
        PwContactList(verein: s.inhalt.verein, personen: s.inhalt.personen),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PwLabel('Externe Beratung'),
            const SizedBox(height: 10),
            for (var i = 0; i < s.inhalt.beratung.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              PwBeratungKarte(beratung: s.inhalt.beratung[i]),
            ],
          ],
        ),
        PwCard(
          ton: PwCardTon.tint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const PwLabel('Was gespeichert wird'),
              const SizedBox(height: PwSpace.s4),
              Text(
                'Dein Fortschritt und deine Entscheidungen bleiben auf diesem '
                'Gerät. An den Verein geht nichts. Gespeichert wird nur ein '
                'Zählwert je Entscheidungspunkt und Handlungsoption.',
                style: t.bodyLarge?.copyWith(color: c.textOnTint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
