// PwField / PwInput / PwTextarea — DESIGN.md 4.13.
//
// Unter dem Feld steht entweder ein Hinweis oder ein Fehler, nie beides.
// Kein Zeichenzaehler.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';

class PwField extends StatelessWidget {
  const PwField({
    super.key,
    required this.label,
    required this.child,
    this.pflicht = false,
    this.hinweis,
    this.fehler,
  });

  final String label;
  final Widget child;
  final bool pflicht;
  final String? hinweis;
  final String? fehler;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: c.textHeading,
            ),
            children: [
              if (pflicht)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: c.textAccent),
                ),
            ],
          ),
        ),
        const SizedBox(height: PwSpace.s3),
        child,
        // Entweder Hinweis oder Fehler — nie beides.
        if (fehler != null) ...[
          const SizedBox(height: PwSpace.s3),
          Text(
            fehler!,
            style: t.bodyMedium?.copyWith(color: c.statusDanger),
          ),
        ] else if (hinweis != null) ...[
          const SizedBox(height: PwSpace.s3),
          Text(hinweis!, style: t.bodyMedium?.copyWith(color: c.textMuted)),
        ],
      ],
    );
  }
}

class PwInput extends StatefulWidget {
  const PwInput({
    super.key,
    required this.controller,
    this.platzhalter,
    this.zeilen = 1,
    this.aktiv = true,
    this.ungueltig = false,
    this.tastatur,
    this.onChanged,
    this.onAbgeschickt,
    this.grossschreibung = false,
  });

  final TextEditingController controller;
  final String? platzhalter;

  /// 1 = Input. 4 (Rueckmeldung) bzw. 6 (Situation einschicken) = Textarea.
  final int zeilen;

  final bool aktiv;
  final bool ungueltig;
  final TextInputType? tastatur;
  final ValueChanged<String>? onChanged;

  /// Enter im einzeiligen Feld.
  final ValueChanged<String>? onAbgeschickt;

  /// Wandelt die Eingabe in Grossbuchstaben — fuer Codes, die so vergeben
  /// werden.
  final bool grossschreibung;

  @override
  State<PwInput> createState() => _PwInputState();
}

class _PwInputState extends State<PwInput> {
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

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    final rand = !widget.aktiv
        ? c.borderSubtle
        : widget.ungueltig
            ? c.statusDanger
            : _hatFokus
                ? c.borderFocus
                : c.borderDefault;

    return AnimatedContainer(
      duration: PwMotion.dauer(context, PwDur.fast),
      curve: PwCurve.standard,
      constraints: BoxConstraints(
        minHeight: widget.zeilen > 1 ? 0 : PwSize.controlMd,
      ),
      padding: const EdgeInsets.all(PwSpace.gapTight),
      decoration: BoxDecoration(
        color: widget.aktiv ? c.surfaceCard : c.surfaceSunken,
        borderRadius: PwRadius.control,
        border: Border.all(color: rand),
        // Im Fokus tritt der 3 dp Ring an die Stelle des Schattens.
        boxShadow: _hatFokus
            ? [BoxShadow(color: c.focusRing, spreadRadius: 3, blurRadius: 0)]
            : PwShadow.xs(context.isDark),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _fokus,
        enabled: widget.aktiv,
        minLines: widget.zeilen,
        maxLines: widget.zeilen,
        keyboardType: widget.tastatur ??
            (widget.zeilen > 1 ? TextInputType.multiline : TextInputType.text),
        onChanged: widget.onChanged,
        onSubmitted: widget.onAbgeschickt,
        textCapitalization: widget.grossschreibung
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
        inputFormatters: widget.grossschreibung
            ? [
                TextInputFormatter.withFunction(
                  (alt, neu) => neu.copyWith(text: neu.text.toUpperCase()),
                ),
              ]
            : null,
        style: t.bodyLarge?.copyWith(
          color: widget.aktiv ? c.textBody : c.actionDisabledText,
        ),
        cursorColor: c.textLink,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.platzhalter,
          hintStyle: t.bodyLarge?.copyWith(color: c.textFaint),
        ),
      ),
    );
  }
}
