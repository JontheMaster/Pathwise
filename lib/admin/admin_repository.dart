// Alle Datenzugriffe des Dashboards an einer Stelle.
//
// Als Schnittstelle, damit die Oberflaeche gegen eine Attrappe pruefbar ist:
// die echte Umsetzung braucht den geheimen Schluessel, und der gehoert nicht
// in einen Testlauf.
//
// Das Dashboard laeuft mit dem geheimen Schluessel und damit an RLS vorbei.
// Es greift deshalb direkt auf die Tabellen zu, nicht auf die Funktionen der
// App — die sind fuer anon gemacht und koennen weniger, als hier gebraucht
// wird (Entwuerfe sehen, Fassungen lesen, Vereine anlegen).
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_modelle.dart';

abstract interface class AdminRepository {
  Future<List<AdminSzenario>> szenarien();
  Future<void> szenarioSichern(AdminSzenario s);
  Future<void> szenarioAnlegen(AdminSzenario s);
  Future<void> szenarioLoeschen(String id);

  /// Alle veroeffentlichten Fassungen eines Szenarios, neueste zuerst.
  Future<List<AdminSzenario>> fassungen(String szenarioId);

  Future<List<AdminVerein>> vereine();
  Future<String> vereinAnlegen({required String code, required String name});
  Future<void> vereinSichern(AdminVerein v);
  Future<void> vereinLoeschen(String id);

  Future<void> personSichern(AdminPerson p);
  Future<void> personLoeschen(String id);

  Future<void> beratungSichern(AdminBeratung b);
  Future<void> beratungLoeschen(String id);

  /// Die bundesweiten Stellen (verein_id ist null).
  Future<List<AdminBeratung>> beratungBundesweit();

  Future<List<AdminRueckmeldung>> rueckmeldungen();
  Future<void> rueckmeldungBearbeitet(String id, bool bearbeitet);
  Future<void> rueckmeldungLoeschen(String id);

  Future<List<AdminZahl>> zahlen();
}

class SupabaseAdminRepository implements AdminRepository {
  const SupabaseAdminRepository(this._c);

  final SupabaseClient _c;

  // ── Szenarien ──────────────────────────────────────────────────────────

  @override
  Future<List<AdminSzenario>> szenarien() async {
    final zeilen = await _c
        .from('szenarien')
        .select('id, status, reihenfolge, fassung, signatur, inhalt, '
            'aktualisiert_am')
        .order('reihenfolge')
        .order('id');
    return zeilen.map(AdminSzenario.ausZeile).toList(growable: false);
  }

  @override
  Future<void> szenarioAnlegen(AdminSzenario s) async {
    await _c.from('szenarien').insert({
      'id': s.id,
      'status': s.status.schluessel,
      'reihenfolge': s.reihenfolge,
      'inhalt': s.inhalt,
    });
  }

  @override
  Future<void> szenarioSichern(AdminSzenario s) async {
    // fassung und signatur setzt der Trigger. Sie hier mitzuschicken waere
    // der sichere Weg, die Fassungszaehlung zu zerschiessen.
    await _c.from('szenarien').update({
      'status': s.status.schluessel,
      'reihenfolge': s.reihenfolge,
      'inhalt': s.inhalt,
    }).eq('id', s.id);
  }

  @override
  Future<void> szenarioLoeschen(String id) async {
    await _c.from('szenarien').delete().eq('id', id);
  }

  @override
  Future<List<AdminSzenario>> fassungen(String szenarioId) async {
    final zeilen = await _c
        .from('szenario_fassungen')
        .select('szenario_id, fassung, inhalt, signatur, veroeffentlicht_am')
        .eq('szenario_id', szenarioId)
        .order('fassung', ascending: false);
    return zeilen
        .map((z) => AdminSzenario(
              id: z['szenario_id'] as String,
              status: AdminStatus.veroeffentlicht,
              reihenfolge: 0,
              fassung: (z['fassung'] as num).toInt(),
              signatur: z['signatur'] as String? ?? '',
              inhalt: Map<String, dynamic>.from(z['inhalt'] as Map),
              aktualisiertAm:
                  DateTime.tryParse(z['veroeffentlicht_am'] as String? ?? ''),
            ))
        .toList(growable: false);
  }

  // ── Vereine ────────────────────────────────────────────────────────────

