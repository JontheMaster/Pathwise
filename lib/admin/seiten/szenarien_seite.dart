// Alle Szenarien: Entwürfe und Veröffentlichte, mit Fassungsverlauf.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/pw_button.dart';
import '../../design/components/pw_icons.dart';
import '../../design/components/pw_label.dart';
import '../../design/pathwise_theme.dart';
import '../../design/pathwise_tokens.dart';
import '../admin_modelle.dart';
import '../admin_state.dart';
import '../widgets/admin_bausteine.dart';
import 'szenario_editor.dart';

class SzenarienSeite extends ConsumerWidget {
  const SzenarienSeite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(szenarienProvider);
    final t = Theme.of(context).textTheme;
    final c = context.pw;

    return ListView(
      padding: const EdgeInsets.all(PwSpace.gap),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Szenarien', style: t.displaySmall?.copyWith(fontSize: 26)),
                  const SizedBox(height: PwSpace.s4),
                  Text(
                    'Veröffentlichte Szenarien holt die App beim Start. '
                    'Entwürfe bekommt sie nicht zu sehen.',
                    style: t.bodyMedium?.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PwSpace.gap),
            PwButton(
              label: 'Neues Szenario',
              variante: PwButtonVariante.accent,
              ikon: PwIcons.plus,
              onPressed: () => _neu(context),
            ),
          ],
        ),
        const SizedBox(height: PwSpace.gap),
        AdminLadeflaeche<List<AdminSzenario>>(
          wert: liste,
          bauen: (szenarien) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (szenarien.isEmpty)
                Text(
                  'Noch keine Szenarien. Die App fällt dann auf das Bündel '
                  'zurück.',
                  style: t.bodyMedium?.copyWith(color: c.textMuted),
                ),
              for (final s in szenarien) ...[
                _SzenarioZeile(szenario: s),
                const SizedBox(height: PwSpace.gapTight),
              ],
              if (szenarien.isNotEmpty) ...[
                const SizedBox(height: PwSpace.gap),
                PwButton(
                  label: 'Alle Szenarien als JSON kopieren',
                  ikon: PwIcons.fileText,
                  vollBreite: true,
                  onPressed: () => _export(context, szenarien),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _neu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SzenarioEditor(
          neu: true,
          szenario: const AdminSzenario(
            id: '',
            status: AdminStatus.entwurf,
            reihenfolge: 0,
            fassung: 1,
            signatur: '',
            inhalt: {
              'titel': '',
              'themenfeld': '',
              'kurz': '',
              'dauer': 'ca. 5 Min.',
              'rahmen': <String>[],
              'vorgeschichte': '',
              'ausgangssituation': '',
              'merkmale': <dynamic>[],
              'punkte': <dynamic>[],
            },
          ),
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    List<AdminSzenario> szenarien,
  ) async {
    // Bewusst in die Zwischenablage statt als Download: das Ergebnis soll
    // dorthin, wo gerade gearbeitet wird, und ein Browser-Download waere
    // eine Datei mehr im Downloads-Ordner.
    final text = const JsonEncoder.withIndent('  ').convert({
      'szenarien': [
        for (final s in szenarien)
          {
            'id': s.id,
            'status': s.status.schluessel,
            'reihenfolge': s.reihenfolge,
            'fassung': s.fassung,
            'signatur': s.signatur,
            'inhalt': s.inhalt,
          },
      ],
    });
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      adminMelden(context, '${szenarien.length} Szenarien in die '
          'Zwischenablage kopiert.');
    }
  }
}

class _SzenarioZeile extends ConsumerWidget {
  const _SzenarioZeile({required this.szenario});

  final AdminSzenario szenario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(PwSpace.gap),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: PwRadius.card,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PwLabel(szenario.themenfeld),
                    const SizedBox(height: PwSpace.s3),
                    Text(szenario.titel, style: t.titleMedium),
                    const SizedBox(height: PwSpace.s3),
                    Text(
                      '${szenario.id} · ${szenario.punkteAnzahl} '
                      'Entscheidungspunkte',
                      style: t.labelMedium?.copyWith(color: c.textFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PwSpace.gap),
              AdminStatusMarke(
                status: szenario.status,
                fassung: szenario.status == AdminStatus.veroeffentlicht
                    ? szenario.fassung
                    : null,
              ),
            ],
          ),
          const SizedBox(height: PwSpace.gap),
          Wrap(
            spacing: PwSpace.s4,
            runSpacing: PwSpace.s4,
            children: [
              PwButton(
                label: 'Bearbeiten',
                variante: PwButtonVariante.primary,
                groesse: PwButtonGroesse.sm,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SzenarioEditor(szenario: szenario),
                  ),
                ),
              ),
              PwButton(
                label: szenario.status == AdminStatus.veroeffentlicht
                    ? 'Zurückziehen'
                    : 'Veröffentlichen',
                groesse: PwButtonGroesse.sm,
                onPressed: () => _statusWechseln(context, ref),
              ),
              if (szenario.status == AdminStatus.veroeffentlicht)
                PwButton(
                  label: 'Fassungen',
                  groesse: PwButtonGroesse.sm,
                  onPressed: () => _fassungen(context, ref),
                ),
              PwButton(
                label: 'Löschen',
                groesse: PwButtonGroesse.sm,
                onPressed: () => _loeschen(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _statusWechseln(BuildContext context, WidgetRef ref) async {
    final raus = szenario.status == AdminStatus.veroeffentlicht;
    if (raus) {
      final sicher = await adminBestaetigen(
        context,
        titel: 'Szenario zurückziehen?',
        text: 'Die App zeigt es danach nicht mehr. Wer es gerade angefangen '
            'hat, spielt seine Fassung zu Ende — die bleibt abrufbar. '
            'Zählwerte bleiben erhalten.',
        knopf: 'Zurückziehen',
      );
      if (!sicher || !context.mounted) return;
    }

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).szenarioSichern(
            szenario.copyWith(
              status: raus ? AdminStatus.entwurf : AdminStatus.veroeffentlicht,
            ),
          ),
      erfolg: raus ? 'Zurückgezogen.' : 'Veröffentlicht.',
    );
    ref.szenarienNeu();
  }

  Future<void> _loeschen(BuildContext context, WidgetRef ref) async {
    final sicher = await adminBestaetigen(
      context,
      titel: 'Szenario löschen?',
      text: 'Das Szenario, alle seine Fassungen und die Zählwerte dazu '
          'verschwinden. Das lässt sich nicht rückgängig machen. Wer es nur '
          'aus der App nehmen will, zieht es besser zurück.',
    );
    if (!sicher || !context.mounted) return;

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).szenarioLoeschen(szenario.id),
      erfolg: 'Szenario gelöscht.',
    );
    ref.szenarienNeu();
  }

  Future<void> _fassungen(BuildContext context, WidgetRef ref) async {
    final liste =
        await ref.read(adminRepositoryProvider).fassungen(szenario.id);
    if (!context.mounted) return;

    await showDialog<void>(
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
          title: Text('Fassungen von ${szenario.titel}', style: t.titleLarge),
          content: SizedBox(
            width: 460,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jede veröffentlichte Fassung bleibt abrufbar, damit ein '
                  'angefangener Durchlauf zu Ende gespielt werden kann.',
                  style: t.bodyMedium?.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: PwSpace.gap),
                for (final f in liste)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fassung ${f.fassung} · ${f.titel}',
                            style: t.bodyLarge,
                          ),
                        ),
                        Text(
                          f.signatur.substring(0, 8),
                          style: t.labelMedium?.copyWith(color: c.textFaint),
                        ),
                      ],
                    ),
                  ),
                if (liste.isEmpty)
                  Text('Noch keine.',
                      style: t.bodyMedium?.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            PwButton(
              label: 'Schließen',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }
}
