// Tests zu den Regeln, die DESIGN.md festlegt — nicht zum Aussehen.
// Das Aussehen wird gegen design_reference/.../screenshots geprueft.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/spiegel_repository.dart';
import 'package:pathwise/data/szenario_repository.dart';
import 'package:pathwise/design/components/pw_decision_point.dart';
import 'package:pathwise/design/pathwise_theme.dart';
import 'package:pathwise/design/pathwise_tokens.dart';
import 'package:pathwise/state/durchlauf_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'verein_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Szenariodaten', () {
    late PwInhalt inhalt;

    setUpAll(() async {
      inhalt = await const SzenarioRepository().laden();
    });

    test('drei Szenarien mit je drei Punkten und drei Optionen', () {
      expect(inhalt.szenarien, hasLength(3));
      for (final s in inhalt.szenarien) {
        expect(s.punkte, hasLength(3), reason: s.id);
        for (final p in s.punkte) {
          // Genau drei Handlungsoptionen, nie mehr, nie weniger (DESIGN.md 4.7).
          expect(p.optionen, hasLength(3), reason: s.id);
          expect(
            p.optionen.map((o) => o.id),
            containsAll(<String>['a', 'b', 'c']),
          );
        }
      }
    });

    test('Rahmen, Infos, Beratung, Module und Personen sind vollstaendig', () {
      expect(inhalt.infos, hasLength(6));
      expect(inhalt.beratung, hasLength(2));
      expect(inhalt.module, hasLength(3));
      expect(inhalt.personen, hasLength(2));
      expect(inhalt.verein, isNotEmpty);
      expect(inhalt.themenfelder.first, 'Alle');
    });

    test('nicht eingetretene Merkmale tragen den Nachsatz im Text', () {
      final merkmale = inhalt.szenarien
          .expand((s) => s.merkmale)
          .where((m) => m.nichtEingetreten);
      expect(merkmale, isNotEmpty);
      for (final m in merkmale) {
        expect(
          m.anzeigetext,
          endsWith('in diesem Durchlauf nicht eingetreten, hier würde die '
              'Situation kippen.'),
        );
      }
    });

    test('jedes Merkmal traegt eine Ampelstufe', () {
      for (final s in inhalt.szenarien) {
        expect(s.merkmale, isNotEmpty, reason: s.id);
        for (final stufe in PwStufe.values) {
          expect(s.merkmaleDerStufe(stufe), isNotEmpty, reason: '${s.id} $stufe');
        }
      }
    });
  });

  group('Statusableitung', () {
    late DurchlaufState leer;

    setUpAll(() async {
      final inhalt = await const SzenarioRepository().laden();
      leer = DurchlaufState(inhalt: inhalt, fortschritt: const Fortschritt());
    });

    test('kein Eintrag heisst "Noch nicht bearbeitet"', () {
      final sz = leer.inhalt.szenarien.first;
      expect(leer.status(sz), SzenarioStatus.offen);
      expect(leer.status(sz).label, 'Noch nicht bearbeitet');
      expect(leer.erststartAn, isTrue);
    });

    test('eine Wahl heisst "Angefangen"', () {
      final sz = leer.inhalt.szenarien.first;
      final s = leer.copyWith(
        fortschritt: Fortschritt(
          begonnen: {sz.id},
          wahlen: {Fortschritt.schluessel(sz.id, 0): 'a'},
        ),
      );
      expect(s.status(sz), SzenarioStatus.angefangen);
      expect(s.letzterPunkt(sz), 1);
      expect(s.laufendes?.id, sz.id);
    });

    test('Wahl am letzten Punkt heisst "Abgeschlossen"', () {
      final sz = leer.inhalt.szenarien.first;
      final s = leer.copyWith(
        fortschritt: Fortschritt(
          begonnen: {sz.id},
          wahlen: {
            for (var i = 0; i < sz.punkte.length; i++)
              Fortschritt.schluessel(sz.id, i): 'b',
          },
        ),
      );
      expect(s.status(sz), SzenarioStatus.abgeschlossen);
      // Abgeschlossene Szenarien tauchen nicht in "Weiter machen" auf.
      expect(s.laufendes, isNull);
    });

    test('der Themenfeld-Filter schraenkt die Liste ein', () {
      final feld = leer.inhalt.szenarien.first.themenfeld;
      final gefiltert = leer.copyWith(themenfeldFilter: feld);
      expect(gefiltert.sichtbareSzenarien, hasLength(1));
      expect(gefiltert.sichtbareSzenarien.single.themenfeld, feld);
      expect(leer.sichtbareSzenarien, hasLength(3));
    });
  });

  group('Zählwerte', () {
    late PwInhalt inhalt;

    setUpAll(() async {
      inhalt = await const SzenarioRepository().laden();
      SharedPreferences.setMockInitialValues({});
    });

    DurchlaufNotifier notifier(_ZaehlerSpion spion) {
      final container = ProviderContainer(
        overrides: [
          durchlaufProvider.overrideWith(
            () => DurchlaufNotifier(
              DurchlaufState(
                inhalt: inhalt,
                fortschritt: mitVerein(const Fortschritt(), inhalt),
              ),
              const FortschrittSpeicher(),
              spion,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container.read(durchlaufProvider.notifier);
    }

    test('zählt je Entscheidungspunkt genau einmal', () {
      final spion = _ZaehlerSpion();
      final n = notifier(spion);
      final sz = inhalt.szenarien.first;

      n.waehlen(sz, 0, 'a');
      expect(spion.rufe, hasLength(1));

      // "Antwort ändern" und eine neue Wahl am selben Punkt zählen nicht noch
      // einmal — sonst misst der Spiegel das Ändern statt das Entscheiden.
      n.wahlLoeschen(sz, 0);
      n.waehlen(sz, 0, 'c');
      expect(spion.rufe, hasLength(1));
      expect(spion.rufe.single, (sz.id, 0, 'a'));

      // Ein weiterer Punkt zählt eigenständig.
      n.waehlen(sz, 1, 'b');
      expect(spion.rufe, hasLength(2));

      // Der Zaehlwert traegt den Verein — sonst zeigt der Spiegel die Zahlen
      // aller Vereine statt die des eigenen Teams.
      expect(spion.vereine, everyElement(probeVerein(inhalt).id));
    });

    test('"Nochmal" zählt den Durchlauf nicht erneut', () {
      final spion = _ZaehlerSpion();
      final n = notifier(spion);
      final sz = inhalt.szenarien.first;

      for (var i = 0; i < sz.punkte.length; i++) {
        n.waehlen(sz, i, 'a');
      }
      expect(spion.rufe, hasLength(sz.punkte.length));

      n.nochmal(sz);
      for (var i = 0; i < sz.punkte.length; i++) {
        n.waehlen(sz, i, 'b');
      }
      expect(spion.rufe, hasLength(sz.punkte.length));
    });
  });

  group('Theme', () {
    test('baut in Light und Dark und traegt PwColors', () {
      for (final dunkel in [false, true]) {
        final theme = pwTheme(dark: dunkel);
        final farben = theme.extension<PwColors>();
        expect(farben, isNotNull);
        expect(farben, dunkel ? PwColors.dark : PwColors.light);
        expect(theme.scaffoldBackgroundColor, farben!.surfacePage);
        // Pathwise hat keine Ripple — Bedienfeedback ist der Press-Scale.
        expect(theme.splashFactory, NoSplash.splashFactory);
      }
    });

    test('lerp schneidet hart um statt zu blenden', () {
      expect(PwColors.light.lerp(PwColors.dark, 0.4), PwColors.light);
      expect(PwColors.light.lerp(PwColors.dark, 0.6), PwColors.dark);
    });
  });

  group('PwDecisionPoint', () {
    final optionen = [
      const PwOption(id: 'a', text: 'Erste Möglichkeit'),
      const PwOption(id: 'b', text: 'Zweite Möglichkeit'),
      const PwOption(id: 'c', text: 'Dritte Möglichkeit'),
    ];

    Widget huelle(Widget kind) => MaterialApp(
          theme: pwTheme(dark: true),
          home: Scaffold(body: SingleChildScrollView(child: kind)),
        );

    testWidgets('meldet die getippte Option', (tester) async {
      String? gewaehlt;
      await tester.pumpWidget(huelle(
        PwDecisionPoint(
          leitfrage: 'Was tust du?',
          optionen: optionen,
          gewaehlt: null,
          onWaehlen: (id) => gewaehlt = id,
        ),
      ));

      expect(find.text('Was tust du?'), findsOneWidget);
      // Vor der Wahl tragen die Optionen ihre Buchstaben.
      expect(find.text('A'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      await tester.tap(find.text('Zweite Möglichkeit'));
      expect(gewaehlt, 'b');
    });

    testWidgets('nach der Wahl ist keine Option mehr tippbar', (tester) async {
      var rufe = 0;
      await tester.pumpWidget(huelle(
        PwDecisionPoint(
          leitfrage: 'Was tust du?',
          optionen: optionen,
          gewaehlt: 'a',
          onWaehlen: (_) => rufe++,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dritte Möglichkeit'));
      await tester.tap(find.text('Erste Möglichkeit'));
      expect(rufe, 0);

      // Die gewaehlte Option zeigt das Haekchen statt ihres Buchstabens.
      expect(find.text('A'), findsNothing);
    });
  });
}

/// Merkt sich, welche Zaehlwerte gesendet wurden.
class _ZaehlerSpion implements SpiegelRepository {
  final List<(String, int, String)> rufe = [];

  /// Vereins-IDs der gesendeten Zaehlwerte — ohne Verein zaehlt die App nicht.
  final List<String?> vereine = [];

  @override
  Future<void> zaehlen({
    required String? vereinId,
    required String szenarioId,
    required String signatur,
    required int punktIndex,
    required String optionId,
  }) async {
    rufe.add((szenarioId, punktIndex, optionId));
    vereine.add(vereinId);
  }

  @override
  Future<SpiegelDaten> laden(String szenarioId,
          {required String signatur, String? vereinId}) async => SpiegelDaten.fehler;
}
