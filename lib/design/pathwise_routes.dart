// ignore_for_file: unnecessary_underscores  // Datei 1:1 aus dem Design-Handoff.
// Pathwise Page-Transitions — siehe DESIGN.md, Abschnitt 6.
import 'package:flutter/material.dart';
import 'pathwise_tokens.dart';

enum PwTransition {
  oeffnen(Duration(milliseconds: 340), Duration(milliseconds: 260)),
  schliessen(Duration(milliseconds: 260), Duration(milliseconds: 260)),
  vor(Duration(milliseconds: 260), Duration(milliseconds: 260)),
  zurueck(Duration(milliseconds: 260), Duration(milliseconds: 260)),
  hoch(Duration(milliseconds: 300), Duration(milliseconds: 260)),
  runter(Duration(milliseconds: 260), Duration(milliseconds: 260));

  const PwTransition(this.dur, this.reverseDur);
  final Duration dur;
  final Duration reverseDur;
}

Route<T> pwRoute<T>(Widget page, PwTransition kind) => PageRouteBuilder<T>(
  transitionDuration: kind.dur,               // M4 340 · M6/M5 260 · M10 300
  reverseTransitionDuration: kind.reverseDur,
  opaque: true,
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (ctx, anim, sec, child) {
    final e = CurvedAnimation(parent: anim, curve: PwCurve.out);
    return FadeTransition(opacity: e, child: switch (kind) {
      PwTransition.oeffnen => ScaleTransition(                    // M4
          scale: Tween(begin: .94, end: 1.0).animate(e),
          child: SlideTransition(
              position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(e),
              child: child)),
      PwTransition.schliessen => ScaleTransition(                 // M5
          scale: Tween(begin: 1.04, end: 1.0).animate(e), child: child),
      PwTransition.vor => SlideTransition(                        // M6 vorwärts
          position: Tween(begin: const Offset(.045, 0), end: Offset.zero).animate(e),
          child: child),
      PwTransition.zurueck => SlideTransition(                    // M6 zurück
          position: Tween(begin: const Offset(-.045, 0), end: Offset.zero).animate(e),
          child: child),
      PwTransition.hoch => SlideTransition(                       // M10
          position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(e),
          child: child),
      PwTransition.runter => SlideTransition(                     // M11
          position: Tween(begin: const Offset(0, -.04), end: Offset.zero).animate(e),
          child: child),
    });
  },
);
