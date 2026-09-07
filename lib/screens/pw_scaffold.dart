// Gemeinsames Geruest aller Screens — DESIGN.md 7.
//
// Kopfzeile, Inhalt, Fusszeile, dazu ab 900 dp die Seitenleiste. Kopf- und
// Fusszeile animieren nie mit dem Screen (DESIGN.md 6, letzter Absatz).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/szenario_modelle.dart';
import '../design/components/pw_help_bar.dart';
import '../design/components/pw_icon_button.dart';
import '../design/components/pw_icons.dart';
import '../design/components/pw_label.dart';
import '../design/components/pw_logo.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../state/durchlauf_state.dart';
import 'overlays.dart';

/// Ab dieser Fensterbreite gilt das Zweispalten-Layout (DESIGN.md 7).
const double kRailAb = 900;

/// Unter dieser Breite schrumpft das Seitenpolster und die Footer-Buttons
/// stehen untereinander.
const double kEngAb = 360;

/// Seitenpolster nach Fensterbreite (DESIGN.md 7, Responsive-Regeln).
double pwSeitenpolster(double breite) {
  if (breite < kEngAb) return PwSpace.gapTight;
  if (breite >= 600) return PwSpace.pagePadWide;
  return PwSpace.pagePad;
}

class PwScaffold extends ConsumerWidget {
  const PwScaffold({
    super.key,
    required this.titel,
    required this.inhalt,
    this.aktionen = const [],
    this.onZurueck,
    this.zeigtLogo = false,
    this.zeigtEinstellungen = false,
    this.zaehler,
    this.helpBar = true,
    this.onEinstellungen,
    this.onSzenarioOeffnen,
  });

  final String titel;

  /// Elemente des Inhaltsbereichs; dazwischen liegen 16 dp.
  final List<Widget> inhalt;

  /// Primaeraktion(en) der Fusszeile, oberhalb der HelpBar.
  final List<Widget> aktionen;

  /// Fehlt der Rueckweg, gilt der Screen als Wurzel (die Uebersicht).
  final VoidCallback? onZurueck;

  final bool zeigtLogo;
  final bool zeigtEinstellungen;

  /// Der Mono-Zaehler "2/3" im Punkt-Screen.
  final String? zaehler;

  /// Die HelpBar steht ueberall ausser in den Vereinsangaben.
  final bool helpBar;

  final VoidCallback? onEinstellungen;

  /// Sprung aus der Seitenleiste in ein Szenario.
  final void Function(PwSzenario)? onSzenarioOeffnen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pw;

    return Scaffold(
      backgroundColor: c.surfacePage,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final railAn = constraints.maxWidth >= kRailAb;
          final polster = pwSeitenpolster(constraints.maxWidth);

          final spalte = Column(
            children: [
              _Kopfzeile(
                titel: titel,
                onZurueck: onZurueck,
                // Bei aktiver Seitenleiste entfallen Logo und Zahnrad oben.
                zeigtLogo: zeigtLogo && !railAn,
                zeigtEinstellungen: zeigtEinstellungen && !railAn,
                zaehler: zaehler,
                onEinstellungen: onEinstellungen,
              ),
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(polster),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: PwSpace.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < inhalt.length; i++) ...[
                              if (i > 0) const SizedBox(height: PwSpace.gap),
                              inhalt[i],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _Fusszeile(
                polster: polster,
                aktionen: aktionen,
                helpBar: helpBar,
              ),
            ],
          );

          if (!railAn) return spalte;

          return Row(
            children: [
              _Seitenleiste(onSzenarioOeffnen: onSzenarioOeffnen),
              Expanded(child: spalte),
            ],
          );
        },
      ),
    );
  }
}

class _Kopfzeile extends StatelessWidget {
  const _Kopfzeile({
    required this.titel,
    required this.onZurueck,
    required this.zeigtLogo,
    required this.zeigtEinstellungen,
    required this.zaehler,
    required this.onEinstellungen,
  });

