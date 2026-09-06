// PwStepIndicator — DESIGN.md 4.5, Motion M20.
//
// Reihe aus n Punkten, Abstand 5. Erledigt und aktuell in actionPrimary, offen
// in borderSubtle; der aktuelle Punkt ist 18 x 7 statt 7 x 7. Danach 10 dp
// Abstand und der Text "Entscheidungspunkt {i} von {n}".
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';

class PwStepIndicator extends StatelessWidget {
  const PwStepIndicator({
    super.key,
    required this.gesamt,
    required this.aktuell,
    this.mitText = true,
  });

  final int gesamt;

  /// Einsbasiert.
  final int aktuell;

  final bool mitText;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Semantics(
      label: 'Entscheidungspunkt $aktuell von $gesamt',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= gesamt; i++) ...[
            if (i > 1) const SizedBox(width: 5),
            AnimatedContainer(
              duration: PwMotion.dauer(context, PwDur.base),
              curve: PwCurve.out,
              width: i == aktuell ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i <= aktuell ? c.actionPrimary : c.borderSubtle,
                borderRadius: BorderRadius.circular(PwRadius.pill),
              ),
            ),
          ],
          if (mitText) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Entscheidungspunkt $aktuell von $gesamt',
                style: t.bodyMedium?.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
