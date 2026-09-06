// PwButton — DESIGN.md 4.1.
//
// Fuenf Varianten, drei Groessen, dazu die States default, hovered, pressed,
// focused, disabled und loading. Die Ripple ist global abgeschaltet
// (splashFactory: NoSplash); Bedienfeedback ist der Press-Scale aus M1.
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';
import 'pw_icons.dart';
import 'pw_press_scale.dart';

enum PwButtonVariante {
  /// Die eine handlungsleitende Aktion je Ansicht.
  accent,

  /// Zweitwichtiges, ausserhalb des Footers.
  primary,

  /// Nebenaktion ("Nochmal", "Antwort ändern").
  secondary,

  /// Textaktionen in Sheets.
  ghost,

  /// Aktion auf getoenter Flaeche.
  quiet,
}

enum PwButtonGroesse {
  sm(PwSize.controlSm, 12, 13),
  md(PwSize.controlMd, 18, 14),
  lg(PwSize.controlLg, 24, 15.5);

  const PwButtonGroesse(this.hoehe, this.polster, this.schrift);
  final double hoehe;
  final double polster;
  final double schrift;
}

class PwButton extends StatefulWidget {
  const PwButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variante = PwButtonVariante.secondary,
    this.groesse = PwButtonGroesse.md,
    this.ikon,
    this.ikonDanach,
    this.vollBreite = false,
    this.laedt = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PwButtonVariante variante;
  final PwButtonGroesse groesse;

  /// Fuehrungs-Icon, 16 dp. Im Zustand [laedt] tritt der Spinner an seine Stelle.
  final IconData? ikon;

  /// Folge-Icon, 16 dp.
  final IconData? ikonDanach;

  /// Im Footer immer true — dort gilt die Hoehe 48 (DESIGN.md 4.1).
  final bool vollBreite;

  final bool laedt;

  bool get _aus => onPressed == null || laedt;

  @override
  State<PwButton> createState() => _PwButtonState();
}

class _PwButtonState extends State<PwButton> {
  final FocusNode _fokus = FocusNode();
  bool _hatFokus = false;

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

  double get _hoehe =>
      widget.vollBreite ? PwSize.buttonFull : widget.groesse.hoehe;

  List<BoxShadow> _schatten(bool dunkel) {
    if (widget._aus) return const [];
    return switch (widget.variante) {
      PwButtonVariante.accent => PwShadow.accent(dunkel),
      PwButtonVariante.secondary => PwShadow.xs(dunkel),
      _ => const <BoxShadow>[],
    };
  }

  Color _flaeche(PwColors c, Set<WidgetState> s) {
    if (s.contains(WidgetState.disabled)) return c.actionDisabledBg;
    final gedrueckt = s.contains(WidgetState.pressed);
    final ueber = s.contains(WidgetState.hovered);
    return switch (widget.variante) {
      PwButtonVariante.accent => gedrueckt
          ? c.actionAccentActive
          : ueber
              ? c.actionAccentHover
              : c.actionAccent,
      PwButtonVariante.primary => gedrueckt
          ? c.actionPrimaryActive
          : ueber
              ? c.actionPrimaryHover
              : c.actionPrimary,
      PwButtonVariante.secondary =>
        gedrueckt ? c.surfaceSunken : c.surfaceCard,
      PwButtonVariante.ghost =>
        (gedrueckt || ueber) ? c.actionQuietHover : Colors.transparent,
      PwButtonVariante.quiet =>
        (gedrueckt || ueber) ? c.actionQuietHover : c.surfaceTint,
    };
  }

  Color _schriftfarbe(PwColors c, Set<WidgetState> s) {
    if (s.contains(WidgetState.disabled)) return c.actionDisabledText;
    return switch (widget.variante) {
      PwButtonVariante.accent || PwButtonVariante.primary => c.textInverse,
      PwButtonVariante.secondary => c.textHeading,
      PwButtonVariante.ghost => c.textLink,
      PwButtonVariante.quiet => c.textOnTintMuted,
    };
  }