  final String titel;
  final VoidCallback? onZurueck;
  final bool zeigtLogo;
  final bool zeigtEinstellungen;
  final String? zaehler;
  final VoidCallback? onEinstellungen;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: c.glassBg,
            border: Border(bottom: BorderSide(color: c.borderSubtle)),
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(
                horizontal: PwSpace.gap,
                vertical: PwSpace.gapTight,
              ),
              child: Row(
                children: [
                  if (onZurueck != null) ...[
                    PwIconButton(
                      ikon: PwIcons.chevronLeft,
                      label: 'Zur Übersicht',
                      onPressed: onZurueck,
                    ),
                    const SizedBox(width: PwSpace.s4),
                  ],
                  if (zeigtLogo) ...[
                    const PwLogo(),
                    const SizedBox(width: PwSpace.gapTight),
                  ],
                  Expanded(
                    child: Text(
                      titel,
                      style: t.titleMedium,
                      maxLines: 1,
                      // Der Kopfzeilentitel ist die einzige Stelle mit Ellipse.
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (zaehler != null) ...[
                    const SizedBox(width: PwSpace.s4),
                    Text(
                      zaehler!,
                      style: t.labelMedium?.copyWith(
                        color: c.textFaint,
                        height: 1,
                      ),
                    ),
                  ],
                  const SizedBox(width: PwSpace.s4),
                  Builder(
                    builder: (ctx) => PwIconButton(
                      ikon: PwIcons.info,
                      label: 'So funktioniert Pathwise',
                      onPressed: () => infoSheetZeigen(ctx),
                    ),
                  ),
                  if (zeigtEinstellungen)
                    PwIconButton(
                      ikon: PwIcons.settings,
                      label: 'Einstellungen',
                      onPressed: onEinstellungen,
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

class _Fusszeile extends StatelessWidget {
  const _Fusszeile({
    required this.polster,
    required this.aktionen,
    required this.helpBar,
  });

  final double polster;
  final List<Widget> aktionen;
  final bool helpBar;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    if (aktionen.isEmpty && !helpBar) return const SizedBox.shrink();

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: c.glassBg,
            border: Border(top: BorderSide(color: c.borderSubtle)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(polster, 12, polster, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: PwSpace.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final a in aktionen) ...[
                        a,
                        const SizedBox(height: 10),
                      ],
                      if (helpBar)
                        Builder(
                          builder: (ctx) =>
                              PwHelpBar(onTap: () => hilfeSheetZeigen(ctx)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Seitenleiste ersetzt keine Navigation, sie spiegelt sie: dieselben
/// Ziele, dieselben Zustandstexte (DESIGN.md 7).
class _Seitenleiste extends ConsumerWidget {
  const _Seitenleiste({required this.onSzenarioOeffnen});

  final void Function(PwSzenario)? onSzenarioOeffnen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;
    final s = ref.watch(durchlaufProvider);

    return Container(
      width: PwSpace.railWidth,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        border: Border(right: BorderSide(color: c.borderSubtle)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const PwLogo(groesse: 26),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Pathwise', style: t.titleMedium)),
                  PwIconButton(
                    ikon: PwIcons.settings,
                    label: 'Einstellungen',
                    onPressed: () => einstellungenOeffnen(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const PwLabel('Szenarien'),
              const SizedBox(height: PwSpace.s4),
              // Die Liste scrollt; der Block darunter bleibt stehen. Sonst
              // laeuft die Leiste auf niedrigen Fenstern ueber.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final sz in s.inhalt.szenarien) ...[
                        _RailEintrag(
                          szenario: sz,
                          status: s.status(sz).label,
                          onTap: () => onSzenarioOeffnen?.call(sz),
                        ),
                        const SizedBox(height: PwSpace.s4),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: PwSpace.s4),
              PwHelpBar(onTap: () => hilfeSheetZeigen(context)),
              const SizedBox(height: 10),
              _RailLink(
                ikon: PwIcons.info,
                text: 'So funktioniert Pathwise',
                onTap: () => infoSheetZeigen(context),
              ),
              const SizedBox(height: 10),
              _RailLink(
                ikon: PwIcons.messageSquare,
                text: 'Rückmeldung geben',
                onTap: () => rueckmeldungSheetZeigen(context),
              ),
              const SizedBox(height: 10),
              Text(
                'Freiwillig, ohne Anmeldung, kein Nachweis.',
                style: t.bodyMedium?.copyWith(color: c.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailEintrag extends StatefulWidget {
  const _RailEintrag({
    required this.szenario,
    required this.status,
    required this.onTap,
  });

  final PwSzenario szenario;
  final String status;
  final VoidCallback onTap;

  @override
  State<_RailEintrag> createState() => _RailEintragState();
}

class _RailEintragState extends State<_RailEintrag> {
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
        child: Container(
          constraints: const BoxConstraints(minHeight: PwSize.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: c.surfacePage,
            borderRadius: PwRadius.control,
            border: Border.all(
              color: _darueber ? c.borderStrong : c.borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.szenario.titel,
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: c.textHeading,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.status,
                      style: t.bodyMedium?.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailLink extends StatelessWidget {
  const _RailLink({
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
    );
  }
}
