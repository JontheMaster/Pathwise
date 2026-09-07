// S3 — Entscheidungspunkt, DESIGN.md 7/S3, Motion M6, M7, M9, M12.
//
// Die drei Entscheidungspunkte sind *eine* Route mit einem AnimatedSwitcher
// ueber den Punktinhalt. Kopfzeile, Schrittanzeige und Fusszeile bleiben
// stehen und wechseln nicht mit (DESIGN.md 6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/components/pw_button.dart';
import '../design/components/pw_decision_point.dart';
import '../design/components/pw_feedback_panel.dart';
import '../design/components/pw_icon_button.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_label.dart';
import '../design/components/pw_step_indicator.dart';
import '../design/pathwise_routes.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../design/pw_motion.dart';
import '../state/durchlauf_state.dart';
import 'auswertung_screen.dart';
import 'einstieg_screen.dart';
import 'overlays.dart';
import 'pw_scaffold.dart';

/// Mikro-Label ueber dem Punkttext (PathwiseApp.dc.html Z. 830).
const _punktLabel = [
  'Was gerade passiert',
  'Wie es weitergeht',
  'Was danach geschieht',
];

class PunktScreen extends ConsumerStatefulWidget {
  const PunktScreen({
    super.key,
    required this.szenarioId,
    required this.startPunkt,
  });

  final String szenarioId;
  final int startPunkt;

  @override
  ConsumerState<PunktScreen> createState() => _PunktScreenState();
}

class _PunktScreenState extends ConsumerState<PunktScreen> {
  late int _punkt = widget.startPunkt;
  bool _situationOffen = false;
  bool _einordnungOffen = false;
  bool _vorwaerts = true;

