// S1 — Uebersicht, DESIGN.md 7/S1. Wurzel der Navigation.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/szenario_modelle.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_card.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_konfetti.dart';
import '../design/components/pw_label.dart';
import '../design/components/pw_press_scale.dart';
import '../design/components/pw_step_indicator.dart';
import '../design/components/pw_tag.dart';
import '../design/components/pw_wenn_sichtbar.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../state/durchlauf_state.dart';
import 'einstieg_screen.dart';
import 'overlays.dart';
import 'pw_scaffold.dart';

class UebersichtScreen extends ConsumerStatefulWidget {
  const UebersichtScreen({super.key});

  @override
  ConsumerState<UebersichtScreen> createState() => _UebersichtScreenState();
}

class _UebersichtScreenState extends ConsumerState<UebersichtScreen> {
  /// Laeuft, solange die Vereinsfrage offen auf dem Schirm steht.
  bool _fragtGerade = false;

  @override
  void initState() {
    super.initState();
    // Beim Start die zwischengespeicherten Vereinsangaben auffrischen, damit
    // eine geaenderte Nummer ohne neue App-Fassung ankommt. Scheitert es,
    // bleiben die alten stehen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(durchlaufProvider.notifier).vereinAuffrischen();
    });
  }

  /// Fragt einmalig nach dem Vereinscode.
  ///
  /// Nicht waehrend die Erststart-Karte steht: die ist beim allerersten
  /// Oeffnen die Einfuehrung in die App, und ein Sheet darueber verdeckt
  /// genau den Text, der erklaert, worum es geht. Die Frage kommt, sobald
  /// die Karte weg ist — also nach dem ersten Antippen von "Szenario
  /// starten". Deshalb steht die Pruefung im Aufbau und nicht in initState.
  void _vielleichtFragen(bool erststartKarteSteht) {
    if (_fragtGerade || erststartKarteSteht) return;
    if (!ref.read(durchlaufProvider).vereinFragen) return;

    _fragtGerade = true;
    vereinsfrageZeigen(context).then((_) {
      _fragtGerade = false;
      if (mounted) ref.read(durchlaufProvider.notifier).vereinsfrageErledigt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(durchlaufProvider);
    final notifier = ref.read(durchlaufProvider.notifier);
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    final laufend = s.laufendes;
    final erststart = !s.fortschritt.erststartGesehen && s.erststartAn;

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _vielleichtFragen(erststart));

    return PwScaffold(
      titel: 'Pathwise',
      zeigtLogo: true,
      zeigtEinstellungen: true,
      onEinstellungen: () => einstellungenOeffnen(context),
      onSzenarioOeffnen: (ziel) => szenarioOeffnen(context, ref, ziel),
      inhalt: [
        if (erststart)
          _ErststartKarte(
            infos: s.inhalt.infos,
            onStart: () {
              notifier.erststartGesehen();
              szenarioOeffnen(context, ref, s.inhalt.szenarien.first);
            },
          ),
        if (laufend != null)
          _WeiterMachenKarte(
            szenario: laufend,
            aktuell: s.letzterPunkt(laufend) + 1,
            onFortsetzen: () => szenarioOeffnen(context, ref, laufend),
          ),
        Text(
          'Erfundene, realitätsnahe Situationen aus dem Trainingsalltag. '
          'Höchstens fünf Minuten, jederzeit unterbrechbar.',
          style: t.bodyMedium?.copyWith(color: c.textMuted),
        ),
        Wrap(
          spacing: PwSpace.s4,
          runSpacing: PwSpace.s4,
          children: [
            for (final feld in s.inhalt.themenfelder)
              PwTag(
                label: feld,
                gewaehlt: s.themenfeldFilter == feld,
                onTap: () => notifier.filterSetzen(feld),
              ),
          ],
        ),
        _Raster(
          mindestBreite: 272,
          abstand: PwSpace.gapTight,
          kinder: [
            for (final sz in s.sichtbareSzenarien)
              _SzenarioKarte(
                szenario: sz,
                status: s.status(sz),
                onTap: () => szenarioOeffnen(context, ref, sz),
                // Einmalig, beim ersten Abschluss — und nur, wenn die
                // zusaetzlichen Animationen eingeschaltet sind. Ohne sie
                // bleibt die App bei DESIGN.md 1: keine Feiergeste.
                feiern: s.fortschritt.bewegung.zeigtExtras &&
                    s.status(sz) == SzenarioStatus.abgeschlossen &&
                    !s.fortschritt.gefeiert.contains(sz.id),
                onGefeiert: () => notifier.gefeiert(sz),
              ),
          ],
        ),
        _WeitereBereiche(module: s.inhalt.module),
        _RueckmeldungBlock(onTap: () => rueckmeldungSheetZeigen(context)),
      ],
    );
  }
}

/// Erststart-Karte — nur beim ersten Oeffnen (DESIGN.md 7/S1).
class _ErststartKarte extends StatelessWidget {
  const _ErststartKarte({required this.infos, required this.onStart});

