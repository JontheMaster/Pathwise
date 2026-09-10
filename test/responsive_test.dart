// Prueft jeden Screen in allen vier Breitenbereichen aus DESIGN.md 7 auf
// Layoutfehler.
//
// Ein RenderFlex-Ueberlauf meldet sich in Flutter als Exception. Dieser Test
// faengt sie ein und laesst den Lauf scheitern — damit faellt auf, wenn ein
// Screen auf einer Groesse bricht, ohne dass jemand hinsehen muss.
//
// Bereiche laut DESIGN.md 7:
//   < 360 dp   Seitenpolster 12, Footer-Buttons untereinander
//   360-599    Standard, eine Spalte
//   600-899    Seitenpolster 24, Inhalt auf 640 zentriert, Raster zweispaltig
//   >= 900     Zweispalten-Layout mit Seitenleiste, Ampel-Listen dreispaltig
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/spiegel_repository.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/szenario_repository.dart';
import 'package:pathwise/design/components/pw_card.dart';
import 'package:pathwise/design/pathwise_theme.dart';
import 'package:pathwise/screens/auswertung_screen.dart';
import 'package:pathwise/screens/einstieg_screen.dart';
import 'package:pathwise/screens/punkt_screen.dart';
import 'package:pathwise/screens/uebersicht_screen.dart';
import 'package:pathwise/screens/einstellungen_screen.dart';
import 'package:pathwise/state/durchlauf_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'schriften.dart';
import 'verein_probe.dart';

/// Geraeteklassen, gegen die geprueft wird. Die Werte sind logische Pixel.
const _groessen = <String, Size>{
  'Handy klein (320x568)': Size(320, 568),
  'Handy (390x844)': Size(390, 844),
  'Handy quer (844x390)': Size(844, 390),
  'Tablet hoch (834x1112)': Size(834, 1112),
  'Tablet quer (1112x834)': Size(1112, 834),
  'Laptop (1440x900)': Size(1440, 900),
};

class _StillerSpiegel implements SpiegelRepository {
  const _StillerSpiegel();

  @override
  Future<SpiegelDaten> laden(String s, {String? vereinId}) async => const SpiegelDaten(
        status: SpiegelStatus.da,
        werte: {
          0: {'a': 34, 'b': 12, 'c': 12},
          1: {'a': 14, 'b': 27, 'c': 17},
          2: {'a': 9, 'b': 11, 'c': 6},
        },
      );

  @override
  Future<void> zaehlen({
    required String? vereinId,
    required String szenarioId,
    required int punktIndex,
    required String optionId,
  }) async {}
}

