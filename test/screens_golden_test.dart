// Rendert jeden Screen und legt ihn als Bild unter test/goldens/ ab.
//
// Zweck ist die Abnahme gegen design_reference/.../screenshots: die Bilder
// entstehen im echten Renderer, mit den gebuendelten Schriften, bei 390 x 844 —
// der Preview-Groesse des Entwurfs.
//
// Bilder erneuern:  flutter test --update-goldens test/screens_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/spiegel_repository.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/szenario_repository.dart';
import 'package:pathwise/design/pathwise_theme.dart';
import 'package:pathwise/screens/auswertung_screen.dart';
import 'package:pathwise/screens/einstieg_screen.dart';
import 'package:pathwise/screens/kommt_bald_dialog.dart';
import 'package:pathwise/screens/punkt_screen.dart';
import 'package:pathwise/screens/rueckmeldung_sheet.dart';
import 'package:pathwise/screens/uebersicht_screen.dart';
import 'package:pathwise/screens/einstellungen_screen.dart';
import 'package:pathwise/state/durchlauf_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'schriften.dart';
import 'verein_probe.dart';

/// Preview-Groesse aus PathwiseApp.dc.html ($preview: 390 x 844).
const _geraet = Size(390, 844);

/// Liefert immer denselben Spiegel — kein Netzaufruf im Test.
class _FesterSpiegel implements SpiegelRepository {
  const _FesterSpiegel(this.daten);

  final SpiegelDaten daten;

  @override
  Future<SpiegelDaten> laden(String szenarioId,
          {required String signatur, String? vereinId}) async => daten;

  @override
  Future<void> zaehlen({
    required String? vereinId,
    required String szenarioId,
    required String signatur,
    required int punktIndex,
    required String optionId,
  }) async {}
}


