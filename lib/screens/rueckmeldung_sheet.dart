// S8 — Rueckmeldungs-Sheet, DESIGN.md 7/S8, Motion M23.
//
// Label, Hinweis, Platzhalter und Zeilenzahl wechseln mit der gewaehlten Art.
// Nach dem Senden tauscht der Inhalt gegen die Bestaetigung; scheitert es,
// bleiben die Eingaben stehen und der Fehler steht unter dem Textfeld.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rueckmeldung_repository.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_field.dart';
import '../design/components/pw_haken.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_lottie.dart';
import '../design/components/pw_press_scale.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../design/pw_motion.dart';
import '../state/durchlauf_state.dart';

class RueckmeldungInhalt extends StatefulWidget {
  const RueckmeldungInhalt({super.key});

  @override
  State<RueckmeldungInhalt> createState() => _RueckmeldungInhaltState();
}

class _RueckmeldungInhaltState extends State<RueckmeldungInhalt> {
  final _text = TextEditingController();
  final _mail = TextEditingController();

  RueckmeldungArt _art = RueckmeldungArt.feedback;
  bool _sendet = false;
  bool _gesendet = false;
  String? _fehler;

  bool get _istSzenario => _art == RueckmeldungArt.szenario;

  @override
  void dispose() {
    _text.dispose();
    _mail.dispose();
    super.dispose();
  }

  Future<void> _senden() async {
    setState(() {
      _sendet = true;
      _fehler = null;
    });
    try {
      await const RueckmeldungRepository().senden(
        art: _art,
        text: _text.text,
        email: _mail.text,
      );
      if (!mounted) return;
      setState(() {
        _sendet = false;
        _gesendet = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sendet = false;
        _fehler = 'Das hat gerade nicht geklappt. Der Text bleibt stehen, '
            'versuch es später noch einmal.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // M23: Inhaltstausch mit translateY 14 -> 0 und Einblenden.
    return AnimatedSwitcher(
      duration: PwMotion.dauer(context, const Duration(milliseconds: 320)),
      switchInCurve: PwCurve.out,
      switchOutCurve: PwCurve.inn,
      transitionBuilder: (kind, anim) => FadeTransition(
        opacity: anim,
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, k) => Transform.translate(
            offset: Offset(0, kRevealShift * (1 - anim.value)),
            child: k,
          ),
          child: kind,
        ),
      ),
      child: _gesendet ? _bestaetigung(context) : _formular(context),
    );
  }

  Widget _bestaetigung(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('bestaetigung'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
            // In der Stufe "Verspielt" zeichnet sich der Haken selbst — eine
            // Quittung fuer eine Handlung, keine Belohnung. Liegt eine
            // Lottie-Datei bereit, hat die Vorrang.
            child: Consumer(
              builder: (ctx, ref, _) {
                final extras = ref.watch(durchlaufProvider
                    .select((s) => s.fortschritt.bewegung.zeigtExtras));
                return PwLottie(
                  stelle: PwLottieStelle.angekommen,
                  an: extras,
                  groesse: 30,
                  ersatz: extras
                      ? PwHaken(farbe: c.levelOk, groesse: 22)
                      : Icon(PwIcons.check, size: 20, color: c.levelOk),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Angekommen',
          textAlign: TextAlign.center,
          style: t.displaySmall?.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 10),
        Text(
          'Deine Rückmeldung wird gelesen und bearbeitet. Das geschieht von '
          'Hand, es kann also etwas dauern. Eine Antwort erhältst du nur, wenn '
          'du eine Adresse hinterlassen hast.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 18),
        PwButton(
          label: 'Schließen',
          vollBreite: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _formular(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;
    final leer = _text.text.trim().isEmpty;

    return Column(
      key: const ValueKey('formular'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Kachel(
          ikon: PwIcons.messageSquare,
          titel: 'Rückmeldung zur App',
          zusatz: 'Was unklar war, was fehlt, was gut funktioniert.',
          gewaehlt: !_istSzenario,
          onTap: () => setState(() => _art = RueckmeldungArt.feedback),
        ),
        const SizedBox(height: PwSpace.s4),
        _Kachel(
          ikon: PwIcons.plus,
          titel: 'Situation einschicken',
          zusatz: 'Eine Situation aus deinem Alltag, die als Szenario passen '
              'würde.',
          gewaehlt: _istSzenario,
          onTap: () => setState(() => _art = RueckmeldungArt.szenario),
        ),
        const SizedBox(height: PwSpace.gap),
        PwField(
          label: _istSzenario ? 'Die Situation' : 'Deine Rückmeldung',
          hinweis: _istSzenario
              ? 'Was ist passiert, wer war beteiligt, was hat die Situation '
                  'mehrdeutig gemacht?'
              : 'Zwei bis drei Sätze genügen.',
          fehler: _fehler,
          child: PwInput(
            controller: _text,
            zeilen: _istSzenario ? 6 : 4,
            aktiv: !_sendet,
            ungueltig: _fehler != null,
            platzhalter: _istSzenario
                ? 'Nach dem Training bleibt ein Kind allein in der Kabine '
                    'zurück …'
                : 'Mir ist aufgefallen, dass …',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        PwField(
          label: 'E-Mail, falls du eine Antwort möchtest',
          hinweis: 'Freiwillig. Ohne Adresse bleibt die Rückmeldung anonym.',
          child: PwInput(
            controller: _mail,
            aktiv: !_sendet,
            tastatur: TextInputType.emailAddress,
            platzhalter: 'name@verein.de',
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: c.surfaceTint,
            borderRadius: PwRadius.control,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(PwIcons.info, size: 14, color: c.iconOnTint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jede Rückmeldung wird gelesen und bearbeitet. Das geschieht '
                  'von Hand, es kann also etwas dauern. Bitte schreibe keine '
                  'echten Namen — eingeschickte Situationen werden vor der '
                  'Aufnahme ohnehin verfremdet.',
                  style: t.bodyMedium?.copyWith(color: c.textOnTintMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PwButton(
          label: 'Abschicken',
          variante: PwButtonVariante.accent,
          ikonDanach: PwIcons.arrowRight,
          vollBreite: true,
          laedt: _sendet,
          onPressed: leer ? null : _senden,
        ),
      ],
    );
  }
}

/// Auswahlkachel. Gewaehlt: surfaceTint mit Rand borderFocus (DESIGN.md 7/S8).
class _Kachel extends StatelessWidget {
  const _Kachel({
    required this.ikon,
    required this.titel,
    required this.zusatz,
    required this.gewaehlt,
    required this.onTap,
  });

  final IconData ikon;
  final String titel;
  final String zusatz;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: gewaehlt,
      label: '$titel. $zusatz',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: PwPressScale(
            child: AnimatedContainer(
              duration: PwMotion.dauer(context, PwDur.base),
              curve: PwCurve.standard,
              constraints: const BoxConstraints(minHeight: PwSize.touchMin),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: gewaehlt ? c.surfaceTint : c.surfacePage,
                borderRadius: PwRadius.control,
                border: Border.all(
                  color: gewaehlt ? c.borderFocus : c.borderSubtle,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      ikon,
                      size: 16,
                      color: gewaehlt ? c.iconOnTint : c.textFaint,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titel,
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          zusatz,
                          style: t.bodyMedium?.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
