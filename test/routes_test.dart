// Der Weg zurueck zur Uebersicht muss immer gleich aussehen — egal, ob der
// Screen mit M4 (Szenario oeffnen) oder M6 (Entscheidungspunkt, Auswertung)
// gekommen ist. DESIGN.md gibt fuer das Schliessen mit M5 genau eine Bewegung
// vor.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/design/pathwise_routes.dart';

void main() {
  /// Liefert Versatz und Skalierung des schliessenden Screens, 130 ms nachdem
  /// das Zurueck ausgeloest wurde.
  Future<(Offset, double)> beimSchliessen(
    WidgetTester tester,
    PwTransition kind,
  ) async {
    final nav = GlobalKey<NavigatorState>();

    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: const Scaffold(body: Center(child: Text('Übersicht'))),
    ));

    nav.currentState!.push(
      pwRoute(const Scaffold(body: Center(child: Text('Szenario'))), kind),
    );
    await tester.pumpAndSettle();

    nav.currentState!.pop();
    await tester.pump(); // Rueckwaertslauf beginnt
    await tester.pump(const Duration(milliseconds: 130));

    // Nur die geschobene Seite ansehen: die Wurzelroute bringt die
    // Standard-Transition von MaterialApp mit, samt eigener Transforms.
    final versatz = tester
        .widget<FractionalTranslation>(find.ancestor(
          of: find.text('Szenario'),
          matching: find.byType(FractionalTranslation),
        ))
        .translation;
    final skalen = tester
        .widgetList<Transform>(find.ancestor(
          of: find.text('Szenario'),
          matching: find.byType(Transform),
        ))
        // toList(): map ist lazy und wuerde sonst erst nach dem
        // pumpAndSettle unten ausgewertet, also im Endzustand.
        .map((w) => w.transform.getMaxScaleOnAxis())
        .toList();

    // Die Route ist fertig animiert, bevor der Test endet.
    await tester.pumpAndSettle();
    // Die groesste Skalierung ueber der Seite: die Wurzelroute und das
    // Material-Geruest bringen eigene Transforms bei 1.0 mit.
    return (versatz, skalen.isEmpty ? 1.0 : skalen.reduce(math.max));
  }

  testWidgets('Schliessen sieht nach M4 und nach M6 gleich aus',
      (tester) async {
    final nachOeffnen = await beimSchliessen(tester, PwTransition.oeffnen);
    final nachVor = await beimSchliessen(tester, PwTransition.vor);

    expect(nachOeffnen.$1, nachVor.$1,
        reason: 'Der Versatz beim Schliessen darf nicht von der Herkunft '
            'abhängen');
    expect(nachOeffnen.$2, closeTo(nachVor.$2, 0.0001),
        reason: 'Die Skalierung beim Schliessen darf nicht von der Herkunft '
            'abhängen');
  });

  testWidgets('Schliessen folgt M5: kein Versatz, Skalierung über 1',
      (tester) async {
    final (versatz, skala) = await beimSchliessen(tester, PwTransition.vor);

    // M5 ist eine reine Skalierung 1.04 -> 1 mit Einblenden, ohne Verschieben.
    expect(versatz, Offset.zero);
    // Der schliessende Screen weitet sich auf dem Weg nach draussen.
    expect(skala, greaterThan(1.0));
    expect(skala, lessThanOrEqualTo(1.04));
  });

  testWidgets('Vorwaerts bleibt bei der jeweiligen Bewegung', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: const Scaffold(body: Center(child: Text('Übersicht'))),
    ));

    nav.currentState!.push(
      pwRoute(
        const Scaffold(body: Center(child: Text('Szenario'))),
        PwTransition.vor,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // M6 vorwärts kommt von rechts.
    final versatz = tester
        .widget<FractionalTranslation>(find.ancestor(
          of: find.text('Szenario'),
          matching: find.byType(FractionalTranslation),
        ))
        .translation;
    expect(versatz.dx, greaterThan(0));
    expect(versatz.dy, 0);

    await tester.pumpAndSettle();
  });
}
