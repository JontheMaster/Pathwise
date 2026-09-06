// Press-Scale — Motion M1 aus DESIGN.md 5: scale 1 -> 0.985 -> 1 in 80 ms.
//
// Bewusst ueber [Listener] statt [GestureDetector]: so mischt sich das Widget
// nicht in die Gestenerkennung ein und laesst sich um einen Button legen, der
// seinen Tap selbst behandelt.
import 'package:flutter/material.dart';

import '../pathwise_tokens.dart';
import '../pw_motion.dart';

class PwPressScale extends StatefulWidget {
  const PwPressScale({super.key, required this.child, this.aktiv = true});

  final Widget child;

  /// Deaktivierte Bedienelemente reagieren nicht (DESIGN.md 4.1, State disabled).
  final bool aktiv;

  @override
  State<PwPressScale> createState() => _PwPressScaleState();
}

class _PwPressScaleState extends State<PwPressScale> {
  bool _gedrueckt = false;

  void _setzen(bool wert) {
    if (!widget.aktiv || _gedrueckt == wert) return;
    setState(() => _gedrueckt = wert);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setzen(true),
      onPointerUp: (_) => _setzen(false),
      onPointerCancel: (_) => _setzen(false),
      child: AnimatedScale(
        scale: _gedrueckt && widget.aktiv ? kPressScale : 1.0,
        duration: PwMotion.dauer(context, PwDur.instant),
        curve: PwCurve.standard,
        child: widget.child,
      ),
    );
  }
}