  @override
  Future<List<AdminVerein>> vereine() async {
    final zeilen =
        await _c.from('vereine').select('id, code, name, aktiv').order('name');
    final vereine = zeilen.map(AdminVerein.ausZeile).toList();
    if (vereine.isEmpty) return const [];

    final personen = await _c
        .from('ansprechpersonen')
        .select('id, verein_id, name, rolle, kontakt, kontaktart, reihenfolge')
        .order('reihenfolge')
        .order('name');
    final stellen = await _c
        .from('beratungsstellen')
        .select('id, verein_id, titel, zusatz, nummer, reihenfolge')
        .not('verein_id', 'is', null)
        .order('reihenfolge')
        .order('titel');

    return vereine
        .map((v) => v.mit(
              personen: personen
                  .where((p) => p['verein_id'] == v.id)
                  .map(AdminPerson.ausZeile)
                  .toList(growable: false),
              beratung: stellen
                  .where((b) => b['verein_id'] == v.id)
                  .map(AdminBeratung.ausZeile)
                  .toList(growable: false),
            ))
        .toList(growable: false);
  }

  @override
  Future<String> vereinAnlegen({
    required String code,
    required String name,
  }) async {
    final zeile = await _c
        .from('vereine')
        .insert({'code': code.trim().toUpperCase(), 'name': name.trim()})
        .select('id')
        .single();
    return zeile['id'] as String;
  }

  @override
  Future<void> vereinSichern(AdminVerein v) async {
    await _c.from('vereine').update({
      'code': v.code.trim().toUpperCase(),
      'name': v.name.trim(),
      'aktiv': v.aktiv,
    }).eq('id', v.id);
  }

  @override
  Future<void> vereinLoeschen(String id) async {
    await _c.from('vereine').delete().eq('id', id);
  }

  @override
  Future<void> personSichern(AdminPerson p) async {
    final zeile = p.zuZeile();
    if (p.id == null) {
      await _c.from('ansprechpersonen').insert(zeile);
    } else {
      await _c.from('ansprechpersonen').update(zeile).eq('id', p.id!);
    }
  }

  @override
  Future<void> personLoeschen(String id) async {
    await _c.from('ansprechpersonen').delete().eq('id', id);
  }

  @override
  Future<void> beratungSichern(AdminBeratung b) async {
    final zeile = b.zuZeile();
    if (b.id == null) {
      await _c.from('beratungsstellen').insert(zeile);
    } else {
      await _c.from('beratungsstellen').update(zeile).eq('id', b.id!);
    }
  }

  @override
  Future<void> beratungLoeschen(String id) async {
    await _c.from('beratungsstellen').delete().eq('id', id);
  }

  @override
  Future<List<AdminBeratung>> beratungBundesweit() async {
    final zeilen = await _c
        .from('beratungsstellen')
        .select('id, verein_id, titel, zusatz, nummer, reihenfolge')
        .isFilter('verein_id', null)
        .order('reihenfolge')
        .order('titel');
    return zeilen.map(AdminBeratung.ausZeile).toList(growable: false);
  }

  // ── Rueckmeldungen ─────────────────────────────────────────────────────

  @override
  Future<List<AdminRueckmeldung>> rueckmeldungen() async {
    final zeilen = await _c
        .from('rueckmeldungen')
        .select('id, art, text, email, bearbeitet, erstellt_am, verein_id')
        .order('erstellt_am', ascending: false);
    return zeilen.map(AdminRueckmeldung.ausZeile).toList(growable: false);
  }

  @override
  Future<void> rueckmeldungBearbeitet(String id, bool bearbeitet) async {
    await _c
        .from('rueckmeldungen')
        .update({'bearbeitet': bearbeitet}).eq('id', id);
  }

  @override
  Future<void> rueckmeldungLoeschen(String id) async {
    await _c.from('rueckmeldungen').delete().eq('id', id);
  }

  // ── Zahlen ─────────────────────────────────────────────────────────────

  @override
  Future<List<AdminZahl>> zahlen() async {
    final zeilen = await _c
        .from('zaehlwerte')
        .select('verein_id, szenario_id, signatur, punkt_index, option_id, '
            'anzahl')
        .order('szenario_id')
        .order('punkt_index')
        .order('option_id');
    return zeilen.map(AdminZahl.ausZeile).toList(growable: false);
  }
}
