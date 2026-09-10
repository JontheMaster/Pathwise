// Vereinscode eintragen, prüfen und wieder entfernen.
//
// Dasselbe Feld steht an zwei Stellen: beim ersten Start (übersprungbar) und
// in den Einstellungen. Deshalb liegt es hier und nicht in einem der beiden
// Screens.
//
// Der Code ist kein Login. Er ordnet ein Gerät einem Verein zu, damit die
// Ansprechpersonen stimmen und der Einschätzungsspiegel die Zahlen des eigenen
// Teams zeigt. Ohne Code läuft die App vollständig weiter (DESIGN.md 8).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/verein_repository.dart';
import '../design/components/pw_button.dart';
import '../design/components/pw_field.dart';
import '../design/components/pw_icons.dart';
import '../design/pathwise_theme.dart';
import '../design/pathwise_tokens.dart';
import '../state/durchlauf_state.dart';

class PwVereinscodeFeld extends ConsumerStatefulWidget {
  const PwVereinscodeFeld({super.key, this.onGefunden});

  /// Wird nach einem erfolgreichen Nachschlagen gerufen — der Erststart
  /// schließt darüber seinen Schritt ab.
  final VoidCallback? onGefunden;

  @override
  ConsumerState<PwVereinscodeFeld> createState() => _PwVereinscodeFeldState();
}

class _PwVereinscodeFeldState extends ConsumerState<PwVereinscodeFeld> {
  final _eingabe = TextEditingController();
  bool _laeuft = false;
  String? _fehler;

  @override
  void dispose() {
    _eingabe.dispose();
    super.dispose();
  }

  Future<void> _pruefen() async {
    final code = _eingabe.text.trim();
    if (code.isEmpty || _laeuft) return;

    setState(() {
      _laeuft = true;
      _fehler = null;
    });

    final antwort = await const VereinRepository().nachschlagen(code);
    if (!mounted) return;

    switch (antwort.ergebnis) {
      case PwCodeErgebnis.gefunden:
        ref.read(durchlaufProvider.notifier).vereinSetzen(antwort.verein!);
        _eingabe.clear();
        setState(() => _laeuft = false);
        widget.onGefunden?.call();
      case PwCodeErgebnis.unbekannt:
        setState(() {
          _laeuft = false;
          _fehler = 'Diesen Code kennen wir nicht. Er wird im Verein '
              'vergeben — frag dort nach.';
        });
      case PwCodeErgebnis.nichtErreichbar:
        setState(() {
          _laeuft = false;
          _fehler = 'Der Code lässt sich gerade nicht prüfen. Versuch es '
              'später noch einmal.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final verein = ref.watch(durchlaufProvider).verein;
    return verein == null ? _eingabefeld(context) : _zugeordnet(context);
  }

  Widget _eingabefeld(BuildContext context) => PwField(
        label: 'Vereinscode',
        hinweis: 'Ohne Code bleiben die bundesweiten Nummern. Du kannst ihn '
            'jederzeit nachtragen.',
        fehler: _fehler,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PwInput(
                controller: _eingabe,
                platzhalter: 'z. B. POSTSV-2026',
                aktiv: !_laeuft,
                ungueltig: _fehler != null,
                // Codes stehen in Großbuchstaben; die Datenbank hebt selbst an,
                // aber das Feld soll zeigen, wie er aussieht.
                grossschreibung: true,
                onChanged: (_) {
                  if (_fehler != null) setState(() => _fehler = null);
                },
                onAbgeschickt: (_) => _pruefen(),
              ),
            ),
            const SizedBox(width: PwSpace.s4),
            PwButton(
              label: 'Prüfen',
              variante: PwButtonVariante.primary,
              laedt: _laeuft,
              onPressed: _laeuft ? null : _pruefen,
            ),
          ],
        ),
      );

  Widget _zugeordnet(BuildContext context) {
    final s = ref.watch(durchlaufProvider);
    final c = context.pw;
    final t = Theme.of(context).textTheme;
    final verein = s.verein!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: c.surfaceTint,
            borderRadius: PwRadius.control,
            border: Border.all(color: c.borderFocus),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(PwIcons.check, size: 16, color: c.iconOnTint),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      verein.name,
                      style: t.bodyLarge?.copyWith(
                        color: c.textOnTint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code ${verein.code}',
                      style: t.labelMedium?.copyWith(color: c.textOnTintMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PwSpace.gapTight),
        PwButton(
          label: 'Verein entfernen',
          groesse: PwButtonGroesse.sm,
          onPressed: () =>
              ref.read(durchlaufProvider.notifier).vereinEntfernen(),
        ),
      ],
    );
  }
}
