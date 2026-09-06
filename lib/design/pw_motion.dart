// Zentrale Stelle fuer reduzierte Bewegung — siehe DESIGN.md, Abschnitt 5,
// Absatz "Reduzierte Bewegung".
//
// Jede Dauer in der App laeuft durch [PwMotion.dauer]. Ist im System "Bewegung
// reduzieren" gesetzt, liefert der Faktor 0.0: alles steht sofort im Endzustand,
// die Dauerschleifen M17-M19 laufen gar nicht erst an.
import 'package:flutter/material.dart';

abstract final class PwMotion {
  /// 1.0 im Normalfall, 0.0 wenn das System Bewegung reduziert.
  static double scale(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return 1.0;
    return (mq.disableAnimations || mq.accessibleNavigation) ? 0.0 : 1.0;
  }

  /// [d] mit dem Faktor aus [scale] — bei reduzierter Bewegung [Duration.zero].
  static Duration dauer(BuildContext context, Duration d) =>
      scale(context) == 0.0 ? Duration.zero : d;

  /// Ob Dauerschleifen (M17, M18, M19) ueberhaupt starten duerfen.
  static bool schleifenErlaubt(BuildContext context) => scale(context) != 0.0;

  /// Versatz einer gestaffelten Reihe (M21, M22): [schritt] je Position,
  /// bei reduzierter Bewegung ohne Versatz.
  static Duration versatz(BuildContext context, int position, Duration schritt) =>
      scale(context) == 0.0 ? Duration.zero : schritt * position;
}