  BorderSide _rand(PwColors c, Set<WidgetState> s) {
    if (s.contains(WidgetState.disabled)) {
      return const BorderSide(color: Colors.transparent);
    }
    if (_hatFokus) return BorderSide(color: c.borderFocus);
    return switch (widget.variante) {
      // Rand in Flaechenfarbe: der Button traegt keine sichtbare Kante.
      PwButtonVariante.accent ||
      PwButtonVariante.primary =>
        BorderSide(color: _flaeche(c, s)),
      PwButtonVariante.secondary => BorderSide(
          color:
              s.contains(WidgetState.hovered) ? c.borderStrong : c.borderDefault,
        ),
      PwButtonVariante.ghost ||
      PwButtonVariante.quiet =>
        const BorderSide(color: Colors.transparent),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    final stil = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, _hoehe)),
      // Kein fixedSize: der Button muss mit der Textskalierung wachsen
      // (DESIGN.md 7, Responsive-Regeln).
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: widget.groesse.polster),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: PwRadius.control),
      ),
      textStyle: WidgetStatePropertyAll(
        t.labelLarge!.copyWith(fontSize: widget.groesse.schrift),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((s) => _flaeche(c, s)),
      foregroundColor:
          WidgetStateProperty.resolveWith((s) => _schriftfarbe(c, s)),
      side: WidgetStateProperty.resolveWith((s) => _rand(c, s)),
      // Der Fokusring wird aussen gezeichnet, nicht als Overlay.
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      animationDuration: PwMotion.dauer(context, PwDur.fast),
      tapTargetSize: _hoehe >= PwSize.touchMin
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      alignment: Alignment.center,
    );

    return PwPressScale(
      aktiv: !widget._aus,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: PwRadius.control,
          boxShadow: [
            // Fokusring: 3 dp aussen, nie entfernen (DESIGN.md 4.1 und 9).
            if (_hatFokus)
              BoxShadow(color: c.focusRing, spreadRadius: 3, blurRadius: 0),
            ..._schatten(context.isDark),
          ],
        ),
        child: SizedBox(
          width: widget.vollBreite ? double.infinity : null,
          child: TextButton(
            focusNode: _fokus,
            onPressed: widget._aus ? null : widget.onPressed,
            style: stil,
            child: _Inhalt(
              label: widget.label,
              ikon: widget.ikon,
              ikonDanach: widget.ikonDanach,
              laedt: widget.laedt,
              vollBreite: widget.vollBreite,
            ),
          ),
        ),
      ),
    );
  }
}

class _Inhalt extends StatelessWidget {
  const _Inhalt({
    required this.label,
    required this.ikon,
    required this.ikonDanach,
    required this.laedt,
    required this.vollBreite,
  });

  final String label;
  final IconData? ikon;
  final IconData? ikonDanach;
  final bool laedt;
  final bool vollBreite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: vollBreite ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Der Spinner tritt an die Stelle des Fuehrungs-Icons, das Label bleibt
        // stehen (DESIGN.md 4.1, State loading).
        if (laedt)
          const PwSpinner(groesse: 16)
        else if (ikon != null)
          Icon(ikon, size: 16),
        if (laedt || ikon != null) const SizedBox(width: PwSpace.s4),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (ikonDanach != null) ...[
          const SizedBox(width: PwSpace.s4),
          Icon(ikonDanach, size: 16),
        ],
      ],
    );
  }
}

/// Motion M24: Spinner-Rotation, 900 ms, linear, endlos.
class PwSpinner extends StatefulWidget {
  const PwSpinner({super.key, this.groesse = 16});

  final double groesse;

  @override
  State<PwSpinner> createState() => _PwSpinnerState();
}

class _PwSpinnerState extends State<PwSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: PwDur.ambient);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bei reduzierter Bewegung laeuft die Dauerschleife gar nicht erst an.
    if (PwMotion.schleifenErlaubt(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _c,
        child: Icon(PwIcons.loaderCircle, size: widget.groesse),
      );
}
