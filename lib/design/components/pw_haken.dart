// Ein Haken, der sich selbst zeichnet — Bestaetigung, nachdem eine
// Rueckmeldung abgeschickt wurde.
//
// Bewusst eine Bestaetigung und keine Feier: sie quittiert eine Handlung, wie
// es jedes Formular tut. Bewertet wird nichts. Deshalb ist das die
// unbedenklichste Stelle fuer eine zusaetzliche Animation (DESIGN.md 1).
//
// Ohne Lottie gebaut: ein Pfad, zwei Striche, keine Datei und keine Lizenzfrage.
import 'package:flutter/material.dart';

import '../pathwise_tokens.dart';
import '../pw_motion.dart';

class PwHaken extends StatefulWidget {
  const PwHaken({
    super.key,
    required this.farbe,
    this.groesse = 20,
    this.dauer = const Duration(milliseconds: 520),
  });

  final Color farbe;
  final double groesse;
  final Duration dauer;

  @override
  State<PwHaken> createState() => _PwHakenState();
}

class _PwHakenState extends State<PwHaken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.dauer);
  bool _gestartet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gestartet) return;
    _gestartet = true;

    if (!PwMotion.schleifenErlaubt(context)) {
      // Bei reduzierter Bewegung steht der Haken sofort fertig da.
      _c.value = 1;
      return;
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.groesse,
      height: widget.groesse,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _HakenMaler(
            fortschritt: PwCurve.out.transform(_c.value),
            farbe: widget.farbe,
          ),
        ),
      ),
    );
  }
}

class _HakenMaler extends CustomPainter {
  const _HakenMaler({required this.fortschritt, required this.farbe});

  final double fortschritt;
  final Color farbe;

  @override
  void paint(Canvas canvas, Size size) {
    if (fortschritt <= 0) return;

    // Ein Haken in den Proportionen des Lucide-Icons, auf die Kantenlaenge
    // bezogen.
    final start = Offset(size.width * 0.20, size.height * 0.53);
    final knick = Offset(size.width * 0.42, size.height * 0.74);
    final ende = Offset(size.width * 0.80, size.height * 0.28);

    final kurz = (knick - start).distance;
    final lang = (ende - knick).distance;
    final gesamt = kurz + lang;
    final gezeichnet = gesamt * fortschritt;

    final pfad = Path()..moveTo(start.dx, start.dy);
    if (gezeichnet <= kurz) {
      final t = gezeichnet / kurz;
      pfad.lineTo(
        start.dx + (knick.dx - start.dx) * t,
        start.dy + (knick.dy - start.dy) * t,
      );
    } else {
      pfad.lineTo(knick.dx, knick.dy);
      final t = ((gezeichnet - kurz) / lang).clamp(0.0, 1.0);
      pfad.lineTo(
        knick.dx + (ende.dx - knick.dx) * t,
        knick.dy + (ende.dy - knick.dy) * t,
      );
    }

    canvas.drawPath(
      pfad,
      Paint()
        ..color = farbe
        ..style = PaintingStyle.stroke
        // Dieselbe Strichstaerke wie die Lucide-Icons bei dieser Groesse.
        ..strokeWidth = size.width * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HakenMaler alt) =>
      alt.fortschritt != fortschritt || alt.farbe != farbe;
}
