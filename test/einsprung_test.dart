// Widget auf dem Homescreen und taegliche Erinnerung.
//
// Die iOS-Seite laesst sich hier nicht pruefen — sie steht in
// ios/Runner/PathwiseBruecke.swift und ios/PathwiseWidget/ und ist im
// Simulator geprueft. Hier geht es um das, was die App entscheidet: was das
// Widget zeigt, was die Erinnerung sagt und wohin ein Tipp fuehrt.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/data/einsprung_bruecke.dart';
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/spiegel_repository.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/szenario_repository.dart';
import 'package:pathwise/data/vorschlag.dart';
import 'package:pathwise/design/pathwise_theme.dart';
import 'package:pathwise/main.dart';
import 'package:pathwise/screens/einstellungen_screen.dart';
import 'package:pathwise/screens/einstieg_screen.dart';
import 'package:pathwise/screens/punkt_screen.dart';
import 'package:pathwise/state/durchlauf_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'verein_probe.dart';

/// Eine Bruecke, die mitschreibt, statt mit iOS zu reden.
class _ProbeBruecke extends EinsprungBruecke {
  _ProbeBruecke({this.erlaubt = true});

  bool erlaubt;
  final zieleStrom = StreamController<String>.broadcast();
  String? start;
  final widgetStaende = <Map<String, Object?>>[];
  final plaene = <List<PwErinnerung>>[];
  int geloescht = 0;
  int anfragen = 0;
  int einstellungen = 0;

  @override
  bool get verfuegbar => true;
  @override
  Future<String?> startZiel() async {
    final z = start;
    start = null;
    return z;
  }

  @override
  Stream<String> get ziele => zieleStrom.stream;
  @override
  Future<void> widgetAktualisieren(Map<String, Object?> daten) async =>
      widgetStaende.add(daten);
  @override
  Future<PwErlaubnis> erlaubnis() async =>
      erlaubt ? PwErlaubnis.erlaubt : PwErlaubnis.abgelehnt;
  @override
  Future<bool> erlaubnisAnfragen() async {
    anfragen++;
    return erlaubt;
  }

  @override
  Future<void> erinnerungenPlanen(List<PwErinnerung> plan) async =>
      plaene.add(plan);
  @override
  Future<void> erinnerungenLoeschen() async => geloescht++;
  @override
  Future<List<String>> geplanteErinnerungen() async =>
      [for (final e in plaene.lastOrNull ?? const <PwErinnerung>[]) e.id];
  @override
  Future<void> systemEinstellungenOeffnen() async => einstellungen++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PwInhalt inhalt;
  late DurchlaufState leer;

