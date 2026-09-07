// Ein vollstaendiger Durchlauf in der echten Laufzeit — nicht im Test-Renderer.
//
// Laeuft auf jedem Ziel, das Flutter ansteuern kann:
//   flutter test integration_test -d windows
//   flutter test integration_test -d chrome      (braucht chromedriver)
//   flutter test integration_test -d emulator-5554
//
// Geprueft wird, was Widget-Tests nicht abdecken: dass die App wirklich
// startet, die Assets aus dem Buendel liest, Supabase initialisiert und sich
// mit echten Gesten bedienen laesst.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pathwise/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Jeder Lauf beginnt beim Erststart.
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await p.clear();
  });

  /// Tippt auf [finder], nachdem es in den sichtbaren Bereich gescrollt wurde.
  Future<void> tippen(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  testWidgets('Übersicht bis Auswertung', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // S1: Erststart-Karte steht, die drei Szenarien sind da.
    expect(find.text('Pathwise'), findsWidgets);
    expect(
      find.text('Die meisten Situationen im Training sind nicht eindeutig.'),
      findsOneWidget,
    );
    expect(find.text('Vor dem Heimspiel'), findsOneWidget);
    expect(find.text('Die Hilfestellung'), findsOneWidget);
    expect(find.text('Der zuverlässige Co-Trainer'), findsOneWidget);

    // S2: Einstieg über die Erststart-Karte.
    await tippen(tester, find.text('Erstes Szenario ansehen'));
    expect(find.text('Vorgeschichte'.toUpperCase()), findsOneWidget);
    expect(find.text('Szenario beginnen'), findsOneWidget);

    // S3: drei Entscheidungspunkte.
    await tippen(tester, find.text('Szenario beginnen'));
    expect(find.text('Entscheidungspunkt 1 von 3'), findsOneWidget);
    expect(find.text('Situation nachlesen'), findsOneWidget);
    // Vor der Wahl ist "Weiter" gesperrt.
    expect(
      tester.widget<TextButton>(
        find.ancestor(of: find.text('Weiter'), matching: find.byType(TextButton)),
      ).onPressed,
      isNull,
    );

    for (var punkt = 1; punkt <= 3; punkt++) {
      expect(find.text('Entscheidungspunkt $punkt von 3'), findsOneWidget);

      // Die erste Handlungsoption waehlen.
      final leitfrage = find.textContaining('?');
      expect(leitfrage, findsWidgets, reason: 'Leitfrage bei Punkt $punkt');
      await tester.pumpAndSettle();

      final optionA = find.byType(Semantics).evaluate().isNotEmpty;
      expect(optionA, isTrue);

      // Option A ist die erste Optionskarte unter der Leitfrage.
      final buchstabe = find.text('A');
      await tippen(tester, buchstabe);

      // Nach der Wahl erscheint die abrufbare Einordnung.
      expect(find.text('Fachliche Einordnung anzeigen'), findsOneWidget);

      if (punkt == 1) {
        // Einmal aufklappen: Erkennen, Absichern, Handeln.
        await tippen(tester, find.text('Fachliche Einordnung anzeigen'));
        expect(find.text('ERKENNEN'), findsOneWidget);
        expect(find.text('ABSICHERN'), findsOneWidget);
        expect(find.text('HANDELN'), findsOneWidget);
        await tippen(tester, find.text('Fachliche Einordnung ausblenden'));
      }

      await tippen(tester, find.text(punkt < 3 ? 'Weiter' : 'Auswertung'));
    }

    // S4: Auswertung mit allen drei Ampelstufen.
    expect(
      find.text('Was war unbedenklich, was klärungsbedürftig?'),
      findsOneWidget,
    );
    expect(find.text('UNBEDENKLICH'), findsOneWidget);
    expect(find.text('KLÄRUNGSBEDÜRFTIG'), findsOneWidget);
    expect(find.text('GRENZVERLETZEND'), findsOneWidget);
    expect(find.text('EINSCHÄTZUNGSSPIEGEL'), findsOneWidget);
    expect(find.text('ANSPRECHPERSONEN · POST SV NÜRNBERG'), findsOneWidget);

    // Zurück zur Übersicht: das Szenario gilt als abgeschlossen.
    await tippen(tester, find.text('Zur Übersicht'));
    expect(find.text('Abgeschlossen'), findsOneWidget);
  });

  testWidgets('Overlays öffnen und schließen', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Hilfe-Sheet über die Beratungsleiste.
    await tippen(tester, find.text('Hilfetelefon Sexueller Missbrauch').first);
    expect(find.text('Hilfe und Beratung'), findsOneWidget);
    expect(find.text('Nummer gegen Kummer'), findsOneWidget);
    await tippen(tester, find.text('Zurück zum Szenario'));
    expect(find.text('Hilfe und Beratung'), findsNothing);

    // Info-Sheet über das i in der Kopfzeile.
    await tippen(tester, find.byTooltip('So funktioniert Pathwise'));
    expect(find.text('Kein Konto, keine Anmeldung'), findsWidgets);
    await tippen(tester, find.text('Verstanden'));

    // Rückmeldungs-Sheet: das Textfeld muss bedienbar sein.
    await tippen(
      tester,
      find.text('Rückmeldung geben oder eine Situation einschicken'),
    );
    expect(find.text('Deine Rückmeldung'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'Probe');
    await tester.pumpAndSettle();
    // Mit Text ist "Abschicken" freigegeben.
    expect(
      tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Abschicken'),
          matching: find.byType(TextButton),
        ),
      ).onPressed,
      isNotNull,
    );

    // Auf "Situation einschicken" umschalten: Label und Zeilenzahl wechseln.
    await tippen(tester, find.text('Situation einschicken'));
    expect(find.text('Die Situation'), findsOneWidget);
  });

  testWidgets('Einstellungen und Kommt-bald-Dialog', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tippen(tester, find.byTooltip('Einstellungen'));
    expect(find.text('DARSTELLUNG'), findsOneWidget);
    expect(find.text('BEWEGUNG'), findsOneWidget);
    // Die Vereinsangaben stehen weiter unten auf derselben Seite.
    expect(find.text('Post SV Nürnberg'), findsWidgets);
    expect(find.text('EXTERNE BERATUNG'), findsOneWidget);
    expect(find.text('WAS GESPEICHERT WIRD'), findsOneWidget);

    // Der Hell-Modus muss wirklich umschalten.
    await tippen(tester, find.text('Hell'));
    expect(Theme.of(tester.element(find.text('Hell'))).brightness,
        Brightness.light);
    await tippen(tester, find.text('Dunkel'));
    expect(Theme.of(tester.element(find.text('Dunkel'))).brightness,
        Brightness.dark);
    await tippen(tester, find.text('Zurück zur Übersicht'));

    // Der Dialog traegt drei Dauerschleifen (M17-M19) und wird nie ruhig.
    // Deshalb hier kein pumpAndSettle, sondern feste Schritte.
    final kachel = find.text('Gespräche mit Eltern');
    await tester.ensureVisible(kachel);
    await tester.pumpAndSettle();
    await tester.tap(kachel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Kommt bald'), findsOneWidget);
    expect(find.text('GESPRÄCHE MIT ELTERN'), findsOneWidget);

    await tester.tap(find.text('Zurück zur Übersicht'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Kommt bald'), findsNothing);
  });
}
