// Die Abschluss-Geste darf erst laufen, wenn ihre Karte im Bild steht.
//
// Ein Scrollbereich baut alle Karten sofort. Ohne die Kopplung an die
// Sichtbarkeit lief die Geste bei einer Karte weiter unten ab, waehrend
// niemand hinsah — und war danach als gezeigt abgehakt, also fuer immer weg.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/spiegel_repository.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/szenario_repository.dart';
import 'package:pathwise/design/components/pw_konfetti.dart';
import 'package:pathwise/design/pathwise_theme.dart';
import 'package:pathwise/screens/uebersicht_screen.dart';
import 'package:pathwise/state/durchlauf_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'schriften.dart';

void main() {
  late PwInhalt inhalt;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await schriftenLaden();
    SharedPreferences.setMockInitialValues({});
    inhalt = await const SzenarioRepository().laden();
  });

  /// Ein abgeschlossenes Szenario, dessen Geste noch aussteht.
  Fortschritt abgeschlossen(PwSzenario sz, {required PwBewegung bewegung}) =>
      Fortschritt(
        erststartGesehen: true,
        bewegung: bewegung,
        begonnen: {sz.id},
        wahlen: {
          for (var i = 0; i < sz.punkte.length; i++)
            Fortschritt.schluessel(sz.id, i): 'a',
        },
      );

  Widget huelle(Fortschritt f) => ProviderScope(
        overrides: [
          durchlaufProvider.overrideWith(
            () => DurchlaufNotifier(
              DurchlaufState(inhalt: inhalt, fortschritt: f),
              const FortschrittSpeicher(),
              const SpiegelRepository(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: pwTheme(dark: false),
          darkTheme: pwTheme(dark: true),
          themeMode: ThemeMode.dark,
          home: const UebersichtScreen(),
        ),
      );

  testWidgets('läuft erst, wenn die Karte ins Bild gescrollt wird',
      (tester) async {
    // Das letzte Szenario steht auf dem Handy unterhalb des Falzes.
    final sz = inhalt.szenarien.last;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      huelle(abgeschlossen(sz, bewegung: PwBewegung.verspielt)),
    );
    await tester.pumpAndSettle();

    // Die Karte ist gebaut, aber ausserhalb des Bildes: nichts laeuft.
    expect(find.text(sz.titel), findsOneWidget);
    expect(
      find.byType(PwKonfetti),
      findsNothing,
      reason: 'Die Geste darf nicht ausserhalb des Bildes ablaufen',
    );

    // Hinunterscrollen, bis die Karte im Bild steht.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byType(PwKonfetti),
      findsOneWidget,
      reason: 'Im Bild muss die Geste starten',
    );

    // Nicht aussetteln: die Geste laeuft rund eine Sekunde.
    await tester.pump(const Duration(milliseconds: 1300));
  });

  testWidgets('läuft gar nicht in der Vorgabe „Normal"', (tester) async {
    final sz = inhalt.szenarien.first;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      huelle(abgeschlossen(sz, bewegung: PwBewegung.normal)),
    );
    await tester.pumpAndSettle();

    // Die Karte steht im Bild — trotzdem keine Geste.
    expect(find.text(sz.titel), findsOneWidget);
    expect(find.byType(PwKonfetti), findsNothing);
  });

  testWidgets('läuft im Bild, wenn „Verspielt" gesetzt ist', (tester) async {
    final sz = inhalt.szenarien.first;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      huelle(abgeschlossen(sz, bewegung: PwBewegung.verspielt)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PwKonfetti), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
  });
}
