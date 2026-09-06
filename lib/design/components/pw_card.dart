// PwCard — DESIGN.md 4.3.
//
// DecoratedBox + ClipRRect statt Card: Card bringt Material-Elevation und
// Surface-Tint mit, die hier stoeren, und die 3 dp hohe Oberkante muss
// beschnitten werden.
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';
import 'pw_press_scale.dart';

enum PwCardTon {
  standard,
  tint,
  warm,

  /// Hoechstens einmal je Ansicht.
  inverse,
}

enum PwCardPolster {
  sm(14),
  md(PwSpace.cardPad),
  lg(PwSpace.cardPadLg);

  const PwCardPolster(this.wert);
  final double wert;
}

/// Dekoration der 3 dp hohen Oberkante. Eine farbige *linke* Kante ist kein
/// Pathwise-Muster (DESIGN.md 4.3).
sealed class PwCardAkzent {
  const PwCardAkzent();

  /// Die Drei-Bogen-Folge der Marke — der einzige erlaubte Gradient.
  static const sweep = _AkzentSweep();

  /// Eine Volltonfarbe.
  const factory PwCardAkzent.vollton(Color farbe) = _AkzentVollton;
}

class _AkzentSweep extends PwCardAkzent {
  const _AkzentSweep();
}

class _AkzentVollton extends PwCardAkzent {
  const _AkzentVollton(this.farbe);
  final Color farbe;
}

class PwCard extends StatefulWidget {
  const PwCard({
    super.key,
    required this.child,
    this.ton = PwCardTon.standard,
    this.polster = PwCardPolster.md,
    this.akzent,
    this.onTap,
  });

  final Widget child;
  final PwCardTon ton;
  final PwCardPolster polster;
  final PwCardAkzent? akzent;

  /// Gesetzt macht die Karte interaktiv: Hover hebt sie um 2 dp, auf Touch
  /// greift stattdessen der Press-Scale.
  final VoidCallback? onTap;

  @override
  State<PwCard> createState() => _PwCardState();
}

/// Hoehe der Akzent-Oberkante (DESIGN.md 4.3).
const double _kAkzentHoehe = 3.0;

class _PwCardState extends State<PwCard> {
  bool _darueber = false;

  Color _flaeche(PwColors c) => switch (widget.ton) {
        PwCardTon.standard => c.surfaceCard,
        PwCardTon.tint => c.surfaceTint,
        PwCardTon.warm => c.surfaceTintWarm,
        PwCardTon.inverse => c.surfaceInverse,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final dunkel = context.isDark;
    final interaktiv = widget.onTap != null;
    final gehoben = interaktiv && _darueber;

    Widget karte = AnimatedContainer(
      duration: PwMotion.dauer(context, PwDur.base),
      curve: PwCurve.out,
      decoration: BoxDecoration(
        color: _flaeche(c),
        borderRadius: PwRadius.card,
        border: Border.all(color: c.borderSubtle),
        boxShadow: gehoben ? PwShadow.md(dunkel) : PwShadow.sm(dunkel),
      ),
      child: ClipRRect(
        // Die Oberkante muss beschnitten werden, sonst steht sie ueber die
        // Rundung hinaus.
        borderRadius: PwRadius.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.akzent != null) _Oberkante(akzent: widget.akzent!),
            Padding(
              padding: EdgeInsets.all(widget.polster.wert),
              child: widget.child,
            ),
          ],
        ),
      ),
    );

    if (!interaktiv) return karte;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _darueber = true),
      onExit: (_) => setState(() => _darueber = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: PwPressScale(
          // Hover hebt die Karte um 2 dp — nur auf Zeigergeraeten (M3).
          // Der Versatz ist in dp angegeben, nicht als Anteil der Kartenhoehe.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: gehoben ? kLiftHover : 0.0),
            duration: PwMotion.dauer(context, PwDur.base),
            curve: PwCurve.out,
            builder: (_, dy, kind) =>
                Transform.translate(offset: Offset(0, dy), child: kind),
            child: karte,
          ),
        ),
      ),
    );
  }
}

class _Oberkante extends StatelessWidget {
  const _Oberkante({required this.akzent});

  final PwCardAkzent akzent;

  @override
  Widget build(BuildContext context) {
    final a = akzent;
    return SizedBox(
      height: _kAkzentHoehe,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: a is _AkzentSweep ? PwPalette.sweep : null,
          color: a is _AkzentVollton ? a.farbe : null,
        ),
      ),
    );
  }
}
