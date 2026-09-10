// Vereine, ihre Ansprechpersonen und die Beratungsstellen.
//
// Was hier steht, erscheint in der App am Ende jedes Szenarios und in der
// Beratungsleiste. Eine falsche Nummer ist hier teurer als anderswo: jemand
// koennte einen Verdacht an die falsche Stelle schreiben.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/pw_button.dart';
import '../../design/components/pw_icons.dart';
import '../../design/components/pw_label.dart';
import '../../design/pathwise_theme.dart';
import '../../design/pathwise_tokens.dart';
import '../admin_modelle.dart';
import '../admin_state.dart';
import '../widgets/admin_bausteine.dart';

class VereineSeite extends ConsumerWidget {
  const VereineSeite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text('Vereine',
                      style: t.displaySmall?.copyWith(fontSize: 26)),
                  const SizedBox(height: PwSpace.s4),
                  Text(
                    'Ein Gerät erfährt seinen Verein über den Code. Ohne Code '
                    'zeigt die App keine Ansprechpersonen — nur die '
                    'bundesweiten Nummern.',
                    style: t.bodyMedium?.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PwSpace.gap),
            PwButton(
              label: 'Neuer Verein',
              variante: PwButtonVariante.accent,
              ikon: PwIcons.plus,
              onPressed: () => _neuerVerein(context, ref),
            ),
          ],
        ),
        const SizedBox(height: PwSpace.gap),
        AdminLadeflaeche<List<AdminVerein>>(
          wert: ref.watch(vereineProvider),
          bauen: (vereine) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vereine.isEmpty)
                Text('Noch kein Verein angelegt.',
                    style: t.bodyMedium?.copyWith(color: c.textMuted)),
              for (final v in vereine) ...[
                _VereinBlock(verein: v),
                const SizedBox(height: PwSpace.gap),
              ],
            ],
          ),
        ),
        const SizedBox(height: PwSpace.gap),
        _BundesweiteBeratung(),
      ],
    );
  }

  Future<void> _neuerVerein(BuildContext context, WidgetRef ref) async {
    final daten = await _vereinsdatenErfragen(context);
    if (daten == null || !context.mounted) return;

    await adminTun(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .vereinAnlegen(code: daten.$1, name: daten.$2),
      erfolg: 'Verein angelegt.',
    );
    ref.vereineNeu();
  }
}

/// Fragt Code und Name ab. Null, wenn abgebrochen.
Future<(String, String)?> _vereinsdatenErfragen(
  BuildContext context, {
  String code = '',
  String name = '',
}) {
  var c1 = code;
  var n1 = name;

  return showDialog<(String, String)>(
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
        title: Text(code.isEmpty ? 'Neuer Verein' : 'Verein ändern',
            style: t.titleLarge),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminFeld(
                label: 'Vereinscode',
                wert: c1,
                grossschreibung: true,
                platzhalter: 'POSTSV-2026',
                hinweis: 'Vier bis 32 Zeichen. Den geben die Trainerinnen und '
                    'Trainer einmal ein.',
                onGeaendert: (v) => c1 = v,
              ),
              const SizedBox(height: PwSpace.gap),
              AdminFeld(
                label: 'Name',
                wert: n1,
                onGeaendert: (v) => n1 = v,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          PwButton(
            label: 'Abbrechen',
            variante: PwButtonVariante.ghost,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          PwButton(
            label: 'Übernehmen',
            variante: PwButtonVariante.accent,
            onPressed: () {
              if (c1.trim().length < 4 || n1.trim().isEmpty) {
                adminMelden(ctx, 'Code und Name werden beide gebraucht.',
                    fehler: true);
                return;
              }
              Navigator.of(ctx).pop((c1, n1));
            },
          ),
        ],
      );
    },
  );
}

class _VereinBlock extends ConsumerWidget {
  const _VereinBlock({required this.verein});