/// Laedt alle Image-Widgets wirklich, bevor das Bild verglichen wird.
///
/// Image.asset dekodiert asynchron. Im Widget-Test passiert das nur innerhalb
/// von runAsync — sonst haengt es davon ab, ob ein frueherer Test das Bild
/// schon in den Cache gelegt hat, und dieselbe Aufnahme sieht je nach
/// Reihenfolge anders aus. Betrifft hier das Logo in Kopfzeile und
/// Seitenleiste, das einzige Bildmotiv der App.
Future<void> _bilderLaden(WidgetTester tester) async {
  final bilder = tester.widgetList<Image>(find.byType(Image)).toList();
  if (bilder.isEmpty) return;

  final stelle = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final b in bilder) {
      await precacheImage(b.image, stelle);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  late PwInhalt inhalt;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await schriftenLaden();
    SharedPreferences.setMockInitialValues({});
    inhalt = await const SzenarioRepository().laden();
  });

  /// Baut die App-Huelle mit gesetztem Zustand.
  Widget huelle({
    required Widget screen,
    Fortschritt fortschritt = const Fortschritt(),
    String filter = 'Alle',
    bool dunkel = true,
    bool ohneBewegung = false,
    SpiegelDaten spiegel = const SpiegelDaten(status: SpiegelStatus.ohneBackend),
  }) {
    Widget mitBewegungsschalter(Widget kind) => ohneBewegung
        ? Builder(
            builder: (ctx) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
              child: kind,
            ),
          )
        : kind;

    return ProviderScope(
      overrides: [
        durchlaufProvider.overrideWith(
          () => DurchlaufNotifier(
            DurchlaufState(
              inhalt: inhalt,
              fortschritt: mitVerein(fortschritt, inhalt),
              themenfeldFilter: filter,
            ),
            const FortschrittSpeicher(),
            const SpiegelRepository(),
          ),
        ),
        spiegelRepositoryProvider.overrideWithValue(_FesterSpiegel(spiegel)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: pwTheme(dark: false),
        darkTheme: pwTheme(dark: true),
        themeMode: dunkel ? ThemeMode.dark : ThemeMode.light,
        home: mitBewegungsschalter(screen),
      ),
    );
  }

  Future<void> aufnehmen(
    WidgetTester tester,
    String name,
    Widget app, {
    Future<void> Function(WidgetTester)? danach,
    Duration? mitten,
  }) async {
    tester.view.physicalSize = _geraet;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);

    if (mitten != null) {
      // Fuer Bewegungen, die nie auslaufen oder nur unterwegs zu sehen sind:
      // gezielt bis zu einem Zeitpunkt vorspulen statt auszusetteln.
      await tester.pump(mitten);
    } else {
      await tester.pumpAndSettle();
    }

    if (danach != null) {
      await danach(tester);
      await tester.pumpAndSettle();
    }

    await _bilderLaden(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  // Der Fortschritt eines vollstaendig gespielten ersten Szenarios.
  Fortschritt komplett(PwSzenario sz, {int bis = 2}) => Fortschritt(
        erststartGesehen: true,
        begonnen: {sz.id},
        wahlen: {
          for (var i = 0; i <= bis; i++)
            Fortschritt.schluessel(sz.id, i): ['a', 'b', 'a'][i],
        },
      );

  // Aufnahmen der drei Geraeteklassen, gegen die im Browser geprueft wird.
  // Der Layouttest in responsive_test.dart deckt alle Groessen ab; diese
  // Bilder sind fuer die Sichtprobe.
  group('Geraeteklassen', () {
    Future<void> beiGroesse(
      WidgetTester tester,
      String name,
      Size groesse,
      Widget screen, {
      Fortschritt fortschritt = const Fortschritt(erststartGesehen: true),
      SpiegelDaten spiegel =
          const SpiegelDaten(status: SpiegelStatus.ohneBackend),
    }) async {
      tester.view.physicalSize = groesse;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(huelle(
        screen: screen,
        fortschritt: fortschritt,
        spiegel: spiegel,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    }

    testWidgets('Laptop 1440x900 — Übersicht mit Seitenleiste',
        (tester) async {
      await beiGroesse(
        tester,
        'G-laptop-1440-uebersicht',
        const Size(1440, 900),
        const UebersichtScreen(),
      );
    });

    testWidgets('Laptop 1440x900 — Auswertung', (tester) async {
      await beiGroesse(
        tester,
        'G-laptop-1440-auswertung',
        const Size(1440, 900),
        AuswertungScreen(szenarioId: inhalt.szenarien.first.id),
        fortschritt: Fortschritt(
          erststartGesehen: true,
          begonnen: {inhalt.szenarien.first.id},
          gefeiert: {inhalt.szenarien.first.id},
          wahlen: {
            for (var i = 0; i < 3; i++)
              Fortschritt.schluessel(inhalt.szenarien.first.id, i): 'a',
          },
        ),
        spiegel: const SpiegelDaten(
          status: SpiegelStatus.da,
          werte: {
            0: {'a': 34, 'b': 12, 'c': 12},
            1: {'a': 14, 'b': 27, 'c': 17},
            2: {'a': 9, 'b': 11, 'c': 6},
          },
        ),
      );
    });

    testWidgets('Tablet 834x1112 — Übersicht', (tester) async {
      await beiGroesse(
        tester,
        'G-tablet-834-uebersicht',
        const Size(834, 1112),
        const UebersichtScreen(),
      );
    });

    testWidgets('Tablet quer 1112x834 — Übersicht', (tester) async {
      await beiGroesse(
        tester,
        'G-tablet-quer-1112-uebersicht',
        const Size(1112, 834),
        const UebersichtScreen(),
      );
    });

    testWidgets('Handy klein 320x568 — Entscheidungspunkt', (tester) async {
      await beiGroesse(
        tester,
        'G-handy-320-punkt',
        const Size(320, 568),
        PunktScreen(szenarioId: inhalt.szenarien.first.id, startPunkt: 0),
        fortschritt: Fortschritt(
          erststartGesehen: true,
          begonnen: {inhalt.szenarien.first.id},
          wahlen: {
            Fortschritt.schluessel(inhalt.szenarien.first.id, 0): 'a',
          },
        ),
      );
    });
  });

  testWidgets('S1 Uebersicht — Erststart', (tester) async {
    await aufnehmen(
      tester,
      'S1-uebersicht-erststart',
      huelle(screen: const UebersichtScreen()),
    );
  });

  testWidgets('S1 Uebersicht — mit Fortschritt', (tester) async {
    await aufnehmen(
      tester,
      'S1-uebersicht-fortschritt',
      huelle(
        screen: const UebersichtScreen(),
        fortschritt: komplett(inhalt.szenarien.first, bis: 0),
      ),
    );
  });

  testWidgets('S1 Uebersicht — hell', (tester) async {
    await aufnehmen(
      tester,
      'S1-uebersicht-hell',
      huelle(
        screen: const UebersichtScreen(),
        fortschritt: komplett(inhalt.szenarien.first, bis: 0),
        dunkel: false,
      ),
    );
  });

  // Die einmalige Abschluss-Geste in der Szenariokarte, unterwegs festgehalten.
  testWidgets('S1 Uebersicht — Abschluss-Geste', (tester) async {
    final sz = inhalt.szenarien.first;
    await aufnehmen(
      tester,
      'S1-uebersicht-konfetti',
      huelle(
        screen: const UebersichtScreen(),
        fortschritt: komplett(sz),
      ),
      mitten: const Duration(milliseconds: 430),
    );
  });

  testWidgets('S2 Szenario-Einstieg', (tester) async {
    await aufnehmen(
      tester,
      'S2-einstieg',
      huelle(
        screen: EinstiegScreen(szenarioId: inhalt.szenarien[1].id),
        fortschritt: const Fortschritt(erststartGesehen: true),
      ),
    );
  });

  testWidgets('S3 Entscheidungspunkt — ohne Wahl', (tester) async {
    await aufnehmen(
      tester,
      'S3-punkt-ohne-wahl',
      huelle(
        screen: PunktScreen(szenarioId: inhalt.szenarien[1].id, startPunkt: 0),
        fortschritt: Fortschritt(
          erststartGesehen: true,
          begonnen: {inhalt.szenarien[1].id},
        ),
      ),
    );
  });

  testWidgets('S3 Entscheidungspunkt — nach der Wahl', (tester) async {
    final sz = inhalt.szenarien[1];
    await aufnehmen(
      tester,
      'S3-punkt-nach-wahl',
      huelle(
        screen: PunktScreen(szenarioId: sz.id, startPunkt: 0),
        fortschritt: Fortschritt(
          erststartGesehen: true,
          begonnen: {sz.id},
          wahlen: {Fortschritt.schluessel(sz.id, 0): 'a'},
        ),
      ),
    );
  });

  testWidgets('S3 Entscheidungspunkt — Einordnung offen', (tester) async {
    final sz = inhalt.szenarien[1];
    await aufnehmen(
      tester,
      'S3-einordnung-offen',
      huelle(
        screen: PunktScreen(szenarioId: sz.id, startPunkt: 0),
        fortschritt: Fortschritt(
          erststartGesehen: true,
          begonnen: {sz.id},
          wahlen: {Fortschritt.schluessel(sz.id, 0): 'a'},
        ),
      ),
      danach: (t) async {
        // Das Panel steht unter dem Falz — erst heranscrollen, dann tippen.
        final kopf = find.text('Fachliche Einordnung anzeigen');
        await t.ensureVisible(kopf);
        await t.pumpAndSettle();
        await t.tap(kopf);
      },
    );
  });

  testWidgets('S4 Auswertung', (tester) async {
    final sz = inhalt.szenarien[1];
    await aufnehmen(
      tester,
      'S4-auswertung',
      huelle(
        screen: AuswertungScreen(szenarioId: sz.id),
        fortschritt: komplett(sz),
        spiegel: const SpiegelDaten(
          status: SpiegelStatus.da,
          werte: {
            0: {'a': 34, 'b': 12, 'c': 12},
            1: {'a': 14, 'b': 27, 'c': 17},
            2: {'a': 2, 'b': 1, 'c': 0},
          },
        ),
      ),
    );
  });

  testWidgets('S5 Einstellungen', (tester) async {
    await aufnehmen(
      tester,
      'S5-einstellungen',
      huelle(
        screen: const EinstellungenScreen(),
        fortschritt: const Fortschritt(erststartGesehen: true),
      ),
    );
  });

  // Die Sheets werden ueber den echten Weg geoeffnet, nicht als nackter
  // Inhalt: die Sheet-Huelle selbst ist Teil dessen, was geprueft wird.
  testWidgets('S6 Hilfe-Sheet', (tester) async {
    await aufnehmen(
      tester,
      'S6-hilfe-sheet',
      huelle(
        screen: const UebersichtScreen(),
        fortschritt: const Fortschritt(erststartGesehen: true),
      ),
      danach: (t) async {
        await t.tap(find.text('Hilfetelefon Sexueller Missbrauch'));
      },
    );
  });

  testWidgets('S7 Info-Sheet', (tester) async {
    await aufnehmen(
      tester,
      'S7-info-sheet',
      huelle(
        screen: const UebersichtScreen(),
        fortschritt: const Fortschritt(erststartGesehen: true),
      ),
      danach: (t) async {
        await t.tap(find.byTooltip('So funktioniert Pathwise'));
      },
    );
  });

  testWidgets('S8 Rueckmeldungs-Sheet', (tester) async {
    await aufnehmen(
      tester,
      'S8-rueckmeldung-sheet',
      huelle(
        screen: const UebersichtScreen(),
        fortschritt: const Fortschritt(erststartGesehen: true),
      ),
      danach: (t) async {
        final block =
            find.text('Rückmeldung geben oder eine Situation einschicken');
        await t.ensureVisible(block);
        await t.pumpAndSettle();
        await t.tap(block);
      },
    );
  });

  testWidgets('S8 Rueckmeldung — Formular', (tester) async {
    await aufnehmen(
      tester,
      'S8-rueckmeldung',
      huelle(
        screen: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: RueckmeldungInhalt(),
          ),
        ),
        fortschritt: const Fortschritt(erststartGesehen: true),
      ),
    );
  });

  // Die Ringe wachsen auf das 1,9-fache. Diese Aufnahme haelt sie unterwegs
  // fest und zeigt, dass sie im reservierten Bereich bleiben und nicht in den
  // Text darunter ragen.
  testWidgets('S9 Kommt bald — Ringe unterwegs', (tester) async {
    await aufnehmen(
      tester,
      'S9-kommt-bald-ringe',
      huelle(
        screen: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: KommtBaldInhalt(modul: inhalt.module.first),
            ),
          ),
        ),
        fortschritt: const Fortschritt(erststartGesehen: true),
      ),
      mitten: const Duration(milliseconds: 520),
    );
  });

  // Der Dialog traegt drei Dauerschleifen (M17-M19). Aufgenommen wird er mit
  // disableAnimations — das ist zugleich der Nachweis, dass die Schleifen bei
  // reduzierter Bewegung gar nicht erst anlaufen (DESIGN.md 5).
  testWidgets('S9 Kommt bald — reduzierte Bewegung', (tester) async {
    await aufnehmen(
      tester,
      'S9-kommt-bald',
      huelle(
        screen: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: KommtBaldInhalt(modul: inhalt.module.first),
            ),
          ),
        ),
        fortschritt: const Fortschritt(erststartGesehen: true),
        ohneBewegung: true,
      ),
    );
  });
}
