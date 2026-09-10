// PwContactList — DESIGN.md 4.11.
//
// Tippen oeffnet tel: bzw. mailto:. Schlaegt das fehl, wird der Kontakt in die
// Zwischenablage kopiert und ein ruhiger Hinweis gezeigt — kein Fehlerdialog.
import 'dart:math' as math;

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
                  const kreisGroesse = 34.0;
                  final kreis = Container(
                    width: kreisGroesse,
                    height: kreisGroesse,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PwIcons.user, size: 16, color: c.iconOnTint),
                  );

                  final namensStil = TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: c.textHeading,
                  );
                  final rollenStil =
                      t.bodyMedium?.copyWith(color: c.textMuted);

                  final namensblock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(person.name, style: namensStil),
                      Text(person.rolle, style: rollenStil),
                    ],
                  );

                  // Steht der Kontakt in einer eigenen Zeile, darf er
                  // umbrechen. Eine lange Adresse passt auf einem schmalen
                  // Telefon sonst auch dort nicht hinein, und abgeschnitten
                  // laesst sie sich nicht mehr abtippen.
                  Widget kontaktzeileMit({required bool umbruch}) => Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: umbruch
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: umbruch ? 3 : 0),
                            child: Icon(
                              person.perTelefon
                                  ? PwIcons.phone
                                  : PwIcons.mail,
                              size: 14,
                              color: c.textLink,
                            ),
                          ),
                          const SizedBox(width: PwSpace.s3),
                          Flexible(
                            child: Text(
                              person.kontakt,
                              style: kontaktStil,
                              softWrap: umbruch,
                              overflow: umbruch
                                  ? TextOverflow.clip
                                  : TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );

                  // Nebeneinander nur, wenn beides wirklich nebeneinander
                  // passt — sonst untereinander.
                  //
                  // Gemessen statt geraten: eine feste Schwelle war auf einem
                  // 393-dp-Telefon um drei Pixel zu niedrig, und "Kinder-
                  // schutzbeauftragter" brach mitten im Wort um. Ausgerechnet
                  // an der Stelle, an der jemand nachschlaegt, an wen er sich
                  // wendet. Das Messen traegt ausserdem die Textskalierung
                  // mit, gegen die keine feste Zahl bestehen kann
                  // (DESIGN.md 9: bis 200 Prozent ohne Ueberlauf).
                  double breiteVon(String text, TextStyle? stil) {
                    final maler = TextPainter(
                      text: TextSpan(text: text, style: stil),
                      textDirection: Directionality.of(ctx),
                      textScaler: MediaQuery.textScalerOf(ctx),
                      maxLines: 1,
                    )..layout();
                    return maler.width;
                  }

                  final blockBreite = math.max(
                    breiteVon(person.name, namensStil),
                    breiteVon(person.rolle, rollenStil),
                  );
                  final kontaktBreite = 14 +
                      PwSpace.s3 +
                      breiteVon(person.kontakt, kontaktStil);
                  // Kreis und sein Abstand gehen ab: sie stehen links davon,
                  // nicht in derselben Zeile.
                  final platz = constraints.maxWidth -
                      kreisGroesse -
                      PwSpace.gapTight;
                  final eng =
                      blockBreite + PwSpace.gapTight + kontaktBreite > platz;

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
                                  kontaktzeileMit(umbruch: true),
                                ],
                              )
                            : Row(
                                children: [
                                  // Der Kontakt zuerst, mit seiner natuerlichen
                                  // Breite: Flutter misst die starren Kinder
                                  // einer Row vor den flexiblen. Stand hier
                                  // frueher ein Flexible, schnappte sich der
                                  // Namensblock ueber Expanded allen Platz und
                                  // die Telefonnummer wurde abgeschnitten —
                                  // eine halbe Nummer ist schlimmer als ein
                                  // Umbruch.
                                  Expanded(child: namensblock),
                                  const SizedBox(width: PwSpace.gapTight),
                                  kontaktzeileMit(umbruch: false),
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