  final AdminVerein verein;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return AdminBlock(
      titel: verein.name,
      zusatz: 'Code ${verein.code}${verein.aktiv ? '' : ' · abgeschaltet'}',
      aktion: Wrap(
        spacing: PwSpace.s4,
        children: [
          PwButton(
            label: 'Ändern',
            groesse: PwButtonGroesse.sm,
            onPressed: () => _aendern(context, ref),
          ),
          PwButton(
            label: verein.aktiv ? 'Abschalten' : 'Anschalten',
            groesse: PwButtonGroesse.sm,
            onPressed: () => _umschalten(context, ref),
          ),
          PwButton(
            label: 'Löschen',
            groesse: PwButtonGroesse.sm,
            onPressed: () => _loeschen(context, ref),
          ),
        ],
      ),
      kinder: [
        Row(
          children: [
            const Expanded(child: PwLabel('Ansprechpersonen')),
            PwButton(
              label: 'Person',
              ikon: PwIcons.plus,
              groesse: PwButtonGroesse.sm,
              onPressed: () => _person(context, ref, null),
            ),
          ],
        ),
        if (verein.personen.isEmpty)
          Text(
            'Keine. Die App zeigt dann für diesen Verein nur die '
            'bundesweiten Nummern.',
            style: t.bodyMedium?.copyWith(color: c.textMuted),
          ),
        for (final p in verein.personen)
          _Zeile(
            titel: p.name,
            zusatz: '${p.rolle} · ${p.kontakt}',
            ikon: p.perTelefon ? PwIcons.phone : PwIcons.mail,
            onAendern: () => _person(context, ref, p),
            onLoeschen: () => _personLoeschen(context, ref, p),
          ),
        Row(
          children: [
            const Expanded(child: PwLabel('Eigene Beratungsstellen')),
            PwButton(
              label: 'Stelle',
              ikon: PwIcons.plus,
              groesse: PwButtonGroesse.sm,
              onPressed: () => _beratung(context, ref, null),
            ),
          ],
        ),
        if (verein.beratung.isEmpty)
          Text(
            'Keine eigenen. Die bundesweiten Stellen gelten trotzdem.',
            style: t.bodyMedium?.copyWith(color: c.textMuted),
          ),
        for (final b in verein.beratung)
          _Zeile(
            titel: b.titel,
            zusatz: '${b.zusatz} · ${b.nummer}',
            ikon: PwIcons.lifeBuoy,
            onAendern: () => _beratung(context, ref, b),
            onLoeschen: () => _beratungLoeschen(context, ref, b),
          ),
      ],
    );
  }

  Future<void> _aendern(BuildContext context, WidgetRef ref) async {
    final daten = await _vereinsdatenErfragen(
      context,
      code: verein.code,
      name: verein.name,
    );
    if (daten == null || !context.mounted) return;

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).vereinSichern(
            AdminVerein(
              id: verein.id,
              code: daten.$1,
              name: daten.$2,
              aktiv: verein.aktiv,
            ),
          ),
      erfolg: 'Gespeichert.',
    );
    ref.vereineNeu();
  }

  Future<void> _umschalten(BuildContext context, WidgetRef ref) async {
    if (verein.aktiv) {
      final sicher = await adminBestaetigen(
        context,
        titel: 'Verein abschalten?',
        text: 'Der Code funktioniert danach nicht mehr. Geräte, die ihn schon '
            'eingetragen haben, fallen auf die bundesweiten Nummern zurück.',
        knopf: 'Abschalten',
      );
      if (!sicher || !context.mounted) return;
    }

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).vereinSichern(
            AdminVerein(
              id: verein.id,
              code: verein.code,
              name: verein.name,
              aktiv: !verein.aktiv,
            ),
          ),
      erfolg: verein.aktiv ? 'Abgeschaltet.' : 'Angeschaltet.',
    );
    ref.vereineNeu();
  }

  Future<void> _loeschen(BuildContext context, WidgetRef ref) async {
    final sicher = await adminBestaetigen(
      context,
      titel: 'Verein löschen?',
      text: 'Der Verein, seine Ansprechpersonen, seine Beratungsstellen und '
          'alle Zählwerte seines Teams verschwinden. Wer ihn nur stilllegen '
          'will, schaltet ihn besser ab.',
    );
    if (!sicher || !context.mounted) return;

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).vereinLoeschen(verein.id),
      erfolg: 'Verein gelöscht.',
    );
    ref.vereineNeu();
  }

  Future<void> _person(
    BuildContext context,
    WidgetRef ref,
    AdminPerson? vorhanden,
  ) async {
    final neu = await _personErfragen(context, verein.id, vorhanden);
    if (neu == null || !context.mounted) return;

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).personSichern(neu),
      erfolg: 'Gespeichert.',
    );
    ref.vereineNeu();
  }

  Future<void> _personLoeschen(
    BuildContext context,
    WidgetRef ref,
    AdminPerson p,
  ) async {
    final sicher = await adminBestaetigen(
      context,
      titel: 'Ansprechperson entfernen?',
      text: '${p.name} steht danach nicht mehr in der App.',
      knopf: 'Entfernen',
    );
    if (!sicher || !context.mounted || p.id == null) return;

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).personLoeschen(p.id!),
      erfolg: 'Entfernt.',
    );
    ref.vereineNeu();
  }

  Future<void> _beratung(
    BuildContext context,
    WidgetRef ref,
    AdminBeratung? vorhanden,
  ) async {
    final neu = await _beratungErfragen(context, verein.id, vorhanden);
    if (neu == null || !context.mounted) return;

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).beratungSichern(neu),
      erfolg: 'Gespeichert.',
    );
    ref.vereineNeu();
  }

  Future<void> _beratungLoeschen(
    BuildContext context,
    WidgetRef ref,
    AdminBeratung b,
  ) async {
    final sicher = await adminBestaetigen(
      context,
      titel: 'Beratungsstelle entfernen?',
      text: '${b.titel} steht danach nicht mehr in der App.',
      knopf: 'Entfernen',
    );
    if (!sicher || !context.mounted || b.id == null) return;

    await adminTun(
      context,
      () => ref.read(adminRepositoryProvider).beratungLoeschen(b.id!),
      erfolg: 'Entfernt.',
    );
    ref.vereineNeu();
  }
}

