// Szenarien aus der Datenbank: Fassungen anheften, austauschen, zaehlen.
//
// Der Kern ist die Zusage aus supabase/migrations/0003_szenarien.sql: wer ein
// Szenario angefangen hat, spielt es in seiner Fassung zu Ende. Wird es
// waehrenddessen ueberarbeitet, darf zwischen zwei Entscheidungspunkten nicht
// die Leitfrage wechseln.
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/spiegel_repository.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/szenario_repository.dart';
import 'package:pathwise/state/durchlauf_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'verein_probe.dart';

/// Liefert vorgegebene Szenarien statt der Datenbank.
class _FesteSzenarien implements SzenarioRepository {
  _FesteSzenarien({required this.aktuell, this.alteFassungen = const {}});

  final List<PwSzenario>? aktuell;

  /// "id:fassung" -> Szenario.
  final Map<String, PwSzenario> alteFassungen;

  final List<String> abgerufen = [];

  @override
  Future<List<PwSzenario>?> ausDatenbank() async => aktuell;

  @override
  Future<PwSzenario?> fassung(String id, int fassung) async {
    abgerufen.add('$id:$fassung');
    return alteFassungen['$id:$fassung'];
  }

  @override
  Future<PwInhalt> laden() => throw UnimplementedError();
}

class _ZaehlerSpion implements SpiegelRepository {
  final List<Map<String, Object?>> rufe = [];

  @override
  Future<void> zaehlen({
    required String? vereinId,
    required String szenarioId,
    required String signatur,
    required int punktIndex,
    required String optionId,
  }) async {
    rufe.add({
      'verein': vereinId,
      'szenario': szenarioId,
      'signatur': signatur,
      'punkt': punktIndex,
      'option': optionId,
    });
  }

