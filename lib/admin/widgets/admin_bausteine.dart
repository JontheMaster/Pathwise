// Kleinteile, die auf mehreren Seiten des Dashboards vorkommen.
//
// Das Dashboard benutzt dieselben Farben, Abstaende und Schriften wie die App
// (lib/design). Es ist dasselbe Projekt, und zwei Gestaltungen zu pflegen
// waere Aufwand ohne Gegenwert.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/pw_button.dart';
import '../../design/components/pw_field.dart';
import '../../design/components/pw_icons.dart';
import '../../design/pathwise_theme.dart';
import '../../design/pathwise_tokens.dart';
import '../admin_modelle.dart';

/// Beschriftetes Textfeld. Haelt seinen Controller selbst, damit die
/// aufrufende Seite nur den Wert kennt.
class AdminFeld extends StatefulWidget {
  const AdminFeld({
    super.key,
    required this.label,
    required this.wert,
    required this.onGeaendert,
    this.zeilen = 1,
    this.platzhalter,
    this.hinweis,
    this.grossschreibung = false,
  });

  final String label;
  final String wert;
  final ValueChanged<String> onGeaendert;
  final int zeilen;
  final String? platzhalter;
  final String? hinweis;
  final bool grossschreibung;

  @override
  State<AdminFeld> createState() => _AdminFeldState();
}

class _AdminFeldState extends State<AdminFeld> {
  late final TextEditingController _regler =
      TextEditingController(text: widget.wert);

  @override
  void didUpdateWidget(AdminFeld alt) {
    super.didUpdateWidget(alt);
    // Nur nachziehen, wenn der Wert von aussen wirklich ein anderer ist —
    // sonst springt der Cursor bei jedem Tastendruck ans Ende.
    if (widget.wert != _regler.text) _regler.text = widget.wert;
  }

  @override
  void dispose() {
    _regler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PwField(
        label: widget.label,
        hinweis: widget.hinweis,
        child: PwInput(
          controller: _regler,
          zeilen: widget.zeilen,
          platzhalter: widget.platzhalter,
          grossschreibung: widget.grossschreibung,
          onChanged: widget.onGeaendert,
        ),
      );
}

/// Ein Abschnitt mit Ueberschrift und Rahmen.
class AdminBlock extends StatelessWidget {
  const AdminBlock({
    super.key,
    required this.titel,
    required this.kinder,
    this.aktion,
    this.zusatz,
  });

  final String titel;
  final List<Widget> kinder;
  final Widget? aktion;
  final String? zusatz;

  @override
  Widget build(BuildContext context) {
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
                    Text(titel, style: t.titleMedium),
                    if (zusatz != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        zusatz!,
                        style: t.bodyMedium?.copyWith(color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (aktion != null) ...[const SizedBox(width: 12), aktion!],
            ],
          ),
          for (final k in kinder) ...[const SizedBox(height: PwSpace.gap), k],
        ],
      ),
    );
  }
}

/// Statusmarke eines Szenarios.
class AdminStatusMarke extends StatelessWidget {
  const AdminStatusMarke({super.key, required this.status, this.fassung});

  final AdminStatus status;
  final int? fassung;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final veroeffentlicht = status == AdminStatus.veroeffentlicht;
    final farbe = veroeffentlicht ? c.levelOk : c.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: veroeffentlicht ? c.levelOkBg : c.surfaceSunken,
        borderRadius: BorderRadius.circular(PwRadius.pill),
        border: Border.all(color: veroeffentlicht ? farbe : c.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            veroeffentlicht ? PwIcons.circleCheck : PwIcons.fileText,
            size: 13,
            color: farbe,
          ),
          const SizedBox(width: 6),
          Text(
            fassung == null
                ? status.label
                : '${status.label} · Fassung $fassung',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: farbe,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fragt nach, bevor etwas unwiederbringlich verschwindet.
Future<bool> adminBestaetigen(
  BuildContext context, {
  required String titel,
  required String text,
  String knopf = 'Löschen',
}) async {
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
        title: Text(titel, style: t.titleLarge),
        content: Text(text, style: t.bodyLarge),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          PwButton(
            label: 'Abbrechen',
            variante: PwButtonVariante.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          PwButton(
            label: knopf,
            variante: PwButtonVariante.accent,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );
  return gewollt == true;
}

/// Ruhige Rueckmeldung am unteren Rand.
void adminMelden(BuildContext context, String text, {bool fehler = false}) {
  final c = context.pw;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: fehler ? c.statusDanger : c.surfaceInverse,
        content: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: PwPalette.white),
        ),
      ),
    );
}

/// Fuehrt [tun} aus und meldet Erfolg oder Fehler. Gibt zurueck, ob es
/// geklappt hat.
Future<bool> adminTun(
  BuildContext context,
  Future<void> Function() tun, {
  required String erfolg,
}) async {
  try {
    await tun();
    if (context.mounted) adminMelden(context, erfolg);
    return true;
  } catch (e) {
    if (context.mounted) {
      adminMelden(context, 'Nicht gespeichert: $e', fehler: true);
    }
    return false;
  }
}

/// Ladezustand und Fehler einer Liste, einheitlich.
class AdminLadeflaeche<T> extends StatelessWidget {
  const AdminLadeflaeche({
    super.key,
    required this.wert,
    required this.bauen,
    this.leerText,
  });

  final AsyncValue<T> wert;
  final Widget Function(T) bauen;
  final String? leerText;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return wert.when(
      data: bauen,
      loading: () => Padding(
        padding: const EdgeInsets.all(PwSpace.gap),
        child: Text('Wird geladen …',
            style: t.bodyMedium?.copyWith(color: c.textMuted)),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(PwSpace.gap),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: PwRadius.control,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nicht abrufbar', style: t.titleMedium),
            const SizedBox(height: PwSpace.s4),
            Text('$e', style: t.bodyMedium?.copyWith(color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}
