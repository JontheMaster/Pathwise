// PwIconButton — DESIGN.md 4.2.
//
// Quadrat 30/38/46 dp, Icon 15/18/20. Wichtig: trotz 30 dp Kantenlaenge
// bekommt `sm` eine 44 dp grosse Trefferflaeche. Immer mit Tooltip und
// Semantik-Label.
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';
import 'pw_press_scale.dart';

enum PwIconButtonVariante { ghost, secondary, primary }

enum PwIconButtonGroesse {
  sm(PwSize.controlSm, 15),
  md(PwSize.controlMd, 18),
  lg(PwSize.controlLg, 20);

  const PwIconButtonGroesse(this.kante, this.ikon);
  final double kante;
  final double ikon;
}

class PwIconButton extends StatefulWidget {
  const PwIconButton({
    super.key,
    required this.ikon,
    required this.label,
    this.onPressed,
    this.variante = PwIconButtonVariante.ghost,
    this.groesse = PwIconButtonGroesse.sm,
  });

  final IconData ikon;

  /// Dient zugleich als Tooltip und als Semantik-Label (DESIGN.md 4.2).
  final String label;

  final VoidCallback? onPressed;
  final PwIconButtonVariante variante;
  final PwIconButtonGroesse groesse;

  @override
  State<PwIconButton> createState() => _PwIconButtonState();
}

class _PwIconButtonState extends State<PwIconButton> {
  final FocusNode _fokus = FocusNode();
  bool _hatFokus = false;
  bool _darueber = false;

  @override
  void initState() {
    super.initState();
    _fokus.addListener(_fokusGeaendert);
  }

  void _fokusGeaendert() {
    if (_hatFokus != _fokus.hasFocus) {
      setState(() => _hatFokus = _fokus.hasFocus);
    }
  }

  @override
  void dispose() {
    _fokus.removeListener(_fokusGeaendert);
    _fokus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final aus = widget.onPressed == null;

    final flaeche = aus
        ? Colors.transparent
        : _darueber
            ? c.actionQuietHover
            : switch (widget.variante) {
                PwIconButtonVariante.ghost => Colors.transparent,
                PwIconButtonVariante.secondary => c.surfaceCard,
                PwIconButtonVariante.primary => c.actionPrimary,
              };

    final ikonfarbe = aus
        ? c.actionDisabledText
        : _darueber
            ? c.textOnTintMuted
            : switch (widget.variante) {
                PwIconButtonVariante.ghost ||
                PwIconButtonVariante.secondary =>
                  c.textMuted,
                PwIconButtonVariante.primary => c.textInverse,
              };

    final rand = switch (widget.variante) {
      PwIconButtonVariante.secondary => BorderSide(color: c.borderDefault),
      _ => BorderSide.none,
    };

    final flaechenTeil = AnimatedContainer(
      duration: PwMotion.dauer(context, PwDur.fast),
      curve: PwCurve.standard,
      width: widget.groesse.kante,
      height: widget.groesse.kante,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: flaeche,
        borderRadius: PwRadius.control,
        border: rand == BorderSide.none ? null : Border.fromBorderSide(rand),
        boxShadow: [
          if (_hatFokus)
            BoxShadow(color: c.focusRing, spreadRadius: 3, blurRadius: 0),
        ],
      ),
      child: Icon(widget.ikon, size: widget.groesse.ikon, color: ikonfarbe),
    );

    return Semantics(
      button: true,
      enabled: !aus,
      label: widget.label,
      child: Tooltip(
        message: widget.label,
        child: Focus(
          focusNode: _fokus,
          canRequestFocus: !aus,
          child: MouseRegion(
            cursor: aus ? SystemMouseCursors.basic : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _darueber = true),
            onExit: (_) => setState(() => _darueber = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: aus ? null : widget.onPressed,
              child: PwPressScale(
                aktiv: !aus,
                // Die Trefferflaeche ist mindestens 44 dp, auch wenn das
                // Quadrat kleiner aussieht (DESIGN.md 4.2 und 9).
                child: SizedBox(
                  width: widget.groesse.kante < PwSize.touchMin
                      ? PwSize.touchMin
                      : widget.groesse.kante,
                  height: widget.groesse.kante < PwSize.touchMin
                      ? PwSize.touchMin
                      : widget.groesse.kante,
                  child: Center(child: flaechenTeil),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