class _BundesweiteBeratung extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return AdminLadeflaeche<List<AdminBeratung>>(
      wert: ref.watch(beratungBundesweitProvider),
      bauen: (stellen) => AdminBlock(
        titel: 'Bundesweite Beratung',
        zusatz: 'Gilt für alle Vereine — und als einziges auch für Geräte '
            'ohne Vereinscode.',
        aktion: PwButton(
          label: 'Stelle',
          ikon: PwIcons.plus,
          groesse: PwButtonGroesse.sm,
          onPressed: () async {
            final neu = await _beratungErfragen(context, null, null);
            if (neu == null || !context.mounted) return;
            await adminTun(
              context,
              () => ref.read(adminRepositoryProvider).beratungSichern(neu),
              erfolg: 'Gespeichert.',
            );
            ref.vereineNeu();
          },
        ),
        kinder: [
          if (stellen.isEmpty)
            Text(
              'Keine. Dann steht in der Beratungsleiste nichts — und ohne '
              'Vereinscode hat die App gar keine Nummer mehr.',
              style: t.bodyMedium?.copyWith(color: c.statusDanger),
            ),
          for (final b in stellen)
            _Zeile(
              titel: b.titel,
              zusatz: '${b.zusatz} · ${b.nummer}',
              ikon: PwIcons.lifeBuoy,
              onAendern: () async {
                final neu = await _beratungErfragen(context, null, b);
                if (neu == null || !context.mounted) return;
                await adminTun(
                  context,
                  () => ref.read(adminRepositoryProvider).beratungSichern(neu),
                  erfolg: 'Gespeichert.',
                );
                ref.vereineNeu();
              },
              onLoeschen: () async {
                final sicher = await adminBestaetigen(
                  context,
                  titel: 'Stelle entfernen?',
                  text: '${b.titel} steht danach in keiner App mehr.',
                  knopf: 'Entfernen',
                );
                if (!sicher || !context.mounted || b.id == null) return;
                await adminTun(
                  context,
                  () =>
                      ref.read(adminRepositoryProvider).beratungLoeschen(b.id!),
                  erfolg: 'Entfernt.',
                );
                ref.vereineNeu();
              },
            ),
        ],
      ),
    );
  }
}

