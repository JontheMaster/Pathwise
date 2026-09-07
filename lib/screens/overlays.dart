// Die Overlays: Hilfe (S6), Info (S7), Rueckmeldung (S8), "Kommt bald" (S9)
// sowie der Weg in die Einstellungen.
//
// Alle vier Overlays sind von jedem Screen aus erreichbar, ohne den Durchlauf
// zu verlassen: der Zustand des Szenarios bleibt vollstaendig erhalten
// (DESIGN.md 7, S6).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/szenario_modelle.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_card.dart';
import '../design/components/pw_contact_list.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_press_scale.dart';
import '../design/components/pw_sheet.dart';
import '../design/pathwise_routes.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../state/durchlauf_state.dart';
import 'einstellungen_screen.dart';
import 'kommt_bald_dialog.dart';
import 'rueckmeldung_sheet.dart';

/// S6 — Hilfe und Beratung.
Future<void> hilfeSheetZeigen(BuildContext context) {
  return pwSheetZeigen<void>(
    context,
    titel: 'Hilfe und Beratung',
    untertitel: 'Erreichbar auf jedem Bildschirm, ohne dass du das Szenario '
        'verlässt.',
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final s = ref.watch(durchlaufProvider);
        final c = ctx.pw;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final b in s.inhalt.beratung) ...[
              PwBeratungKarte(beratung: b),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: PwSpace.s3),
            PwContactList(
              verein: s.inhalt.verein,
              personen: s.inhalt.personen,
            ),
            const SizedBox(height: PwSpace.gap),
            Text(
              'Bei einem konkreten Verdacht wende dich an den '
              'Kinderschutzbeauftragten. Der Prototyp nimmt keine Meldung '
              'entgegen.',
              style: Theme.of(ctx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: c.textFaint),
            ),
            const SizedBox(height: 14),
            PwButton(
              label: 'Zurück zum Szenario',
              vollBreite: true,
              onPressed: () => Navigator.of(ctx).maybePop(),
            ),
          ],
        );
      },
    ),
  );
}

/// S7 — So funktioniert Pathwise.
Future<void> infoSheetZeigen(BuildContext context) {
  return pwSheetZeigen<void>(
    context,
    titel: 'So funktioniert Pathwise',
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final s = ref.watch(durchlaufProvider);
        final c = ctx.pw;
        final t = Theme.of(ctx).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < s.inhalt.infos.length; i++) ...[
              if (i > 0) const SizedBox(height: PwSpace.gap),
              PwInfoBlock(info: s.inhalt.infos[i], kreis: 32, ikon: 16),
            ],
            const SizedBox(height: 18),
            Text(
              'Pathwise ersetzt keine Beratung und nimmt keine Meldung '
              'entgegen. Bei einem konkreten Verdacht führt der Weg über die '
              'Ansprechpersonen im Verein.',
              style: t.bodyMedium?.copyWith(color: c.textFaint),
            ),
            const SizedBox(height: 14),
            _Textlink(
              ikon: PwIcons.messageSquare,
              text: 'Rückmeldung geben oder eine Situation einschicken',
              onTap: () {
                Navigator.of(ctx).pop();
                rueckmeldungSheetZeigen(context);
              },
            ),
            const SizedBox(height: PwSpace.gap),
            PwButton(
              label: 'Verstanden',
              vollBreite: true,
              onPressed: () => Navigator.of(ctx).maybePop(),
            ),
          ],
        );
      },
    ),
  );
}

/// S8 — Rueckmeldung geben oder eine Situation einschicken.
Future<void> rueckmeldungSheetZeigen(BuildContext context) {
  return pwSheetZeigen<void>(
    context,
    titel: 'Rückmeldung',
    anteilHoehe: 0.94,
    builder: (ctx) => const RueckmeldungInhalt(),
  );
}

/// S9 — "Kommt bald" fuer die angekuendigten Module.
Future<void> kommtBaldZeigen(BuildContext context, PwModul modul) {
  return pwDialogZeigen<void>(
    context,
    builder: (ctx) => KommtBaldInhalt(modul: modul),
  );
}

/// Einstellungen, Motion M10 hinein, M11 zurueck. Die Vereinsangaben
/// stehen dort weiter unten.
void einstellungenOeffnen(BuildContext context) {
  Navigator.of(context).push(
    pwRoute(const EinstellungenScreen(), PwTransition.hoch),
  );
}

/// Karte einer externen Beratungsstelle. Der Anruf startet hier — aus dem
/// Sheet heraus, nicht aus der HelpBar (DESIGN.md 4.12).
class PwBeratungKarte extends StatelessWidget {
  const PwBeratungKarte({super.key, required this.beratung});

  final PwBeratung beratung;

  Future<void> _anrufen(BuildContext context) async {
    final ziel = Uri(scheme: 'tel', path: beratung.nummer.replaceAll(' ', ''));
    var geklappt = false;
    try {
      geklappt = await launchUrl(ziel);
    } catch (_) {
      geklappt = false;
    }
    if (geklappt || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: beratung.nummer));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.pw.surfaceInverse,
        content: Text(
          'Nummer kopiert: ${beratung.nummer}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: PwPalette.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PwCard(
      polster: PwCardPolster.sm,
      onTap: () => _anrufen(context),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
            child: Icon(PwIcons.lifeBuoy, size: 16, color: c.iconOnTint),
          ),
          const SizedBox(width: PwSpace.gapTight),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  beratung.titel,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: c.textHeading,
                  ),
                ),
                Text(
                  beratung.zusatz,
                  style: t.bodyMedium?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: PwSpace.s4),
          // Telefonnummern stehen in Mono (DESIGN.md 2.6).
          Text(
            beratung.nummer,
            style: t.labelMedium?.copyWith(color: c.textLink),
          ),
        ],
      ),
    );
  }
}

/// Einer der sechs Info-Bloecke — in der Erststart-Karte (Kreis 30) und im
/// Info-Sheet (Kreis 32).
class PwInfoBlock extends StatelessWidget {
  const PwInfoBlock({
    super.key,
    required this.info,
    this.kreis = 30,
    this.ikon = 14,
  });

  final PwInfo info;
  final double kreis;
  final double ikon;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: kreis,
          height: kreis,
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
          child: Icon(
            PwIcons.ausName(info.ikon),
            size: ikon,
            color: c.iconOnTint,
          ),
        ),
        const SizedBox(width: PwSpace.gapTight),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.titel,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: c.textHeading,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                info.text,
                style: t.bodyMedium?.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Textlink extends StatelessWidget {
  const _Textlink({
    required this.ikon,
    required this.text,
    required this.onTap,
  });

  final IconData ikon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PwPressScale(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PwSize.touchMin),
            child: Row(
              children: [
                Icon(ikon, size: 14, color: c.textLink),
                const SizedBox(width: PwSpace.s4),
                Flexible(
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: c.textLink),
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
