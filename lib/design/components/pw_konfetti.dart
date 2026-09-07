// Kurze Konfetti-Geste in der Szenariokarte, wenn ein Szenario zum ersten Mal
// abgeschlossen wurde.
//
// ACHTUNG — bewusste Abweichung: DESIGN.md 1 und die Anforderung NF10
// schliessen Feier- und Belohnungsanimationen aus, weil ein abgeschlossenes
// Szenario keine Leistung ist, die belohnt wird. Diese Geste ist auf
// ausdruecklichen Wunsch ergaenzt und deshalb bewusst zurueckhaltend gehalten:
// einmalig je Szenario, knapp eine Sekunde, kleine Teilchen, kein Ton.
//
// Herausnehmen: in uebersicht_screen.dart das Feld `feiern` der Szenariokarte
// auf false setzen — dann faellt der ganze Zweig weg.
//
// Die Ampelfarben sind hier tabu: Gruen, Aprikot und Koralle in ihrer
// Signalbedeutung gehoeren allein der Einordnung von Situationsmerkmalen
// (DESIGN.md 1). Verwendet werden die Markenfarben der Drei-Bogen-Folge.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../pathwise_tokens.dart';
import '../pw_motion.dart';

class PwKonfetti extends StatefulWidget {
  const PwKonfetti({super.key, required this.onFertig});

  /// Wird einmal gerufen, wenn die Geste durch ist — auch dann, wenn sie
  /// wegen reduzierter Bewegung gar nicht erst laeuft.
  final VoidCallback onFertig;

  @override
  State<PwKonfetti> createState() => _PwKonfettiState();
}

class _PwKonfettiState extends State<PwKonfetti>
    with SingleTickerProviderStateMixin {
  static const _dauer = Duration(milliseconds: 1100);
  static const _anzahl = 16;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: _dauer);

  late final List<_Teilchen> _teilchen = _streuen();
  bool _gestartet = false;

  List<_Teilchen> _streuen() {
    // Fester Startwert: die Streuung sieht bei jedem Szenario gleich aus und
    // laesst sich in einem Golden-Bild festhalten.
    final zufall = math.Random(7);
    return [
      for (var i = 0; i < _anzahl; i++)
        _Teilchen(
          // Faecher nach oben, leicht nach links und rechts gestreut.
          winkel: -math.pi / 2 +
              (i / (_anzahl - 1) - 0.5) * 2.1 +
              (zufall.nextDouble() - 0.5) * 0.25,
          tempo: 46 + zufall.nextDouble() * 40,
          groesse: 3 + zufall.nextDouble() * 3,
          drehung: (zufall.nextDouble() - 0.5) * 5,
          farbe: _farben[i % _farben.length],
          verzoegerung: zufall.nextDouble() * 0.12,
        ),
    ];
  }

  static const _farben = [
    PwPalette.blue300,
    PwPalette.blue600,
    PwPalette.coral400,
    PwPalette.apricot400,
    PwPalette.blue500,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gestartet) return;
    _gestartet = true;

    if (!PwMotion.schleifenErlaubt(context)) {
      // Bei reduzierter Bewegung entfaellt die Geste ersatzlos.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFertig());
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) widget.onFertig();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PwMotion.schleifenErlaubt(context)) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _KonfettiMaler(teilchen: _teilchen, t: _c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Teilchen {
  const _Teilchen({
    required this.winkel,
    required this.tempo,
    required this.groesse,
    required this.drehung,
    required this.farbe,
    required this.verzoegerung,
  });

  final double winkel;
  final double tempo;
  final double groesse;
  final double drehung;
  final Color farbe;
  final double verzoegerung;
}

class _KonfettiMaler extends CustomPainter {
  const _KonfettiMaler({required this.teilchen, required this.t});

  final List<_Teilchen> teilchen;
  final double t;

  /// Fallbeschleunigung in dp je Fortschrittseinheit im Quadrat.
  static const _schwerkraft = 190.0;

  @override
  void paint(Canvas canvas, Size size) {
    final ursprung = Offset(size.width / 2, size.height * 0.58);
    final stift = Paint()..style = PaintingStyle.fill;

    for (final teil in teilchen) {
      final eigen = ((t - teil.verzoegerung) / (1 - teil.verzoegerung))
          .clamp(0.0, 1.0);
      if (eigen <= 0) continue;

      // Wurf mit Schwerkraft: erst auffaechern, dann absinken.
      final weg = PwCurve.out.transform(eigen);
      final pos = ursprung +
          Offset(
            math.cos(teil.winkel) * teil.tempo * weg,
            math.sin(teil.winkel) * teil.tempo * weg +
                _schwerkraft * eigen * eigen * 0.5,
          );

      // Die letzten 45 % blendet das Teilchen aus.
      final deckkraft = eigen < 0.55 ? 1.0 : 1 - (eigen - 0.55) / 0.45;
      stift.color = teil.farbe.withValues(alpha: deckkraft.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(teil.drehung * eigen);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: teil.groesse,
            height: teil.groesse * 1.6,
          ),
          const Radius.circular(1),
        ),
        stift,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_KonfettiMaler alt) => alt.t != t;
}
