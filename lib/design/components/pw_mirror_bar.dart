// PwMirrorBar — Einschaetzungsspiegel, DESIGN.md 4.10, Motion M21.
//
// Einordnung, keine Bewertung: der Balken zeigt, wie sich andere entschieden
// haben, nicht was richtig war.
import 'package:flutter/material.dart';

import '../../data/szenario_modelle.dart';
import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import 'pw_icons.dart';
import 'pw_stagger.dart';

enum PwMirrorZustand {
  /// Balken mit Anteilen.
  werte,

  /// Zaehlwerte werden geladen: Spur ohne Fuellung, Prozenttext als Strich.
  laedt,

  /// Zu wenige Einschaetzungen — der Empty-State, kein Fehler.
  zuWenige,

  /// Abruf gescheitert. Derselbe Block wie zuWenige, anderer Text.
  fehler,

  /// Kein Vereinscode eingetragen. Der Spiegel zeigt die Einschaetzungen des
  /// eigenen Teams — ohne Verein gibt es dieses Team nicht.
  ohneVerein,
}

class PwMirrorBar extends StatelessWidget {
  const PwMirrorBar({
    super.key,
    required this.optionen,
    required this.anteile,
    required this.eigeneWahl,
    required this.zustand,
  });

  final List<PwOption> optionen;

  /// optionId -> Prozent.
  final Map<String, int> anteile;

  final String? eigeneWahl;
  final PwMirrorZustand zustand;

  @override
  Widget build(BuildContext context) {
    final hinweis = switch (zustand) {
      PwMirrorZustand.fehler =>
        'Die Einschätzungen des Teams sind gerade nicht abrufbar.',
      PwMirrorZustand.ohneVerein =>
        'Für die Einschätzungen deines Teams fehlt der Vereinscode. Du kannst '
            'ihn in den Einstellungen eintragen.',
      PwMirrorZustand.zuWenige =>
        'Für diesen Entscheidungspunkt liegen noch zu wenige '
            'Einschätzungen vor. Sobald mehr Trainerinnen und Trainer ihn '
            'durchgespielt haben, siehst du hier, wie sie sich entschieden '
            'haben.',
      _ => null,
    };
    if (hinweis != null) return _Hinweis(text: hinweis);

    return PwStaffel(
      anzahl: optionen.length,
      dauer: PwDur.slow, // 360 ms
      builder: (ctx, werte) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < optionen.length; i++) ...[
            if (i > 0) const SizedBox(height: PwSpace.gapTight),
            _Zeile(
              option: optionen[i],
              anteil: anteile[optionen[i].id] ?? 0,
              eigene: eigeneWahl == optionen[i].id,
              laedt: zustand == PwMirrorZustand.laedt,
              fortschritt: werte[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.option,
    required this.anteil,
    required this.eigene,
    required this.laedt,
    required this.fortschritt,
  });

  final PwOption option;
  final int anteil;
  final bool eigene;
  final bool laedt;
  final double fortschritt;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    final fuellung = eigene
        ? c.actionPrimary
        : (context.isDark ? c.borderStrong : PwPalette.blue300);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: option.text,
                  style: t.bodyLarge,
                  children: [
                    if (eigene)
                      TextSpan(
                        text: '  deine Wahl',
                        style: t.bodyMedium?.copyWith(color: c.iconOnTint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: PwSpace.s4),
            // Prozentwerte stehen in Mono (DESIGN.md 2.6).
            Text(
              laedt ? '—' : '$anteil %',
              style: t.labelMedium?.copyWith(color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: PwSpace.s3),
        ClipRRect(
          borderRadius: BorderRadius.circular(PwRadius.pill),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: c.surfaceSunken)),
                if (!laedt)
                  FractionallySizedBox(
                    widthFactor: (anteil / 100 * fortschritt).clamp(0.0, 1.0),
                    child: ColoredBox(color: fuellung),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Hinweis extends StatelessWidget {
  const _Hinweis({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: PwRadius.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(PwIcons.users, size: 15, color: c.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: t.bodyMedium?.copyWith(color: c.textMuted)),
          ),
        ],
      ),
    );
  }
}
