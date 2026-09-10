// Vereinszuordnung: die Frage beim ersten Start, und was ohne Code gilt.
//
// Der wichtigste Punkt hier ist der letzte Test: ohne eingetragenen Verein
// darf die App keine Ansprechperson nennen. Im Buendel liegen die Angaben des
// Pilotvereins — sie als Vorgabe zu zeigen hiesse, jemandem aus einem anderen
// Verein eine fremde Kinderschutz-Adresse zu nennen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/spiegel_repository.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/szenario_repository.dart';
import 'package:pathwise/design/components/pw_contact_list.dart';
import 'package:pathwise/design/pathwise_theme.dart';
import 'package:pathwise/screens/uebersicht_screen.dart';
import 'package:pathwise/state/durchlauf_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'schriften.dart';
import 'verein_probe.dart';

const _frage = 'Bist du in einem Verein?';

void main() {
  late PwInhalt inhalt;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await schriftenLaden();
    SharedPreferences.setMockInitialValues({});
    inhalt = await const SzenarioRepository().laden();
  });

  group('Vereinsfrage beim ersten Start', () {
    /// Baut die Uebersicht und gibt den Behaelter zurueck, damit der Test den
    /// Fortschritt danach nachlesen kann.
    (Widget, ProviderContainer) huelle(Fortschritt f) {
      final container = ProviderContainer(
        overrides: [
          durchlaufProvider.overrideWith(
            () => DurchlaufNotifier(
              DurchlaufState(inhalt: inhalt, fortschritt: f),
              const FortschrittSpeicher(),
              const SpiegelRepository(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return (
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: pwTheme(dark: false),
            darkTheme: pwTheme(dark: true),
            themeMode: ThemeMode.dark,
            home: const UebersichtScreen(),
          ),
        ),
        container,
      );
    }

    testWidgets('legt sich nicht über die Erststart-Karte', (tester) async {
      final (widget, _) = huelle(const Fortschritt());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Die Erststart-Karte ist beim allerersten Oeffnen die Einfuehrung in
      // die App. Ein Sheet darueber verdeckt genau den Text, der erklaert,
      // worum es geht.
      expect(find.text(_frage), findsNothing);
      expect(
        find.text('Die meisten Situationen im Training sind nicht eindeutig.'),
        findsOneWidget,
      );
    });

    testWidgets('kommt, sobald die Erststart-Karte weg ist', (tester) async {
      final (widget, _) = huelle(const Fortschritt(erststartGesehen: true));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text(_frage), findsOneWidget);
    });

    testWidgets('"Später" schliesst sie und fragt nicht wieder',
        (tester) async {
      final (widget, container) =
          huelle(const Fortschritt(erststartGesehen: true));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Später'));
      await tester.pumpAndSettle();

      expect(find.text(_frage), findsNothing);
      expect(
        container.read(durchlaufProvider).fortschritt.vereinGefragt,
        isTrue,
      );

      // Ein weiterer Aufbau der Uebersicht darf sie nicht erneut oeffnen.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(_frage), findsNothing);
    });

    testWidgets('entfaellt, wenn schon ein Verein eingetragen ist',
        (tester) async {
      final (widget, _) = huelle(
        mitVerein(const Fortschritt(erststartGesehen: true), inhalt),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text(_frage), findsNothing);
    });
  });

  group('ohne Verein', () {
    test('nennt keine Ansprechperson und keinen Vereinsnamen', () {
      final s = DurchlaufState(inhalt: inhalt, fortschritt: const Fortschritt());

      expect(s.personen, isEmpty);
      expect(s.vereinName, isNull);
      expect(s.vereinId, isNull);

      // Die bundesweiten Nummern bleiben — sie sind ohne Verein richtig.
      expect(s.beratung, isNotEmpty);
      expect(s.beratung, inhalt.beratung);
    });

    test('mit Verein gelten dessen Angaben', () {
      final s = DurchlaufState(
        inhalt: inhalt,
        fortschritt: mitVerein(const Fortschritt(), inhalt),
      );

      expect(s.vereinName, inhalt.verein);
      expect(s.personen, inhalt.personen);
      expect(s.vereinId, probeVerein(inhalt).id);
    });

    testWidgets('die Kontaktliste zeigt den Hinweis statt fremder Namen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: pwTheme(dark: true),
          home: const Scaffold(
            body: PwContactList(verein: null, personen: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('sobald sein Code'), findsOneWidget);
      expect(find.text(inhalt.personen.first.name), findsNothing);
    });
  });

  group('Einschätzungsspiegel', () {
    test('zählt ohne Verein nicht', () async {
      // Ohne Verein gehoert die Zahl zu keinem Team. Der Aufruf muss
      // stillschweigend nichts tun — und darf nie werfen (DESIGN.md 8).
      await const SpiegelRepository().zaehlen(
        vereinId: null,
        szenarioId: 'egal',
        punktIndex: 0,
        optionId: 'a',
      );
    });

    test('lädt ohne Verein den eigenen Leerzustand', () async {
      final daten = await const SpiegelRepository().laden('egal');
      expect(daten.status, SpiegelStatus.ohneVerein);
    });
  });
}
