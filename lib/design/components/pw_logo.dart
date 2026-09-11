// Die Bildmarke — DESIGN.md 10.
//
// Sie steht auf weissem Grund und wird rund beschnitten; genau so setzt der
// Prototyp sie ein (border-radius: 50%). Kopfzeile 28 dp, Seitenleiste 26 dp.
// Es ist das einzige Bildmotiv der App: kein Foto, keine Illustration.
import 'package:flutter/material.dart';

class PwLogo extends StatelessWidget {
  const PwLogo({super.key, this.groesse = 28});

  final double groesse;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/logo-mark.png',
        width: groesse,
        height: groesse,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        // Fehlt das Bild, bleibt die Stelle genau so gross wie die Marke.
        // Flutters Fehlerkasten ist breiter und schiebt sonst den Rest der
        // Zeile hinaus — in der Verwaltung stand der Titel dann senkrecht.
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: groesse,
          height: groesse,
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
  }
}
