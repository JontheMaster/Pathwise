// Mikro-Label — DESIGN.md 2.6.
//
// Das einzige versal gesetzte Element der App: 11,5 px, 700, Laufweite 0.08em.
// Alles andere bleibt in normaler Gross- und Kleinschreibung.
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';

class PwLabel extends StatelessWidget {
  const PwLabel(this.text, {super.key, this.farbe});

  final String text;

  /// Standard ist textFaint; auf getoenten Flaechen und in den Ampelstufen
  /// traegt das Label die Farbe der Stufe.
  final Color? farbe;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Text(
      text.toUpperCase(),
      style: t.labelSmall?.copyWith(color: farbe ?? context.pw.textFaint),
    );
  }
}
