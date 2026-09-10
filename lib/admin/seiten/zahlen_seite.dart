// Die Zahlen aus dem Einschätzungsspiegel.
//
// Was hier steht, ist bewusst wenig: je Verein, Szenario, Fassung,
// Entscheidungspunkt und Handlungsoption eine Zahl. Keine Geräte, keine
// Sitzungen, keine Zeitstempel — es gibt sie schlicht nicht.
//
// Und es bleibt eine Einordnung, keine Bewertung: die Zahlen sagen, wie sich
// ein Team entschieden hat, nicht ob es richtig lag.
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

class ZahlenSeite extends ConsumerWidget {
  const ZahlenSeite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final c = context.pw;
    final vereine = ref.watch(vereineProvider).value ?? const <AdminVerein>[];
    final szenarien =
        ref.watch(szenarienProvider).value ?? const <AdminSzenario>[];

    String vereinsname(String id) => vereine
        .where((v) => v.id == id)
        .map((v) => v.name)
        .followedBy(['(gelöschter Verein)']).first;

    String szenariotitel(String id) => szenarien
        .where((s) => s.id == id)
        .map((s) => s.titel)
        .followedBy([id]).first;

    return ListView(
      padding: const EdgeInsets.all(PwSpace.gap),
      children: [
        Text('Zahlen', style: t.displaySmall?.copyWith(fontSize: 26)),
        const SizedBox(height: PwSpace.s4),
        Text(
          'Je Verein, Szenario, Fassung, Entscheidungspunkt und '
          'Handlungsoption eine Zahl. Mehr wird nicht erhoben — keine Geräte, '
          'keine Sitzungen, keine Zeitstempel.',
          style: t.bodyMedium?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: PwSpace.gap),
        AdminLadeflaeche<List<AdminZahl>>(
          wert: ref.watch(zahlenProvider),
          bauen: (zahlen) {
            if (zahlen.isEmpty) {
              return Text(
                'Noch keine Einschätzungen. Sie entstehen, sobald jemand mit '
                'eingetragenem Vereinscode ein Szenario durchspielt.',
                style: t.bodyMedium?.copyWith(color: c.textMuted),
              );
            }

            // Nach Verein, dann Szenario, dann Signatur gruppieren.
            final gruppen = <String, List<AdminZahl>>{};
            for (final z in zahlen) {
              gruppen
                  .putIfAbsent(
                      '${z.vereinId}|${z.szenarioId}|${z.signatur}', () => [])
                  .add(z);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${zahlen.fold<int>(0, (a, z) => a + z.anzahl)} '
                  'Einschätzungen in ${gruppen.length} Gruppen',
                  style: t.bodyLarge,
                ),
                const SizedBox(height: PwSpace.gap),
                for (final e in gruppen.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: PwSpace.gapTight),
                    child: _Gruppe(
                      verein: vereinsname(e.key.split('|')[0]),
                      szenario: szenariotitel(e.key.split('|')[1]),
                      signatur: e.key.split('|')[2],
                      zahlen: e.value,
                    ),
                  ),
                const SizedBox(height: PwSpace.gap),
                PwButton(
                  label: 'Alle Zahlen als JSON kopieren',
                  ikon: PwIcons.fileText,
                  vollBreite: true,
                  onPressed: () => _export(context, zahlen),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, List<AdminZahl> zahlen) async {
    final text = const JsonEncoder.withIndent('  ').convert({
      'zaehlwerte': [
        for (final z in zahlen)
          {
            'verein_id': z.vereinId,
            'szenario_id': z.szenarioId,
            'signatur': z.signatur,
            'punkt_index': z.punktIndex,
            'option_id': z.optionId,
            'anzahl': z.anzahl,
          },
      ],
    });
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      adminMelden(context, '${zahlen.length} Zeilen kopiert.');
    }
  }
}

class _Gruppe extends StatelessWidget {
  const _Gruppe({
    required this.verein,
    required this.szenario,
    required this.signatur,
    required this.zahlen,
  });

  final String verein;
  final String szenario;
  final String signatur;
  final List<AdminZahl> zahlen;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    final punkte = <int, List<AdminZahl>>{};
    for (final z in zahlen) {
      punkte.putIfAbsent(z.punktIndex, () => []).add(z);
    }
    final reihenfolge = punkte.keys.toList()..sort();

    return AdminBlock(
      titel: szenario,
      zusatz: '$verein · Signatur '
          '${signatur.isEmpty ? '—' : signatur.substring(0, 8)}',
      kinder: [
        for (final p in reihenfolge)
          Padding(
            padding: const EdgeInsets.only(bottom: PwSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                PwLabel('Entscheidungspunkt ${p + 1}'),
                const SizedBox(height: PwSpace.s3),
                for (final z in punkte[p]!
                  ..sort((a, b) => a.optionId.compareTo(b.optionId)))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            z.optionId.toUpperCase(),
                            style: t.labelMedium?.copyWith(color: c.textMuted),
                          ),
                        ),
                        Expanded(
                          child: _Balken(
                            anteil: z.anzahl /
                                punkte[p]!
                                    .fold<int>(0, (a, x) => a + x.anzahl),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${z.anzahl}', style: t.labelMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Balken extends StatelessWidget {
  const _Balken({required this.anteil});

  final double anteil;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PwRadius.pill),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: c.surfaceSunken)),
            FractionallySizedBox(
              widthFactor: anteil.clamp(0.0, 1.0),
              child: ColoredBox(color: c.actionPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
