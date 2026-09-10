// Was die Leute eingeschickt haben.
//
// Die App verspricht: „Jede Rückmeldung wird gelesen und bearbeitet." Diese
// Seite ist die Stelle, an der das eingelöst wird.
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

class RueckmeldungenSeite extends ConsumerStatefulWidget {
  const RueckmeldungenSeite({super.key});

  @override
  ConsumerState<RueckmeldungenSeite> createState() =>
      _RueckmeldungenSeiteState();
}

class _RueckmeldungenSeiteState extends ConsumerState<RueckmeldungenSeite> {
  bool _nurOffene = true;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.pw;

    return ListView(
      padding: const EdgeInsets.all(PwSpace.gap),
      children: [
        Text('Rückmeldungen', style: t.displaySmall?.copyWith(fontSize: 26)),
        const SizedBox(height: PwSpace.s4),
        Text(
          'Eingesandte Rückmeldungen und Situationen. Sie tragen keinen Bezug '
          'zu einem Gerät; eine E-Mail-Adresse steht nur dabei, wenn sie '
          'freiwillig angegeben wurde.',
          style: t.bodyMedium?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: PwSpace.gap),
        AdminLadeflaeche<List<AdminRueckmeldung>>(
          wert: ref.watch(rueckmeldungenProvider),
          bauen: (alle) {
            final offen = alle.where((r) => !r.bearbeitet).length;
            final sichtbar =
                _nurOffene ? alle.where((r) => !r.bearbeitet).toList() : alle;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$offen offen · ${alle.length} insgesamt',
                        style: t.bodyLarge,
                      ),
                    ),
                    PwButton(
                      label: _nurOffene ? 'Alle zeigen' : 'Nur offene',
                      groesse: PwButtonGroesse.sm,
                      onPressed: () => setState(() => _nurOffene = !_nurOffene),
                    ),
                  ],
                ),
                const SizedBox(height: PwSpace.gap),
                if (sichtbar.isEmpty)
                  Text(
                    _nurOffene
                        ? 'Nichts Offenes.'
                        : 'Noch keine Rückmeldungen.',
                    style: t.bodyMedium?.copyWith(color: c.textMuted),
                  ),
                for (final r in sichtbar) ...[
                  _RueckmeldungKarte(rueckmeldung: r),
                  const SizedBox(height: PwSpace.gapTight),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RueckmeldungKarte extends ConsumerWidget {
  const _RueckmeldungKarte({required this.rueckmeldung});

  final AdminRueckmeldung rueckmeldung;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;
    final r = rueckmeldung;

    return Container(
      padding: const EdgeInsets.all(PwSpace.gap),
      decoration: BoxDecoration(
        color: r.bearbeitet ? c.surfaceSunken : c.surfaceCard,
        borderRadius: PwRadius.card,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: PwLabel(r.artLabel)),
              Text(
                _datum(r.erstelltAm),
                style: t.labelMedium?.copyWith(color: c.textFaint),
              ),
            ],
          ),
          const SizedBox(height: PwSpace.s4),
          SelectableText(r.text, style: t.bodyLarge),
          if (r.email != null && r.email!.isNotEmpty) ...[
            const SizedBox(height: PwSpace.s4),
            Row(
              children: [
                Icon(PwIcons.mail, size: 14, color: c.textMuted),
                const SizedBox(width: 8),
                SelectableText(
                  r.email!,
                  style: t.bodyMedium?.copyWith(color: c.textLink),
                ),
              ],
            ),
          ],
          const SizedBox(height: PwSpace.gap),
          Wrap(
            spacing: PwSpace.s4,
            runSpacing: PwSpace.s4,
            children: [
              PwButton(
                label: r.bearbeitet ? 'Wieder öffnen' : 'Als bearbeitet merken',
                variante: r.bearbeitet
                    ? PwButtonVariante.secondary
                    : PwButtonVariante.primary,
                groesse: PwButtonGroesse.sm,
                ikon: r.bearbeitet ? PwIcons.rotateCcw : PwIcons.check,
                onPressed: () async {
                  await adminTun(
                    context,
                    () => ref
                        .read(adminRepositoryProvider)
                        .rueckmeldungBearbeitet(r.id, !r.bearbeitet),
                    erfolg: r.bearbeitet ? 'Wieder offen.' : 'Erledigt.',
                  );
                  ref.rueckmeldungenNeu();
                },
              ),
              PwButton(
                label: 'Text kopieren',
                groesse: PwButtonGroesse.sm,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: r.text));
                  if (context.mounted) adminMelden(context, 'Kopiert.');
                },
              ),
              PwButton(
                label: 'Löschen',
                groesse: PwButtonGroesse.sm,
                onPressed: () async {
                  final sicher = await adminBestaetigen(
                    context,
                    titel: 'Rückmeldung löschen?',
                    text: 'Sie ist danach weg. Das lässt sich nicht '
                        'rückgängig machen.',
                  );
                  if (!sicher || !context.mounted) return;
                  await adminTun(
                    context,
                    () => ref
                        .read(adminRepositoryProvider)
                        .rueckmeldungLoeschen(r.id),
                    erfolg: 'Gelöscht.',
                  );
                  ref.rueckmeldungenNeu();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _datum(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String zwei(int n) => n.toString().padLeft(2, '0');
    return '${zwei(l.day)}.${zwei(l.month)}.${l.year}, '
        '${zwei(l.hour)}:${zwei(l.minute)}';
  }
}