  setUpAll(() async {
    inhalt = await const SzenarioRepository().laden();
    leer = DurchlaufState(inhalt: inhalt, fortschritt: const Fortschritt());
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  DurchlaufState mit(Fortschritt f) => leer.copyWith(fortschritt: f);

  /// Erster Punkt gewaehlt: unterbrochen bei Punkt 2.
  Fortschritt unterbrochen(PwSzenario sz) => Fortschritt(
        begonnen: {sz.id},
        wahlen: {Fortschritt.schluessel(sz.id, 0): 'a'},
      );

  Fortschritt abgeschlossen(Iterable<PwSzenario> szenarien) => Fortschritt(
        begonnen: {for (final sz in szenarien) sz.id},
        wahlen: {
          for (final sz in szenarien)
            for (var i = 0; i < sz.punkte.length; i++)
              Fortschritt.schluessel(sz.id, i): 'b',
        },
      );

  group('Was das Widget zeigt', () {
    test('ohne unterbrochenes Szenario die offenen, mit Vorgeschichte', () {
      final d = widgetDaten(leer);
      expect(d['laufend'], isNull);
      final vorschlaege = d['vorschlaege']! as List;
      expect(
        vorschlaege.map((v) => (v as Map)['id']),
        inhalt.szenarien.map((s) => s.id),
      );
      final erster = vorschlaege.first as Map;
      expect(erster['vorgeschichte'], inhalt.szenarien.first.vorgeschichte);
      expect(erster['themenfeld'], inhalt.szenarien.first.themenfeld);
    });

    test('abgeschlossene fallen heraus, bis alle durch sind', () {
      final erstes = inhalt.szenarien.first;
      expect(
        vorschlagsliste(mit(abgeschlossen([erstes]))).map((s) => s.id),
        isNot(contains(erstes.id)),
      );
      expect(
        vorschlagsliste(mit(abgeschlossen(inhalt.szenarien))),
        hasLength(inhalt.szenarien.length),
        reason: 'sind alle durch, steht wieder alles zur Wahl',
      );
    });

    test('ein unterbrochenes Szenario steht mit seinem offenen Punkt da', () {
      final sz = inhalt.szenarien[1];
      final laufend = widgetDaten(mit(unterbrochen(sz)))['laufend']! as Map;
      expect(laufend['id'], sz.id);
      expect(laufend['punkt'], 2);
      expect(laufend['punkte'], sz.punkte.length);
    });

    test('das Theme der App geht mit', () {
      expect(
        widgetDaten(mit(const Fortschritt(themeMode: ThemeMode.light)))['theme'],
        'light',
      );
      expect(widgetDaten(leer)['theme'], 'dark');
    });
  });

  group('Die Erinnerung', () {
    test('einmal am Tag um 18 Uhr, vierzehn Tage im Voraus', () {
      final plan = erinnerungsplan(leer, DateTime(2026, 9, 11, 10));
      expect(plan, hasLength(kErinnerungTage));
      expect(plan.first.zeitpunkt, DateTime(2026, 9, 11, 18));
      expect(plan.last.zeitpunkt, DateTime(2026, 9, 24, 18));
      for (final e in plan) {
        expect(e.zeitpunkt.hour, kErinnerungStunde);
      }
      expect(plan.map((e) => e.id).toSet(), hasLength(kErinnerungTage));
    });

    test('ist 18 Uhr schon vorbei, beginnt der Plan morgen', () {
      final plan = erinnerungsplan(leer, DateTime(2026, 9, 11, 18, 0, 1));
      expect(plan.first.zeitpunkt, DateTime(2026, 9, 12, 18));
    });

    test('bleibt ueber die Zeitumstellung bei 18 Uhr', () {
      final plan = erinnerungsplan(leer, DateTime(2026, 10, 20, 9));
      for (final e in plan) {
        expect(e.zeitpunkt.hour, 18, reason: e.id);
      }
    });

    test('jeden Tag ein anderes Szenario', () {
      final plan = erinnerungsplan(leer, DateTime(2026, 9, 11, 10));
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].titel, isNot(plan[i - 1].titel), reason: plan[i].id);
      }
      final sz = inhalt.szenarien.firstWhere((s) => s.titel == plan.first.titel);
      expect(plan.first.untertitel, sz.themenfeld);
      expect(plan.first.text, sz.kurz);
      expect(plan.first.ziel, 'pathwise://szenario/${sz.id}');
    });

    test('unterbrochen heisst: sie fuehrt dorthin zurueck', () {
      final sz = inhalt.szenarien.last;
      final plan = erinnerungsplan(mit(unterbrochen(sz)), DateTime(2026, 9, 11));
      expect(plan.first.titel, 'Weiter machen');
      expect(plan.first.untertitel, sz.titel);
      expect(plan.first.text, contains('Entscheidungspunkt 2 von 3'));
      expect(plan.first.ziel, 'pathwise://szenario/${sz.id}');
    });

    test('ohne Ausrufezeichen, ohne Frist, ohne Serie (DESIGN.md 1)', () {
      final alle = [
        ...erinnerungsplan(leer, DateTime(2026, 9, 11)),
        ...erinnerungsplan(
            mit(unterbrochen(inhalt.szenarien.first)), DateTime(2026, 9, 11)),
      ];
      for (final e in alle) {
        final text = '${e.titel} ${e.untertitel} ${e.text}';
        expect(text, isNot(contains('!')), reason: e.id);
        for (final wort in ['heute noch', 'Serie', 'verpass', 'Tage in Folge']) {
          expect(text, isNot(contains(wort)), reason: '${e.id}: $wort');
        }
      }
    });
  });

  group('Adressen', () {
    test('hin und zurueck', () {
      expect(szenarioAdresse('heimspiel').toString(),
          'pathwise://szenario/heimspiel');
      expect(szenarioAusAdresse('pathwise://szenario/heimspiel'), 'heimspiel');
      expect(szenarioAusAdresse('pathwise://start'), isNull);
      expect(szenarioAusAdresse('https://szenario/heimspiel'), isNull);
      expect(szenarioAusAdresse('kein link'), isNull);
    });
  });

  group('Ein Tipp aufs Widget', () {
    Future<void> appStarten(
      WidgetTester tester,
      _ProbeBruecke bruecke, {
      Fortschritt fortschritt = const Fortschritt(),
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            durchlaufProvider.overrideWith(
              () => DurchlaufNotifier(
                DurchlaufState(
                  inhalt: inhalt,
                  fortschritt: mitVerein(fortschritt, inhalt),
                ),
                const FortschrittSpeicher(),
                const SpiegelRepository(),
              ),
            ),
            einsprungBrueckeProvider.overrideWithValue(bruecke),
          ],
          child: const PathwiseApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('oeffnet ein offenes Szenario beim Einstieg', (tester) async {
      final bruecke = _ProbeBruecke();
      await appStarten(tester, bruecke);

      bruecke.zieleStrom.add('pathwise://szenario/hilfestellung');
      await tester.pumpAndSettle();

      final einstieg = tester.widget<EinstiegScreen>(find.byType(EinstiegScreen));
      expect(einstieg.szenarioId, 'hilfestellung');
      expect(find.text('Szenario beginnen'), findsOneWidget);
    });

    testWidgets('fuehrt ein unterbrochenes Szenario an den offenen Punkt',
        (tester) async {
      final bruecke = _ProbeBruecke();
      final sz = inhalt.szenarien.first;
      await appStarten(tester, bruecke, fortschritt: unterbrochen(sz));

      bruecke.zieleStrom.add('pathwise://szenario/${sz.id}');
      await tester.pumpAndSettle();

      final punkt = tester.widget<PunktScreen>(find.byType(PunktScreen));
      expect(punkt.szenarioId, sz.id);
      expect(punkt.startPunkt, 1);
    });

    testWidgets('startet die App direkt im Szenario', (tester) async {
      final bruecke = _ProbeBruecke()..start = 'pathwise://szenario/cotrainer';
      await appStarten(tester, bruecke);

      final einstieg = tester.widget<EinstiegScreen>(find.byType(EinstiegScreen));
      expect(einstieg.szenarioId, 'cotrainer');
    });

    testWidgets('ein unbekanntes Szenario fuehrt zur Uebersicht',
        (tester) async {
      final bruecke = _ProbeBruecke();
      await appStarten(tester, bruecke);

      bruecke.zieleStrom.add('pathwise://szenario/gibt-es-nicht');
      await tester.pumpAndSettle();

      expect(find.byType(EinstiegScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('das Widget bekommt jeden neuen Stand', (tester) async {
      final bruecke = _ProbeBruecke();
      await appStarten(tester, bruecke);
      expect(bruecke.widgetStaende, isNotEmpty);
      expect(bruecke.widgetStaende.last['laufend'], isNull);

      final container = ProviderScope.containerOf(
          tester.element(find.byType(PathwiseApp)));
      container
          .read(durchlaufProvider.notifier)
          .begonnen(inhalt.szenarien.first);
      await tester.pumpAndSettle();

      final laufend = bruecke.widgetStaende.last['laufend'] as Map?;
      expect(laufend?['id'], inhalt.szenarien.first.id);
      expect(laufend?['punkt'], 1);
    });

    testWidgets('plant nur, solange die Erinnerung an ist', (tester) async {
      final bruecke = _ProbeBruecke();
      await appStarten(tester, bruecke,
          fortschritt: const Fortschritt(erinnerung: true));
      expect(bruecke.plaene, isNotEmpty);
      expect(bruecke.plaene.last, hasLength(kErinnerungTage));

      final container = ProviderScope.containerOf(
          tester.element(find.byType(PathwiseApp)));
      final vorher = bruecke.geloescht;
      container.read(durchlaufProvider.notifier).erinnerungSetzen(false);
      await tester.pumpAndSettle();
      expect(bruecke.geloescht, greaterThan(vorher));
    });
  });

  group('Einstellungen', () {
    Future<ProviderContainer> einstellungen(
      WidgetTester tester,
      EinsprungBruecke bruecke,
    ) async {
      tester.view.physicalSize = const Size(1170, 4000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(overrides: [
        durchlaufProvider.overrideWith(
          () => DurchlaufNotifier(
            DurchlaufState(
              inhalt: inhalt,
              fortschritt: mitVerein(const Fortschritt(), inhalt),
            ),
            const FortschrittSpeicher(),
            const SpiegelRepository(),
          ),
        ),
        einsprungBrueckeProvider.overrideWithValue(bruecke),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: pwTheme(dark: true),
          home: const EinstellungenScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('einschalten fragt das System und merkt es sich',
        (tester) async {
      final bruecke = _ProbeBruecke();
      final container = await einstellungen(tester, bruecke);

      expect(find.text('Erinnerung'.toUpperCase()), findsOneWidget);
      await tester.ensureVisible(find.text('Einmal am Tag'));
      await tester.tap(find.text('Einmal am Tag'));
      await tester.pumpAndSettle();

      expect(bruecke.anfragen, 1);
      expect(container.read(durchlaufProvider).fortschritt.erinnerung, isTrue);

      await tester.ensureVisible(find.text('Aus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aus'));
      await tester.pumpAndSettle();
      expect(container.read(durchlaufProvider).fortschritt.erinnerung, isFalse);
    });

    testWidgets('abgelehnt bleibt aus und sagt, wo es sich erlauben laesst',
        (tester) async {
      final bruecke = _ProbeBruecke(erlaubt: false);
      final container = await einstellungen(tester, bruecke);

      await tester.ensureVisible(find.text('Einmal am Tag'));
      await tester.tap(find.text('Einmal am Tag'));
      await tester.pumpAndSettle();

      expect(container.read(durchlaufProvider).fortschritt.erinnerung, isFalse);
      expect(find.text('Mitteilungen erlauben'), findsOneWidget);
      await tester.tap(find.text('Mitteilungen erlauben'));
      expect(bruecke.einstellungen, 1);
    });

    testWidgets('ohne Widget und Erinnerung fehlt der Abschnitt ganz',
        (tester) async {
      await einstellungen(tester, const KeineEinsprungBruecke());
      expect(find.text('Erinnerung'.toUpperCase()), findsNothing);
      expect(find.text('Einmal am Tag'), findsNothing);
    });
  });

  test('die Erinnerung uebersteht einen Neustart und faellt beim Loeschen weg',
      () async {
    const speicher = FortschrittSpeicher();
    await speicher.sichern(const Fortschritt(erinnerung: true));
    expect((await speicher.laden()).erinnerung, isTrue);
    await speicher.allesLoeschen();
    expect((await speicher.laden()).erinnerung, isFalse);
  });
}