  final List<PwInfo> infos;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PwCard(
      polster: PwCardPolster.lg,
      akzent: PwCardAkzent.sweep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PwLabel('Zum Anfangen'),
          const SizedBox(height: 10),
          Text(
            'Die meisten Situationen im Training sind nicht eindeutig.',
            style: t.displaySmall,
          ),
          const SizedBox(height: PwSpace.gapTight),
          Text(
            'Hier kannst du sie einmal durchdenken, bevor du in der Halle '
            'entscheiden musst. Du liest eine Situation, entscheidest dich für '
            'eine von drei Möglichkeiten und bekommst auf Abruf eine fachliche '
            'Einordnung.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: PwSpace.s4),
          Text(
            'Keine der Möglichkeiten ist richtig oder falsch. Eingeordnet wird '
            'nur die Situation und nicht deine Entscheidung. Es gibt keine '
            'Zeitbegrenzung, du kannst jederzeit unterbrechen.',
            style: t.bodyMedium?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 18),
          Divider(color: c.borderSubtle, height: 1),
          const SizedBox(height: PwSpace.gap),
          for (var i = 0; i < infos.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            PwInfoBlock(info: infos[i]),
          ],
          const SizedBox(height: 18),
          PwButton(
            label: 'Erstes Szenario ansehen',
            variante: PwButtonVariante.accent,
            ikonDanach: PwIcons.arrowRight,
            vollBreite: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// "Weiter machen" — springt zum ersten unabgeschlossenen Szenario.
class _WeiterMachenKarte extends StatelessWidget {
  const _WeiterMachenKarte({
    required this.szenario,
    required this.aktuell,
    required this.onFortsetzen,
  });

  final PwSzenario szenario;
  final int aktuell;
  final VoidCallback onFortsetzen;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PwCard(
      akzent: PwCardAkzent.sweep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: PwLabel('Weiter machen')),
              const SizedBox(width: PwSpace.s4),
              Flexible(
                child: Text(
                  szenario.themenfeld,
                  style: t.bodyMedium?.copyWith(color: c.textFaint),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: PwSpace.s4),
          Text(
            szenario.titel,
            style: t.titleLarge?.copyWith(fontSize: 21, height: 1.25),
          ),
          const SizedBox(height: 14),
          PwStepIndicator(
            gesamt: szenario.punkte.length,
            aktuell: aktuell,
            mitText: false,
          ),
          const SizedBox(height: PwSpace.gap),
          PwButton(
            label: 'Fortsetzen',
            variante: PwButtonVariante.accent,
            ikonDanach: PwIcons.arrowRight,
            vollBreite: true,
            onPressed: onFortsetzen,
          ),
        ],
      ),
    );
  }
}

/// Szenariokarte. Keine Fusszeile, kein Button, keine Zeitangabe — die ganze
/// Karte ist die Aktion (DESIGN.md 7/S1).
class _SzenarioKarte extends StatelessWidget {
  const _SzenarioKarte({
    required this.szenario,
    required this.status,
    required this.onTap,
    this.feiern = false,
    this.onGefeiert,
  });

  final PwSzenario szenario;
  final SzenarioStatus status;
  final VoidCallback onTap;

  /// Auf false gesetzt entfaellt die Abschluss-Geste vollstaendig.
  final bool feiern;
  final VoidCallback? onGefeiert;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    // Jede Farbaussage traegt zusaetzlich Text und Icon (DESIGN.md 9).
    final (statusFarbe, statusIkon) = switch (status) {
      SzenarioStatus.abgeschlossen => (c.levelOk, PwIcons.check),
      SzenarioStatus.angefangen => (PwPalette.blue700, PwIcons.rotateCcw),
      SzenarioStatus.offen => (c.textFaint, null),
    };

    final karte = PwCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Themenfeld, darunter der Status — immer, unabhaengig von der Laenge
          // des Themenfeldnamens. Ein Wrap mit spaceBetween stellte den Status
          // mal daneben und mal darunter, je nachdem ob beides in eine Zeile
          // passte; auf der Uebersicht standen dann Karten unterschiedlich da.
          PwTag(label: szenario.themenfeld),
          const SizedBox(height: PwSpace.s3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusIkon != null) ...[
                Icon(statusIkon, size: 13, color: statusFarbe),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  status.label,
                  style: t.bodyMedium?.copyWith(color: statusFarbe),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            szenario.titel,
            style: t.titleMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 10),
          Text(
            szenario.kurz,
            style: t.bodyMedium?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );

    if (!feiern) return karte;

