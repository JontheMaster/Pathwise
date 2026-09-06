// S4 — Auswertung, DESIGN.md 7/S4, Motion M21 und M22.
//
// Eingeordnet wird die Situation, nicht die Entscheidung: die Ampelstufen
// gehoeren den Merkmalen, der Spiegel zeigt Verteilung statt Bewertung.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/spiegel_repository.dart';
import '../data/szenario_modelle.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_card.dart';
import '../design/components/pw_contact_list.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_label.dart';
import '../design/components/pw_level_list.dart';
import '../design/components/pw_mirror_bar.dart';
import '../design/pathwise_routes.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../design/pw_motion.dart';
import '../state/durchlauf_state.dart';
import 'einstieg_screen.dart';
import 'overlays.dart';
import 'pw_scaffold.dart';

/// Ab dieser *Inhaltsbreite* stehen die drei Ampelstufen nebeneinander.
/// Massgeblich ist der Inhaltsbereich, nicht das Fenster — im Zweispalten-
/// Layout ist die Seitenleiste schon abgezogen (DESIGN.md 7/S4).
const double _kAmpelDreispaltigAb = 900;

class AuswertungScreen extends ConsumerStatefulWidget {
  const AuswertungScreen({super.key, required this.szenarioId});

  final String szenarioId;

  @override
  ConsumerState<AuswertungScreen> createState() => _AuswertungScreenState();
}

class _AuswertungScreenState extends ConsumerState<AuswertungScreen> {
  SpiegelDaten _spiegel = SpiegelDaten.laedt;
  int? _offenerSpiegel;

  @override
  void initState() {
    super.initState();
    _spiegelLaden();
  }

  Future<void> _spiegelLaden() async {
    final daten =
        await ref.read(spiegelRepositoryProvider).laden(widget.szenarioId);
    if (mounted) setState(() => _spiegel = daten);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(durchlaufProvider);
    final sz = s.inhalt.szenarien.firstWhere((x) => x.id == widget.szenarioId);
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PwScaffold(
      titel: 'Auswertung',
      onZurueck: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onEinstellungen: () => vereinOeffnen(context),
      onSzenarioOeffnen: (ziel) => szenarioOeffnen(context, ref, ziel),
      aktionen: [
        Row(
          children: [
            Expanded(
              flex: 10,
              child: PwButton(
                label: 'Nochmal',
                ikon: PwIcons.rotateCcw,
                vollBreite: true,
                onPressed: () {
                  ref.read(durchlaufProvider.notifier).nochmal(sz);
                  final nav = Navigator.of(context);
                  nav.popUntil((r) => r.isFirst);
                  nav.push(
                    pwRoute(
                      EinstiegScreen(szenarioId: sz.id),
                      PwTransition.oeffnen,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 12,
              child: PwButton(
                label: 'Zur Übersicht',
                variante: PwButtonVariante.accent,
                ikonDanach: PwIcons.arrowRight,
                vollBreite: true,
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ),
          ],
        ),
      ],
      inhalt: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Was war unbedenklich, was klärungsbedürftig?',
              style: t.displaySmall?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: PwSpace.s4),
            Text(
              'Alle Merkmale dieses Szenarios, auch die, die hier nicht '
              'eingetreten sind.',
              style: t.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ],
        ),
        _Ampelstufen(szenario: sz),
        Divider(color: c.divider, height: 1),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PwLabel('Einschätzungsspiegel'),
            const SizedBox(height: PwSpace.s4),
            Text(
              'So haben die Trainerinnen und Trainer deines Vereins '
              'entschieden.',
              style: t.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < sz.punkte.length; i++) ...[
              if (i > 0) const SizedBox(height: PwSpace.gapTight),
              _SpiegelKarte(
                szenario: sz,
                index: i,
                eigeneWahl: s.fortschritt.wahl(sz.id, i),
                spiegel: _spiegel,
                offen: _offenerSpiegel == i,
                onUmschalten: () => setState(
                  () => _offenerSpiegel = _offenerSpiegel == i ? null : i,
                ),
              ),
            ],
          ],
        ),
        Divider(color: c.divider, height: 1),
        PwContactList(verein: s.inhalt.verein, personen: s.inhalt.personen),
        Text(
          'Dieser Prototyp gehört zur Prävention. Er ersetzt keine Meldung und '
          'keine Beratung.',
          style: t.bodyMedium?.copyWith(color: c.textFaint),
        ),
      ],
    );
  }
}

class _Ampelstufen extends StatelessWidget {
  const _Ampelstufen({required this.szenario});

  final PwSzenario szenario;

  @override
  Widget build(BuildContext context) {
    final listen = [
      for (final stufe in PwStufe.values)
        PwLevelList(
          stufe: stufe,
          merkmale: szenario.merkmaleDerStufe(stufe),
        ),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth >= _kAmpelDreispaltigAb) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < listen.length; i++) ...[
                if (i > 0) const SizedBox(width: PwSpace.s7),
                Expanded(child: listen[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < listen.length; i++) ...[
              if (i > 0) const SizedBox(height: PwSpace.s7),
              listen[i],
            ],
          ],
        );
      },
    );
  }
}

class _SpiegelKarte extends StatelessWidget {
  const _SpiegelKarte({
    required this.szenario,
    required this.index,
    required this.eigeneWahl,
    required this.spiegel,
    required this.offen,
    required this.onUmschalten,
  });

  final PwSzenario szenario;
  final int index;
  final String? eigeneWahl;
  final SpiegelDaten spiegel;
  final bool offen;
  final VoidCallback onUmschalten;

  PwMirrorZustand get _zustand {
    final punkt = szenario.punkte[index];
    switch (spiegel.status) {
      case SpiegelStatus.laedt:
        return PwMirrorZustand.laedt;
      case SpiegelStatus.fehler:
        return PwMirrorZustand.fehler;
      case SpiegelStatus.ohneBackend:
        // Ohne Backend gelten die vorbelegten Anteile aus dem Buendel.
        return punkt.zuWenige
            ? PwMirrorZustand.zuWenige
            : PwMirrorZustand.werte;
      case SpiegelStatus.da:
        return spiegel.gesamt(index) < kSpiegelSchwelle
            ? PwMirrorZustand.zuWenige
            : PwMirrorZustand.werte;
    }
  }

  Map<String, int> get _anteile {
    final punkt = szenario.punkte[index];
    if (spiegel.status == SpiegelStatus.da) {
      return spiegel.anteile(
        index,
        punkt.optionen.map((o) => o.id).toList(growable: false),
      );
    }
    return punkt.anteile;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;
    final punkt = szenario.punkte[index];

    return PwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: PwLabel('Entscheidungspunkt ${index + 1}')),
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onUmschalten,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PwIcons.fileText, size: 13, color: c.textLink),
                      const SizedBox(width: 5),
                      Text(
                        offen ? 'Schließen' : 'Situation nachlesen',
                        style: t.bodyMedium?.copyWith(color: c.textLink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PwSpace.s3),
          Text(
            punkt.leitfrage,
            style: t.bodyMedium?.copyWith(color: c.textBody),
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: PwMotion.dauer(context, PwDur.base),
            curve: PwCurve.out,
            alignment: Alignment.topCenter,
            child: offen
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      borderRadius: PwRadius.control,
                    ),
                    child: Text(
                      szenario.situationZuPunkt(index),
                      style: t.bodyMedium?.copyWith(color: c.textOnTint),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          PwMirrorBar(
            optionen: punkt.optionen,
            anteile: _anteile,
            eigeneWahl: eigeneWahl,
            zustand: _zustand,
          ),
        ],
      ),
    );
  }
}
