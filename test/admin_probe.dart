// Eine Attrappe des Admin-Repositories.
//
// Die echte Umsetzung braucht den geheimen Schluessel des Supabase-Projekts,
// und der gehoert nicht in einen Testlauf. Diese hier haelt alles im Speicher
// und merkt sich, was aufgerufen wurde.
import 'package:pathwise/admin/admin_modelle.dart';
import 'package:pathwise/admin/admin_repository.dart';

class ProbeAdminRepository implements AdminRepository {
  ProbeAdminRepository({
    List<AdminSzenario>? szenarien,
    List<AdminVerein>? vereine,
    List<AdminBeratung>? bundesweit,
    List<AdminRueckmeldung>? rueckmeldungen,
    List<AdminZahl>? zahlen,
  })  : _szenarien = [...?szenarien],
        _vereine = [...?vereine],
        _bundesweit = [...?bundesweit],
        _rueckmeldungen = [...?rueckmeldungen],
        _zahlen = [...?zahlen];

  final List<AdminSzenario> _szenarien;
  final List<AdminVerein> _vereine;
  final List<AdminBeratung> _bundesweit;
  final List<AdminRueckmeldung> _rueckmeldungen;
  final List<AdminZahl> _zahlen;

  /// Was aufgerufen wurde, in der Reihenfolge — fuer Zusicherungen im Test.
  final List<String> rufe = [];

  /// Wenn gesetzt, wirft der naechste schreibende Aufruf.
  String? fehlerBeimSchreiben;

  void _pruefen(String ruf) {
    rufe.add(ruf);
    final f = fehlerBeimSchreiben;
    if (f != null) {
      fehlerBeimSchreiben = null;
      throw Exception(f);
    }
  }

  @override
  Future<List<AdminSzenario>> szenarien() async => List.unmodifiable(_szenarien);

  @override
  Future<void> szenarioAnlegen(AdminSzenario s) async {
    _pruefen('szenarioAnlegen:${s.id}');
    _szenarien.add(s);
  }

  @override
  Future<void> szenarioSichern(AdminSzenario s) async {
    _pruefen('szenarioSichern:${s.id}:${s.status.schluessel}');
    final i = _szenarien.indexWhere((x) => x.id == s.id);
    if (i >= 0) _szenarien[i] = s;
  }

  @override
  Future<void> szenarioLoeschen(String id) async {
    _pruefen('szenarioLoeschen:$id');
    _szenarien.removeWhere((x) => x.id == id);
  }

  @override
  Future<List<AdminSzenario>> fassungen(String szenarioId) async {
    rufe.add('fassungen:$szenarioId');
    return _szenarien.where((s) => s.id == szenarioId).toList(growable: false);
  }

  @override
  Future<List<AdminVerein>> vereine() async => List.unmodifiable(_vereine);

  @override
  Future<String> vereinAnlegen({
    required String code,
    required String name,
  }) async {
    _pruefen('vereinAnlegen:$code');
    final id = 'verein-${_vereine.length + 1}';
    _vereine.add(
      AdminVerein(id: id, code: code, name: name, aktiv: true),
    );
    return id;
  }

  @override
  Future<void> vereinSichern(AdminVerein v) async {
    _pruefen('vereinSichern:${v.id}:aktiv=${v.aktiv}');
    final i = _vereine.indexWhere((x) => x.id == v.id);
    if (i >= 0) _vereine[i] = v;
  }

  @override
  Future<void> vereinLoeschen(String id) async {
    _pruefen('vereinLoeschen:$id');
    _vereine.removeWhere((x) => x.id == id);
  }

  @override
  Future<void> personSichern(AdminPerson p) async {
    _pruefen('personSichern:${p.name}');
  }

  @override
  Future<void> personLoeschen(String id) async {
    _pruefen('personLoeschen:$id');
  }

  @override
  Future<void> beratungSichern(AdminBeratung b) async {
    _pruefen('beratungSichern:${b.titel}');
  }

  @override
  Future<void> beratungLoeschen(String id) async {
    _pruefen('beratungLoeschen:$id');
  }

  @override
  Future<List<AdminBeratung>> beratungBundesweit() async =>
      List.unmodifiable(_bundesweit);

  @override
  Future<List<AdminRueckmeldung>> rueckmeldungen() async =>
      List.unmodifiable(_rueckmeldungen);

  @override
  Future<void> rueckmeldungBearbeitet(String id, bool bearbeitet) async {
    _pruefen('rueckmeldungBearbeitet:$id:$bearbeitet');
    final i = _rueckmeldungen.indexWhere((r) => r.id == id);
    if (i >= 0) {
      final r = _rueckmeldungen[i];
      _rueckmeldungen[i] = AdminRueckmeldung(
        id: r.id,
        art: r.art,
        text: r.text,
        email: r.email,
        bearbeitet: bearbeitet,
        erstelltAm: r.erstelltAm,
        vereinId: r.vereinId,
      );
    }
  }

  @override
  Future<void> rueckmeldungLoeschen(String id) async {
    _pruefen('rueckmeldungLoeschen:$id');
    _rueckmeldungen.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<AdminZahl>> zahlen() async => List.unmodifiable(_zahlen);
}

/// Ein Szenario zum Testen.
AdminSzenario probeSzenario({
  String id = 'probe',
  AdminStatus status = AdminStatus.entwurf,
  String titel = 'Ein Szenario',
  String themenfeld = 'Testfeld',
  int fassung = 1,
}) =>
    AdminSzenario(
      id: id,
      status: status,
      reihenfolge: 0,
      fassung: fassung,
      signatur: 'a' * 32,
      inhalt: {
        'titel': titel,
        'themenfeld': themenfeld,
        'kurz': 'kurz',
        'dauer': 'ca. 5 Min.',
        'rahmen': ['U12'],
        'vorgeschichte': 'v',
        'ausgangssituation': 'a',
        'merkmale': [
          {'text': 'ein Merkmal', 'stufe': 'check'},
        ],
        'punkte': [
          {
            'text': 't',
            'leitfrage': 'Wie reagierst du?',
            'optionen': [
              {'id': 'a', 'text': 'A'},
              {'id': 'b', 'text': 'B'},
              {'id': 'c', 'text': 'C'},
            ],
            'erkennen': 'e',
            'absichern': 's',
            'handeln': 'h',
          },
        ],
      },
    );
