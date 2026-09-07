// Pathwise Page-Transitions — siehe DESIGN.md, Abschnitt 6.
//
// Abweichung vom Handoff-Entwurf: dort baut transitionsBuilder immer die
// Bewegung, mit der ein Screen gekommen ist — beim Schliessen laeuft sie
// rueckwaerts. Der Weg zurueck zur Uebersicht saehe dann je nach Herkunft
// anders aus (aus dem Einstieg anders als aus der Auswertung), obwohl M5 fuer
// das Schliessen genau eine Bewegung vorgibt. Beim Rueckwaertslauf gilt
// deshalb immer PwTransition.schliessen.
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

/// Versatz einer Bewegung als Anteil der Bildschirmgroesse, bei Fortschritt 0.
Offset _startversatz(PwTransition kind) => switch (kind) {
      PwTransition.oeffnen => const Offset(0, .03), // M4
      PwTransition.schliessen => Offset.zero, // M5
      PwTransition.vor => const Offset(.045, 0), // M6 vorwärts
      PwTransition.zurueck => const Offset(-.045, 0), // M6 zurück
      PwTransition.hoch => const Offset(0, .06), // M10
      PwTransition.runter => const Offset(0, -.04), // M11
    };

/// Skalierung einer Bewegung bei Fortschritt 0.
double _startskala(PwTransition kind) => switch (kind) {
      PwTransition.oeffnen => .94, // M4
      PwTransition.schliessen => 1.04, // M5
      _ => 1.0,
    };

Route<T> pwRoute<T>(Widget page, PwTransition kind) => PageRouteBuilder<T>(
      transitionDuration: kind.dur, // M4 340 · M6/M5 260 · M10 300
      reverseTransitionDuration: kind.reverseDur,
      opaque: true,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (ctx, anim, sec, child) {
        // AnimatedBuilder statt der *Transition-Widgets, weil die Richtung
        // erst je Frame feststeht.
        return AnimatedBuilder(
          animation: anim,
          child: child,
          builder: (ctx, inhalt) {
            final art = anim.status == AnimationStatus.reverse
                ? PwTransition.schliessen
                : kind;

            final t = PwCurve.out.transform(anim.value.clamp(0.0, 1.0));
            final versatz = _startversatz(art) * (1 - t);
            final skala = _startskala(art) + (1.0 - _startskala(art)) * t;

            return Opacity(
              opacity: t,
              child: FractionalTranslation(
                translation: versatz,
                child: skala == 1.0
                    ? inhalt
                    : Transform.scale(scale: skala, child: inhalt),
              ),
            );
          },
        );
      },
    );
