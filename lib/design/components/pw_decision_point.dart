// PwDecisionPoint — DESIGN.md 4.7.
//
// Leitfrage und genau drei Handlungsoptionen. Nie Ampelfarben, nie Haekchen
// oder Kreuz als Wertung, nie eine Reihenfolge nach "Guete": keine der
// Moeglichkeiten ist richtig oder falsch (DESIGN.md 1).
import 'package:flutter/material.dart';

import '../../data/szenario_modelle.dart';
import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';
import 'pw_icons.dart';
import 'pw_press_scale.dart';

class PwDecisionPoint extends StatelessWidget {
  const PwDecisionPoint({
    super.key,
    required this.leitfrage,
    required this.optionen,
    required this.gewaehlt,
    required this.onWaehlen,
  });

  final String leitfrage;
  final List<PwOption> optionen;
  final String? gewaehlt;
  final ValueChanged<String> onWaehlen;

  static const _buchstaben = ['A', 'B', 'C'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(leitfrage, style: t.titleSmall),
        const SizedBox(height: PwSpace.gapTight),
        for (var i = 0; i < optionen.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _Option(
            option: optionen[i],
            buchstabe: _buchstaben[i % _buchstaben.length],
            gewaehlt: gewaehlt == optionen[i].id,
            eineWahlSteht: gewaehlt != null,
            onTap: () => onWaehlen(optionen[i].id),
          ),
        ],
      ],
    );
  }
}

class _Option extends StatefulWidget {
  const _Option({
    required this.option,
    required this.buchstabe,
    required this.gewaehlt,
    required this.eineWahlSteht,
    required this.onTap,
  });

  final PwOption option;
  final String buchstabe;
  final bool gewaehlt;
  final bool eineWahlSteht;
  final VoidCallback onTap;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  bool _darueber = false;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    // Nach der Wahl sind die uebrigen Optionen nicht mehr tippbar.
    final tippbar = !widget.eineWahlSteht;
    final verblasst = widget.eineWahlSteht && !widget.gewaehlt;

    final randfarbe = widget.gewaehlt
        ? PwPalette.blue600
        : (tippbar && _darueber)
            ? c.borderStrong
            : c.borderDefault;

    final karte = AnimatedContainer(
      duration: PwMotion.dauer(context, PwDur.base),
      curve: PwCurve.standard,
      constraints: const BoxConstraints(minHeight: PwSize.touchMin),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: widget.gewaehlt ? c.surfaceTint : c.surfaceCard,
        borderRadius: PwRadius.control,
        border: Border.all(color: randfarbe),
        boxShadow: widget.gewaehlt ? const [] : PwShadow.xs(context.isDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Kreis(gewaehlt: widget.gewaehlt, buchstabe: widget.buchstabe),
          const SizedBox(width: PwSpace.gapTight),
          Expanded(
            child: Text(
              widget.option.text,
              style: t.bodyLarge?.copyWith(
                color: widget.gewaehlt ? c.textOnTint : c.textBody,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: widget.gewaehlt,
      enabled: tippbar,
      label: '${widget.buchstabe}: ${widget.option.text}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: tippbar ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _darueber = true),
        onExit: (_) => setState(() => _darueber = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tippbar ? widget.onTap : null,
          child: PwPressScale(
            aktiv: tippbar,
            child: AnimatedOpacity(
              opacity: verblasst ? 0.55 : 1.0,
              duration: PwMotion.dauer(context, PwDur.base),
              curve: PwCurve.standard,
              child: karte,
            ),
          ),
        ),
      ),
    );
  }
}

class _Kreis extends StatelessWidget {
  const _Kreis({required this.gewaehlt, required this.buchstabe});

  final bool gewaehlt;
  final String buchstabe;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    return AnimatedContainer(
      duration: PwMotion.dauer(context, PwDur.base),
      curve: PwCurve.standard,
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gewaehlt ? c.actionPrimary : Colors.transparent,
        border: Border.all(
          color: gewaehlt ? c.actionPrimary : c.borderDefault,
        ),
      ),
      child: gewaehlt
          ? Icon(PwIcons.check, size: 13, color: c.textInverse)
          : Text(
              buchstabe,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: c.textMuted, letterSpacing: 0),
            ),
    );
  }
}
