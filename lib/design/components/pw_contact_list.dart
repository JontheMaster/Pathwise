// PwContactList — DESIGN.md 4.11.
//
// Tippen oeffnet tel: bzw. mailto:. Schlaegt das fehl, wird der Kontakt in die
// Zwischenablage kopiert und ein ruhiger Hinweis gezeigt — kein Fehlerdialog.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/szenario_modelle.dart';
import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import 'pw_icons.dart';
import 'pw_label.dart';
import 'pw_press_scale.dart';

class PwContactList extends StatelessWidget {
  const PwContactList({
    super.key,
    required this.verein,
    required this.personen,
  });

  /// Null, solange kein Verein zugeordnet ist.
  final String? verein;

  final List<PwPerson> personen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PwLabel(
          verein == null ? 'Ansprechpersonen' : 'Ansprechpersonen · $verein',
        ),
        const SizedBox(height: 10),
        if (personen.isEmpty)
          const _OhneVerein()
        else
          for (var i = 0; i < personen.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _Zeile(person: personen[i]),
          ],
      ],
    );
  }
}

/// Ohne Vereinscode gibt es keine Ansprechpersonen — statt einer fremden
/// Adresse steht hier der Weg zu den eigenen.
class _OhneVerein extends StatelessWidget {
  const _OhneVerein();

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
            child: Text(
              'Die Ansprechpersonen deines Vereins erscheinen hier, sobald '
              'sein Code in den Einstellungen steht. Die Nummern unten helfen '
              'auch ohne ihn weiter.',
              style: t.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({required this.person});

  final PwPerson person;

  Future<void> _oeffnen(BuildContext context) async {
    var geklappt = false;
    try {
      geklappt = await launchUrl(person.ziel);
    } catch (_) {
      geklappt = false;
    }
    if (geklappt || !context.mounted) return;

    await Clipboard.setData(ClipboardData(text: person.kontakt));
    if (!context.mounted) return;
    final c = context.pw;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceInverse,
        content: Text(
          'Kontakt kopiert: ${person.kontakt}',
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

    // Telefonnummern stehen in Mono, Adressen im Fliesstext (DESIGN.md 2.6).
    final kontaktStil = person.perTelefon
        ? t.labelMedium?.copyWith(color: c.textLink)
        : TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: c.textLink,
          );

    return Semantics(
      button: true,
      label: '${person.name}, ${person.rolle}, ${person.kontakt}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _oeffnen(context),
          child: PwPressScale(
            child: Container(
              constraints: const BoxConstraints(minHeight: PwSize.touchMin),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: PwRadius.card,
                border: Border.all(color: c.borderSubtle),
                boxShadow: PwShadow.sm(context.isDark),
              ),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final kreis = Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PwIcons.user, size: 16, color: c.iconOnTint),
                  );

                  final namensblock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        person.name,
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: c.textHeading,
                        ),
                      ),
                      Text(
                        person.rolle,
                        style: t.bodyMedium?.copyWith(color: c.textMuted),
                      ),
                    ],
                  );

                  final kontaktzeile = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        person.perTelefon ? PwIcons.phone : PwIcons.mail,
                        size: 14,
                        color: c.textLink,
                      ),
                      const SizedBox(width: PwSpace.s3),
                      Flexible(
                        child: Text(
                          person.kontakt,
                          style: kontaktStil,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );

                  // Auf schmalen Geraeten steht der Kontakt unter Name und
                  // Rolle. Nebeneinander wuerde beides umbrechen und die
                  // Adresse abgeschnitten.
                  final eng = constraints.maxWidth < 330;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      kreis,
                      const SizedBox(width: PwSpace.gapTight),
                      Expanded(
                        child: eng
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  namensblock,
                                  const SizedBox(height: PwSpace.s3),
                                  kontaktzeile,
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: namensblock),
                                  const SizedBox(width: PwSpace.gapTight),
                                  Flexible(child: kontaktzeile),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
