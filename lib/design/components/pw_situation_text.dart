// PwSituationText — DESIGN.md 4.6.
//
// Karte mit Rahmen-Chips oben (Altersgruppe, Ort, Zeitpunkt) und dem
// Situationstext darunter. Die Variante `fortsetzung` ersetzt die Chips durch
// das Icon corner-down-right und ein Mikro-Label.
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import 'pw_icons.dart';
import 'pw_label.dart';

class PwSituationText extends StatelessWidget {
  const PwSituationText({
    super.key,
    required this.text,
    this.rahmen = const [],
    this.fortsetzungLabel,
  });

  final String text;

  /// Rahmen-Chips: Altersgruppe, Ort, Zeitpunkt.
  final List<String> rahmen;

  /// Gesetzt schaltet auf die Variante `fortsetzung` um — etwa
  /// "So geht es weiter" oder "Was gerade passiert".
  final String? fortsetzungLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(PwSpace.cardPad),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: PwRadius.card,
        border: Border.all(color: c.borderSubtle),
        boxShadow: PwShadow.sm(context.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fortsetzungLabel != null)
            Row(
              children: [
                Icon(PwIcons.cornerDownRight, size: 14, color: c.textFaint),
                const SizedBox(width: 7),
                PwLabel(fortsetzungLabel!),
              ],
            )
          else if (rahmen.isNotEmpty)
            Wrap(
              spacing: PwSpace.s4,
              runSpacing: PwSpace.s4,
              children: [for (final r in rahmen) _RahmenChip(text: r)],
            ),
          if (fortsetzungLabel != null || rahmen.isNotEmpty)
            const SizedBox(height: PwSpace.gapTight),
          Text(text, style: t.bodyLarge),
        ],
      ),
    );
  }
}

class _RahmenChip extends StatelessWidget {
  const _RahmenChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(PwRadius.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: c.textMuted),
      ),
    );
  }
}