void main() {
  late PwInhalt inhalt;
  late PwSzenario sz;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Ohne echte Schriften misst der Test-Renderer jeden Text zu breit.
    await schriftenLaden();
    SharedPreferences.setMockInitialValues({});
    inhalt = await const SzenarioRepository().laden();
    sz = inhalt.szenarien.first;
  });

  Fortschritt fertig() => Fortschritt(
        erststartGesehen: true,
        begonnen: {sz.id},
        wahlen: {
          for (var i = 0; i < sz.punkte.length; i++)
            Fortschritt.schluessel(sz.id, i): 'a',
        },
        // Die Abschluss-Geste hier ausgelassen: sie laeuft endlos lange nicht,
        // wuerde aber pumpAndSettle unnoetig verlaengern.
        gefeiert: {sz.id},
      );

  Widget huelle(Widget screen, Fortschritt f) => ProviderScope(
        overrides: [
          durchlaufProvider.overrideWith(
            () => DurchlaufNotifier(
              DurchlaufState(inhalt: inhalt, fortschritt: mitVerein(f, inhalt)),
              const FortschrittSpeicher(),
              const SpiegelRepository(),
            ),
          ),
          spiegelRepositoryProvider.overrideWithValue(const _StillerSpiegel()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: pwTheme(dark: false),
          darkTheme: pwTheme(dark: true),
          themeMode: ThemeMode.dark,
          home: screen,
        ),
      );

  /// Baut [screen] bei [groesse] und meldet jeden Layoutfehler.
  Future<void> pruefen(
    WidgetTester tester,
    Size groesse,
    Widget screen,
    Fortschritt f,
  ) async {
    tester.view.physicalSize = groesse;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(huelle(screen, f));
    await tester.pumpAndSettle();

    final fehler = tester.takeException();
    expect(
      fehler,
      isNull,
      reason: 'Layoutfehler bei ${groesse.width.toInt()}x'
          '${groesse.height.toInt()}: $fehler',
    );
  }

  for (final eintrag in _groessen.entries) {
    group(eintrag.key, () {
      final groesse = eintrag.value;

      testWidgets('S1 Übersicht — Erststart', (tester) async {
        await pruefen(
          tester,
          groesse,
          const UebersichtScreen(),
          const Fortschritt(),
        );
      });

      testWidgets('S1 Übersicht — mit Fortschritt', (tester) async {
        await pruefen(tester, groesse, const UebersichtScreen(), fertig());
      });

      testWidgets('S2 Einstieg', (tester) async {
        await pruefen(
          tester,
          groesse,
          EinstiegScreen(szenarioId: sz.id),
          const Fortschritt(erststartGesehen: true),
        );
      });

      testWidgets('S3 Entscheidungspunkt — ohne Wahl', (tester) async {
        await pruefen(
          tester,
          groesse,
          PunktScreen(szenarioId: sz.id, startPunkt: 0),
          Fortschritt(erststartGesehen: true, begonnen: {sz.id}),
        );
      });

      testWidgets('S3 Entscheidungspunkt — nach der Wahl', (tester) async {
        await pruefen(
          tester,
          groesse,
          PunktScreen(szenarioId: sz.id, startPunkt: 2),
          fertig(),
        );
      });

      testWidgets('S4 Auswertung', (tester) async {
        await pruefen(
          tester,
          groesse,
          AuswertungScreen(szenarioId: sz.id),
          fertig(),
        );
      });

      testWidgets('S5 Einstellungen', (tester) async {
        await pruefen(
          tester,
          groesse,
          const EinstellungenScreen(),
          const Fortschritt(erststartGesehen: true),
        );
      });
    });
  }

  group('Breitenregeln greifen', () {
    testWidgets('ab 900 dp erscheint die Seitenleiste', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      tester.view.physicalSize = const Size(899, 800);
      await tester.pumpWidget(
        huelle(const UebersichtScreen(), const Fortschritt(erststartGesehen: true)),
      );
      await tester.pumpAndSettle();
      // Unter 900 steht "Szenarien" als Leisten-Label nicht im Baum.
      expect(find.text('SZENARIEN'), findsNothing);

      tester.view.physicalSize = const Size(901, 800);
      await tester.pumpWidget(
        huelle(const UebersichtScreen(), const Fortschritt(erststartGesehen: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('SZENARIEN'), findsOneWidget);
      expect(find.text('Freiwillig, ohne Anmeldung, kein Nachweis.'),
          findsOneWidget);
    });

    // Der Status stand frueher mal neben und mal unter dem Themenfeld-Chip,
    // je nachdem ob beides in eine Zeile passte. Bei den kuerzeren
    // Themenfeldnamen fiel das auf dem Handy auf.
    testWidgets('der Status steht immer unter dem Themenfeld-Chip',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Breiten abtasten statt raten: ob Chip und Status in eine Zeile passen,
      // haengt an der Kartenbreite und damit an wenigen dp. Ein fester
      // Stichprobensatz haette den Fehler je nach Geraet verfehlt.
      for (var breite = 320.0; breite <= 900.0; breite += 10.0) {
        tester.view.physicalSize = Size(breite, 1600);
        await tester.pumpWidget(huelle(
          const UebersichtScreen(),
          const Fortschritt(erststartGesehen: true),
        ));
        await tester.pumpAndSettle();

        for (final sz in inhalt.szenarien) {
          // Der Themenfeldname steht auch in der Filterzeile — deshalb nur
          // innerhalb der Karte suchen, die den Szenariotitel traegt.
          final karte = find
              .ancestor(of: find.text(sz.titel), matching: find.byType(PwCard))
              .first;
          final chip =
              find.descendant(of: karte, matching: find.text(sz.themenfeld));
          final status = find.descendant(
            of: karte,
            matching: find.text(SzenarioStatus.offen.label),
          );

          expect(chip, findsOneWidget, reason: '${sz.id} bei $breite dp');
          expect(status, findsOneWidget, reason: '${sz.id} bei $breite dp');
          expect(
            tester.getRect(status).top,
            greaterThanOrEqualTo(tester.getRect(chip).bottom),
            reason: 'Status neben statt unter dem Chip: ${sz.id} bei $breite dp',
          );
        }
      }
    });

    testWidgets('unter 360 dp stehen die Footer-Buttons untereinander',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Future<Rect> lageVon(double breite, String label) async {
        tester.view.physicalSize = Size(breite, 800);
        await tester.pumpWidget(huelle(
          PunktScreen(szenarioId: sz.id, startPunkt: 0),
          fertig(),
        ));
        await tester.pumpAndSettle();
        return tester.getRect(find.text(label).first);
      }

      // Breit: nebeneinander — "Weiter" rechts, die Zeilen ueberlappen sich
      // vertikal. Gleiche Oberkante waere zu streng, weil die Beschriftungen
      // unterschiedlich hoch umbrechen koennen.
      final breitAendern = await lageVon(390, 'Antwort ändern');
      final breitWeiter = await lageVon(390, 'Weiter');
      expect(breitWeiter.left, greaterThan(breitAendern.left));
      expect(breitWeiter.top, lessThan(breitAendern.bottom));
      expect(breitAendern.top, lessThan(breitWeiter.bottom));

      // Eng: untereinander, "Weiter" oben.
      final engAendern = await lageVon(320, 'Antwort ändern');
      final engWeiter = await lageVon(320, 'Weiter');
      expect(engWeiter.bottom, lessThanOrEqualTo(engAendern.top));
    });

    // DESIGN.md nennt zwei Regeln, die sich widersprechen: der Inhaltsbereich
    // ist auf 640 dp begrenzt (Abschnitt 7), die Ampelstufen sollen aber ab
    // 900 dp *Inhaltsbreite* nebeneinander stehen (Abschnitt 7/S4). 640 wird
    // nie 900, die Dreispaltigkeit ist damit unerreichbar. Der HTML-Prototyp
    // verhaelt sich genauso: seine Container-Query auf 900 px greift innerhalb
    // des 640er-Inhalts ebenfalls nie.
    //
    // Dieser Test haelt das beobachtbare Verhalten fest: die Stufen stehen auf
    // jeder Fensterbreite untereinander. Soll die Dreispaltigkeit kommen, muss
    // der Ampelblock aus der 640er-Begrenzung ausbrechen duerfen — das waere
    // eine Designentscheidung, keine Fehlerkorrektur.
    testWidgets('Ampelstufen stehen untereinander, auch auf breiten Fenstern',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Future<(Rect, Rect)> lagen(double breite) async {
        tester.view.physicalSize = Size(breite, 1400);
        await tester.pumpWidget(
          huelle(AuswertungScreen(szenarioId: sz.id), fertig()),
        );
        await tester.pumpAndSettle();
        return (
          tester.getRect(find.text('UNBEDENKLICH')),
          tester.getRect(find.text('KLÄRUNGSBEDÜRFTIG')),
        );
      }

      for (final breite in [390.0, 834.0, 1600.0]) {
        final (ok, check) = await lagen(breite);
        expect(check.top, greaterThan(ok.top), reason: 'bei $breite dp');
        expect(check.left, closeTo(ok.left, 1), reason: 'bei $breite dp');
      }
    });
  });
}