    // Die Geste liegt ueber der Karte und ist auf deren Rundung beschnitten,
    // damit nichts in die Nachbarkarten ragt.
    //
    // Sie startet erst, wenn die Karte im Bild steht. Der Scrollbereich baut
    // alle Karten sofort — ohne diese Kopplung liefe die Geste bei einer Karte
    // weiter unten ab, waehrend niemand hinsieht, und waere danach als gezeigt
    // abgehakt.
    return Stack(
      children: [
        karte,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: PwRadius.card,
            child: PwWennSichtbar(
              builder: (ctx, sichtbar) => sichtbar
                  ? PwKonfetti(onFertig: onGefeiert ?? () {})
                  : const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeitereBereiche extends StatelessWidget {
  const _WeitereBereiche({required this.module});

  final List<PwModul> module;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: PwSpace.s3),
        Divider(color: c.borderSubtle, height: 1),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: PwLabel('Weitere Bereiche')),
            const SizedBox(width: PwSpace.s4),
            Text(
              'in Vorbereitung',
              style: t.bodyMedium?.copyWith(color: c.textFaint),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Raster(
          mindestBreite: 200,
          abstand: 10,
          kinder: [
            for (final m in module)
              _ModulKachel(
                modul: m,
                onTap: () => kommtBaldZeigen(context, m),
              ),
          ],
        ),
      ],
    );
  }
}

class _ModulKachel extends StatefulWidget {
  const _ModulKachel({required this.modul, required this.onTap});

  final PwModul modul;
  final VoidCallback onTap;

  @override
  State<_ModulKachel> createState() => _ModulKachelState();
}

class _ModulKachelState extends State<_ModulKachel> {
  bool _darueber = false;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _darueber = true),
      onExit: (_) => setState(() => _darueber = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: PwPressScale(
          child: CustomPaint(
            // Gestrichelter Rahmen — Flutter kennt keinen dashed border.
            painter: _GestrichelterRahmen(
              farbe: _darueber ? c.textFaint : c.borderStrong,
              radius: PwRadius.lg,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: PwSize.touchMin),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _darueber ? c.surfaceTint : c.surfacePage,
                borderRadius: PwRadius.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      borderRadius: PwRadius.control,
                    ),
                    child: Icon(
                      PwIcons.ausName(widget.modul.ikon),
                      size: 16,
                      color: c.iconOnTint,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.modul.titel,
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.modul.zusatz,
                          style: t.bodyMedium?.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PwSpace.s4),
                  Icon(PwIcons.arrowUpRight, size: 14, color: c.textFaint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GestrichelterRahmen extends CustomPainter {
  const _GestrichelterRahmen({required this.farbe, required this.radius});

  final Color farbe;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final stift = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final pfad = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const strich = 5.0;
    const luecke = 4.0;
    for (final teil in pfad.computeMetrics()) {
      var abstand = 0.0;
      while (abstand < teil.length) {
        final bis = (abstand + strich).clamp(0.0, teil.length);
        canvas.drawPath(teil.extractPath(abstand, bis), stift);
        abstand = bis + luecke;
      }
    }
  }

  @override
  bool shouldRepaint(_GestrichelterRahmen alt) =>
      alt.farbe != farbe || alt.radius != radius;
}

class _RueckmeldungBlock extends StatelessWidget {
  const _RueckmeldungBlock({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PwPressScale(
          child: Container(
            padding: const EdgeInsets.all(PwSpace.gap),
            decoration: BoxDecoration(
              color: c.surfaceTint,
              borderRadius: PwRadius.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child:
                      Icon(PwIcons.messageSquare, size: 16, color: c.iconOnTint),
                ),
                const SizedBox(width: PwSpace.gapTight),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rückmeldung geben oder eine Situation einschicken',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: c.textOnTint,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Was unklar war, was fehlt — oder eine Situation aus '
                        'deinem Trainingsalltag, die als Szenario aufgenommen '
                        'werden könnte.',
                        style:
                            t.bodyMedium?.copyWith(color: c.textOnTintMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PwSpace.gapTight),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    PwIcons.chevronRight,
                    size: 16,
                    color: c.iconOnTint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raster nach dem Muster repeat(auto-fill, minmax(mindestBreite, 1fr)).
class _Raster extends StatelessWidget {
  const _Raster({
    required this.mindestBreite,
    required this.abstand,
    required this.kinder,
  });

  final double mindestBreite;
  final double abstand;
  final List<Widget> kinder;

  @override
  Widget build(BuildContext context) {
    if (kinder.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final spalten = ((constraints.maxWidth + abstand) /
                (mindestBreite + abstand))
            .floor()
            .clamp(1, kinder.length);

        if (spalten == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < kinder.length; i++) ...[
                if (i > 0) SizedBox(height: abstand),
                kinder[i],
              ],
            ],
          );
        }

        final reihen = <Widget>[];
        for (var i = 0; i < kinder.length; i += spalten) {
          final reihe = kinder.skip(i).take(spalten).toList();
          reihen.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < spalten; j++) ...[
                    if (j > 0) SizedBox(width: abstand),
                    Expanded(
                      child: j < reihe.length
                          ? reihe[j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < reihen.length; i++) ...[
              if (i > 0) SizedBox(height: abstand),
              reihen[i],
            ],
          ],
        );
      },
    );
  }
}
