// PwFeedbackPanel — DESIGN.md 4.8, Motion M7 und M8.
//
// Eigenes Widget statt ExpansionTile: dessen Chrome und Ripple passen nicht.
// Das Panel ist immer zu, bis es abgerufen wird — die fachliche Einordnung
// kommt auf Abruf, nicht ungefragt.
import 'dart:async';

import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';
import 'pw_icons.dart';
import 'pw_label.dart';

class PwFeedbackPanel extends StatefulWidget {
  const PwFeedbackPanel({
    super.key,
    required this.offen,
    required this.onUmschalten,
    required this.erkennen,
    required this.absichern,
    required this.handeln,
  });

  final bool offen;
  final ValueChanged<bool> onUmschalten;
  final String erkennen;
  final String absichern;
  final String handeln;

  @override
  State<PwFeedbackPanel> createState() => _PwFeedbackPanelState();
}

class _PwFeedbackPanelState extends State<PwFeedbackPanel>
    with SingleTickerProviderStateMixin {
  // M7: Ring um das Panel, 4 Zyklen a 2,6 s, Start nach 600 ms.
  static const _zyklus = Duration(milliseconds: 2600);
  static const _verzoegerung = Duration(milliseconds: 600);
  static const _zyklen = 4;

  late final AnimationController _puls =
      AnimationController(vsync: this, duration: _zyklus);
  Timer? _start;
  int _gelaufen = 0;

  @override
  void initState() {
    super.initState();
    _puls.addStatusListener(_zyklusEnde);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulsPruefen();
  }

  @override
  void didUpdateWidget(PwFeedbackPanel alt) {
    super.didUpdateWidget(alt);
    if (widget.offen != alt.offen) _pulsPruefen();
  }

  void _pulsPruefen() {
    // Der Hinweis gilt nur, solange das Panel zu ist.
    if (widget.offen || !PwMotion.schleifenErlaubt(context)) {
      _start?.cancel();
      _puls.stop();
      _puls.value = 0;
      return;
    }
    if (_start != null || _puls.isAnimating || _gelaufen >= _zyklen) return;
    _start = Timer(_verzoegerung, () {
      if (mounted && !widget.offen) _puls.forward(from: 0);
    });
  }

  void _zyklusEnde(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    _gelaufen++;
    if (_gelaufen < _zyklen && !widget.offen && mounted) {
      _puls.forward(from: 0);
    } else {
      _puls.value = 0;
    }
  }

  @override
  void dispose() {
    _start?.cancel();
    _puls.removeStatusListener(_zyklusEnde);
    _puls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pw;

    final panel = Container(
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: PwRadius.card,
        border: Border.all(
          color: context.isDark ? c.borderSubtle : PwPalette.blue200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Kopf(offen: widget.offen, onTap: () => widget.onUmschalten(!widget.offen)),
          // M8: Hoehe animiert, der Inhalt kommt mit translateY -6 -> 0.
          AnimatedSize(
            duration: PwMotion.dauer(
              context,
              widget.offen
                  ? const Duration(milliseconds: 260)
                  : const Duration(milliseconds: 220),
            ),
            curve: PwCurve.out,
            alignment: Alignment.topCenter,
            child: widget.offen
                ? _Inhalt(
                    erkennen: widget.erkennen,
                    absichern: widget.absichern,
                    handeln: widget.handeln,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _puls,
      builder: (_, kind) {
        // 0 -> 5 dp und zurueck, ein Sinusbogen je Zyklus.
        final t = Curves.easeInOut.transform(
          _puls.value <= .5 ? _puls.value * 2 : (1 - _puls.value) * 2,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: PwRadius.card,
            boxShadow: t <= 0
                ? const []
                : [
                    BoxShadow(
                      color: c.textLink.withValues(alpha: 0.34 * t),
                      spreadRadius: 5 * t,
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: kind,
        );
      },
      child: panel,
    );
  }
}

class _Kopf extends StatelessWidget {
  const _Kopf({required this.offen, required this.onTap});

  final bool offen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    return Semantics(
      button: true,
      expanded: offen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            constraints: const BoxConstraints(minHeight: PwSize.touchMin),
            padding:
                const EdgeInsets.symmetric(horizontal: PwSpace.s6, vertical: 12),
            child: Row(
              children: [
                Icon(PwIcons.bookOpen, size: 16, color: c.iconOnTint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    offen
                        ? 'Fachliche Einordnung ausblenden'
                        : 'Fachliche Einordnung anzeigen',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: c.textOnTintMuted,
                    ),
                  ),
                ),
                Icon(
                  offen ? PwIcons.chevronUp : PwIcons.chevronDown,
                  size: 16,
                  color: c.iconOnTint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Inhalt extends StatelessWidget {
  const _Inhalt({
    required this.erkennen,
    required this.absichern,
    required this.handeln,
  });

  final String erkennen;
  final String absichern;
  final String handeln;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    // Feste Reihenfolge: Erkennen, Absichern, Handeln.
    final bloecke = <_BlockDaten>[
      _BlockDaten('Erkennen', PwIcons.eye, c.feedbackErkennen, erkennen),
      _BlockDaten('Absichern', PwIcons.shield, c.feedbackAbsichern, absichern),
      _BlockDaten('Handeln', PwIcons.footprints, c.feedbackHandeln, handeln),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: PwMotion.dauer(context, const Duration(milliseconds: 260)),
      curve: PwCurve.out,
      builder: (_, v, kind) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, -6 * (1 - v)), child: kind),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PwSpace.s6,
          0,
          PwSpace.s6,
          PwSpace.s6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < bloecke.length; i++) ...[
              if (i > 0) const SizedBox(height: PwSpace.gap),
              _Block(daten: bloecke[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlockDaten {
  const _BlockDaten(this.label, this.ikon, this.farbe, this.text);
  final String label;
  final IconData ikon;
  final Color farbe;
  final String text;
}

class _Block extends StatelessWidget {
  const _Block({required this.daten});

  final _BlockDaten daten;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.surfaceCard, shape: BoxShape.circle),
          child: Icon(daten.ikon, size: 15, color: daten.farbe),
        ),
        const SizedBox(width: PwSpace.gapTight),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PwLabel(daten.label, farbe: daten.farbe),
              const SizedBox(height: PwSpace.s3),
              Text(
                daten.text,
                style: t.bodyLarge?.copyWith(color: c.textOnTint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
