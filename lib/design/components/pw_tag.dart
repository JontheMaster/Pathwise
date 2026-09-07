// PwTag / Themenfeld-Chip — DESIGN.md 4.4.
//
// Eigenes GestureDetector + AnimatedContainer statt FilterChip: der Farbwechsel
// trifft so exakt, und die Chip-Chrome von Material entfaellt.
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';
import 'pw_icons.dart';

class PwTag extends StatefulWidget {
  const PwTag({
    super.key,
    required this.label,
    this.gewaehlt = false,
    this.onTap,
    this.onEntfernen,
  });

  final String label;
  final bool gewaehlt;
  final VoidCallback? onTap;

  /// Zeigt ein kleines x zum Entfernen (13 dp).
  final VoidCallback? onEntfernen;

  @override
  State<PwTag> createState() => _PwTagState();
}

class _PwTagState extends State<PwTag> {
  bool _darueber = false;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final klickbar = widget.onTap != null;

    final flaeche = widget.gewaehlt
        ? c.iconOnTint
        : (klickbar && _darueber)
            ? c.actionQuietHover
            : c.surfaceCard;
    final schrift = widget.gewaehlt ? c.textInverse : c.iconOnTint;

    final pille = AnimatedContainer(
      duration: PwMotion.dauer(context, PwDur.fast),
      curve: PwCurve.standard,
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: PwSpace.s5),
      decoration: BoxDecoration(
        color: flaeche,
        borderRadius: BorderRadius.circular(PwRadius.pill),
        border: Border.all(
          color: widget.gewaehlt ? flaeche : c.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flexible, damit lange Themenfeldnamen in der Pille umbrechen statt
          // ueberzulaufen. Voraussetzung: PwTag steht in einem Kontext mit
          // begrenzter Breite — in der App immer ein Wrap.
          Flexible(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: schrift,
              ),
            ),
          ),
          if (widget.onEntfernen != null) ...[
            const SizedBox(width: PwSpace.s3),
            GestureDetector(
              onTap: widget.onEntfernen,
              child: Icon(PwIcons.x, size: 13, color: schrift),
            ),
          ],
        ],
      ),
    );

    if (!klickbar) return pille;

    return Semantics(
      button: true,
      selected: widget.gewaehlt,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _darueber = true),
        onExit: (_) => setState(() => _darueber = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          // Trefferflaeche mindestens 44 dp hoch, auch wenn die Pille 28 misst.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PwSize.touchMin),
            child: Center(widthFactor: 1, child: pille),
          ),
        ),
      ),
    );
  }
}