Future<AdminPerson?> _personErfragen(
  BuildContext context,
  String vereinId,
  AdminPerson? vorhanden,
) {
  var name = vorhanden?.name ?? '';
  var rolle = vorhanden?.rolle ?? '';
  var kontakt = vorhanden?.kontakt ?? '';
  var perTelefon = vorhanden?.perTelefon ?? false;

  return showDialog<AdminPerson>(
    context: context,
    barrierColor: context.pw.surfaceOverlay,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setzen) {
        final c = ctx.pw;
        final t = Theme.of(ctx).textTheme;
        return AlertDialog(
          backgroundColor: c.surfaceCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: PwRadius.dialog,
            side: BorderSide(color: c.borderSubtle),
          ),
          title: Text(
            vorhanden == null ? 'Neue Ansprechperson' : 'Ansprechperson ändern',
            style: t.titleLarge,
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminFeld(
                    label: 'Name',
                    wert: name,
                    onGeaendert: (v) => name = v,
                  ),
                  const SizedBox(height: PwSpace.gap),
                  AdminFeld(
                    label: 'Rolle',
                    wert: rolle,
                    platzhalter: 'Kinderschutzbeauftragter',
                    onGeaendert: (v) => rolle = v,
                  ),
                  const SizedBox(height: PwSpace.gap),
                  AdminFeld(
                    label: 'Kontakt',
                    wert: kontakt,
                    hinweis: perTelefon
                        ? 'Wird in der App als Anruf geöffnet.'
                        : 'Wird in der App als E-Mail geöffnet.',
                    onGeaendert: (v) => kontakt = v,
                  ),
                  const SizedBox(height: PwSpace.gap),
                  Row(
                    children: [
                      PwButton(
                        label: 'E-Mail',
                        groesse: PwButtonGroesse.sm,
                        variante: perTelefon
                            ? PwButtonVariante.secondary
                            : PwButtonVariante.primary,
                        onPressed: () => setzen(() => perTelefon = false),
                      ),
                      const SizedBox(width: PwSpace.s4),
                      PwButton(
                        label: 'Telefon',
                        groesse: PwButtonGroesse.sm,
                        variante: perTelefon
                            ? PwButtonVariante.primary
                            : PwButtonVariante.secondary,
                        onPressed: () => setzen(() => perTelefon = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            PwButton(
              label: 'Abbrechen',
              variante: PwButtonVariante.ghost,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            PwButton(
              label: 'Übernehmen',
              variante: PwButtonVariante.accent,
              onPressed: () {
                if (name.trim().isEmpty ||
                    rolle.trim().isEmpty ||
                    kontakt.trim().isEmpty) {
                  adminMelden(ctx, 'Name, Rolle und Kontakt werden gebraucht.',
                      fehler: true);
                  return;
                }
                Navigator.of(ctx).pop(AdminPerson(
                  id: vorhanden?.id,
                  vereinId: vereinId,
                  name: name.trim(),
                  rolle: rolle.trim(),
                  kontakt: kontakt.trim(),
                  perTelefon: perTelefon,
                  reihenfolge: vorhanden?.reihenfolge ?? 0,
                ));
              },
            ),
          ],
        );
      },
    ),
  );
}

Future<AdminBeratung?> _beratungErfragen(
  BuildContext context,
  String? vereinId,
  AdminBeratung? vorhanden,
) {
  var titel = vorhanden?.titel ?? '';
  var zusatz = vorhanden?.zusatz ?? '';
  var nummer = vorhanden?.nummer ?? '';

  return showDialog<AdminBeratung>(
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
        title: Text(
          vorhanden == null ? 'Neue Beratungsstelle' : 'Beratungsstelle ändern',
          style: t.titleLarge,
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminFeld(
                  label: 'Titel',
                  wert: titel,
                  onGeaendert: (v) => titel = v,
                ),
                const SizedBox(height: PwSpace.gap),
                AdminFeld(
                  label: 'Zusatz',
                  wert: zusatz,
                  platzhalter: 'anonym und kostenfrei, bundesweit',
                  onGeaendert: (v) => zusatz = v,
                ),
                const SizedBox(height: PwSpace.gap),
                AdminFeld(
                  label: 'Nummer',
                  wert: nummer,
                  hinweis: 'Wird in der App als Anruf geöffnet.',
                  onGeaendert: (v) => nummer = v,
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          PwButton(
            label: 'Abbrechen',
            variante: PwButtonVariante.ghost,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          PwButton(
            label: 'Übernehmen',
            variante: PwButtonVariante.accent,
            onPressed: () {
              if (titel.trim().isEmpty || nummer.trim().isEmpty) {
                adminMelden(ctx, 'Titel und Nummer werden gebraucht.',
                    fehler: true);
                return;
              }
              Navigator.of(ctx).pop(AdminBeratung(
                id: vorhanden?.id,
                vereinId: vereinId,
                titel: titel.trim(),
                zusatz: zusatz.trim(),
                nummer: nummer.trim(),
                reihenfolge: vorhanden?.reihenfolge ?? 0,
              ));
            },
          ),
        ],
      );
    },
  );
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.titel,
    required this.zusatz,
    required this.ikon,
    required this.onAendern,
    required this.onLoeschen,
  });

  final String titel;
  final String zusatz;
  final IconData ikon;
  final VoidCallback onAendern;
  final VoidCallback onLoeschen;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(PwSpace.gapTight),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: PwRadius.control,
      ),
      child: Row(
        children: [
          Icon(ikon, size: 16, color: c.textMuted),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titel, style: t.bodyLarge),
                Text(zusatz,
                    style: t.bodyMedium?.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          PwButton(
            label: 'Ändern',
            groesse: PwButtonGroesse.sm,
            onPressed: onAendern,
          ),
          const SizedBox(width: PwSpace.s4),
          PwButton(
            label: 'Weg',
            groesse: PwButtonGroesse.sm,
            onPressed: onLoeschen,
          ),
        ],
      ),
    );
  }
}
