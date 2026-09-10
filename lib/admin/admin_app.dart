// Der Rahmen des Dashboards: links die Bereiche, rechts der Inhalt.
//
// Bewusst keine Routen und keine URLs: das Dashboard laeuft lokal in einem
// Tab, und ein Link darauf waere ein Link, den es nicht geben soll.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/components/pw_button.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_logo.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import 'admin_config.dart';
import 'admin_state.dart';
import 'seiten/rueckmeldungen_seite.dart';
import 'seiten/szenarien_seite.dart';
import 'seiten/vereine_seite.dart';
import 'seiten/zahlen_seite.dart';

enum AdminBereich {
  szenarien('Szenarien', PwIcons.listChecks),
  vereine('Vereine', PwIcons.users),
  rueckmeldungen('Rückmeldungen', PwIcons.messageSquare),
  zahlen('Zahlen', PwIcons.circleCheck);

  const AdminBereich(this.label, this.ikon);
  final String label;
  final IconData ikon;
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, this.hindernis});

  /// Wenn gesetzt, wird nur die Sperrseite gezeigt.
  final AdminHindernis? hindernis;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathwise — Verwaltung',
      debugShowCheckedModeBanner: false,
      theme: pwTheme(dark: false),
      darkTheme: pwTheme(dark: true),
      themeMode: ThemeMode.dark,
      home: hindernis == null
          ? const AdminRahmen()
          : _Sperrseite(hindernis: hindernis!),
    );
  }
}

class AdminRahmen extends StatefulWidget {
  const AdminRahmen({super.key});

  @override
  State<AdminRahmen> createState() => _AdminRahmenState();
}

class _AdminRahmenState extends State<AdminRahmen> {
  AdminBereich _bereich = AdminBereich.szenarien;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;

    return Scaffold(
      backgroundColor: c.surfacePage,
      body: Row(
        children: [
          _Seitenleiste(
            bereich: _bereich,
            onWechsel: (b) => setState(() => _bereich = b),
          ),
          Expanded(
            child: switch (_bereich) {
              AdminBereich.szenarien => const SzenarienSeite(),
              AdminBereich.vereine => const VereineSeite(),
              AdminBereich.rueckmeldungen => const RueckmeldungenSeite(),
              AdminBereich.zahlen => const ZahlenSeite(),
            },
          ),
        ],
      ),
    );
  }
}

class _Seitenleiste extends ConsumerWidget {
  const _Seitenleiste({required this.bereich, required this.onWechsel});

  final AdminBereich bereich;
  final ValueChanged<AdminBereich> onWechsel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        border: Border(right: BorderSide(color: c.borderSubtle)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PwSpace.gapTight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const PwLogo(groesse: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Verwaltung', style: t.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: PwSpace.gap),
              for (final b in AdminBereich.values) ...[
                _Eintrag(
                  bereich: b,
                  aktiv: b == bereich,
                  onTap: () => onWechsel(b),
                ),
                const SizedBox(height: PwSpace.s3),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(PwSpace.gapTight),
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
                  borderRadius: PwRadius.control,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(PwIcons.shield, size: 14, color: c.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Läuft lokal',
                            style: t.bodyMedium?.copyWith(color: c.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Der Schlüssel bleibt auf diesem Rechner. Schließen '
                      'beendet die Verwaltung.',
                      style: t.bodyMedium?.copyWith(color: c.textFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PwSpace.s3),
              PwButton(
                label: 'Alles neu laden',
                ikon: PwIcons.rotateCcw,
                vollBreite: true,
                onPressed: () {
                  ref.szenarienNeu();
                  ref.vereineNeu();
                  ref.rueckmeldungenNeu();
                  ref.zahlenNeu();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eintrag extends StatelessWidget {
  const _Eintrag({
    required this.bereich,
    required this.aktiv,
    required this.onTap,
  });

  final AdminBereich bereich;
  final bool aktiv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: PwSize.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: aktiv ? c.surfaceTint : Colors.transparent,
            borderRadius: PwRadius.control,
            border: Border.all(
              color: aktiv ? c.borderFocus : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                bereich.ikon,
                size: 16,
                color: aktiv ? c.iconOnTint : c.textMuted,
              ),
              const SizedBox(width: 11),
              Text(
                bereich.label,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: aktiv ? c.textOnTint : c.textBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Was zu sehen ist, wenn das Dashboard nicht starten darf.
class _Sperrseite extends StatelessWidget {
  const _Sperrseite({required this.hindernis});

  final AdminHindernis hindernis;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.surfacePage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PwSpace.gap),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(PwSpace.cardPadLg),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: PwRadius.card,
                border: Border.all(color: c.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const PwLogo(groesse: 28),
                      const SizedBox(width: 12),
                      Text('Pathwise — Verwaltung', style: t.titleMedium),
                    ],
                  ),
                  const SizedBox(height: PwSpace.gap),
                  Text(hindernis.titel,
                      style: t.displaySmall?.copyWith(fontSize: 24)),
                  const SizedBox(height: PwSpace.gapTight),
                  Text(hindernis.text, style: t.bodyLarge),
                  if (hindernis.befehl != null) ...[
                    const SizedBox(height: PwSpace.gap),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(PwSpace.gapTight),
                      decoration: BoxDecoration(
                        color: c.surfaceSunken,
                        borderRadius: PwRadius.control,
                      ),
                      child: SelectableText(
                        hindernis.befehl!,
                        style: t.labelMedium?.copyWith(color: c.textBody),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