  void _zuPunkt(int neu) {
    setState(() {
      _vorwaerts = neu > _punkt;
      _punkt = neu;
      // Die Einordnung ist bei jedem neuen Punkt wieder zu.
      _einordnungOffen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(durchlaufProvider);
    final sz = s.inhalt.szenarien.firstWhere((x) => x.id == widget.szenarioId);
    final punkt = sz.punkte[_punkt];
    final gewaehlt = s.fortschritt.wahl(sz.id, _punkt);
    final letzter = _punkt == sz.punkte.length - 1;

    return PwScaffold(
      titel: sz.titel,
      zaehler: '${_punkt + 1}/${sz.punkte.length}',
      onZurueck: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onEinstellungen: () => einstellungenOeffnen(context),
      onSzenarioOeffnen: (ziel) => szenarioOeffnen(context, ref, ziel),
      aktionen: [
        _Fussaktionen(
          weiterLabel: letzter ? 'Auswertung' : 'Weiter',
          weiterAus: gewaehlt == null,
          onAendern: gewaehlt == null
              ? null
              : () {
                  ref
                      .read(durchlaufProvider.notifier)
                      .wahlLoeschen(sz, _punkt);
                  setState(() => _einordnungOffen = false);
                },
          onWeiter: gewaehlt == null
              ? null
              : () {
                  if (letzter) {
                    // M12 verhaelt sich wie M6 vorwaerts.
                    Navigator.of(context).push(
                      pwRoute(
                        AuswertungScreen(szenarioId: sz.id),
                        PwTransition.vor,
                      ),
                    );
                  } else {
                    _zuPunkt(_punkt + 1);
                  }
                },
        ),
      ],
      inhalt: [
        // Die Schrittanzeige bleibt stehen und wechselt nicht mit.
        Row(
          children: [
            if (_punkt > 0) ...[
              PwIconButton(
                ikon: PwIcons.chevronLeft,
                label: 'Vorheriger Entscheidungspunkt',
                onPressed: () => _zuPunkt(_punkt - 1),
              ),
              const SizedBox(width: PwSpace.s3),
            ],
            Flexible(
              child: PwStepIndicator(
                gesamt: sz.punkte.length,
                aktuell: _punkt + 1,
              ),
            ),
          ],
        ),
        // M6: vorwaerts translateX +16 -> 0, zurueck -16 -> 0, je mit Fade.
        AnimatedSwitcher(
          duration: PwMotion.dauer(context, const Duration(milliseconds: 260)),
          switchInCurve: PwCurve.out,
          switchOutCurve: PwCurve.inn,
          layoutBuilder: (aktuell, vorherige) => Stack(
            alignment: Alignment.topCenter,
            children: [...vorherige, ?aktuell],
          ),
          transitionBuilder: (kind, anim) => FadeTransition(
            opacity: anim,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, k) => Transform.translate(
                offset: Offset((_vorwaerts ? 16 : -16) * (1 - anim.value), 0),
                child: k,
              ),
              child: kind,
            ),
          ),
          child: Column(
            key: ValueKey('${sz.id}:$_punkt'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SituationNachlesen(
                offen: _situationOffen,
                titel: sz.titel,
                ausgangssituation: sz.ausgangssituation,
                vorgeschichte: sz.vorgeschichte,
                onUmschalten: () =>
                    setState(() => _situationOffen = !_situationOffen),
              ),
              const SizedBox(height: PwSpace.gap),
              _Punkttext(
                label: _punktLabel[_punkt.clamp(0, _punktLabel.length - 1)],
                text: punkt.text,
              ),
              const SizedBox(height: PwSpace.gap),
              PwDecisionPoint(
                leitfrage: punkt.leitfrage,
                optionen: punkt.optionen,
                gewaehlt: gewaehlt,
                onWaehlen: (id) {
                  ref
                      .read(durchlaufProvider.notifier)
                      .waehlen(sz, _punkt, id);
                  setState(() => _einordnungOffen = false);
                },
              ),
              const SizedBox(height: PwSpace.gap),
              if (gewaehlt != null)
                PwFeedbackPanel(
                  offen: _einordnungOffen,
                  onUmschalten: (auf) =>
                      setState(() => _einordnungOffen = auf),
                  erkennen: punkt.erkennen,
                  absichern: punkt.absichern,
                  handeln: punkt.handeln,
                )
              else
                Text(
                  'Eine fachliche Einordnung erscheint, sobald du dich '
                  'entschieden hast.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.pw.textFaint),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aufklappfeld "Situation nachlesen" — Motion M9.
class _SituationNachlesen extends StatelessWidget {
  const _SituationNachlesen({
    required this.offen,
    required this.titel,
    required this.ausgangssituation,
    required this.vorgeschichte,
    required this.onUmschalten,
  });

  final bool offen;
  final String titel;
  final String ausgangssituation;
  final String vorgeschichte;
  final VoidCallback onUmschalten;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: PwRadius.card,
        border: Border.all(color: c.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            expanded: offen,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onUmschalten,
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: PwSize.touchMin),
                  padding: const EdgeInsets.symmetric(
                    horizontal: PwSpace.gap,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(PwIcons.fileText, size: 16, color: c.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Situation nachlesen',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: c.textHeading,
                          ),
                        ),
                      ),
                      // Der Chevron dreht sich um 180 Grad (M9).
                      AnimatedRotation(
                        turns: offen ? 0.5 : 0,
                        duration: PwMotion.dauer(
                          context,
                          const Duration(milliseconds: 240),
                        ),
                        curve: PwCurve.out,
                        child: Icon(
                          PwIcons.chevronDown,
                          size: 16,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration:
                PwMotion.dauer(context, const Duration(milliseconds: 240)),
            curve: PwCurve.out,
            alignment: Alignment.topCenter,
            child: offen
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      PwSpace.gap,
                      14,
                      PwSpace.gap,
                      PwSpace.gap,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.borderSubtle)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PwLabel(titel),
                        const SizedBox(height: PwSpace.s4),
                        Text(ausgangssituation, style: t.bodyLarge),
                        const SizedBox(height: PwSpace.gapTight),
                        const PwLabel('Vorgeschichte'),
                        const SizedBox(height: PwSpace.s4),
                        Text(
                          vorgeschichte,
                          style: t.bodyMedium?.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Punkttext extends StatelessWidget {
  const _Punkttext({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(PwSpace.cardPad),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: PwRadius.card,
        border: Border.all(color: c.borderSubtle),
        boxShadow: PwShadow.sm(context.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(PwIcons.cornerDownRight, size: 14, color: c.textFaint),
              const SizedBox(width: 7),
              Flexible(child: PwLabel(label)),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: t.bodyLarge),
        ],
      ),
    );
  }
}

/// "Antwort ändern" (Flex 1) und "Weiter" (Flex 1.2). Unter 360 dp stehen die
/// beiden untereinander, "Weiter" oben (DESIGN.md 7/S3).
class _Fussaktionen extends StatelessWidget {
  const _Fussaktionen({
    required this.weiterLabel,
    required this.weiterAus,
    required this.onAendern,
    required this.onWeiter,
  });

  final String weiterLabel;
  final bool weiterAus;
  final VoidCallback? onAendern;
  final VoidCallback? onWeiter;

  @override
  Widget build(BuildContext context) {
    final aendern = PwButton(
      label: 'Antwort ändern',
      ikon: PwIcons.rotateCcw,
      vollBreite: true,
      onPressed: onAendern,
    );
    final weiter = PwButton(
      label: weiterLabel,
      variante: PwButtonVariante.accent,
      ikonDanach: PwIcons.arrowRight,
      vollBreite: true,
      onPressed: weiterAus ? null : onWeiter,
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (MediaQuery.sizeOf(ctx).width < kEngAb) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [weiter, const SizedBox(height: 10), aendern],
          );
        }
        return Row(
          children: [
            Expanded(flex: 10, child: aendern),
            const SizedBox(width: 10),
            Expanded(flex: 12, child: weiter),
          ],
        );
      },
    );
  }
}
