// Einstellungen — erreichbar über das Zahnrad auf der Übersicht.
//
// Der Screen war vorher reine Anzeige der Vereinsangaben (S5 in DESIGN.md).
// Er trägt jetzt zuerst die Einstellungen, die die App wirklich verändern; die
// Vereinsangaben stehen unverändert darunter.
//
// Was hier bewusst *nicht* steht:
//   Sprache — die App gibt es nur auf Deutsch. Eine Auswahl mit einem Eintrag
//   wäre Schaufenster.
//   Textgröße — dafür ist die Systemeinstellung da, und die App trägt sie bis
//   200 % ohne Überlauf (DESIGN.md 9). Eine zweite Stellschraube danebenzusetzen
//   verwirrt mehr, als sie hilft.
//
// Die Stufe „Verspielt" schaltet die zusätzlichen Gesten frei. Welche das
// sind und woher ihre Dateien kommen, steht in assets/lottie/LIESMICH.md.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fortschritt_speicher.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_card.dart';
import '../design/components/pw_contact_list.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_label.dart';
import '../design/components/pw_press_scale.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../design/pw_motion.dart';
import '../state/durchlauf_state.dart';
import 'overlays.dart';
import 'verein_code_feld.dart';
import 'pw_scaffold.dart';

class EinstellungenScreen extends ConsumerWidget {
  const EinstellungenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(durchlaufProvider);
    final notifier = ref.read(durchlaufProvider.notifier);
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PwScaffold(
      titel: 'Einstellungen',
      onZurueck: () => Navigator.of(context).maybePop(),
      // Hier steht als einzigem Screen keine Beratungsleiste: die
      // Beratungsangebote stehen weiter unten schon im Inhalt.
      helpBar: false,
      aktionen: [
        PwButton(
          label: 'Zurück zur Übersicht',
          ikon: PwIcons.chevronLeft,
          vollBreite: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      inhalt: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Einstellungen', style: t.displaySmall?.copyWith(fontSize: 26)),
            const SizedBox(height: PwSpace.s4),
            Text(
              'Alles hier gilt nur auf diesem Gerät. Nichts davon geht an den '
              'Verein.',
              style: t.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ],
        ),

        // ── Darstellung ──────────────────────────────────────────────────
        _Abschnitt(
          label: 'Darstellung',
          erklaerung: 'Dunkel ist die Vorgabe — die App wird meist abends auf '
              'dem Handy benutzt.',
          kinder: [
            for (final eintrag in const [
              (ThemeMode.light, 'Hell', 'Heller Grund, dunkle Schrift.'),
              (ThemeMode.dark, 'Dunkel', 'Dunkler Grund, helle Schrift.'),
              (
                ThemeMode.system,
                'Wie das System',
                'Folgt der Einstellung deines Geräts.',
              ),
            ])
              _Wahlfeld(
                titel: eintrag.$2,
                zusatz: eintrag.$3,
                gewaehlt: s.fortschritt.themeMode == eintrag.$1,
                onTap: () => notifier.themeSetzen(eintrag.$1),
              ),
          ],
        ),

        // ── Bewegung ─────────────────────────────────────────────────────
        _Abschnitt(
          label: 'Bewegung',
          erklaerung: 'Hat dein Gerät „Bewegung reduzieren" gesetzt, gilt das '
              'ohnehin — unabhängig von dieser Einstellung.',
          kinder: [
            _Wahlfeld(
              titel: 'Reduziert',
              zusatz: 'Alles erscheint sofort im Endzustand, ohne Animation.',
              gewaehlt: s.fortschritt.bewegung == PwBewegung.reduziert,
              onTap: () => notifier.bewegungSetzen(PwBewegung.reduziert),
            ),
            _Wahlfeld(
              titel: 'Normal',
              zusatz: 'Übergänge und Aufklappen laufen wie vorgesehen.',
              gewaehlt: s.fortschritt.bewegung == PwBewegung.normal,
              onTap: () => notifier.bewegungSetzen(PwBewegung.normal),
            ),
            _Wahlfeld(
              titel: 'Verspielt',
              zusatz: 'Dazu kleine Gesten, die nichts erklären — etwa beim '
                  'ersten Abschluss eines Szenarios.',
              gewaehlt: s.fortschritt.bewegung == PwBewegung.verspielt,
              onTap: () => notifier.bewegungSetzen(PwBewegung.verspielt),
            ),
          ],
        ),

        Divider(color: c.divider, height: 1),

        // ── Vereinsangaben ───────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.vereinName ?? 'Vereinsangaben',
              style: t.titleLarge?.copyWith(fontSize: 21, height: 1.25),
            ),
            const SizedBox(height: PwSpace.s4),
            Text(
              s.verein == null
                  ? 'Trag den Code deines Vereins ein, dann stehen hier seine '
                      'Ansprechpersonen — und der Einschätzungsspiegel zeigt, '
                      'wie sich dein Team entschieden hat.'
                  : 'Die Angaben pflegt der Verein. Sie stehen in jedem '
                      'Szenario am Ende und jederzeit über die '
                      'Beratungsleiste.',
              style: t.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ],
        ),
        const PwVereinscodeFeld(),
        PwContactList(verein: s.vereinName, personen: s.personen),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PwLabel('Externe Beratung'),
            const SizedBox(height: 10),
            for (var i = 0; i < s.beratung.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              PwBeratungKarte(beratung: s.beratung[i]),
            ],
          ],
        ),
        PwCard(
          ton: PwCardTon.tint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const PwLabel('Was gespeichert wird'),
              const SizedBox(height: PwSpace.s4),
              Text(
                'Dein Fortschritt und deine Entscheidungen bleiben auf diesem '
                'Gerät. An den Verein geht nichts. Gespeichert wird nur ein '
                'Zählwert je Entscheidungspunkt und Handlungsoption.',
                style: t.bodyLarge?.copyWith(color: c.textOnTint),
              ),
            ],
          ),
        ),

        Divider(color: c.divider, height: 1),

        // ── Daten ────────────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PwLabel('Daten auf diesem Gerät'),
            const SizedBox(height: 10),
            Text(
              'Entfernt alle Entscheidungen, den Fortschritt und die '
              'Einstellungen. Die bereits gezählten Werte im '
              'Einschätzungsspiegel bleiben davon unberührt — sie tragen '
              'keinen Bezug zu diesem Gerät.',
              style: t.bodyMedium?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: PwSpace.gapTight),
            PwButton(
              label: 'Alle lokalen Daten löschen',
              vollBreite: true,
              onPressed: () => _loeschenBestaetigen(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

/// Fragt nach, bevor gelöscht wird — der Schritt lässt sich nicht zurücknehmen.
Future<void> _loeschenBestaetigen(BuildContext context, WidgetRef ref) async {
  final gewollt = await showDialog<bool>(
    context: context,
    barrierColor: context.pw.surfaceOverlay,
    builder: (ctx) {
      final c = ctx.pw;
      final t = Theme.of(ctx).textTheme;
      return AlertDialog(
        backgroundColor: c.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: PwRadius.dialog,
          side: BorderSide(color: c.borderSubtle),
        ),
        title: Text('Alle lokalen Daten löschen', style: t.titleLarge),
        content: Text(
          'Deine Entscheidungen, dein Fortschritt und deine Einstellungen '
          'werden entfernt. Die App steht danach wie beim ersten Öffnen da. '
          'Das lässt sich nicht rückgängig machen.',
          style: t.bodyLarge,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          PwButton(
            label: 'Abbrechen',
            variante: PwButtonVariante.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          PwButton(
            label: 'Löschen',
            variante: PwButtonVariante.accent,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );

  if (gewollt != true || !context.mounted) return;

  await ref.read(durchlaufProvider.notifier).allesLoeschen();
  if (!context.mounted) return;

  // Zurück zur Übersicht: die steht danach wieder mit der Erststart-Karte da.
  Navigator.of(context).popUntil((r) => r.isFirst);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.pw.surfaceInverse,
      content: Text(
        'Alle lokalen Daten wurden gelöscht.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: PwPalette.white),
      ),
    ),
  );
}

/// Überschrift, Erklärsatz und die Felder eines Einstellungsblocks.
class _Abschnitt extends StatelessWidget {
  const _Abschnitt({
    required this.label,
    required this.erklaerung,
    required this.kinder,
  });

  final String label;
  final String erklaerung;
  final List<Widget> kinder;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PwLabel(label),
        const SizedBox(height: PwSpace.s4),
        Text(erklaerung, style: t.bodyMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 10),
        for (var i = 0; i < kinder.length; i++) ...[
          if (i > 0) const SizedBox(height: PwSpace.s4),
          kinder[i],
        ],
      ],
    );
  }
}

/// Eine Auswahl innerhalb eines Blocks. Übernimmt das Muster der Auswahlkacheln
/// aus dem Rückmeldungs-Sheet: gewählt heißt surfaceTint mit Rand borderFocus.
class _Wahlfeld extends StatelessWidget {
  const _Wahlfeld({
    required this.titel,
    required this.zusatz,
    required this.gewaehlt,
    required this.onTap,
  });

  final String titel;
  final String zusatz;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: gewaehlt,
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
                color: gewaehlt ? c.surfaceTint : c.surfaceCard,
                borderRadius: PwRadius.control,
                border: Border.all(
                  color: gewaehlt ? c.borderFocus : c.borderSubtle,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Der gefüllte Kreis mit Haken folgt dem Muster der
                  // Optionskarten (DESIGN.md 4.7) — nur ohne Buchstabe.
                  AnimatedContainer(
                    duration: PwMotion.dauer(context, PwDur.base),
                    curve: PwCurve.standard,
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gewaehlt ? c.actionPrimary : Colors.transparent,
                      border: Border.all(
                        color: gewaehlt ? c.actionPrimary : c.borderDefault,
                      ),
                    ),
                    child: gewaehlt
                        ? Icon(PwIcons.check, size: 12, color: c.textInverse)
                        : null,
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
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: gewaehlt ? c.textOnTint : c.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          zusatz,
                          style: t.bodyMedium?.copyWith(
                            color:
                                gewaehlt ? c.textOnTintMuted : c.textMuted,
                          ),
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
