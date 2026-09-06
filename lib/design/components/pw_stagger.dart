// Gestaffelter Eintritt — Motion M22 (Ampel-Listen) und M21 (Spiegelbalken).
//
// Eintritte sind ein kurzes Aufsteigen mit Einblenden, je Zeile 60 ms versetzt.
// Kein Federn, kein Bounce (DESIGN.md 5, Grundsaetze).
import 'package:flutter/material.dart';

import '../pathwise_tokens.dart';
import '../pw_motion.dart';

/// Steuert eine gestaffelte Reihe. Laeuft einmal beim Erscheinen.
class PwStaffel extends StatefulWidget {
  const PwStaffel({
    super.key,
    required this.anzahl,
    required this.builder,
    this.dauer = PwDur.base,
    this.schritt = PwDur.staggerStep,
  });

  final int anzahl;
  final Duration dauer;
  final Duration schritt;

  /// [fortschritt] laeuft je Position von 0 nach 1, bereits mit PwCurve.out.
  final Widget Function(BuildContext context, List<double> fortschritt) builder;

  @override
  State<PwStaffel> createState() => _PwStaffelState();
}

class _PwStaffelState extends State<PwStaffel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.dauer + widget.schritt * widget.anzahl,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PwMotion.schleifenErlaubt(context)) {
      if (!_c.isAnimating && _c.value == 0) _c.forward();
    } else {
      // Bei reduzierter Bewegung sofort der Endzustand.
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gesamt = _c.duration!.inMilliseconds;
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) {
        final werte = <double>[
          for (var i = 0; i < widget.anzahl; i++)
            PwCurve.out.transform(
              (((_c.value * gesamt) - widget.schritt.inMilliseconds * i) /
                      widget.dauer.inMilliseconds)
                  .clamp(0.0, 1.0),
            ),
        ];
        return widget.builder(ctx, werte);
      },
    );
  }
}

/// Aufsteigen mit Einblenden fuer einen einzelnen Eintrag der Staffel.
class PwEintritt extends StatelessWidget {
  const PwEintritt({
    super.key,
    required this.fortschritt,
    required this.child,
    this.versatz = kRevealShift,
  });

  final double fortschritt;
  final double versatz;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: fortschritt,
        child: Transform.translate(
          offset: Offset(0, versatz * (1 - fortschritt)),
          child: child,
        ),
      );
}
