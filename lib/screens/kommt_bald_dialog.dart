// S9 — "Kommt bald"-Dialog, DESIGN.md 7/S9, Motion M16 bis M19.
//
// Die drei Dauerschleifen M17 (Ringe), M18 (Icon-Atmen) und M19 (Punkte)
// laufen bei reduzierter Bewegung gar nicht erst an (DESIGN.md 5).
import 'package:flutter/material.dart';

import '../data/szenario_modelle.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_label.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../design/pw_motion.dart';

class KommtBaldInhalt extends StatelessWidget {
  const KommtBaldInhalt({super.key, required this.modul});

  final PwModul modul;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _Ringe(ikon: PwIcons.ausName(modul.ikon))),
        const SizedBox(height: PwSpace.s7),
        Center(child: PwLabel(modul.titel)),
        const SizedBox(height: 10),
        Text(
          'Kommt bald',
          textAlign: TextAlign.center,
          style: t.displaySmall?.copyWith(fontSize: 25),
        ),
        const SizedBox(height: 10),
        Text(
          '${modul.text} Der Bereich wird als eigenes Modul ergänzt — deine '
          'bisherigen Szenarien bleiben dabei unverändert.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 18),
        const Center(child: _Punkte()),
        const SizedBox(height: PwSpace.s7),
        PwButton(
          label: 'Zurück zur Übersicht',
          vollBreite: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

/// M17: drei Ringe, scale 0.6 -> 1.9, Deckkraft 0.55 -> 0, Versatz 0/0.9/1.8 s.
/// M18: das Icon atmet, scale 1 -> 1.06 -> 1 ueber 3,4 s.
class _Ringe extends StatefulWidget {
  const _Ringe({required this.ikon});

  final IconData ikon;

  @override
  State<_Ringe> createState() => _RingeState();
}

class _RingeState extends State<_Ringe> with TickerProviderStateMixin {
  late final AnimationController _ringe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _atem = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  static const _versatz = [0.0, 0.9 / 2.6, 1.8 / 2.6];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PwMotion.schleifenErlaubt(context)) {
      if (!_ringe.isAnimating) _ringe.repeat();
      if (!_atem.isAnimating) _atem.repeat();
    } else {
      _ringe.stop();
      _atem.stop();
      _ringe.value = 0;
      _atem.value = 0;
    }
  }

  @override
  void dispose() {
    _ringe.dispose();
    _atem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final laeuft = PwMotion.schleifenErlaubt(context);

    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (laeuft)
            for (final v in _versatz)
              AnimatedBuilder(
                animation: _ringe,
                builder: (_, _) {
                  final p = (_ringe.value + v) % 1.0;
                  final e = PwCurve.out.transform(p);
                  // Ab 70 % ist der Ring verschwunden.
                  final deckkraft = p >= 0.7 ? 0.0 : 0.55 * (1 - p / 0.7);
                  return Opacity(
                    opacity: deckkraft,
                    child: Transform.scale(
                      scale: 0.6 + (1.9 - 0.6) * e,
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.textLink),
                        ),
                      ),
                    ),
                  );
                },
              ),
          AnimatedBuilder(
            animation: _atem,
            builder: (_, kind) {
              final t = laeuft
                  ? (_atem.value <= .5 ? _atem.value * 2 : (1 - _atem.value) * 2)
                  : 0.0;
              return Transform.scale(
                scale: 1 + 0.06 * PwCurve.gentle.transform(t),
                child: kind,
              );
            },
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.ikon, size: 20, color: c.iconOnTint),
            ),
          ),
        ],
      ),
    );
  }
}

/// M19: drei Punkte, Deckkraft 0.25 -> 1 -> 0.25, Versatz 0/0.2/0.4 s.
class _Punkte extends StatefulWidget {
  const _Punkte();

  @override
  State<_Punkte> createState() => _PunkteState();
}

class _PunkteState extends State<_Punkte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  static const _versatz = [0.0, 0.2 / 1.4, 0.4 / 1.4];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PwMotion.schleifenErlaubt(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final laeuft = PwMotion.schleifenErlaubt(context);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: PwSpace.s3),
            Opacity(
              opacity: laeuft ? _deckkraft((_c.value + _versatz[i]) % 1.0) : 0.25,
              child: Container(
                width: 5,
                height: 5,
                decoration:
                    BoxDecoration(color: c.textLink, shape: BoxShape.circle),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 0.25 bis 80 %, Spitze 1.0 bei 40 %.
  double _deckkraft(double p) {
    if (p >= 0.8) return 0.25;
    final t = p <= 0.4 ? p / 0.4 : (0.8 - p) / 0.4;
    return 0.25 + 0.75 * Curves.easeInOut.transform(t.clamp(0.0, 1.0));
  }
}
