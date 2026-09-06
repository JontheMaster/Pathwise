// PwLevelList — Ampel-Einordnung, DESIGN.md 4.9, Motion M22.
//
// Farbe ist hier bedeutungstragend. Deshalb traegt jede Stufe zusaetzlich ihr
// Icon und ihr Textlabel: Farbe ist nie der einzige Traeger (DESIGN.md 9).
// Diese Farben gehoeren ausschliesslich der Einordnung von Merkmalen — nie
// Buttons, Optionen, Fortschritt.
import 'package:flutter/material.dart';

import '../../data/szenario_modelle.dart';
import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import 'pw_icons.dart';
import 'pw_label.dart';
import 'pw_stagger.dart';

class PwLevelList extends StatelessWidget {
  const PwLevelList({super.key, required this.stufe, required this.merkmale});

  final PwStufe stufe;
  final List<PwMerkmal> merkmale;

  (Color, Color, IconData) _stufenwerte(PwColors c) => switch (stufe) {
        PwStufe.unbedenklich => (c.levelOk, c.levelOkBg, PwIcons.circleCheck),
        PwStufe.klaerungsbeduerftig => (
            c.levelCheck,
            c.levelCheckBg,
            PwIcons.circleHelp
          ),
        PwStufe.grenzverletzend => (
            c.levelViolation,
            c.levelViolationBg,
            PwIcons.circleAlert
          ),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final (farbe, flaeche, ikon) = _stufenwerte(c);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: flaeche, shape: BoxShape.circle),
              child: Icon(ikon, size: 13, color: farbe),
            ),
            const SizedBox(width: PwSpace.s4),
            Flexible(child: PwLabel(stufe.label, farbe: farbe)),
          ],
        ),
        const SizedBox(height: 10),
        PwStaffel(
          anzahl: merkmale.length,
          builder: (ctx, werte) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < merkmale.length; i++) ...[
                if (i > 0) const SizedBox(height: PwSpace.s3),
                PwEintritt(
                  fortschritt: werte[i],
                  child: _Block(
                    merkmal: merkmale[i],
                    farbe: farbe,
                    flaeche: flaeche,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.merkmal,
    required this.farbe,
    required this.flaeche,
  });

  final PwMerkmal merkmal;
  final Color farbe;
  final Color flaeche;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    // Stack statt Border(left:) — eine ungleichmaessige Border vertraegt sich
    // in Flutter nicht mit borderRadius.
    return ClipRRect(
      borderRadius: PwRadius.control,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: flaeche)),
          // Der 3 dp breite Strich links traegt die Stufenfarbe.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: farbe),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 13, 11),
            child: Text(
              merkmal.anzeigetext,
              style: t.bodyLarge?.copyWith(
                color: merkmal.nichtEingetreten ? c.textMuted : c.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