  @override
  Future<SpiegelDaten> laden(
    String szenarioId, {
    required String signatur,
    String? vereinId,
  }) async =>
      SpiegelDaten.fehler;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> rohInhalt;
  late PwInhalt buendel;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final roh = await rootBundle.loadString(SzenarioRepository.pfad);
    rohInhalt = jsonDecode(roh) as Map<String, dynamic>;
    buendel = PwInhalt.ausJson(rohInhalt);
  });

  /// Baut ein Szenario aus dem Buendel nach, mit Fassung, Signatur und
  /// optional geaenderter Leitfrage am ersten Punkt.
  PwSzenario ausDb(
    int index, {
    required int fassung,
    required String signatur,
    String? leitfrage,
  }) {
    final j = jsonDecode(
      jsonEncode((rohInhalt['szenarien'] as List)[index]),
    ) as Map<String, dynamic>;
    j['fassung'] = fassung;
    j['signatur'] = signatur;
    if (leitfrage != null) {
      ((j['punkte'] as List).first as Map<String, dynamic>)['leitfrage'] =
          leitfrage;
    }
    return PwSzenario.ausJson(j);
  }

  DurchlaufNotifier baue(
    SzenarioRepository szenarien,
    SpiegelRepository spiegel, {
    Fortschritt? fortschritt,
  }) {
    final container = ProviderContainer(
      overrides: [
        durchlaufProvider.overrideWith(
          () => DurchlaufNotifier(
            DurchlaufState(
              inhalt: buendel,
              fortschritt:
                  fortschritt ?? mitVerein(const Fortschritt(), buendel),
            ),
            const FortschrittSpeicher(),
            spiegel,
            szenarien,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(durchlaufProvider.notifier);
  }

  group('Abruf', () {
    test('tauscht die Szenarien aus dem Buendel gegen die der Datenbank',
        () async {
      final db = _FesteSzenarien(
        aktuell: [ausDb(0, fassung: 4, signatur: 'x' * 32, leitfrage: 'Neu?')],
      );
      final n = baue(db, _ZaehlerSpion());

      expect(n.state.inhalt.szenarien, hasLength(3), reason: 'erst das Buendel');
      await n.szenarienAuffrischen();

      expect(n.state.inhalt.szenarien, hasLength(1));
      expect(n.state.inhalt.szenarien.first.punkte.first.leitfrage, 'Neu?');
      expect(n.state.inhalt.szenarien.first.fassung, 4);
      // Die Rahmendaten bleiben: der Abruf betrifft nur die Szenarien.
      expect(n.state.inhalt.infos, buendel.infos);
    });

    test('laesst das Buendel stehen, wenn die Datenbank nichts liefert',
        () async {
      final n = baue(_FesteSzenarien(aktuell: null), _ZaehlerSpion());
      await n.szenarienAuffrischen();
      expect(n.state.inhalt.szenarien, hasLength(3));
    });
  });

  group('Fassung anheften', () {
    test('heftet beim Beginnen an und gibt beim "Nochmal" wieder frei', () {
      final n = baue(_FesteSzenarien(aktuell: null), _ZaehlerSpion());
      final ausDatenbank = ausDb(0, fassung: 7, signatur: 'y' * 32);

      n.begonnen(ausDatenbank);
      expect(n.state.fortschritt.fassungen, {ausDatenbank.id: 7});

      n.nochmal(ausDatenbank);
      expect(n.state.fortschritt.fassungen, isEmpty);
    });

    test('heftet nichts an, was aus dem Buendel kommt', () {
      final n = baue(_FesteSzenarien(aktuell: null), _ZaehlerSpion());
      n.begonnen(buendel.szenarien.first);
      expect(n.state.fortschritt.fassungen, isEmpty);
    });

    test('holt die angeheftete Fassung, wenn inzwischen eine neuere steht',
        () async {
      final alt = ausDb(0, fassung: 2, signatur: 'a' * 32, leitfrage: 'Alt?');
      final neu = ausDb(0, fassung: 3, signatur: 'b' * 32, leitfrage: 'Neu?');
      final db = _FesteSzenarien(
        aktuell: [neu],
        alteFassungen: {'${alt.id}:2': alt},
      );
      final n = baue(
        db,
        _ZaehlerSpion(),
        fortschritt: mitVerein(
          Fortschritt(begonnen: {alt.id}, fassungen: {alt.id: 2}),
          buendel,
        ),
      );

      await n.szenarienAuffrischen();

      expect(db.abgerufen, ['${alt.id}:2']);
      expect(n.state.inhalt.szenarien.single.punkte.first.leitfrage, 'Alt?');
      expect(n.state.inhalt.szenarien.single.fassung, 2);
    });

    test('nimmt die aktuelle Fassung, wenn die alte nicht mehr abrufbar ist',
        () async {
      // Ein veraenderter Text ist immer noch besser als ein Szenario, das
      // mitten im Durchlauf aus der Uebersicht verschwindet.
      final neu = ausDb(0, fassung: 3, signatur: 'b' * 32, leitfrage: 'Neu?');
      final n = baue(
        _FesteSzenarien(aktuell: [neu]),
        _ZaehlerSpion(),
        fortschritt: mitVerein(
          Fortschritt(begonnen: {neu.id}, fassungen: {neu.id: 2}),
          buendel,
        ),
      );

      await n.szenarienAuffrischen();
      expect(n.state.inhalt.szenarien.single.fassung, 3);
    });
  });

  group('Zaehlwerte', () {
    test('tragen die Signatur der gespielten Fassung', () {
      final spion = _ZaehlerSpion();
      final n = baue(_FesteSzenarien(aktuell: null), spion);
      final sz = ausDb(0, fassung: 5, signatur: 'c' * 32);

      n.waehlen(sz, 0, 'b');

      expect(spion.rufe.single['signatur'], 'c' * 32);
      expect(spion.rufe.single['verein'], probeVerein(buendel).id);
    });

    test('aus dem Buendel tragen keine Signatur und werden nicht gesendet',
        () async {
      // Das Buendel greift nur ohne Netz — und ohne Netz kaeme der Zaehlwert
      // ohnehin nicht an. Der echte Speicher muss das stillschweigend
      // schlucken (DESIGN.md 8).
      final n = baue(_FesteSzenarien(aktuell: null), const SpiegelRepository());
      n.waehlen(buendel.szenarien.first, 0, 'a');

      await const SpiegelRepository().zaehlen(
        vereinId: probeVerein(buendel).id,
        szenarioId: 'egal',
        signatur: '',
        punktIndex: 0,
        optionId: 'a',
      );
    });
  });

  group('Speicher', () {
    test('sichert und laedt die angehefteten Fassungen', () async {
      SharedPreferences.setMockInitialValues({});
      const speicher = FortschrittSpeicher();

      await speicher.sichern(
        const Fortschritt(fassungen: {'heimspiel': 3, 'cotrainer': 1}),
      );
      final geladen = await speicher.laden();

      expect(geladen.fassungen, {'heimspiel': 3, 'cotrainer': 1});
    });

    test('loescht sie mit allen anderen lokalen Daten', () async {
      SharedPreferences.setMockInitialValues({});
      const speicher = FortschrittSpeicher();

      await speicher.sichern(const Fortschritt(fassungen: {'heimspiel': 3}));
      await speicher.allesLoeschen();

      expect((await speicher.laden()).fassungen, isEmpty);
    });
  });
}
