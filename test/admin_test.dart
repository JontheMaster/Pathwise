// Das Dashboard: Sperren, Szenarienliste, Editor, Vereine, Rückmeldungen.
//
// Der wichtigste Teil steht ganz oben: das Dashboard läuft mit dem geheimen
// Schlüssel und damit an jeder RLS-Regel vorbei. Es darf deshalb nur lokal
// und nur mit ausdrücklich übergebenem Schlüssel starten.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/admin/admin_app.dart';
import 'package:pathwise/admin/admin_config.dart';
import 'package:pathwise/admin/admin_modelle.dart';
import 'package:pathwise/admin/admin_state.dart';
import 'package:pathwise/admin/seiten/szenario_editor.dart';
import 'package:pathwise/design/pathwise_theme.dart';

import 'admin_probe.dart';
import 'schriften.dart';

/// Antwortet auf alles mit dem Fehler, den Supabase bei falschem Schluessel
/// schickt.
class _AbweisendesRepository extends ProbeAdminRepository {
  @override
  Future<List<AdminSzenario>> szenarien() async =>
      throw Exception('Invalid API key');
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await schriftenLaden();
  });

  group('Sperren', () {
    test('ohne Schlüssel startet nichts', () {
      // Im Testlauf ist SUPABASE_SECRET_KEY nicht gesetzt — genau der Fall,
      // den ein versehentlicher Start ohne --dart-define erzeugt.
      expect(AdminConfig.schluesselDa, isFalse);
      expect(
        AdminConfig.hindernis('localhost'),
        AdminHindernis.ohneSchluessel,
      );
    });

    test('nur localhost zählt als lokal', () {
      for (final host in ['localhost', '127.0.0.1', '::1', '']) {
        expect(AdminConfig.istLokal(host), isTrue, reason: host);
      }
      for (final host in [
        'pathwise.de',
        'localhost.angreifer.de',
        '192.168.0.5',
        'admin.pathwise.vercel.app',
      ]) {
        expect(AdminConfig.istLokal(host), isFalse, reason: host);
      }
    });

    test('ein fremder Host schlägt jede andere Prüfung', () {
      // Auch mit gültigem Schlüssel: liegt die Seite auf einem Server, ist das
      // der schwerere Fehler und muss als solcher gemeldet werden.
      expect(
        AdminConfig.hindernis('pathwise.de'),
        AdminHindernis.nichtLokal,
      );
      expect(AdminHindernis.nichtLokal.befehl, isNull,
          reason: 'dafür gibt es keinen Befehl, der es richtig macht');
    });

    test('im Browser sperrt ein geheimer Schlüssel, bevor Supabase ihn abweist',
        () {
      expect(
        AdminConfig.hindernis('localhost',
            imBrowser: true, schluessel: 'sb_secret_abc'),
        AdminHindernis.imBrowser,
      );
      // Als Desktop-Programm geht derselbe Schlüssel durch.
      expect(
        AdminConfig.hindernis('', imBrowser: false, schluessel: 'sb_secret_abc'),
        isNull,
      );
      // Den alten service_role-Schlüssel sperrt Supabase im Browser nicht.
      expect(
        AdminConfig.hindernis('localhost',
            imBrowser: true, schluessel: 'eyJhbGciOiJIUzI1NiJ9.x.y'),
        isNull,
      );
      // Der fremde Host bleibt der schwerere Fehler.
      expect(
        AdminConfig.hindernis('pathwise.de',
            imBrowser: true, schluessel: 'sb_secret_abc'),
        AdminHindernis.nichtLokal,
      );
    });

    testWidgets('die Browser-Sperre nennt den Befehl für den Desktop',
        (tester) async {
      await tester.pumpWidget(
        const AdminApp(hindernis: AdminHindernis.imBrowser),
      );
      await tester.pumpAndSettle();

      expect(find.text('Im Browser geht der Schlüssel nicht'), findsOneWidget);
      expect(find.textContaining('flutter run -d macos'), findsOneWidget);
      expect(find.textContaining('-d chrome'), findsNothing);
    });

    testWidgets('die Sperrseite nennt den Befehl', (tester) async {
      await tester.pumpWidget(
        const AdminApp(hindernis: AdminHindernis.ohneSchluessel),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kein Schlüssel übergeben'), findsOneWidget);
      expect(
        find.textContaining('--dart-define=SUPABASE_SECRET_KEY'),
        findsOneWidget,
      );
    });

    testWidgets('auf fremdem Host steht keine Anleitung zum Weitermachen',
        (tester) async {
      await tester.pumpWidget(
        const AdminApp(hindernis: AdminHindernis.nichtLokal),
      );
      await tester.pumpAndSettle();

      expect(find.text('Das Dashboard läuft nur lokal'), findsOneWidget);
      expect(find.textContaining('--dart-define'), findsNothing);
    });
  });

  group('Zeilen lesen', () {
    test('versteht die Zeitstempel, die PostgREST liefert', () {
      // Zwei Schreibweisen kommen vor: PostgREST setzt ein T und +00:00, die
      // SQL-Konsole ein Leerzeichen und +00. Beide muessen ankommen — sonst
      // steht in der Liste kein Datum, ohne dass etwas kaputt aussieht.
      for (final roh in [
        '2026-09-10T20:19:00.652679+00:00',
        '2026-09-10 20:19:00.652679+00',
        '2026-09-10T20:19:00Z',
      ]) {
        final r = AdminRueckmeldung.ausZeile({
          'id': 'r1',
          'art': 'feedback',
          'text': 't',
          'bearbeitet': false,
          'erstellt_am': roh,
        });
        expect(r.erstelltAm, isNotNull, reason: roh);
        expect(r.erstelltAm!.toUtc().hour, 20, reason: roh);
      }
    });

    test('kommt ohne Zeitstempel und ohne E-Mail aus', () {
      final r = AdminRueckmeldung.ausZeile({
        'id': 'r1',
        'art': 'szenario',
        'text': 't',
        'bearbeitet': true,
      });
      expect(r.erstelltAm, isNull);
      expect(r.email, isNull);
      expect(r.artLabel, 'Situation eingeschickt');
    });

    test('liest ein Szenario so, wie die Tabelle es liefert', () {
      final s = AdminSzenario.ausZeile({
        'id': 'heimspiel',
        'status': 'veroeffentlicht',
        'reihenfolge': 2,
        'fassung': 5,
        'signatur': 'b' * 32,
        'inhalt': {
          'titel': 'Vor dem Heimspiel',
          'themenfeld': 'Umkleide',
          'punkte': [1, 2, 3],
        },
        'aktualisiert_am': '2026-09-10T20:19:00+00:00',
      });
      expect(s.status, AdminStatus.veroeffentlicht);
      expect(s.fassung, 5);
      expect(s.titel, 'Vor dem Heimspiel');
      expect(s.punkteAnzahl, 3);
    });

    test('ein unbekannter Status gilt als Entwurf, nicht als veröffentlicht',
        () {
      // Im Zweifel nicht ausspielen: ein Tippfehler in der Datenbank darf
      // nichts vor Publikum bringen.
      expect(AdminStatus.vonSchluessel('quatsch'), AdminStatus.entwurf);
      expect(AdminStatus.vonSchluessel(null), AdminStatus.entwurf);
    });
  });

  group('Dashboard', () {
    late ProbeAdminRepository probe;

    Widget huelle() => ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(probe)],
          child: const AdminApp(),
        );

    setUp(() {
      probe = ProbeAdminRepository(
        szenarien: [
          probeSzenario(id: 'heimspiel', titel: 'Vor dem Heimspiel'),
          probeSzenario(
            id: 'cotrainer',
            titel: 'Der Co-Trainer',
            status: AdminStatus.veroeffentlicht,
            fassung: 3,
          ),
        ],
        vereine: [
          const AdminVerein(
            id: 'v1',
            code: 'POSTSV-2026',
            name: 'Post SV Nürnberg',
            aktiv: true,
            personen: [
              AdminPerson(
                id: 'p1',
                vereinId: 'v1',
                name: 'Michael Brandt',
                rolle: 'Kinderschutzbeauftragter',
                kontakt: 'kinderschutz@postsv.de',
                perTelefon: false,
                reihenfolge: 0,
              ),
            ],
          ),
        ],
        bundesweit: [
          const AdminBeratung(
            id: 'b1',
            vereinId: null,
            titel: 'Hilfetelefon Sexueller Missbrauch',
            zusatz: 'anonym und kostenfrei',
            nummer: '0800 22 55 530',
            reihenfolge: 0,
          ),
        ],
        rueckmeldungen: [
          AdminRueckmeldung(
            id: 'r1',
            art: 'feedback',
            text: 'Eine offene Rückmeldung',
            email: null,
            bearbeitet: false,
            erstelltAm: DateTime(2026, 9, 1, 10, 30),
          ),
          AdminRueckmeldung(
            id: 'r2',
            art: 'szenario',
            text: 'Eine erledigte',
            email: 'jemand@example.org',
            bearbeitet: true,
            erstelltAm: DateTime(2026, 8, 20, 9),
          ),
        ],
        zahlen: [
          const AdminZahl(
            vereinId: 'v1',
            szenarioId: 'cotrainer',
            signatur: 'abcdef1234567890abcdef1234567890',
            punktIndex: 0,
            optionId: 'a',
            anzahl: 7,
          ),
          const AdminZahl(
            vereinId: 'v1',
            szenarioId: 'cotrainer',
            signatur: 'abcdef1234567890abcdef1234567890',
            punktIndex: 0,
            optionId: 'b',
            anzahl: 3,
          ),
        ],
      );
    });

    testWidgets('zeigt Entwürfe und Veröffentlichte auseinandergehalten',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();

      expect(find.text('Vor dem Heimspiel'), findsOneWidget);
      expect(find.text('Der Co-Trainer'), findsOneWidget);
      expect(find.text('Entwurf'), findsOneWidget);
      expect(find.text('Veröffentlicht · Fassung 3'), findsOneWidget);
    });

    testWidgets('veröffentlicht einen Entwurf', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Veröffentlichen'));
      await tester.pumpAndSettle();

      expect(
        probe.rufe,
        contains('szenarioSichern:heimspiel:veroeffentlicht'),
      );
    });

    testWidgets('fragt nach, bevor ein Szenario zurückgezogen wird',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zurückziehen'));
      await tester.pumpAndSettle();

      expect(find.text('Szenario zurückziehen?'), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(
        probe.rufe.where((r) => r.startsWith('szenarioSichern')),
        isEmpty,
        reason: 'Abbrechen darf nichts geändert haben',
      );
    });

    testWidgets('warnt beim Löschen davor, dass die Zählwerte mitgehen',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Löschen').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Zählwerte'), findsOneWidget);
      expect(find.textContaining('zieht es besser zurück'), findsOneWidget);
    });

    testWidgets('der Editor speichert nichts Unvollständiges', (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(probe)],
          child: MaterialApp(
            theme: pwTheme(dark: true),
            home: SzenarioEditor(
              neu: true,
              szenario: const AdminSzenario(
                id: '',
                status: AdminStatus.entwurf,
                reihenfolge: 0,
                fassung: 1,
                signatur: '',
                inhalt: {
                  'titel': '',
                  'themenfeld': '',
                  'punkte': <dynamic>[],
                  'merkmale': <dynamic>[],
                  'rahmen': <dynamic>[],
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anlegen'));
      await tester.pumpAndSettle();

      expect(find.text('Die Kennung fehlt.'), findsOneWidget);
      expect(probe.rufe, isEmpty);
    });

    testWidgets('der Editor nimmt keine Kennung mit Großbuchstaben',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(probe)],
          child: MaterialApp(
            theme: pwTheme(dark: true),
            home: SzenarioEditor(neu: true, szenario: probeSzenario(id: '')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final kennung = find.widgetWithText(TextField, '').first;
      await tester.enterText(kennung, 'Mit Grossbuchstaben');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anlegen'));
      await tester.pumpAndSettle();

      expect(find.textContaining('nur Kleinbuchstaben'), findsOneWidget);
      expect(probe.rufe, isEmpty);
    });

    testWidgets('zeigt Vereine mit Code und Ansprechpersonen', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vereine'));
      await tester.pumpAndSettle();

      expect(find.text('Post SV Nürnberg'), findsOneWidget);
      expect(find.textContaining('POSTSV-2026'), findsOneWidget);
      expect(find.text('Michael Brandt'), findsOneWidget);
      expect(find.text('Hilfetelefon Sexueller Missbrauch'), findsOneWidget);
    });

    testWidgets('warnt, wenn es keine bundesweite Nummer mehr gäbe',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final leer = ProbeAdminRepository(vereine: const [], bundesweit: const []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(leer)],
          child: const AdminApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vereine'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ohne Vereinscode hat die App gar keine Nummer'),
        findsOneWidget,
      );
    });

    testWidgets('zeigt zuerst die offenen Rückmeldungen', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rückmeldungen'));
      await tester.pumpAndSettle();

      expect(find.text('1 offen · 2 insgesamt'), findsOneWidget);
      expect(find.text('Eine offene Rückmeldung'), findsOneWidget);
      expect(find.text('Eine erledigte'), findsNothing);

      await tester.tap(find.text('Alle zeigen'));
      await tester.pumpAndSettle();
      expect(find.text('Eine erledigte'), findsOneWidget);
    });

    testWidgets('merkt eine Rückmeldung als bearbeitet', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rückmeldungen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Als bearbeitet merken'));
      await tester.pumpAndSettle();

      expect(probe.rufe, contains('rueckmeldungBearbeitet:r1:true'));
    });

    testWidgets('zeigt einen abgelehnten Schlüssel an, statt ewig zu laden',
        (tester) async {
      // Der haeufigste Fehler beim Starten ist ein falscher Schluessel. Die
      // Antwort ist ein 401, und der muss zu sehen sein — Riverpod wuerde
      // sonst im Hintergrund weiter versuchen und die Seite bliebe auf
      // "Wird geladen …" stehen.
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider
                .overrideWithValue(_AbweisendesRepository()),
          ],
          child: const AdminApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nicht abrufbar'), findsOneWidget);
      expect(find.textContaining('Invalid API key'), findsOneWidget);
      expect(find.text('Wird geladen …'), findsNothing);
    });

    testWidgets('meldet einen Fehler, statt ihn zu verschlucken',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rückmeldungen'));
      await tester.pumpAndSettle();

      probe.fehlerBeimSchreiben = 'Netz weg';
      await tester.tap(find.text('Als bearbeitet merken'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nicht gespeichert'), findsOneWidget);
    });

    testWidgets('rechnet die Zahlen je Entscheidungspunkt zusammen',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zahlen'));
      await tester.pumpAndSettle();

      expect(find.text('10 Einschätzungen in 1 Gruppen'), findsOneWidget);
      expect(find.textContaining('Signatur abcdef12'), findsOneWidget);
    });
  });
}
